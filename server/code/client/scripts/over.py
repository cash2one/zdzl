#!/usr/bin/env python
# -*- coding:utf-8 -*-
import random
from corelib import spawn, sleep, Event, log
from game.base.constant import MAIL_NORMAL, MAIL_REWARD, MAIL_BATTLE
from .player import login_user, enter_player, test_task, test_buff, test_chat, test_mail
from .deep import test_deep
import deep
deep.DEBUG = 0

from client import scene, chat, player
scene.DEBUG = 0
chat.DEBUG = 0
player.DEBUG = 0

valid_map_infos = {
    #9:['{124,166}', '{69,104}', '{10,10}', '{149,195}', ],
    1:['{94, 100}','{93,99}','{92,98}','{104, 81}', '{118, 104}', '{99, 133}',
       '{128, 94}', '{110, 84}', '{108, 114}',
       '{138, 94}', '{130, 104}', '{148, 80}',
    ],
    3:['{113, 63}', '{5, 173}', '{31, 105}', '{5, 173}', '{91, 7}', '{37, 72}'
       ],
    4:['{50, 54}', '{55, 58}', '{104, 106}', '{101, 102}', '{28, 47}',
       '{50, 90}', '{85, 112}'
       ],
    5:['{72, 43}', '{51, 46}', '{37, 65}', '{39, 56}', '{32, 67}', '{30, 118}',
       '{84, 26}', '{29, 72}', '{116, 130}',
        ]
}

def enter(name, host, port):
    UDID = name
    DT = name
    addr = (host, int(port))
    user = login_user(addr, name, name, UDID, DT)
    player = enter_player(user, name)
    return player

def close(user):
    user.logout()
    
class TestCase1:
    @staticmethod
    def test_chat(player):
        """ 聊天测试 """
        #log.debug('test_chat')
        player.chat.chat_send(1, u'(%s)世界测试', player.name)

    @staticmethod
    def test_look_player(player):
        """ 常看信息 """
        #log.debug('test_look_player')
        player.look_player(player.id, player.id)

    @staticmethod
    def test_get_rank(player):
        """ 获取排行榜 """
        #log.debug('test_get_rank')
        type_nums = range(1, 3)
        page_nums = range(1, 5)
        type = random.choice(type_nums)
        page = random.choice(page_nums)
        player.rank.enter(type, page)

    @staticmethod
    def test_do_eq(player):
        """ 操作装备穿脱 """
        roles = player.role.role_roles()
        role = random.choice(roles)
        parts = range(1, 6)
        part_place = random.choice(parts)
        part = 'eq%d' % part_place
        eid = role[part]
        if eid:
            rid = role['id']
            #脱掉
            player.role.role_tackoff_eq(eid, rid)
            #穿上
            player.role.role_wear_eq(eid, rid)
            #log.debug('test_do_eq--ok')



    @classmethod
    def get_tests(cls):
        return [getattr(cls, n) for n in dir(cls) if n.startswith('test_')]

class TestCase:
    @staticmethod
    def test_chat(player):
        player.chat.chat_send(1, u'(%s)世界测试', player.name)
        #player.chat.chat_send(2, u'(%s)系统测试', player.name)
        #player.chat.chat_send(3, u'(%s)大喇叭测试', player.name)
        sleep(0.5)

    @staticmethod
    def test1_deep(player):
        player.deep.enter(0)
        #print player.deep.auto()
        #sleep(100)
        player.deep.fight(1)
        player.deep.enter(1)
        player.deep.box()
        player.deep.enter(0)

    @staticmethod
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

    @staticmethod
    def test_buff(player):
        player.game_master.add_coin(aCoin3=25)
        player.buffs.eat(1, 2)

    @staticmethod
    def test1_mail(player):
        pid = 0#1189
        if not pid:
            pid = player.id
        items = [dict(t='i', i=1, c=1000), dict(t='i', i=38, c=2)]
        player.game_master.send_mails(pid, MAIL_NORMAL, u'标题', u'内容', items)
        player.game_master.send_mails(pid, MAIL_REWARD, u'奖励', 1, items)
        #player.game_master.send_mails(pid, MAIL_BATTLE, u'奖励', u'内容', items)

        mail = player.mail
        for i in xrange(120):
            sleep(0.5)
            if mail.count >= 2:
                break
        for mid in mail.mails.keys():
            mail.receive(mid)

    @classmethod
    def get_tests(cls):
        return [getattr(cls, n) for n in dir(cls) if n.startswith('test_')]


