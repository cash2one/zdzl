#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj

class ResDirectShop(StoreObj):
    def init(self):
        self.id = None
        self.iid = 0 #物品id
        self.coin1 = 0
        self.coin2 = 0
        self.coin3 = 0