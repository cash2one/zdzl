#!/usr/bin/env python
# -*- coding:utf-8 -*-
"""
    场景
"""
import random
from grpc import get_addr, DictExport, DictItemProxy

from corelib import spawn, sleep, log
from game import Game, BaseGameMgr, pack_msg, prepare_send, grpc_monitor
from game.base import msg_define
from game.store.define import TN_PLAYER, TN_P_MAP, GF_BOT_START
from game.base.constant import (MAP_ALLYS, MAP_ROLES_MAX, MAP_ROLES_MAX_V,
        SCENE_ALLY, IF_IDX_POS, NPC_DIR_1, NPC_DIR_2, NPC_DIR_3, NPC_DIR_4,
        NPC_DIR_5, NPC_DIR_6, NPC_DIR_7, NPC_DIR_8, NPC_POS_INDEX,
        PLAYER_POS_INDEX, MAP_ALLY_WAR,
)
from game.player.player import Player, PlayerData
from .scene import SingleScene, Scene

import app
import game_config
import app_config

def get_map(map_id):
    return Game.res_mgr.maps.get(map_id)

class GSceneMgr(DictExport):
    """ 主城管理 """
    _rpc_name_ = 'rpc_scene_mgr'
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        self.scenes = {} #scene_id=[scene, ...]
        self.ids = {} #id=scene
        self.players = {} #player_id=scene
        self.player_infos = {} #player_id=info
        self.rpc_sub_mgrs = {} #proxy_id=rpc_sub_mgr
        self.scene_index = 0
        self.key2scenes = {} #mid:{key:scene} 根据key获取场景对象,如同盟地图
        self.scene_cap = 0
        self.bot = SceneBots(self)
        app.sub(msg_define.MSG_START, self.start)

    def gm_stop_bot(self):
        """ gm关闭机器人 """
        self.bot.gm_stop()
    
    def gm_start_bot(self):
        """ gm开启机器人 """
        self.bot.gm_start()

    def get_next_id(self):
        self.scene_index += 1
        return self.scene_index

    def start(self):
        self.bot.start()
        self._task = spawn(self._loop)
        Game.setting_mgr.sub(msg_define.MSG_RES_RELOAD, self.load)
        self.load()

    @grpc_monitor
    def reg_sub_mgr(self, rpc_sub_mgr, sub_name, _proxy=True):
        log.debug('reg_scene_mgr:%s', sub_name)
        self.rpc_sub_mgrs[sub_name] = rpc_sub_mgr
        return sub_name

    @grpc_monitor
    def unreg_sub_mgr(self, key, _no_result=True):
        log.debug('unreg_scene_mgr:%s', key)
        self.rpc_sub_mgrs.pop(key)

    def load(self):
        self.scene_cap = Game.setting_mgr.setdefault(MAP_ROLES_MAX,
                MAP_ROLES_MAX_V)


    def _loop(self):
        """ 定时更新场景数据,统一处理所有场景的,可以批量更新,提高性能;
        """
        sync_time = 0.6
        time1 = 0.1
        while 1:
            changes = {}
            for ss in self.scenes.itervalues():
                for s in ss:
                    c = s.pop_changes()
                    if c is None:
                        continue
                    _, data = c
                    if data is None:
                        continue
                    changes[s.id] = c
            if changes:
                for rpc_sub_mgr in self.rpc_sub_mgrs.values():
                    rpc_sub_mgr.scenes_changes(changes, _no_result=True)
                sleep(sync_time)
            else:
                sleep(time1)


    @grpc_monitor
    def get_scene(self, scene_id, scene_key = None):
        """ 获取场景对象,人满自动分场景,分场景后暂时不考虑再释放
        暂时只在第一个场景增加机器人
        """
        scenes = self.scenes.setdefault(scene_id, [])
        if scene_key is None:
            for s in scenes:
                if not s.is_full:
                    return s
        map = get_map(scene_id)
        if map is None:
            return None
        s = Scene(map, self.get_next_id(), self, self.scene_cap)
        if not scenes:
            self.bot.add_scene(s)
        scenes.append(s)
        self.ids[s.id] = s
        return s


    @grpc_monitor
    def enter_scene(self, rpc_player, scene_id, pos, scene_key=None, _proxy=True):
        """ 进入场景 """
        player_id = rpc_player.key
        old_scene = self.players.get(player_id)
        if old_scene and old_scene.scene_id == scene_id:
            return old_scene.id
        if scene_key and scene_id in self.key2scenes and \
                scene_key in self.key2scenes[scene_id]:
            scene = self.key2scenes[scene_id][scene_key]
        else:
            scene = self.get_scene(scene_id, scene_key = scene_key)
            if scene_key:
                keys = self.key2scenes.setdefault(scene_id, {})
                keys[scene_key] = scene

        if scene is None:
            return
        #log.debug('enter_scene(%s, %s) %s', player_id, scene_id, old_scene.scene_id if old_scene else 0)
        if old_scene:
            old_scene.player_leave(player_id)
        if player_id not in self.player_infos or old_scene is None:
            self.player_infos[player_id] = list(rpc_player.get_scene_info())
        else:
            self.player_infos[player_id][IF_IDX_POS] = pos
        scene.player_enter(player_id)
        self.players[player_id] = scene
        return scene.id

    @grpc_monitor
    def leave_scene(self, player_id, logout=0):
        if logout:
            self.player_infos.pop(player_id, None)
        if player_id not in self.players:
            return 0
        old_scene = self.players.pop(player_id)
        old_scene.player_leave(player_id)
        return 1

    @grpc_monitor
    def remove_scene(self):
        """ 暂时不清理场景对象 """

    @grpc_monitor
    def get_online_ids(self, pids=None, random_num=None):
        """ 返回在线的玩家id列表,
        pids: 查询的玩家列表,返回在线的ids
        random:整形, 随机选择random个pid返回
        """
        if random_num is not None:
            if len(self.player_infos) <= random_num:
                return self.player_infos.keys()
            return random.sample(self.player_infos, random_num)
        if not pids:
            return self.player_infos.keys()
        return [pid for pid in pids if pid in self.player_infos]


