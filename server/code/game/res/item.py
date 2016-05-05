#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store import StoreObj
from game.base.constant import IT_USE_LIST

class ResItem(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.act = ''
        self.quality = 0
        self.type = 0
        self.price = 0
        self.stack = 0
        self.rid = 0
        self.lv = 0#等级限制

    def update(self, adict):
        super(ResItem, self).update(adict)
        if self.stack <= 0:
            self.stack = 1

    def can_use(self):
        """ 是否可以使用 """
        return self.type in IT_USE_LIST

class ResFusion(StoreObj):
    """ 物品合成 """
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.type = ''
        self.desId = 0
        self.srcId = 0
        self.count = 0
        self.coin1 = 0
        self.coin2 = 0
        self.coin3 = 0

class ResCar(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.isExchange = 1
        self.info = ''
        self.act = ''
        self.quality = 0
        self.speed = 0
        self.useId = 0
        self.count = 0
        self.coin1 = 0
        self.coin2 = 0
        self.coin3 = 0


class ResReward(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.reward = ''
        self.useId = 0
        self.useNum = 0






#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



