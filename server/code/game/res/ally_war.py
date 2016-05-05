#!/usr/bin/env python
# -*- coding:utf-8 -*-


from game.store import StoreObj

class ResAwarstartConfig(StoreObj):

    def init(self):
        self.id = None
        self.type = 0
        self.stime = 0
        self.etime = 0
        self.unlock = 0
        self.ntime = 0
        self.rtime = 0
        self.mplayer = 0
        self.books = ''
        self.mid = 0


class ResAwarperConfig(StoreObj):

    def init(self):
        self.id = None
        self.type = 0
        self.fnum = 0  #第几场战斗
        self.cannon = 0
        self.mapid = 0
        self.wtime = 0 #该场战斗时长
        self.kboss = 0
        self.winway = 0
        self.cannonid = 0
        self.poses = ''
        self.dirs = ''
        self.winway = ''
        self.ishp = 0
        self.cdtime = 0
        self.hurts = ''
        self.refresh = 0
        self.info = ''

class ResAwarNpcConfig(StoreObj):

    def init(self):
        self.id = None
        self.apcid = 0
        self.name = ''
        self.mnpcid = 0
        self.pos = ''
        self.dir = 0
        self.bid = 0
        self.fid = 0
        self.mlids = ''
        self.rid = 0


class ResAwarBook(StoreObj):

    def init(self):
        self.id = None
        self.name = ''
        self.des = ''
        self.buff = ''
        self.uncd = 0
        self.hard = 0
        self.time = 0
        self.rexp = 0
        self.exchange = 0

class ResAwarStrongMap(StoreObj):

    def init(self):
        self.id = None
        self.name = ''
        self.smids = ''
        self.apcid = 0
        self.rid = 0


class ResAwarWorldScore(StoreObj):

    def init(self):
        self.id = None
        self.type = 0
        self.num = 0
        self.way = 0
        self.score = 0

class ResAwarWorldAssess(StoreObj):

    def init(self):
        self.id = None
        self.name = ''
        self.sscore = 0
        self.escore = 0
        self.rid = 0


