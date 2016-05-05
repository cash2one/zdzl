#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store import StoreObj, GameObj
from game.store.define import TN_P_FATE
from game.base.constant import FATE_INIT_LEVEL

class FateData(StoreObj):
    __slots__ = ('id', 'pid', 'fid', 'level', 'exp', 'used', 'isTrade')
    def init(self):
        #标示
        self.id = None
        #玩家id
        self.pid = 0
        #命格id
        self.fid = 0
        #命格等级
        self.level = 0
        #命格经验
        self.exp = 0
        #是否使用
        self.used = 0
        #是否交易
        self.isTrade = 0

class Fate(GameObj):
    __slots__ = GameObj.__slots__
    TABLE_NAME = TN_P_FATE
    DATA_CLS = FateData
    def __init__(self, adict=None):
        super(Fate, self).__init__(adict=adict)

    @classmethod
    def new_by_res(cls, res_fate, is_trade=0):
        fate = cls()
        fate.data.fid = res_fate.id
        fate.data.level = FATE_INIT_LEVEL
        fate.data.exp = res_fate.beginExp
        fate.data.isTrade = int(is_trade)
        return fate


