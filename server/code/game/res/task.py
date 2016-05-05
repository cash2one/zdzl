#!/usr/bin/env python
# -*- coding:utf-8 -*-
from corelib import log
from game.store import StoreObj
from game.base.common import str2dict1

class ResChapter(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.start = 0 #是否初章
        self.startTid = 0
        self.endTid = 0
        self.mid = 0


class ResTask(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.icon = ''
        self.info = ''
        self.type = 0
        self.unlock = ''
        self.nextId = 0
        self.rid = 0
        self.step = ''

        #runtime
        self.parent = None

    def runtime_init(self, tasks):
        """ 将解锁条件的字符串的数据转为字典 """
        if self.nextId:
            next_task = tasks.get(self.nextId)
            if next_task is not None:
                assert not getattr(next_task, 'parent')
                next_task.parent = self
        #level:1:100|role:7:8|tid:1|obj:1:3|equ:5 -->
        # {level:[1,100], role:[7,8],tid:[1, 3],equ:[5], obj:[1,3]...}
        #obj的最后一个数量先不管，拥有时判断即可
        try:
            self.unlock = str2dict1(self.unlock)
            if self.unlock is None:
                self.unlock = {}
        except:
            log.error(u'任务(%d)解锁条件错误:%s', self.id, self.unlock)
        self.unlock_level = map(int, self.unlock['level']) if 'level' in self.unlock else 0
        self.unlock_roles = map(int, self.unlock['role']) if 'role' in self.unlock else None
        self.unlock_tasks = map(int, self.unlock['tid']) if 'tid' in self.unlock else None
        self.unlock_objs = map(int, self.unlock['obj']) if 'obj' in self.unlock else None
        self.unlock_equs = map(int, self.unlock['equ']) if 'equ' in self.unlock else None
        self.auto = bool(int(self.unlock['auto'][0])) if 'auto' in self.unlock else True
        #if not self.auto:
        #    log.debug("*!*"* 20)
        

class ResBfTask(StoreObj):
    def init(self):
        self.id = None
        self.type = ''
        self.quality = 0
        self.tid = ''
        self.rid = 0

        #runtime
        self.parent = None

class ResBfRate(StoreObj):
    def init(self):
        self.id = None
        self.type = 0
        self.part = 0
        self.rate = 0
        self.quality = 0

        #runtime
        self.parent = None