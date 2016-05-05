#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys, os
import gevent
import gevent.event
import re

import grpc

import corelib
from corelib import message
from corelib import log, common, spawn, sleep
import config
import game_config

import subgame

def init_config():
    #单服使用范围:base_port ~ base_port + 200(假设max_subgame小于90)
    inet_ip, base_port, max_subgame = config.inet_ip, config.base_port, config.max_subgame
    local_ip = config.local_ip
    lhost = '0.0.0.0'
    config.admin_addr = (lhost, base_port)
    config.player_addr = (lhost, base_port + 1)
    config.web_addr = (lhost, base_port + 2)
    #逻辑进程开放给玩家的端口
    start = 3
    player_ports = config.player_ports = tuple(range(base_port + start,
            base_port + start + max_subgame))
    if sys.platform.startswith('win'):
        config.subgame_addrs = map(lambda port:(local_ip, port),
            xrange(player_ports[-1] + 1, player_ports[-1] + 1 + max_subgame))
    else:
        config.subgame_addrs = False


@message.observable
class Application(common.BaseApp):
    EXTRA_CMDS = []
    _rpc_name_ = 'main_app'
    def __init__(self):
        init_config()
        common.BaseApp.init(self, config)
        self.name = 'main'
        self.stoped = False
        self.restarted = False
        self.rpc_svr = grpc.RpcServer(access=self)
        self._waiter = gevent.event.Event()
        self.admin_addr = config.admin_addr
        self.inet_addr = (config.inet_ip, config.base_port)

    def run(self):
        import game
        game.init(self)
        sys.modules['app'] = self
        self.names = None #subgame names
        self.sub_mgr = subgame.SubGameMgr(self)
        self.sub_mgr.start()
        self.rpc_svr.bind(self.admin_addr)
        self.rpc_svr.register(self)
        self.rpc_svr.start()

        self._init_web()
        self.web_svr.start()
        log.info('app started')
        while 1:
            try:
                self._waiter.wait()
                break
            except KeyboardInterrupt:
                log.info('app stoped:KeyboardInterrupt')
            except SystemExit:
                log.info('app stoped:SystemExit')
            except:
                log.log_except()
                break
            log.info('spawn app stop')
            spawn(self.stop)
            sleep(0.2)
        cmd = ' '.join(map(str, [sys.executable,] + sys.argv))
        log.info('*****app(%s) stoped', cmd)
        self.stop()

        #守护进程方式,重启服务
        if self.restarted and hasattr(self, 'daemon_runner'):
            self.daemon_runner.domain_restart()

    def _init_web(self):
        from gevent import pywsgi
        from corelib import Http10WSGIHandler
        import webapp
        web_addr = config.web_addr
        self.wsgi_app = webapp.get_wsgi_app()
        self.web_svr = pywsgi.WSGIServer(web_addr,
                self.wsgi_app, log=log if config.debug else None,
                handler_class=Http10WSGIHandler)
        self.web_svr.reuse_addr = 1
        log.info('game web:%s', web_addr)

    def access_sock(self, sock, addr):
        """ 校验是否允许rpc """
        from game import Game
        from game.store.define import GF_ACCESS_IP
        s = Game.rpc_res_store.get_config(GF_ACCESS_IP)
        if not s:
            return True
        access_ip_re = re.compile(s)
        return access_ip_re.match(addr[0]) is not None

    def access_shell(self, proxy):
        """ 是否允许启动shell """
        return True

    def shell_get(self, proxy_name):
        return self.names.get(proxy_name, None)

    def stop(self):
        if self.stoped:
            return
        self.stoped = True
        log.warn(u'管理进程开始退出')
        try:
            self.sub_mgr.stop()
            self.rpc_svr.stop()
            self.web_svr.stop()
        except:
            log.log_except()
        finally:
            self._waiter.set()

    def restart(self, m, msg=None):
        """ 过min分钟后,自动重启, """
        spawn(self._restart, m, msg)

    def app_stop(self, m, msg=None):
        """ 过min分钟后,自动重启, """
        spawn(self._restart, m, msg, restart=False)

    def _restart(self, m, msg, restart=True):
        if restart:
            amsg = u'重启'
        else:
            amsg = u'关闭维护'
        if msg is None:
            msg = u'服务器将在%%(min)s分钟后%s, 谢谢!' % amsg
        from game import Game
        m = int(m)
        #广播
        while m > 0:
            if m <= 5 or (m % 10 == 0):
                s = msg % dict(min=m)
                Game.chat_mgr.bugle(s)
                log.info(s)
            sleep(60)
            m -= 1
        #重启
        Game.chat_mgr.bugle(u'服务器%s, 谢谢!' % amsg)
        sleep(1)
        self.restarted = restart
        self._waiter.set()

    def _init_db_(app):
        """ 清除用户数据库 """
        from game import Game
        from game.store.define import TN_PLAYER
        store = Game.rpc_store
        c = store.count(TN_PLAYER, {})
        if c > 100:
            raise ValueError('players to much(%d > 100)', c)
        store.initdb()
        Game.rpc_logger_svr.initdb()



def main():
    app = Application()
    corelib.common.daemon(app)

if __name__ == '__main__':
    main()
