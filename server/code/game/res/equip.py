#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj
from game.base.constant import ALL_PROPS

class ResEquip(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.act = ''
        self.sid = 0
        self.part = 0
        self.limit = 0
        self.price = 0
        self.rate = 0
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


class ResEquipLevel(StoreObj):
    def init(self):
        self.id = None
        self.part = 0 #1=头,2=身,3=脚,4=项链,5=腰带,6=戒子
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

    def runtime_init(self):
        props = []
        for k in ALL_PROPS:
            if not getattr(self, k):
                continue
            props.append(k)
        self.props = props

class ResEquipSet(StoreObj):
    EFFECT_TMP = 'effect%d'
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.effect2 = ''
        self.effect4 = ''
        self.effect6 = ''
        self.quality = 0
        self.lv = 0 #装备等级
        self.cond = 0

    def get_effect(self, n):
        effect = ''
        for i in xrange(n):
            attr = self.EFFECT_TMP % (i + 1)
            attr = getattr(self, attr, None)
            if attr is None:
                continue
            effect = attr
        return effect

class ResStrongEquip(StoreObj):
    def init(self):
        self.id = None
        self.level = 0
        self.useId = 0
        self.count = 0
        self.mvCoin1 = 0



