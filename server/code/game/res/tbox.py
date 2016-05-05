#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store import StoreObj

class ResTbox(StoreObj):
    def init(self):
        self.id = None
        self.mid = 0
        self.chapter = ''
        self.rid = 0
        self.place = 0
        #组队炼妖
        self.tmid = 0
        self.trid = 0


