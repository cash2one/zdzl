#!/usr/bin/env python
# -*- coding:utf-8 -*-

import bisect
import copy

from corelib import spawn, sleep, log
from .war import War

from game import Game, pack_msg
from game.base import common, errcode
from game.player.player import Player
from game.base.constant import (ALLY_WORLD_WAR, AWAR_TYPE_1,
    AWAR_TYPE_2, AWAR_TYPE_3, AWAR_TYPE_4, AWAR_TYPE_5,
    AWAR_TYPE_6, ALLY_WAR_FAIL_TIME, AWAR_WORLD_CHOOSE_TIME,
    AWAR_WORLD_CHOOSE_TIME_V, ALLY_WAR_WIN,
    )

from .war import PlayerWarData

NODE_TYPE_MONSTER = 1
NODE_TYPE_COPY = 2

class WarWorld(War):
    """ 魔龙降世战 """
    def __init__(self):
        super(WarWorld, self).__init__()

        #{npcid:copydata}
        self.npcid2copy = {}

        #当前战斗的节点
        self.war_node = 0
        #当前战斗节点的类型(怪物或分身)
        self.node_type = 0
        #开战时该节点是否有隐分身(用来判定该节点战斗结果的隐分身是否出现问题)
        self.start_is_copy = False

        #当前组所在的组
        self.group = None

        #是否选择
        self.is_choose = False
        #战斗过的节点
        self.hit_nodes = []

        self.assess = Assess()


    def get_map(self, pid):
        """ 获取魔龙降世势力地图 """
        return

    def reconnection(self, pid):
        """ 掉线重连进入 广播数据 """
        if self.war_data.war_end:
            return False, errcode.EC_ALLY_WAR_END
        if pid not in self.war_data.war_pids:
            self.war_data.war_pids.append(pid)
        if self.is_choose is False:
            self.smap_broad(send_pids=[pid])
            return True, None
        resp_f = 'awarStartB'
        data = self.pack_data(pid)
        self.send_msg(resp_f, data, send_pids=[pid])
        return True, None

    def start(self, room, pid, data=None):
        """ 开战 """
        self.room = room
        self.group = data
        self.group.win_node(room.aid)
        self.war_node = self.group.get_node(room.aid)
        self.is_choose = False
        self.smap_broad()
        spawn(self.auto_choose_node)
        return True, None

    def pass_scene(self, aid):
        """ 通过本场 """
        if self.war_data.war_end:
            return
        log.debug('pass_scene-node-type %s',self.node_type)
        if self.node_type == NODE_TYPE_COPY:
            self._copy_reward()
        #当战胜隐分身或者开战前该点未被占领 时占领此节点
        if self.node_type == NODE_TYPE_COPY or not self.start_is_copy:
            self.group.win_node(aid, self.war_node)
        log.debug('time1------------')
        self.start_is_copy = False
        #广播势力地图
        self.is_choose = False
        self.smap_broad()
        spawn(self.auto_choose_node)
        log.debug('time2------------')
        self.group.copy_mgr.new_copys(aid, self.war_node)
        log.debug('time3------------')

    def _copy_reward(self):
        """ 击打隐分身最终的大奖励 """
        res_strong_map = Game.res_mgr.awar_strong_maps.get(self.war_node)
        for pid in self.war_data.war_pids:
            rpc_player = Game.rpc_player_mgr.get_rpc_player(pid)
            rpc_player.awar_copy_reward(res_strong_map.rid)
        sleep(2)

    def enter_next_scene(self):
        """ 进入下一场 """
        for pid in self.room.pids:
            pdata = self.pid2pdata.get(pid)
            if not pdata:
                continue
            pdata.next_scene_clear()
        self.boat.cannon = self.fetch_mcannon
        self.boat.connon2data.clear()
        self.war_data.init_monster(self.war_per_config.id)
        #进入下一场广播
        #self.start_broad()

    def smap_broad(self, send_pids=None):
        """ 势力地图广播 """
        resp_f = 'awarWorldMapB'
        data = dict(node=self.war_node, hnodes=self.hit_nodes)
        if self.group.node_aname:
            data['names'] = self.group.node_aname
        self.send_msg(resp_f, data, send_pids=send_pids)

    def auto_choose_node(self):
        """ 时间到自动选择路线 """
        n = 0
        while not self.is_choose:
            sleep(1)
            n += 1
            if n > self.fetch_choose_time :
                log.debug('time out !! %s, %s, %s', self.room.pids, self.is_choose, n)
                war_node = self.group.auto_choose(self.war_node)
                self.choose_node(war_node, NODE_TYPE_MONSTER)
                break

    def choose_node(self, node, type, pid=None):
        """ 降龙战队长选择路线 """
        if self.is_choose:
            return False, errcode.EC_ALLY_WAR_OUTTIME
        log.debug('choos-node %s',pid)
        self.is_choose = True
        self.war_node = node
        self.node_type = type
        self.hit_nodes.append(node)
        res_map = Game.res_mgr.awar_strong_maps.get(self.war_node)
        res_war_per = Game.res_mgr.awar_per_configs.get(int(float(res_map.apcid)))
        if res_war_per is None:
            return False, errcode.EC_NORES
        #记录选择时该节点是否已被占据
        if self.group.copy_mgr.get_copys(node):
            self.start_is_copy = True
        self.war_per_config = res_war_per
        spawn(self.choose_node_broad, pid)
        return True, None

    def choose_node_broad(self, pid):
        """ 选择路线的广播 """
        resp_f = 'awarWorldChooseB'
        data = dict(node=self.war_node)
        self.send_msg(resp_f, data, remove_pid=pid)
        spawn(self.start_broad)

    def start_broad(self, pid=0):
        """ 开战或进入下一场广播 """
        resp_f = 'awarStartB'
        if self.war_data:
            self.enter_next_scene()
        else:
            self.data_init()
        self.war_data.start()
        self._loop_task_broad = spawn(self._loop_broad)
        sleep(1)
        for pid in self.war_data.war_pids:
            data = self.pack_data(pid)
            self.send_msg(resp_f, data, send_pids=[pid])
        spawn(self._loop_war)

    def _loop_war(self):
        """ 开战计时 """
        is_use_boattime = False
        while 1:
            now_time = common.current_time()
            use_time = now_time - self.war_data.stime
            if use_time > self.war_per_config.wtime + self.boat.gtime:
                self.war_result_borad(ALLY_WAR_FAIL_TIME)
                break
            elif not is_use_boattime and use_time > self.war_per_config.wtime:
                is_use_boattime = True
                self.record_uboattimes()
            sleep(1)

    def war_copy_start(self, pid, ancid):
        """ 击杀影分身开始 """
        rs, copy_pid = self.group.get_pid_by_ancid(self.war_node, ancid)
        self.war_monster_start_broad(pid, ancid)
        pdata = self.pid2pdata.get(pid)
        pdata.save_monsster_fight(ancid)
        return rs, (copy_pid, pdata.pbuff)

    def pack_data(self, pid):
        """ 打包数据 """
        data = self.get_data(pid)
        data.update(dict(asid=self.room.res_warstart_config.id))
        if self.node_type == NODE_TYPE_COPY:
            copys = self.group.copy_mgr.get_copys(self.war_node)
            if copys:
                data.update({'copys':copys})
        return data

    def war_finish(self, reward_item=None):
        """ 通关 """
        rid = self.assess.handle_assess()
        if rid:
            rw = Game.reward_mgr.get(rid)
            reward_item = rw.reward({})
            for cpid in self.room.pids:
                preward_items = copy.copy(reward_item)
                p_data = self.pid2pdata.get(cpid)
                p_data.rbox = preward_items
        self.war_result_borad(ALLY_WAR_WIN)

    def get_assess(self):
        """ 获取评级 """
        return self.assess.get_assess()

    def record_rs_war(self, type):
        """ 记录战斗的结束 """
        if type == ALLY_WAR_WIN:
            self.assess.win = 1

    def record_war_fail(self):
        """ 记录挑战失败 """
        self.assess.cdnum += 1

    def record_use_book(self):
        """ 记录使用天书 """
        self.assess.ubooks += 1

    def record_use_fire(self):
        """ 记录使用火炮 """
        self.assess.ufires += 1

    def record_utime(self, utime):
        """ 记录总的使用时间 """
        self.assess.utime = utime

    def record_uboattimes(self):
        """ 记录使用续航时间的次数 """
        self.assess.uboattimes += 1

    @property
    def fetch_choose_time(self):
        return Game.setting_mgr.setdefault(AWAR_WORLD_CHOOSE_TIME, AWAR_WORLD_CHOOSE_TIME_V)


