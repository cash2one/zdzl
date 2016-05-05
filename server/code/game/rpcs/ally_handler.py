#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time

from game.glog.common import ITEM_ADD_ALLYCAT, ITEM_ADD_ALLY_WAR
from corelib import log

from game.base import errcode

from .player_handler import pack_msg, reg_player_handler, BasePlayerRpcHander
from game.glog.common import ITEM_ADD_GLORY_EXCHANGE, ITEM_COST_CRYSTAL,COIN_ALLY_GRAVE, TRAIN_GRAVE
from game.base.constant import (RW_MAIL_AWAR_NPC, RW_MAIL_AWARSKY_END,
                                RW_MAIL_AWARWORLD_END, ALLY_SKY_WAR, MAIL_REWARD)

CRYSTAL_ID = 84

class PlayerAllyHandler(BasePlayerRpcHander):

    TRAM_HEAD = u"我组建了同盟首领战队伍,赶快来战!#38d3ff###"
    WAR_SKY_HEAD = u"向你发出烛龙飞空英雄帖，一起来战吧!#38d3ff###"

    def rc_allyOwn(self):
        """ 获得自己的同盟 """
        resp_f = "allyOwn"
        rs, data = self.player._game.rpc_ally_mgr.player_own(self.player.data.id)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_allyCreate(self, name):
        """ 创建同盟 """
        resp_f = "allyCreate"
        rs, data = self.player.ally_create(name)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_allyCPost(self, ct, inf):
        """ 更改公告 """
        resp_f = "allyCPost"
        rs, data = self.player._game.rpc_ally_mgr.change_post(self.player.data.id, ct, inf)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1)

    def rc_allyApply(self, aid):
        """ 申请加入同盟 """
        resp_f = "allyApply"
        d = self.player.data
        rs, data = self.player._game.rpc_ally_mgr.apply_join(d.id, d.name, d.level, aid)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1)

    def rc_allyApplicants(self):
        """ 获得请者的信息 """
        resp_f = "allyApplicants"
        rs, data = self.player._game.rpc_ally_mgr.applicants(self.player.data.id)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_allyHDApply(self, pid, state):
        """ 处理申请加入同盟 """
        resp_f = "allyHDApply"
        rs, data = self.player._game.rpc_ally_mgr.handle_apply(self.player.data.id, pid, state)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1)

    def rc_allyCDuty(self, pid, duty):
        """ 改变职责 """
        resp_f = "allyCDuty"
        d = self.player.data
        rs, data = self.player._game.rpc_ally_mgr.change_duty(d.id, d.name, pid, duty)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1)

    def rc_allyKick(self, pid):
        """ 踢人 """
        resp_f = "allyKick"
        d = self.player.data
        rs, data = self.player._game.rpc_ally_mgr.kick_out(d.id, d.name, pid)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1)

    def rc_allyQuit(self):
        """ 自己退出同盟 """
        resp_f = "allyQuit"
        rs, data = self.player._game.rpc_ally_mgr.quit(self.player.data.id, self.player.data.name)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1)

    def rc_allyMembers(self):
        """ 获取自己同盟page页成员 """
        resp_f = "allyMembers"
        rs, data = self.player._game.rpc_ally_mgr.members(self.player.data.id)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_allyOtherMembers(self, aid):
        """ 获取他人同盟page页成员 """
        resp_f = "allyOtherMembers"
        rs, data = self.player._game.rpc_ally_mgr.other_members(aid)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_allyAllyList(self, page):
        """ 查看某一页的同盟 """
        resp_f = "allyAllyList"
        rs, data = self.player._game.rpc_ally_mgr.ally_by_page(self.player.data.id, page)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_allyLog(self):
        """ 获取自己同盟的活动日志 """
        resp_f = "allyLog"
        rs, data = self.player._game.rpc_ally_mgr.active_log(self.player.data.id)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_allyDismiss(self):
        """ 解散同盟 """
        resp_f = "allyDismiss"
        rs, data = self.player._game.rpc_ally_mgr.dismiss(self.player.data.id)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1)

    def rc_allySetBossTime(self, t):
        """ 设置同盟BOSS时间 """
        resp_f = 'allySetBossTime'
        log.debug('rc_allySetBossTime---- %s', t)
        rs, data = self.player._game.rpc_ally_mgr.set_boss_time(self.player.data.id, t)
        log.debug('rc_allySetBossTime---- %s', data)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1)

    def rc_allyGetBossTime(self):
        """ 得到同盟的BOSS时间 """
        resp_f = 'allyGetBossTime'
        rs, data = self.player._game.rpc_ally_mgr.get_boss_time(self.player.data.id)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        w = int(time.strftime("%w", time.localtime()))
        return pack_msg(resp_f, 1, data = {'t':data[0], 'isfight':data[1], 'w':w})

    def rc_allyCatEnter(self):
        """ 进入招财 """
        resp_f = 'allyCatEnter'
        p = self.player
        d = p.data
        rs, data = self.player._game.rpc_ally_mgr.cat_enter(d.id, d.vip)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_allyCat(self):
        """ 招财 """
        resp_f = "allyCat"
        d = self.player.data
        rs, data = self.player._game.rpc_ally_mgr.cat(d.id, d.vip)
        if not rs:
            #如果次数已经超过了返回错误
            return pack_msg(resp_f, 0, err = data)
        t_rw = self.player._game.reward_mgr.get(data)
        t_rs_item = t_rw.reward(params=self.player.reward_params())
        bag_items = self.player.bag.add_items(t_rs_item, log_type=ITEM_ADD_ALLYCAT)
        return pack_msg(resp_f, 1, data = bag_items.pack_msg(coin = True))

    def rc_allyGraveEnter(self):
        """ 进入铭刻 """
        resp_f = 'allyGraveEnter'
        d = self.player.data
        rs, data = self.player._game.rpc_ally_mgr.grave_enter(
                d.id, d.vip)
        if not rs:
            return pack_msg(resp_f, 0, err = data)
        return pack_msg(resp_f, 1, data = data)

    def rc_allyGrave(self, type):
        """ 铭刻 """
        resp_f = 'allyGrave'
        d = self.player.data
        rs, data = self.player._game.rpc_ally_mgr.grave_have(d.id, type, d.vip)
        if not rs:
            return pack_msg(resp_f, 0, err = data)

        coin1, coin3, arm = data[0], data[1], data[2]
        if self.player.enough_coin(coin1, coin3, use_bind = True):
            #扣费满足才扣费&&加历练
            self.player._game.rpc_ally_mgr.grave(d.id, type, d.vip)
            self.player.cost_coin_ex(coin1, aCoin3=coin3, log_type = COIN_ALLY_GRAVE)
            self.player.add_train(arm, log_type=TRAIN_GRAVE)
            data = self.player.pack_msg_data(coin=True, train=True)
            return pack_msg(resp_f, 1, data = data)
        return pack_msg(resp_f, 0, err = errcode.EC_COST_ERR)

    def rc_allyTTBoxEnter(self):
        """进入同盟炼妖"""
        resp_f = 'allyTTBoxEnter'
        p_tbox = self.player._game.tbox_mgr.init_player_tbox(self.player)
        data = dict(bids = p_tbox.get_bids())
        return pack_msg(resp_f, 1, data = data)

    def rc_allyTTBoxList(self):
        """同盟炼妖队伍列表"""
        #boss_id, name, level
        resp_f = 'allyTTBoxList'
        pid = self.player.data.id
        aid = self.player._game.rpc_ally_mgr.get_aid_by_pid(pid)
        if not aid:
            pack_msg(resp_f, 0, err = errcode.EC_PLAYER_NO)
        data = self.player._game.rpc_team_mgr.ally_tbox_list(aid)
        return pack_msg(resp_f, 1, data = data)

    def rc_allyTTBoxNew(self, tbid):
        """创建同盟炼妖队伍"""
        resp_f = 'allyTTBoxNew'
        pid = self.player.data.id
        aid = self.player._game.rpc_ally_mgr.get_aid_by_pid(pid)
        if not aid:
            pack_msg(resp_f, 0, err = errcode.EC_PLAYER_NO)
        rs, tid = self.player._game.rpc_team_mgr.ally_tbox_new(pid, tbid, aid)
        if not rs:
            return pack_msg(resp_f, 0, err = tid)
        return pack_msg(resp_f, 1, data = dict(tid = tid))

    def rc_allyTTBoxInvitePub(self, msg):
        """
        组队邀请所有同盟玩家
        """
        from game.mgr.chat import CT_ALLY
        resp_f = 'allyTTBoxInvitePub'
        pid = self.player.data.id
        aid = self.player._game.rpc_ally_mgr.get_aid_by_pid(pid)
        if not aid:
            pack_msg(resp_f, 0, err = errcode.EC_PLAYER_NO)
        msg = PlayerAllyHandler.TRAM_HEAD+msg
        rs, data = self.player._game.chat_mgr.chat_send(self.player, CT_ALLY, msg)
        return pack_msg(resp_f, 1)

    def rc_allyTTBoxAdd(self, tid):
        """加入同盟队伍"""
        resp_f = 'allyTTBoxAdd'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.ally_tbox_add(tid, pid)
        if not rs:
            return pack_msg(resp_f, 0, err = err)
        return pack_msg(resp_f, 1)

    def rc_allyTTBoxMove(self, pos):
        """同盟队伍位置移动"""
        resp_f = 'allyTTBoxMove'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.ally_tbox_move(pid, pos)
        if not rs:
            return pack_msg(resp_f, 0, err = err)
        return pack_msg(resp_f, 1)

    def rc_allyTTBoxDel(self):
        """退出同盟队伍"""
        resp_f = 'allyTTBoxDel'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.ally_tbox_exit(pid)
        if not rs:
            return pack_msg(resp_f, 0, err = err)
        return pack_msg(resp_f, 1)

    def rc_allyTTBoxStart(self):
        """开始同盟炼妖"""
        resp_f = 'allyTTBoxStart'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.ally_tbox_start(pid)
        if not rs:
            return pack_msg(resp_f, 0, err = err)

    def rc_allyTTBoxEnd(self, isOK, fp):
        """同盟炼妖结束"""
        resp_f = 'allyTTBoxEnd'
        pid = self.player.data.id
        rs, err = self.player._game.rpc_team_mgr.ally_box_end(pid, isOK, fp)
        if not rs:
            return pack_msg(resp_f, 0, err = err)

