#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time
import copy
from corelib import log

from game.base import msg_define
from game.base.constant import (TT_BRANCH, TT_OFFER, TASK_BFTASK_FINISH,
    TASK_ZXTASK_FINISH, TASK_YCTASK_FINISH)
from game.base.common import str2dict, is_today, is_yesterday, str2dict1
from .achi_config import (
    KEY_DAY, KEY_EVER, KEY_FINISH, KEY_STATE, KEY_TARGET, KEY_TIME, KEY_COUNT, KEY_NEED, KEY_DAY_TIME,
    STATE_0, STATE_1, STATE_2, KEY_QUALITY, KEY_RIDS, KEY_CHAPTER, KEY_TASKTYPE, KEY_ID
    )

def wrap_handler(func):
    """handler修饰"""
    def _func(self, *args, **kw):
        _data = kw.pop('_data')
        kw['_data'] = self.get_data(_data)
        if kw['_data'] is None:
            return
        return func(self, *args, **kw)
    return _func

class EverAchievement(object):
    def __init__(self, mgr):
        self.mgr = mgr

    def listen(self, player, aid):
        pass

    def parse(self, target):
        target = str2dict(target, ktype=str, vtype=int)
        return target

    def new(self):
        """返回新建角色数据"""
        return {KEY_COUNT : 0}

    def finish(self, player, res):
        d_ever = player.achievement.data[KEY_EVER].get(res.id)
        d_ever[KEY_STATE] = STATE_2
        player.achievement.data[KEY_FINISH][res.id] = int(time.time())
        self.next(player, res)

    def next(self, player, res):
        key = (res.group, res.level + 1)
        aid = self.mgr.ever_index.get(key)
        data = None
        if aid:
            d_ever = player.achievement.data[KEY_EVER]
            d_ever.pop(res.id)
            data = self.new()
            data[KEY_STATE] = STATE_0
            d_ever[aid] = data
        return aid, data

    def update(self, player, res):
        """更新前端"""
        pass

    def get_data(self, _data):
        player = _data[0]
        aid = _data[1]
        target = self.mgr.ever_target.get(aid)
        if target is None:
            return
        d_ever = player.achievement.data[KEY_EVER].get(aid)
        if d_ever is None:
            return
        if d_ever[KEY_STATE] != STATE_0:
            return
        return (player, aid, d_ever, target)

    def handle_1(self, _data, num):
        """通用handle_1"""
        player, aid, d_ever, target = _data
        d_ever[KEY_COUNT] = num
        if d_ever[KEY_COUNT] >= target[KEY_NEED]:
            d_ever[KEY_STATE] = STATE_1

    def handle_2(self, _data, num):
        """通用handle_2"""
        player, aid, d_ever, target = _data
        d_ever[KEY_COUNT] += num
        if d_ever[KEY_COUNT] >= target[KEY_NEED]:
            d_ever[KEY_STATE] = STATE_1

