#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time
import random
from random import shuffle

from game import Game, BaseGameMgr
from corelib import log

from game.store import TN_PLAYER, TN_SOCIAL
from game.store import StoreObj, GameObj
from game.base import common, errcode
from game.base.constant import SOCIAL_RECENTLY_NUM
from game.base.constant import MAIL_REWARD, SOCIAL_MAIL_FRIEND
from game.base.constant import VIP_LV_FRIENDS, VIP_LV_FRIENDS_V
from game.base.msg_define import MSG_SOCIAL_ADD

from game.player.player import PlayerData


TYPE_FRIEND = 1
TYPE_BLACK = 2
TYPE_ONLINE = 3

NUM_PER_PAGE = 15


class SocialMgr(BaseGameMgr):
    """ 社交管理类 """

    def __init__(self, game):
        super(SocialMgr, self).__init__(game)
        self.get_free_num = None

    def init_player(self, player):
        try:
            p_social = player.runtimes.social
        except AttributeError:
            p_social = PlayerSocial(self, player)
            p_social.load(player)
            player.runtimes.social = p_social
        return p_social

    def is_friend(self, player, pid):
        """ 检测是不是好友 """
        p_social = self.init_player(player)
        return p_social.is_friend(pid)

    def is_black(self, player, pid):
        p_social = self.init_player(player)
        return p_social.is_black(pid)

    def get_near_online(self, player):
        rpc_player_mgr = player._game.rpc_player_mgr
        onl_ids = player._game.rpc_scene_mgr.get_online_ids(random_num=NUM_PER_PAGE)
        rl=[]
        for onl_id in onl_ids:
            if onl_id == player.data.id:
                continue
            rpc_player = rpc_player_mgr.get_rpc_player(onl_id)
            try:
                social_info = rpc_player.social_online_info()
                rl.append(social_info)
            except:
                log.info("pid:(%s) is login out", onl_id)
        return True, dict(rl=rl)

    def get_page(self, player, t, page):
        """ 得到某一页的玩家 """
        if TYPE_ONLINE == t:
            return self.get_near_online(player)
        p_social = self.init_player(player)
        rs, data = p_social.get_page(player, t, page)
        if not rs:
            return rs, data
        return True, {'rl':data}

    def add_friend(self, player, pid):
        """ 添加好友 """
        p_social = self.init_player(player)
        return p_social.add_friend(player, pid)

    def del_friend(self, player, pid):
        """ 删除好友 """
        p_social = self.init_player(player)
        return p_social.del_friend(player, pid)

    def _add_black(self, player, querys):
        """
        添加黑名单
        """
        dics = self._game.rpc_store.query_loads(TN_PLAYER, querys=querys)
        if not dics:
            return False, errcode.EC_PLAYER_EMPTY
        dic = dics[0]
        pid = dic['id']
        p_social = self.init_player(player)
        rs, err = p_social.add_black(player, pid)
        if not rs:
            return rs, err
        return True, p_social._node_list(list((pid,)))[0]

    def add_black_name(self, player, name):
        """
        添加黑名单, 名字
        """
        return self._add_black(player, dict(name=name))

    def add_black_pid(self, player, pid):
        """
        添加黑名单, 玩家id
        """
        return self._add_black(player, dict(id=pid))

    def del_black(self, player, pid):
        """ 删除黑名单 """
        p_social = self.init_player(player)
        return p_social.del_black(player, pid)

    def get_max_f_num(self, player):
        try:
            return self.get_free_num(player.data.vip)
        except TypeError:
            sett_str = player._game.setting_mgr.setdefault(VIP_LV_FRIENDS, VIP_LV_FRIENDS_V)
            self.get_free_num = common.make_lv_regions(sett_str)
            return self.get_free_num(player.data.vip)


class SocialData(StoreObj):
    """ 社交玩家的数据 """

    def init(self):
        self.id = None
        self.fds = []                           #朋友的列表
        self.bks = []                           #黑名单列表


