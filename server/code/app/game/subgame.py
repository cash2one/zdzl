#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os, sys
import signal
import psutil

import gevent
from grpc import get_proxy_by_addr

from localprocess import LocalProcessMgr

from corelib import spawn, sleep, log, spawn_later
from corelib.common import module_to_dict
from game.base.msg_define import MSG_START
from game import get_union_mgr_funcs, new_logic_game, get_obj, Game, LogicGame

import config

executable = os.environ['executable']
sub_game_cmd = executable + ' subgame %(name)s %(pid)s "%(addr)s"'
sub_go_cmd = '%(path)s %(name)s %(pid)s "%(addr)s"'
# % (os.path.join('.', '..', 'go', 'main')


class LocalApp(object):
    def __init__(self):
        self.objs = {}

    def get_addr(self):
        return None

    def register(self, obj_func):
        """ 注册对象 """
        obj = obj_func()
        self.objs[obj._rpc_name_] = obj
        return obj._rpc_name_

    def get_proxy(self, name):
        return self.objs[name]

    def sub_close(self, close_func):
        pass


class LogicMgr(object):
    """ 游戏逻辑进程管理 """
    def __init__(self, mgr):
        self.mgr = mgr
        self.logics = {}
        self.index = 0
        if 0:
            self.mgr = SubGameMgr()

    def _on_close(self, app):
        if app in self.logics:
            log.info(u'逻辑进程断线,清理该进程数据')
            self._remove_logic(app, app_exist=False)

    def get_subgame_infos(self):
        """ 获取游戏逻辑对象部署情况表 """
        subgames = {}
        for app, game in self.logics.iteritems():
            addr = app.get_addr()
            addr_or_app = addr if not self.mgr.is_single else app
            subgames[game.get_export_id()] = (addr_or_app, )
        return subgames

    def _get_key(self):
        self.index += 1
        return 'logic%d' % self.index

    def start(self):
        pass

    def stop(self):
        log.info(u'主进程stop,关闭逻辑进程')
        for logic_app, (pid, game) in self.logics.items():
            try:
                self._remove_logic(logic_app)
            except:
                log.log_except()

    def _logic_rate(self):
        """ 返回逻辑进程容量比率
        返回:1=100%,容量充足
        0=0%,容量不足
        返回:剩余容量和单服容量的比率
        """
        l = len(self.logics)
        if not l:
            return 0
        try:
            count = Game.rpc_player_mgr.get_count()
        except:
            return 1
        total = l * config.logic_players
        if count >= total:
            return 0
        rate = float(total - count) / config.logic_players
        return rate


    def _increase_logic(self):
        """ 增加 """
        count = len(self.logics)
        if count >= config.max_subgame:
            return
        if count < config.logic_pool:
            for i in xrange(config.logic_pool - count):
                self.new_logic()
        else:
            self.new_logic()

    def _free_logic(self, count):
        """ 检查是否有空余的逻辑进程,释放 """
        for app in self.logics.keys():
            if count <= 0 or len(self.logics) <= config.logic_pool:
                return
            game = app.get_proxy('game')
            if game.get_count() == 0:
                log.info(u'释放空闲的逻辑进程')
                self._remove_logic(app)
                count -= 1

    def new_logic(self):
        """ 新建游戏逻辑进程 """
        log.info(u'新建游戏逻辑进程')
        mgr = self.mgr
        app, pid = mgr._new_subgame(self._get_key())
        name = mgr._app_register(app, new_logic_game)[0]
        game = app.get_proxy(name)
        self.mgr.init_subgame(app)
        game.init()
        game.start()
        self.logics[app] = pid, game
        #注册
        Game.reg_other_game(game, pid)
        log.debug('new_logic:%s, %s', pid, game)
        app.sub_close(self._on_close)
        spawn_later(1, self.mgr._new_game, app, game, pid)
        return app

    def _remove_logic(self, app, app_exist=True):
        pid, game = self.logics.pop(app, None)
        log.debug('remove_logic:%s, %s', pid, game)
        #self.mgr.apps.pop(app, None)
        #反注册
        try:
            if game:
                Game.unreg_other_game(game.get_addr())
        except:
            log.log_except()

        if app_exist:
            game.stop()
            app.stop()
            app.get_service().stop()
        spawn(self.mgr._del_game, app)
        spawn_later(5, self.mgr._del_subgame, pid, app)

    def check(self):
        """ 管理游戏逻辑进程,维持合理的进程数量 """
        #返回:剩余容量和单服容量的比率
        rate = self._logic_rate()
        r = 1.5
        if len(self.logics) < config.logic_pool or rate <= 0.3:
            self._increase_logic()
        elif rate >= r:
            c = int(rate - r) + 1
            self._free_logic(c)

