#!/usr/bin/env python
# -*- coding:utf-8 -*-

import copy

from corelib import spawn, sleep

from .war import War
from game import Game, pack_msg
from game.base import common, errcode
from game.base.constant import (ALLY_SKY_WAR, ALLY_WAR_FAIL_TIME,
    ALLY_WAR_WIN
)

from .war import PlayerWarData

class WarSky(War):
    """ 守龙战 """
    def __init__(self):
        super(WarSky, self).__init__()

    def reconnection(self, pid):
        """ 掉线重连进入 广播数据 """
        if self.war_data.war_end:
            return False, errcode.EC_ALLY_WAR_END
        resp_f = 'awarStartB'
        if pid not in self.war_data.war_pids:
            self.war_data.war_pids.append(pid)
        data = self.get_data(pid)
        data.update(dict(asid=self.room.res_warstart_config.id))
        self.send_msg(resp_f, data, send_pids=[pid])
        return True, None

    def start(self, room, pid, data=None):
        """ 开战 """
        self.room = room
        key = (ALLY_SKY_WAR, 1)
        res_config = Game.res_mgr.awar_per_configs_bykeys.get(key)
        if res_config is None:
            return False, errcode.EC_NORES
        self.war_per_config = res_config
        #初始化战斗数据
        rs, data = self.data_init()
        if rs is False:
            return rs, data
        self.start_broad(pid)
        return True, None

    def start_broad(self, pid=0):
        """ 开战或和进入下一场广播 """
        resp_f = 'awarStartB'
        self.war_data.start()
        self._loop_task_broad = spawn(self._loop_broad)
        for pid in self.war_data.war_pids:
            data = self.get_data(pid)
            data.update(dict(asid=self.room.res_warstart_config.id))
            self.send_msg(resp_f, data, send_pids=[pid])
        if self.war_per_config.hurts:
            spawn(self.boss_hurt_boat)
        spawn(self._loop_war)

    def _loop_war(self):
        """ 开战计时 """
        while 1:
            now_time = common.current_time()
            use_time = now_time - self.war_data.stime
            if use_time > self.war_per_config.wtime + self.boat.gtime:
                self.war_result_borad(ALLY_WAR_FAIL_TIME)
                break
            sleep(1)
    
    def boss_hurt_boat(self):
        """ boss袭击天舟 """
        sc, hurt = common.str2list(self.war_per_config.hurts, vtype=str)
        sc = int(sc)
        n = 1
        sleep(sc)
        while self.war_data.boss_hp > 0 and not self.war_data.war_end:
            boss_data = eval(hurt)
            n += 1
            self.boat.hard -= boss_data
            if self.boat.hard < 0:
                self.boat.hard = 0
            self.boat.hard_broad(boss_data=boss_data)
            sleep(sc)

    def pass_scene(self, aid):
        """ 通过本场 """
        if self.war_data.war_end:
            return
        self.enter_next_scene()

    def enter_next_scene(self):
        """ 进入下一场 """
        self.next_scene_data_init()

    def war_finish(self, reward_item=None):
        """ 通关 """
        if reward_item:
            preward_items = copy.copy(reward_item)
            for cpid in self.war_data.war_pids:
                p_data = self.pid2pdata.get(cpid)
                p_data.rbox = preward_items
        self.war_result_borad(ALLY_WAR_WIN)