#----------------------狩龙战系统----------------------
    def rc_allyCrystalEnter(self):
        """同盟狩龙捐龙晶进入"""
        resp_f = 'allyCrystalEnter'
        pid = self.player.data.id
        rs, data = self.player._game.rpc_ally_mgr.crystal_enter(pid)
        if rs:
            data['cn'] = self.player.bag.get_item_num_by_iid(CRYSTAL_ID)
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_allyCrystalOffer(self, t=0, n=1):
        """同盟龙晶捐献"""
        resp_f = 'allyCrystalOffer'
        #return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
        bag_num = self.player.bag.get_item_num_by_iid(CRYSTAL_ID)
        if bag_num < n:
            return pack_msg(resp_f, 0, err=errcode.EC_CRYSTAL_NO)
        rs, data = self.player._game.rpc_ally_mgr.crystal_offer(self.player.data.id, t, n)
        if rs:
            num1 = self.player.bag.get_item_num_by_iid(CRYSTAL_ID)
            r_d = self.player.bag.cost_item(CRYSTAL_ID, n, log_type=ITEM_COST_CRYSTAL, pack_msg=True)
            self.player.send_update_msg(r_d[2])
            num2 = self.player.bag.get_item_num_by_iid(CRYSTAL_ID)
            data['cn'] = num2
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_allyGloryExchangeEnter(self):
        """同盟物品兑换进入"""
        resp_f = 'allyGloryExchangeEnter'
        rs, data = self.player._game.rpc_ally_mgr.glory_exchange_enter(self.player.data.id)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_allyGloryExchange(self, iid=0):
        """同盟龙晶物品兑换"""
        resp_f = 'allyGloryExchange'
        pid = self.player.data.id
        #捐献预判断
        rs, rid= self.player._game.rpc_ally_mgr.pre_glory_exchange(pid, iid)
        if not rs:
            return pack_msg(resp_f, 0, err=rid)
        t_rw = self.player._game.reward_mgr.get(rid)
        if t_rw is None:
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
        items = t_rw.reward(params=self.player.reward_params())
        if not self.player.bag.can_add_items(items):
            return pack_msg(resp_f, 0, err=errcode.EC_BAG_FULL)
        rs, data = self.player._game.rpc_ally_mgr.glory_exchange(pid, iid)
        if rs:
            bag_items = self.player.bag.add_items(items, log_type=ITEM_ADD_GLORY_EXCHANGE, rid=rid)
            bag_items.pack_msg(send=1)
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_allyInGloryRank(self):
        """同盟内部声望排名"""
        resp_f = 'allyInGloryRank'
        pid = self.player.data.id
        rs, data = self.player._game.rpc_ally_mgr.in_glory_rank(pid)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_allyAllGloryRank(self, page=1):
        """同盟全部声望排名"""
        resp_f = 'allyAllGloryRank'
        pid = self.player.data.id
        rs, data = self.player._game.rpc_ally_mgr.all_glory_rank(pid, page)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)









    def rc_awarEnterRoom(self, rnum=0):
        """ 进入狩龙战房间 """
        resp_f = 'awarEnterRoom'
        pid = self.player.data.id
        log.debug('rc_awarEnterRoom --pid %s, %s', pid, rnum )
        rs, data = self.player._game.rpc_awar_mgr.enter_room(pid, rnum)
        log.debug('rc_awarEnterRoom -- %s', data)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_awarSkyInvite(self, msg):
        """ 守龙战邀请同盟加入战斗 """
        from game.mgr.chat import CT_ALLY
        resp_f = 'awarSkyInvite'
        pid = self.player.data.id
        log.debug('rc_awarSkyInvite --pid %s, %s', pid, msg)
        aid = self.player._game.rpc_ally_mgr.get_aid_by_pid(pid)
        if not aid:
            pack_msg(resp_f, 0, err = errcode.EC_PLAYER_NO)
        msg = PlayerAllyHandler.WAR_SKY_HEAD+msg
        rs, data = self.player._game.chat_mgr.chat_send(self.player, CT_ALLY, msg)
        return pack_msg(resp_f, 1)

    def rc_awarExitRoom(self):
        """ 退出狩龙战房间 """
        resp_f = 'awarExitRoom'
        pid = self.player.data.id
        log.debug('rc_awarExitRoom --pid %s', pid)
        rs, data = self.player._game.rpc_awar_mgr.exit_room(pid)
        log.debug('rc_awarExitRoom-rs --pid %s', data)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_awarStart(self):
        """ 开战 """
        resp_f = 'awarStart'
        pid = self.player.data.id
        log.debug('rc_awarStart --pid %s', pid)
        rs, data = self.player._game.rpc_awar_mgr.start_war(pid)
        log.debug('rc_awarStart -- %s', data)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_awarMosterStart(self, ancid):
        """ 击杀怪物开始 """
        resp_f = 'awarMosterStart'
        pid = self.player.data.id
        log.debug('rc_awarMosterStart --pid %s', pid)
        rs, data = self.player._game.rpc_awar_mgr.war_monster_start(pid, ancid)
        log.debug('rc_awarMosterStart -- %s', data)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_awarCopyStart(self, ancid):
        """ 击杀影分身开始 """
        resp_f = 'awarCopyStart'
        pid = self.player.data.id
        log.debug('rc_awarCopyStart --pid %s', pid)
        rs, data = self.player._game.rpc_awar_mgr.war_copy_start(pid, ancid)
        if rs is False:
            return pack_msg(resp_f, 0, err=data)
        rpid, pbuff = data
        rs, info = self.player._game.player_mgr.look(rpid)
        if not rs:
            return pack_msg(resp_f, 0, err=info)
        info.update(dict(pbuff=pbuff))
        return pack_msg(resp_f, 1, data=info)

    def rc_awarMosterEnd(self, ancid, isWin, hurts=0):
        """ 击杀怪物结束 """
        resp_f = 'awarMosterEnd'
        pid = self.player.data.id
        log.debug('rc_awarMosterEnd --pid %s, ancid %s, iswin %s', pid, ancid, isWin)
        rs, data = self.player._game.rpc_awar_mgr.war_monster_end(pid, ancid, isWin, hurts)
        log.debug('rc_awarMosterEnd -- %s', data)
        if not rs:
            return pack_msg(resp_f, 0, err=data)
        if data is None:
            return pack_msg(resp_f, 1)
        rs, data = self.reward(data)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)


    def rc_awarBookUse(self, bid):
        """ 天书使用 """
        resp_f = 'awarBookUse'
        pid = self.player.data.id
        log.debug('rc_awarBookUse --pid %s', pid)
        rs, data = self.player._game.rpc_awar_mgr.use_book(pid, bid)
        log.debug('rc_awarBookUse -- %s', data)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_awarBookExchange(self, bid):
        """ 天书兑换 """
        resp_f = 'awarBookExchange'
        pid = self.player.data.id
        log.debug('rc_awarBookExchange --pid %s', pid)
        rs, data = self.player._game.rpc_awar_mgr.exchange_book(pid, bid)
        log.debug('rc_awarBookExchange -- %s', data)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_awarFire(self, index):
        """ 开炮 """
        resp_f = 'awarFire'
        pid = self.player.data.id
        log.debug('rc_awarFire --pid %s', pid)
        rs, data = self.player._game.rpc_awar_mgr.connon_fire(pid, index)
        log.debug('rc_awarFire -- %s', data)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_awarGetBox(self):
        """ 获取宝箱 """
        resp_f = 'awarGetBox'
        pid = self.player.data.id
        log.debug('rc_awarGetBox --pid %s', pid)
        rs, data, war_type = self.player._game.rpc_awar_mgr.get_box(pid)
        log.debug('rc_awarGetBox -- %s', data)
        if rs is False:
            return pack_msg(resp_f, 0, err=data)
        rs, data = self.reward(data, war_type=war_type)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_awarWorldMap(self):
        """ 获取魔龙降世势力地图 """
        resp_f = 'awarWorldMap'
        pid = self.player.data.id
        log.debug('rc_awarWorldMap --pid %s', pid)
        rs, data = self.player._game.rpc_awar_mgr.get_map(pid)
        log.debug('rc_awarWorldMap -- %s', data)
        if rs is False:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_awarWorldChoose(self, node, type):
        """ 队长选择路线 """
        resp_f = 'awarWorldChoose'
        pid = self.player.data.id
        log.debug('rc_awarWorldChoose --pid %s', pid)
        rs, data = self.player._game.rpc_awar_mgr.choose_node(pid, node, type)
        log.debug('rc_awarWorldChoose -- %s', data)
        if rs is False:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def rc_awardownEnter(self):
        """ 断线后再次进入 """
        resp_f = 'awardownEnter'
        pid = self.player.data.id
        log.debug('rc_awardownEnter --pid %s', pid)
        rs, data = self.player._game.rpc_awar_mgr.down_enter(pid)
        log.debug('rc_awardownEnter -- %s', data)
        if rs is False:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)
    
    def rc_awarWorldAssess(self):
        """ 获取评级 """
        resp_f = 'awarWorldAssess'
        pid = self.player.data.id
        log.debug('rc_awarWorldAssess --pid %s', pid)
        rs, data = self.player._game.rpc_awar_mgr.get_assess(pid)
        log.debug('rc_awarWorldAssess -- %s', data)
        if rs is False:
            return pack_msg(resp_f, 0, err=data)
        return pack_msg(resp_f, 1, data=data)

    def reward(self, reward_items, war_type=None):
        """ 发放奖励 """
        log.debug('reward_items - %s',reward_items)
        if not reward_items:
            return False, errcode.EC_VALUE
        if self.player.bag.can_add_items(reward_items):
            bag_item = self.player.bag.add_items(reward_items, log_type=ITEM_ADD_ALLY_WAR)
            return True, bag_item.pack_msg()
            #背包装不下发邮件
        if war_type is None:
            mail_type = RW_MAIL_AWAR_NPC
        elif war_type == ALLY_SKY_WAR:
            mail_type = RW_MAIL_AWARSKY_END
        else:
            mail_type = RW_MAIL_AWARWORLD_END
        res_rw_mail = self.player._game.res_mgr.reward_mails.get(mail_type)
        self.player._game.mail_mgr.send_mails(self.player.data.id, MAIL_REWARD,
            res_rw_mail.title, mail_type, reward_items, param=res_rw_mail.content)
        return False, errcode.EC_ALLY_WAR_FULLBAG


reg_player_handler(PlayerAllyHandler)

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



