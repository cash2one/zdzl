#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time

from game import BaseGameMgr
from game import pack_msg
from game.base import common, errcode
from game.glog.common import ITEM_ADD_FETE
from game.base.constant import (FETE_COIN2_MAX, FETE_COIN2_MAX_V,
    FETE_COIN2_NUM, FETE_COIN2_NUM_V, FETE_FREE, FETE_COIN2,
    FETE_TYPE_DOUBLE, IKEY_COUNT, PLAYER_ATTR_FETE, FETE_FREE_MAX,
    FETE_FREE_MAX_V,
)
from game.glog.common import COIN_FETE
from corelib import log

class FeteMgr(BaseGameMgr):
    """ 祭天管理器 """
    def __init__(self, game):
        super(FeteMgr, self).__init__(game)
        self.free_num = None
        self.coin2_num = None

    def start(self):
        self.free_num = self.fetch_res(FETE_FREE_MAX, FETE_FREE_MAX_V)
        self.coin2_num = self.fetch_res(FETE_COIN2_MAX, FETE_COIN2_MAX_V)

    def init_player_fete(self, player):
        """ 获取玩家祭天数据 """
        player_fete = getattr(player.runtimes, PLAYER_ATTR_FETE, None)
        if player_fete is None:
            player_fete = PlayerFete(player)
            player_fete.load()
            setattr(player.runtimes, PLAYER_ATTR_FETE, player_fete)
        return player_fete

    def enter_fete(self, player):
        """ 进入祭天 """
        player_fete = self.init_player_fete(player)
        return player_fete.enter_fete()

    def fete_ing(self, player, type):
        """ 进行祭天 """
        player_fete = self.init_player_fete(player)
        return player_fete.fete_ing(type)

    def fetch_res(self, key, value):
        res_num = self._game.setting_mgr.setdefault(key, value)
        return common.make_lv_regions(res_num)

class FeteData(object):
    def __init__(self):
        self.init()

    def init(self):
        #免费祭天次数(已祭天)
        self.n1 = 0
        #元宝祭天次数(已祭天)
        self.n2 = 0
        #翻倍次数(当天累计,获取物品翻倍后更新为0)
        self.db = 0
        #当天第一次祭天时间
        self.ft = 0

    def update(self, adict):
        """ 更新 """
        __dict__ = self.__dict__
        for k in __dict__.iterkeys():
            if k not in adict:
                continue
            __dict__[k] = adict[k]

    def to_dict(self):
        return self.__dict__

    def update_attr(self, player):
        player.play_attr.update_attr({PLAYER_ATTR_FETE:self.to_dict()})

