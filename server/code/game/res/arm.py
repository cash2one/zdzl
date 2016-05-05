#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj

class ResArm(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.act = ''
        self.quality = 0 #品质
        self.sk1 = 0
        self.sk2 = 0

class ResSkill(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.act = ''
        self.effect = ''
        self.effectRG = 0
        self.effectDIS = 0
        self.range = ''
        self.rHurt1 = 0
        self.rHurt2 = 0
        self.far = 0

class ResArmLevel(StoreObj):
    def init(self):
        self.id = None
        self.aid = 0
        self.level = 0
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
        self.hurt_p = 0
        self.addHp = 0
        self.addHp_p = 0

class ResArmExp(StoreObj):
    def init(self):
        self.id = None
        self.level = 0
        self.exp = 0
        self.limit = 0




#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



