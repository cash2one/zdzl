#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time

from corelib import spawn, sleep, log
from corelib.message import observable

from game import Game
from game.base import common
from game.store import TN_BOSS
from game.base.msg_define import (MSG_START, MSG_LOGON, MSG_LOGOUT, MSG_ALLY_UP)
from game.base.errcode import (EC_BOSS_NOALLY, EC_BOSS_NOSTART, )
from game.base.constant import (BOSS_NOTICE_START, BOSS_NOTICE_START_V,
        BOSS_ALLY_LEVEL, BOSS_ALLY_LEVEL_V, HORN_TYPE_WORLDBOSSHP,
        BOSS_START_TIME_V, BOSS_ENTER_LEVEL, BOSS_START_TIME,
        BOSS_ENTER_LEVEL_V, HORN_TYPE_ALLYBOSSHP,
)
from .boss import *
from .world_boss import WorldBoss
from .ally_boss import AllyBoss


def wrap_ally_data(func):
    """ 通过pid获取同盟boss对象 """
    def _func(self, pid, *args, **kw):
        aid = Game.rpc_ally_mgr.get_aid_by_pid(pid)
        if not aid:
            return False, EC_BOSS_NOALLY
        if aid not in self.notices:
            return False, EC_BOSS_NOSTART
        boss_id = self.a_bosses.get(aid)
        boss = self.bosses.get(boss_id)
        kw['boss'] = boss
        return func(self, pid, *args, **kw)
    return _func

def wrap_boss_data(func):
    """ 通过同盟id获取同盟boss对象 """
    def _func(self, aid, *args, **kw):
        boss_id = self.a_bosses.get(aid)
        if not boss_id:
            return False, EC_BOSS_NOSTART
        kw['boss'] = self.bosses.get(boss_id)
        return func(self, aid, *args, **kw)
    return _func

def wrap_world_data(func):
    """ 获取世界boss对象 """
    def _func(self, *args, **kw):
        if not self.w_start_boss:
            return False, EC_BOSS_NOSTART
        kw['boss'] = self.w_start_boss
        return func(self, *args, **kw)
    return _func

def logon_by_boss(pid):
    #log.info('logon_by_boss:%s', pid)
    online, player_infos = Game.rpc_player_mgr.get_player_infos([pid])
    player_info = player_infos[pid]
    if player_info[2] >= Game.rpc_boss_mgr.fetch_boss_uplevel:
        spawn(Game.rpc_boss_mgr.player_logon, pid)

def logout_by_boss(pid):
    #log.info('logout_by_boss:%s', pid)
    spawn(Game.rpc_boss_mgr.player_logout, pid)

def ally_up(aid, level):
    """ 同盟升级 """
    log.info('ally_up :%s, %s', aid, level)
    spawn(Game.rpc_boss_mgr.new_ally_boss, aid, level)

def ally_close():
    """ 同盟解散 """
    pass


