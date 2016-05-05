#!/usr/bin/env python
# -*- coding:utf-8 -*-
import copy
from functools import wraps

from game.base.constant import REPORT_TYPE_ARENA
from game.base import errcode, msg_define
from game.glog.common import COIN_ARENA, COIN_ADD_ARENA, TRAIN_ARENA
from game.store.define import FN_P_ATTR_CBE
from corelib import log

from .player_handler import pack_msg, reg_player_handler, BasePlayerRpcHander

def wrap_arena(func):
    @wraps(func)
    def _func(self, *args, **kw):
        if not self.player.can_arena():
            return pack_msg(func.__name__[3:], 0, err=errcode.EC_NOLEVEL)
        return func(self, *args, **kw)
    return _func

class ActivityHandler(BasePlayerRpcHander):
    """ 活动类接口 """
    def rc_actiInfo(self, allyOnly=0):
        """ 查询活动信息 """
        resp_f = 'actiInfo'
        data = self.player.get_activity_infos(allyOnly)
        return pack_msg(resp_f, 1, data=data)

    @wrap_arena
    def rc_arenaEnter(self):
        """ 进入竞技场 """
        resp_f = 'arenaEnter'
        rs, data = self.player._game.rpc_arena_mgr.enter(self.player.data.id,
                self.player.data.vip)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    @wrap_arena
    def rc_arenaStart(self, rk):
        """ 开始挑战 """
        resp_f = 'arenaStart'
        rs, rival_id = self.player._game.rpc_arena_mgr.start_arena(
                self.player.data.id, rk)
        if not rs:
            return pack_msg(resp_f, 0, err=rival_id)
        from game.mgr.arena import is_bot
        if is_bot(rival_id):
            rs, info = self.player._game.rpc_arena_mgr.look_bot(rival_id)
        else:
            rs, info = self.player._game.player_mgr.look(rival_id)
        if not rs:
            return pack_msg(resp_f, 0, err=info)
        self.player.safe_pub(msg_define.MSG_START_ARENA)
        return pack_msg(resp_f, 1, data=info)

    @wrap_arena
    def rc_arenaEnd(self, isOK, rid, fp):
        """ 挑战是否成功 """
        resp_f = 'arenaEnd'
        pid = self.player.data.id
        game = self.player._game
        #保存战报
        fp_id = self.player._game.rpc_report_mgr.save(REPORT_TYPE_ARENA,
                [rid, pid], fp)
        rs, data = self.player._game.rpc_arena_mgr.end_arena(pid,
                rid, isOK, fp_id, self.player.data.vip)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        if isOK:
            self.player.safe_pub(msg_define.MSG_WIN_ARENA)
        #奖励
        coin, train = data
        self.player.add_train(train, log_type=TRAIN_ARENA)
        self.player.add_coin(aCoin1=coin, log_type=COIN_ADD_ARENA)
        #给被挑战者发信息
        rplayer = game.rpc_player_mgr.get_rpc_player(pid)
        if rplayer:
            r_resp = 'arenaRivalEnd'
            r_data = dict(rid = pid, isOK = isOK, fp_id = fp_id)
            msg = pack_msg(r_resp, 1, data = r_data)
            rplayer.send_msg(msg)
        return pack_msg(resp_f, 1, data=self.player.pack_msg_data(coin=True, train=True))



    def rc_arenaReward(self, rk):
        """ 获取排行榜奖励内容 """
        resp_f = 'arenaReward'
        rs, items, _ = self.player._game.rpc_arena_mgr.get_reward(rk, self.player.data.level)
        if not rs:
            return pack_msg(resp_f, 0, err=items)
        return pack_msg(resp_f, 1, data=items)

    def rc_arenaBuy(self, c=1):
        """ 购买竞技次数 """
        #扣费
        resp_f = 'arenaBuy'
        rs, data = self.player._game.rpc_arena_mgr.buy_arena(self.player.data.id, c, self.player.get_coin2())
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        count, cost = data
        self.player.cost_coin(aCoin2=cost, log_type=COIN_ARENA)
        msg = self.player.pack_msg_data(coin=True)
        msg['c'] = count
        return pack_msg(resp_f, 1, data=msg)

    def rc_arenaTeamNew(self, n):
        """创建竞技场队伍"""
        resp_f = 'arenaTeamNew'
        pid = self.player.data.id
        rs, tid = self.player._game.rpc_team_mgr.arena_new(pid, n)
        if not rs:
            return pack_msg(resp_f, 0, err=tid)
        return pack_msg(resp_f, 1, data=dict(tid = tid))

    def rc_arenaTeamChangeState(self, s):
        """更换竞技场队伍状态"""
        resp_f = 'arenaTeamChangeState'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.arena_change_state(pid, s)
        if not rs:
            return pack_msg(resp_f, 0, err=err)
        return pack_msg(resp_f, 1)

    def rc_arenaTeamChangeName(self, n):
        """"更换竞技场队伍名称"""
        resp_f = 'arenaTeamChangeName'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.arena_change_name(pid, n)
        if not rs:
            return pack_msg(resp_f, 0, err=err)
        return pack_msg(resp_f, 1)

    def rc_arenaTeamInvite(self):
        """竞技场组队邀请"""
        resp_f = 'arenaTeamInvite'
        pid = self.player.data.id
        rs, pids = self.player._game.rpc_ally_mgr.member_pids_by_pid(pid)
        #没有公会
        if not rs:
            pids = []
        p_social = self.player._game.social_mgr.init_player(self.player)
        pids.extend(p_social.data.fds)
        p_name = self.player.data.name
        rs, err = self.player._game.rpc_team_mgr.arena_invite(pid, p_name, pids)
        if not rs:
            return pack_msg(resp_f, 0, err=err)
        return pack_msg(resp_f, 1)

    def rc_arenaTeamList(self):
        """获取竞技场队伍列表"""
        resp_f = 'arenaTeamList'
        rs, data = self.player._game.rpc_team_mgr.arena_list()
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_arenaTeamJoinRequest(self):
        """申请加入竞技场队伍"""
        resp_f = 'arenaTeamJoinRequest'
        pid = self.player.data.id
        p_name = self.player.data.name
        rs, err = self.player._game.rpc_team_mgr.arena_join_request(pid, p_name)
        if not rs:
            return pack_msg(resp_f, 0, err=err)
        return pack_msg(resp_f, 1)

    def rc_arenaTeamJoinResponse(self, pid, isOK):
        """竞技场队伍申请回复"""
        resp_f = 'arenaTeamJoinResponse'
        lid = self.player.data.id
        l_name = self.player.data.name
        rs, err = self.player._game.rpc_team_mgr.arena_join_response(lid, l_name, pid, isOK)
        if not rs:
            return pack_msg(resp_f, 0, err=err)
        return pack_msg(resp_f, 1)

    def rc_arenaTeamFightEnd(self, fp, isOK):
        """竞技场组队战斗结束"""
        resp_f = 'arenaTeamFightEnd'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.arena_fight_end(pid, fp, isOK)
        if not rs:
            return pack_msg(resp_f, 0, err=err)

    def rc_arenaTeamFightInfo(self):
        """竞技场战斗数据请求"""
        resp_f = 'arenaTeamFightInfo'
        pid = self.player.data.id
        rs, data = self.player._game.rpc_team_mgr.arena_fight_info(pid)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_arenaTeamMove(self, pos):
        """竞技场队伍位置移动"""
        resp_f = 'arenaTeamMove'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.arena_move(pid, pos)
        if not rs:
            return pack_msg(resp_f, 0, err=err)

    def rc_arenaTeamExit(self):
        """退出竞技场队伍"""
        resp_f = 'arenaTeamExit'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.arena_exit(pid)
        if not rs:
            return pack_msg(resp_f, 0, err=err)

    def rc_arenaTeamDisband(self):
        """竞技场队伍解散"""
        resp_f = 'arenaTeamDisband'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.arena_disband(pid)
        if not rs:
            return pack_msg(resp_f, 0, err=err)

    def rc_arenaTeamInfo(self, n, tid):
        """获取竞技场队伍详细信息"""
        resp_f = 'arenaTeamInfo'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.arena_disband(pid)

    def rc_socialFight(self, pid):
        """
        玩家之间的友善决斗
        """
        resp_f = "socialFight"
        if int(pid) == int(self.player.data.id):
            return pack_msg(resp_f, 0, err=errcode.EC_SOCIAL_FIGHT_ERR)
        rs, info = self.player._game.player_mgr.look(pid)
        if not rs:
            return pack_msg(resp_f, 0, err=info)
        info = copy.deepcopy(info)
        info.pop(FN_P_ATTR_CBE, None)
        return pack_msg(resp_f, 1, data=info)

    def rc_socialGetInfo(self, t, page):
        """
        获得玩家某页好友的信息
        """
        resp_f = "socialGetInfo"
        rs, data = self.player._game.social_mgr.get_page(self.player, t, page)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_socialAddFriend(self, pid = None, name = None):
        """
        添加好友
        """
        resp_f = 'socialAddFriend'
        if name and not pid:
            pid = self.player._game.rpc_player_mgr.get_id_by_name(name)
        if not pid:
            return pack_msg(resp_f, 0, err=errcode.EC_PLAYER_EMPTY)
        rs, data = self.player._game.social_mgr.add_friend(self.player, pid)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_socialDelFriend(self, pid):
        """
        删除好友
        """
        resp_f = 'socialDelFriend'
        rs, data = self.player._game.social_mgr.del_friend(self.player, pid)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_socialAddBlack(self, pid=None, name=None):
        """
        添加黑名单
        """
        resp_f = 'socialAddBlack'
        if pid:
            rs, data = self.player._game.social_mgr.add_black_pid(self.player, pid)
        else:
            rs, data = self.player._game.social_mgr.add_black_name(self.player, name)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)


    def rc_socialDelBlack(self, pid):
        """
        删除黑名单
        """
        resp_f = 'socialDelBlack'
        rs, data = self.player._game.social_mgr.del_black(self.player, pid)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_dayLuckEnter(self):
        """ 每日抽奖进入 """
        resp_f = 'dayLuckEnter'
        rs, data = self.player._game.day_lucky_mgr.day_luck_enter(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_dayLuckDraw(self, index):
        """ 每日抽奖进行抽奖 """
        log.debug('rc_dayluckDarw == %s' % index)
        resp_f = 'dayLuckDraw'
        rs, data = self.player._game.day_lucky_mgr.day_luck_draw(self.player, index)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_daySignDid(self):
        """是否已签到"""
        resp_f = 'daySignDid'
        data = self.player._game.day_sign_mgr.is_did(self.player)
        return pack_msg(resp_f, 1, data=data)

    def rc_daySign(self):
        """签到"""
        resp_f = 'daySign'
        rs, data = self.player._game.day_sign_mgr.sign(self.player)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)


reg_player_handler(ActivityHandler)
