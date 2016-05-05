#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time

from corelib import log

from game import Game
from game import BaseGameMgr
from game.base import common, errcode
from game.base.msg_define import MSG_HFATE_COIN3, MSG_HFATE_NUM, MSG_HFATE_YB, MSG_RES_RELOAD
from game.base.constant import ( HITFATE_COIN2_VIP, HITFATE_COIN2_VIP_V, WAITBAG_TYPE_HITFATE,
    HITFATE_COIN1, HITFATE_COIN2, HITFATE_BATCH_VIP, HITFATE_BATCH_VIP_V,
    HITFATE_BATCH_NUM, HITFATE_BATCH_NUM_V, IKEY_ID, IKEY_COUNT,
    PLAYER_ATTR_HITFATE, HITFATE_FREE, DIFF_TITEM_COIN3,
    IKEY_TYPE, IT_ITEM_STR, HITFATE_COIN1_MAX, HITFATE_FREE_MAX,
    HITFATE_COIN1_MAX_V, HITFATE_COIN2_MAX, HITFATE_COIN2_MAX_V,
    HITFATE_FREE_MAX_V,
)
from game.glog.common import COIN_HF_COIN1, COIN_HF_COIN2

class HitFateMgr(BaseGameMgr):
    """ 猎命管理器 """
    def __init__(self, game):
        super(HitFateMgr, self).__init__(game)
        self.luck_num1 = 0 #幸运星活动添加的免费银币观星次数
        self.luck_num2 = 0 #幸运星活动添加的免费元宝观星次数
        self.drop_num1 = 0 #天外坠星活动添加的银币观星次数
        self.drop_num2 = 0 #天外坠星活动添加的元宝观星次数
        game.res_mgr.sub(MSG_RES_RELOAD, self.start)

    def start(self):
        self.coin1_num = self.fetch_res(HITFATE_COIN1_MAX, HITFATE_COIN1_MAX_V)
        self.coin2_num = self.fetch_res(HITFATE_COIN2_MAX, HITFATE_COIN2_MAX_V)
        self.free_num = self.fetch_res(HITFATE_FREE_MAX, HITFATE_FREE_MAX_V)

    def init_player_hitfate(self, player):
        """ 获取玩家猎命数据 """
        player_hit_fate = getattr(player.runtimes, PLAYER_ATTR_HITFATE, None)
        if player_hit_fate is None:
            player_hit_fate = PlayHitFate(player)
            player_hit_fate.load()
            setattr(player.runtimes, PLAYER_ATTR_HITFATE, player_hit_fate)
        return player_hit_fate
    
    def enter_hit_fate(self, player):
        """ 进入猎命 """
        player_hit_fate = self.init_player_hitfate(player)
        return player_hit_fate.enter()

    def hit_fate(self, player, aType, aIsBatch):
        """ 进行猎命 """
        player_hit_fate = self.init_player_hitfate(player)
        return player_hit_fate.hit(aType, aIsBatch)

    def fetch_res(self, key, value):
        res_num = self._game.setting_mgr.setdefault(key, value)
        return common.make_lv_regions(res_num)

    def get_free_num(self, lv):
        """vip免费"""
        return self.free_num(lv) + self.luck_num1

    def get_coin2_num(self, lv):
        return self.coin2_num(lv) + self.drop_num2

    def get_free_coin2_num(self):
        return self.luck_num2

    def get_coin1_num(self, lv):
        return self.coin1_num(lv) + self.drop_num1


class HitFateData(object):

    def __init__(self):
        self.init()

    def init(self):
        #银币已猎命次数
        self.n1 = 0
        #元宝已猎命次数
        self.n2 = 0
        #vip免费已使用次数
        self.n3 = 0
        #活动免费元宝猎命次数
        self.n4 = 0
        #第一次猎命时间
        self.fTime = int(time.time())

    def update(self, aDict):
        """ 更新 """
        __dict__ = self.__dict__
        for k in __dict__.iterkeys():
            if k not in aDict:
                continue
            __dict__[k] = aDict[k]

    def to_dict(self):
        return self.__dict__

    def update_attr(self, player):
        """ 更新玩家属性表 """
        player.play_attr.update_attr({PLAYER_ATTR_HITFATE:self.to_dict()})

