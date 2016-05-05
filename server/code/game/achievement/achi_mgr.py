#!/usr/bin/env python
# -*- coding:utf-8 -*-

import copy
import time

from corelib import message, log

from game.store.define import TN_P_ACHI
from game import BaseGameMgr
from game.base import msg_define, errcode
from game.base.common import is_today
from game.glog.common import ITEM_ADD_DAY_ACHI, ITEM_ADD_EVER_ACHI

from .day_achi import DAY_CLS
from .ever_achi import EVER_CLS
from .achi_config import (
    KEY_DAY, KEY_EVER, KEY_FINISH, KEY_DAY_TIME,
    KEY_STATE, KEY_TARGET, KEY_TIME, KEY_ID, KEY_PID,
    KEY_COUNT, KEY_NEED, TYPE_DAY, TYPE_EVER,
    STATE_0, STATE_1, STATE_2
    )

class AchievementMgr(BaseGameMgr):
    """成就管理器"""
    def __init__(self, game):
        super(AchievementMgr, self).__init__(game)
        self.new = None
        self.day_handlers = {} # aid : handler
        self.ever_handlers = {} # gid : handler

        self.day_target = {}
        self.ever_target = {}
        self.ever_index = {} # (gid, level) : aid
        self.gid_aids = {} # {gid :[aids]}

    def start(self):
        self.init()
        self._game.res_mgr.sub(msg_define.MSG_RES_RELOAD, self.init)

    def stop(self):
        super(AchievementMgr, self).stop()

    def init(self):
        self.init_handler()
        self.init_res()
        self.init_new()

    def init_handler(self):
        """根据config初始化处理对象"""
        for aid, cls in DAY_CLS.iteritems():
            handler = cls(self)
            self.day_handlers[aid] = handler

        for gid, cls in EVER_CLS.iteritems():
            handler = cls(self)
            self.ever_handlers[gid] = handler

    def init_res(self):
        """初始化资源"""
        for aid, obj in self._game.res_mgr.achi_day.iteritems():
            handler = self.day_handlers.get(aid)
            if handler:
                target = handler.parse(obj.target)
                self.day_target[aid] = target

        for aid, obj in self._game.res_mgr.achi_eternal.iteritems():
            handler = self.ever_handlers.get(obj.group)
            if handler:
                target = handler.parse(obj.target)
                self.ever_target[aid] = target
                key = (obj.group, obj.level)
                self.ever_index[key] = aid
                aids = self.gid_aids.setdefault(obj.group, [])
                aids.append(aid)

    def init_new(self):
        """获得新建角色成就数据"""
        d = dict(day = {}, ever = {}, finish = {}, t_day = 0)
        for aid, handler in self.day_handlers.iteritems():
            data = handler.new()
            data[KEY_STATE] = STATE_0
            d[KEY_DAY][aid] = data

        for gid, handler in self.ever_handlers.iteritems():
            data = handler.new()
            data[KEY_STATE] = STATE_0
            level = 1 #档次
            aid = self.ever_index.get((gid, level))
            if aid is None:
                continue
            d[KEY_EVER][aid] = data
        self.new = d
        return self.new

    def get_new(self):
        if self.new:
            return self.new
        return self.init_new()

def wrap_time(func):
    """每日零点更新数据"""
    def _func(self, *args, **kw):
        if not is_today(self.data[KEY_DAY_TIME]):
            new = copy.deepcopy(self.player._game.achi_mgr.get_new())
            self.data[KEY_DAY] = new[KEY_DAY]
        return func(self, *args, **kw)
    return _func