class EverAchievement1(EverAchievement):
    """连续登陆成就 target {n : 5}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_LOGON, self.handle, data = (player, aid))

    @wrap_handler
    def handle(self, _data=None):
        player, aid, d_ever, target = _data
        ct = d_ever[KEY_TIME]
        if is_today(ct):
            #今日已经登陆过
            return
        #时间是否是昨天
        if is_yesterday(ct):
            d_ever[KEY_COUNT] += 1
        else:
            d_ever[KEY_COUNT] = 0
        #新号第一次登陆
        if ct == 0:
            d_ever[KEY_COUNT] = 1
        d_ever[KEY_TIME] = int(time.time())
        #是否达成目标
        if target[KEY_NEED] <= d_ever[KEY_COUNT]:
            d_ever[KEY_STATE] = STATE_1

    def new(self):
        """返回新建角色数据"""
        return {KEY_COUNT : 0, KEY_TIME : 0}

    def next(self, player, res):
        aid, data = super(EverAchievement1, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_LOGON, self.handle, data = (player, res.id))
            player.sub(msg_define.MSG_LOGON, self.handle, data = (player, aid))

class EverAchievement2(EverAchievement):
    """ 点将招募类 """
    def listen(self, player, aid):
        data=(player, aid)
        self.before_listen(data)
        player.sub(msg_define.MSG_ROLE_INVITE, self.handle, data=data)

    def before_listen(self, data):
        rs = self.get_data(data)
        if not rs:
            return
        player, aid, d_ever, target = rs
        #招募第一个武将满足时可领取
        if target.has_key(KEY_RIDS) and target[KEY_RIDS][0] in player.roles.rid2roles:
            d_ever[KEY_COUNT] = 1
            d_ever[KEY_STATE] = STATE_1

    @wrap_handler
    def handle(self, rid, player, _data=None):
        player, aid, d_ever, target = _data
        #天下归心
        if not target[KEY_NEED]:
            s, d = self.all_role(player)
            d_ever[KEY_STATE] = s
            return
        target_rids = target.get(KEY_RIDS)
        #招募boss
        if target_rids:
            if rid not in target_rids:
                return
            self._sucess(d_ever, target)
            return
            #其他
        target_q = target.get(KEY_QUALITY)
        if target_q:
            res_role = player._game.res_mgr.roles.get(rid)
            if res_role.quality != target_q:
                return
        self._sucess(d_ever, target)

    def _sucess(self, d_ever, target):
        """ 完成一次成就 """
        d_ever[KEY_COUNT] += 1
        if target[KEY_NEED] <= d_ever[KEY_COUNT]:
            d_ever[KEY_STATE] = 1

    def all_role(self, player):
        """ 招募全部 """
        all_role_nums = len(player._game.res_mgr.roles)
        own_role_nums = len(player.roles.roles)
        if own_role_nums < all_role_nums:
            return STATE_0, own_role_nums
        return STATE_1, all_role_nums

    def next(self, player, res):
        aid, data = super(EverAchievement2, self).next(player, res)
        if data:
            state, count = self.next_data(player, aid)
            data[KEY_STATE] = state
            data[KEY_COUNT] = count
            player.unsub(msg_define.MSG_ROLE_INVITE, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_ROLE_INVITE, self.handle, data=(player, aid))

    def next_data(self, player, aid):
        """ 获取下一档的状态的数据(积累有可能直接完成) """
        target = self.mgr.ever_target.get(aid)
        #天下归心
        if not target[KEY_NEED]:
            return self.all_role(player)
        target_rids = target.get(KEY_RIDS)
        #招募boss
        own_roles = player.roles.roles
        if target_rids:
            target_num = len(target_rids)
            own_boss_num = 0
            for target_rid in target_rids:
                if target_rid in own_roles:
                    own_boss_num += 1
                if own_boss_num == target_num:
                    return STATE_1, own_boss_num
            return STATE_0, own_boss_num
        #其他
        target_q = target.get(KEY_QUALITY)
        target_num = target.get(KEY_NEED)
        #无品质只有数目
        if not target_q:
            #去除主将 -1
            own_roles_num = len(own_roles) - 1
            if own_roles_num >= target_num:
                return STATE_1, own_roles_num
            return STATE_0, own_roles_num
        own_q_num = 0
        #有品质有数目
        if target_q:
            for own_role in own_roles.itervalues():
                #去除主将
                if own_role.data.rid == player.data.rid:
                    continue
                res_role = player._game.res_mgr.roles.get(own_role.data.rid)
                if target_q == res_role.quality:
                    own_q_num += 1
                if target_num == own_q_num:
                    return STATE_1, own_q_num
        return STATE_0, own_q_num

    def parse(self, target):
        #res n:1|q=1|rid:3:4
        #解析后{n=1,q=1,rid=[]..}
        target = str2dict1(target)
        target[KEY_NEED] = int(target[KEY_NEED][0])
        #target[KEY_QUALITY] = int(target[KEY_QUALITY][0])
        if target.has_key(KEY_RIDS):
            target[KEY_RIDS] = map(int, target[KEY_RIDS])
        if target.has_key(KEY_QUALITY):
            target[KEY_QUALITY] = int(target[KEY_QUALITY][0])
        return target

class EverAchievement3(EverAchievement):
    """ 玩家升阶类 target {n : 10}"""
    def listen(self, player, aid):
        data=(player, aid)
        self.before_listen(data)
        player.sub(msg_define.MSG_WEAPON_UP, self.handle, data=(player, aid))

    def before_listen(self, data):
        rs = self.get_data(data)
        if not rs:
            return
        player, aid, d_ever, target = rs
        main_rid = player.data.rid
        main_arm_level = 0
        for role in player.roles.roles.itervalues():
            if role.data.rid == main_rid:
                main_arm_level = role.data.armLevel
                break
        d_ever[KEY_COUNT] = main_arm_level
        if target[KEY_NEED] > main_arm_level:
            return
        d_ever[KEY_STATE] = STATE_1

    @wrap_handler
    def handle(self, level, arm_id, player, rid, _data=None):
        if player.data.rid != rid:
            return
        self.handle_1(_data, level)

    def next(self, player, res):
        aid, data = super(EverAchievement3, self).next(player, res)
        if data:
            state, arm_level = self.next_data(player, aid)
            data[KEY_COUNT] = arm_level
            data[KEY_STATE] = state
            player.unsub(msg_define.MSG_WEAPON_UP, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_WEAPON_UP, self.handle, data=(player, aid))

    def next_data(self, player, aid):
        """ 获取下一档的数据(积累有可能直接完成) """
        arm_level = 0
        for role in player.roles.roles.itervalues():
            #获取主将
            if role.data.rid == player.data.rid:
                arm_level = role.data.armLevel
                break
        target = self.mgr.ever_target.get(aid)
        if arm_level and arm_level >= target[KEY_NEED]:
            return STATE_1, arm_level
        return STATE_0, arm_level

class EverAchievement4(EverAchievement):
    """ 玩家积累练历 target {n : 10}"""
    def listen(self, player, aid):
        data=(player, aid)
        self.before_listen(data)
        player.sub(msg_define.MSG_TRAIN, self.handle, data=(player, aid))

    def before_listen(self, data):
        rs = self.get_data(data)
        if not rs:
            return
        player, aid, d_ever, target = rs
        d_ever[KEY_COUNT] = player.data.train
        if target[KEY_NEED] > player.data.train:
            return
        d_ever[KEY_STATE] = STATE_1

    @wrap_handler
    def handle(self, _data=None):
        player = _data[0]
        self.handle_1(_data, player.data.train)

    def next(self, player, res):
        aid, data = super(EverAchievement4, self).next(player, res)
        if data:
            data[KEY_COUNT] = player.data.train
            data[KEY_STATE] = self.next_data(player, aid)
            player.unsub(msg_define.MSG_TRAIN, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_TRAIN, self.handle, data=(player, aid))

    def next_data(self, player, aid):
        """ 获取下一档的数据(积累有可能直接完成) """
        target = self.mgr.ever_target.get(aid)
        if player.data.train >= target[KEY_NEED]:
            return STATE_1
        return STATE_0

class EverAchievement5(EverAchievement):
    """阵型升级类"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_POSITION_UP, self.handle, data = (player, aid))
        self.repub(player, aid)

    def repub(self, player, aid):
        target = self.mgr.ever_target.get(aid)
        if target is None:
            return
        position = player.positions.get_by_pid(target['p'])
        if position is None:
            return
        player.safe_pub(msg_define.MSG_POSITION_UP, position.data.posId, position.data.level)

    @wrap_handler
    def handle(self, pid, level, _data = None):
        player, aid, d_ever, target = _data
        if target['p'] != pid:
            return
        d_ever[KEY_COUNT] = level
        if target[KEY_NEED] <= d_ever[KEY_COUNT]:
            d_ever[KEY_STATE] = STATE_1

    def next(self, player, res):
        aid, data = super(EverAchievement5, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_POSITION_UP, self.handle, data = (player, res.id))
            player.sub(msg_define.MSG_POSITION_UP, self.handle, data = (player, aid))
            #重发消息, 判断玩家阵型是否已经满足成就
            self.repub(player, aid)

    def parse(self, target):
        target = str2dict(target, ktype=str, vtype=int)
        if target[KEY_NEED] != -1: #需求阵型最大等级 -1
            return target
        need = 0
        for key in self.mgr._game.res_mgr.position_levels:
            pid = key[0]
            if target['p'] == pid:
                need += 1
        target[KEY_NEED] = need
        return target

