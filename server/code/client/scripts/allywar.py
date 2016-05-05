#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import sleep

def awar_test1(player):
    """ 同盟狩龙测试 """
    #进入房间
    rs = player.awar.awar_enter_room()
    print 'enter_room -- ',rs

    #邀请玩家
    rs = player.awar.awar_sky_invite('1')
    print 'invite -- ', rs

    #进入房间 邀请进入
    #rs = player.awar.awar_enter_room(1)
    #print 'enter_room1 -- ',rs

    sleep(1)
    #开战
    rs = player.awar.awar_start()
    print 'awar_start --', rs

    sleep(3)

    rs = player.awar.awar_book_use(1)
    print 'awar_book use ---', rs
    rs = player.awar.awar_book_use(2)
    print 'awar_book use ---', rs

    sleep(10)
    #击杀怪物
    npcids = range(1,5)
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'awar-monster-start --',rs

        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
        sleep(1)
    sleep(5)
    npcids = range(5,10)

    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'awar-monster-start --',rs

        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
        sleep(1)
    sleep(10)

def awar_test2(player):
    """ 同盟狩龙测试 """
    #进入房间
    rs = player.awar.awar_enter_room()
    print 'enter_room -- ',rs

    #邀请玩家
    #rs = player.awar.awar_sky_invite('1')
    #print 'invite -- ', rs

    #进入房间 邀请进入
    #rs = player.awar.awar_enter_room(1)
    #print 'enter_room1 -- ',rs

    sleep(1)
    #开战
    rs = player.awar.awar_start()
    print 'awar_start --', rs

    #选择势力地图
    rs_map = player.awar.awar_choose(1, 1)
    print 'choose--', rs_map


    sleep(5)
    #击杀怪物
    npcids = range(7,9)
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
        sleep(1)
    sleep(5)
    #选择势力地图
    rs_map = player.awar.awar_choose(9, 1)
    print 'choose--', rs_map
    sleep(5)
    #击杀怪物
    npcids = range(9,11)
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
        sleep(1)

    #选择势力地图
    rs_map = player.awar.awar_choose(11, 1)
    print 'choose--', rs_map
    sleep(5)
    #击杀怪物
    npcids = range(11,13)
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
        sleep(1)
    print 'awar-monster-start --',rs


    #选择势力地图
    rs_map = player.awar.awar_choose(15, 1)
    print 'choose--', rs_map
    sleep(5)
    #击杀怪物
    npcids = range(13,15)
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
        sleep(1)
    print 'awar-monster-start --',rs

    #选择势力地图
    rs_map = player.awar.awar_choose(16, 1)
    print 'choose--', rs_map
    sleep(5)
    #击杀怪物
    npcids = range(15,16)
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
        sleep(1)
    print 'awar-monster-start --',rs
    sleep(40)

def awar_test3(player):
    #进入房间
    rs = player.awar.awar_enter_room()
    print 'enter_room -- ',rs

    #邀请玩家
    rs = player.awar.awar_sky_invite('1')
    print 'invite -- ', rs

    #进入房间 邀请进入
    #rs = player.awar.awar_enter_room(1)
    #print 'enter_room1 -- ',rs

    sleep(1)
    #开战
    rs = player.awar.awar_start()
    print 'awar_start --', rs

    sleep(3)
    #击杀怪物
    npcids = range(1,3)
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'awar-monster-start --',rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'awar-monster-end ----', rs
        sleep(1)
    sleep(10)
    print '*'*10
    #开炮
    for i in xrange(3):
        for i in xrange(2):
            rs = player.awar.awar_fire(i)
            print 'awar-fire --', rs
        sleep(112)

def awar_test3(player):
    """ 同盟狩龙测试 """
    #进入房间
    rs = player.awar.awar_enter_room()
    print 'enter_room -- ',rs

    #开战
    rs = player.awar.awar_start()
    print 'awar_start --', rs

    sleep(3)

    sleep(1)
    #击杀怪物
    npcids = [1, 2, 3, 4, 5, 6]
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'awar-monster-start --',rs

        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
        sleep(1)
    #npcids = [1, 2, 3, 9, 10, 12]
    npcids = [7, 8, 9, 10, 11, 12]
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'awar-monster-start --',rs

        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
        sleep(1)
    sleep(5)
#    npcids = range(13,25)
#
#    for npcid in npcids:
#        rs = player.awar.awar_monster_start(npcid)
#        print 'awar-monster-start --',rs
#
#        sleep(1)
#        rs = player.awar.awar_monster_end(npcid, 1)
#        print 'monster-end ----', rs
#        sleep(1)
#    sleep(10)


def awar_test4(player):
    """ 同盟狩龙测试 """
    #进入房间
    rs = player.awar.awar_enter_room()
    print 'enter_room -- ',rs

    #邀请玩家
    #rs = player.awar.awar_sky_invite('1')
    #print 'invite -- ', rs

    #进入房间 邀请进入
    #rs = player.awar.awar_enter_room(1)
    #print 'enter_room1 -- ',rs

    sleep(1)
    #开战
    rs = player.awar.awar_start()
    print 'awar_start --', rs

    #选择势力地图
    rs_map = player.awar.awar_choose(1, 1)
    print 'choose--', rs_map


    sleep(3)
    #击杀怪物
    npcids = [27, 28, 29, 30, 31, 32]
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
    npcids = [33, 34, 35, 36, 37, 38]
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
    sleep(2)

    #选择势力地图
    rs_map = player.awar.awar_choose(9, 1)
    print 'choose--', rs_map
    sleep(2)
    #击杀怪物
    npcids = [39, 40, 41, 42, 43, 44]
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
    npcids = [45, 46, 47, 48, 49, 50]
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
    #选择势力地图
    rs_map = player.awar.awar_choose(11, 1)
    print 'choose--', rs_map
    sleep(2)
    #击杀怪物
    npcids = [51, 52, 53, 54, 55, 56]
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
    npcids = [57, 58, 59, 60, 61, 62]
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs

    #选择势力地图
    rs_map = player.awar.awar_choose(15, 1)
    print 'choose--', rs_map
    sleep(2)
    #击杀怪物
    npcids = [63, 64, 65, 66, 67, 68]
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
        #击杀怪物
    npcids = [69, 70, 71, 72, 73, 74]
    for npcid in npcids:
        rs = player.awar.awar_monster_start(npcid)
        print 'monster-start----', rs
        sleep(1)
        rs = player.awar.awar_monster_end(npcid, 1)
        print 'monster-end ----', rs
    print 'awar-monster-start --',rs