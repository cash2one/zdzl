#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game import Game, spawn, sleep, pack_msg
from game.base import common, errcode
from game.base.constant import ALLY_SKY_WAR
from game.base.constant import ALLY_WORLD_WAR

from .war_sky import WarSky
from .war_world import WarWorld

def wrap_get_room(func):
    """ 通过pid获取他的room对象 """
    def _func(self, pid, *args, **kw):
        room_id = self.pid_room.get(pid)
        room = self.rooms.get(room_id)
        if room is None:
            return False, errcode.EC_ALLY_WAR_NOROOM
        kw['room'] = room
        return func(self, pid, *args, **kw)
    return _func

class RoomMgr(object):
    """ 房间管理类 """
    def __init__(self):

        #保存同盟id对应的房间key{aid :[room_id,]}
        self.aid_rooms = {}
        #进入房间后的保存 {pid:room_id...}
        self.pid_room = {}
        #{room_id:room,...}
        self.rooms = {}
        #记录当前最大的房间id
        self.mroom_id = 0
        #该次活动的唯一标示
        self.key = common.current_time()

    def build(self, pid, aid, res_warstart_config):
        """ 建房 """
        #根据类型初始化战斗对象
        type = res_warstart_config.type
        if type == ALLY_SKY_WAR:
            war = WarSky()
        else:
            war = WarWorld()
        room_id = self.get_next_roomid()
        room = Room.build(room_id, aid, war, res_warstart_config)
        rs, data = room.join(pid)
        room_ids = self.aid_rooms.setdefault(aid, [])
        room_ids.append(room_id)
        self.pid_room[pid] = room_id
        self.rooms[room_id] = room
        return rs, data

    def get_next_roomid(self):
        """ 获取下一个room的id """
        self.mroom_id += 1
        return self.mroom_id

    def enter(self, pid, res_warstart_config, rnum=0):
        """ 进入房间 """
        #邀请的直接进入某房间
        if rnum:
            room = self.rooms.get(rnum)
            if room is None:
                return False, errcode.EC_ALLY_WAR_ROOMED
            rs, data = room.join(pid)
            if rs:
                self.pid_room[pid] = rnum
            return rs, data
        #活动进入
        if res_warstart_config.type == ALLY_SKY_WAR:
            return self.enter_sky_war(pid, res_warstart_config)
        elif res_warstart_config.type == ALLY_WORLD_WAR:
            return self.enter_world_war(pid, res_warstart_config)
        return False, errcode.EC_VALUE
    
    def enter_sky_war(self, pid, res_warstart_config):
        """ 活动入库进入守龙战 直接建房  """
        #守龙战活动进入建房
        aid = Game.rpc_ally_mgr.get_aid_by_pid(pid)
        return self.build(pid, aid, res_warstart_config)

    def enter_world_war(self, pid, res_warstart_config):
        """ 活动入口进入房间 (建房\进入)
            返回 True  None=进入，非None=建房的
        """
        aid = Game.rpc_ally_mgr.get_aid_by_pid(pid)
        if aid is None:
            return False, errcode.EC_NO_ALLY
        room_ids = self.aid_rooms.get(aid)
        is_join = False
        if room_ids:
            for room_id in room_ids:
                room = self.rooms.get(room_id)
                rs, data = room.join(pid)
                if rs is False:
                    continue
                self.pid_room[pid] = room_id
                is_join = True
                break
        if is_join is False:
            rs, data = self.build(pid, aid, res_warstart_config)
        return True, data

    def exit(self, pid):
        """ 退出房间 """
        room_id = self.pid_room.get(pid)
        if room_id is None:
            return
        room = self.rooms.get(room_id)
        #已开启战斗玩家不退出房间
        if room.war.war_data:
            return
        self.pid_room.pop(pid)
        rs = room.exit(pid)
        if rs == DESTRY:
            aid = Game.rpc_ally_mgr.get_aid_by_pid(pid)
            rooms = self.aid_rooms.get(aid)
            if rooms:
                rooms.remove(room_id)
            self.rooms.pop(room_id)

    @wrap_get_room
    def start_war(self, pid, group, room=None):
        """ 开战 """
        rs = room.is_teamleader(pid)
        if rs is False:
            return rs, errcode.EC_ALLY_WAR_NOTEAMER
        return room.start_war(pid, group)

    @wrap_get_room
    def war_monster_start(self, pid, ancid, room=None):
        """ 击杀怪物开始 """
        return room.war.war_monster_start(pid, ancid)

    @wrap_get_room
    def war_copy_start(self, pid, ancid, room=None):
        """ 击杀影分身开始 """
        return room.war.war_copy_start(pid, ancid)

    @wrap_get_room
    def gm_kill_monsters(self, pid, room=None):
        """ 秒杀制定玩家该战场出现的怪物 """
        return room.war.gm_kill_monsters(pid)

    @wrap_get_room
    def war_monster_end(self, pid, ancid, is_win, hurts, room=None):
        """ 击杀怪物结束 """
        if room.war.war_per_config.type == ALLY_WORLD_WAR and not is_win:
            room.war.record_war_fail()
        return room.war.war_monster_end(pid, ancid, is_win, hurts)

    @wrap_get_room
    def use_book(self, pid, bid, room=None):
        """ 使用天书 """
        rs, data = room.war.use_book(pid, bid)
        if rs and room.war.war_per_config.type == ALLY_WORLD_WAR:
            room.war.record_use_book()
        return rs, data

    @wrap_get_room
    def exchange_book(self, pid, bid, room=None):
        """ 兑换天书 """
        return room.war.exchange_book(pid, bid)

    @wrap_get_room
    def connon_fire(self, pid, index, room=None):
        """ 开炮 """
        rs, data = room.war.connon_fire(pid, index)
        if rs and room.war.war_per_config.type == ALLY_WORLD_WAR:
            room.war.record_use_fire()
        return rs, data

    @wrap_get_room
    def choose_node(self, pid, node, type, room=None):
        """ 队长选择路线 """
        rs = room.is_teamleader(pid)
        if rs is False:
            return rs, errcode.EC_ALLY_WAR_NOTEAMER
        return room.war.choose_node(node, type, pid=pid)

    @wrap_get_room
    def get_map(self, pid, room=None):
        """ 获取魔龙降世势力图 """
        return room.war.get_map(pid)

    def invite(self):
        """ 邀请同盟队友 """
        pass

    @wrap_get_room
    def get_box(self, pid, room=None):
        """ 获取宝箱 """
        return room.war.get_box(pid)

    @wrap_get_room
    def get_assess(self, pid, room=None):
        """ 获取评级 """
        return room.war.get_assess()

    @wrap_get_room
    def handle_reward(self, pid, reward_items, room=None):
        """ 奖励对经验的处理 """
        return room.war.handle_reward(pid, reward_items)

    def get_roomkey_by_pid(self, pid):
        """ 通过玩家pid获取roomid """
        room_id = self.pid_room.get(pid)
        if room_id is None:
            return
        return '%s%s' %(self.key, room_id)
        

    @wrap_get_room
    def get_room_data(self, pid, room=None):
        """ 通过玩家id获取房间数据 """
        return True, room.get_data()

    @wrap_get_room
    def player_logout(self, pid, room=None):
        """ 掉线处理 """
        return room.player_logout(pid)

    @wrap_get_room
    def reconnection(self, pid, room=None):
        """ 掉线重连进入 广播数据 """
        return room.reconnection(pid)

    def clear_player_data(self, pid):
        """ 清楚房间数据 """
        self.rooms.pop(pid, None)

    def stop_war(self):
        """ 停止战斗 """
        for room in self.rooms.itervalues():
            room.stop_war()




