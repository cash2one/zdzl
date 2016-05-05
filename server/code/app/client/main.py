#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys
import locale

import config

from corelib import client_rpc, log, json
from corelib.common import import1


encoding = locale.getdefaultlocale()[1]
if encoding is None:
    encoding = 'UTF-8'


def main():
    if '-h' in sys.argv:
        print u"""
游戏模拟,格式:
    python main.py client <script_name> arg1 arg2 arg3 ...
举例:
    python main.py client main 127.0.0.1 8002

        """.decode('utf-8').encode(encoding)
        sys.exit(0)

    #处理压缩、解压问题
    #client_rpc.JsonPacker.ZIP, client_rpc.JsonUnPacker.UNZIP = 1, 1

    #处理压缩、解压问题
    #client_rpc.JsonPacker.ZIP, client_rpc.JsonUnPacker.UNZIP = 1, 1
    if '-w' in sys.argv:
        test = Web()
        test.run()

    from corelib import log
    log.console_config(True)
    log.debug(sys.argv)
    index = 1
    script_name = sys.argv[index]
    args = sys.argv[index + 1:]
    md = 'client.scripts.%s' % script_name
    script = import1(md)
    script(*args)



class Web():

    def run(self):
        self._init_web()
        self.web_svr.serve_forever()

    def _init_web(self):
        from gevent import pywsgi
        web_addr = config.over_login_web_addr
        self.wsgi_app = get_wsgi_app()
        self.web_svr = pywsgi.WSGIServer(web_addr,
            self.wsgi_app, log=log if config.debug else None)
        self.web_svr.reuse_addr = 1
        log.info('client game web:%s', web_addr)


import web
web.config['debug'] = False #disable autoreload
app = web.auto_application()

game_url = '/api/game'

ids = range(1, config.over_login_player_nums, 1)

class TestLogin(app.page):
    """ 测试服务器登陆压力 """
    path = '%s/%s' % (game_url, 'testLogin')

    def GET(self):
        from client.scripts.script1 import over_login_test
        name_id = ids.pop(0)
        try:
            rs = over_login_test(name_id, config.over_login_ip, config.over_login_port)
            if rs:
                msg = 'ok %s'% name_id
            else:
                msg = 'err %s'% name_id
            data = json.dumps({'rs':msg})
            return data
        except:
            log.log_except()
            raise
        finally:
            ids.append(name_id)

def get_wsgi_app(*middleware):
    return app.wsgifunc(*middleware)

if __name__ == '__main__':
    main()