@observable
class BossMgr(object):
    """ boss战管理系统 """
    _rpc_name_ = 'rpc_boss_mgr'
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        self._loop_task = None
        self._game = Game

        #{boss表id1:boss表对象1, ...}包括同盟和世界boss战
        self.bosses = {}

        #同盟boss保存 {同盟id1:boss表id1, ...}
        self.a_bosses = {}
        #世界boss保存 {resblid:boss表id1, ...}
        self.w_bosses = {}

        #boss开启提前广播列表[同盟id1, ...]
        self.notices = []

        #当前开启的世界boss战(包括通知的时间)
        self.w_start_boss = None

        #广播世界boss剩余血量的条件
        self.w_horn_conds = []

        #广播同盟boss剩余血量的条件
        self.a_horn_conds = []

        import app
        app.sub(MSG_START, self.start)

    def get_boss(self, index):
        """ 通过index获取选中的世界boss返回其boss对象 """
        res_starts = self.fetch_start_time
        res = res_starts.keys()
        res.sort()
        res_blid = res_starts.get(res[index])
        boss_id = self.w_bosses.get(res_blid)
        if boss_id:
            return self.bosses.get(boss_id)
        else:
            return self._new_world_boss(res_blid)

    def set_boss_level(self, level, index):
        """ 设置世界boss等级 """
        w_boss = self.get_boss(index)
        w_boss.gm_set_level(level)

    def set_world_start(self, index=0, delay_time=300):
        """ gm使用开始世界boss战斗 """
        #停止当前的boss
        if self.w_start_boss:
            self.w_start_boss.stop(WORLD_BOSS)
        #开启下一场boss战
        w_boss = self.get_boss(index)
        w_boss.start(delay_time)
        w_boss.set_start_type(index)
        self.w_start_boss = w_boss

    def set_ally_start(self, aid, delay_time=300):
        """ gm设置同盟boss开启 """
        boss_id = self.a_bosses.get(aid)
        #停止当前的boss
        a_boss = self.bosses.get(boss_id)
        if not a_boss:
            return False
        if aid in self.notices:
            a_boss.stop(ALLY_BOSS)
        #开启
        a_boss.start(delay_time)
        self.notices.append(aid)
        return True

    def kill_boss(self, pid, name, hurts, aid=0):
        """ 秒杀boss aid=0 世界 aid!=0同盟"""
        if aid:
            boss_id = self.a_bosses.get(aid)
            a_boss = self.bosses.get(boss_id)
            if not a_boss:
                return False
            a_boss.one_finish(pid, name, hurts, is_cd=False)
            return True
        if not self.w_start_boss:
            return True
        rs = self.w_start_boss.one_finish(pid, name, hurts, is_cd=False)
        log.debug('kill_boss=rs----- %s', rs)
        return True

    def start(self):
        self._game.rpc_player_mgr.rpc_sub(logon_by_boss, MSG_LOGON, _proxy=True)
        self._game.rpc_player_mgr.rpc_sub(logout_by_boss, MSG_LOGOUT, _proxy=True)
        self._game.rpc_ally_mgr.rpc_sub(ally_up, MSG_ALLY_UP, _proxy=True)
        self.load()
        self._loop_task_ally = spawn(self._a_boss)
        self._loop_task_world = spawn(self._w_boos)

    def get_horn_conds(self, aid):
        """ 获取boos血量广播条件 """
        if not aid:
            if not self.w_horn_conds:
                self.w_horn_conds = self._game.rpc_horn_mgr.get_conds(HORN_TYPE_WORLDBOSSHP)
                self.w_horn_conds.sort(reverse=True)
            return self.w_horn_conds
        else:
            if not self.a_horn_conds:
                self.a_horn_conds = self._game.rpc_horn_mgr.get_conds(HORN_TYPE_ALLYBOSSHP)
                self.a_horn_conds.sort(reverse=True)
            return self.a_horn_conds
    @property
    def fetch_boss_uplevel(self):
        """ 获取boss解锁等级 """
        return Game.setting_mgr.setdefault(BOSS_ENTER_LEVEL, BOSS_ENTER_LEVEL_V)

    def player_logon(self, pid):
        """ 玩家登陆，检测boss战是否已开启 并广播 """
        sleep(10)
        if self.w_start_boss:
            self.w_start_boss.p_logon(pids=[pid])
        aid = Game.rpc_ally_mgr.get_aid_by_pid(pid)
        if aid and aid in self.notices:
            boss_id = self.a_bosses.get(aid)
            a_boss = self.bosses.get(boss_id)
            a_boss.p_logon(pids=[pid])

    def player_logout(self, pid):
        """ 玩家登出，退出boss场景 """
        if self.w_start_boss:
            self.w_start_boss.p_logout(pid=pid)
        aid = Game.rpc_ally_mgr.get_aid_by_pid(pid)
        if aid and aid in self.notices:
            boss_id = self.a_bosses.get(aid)
            a_boss = self.bosses.get(boss_id)
            a_boss.p_logout(pid=pid)

    def load(self):
        """ 加载boss战数据 """
        all_boss = Game.rpc_store.query_loads(TN_BOSS, {})
        res_starts = self.fetch_start_time
        for boss in all_boss:
            if boss['aid'] == AID_WORLD_BOSS:
                #根据setting表初始化boss数据
                res_starts_copy = res_starts.copy()
                is_init_boss = False
                for k, v in res_starts_copy.iteritems():
                    if v == boss['resblid']:
                        res_starts.pop(k)
                        is_init_boss = True
                if not is_init_boss:
                    continue
                oBoss = WorldBoss(self, boss)
                self.w_bosses[oBoss.data.resblid] = oBoss.data.id
            else:
                oBoss = AllyBoss(self, boss)
                self.a_bosses[oBoss.data.aid] = oBoss.data.id
            self.bosses[oBoss.data.id] = oBoss
            #创建世界boss
        if res_starts:
            #数据库中无资源指定的boss重新加入新boss
            self.new_world_bosses(res_starts)

    def new_world_bosses(self, res_starts):
        """ 添加世界boss """
        add_blids = []
        #同一个怪物id只加入一条
        for start_sec, res_blid in res_starts.iteritems():
            if res_blid in add_blids:
                continue
            add_blids.append(res_blid)
            self._new_world_boss(res_blid)

    def _new_world_boss(self, res_blid):
        """ 添加setting表指定的世界boss """
        oBoss = WorldBoss(self)
        oBoss.new(res_blid)
        self.w_bosses[res_blid] = oBoss.data.id
        self.bosses[oBoss.data.id] = oBoss
        return oBoss

    def new_ally_boss(self, aid, level):
        """ 添加同盟boss """
        if level != self.fetch_aboss_level:
            return
        oBoss = AllyBoss(self)
        oBoss.new(level, aid)
        self.bosses[oBoss.data.id] = oBoss
        self.a_bosses[aid] = oBoss.data.id

    def _a_boss(self):
        """ 同盟boss开启提前广播(判断时间是否到达) """
        while 1:
            now_sec = self.get_week_seconds
            for aid, a_boss_id in self.a_bosses.iteritems():
                if not a_boss_id or aid in self.notices:
                    continue
                a_boss = self.bosses.get(a_boss_id)
                if not a_boss or a_boss.is_start:
                    continue
                a_boss.handle_week()
                if a_boss.data.c > 0:
                    continue
                l_sec = a_boss.handle_start_time(now_sec)
                if l_sec:
                    a_boss.start(l_sec)
                    self.notices.append(aid)
            sleep(1)

    def _w_boos(self):
        """ 世界boos开启提前广播(判断时间是否到达) """
        res_starts = self.fetch_start_time
        while 1:
            min_sec = 0
            common.current_time()
            now_sec = self.get_today_seconds
            time_keys = res_starts.keys()
            time_keys.sort()
            for start_sec, res_blid in res_starts.iteritems():
                if self.w_start_boss:
                    continue
                boss_id = self.w_bosses[res_blid]
                #setting表的改动后建立新的boss数据
                if boss_id:
                    w_boss = self.bosses.get(boss_id)
                else:
                    w_boss = self._new_world_boss(res_blid)
                l_sec = start_sec - now_sec
                rs, data = w_boss.handle_start_time(l_sec, min_sec)
                w_boss.set_start_type(time_keys.index(start_sec))
                if rs:
                    w_boss.start(data)
                    self.w_start_boss = w_boss
                else:
                    min_sec = data
            #还有多久通知min_sec
            if min_sec <= 0:
                min_sec = self.fetch_notice_start
            sleep(min_sec)
   
    def ally_boss_clear(self, aid):
        """ 同盟boss结束 去除通知 """
        if aid in self.notices:
            self.notices.remove(aid)
    
    def world_boss_clear(self):
        """ 当前世界boss战结束 """
        self.w_start_boss = None

    @property
    def fetch_aboss_level(self):
        """ 获取同盟战开启的同盟等级 """
        return Game.setting_mgr.setdefault(BOSS_ALLY_LEVEL, BOSS_ALLY_LEVEL_V)

    @wrap_world_data
    def world_boss_enter(self, pid, boss=None):
        """ 进入世界boss战的场景 """
        return boss.enter(pid)

    @wrap_world_data
    def is_start_world_boss(self, pid, boss=None):
        """ 世界boss战是否开启 """
        return True, None

    @wrap_ally_data
    def ally_boss_enter(self, pid, boss=None):
        """ 进入同盟boss战的场景 """
        return boss.enter(pid)

    @wrap_ally_data
    def is_start_ally_boss(self, pid, boss=None):
        """ 同盟boss战斗是否开始 """
        if not boss.is_start:
            return False, EC_BOSS_NOSTART
        return True, None

    @wrap_world_data
    def world_boss_exit(self, pid, boss=None):
        """ 退出世界boss战的场景 """
        return boss.exit(pid)

    @wrap_world_data
    def world_cd_time(self, pid, boss=None):
        return boss.cd_times(pid)

    @wrap_world_data
    def world_cd_coin2(self, pid, boss=None):
        """ 获取取消cd时间所要扣的元宝数 """
        return boss.cd_end_coin2(pid)

    @wrap_world_data
    def world_cd_clear(self, pid, boss=None):
        return boss.cd_end_clear(pid)

    @wrap_ally_data
    def ally_boss_exit(self, pid, boss=None):
        """ 退出同盟boss战的场景 """
        return boss.exit(pid)

    @wrap_world_data
    def world_boss_start(self, pid, boss=None):
        """ 单场世界boss战开始 """
        return boss.one_start(pid)

    @wrap_ally_data
    def ally_cd_coin2(self, pid, boss=None):
        """ 获取取消cd时间所要扣的元宝数 """
        return boss.cd_end_coin2(pid)

    @wrap_ally_data
    def ally_cd_clear(self, pid, boss=None):
        return boss.cd_end_clear(pid)

    @wrap_ally_data
    def ally_cd_time(self, pid, boss=None):
        """ 获取同盟bosscd时间 """
        return boss.cd_times(pid)

    @wrap_ally_data
    def ally_boss_start(self, pid, boss=None):
        """ 单场同盟boss战开始 """
        return boss.one_start(pid)

    @wrap_world_data
    def world_boss_finish(self, pid, name, hurt, check_data, boss=None):
        """ 单场世界boss战结束 """
        return boss.one_finish(pid, name, hurt, check_data)

    @wrap_world_data
    def boss_add_buff(self, pid, boss=None):
        """ 世界bos添加buff """
        return boss.add_buff(pid)

    @wrap_ally_data
    def ally_boss_finish(self, pid, name, hurt, boss=None):
        """ 本次同盟boss战结束 """
        return boss.one_finish(pid, name, hurt)

    @wrap_boss_data
    def ally_boss_set_time(self, aid, times, boss=None):
        """ 同盟设置boss开启时间 """
        return boss.set_time(times)

    @wrap_boss_data
    def ally_boss_get_time(self, aid, boss=None, is_enter=False, is_fight=False):
        """ 获取boss同盟开启时间 """
        return boss.get_time(is_enter=is_enter, is_fight=is_fight)

    @property
    def get_today_seconds(self):
        """ 获取当前时间离零点的秒数 """
        t = time.localtime()
        return t.tm_hour * HOUR_SEC + t.tm_min * MIN_SEC + t.tm_sec

    @property
    def get_week_seconds(self):
        """ 获取离上周末零点的秒数 """
        t = time.localtime()
        return (t.tm_wday+1) * DAY_SEC + t.tm_hour * HOUR_SEC + t.tm_min * MIN_SEC + t.tm_sec

    @property
    def fetch_notice_start(self):
        """ 获取boss开启通知时间 """
        return Game.setting_mgr.setdefault(BOSS_NOTICE_START, BOSS_NOTICE_START_V)

    @property
    def fetch_start_time(self):
        v = Game.setting_mgr.setdefault(BOSS_START_TIME, BOSS_START_TIME_V)
        values = v.split('|')
        rs = {}
        for value in values:
            value = value.split(':')
            value = map(int, value)
            rs[value[0]] = value[1]
        return rs

def new_boss_mgr():
    mgr = BossMgr()
    return mgr