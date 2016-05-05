#!/usr/bin/env python
# -*- coding:utf-8 -*-

import random, math
import copy

from corelib import spawn, sleep, log

from game import Game, pack_msg
from game.base import common, errcode
from game.base import msg_define, constant
from game.player.player import Player
from game.base.constant import ALLY_SKY_WAR, ALLY_WORLD_WAR

from .war_room import RoomMgr

def logon_by_war(pid):
    """ 重新上线处理 """
    spawn(Game.rpc_awar_mgr.player_logon, pid)

def logout_by_war(pid):
    """ 玩家退出游戏 """
    spawn(Game.rpc_awar_mgr.player_logout, pid)


class WarMgr(object):
    """ 同盟战斗系统管理类(狩龙战) """
    _rpc_name_ = 'rpc_awar_mgr'
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        self._game = Game
        self._loop_task = None

        #保存资源的势力地图结构{节点1：[关联的节点2,...]...}
        self.res_strong_map = {}

        #基础表战场开启的配置表
        self.res_warstart_configs = {}

        #当前开启活动的配置信息
        self.warstart_config = None

        #活动
        self.init()
        import app
        app.sub(msg_define.MSG_START, self.start)

    def init(self):
        log.debug('------stop-----')
        self.room_mgr = RoomMgr()
        #开战后守龙战 {pid:守龙战1...}
        #self.sky_wars = {}
        #开战后降世战 {pid:降世战1...}
        #self.world_wars = {}
        #降世战组的保存 {组id:组的对象}
        self.groups = {}
        #保存已获胜的玩家
        self.win_pids= []


    def start(self):
        self._game.rpc_player_mgr.rpc_sub(logon_by_war, msg_define.MSG_LOGON, _proxy=True)
        self._game.rpc_player_mgr.rpc_sub(logout_by_war, msg_define.MSG_LOGOUT, _proxy=True)
        self.load()
        self._game.res_mgr.sub(msg_define.MSG_RES_RELOAD, self.load)
        self._loop_task_war = spawn(self._loop_war)

    def load(self):
        """ 加载数据 """
        self.res_warstart_configs = self._game.res_mgr.awar_start_configs
        self.res_strong_map = self.init_strong_map()

    def gm_kill_monsters(self, pid):
        """ 秒杀制定玩家该战场出现的怪物 """
        return self.room_mgr.gm_kill_monsters(pid)

    def gm_start_activity(self, war_type, time=300):
        """ gm开启活动 """
        if time > 300:
            time = 300
        self.stop_activity()
        now_sec = common.current_time() - common.zero_day_time()
        for res_warstart in self.res_warstart_configs.itervalues():
            if war_type == res_warstart.type:
                self.warstart_config = copy.copy(res_warstart)
                self.warstart_config.etime = now_sec + 60 * 60
                start_time = now_sec + time
                self.warstart_config.stime = start_time
                log.debug('gm-start----- %s, %s', start_time, res_warstart.type)
                break
        l_sec = self.warstart_config.stime - now_sec
        if l_sec <= self.warstart_config.ntime:
            spawn(self._notice, l_sec)

    def stop_activity(self):
        """ 停止当前的活动 """
        log.debug('stop_activity---- ')
        self.room_mgr.stop_war()
        self.init()

    def init_strong_map(self):
        """ 初始化降龙战势力地图 """
        res_strong_map = Game.res_mgr.awar_strong_maps
        dic = {}
        for id, o in res_strong_map.iteritems():
            try:
                smid = float(o.smids)
                smids = [int(smid)]
            except:
                smids = common.str2list(o.smids)
            dic[id] = smids
        return dic

    def player_logon(self, pid):
        """ 玩家登陆监听 """
        if not self.warstart_config:
            return
        if pid in self.win_pids:
            return
        ally = Game.rpc_ally_mgr.get_ally_by_pid(pid)
        if not ally:
            return
        if ally.data.level < self.warstart_config.unlock:
            return
        l_sec = self.warstart_config.stime - (common.current_time()-common.zero_day_time())
        if l_sec > self.warstart_config.ntime:
            return
        sleep(10)
        self._notice(l_sec, [pid])

    def player_logout(self, pid):
        """ 玩家退出监听 """
        self.exit_room(pid)
        rs, is_win = self.room_mgr.player_logout(pid)
        log.debug('is--win %s, rs %s pid %s', pid, rs, is_win)
        if rs and is_win:
            self.win_pids.append(pid)
            self.clear_player_data(pid)

    def _loop_war(self):
        """ 活动开启提前通知 """
        while 1:
            now_sec = common.current_time() - common.zero_day_time()
            #开启的活动结束
            if self.warstart_config and now_sec > self.warstart_config.etime:
                if self.time_start():
                    #本次开启活动时清楚上一次的数据
                    self.stop_activity()
            #未开启活动时
            elif self.warstart_config is None:
                self.time_start()
            sleep(1)

    def time_start(self):
        """ 根据当前时间和配置表数据对应开启活动 """
        now_sec = common.current_time() - common.zero_day_time()
        for res_config in self.res_warstart_configs.itervalues():
            notice_time = res_config.stime - res_config.ntime
            if notice_time <= now_sec < res_config.etime:
                self.warstart_config = res_config
                l_sec = now_sec - res_config.stime
                spawn(self._notice, l_sec)
                log.debug('start----- %s, %s', res_config.stime, res_config.type)
                return True
        return False

    def _notice(self, l_sec, pids=None):
        """ 活动开启提前广播 """
        notice_resp_f = 'awarNotice'
        if pids is None:
            pids = self._game.rpc_ally_mgr.get_allypids_by_level(self.warstart_config.unlock)
        if not pids:
            return
        data = dict(type=self.warstart_config.type, ltime=l_sec)
        msg = pack_msg(notice_resp_f, 1, data=data)
        self._game.rpc_player_mgr.player_send_msg(pids, msg)

    def enter_room(self, pid, rnum):
        """ 进入房间 """
        #获胜玩家禁止进入
        if pid in self.win_pids:
            return False, errcode.EC_ALLY_WAR_WINED
        #掉线重连 回到之前的房
        if not rnum:
            rs, data = self.room_mgr.reconnection(pid)
            if rs:
                return rs, data
        if self.warstart_config is None:
            return False, errcode.EC_ALLY_ACTIVIY_END
        return self.room_mgr.enter(pid, self.warstart_config, rnum=rnum)

    def exit_room(self, pid):
        """ 退出房间 """
        self.room_mgr.exit(pid)
        return True, None

    def start_war(self, pid):
        """ 开战 """
        group = None
        if self.warstart_config.type == constant.ALLY_WORLD_WAR:
            group = self.get_group(pid)
        return self.room_mgr.start_war(pid, group)

    def get_group(self, pid):
        """ 获取降龙战的组 """
        aid = Game.rpc_ally_mgr.get_aid_by_pid(pid)
        enter_group = None
        #加入现有的组(规则：统一组不能有相同的同盟)
        for gid, group in self.groups.iteritems():
            if group.join(aid):
                enter_group = group
                break
        #没有符合的组开新组
        if enter_group is None:
            id = len(self.groups)+1
            enter_group = Group.new(self, id, [aid])
            self.groups[id] = enter_group
        return enter_group

    def war_monster_start(self, pid, ancid):
        """ 击杀怪物开始 """
        return self.room_mgr.war_monster_start(pid, ancid)

    def war_copy_start(self, pid, ancid):
        """ 击杀影分身开始 """
        return self.room_mgr.war_copy_start(pid, ancid)

    def war_monster_end(self, pid, ancid, is_win, hurts):
        """ 击杀怪物结束 """
        return self.room_mgr.war_monster_end(pid, ancid, is_win, hurts)
    
    def use_book(self, pid, bid):
        """ 使用天书 """
        return self.room_mgr.use_book(pid, bid)

    def exchange_book(self, pid, bid):
        """ 兑换天书 """
        return self.room_mgr.exchange_book(pid, bid)

    def connon_fire(self, pid, index):
        """ 开炮 """
        return self.room_mgr.connon_fire(pid, index)
    
    def choose_node(self, pid, node, type):
        """ 队长选择路线 """
        return self.room_mgr.choose_node(pid, node, type)
    
    def get_map(self, pid):
        """ 获取魔龙降世势力图 """
        return self.room_mgr.get_map(pid)

    def get_box(self, pid):
        """ 获取宝箱 """
        rs, data =  self.room_mgr.get_box(pid)
        self.clear_player_data(pid)
        return rs, data, self.warstart_config.type

    def get_roomkey_by_pid(self, pid):
        """ 通过pid获取房间id """
        return self.room_mgr.get_roomkey_by_pid(pid)

    def fetch_res(self, key, value):
        return self._game.setting_mgr.setdefault(key, value)

    def get_start_activity(self, pid):
        """ 活动是否开启 """
        ally = self._game.rpc_ally_mgr.get_ally_by_pid(pid)
        now_sec = common.current_time() - common.zero_day_time()
        if self.warstart_config and self.warstart_config.stime < now_sec and \
           ally.data.level >= self.warstart_config.unlock:
            return True, self.warstart_config.type
        return False, None
    
    def get_activity_time(self, aid):
        """ 获取当日开启的时间 """
        alevel = Game.rpc_ally_mgr.ally_level_by_aid(aid)
        rs1 = rs2 = ''
        for res_config in self.res_warstart_configs.itervalues():
            if alevel >= res_config.unlock:
                hour = res_config.stime / 3600
                s_sec = res_config.stime % 3600
                sec = s_sec / 60
                rs = '%d:%d' % (hour, sec)
                if res_config.type == ALLY_SKY_WAR and not rs1:
                    rs1 = rs
                elif res_config.type == ALLY_SKY_WAR and rs1:
                    rs1 = '%s/%s' % (rs1, rs)
                elif res_config.type == ALLY_WORLD_WAR and not rs2:
                    rs2 = rs
                elif res_config.type == ALLY_WORLD_WAR and rs2:
                    rs2 = '%s/%s' % (rs2, rs)
        return rs1, rs2

    def get_room_data(self, pid):
        """ 获取房间数据 """
        return self.room_mgr.get_room_data(pid)

    def clear_player_data(self, pid):
        """ 清楚玩家数据 """
        self.room_mgr.clear_player_data(pid)

    def get_assess(self, pid):
        """ 获取评级 """
        return self.room_mgr.get_assess(pid)

    def handle_reward(self, pid, reward_items):
        """ 处理奖励的经验加成 """
        return self.room_mgr.handle_reward(pid, reward_items)
    
    def set_win_pids(self, pids):
        """ 获胜玩家保存 """
        if pids:
            self.win_pids.extend(pids)

