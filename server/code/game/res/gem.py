#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store import StoreObj
from game.base.constant import ALL_PROPS

class ResGem(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.act = ''
        self.quality = 0
        self.parts = ''
        self.price = 0
        self.rate = 0
        self.type = 0

class ResGemLevel(StoreObj):
    def init(self):
        self.id = None
        self.gid = 0
        self.level = 0
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

class ResGemUpRate(StoreObj):
    def init(self):
        self.id = None
        self.fq = 0 #材料品质
        self.flv = 0 #材料等级
        self.tq = 0 #提升品质
        self.tlv = 0 #提升等级
        self.succ = 0 #成功率