class UnionMgr(object):
    """ 功能进程管理器 """
    _go_name = "golang"
    def __init__(self, mgr):
        self.mgr = mgr
        self.unions = {}
        self.names = {}
        self.union_names = []
        if 0:
            self.mgr = SubGameMgr()

    def start_go(self):
        go_app, go_pid = self.mgr._new_subgame(self._go_name, sub_cmd=sub_go_cmd)
        self.mgr.go_register(go_app, ['rpc_bandword_mgr'])

    def init(self):
        unions = get_union_mgr_funcs().items()
        #unions.sort()
        names = []
        apps = []
        for name, funcs in unions:
            self.names[name] = funcs
            app = self._new_union(name, funcs)
            self.mgr.reg_app_addr(name, app.get_addr())
            apps.append(app)
            names.append(name)
        self.union_names = names
        # start golang
        if 0:
            self.start_go()

        #init_subgames
        log.info('begin init_subgames:%s', names)
        for app in apps:
            self.mgr.init_subgame(app)
        LogicGame.init_subgame(self.mgr.app, self.mgr.app, self.mgr.get_union_infos())
        self.mgr.app.pub(MSG_START)

        #将rpc_client注册
        LogicGame.rpc_client._rpc_name_ = 'rpc_client'
        self.mgr.app.rpc_svr.register(LogicGame.rpc_client)

    def stop(self):
        for n in reversed(self.union_names):
#        for app, (pid, name) in self.unions.items():
            try:
                app = self.get_app(n)
                app.stop()
            except:
                log.log_except()

    def _new_union(self, name, obj_funcs):
        """ 新建联合进程 """
        app, pid = self.mgr._new_subgame(name)
        for obj_func in obj_funcs:
            self.mgr._app_register(app, obj_func)
        app.sub_close(self._on_close)
        self.unions[app] = pid, name
        return app

    def _on_close(self, app):
        pid, name = self.unions.pop(app, (0, ''))
        #重启启动
        if not self.mgr.stoped and name and name in self.names:
            funcs = self.names[name]
            app = self._new_union(name, funcs)
            self.mgr.init_subgame(app)

    def get_app(self, name):
        for app, (pid, app_name) in self.unions.iteritems():
            if app_name != name:
                continue
            return app


