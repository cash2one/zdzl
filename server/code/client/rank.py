#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import PlayerProp

class PlayerRank(PlayerProp):
    def __init__(self, player):
        super(PlayerRank, self).__init__(player)

    def enter(self, t, p):
        """ 进入 """
        rs  = self.player.client.call_rankEnter(t=t, p=p)
        return rs

