#!/usr/bin/env python
# -*- coding:utf-8 -*-
from .base import *
#from DebugMessage import CALL_TRACK_PATH_PRINT

class PlayerFish(PlayerProp):

    def __init__(self, player):
        super(PlayerFish, self).__init__(player)
        self.client = player.client

    def fish_enter(self):
        return self.client.call_fishEnter()

    def fish_up(self, iid, num, qt):
        return self.client.call_fishUp(iid=iid, num=num, qt=qt)

    def fish_give_up(self, iid, t):
        return self.client.call_fishGiveup(iid=iid, t=t)