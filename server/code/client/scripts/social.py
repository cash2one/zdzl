#!/usr/bin/env python
# -*- coding:utf-8 -*-
from fish import *

#@deco_event1
#def test_socialEnter(player):
#    return player.social.socialEnter()

@deco_event3
def test_socialGetInfo(player, t, page):
    return player.social.socialGetInfo(t, page)

@deco_event2
def test_addFriend(player, pid):
    return player.social.socialaddFriend(pid)

@deco_event2
def test_delFriend(player, pid):
    return player.social.socialDelFriend(pid)

@deco_event2
def test_addBlack(player, pid):
    return player.social.socialAddBlack(pid)

@deco_event2
def test_addBlack_name(player, name):
    return player.social.socialAddBlackName(name)

@deco_event2
def test_delBlack(player, pid):
    return player.social.socialDelBlack(pid)

@deco_event2
def test_changeName(player, name):
    return player.social.socialChangeName(name)


def test_m_social1(player1):
    #test_socialGetInfo(player1, 1, 1)
    #test_socialEnter(player1)
    #test_addFriend(player1, 2518)
    #test_delFriend(player1, 2518)
    #test_addBlack(player1, 2518)
    #test_delBlack(player1, 2518)
    from corelib import sleep
    sleep(200)

def test_m_social(player1, player2):
    #test_socialGetInfo(player1, 1, 1)
    test_changeName(player1, u"改变名字")
    #test_socialGetInfo(player2, 1, 1)
    #test_socialEnter(player1)
    #test_socialEnter(player2)
    #test_delBlack(player1, 2518)
    #test_addBlack_name(player1, u"怀禹晨")
    #test_addBlack_name(player1, u"怀禹晨")
    #test_addBlack_name(player1, u"怀禹晨")
    #test_delFriend(player1, 2518)
    #test_addFriend(player1, 2518)
    #test_addBlack(player1, 2518)
    from corelib import sleep
    sleep(200)
