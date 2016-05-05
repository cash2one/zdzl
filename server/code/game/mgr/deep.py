#!/usr/bin/env python
# -*- coding:utf-8 -*-
#深渊模块

import time
import random

from corelib import RLock, spawn_later, log
from corelib.data import IntBiteMap
from store.store import GameObj, StoreObj

from game.base.msg_define import MSG_RES_RELOAD, MSG_DEEP_FLOOR
from game.base.constant import DEEP_AUTO_TIMES, DEEP_AUTO_TIMES_V
from game.base.constant import DEEP_ENTER_LEVEL, DEEP_ENTER_LEVEL_V
from game.base.constant import (DEEP_BUFF, DEEP_BUFF_V, DEEP_GUARD_IDS,
        DEEP_GUARD_IDS_V, STATUS_DEEP_FT, DEEP_BOX_NPC, DEEP_BOX_NPC_v,
        DEEP_MAP_ID, DEEP_MAP_ID_v,
        DEEP_AUTO_COST, DEEP_AUTO_COST_V,
        MAIL_REWARD, RW_MAIL_DEEP,
        #DEEP_GUARD_BUFF, DEEP_GUARD_BUFF_V,
       )
from game.base import common, msg_define
from game.base import errcode
from game.glog.common import PL_DEEP_BOX
from game import Game, BaseGameMgr
from game.glog.common import COIN_DEEP_AUTO, ITEM_ADD_DEEPBOX
from game.store.define import TN_P_DEEP
from game.player.buff import merge_buff
from game.item.reward import merge_reward_items
from game.res.deep import FLOOR_MAX, FLOOR_MIN, FLOOR_BOSS_START

import language

PLAYER_DEEP = 'deep'
PD_FTIME = 'ft'
PD_FLOOR = 'fl'
PD_BUFF = 'bf'
PD_BOX = 'box'
PD_GUARD = 'gd'
PD_CLEAR = 'cl' #已经清完怪的层列表

#进入深渊类型:0=重新进入, 1=普通门, 2=精英门, 3=后退门
ET_ENTER = 0
ET_NORMAL = 1
ET_GOOD = 2
ET_BACK = 3

FIRST_IN = 8

GUARD_COUNT = 5 #精英怪出场数
GUARD_GOOD = 0
GUARD_NORMAL = 1
GT_NORMAL = 1
GT_GOOD = 2
GT_BOSS = 3

#状态 1=正常, 2=挂机, 3=完成
DT_NORMAL = 1
DT_AUTO = 2
DT_COMPLETE = 3

NORMAL_PER_FLOOR = FLOOR_BOSS_START

_deep_lock = RLock()
def handle_pass_day():
    """ 当天服宝箱设置 """
    status_mgr = Game.rpc_status_mgr
    with _deep_lock:
        data = status_mgr.get(STATUS_DEEP_FT)
        if not (data is None or common.is_pass_day(data['ft'])):
            return data
        data = dict(ft=int(time.time()), box={})
        boxs = data['box']
        for box in Game.res_mgr.deep_boxs.itervalues():
            floor = box.random_floor()
            if isinstance(floor, (list, tuple)):
                for fl in floor:
                    boxs[str(fl)] = box.id
            else:
                boxs[str(floor)] = box.id
        status_mgr.set(STATUS_DEEP_FT, data)
        return data

def get_res_box(bid):
    return Game.res_mgr.deep_boxs.get(bid)

def get_res_pos(pid):
    return Game.res_mgr.deep_poses.get(pid)

def get_res_guard(gid):
    guard = Game.res_mgr.deep_guards.get(gid)
    if not guard:
        log.error(u'resguard not found:%s', gid)
    return guard

#def logon_by_g(pid):
#    log.info('logon_by_g:%s', pid)

class DeepMgr(BaseGameMgr):
    """ 深渊管理器 """


    def __init__(self, game):
        super(DeepMgr, self).__init__(game)
        self._sguard_ids = ''
        self._guard_ids = None
        self._sbuff = ''
        self._one_buff = None
        self.first_time = None
        self.box = None
        self.boss_npc_id = 0
        self.gd1_npc_id = 0
        self.boss = None
        self._auto_times = 0
        #self._reset_time = 86400 - 1           #一天的时间-1秒
        #记录玩家进入深渊的最大层数{pid1:floor_max1, ...}
        self._enter_floor_max = {}

    def start(self):
        self._game.res_mgr.sub(MSG_RES_RELOAD, self.lood)
        self._game.player_mgr.sub(msg_define.MSG_LOGON, self.player_logon)
