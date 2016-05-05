#!/usr/bin/env python
# -*- coding:utf-8 -*-

import random

import app
from corelib import log, common

from game import Game
from game.base import errcode, msg_define
from .team import AllyTBoxTeam, ArenaTeam
from game.base.constant import (
    MAIL_NORMAL, REPORT_TYPE_ARENA_TEAM,
    REPORT_TYPE_ALLY_TBOX
    )
from game.base.common import is_today

from corelib.client_rpc import JsonClientRpc as ClientRpc

pack_msg = ClientRpc.pack_msg
prepare_send = ClientRpc.prepare_send

class TeamMgr(object):
    """队伍管理器"""
    _rpc_name_ = 'rpc_team_mgr'

    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        self.iter_id = common.IterId()
        self.ally_tbox_mgr = AllyTboxTeamMgr(self)
        self.arena_mgr = ArenaTeamMgr(self)
        app.sub(msg_define.MSG_START, self.start)

    def start(self):
        Game.rpc_player_mgr.sub(msg_define.MSG_LOGOUT, self.player_logout)
        self.load()

    def stop(self):
        self.save()

    def load(self):
        self.arena_mgr.load()

    def save(self):
        self.arena_mgr.save()

    def get_id(self):
        return self.iter_id.next()

    def player_logout(self, pid):
        """玩家下线"""
        self.ally_tbox_mgr.exit(pid)

    def disband(self, tid):
        """解散队伍"""
        team = self.ally_tbox_mgr.teams.get(tid)
        if team:
            self.ally_tbox_mgr.disband(team)
            self._disband(team)
            return True, ''
        return False, errcode.EC_TEAM_NOT_FIND

    def _disband(self, team):
        resp_f = 'TeamDisband'
        msg = pack_msg(resp_f, 1, data=dict(tid = team.tid))
        msg = prepare_send(msg)
        for pid in team.pids:
            player = Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                continue
            player.send_msg(msg)

    def get_fight_info(self, tid):
        """获得战斗计算数据"""
        team = self.ally_tbox_mgr.teams.get(tid)
        if team:
            pos = team.get_pos()
            info = team.get_fight()
            return dict(players = info, mb = pos, lid = team.lid)

    def ally_tbox_new(self, pid, bid, aid):
        """新建同盟炼妖队伍"""
        return self.ally_tbox_mgr.new(pid, bid, aid)

    def ally_tbox_list(self, aid):
        """获得同盟队伍列表信息"""
        return self.ally_tbox_mgr.get_infos_by_aid(aid)

    def ally_tbox_add(self, tid, pid):
        """加入同盟队伍"""
        return  self.ally_tbox_mgr.join(tid, pid)

    def ally_tbox_move(self, pid, pos):
        """同盟队伍位置移动"""
        return self.ally_tbox_mgr.move(pid, pos)

    def ally_tbox_exit(self, pid):
        """退出同盟队伍"""
        return self.ally_tbox_mgr.exit(pid)

    def ally_tbox_start(self, pid):
        """开始同盟炼妖"""
        return self.ally_tbox_mgr.fight_start(pid)

    def ally_box_end(self, pid, isOK, fp):
        """同盟炼妖结束"""
        return self.ally_tbox_mgr.fight_end(pid, isOK, fp)

    def arena_new(self, pid, name):
        """创建竞技场队伍"""
        return self.arena_mgr.new(pid, name)

    def arena_change_state(self, pid, state):
        """更换竞技场队伍状态"""
        return self.arena_mgr.change_state(pid, state)

    def arena_change_name(self, pid, name):
        """"更换竞技场队伍名称"""
        return self.arena_mgr.change_name(pid, name)

    def arena_invite(self, pid, p_name, pids):
        """竞技场组队邀请"""
        return self.arena_mgr.invite(pid, p_name, pids)

    def arena_list(self):
        """获取竞技场队伍列表"""
        return self.arena_mgr.list()

    def arena_join_request(self, pid, p_name):
        """申请加入竞技场队伍"""
        return self.arena_mgr.join_request(pid, p_name)

    def arena_join_response(self, lid, l_name, pid, isOK):
        """竞技场队伍申请回复"""
        return self.arena_mgr.join_response(lid, l_name, pid, isOK)

    def arena_fight_end(self, pid, fp, isOK):
        """竞技场组队战斗结束"""
        return self.arena_mgr.fight_end(pid, fp, isOK)

    def arena_fight_info(self, pid):
        """竞技场战斗数据请求"""
        return self.arena_mgr.fight_info(pid)

    def arena_move(self, pid, pos):
        """竞技场队伍位置移动"""
        return self.arena_mgr.move(pid, pos)

    def arena_exit(self, pid):
        """退出竞技场队伍"""
        return self.arena_mgr.exit(pid)

    def arena_disband(self, pid):
        """竞技场队伍解散"""
        return self.arena_mgr.arena_disband(pid)

