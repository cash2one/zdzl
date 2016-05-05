#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj

class ResAllyLevel(StoreObj):

    def init(self):
        self.id = None
        self.dt1Num = 0
        self.dt2Num = 0
        self.dt3Num = 0
        self.dt4Num = 0
        self.dt5Num = 0
        self.dt6Num = 0
        self.exp = 0
        self.level = 0
        self.maxNum = 0

class ResAllyRight(StoreObj):

    def init(self):
        self.id = None
        self.change = 0
        self.check = 0
        self.duty = 0
        self.kick = 0
        self.post = 0
        self.name = ""

class ResAllyGrave(StoreObj):

    def init(self):
       self.id = None
       self.t = 0
       self.coin1 = 0
       self.coin3 = 0
       self.lv1arm = 0
       self.lv2arm = 0
       self.lv3arm = 0
       self.lv4arm = 0
       self.lv5arm = 0
       self.lv6arm = 0
       self.lv7arm = 0
       self.lv8arm = 0
       self.lv9arm = 0
       self.lv10arm = 0


class ResAllyBoatLevel(StoreObj):
    """同盟狩龙各类的等级"""

    def init(self):
        self.id = None
        self.t = 0
        self.lv = 0
        self.nlv = 0
        self.exp = 0
        self.t = 0
        self.us = 0


class ResAllyExchange(StoreObj):
    """同盟天舟物品兑换"""

    def init(self):
        self.id = None
        self.rid = 0
        self.glory = 0


#class ResAllyDragonNum(StoreObj):
#    """同盟职位对应狩龙次数表"""
#
#    def init(self):
#        self.id = None
#        self.lv = 0
#        self.dt1 = 0
#        self.dt2 = 0
#        self.dt3 = 0
#        self.dt4 = 0
#        self.dt5 = 0
#        self.dt6 = 0


#class ResAllyBook(StoreObj):
#    """天书"""
#    def init(self):
#        self.id = None
#        self.name = ""
#        self.buff = 0
#        self.time = 0


#class ResAllyDragonAssess(StoreObj):
#    """魔龙将世评级表"""
#
#    def init(self):
#        self.id = None
#        self.t = 0
#        self.num = 0
#        self.way = 0
#        self.n = ""
#        self.rid = 0

