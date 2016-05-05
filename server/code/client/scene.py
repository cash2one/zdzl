#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import *

DEBUG = 1

class PlayerScene(PlayerProp):
    def __init__(self, player):
        super(PlayerScene, self).__init__(player)
        self.cur_id = player.info['mapId']
        self.pos = player.info['pos']
        self.player.client.add_listener(self)

    def stop(self):
        self.player.client.del_listener(self)

    def on_mapChange(self, status, kw, err):
        if DEBUG:
            print 'on_mapChange:\n', kw

    def enter_map(self, mid):
        rs = self.player.client.call_enterMap(mid=mid)
        #print(rs)
        assert rs['mid'] == mid, 'mid:%d' % mid
        self.cur_id = mid

    def get_players(self):
        rs = self.player.client.call_mapPlayers(mid=self.cur_id)
        return rs

    def move(self, x, y):
        x, y = int(x), int(y)
        self.pos = '{%d,%d}' % (x, y)
        self.move_str(self.pos)

    def move_str(self, x_y):
        self.pos = x_y
        self.player.client.call_move(pos=self.pos, _no_result=True)


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