class EverAchievement6(EverAchievement):
    """ 装备强化类 target {n : 10}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_EQUIP_UP, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, eid, level, _data=None):
        self.handle_2(_data, 1)

    def next(self, player, res):
        aid, data = super(EverAchievement6, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_EQUIP_UP, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_EQUIP_UP, self.handle, data=(player, aid))

class EverAchievement7(EverAchievement):
    """ 装备品质类 target {n : 10}"""
    def listen(self, player, aid):
        data = (player, aid)
        self.before_listen(data)
        player.sub(msg_define.MSG_MAIN_WEAR_EQUIP, self.handle, data=data)
        player.sub(msg_define.MSG_MAIN_EQUIP_UP, self.handle, data=data)

    def before_listen(self, data):
        rs = self.get_data(data)
        if rs is None:
            return
        player, aid, d_ever, target = rs
        role = player.roles.get_role_by_rid(player.data.rid)
        if role is None:
            return
        for e, eid in role.iter_equips():
            eq, res = player.bag.get_equip_ex(eid)
            if eq is None or res is None:
                continue
            if target['sid'] != res.sid or target['lv'] > eq.data.level:
                return
        d_ever[KEY_STATE] = STATE_1

    @wrap_handler
    def handle(self, role, equip, res_equip, _data=None):
        player, aid, d_ever, target = _data
        if target['sid'] != res_equip.sid or target['lv'] > equip.data.level:
            return
        for e, eid in role.iter_equips():
            eq, res = player.bag.get_equip_ex(eid)
            if eq is None or res is None:
                continue
            if target['sid'] != res.sid or target['lv'] > eq.data.level:
                return
        d_ever[KEY_STATE] = STATE_1

    def next(self, player, res):
        aid, data = super(EverAchievement7, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_MAIN_WEAR_EQUIP, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_MAIN_WEAR_EQUIP, self.handle, data=(player, aid))
            player.unsub(msg_define.MSG_MAIN_EQUIP_UP, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_MAIN_EQUIP_UP, self.handle, data=(player, aid))

    def new(self):
        return dict()

class EverAchievement8(EverAchievement):
    """ 观星收集类 target {n : 10}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_HFATE_NUM, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, num, _data=None):
        self.handle_2(_data, num)

    def next(self, player, res):
        aid, data = super(EverAchievement8, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_HFATE_NUM, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_HFATE_NUM, self.handle, data=(player, aid))