class Copy(object):
    """ 隐分数数据 """
    def __init__(self):
        self.ancid = 0  #战斗npc配置表id
        self.pid = 0
        self.rid = 0    #主将id
        self.q = 0      #品质
        self.name = ''  #玩家名
        self.aname = '' #同盟名
        self.eqid = 0   #主角的装备id

    def to_dict(self):
        """ 返回打包的数据 """
        return self.__dict__




class Group(object):
    """ 降龙战的组 """
    def __init__(self):
        self.id = None
        self.war_mgr = None
        #该组已参与有的同盟id
        self.aids = []
        #{节点:隐分身同盟名, ... }
        self.node_aname = {}
        #{节点:{战斗npc配置表id:影分身数据,...], ... }
        self.node_copys = {}
        #隐分身的管理器
        self.copy_mgr = CopyMgr()

    @classmethod
    def new(cls, mgr, id, aids):
        o = cls()
        o.id = id
        o.war_mgr = mgr
        o.aids = aids
        return o

    def get_node(self, aid):
        """ 通过pid获取玩家同盟当前所在的节点id """
        aname = Game.rpc_ally_mgr.ally_name_by_aid(aid)
        for node, naname in self.node_aname.iteritems():
            if aname == naname:
                return node
        return
    
    def auto_choose(self, node):
        """ 自动选取 """
        nodes = self.war_mgr.res_strong_map[node]
        return random.choice(nodes)

    def join(self, aid):
        """ 加入该组 """
        if aid in self.aids:
            return False
        self.aids.append(aid)
        return True

    def win_node(self, aid=None, node=None):
        """ 战胜节点或开始位置变化 """
        aname = Game.rpc_ally_mgr.ally_name_by_aid(aid)
        if node is None:
            min_node = -1
            if self.node_aname:
                for key_node in self.node_aname.iterkeys():
                    if min_node > key_node:
                        min_node = key_node
                node = min_node - 1
            else:
                node = min_node
        self.node_aname[node] = aname

    def get_pid_by_ancid(self, node, ancid):
        """ 通过npc配置表id获取玩家id """
        return self.copy_mgr.get_pid_by_npcid(node, ancid)

    def is_choose(self, node):
        """ 判断该节点是否可选 """
        pass



