#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj

class ResMap(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.type = 0 #1:标准地图, 2:副本地图, 3=钓鱼, 4=采矿, 5=时光盒, 6=深渊, 7=同盟
        self.pmid = 0 #用于副本地图类型返回到主地图
        self.tiledFile = ''
        self.multi = 0 #0/1

    @property
    def is_stage(self):
        return self.type == 2

class ResStage(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.mapId = 0
        self.monster = ''

class ResFight(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.BG = ''
        self.rid = 0
        self.s1 = ''
        self.s2 = ''
        self.s3 = ''
        self.s4 = ''
        self.s5 = ''
        self.s6 = ''
        self.s7 = ''
        self.s8 = ''
        self.s9 = ''
        self.s10 = ''
        self.s11 = ''
        self.s12 = ''
        self.s13 = ''
        self.s14 = ''
        self.s15 = ''

class ResPosition(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.act = ''
        self.eye = 0

class ResPositionLevel(StoreObj):
    def init(self):
        self.id = None
        self.pid = 0
        self.level = 0
        self.lockLevel = 0
        self.lockTask = 0
        self.coin1 = 0
        self.s1 = ''
        self.s2 = ''
        self.s3 = ''
        self.s4 = ''
        self.s5 = ''
        self.s6 = ''
        self.s7 = ''
        self.s8 = ''
        self.s9 = ''
        self.s10 = ''
        self.s11 = ''
        self.s12 = ''
        self.s13 = ''
        self.s14 = ''
        self.s15 = ''

    def can_unlock(self, player):
        """ 是否可以解锁 """
        return player.data.level >= self.lockLevel and \
                (not self.lockTask or self.lockTask in player.task.tid_bm)



