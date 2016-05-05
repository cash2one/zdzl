#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import *

class Awar(PlayerProp):

    def __init__(self, player):
        super(Awar, self).__init__(player)
        self.client = player.client
        self.player.client.add_listener(self)
        self.info = None

    def on_awarNotice(self, status, kw, err):
        """ boss广播开启时间 """
        print 'on_awarNotice----', kw

    def on_awarStartB(self, status, kw, err):
        """ 开战广播 """
        print 'on_awarStartB-----', kw

    def on_awarMosterStartB(self, status, kw, err):
        """ 开始击杀怪物广播 """
        print 'on_awarMosterStartB----',kw
        
    def on_awarMosterEndB(self, status, kw, err):
        """ 击杀怪物结束广播 """
        print 'on_awarMosterEndB----',kw

    def on_awarWorldMapB(self, status, kw, err):
        """ 势力地图广播 """
        print 'on_awarWorldMapB----', kw

    def on_awarFireB(self, status, kw, err):
        """ 开炮广播 """
        print 'on_awarFireB----', kw

    def awar_enter_room(self, rnum=0):
        """ 进入房间 """
        return self.client.call_awarEnterRoom(rnum=rnum)

    def awar_sky_invite(self, msg):
        """ 房间邀请 """
        return self.client.call_awarSkyInvite(msg=msg)

    def awar_exit_room(self):
        """ 退出房间 """
        return self.client.call_awarExitRoom()


    def awar_start(self):
        """ 开战 """
        return self.client.call_awarStart()


    def awar_choose(self, node, type):
        """ 选择势力地图 """
        return self.client.call_awarWorldChoose(node=node, type=type)

    def awar_monster_start(self, ancid):
        """ 击杀怪物开始 """
        return self.client.call_awarMosterStart(ancid=ancid)

    def awar_monster_end(self, ancid, isWin):
        """ 击杀怪物结束 """
        return self.client.call_awarMosterEnd(ancid=ancid, isWin=isWin)

    def awar_copy_start(self, ancid):
        """ 击杀 """
        return self.client.call_awarCopyStart(ancid=ancid)

    def awar_book_use(self, bid):
        """ 使用兵书 """
        return self.client.call_awarBookUse(bid=bid)
    
    def awar_fire(self, index):
        """ 开炮 """
        return self.client.call_awarFire(index=index)
    