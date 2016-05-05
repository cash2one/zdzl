#!/usr/bin/env python
# -*- coding:utf-8 -*-
from fish import *

@deco_event1
def test_allyOwn(player):
    return player.ally.allyOwn()

@deco_event2
def test_allyCreate(player, ally_name):
    return player.ally.allyCreate(ally_name)

@deco_event1
def test_allyCPost(player):
    return player.ally.allyCPost(u'测试改变')

@deco_event2
def test_allyApply(player, aid):
    return player.ally.allyApply(aid)

@deco_event1
def test_allyApplicants(player):
    return player.ally.allyApplicants()

@deco_event3
def test_allyHDApply(player, pid, state):
    return player.ally.allyHDApply(pid, state)

@deco_event3
def test_allyCDuty(player, pid, duty):
    return player.ally.allyCDuty(pid, duty)

@deco_event2
def test_allyKick(player, pid):
    return player.ally.allyKick(pid)

@deco_event1
def test_allyQuit(player):
    return player.ally.allyQuit()

@deco_event1
def test_allyMembers(player):
    return player.ally.allyMembers()

@deco_event1
def test_allyOtherMembers(player):
    return player.ally.allyOtherMembers(56)

@deco_event1
def test_allyAllyList(player):
    return player.ally.allyAllyList(1)

@deco_event2
def test_allyAllyPost(player, aid):
    return player.ally.allyAllyPost(aid)

@deco_event1
def test_allyLog(player):
    return player.ally.allyLog()

@deco_event1
def test_allyDismiss(player):
    return player.ally.allyDismiss()

@deco_event1
def test_allyEnterCat(player):
    return player.ally.allyEnterCat()

@deco_event1
def test_allyCat(player):
    return player.ally.allyCat()

@deco_event1
def test_allyGraveEnter(player):
    return player.ally.allyGraveEnter()

@deco_event2
def test_allyGrave(player, t):
    return player.ally.allyGrave(t)

@deco_event1
def test_allyTTBoxEnter(player):
    return player.ally.allyTTBoxEnter()

@deco_event1
def test_allyTTBoxList(player):
    return player.ally.allyTTBoxList()

@deco_event2
def test_allyTTBoxNew(player, tbid):
    return player.ally.allyTTBoxNew(tbid)

@deco_event2
def test_allyTTBoxInfo(player, tid):
    return player.ally.allyTTBoxInfo(tid)

@deco_event2
def test_allyTTBoxAdd(player, tid):
    return player.client.call_allyTTBoxAdd(tid =tid)

def test_m_ally_tbox(player1, player2, player3):
    #pid1 = 3139, pid2 = 3140, pid3 = 3141  ally_id =94
    ally_id =94
    pid1 = 3139
    pid2 = 3140
    pid3 = 3141
    #test_allyCreate(player1, "test_ally_tbox")
    #test_allyOwn(player1)
    #test_allyApply(player2, ally_id)
    #test_allyApply(player3, ally_id)
    #test_allyApplicants(player1)
    #test_allyHDApply(player1, pid2, True)
    #test_allyHDApply(player1, pid3, True)
    #test_allyOwn(player2)
    #test_allyOwn(player3)
    test_allyTTBoxEnter(player1)
    boss_id = 2
    test_allyTTBoxNew(player1, boss_id)
    test_allyTTBoxList(player1)
    test_allyTTBoxAdd(player2, 2)

    rs = player1.client.call_TeamFight(tid =2)
    print rs


def test_m_ally(player1, player2 = None):
    #test_allyCreate(player2, "测试测试")
    #test_allyOwn(player2)
    ##test_allyCPost(player2)
    #test_allyApply(player1, 56)
    #test_allyApplicants(player2)
    #test_allyApplicants(player1)
    #test_allyHDApply(player2, 1201, True)
    ##test_allyCDuty(player2, 1201, 2)
    ##test_allyKick(player2, 1201)
    #test_allyQuit(player1)
    #test_allyMembers(player2)
    #test_allyOtherMembers(player2)
    test_allyAllyList(player2)
    #test_allyLog(player2)
    #test_allyDismiss(player2)
    test_allyEnterCat(player2)
    #test_allyCat(player2)
    #test_allyCat(player2)
    test_allyGraveEnter(player2)
    test_allyGrave(player2, 1)
