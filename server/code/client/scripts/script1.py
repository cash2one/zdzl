#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import sleep

from client.player import User, Player
from .player import login, test_arm, fete_test, bf_task_test, merge_items_test,sit_test
from .equip import equip_move_test
from .role import wear_takeoff_eq, wear_takeoff_fate, merge_fate_test
from .fate import hit_fate_test
from .tbox import tbox_test
from .boss import ally_boss_test, world_boss_teset, ally_boss_notice, world_boss_notice
from .add_exps import test_tasks
from .allywar import awar_test1, awar_test2, awar_test3, awar_test4
#from .gm import test_gm

#import config

def test_copy(host, port):
    """ 第一章所有任务完成累计经验的测试 """
    addr = (host, int(port))
    name, pwd, UDID, DT = 'ab10', 'abc1', "ABC", "ABC"
    #用户登录
    player = login(addr, name, pwd, UDID, DT, name)
    sleep(1)
    player.logout()
    sleep(22)
    player.client.close()

def add_exps(host, port):
    """ 第一章所有任务完成累计经验的测试 """
    addr = (host, int(port))
    name, pwd, UDID, DT = 'ab10', 'abc1', "ABC", "ABC"
    #用户登录
    player = login(addr, name, pwd, UDID, DT, name)

    test_tasks(player)
    sleep(1)
    player.logout()
    sleep(0.2)
    player.client.close()

def test3(host, port):
    """ 物品合成测试 """
    addr = (host, int(port))
    #name, pwd, UDID, DT = 'abc1', 'abc1', "ABC", "ABC"
    #name, pwd, UDID, DT = '15467203', '', "2e745448eddfecae048f2230123cb51c", "9117f7216960f32d435dfca2685dae2a"
    name, pwd, UDID, DT = '15631365', '', "9236ecaad32f4081533b469232f70037", "7156e592284b695b82ed98dc44bad61d"
    #用户登录
    player = login(addr, name, pwd, UDID, DT, name)
    #武器升级测试(测试大于一定等级时取回技能)
    #test_arm(player, 1)
    #player.game_master.clear_player()
    #时光盒
    #tbox_test(player)

    #world_boss_notice(player)

    #world_boss_teset(player)

    #awar_test1(player)

    #awar_test2(player)

    awar_test4(player)


    sleep(1)
    player.logout()
    sleep(0.2)
    player.client.close()

def test2(host, port):
    addr = (host, int(port))
    name, pwd, UDID, DT = 'abc2', 'abc1', "ABC", "ABC"
    #用户登陆
    player = login(addr, name, pwd, UDID, DT, name)
    print '-------------'

    #装备等级转移的测试
    #equip_move_test(player)

    #合并命格
    #merge_fate_test(player, 0)

    #猎命测试
    #hit_fate_test(player, 1, isBatch=0)

    #祭天测试
    #fete_test(player, 2)

    #兵符任务测试
    #bf_task_test(player)

    #物品合成
    #merge_items_test(player)

    #时光盒
    #tbox_test(player)

    #打坐测试
    #sit_test(player)

    #boss战
    #同盟
    #ally_boss_test(player)
    #世界
    #world_boss_teset(player)

    #world_boss_notice(player)
    import rank
    rs = rank.test_rankEnter(player, 5, 1)
    print 'rs----rank --- %s', rs

    #player.game_master.reward(100002)

    #获取玩家物品
    #print '-------------'
    #playIlist = player.bag.bag_get_ilist()
    #print playIlist
    sleep(100)
    #sleep(1)
    player.logout()
    sleep(0.2)
    player.client.close()


def test1(host, port):
    addr = (host, int(port))
    name, pwd, UDID, DT = 'abc1', 'abc1', "ABC", "ABC"


    player = login(addr, name, pwd, UDID, DT, name)

    #test_arm(player, 2)
    #test_gm(player)

    #print 'player.bag_add_fate = ', player.bag.bag_add_fate(1,1,1,0)
    #player.gm('p=myself();p.add_money(2, 3333, 2222)')

    #装备
    #add_equip(player, 2)
    #装备的脱穿(装备id, 配将id)
    #print 'wear_takeoff_eq = ', wear_takeoff_eq(player, 6, 34)

    #rs = player.role.roleup_do(6)
    #print 'rs----roleup_do', rs


    #rs = player.role.roleup_train(6, 0)
    #print 'rs---roleup_train', rs

    #rs = player.role.roleup_train_svae(6)
    #print 'rs--roleup_train_svae', rs

    import rank
    rs = rank.test_rankEnter(player, 4, 1)
    print 'rs----rank --- %s', rs

    player.logout()
    print 'ok--------------'
    player.client.close()


from . import over
def over_login_test(id, host, port):
    """ 登陆压力的测试 """
    name = 'over1_%s' % id
    player = over.enter(name, host, port)
    player.logout()
    player.client.close()
    return 1


def test_boss(start, end, host='dev.zl.efun.com', port=8002):
    """ 压力测试1:模拟多个角色进入并行走 """
    from .over import over_boss
    over_boss(int(start), int(end), host, port)

def test_chat(host, port):
    from .over import over_chat
    over_chat(1, 15, host, port)

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