class  EverAchievement9(EverAchievement):
    """同盟成就"""

    def dis_online_did(self, player, aid):
        """上次玩家同盟处理却不在线的逻辑"""
        target = self.mgr.ever_target.get(aid)
        if target is None:
            return
        d_ever = player.achievement.data[KEY_EVER].get(aid)
        if d_ever is None:
            return
        if target[KEY_NEED] == 0:
            #n=0是首次加入
            if d_ever[KEY_STATE] == STATE_0:
                d_ever[KEY_STATE] = STATE_1
        else:
            #n=num是达到下次奖励的同盟的等级
            level = player._game.rpc_ally_mgr.ally_level_by_pid(player.data.id)
            d_ever[KEY_COUNT] = level
            if level >= target[KEY_NEED] and d_ever[KEY_STATE] == STATE_0:
                d_ever[KEY_STATE] = STATE_1

    def listen(self, player, aid):
        if player._game.rpc_ally_mgr.get_aid_by_pid(player.data.id):
            self.dis_online_did(player, aid)
        else:
            player.sub(msg_define.MSG_ALLY_JOIN, self.handle_join, data = (player, aid))
        player.sub(msg_define.MSG_ALLY_UP, self.handle_level_up, data = (player, aid))

    @wrap_handler
    def handle_join(self, level, _data = None):
        player, aid, d_ever, target = _data
        if target[KEY_NEED] != 0:
            return
        #n=0是首次加入   n=num 是达到下次奖励的同盟的等级
        if d_ever[KEY_STATE] == STATE_0:
            d_ever[KEY_STATE] = STATE_1

    @wrap_handler
    def handle_level_up(self, level, _data = None):
        player, aid, d_ever, target = _data
        if target[KEY_NEED] == 0:
            return
        d_ever[KEY_COUNT] = level
        if level >= target[KEY_NEED] and d_ever[KEY_STATE] == STATE_0:
            d_ever[KEY_STATE] = STATE_1

    def next(self, player, res):
        aid, data = super(EverAchievement9, self).next(player, res)
        if data:
            d_ever = player.achievement.data[KEY_EVER]
            data = self.new()
            data[KEY_STATE] = STATE_0
            d_ever[aid] = data
            player.unsub(msg_define.MSG_ALLY_UP, self.handle_level_up, data = (player, res.id))
            player.sub(msg_define.MSG_ALLY_UP, self.handle_level_up, data = (player, aid))
            level = player._game.rpc_ally_mgr.ally_level_by_pid(player.data.id)
            self.handle_level_up(level, _data=(player, aid))


    def new(self):
        """返回新建角色数据"""
        return {}


