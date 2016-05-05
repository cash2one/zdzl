#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import *

class PlayerBag(PlayerProp):
    def __init__(self, player):
        super(PlayerBag, self).__init__(player)
        self.client = player.client

    def update(self, ilist):
        self.items = ilist['item']
        self.equips = ilist['equip']
        self.fates = ilist['fate']
        self.cars = ilist['car']

    def bag_iwait(self):
        """ 获取待收取物品列表 """
        return self.client.call_iwait()

    def bag_sellAll(self, equip, item, fate):
        """ 批量卖出 """
        return self.client.call_sellAll(equip=equip, item=item, fate=fate)

    def bag_merge_item(self, desId, count, srcId):
        """ 物品合成 """
        return self.client.call_mergeItem(desId=desId, count=count, srcId=srcId)

    def bag_eq_str(self, eid):
        """ 装备升级 """
        return self.client.call_eqStr(eid=eid)

    def bag_eq_move(self, rid, eid1, eid2):
        """ 装备等级转移 """
        return self.client.call_eqMove(rid=rid, eid1=eid1, eid2=eid2)

    def bag_get_ilist(self):
        """ 获取物品列表 """
        rs = self.client.call_ilist()
        return rs

    def get_item_by_iid(self, aIid):
        """ 通过物品基础id获取物品 """
        tIlist = self.bag_get_ilist()
        for item in  tIlist['item']:
            if item['iid'] == aIid:
                return item
        return


class WaitBag(PlayerProp):
    def __init__(self, player):
        super(WaitBag, self).__init__(player)

    def fetch(self, wtype, id=None):
        if id:
            return self.player.client.call_waitFetch(type=wtype, id=id)
        return self.player.client.call_waitFetch(type=wtype)

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