class AllyTboxTeamMgr(object):
    """同盟组队炼妖管理"""
    TEAM_CLS = AllyTBoxTeam
    def __init__(self, mgr):
        self.mgr = mgr
        self.teams = {} #{tid:team}
        self.pid2team = {} #{pid:team}
        self.aid2teams ={} #{aid:[team]}

    def disband(self, team):
        """解散队伍"""
        self.teams.pop(team.tid)
        aid_teams = self.aid2teams.get(team.aid)
        if aid_teams:
            aid_teams.remove(team)
        for pid in team.pids:
            if pid in self.pid2team:
                del self.pid2team[pid]
        self.mgr._disband(team)

    def get_infos_by_aid(self, aid):
        """获得同盟队伍信息"""
        data = []
        teams = self.aid2teams.get(aid, [])
        for team in teams:
            #战斗中的队伍不显示
            if team.is_fight:
                continue
            mb = team.get_member()
            d = dict(tid = team.tid, tbid = team.bid, mb = mb)
            data.append(d)
        return data

    def new(self, pid, bid, aid):
        if pid in self.pid2team:
            return False, errcode.EC_TEAM_SAME_NEW
        #同一玩家1天只能创建1次队伍
        player = Game.rpc_player_mgr.get_rpc_player(pid)
        if player is None:
            return False, errcode.EC_PLAYER_EMPTY
        data = player.get_ally_tbox_data()
        if not is_today(data['t']):
            data['cr'] = 0
        if 'cr'in data and data['cr'] > 0:
            return False, errcode.EC_TEAM_CAN_NOT_NEW

        team = self.TEAM_CLS(self, self.mgr.get_id())
        team.init(pid, bid, aid)
        team.join(pid)
        self.teams[team.tid] = team
        self.pid2team[pid] = team
        aid2teams = self.aid2teams.setdefault(aid, [])
        aid2teams.append(team)
        return True, team.tid

    def join(self, tid, pid):
        """加入同盟队伍"""
        if tid not in self.teams:
            return False, errcode.EC_TEAM_NOT_FIND
        if pid in self.pid2team:
            return False, errcode.EC_TEAM_SAME_NEW
        team = self.teams.get(tid)
        if pid in team.pids:
            return False, errcode.EC_TEAM_SAME_NEW
        if team.is_fight:
            return False, errcode.EC_TEAM_IS_FIGHT
        if team.len <= len(team.pids):
            return False, errcode.EC_TEAM_ROLE_FULL
        team.join(pid)
        self.pid2team[pid] = team
        common.spawn_later(0, team.update_pos)
        return True, ''

    def move(self, pid, pos):
        """同盟队伍位置移动"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(pid)
        if pid not in team.pids:
            return False, errcode.EC_TEAM_NOT_IN_TEAM
        if len(pos) > 2:
            return False, errcode.EC_TEAM_ROLE_FULL
        err = team.move(pid, pos)
        if err:
            return False, err
        team.update_pos()
        return True, ''

    def exit(self, pid):
        """退出同盟队伍"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(pid)
        if pid not in team.pids:
            return False, errcode.EC_TEAM_NOT_IN_TEAM
        team.exit(pid)
        self.pid2team.pop(pid)
        if len(team.pids) == 0 or pid == team.lid:
            self.disband(team)
        return True, ''

    def fight_start(self, pid):
        """开始同盟炼妖"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(pid)
        if pid not in team.pids:
            return False, errcode.EC_TEAM_NOT_IN_TEAM
        if pid != team.lid:
            return False, errcode.EC_TEAM_NO_POWER
        team.fight_start()
        return True, ''

    def fight_end(self, pid, isOK, fp):
        """同盟炼妖结束"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(pid)
        if pid not in team.pids:
            return False, errcode.EC_TEAM_NOT_IN_TEAM
        if pid != team.lid:
            return False, errcode.EC_TEAM_NO_POWER
        #保存战报
        fp_id = Game.rpc_report_mgr.save(REPORT_TYPE_ALLY_TBOX, team.pids, fp)
        #广播战报 发奖励
        team.fight_end(isOK, fp_id)
        if isOK:
            team.send_reward()
        #队伍解散
        self.disband(team)
        return True, ''

