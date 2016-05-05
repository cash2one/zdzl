#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj, GameObj
from game.store.define import TN_P_GEM

class GemData(StoreObj):
    __slots__ = ('id', 'pid', 'gid', 'level', 'upSucc', 'used', 'isTrade')
    def init(self):
        #标示
        self.id = None
        #玩家id
        self.pid = 0
        #珠宝id
        self.gid = 0
        #珠宝等级
        self.level = 0
        #升级成功率保留
        self.upSucc = 0
        #是否使用
        self.used = 0
        #是否交易
        self.isTrade = 0

class Gem(GameObj):
    __slots__ = GameObj.__slots__
    TABLE_NAME = TN_P_GEM
    DATA_CLS = GemData
    def __init__(self, adict=None):
        super(Gem, self).__init__(adict=adict)

    @classmethod
    def new_by_res(cls, res_gem, level, is_trade=0):
        gem = cls()
        gem.data.gid = res_gem.id
        gem.data.level = level
        gem.data.isTrade = int(is_trade)
        return gem