def new_scene_mgr():
    mgr = GSceneMgr()
    return mgr



class SubSceneMgr(BaseGameMgr):
    _rpc_name_ = 'scene_mgr'
    def __init__(self, game):
        BaseGameMgr.__init__(self, game)
        self._game.player_mgr.sub(msg_define.MSG_LOGOUT, self.on_logout)
        self.rpc_scenes = {} #sid=rpc_scene

    def start(self):
        self.key = Game.rpc_scene_mgr.reg_sub_mgr(self, self._game.name, _proxy=True)

    def stop(self):
        if not BaseGameMgr.stop(self):
            return
        if not Game.parent_stoped:
            Game.rpc_scene_mgr.unreg_sub_mgr(self.key, _no_result=True)


    def get_rpc_scene(self, sid, map):
        """ 获取场景对象 """
        try:
            return self.rpc_scenes[sid]
        except KeyError:
            addr = get_addr(self._game.rpc_scene_mgr)
            scene = DictItemProxy(GSceneMgr._rpc_name_, dict_name='ids',
                svc=Game.rpc_scene_mgr.get_service(),
                key=sid, addr=addr)
            scene.id = sid
            scene.map = map
            scene.scene_id = map.id
            self.rpc_scenes[sid] = scene
            return scene

    def get_scene_key(self, player, map):
        """ 获取场景key,如:
        同盟地图, key=ally_id
        """
        t = map.type
        if t in MAP_ALLYS:#返回同盟id
            key = SCENE_ALLY + str(player.ally_id)
            return key
        if t in MAP_ALLY_WAR:
            room_key = self._game.rpc_awar_mgr.get_roomkey_by_pid(player.data.id)
            log.debug('room_key %s, pid %s', room_key, player.data.id)
            if room_key:
                return "%s%d%s" % (SCENE_ALLY, player.ally_id, room_key)
            print 'player--------',player.ally_id
            return "%s%s" % (SCENE_ALLY, player.ally_id)

    def enter_scene(self, player, scene_id, pos):
        """ 玩家请求进入场景,返回场景对象 """
        if not scene_id: #默认地图id
            scene_id = 1
        map = get_map(scene_id)
        assert map is not None, 'scene id(%d) not found' % scene_id
        #副本场景玩家不同屏
        if not map.multi:
            if player.rpc_scene is not None:
                player.scene_leave()
            scene = SingleScene(map)
            return scene
        rpc_scene_mgr = self._game.rpc_scene_mgr
        key = self.get_scene_key(player, map)
        sid = rpc_scene_mgr.enter_scene(player, scene_id, pos, scene_key=key, _proxy=True)
        if sid is None:
            raise ValueError('scene_id(%d) not found' % scene_id)
        scene = self.get_rpc_scene(sid, map)
        #if not rpc_scene.can_enter(self.data.level):
        #    return False
        return scene

    def on_logout(self, player):
        """ 玩家退出 """
        self._game.rpc_scene_mgr.leave_scene(player.data.id, logout=1)

    def scenes_changes(self, changes, _no_result=True):
        """
        场景变更,发送消息
        """
        #log.debug('scenes_changes(%s)', changes)
        resp_f = 'mapChange'
        #log.debug('scenes_changes:%s', changes)
        for scene_id, (plist, change) in changes.iteritems():
            #pack_msg出来的数据只能发送一次,里面的_tag会消失,如果需要发送多次用prepare_send
            data = prepare_send(pack_msg(resp_f, 1, data=change))
            for pid in plist:
                player = self._game.player_mgr.players.get(pid)
                if not player:
                    continue
                player.send_msg(data)

