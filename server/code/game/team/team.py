#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import log
from corelib.client_rpc import JsonClientRpc as ClientRpc

pack_msg = ClientRpc.pack_msg
prepare_send = ClientRpc.prepare_send

from game import Game
from game.base.constant import (
    RW_MAIL_ATBOX, MAIL_REWARD
    )
from game.player.player import Player
from game.base.common import decode_dict, is_today, current_time
from game.base.errcode import EC_TEAM_SAME_POS

def wrap_team_pid(func):
    def _func(self, pid, *args, **kw):
        if pid not in self.players:
            log.debug('player(pid) is not in team(%s)', pid, self.tid)
            return
        return func(self, pid, *args, **kw)
    return _func

class BaseTeam(object):
    """队伍基类"""
    def __init__(self, mgr, tid):
        self.mgr = mgr
        self.tid = tid
        self.pids = [] #成员列表

class AllyTBoxTeam(BaseTeam):
    """同盟时光盒炼妖队伍"""
    def init(self, pid, bid, aid):
        self.lid = pid #队长id
        self.len = 3 #队伍容量
        self.bid = bid #boss_id
        self.aid = aid #同盟id
        self.position = {} #阵型信息 {index : {pid:0, rid:0}}
        self.is_fight = False

    def join(self, pid):
        if pid not in self.pids:
            self.pids.append(pid)

    def get_fight(self):
        """获取战斗所需数据"""
        data = []
        for pid in self.pids:
            player = Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                player = Player.load_player(pid)
            if player is None:
                continue
            rids = []
            for d in self.position.itervalues():
                if d['pid'] == pid:
                    rids.append(d['rid'])
            info = player.team_look(rids)
            data.append(info)
        return data

    def get_member(self):
        """获取成员信息"""
        data = []
        onlines, rs = Game.rpc_player_mgr.get_player_infos(self.pids)
        for pid, d in rs.iteritems():
            name, rid, level = d[0], d[1], d[2]
            info = dict(n = name, rid = rid, lv = level)
            #队长放在第一位
            if pid == self.lid:
                data.insert(0, info)
            else:
                data.append(info)
        return data

    def get_pos(self):
        """获得阵型信息"""
        pos = {}
        pos.update(self.position)
        for pid in self.pids:
            player = Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                player = Player.load_player(pid)
            if player is None:
                continue
            rid, eid = player.get_main_role_eid()
            for data in pos.itervalues():
                if data['pid'] == pid and data['rid'] == rid:
                    data['eid'] = eid
        return pos

    def update_pos(self):
        """同步阵型信息"""
        resp_f = 'TeamInfo'
        data = dict(tid = self.tid, mb = self.get_pos())
        msg = pack_msg(resp_f, 1, data = data)
        msg = prepare_send(msg)
        for pid in self.pids:
            player = Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                continue
            player.send_msg(msg)

    def clean_pos(self, pid):
        """清理站位信息"""
        data = self.position.items()
        for k, v in data:
            if v['pid'] == pid:
                del self.position[k]

    def move(self, pid, pos):
        """同盟队伍位置移动"""
        self.clean_pos(pid)
        for index, rid in pos.iteritems():
            index = int(index)
            if index < 0:
                continue
            d = self.position.setdefault(index, {})
            if len(d) > 0 and d['pid'] != pid:
                return EC_TEAM_SAME_POS
            d['pid'] = pid
            d['rid'] = rid

    def exit(self, pid):
        """退出同盟队伍"""
        self.pids.remove(pid)
        self.clean_pos(pid)
        self.update_pos()

    def fight_start(self):
        """开始同盟炼妖"""
        resp_f = 'allyTTBoxStart'
        msg = pack_msg(resp_f, 1, data=dict(tid=self.tid))
        msg = prepare_send(msg)
        for pid in self.pids:
            player = Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                continue
            player.send_msg(msg)
        self.is_fight = True

    def fight_end(self, isOK, fp_id):
        """同盟炼妖结束"""
        resp_f = 'allyTTBoxEnd'
        data = dict(tid = self.tid, isOK = isOK, fp_id = fp_id)
        msg = pack_msg(resp_f, 1, data=data)
        msg = prepare_send(msg)
        for pid in self.pids:
            if pid == self.lid:
                continue
            player = Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                continue
            player.send_msg(msg)
        self.is_fight = False

    def send_reward(self):
        res_tbox = Game.res_mgr.tboxs.get(self.bid)
        if res_tbox is None:
            log.error('ally_team(%s) res_tbox is None, pids(%s)', self.tid, self.pids)
            return
        rw = Game.reward_mgr.get(res_tbox.trid)
        items = rw.reward(None)
        if items is None:
            log.error('ally_team(%s) reward_items is None, pids(%s)', self.tid, self.pids)
            return
        rw_mail = Game.res_mgr.reward_mails.get(RW_MAIL_ATBOX)
        boss = Game.res_mgr.monsters.get(res_tbox.tmid)
        content = rw_mail.content % dict(name = boss.name)
        pids = []
        for pid in self.pids:
            player = Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                player = Player.load_player(pid)
            if player is None:
                continue
            data = player.get_ally_tbox_data()
            if not is_today(data['t']):
                data['bids'] = []
                data['cr'] = 0
            if len(data['bids']) == 0:
                data['bids'].append(self.bid)
                data['t'] = current_time()
                pids.append(pid)
            if pid == self.lid:
                data['cr'] += 1
            player.set_ally_tbox_data(data)
        Game.mail_mgr.send_mails(pids, MAIL_REWARD, rw_mail.title, content, items)

