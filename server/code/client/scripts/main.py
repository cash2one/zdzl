#!/usr/bin/env python
# -*- coding:utf-8 -*-
from .player import *
from .scene import test_scene
from .gm import test_gm, test_show
from corelib.common import import1, log
from .bag import sellAll

from .deep import test_deep
from .shop import test_shopEnter, test_shopBuy, test_dshopBuy, test_goodsPay
from .ally import *
from .activity import *
from .rank import test_rankEnter

def main(host, port, name='test_main', pwd='test_main'):
    """ 主测试脚本 """
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, pwd, UDID, DT)
    #user.del_all()
    player = enter_player(user, name)
    player.game_master.clear_player()
    test_show(player)
    #test_scene(player)
    #test_buff(player)
    #test_gm(player)
    #test_task(player)
    #test_fishBatch(player)
    #test_fishUp(player)
    #test_fishEnter(player)
    #test_fishOnce(player)
    #test_fishUp(player)
    #test_entrustNpcFish(player)
    #test_fishUp(player)
    #test_show(player)


def test(host, port, test_name, name='test_main', pwd='test_main'):
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, pwd, UDID, DT)
    player = enter_player(user, name)
    md = 'client.scripts.%s' % test_name
    script = import1(md)
    script(player)


def see(host='172.16.40.13', port=8002, name='test_see'):
    UDID = name
    DT = name
    addr = (host, int(port))
    print addr
    user = login_user(addr, name, name, UDID, DT, sns=0)
    #user.del_all()
    player = enter_player(user, name)
    test_goodsPay(player)
    #print player.game_master.copy(526)
    #player.game_master.clear_player()
    #test_show(player)
    #test_scene(player)
    #test_buff(player)
    #test_waitbag(player)
    #test_gm(player)
    #test_task(player)
    #test_chapter(player)
    #test_deep(player)
    #test_chat(player)
    #print player.game_master.del_player(802)
    #player.game_master.del_player(801)
    #test_mail(player)
    #test_arena(player)
    #test_show(player)

#def test163(host= '172.16.8.38', port=8002, name1 = 'test_163'):
def test_ally(host= '172.16.40.133', port=8002, name = '163_apply'):
    print "---------------test163 start---------------"
    name1 = name + "1"
    UDID = name1
    DT = name1
    addr = (host, int(port))
    print addr
    user1 = login_user(addr, name1, name1, UDID, DT)
    player1 = enter_player(user1, name1)

    name2 = '163_apply'
    UDID = name2
    DT = UDID
    addr = (host, int(port))
    print addr
    user2 = login_user(addr, name2, name2, UDID, DT)
    player2 = enter_player(user2, name2)
    test_m_ally(player1, player2)

    print "---------------test163 end---------------"
def test_fish(host= '172.16.40.133', port=8002, name = 'test_fish'):
    from fish import *
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, name, UDID, DT)
    player = enter_player(user, name)
    #player.game_master.add_item(DES_ITEM_ID, 30)
    testFish(player)

def testdeep(host= '172.16.40.133', port=8002, name = 'test_deep'):
    from fish import *
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, name, UDID, DT)
    player = enter_player(user, name)
    test_deep(player)

def test_mine(host= '172.16.40.133', port=8002, name = 'test_mine'):
    from .mining import *
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, name, UDID, DT)
    player = enter_player(user, name)
    testMining(player)

def over1(start, end, host='dev.zl.efun.com', port=8002):
    """ 压力测试1:模拟多个角色进入并行走 """
    from .over import over1
    over1(int(start), int(end), host, port)

def over_move(start, end, action=0, host='dev.zl.efun.com', port=8002):
    """ 压力测试1:模拟多个角色进入并行走 """
    from .over import over_move
    over_move(int(start), int(end), action, host, port)



def test_shop(host='127.0.0.1', port=8002,name='abc2'):
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, 'abc1', UDID, DT)
    #user.del_all()
    player = enter_player(user, name)
    ret = test_shopEnter(player, 1)
    print 'shopEnter:',ret
    print test_shopBuy(player, 1, ret['ret']['sids'][0])
    ret = test_shopBuy(player, 1, 3)
    print 'ret:::::',ret

def test_dbuy(host='127.0.0.1', port=8002,name='abc2'):
    UDID = name
    DT = name
    addr = (host, int(port))
    print addr
    user = login_user(addr, name, 'abc1', UDID, DT)
    #user.del_all()
    player = enter_player(user, name)
    ret = test_dshopBuy(player, 3, 1)
    print 'ret:',ret

def test_rank(host='172.16.40.11', port=8002, name='test_see'):
    UDID = name
    DT = name
    addr = (host, int(port))
    print addr
    user = login_user(addr, name, name, UDID, DT)
    #user.del_all()
    player = enter_player(user, name)
    ret = test_rankEnter(player, t=1, p=1)
    print 'ret:',ret