#部分退出
HOLD = 1
#全部退出
DESTRY = 2

class Room(object):

    def __init__(self, room_id, aid, war, res_warstart_config):
        self.id = room_id
        self.war = war
        self.aid = aid
        self.pids = []      #房间内的玩家的pid
        self.b_time = 0     #建房时间
        self.tname = ''      #队长的名字
        self.res_warstart_config = res_warstart_config
        #天书{天书:天书数目,...}
        self.books = {}
        #天书兑换{天书id:可兑换上限，...}
        self.ebooks = {}

        self.is_war = 0
        self._loop_task_ready = spawn(self._loop_ready_war)

    def get_data(self):
        """ 获取房间数据 """
        return dict(tname=self.tname,
            pnum=len(self.pids),
            mpnum=self.res_warstart_config.mplayer)

    def _loop_ready_war(self):
        """ 准备倒计时自动开战 """
        while not self.is_war:
            now = common.current_time()
            if now >= self.b_time + self.res_warstart_config.rtime:
                Game.rpc_awar_mgr.start_war(self.pids[0])
                self.is_war = 1
                break
            sleep(1)
    
    def clear(self):
        """ 房间清楚 """
        if self._loop_task_ready is not None:
            self._loop_task_ready.kill(block=0)
            self._loop_task_ready = None

    def join(self, pid):
        """ 加入房间 """
        if self.is_war:
            return False, errcode.EC_ALLY_WAR_ING
        if len(self.pids) >= self.res_warstart_config.mplayer:
            return False, errcode.EC_ALLY_WAR_ROOMMAX
        if pid in self.pids:
            return False, errcode.EC_ALLY_WAR_ENTERED
        self.pids.append(pid)
        _, glory = Game.rpc_ally_mgr.get_glory_by_pid(pid)
        if not self.books:
            books = common.str2dict2(self.res_warstart_config.books)
            for bid, (num, emax) in books.iteritems():
                self.books[bid] = int(num)
                self.ebooks[bid] = int(emax)
        now = common.current_time()
        rtime = self.res_warstart_config.rtime - (now - self.b_time)
        if not self.tname:
            self.tname = self.get_change_tname
        data = dict(rnum=self.id,  rtime=rtime,
            pnum=len(self.pids), asid=self.res_warstart_config.id,
            glory=glory, books=self.books, tname=self.tname)
        self.join_broad(pid)
        return True, data

    def join_broad(self, enter_pid):
        """ 进入广播 """
        pnum = len(self.pids)
        if pnum == 1:
            return
        resp_f = 'awarEnterRoomB'
        data = dict(pnum=pnum)
        self.send_msg(resp_f, data, pid=enter_pid)

    def exit(self, pid):
        if pid in self.pids:
            self.pids.remove(pid)
        self.exit_broad(pid)
        if len(self.pids):
            return HOLD
        self.clear()
        return DESTRY

    def exit_broad(self, exit_pid):
        """ 退出广播 """
        pnum = len(self.pids)
        if not pnum:
            return
        resp_f = 'awarExitRoomB'
        data = dict(pnum=pnum)
        if self.tname != self.get_change_tname:
            self.tname = self.get_change_tname
            data.update({'tname':self.tname})
        self.send_msg(resp_f, data, pid=exit_pid)

    def start_war(self, pid, group):
        """ 开战 """
        self.is_war = 1
        return self.war.start(self, pid, data=group)

    def get_pids(self):
        return self.pids

    def create_pid(self):
        if len(self.pids):
            return self.pids[0]

    def send_msg(self, resp_f, data, pid=0):
        """ 主动发给客户端的数据 """
        msg = pack_msg(resp_f, 1, data=data)
        send_pids = self.pids[:]
        if pid and pid in self.pids:
            send_pids.remove(pid)
        Game.rpc_player_mgr.player_send_msg(send_pids, msg)

    def is_teamleader(self, pid):
        """ 是否是队长 """
        if self.pids and self.pids[0] == pid:
            return True
        return False
    
    def player_logout(self, pid):
        """ 掉线处理 """
        return self.war.player_logout(pid)

    def reconnection(self, pid):
        """ 掉线重连进入 广播数据 """
        return self.war.reconnection(pid)

    @property
    def get_room_id(self):
        """ 获取房间id """
        return self.id

    @property
    def get_change_tname(self):
        """ 获取队长名 """
        if not self.pids:
            return
        tpid = self.pids[0]
        _, player_infos = Game.rpc_player_mgr.get_player_infos([tpid])
        name, _, _ = player_infos.get(tpid)
        return name


    @classmethod
    def build(cls, room_id, aid, war, res_warstart_config):
        o = Room(room_id, aid, war, res_warstart_config)
        o.b_time = common.current_time()
        return o
    
    def stop_war(self):
        """ 关闭战斗 """
        if self.is_war:
            self.war.stop_war()