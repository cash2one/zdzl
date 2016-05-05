#!/usr/bin/env python
# -*- coding:utf-8 -*-
import time

from game.base.constant import (FOOD_USE_TIME, FOOD_BUFF_TIME,
        FOOD_BUFF_TIME_V, BUFF_TYPE_FOOD,
        FOOD_ROLL, FOOD_ROLL_V,
        FIGHT_ATTR_MP,
        )
from game.store.define import TN_P_BUFF
from game.store import StoreObj, GameObj
from game.glog.common import COIN_BUFF_EAT, PL_EAT
from game.base import errcode

EAT_COST_ROLL = 1
EAT_COST_COIN = 2


def merge_buff(sbuff_dict, dbuff_dict, multiply=1):
    for k,v in sbuff_dict.iteritems():
        b = dbuff_dict.setdefault(k, 0)
        dbuff_dict[k] = b + v*multiply
    return dbuff_dict

class BuffData(StoreObj):
    __slots__ = ('id', 'pid', 't', 'bid', 'et', 'buff')
    def init(self):
        self.id = None
        self.pid = 0
        self.t = 0 #1=食馆buff, 2=vipBuff
        self.bid = 0
        self.et = 0
        self.buff = ''


class Buff(GameObj):
    __slots__ = GameObj.__slots__
    TABLE_NAME = TN_P_BUFF
    DATA_CLS = BuffData
    @classmethod
    def new_by_res(cls, t, res_buff, buff_data, delay_time):
        buff = cls()
        buff.data.t = t
        buff.data.bid = res_buff.id
        buff.data.buff = buff_data
        buff.data.et = time.time() + delay_time
        return buff

    @property
    def is_timeout(self):
        return time.time() >= self.data.et

class PlayerBuff(object):
    """ 玩家buff列表,并有食馆功能 """
    def __init__(self, player):
        self.buffs = {}
        self.player = player
        if 0:
            from .player import Player
            self.player = Player()

    def uninit(self):
        self.player = None
        self.buffs = {}

    def load(self):
        """ 加载数据 """
        store = self.player._game.rpc_store
        querys = dict(pid=self.player.data.id)
        buffs = store.query_loads(TN_P_BUFF, querys)
        for b in buffs:
            buff = Buff(adict=b)
            if buff.is_timeout:
                buff.delete(store)
            else:
                self.buffs[buff.data.id] = buff

        #食馆上次使用时间
        self.use_time = self.player.play_attr.setdefault(FOOD_USE_TIME, 0)

    def save(self):
        """ 保存 """
        store = self.player._game.rpc_store
        for buff in self.buffs.itervalues():
            buff.save(store)

    def clear(self):
        """ 清除 """
        store = self.player._game.rpc_store
        for buff in self.buffs.itervalues():
            buff.delete(store)
        self.buffs.clear()

    def copy_from(self, buffs):
        self.clear()
        for b in buffs.buffs.itervalues():
            nb = Buff(adict=b.data.to_dict())
            nb.data.id = None
            nb.data.pid = self.player.data.id
            nb.save(self.player._game.rpc_store)
        self.load()

    def to_dict(self):
        return [b.to_dict() for b in self.buffs.itervalues()]

    @property
    def roll_id(self):
        """ 食卷id """
        return self.player._game.setting_mgr.setdefault(FOOD_ROLL, FOOD_ROLL_V)

    @property
    def food_buff_times(self):
        return self.player._game.setting_mgr.setdefault(FOOD_BUFF_TIME, FOOD_BUFF_TIME_V)

    @property
    def delay_times(self):
        """ 延迟多少秒可以进食 """
        cur_time = int(time.time())
        pass_times = cur_time - self.use_time
        food_buff_times = self.food_buff_times
        if pass_times >= food_buff_times:
            return 0
        return int((food_buff_times - pass_times))

    def update_buff(self, buff):
        buff.modify()

    def add_buff(self, buff):
        """ 添加buff, 检查时效 """
        if buff.is_timeout:
            return
        buff.data.pid = self.player.data.id
        buff.save(self.player._game.rpc_store)
        self.buffs[buff.data.id] = buff
        return buff

    def get_buff(self, bid):
        return self.buffs.get(bid)

    def del_buff(self, buff, check=True):
        """ buff过期，删除buff """
        if not buff:
            return False
        if check and not buff.is_timeout:
            return False
        self.buffs.pop(buff.data.id)
        buff.delete(self.player._game.rpc_store)
        return True

    def iter_food_buffs(self):
        """ 获取当前玩家的食馆buff """
        for buff in self.buffs.values():
            if buff.data.t == BUFF_TYPE_FOOD:
                yield buff

    def eat(self, bid, t, pack_msg=True):
        """ 进食,允许重复进食,新的buff会覆盖掉旧的 """
        res_buff = self.player._game.res_mgr.buffs.get(bid)
        if res_buff is None:
            return False, errcode.EC_VALUE

        #花费
        if t == EAT_COST_ROLL:
            cost = res_buff.cost
            rs = self.player.bag.cost_item(self.roll_id, cost) is not None
        else:
            coin2, coin3 = res_buff.coin2, res_buff.coin3
            rs = self.player.cost_coin_ex(aCoin2=coin2, aCoin3=coin3, log_type=COIN_BUFF_EAT)
        if not rs:
            return False, errcode.EC_COST_ERR

        #删除旧的食馆buff
        for b in self.iter_food_buffs():
            self.del_buff(b, check=False)
        #增加
        buff = Buff.new_by_res(BUFF_TYPE_FOOD,
                res_buff, res_buff.get_plan_buff(),
                self.food_buff_times)
        self.add_buff(buff)
        self.player.log_normal(PL_EAT, bid=bid)
        cur_time = int(time.time())
        self.use_time = cur_time
        self.player.play_attr.set(FOOD_USE_TIME, cur_time)
        if pack_msg:
            return True, self.player.pack_msg_data(coin=True, buffs=[buff])
        return True, buff


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