#        self._game.rpc_player_mgr.rpc_sub(logon_by_g, msg_define.MSG_LOGON, _proxy=True)
        self.lood()


    def player_logon(self, player):
        """ 玩家登陆,检查是否自动挂机 """
        is_auto = PlayerDeepData.check_auto(self._game.rpc_store, player.data.id)
        if is_auto:
            self.init_player(player)

    def lood(self):
        res_mgr = self._game.res_mgr
        gids = []
        boss_id = 0
        for res_guard in res_mgr.deep_guards.itervalues():
            if res_guard.is_boss:
                boss_id = res_guard.get_guards(50, 1)
                self.boss = res_guard
            else:
                gids.append((res_guard.lv1, res_guard.id))
        self.get_gd2 = common.make_lv_regions(gids, accept_low=1)
        #阵型
        poses = []
        for res_pos in res_mgr.deep_poses.itervalues():
            poses.append((res_pos.lv1, res_pos.id))
        self.get_pid = common.make_lv_regions(poses, accept_low=1)

        if boss_id:
            mid = res_mgr.monster_levels.get(boss_id).mid
            self.boss_npc_id = res_mgr.monsters.get(mid).npc
        gd1ids = self.get_gd1_ids()
        self.gd1_npc_id = res_mgr.monsters.get(gd1ids[0]).npc
        times = self._game.setting_mgr.setdefault(DEEP_AUTO_TIMES, DEEP_AUTO_TIMES_V)
        self._auto_times = common.make_lv_regions(times)

    def handle_pass_day(self):
        """ 处理超过一天(超过则更新数据) """
        if not self.first_time:
            data = self._game.rpc_status_mgr.get(STATUS_DEEP_FT)
            if data:
                self.first_time = data['ft']
                self.box = data['box']
                self.box_total = len(self.box)

        if self.first_time is None or common.is_pass_day(self.first_time):
            data = self._game.rpc_client.sync_exec(handle_pass_day,
                    None, _pickle=True)
            self.first_time = data['ft']
            self.box = data['box']
            self.box_total = len(self.box)
            self._enter_floor_max.clear()

    def get_one_buff(self):
        """ 获取单次战斗后给与的buff加成 """
        sbuff = self._game.setting_mgr.setdefault(DEEP_BUFF, DEEP_BUFF_V)
        if sbuff != self._sbuff:
            self._sbuff = sbuff
            self._one_buff = common.str2dict(sbuff)
        return self._one_buff

    def get_gd1_ids(self):
        """ 获取普通怪id列表 """
        sguard_ids = self._game.setting_mgr.setdefault(DEEP_GUARD_IDS, DEEP_GUARD_IDS_V)
        if sguard_ids != self._sguard_ids:
            self._sguard_ids = sguard_ids
            self._guard_ids = map(int, sguard_ids.split('|'))
        return self._guard_ids

    def get_gd2_npc_id(self, rid):
        """ 获取精英怪npc id """
        return self._game.res_mgr.roles.get(rid).npc

    @property
    def box_npc_id(self):
        """ 宝箱npc Id """
        return self._game.setting_mgr.setdefault(DEEP_BOX_NPC, DEEP_BOX_NPC_v)
    
    def get_map_id(self, floor):
        """ 根据层,获取地图id """
        base_id = self._game.setting_mgr.setdefault(DEEP_MAP_ID, DEEP_MAP_ID_v)
        return base_id + floor

    @property
    def auto_cost(self):
        """ 挂机花费元宝 """
        return self._game.setting_mgr.setdefault(DEEP_AUTO_COST, DEEP_AUTO_COST_V)

    def auto_times(self, player):
        """ 挂机单层耗时 """
        return self._auto_times(player.data.vip)

    #@property
    #def reset_time(self):
    #    """ 重置时间 """
    #    return self._reset_time
    #    return self._game.setting_mgr.setdefault(DEEP_AUTO_TIMES, DEEP_AUTO_TIMES_V)

    def init_player(self, player):
        """ 获取玩家的deep数据 """
        deep = getattr(player.runtimes, PLAYER_DEEP, None)
        if deep is None:
            deep = PlayerDeep(player)
            deep.load(player)
            setattr(player.runtimes, PLAYER_DEEP, deep)
            player.runtimes.deep = deep
            deep.login(self, player)
        self.handle_pass_day()
        deep.pass_day(self, player)
        return deep

    def clear(self, player):
        """ 清除数据 """
        deep = self.init_player(player)
        deep.clear()