class PlayerFete(object):
    """ 玩家祭天 """
    def __init__(self, player):
        self.player = player
        if 0:
            self.feteData = FeteData()
        self.feteData = None

    def __getstate__(self):
        return self.feteData

    def __setstate__(self, data):
        self.feteData = data

    def uninit(self):
        self.player = None
        self.feteData = None

    def load(self, player = None):
        """ 加载数据 """
        oFeteData = FeteData()
        tObjDict = self.player.play_attr.get(PLAYER_ATTR_FETE)
        if tObjDict:
            oFeteData.update(tObjDict)
        self.feteData = oFeteData
        self.handle_pass_day()

    def save(self, store):
        """ 保存玩家数据 """
        self.feteData.update_attr(self.player)

    def clear(self):
        self.feteData.init()

    def copy_from(self, player):
        p_fete = getattr(player.runtimes, PLAYER_ATTR_FETE)
        if p_fete:
            self.feteData = FeteData()
            self.feteData.update(p_fete.feteData.to_dict())

    def handle_pass_day(self):
        """ 处理超过一天(超过则更新数据) """
        if common.is_pass_day(self.feteData.ft):
            self.feteData.ft = int(time.time())
            self.feteData.n1 = 0
            self.feteData.n2 = 0
            self.feteData.db = 0
            return True
        return False

    def get_enter_msg(self):
        resp_f = 'enterFete'
        vip = self.player.data.vip
        num1 = self.player._game.fete_mgr.free_num(vip) - self.feteData.n1
        num2 = self.player._game.fete_mgr.coin2_num(vip) - self.feteData.n2
        #返回可以使用的次数
        return pack_msg(resp_f, 1, data={'num1':num1, 'num2':num2})

    def enter_fete(self):
        """ 进入祭天初始化数据 """
        #处理超过一天
        self.handle_pass_day()
        return self.get_enter_msg()

    def fete_ing(self, aType):
        """ 进行祭天 """
        #处理超过一天
        #满格 不给祭天
        if self.player.bag.bag_free() <= 0:
            return False, errcode.EC_BAG_FULL
        if self.handle_pass_day():
            self.player.send_msg(self.get_enter_msg())
        rs, data = self.handle_fete_ing(aType)
        if not rs:
            return rs, data
        tResFeteRates = self.player._game.res_mgr.fete_rate_by_type.get(aType)
        regions = {}
        for tResFeteRate in tResFeteRates:
            regions[tResFeteRate] = tResFeteRate.rate
        tRandomR = common.RandomRegion(regions)
        tFeteRate = tRandomR.random()
        #处理特殊
        tNoItems = self._handle_noitems_type(tFeteRate)
        if tNoItems:
            return True, tNoItems
            #获取奖励
        tRw = self.player._game.reward_mgr.get(tFeteRate.rid)
        tRsItem = tRw.reward(params=self.player.reward_params())
        if self.feteData.db:
            tCount = tRsItem[0][IKEY_COUNT]
            tRsItem[0][IKEY_COUNT] = int(tCount) * pow(2, self.feteData.db)
            self.feteData.db = 0
        if not self.player.bag.can_add_items(tRsItem):
            if aType == FETE_FREE:
                self.feteData.n1 -= 1
            else:
                self.feteData.n2 -=1
            return False, errcode.EC_BAG_FULL
        bag_items = self.player.bag.add_items(tRsItem, log_type=ITEM_ADD_FETE)
        rs = self.player.pack_msg_data(coin=True, items=bag_items.items)
        rs.update({'frid':tFeteRate.id})
        return True, rs

    def _handle_noitems_type(self, aFeteRate):
        """ 处理特殊的没有奖励的类型 """
        if aFeteRate.rid > 0 or aFeteRate.rid < FETE_TYPE_DOUBLE:
            return
        if aFeteRate.rid == FETE_TYPE_DOUBLE:
            self.feteData.db += 1
        else:
            self.feteData.db = 0
        tSend = self.player.pack_msg_data(coin=True)
        tSend.update({'frid':aFeteRate.id})
        return tSend

    def handle_fete_ing(self, aType):
        """ 是否能够祭天，能则更新祭天次数 """
        vip = self.player.data.vip
        if aType == FETE_FREE:
            #免费祭天
            if self.feteData.n1 >= self.player._game.fete_mgr.free_num(vip):
                return False, errcode.EC_FETEHIT_MAX
            self.feteData.n1 += 1
        elif aType == FETE_COIN2:
            #元宝祭天
            coin2_max = self.player._game.fete_mgr.coin2_num(vip)
            if self.feteData.n2 >= coin2_max:
                return False, errcode.EC_FETEHIT_MAX
            tCostCoin2 = self.fetch_fete_coin2_num
            if not self.player.cost_coin(0, tCostCoin2, log_type=COIN_FETE):
                return False, errcode.EC_COST_ERR
            self.feteData.n2 += 1
        else:
            return False, errcode.EC_VALUE
        return True, None


    @property
    def fetch_fete_coin2_num(self):
        return self.player._game.setting_mgr.setdefault(FETE_COIN2_NUM, FETE_COIN2_NUM_V)

    def _get_setting_v(self, aKey, aDefault):
        """ 获取全局表的值 """
        return self.player._game.setting_mgr.setdefault(aKey, aDefault)

