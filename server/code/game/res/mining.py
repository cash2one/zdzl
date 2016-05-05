#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj

class ResMining(StoreObj):

    def init(self):
        self.id = None
        self.type = 0
        self.level1 = 0
        self.level2 = 0
        self.rids = ''
        self.coin1 = 0
        self.coin2 = 0
        self.coin3 = 0