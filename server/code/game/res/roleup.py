#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store import StoreObj

class ResRoleUps(StoreObj):
    def init(self):
        self.id = None
        self.type = 0
        self.quality = ''
        self.grade = 0
        self.check = 0
        self.attr = {}


class ResRoleUpType(StoreObj):
    def init(self):
        self.id = None
        self.type = 0
        self.rid = 0
