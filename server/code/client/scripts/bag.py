#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import sleep

from client.player import User, Player

import config

def ilist(aUser):
    """ 获取玩家物品 """
    tRs = aUser.get_ilist()
    return tRs

def iwait(aUser):
    """ 待收物品列表 """
    tRs = aUser.bag_iwait()
    return tRs

def sellAll(aUser, equip, item, fate):
    """ 批量卖出 """
    tRs = aUser.bag.bag_sellAll(equip, item, fate)
    return tRs

def add_item(aUser, iid, count):
    """ 添加物品 """
    tRs = aUser.bag_add_item(iid, count)
    return tRs

def bag_merge_item(aUser, desId, count, srcId):
    """ 物品合成 """
    tRs =  aUser.bag_merge_item(desId, count, srcId)
    return tRs



#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


