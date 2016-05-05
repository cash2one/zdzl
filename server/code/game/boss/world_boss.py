#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time, math

from corelib import spawn, sleep, log

from game import Game, pack_msg
from game.glog.common import PL_WORLD_BOSS
from game.store.define import TN_PLAYER, TN_P_MAIL
from game.player.player import PlayerData
from game.base.msg_define import (MSG_REWARD_WORLDBOSS,
    MSG_REWARD_WORLDITEMS, MSG_WBOSS_RANK)
from game.base.errcode import EC_VALUE
from game.base.constant import (BOSS_START_TIME_V, BOSS_START_TIME,
        IT_CAR_STR, BOSS_TIME, BOSS_TIME_V, MAIL_REWARD, RW_MAIL_BOSS,
        BOSS_REWARD_VIP, BOSS_REWARD_VIP_V, CHATER_START, RW_MAIL_BOSSVIP,
        HORN_TYPE_WORLDNOTICE,
        )
from .boss import *

class WorldBoss(Boss):
    """ 世界boss """
    def __init__(self, mgr, adict=None):
        super(WorldBoss, self).__init__(mgr, adict)
        self.start_type = 0
        self.pid_check_hurts = {}  # {pid1:check_hurts, ...}

    def handle_start_time(self, l_sec, min_sec):
        """ 根据时间判断是否开启 """
        if l_sec <= 0:
            return False, min_sec
        if l_sec <= self.boss_mgr.fetch_notice_start:
            return True, l_sec
        else:
            seconds = l_sec - self.boss_mgr.fetch_notice_start
            if not min_sec or seconds < min_sec:
                min_sec = seconds
        return False, min_sec

    def set_start_type(self, ty):
        self.start_type = ty

    def start(self, l_sec):
        """ 开启boss战并初始化数据 """
        self.init()
        max_hp = self._get_max_hp()
        self._init_boss(AID_WORLD_BOSS, l_sec, max_hp)
        #大喇叭广播boss战斗开始通知
        self.handle_horn(HORN_TYPE_WORLDNOTICE)
        #广播通知即将开始
        self.notice(l_sec)
        #开启等待数据的广播
        self.loop_task = spawn(self._notice_data, l_sec)

    def gm_set_level(self, level):
        """ gm设置世界boss等级 """
        res_boss_level = Game.res_mgr.boss_level.get(self.data.blid)
        key = (res_boss_level.mid, level)
        res_boss_level_up = Game.res_mgr.boss_level_by_midlevel.get(key)
        self.data.blid = res_boss_level_up.id
        self.data.deads = 0

    def new(self, res_blid):
        """ 创建boss数据 """
        self.data.resblid = res_blid
        self.data.blid = res_blid
        self.data.st = int(time.time())
        self.data.aid = AID_WORLD_BOSS
        self.save(Game.rpc_store, forced=True)

    def _notice_data(self, l_sec):
        """ 广播数据 包括世界boss剩余血量和排名 """
        hp_resp_f = 'bossHp'
        rank_resp_f = 'bossRank'
        hp_time = self.fetch_hp_time
        c = self.fetch_rank_time / hp_time
        sleep(l_sec)
        tmp = 0
        self.is_start = is_win =True
        while not self.stoped:
            sleep(hp_time)
            self.send_msg(hp_resp_f, dict(hp=self.boss_hp, mhp=self.max_hp))
            if self.boss_hp <= 0:
                break
            if self.boss_start + self.fetch_world_boss_times < time.time():
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
        self.boss_mgr.world_boss_clear()
        #更改为不管怪物是否死都发奖励
        try:
            #发放奖励
            self._reward()
            #vip不参加也发奖励
            self._reward_vip()
        except:
            log.log_except()
        if not is_win:
            self.fail_horn()
        #写入log 记录伤害
        self._log_info()
        #清楚数据
        self._clear_data()
        #记录数据
        self.save_data(is_win)

    def _log_info(self):
        """ 记录玩家在该场boss中的伤害值 """
        for pid, hurts in self.pid_hurts.iteritems():
            Game.glog.log(dict(p=pid, t=PL_WORLD_BOSS, d=dict(hurts=hurts)))

    def _reward_vip(self):
        """ 达到vip等级后不参与世界boss发奖励 """
        vip = self.fetch_reward_vip
        querys = dict(vip={"$gte":vip}, level={"$gte":self.fetch_boss_uplevel}, chapter={"$gt":CHATER_START})
        players = Game.rpc_store.query_loads(TN_PLAYER, querys)
        #获取奖励
        rid = Game.res_mgr.boss_reward_by_keys.get((WORLD_BOSS,0))
        rw = Game.reward_mgr.get(rid)
        join_boss_pids = self.pid_hurts.keys()

        for player in players:
            pid = player['id']
            if pid in join_boss_pids:
                continue
            mail_querys = dict(pid=pid, t=MAIL_REWARD, content=str(RW_MAIL_BOSSVIP))
            mails = Game.rpc_store.query_loads(TN_P_MAIL, mail_querys)
            if len(mails):
                continue
            items = rw.reward(dict(level=player['level'], hurt=0))
            rs_items = []
            for item in items:
                if not item[IT_CAR_STR]:
                    continue
                rs_items.append(item)
                #发送邮件
            res_rw_mail = Game.res_mgr.reward_mails.get(RW_MAIL_BOSSVIP)
            content = res_rw_mail.content % dict(rank=0)
            Game.mail_mgr.send_mails(pid, MAIL_REWARD,
                res_rw_mail.title, RW_MAIL_BOSSVIP, rs_items, param=content)

    def _reward(self):
        """ 世界boss战发放奖励并 """
        rank_data = sorted(self.pid_hurts.iteritems(), key=lambda x:x[1], reverse=True)
        #活动奖励广播
        self.boss_mgr.safe_pub(MSG_REWARD_WORLDBOSS, rank_data, self.max_hp)
        pid_levels = PlayerData.get_players_levels(self.pid_hurts.keys())
        res_rw_mail = Game.res_mgr.reward_mails.get(RW_MAIL_BOSS)
        ranks_data = {}
        p_ranks = []
        start_type = self.start_type
        for index, (pid, hurts) in enumerate(rank_data):
            rank = index + 1
            key = (WORLD_BOSS, rank)
            rs_items = self._get_reward(key, hurts, pid_levels[pid])
            #邮件通知玩家
            content = res_rw_mail.content % dict(rank=rank)
            Game.mail_mgr.send_mails(pid, MAIL_REWARD,
                res_rw_mail.title, RW_MAIL_BOSS, rs_items, param=content)
            self.boss_mgr.safe_pub(MSG_REWARD_WORLDITEMS, pid, start_type, rs_items)
            ranks_data[pid] = (rank, hurts)
            p_ranks.append(pid)
        self.boss_mgr.safe_pub(MSG_WBOSS_RANK, ranks_data, p_ranks)

    def one_finish(self, pid, name, hurt, check_data=None, is_cd=True):
        """ 单场结束 """
        if check_data and not self._check(check_data, hurt, pid):
            return False, EC_VALUE
        return super(WorldBoss, self).one_finish(pid, name, hurt, is_cd)

    def _check(self, check_data, hurt, pid):
        """
        伤害值检测
        #玩家等级LV，玩家上阵人数r，玩家上阵人数中最大ATK，BOSS防御DEF
        #Hurt = ATK * ( 1 - DEF * SQRT( LV * 100 )/( DEF * LV + LV * LV * 180))
        #总伤害=r*5*hurt*3
        """
        check_hurt = self.pid_check_hurts.get(pid, 0)
        if not check_hurt or check_hurt < hurt:
            p_level, join_nums, m_atk = check_data
            #根据atk确定回合数
            if m_atk > 30000:
                round = 8
            else:
                round = 5
            boss_def = self.get_boss_def()
            hurt1 = m_atk * (1 - boss_def * math.sqrt(p_level*10)
                             /(boss_def * p_level + p_level * p_level * 180))
            check_hurt = max(join_nums * round * hurt1 * 3, check_hurt)
            self.pid_check_hurts[pid] = check_hurt
        if check_hurt < hurt:
            log.debug('world_boss_finish - pid %d check_hurt %s, hurt %s, check-data %s', pid, check_hurt, hurt, check_data)
            return False
        return True

    def get_boss_def(self):
        """ 获取世界boss的防御力 """
        if not self.boss_def:
            res_boss_level = Game.res_mgr.boss_level.get(self.data.blid)
            keys = (res_boss_level.mid, res_boss_level.level)
            self.boss_def = Game.res_mgr.boss_def_by_keys.get(keys)
        return self.boss_def
    
    @property
    def fetch_world_boss_times(self):
        return Game.setting_mgr.setdefault(BOSS_TIME, BOSS_TIME_V)

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

    @property
    def fetch_reward_vip(self):
        return Game.setting_mgr.setdefault(BOSS_REWARD_VIP, BOSS_REWARD_VIP_V)