class EverAchievement10(EverAchievement):
    """ 竞技战场类 target {n : 10}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_WIN_ARENA, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, _data):
        self.handle_2(_data, 1)

    def next(self, player, res):
        aid, data = super(EverAchievement10, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_WIN_ARENA, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_WIN_ARENA, self.handle, data=(player, aid))

class EverAchievement11(EverAchievement):
    """ 闯时光盒类 target {n:10, chapter:2}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_TBOX_PASS, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, chapter, _data=None):
        player, aid, d_ever, target = _data
        if target[KEY_CHAPTER] != chapter:
            return
        d_ever[KEY_COUNT] += 1
        if d_ever[KEY_COUNT] >= target[KEY_NEED]:
            d_ever[KEY_STATE] = STATE_1

    def next(self, player, res):
        aid, data = super(EverAchievement11, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_TBOX_PASS, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_TBOX_PASS, self.handle, data=(player, aid))

class  EverAchievement12(EverAchievement):
    """深渊闯关成就 target {n:10}"""

    def listen(self, player, aid):
        player.sub(msg_define.MSG_DEEP_FINISH, self.handle, data = (player, aid))

    @wrap_handler
    def handle(self, _data = None):
        self.handle_2(_data, 1)

    def next(self, player, res):
        aid, data = super(EverAchievement12, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_DEEP_FINISH, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_DEEP_FINISH, self.handle, data=(player, aid))

class  EverAchievement13(EverAchievement):
    """钓鱼成就 target {n:10}"""

    def listen(self, player, aid):
        player.sub(msg_define.MSG_FISH_UP, self.handle, data = (player, aid))

    @wrap_handler
    def handle(self, num, fq, _data = None):
        player, aid, d_ever, target = _data
        if target[KEY_QUALITY] != fq:
            return
        d_ever[KEY_COUNT] += num
        if d_ever[KEY_COUNT] >= target[KEY_NEED]:
            d_ever[KEY_STATE] = STATE_1

    def next(self, player, res):
        aid, data = super(EverAchievement13, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_FISH_UP, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_FISH_UP, self.handle, data=(player, aid))

class EverAchievement14(EverAchievement):
    """ 玄石合成类 target {n:10, q:2}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_MERGE_ITEM, self.handle, data=(player, aid))

    @wrap_handler
    def handle(self, aDesId, aCount, aSrcId, _data):
        player, aid, d_ever, target = _data
        if not player._game.item_mgr.is_iron(aDesId):
            return
        item = player._game.item_mgr.get_res_item(aDesId)
        if item is None:
            return
        if item.quality != target['q']:
            return
        d_ever[KEY_COUNT] += aCount
        if target[KEY_NEED] <= d_ever[KEY_COUNT]:
            d_ever[KEY_STATE] = STATE_1

    def next(self, player, res):
        aid, data = super(EverAchievement14, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_MERGE_ITEM, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_MERGE_ITEM, self.handle, data=(player, aid))

class  EverAchievement15(EverAchievement):
    """商店购买成就 target {n:10}"""

    def listen(self, player, aid):
        player.sub(msg_define.MSG_SHOP_BUY, self.handle, data = (player, aid))

    @wrap_handler
    def handle(self, sid, _data = None):
        self.handle_2(_data, 1)

    def next(self, player, res):
        aid, data = super(EverAchievement15, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_SHOP_BUY, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_SHOP_BUY, self.handle, data=(player, aid))

class EverAchievement16(EverAchievement):
    """ 主线剧情类 target {ch:1}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_ACHI_CHAPTER_FINISH, self.handle, data=(player, aid))
        player.safe_pub(msg_define.MSG_ACHI_CHAPTER_FINISH)

    @wrap_handler
    def handle(self, _data):
        player, aid, d_ever, target = _data
        f_chaptre = player.data.chapter - 1
        if target['ch'] <= f_chaptre:
            d_ever[KEY_STATE] = STATE_1

    def next(self, player, res):
        aid, data = super(EverAchievement16, self).next(player, res)
        if  data:
            player.unsub(msg_define.MSG_ACHI_CHAPTER_FINISH, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_ACHI_CHAPTER_FINISH, self.handle, data=(player, aid))
            #重发消息，判断玩家已经完成过章节
            player.safe_pub(msg_define.MSG_ACHI_CHAPTER_FINISH)

    def new(self):
        return dict()