class SubGameMgr(object):
    """ 子进程管理类,启动管理子进程 """
    _rpc_name_ = 'subgame_mgr'
    def __init__(self, app):
        self.app = app
        self.apps = {}
        self.names = {}
        self.key_addrs = {}
        #游戏对象部署情况表
        self._subunions = {}
        self.subgame_index = 0
        app.names = self.names
        if hasattr(signal, 'SIGCHLD'):#避免僵尸进程
            signal.signal(signal.SIGCHLD, signal.SIG_IGN)
        if 0:
            import main
            self.app = main.Application()

    @property
    def is_single(self):
        return config.run_type == config.RT_SINGLE

    def reg_app_addr(self, key, addr):
        self.key_addrs[key] = addr

    def _get_addr(self, key):
        if key in self.key_addrs:
            return self.key_addrs[key]
        if self.free_addrs is not None:
            return self.free_addrs.pop(0)
        #linux系统下,使用unix socket
        addr = os.path.join(config.cfg_path, '%s.sock' % key)
        log.info('sub_game addr: %s', addr)
        return addr


    def start(self):
        if config.subgame_addrs:
            self.free_addrs = config.subgame_addrs[:]
        else:
            self.free_addrs = None
        self.proc_mgr = LocalProcessMgr(config.root_path)
        self.logic_mgr = LogicMgr(self)
        self.union_mgr = UnionMgr(self)

        if not self.is_single:
            self._init_normal()
        else:
            self._init_single()

        self.logic_mgr.start()
        self._loop_task = spawn(self._loop)

    @property
    def stoped(self):
        return self.app.stoped

    def stop(self):
        self._loop_task.kill()
        self.logic_mgr.stop()
        self.union_mgr.stop()
        self.proc_mgr.killall()
        self.proc_mgr = None

    def _on_close(self, app):
        if app not in self.apps:
            return
        pid, key, addr, names = self.apps.pop(app)
        log.warn('close app:pid=%s, key=%s, addr=%s', pid, key, addr)
        self.names.pop(key, None)
        if self.free_addrs is not None and key not in self.key_addrs:
            self.free_addrs.append(addr)
        spawn_later(5, self.proc_mgr.kill_process, pid)

    def _new_game(self, new_app, new_game, pid):
        for app in self.apps.keys():
            if app == new_app:
                continue
            app.reg_other_game(new_game, pid, _pickle=True, _no_result=True)

    def _del_game(self, del_app):
        for app in self.apps.keys():
            if app == del_app:
                continue
            app.unreg_other_game(del_app.get_addr(), _no_result=True)

    def _check_apps(self):
        """ 检查进程(游戏逻辑进程和union进程)是否正常 """
        for app, values in self.apps.items():
            pid = values[0]
            if not psutil.pid_exists(pid):
                self._on_close(app)
                self.logic_mgr._on_close(app)
                self.union_mgr._on_close(app)

    def _loop(self):
        """ 管理游戏逻辑进程,维持合理的进程数量 """
        while not self.stoped:
            try:
                self._check_apps()
                self.logic_mgr.check()
            except:
                log.log_except()
            sleep(10)

    def get_apps(self):
        return self.apps.keys()

    def _del_subgame(self, pid, app):
        """ 清除子进程 """
        self._on_close(app)

    def _new_subgame(self, key, sub_cmd=None):
        """ 新建进程 """
        if self.is_single:
            try:
                return self._local_app
            except AttributeError:
                self._local_app = LocalApp()
                self.apps[self._local_app] = [os.getpid(), key, self._local_app.get_addr(), []]
                return self._local_app

        times = 30
        self.subgame_index += 1
        addr = self._get_addr(key)
        kw = dict(name=key, pid=os.getpid(), addr=addr)
        if sub_cmd:
            go_path = os.path.join(config.root_path, 'go', 'main')
            kw.update({"path":go_path})
        if sub_cmd is None:
            sub_cmd = sub_game_cmd
        cmd = sub_cmd % kw
        if os.SUBGAME_DEBUG == key:
            cmd += ' subgame_debug'
            times = 10
        env = None#env存在时,启动有问题 dict(subgame_index=str(self.subgame_index), )
        pid = self.proc_mgr.start_process(cmd, env=env)
        app = None
        for i in xrange(times):
            sleep(0.5)
            app = get_proxy_by_addr(addr, 'app')
            if app:
                break
        if app is None:
            raise SystemError('new subgame error')
        app.sub_close(self._on_close)
        app.init(self, module_to_dict(config), _proxy=True)
        self.apps[app] = [pid, key, addr, []]
        self.names[key] = app
        return app, pid

    def init_subgame(self, sub_app):
        """ 初始化子进程 """
        sub_app.init_subgame(self.app, self.get_union_infos(), _proxy=True)

    def _app_register(self, app, obj_func):
        """ 子进程app，注册对象 """
        obj_names = app.register(obj_func, _pickle=True)
        obj_list = self.apps[app][-1]
        obj_list.extend(obj_names)
        return obj_names

    def go_register(self, app, names):
        self.apps[app][-1].extend(names)

    def get_union_infos(self):
        """ 获取特殊对象部署情况表 """
        if not self._subunions:
            subgames = {}
            for app, (pid, key, addr, names) in self.apps.iteritems():
                if not names:
                    continue
                addr_or_app = addr if not self.is_single else app
                for name in names:
                    namelist = subgames.setdefault(name, [])
                    namelist.append(addr_or_app)
            self._subunions.update(subgames)
        return self._subunions

    def get_obj_by_name(self, name, index=0):
        unions = self.get_union_infos()
        try:
            addr_or_apps = unions[name]
            return get_obj(addr_or_apps[index], name)
        except KeyError:
            return None

    def _init_single(self):
        """ 单进程方式：游戏逻辑进程 """
        self.union_mgr.init()

    def _init_normal(self):
        """ 正常方式：联合进程+逻辑进程 """
        self.union_mgr.init()



#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

