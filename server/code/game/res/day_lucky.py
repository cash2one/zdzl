#!/usr/bin/env python
# -*- coding:utf-8 -*-

from store.store import StoreObj

class ResDayLuckys(StoreObj):
    """ 每日抽奖活动 """
    def init(self):
        self.id = None
        #对应的奖励(rid, int)
        self.rid = 0
        #出现在抽奖格子的概率(srate, int)-1=必出
        self.srate = 0
        #被抽到的概率(lrate, int)
        self.lrate = 0
        #出现的条件(cond, int)
        #0=无条件，1=创号前三天登陆，2=创号三天后，3=已招募武将, 4=未招募奖励
        self.cond = 0