def test_reward(host = '127.0.0.1', port = 8002, name = 'test_reward'):
    UDID = name
    DT = name
    addr = (host, int(port))
    #print addr
    user = login_user(addr, name, name, UDID, DT)
    #user.del_all()
    player = enter_player(user, name)
    from .reward import t_reward
    t_reward(player)

def test_social(host = '127.0.0.1', port = 8002, name = 'ttt_est'):
    UDID = name
    DT = name
    addr = (host, int(port))
    user1 = login_user(addr, name, name, UDID, DT)
    player1 = enter_player(user1, name)
    name1 = name + str(1)
    DT = name1
    UDID = name1
    addr = (host, int(port))
    user2 = login_user(addr, name1, name1, UDID, DT)
    player2 = enter_player(user2, name1)

    from .social import test_m_social, test_m_social1
    test_m_social(player1, player2)
    #test_m_social1(player1)


def test_arena(host = '127.0.0.1', port = 8002, name = 'test_arena1'):
    UDID = name
    DT = name
    addr = (host, int(port))
    print addr
    user = login_user(addr, name, name, UDID, DT)
    #user.del_all()
    player = enter_player(user, name)

    rs = test_arena_enter(player)

#    c = 1
#    test_arena_buy(player, c)
#    return
#
#    rk = rs[u'rk']
#    test_arena_get_reward(player, rk)
#    #return
#
#    rivals = []
#    rivals.extend(rs[u'rivals'])
#    rival = get_arena_rival(player, rivals)
#    rid = int(rival[u'pid'])
#    test_arena_start(player, rid)
#
#    isOK = 0
#    fp = '123123123'
#    test_arena_end(player, isOK, rid, fp)

def test_libo(host = '172.16.80.250', port = 8002, name = 't_libo1'):
    UDID = name
    DT = name
    addr = (host, int(port))
    #print addr
    user = login_user(addr, name, name, UDID, DT)
    #user.del_all()
    player = enter_player(user, name)
    from .reward import t_reward
    t_reward(player)

def test_ally_tbox(host = '172.16.40.23', port = 8002, name = 'test_ally_tbox1'):
    #pid1 = 3139, pid2 = 3140, pid3 = 3141  ally_id =94
    UDID = name
    DT = name
    addr = (host, int(port))
    user1 = login_user(addr, name, name, UDID, DT)
    player1 = enter_player(user1, name)

    name1 = name + str(1)
    DT = name1
    UDID = name1
    addr = (host, int(port))
    user2 = login_user(addr, name1, name1, UDID, DT)
    player2 = enter_player(user2, name1)

    name2 = name1 + str(1)
    DT = name2
    UDID = name2
    addr = (host, int(port))
    user3 = login_user(addr, name2, name2, UDID, DT)
    player3 = enter_player(user3, name2)

    from .ally import test_m_ally_tbox
    test_m_ally_tbox(player1, player2, player3)

def test_level_gift(host = '172.16.80.250', port = 8002, name = 't_level_gift'):
    UDID = name
    DT = name
    addr = (host, int(port))
    #print addr
    user = login_user(addr, name, name, UDID, DT)
    #user.del_all()
    player = enter_player(user, name)
    from gevent import sleep
    sleep(600)

def test_fight_win(host = '172.16.80.250', port = 8002, name = 't_fight_win'):
    UDID = name
    DT = name
    addr = (host, int(port))
    #print addr
    user = login_user(addr, name, name, UDID, DT)
    #user.del_all()
    player = enter_player(user, name)

    rs = player.client.call_fightWin(fid = 79)
    print rs
    rs = player.client.call_fightWin(fid = 79)
    print rs

def test_achi(host = 'egame1.f3322.org', port = 38002, name = 't_achi5'):
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, name, UDID, DT)
    player = enter_player(user, name)
    from gevent import sleep
    sleep(6000)

def test_team_fight(host = '172.16.40.23', port = 8002, name = 't_libo_team_fight'):
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, name, UDID, DT)
    player = enter_player(user, name)

    rs = player.client.call_TeamFight(tid =1)
    print rs


def test_vip_attr(host = '172.16.40.133', port = 8002, name = 't_vip_attr'):
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, name, UDID, DT, sns=1)
    player = enter_player(user, name)
    from vipattr import vip_attr
    vip_attr(player)

def test_day_sign(host = '172.16.40.133', port = 8002, name = 't_day_sign'):
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, name, UDID, DT)
    player = enter_player(user, name)
    from day_sign import day_sign
    day_sign(player)

def test_goodbuy(host = '127.0.0.1', port = 8002, name = 't_goodbuy'):
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, name, UDID, DT)
    player = enter_player(user, name)

    rs = player.client.call_goodsBuy(t=11, gid=1)
    print rs