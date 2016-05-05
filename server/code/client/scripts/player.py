#!/usr/bin/env python
# -*- coding:utf-8 -*-

import random
from game.base.constant import MAIL_NORMAL, MAIL_REWARD, MAIL_BATTLE

from client.player import User, Player

RIDS = [1,2,3,4,5,6]

def login_user(addr, name, pwd, UDID, DT, sns=0):
    """ 登陆 """
    user = User()
    if not sns:
        user.login(name, pwd, addr, UDID=UDID, DT=DT)
    else:
        user.loginSNS(addr, 1, name, pwd, UDID=UDID, DT=DT)
    return user

def enter_player(user, player_name, sex=1, rid=0):
    players = user.get_players()
    if not players:
        #新建用戶
        if not rid:
            rid = random.choice(RIDS)
        user.new_player(player_name, rid)
        players = user.get_players()
    player = user.enter(players[0]['id'])
    return player

def login(addr, name, pwd, UDID, DT, player_name):
    """ 登陆 """
    user = login_user(addr, name, pwd, UDID, DT)
    player = enter_player(user, player_name)
    return player

def test_chapter(player):
    print player.tasks.complete_chapter()

def test_task(player):
    player.tasks.tasks = []
    player.game_master.accept_tasks()
    for i in xrange(5):
        sleep(0.5)
        if not player.tasks.tasks:
            continue
        task = player.tasks.tasks[0]
        player.tasks.complete(task['id'])
        return

def test_buff(player):
    player.game_master.add_coin(aCoin3=25)
    player.buffs.eat(1, 2)


def test_waitbag(player):
    player.game_master.add_wait_item(1, '[{"t":"f", "i":22,"tr":0}]')
    player.wait_bag.fetch(1)

def test_merge_item(player):
    """ 物品合成测试 """
    player.game_master.clear_player()
    #清楚背包内所有物品信息
    #添加合成的物品
    #合成
    
def test_arm(player, skill_back_type=1):
    """ 武器升级测试(测试大于一定登记时取回技能) """
    tRoles = player.role.role_roles()
    tRole = tRoles[0]
    print "test_arm_role = ", tRole
    #升级
    print "test_arm_up_grade = ", player.arm_upgrade(tRole['id'])
    if skill_back_type == 1:
        #取回技能(普通)
        print "test_arm_skill_back_1 = ", player.skill_back(tRole['id'], 1)
    else:
        #取回技能(元宝)
        print "test_arm_skill_back_2 = ", player.skill_back(tRole['id'], 2)

def fete_test(player, type):
    """ 祭天测试 """
    if 0:
        from client.player import Player
        player = Player()
    #进入祭天
    rs = player.role.role_enter_enterFete()
    print "role_enter_enterFete = %s", rs
    #进行祭天
#    for i in xrange(50):
#        rs = player.role.role_fete(type)
#        if rs.has_key('item'):
#            print 'item-count-', rs['item'][0]['count']
#        else:
#            print 'item--NO--', rs['frid']
    rs = player.role.role_fete(type)
    print "role_fete = %s", rs


#刷新方式（客户端）
#免费刷新
RESET_FREE = 1 #包括两种
#元宝刷新
RESET_COIN2 = 2
#全紫刷新
RESET_ALL = 3

def bf_task_test(player):
    """ 兵符任务测试
    """
    #清楚背包中的物品
    #player.game_master.clear_part_data('bag')
    #playIlist = player.bag.bag_get_ilist()
    #print playIlist['item']
    #进入兵符任务
    rsEnter = player.tasks.bf_task_enter()
    print 'bf_task_enter = ', rsEnter
    #刷新兵符任务
    rs = player.tasks.bf_task_re(RESET_FREE)
    print 'bf_task_re = ', rs
    #接任务
#    if rsEnter['tids']:
#        index = rsEnter['status'].index(1)
#        tid = rsEnter['tids'][index+2]
#        print 'tid ----- ', tid
#        rs = player.tasks.bf_task_get(1)
#        print 'bf_task_get = ', rs
#    player.update_task()
#    print 'tasks = ', player.tasks.tasks
#    #完成任务
#    if not player.tasks.tasks:
#        return
#    for task in player.tasks.tasks:
#        if task['rid']:
#            rs = player.tasks.complete(task["id"])
#            print 'complete = ', rs
#    player.update_task()
    print 'tasks = ', player.tasks.tasks

    #立即完成
#    rs = player.tasks.bf_task_finish()
#    print 'bf_task_finish = ', rs
    #开宝箱
#    rs = player.tasks.bf_task_box()
#    print 'bf_task_box = ', rs

DES_ITEM_ID = 36
SRC_ITEM_ID= 35

def merge_items_test(player):
    """ 物品合成 """
    #清楚背包中的物品
    player.game_master.clear_part_data('bag')
    player.game_master.add_item(SRC_ITEM_ID, 11)
    #player.game_master.add_item(DES_ITEM_ID, 1)
    playIlist = player.bag.bag_get_ilist()
    print playIlist['item']
    #合成
    rs = player.bag.bag_merge_item(DES_ITEM_ID, 1, SRC_ITEM_ID)
    print 'bag_merge_item = ', rs
    playIlist = player.bag.bag_get_ilist()
    print playIlist['item']


from corelib import sleep
def sit_test(player):
    """ 打坐测试 """
    #上线获取打坐数据
    rs = player.sit.online_sit()
    print "online_sit-rs -------------", rs
    #开始打坐
    player.sit.stop_sit()
    rs = player.sit.start_sit()
    print "start_sit-rs -------------", rs
    sleep(21)
    #rs = player.sit.stop_sit()
    print 'stop_sit-rs -------------', rs

def test_chat(player):
    player.chat.chat_send(1, u'(%s)世界测试', player.name)
    player.chat.chat_send(2, u'(%s)系统测试', player.name)
    player.chat.chat_send(3, u'(%s)大喇叭测试', player.name)
    sleep(0.5)

def test_mail(player):
    pid = 0#1189
    if not pid:
        pid = player.id
    items = [dict(t='i', i=1, c=1000), dict(t='i', i=38, c=2)]
    player.game_master.send_mails(pid, MAIL_NORMAL, u'标题', u'内容', items)
    player.game_master.send_mails(pid, MAIL_REWARD, u'奖励', u'内容', items)
    #player.game_master.send_mails(pid, MAIL_BATTLE, u'奖励', u'内容', items)

    mail = player.mail
    for i in xrange(120):
        sleep(0.5)
        if mail.count >= 2:
            break
    for mid in mail.mails.keys():
        mail.receive(mid)


