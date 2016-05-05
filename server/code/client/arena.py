#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import PlayerProp

class PlayerArena(PlayerProp):
    def __init__(self, player):
        super(PlayerArena, self).__init__(player)
        self.player.client.add_listener(self)
        self.info =None

    def enter(self):
        rs = self.player.client.call_arenaEnter()
        self.info = rs
        return rs

    def start_arena(self, rk):
        rs = self.player.client.call_arenaStart(rk=rk)
        return rs

    def arena_end(self, isOK, rid, fp):
        rs = self.player.client.call_arenaEnd(isOK=isOK, rid=rid, fp=fp)
        return rs

    def get_reward(self, rk):
        rs = self.player.client.call_arenaReward(rk=rk)
        return rs

    def arena_buy(self, c):
        rs = self.player.client.call_arenaBuy(c=c)
        return rs

    def on_arenaRivalEnd(self, status, kw, err):
        print 'on_arenaRivalEnd', status, kw, err