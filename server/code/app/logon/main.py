#!/usr/bin/env python
# -*- coding:utf-8 -*-

import os
import re

import gevent
import gevent.event
from gevent import pywsgi
pywsgi.WSGIServer.reuse_addr = 1

import corelib
from corelib import sleep, spawn, spawn_later, json_dumps
from corelib import log, common
import grpc

import config
import model
import webapp

static_path = config.static_path
p_static_path = os.path.dirname(static_path)
aes_encrypt = None


class GWebsvrHandler(object):
    def __init__(self, address, wsgi_app):
        self._app = wsgi_app
        self._svr = pywsgi.WSGIServer(address, wsgi_app, log=log if config.debug else None)

    def run(self):
        self._svr.start()

class Application(common.BaseApp):
    app = None

    def __init__(self, **handlers):
        common.BaseApp.init(self, config)

        Application.app = self
        self._tasks = []
        self._waiter = gevent.event.Event()
        self._handlers = handlers
        self.rpc_svr = grpc.RpcServer(access=self)

    def access_sock(self, sock, addr):
        """ 校验是否允许rpc """
        from game.store.define import GF_ACCESS_IP
        s = model.logon_store.get_config(GF_ACCESS_IP)
        if not s:
            return True
        access_ip_re = re.compile(s)
        return access_ip_re.match(addr[0]) is not None

    def access_shell(self, proxy):
        """ 是否允许启动shell """
        return True

    def run(self):
        #修改当前目录，使static目录生效
        log.info(u'change current dir:%s', p_static_path)
        os.chdir(p_static_path)

        self.rpc_svr.bind(admin_addr)
        self.rpc_svr.register(self)
        self.rpc_svr.start()
        grpc.shell_locals.update({'app':self, 'webapp':app})

        log.info('web_config_path:%s', config.web_config_path)
        log.info('app started:%s', addr)
        log.info('app mapping:\n%s', '\n'.join(map(str, webapp.app.mapping)))
        self.init_app()
        if config.use_gunicorn and module_exists('gunicorn') and module_exists('fcntl'):
            self.gunicorn_main()
        else:
            self.gevent_main()
        log.info('app stoped')

    def init_app(self):
        """ 初始化 """
        global aes_encrypt
        from game import aes_encrypt as game_aes_encrypt, ClientRpc
        from game.store.define import GF_CLIENTRPC_AESKEY
        client_rpc_aes_key = model.logon_store.get_config(GF_CLIENTRPC_AESKEY)
        ClientRpc.aes_init(client_rpc_aes_key, pack=1)
        aes_encrypt = game_aes_encrypt


    def gunicorn_main(self):
        modify_sys_argv()
        from gunicorn.app.wsgiapp import WSGIApplication
        WSGIApplication("%prog [OPTIONS] APP_MODULE").run()
        restore_sys_argv()

    def gevent_main(self):
        self._tasks = [corelib.spawn(hd.run) for hd in self._handlers.itervalues()]
        try:
            self._waiter.wait()
        except KeyboardInterrupt:
            self.stop()

    def stop(self):
        for task in self._tasks:
            task.kill()
        self._waiter.set()
        web_handler._svr.stop()
        self.rpc_svr.stop()

from web.httpserver import StaticApp
import posixpath, urllib
class StaticAppEx(StaticApp):
    _caches_ = {}
    def my_translate_path(self, path):
        """Translate a /-separated PATH to the local filename syntax.

        Components that mean special things to the local file system
        (e.g. drive or directory names) are ignored.  (XXX They should
        probably be diagnosed.)

        """
        # abandon query parameters
        path = path.split('?',1)[0]
        path = path.split('#',1)[0]
        path = posixpath.normpath(urllib.unquote(path))
        words = path.split('/')
        words = filter(None, words)
        path = p_static_path
        for word in words:
            drive, word = os.path.splitdrive(word)
            head, word = os.path.split(word)
            if word in (os.curdir, os.pardir):
                continue
            path = os.path.join(path, word)
        return path

    def translate_path(self, path):
        #守护进程，在断开控制台时，os.getcwd会变
        tpath = self.my_translate_path(path)
        self._pre_path = tpath
        return tpath

    def send_error(self, code, message=None):
        return StaticApp.send_error(self, code, message)


class StaticMiddlewareEx:
    """WSGI middleware for serving static files."""
    def __init__(self, app, prefix='/static/'):
        self.app = app
        self.prefix = prefix

    def __call__(self, environ, start_response):
        path = environ.get('PATH_INFO', '')
        if path.startswith(self.prefix):
            return StaticAppEx(environ, start_response)
        else:
            return self.app(environ, start_response)

class ConfigMiddlewareEx:
    """ 处理/config/(.+)\.xml$ 下的请求,减少session等处理 """
    NAMES = ['servers', ]
    xml_headers = [('Content-Type', 'text/xml; charset=UTF-8')]
    txt_headers = [('Content-Type', 'text/plain; charset=UTF-8')]
    json_headers = [('Content-Type', 'application/json; charset=UTF-8')]
    def __init__(self, app):
        self.app = app
        self.prefix = '/config/'
        self.pre_len = len(self.prefix)
        self.pre_ver = None
        self.file_path = None
        self.servers_json = None
        spawn_later(3, self._refresh)

