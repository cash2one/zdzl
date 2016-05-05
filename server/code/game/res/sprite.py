#!/usr/bin/env python
# -*- coding:utf-8 -*-

import math
from game.store import StoreObj
from corelib import log

class ResMonster(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.quality = 0
        self.act = ''
        self.npc = 0
        self.sk1 = 0
        self.sk2 = 0

class ResMonsterLevel(StoreObj):
    def init(self):
        self.id = None
        self.mid = 0
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

    def update_data(self):
        """ 更新数据公式为字符串，整形为整形的保存 """
        dic = self.to_dict()
        for attr, value in dic.iteritems():
            if attr in ('id', 'mid'):
                continue
            try:
                if value.isdigit():
                    v = int(value)
                else:
                    v = float(value)
                    if value.endswith('.0'):
                        v = int(float(value))
            except:
                v = value
            dic[attr] = v

    def get_attr(self, R=0, L=0, CBE=0, AL=0, FL=0):
        """ 计算公式得到属性值 """
        dic = self.to_dict()
        attr_dict = dic.copy()
        for attr, value in dic.iteritems():
            if not isinstance(value, str):
                continue
            attr_dict[attr] = int(math.ceil(eval(value)))
        return attr_dict

class ResNpc(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.func = 0
        self.msg = ''
        self.isShowName = 0 #0/1
        self.dir = 0