#        deep.delete(player._game.rpc_store)
#        del player.runtimes.deep

    @property
    def enter_level(self):
        return Game.setting_mgr.setdefault(DEEP_ENTER_LEVEL, DEEP_ENTER_LEVEL_V)

    def enter(self, player, etype, pack_msg=True, level=0):
        """ 玩家进入某层
        etype: 0=重新进入, 1=普通门, 2=精英门, 3=后退门
        level: 直接跳到指定层
        返回:
            失败: False, err
            成功: True, deep_data or msg
        """
        if player.data.level < self.enter_level:
            return False, errcode.EC_NOLEVEL
        log.info("player(%s) level:%s and enter_level:%s", player.data.name,
            player.data.level, self.enter_level)
        deep = self.init_player(player)
        deep.init_floor(self, player)
        rs, data = deep.enter(self, player, etype, level=level)
        if not rs:
            return False, data
        self.pub_floor(player, deep.data.fl)
        if pack_msg:
            r_s = deep.pack_enter_msg(self)
            #添加了是不是第一次进入该层
            r_s['fsi'] = 1 if data == FIRST_IN else 0
            return True, r_s
        return True, deep

    def pub_floor(self, player, floor):
        """ 抛出当前到达的最高层事件 """
        #进入大厅不用广播
        if not floor:
            return
        log.debug('enter----floor-------%s', floor)
        pid = player.data.id
        floor_max = self._enter_floor_max.get(pid)
        if not floor_max or floor_max < floor:
            self._enter_floor_max[pid] = floor
            Game.rpc_horn_mgr.safe_pub(MSG_DEEP_FLOOR, pid, floor)

    def open_box(self, player, pack_msg=True):
        """ 收取本层宝箱 """
        deep = self.init_player(player)
        rs, err = deep.box(self, player)
        if not rs:
            return False, err
        bag_items, boxes, bid = err
        player.log_normal(PL_DEEP_BOX, bid=bid)
        if pack_msg:
            data = bag_items.pack_msg()
            return True, dict(data=data, box=boxes)
        return True, bag_items

    def fight(self, player, type):
        """ 打怪
        怪类型(type, int, 1=普通, 2=精英, 3=boss)
        """
        deep = self.init_player(player)
        rs, err = deep.fight(self, type, player)
        if not rs:
            return False, err
        return True, err

    def auto(self, player):
        """ 自动挂机, 返回:wasteTimes """
        deep = self.init_player(player)
        rs, err = deep.auto(self, player)
        if not rs:
            return False, err
        return True, err

    #def set_reset_time(self, re_time):
    #    """ 设置重置时间 """
    #    self._reset_time = int(re_time)


class PlayerDeepData(StoreObj):
    def init(self):
        self.id = None
        self.pid = 0
        self.zero()

    def zero(self, ft=0):
        self.ft = ft #开始时间
        self.at = 0 #自动挂机完成时间
        self.fl = 0
        self.bf = {}
        self.box = {}
        self.rw = [] #奖励累计
        self.gd = {}
        self.cl = ''
        self.auto = 0 #今天是否已经挂机过

    @classmethod
    def check_auto(cls, store, pid):
        v = store.values(TN_P_DEEP, ['at'], dict(pid=pid))
        return v and v[0]['at'] > 0

    def clear(self):
        self.zero()


