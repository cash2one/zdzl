#!/usr/bin/env python
# -*- coding:utf-8 -*-


from .base import PlayerProp

class PlayerShop(PlayerProp):
    def __init__(self, player):
        super(PlayerShop, self).__init__(player)
        self.info =None

    def enter(self, t):
        """ 进入 """
        rs  = self.player.client.call_shop(t=t)
        return rs

    def buy(self, t, sid):
        """ 猎怪结束 """
        return self.player.client.call_shopBuy(t=t, sid=sid)

    def dshopBuy(self, id, c):
        return self.player.client.call_dshopBuy(id=id, c=c)

    def goodsPay(self, gorder, pid):
        return self.player.client.call_goodsPay(gorder=gorder, pid=pid)
