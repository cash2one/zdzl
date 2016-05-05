#!/usr/bin/env python
# -*- coding:utf-8 -*-
"""
    场景
"""

import random
from corelib import log, spawn, sleep

from game import Game
#场景信息索引
from game.base.constant import (IF_IDX_CAR, IF_IDX_ID, IF_IDX_POS,
    STATE_SIT, IF_IDX_STATE, STATE_NORMAL, NPC_POS_INDEX, PLAYER_POS_INDEX)


def make_scene_info(player):
    """ 获取场景信息 """
    data = player.data
    main_role = player.roles.main_role
    d = (data.id, data.name, data.level, data.rid,
         player.roles.main_role.body_equip_id if player.roles.main_role else 0,
         data.car, data.pos, data.state, player.ally_name, main_role.data.q)
    return d


class BaseScene(object):
    def __init__(self, res_map):
        #消息缓存
        self.res_map = res_map
        self.init()
        if 0:
            from game.res.scene import ResMap
            self.res_map = ResMap()

    def init(self):
        self._enters = set()
        self._leaves = set()
        self._moves = {}
        self._updates = {}

    @property
    def mid(self):
        return self.res_map.id

    @property
    def scene_id(self):
        return self.res_map.id

    @property
    def multi(self):
        return self.res_map.multi

    def can_enter(self, level):
        """ 是否可进入 """
        return True

    def get_infos(self, ids=None):
        """ 当前场景玩家信息 """
        return []

    def add_item(self, scene_item_id):
        if scene_item_id in self._leaves:
            self._leaves.remove(scene_item_id)
        else:
            self._enters.add(scene_item_id)

    def del_item(self, scene_item_id):
        self._moves.pop(scene_item_id, None)
        self._updates.pop(scene_item_id, None)
        if scene_item_id in self._enters:
            self._enters.remove(scene_item_id)
        else:
            self._leaves.add(scene_item_id)

    def move_item(self, scene_item_id, x_y):
        if scene_item_id in self._enters:
            return
        self._moves[scene_item_id] = (scene_item_id, x_y)

    def update_item(self, scene_item_id, info):
        if scene_item_id in self._enters:
            return
        self._updates[scene_item_id] = info


class Scene(BaseScene):
    def __init__(self, res_map, id, mgr, cap):
        if 0:
            from .scene_mgr import GSceneMgr
            self.mgr = GSceneMgr()
        super(Scene, self).__init__(res_map)
        self.id = id
        self.mgr = mgr
        self.cap = cap
        self.players = set()
#        self._bases = []
#        self._updates = {}

    @property
    def is_full(self):
        return len(self.players) >= self.cap

    def get_infos(self, ids=None):
        """ 当前场景玩家信息 """
        if ids is None:
            ids = self.players
        infos = []
        for i in ids:
            info = self.mgr.player_infos.get(i)
            if not info:
                continue
            infos.append(info)
        return infos

    def pop_changes(self):
        """ 获取场景变化信息 """
        if not self.players or \
                not (self._enters or self._leaves or self._moves or self._updates):
            return list(self.players), None

        enter_infos = self.get_infos(ids=self._enters)
        resp = dict(mid=self.mid,
                enters=enter_infos, leaves=list(self._leaves),
                moves=self._moves.values(), up=self._updates.values())
#        self._bases = list(self.players)
        self.init()
        return list(self.players), resp

    def player_update(self, player_id, info, _no_result=True):
        """ 更新信息 """
        if player_id not in self.players:
            return
        if player_id not in self.mgr.player_infos:
            return
        base_info = self.mgr.player_infos[player_id]
        for k, v in info.iteritems():
            base_info[k] = v
        self.update_item(player_id, base_info)

    def player_enter(self, player_id):
        #log.debug('player_enter(%s) enterd:%s', player_id, player_id in self.players)
#        if player_id in self.players: return
        self.add_item(player_id)
        self.players.add(player_id)

    def player_leave(self, player_id):
        #log.debug('player_leave(%s) enterd:%s', player_id, player_id in self.players)
        if player_id not in self.players:
            return
        self.players.remove(player_id)
        self.del_item(player_id)

    def player_move(self, player_id, x_y, _no_result=True):
        if player_id not in self.players:
            return
        self.move_item(player_id, x_y)
        if player_id in self.mgr.player_infos:
            self.mgr.player_infos[player_id][IF_IDX_POS] = x_y