class PlayerAchievement(object):
    """玩家成就管理"""
    def __init__(self, player):
        self.player = player

        #self.data = dict(id = None, pid = 0, day = {}, ever = {}, finish = {}, t_day = 0)
        # id 数据库key
        # pid 玩家id
        # day = {aid : data}    ever = {aid : data}   finish = {aid : time}
        # data = {'c':0, 's':0, 'ct':time}
        # 's'必有，其它可选 s=0 未完成  s=1 可领取 s=2 已完成
        # t_day 每日成就时间（用于刷新判断）
        self.data = self.get_new()

    def uninit(self):
        self.player = None
        self.data = None

    def get_aid_by_gid(self, gid):
        aid = None
        aids = self.player._game.achi_mgr.gid_aids.get(gid)
        if aids is None:
            return aid
        for _aid in self.data[KEY_EVER]:
            if _aid in aids:
                return _aid
        return aid

    def get_gid_by_aid(self, aid):
        for gid, aids in self.player._game.achi_mgr.gid_aids.iteritems():
            if aid in aids:
                return gid

    def init(self):
        if self.player.no_game:
            return
        achi_mgr = self.player._game.achi_mgr
        for aid, handler in achi_mgr.day_handlers.iteritems():
            handler.listen(self.player, aid)
        for gid, handler in achi_mgr.ever_handlers.iteritems():
            aid = self.get_aid_by_gid(gid)
            if aid is None:
                continue
            handler.listen(self.player, aid)

    def init_data(self, old):
        #当新增成就时，需要更新 旧数据(将新成就加上)
        if self.player.no_game:
            return old

        data = dict(day = {}, ever = {}, finish = {})
        data.update(old)
        new = copy.deepcopy(self.player._game.achi_mgr.get_new())
        #隔天刷新每日成就  还需要考虑在线玩家数据清理
        if is_today(old[KEY_DAY_TIME]):
            for aid in new[KEY_DAY]:
                if aid in old[KEY_DAY]:
                    continue
                data[KEY_DAY][aid] = new[KEY_DAY][aid]
        else:
            data[KEY_DAY] = new[KEY_DAY]
        data[KEY_DAY_TIME] = int(time.time())

        for aid in new[KEY_EVER]:
            if aid in old[KEY_EVER] or aid in old[KEY_FINISH]:
                continue
            data[KEY_EVER][aid] = new[KEY_EVER][aid]
        return data

    def decode(self, data):
        """将mongo数据的key转为int"""
        def _decode(data, d):
            for aid, value in data.iteritems():
                d[int(aid)] = value

        d = dict(day = {}, ever = {}, finish = {})
        d.update(data)
        d[KEY_DAY] = {}
        _decode(data[KEY_DAY], d[KEY_DAY])
        d[KEY_EVER] = {}
        _decode(data[KEY_EVER], d[KEY_EVER])
        d[KEY_FINISH] = {}
        _decode(data[KEY_FINISH], d[KEY_FINISH])
        return d

    def encode(self, data):
        """将int的key转为str，存储mongo"""
        def _encode(data, d):
            for aid, value in data.iteritems():
                d[str(aid)] = value

        d = dict(day = {}, ever = {}, finish = {})
        d.update(data)
        d[KEY_DAY] = {}
        _encode(data[KEY_DAY], d[KEY_DAY])
        d[KEY_EVER] = {}
        _encode(data[KEY_EVER], d[KEY_EVER])
        d[KEY_FINISH] = {}
        _encode(data[KEY_FINISH], d[KEY_FINISH])
        return d

    def get_new(self):
        """获得新建角色数据"""
        if self.player.no_game:
            return
        d = copy.deepcopy(self.player._game.achi_mgr.get_new())
        d[KEY_ID] = None
        d[KEY_PID] = self.player.data.id
        d[KEY_DAY_TIME] = int(time.time())
        return d

    def load(self):
        querys = dict(pid = self.player.data.id)
        rs = self.player._game.rpc_store.query_loads(TN_P_ACHI, querys)
        if len(rs):
            #当新增成就时，需要更新 旧数据(将新成就加上)
            data = rs[0]
            data = self.decode(data)
            data = self.init_data(data)
            self.data = data
        else:
            self.data = self.get_new()
        self.init()

    def save(self):
        data = self.encode(self.data)
        if data[KEY_PID] is None:
            return
        if data[KEY_ID] is None:
            id = self.player._game.rpc_store.insert(TN_P_ACHI, data)
            self.data[KEY_ID] = id
        else:
            self.player._game.rpc_store.save(TN_P_ACHI, data)

    def clear(self):
        pass

    def _to_dict(self, data, rs, targets):
        for aid, d in data.iteritems():
            rs[str(aid)] = dict()
            rs[str(aid)][KEY_STATE] = d[KEY_STATE]
            if KEY_COUNT in d:
                rs[str(aid)][KEY_COUNT] = d[KEY_COUNT]
            target = targets.get(aid)
            if target and KEY_NEED in target:
                rs[str(aid)][KEY_NEED] = target[KEY_NEED]

    @wrap_time
    def to_dict(self):
        data = dict(day = {}, ever = {}, finish = {})
        d_day = data[KEY_DAY]
        day_target =  self.player._game.achi_mgr.day_target
        self._to_dict(self.data[KEY_DAY], d_day, day_target)
        d_ever = data[KEY_EVER]
        ever_target = self.player._game.achi_mgr.ever_target
        self._to_dict(self.data[KEY_EVER], d_ever, ever_target)
        d_finish = data[KEY_FINISH]
        d_finish.update(self.data[KEY_FINISH])
        return data

    def copy_from(self, p_achi):
        _id = self.data[KEY_ID]
        self.data = copy.deepcopy(p_achi.data)
        self.data[KEY_ID] = _id
        self.data[KEY_PID] = self.player.data.id

    def _get_reward(self, aid, type):
        res_mgr = self.player._game.res_mgr
        achi_mgr = self.player._game.achi_mgr
        data, res, handler, log_type = None, None, None, None
        if type == TYPE_DAY:
            res = res_mgr.achi_day.get(aid)
            handler = achi_mgr.day_handlers.get(aid)
            log_type = ITEM_ADD_DAY_ACHI
            data = self.data[KEY_DAY].get(aid)
        elif type == TYPE_EVER:
            res = res_mgr.achi_eternal.get(aid)
            gid = self.get_gid_by_aid(aid)
            handler = achi_mgr.ever_handlers.get(gid)
            log_type = ITEM_ADD_EVER_ACHI
            data = self.data[KEY_EVER].get(aid)
        return data, res, handler, log_type

    @wrap_time
    def get_reward(self, aid, type):
        """领取奖励"""
        data, res, handler, log_type = self._get_reward(aid, type)
        if res is None or handler is None or data is None:
            return False, errcode.EC_ACHI_REWARD
        if data[KEY_STATE] != STATE_1:
            return False, errcode.EC_ACHI_REWARD

        rw = self.player._game.reward_mgr.get(res.rid)
        if rw is None:
            return False, errcode.EC_ACHI_REWARD
        items = rw.reward(params=self.player.reward_params())
        if items is None:
            return False, errcode.EC_ACHI_REWARD
        if self.player.bag.can_add_items(items):
            bag_items = self.player.bag.add_items(items, log_type=log_type)
            handler.finish(self.player, res)
            #handler.update(self.player, res)
            return True, bag_items.pack_msg(coin = True)
        else:
            return False, errcode.EC_BAG_FULL

    def enter(self):
        """进入成就系统"""
        return self.to_dict()

    def gm_finish(self, t, aid):
        """gm命令完成指定成就 t='day' 每日  t='ever' 永久"""
        data = self.data.get(t)
        if data is None:
            return
        if aid not in data:
            return
        achi = data[aid]
        achi[KEY_STATE] = STATE_1