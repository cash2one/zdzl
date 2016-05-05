#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time
import copy
from corelib import log

from game.base import msg_define
from game.base.common import is_today, str2dict
from .achi_config import (
    KEY_DAY, KEY_STATE, KEY_DAY_TIME, KEY_COUNT, KEY_NEED,
    STATE_0, STATE_1, STATE_2
    )

def wrap_handler(func):
    """handler修饰"""
    def _func(self, *args, **kw):
        _data = kw.pop('_data')
        #每日零点更新数据
        player = _data[0]
        if not is_today(player.achievement.data[KEY_DAY_TIME]):
            new = copy.deepcopy(player._game.achi_mgr.get_new())
            player.achievement.data[KEY_DAY] = new[KEY_DAY]
            player.achievement.data[KEY_DAY_TIME] = int(time.time())
        kw['_data'] = self.get_data(_data)
        if kw['_data'] is None:
            return
        return func(self, *args, **kw)
    return _func

class DayAchievement(object):
    def __init__(self, mgr):
        self.mgr = mgr

    def listen(self, player, aid):
        pass

    def handle(self, *args, **kw):
        pass

    def parse(self, target):
        """解析目标"""
        target = str2dict(target, ktype=str, vtype=int)
        return target

    def new(self):
        """返回新建角色数据"""
        return {KEY_COUNT : 0}

    def finish(self, player, res):
        d_day = player.achievement.data[KEY_DAY].get(res.id)
        d_day[KEY_STATE] = STATE_2

    def update(self, player, res):
        """更新前端"""
        pass

    def get_data(self, _data):
        player = _data[0]
        aid = _data[1]
        d_day = player.achievement.data[KEY_DAY].get(aid)
        if d_day is None:
            return
        if d_day[KEY_STATE] != STATE_0:
            return
        target = self.mgr.day_target.get(aid)
        if target is None:
            return
        return (player, aid, d_day, target)

    def handle_1(self, _data, num):
        """通用handle_1"""
        player, aid, d_day, target = _data
        d_day[KEY_COUNT] += num
        if d_day[KEY_COUNT] >= target[KEY_NEED]:
            d_day[KEY_COUNT] = target[KEY_NEED]
            d_day[KEY_STATE] = STATE_1

class DayAchievement1(DayAchievement):
    """每日签到"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_LOGON, self.handle, data = (player, aid))

    @wrap_handler
    def handle(self, _data=None):
        player, aid, d_day, target = _data
        d_day[KEY_STATE] = STATE_1

    def parse(self, target):
        return dict()

    def new(self):
        return dict()

class DayAchievement2(DayAchievement):
    """ 升阶宝具 target{n:5}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_WEAPON_UP, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, level, armId, player, rid, _data=None):
        self.handle_1(_data, 1)

class DayAchievement3(DayAchievement):
    """ 强化装备 target{n:5} """
    def listen(self, player, aid):
        player.sub(msg_define.MSG_EQUIP_UP, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, eid, level, _data=None):
        self.handle_1(_data, 1)

class DayAchievement4(DayAchievement):
    """ 夜观星象 target{n:5} """
    def listen(self, player, aid):
        player.sub(msg_define.MSG_HFATE_NUM, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, num, _data=None):
        self.handle_1(_data, num)

class DayAchievement5(DayAchievement):
    """辛勤采矿 target{n:5}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_MINING, self.handle, data = (player, aid))

    @wrap_handler
    def handle(self, num, _data=None):
        self.handle_1(_data, num)

class DayAchievement6(DayAchievement):
    """ 敬祭苍天 target{n:5} """
    def listen(self, player, aid):
        player.sub(msg_define.MSG_FETE_NUM, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, _data=None):
        self.handle_1(_data, 1)

class DayAchievement7(DayAchievement):
    """ 承担重任(悬赏任务完成次数) target{n:5} """
    def listen(self, player, aid):
        player.sub(msg_define.MSG_TASK_FINISH, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, type, _data=None):
        self.handle_1(_data, 1)

class DayAchievement8(DayAchievement):
    """角力竞技 target{n:5} """
    def listen(self, player, aid):
        player.sub(msg_define.MSG_START_ARENA, self.handle, data = (player, aid))

    @wrap_handler
    def handle(self, _data=None):
        self.handle_1(_data, 1)

class DayAchievement9(DayAchievement):
    """ 时光穿梭(战死时光盒怪物五次)  target{n:5}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_TBOX_MDIE, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, num, _data=None):
        self.handle_1(_data, num)

class DayAchievement10(DayAchievement):
    """悠闲钓鱼 target{n:5}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_FISH_UP, self.handle, data = (player, aid))

    @wrap_handler
    def handle(self, num, qt, _data=None):
        self.handle_1(_data, num)

class DayAchievement11(DayAchievement):
    """勇闯深渊 target{n:5} """
    def listen(self, player, aid):
        player.sub(msg_define.MSG_DEEP_BOX, self.handle, data = (player, aid))

    @wrap_handler
    def handle(self, _data=None):
        self.handle_1(_data, 1)

class DayAchievement12(DayAchievement):
    """ 专心修炼 target{n:5}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_SIT_PER, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, num, _data=None):
        self.handle_1(_data, num)

DAY_CLS = {
    1 : DayAchievement1, # 每日签到
    2 : DayAchievement2, # 升阶宝具
    3 : DayAchievement3, # 强化装备
    4 : DayAchievement4, # 夜观星象
    5 : DayAchievement5, # 辛勤采矿
    6 : DayAchievement6, # 敬祭苍天
    7 : DayAchievement7, # 承担重任(悬赏任务完成次数)
    8 : DayAchievement8, # 角力竞技
    9 : DayAchievement9, # 时光穿梭(战死时光盒怪物五次)
    10 : DayAchievement10, #悠闲钓鱼
    11 : DayAchievement11, #勇闯深渊
    12 : DayAchievement12, #专心修炼
}