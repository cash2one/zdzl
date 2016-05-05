#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj

class ResHornMsg(StoreObj):

    def init(self):
        self.id = None
        self.type = 0
        self.msg = ''
        self.cond = ''

