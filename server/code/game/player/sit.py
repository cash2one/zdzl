#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time, math

from corelib import spawn, spawn_later, sleep, log

from game import pack_msg
from game.base import errcode, common
from game.base.msg_define import MSG_SIT_PER
from game.base.constant import (SIT_START_TIME, SIT_EXPPER_TIME,
    SIT_EXPPER_TIME_V, SIT_TIME_MAX, SIT_TIME_MAX_V, SIT_EXP, PLAYER_ATTR_SIT,
    STATE_SIT, STATE_NORMAL, SIT_ADD_EXP, SIT_ADD_EXP_V, SIT_LOGOUT_TIME,
)

class PlayerSit(object):
    """ 玩家打坐 """
    def __init__(self, player):
        if 0:
            from .player import Player
            self.player = Player()
        self.player = player

        #保存玩家属性数据累加经验{'st':time, 'exp':1}
        self.sit_data = {}
        #玩家开始打坐的坐标
        self.start_sit_pos = ''

        self._loop_task = None
        self.online_rs = None
        self._sit_time = 0

    def uninit(self):
        self.player = None
        self.sit_data = {}
        #玩家开始打坐的坐标
        self.start_sit_pos = ''
        self._stop_loop_task()
        self.online_rs = None
        self._sit_time = 0

    def load(self):
        """ 加载数据 """
        v = self.player.play_attr.get(PLAYER_ATTR_SIT)
        log.debug('player-login-exp1 pid = %s, exp = %s', self.player.data.id, self.player.data.exp)
        if not v:
            v = self.make_sit_data()
            self.player.play_attr.set(PLAYER_ATTR_SIT, v)
        self.sit_data = v
        self._save_logout_time()
        tResLevelExp = self._get_res_exp(self.player.data.level)
        #vip提速
        self.vip_addexp = self.fetch_res(SIT_ADD_EXP, SIT_ADD_EXP_V)
        if not tResLevelExp or not tResLevelExp.siteExp:
            return
        #提前更新玩家状态
        self._update_player_state()
        #判断离线之前是否处于打坐状态，并且做处理
        #延迟5秒 是因为此模块会抛出消息如果先执行别的模块获得不到消息
        def _delay():
            try:
                self.online_add_sitexp()
            except:
                log.log_except()
        if not self.player.no_game:
            spawn_later(5, _delay)

    def _save_logout_time(self):
        """ 保存登出时间(上次未处理打坐流程的登出时间) """
        if self.sit_data.get(SIT_LOGOUT_TIME):
            return
        self.sit_data[SIT_LOGOUT_TIME] = self.player.data.tLogout

    def save(self):
        """ 保存属性 """
        if self.sit_data:
            self.player.play_attr.update_attr({PLAYER_ATTR_SIT:self.sit_data})

    def fetch_res(self, key, value):
        res_num = self.player._game.setting_mgr.setdefault(key, value)
        return common.make_lv_regions(res_num)

    def make_sit_data(self):
        """ 创建玩家属性表结构 """
        return {SIT_START_TIME:int(time.time()), SIT_EXP:0}

    def _get_res_exp(self, aLevel):
        """ 获取指定等级对应的等级表数据 """
        return self.player._game.res_mgr.exps_by_level.get(aLevel)

    def close(self):
        """ 关闭,玩家退出也会调用 """
        self._stop_loop_task()

    @property
    def is_sit(self):
        return self.player.data.state == STATE_SIT

    @property
    def can_sit(self):
        return self.player.data.state == STATE_NORMAL

    def start_sit(self):
        """ 开始打坐 """
        self.start_sit_pos = self.player.data.pos
        tResLevelExp = self._get_res_exp(self.player.data.level)
        if not tResLevelExp or not tResLevelExp.siteExp:
            return False, errcode.EC_NOLEVEL
        if not self.can_sit:
            return False, errcode.EC_SIT_STARTE
        self.player.update_state(STATE_SIT)
        self.sit_data[SIT_START_TIME] = int(time.time())
        self.sit_data[SIT_EXP] = 0
        self._online_start_sit(aFinishSitTime=0)
        return True, None

    def _loop(self, aFinishSitTime=0):
        """ 按规定时间每一段时间获得一段经验
            aFinishSitTime 为零时表示开始打坐
            不为零 表示已打坐的时间
         """
        tPerTime = self.fetch_exppre_time
        is_online = aFinishSitTime
        while self.is_sit:
            aFinishSitTime += tPerTime
            if aFinishSitTime > self.fetch_time_max:
                self.stop_sit()
                break
            if is_online:
                #上线打坐时算出第一次到达60s剩余的描述
                sleep(tPerTime - aFinishSitTime % tPerTime)
                is_online = False
            else:
                sleep(tPerTime)
                #在线每两分钟的广播
                self._sit_time += 60
                if self._sit_time / 60 % 2 == 0:
                    self.player.pub(MSG_SIT_PER, 2)
            #服务端检测位置是否发生变化
            if self.start_sit_pos and self.start_sit_pos != self.player.data.pos:
                log.debug('start_sit_pos = %s, change_pos = %s', self.start_sit_pos, self.player.data.pos)
                self.stop_sit()
                break
            self.add_sit_exp()

    def add_sit_exp(self):
        """ 添加经验并发给客户端 """
        resp_f = 'addSitExp'
        vip = self.player.data.vip
        res_rate = self.vip_addexp(vip)
        tResLevelExp = self._get_res_exp(self.player.data.level)
        add_sit_exp = tResLevelExp.siteExp + tResLevelExp.siteExp * res_rate / 100
        self.player.add_exp(add_sit_exp)
        #主动发送给客户端
        self.sit_data[SIT_EXP] += add_sit_exp
        self.player.send_msg(pack_msg(resp_f, 1, data={'exp':self.sit_data[SIT_EXP]}))

    def _stop_loop_task(self):
        if self._loop_task is not None:
            self._loop_task.kill(block=0)
            self._loop_task = None

    def stop_sit(self):
        """ 停止打坐 """
        if not self.is_sit:
            return False, errcode.EC_SIT_NOSIT
        self.player.update_state(STATE_NORMAL)
        #关掉线程
        self.close()
        self.sit_data[SIT_EXP] = 0
        self.sit_data[SIT_START_TIME] = 0
        return True, None

    def online_sit(self):
        """ 上线获取打坐数据 """
        if self.online_rs is None:
            sleep(5)
            self.online_add_sitexp()
            if self.online_rs is None:
                return False, None
        data = self.online_rs
        if data.has_key('canSitTime'):
            #继续打坐
            self._online_start_sit(self.fetch_time_max - data['canSitTime'])
        data['addExp'] = self.sit_data[SIT_EXP]
        data['exp'] = self.player.data.exp
        return True, data

    def online_add_sitexp(self):
        """ 上线添加打坐经验 """
        if self.online_rs is not None or self.player is None:
            return
        #离线前是否处于打坐状态
        logout_time = self.sit_data.get(SIT_LOGOUT_TIME)
        can_site_time, finish_site_time = self._get_time_exp(logout_time)
        data ={}
        if can_site_time > 0:
            data = {'canSitTime':can_site_time}
            #如打坐时间未超过上线 则继续打坐
            if self.sit_data[SIT_START_TIME]:
                start = self.sit_data[SIT_START_TIME]
            else:
                start = logout_time
            self.sit_data[SIT_START_TIME] = start
        tAddCnt = finish_site_time / self.fetch_exppre_time
        self.online_rs = data
        self._clear_logout_time()
        if not tAddCnt:
            return data
        tAddExp = self._handle_exp(tAddCnt)
        if tAddExp:
            #添加经验
            vip = self.player.data.vip
            res_rate = self.vip_addexp(vip)
            tAddExps = tAddExp + tAddExp * res_rate / 100
            log.debug('player-sit-exp pid = %s, tAddExps = %s', self.player.data.id, tAddExps)
            self.player.add_exp(tAddExps)
            self.sit_data[SIT_EXP] += tAddExps
        return data

    def _clear_logout_time(self):
        """ 已计算离线经验清楚记录的登出时间 """
        self.sit_data[SIT_LOGOUT_TIME] = 0

    def _get_time_exp(self, logout_time):
        """ 获取可以打坐的时间和完成的时间 """
        tResSiteTimeMax = self.fetch_time_max
        tNowTime = int(time.time())
        if not self.sit_data[SIT_START_TIME] or logout_time < self.sit_data[SIT_START_TIME]:
            #离线前不处于打坐状态
            finish_site_time = tNowTime - logout_time
            can_site_time = tResSiteTimeMax - (tNowTime - logout_time)
        else:
            #离线前处于打坐状态
            tOlineTime = (logout_time - self.sit_data[SIT_START_TIME]) % self.fetch_exppre_time
            finish_site_time = tNowTime - logout_time + tOlineTime
            can_site_time = tResSiteTimeMax - (tNowTime - self.sit_data[SIT_START_TIME])
        if finish_site_time > tResSiteTimeMax:
            finish_site_time = tResSiteTimeMax
        if finish_site_time < 0:
            finish_site_time = 0
            can_site_time = tResSiteTimeMax
        return can_site_time, finish_site_time

    def _handle_exp(self, aAddCnt):
        """ 处理经验 """
        tResLevelExp = self._get_res_exp(self.player.data.level)
        if not tResLevelExp:
            return
        tAddExp = 0
        tUpLevel = self.player.data.level
        tPlayerExp = self.player.data.exp
        while aAddCnt:
            res_uplevel_exp = self._get_res_exp(tUpLevel+1)
            up_level_exp =  res_uplevel_exp.exp
            tUpLevelExp = float(up_level_exp - tPlayerExp)
            tNeedCnt = int(math.ceil(tUpLevelExp / tResLevelExp.siteExp))
            if tNeedCnt > aAddCnt:
                tAddExp += aAddCnt * tResLevelExp.siteExp
                break
            tNeedAddExp = tNeedCnt * tResLevelExp.siteExp
            tAddExp += tNeedAddExp
            tPlayerExp = tNeedAddExp - int(tUpLevelExp)
            tUpLevel += 1
            tResLevelExp = self._get_res_exp(tUpLevel)
            aAddCnt -= tNeedCnt
        return tAddExp

    def _online_start_sit(self, aFinishSitTime):
        """ 上线继续打坐 """
        self._stop_loop_task()
        self._loop_task = spawn(self._loop, aFinishSitTime)

    def _get_setting_v(self, aKey, aDefault):
        """ 获取全局表的值 """
        return self.player._game.setting_mgr.setdefault(aKey, aDefault)

    def _update_player_state(self):
        """ 玩家状态的更新 """
        tNowTime = int(time.time())
        if self.player.data.state == STATE_SIT:
            can_site_time = self.fetch_time_max - (tNowTime - self.sit_data[SIT_START_TIME])
            if can_site_time <= 0:
                self.player.update_state(STATE_NORMAL)
            return
        logout_time = self.sit_data.get(SIT_LOGOUT_TIME)
        if tNowTime - logout_time >= self.fetch_exppre_time:
            self.player.update_state(STATE_SIT)

    def copy_from(self, p_sit):
        """拷贝打坐数据"""
        self.sit_data.clear()
        self.online_rs = p_sit.online_rs
        self.sit_data.update(p_sit.sit_data)

    @property
    def fetch_exppre_time(self):
        return self._get_setting_v(SIT_EXPPER_TIME, SIT_EXPPER_TIME_V)

    @property
    def fetch_time_max(self):
        return self._get_setting_v(SIT_TIME_MAX, SIT_TIME_MAX_V)

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


