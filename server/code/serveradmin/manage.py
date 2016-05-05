#!/usr/bin/env python
#coding=utf-8
__author__ = 'kainwu'

from corelib import log

from luffy import create_app
from luffy.models import AdminUser
from gevent.pywsgi import WSGIServer
from flask.ext.script import Manager
import sys, config as game_config

app = create_app()
manager = Manager(app)

@manager.command
def start(port):
    """ gevent WSGIServer启动服务器 """
    log.info('start:%s', game_config.SERVER_VER_CONFIG)
    WSGIServer(('0.0.0.0', int(port)), app).serve_forever()

@manager.command
def run(port):
    """ 启动测试debug=True """
    app.run(host='0.0.0.0', port=port, debug=True)

@manager.command
def admin(email):
    """ 设置用户为管理员 """
    u = AdminUser.query.filter(AdminUser.username == email).first()
    if u is None:
        print 'error user_name'
    else:
        u.role = AdminUser.ADMIN
        u.save()
        print 'success set admin'

@manager.command
def moderator(email):
    """ 设置用户帐号为moderator """
    u = AdminUser.query.filter(AdminUser.username == email).first()
    if u is None:
        print 'error user_name'
    else:
        u.role = AdminUser.MODERATOR
        u.save()
        print 'success set moderator'



    
if __name__ == '__main__':
    manager.run()