class SceneBots(object):
    """ 场景机器人管理类 """
    TIMES = 60 * 1
    COUNT = 20
    LEVELS = {
        1:[5, 30],
        3:[40, 50],
        5:[50, 70],
    }
    def __init__(self, mgr):
        self.mgr = mgr
        #保存所有场景机器人管理类{scene1:BotScene1, ...}
        self.bots = {}
        self.stoped = True

        self.player_infos = {} #player_id=info

        #等级范围内对应不在线的玩家ids
        #{[level1, level2]:[player1,player2...],...}
        self.levels_players = {}
        #mapid对应的玩家和npc位置{mapid1:[[ppos1, ppos2...],[npos1...]]...}
        self.mapid_pos = {}

        self.p = Player

    def start(self):
        self.stoped = False
        spawn(self.loop)
        #获取信息
        spawn(self.message)

    def stop(self):
        self.stoped = True

    def gm_stop(self):
        """ gm关闭所有机器人 """
        if not self.bots:
            return
        for bot in self.bots.itervalues():
            bot.stop_bot()
        return

    def gm_start(self):
        """ gm开启所有机器人 """
        for bot in self.bots.itervalues():
            bot.start_bot()

    def message(self):
        """ 获取需要的信息 """
        #获取对应等级范围内对应玩家的id
        while not self.stoped:
            self.mapid_pos = {}
            self.levels_players = {}
            for levels in self.LEVELS.itervalues():
                cols = ['pos', 'mapId', 'id']
                players = PlayerData.get_level_pvalue(levels[0], levels[1], cols, 100)
                if not players:
                    continue
                while players:
                    player = random.choice(players)
                    players.remove(player)
                    levels_players = self.levels_players.setdefault(tuple(levels), [])
                    levels_players.append(player)
                    if self.COUNT < len(levels_players):
                        break
                    p_pos = player['pos']
                    mid = player['mapId']
                    pid = player['id']
                    poses = self.mapid_pos.setdefault(mid, [[],[]])
                    if p_pos and p_pos not in poses[PLAYER_POS_INDEX]:
                        poses[PLAYER_POS_INDEX].append(p_pos)
                    self._get_npc_pos(mid, pid, poses)
            sleep(10*60)

    def _get_npc_pos(self, mid, pid, poses):
        """ 通过地图id获取npc的坐标 """
        querys = dict(pid=pid, mid=mid)
        p_maps = Game.rpc_store.query_loads(TN_P_MAP, querys)
        if not p_maps:
            return
        p_map = p_maps[0]
        data = p_map['data']
        #13: {113, 37}: -1: 1|19: {14, 129}: 1: 1|11: {119, 57}: -1: 1
        if not data:
            return
        npc_datas = data.split('|')
        for npc_data in npc_datas:
            if not npc_data:
                continue
            npc = npc_data.split(':')
            res_npc = Game.res_mgr.npcs.get(int(npc[0]))
            dir = res_npc.dir
            x, y = self._prase_pos(npc[1])
            direction = int(npc[2])
            if dir == NPC_DIR_1:
                y -= 5
            elif dir == NPC_DIR_2:
                y += 5
            if direction > 0:
                if dir == NPC_DIR_3:
                    x -= 4
                elif dir == NPC_DIR_4:
                    x += 4
                elif dir == NPC_DIR_5:
                    x -= 3
                    y -= 5
                elif dir == NPC_DIR_6:
                    x -= 3
                    y += 5
                elif dir == NPC_DIR_7:
                    x += 3
                    y -= 5
                elif dir == NPC_DIR_8:
                    x += 3
                    y += 5
            else:
                if dir == NPC_DIR_3:
                    x += 4
                elif dir == NPC_DIR_4:
                    x -= 4
                elif dir == NPC_DIR_5:
                    x += 3
                    y -= 5
                elif dir == NPC_DIR_6:
                    x += 3
                    y += 5
                elif dir == NPC_DIR_7:
                    x -= 3
                    y -= 5
                elif dir == NPC_DIR_8:
                    x -= 3
                    y += 5
            pos = '{%d, %d}' %  (x, y)
            if pos in poses[NPC_POS_INDEX]:
                return
            poses[NPC_POS_INDEX].append(pos)

    def _prase_pos(self, pos):
        """ 解析pos字符串坐标 """
        pos = pos.split(',')
        x = int(pos[0].split('{')[1])
        y = int(pos[1].split('}')[0])
        return x, y

    def is_start(self):
        """ 判断是否自动启动机器人 """
        return Game.rpc_res_store.get_config(GF_BOT_START, True)

    def add_scene(self, scene):
        """ 添加需要机器人的场景 """
        if scene in self.bots:
            return self.bots[scene]
        mid = scene.mid
        if mid not in self.LEVELS:
            return
        from .scene import BotScene
        bot = BotScene(self.mgr, self, scene, self.LEVELS[mid])
        bot.bot_init()
        bot.gm_stop = not self.is_start()
        self.bots[scene] = bot

    def remove(self, scene):
        """ 移除场景 """
        bot = self.bots.pop(scene, None)
        if bot:
            bot.bot_uninit()

    def loop(self):
        """ 处理bot """
        while not self.stoped:
            times = random.randint(self.TIMES/2, self.TIMES)
            sleep(times)
            for bot in self.bots.values():
                bot.update()
                sleep(1)




#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

