#!/usr/bin/env python
# -*- coding:utf-8 -*-

DEBUG = 1
def log(msg):
    if DEBUG:
        print(msg)

def test_deep(player):
    log(player.deep.enter(0))
    #print player.deep.auto()
    #sleep(100)
    #log(player.deep.fight(1))
    #log(player.deep.enter(1))
    #log(player.deep.box())
    #log(player.deep.enter(0))
    from corelib import sleep
    sleep(200)
