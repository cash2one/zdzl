#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj
from game.base.constant import ALL_PROPS

class ResFate(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.act = ''
        self.quality = 0
        self.beginExp = 0
        self.rate = 0.0
        self.price = 0

    def init_fate(self, fate_levels):
        self.effect = fate_levels[0].get_effect() if fate_levels else ''
        self.is_exp_fate = 0 if fate_levels else 1

class ResFateLevel(StoreObj):
    BASE_FIELDS = ('id', 'fid', 'level', 'exp', 'price')
    def init(self):
        self.id = None
        self.fid = 0
        self.level = 0
        self.exp = 0
        for k in ALL_PROPS:
            setattr(self, k, 0)
        if 0:
            self.STR = 0
            self.DEX = 0
            self.VIT = 0
            self.INT = 0
            self.HP = 0
            self.ATK = 0
            self.STK = 0
            self.DEF = 0
            self.SPD = 0
            self.MP = 0
            self.MPS = 0
            self.MPR = 0
            self.HIT = 0
            self.MIS = 0
            self.BOK = 0
            self.COT = 0
            self.COB = 0
            self.CRI = 0
            self.CPR = 0
            self.PEN = 0
            self.TUF = 0

    def get_effect(self):
        """ 初始化命格作用的效果 """
        for k in ALL_PROPS:
            if not getattr(self, k):
                continue
            return k


class ResFateRate(StoreObj):
    def init(self):
        self.id = None
        self.type = 0 #类型:1=普通 2=高级
        self.mid = 0 #怪物id
        self.rate = 0
        self.rid = 0 #奖励id


class ResFateCost(StoreObj):
    def init(self):
        self.id = None
        self.num = 0
        self.coin1 = 0
        self.coin2 = 0
        self.coin3 = 0




