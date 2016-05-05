#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import *

class Sign(PlayerProp):

    def __init__(self, player):
        super(Sign, self).__init__(player)
        self.client = player.client

    def test_isDid(self):
        return self.client.call_daySignDid()

    def sign(self):
        return self.client.call_daySign()