class EverAchievement17(EverAchievement):
    """ 任务完成类 target {n:10, tt:2}"""
    def listen(self, player, aid):
        data=(player, aid)
        self.before_listen(data)
        player.sub(msg_define.MSG_TASK_FINISH, self.handle, data=(player, aid))

    def before_listen(self, data):
        rs = self.get_data(data)
        if not rs:
            return
        player, aid, d_ever, target = rs
        #悬赏
        if target[KEY_TASKTYPE] == TT_OFFER:
            task_type = TASK_BFTASK_FINISH
        #支线
        elif target[KEY_TASKTYPE] == TT_BRANCH:
            task_type = TASK_ZXTASK_FINISH
        #隐藏
        else:
            task_type = TASK_YCTASK_FINISH
        num = player.task.p_attr_task.get(task_type)
        d_ever[KEY_COUNT] = num
        if num < target[KEY_NEED]:
            return
        d_ever[KEY_STATE] = STATE_1

    @wrap_handler
    def handle(self, task_type, _data=None):
        player, aid, d_ever, target = _data
        if target[KEY_TASKTYPE] != task_type:
            return
        d_ever[KEY_COUNT] += 1
        if d_ever[KEY_COUNT] >= target[KEY_NEED]:
            d_ever[KEY_STATE] = STATE_1

    def next(self, player, res):
        aid, data = super(EverAchievement17, self).next(player, res)
        if aid:
            state, count = self.next_data(player, aid)
            data[KEY_STATE] = state
            data[KEY_COUNT] = count
            player.unsub(msg_define.MSG_TASK_FINISH, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_TASK_FINISH, self.handle, data=(player, aid))

    def next_data(self, player, aid):
        """ 获取下一档的数据(积累有可能直接完成) """
        target = self.mgr.ever_target.get(aid)
        #悬赏
        if target[KEY_TASKTYPE] == TT_OFFER:
            task_type = TASK_BFTASK_FINISH
        #支线
        elif target[KEY_TASKTYPE] == TT_BRANCH:
            task_type = TASK_ZXTASK_FINISH
        #隐藏
        else:
            task_type = TASK_YCTASK_FINISH
        num = player.task.p_attr_task.get(task_type)
        if num < target[KEY_NEED]:
            return STATE_0, num
        return STATE_1, target[KEY_NEED]

