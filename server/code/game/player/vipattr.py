#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game import Game, BaseGameMgr
from game.base import common

from game.base import errcode

from game.base.constant import PLAYER_ATTR_VIP
from game.base.constant import FSPEEDNUM

from game.base.msg_define import MSG_VIP_UP_GRADE


class VipFightSpeedData(object):

    def __init__(self, mgr):
        self._mgr = mgr
        self._data()
        mgr.update_local(self.to_dict())
        mgr.append_pass_day_obj(self)

    def _data(self, num=0):
        self.num = num            #战斗剩余的次数

    def to_dict(self):
        return {FSPEEDNUM:self.num}

    def updata_attr(self):
        """ 更新玩家属性表 """
        self._mgr.update_local(self.to_dict())

    def update(self, dic):
        num = dic.get(FSPEEDNUM, None)
        if not num:
            return
        self.num = num

    def use(self):
        self.num -= 1
        self.updata_attr()

    def pass_day(self, mgr, player):
        num = mgr.player._game.vip_attr_mgr.day_speed_num(player)
        self._data(num)

    def vip_lv_up(self, mgr, player):
        self.pass_day(mgr, player)

    def vip_reach(self):
        '''
        vip等级达到了
        '''
        self.num = -1
        self.updata_attr()


class PlayerVipAttr(object):
    """玩家vip相关"""

    def __init__(self, player):
        self.data_dict = dict()
        self.data_dict['t'] = 0
        self.pass_days_objs = []
        self.player = player
        self.vip_speed_data = VipFightSpeedData(self)

    def uninit(self):
        self.player = None
        self.data_dict = dict()
        self.pass_days_objs = []
        self.vip_speed_data = None

    def vip_task(self, vip_lv):
        """
        处理vip等级升级
        """
        self.vip_speed_data.vip_lv_up(self, self.player)
        if vip_lv >= self.player._game.vip_attr_mgr.dis_limit_vip():
            self.vip_speed_data.vip_reach()
            self.player.unsub(MSG_VIP_UP_GRADE, self.vip_task)
        self.vip_speed_data.updata_attr()

    def sub(self):
        """
        注册监听的
        """
        self.player.sub(MSG_VIP_UP_GRADE, self.vip_task)

    def load(self):
        tObjDict = self.player.play_attr.get(PLAYER_ATTR_VIP)
        if not tObjDict:
            self.update_attr()
        tObjDict = self.player.play_attr.get(PLAYER_ATTR_VIP)
        self.update(tObjDict)
        self.handle_pass_day()
        self.sub()

    def handle_pass_day(self):
        if self.player.no_game:
            return
        if common.is_pass_day(self.data_dict['t']):
            for obj in self.pass_days_objs:
                obj.pass_day(self, self.player)
                obj.updata_attr()
            self.data_dict['t'] = common.current_time()
            self.update_attr()

    def update_attr(self):
        self.player.play_attr.update_attr({PLAYER_ATTR_VIP:self.data_dict})

    def update_local(self, _dic):
        """更新到自己本地的data_dic"""
        self.data_dict.update(_dic)

    def append_pass_day_obj(self, obj):
        self.pass_days_objs.append(obj)

    def update(self, adict):
        """ 更新 """
        for k in self.data_dict.iterkeys():
            if k not in adict:
                continue
            self.data_dict[k] = adict[k]
        for obj in self.pass_days_objs:
            obj.update(adict)

    def to_dict(self):
        return self.data_dict

    def speed_up(self, mul):
        """战斗加速"""
        mul = float(mul)
        self.handle_pass_day()
        vip_attr_mgr = self.player._game.vip_attr_mgr
        #玩家自己可以达到的倍数
        if mul <= vip_attr_mgr.current_multiple(self.player):
            return True, self.vip_speed_data.to_dict()
        #申请的倍数>玩家自己可以尝试的倍数返回错误
        if mul > vip_attr_mgr.can_try_multiple(self.player):
            return False, errcode.EC_VALUE
        #检查是不是还有剩余次数
        if not self.vip_speed_data.num:
            return False, errcode.EC_VALUE
        self.vip_speed_data.use()
        self.update_attr()
        return True, self.vip_speed_data.to_dict()