def _test(name, p, tests, func_times):
    random.shuffle(tests)
    sleep(3)
    #log.debug(u'(%s)清理数据', name)
    #p.clear_all()
    p.reinit()
    #地图行走
    mid = random.choice(valid_map_infos.keys())
    p.scene.enter_map(mid)
    #            log.debug(u'(%s)进入地图(%d)', name, mid)
    poses = valid_map_infos[mid]
    for i in xrange(7):
        pos = random.choice(poses)
        p.scene.move_str(pos)
        if tests:
            test_func = tests.pop()
#            log.debug(u'(%s) over test(%s)', name, test_func.func_name)
            try:
                test_func(p)
            except:
                log.log_except()
        sleep(random.choice(func_times))

def over1(start, end, host, port):
    """ 压力测试1:模拟多个角色进入 """
    func_times = range(8, 20)
    move_times = range(1, 2)
    wait_event = Event()
    count = 0
    tasks = []
    TESTS = TestCase.get_tests()
    def _show_info():
        while 1:
            sleep(10)
            log.info(u'******tasks(%s / %s) runing', len(tasks), count)

    def _test_one(name):
        tasks.append(name)
        try:
            p = enter(name, host, port)
            log.debug(u'玩家(%s)进入', name)
            p.valid_gm()
            while 1:
                _test(name, p, TESTS[:], func_times)
                #close(p.user)
        except KeyboardInterrupt:
            wait_event.set()
        except:
            log.log_except()
        finally:
            tasks.remove(name)

    for i in xrange(start, end+1):
        count += 1
        name = 'over1_%s' % i
        spawn(_test_one, name)
    spawn(_show_info)
    wait_event.wait()

def over_move(start, end, action, host, port):
    """ 压力测试1:模拟多个角色进入并行走 action:行为测试"""
    func_times = range(8, 15)
    move_times = range(1, 10)
    wait_event = Event()
    if action:
        TESTS = TestCase1.get_tests()
    def _test_one(name):
        p = enter(name, host, port)
        p.valid_gm()
        log.debug(u'玩家(%s)进入', name)
        #完成初章
        p.tasks.complete_chapter()
        #骑马
        p.game_master.add_car(3)
        p.game_master.car_do(3)
        while 1:
            mid = random.choice(valid_map_infos.keys())
            p.scene.enter_map(mid)
            #log.debug(u'(%s)进入地图(%d)', name, mid)
            poses = valid_map_infos[mid]
            for i in xrange(2):
                pos = random.choice(poses)
                p.scene.move_str(pos)
                #log.debug(u'(%s)地图移动(%s)', name, pos)
                sleep(random.choice(move_times))
            if action:
                _test(name, p, TESTS[:], func_times)

    for i in xrange(start, end+1):
        if i % 50 == 0:
            sleep(5)
        name = 'over1_%s' % i
        spawn(_test_one, name)

    wait_event.wait()

def over_boss(start, end, host, port):
    """ 测试世界boss """
    hit_hp = range(10000, 100000)
    wait_event = Event()
    def _test_boss(name):
        print 'name --- %s', name
        player = enter(name, host, port)
        player.valid_gm()
        log.debug(u'玩家(%s)进入', name)
        while 1:
            player.boss.boss_enter()
            player.boss.boss_start()
            hurt = random.choice(hit_hp)
            player.boss.boss_finish(hurt)
            sleep(10)
    for i in xrange(start, end+1):
        name = 'over1_%s' % i
        spawn(_test_boss, name)
    wait_event.wait()


def over_chat(start, end, host, port):
    """ 测试聊天 """
    wait_event = Event()
    def _test_boss(name):
        print 'name --- %s', name
        player = enter(name, host, port)
        player.valid_gm()
        log.debug(u'玩家(%s)进入', name)
        while 1:
            player.chat.chat_send(1, u'(%s)世界测试', player.name)
            sleep(2)
            player.chat.chat_send(2, u'(%s)世界测试', player.name)
            sleep(2)
            player.chat.chat_send(2, u'(%s)世界测试', player.name)
            sleep(2)
    for i in xrange(start, end+1):
        name = 'over1_%s' % i
        spawn(_test_boss, name)
    wait_event.wait()





