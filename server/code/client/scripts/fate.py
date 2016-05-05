#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import sleep

from client.player import User, Player

import config


def hitFate(aUser, aType):
    """ 进行猎命 """
    tRs = aUser.role_hitFate(aType)
    return tRs

def hit_fate_test(player, type, isBatch=0):
    """ 猎命测试
        type:1 普通猎命
        type:2 元宝猎命
    """
    if 0:
        from client.player import Player
        player = Player()
    #print 'play_data = %s, %s, %s ', player.info['coin1'], player.info['coin2'], player.info['coin3']
    #进入猎命

    rs = player.role.role_enter_hitFate()
    #print "role_enter_hitFate = %s", rs
    #进行猎命
    if not isBatch:
        #非批量猎命
        for i in xrange(1):
            rs = player.role.role_hitFate(type)
            print 'rs--type', rs['wait'][0]['items']
    else:
        #批量猎命
        rs = player.role.role_hitFate(type, isBatch)
    #print "role_hitFate = [%s]", rs




#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