class PlayerSocial(GameObj):
    """ 玩家社交 """

    TABLE_NAME = TN_SOCIAL
    DATA_CLS = SocialData

    def __init__(self, mgr, player, adict = None):
        super(PlayerSocial, self).__init__(adict = adict)
        self.player = player
        self._mgr = mgr

    def __getstate__(self):
        return self.data

    def __setstate__(self, data):
        self.data = data

    def uninit(self):
        self.player = None
        self._mgr = None

    def is_friend(self, pid):
        """ 检测是不是朋友 """
        return pid in self.data.fds

    def is_black(self, pid):
        """ 是不是在黑名单中 """
        return pid in self.data.bks

    def load(self, player):
        if not super(PlayerSocial, self).load(player._game.rpc_store, player.data.id):
            self.data.id = player.data.id


    def copy_from(self, player):
        social = getattr(player.runtimes, 'social')
        if social:
            self.data = SocialData()
            self.data.update(social.data.to_dict())
            self.data.id = self.player.data.id

    def _node_list(self, op_l):
        online_pids = self._mgr._game.rpc_player_mgr.get_online_ids(op_l)
        r_l = []
        for pid in op_l:
            t_dict = PlayerData.get_values(pid, ['rid', 'name', 'level'], self._mgr._game.rpc_store)
            if not t_dict:
                continue
            if pid in online_pids:
                t_dict['st'] = 1
            else:
                t_dict['st'] = 0
            r_l.append(t_dict)
        return r_l

    def get_page(self, player, t, page):
        if t == TYPE_FRIEND:
            r_s = self.data.fds
        elif t == TYPE_BLACK:
            r_s = self.data.bks
        else:
            return False, errcode.EC_VALUE
        page = max(page - 1, 0)
        s_num = page * NUM_PER_PAGE
        e_num = s_num + NUM_PER_PAGE
        r_s = self._node_list(r_s[s_num:e_num])
        return True, r_s

    def add_check(self, player, pid):
        if self.is_friend(pid):
            return False, errcode.EC_SOCIAL_FRIEND_IN
        if len(self.data.fds) > self._mgr.get_max_f_num(player):
            return False, errcode.EC_SOCIAL_MAX_ERR
        return True, None

    def add_friend(self, player, pid):
        """ 添加好友 """
        if self.is_black(pid):
            self.data.bks.remove(pid)
        rs, err = self.add_check(player, pid)
        if not rs:
            return rs, err
        rpc_player = self._mgr._game.rpc_player_mgr.get_rpc_player(pid)
        self.data.fds.append(pid)
        player.pub(MSG_SOCIAL_ADD, len(self.data.fds))
        if rpc_player:
            #对方未加我
            if not rpc_player.is_friend(player.data.id):
                rpc_player.force_add_friend(player.data.id)
                rpc_player.apply_friend(player.data.name)
            return True, rpc_player.social_online_info()
        #对方不在线直接操作数据库
        t_d = self._mgr._game.rpc_store.load(self.TABLE_NAME, pid)
        if not t_d:
            log.error("database have no this player pid:%s", pid)
            return False, errcode.EC_PLAYER_EMPTY
        if player.data.id in t_d['fds']:
            #对方也加我了
            return True, self._node_list(list((pid,)))[0]
        t_d['fds'].append(player.data.id)
        #写入数据库中
        self._mgr._game.rpc_store.save(self.TABLE_NAME, t_d)
        fd_mail = Game.res_mgr.reward_mails.get(SOCIAL_MAIL_FRIEND)
        res_role = Game.res_mgr.roles.get(player.data.rid)
        color = '#' + Game.item_mgr.get_color(res_role.quality)
        content = fd_mail.content % dict(name=player.data.name, color=color)
        self._mgr._game.mail_mgr.send_mails(pid, MAIL_REWARD, fd_mail.title,
                SOCIAL_MAIL_FRIEND, [], param=content)
        return True, self._node_list(list((pid,)))[0]

    def del_friend(self, player, pid):
        """ 删除好友 """
        if not self.is_friend(pid):
            return False, errcode.EC_SOCIAL_FRIEND_DEL_ERR
        self.data.fds.remove(pid)
        return True, None

    def add_black(self, player, pid):
        """ 添加黑名单 """
        if self.is_black(pid):
            return False, errcode.EC_SOCIAL_BLACK_IN
        if self.is_friend(pid):
            self.data.fds.remove(pid)
        self.data.bks.append(pid)
        return True, None

    def del_black(self, player, pid):
        """ 删除黑名单 """
        if not self.is_black(pid):
            return False, errcode.EC_SOCIAL_BLACK_DEL_ERR
        self.data.bks.remove(pid)
        return True, None

    def save(self, store, forced = True):
        super(PlayerSocial, self).save(store, forced)

