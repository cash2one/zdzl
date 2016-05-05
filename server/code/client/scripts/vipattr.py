#!/usr/bin/env python
# -*- coding:utf-8 -*-
from corelib import log

def test_speed_up(player):
    return player.vip_attr.speed_up(1.5)


def vip_attr(player):
    print ">"*20
    log.info("%s", test_speed_up(player))
