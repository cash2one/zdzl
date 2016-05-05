#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import *

class PlayerRole(PlayerProp):
    def __init__(self, player):
        super(PlayerRole, self).__init__(player)
        self.client = player.client

    def role_roles(self):
        """ 获取配将列表 """
        return self.client.call_roles()

    def role_wear_fate(self, id, rid, place):
        """ 穿命格 """
        return self.client.call_wearFt(id=id, rid=rid, place=place)

    def role_tackoff_fate(self, id, rid, place):
        """ 脱命格 """
        return self.client.call_tackOffFt(id=id, rid=rid, place=place)

    def role_merge_fate(self, id1, id2, rid=0):
        """ 命格合并 """
        return self.client.call_mergeFt(id1=id1, id2=id2, rid=rid)

    def role_merge_all_fate(self):
        """ 命格一键合成"""
        return self.client.call_mergeAllFt()

    def role_enter_hitFate(self):
        """ 进入猎命获取初始数据 """
        return self.client.call_enterHitFate()

    def role_hitFate(self, type, isBatch=0):
        """ 进行猎命 """
        return self.client.call_hitFate(type=type, isBatch=isBatch)

    def role_wear_eq(self, id, rid):
        """ 穿装备 """
        return self.client.call_wearEq(id=id, rid=rid)

    def role_tackoff_eq(self, id, rid):
        """ 脱装备 """
        return self.client.call_tackOffEq(id=id, rid=rid)

    def role_enter_enterFete(self):
        """ 进入祭天获取初始数据 """
        return self.client.call_enterFete()

    def role_fete(self, type):
        """ 进行祭天 """
        return self.client.call_fete(type=type)

    def roleup_enter(self, rid):
        """ 进入升段 """
        return self.client.call_roleUpEnter(rid=rid)

    def roleup_do(self, rid):
        """ 武将升段 """
        return self.client.call_roleUpDo(rid=rid)

    def roleup_train(self, rid, type):
        """ 武将培养 """
        return self.client.call_roleUpTrain(rid=rid, type=type)

    def roleup_train_svae(self, rid):
        """ 武将培养保存 """
        return self.client.call_roleUpTrainOk(rid=rid)

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


