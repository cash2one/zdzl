#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import PlayerProp

class PlayerDeep(PlayerProp):
    def __init__(self, player):
        super(PlayerDeep, self).__init__(player)
        self.info =None

    def enter(self, type=0):
        rs = self.player.client.call_deepEnter(type=type)
        self.info = rs
        return rs

    def box(self):
        return self.player.client.call_deepBox()

    def fight(self, type):
        return self.player.client.call_deepFight(type=type)

    def auto(self):
        """ 挂机 """
        return self.player.client.call_deepAuto()
