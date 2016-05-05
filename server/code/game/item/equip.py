#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store import StoreObj, GameObj
from game.store.define import TN_P_EQUIP
from game.base import common

class EquipData(StoreObj):
    __slots__ = ('id', 'pid', 'eid', 'level', 'used', 'isTrade', 'gem')
    def init(self):
        #标示
        self.id = None
        #玩家id
        self.pid = 0
        #装备id
        self.eid = 0
        #装备等级
        self.level = 0
        #是否使用
        self.used = 0
        #是否交易
        self.isTrade = 0
        #珠宝
        self.gem = {} #{index : gem_id}

class Equip(GameObj):
    __slots__ = GameObj.__slots__
    TABLE_NAME = TN_P_EQUIP
    DATA_CLS = EquipData
    def __init__(self, adict=None):
        if adict and 'gem' in adict:
            adict['gem'] = common.decode_dict(adict['gem'], ktype=int, vtype=int)
        super(Equip, self).__init__(adict=adict)

    @classmethod
    def new_by_res(cls, res_equip, is_trade=0):
        equip = cls()
        equip.update(dict(eid=res_equip.id, isTrade=int(is_trade)))
        return equip

    def save(self, store, forced=False):
        self.data.gem = common.decode_dict(self.data.gem, ktype=str, vtype=int)
        super(Equip, self).save(store, forced)
        self.data.gem = common.decode_dict(self.data.gem, ktype=int, vtype=int)

