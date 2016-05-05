#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj

class FishQuality(StoreObj):

    def init(self):
        self.id = None
        self.fid = 0
        self.qt = 0
        self.rid = 0