class PlayHitFate(object):
    """ 玩家猎命 """
    def __init__(self, player):
        self.player = player
        self.hitFateData = None

    def __getstate__(self):
        return self.hitFateData

    def __setstate__(self, data):
        self.hitFateData = data

    def uninit(self):
        self.player = None
        self.hitFateData = None

    def load(self, player = None):
        """ 获取玩家数据 """
        tObjDict = self.player.play_attr.get(PLAYER_ATTR_HITFATE)
        oHitFateData = HitFateData()
        if tObjDict:
            oHitFateData.update(tObjDict)
        self.hitFateData = oHitFateData

    def save(self, store):
        """ 保存玩家数据 """
        self.hitFateData.update_attr(self.player)

    def clear(self):
        self.hitFateData.init()

    def copy_from(self,player):
        p_hit_fate = getattr(player.runtimes, PLAYER_ATTR_HITFATE)
        if p_hit_fate:
            self.hitFateData = HitFateData()
            adict = p_hit_fate.hitFateData.to_dict()
            self.hitFateData.update(adict)

    def handle_pass_day(self, fetch=False):
        """ 处理超过一天(超过则更新数据) """
        #判断是否已过一天
        if common.is_pass_day(self.hitFateData.fTime):
            self.hitFateData = HitFateData()
            #删除待收物品
            if not fetch:
                return self.player.wait_bag.deletes(WAITBAG_TYPE_HITFATE)
            return True
        return False

    def enter(self):
        """ 进入猎命获取初始化数据 """
        rs = self.handle_pass_day()
        tResVip = self.fetch_fate_coin2_vip
        tRs = {}
        if type(rs) is list:
            tRs = self.player.pack_msg_data(del_wids=rs)
        vip = self.player.data.vip
        coin1_max = self.player._game.hfate_mgr.get_coin1_num(vip)
        if self.player.data.vip < tResVip:
            tRs.update({'num1':coin1_max - self.hitFateData.n1})
        else:
            coin2_max = self.player._game.hfate_mgr.get_coin2_num(vip)
            free_max = self.player._game.hfate_mgr.get_free_num(vip)
            tRs.update({'num1':coin1_max - self.hitFateData.n1,
                        'num2':coin2_max - self.hitFateData.n2,
                        'num3':free_max - self.hitFateData.n3
                        })
        return True, tRs

    def msg_hit_num(self, num=1):
        """ 广播本次猎命次数 """
        self.player.pub(MSG_HFATE_NUM, num)

    def hit(self, aType, aIsBatch):
        """ 进行猎命(支持批量) """
        if aIsBatch:
            return self._hit_fate_batch(aType)
        rs, data = self.handle_hit_fate(aType)
        if not rs:
            return False, data
        if aType == HITFATE_FREE:
            aType = HITFATE_COIN1
        tResFateRates = self.player._game.res_mgr.fate_rate_by_type.get(aType)
        regions = {}
        for tResFateRate in tResFateRates:
            regions[tResFateRate] = tResFateRate.rate
        tRandomR = common.RandomRegion(regions)
        tResFateRate = tRandomR.random()
        #获取奖励
        tRw = self.player._game.reward_mgr.get(tResFateRate.rid)
        tRsItem = tRw.reward(params=self.player.reward_params())
        self._handle_horn(self.player, tRsItem)
        #添加到待收物品
        oWaitItem = self.player.wait_bag.add_waitItem(WAITBAG_TYPE_HITFATE, tRsItem)
        rs = self.player.pack_msg_data(coin=True, waits=[oWaitItem])
        rs['frid'] = tResFateRate.id
        self.msg_hit_num()
        return True, rs

    def _hit_fate_batch(self, aType):
        """ 进行批量猎命 """
        tHitFateBatchVip = self.fetch_fate_batch_vip
        if self.player.data.vip < tHitFateBatchVip:
            return False, errcode.EC_NOVIP
        tHitFateBatchNum = self.player._game.setting_mgr.setdefault(HITFATE_BATCH_NUM, HITFATE_BATCH_NUM_V)
        rs, data = self.handle_hit_fate(aType, tHitFateBatchNum)
        if not rs:
            return False, data
        #获取奖励
        tResFateRates = self.player._game.res_mgr.fate_rate_by_type.get(aType)
        regions = {}
        for tResFateRate in tResFateRates:
            regions[tResFateRate] = tResFateRate.rate
        tRsItems = []
        for i in xrange(data):
            tRandomR = common.RandomRegion(regions)
            tResFateRate = tRandomR.random()
            #获取奖励
            tRw = self.player._game.reward_mgr.get(tResFateRate.rid)
            tRsItem = tRw.reward(params=self.player.reward_params())
            self._handle_horn(self.player, tRsItem)
            #添加到待收物品
            oWaitItem = self.player.wait_bag.add_waitItem(WAITBAG_TYPE_HITFATE, tRsItem)
            tRsItems.append(oWaitItem)
        tSend = self.player.pack_msg_data(coin=True,waits=tRsItems)
        if data == 1:
            tSend['frid'] = tResFateRate.id
        self.msg_hit_num(len(tRsItems))
        return True, tSend

    def _handle_horn(self, player, reward_items):
        """ 处理广播 """
        for reward_item in reward_items:
            if reward_item[IKEY_TYPE] == IT_ITEM_STR\
            and reward_item[IKEY_ID] == DIFF_TITEM_COIN3:
                num = reward_item[IKEY_COUNT]
                player.pub(MSG_HFATE_COIN3, num)

    def handle_hit_fate(self, type, aNum=1):
        """ 是否能猎命,能则更新次数(支持批量)扣费 """
        vip = self.player.data.vip
        if type == HITFATE_COIN1:
            #银币猎命
            tNum1 = self.hitFateData.n1
            coin1_max = self.player._game.hfate_mgr.get_coin1_num(vip)
            rs, data = self.is_hit_fate(tNum1, aNum, coin1_max, type)
            if rs is False:
                return rs, data
            self.hitFateData.n1 = data[0]
        elif type == HITFATE_COIN2:
            #元宝猎命
            tResVip = self.fetch_fate_coin2_vip
            if tResVip > self.player.data.vip:
                return False, errcode.EC_NOVIP
            tNum2 = self.hitFateData.n2
            coin2_max = self.player._game.hfate_mgr.get_coin2_num(vip)
            rs, data = self.is_hit_fate(tNum2, aNum, coin2_max, type)
            if rs is False:
                return rs, data
            for i_num in xrange(self.hitFateData.n2, data[0]):
                i_num+=1
                self.player.pub(MSG_HFATE_YB, i_num)
            self.hitFateData.n2 = data[0]
        elif type == HITFATE_FREE:
            #vip免费猎命
            tNum3 = self.hitFateData.n3
            free_max = self.player._game.hfate_mgr.get_free_num(vip)
            rs, data = self.is_hit_fate(tNum3, aNum, free_max, type)
            if rs is False:
                return rs, data
            self.hitFateData.n3 = data[0]
        else:
            return False, errcode.EC_VALUE
        return True, data[1]

    def is_hit_fate(self, onum, nnum, max, type):
        mgr = self.player._game.hfate_mgr
        if max <= onum:
            return False, errcode.EC_FATEHIT_MAX
        tCanNum = max - onum
        if tCanNum < nnum:
            nnum = tCanNum
        #添加进活动免费次数 活动可以减的元宝 消耗的银币 消耗的元宝
        n4_add = tSubCoin2 = tCostCoin1 = tCostCoin2 = 0
        free2_num = mgr.get_free_coin2_num() - self.hitFateData.n4
        if free2_num > 0:
            n4_add += free2_num
        for i in xrange(nnum):
            onum += 1
            tResFateCost = self.player._game.res_mgr.fate_cost_by_num.get(onum)
            tCostCoin1 += tResFateCost.coin1
            tCostCoin2 += tResFateCost.coin2 + tResFateCost.coin3
            if free2_num >0:
                tSubCoin2 += tResFateCost.coin2 + tResFateCost.coin3
                free2_num -= 1
        if type == HITFATE_COIN1:
            if not self.player.cost_coin(aCoin1=tCostCoin1, log_type=COIN_HF_COIN1):
                return False, errcode.EC_COST_ERR
        elif type == HITFATE_COIN2:
            #扣除该次元宝观星的元宝
            tCostCoin2 -= tSubCoin2
            if not self.player.cost_coin(aCoin2=tCostCoin2, log_type=COIN_HF_COIN2):
                return False, errcode.EC_COST_ERR
            #免费元宝观星次数的添加
            self.hitFateData.n4 += n4_add
            log.info("pid:%s hit_fate sub coin2:%s", self.player.data.id, tSubCoin2)
        return  True, (onum, nnum)

    @property
    def fetch_fate_coin2_vip(self):
        return self.player._game.setting_mgr.setdefault(HITFATE_COIN2_VIP, HITFATE_COIN2_VIP_V)

    @property
    def fetch_fate_batch_vip(self):
        return self.player._game.setting_mgr.setdefault(HITFATE_BATCH_VIP, HITFATE_BATCH_VIP_V)
