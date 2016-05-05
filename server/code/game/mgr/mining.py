#!/usr/bin/env python
# -*- coding:utf-8 -*-

####################################采矿系统####################################

import time
import gevent

from store.store import StoreObj
from game import BaseGameMgr, Game
from game.base import common
from game.base.constant import PLAYER_ATTR_MINING
from game.base.constant import MINING_BATCH_NUM,MINING_BATCH_NUM_V
from game.base.constant import MINING_BATCH_VIP,MINING_BATCH_VIP_V
from game.base.constant import VIP_MINING_FREE, VIP_MINING_FREE_V
from game.base.constant import MINING_COIN1,MINING_COIN2, MINING_FREE
from game.base.constant import MINING_COIN1_LIMIT, MINING_COIN1_LIMIT_V
from game.glog.common import COIN_MINE_COIN1, COIN_MINE_COIN2, ITEM_ADD_MINING, COIN_ADD_MINING_SELL
from corelib import log, spawn_later
from game.base import errcode, msg_define
from game.item.reward import RewardItems


class MiningMgr(BaseGameMgr):

    #mine_free_num = None

    def __init__(self, game):
        super(MiningMgr, self).__init__(game)
        self._game = game
        self.mine_free_num = None
        self.rebate = 1.0 #折扣率 float

    def init_player(self, player):
        try:
            mining = player.runtimes.mining
        except AttributeError:
            mining = PlayerMining(self, player)
            mining.load(player)
            player.runtimes.mining = mining
        return mining

    def get_batch_vip_lev(self):
        """ 得到可批量的VIP等级 """
        return  self._game.setting_mgr.setdefault()

    def _player_able_batch(self, player):
        return player.data.vip >= self.get_batch_vip_lev()

    def enter(self, player):
        mining = self.init_player(player)
        return mining.enter(player)

    def mining(self, player, type, hit, isbatch, is_pack = True):
        mining = self.init_player(player)
        return mining.mining(player, type, hit, isbatch, is_pack)

    def get_free_num(self, player):
        try:
            return self.mine_free_num(player.data.vip)
        except TypeError:
            sett_str = player._game.setting_mgr.setdefault(VIP_MINING_FREE, VIP_MINING_FREE_V)
            self.mine_free_num = common.make_lv_regions(sett_str)
            return self.mine_free_num(player.data.vip)

class MiningData(object):
    def __init__(self):
        self.init()

    def init(self):
        self.ft = 0
        self.zero()

    def zero(self):
        self.fm = 0             #已使用的免费采矿次数

    def add_num(self, num):
        self.fm += num

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
        """ 更新玩家属性表 """
        player.play_attr.update_attr({PLAYER_ATTR_MINING:self.to_dict()})


class PlayerMining(object):
    def __init__(self, mgr, player):
        self.player = player
        self._mgr = mgr
        self.data = MiningData()
        self.m_coin1 = MiningCoin1(self)
        self.m_coin2 = MiningCoin2(self)
        self.m_coin3 = MiningCoin3(self)

    def __getstate__(self):
        return self.data

    def __setstate__(self, data):
        self.data = data

    def uninit(self):
        self.player = None
        self._mgr = None

    def able_free(self, num, player):
        return self.data.fm + num <= self._mgr.get_free_num(player)

    def save(self, store):
        self.data.update_attr(self.player)

    def load(self, player):
        t_obj_dict = player.play_attr.get(PLAYER_ATTR_MINING)
        if not t_obj_dict:
            self.data.update_attr(player)
        t_obj_dict = player.play_attr.get(PLAYER_ATTR_MINING)
        self.data.update(t_obj_dict)

    def copy_from(self, player):
        mining = getattr(player.runtimes, 'mining')
        if mining:
            self.data = MiningData()
            self.data.update(mining.data.to_dict())

    def get_free_fm(self, player):
        r_m = self._mgr.get_free_num(player) - self.data.fm
        r_m  = r_m if r_m > 0 else 0
        return r_m

    def enter(self, player):
        self.handle_pass_day()
        return True, {"fm": self.get_free_fm(player)}

    def mining(self, player, type, hit, isbatch, is_pack = True):
        """
        采矿获得矿石
        """
        num = 1
        if isbatch:
            setting_mgr = Game.setting_mgr
            num = setting_mgr.setdefault(MINING_BATCH_NUM, MINING_BATCH_NUM_V)
        if type == MINING_COIN1:
            return self.m_coin1.mining(player, num, hit, is_pack)
        elif type == MINING_COIN2:
            return self.m_coin2.mining(player, num, hit, is_pack)
        elif type == MINING_FREE:
            self.handle_pass_day()
            return self.m_coin3.mining(player, num, hit, is_pack)
        return False, errcode.EC_VALUE

    def handle_pass_day(self):
        if common.is_pass_day(self.data.ft):
            self.data.zero()


