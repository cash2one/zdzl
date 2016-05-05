#!/usr/bin/env python
# -*- coding:utf-8 -*-

def test_init(player):
    rs = player.sign.test_isDid()
    print "*"*30
    print rs
    print "*"*30


def test_sign(player):
    rs = player.sign.sign()
    print "#"*30
    print rs
    print "#"*30

def day_sign(player):
    print "^"*70
    test_init(player)
    test_sign(player)
    print "v"*70
    from corelib import sleep
    sleep(200)
