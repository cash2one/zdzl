#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store import StoreObj

class ResBossCd(StoreObj):
    """ boss战cd时间 """
    def init(self):
        self.id = None
        self.type = 0
        self.h1 = 0
        self.h2 = 0
        self.times = 0


class ResBossReward(StoreObj):
    """ boss战奖励表 """
    def init(self):
        self.id = 0
        self.type = 0
        self.target = ''
        self.rid = 0

class ResBossLevel(StoreObj):
    """ boss登记表 """
    def init(self):
        self.id = 0
        self.type = 0
        self.mid = 0
        self.level = 0
        self.deads = 0

