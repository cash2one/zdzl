#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj

class ResFeteRate(StoreObj):
    def init(self):
        self.id = None
        self.type = 0
        self.rate = 0
        self.rid = 0