class CopyData(object):
    def __init__(self):
        self.ancid = 0  #战斗npc配置表id
        self.pid = 0
        self.rid = 0    #主将id
        self.q = 0      #品质
        self.name = ''  #玩家名
        self.aname = '' #同盟名
        self.eqid = 0   #主角的装备id

    def to_dict(self):
        """ 返回打包的数据 """
        return self.__dict__

    @classmethod
    def new(cls):
        return cls()

class CopyMgr(object):
    """ 隐分数数据 """
    def __init__(self):
        #{node:[copys...]}
        self.node2copys = {}

    def new_copys(self, aid, node):
        """ 新建隐分身数据 """
        res_node = Game.res_mgr.awar_strong_maps.get(node)
        if not res_node:
            return
        res_npc_configs = Game.res_mgr.awar_npc_configs_bykey.get(int(float(res_node.apcid)))
        ally_pids = Game.rpc_ally_mgr.member_pids_by_aid(aid)
        aname = Game.rpc_ally_mgr.ally_name_by_aid(aid)
        copys = []
        num = len(res_npc_configs)
        pid_num = len(ally_pids)
        if pid_num < num:
            ally_pids *= int(math.ceil(float(num) / pid_num))
        for res_npc_config in res_npc_configs:
            pid = ally_pids.pop()
            player = Player.load_player(pid)
            main_role = player.roles.main_role
            o = CopyData.new()
            o.ancid = res_npc_config.id
            o.pid = pid
            o.rid = main_role.data.rid
            o.q = main_role.data.q
            o.name = player.data.name
            o.aname = aname
            o.eqid = player.roles.main_role.body_equip_id
            copys.append(o)
        self.node2copys[node] = copys

    def get_copys(self, node):
        """ 获取隐分身数据 """
        copys = self.node2copys.get(node)
        if copys is None:
            return
        pack_data = []
        for copy in copys:
            pack_data.append(self.to_dict(copy))
        return pack_data

    def get_pid_by_npcid(self, node, npcid):
        """ 通过节点和npcid获取copy """
        copys = self.get_copys(node)
        for copy in copys:
            if copy["ancid"] == npcid:
                return True, copy['pid']
        return False, errcode.EC_ALLY_WAR_MDIE

    def to_dict(self, copy):
        """ 返回打包的数据 """
        return copy.to_dict()


def new_awar_mgr():
    mgr = WarMgr()
    return mgr
