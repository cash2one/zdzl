#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time

from corelib import spawn, sleep, log

from game import Game, pack_msg
from game.base import common
from game.player.player import PlayerData
from game.base.errcode import EC_BOSS_NOTIME
from game.base.constant import (HORN_TYPE_ALLYNOTICE, MAIL_REWARD,
    RW_MAIL_ABOSS, ALLY_BOSS_TIME, BOSS_ALLY_START, BOSS_ALLY_START_V,
    BOSS_ALLY_TIME, BOSS_ALLY_TIME_V,
    )

from .boss import *
import language

class AllyBoss(Boss):
    """ 同盟boss """
    def __init__(self, mgr, adict=None):
        super(AllyBoss, self).__init__(mgr, adict)

    def handle_start_time(self, now_sec):
        """ 根据时间判断是否开启 """
        l_sec = self.data.ct - now_sec
        if l_sec <= 0:
            return
        if l_sec <= self.boss_mgr.fetch_notice_start:
            return l_sec
        return

    def start(self, l_sec):
        """ 开启同盟boss战并初始化数据 """
        max_hp = self._get_max_hp()
        self._init_boss(self.data.aid, l_sec, max_hp)
        #广播boss战斗开始通知
        self.handle_horn(HORN_TYPE_ALLYNOTICE, aid=self.data.aid)
        #广播通知即将开始
        self.notice(l_sec)
        #开启等待数据的广播
        self.loop_task = spawn(self._notice_data, l_sec)

    def new(self, level, aid):
        """ 创建同盟boss数据 """
        need_level = self.boss_mgr.fetch_aboss_level
        if level != need_level:
            return
        start_time = self.fetch_ally_boss_start
        key = (ALLY_BOSS, 51)
        res_boss_level = Game.res_mgr.boss_level_by_keys.get(key)
        if not res_boss_level:
            return
        self.data.aid = aid
        self.data.resblid = res_boss_level.id
        self.data.blid = res_boss_level.id
        self.data.ct = start_time
        self.data.st = int(time.time())
        self.save(Game.rpc_store, forced=True)

    def _notice_data(self, l_sec):
        """ 同盟广播数据 包括boss剩余血量和排名 """
        #log.debug('_a_data %s', l_sec)
        hp_resp_f = 'allyBossHp'
        rank_resp_f = 'allyBossRank'
        hp_time = self.fetch_hp_time
        c = self.fetch_rank_time / hp_time
        sleep(l_sec)
        tmp = 0
        self.is_start = is_win = True
        while not self.stoped:
            sleep(hp_time)
            self.send_msg(hp_resp_f, dict(hp=self.boss_hp))
            if self.boss_hp <= 0:
                break
            if self.boss_start + self.fetch_ally_boss_times < time.time():
                is_win = False
                break
            tmp += 1
            if tmp != c:
                continue
            tmp = 0
            rs, data = self._get_rank()
            if not rs:
                continue
            self.send_msg(rank_resp_f, data)
        self.boss_mgr.ally_boss_clear(self.data.aid)
        if is_win:
            try:
                #发放奖励
                self._reward()
            except:
                log.log_except()
        else:
            self.fail_horn()
        #清楚数据
        self._clear_data()
        #记录数据
        self.save_data(is_win)

    def _reward(self):
        """ 同盟boss战发放奖励并 """
        a_level = Game.rpc_ally_mgr.ally_level_by_aid(self.data.aid)
        pid_levels = PlayerData.get_players_levels(self.pid_hurts.keys())
        for rank, pid in enumerate(self.rank_pids):
            key = (ALLY_BOSS, a_level, rank+1)
            hurt = self.pid_hurts.get(pid)
            rs_items = self._get_reward(key, hurt, pid_levels[pid], a_level)
            #邮件通知玩家
            Game.mail_mgr.send_mails(pid, MAIL_REWARD,
                language.ALLY_BOSS_REWARD, RW_MAIL_ABOSS, rs_items)
        for pid, hurt in self.pid_hurts.iteritems():
            if pid in self.rank_pids:
                continue
            key = (ALLY_BOSS, a_level)
            rs_items = self._get_reward(key, hurt, pid_levels[pid], a_level)
            #邮件通知玩家
            Game.mail_mgr.send_mails(pid, MAIL_REWARD,
                language.ALLY_BOSS_REWARD, RW_MAIL_ABOSS, rs_items)

    def get_week_seconds(self, times=None):
        """ 获取离上周末零点的秒数 """
        if times is not None:
            values = times.split(ALLY_BOSS_TIME)
            values = map(int, values)
            return values[0] * DAY_SEC + values[1] * HOUR_SEC + values[2] * MIN_SEC
        t = time.localtime()
        return t.tm_wday * DAY_SEC + t.tm_hour * HOUR_SEC + t.tm_min * MIN_SEC + t.tm_sec

    def get_strweek_sec(self, sec):
        """ 获取离上周末零点的秒数 """
        week = sec / DAY_SEC
        hour_sec = sec % DAY_SEC
        hour = hour_sec / HOUR_SEC
        min_sec = hour_sec % HOUR_SEC
        min = min_sec / MIN_SEC
        return '%d-%d-%d' % (week, hour, min)

    def handle_week(self):
        """ 处理超过一个星期开启boss """
        week_time = common.week_time(1, zero=1, delta=0)
        if week_time > self.data.st:
            self.data.st = int(time.time())
            self.data.c = 0
            self.save(Game.rpc_store, forced=True)
            return True
        return False

    def set_time(self, times):
        """ 同盟设置开启时间 """
        sec = self.get_week_seconds(times)
        self.handle_week()
        week_time = common.week_time(1, zero=1)
        if not self.data.c and sec < time.time() - week_time:
            return False, EC_BOSS_NOTIME
        self.data.ct = sec
        self.save(Game.rpc_store, forced=True)
        return True, None
    
    def get_time(self, is_enter, is_fight):
        """ 获取同盟开启时间 """
        status = 0
        aid = self.data.aid
        if is_enter and aid in self.boss_mgr.notices:
            status = 1
        if is_fight and (self.data.c or aid in self.boss_mgr.notices):
            status = 1
        return True, (self.get_strweek_sec(self.data.ct), status)
    
    @property
    def fetch_ally_boss_start(self):
        time_str = Game.setting_mgr.setdefault(BOSS_ALLY_START, BOSS_ALLY_START_V)
        sec = self.get_week_seconds(time_str)
        return sec

    @property
    def fetch_ally_boss_times(self):
        return Game.setting_mgr.setdefault(BOSS_ALLY_TIME, BOSS_ALLY_TIME_V)


