#!/usr/bin/env python
# -*- coding:utf-8 -*-

import language

from corelib import log, spawn, sleep
from corelib.message import observable

from game import Game, BaseGameMgr
from game.base.constant import (IKEY_TYPE, IT_ITEM_STR,
    IKEY_ID, DIFF_TITEM_IDS, IT_EQUIP_STR, IT_FATE_STR,
    HORN_TYPE_UNROLE, HORN_TYPE_HFATE, HORN_TYPE_BFBOX,
    HORN_TYPE_EQSTRONG, HORN_TYPE_FISH, HORN_TYPE_AREA,
    HORN_TYPE_PASS, HORN_TYPE_WORLDBOSSHP, HORN_TYPE_MPASS,
    HORN_TYPE_ARMUP, HORN_TYPE_WORLDBOSSFAIL, HORN_TYPE_WORLDNOTICE,
    HORN_TYPE_ALLYBOSSFAIL, HORN_TYPE_ALLYNOTICE, HORN_TYPE_ALLYBOSSHP,
    QUALITY_WHITE, BOSS_ENTER_LEVEL, BOSS_ENTER_LEVEL_V,
    IT_GEM_STR,
    )
from game.base.msg_define import (MSG_WEAPON_UP, MSG_RES_RELOAD,
    MSG_ROLE_INVITE, MSG_HFATE_COIN3, MSG_BF_BESTBOX,
    MSG_EQUIP_UP, MSG_FISH_COIN3, MSG_START, MSG_TBOX_MPASS,
    MSG_TBOX_FPASS, MSG_AREA_RANKFIRST,
)

import app


#解析字符串特殊符号
STRING_INDEX_1 = ':'
STRING_INDEX_2 = '|'

def area_rank(pid, pname, rpid, rname):
    """ 竞技场第一名广播 """
    #log.debug("area--rank--horn %s", pname)
    spawn(Game.rpc_horn_mgr.handle_area_rank, pid, pname, rpid, rname)

@observable
class HornMgr(object):
    """ 大喇叭管理类(活动类的信息发布与监听) """
    _rpc_name_ = 'rpc_horn_mgr'
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        self._game = Game
        self.msgs = []
        self.res_horn = {}
        self.stoped = False

        app.sub(MSG_START, self.start)

    def start(self):
        self._game.res_mgr.sub(MSG_RES_RELOAD, self.load_res)
        self.load_res()
        #竞技场排名第一的广播（跨进程）
        self._game.rpc_arena_mgr.rpc_sub(area_rank, MSG_AREA_RANKFIRST, _proxy=True)

    def load_res(self):
        res_mgr = self._game.res_mgr
        for type, res_horn in res_mgr.hornmsgs.iteritems():
            if not res_horn.cond:
                continue
            if type == HORN_TYPE_ARMUP:
                self.res_horn[type] = self._from_conds(res_horn)
            elif type == HORN_TYPE_UNROLE:
                #conds_dic = {}
                rids = []
                conds = res_horn.cond.split(STRING_INDEX_2)
                for cond in conds:
                    re = cond.split(STRING_INDEX_1)
                    rids = map(int, re[1:])
                    #conds_dic[re[0]] = rids
                self.res_horn[type] = rids
            elif type == HORN_TYPE_EQSTRONG:
                self.res_horn[type] = self._from_conds(res_horn)
            elif type == HORN_TYPE_WORLDBOSSHP:
                self.res_horn[type] = self._from_conds(res_horn)
            elif type == HORN_TYPE_ALLYBOSSHP:
                self.res_horn[type] = self._from_conds(res_horn)

    def _from_conds(self, res_horn):
        """ 解析特殊的条件格式 如  1:2:3 """
        return map(int, res_horn.cond.split(STRING_INDEX_1))

    def handle_area_rank(self, pid, pname, rpid, rname):
        """ 竞技场排名第一 """
        res_horn = Game.res_mgr.hornmsgs.get(HORN_TYPE_AREA)
        if not res_horn:
            return
        pc = self.get_main_role_color(pid)
        rpc = self.get_main_role_color(rpid)
        arg = dict(wname=pname, pcolor=pc, fname=rname, rpcolor=rpc)
        msg = res_horn.msg % arg
        self.send(msg)

    def horn_boss(self, type, pid, pname, mname, rhp=0, aid=0):
        """ boss剩余血量（世界和同盟） """
        res_horn = Game.res_mgr.hornmsgs.get(type)
        if not res_horn:
            return
        if type == HORN_TYPE_WORLDBOSSFAIL or type == HORN_TYPE_ALLYBOSSFAIL:
            #boss失败广播
            arg = dict(mname=mname)
        elif type == HORN_TYPE_WORLDBOSSHP or type == HORN_TYPE_ALLYBOSSHP:
            #boss剩余血量广播
            rhp = '%d%%' % rhp
            pc = self.get_main_role_color(pid)
            arg = dict(pname=pname, pcolor=pc, mname=mname, rhp=rhp)
        elif type == HORN_TYPE_WORLDNOTICE or type == HORN_TYPE_ALLYNOTICE:
            arg = {}
        else:
            #boss第一次和最后一次被击广播
            pc = self.get_main_role_color(pid)
            arg = dict(pname=pname, pcolor=pc, mname=mname)
        #log.debug('arg--------- %s', arg)
        msg = res_horn.msg % arg
        if aid:
            pids = self._game.rpc_ally_mgr.member_pids_by_aid(aid)
            self.send_ally(msg, pids)
        else:
            pids = Game.rpc_player_mgr.get_pids_by_level(self.fetch_boss_uplevel, start_chapter=True)
            if not pids:
                return
            self.send(msg, pids)

    def get_conds(self, type):
        """ 获取广播条件 """
        return self.res_horn.get(type)

    def send(self, msgs, pids=None):
        """ 大喇叭广播数据 """
        self._game.chat_mgr.bugle(msgs, pids)

    def send_ally(self, msgs, pids):
        """ 同盟聊天的广播 """
        self._game.chat_mgr.ally_send(msgs, pids)

    def set_stop(self):
        """ 停止广播 """
        self.stoped = True

    def manage_send(self, msgs, times, interval):
        """ 后台广播大喇叭 """
        self.stoped = False
        spawn(self.manage_loop, msgs, times, interval)

    def manage_loop(self, msgs, times, interval):
        while not self.stoped:
            #log.debug('manage_loop :%s %s', times, interval)
            if times <= 0:
                break
            times -= 1
            self.send(msgs)
            sleep(interval)
    
    def get_main_role_color(self, pid):
        """ 获取主将的颜色 """
        online, player_infos = Game.rpc_player_mgr.get_player_infos([pid])
        if not player_infos.has_key(pid):
            return '#' + Game.item_mgr.get_color(QUALITY_WHITE)
        player_info = player_infos[pid]
        main_rid = player_info[1]
        res_role = Game.res_mgr.roles.get(main_rid)
        return '#' + Game.item_mgr.get_color(res_role.quality)

    @property
    def fetch_boss_uplevel(self):
        """ 获取boss解锁等级 """
        return Game.setting_mgr.setdefault(BOSS_ENTER_LEVEL, BOSS_ENTER_LEVEL_V)

