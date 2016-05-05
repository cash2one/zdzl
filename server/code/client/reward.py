#!/usr/bin/env python
# -*- coding:utf-8 -*-


class Reward(object):

    def __init__(self, player):
        self.client = player.client

    def rewardTime(self):
        return self.client.call_rewardTime()

    def rewardActiveEnter(self):
        return self.client.call_rewardActiveEnter()

    def rewardActive(self, t, lv = 1):
        return self.client.call_rewardActive(t = t, lv = lv)

    def rewardCode(self, code):
        return self.client.call_rewardCode(code = code)