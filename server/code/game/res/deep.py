#!/usr/bin/env python
# -*- coding:utf-8 -*-

from random import randint, shuffle

from corelib import log
from game.base.common import make_lv_regions, RandomRegion
from store.store import StoreObj

FLOOR_MAX = 100
FLOOR_BOSS_START = 50
FLOOR_MIN = 0

class ResDeepBox(StoreObj):
    """ 宝箱配置表(deep_box) """
    def init(self):
        self.id = None
        self.fr1 = 0
        self.fr2 = 0
        self.rd = 0 #奖励id或对应等级奖励(rd, int/str)

    def boss_floor(self):
        """当层的怪物为boss"""
        if self.fr1 == self.fr2:
            if self.fr1 == FLOOR_BOSS_START or self.fr2 == FLOOR_BOSS_START:
                return True
            return False
        else:
            return True

    def _get_rids(self):
        try:
            return self.rids
        except AttributeError:
            self.rids = make_lv_regions(self.rd)
            return self.rids

    def get_rid(self, player_level):
        try:
            return int(self.rd)
        except ValueError:
            rids = self._get_rids()
            return rids(player_level)

    def random_floor(self):
        """ 随机出现在某层 """
        if self.fr1 == self.fr2:
            return randint(self.fr1, self.fr2)
        return [fl for fl in xrange(self.fr1, self.fr2+1)]


class ResDeepPos(StoreObj):
    """ 深渊阵型 """
    def init(self):
        self.id = None
        self.lv1 = 0
        self.lv2 = 0
        self.pos = ''

    def update(self, adict):
        super(ResDeepPos, self).update(adict)
        self.get_pid = RandomRegion(self.pos)


class ResDeepGuard(StoreObj):
    """ 怪物配置 """
    def init(self):
        self.id = None
        self.lv1 = 0
        self.lv2 = 0
        self.guard = ''
        self.up = ''

    @property
    def is_boss(self):
        return self.lv1 == 0

    def get_guards(self, player_level, num):
        """ 获取精英怪(或boss) """
        if self.is_boss:
            return self.boss_func(player_level)
        guard_func = getattr(self, 'guard_func', None)
        if not guard_func:
            return None
        guards = self.guard_func(num)
#        for i in xrange(num + 20):
#            guards.add(self.guard_func())
#            if len(guards) == num:
#                break
        guards = list(guards)
        shuffle(guards)
        c = tuple(guards)
        return c

    def update(self, adict):
        super(ResDeepGuard, self).update(adict)
        if self.is_boss: #boss
            self.boss_func = make_lv_regions(self.guard)
        elif self.guard:
            self.guard_func = RandomRegion(self.guard)
        else:
            log.error(u'深渊怪物配置表(%d)怪物配置缺少', self.id)


