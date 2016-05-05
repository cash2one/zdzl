#!/usr/bin/env python
# -*- coding:utf-8 -*-

from store.store import StoreObj

class ResEveryDayAchievement(StoreObj):
    """每日成就"""
    def init(self):
        self.id = None    #成就id
        self.name = '' #成就名
        self.info = '' #成就内容
        self.rid = 0 #奖励id
        self.target = '' #任务目标

class ResEternalAchievement(StoreObj):
    """永久成就"""
    def init(self):
        self.id = None    #成就id
        self.name = '' #成就名
        self.info = '' #成就内容
        self.rid = 0 #奖励id
        self.target = '' #任务目标
        self.tname = '' #类型名称
        self.group = None  #分组
        self.level = None  #档次