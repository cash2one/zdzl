#!/usr/bin/env python
# -*- coding:utf-8 -*-
import random

from corelib import log
from game import Game
from game.store import StoreObj
from game.base.constant import FIGHT_ATTR_MP, BUFF_MP, BUFF_MP_V

class ResBuff(StoreObj):
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.act = ''
        self.type = 0
        self.stype = 0
        self.buff = ''
        self.plan = ''
        self.cost = 0
        self.coin2 = 0
        self.coin3 = 0

    def update(self, adict):
        super(ResBuff, self).update(adict)
        self.signs = self.buff.strip().split('|')
        self.rates = self.plan.strip().split('|')
        slen = len(self.signs)
        if (self.rates and slen != len(self.rates)):
            log.error(u'buff表数据(%d)错误:buff=%s, plan1=%s, plan2=%s',
                    self.id, self.buff, self.plan)

#    def get_plan1_buff(self):
#        try:
#            return self._plan1_buff
#        except AttributeError:
#            self._plan1_buff = '|'.join(map(lambda x:'%s:%s' % (x[0], x[1]),
#                    zip(self.signs, self.rates1)))
#            return self._plan1_buff

    def get_plan_buff(self):
        mp_v = Game.setting_mgr.setdefault(BUFF_MP, BUFF_MP_V)
        signs = self.signs[:]
        random.shuffle(signs)
        return '|'.join(map(lambda x:'%s:%s' % (x[0], x[1] if x[0] != FIGHT_ATTR_MP else mp_v),
            zip(signs, self.rates)))



