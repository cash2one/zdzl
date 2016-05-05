#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time

from corelib import log

from game.base import common
from game.glog.common import COIN_BOSS_CD
from game.base.errcode import EC_COST_ERR, EC_BOSS_NOJOIN, EC_NOLEVEL
from game.base.constant import (PLAYER_ATTR_BOSS, BOSS_ALLY_TIME,
    BOSS_ALLY_TIME_V, CHATER_START, REPORT_WBOSS_HURTS, REPORT_BOSS_URL
)

from .player_handler import pack_msg, reg_player_handler, BasePlayerRpcHander

def _wrap_lock(func):
    def _func(self, *args, **kw):
        with self._lock:
            return func(self, *args, **kw)
    return _func

class PlayerBossHandler(BasePlayerRpcHander):

    @property
    def fetch_notice_start(self):
        """ 获取boss开启通知时间 """
        return self.player._game.setting_mgr.setdefault(BOSS_ALLY_TIME, BOSS_ALLY_TIME_V)

    def _end_cd(self, is_ally_boss, resp_f, ):
        """ 使用元宝结束cd时间 """
        #获取所需要的钱
        pid = self.player.data.id
        rpc_boss_mgr = self.player._game.rpc_boss_mgr
        if is_ally_boss:
            rs, data = rpc_boss_mgr.ally_cd_coin2(pid)
        else:
            rs, data = rpc_boss_mgr.world_cd_coin2(pid)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        coin2 = int(data)
        #判断费用是否够
        if not self.player.enough_coin_ex(0, aCoin2=coin2):
            return pack_msg(resp_f, 0, err=EC_COST_ERR)
        #清楚当前cd状态
        if is_ally_boss:
            rs, data = rpc_boss_mgr.ally_cd_clear(pid)
        else:
            rs, data = rpc_boss_mgr.world_cd_clear(pid)
        if rs:
            self.player.cost_coin_ex(aCoin2=coin2, log_type=COIN_BOSS_CD)
            send_msg = {'update':self.player.pack_msg_data(coin=True)}
            rs, data = self.player._game.rpc_boss_mgr.boss_add_buff(pid)
            if rs:
                send_msg.update({'buff':data})
            return pack_msg(resp_f, 1, data=send_msg)
        return pack_msg(resp_f, 0, err=data)

    def rc_allyBossEnter(self):
        """ 进入同盟boss战场景 """
        resp_f = 'allyBossEnter'
        rs, data = self.player._game.rpc_boss_mgr.ally_boss_enter(self.player.data.id)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_allyBossExit(self):
        """ 退出同盟boss战场景 """
        resp_f = 'allyBossExit'
        rs, data = self.player._game.rpc_boss_mgr.ally_boss_exit(self.player.data.id)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_allyBossStart(self):
        """ 单场同盟战开始 """
        resp_f = 'allyBossStart'
        #玩家这星期是否已经参加过同盟boss
        tObjDict = self.player.play_attr.get(PLAYER_ATTR_BOSS)
        now = int(time.time())
        if tObjDict:
            jt = tObjDict['jt']
            week_time = common.week_time(1, zero=1, delta=0)
            #过一周
            if jt < week_time:
                jt = now
                tObjDict = {'jt':jt}
                self.player.play_attr.update_attr({PLAYER_ATTR_BOSS:tObjDict})
            if now > jt + self.fetch_notice_start and jt > week_time:
                return pack_msg(resp_f, 0, err=EC_BOSS_NOJOIN)
        else:
            jt = now
            tObjDict = {'jt':jt}
            self.player.play_attr.update_attr({PLAYER_ATTR_BOSS:tObjDict})
        rs, data = self.player._game.rpc_boss_mgr.ally_boss_start(self.player.data.id)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_allyBossFinish(self, hurt):
        """ 单场同盟boss战完成 """
        resp_f = 'allyBossFinish'
        player = self.player.data
        rs, data = self.player._game.rpc_boss_mgr.ally_boss_finish(player.id,player.name, hurt)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_allybossCdTimes(self):
        """ 获取同盟boss战cd时间 """
        resp_f = 'allyBossCdTimes'
        ls_times, times = self.player._game.rpc_boss_mgr.ally_cd_time(self.player.data.id)
        return pack_msg(resp_f, 1, data={'times':ls_times, 'mtimes':times})

    @_wrap_lock
    def rc_allybossCdEnd(self):
        """ 同盟boss使用元宝结束冷却时间 """
        resp_f = 'allybossCdEnd'
        return self._end_cd(True, resp_f)

    def rc_bossEnter(self):
        """ 进入世界boss战场景 """
        resp_f = 'bossEnter'
        if self.player.data.chapter == CHATER_START:
            return pack_msg(resp_f, 0, err=EC_NOLEVEL)
        rs, data = self.player._game.rpc_boss_mgr.world_boss_enter(self.player.data.id)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_bossExit(self):
        """ 退出世界boss战场景 """
        resp_f = 'bossExit'
        rs, data = self.player._game.rpc_boss_mgr.world_boss_exit(self.player.data.id)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_bossCdTimes(self):
        """ 获取当前剩余cd时间 """
        resp_f = 'bossCdTimes'
        ls_times, times = self.player._game.rpc_boss_mgr.world_cd_time(self.player.data.id)
        return pack_msg(resp_f, 1, data={'times':ls_times, 'mtimes':times})

    @_wrap_lock
    def rc_bossCdEnd(self):
        """ 世界boss使用元宝结束冷却时间 """
        resp_f = 'bossCdEnd'
        return self._end_cd(False, resp_f)

    def rc_bossStart(self):
        """ 单场世界战开始 """
        resp_f = 'bossStart'
        rs, data = self.player._game.rpc_boss_mgr.world_boss_start(self.player.data.id)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_bossFinish(self, hurt, news=None):
        """ 单场世界boss战完成 """
        resp_f = 'bossFinish'
        player = self.player.data
        if news:
            self._save_report(news)
        check_data = self._check_data()
        rs, data = self.player._game.rpc_boss_mgr.world_boss_finish(player.id, player.name, hurt, check_data)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def _save_report(self, news):
        """ 保存高伤害值的战报 """
        pid = self.player.data.id
        file = 'boss_%d_%d' % (pid, common.current_time())
        fid = self.player._game.rpc_report_mgr.save(REPORT_WBOSS_HURTS, [pid], news,
            url=[REPORT_BOSS_URL, file])
        log.debug('world—boss-fid %d, %s', fid, file)
        
    def _check_data(self):
        """ 检测玩家的伤害值 """
        p_level = self.player.data.level
        join_nums, max_atk = self.player.property.join_war_data()
        return p_level, join_nums, max_atk

reg_player_handler(PlayerBossHandler)