#    def _get_ver_servers(self, servers):
#        """ 根据版本信息,分离不同服务器列表 """
#        rs = {}
#        for s in servers:
#            slist = rs.setdefault(s.ver, [])
#            slist.append(s)
#        return rs.iteritems()

    def _save_servers(self, ver, params):
        name = 'servers'
        json_data = json_dumps(params, ensure_ascii=True)
        is_same = json_data == self.servers_json
        self.servers_json = json_data

        if not os.path.exists(config.web_config_path):
            log.warn(u'web_config_path(%s) not existed!',
                    config.web_config_path)
            return

        try:
            if self.pre_ver != ver:
                #旧版本json更新client_ver数据,提示玩家更新程序
                if self.pre_ver is not None:
                    self._save_file(self.pre_ver, name, json_data, False)
                self._save_file(ver, name, json_data, False)
                self.pre_ver = ver
            else:
                self._save_file(ver, name, json_data, is_same)
        except:
            log.log_except()

    def _save_file(self, ver, name, json_data, is_same):
        if ver:
            servers_file = os.path.join(config.web_config_path,
                    '%s.%s' % (name, ver))
        else:
            servers_file = os.path.join(config.web_config_path,
                '%s' % (name, ))
        if config.AES:#加密版
            data = aes_encrypt(json_data)
            servers_file = '%s.dat' % servers_file
        else:
            data = json_data

        if (os.path.exists(servers_file) and is_same):
            return
        log.debug('_save_file:%s, %s, %s', ver, is_same, servers_file)
        self._save(servers_file, data)


    def _save(self, save_file, data):
        with open(save_file, 'wb') as f:
            f.write(data)

    def _refresh_servers(self):
        """  """
        from game.store.define import (GF_ClientVer, GF_CurrentSvrId,
                GF_dbPath, GF_dbVer, GF_BUG_URL, GF_RES_URL, GF_NOTICE,
                GF_GAME_URL, GF_ACTIVITY, GF_ClientMinVer, GF_CLI_CURLS,
                GF_PLIST_URL,
                )
        store = model.logon_store
        client_ver = store.get_config(GF_ClientVer)
        params = dict(
                servers = [s.to_dict() for s in store.get_servers()],
                current = store.get_config(GF_CurrentSvrId),
                db_ver = store.get_config(GF_dbVer),
                client_ver = client_ver,
                client_minver = store.get_config(GF_ClientMinVer),
                db_path = store.get_config(GF_dbPath),
                bug_url = store.get_config(GF_BUG_URL),
                res_url = store.get_config(GF_RES_URL),
                notice = store.get_config(GF_NOTICE),
                game_url = store.get_config(GF_GAME_URL),
                activity = store.get_config(GF_ACTIVITY),
                cliUrls = store.get_config(GF_CLI_CURLS),
                PlistUrl = store.get_config(GF_PLIST_URL),
        )

        self._save_servers(client_ver, params)


    def _refresh(self):
        """ 定时刷新 """
        def _refresh_name(name):
            try:
                refresh_func = getattr(self, '_refresh_%s' % name)
                refresh_func()
            except:
                log.log_except()

        while 1:
            for n in self.NAMES:
                _refresh_name(n)
            sleep(config.refresh_time)

    def get_name(self, name):
        name = name.lower()
        value = getattr(self, name, None)
        if value is None:
            return 'Not Found'#web.NotFound(name)
        return value

    def __call__(self, environ, start_response):
        path = environ.get('PATH_INFO', '')
        if path.startswith(self.prefix):
            path = path[self.pre_len:].replace('.', '_')
            fmt = path[path.index('_')+1:]
            headers = getattr(self, '%s_headers' % fmt, None)
            if not headers:
                headers = self.txt_headers
            headers = headers[:]
            start_response('200', headers)
            return [self.get_name(path), ]
        return self.app(environ, start_response)


app = webapp.get_wsgi_app()
app = ConfigMiddlewareEx(app)
app = StaticMiddlewareEx(app)

def module_exists(module_name):
    try:
        __import__(module_name)
    except ImportError:
        return False
    else:
        return True

addr = ('0.0.0.0', config.websvr_port_for_http)
admin_port = getattr(config, 'admin_port', config.websvr_port_for_http - 1)
admin_addr = ('0.0.0.0', admin_port)
web_handler = GWebsvrHandler(addr, app)
main_app = Application(web = web_handler)

origin_sys_argv = None
def modify_sys_argv():
    log.info("Gunicorn Transform!")
    import sys, os
    global origin_sys_argv
    origin_sys_argv = sys.argv
    os.chdir(config.app_path)
    bind_address = '%s:%s' % addr
    sys.argv = ['gunicorn', '-b', bind_address, '-k', 'gevent_pywsgi', '-w',
                '2', 'main:app']

def restore_sys_argv():
    import sys
    sys.argv = origin_sys_argv

def main():
    log.info("Serving on %s:%s", *addr)
    corelib.common.daemon(main_app)

if __name__ == '__main__':
    main()