class Assess(object):
    """ 评级数据管理 """
    def __init__(self):
        #此次战斗是否胜利
        self.win = 0
        #玩家cd次数
        self.cdnum = 0
        #总消耗的时间
        self.utime = 0
        #使用的天书次数
        self.ubooks = 0
        #使用火炮次数
        self.ufires = 0
        #触发天舟续航时间的次数
        self.uboattimes = 0

        #当前评级
        self.assess = ''

    def get_scores(self):
        """ 获取评分结果 """
        score = 0
        res_awar_scores = Game.res_mgr.awar_world_score_bykeys.get(AWAR_TYPE_1)
        for num, res_awar_score in res_awar_scores.iteritems():
            if self.win == num:
                score += res_awar_score.score
        s = self.handle_score(self.cdnum, AWAR_TYPE_2)
        score += s
        s = self.handle_score(self.utime, AWAR_TYPE_3)
        score += s
        s = self.handle_score(self.ubooks, AWAR_TYPE_4)
        score += s
        s = self.handle_score(self.ufires, AWAR_TYPE_5)
        score += s
        s = self.handle_score(self.uboattimes, AWAR_TYPE_6)
        score += s
        return score

    def handle_score(self, num, type):
        """ 获取分数 """
        res_awar_scores = Game.res_mgr.awar_world_score_bykeys.get(type)
        l = res_awar_scores.keys()
        l.sort()
        index = bisect.bisect_left(l, num)
        if index >= len(l):
            log.debug('res-err-----------type %s,index %s, l-%s',type, index, l)
            return 0
        key = l[index]
        res_awar_score = res_awar_scores[key]
        return res_awar_score.score

    def handle_assess(self):
        """ 计算评级 """
        scores = self.get_scores()
        res_world_assesses = Game.res_mgr.awar_world_assesses
        for res in res_world_assesses.itervalues():
            if res.sscore <= scores <= res.escore:
                self.assess = res.name
                self.rid = res.rid
                return self.rid


    def get_assess(self):
        """ 获取评级 """
        if self.assess:
            return True, dict(assess=self.assess)
        self.handle_assess()
        if self.assess:
            return True, dict(assess=self.assess)
        return False, errcode.EC_VALUE