class MiningBase(object):
    def __init__(self, mgr):
        self._mgr = mgr
        if 0:
            self._mgr = PlayerMining()

    def _calc_cost(self, player, num):
        """计算花费"""
        pass

    def get_reward(self, player, res, hit, multi):
        data = []
        rid = res.rids.get(multi)
        if rid is None:
            return data
        rw = player._game.reward_mgr.get(rid)
        if rw is None:
            return data

        for n in xrange(hit):
            items = rw.reward(params=player.reward_params())
            if len(items):
                data.append(items[0])
        return data

    def mining(self, player, num, hit, is_pack):
        #计算消耗无法满足消耗就返回false,err_string
        rs, res = self._calc_cost(player, num)
        if not rs:
            return rs, res

        hit2, hit3, hit5 = hit['hit2'], hit['hit3'], hit['hit5']
        if hit2 + hit3 + hit5 > num:
            return
        hit1 = num - (hit2 + hit3 + hit5)

        rw_list = []
        rw_list.extend(self.get_reward(player, res, hit1, 1))
        rw_list.extend(self.get_reward(player, res, hit2, 2))
        rw_list.extend(self.get_reward(player, res, hit3, 3))
        rw_list.extend(self.get_reward(player, res, hit5, 5))

        add, not_add = player.bag.get_can_add_items(rw_list)

        if player.bag.bag_free() == 0 or len(not_add) != 0:
            return False, errcode.EC_BAG_FULL

        self._cost_coin(player, num, res)
        bag_items = player.bag.add_items(add, log_type=ITEM_ADD_MINING)

        #超出物品折算银币
#        if len(not_add):
#            coin1 = 0
#            items = RewardItems(not_add)
#            coin1 += items.get_price()
#            setting_mgr = Game.setting_mgr
#            limit = setting_mgr.setdefault(MINING_COIN1_LIMIT, MINING_COIN1_LIMIT_V)
#            coin1 = coin1 if coin1 <= limit else limit
#            player.add_coin(aCoin1=coin1, log_type=COIN_ADD_MINING_SELL)
#            bag_items.add_coin(coin1, 0, 0)

        player.safe_pub(msg_define.MSG_MINING, num)
        if is_pack:
            msg = bag_items.pack_msg(coin = True)
            return True, msg

    def _cost_coin(self, player, num, data):
        """ 处理玩家金钱和元宝的消耗 """
        coin1 = data.coin1 * num
        coin2 = int(data.coin2 * num * self._mgr._mgr.rebate)
        coin3 = int(data.coin3 * num * self._mgr._mgr.rebate)
        player.cost_coin_ex(coin1,  coin2, coin3, log_type = self.COST_TYPE)

    def get_res(self, player, is_coin2 = False):
        """
        获得采矿配置数据
        """
        player_level = player.data.level
        if is_coin2:
            dic = player._game.res_mgr.mines_vips
        else:
            dic = player._game.res_mgr.mines_normals
        k_l = dic.keys()
        for lev1, lev2 in k_l:
            if lev1 <= player_level <= lev2:
                return dic[(lev1, lev2)]
        k_l.sort()
        lev1_end, lev2_end = k_l[-1]
        return dic[(lev1_end, lev2_end)]


class MiningCoin1(MiningBase):
    """ 金钱采矿 """
    COST_TYPE = COIN_MINE_COIN1

    def _calc_cost(self, player, num):
        res_mining = self.get_res(player)
        coin1 = res_mining.coin1 * num
        if player.enough_coin(coin1, 0, True):
            return True, res_mining
        return False, errcode.EC_COST_ERR


class MiningCoin2(MiningBase):
    """ 元宝采矿 """
    COST_TYPE = COIN_MINE_COIN2

    def _calc_cost(self, player, num):
        res_mining = self.get_res(player, True)
        if res_mining.coin2:
            coin2 = int(res_mining.coin2 * num * self._mgr._mgr.rebate)
            if player.enough_coin(0, coin2, False):
                return True, res_mining
        else:
            coin3 = int(res_mining.coin3 * num * self._mgr._mgr.rebate)
            if player.enough_coin(0, coin3, True):
                return True, res_mining
        return False, errcode.EC_COST_ERR


class MiningCoin3(MiningBase):
    """ 免费挖矿 """
    def mining(self, player, num, hit, is_pack):
        if num > self._mgr.get_free_fm(player):
            if num > 1:
                return False, errcode.EC_MINING1_BATCH_ERR
            return False, errcode.EC_MINING1_FREE_ERR
        return super(MiningCoin3, self).mining(player, num, hit, is_pack)

    def _calc_cost(self, player, num):
        res_mining = self.get_res(player)
        if self._mgr.able_free(num, player):
            return True, res_mining
        return False, errcode.EC_VALUE

    def _cost_coin(self, player, num, data):
        self._mgr.data.add_num(num)
        self._mgr.data.ft = common.current_time()
        self._mgr.data.update_attr(player)
