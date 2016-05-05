#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .player import login

def deco_event(func):
    def _func(p):
        print "s>>c:>>",func.__name__,
        ret = func(p)
        print "the result is:",ret
        return ret
    return _func

@deco_event
def test_mining_enter(player):
    return player.mining.enter()

@deco_event
def test_mining_once(player):
    return player.mining.mining(1, False)

@deco_event
def test_mining_batch(player):
    return player.mining.mining(1, True)

@deco_event
def test_mining_vip_once(player):
    return player.mining.mining(2, False)

@deco_event
def test_mining_vip_batch(player):
    return player.mining.mining(2, True)

@deco_event
def test_mining_free_once(player):
    return player.mining.mining(3, False)

@deco_event
def test_mining_free_batch(player):
    return player.mining.mining(3, True)

def testMining(player):
    test_mining_enter(player)
    #test_mining_once(player)
    #test_mining_batch(player)
    #test_mining_vip_once(player)
    #test_mining_vip_batch(player)
    #test_mining_free_once(player)
    #test_mining_free_batch(player)
    from corelib import sleep
    sleep(320)
