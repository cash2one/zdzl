#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import *

class PlayMining(PlayerProp):

    def __init__(self, player):
        super(PlayMining, self).__init__(player)
        self.client = player.client

    def enter(self):
        return self.client.call_mineEnter()

    def mining(self, type, is_batch):
        return self.client.call_mine(type = type, isbatch = is_batch)