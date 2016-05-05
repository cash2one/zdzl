#!/usr/bin/env python
# -*- coding:utf-8 -*-

from fish import *


@deco_event1
def test_rewardTime(player):
    return player.reward.rewardTime()

@deco_event1
def test_rewardActiveEnter(player):
    return player.reward.rewardActiveEnter()

@deco_event3
def test_rewardActive(player, t, lv):
    return player.reward.rewardActive(t, lv)


def t_reward(player):
    print "++++++++++++++1"
#    test_rewardTime(player)
#    test_rewardActiveEnter(player)
 #   test_rewardActive(player, 1, 1)
    #sleep(200)
    rs = player.reward.rewardCode('7b4857ece1')
    print rs
    print "++++++++++++++2"
