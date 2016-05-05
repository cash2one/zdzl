#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib.common import log

def log_dict(d):
    for k,v in d.iteritems():
        log.debug('%s : %s', k, v)
        log.debug('---------------------')

def test_arena_enter(player):
    #进入竞技场
    rs = player.arena.enter()
    log_dict(rs)
    return rs

def get_arena_rival(player, rivals):
    rival = rivals.pop()
    if player.name == rival[u'n']:
        rival = rivals.pop()
    return rival

def test_arena_start(player, rid):
    #开始挑战
    rs = player.arena.start_arena(rid)
    log_dict(rs)
    return rs

def test_arena_end(player, isOK, rid, fp):
    rs = player.arena.arena_end(isOK, rid, fp)
    log_dict(rs)
    return rs

def test_arena_get_reward(player, rk):
    rs = player.arena.get_reward(rk)
    print rs
    return rs

def test_arena_buy(player, c):
    rs = player.arena.arena_buy(c)
    print rs
    return rs