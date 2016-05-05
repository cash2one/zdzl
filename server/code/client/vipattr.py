#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import *
#from DebugMessage import CALL_TRACK_PATH_PRINT

class PlayerVipAttr(PlayerProp):

    def __init__(self, player):
        self.client = player.client

    def speed_up(self, mul):
        return self.client.call_speedUp(mul=mul)
