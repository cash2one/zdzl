#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .ally import *

def ally_boss_test(player):
    """ 同盟boss测试 """
    print 'ally_boss_test'
    ally_boss_notice(player)
    #创建同盟
    #test_allyCreate(player, "a_boss_test")
    #进入同盟boss场景
    rs = player.boss.ally_boss_enter()
    print 'enter----', rs
    sleep(2)
    #开始boss战斗
    rs = player.boss.ally_boss_start()
    print 'start----', rs
    #结束boss战斗
    rs = player.boss.ally_boss_finish(8000)
    print 'finish----', rs
    sleep(30)
    #退出boss战场景
    rs = player.boss.ally_boss_exit()
    print 'exit----', rs

def ally_boss_notice(player):
    """ 同盟boss战广播的测试 """
    sleep(15)
    rs = player.boss.ally_boss_enter()
    print 'enter----',rs
    sleep(20)
    rs = player.boss.ally_boss_exit()
    print 'exit---',rs


def world_boss_teset(player):
    """ 世界boss战测试 """
    #rs = player.boss.boss_cd_end()
    #print 'cd----end----',rs
    print 'world_boss_test'
    #进入世界boss场景
    rs = player.boss.boss_enter()
    print 'enter----', rs
    sleep(2)
    #开始boss战斗
    rs = player.boss.boss_start()
    print 'start----', rs
    #结束boss战斗
    rs = player.boss.boss_finish(900000000)
    print 'finish----', rs
    sleep(30)
    #退出boss战场景
    rs = player.boss.boss_exit()
    print 'exit----', rs

def world_boss_notice(player):
    """ 世界boss战广播的测试 """
    sleep(15)
    #进入世界boss场景
    rs = player.boss.boss_enter()
    print 'enter----', rs
    sleep(160)
