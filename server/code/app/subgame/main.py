#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys, os
import weakref
import gevent
import gevent.event
import grpc

from corelib import spawn, spawn_later, sleep, common, message, Timeout
from game.base.msg_define import MSG_START

import config
from corelib import log

SUB_LOGIC = 1
SUB_UNION = 2

@message.observable
class Application(object):
    _rpc_name_ = 'app'
    def __init__(self, name, pid, addr):
        # channel服务的ip和端口
        self.name = name
        self.addr = addr
        self.pid = pid #父进程id
        self.parent = None
        sys.modules['app'] = self
        self.names = {}#weakref.WeakValueDictionary()
        self.stoped = False

    def start(self):
        self.stoped = False
        self.svr = grpc.RpcServer()
        self.svr.bind(self.addr)
        self.svr.register(self)
        self.svr.start()

        # 用来阻塞住主协程
        self._waiter = gevent.event.Event()
        self._waiter_stoped = gevent.event.Event()
        try:
            while 1:
                #检查父进程是否已经关闭
                if not self._exist_pid():
                    self._wait_game_stop()
                    log.warn(u'主进程(%s)已经退出,子进程(%s)将自动关闭', self.pid, os.getpid())
                    os.environ['PARENT_STOPED'] = '1'
                    break
                try:
                    if self._waiter.wait(2):
                        break
                except KeyboardInterrupt:
                    pass
        except Exception as e:
            log.info('subgame app error:%s', e)
        try:
            self._stop()
        finally:
            self._waiter_stoped.set()
        sleep(2)
        self._svr_stop()
        sleep(0.5)


    def _svr_stop(self):
        if not self._exist_pid():
            self.svr.close()
        else:
            self.svr.stop()
        grpc.uninit()
        log.info('grpc.uninit(%s)', self.name)

    def _wait_game_stop(self):
        """ 功能进程,需等待逻辑进程全部关闭 """
        from game import Game
        if Game.instance is not None:
            return
        with Timeout.start_new(60*1):
            while 1:
                if not len(Game.valid_games()):
                    break
                sleep(0.2)

    def _stop(self):
        if self.stoped:
            return
        self.stoped = True
        log.info('subgame app(%s) stoped:%s', self.name, self.names.keys())
        for obj in self.names.values():
            if hasattr(obj, 'stop'):
                try:
                    obj.stop()
                except:
                    log.log_except('stop(%s) error', obj)

    def stop(self):
        """ 主进程通知子进程关闭 """
        self._waiter.set()
        self._waiter_stoped.wait()

    def init(self, parent, config_dict):
        """ 初始化:parent是父进程的proxy """
        import game
        self.parent = parent
        config.__dict__.update(config_dict)
        common.update_config(config)
        game.init(self)


    def register(self, obj_func):
        """ 注册对象 """
        objs = obj_func()
        return self.reg_objs(objs)

    def reg_objs(self, objs):
        if not isinstance(objs, (tuple, list)):
            objs = (objs, )
        names = []
        for obj in objs:
            name = self.reg_obj(obj)
            names.append(name)
        return names

    def reg_obj(self, obj):
        name = self.svr.register(obj)
        self.names[name] = obj
        log.info('[subgame]register:%s', name)
        return name

    def get_addr(self):
        return self.svr.addr

    def execute(self, cmd):
        exec cmd

    def _exist_pid(self):
        """ 检查主进程是否存在,不存在的情况下自动退出 """
        import psutil
        return psutil.pid_exists(self.pid)


    def init_subgame(self, main_app, subgames, _proxy=True):
        """ 根据联合进程情况，初始化模块 """
        from game import LogicGame
        LogicGame.init_subgame(self, main_app, subgames)
        #初始化完成,抛出开始消息
        self.pub(MSG_START)

    def reg_other_game(self, rpc_game, process_id, _pickle=True, _no_result=True):
        """ 注册其它进程的game对象 """
        from game import Game
        Game.reg_other_game(rpc_game, process_id)

    def unreg_other_game(self, game_addr, _no_result=True):
        """ 反注册其它进程的game对象 """
        from game import Game
        Game.unreg_other_game(game_addr)


def main():
    #assert len(sys.argv) == 3
    log.info('[subgame] start:%s', sys.argv)
    app_name = sys.argv[-3]
    pid = int(sys.argv[-2])
    addr = sys.argv[-1]
    if '(' in sys.argv[-1]:
        addr = eval(addr)
    app = Application(app_name, pid, addr)
    app.start()

if __name__ == '__main__':
    main()

