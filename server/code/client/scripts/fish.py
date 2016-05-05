#!/usr/bin/env python
# -*- coding:utf-8 -*-
from corelib import sleep

from .player import login

def deco_event1(func):
    def _func(p):
        print "s>>>>>>>>>>>>>c:>>",func.__name__,
        ret = func(p)
        print "the result is:",ret
        return ret
    return _func

def deco_event2(func):
    def _func(p1, p2):
        print "s>>>>>>>>>>>>>c:>>",func.__name__,
        ret = func(p1, p2)
        print "the result is:",ret
        return ret
    return _func

def deco_event3(func):
    def _func(p1, p2, p3):
        print "s>>>>>>>>>>>>>c:>>",func.__name__,
        ret = func(p1, p2, p3)
        print "the result is:",ret
        return ret
    return _func

def deco_event4(func):
    def _func(p1, p2, p3, p4):
        print "s>>>>>>>>>>>>>c:>>",func.__name__,
        ret = func(p1, p2, p3, p4)
        print "the result is:",ret
        return ret
    return _func

@deco_event1
def test_fishEnter(player):
    return player.fish.fish_enter()

@deco_event4
def test_fishUp(player, iid, num, qt):
    return  player.fish.fish_up(iid, num, qt)

#@deco_event3
#def test_fishGiveup(player, iid, t):
#    return player.fish.fish_give_up(iid, t)

def testFish(player):
    test_fishUp(player, 1, 5, 2)
    #test_fishGiveup(player, 1, 1)
