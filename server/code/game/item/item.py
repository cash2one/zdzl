#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store import StoreObj, GameObj
from game.store.define import TN_P_ITEM

class ItemData(StoreObj):
    __slots__ = ('id', 'pid', 'iid', 'count', 'isTrade')
    def init(self):
        #标示
        self.id = None
        #玩家id
        self.pid = 0
        #物品id
        self.iid = 0
        #数量
        self.count = 0
        #是否交易
        self.isTrade = 0

class Item(GameObj):
    __slots__ = GameObj.__slots__
    TABLE_NAME = TN_P_ITEM
    DATA_CLS = ItemData
    def __init__(self, adict=None):
        super(Item, self).__init__(adict=adict)

    @classmethod
    def new_by_res(cls, res_item, count, is_trade=0):
        item = cls()
        item.update(dict(iid=res_item.id, count=count, isTrade=int(is_trade)))
        return item