class SingleScene(BaseScene):
    """ 单人场景 """
    def player_enter(self, *args, **kw):
        pass
    def player_move(self, *args, **kw):
        """ 没多人同屏,所以不需处理移动 """
        pass

    def player_leave(self, *args, **kw):
        pass

    def player_update(self, *args, **kw):
        """ 更新信息 """

class BotScene(Scene):
    """ 单个场景机器人管理类 """
    def __init__(self, mgr, bot, scene, levels):
        BaseScene.__init__(self, None)
        self.players = set()
        
        self.mgr = bot
        self.bot_mgr = bot
        self.scene = scene
        self.levels = levels
        self._old_pop_changes = None
        self._old_get_infos = None
        #移动
        self._move_task = None
        #打坐玩家的pids
        self.sit_pids = []

        self.gm_stop = False
    
    def stop_bot(self):
        """ gm关闭机器人 """
        self.gm_stop = True

        if not self.players:
            return
        while self.players:
            self._del_bot()

        self.sit_pids = []
        self._stop_move_task()

    def start_bot(self):
        """ gm开启所有机器人 """
        self.gm_stop = False

    def bot_init(self):
        if self._old_pop_changes:
            return
        self._old_pop_changes = self.scene.pop_changes
        self.scene.pop_changes = self.pop_changes

        self._old_get_infos = self.scene.get_infos
        self.scene.get_infos = self.get_infos

    def bot_uninit(self):
        self.scene.pop_changes = self._old_pop_changes
        self.scene.get_infos = self._old_get_infos

    def get_infos(self, ids=None):
        """ 装饰scene.getinfos """
        rs = self._old_get_infos(ids)
        bot_rs = self.get_bot_infos()
        rs.extend(bot_rs)
        return rs

    def get_bot_infos(self):
        """ 获取机器人信息 """
        rs = []
        for i in self.players:
            info = self.mgr.player_infos.get(i)
            if not info:
                continue
            rs.append(info)
        return rs

    def _del_bot(self):
        """ 删除 """
        if not self.players:
            return
        player_id = self.players.pop()
        #self.players.remove(player_id)
        self.del_item(player_id)
        #
        self.bot_mgr.player_infos.pop(player_id, None)

    def _add_bot(self):
        """ 添加 """
        add_num = random.randint(1, 3)
        for i in xrange(add_num):
            #随机获取玩家数据
            add_player = self.rfeatch_player
            if not add_player:
                return
            pid = add_player['id']
            bot = self.mgr.p.load_player(pid)
            infos = list(make_scene_info(bot))
            #加入到机器人列表信息中
            self.bot_mgr.player_infos[pid] = infos
            #随机获取初始位置
            add_pos = self.rfeatch_pos(PLAYER_POS_INDEX)
            self.bot_mgr.player_infos[pid][IF_IDX_POS] = add_pos
            #将数据添加到该场景管理
            self.add_item(pid)
            self.players.add(pid)

    def _up_bot(self):
        """ 更新机器人 """
        self._clear_sit()
        self._stop_move_task()
        num = len(self.players)
        pids = self.players.copy()
        move_pids = []
        while num / 4 > len(move_pids):
            move_pid = random.choice(list(pids))
            move_pids.append(move_pid)
            pids.remove(move_pid)
        self._move_task = spawn(self._move, move_pids)
        for pid in pids:
            r = random.randint(0,1)
            if not r:
                self._move_to(pid)
                continue
            self.sit_pids.append(pid)
        self._sit()


    def _stop_move_task(self):
        if self._move_task is not None:
            self._move_task.kill(block=0)
            self._move_task = None

    def _move(self, pids):
        """ 移动 """
        while True:
            for pid in pids:
                #npc_pos = self.rfeatch_pos(NPC_POS_INDEX)
                pos = self.get_ran_pos()
                self.player_move(pid, pos)
                sleep(0.5)
            sleep(10)

    def _sit(self):
        """ 打坐 """
        if not self.sit_pids:
            return
        _, rs = Game.rpc_player_mgr.get_player_infos(self.sit_pids)
        for index, pid in enumerate(self.sit_pids):
            player_info = rs[pid]
            if player_info[2]:
                continue
            base_info = self.bot_mgr.player_infos[pid]
            self._move_to(pid)
            sleep(10)
            base_info[IF_IDX_STATE] = STATE_SIT
            self.update_item(pid, base_info)
    
    def _move_to(self, pid):
        """ 玩家移到随机的位置 """
        if self.random_0_1:
            pos = self.rfeatch_pos(NPC_POS_INDEX)
        else:
            pos = self.rfeatch_pos(PLAYER_POS_INDEX)
        self.player_move(pid, pos)

    def _clear_sit(self):
        """ 清楚打坐状态 """
        if not self.sit_pids:
            return
        for pid in self.sit_pids:
            if pid not in self.bot_mgr.player_infos:
                continue
            base_info = self.bot_mgr.player_infos[pid]
            base_info[IF_IDX_STATE] = STATE_NORMAL
            self.update_item(pid, base_info)
        self.sit_pids = []
        sleep(1)

    def update(self):
        """ 更新机器人数量 """
        if self.gm_stop:
            return
        c = len(self.scene.players)
        if c > self.bot_mgr.COUNT:
            self._del_bot()
        elif c + len(self.players) < self.bot_mgr.COUNT:
            self._add_bot()
        self._up_bot()

    def _changes(self, scene_changes):
        """
        resp = dict(enters=enter_infos, leaves=list(self._leaves),
            moves=self._moves.values(), up=self._updates.values())
        """
        if not (self._enters or self._leaves or self._moves or self._updates):
            return scene_changes
        pids, resp = scene_changes
        if not pids:
            return scene_changes
        #修正
        s = self.players.intersection(pids)
        for pid in s:
            if pid in self.players:
                self.players.remove(pid)
            if pid in self._enters:
                self._enters.remove(pid)
            self._moves.pop(pid, None)
            self._updates.pop(pid, None)

        self._leaves.difference_update(pids)
        #更新
        if resp:
            resp['enters'] += self.get_infos(ids=self._enters)
            resp['leaves'] += list(self._leaves)
            resp['moves'] += self._moves.values()
            resp['up'] += self._updates.values()
        else:
            resp = {"mid":self.scene.mid}
            resp['enters'] = self.get_infos()
            resp['leaves'] = list(self._leaves)
            resp['moves'] = self._moves.values()
            resp['up'] = self._updates.values()
        return pids, resp

    def pop_changes(self):
        """ 装饰scene.pop_changes,
        """
        rs = self._old_pop_changes()
        rs_change = self._changes(rs)
        self.init()
        return rs_change

    def get_ran_pos(self):
        """ 随机获取任意的一个位置 """
        if self.random_0_1:
            pos = self.rfeatch_pos(NPC_POS_INDEX)
        else:
            pos = self.rfeatch_pos(PLAYER_POS_INDEX)
        return pos
    
    def rfeatch_pos(self, index):
        """
        随机获取该场景下的一个坐标
        index = -1 在npc和玩家出现点的位置中随机产生一个
        """
        poses = self.bot_mgr.mapid_pos.get(self.scene.mid)
        #log.debug('poses-------- %s', poses)
        born_pos =  '{%d, %d}' % (-1, -1)
        if not poses:
            return born_pos
        if poses[index]:
            pos = random.choice(poses[index])
        else:
            if not poses[PLAYER_POS_INDEX]:
                return born_pos
            pos = random.choice(poses[PLAYER_POS_INDEX])
        x, y = self.bot_mgr._prase_pos(pos)
        rand = random.randint(-2, 2)
        if self.random_0_1:
            y += rand
        else:
            x += rand
        return '{%d, %d}' % (x, y)

    @property
    def rfeatch_player(self):
        """ 随机获取指定等级下的一个玩家 """
        players = self.bot_mgr.levels_players.get(tuple(self.levels))
        if not players:
            return
        player = random.choice(players)
        players.remove(player)
        return player

    @property
    def random_0_1(self):
        """ 在0，1中随机数 """
        return random.randint(0, 1)

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

