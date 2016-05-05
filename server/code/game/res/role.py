#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store import StoreObj

class ResRole(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.job = 0
        self.armId = 0
        self.act = ''
        self.npc = 0
        self.quality = 0
        self.sk1 = 0
        self.sk2 = 0
        self.index = 0
        self.disLV = 0
        self.invLV = 0
        self.invs = ''
        self.price = 0
        self.useId = 0
        self.useNum = 0

    @property
    def is_main(self):
        """ 约定id小于等于20的是主将 """
        return self.id <= 20

class ResRoleLevel(StoreObj):
    def init(self):
        self.id = None
        self.rid = 0
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

class ResRoleExp(StoreObj):
    def init(self):
        self.level = 0
        self.exp = 0
        self.siteExp = 0

    @property
    def id(self):
        return self.level


class ResNames(StoreObj):
    def init(self):
        self.id = None
        self.sex = 0 # 0=不区分 1=男 2=女
        self.t = 0 #类型: 1=姓 2=名
        self.n = ''



#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