def wrap_modified(func):
    def _func(self, *args, **kw):
        func(self, *args, **kw)
        self.modified = True
    return _func

class ArenaTeam(BaseTeam):
    """组队竞技"""
    @wrap_modified
    def init(self, pid, name):
        self.id = None #数据库id
        self.lid = pid #队长id
        self.position = {} #阵型信息 {index : {pid:0, rid:0}}
        self.len = 3 #队伍最大成员数
        self.name = name #队伍名字
        self.state = 0 #队伍状态 0=等待状态 1=应战状态
        self.rank = 0 #队伍排名
        self.num = 0 #队伍积分
        self.chg = 0 #今日挑战次数
        self.t_chg = 0 #上一次挑战次数刷新时间
        self.request = [] #申请加入玩家列表
        self.succ = 0 #胜利次数
        self.fail = 0 #失败次数

        self.rival = None #挑战队伍 (tid, name)
        self.modified = False

    @wrap_modified
    def change_state(self, state):
        self.state = state

    @wrap_modified
    def change_name(self, name):
        self.name = name

    @wrap_modified
    def join(self, pid):
        self.pids.append(pid)
        self.state = 0
        #设置默认站位

    def clean_pos(self, pid):
        data = self.position.items()
        for k, v in data:
            if v['pid'] == pid:
                del self.position[k]

    @wrap_modified
    def move(self, pid, pos):
        """竞技场队伍位置变更"""
        self.clean_pos(pid)
        for index, rid in pos.iteritems():
            index = int(index)
            if index < 0:
                continue
            d = self.position.setdefault(index, {})
            d['pid'] = pid
            d['rid'] = rid

    @wrap_modified
    def exit(self, pid):
        """退出竞技场队伍"""
        self.pids.pop(pid)
        self.clean_pos(pid)
        self.state = 0
        if pid == self.lid and len(self.pids) > 0:
            self.lid = self.pids[0]
        #广播
        resp_f = 'arenaTeamExit'
        msg = pack_msg(resp_f, 1, data=self.get_info())
        msg = prepare_send(msg)
        for pid in self.pids:
            player =  Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                continue
            player.send_msg(msg)

    def fight_end(self, isOK, fp_id):
        resp_f = 'arenaTeamFightEnd'
        msg = pack_msg(resp_f, 1, data=dict(n=self.name, tid=self.tid, isOK=isOK, fp_id=fp_id))
        msg = prepare_send(msg)
        for pid in self.pids:
            if pid == self.lid:
                continue
            player =  Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                continue
            player.send_msg(msg)

    def get_pos(self):
        """获得阵型信息"""
        pos = {}
        pos.update(self.position)
        for pid in self.pids:
            player = Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                player = Player.load_player(pid)
            if player is None:
                continue
            rid, eid = player.get_main_role_eid()
            for data in pos.itervalues():
                if data['pid'] == pid and data['rid'] == rid:
                    data['eid'] = eid
        return pos

    def get_fight(self):
        """获得战斗需要的数据"""
        infos = []
        for pid in self.pids:
            player = Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                player = Player.load_player(pid)
            if player is None:
                continue
            rids = []
            for data in self.position.itervalues():
                if data['pid'] == pid:
                    rids.append(data['rid'])
            info = player.team_look(rids)
            infos.append(info)
        return infos

    def get_info(self):
        """获得队伍详细信息"""
        mb = self.get_member()
        pos = self.get_pos()
        return dict(n=self.name, tid=self.tid, num=self.num, rk=self.rank, fn=self.succ+self.fail,
            succ=self.succ/(self.succ+self.fail), chg=self.chg, s=self.state, mb=mb, pos=pos)

    def get_member(self):
        """获得成员信息"""
        mb = []
        onlines, rs = Game.rpc_player_mgr.get_player_infos(self.pids)
        for pid, d in rs.iteritems():
            if pid == self.lid:
                mb.insert(0, dict(n=d[0], rid=d[1], lv=d[2]))
            else:
                mb.append(dict(n=d[0], rid=d[1], lv=d[2]))

    def save(self):
        pos = decode_dict(self.position, ktype=str)
        data = dict(id=self.id, n=self.name, lid=self.lid, s=self.state, rk=self.rank, num=self.num,
            chg=self.chg, t_chg=self.t_chg, pids=self.pids, rq=self.request,
            succ=self.succ, fail=self.fail, pos=pos)
        if self.id is None:
            self.id = Game.rpc_store.insert(tname, data)
        else:
            Game.rpc_store.save(tname, data)

    def load(self):
        Game.rpc_store