class PlayerDeep(GameObj):
    TABLE_NAME = TN_P_DEEP
    DATA_CLS = PlayerDeepData
    __slots__ = ('clears', '_auto_task', 'player') + GameObj.__slots__

    def __init__(self, player):
        super(PlayerDeep, self).__init__()
        self.player = player

    def __getstate__(self):
        return self.data

    def __setstate__(self, data):
        self.data = data

    def init(self):
        self.clears = IntBiteMap()
        if 0:
            self.data = PlayerDeepData()

    def uninit(self):
        self.player = None

    def update(self, adict):
        super(PlayerDeep, self).update(adict)
        self.clears.from_base64(self.data.cl)

    def login(self, mgr, player):
        if self.is_auto:
            waste_times = int(self.data.at - time.time())
            if waste_times <= 0:
                self.auto_complete(mgr, player, send_msg=False)
            else:
                self._auto_task = spawn_later(waste_times + 5, self.auto_complete, mgr, player)

    def logout(self, player):
        """ 玩家退出 """
        if hasattr(self, '_auto_task'):#关闭挂机处理
            self._auto_task.kill(block=False)
            del self._auto_task

    def load(self, player):
        if not self.load_ex(player._game.rpc_store, dict(pid=player.data.id)):
            self.data.pid = player.data.id

    def save(self, store, forced=False):
        self.data.cl = self.clears.to_base64()
        return super(PlayerDeep, self).save(store, forced=forced)

    def clear(self):
        """ 清理 """
        self.clears.clear()
        self.data.clear()

    def copy_from(self, player):
        deep = getattr(player.runtimes, PLAYER_DEEP)
        if deep:
            id = self.data.id
            self.data.update(deep.data.to_dict())
            self.data.pid = self.player.data.id
            self.data.id = id
            self.modified = True

    @property
    def is_auto(self):
        return bool(self.data.at)

    @property
    def is_complete(self):
        return len(self.data.box) == 0

    def _reset_check(self, mgr):
        self.modified = True
        self.clears.clear()
        self.data.zero(ft=common.current_time())
        self.data.box = mgr.box.copy()

    def pass_day(self, mgr, player):
        """ 玩家数据是否过期 """
        if not common.is_pass_day(self.data.ft):
            #TODO 暂时屏蔽vip每日深渊刷新次数
            #p_t = common.current_time() - int(self.data.ft)
            #if p_t >= mgr.reset_time:
            #    self._reset_check(mgr)
            return False
        self._reset_check(mgr)
        return True

    def _init_normal(self, level, mgr):
        """初始化大于普通层"""
        sfloor = str(self.data.fl)
        gid = mgr.get_gd2(level)
        res_guard = get_res_guard(gid)
        gids = res_guard.get_guards(level, GUARD_COUNT)
        gd = []
        res_pos = get_res_pos(mgr.get_pid(level))
        #精英
        if self.data.fl not in (FLOOR_MIN, FLOOR_BOSS_START):
            gd.append(dict(pid=res_pos.get_pid(), rids=gids))
        else: #0层没有精英怪
            gd.append(0)
            #普通守卫
        ids = mgr.get_gd1_ids()
        ngids = [random.choice(ids) for i in xrange(GUARD_COUNT)]
        gd.append(dict(pid=res_pos.get_pid(), rids=ngids))
        self.data.gd[sfloor] = gd

    def _init_boss(self, level, mgr):
        """初始化大于boss层"""
        sfloor = str(self.data.fl)
        res_guard = mgr.boss
        self.data.gd[sfloor] = res_guard.get_guards(level, GUARD_COUNT)

    def init_floor(self, mgr, player):
        """ 初始化玩家在深渊某层的数据,
        返回:
            完成: True
            未完成: guards
            第一次进入: FIRST_IN
        """
        if self.is_complete or self.data.fl in self.clears:
            return True
        sfloor = str(self.data.fl)
        floor = self.data.fl
        if sfloor in self.data.gd:
            return self.data.gd
        level = player.data.level
        if floor >= FLOOR_BOSS_START:
            self._init_boss(level, mgr)
        else:
            self._init_normal(level, mgr)
        return FIRST_IN

    #def enter(self, mgr, player, etype, level=0):
    #    if self.is_auto:
    #        return True, None
    #    floor = self.data.fl
    #    guards = self.data.gd.get(str(floor), None)
    #    if etype == ET_BACK:
    #        if FLOOR_MAX >= floor >= FLOOR_MIN + 1:
    #            floor -= 1
    #            self.data.fl = floor
    #            self.modified = True
    #        else:
    #            return False, errcode.EC_VALUE
    #    elif etype == ET_ENTER:
    #        pass
    #    elif floor >= FLOOR_MAX:
    #        return False, errcode.EC_VALUE
    #    elif 0 < level < FLOOR_MAX:
    #        self.data.fl = level
    #        self.modified = True
    #    else:#检查
    #        g_idx = GUARD_NORMAL if etype == ET_NORMAL else GUARD_GOOD
    #        if not self.is_complete and guards and guards[g_idx]:#当前层有怪
    #            return False, errcode.EC_DEEP_HAVE_GUARD
    #        floor = (floor + 1) if etype == ET_NORMAL else int(floor) / 10 * 10 + 10
    #        self.data.fl = floor
    #        self.modified = True
    #    rs = self.init_floor(mgr, player)
    #    return True, rs

    def enter(self, mgr, player, etype, level=0):
        if self.is_auto:
            return True, None
        floor = self.data.fl
        guards = self.data.gd.get(str(floor), None)
        if etype == ET_BACK:
            if FLOOR_MAX >= floor >= FLOOR_MIN + 1:
                floor -= 1
                self.data.fl = floor
                self.modified = True
            else:
                return False, errcode.EC_VALUE
        elif etype == ET_ENTER:
            pass
        elif floor >= FLOOR_MAX:
            return False, errcode.EC_VALUE
        elif 0 < level < FLOOR_MAX:
            self.data.fl = level
            self.modified = True
        else:#检查
            if floor >= FLOOR_BOSS_START:
                if guards:#当前层有怪
                    return False, errcode.EC_DEEP_HAVE_GUARD
                floor += 1
            else:
                g_idx = GUARD_NORMAL if etype == ET_NORMAL else GUARD_GOOD
                if guards and guards[g_idx]:#当前层有怪
                    return False, errcode.EC_DEEP_HAVE_GUARD
                floor = (floor + 1) if etype == ET_NORMAL else int(floor) / 10 * 10 + 10
            self.data.fl = floor
            self.modified = True
        rs = self.init_floor(mgr, player)
        return True, rs

    def pack_enter_msg(self, mgr):
        """ 打包消息 """
        floor = self.data.fl
        guards = self.data.gd.get(str(floor))
        cleared = floor in self.clears
        npcs = {}
        boxs = dict(box=int(str(floor) in self.data.box),
                rw=self.data.rw, total=mgr.box_total, remain=len(self.data.box))
        msg = dict(floor=floor,
            mid=mgr.get_map_id(floor),
            box=boxs,
            buff=self.data.bf,
            npc=npcs,
        )
        npcs['bid'] = mgr.boss_npc_id #boss npc id
        if str(floor) in self.data.box:
            npcs['box'] = mgr.box_npc_id
        if self.is_auto:
            msg['s'] = DT_AUTO
            msg['autoTimes'] = int(self.data.at - time.time())
        elif self.is_complete:
            msg['s'] = DT_COMPLETE
        else:
            msg['s'] = DT_NORMAL
            if cleared:
                pass
            elif floor >= FLOOR_MAX:
                msg['bid'] = guards
            else:
                has_guard = False
                if floor >= FLOOR_BOSS_START:
                    #boss层没有普通和精英怪
                    msg['bid'] = mgr.boss_npc_id
                else:
                    if guards[GUARD_GOOD]:
                        has_guard = True
                        msg['gd2'] = guards[GUARD_GOOD]
                        npcs['gd2'] = mgr.get_gd2_npc_id(guards[GUARD_GOOD]['rids'][0])
                    if guards[GUARD_NORMAL]:
                        has_guard = True
                        msg['gd1'] = guards[GUARD_NORMAL]
                        npcs['gd1'] = mgr.gd1_npc_id
        return msg

    def _box(self, bid, player):
        """ 获取宝箱物品 """
        res_box = get_res_box(bid)
        rid = res_box.get_rid(player.data.level)
        reward = player._game.reward_mgr.get(rid)
        items = reward.reward(params=player.reward_params())
        return items

    def box(self, mgr, player):
        """ 收取宝箱 """
        if self.is_auto:
            return False, errcode.EC_VALUE
        floor = self.data.fl
        sfloor = str(self.data.fl)
        if sfloor not in self.data.box:
            return False, errcode.EC_VALUE
        bid = self.data.box[sfloor]
        items = self._box(bid, player)
        player.pub(msg_define.MSG_DEEP_FLOOR_BOX, floor, items)
        if not player.bag.can_add_items(items):
            return False, errcode.EC_BAG_FULL
        bag_items = player.bag.add_items(items, log_type=ITEM_ADD_DEEPBOX)
        #累计奖励
        self.data.rw = merge_reward_items(items, self.data.rw)
        self.data.box.pop(sfloor)
        self.modified = True
        boxs = dict(box=int(str(floor) in self.data.box),
            rw=self.data.rw, total=mgr.box_total, remain=len(self.data.box))
        player.pub(msg_define.MSG_DEEP_BOX)
        return True, (bag_items, boxs, bid)

    def fight(self, mgr, type, player):
        """ 打怪
        怪类型(type, int, 1=普通, 2=精英, 3=boss)
        """
        if self.is_auto:
            return False, errcode.EC_VALUE
        floor = self.data.fl
        guards = self.data.gd.get(str(floor))
        cleared = floor in self.clears
        if cleared or not guards:
            return False, errcode.EC_VALUE
        if floor >= FLOOR_BOSS_START:
            self.data.gd.pop(str(floor))
            self.clears.insert(floor)
            self.modified = True
            self.add_buff(mgr)
            #发送通关深渊的消息
            if floor == FLOOR_BOSS_START:
                player.pub(msg_define.MSG_DEEP_FINISH)
            return True, {"buff":self.data.bf}
        gtype = GUARD_GOOD if type == GT_GOOD else GUARD_NORMAL
        if not guards[gtype]:
            return False, errcode.EC_VALUE
        guards[gtype] = 0
        if not (guards[GUARD_NORMAL] or guards[GUARD_GOOD]):#完成本层
            self.clears.insert(floor)
            self.data.gd.pop(str(floor))

        return self.add_buff(mgr)

    def add_buff(self, mgr, floors=1):
        """ 增加多少层buff """
        one_buff = mgr.get_one_buff()
        buffs = self.data.bf
        merge_buff(one_buff, buffs, multiply=floors)
        self.modified = True
        return True, {"buff":self.data.bf}

    def auto_floors(self):
        c_floor = 0
        for fl in xrange(self.data.fl, FLOOR_BOSS_START):
            if fl in self.clears:
                continue
            else:
                guards = self.data.gd.get(str(fl))
                if fl == 0 and guards:
                    c_floor += 1
                    continue
                if guards and 0 in guards:
                    continue
                else:
                    c_floor += 1
        return c_floor

    def auto(self, mgr, player):
        """ 自动挂机, 返回:wasteTimes """
        if self.data.auto:
            return False, errcode.EC_DEEP_NO_AUTO
        if self.data.fl >= FLOOR_BOSS_START - 1:
            return False, errcode.EC_DEEP_BOSS_NO_AUTO
        if self.is_auto:
            log.info("pid %s, is_auto :%s", player.data.id, self.is_auto)
            return False, errcode.EC_VALUE
        #从当前层开始挂机,不理会返回上层的问题
        c_floor = self.auto_floors()
        #TODO: 测试用，60秒完成
        #waste_times = 60
        waste_times = c_floor * mgr.auto_times(player)
        #waste_times = c_floor * mgr.times_per_floor(player)
        auto_time = int(time.time() + waste_times)
        if common.is_pass_day_time(auto_time):#挂机结束时间超过今天
            return False, errcode.EC_DEEP_OVER_DAY
        #扣费
        coin = int(c_floor * mgr.auto_cost)
        if not player.cost_coin(aCoin2=coin, log_type=COIN_DEEP_AUTO):
            return False, errcode.EC_COST_ERR
        self.data.at = auto_time
        self._auto_task = spawn_later(waste_times + 5, self.auto_complete, mgr, player)
        self.data.auto = 1
        self.modified = True
        return True, waste_times

    def auto_complete(self, mgr, player, send_msg=True):
        """ 挂机完成 """
        if self.data.at > time.time():
            return False
        if not player.logined:
            return False

        items = []
        for floor, bid in self.data.box.items():
            res_box = get_res_box(bid)
            if res_box.boss_floor():
                continue
            box_items = self._box(bid, player)
            player.pub(msg_define.MSG_DEEP_FLOOR_BOX, floor, box_items)
            items = merge_reward_items(box_items, items)
            self.data.box.pop(floor)
            player.pub(msg_define.MSG_DEEP_BOX)
        #此次挂机加多少次玩家的buff
        floors = 0
        for floor in xrange(self.data.fl, FLOOR_BOSS_START):
            if floor not in self.clears:
                self.clears.insert(floor)
                floors += 1
            if str(floor) in self.data.gd:
                self.data.gd.pop(str(floor))
        rw_mail = Game.res_mgr.reward_mails.get(RW_MAIL_DEEP)
        if items:
            mgr._game.mail_mgr.send_mails(player.data.id, MAIL_REWARD,
                rw_mail.title, RW_MAIL_DEEP,
                items, param=rw_mail.content)
        floors = 1 if not floors else floors
        self.add_buff(mgr, floors)
        self.data.at = 0
        self.data.rw = merge_reward_items(items, self.data.rw)
        self.data.fl = FLOOR_BOSS_START - 1
        self.modified = True

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


