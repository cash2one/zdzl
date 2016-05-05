#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game import Game
from game.base import common
from game.glog.common import ITEM_ADD_DAY_SIGN
from game.base.constant import DAYSIGN_DAY2RID, DAYSIGN_DAY2RID_V
from game.base.constant import DAYSIGN_OVERTASKID, DAYSIGN_OVERTASKID_V


from game.base import errcode

from game.store import StoreObj, GameObj
from game.store import TN_DAYSIGN


class DaySignMgr(object):
    """日常签到管理类"""

    def __init__(self, game):
        self._game = game
        ridstr = Game.setting_mgr.setdefault(DAYSIGN_DAY2RID, DAYSIGN_DAY2RID_V)
        self.rid_dict = common.str2dict(ridstr, ktype=int, vtype=int)

    def stop(self):
        pass

    def init_player(self, player):
        try:
            p_sign = player.runtimes.daysign
        except AttributeError:
            p_sign = PlayerDaySign(player)
            p_sign.load(self._game.rpc_store, key=player.data.id)
            player.runtimes.daysign = p_sign
        return p_sign

    def is_did(self, player):
        """玩家是不是已经签到"""
        p_sign = self.init_player(player)
        return p_sign.pack_msg()[1]

    def sign(self, player):
        p_sign = self.init_player(player)
        if not common.is_pass_day(p_sign.data.t):
            return False, errcode.EC_VALUE
        rs, data = p_sign.sign(self._game.rpc_store)
        if not rs:
            return rs, data
        return p_sign.pack_msg()


class DaySignData(StoreObj):

    def init(self):
        self.id = None
        self.t      = 0      #上次签到的时间
        self.finish = 0      #已完成到的最大索引

    def to_dict(self):
        return self.__dict__


FINISH_DAY = 15

class PlayerDaySign(GameObj):

    TABLE_NAME = TN_DAYSIGN
    DATA_CLS = DaySignData

    def __init__(self, player):
        self.player = player
        super(PlayerDaySign, self).__init__(adict={})

    def load(self, store, key, check=True):
        if not super(PlayerDaySign, self).load(store, key, check):
            self.data.id = key

    def _over_handle(self, rpc_store):
        data = self.data
        data.finish += 1
        data.t = common.current_time()
        tid = Game.setting_mgr.setdefault(DAYSIGN_OVERTASKID, DAYSIGN_OVERTASKID_V)
        self.player.task.add_task(tid, send_msg=True)
        self.save(rpc_store, forced=True)
        return True, None

    def _normal_handle(self, rpc_store):
        data = self.data
        next_day = data.finish + 1
        rid = self.player._game.day_sign_mgr.rid_dict.get(next_day)
        if not rid:
            return True, None
        t_rw = Game.reward_mgr.get(rid)
        if t_rw is None:
            return True, None
        items = t_rw.reward(params=self.player.reward_params())
        bag = self.player.bag
        if not bag.can_add_items(items):
            return False, errcode.EC_BAG_FULL
        #添加进背包
        bag_items = bag.add_items(items, log_type=ITEM_ADD_DAY_SIGN)
        bag_items.pack_msg(send=True)

        data.finish = next_day
        data.t = common.current_time()
        self.save(rpc_store, forced=True)
        return True, None

    def sign(self, rpc_store):
        """签到"""
        if self.data.finish >= FINISH_DAY:
            return False, errcode.EC_VALUE
        if self.next_is_over():
            return self._over_handle(rpc_store)
        else:
            return self._normal_handle(rpc_store)

    def pack_msg(self):
        r_d = dict()
        if common.is_pass_day(self.data.t) and not self.data.finish == FINISH_DAY:
            r_d['sign'] = 0
        else:
            r_d['sign'] = 1
        r_d['finish'] = self.data.finish
        return True, r_d

    def next_is_over(self):
        return self.data.finish == FINISH_DAY -1