class ArenaTeamMgr(object):
    """竞技场组队管理"""
    TEAM_CLS = ArenaTeam
    def __init__(self, mgr):
        self.mgr = mgr
        self.teams = {} #{tid:team}
        self.pid2team = {} #{pid:team}
        self.name2team ={} #{name:team}

    def save(self):
        pass

    def load(self):
        pass

    def new(self, pid, name):
        """创建竞技场队伍"""
        if name in self.name2team:
            return False, errcode.EC_TEAM_ERR_NAME
        team = self.TEAM_CLS(self, self.mgr.get_id())
        team.init(pid, name)
        team.join(pid)
        self.teams[team.tid] = team
        self.pid2team[pid] = team
        self.name2team[name] = team
        return True, team.tid

    def change_state(self, pid, state):
        """更换竞技场队伍状态"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(pid)
        if pid not in team.pids:
            return False, errcode.EC_TEAM_NOT_IN_TEAM
        if pid != team.lid:
            return False, errcode.EC_TEAM_NO_POWER
        team.change_state(state)
        return True, ''

    def change_name(self, pid, name):
        """更换竞技场队伍名称"""
        if name in self.name2team:
            return False, errcode.EC_TEAM_ERR_NAME
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(pid)
        if pid not in team.pids:
            return False, errcode.EC_TEAM_NOT_IN_TEAM
        if pid != team.lid:
            return False, errcode.EC_TEAM_NO_POWER
        self.name2team.pop(team.name)
        team.change_name(name)
        self.name2team[name] = team
        return True, ''

    def invite(self, pid, p_name, pids):
        """发送竞技场队伍邀请"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(pid)
        if pid not in team.pids:
            return False, errcode.EC_TEAM_NOT_IN_TEAM
        title = u'竞技场组队邀请'
        content = u'%s 在竞技场创建了 %s 队伍，邀请你加入！' % (p_name, team.name)
        items = None
        Game.mail_mgr.send_mails(pids, MAIL_NORMAL, title, content, items)
        return True, ''

    def list(self):
        """获得竞技场队伍列表"""
        teams = self.teams.values()
        data = []
        for i in xrange(10):
            if len(teams) == 0:
                continue
            team = random.choice(teams)
            teams.pop(team)
            mb = team.get_member()
            data.append(dict(n=team.name, tid=team.tid, num=team.num, rk=team.rank, mb=mb))
        return data

    def join_request(self, pid, p_name):
        """申请加入竞技场队伍"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(pid)
        if pid in team.request:
            return False, errcode.EC_TEAM_ERR_REQUEST
        if pid in self.pid2team:
            return False, errcode.EC_TEAM_SAME_NEW
        title = u'竞技场组队申请'
        content = u'%s 申请加入你的队伍！' % p_name
        items = None
        Game.mail_mgr.send_mails([team.lid], MAIL_NORMAL, title, content, items)
        team.request.append(pid)
        return True, ''

    def join_response(self, lid, l_name, pid,  isOK):
        """竞技场队伍申请批复"""
        if lid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(lid)
        if lid != team.lid:
            return False, errcode.EC_TEAM_NO_POWER
        if pid in self.pid2team:
            return False, errcode.EC_TEAM_SAME_NEW
        if pid not in team.request:
            return False, errcode.EC_TEAM_NO_REQUEST
        if team.len >= 3:
            return False, errcode.EC_TEAM_ROLE_FULL
        if isOK:
            title = u'竞技场组队申请回复'
            content = u'%s 的队长 %s 批准你加入队伍！' % (team.name, l_name)
            items = None
            Game.mail_mgr.send_mails([team.lid], MAIL_NORMAL, title, content, items)
            team.join(pid)
            self.pid2team[pid] = team
        else:
            title = u'竞技场组队申请回复'
            content = u'%s 的队长 %s 拒绝了你的加入申请！' % (team.name, l_name)
            items = None
            Game.mail_mgr.send_mails([team.lid], MAIL_NORMAL, title, content, items)
        team.request.remove(pid)
        return True, ''

    def fight_end(self, pid, fp, isOK):
        """竞技场队伍战斗结束"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        myteam = self.pid2team.get(pid)
        if myteam.rival is None:
            return False, errcode.EC_TEAM_NOT_FIND
        if pid != myteam.lid:
            return False, errcode.EC_TEAM_NO_POWER
        oth_team = self.name2team.get(myteam.rival[1])
        pids = []
        pids.extend(myteam.pids)
        pids.extend(oth_team.pids)
        #保存战报
        fp_id = Game.rpc_report_mgr.save(REPORT_TYPE_ARENA_TEAM, pids, fp)
        myteam.fight_end(isOK, fp_id)
        title = u'竞技场组队战报'
        if isOK:
            content = u'%s 在竞技场中，战胜了 %s' % (myteam.name, oth_team.name)
            #增加积分，修改排名
            myteam.succ += 1
            oth_team.fail += 1
            myteam.num += 10
            oth_team.num += 2
        else:
            content = u'%s 在竞技场中，被 %s 击败了' % (myteam.name, oth_team.name)
            #增加积分，修改排名
            myteam.fail += 1
            oth_team.succ += 1
            oth_team.num += 10
            myteam.num += 2
        items = None
        Game.mail_mgr.send_mails(pids, MAIL_NORMAL, title, content, items)
        return True, ''

    def fight_info(self, pid):
        """获取竞技场组队战斗信息"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        myteam = self.pid2team.get(pid)
        if myteam.state == 0:
            return False, errcode.EC_TEAM_ERR_STATE
        #循环20次抽取队伍
        for i in xrange(20):
            oth_team = random.choice(self.teams.values())
            if oth_team.state == 1 and oth_team.name != myteam.name:
                data = []
                #本队信息
                myteam.rival = (oth_team.tid, oth_team.name)
                pos = myteam.get_pos()
                fight = myteam.get_fight()
                data.append(dict(players = fight, mb = pos, lid = myteam.lid))
                #敌队信息
                pos = oth_team.get_pos()
                fight = oth_team.get_fight()
                data.append(dict(players = fight, mb = pos, lid = myteam.lid))
                return True, data
        return False, errcode.EC_TEAM_NO_RIVAL

    def move(self, pid, pos):
        """竞技场队伍位置变更"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(pid)
        if pid not in team.pids:
            return False, errcode.EC_TEAM_NOT_IN_TEAM
        team.move(pid, pos)
        rs = team.get_pos()
        resp_f = 'arenaTeamMove'
        msg = prepare_send(pack_msg(resp_f, 1, data=dict(mb=rs)))
        for pid in team.pids:
            player =  Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                continue
            player.send_msg(msg)

    def disband(self, team):
        """解散队伍"""
        self.teams.pop(team.tid)
        self.name2team.pop(team.name)
        for pid in team.pids:
            if pid in self.pid2team:
                del self.pid2team[pid]

    def exit(self, pid):
        """退出竞技场队伍"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(pid)
        if pid not in team.pids:
            return False, errcode.EC_TEAM_NOT_IN_TEAM
        team.exit(pid)
        self.pid2team.pop(pid)
        if len(team.pids) == 0:
            self.disband(team)
        return True, ''

    def arena_disband(self, pid):
        """竞技场队伍解散"""
        if pid not in self.pid2team:
            return False, errcode.EC_TEAM_NOT_FIND
        team = self.pid2team.get(pid)
        if pid != team.lid:
            return False, errcode.EC_TEAM_NO_POWER
        resp_f = 'arenaTeamDisband'
        msg = prepare_send(pack_msg(resp_f, 1, data=dict(n=team.name, tid=team.tid)))
        for pid in team.pids:
            player =  Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                continue
            player.send_msg(msg)
            self.pid2team.pop(pid)
        self.disband(team)

def new_team_mgr():
    mgr = TeamMgr()
    return mgr