class EverAchievement18(EverAchievement):
    """社交成就 target {n:10}"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_SOCIAL_ADD, self.handle, data = (player, aid))

    @wrap_handler
    def handle(self, num, _data = None):
        self.handle_1(_data, num)

    def next(self, player, res):
        aid, data = super(EverAchievement18, self).next(player, res)
        if  data:
            player.unsub(msg_define.MSG_SOCIAL_ADD, self.handle, data=(player, res.id))
            player.sub(msg_define.MSG_SOCIAL_ADD, self.handle, data=(player, aid))

    def new(self):
        return dict()

class EverAchievement19(EverAchievement):
    """ 物品收集类   物品id:1|n:50   or  命格q:1|n:50"""
    def listen(self, player, aid):
        player.sub(msg_define.MSG_BAG_ITEM_CHANGE, self.handle_item, data=(player, aid))
        player.sub(msg_define.MSG_BAG_FATE_CHANGE, self.handle_fate, data=(player, aid))

    def repub(self, player, aid):
        target = self.mgr.ever_target.get(aid)
        if target is None:
            return
        if KEY_ID in target:
            player.safe_pub(msg_define.MSG_BAG_ITEM_CHANGE, target[KEY_ID])
        elif KEY_QUALITY in target:
            player.safe_pub(msg_define.MSG_BAG_FATE_CHANGE, q = target[KEY_QUALITY])

    @wrap_handler
    def handle_item(self, iid, _data=None):
        player, aid, d_ever, target = _data
        #判断是否道具任务
        if KEY_QUALITY in target:
            return
        if iid != target[KEY_ID]:
            return
        c = player.bag.get_item_num_by_iid(iid)
        d_ever[KEY_COUNT] = c
        if target[KEY_NEED] <= d_ever[KEY_COUNT]:
            d_ever[KEY_STATE] = STATE_1

    @wrap_handler
    def handle_fate(self, q=None, fid=None, _data=None):
        player, aid, d_ever, target = _data
        #判断是否是命格任务
        if KEY_QUALITY not in target:
            return
        if fid:
            res = player._game.res_mgr.fates.get(fid)
            if res is None:
                return
            quality = res.quality
        else:
            quality = q
        if quality is None:
            return
        if quality != target[KEY_QUALITY]:
            return
        c = player.bag.get_fate_num_by_quality(quality)
        d_ever[KEY_COUNT] = c
        if target[KEY_NEED] <= d_ever[KEY_COUNT]:
            d_ever[KEY_STATE] = STATE_1

    def next(self, player, res):
        aid, data = super(EverAchievement19, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_BAG_ITEM_CHANGE, self.handle_item, data=(player, res.id))
            player.sub(msg_define.MSG_BAG_ITEM_CHANGE, self.handle_item, data=(player, aid))
            player.unsub(msg_define.MSG_BAG_FATE_CHANGE, self.handle_fate, data=(player, res.id))
            player.sub(msg_define.MSG_BAG_FATE_CHANGE, self.handle_fate, data=(player, aid))
            #重发消息，判断是否满足成就
            self.repub(player, aid)

class  EverAchievement20(EverAchievement):
    """元宝充值成就 target {n:100}"""
    def listen(self, player, aid):
        self.before_listen((player, aid))
        player.sub(msg_define.MSG_VIP_COIN_ADD, self.handle, data = (player, aid))

    def before_listen(self, data):
        rs = self.get_data(data)
        if not rs:
            return
        player, aid, d_ever, target = rs
        d_ever[KEY_COUNT] = player.data.coin2
        if d_ever[KEY_COUNT] >= target[KEY_NEED]:
            d_ever[KEY_STATE] = STATE_1

    @wrap_handler
    def handle(self, num, _data = None):
        self.handle_1(_data, num)

    def next(self, player, res):
        aid, data = super(EverAchievement20, self).next(player, res)
        if data:
            player.unsub(msg_define.MSG_VIP_COIN_ADD, self.handle, data = (player, res.id))
            player.sub(msg_define.MSG_VIP_COIN_ADD, self.handle, data = (player, aid))
            player.safe_pub(msg_define.MSG_VIP_COIN_ADD, player.data.coin2)

    def new(self):
        return dict()

EVER_CLS = {
    1 : EverAchievement1, # 连续登陆成就
    2 : EverAchievement2, # 点将招募类
    3 : EverAchievement3, # 玩家升阶类
    4 : EverAchievement4, # 玩家积累练历
    5 : EverAchievement5, # 阵型升级类
    6 : EverAchievement6, # 装备强化类
    7 : EverAchievement7, # 装备品质类
    8 : EverAchievement8, # 观星收集类
    9 : EverAchievement9, # 同盟成就
    10 : EverAchievement10, # 竞技战场类
    11 : EverAchievement11, # 闯时光盒类
    12 : EverAchievement12, # 深渊闯关成就
    13 : EverAchievement13, # 钓鱼成就
    14 : EverAchievement14, # 玄石合成类
    15 : EverAchievement15, # 商店购买成就
    16 : EverAchievement16, # 主线剧情类
    17 : EverAchievement17, # 任务完成类
    18: EverAchievement18, # 社交成就
    19: EverAchievement19, # 物品收集类
    20: EverAchievement20, # 元宝充值成就
}