#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import GameObj, StoreObj
from game.store.define import TN_P_POSITION
from game.base import errcode, msg_define
from game.glog.common import COIN_POS_STUDY, COIN_POS_UP, PL_STUDY_POS

#阵型基础等级
BASE_LEVEL = 1


class PlayerPositionData(StoreObj):
    def init(self):
        self.id = None
        self.pid = 0
        self.posId = 0
        self.level = 0
        self.s1 = 0
        self.s2 = 0
        self.s3 = 0
        self.s4 = 0
        self.s5 = 0
        self.s6 = 0
        self.s7 = 0
        self.s8 = 0
        self.s9 = 0
        self.s10 = 0
        self.s11 = 0
        self.s12 = 0
        self.s13 = 0
        self.s14 = 0
        self.s15 = 0


class PlayerPosition(GameObj):
    TABLE_NAME = TN_P_POSITION
    DATA_CLS = PlayerPositionData
    POS_RANGE = range(1, 16)
    MAX_COUNT = 5 #最大出战人数
    POS_TMP = 's%d'
    def study(self, player, res_data):
        """ 学习阵型 """
        self.data.id = None
        self.data.pid = player.data.id
        self.data.posId = res_data.pid
        self.data.level = BASE_LEVEL

    def upgrade(self, res_data):
        """ 升级 """
        self.data.level = res_data.level
        self.modify()

    def set(self, adict):
        """ 完整设置阵型信息 """
        c = 0 #校验人数上限
        for i in self.POS_RANGE:
            n = self.POS_TMP % i
            v = adict.get(n)
            if v is None:
                v = 0
            elif v:
                c += 1
                if c > self.MAX_COUNT:
                    v = 0
            setattr(self.data, n, v)
        self.modify()

    def place(self, role, pos):
        if pos not in self.POS_RANGE:
            return False
        n = self.POS_TMP % pos
        if role is None:
            setattr(self.data, n, 0)#清空
        else:
            setattr(self.data, n, role.data.rid) #位置设定为角色基础表id
        self.modify()
        return True

    def iter_rids(self):
        """ 遍历在阵型中的角色id
        return:
            pos, rid
        """
        for i in self.POS_RANGE:
            n = self.POS_TMP % i
            v = getattr(self.data, n)
            if not v:
                continue
            yield i, v



class PlayerPositions(object):
    """ 玩家阵型属性类 """
    def __init__(self, player):
        self.player = player
        self.positions = {}
        self.pid2positions = {}
        if 0:
            from .player import Player
            self.player = Player()

    def uninit(self):
        self.player = None
        self.positions = {}
        self.pid2positions = {}

    def load(self, querys=None):
        if querys is None:
            querys = dict(pid=self.player.data.id)
        poses = self.player._game.rpc_store.query_loads(TN_P_POSITION, querys)
        for data in poses:
            p = PlayerPosition(adict=data)
            self.positions[p.data.id] = p
            self.pid2positions[p.data.posId] = p

    def load_used(self):
        """ 加载使用中的阵型 """
        querys = dict(pid=self.player.data.id, id=self.player.data.posId)
        self.load(querys=querys)


    def save(self):
        store = self.player._game.rpc_store
        for p in self.positions.itervalues():
            p.save(store)
    
    def clear(self):
        """ 清理数据 """
        store = self.player._game.rpc_store
        for p in self.positions.itervalues():
            p.delete(store)
        self.positions.clear()
        self.pid2positions.clear()

    def copy_from(self, positions, posId):
        self.clear()
        for p in positions.positions.itervalues():
            ni = PlayerPosition(adict=p.data.to_dict())
            ni.data.id = None
            ni.data.pid = self.player.data.id
            ni.save(self.player._game.rpc_store)
            if p.data.id == posId:
                posId = None
                self.player.data.posId = ni.data.id
        if posId is not None and self.positions:
            self.player.data.posId = self.positions.keys()[0]
        self.load()

    def to_dict(self, used=0):
        if not used:
            return [p.to_dict() for p in self.positions.itervalues()]
        p = self.get_active()
        if not p:
            return []
        return [p.to_dict()]

    def get(self, id):
        return self.positions.get(id)

    def get_by_pid(self, pid):
        return self.pid2positions.get(pid)

    def get_active(self):
        """ 获取激活的阵型 """
        return self.positions.get(self.player.data.posId)

    def study(self, pid, forced=False):
        """ 学习阵型 """
        res_data = self.player._game.res_mgr.position_levels.get((pid, BASE_LEVEL))
        if res_data.pid in self.pid2positions or \
            not (forced or res_data.can_unlock(self.player)):
            return False
        #扣除费用
        if not (forced or self.player.cost_coin(aCoin1=res_data.coin1, log_type=COIN_POS_STUDY)):
            return False
        self.player.log_normal(PL_STUDY_POS, pid=pid)
        p = PlayerPosition()
        p.study(self.player, res_data)
        p.save(self.player._game.rpc_store)
        self.positions[p.data.id] = p
        self.pid2positions[p.data.posId] = p
        if self.get_active() is None:
            self.active(p.data.id)
        #抛出阵型升级消息
        self.player.pub(msg_define.MSG_POSITION_UP, pid, BASE_LEVEL)
        return p

    def upgrade(self, id, level=None, forced=False):
        """ 升级阵型 """
        p = self.positions.get(id)
        if p is None:
            return False, errcode.EC_VALUE
        pid = p.data.posId
        if level is None:
            level = p.data.level + 1
        res_data = self.player._game.res_mgr.position_levels.get((pid, level))
        if res_data is None or\
            not (forced or res_data.can_unlock(self.player)):
            return False, errcode.EC_POS_NOFOUND
        #扣除费用
        if not (forced or self.player.cost_coin(aCoin1=res_data.coin1, log_type=COIN_POS_UP)):
            return False, errcode.EC_COST_ERR
        p.upgrade(res_data)
        #抛出阵型升级消息
        self.player.pub(msg_define.MSG_POSITION_UP, pid, level)
        return True, None

    def active(self, id):
        """ 激活阵型 """
        p = self.positions.get(id)
        if p is None:
            return False
        self.player.data.posId = p.data.id
        return True

    def set(self, id, adict):
        """ 设置阵型信息 """
        p = self.positions.get(id)
        if p is None:
            return False
        p.set(adict)
        return True

    def place(self, pid, rid, pos):
        """ 布置某角色到某阵型位置 """
        position = self.pid2positions.get(pid)
        if position is None:
            return False
        role = self.player.roles.get_role_by_rid(rid)
        return position.place(role, pos)

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------




