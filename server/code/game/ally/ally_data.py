#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time


from game import Game
from game.store import StoreObj, GameObj
from game.store import TN_ALLY,TN_P_ALLY, TN_ALLY_LOG, TN_PLAYER
from game.base import errcode, common
from game.base.constant import ALLY_MEMBER
from game.base.constant import ALLY_TBOX_NUM, ALLY_TBOX_NUM_V, ALLY_TBOX_RW_NUM, ALLY_TBOX_RW_NUM_V


class AllyAssistData(StoreObj):
    """ 同盟从表 """

    def init(self):
        self.id = None     #ID
        self.gid = 0    #同盟id
        self.pid = 0    #玩家id
        self.exp = 0    #贡献值
        self.duty = 0   #职责
        self.tJoin = 0  #加入时间
        self.ct = 0     #上次招财猫的时间
        self.gt = 0     #上次铭刻的时间
        self.cryn = 0   #龙晶的捐献数量
        self.glory = 0  #玩家的建设度
        self.day_pass_grave()
        self.day_pass_cat()

    def day_pass_cat(self):
        self.cn = 0
        self.ct = common.current_time()

    def day_pass_grave(self):
        self.gn1 = 0     #铭刻的次数
        self.gn2 = 0    #vip铭刻次数
        self.gt = common.current_time()

class AllyLogData(StoreObj):
    """ 活动表 """

    def init(self):
        self.id = None
        self.gid = 0
        self.t = 0      #操作类型1=加入 2=退出 3=贡献 6=任职 7=踢人   5以下的是单人操作以上的是多人操作
        self.ct = 0     #操作的时间
        self.n1 = ""
        self.n2 = ""  #t是5以下的为单人操作不用管
        self.v1 = 0
        self.v2 = 0

class AllyAssist(GameObj):
    """ 同盟成员从表 """

    TABLE_NAME = TN_P_ALLY
    DATA_CLS = AllyAssistData

    def remove_member(self, rpc_store):
        self.data.duty = -1
        self.data.gid = -1
        self.data.exp = 0
        self.save(rpc_store, forced=True)

    @classmethod
    def new(cls, pid, gid, duty = ALLY_MEMBER):
        assist_obj = cls()
        d = assist_obj.data
        d.gid = gid         #同盟id
        d.pid = pid    #玩家id
        d.duty = duty   #职责
        d.tJoin = common.current_time()#加入时间
        return assist_obj

    @classmethod
    def re_use(cls, gid, pid, duty, dic):
        assist_obj = cls(dic)
        data = assist_obj.data
        data.duty = duty
        data.gid = gid
        data.tJoin = common.current_time()#加入时间
        return assist_obj

        
class AllyLog(GameObj):

    TABLE_NAME = TN_ALLY_LOG
    DATA_CLS = AllyLogData

    @classmethod
    def new(cls, aid, type, n1, n2, v1, v2, rpc_store):
        log_obj = cls()
        log_obj.data.gid = aid
        log_obj.data.t = type      #操作类型1=加入 2=退出 3=贡献 6=任职 7=踢人
        log_obj.data.ct = common.current_time()
        log_obj.data.n1 = n1
        log_obj.data.n2 = n2
        log_obj.data.v1 = v1
        log_obj.data.v2 = v2
        log_obj.save(rpc_store)
        return log_obj