class PlayHornMgr(object):
    """ 玩家大喇叭管理类 """
    def __init__(self, player):
        self.player = player

    def uninit(self):
        self.player = None

    def load(self):
        #武器升级
        self.player.sub(MSG_WEAPON_UP, self._handle_arm_up)
        #招募配奖
        self.player.sub(MSG_ROLE_INVITE, self._handle_role_invite)
        #观星获得绑元宝
        self.player.sub(MSG_HFATE_COIN3, self._handle_hfate_coin2)
        #兵符任务宝箱开出极品装备广播
        self.player.sub(MSG_BF_BESTBOX, self._handle_bf_bestbox)
        #装备强化升级
        self.player.sub(MSG_EQUIP_UP, self._handle_eq_up)
        #钓鱼获得绑元宝
        self.player.sub(MSG_FISH_COIN3, self._handle_fish_coin2)
        #时光盒第一次五星通关
        self.player.sub(MSG_TBOX_MPASS, self._handle_tbox_mpass)
        #时光盒第一次通关
        self.player.sub(MSG_TBOX_FPASS, self._handle_tbox_pass)


    def _handle_arm_up(self, level, arm_id, player, rid):
        """ 处理武器升级 """
        game = self.player._game
        cond = game.rpc_horn_mgr.get_conds(HORN_TYPE_ARMUP)
        if not level in cond:
            return
        res_horn = game.res_mgr.hornmsgs.get(HORN_TYPE_ARMUP)
        res_arm = game.res_mgr.arms.get(arm_id)
        res_role = game.res_mgr.roles.get(rid)
        if res_role.is_main:
            rname = language.HORN_MAIN_ROLE
        else:
            rname = res_role.name
        pc = self.get_player_color(player)
        rc = '#' + game.item_mgr.get_color(res_role.quality)
        ac = '#' + game.item_mgr.get_color(res_arm.quality)
        arg = dict(name=self.player.data.name, pcolor=pc, rname=rname,
            rcolor=rc, arm=res_arm.name,
            acolor=ac, armLv=level)
        msg = res_horn.msg % arg
        game.rpc_horn_mgr.send(msg)

    def _handle_role_invite(self, rid, player):
        """ 招募配奖 """
        cond = player._game.rpc_horn_mgr.get_conds(HORN_TYPE_UNROLE)
        if not rid in cond:
            return
        res_role = player._game.res_mgr.roles.get(rid)
        pc = self.get_player_color(player)
        ac = '#' + player._game.item_mgr.get_color(res_role.quality)
        arg = dict(name=player.data.name, pcolor=pc, rname=res_role.name, rcolor=ac)
        res_horn = player._game.res_mgr.hornmsgs.get(HORN_TYPE_UNROLE)
        msg = res_horn.msg % arg
        player._game.rpc_horn_mgr.send(msg)

    def _handle_hfate_coin2(self, num):
        """ 观星获得绑元宝 """
        self._handle_coin2(num, HORN_TYPE_HFATE)

    def _handle_fish_coin2(self, num):
        """ 钓鱼获得绑元宝 """
        self._handle_coin2(num, HORN_TYPE_FISH)

    def _handle_coin2(self, num, type):
        """ 观星获得绑元宝 """
        pc = self.get_player_color(self.player)
        arg = dict(name=self.player.data.name, pcolor=pc, num=num)
        res_horn = self.player._game.res_mgr.hornmsgs.get(type)
        msg = res_horn.msg % arg
        self.player._game.rpc_horn_mgr.send(msg)

    def _handle_bf_bestbox(self, rs_items):
        """ 兵符任务宝箱开启获得极品装备广播 """
        for rs_item in rs_items:
            if rs_item[IKEY_TYPE] == IT_ITEM_STR and \
                rs_item[IKEY_ID] in DIFF_TITEM_IDS:
                continue
            game = self.player._game
            res_horn = game.res_mgr.hornmsgs.get(HORN_TYPE_BFBOX)
            iid = rs_item[IKEY_ID]
            type = ''
            log.debug('errr------------ %s', rs_item)
            item_type = rs_item[IKEY_TYPE]
            if item_type == IT_EQUIP_STR:
                res_eq = game.res_mgr.equips.get(iid)
                res = game.res_mgr.equip_sets.get(res_eq.sid)
                name = res_eq.name
            elif item_type == IT_FATE_STR:
                type = language.HORN_BFBOX_FATE
                res = game.res_mgr.fates.get(iid)
                name = res.name
            elif item_type == IT_GEM_STR:
                res = game.res_mgr.gem.get(iid)
                name = res.name
            else:
                res = game.res_mgr.items.get(iid)
                name = res.name
            color = '#' + game.item_mgr.get_color(res.quality)
            pc = self.get_player_color(self.player)
            arg = dict(name=self.player.data.name, pcolor=pc, iname=name, color=color)
            part_msg = res_horn.msg % arg
            msg = "%s%s" % (part_msg, type)
            game.rpc_horn_mgr.send(msg)

    def _handle_eq_up(self, eid, level):
        """ 装备升级 """
        game = self.player._game
        cond = game.rpc_horn_mgr.get_conds(HORN_TYPE_EQSTRONG)
        if not level in cond:
            return
        res_horn = game.res_mgr.hornmsgs.get(HORN_TYPE_EQSTRONG)
        if not res_horn:
            return
        res_eq = game.res_mgr.equips.get(eid)
        res_eq_set = game.res_mgr.equip_sets.get(res_eq.sid)
        ec = '#' + game.item_mgr.get_color(res_eq_set.quality)
        pc = self.get_player_color(self.player)
        arg = dict(name=self.player.data.name, pcolor=pc, ename=res_eq.name,
            ecolor=ec, eLv=level)
        msg = res_horn.msg % arg
        game.rpc_horn_mgr.send(msg)

    def _handle_tbox_mpass(self, chapter_id):
        """ 时光盒第一次五星通关广播 """
        self._handle_tbox(chapter_id, HORN_TYPE_MPASS)
    
    def _handle_tbox_pass(self, chapter_id):
        """ 时光盒第一次通关 """
        self._handle_tbox(chapter_id, HORN_TYPE_PASS)
    
    def _handle_tbox(self, chapter_id, type):
        """ 处理时光盒广播 """
        game = self.player._game
        res_chapter = game.res_mgr.chapters.get(chapter_id)
        if not res_chapter:
            return
        res_map = game.res_mgr.maps.get(res_chapter.mid)
        if not res_map:
            return
        res_horn = game.res_mgr.hornmsgs.get(type)
        if not res_horn:
            return
        pc = self.get_player_color(self.player)
        arg = dict(name=self.player.data.name, pcolor=pc, cname=res_map.name)
        msg = res_horn.msg % arg
        game.rpc_horn_mgr.send(msg)

    def get_player_color(self, player):
        game = player._game
        main_rid = player.data.rid
        res_role = game.res_mgr.roles.get(main_rid)
        return '#' + game.item_mgr.get_color(res_role.quality)

def new_horn_mgr():
    return HornMgr()



