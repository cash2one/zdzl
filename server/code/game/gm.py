#!/usr/bin/env python
# -*- coding:utf-8 -*-
"""
game master 游戏管理功能
"""
from random import shuffle
from traceback import format_exc

from datetime import datetime
import time
from contextlib import contextmanager

from corelib import sleep, log
from game.store import TN_P_TBOX, TN_P_DAYLUCKY
from game import Game, BaseGameMgr
from game.player.player import Player, PlayerData, PlayerAttr
from game.glog.common import ITEM_ADD_GM, COIN_ADD_GM, TRAIN_GM
from game.base.constant import (
    TUL_LEVEL, PLAYER_ATTR_FETE, PLAYER_ATTR_HITFATE, PLAYER_ATTR_BFTASK,
    PLAYER_ATTR_BOSS, REPORT_TYPE_ARENA
    )
from game.base import msg_define

from game.store.define import  FN_PLAYER_LEVEL, TN_P_ATTR, FN_ID, TN_P_TASK
from game.store import FOP_GTE

from corelib.client_rpc import (AbsExport, JsonClientRpc as ClientRpc,
                                )
pack_msg = ClientRpc.pack_msg


PRE_GM = 'gm_'

def player_info(player):
    """ 角色信息 """
    data = player.data
    return u'玩家:id=%d, name=%s, level=%s' % (data.id, data.name, data.level)

class GMPlayer(object):
    """ 对玩家的gm命令类 """
    def __init__(self, gm, player):
        self.player = player
        self.gm = gm
        self._raw_return = 0
        if 0:
            from game.player.player import Player
            self.player = Player()
            self.gm = GameMaster()

    @contextmanager
    def raw_return_context(self):
        self._raw_return = 1
        try:
            yield
        finally:
            self._raw_return = 0


    def info(self):
        self.gm.log(player_info(self.player))
        self.gm.log('*' * 10)

    def clear_player(self, all=True, dels=tuple()):
        self.player.clear(all=all, dels=dels)
        self.gm.log(u'清理玩家数据成功')

    def clear_bag(self):
        self.player.bag.clear()
        self.gm.log(u'清除玩家背包')

    def clear_ally_tbox_team(self):
        """重置同盟组队炼妖"""
        data = dict(bids = [], t = 0, cr=0)
        self.player.set_ally_tbox_data(data)
        self.gm.log(u'重置同盟组队炼妖')

    def copy(self, pid):
        """ 完全复制玩家数据 """
        if self.player.copy_player(pid):
            self.gm.log(u'拷贝成功')
        else:
            self.gm.log(u'拷贝失败')

    def clear_part_data(self, *args):
        """ 部分指定删除 """
        self.player.clear(all=False, dels=args[0])
        self.gm.log(u'清理玩家部分数据成功')

    def add_money(self, coin1, coin2=0, coin3=0, is_set=False, vip=False):
         """ 增加金钱(coin1, coin2=0, coin3=0) """
         data = self.player.data
         self.player.add_coin(aCoin1=coin1, aCoin2=coin2, aCoin3=coin3,
                 is_set=is_set, vip=vip, log_type=COIN_ADD_GM)
         self.gm.log(u'增加银币成功，角色当前(银币,元宝,绑元宝)数：(%s, %s, %s)',
                 data.coin1, data.coin2, data.coin3)
         self.player.pack_msg_data(coin=1, send=1)

    def tbox_change_data(self, chapter, tbids):
        """ 修改时光盒数据 """
        log.debug('chpteer--%s %s',chapter, tbids)
        chapter_id = chapter + 1
        self.player._game.tbox_mgr.init_player_tbox(self.player)
        oPTbox = getattr(self.player.runtimes, TN_P_TBOX)
        rs = oPTbox.gm_change_data(chapter_id, tbids)
        if not rs:
            self.gm.log(u'数据填入错误')
            return
        self.gm.log(u'时光盒数据更改成功')

    def add_exp(self, exp):
        """ 增加经验 """
        self.player.add_exp(exp)
        self.gm.log(u'增加经验成功:lv=%s, exp=%s', self.player.data.level, self.player.data.exp)
        self.player.pack_msg_data(exp=1, send=1)

    def add_train(self, train):
        """ 增加练历 """
        self.player.add_train(train, log_type=TRAIN_GM)
        self.gm.log(u'增加练历成功:%s', self.player.data.train)
        self.player.pack_msg_data(train=1, send=1)

    def add_re(self, num, chapter=0):
        """ 刷新次数 1:时光盒，"""
        self.player._game.tbox_mgr.init_player_tbox(self.player)
        oPTbox = getattr(self.player.runtimes, TN_P_TBOX)
        chapter += 1
        for o in oPTbox.p_tboxs.itervalues():
            if chapter == 1:
                o.data.re1 = num
                o.data.re2 = num
                o.modify()
            if chapter == o.data.chapter:
                o.data.re1 = num
                o.data.re2 = num
                o.modify()
        self.gm.log(u'时光盒刷新次数更新完成')

    def awar_kill_monster(self):
        """ 狩龙战 批量杀死地图上的所有npc """
        rs, data = self.player._game.rpc_awar_mgr.gm_kill_monsters(self.player.data.id)
        if rs:
            self.gm.log(u'成功杀完该地图上的npc')
        else:
            self.gm.log(u'秒杀失败，请检查是否进入战场')

    def rest_daylucky(self, mnum, lucky_role=True):
        """ 改变抽奖次数上线并重置抽奖 """
        self.player._game.day_lucky_mgr.init_player_dayluck(self.player)
        player_daylucky = getattr(self.player.runtimes, TN_P_DAYLUCKY)
        player_daylucky.day_lucky.data.d['mdraw'] = mnum - 1
        player_daylucky.day_lucky.data.d['ctime'] = int(time.time()) - 86400
        if lucky_role:
            player_daylucky.day_lucky.data.d['rids'] = []
        player_daylucky.enter()
        self.gm.log(u'抽奖修改成功！')

    def add_bf_boxes(self, num):
        """ 添加兵符任务 剩余箱子数目 """
        self.player._game.bftask_mgr.init_player_bftask(self.player)
        player_bftask = getattr(self.player.runtimes, PLAYER_ATTR_BFTASK)
        max_boxes = self.player._game.bftask_mgr.bf_boxes(self.player.data.vip)
        if num > max_boxes: num = max_boxes
        player_bftask.bfTaskData.bs = num
        self.gm.log(u'兵符任务剩余宝箱数目')

    def add_fete_num(self, num, type=1):
        """ 祭天次数增加 """
        self.player._game.fete_mgr.init_player_fete(self.player)
        player_fete = getattr(self.player.runtimes, PLAYER_ATTR_FETE)
        if type==1:
            player_fete.feteData.n1 = 10-1 * num
        else:
            player_fete.feteData.n2 = 10-1 * num
        self.gm.log(u'祭天次数更新完成')

    def add_fate_num(self, num, type=1):
        """ 猎命次数增加 """
        self.player._game.hfate_mgr.init_player_hitfate(self.player)
        player_hfate = getattr(self.player.runtimes, PLAYER_ATTR_HITFATE)
        if type==1:
            if num >50:num = 50
            player_hfate.hitFateData.n1 = 50-num
        else:
            if num >20:num = 20
            player_hfate.hitFateData.n2 = 20-num
        self.gm.log(u'猎命次数更新完成')

    def del_tbox_news(self):
        """ 清除时光盒所有战报 """
        self.player._game.rpc_tboxnews_mgr.clear()
        self.gm.log(u'清楚时光盒所有战报')

    def del_deep(self):
        """ 清除深渊 """
        self.player._game.deep_mgr.clear(self.player)
        self.gm.log(u'清除深渊数据')

    def deep_jump(self, level):
        """ 直接调整到深渊指定层 """
        from game.mgr.deep import ET_NORMAL
        self.player._game.deep_mgr.enter(self.player, ET_NORMAL, level=int(level))
        self.gm.log(u'跳转成功')

    def deep_buff(self, count):
        """ 增加多少层buff """
        deep = self.player._game.deep_mgr.init_player(self.player)
        deep.add_buff(self.player._game.deep_mgr, floors=count)
        self.gm.log(u'增加buff成功')

    def set_player_attr(self, key, value):
        """ 设置用户属性:cli_introstep """
        self.player.play_attr.client_set(key, value)
        self.gm.log(u'设置用户属性成功')

    def add_wait_item(self, wtype, items):
        """ 添加待收物品(wtype, items) items=列表对象 """
        witem = self.player.wait_bag.add_waitItem(wtype, items)
        self.gm.log(u'add_wait_item:%s', witem.to_dict())

    def add_fate(self, fid, level=1, can_trade=False):
        """添加命格 """
        item_mgr = self.player._game.item_mgr
        fate = item_mgr.new_fate(fid, is_trade=can_trade)
        fate.data.level = level
        res_fate_level =  self.player._game.res_mgr.fate_level_by_keys.get((fid, level))
        if res_fate_level:
            fate.data.exp = res_fate_level.exp
        if self.player.bag.add_fate(fate) is None:
            self.gm.log(u'命格(%d)添加失败', fid)
        else:
            self.gm.log(u'命格(%d)添加成功', fid)
        self.player.pack_msg_data(fates=[fate], send=1)
        return fate

    def roleup_add_num(self, num):
        """ 添加升段次数 """
        self.player.roles.gm_add_num(num)
        self.gm.log(u'升段次数更改成功')

    def reset_gem_mine(self):
        """重置珠宝开采"""
        self.player._game.gem_mgr.reset_mine(self.player)
        self.gm.log(u'重置珠宝开采成功')

    def add_gem(self, gid, level=1, is_trade=0):
        """添加珠宝"""
        item_mgr = self.player._game.item_mgr
        gem = item_mgr.new_gem(gid, level, is_trade=is_trade)
        if gem is None:
            self.gm.log(u'等级(%s)珠宝(%d)添加失败', level, gid)
        if self.player.bag.add_gem(gem) is None:
            self.gm.log(u'等级(%s)珠宝(%d)添加失败', level, gid)
        self.gm.log(u'添加等级(%s)珠宝(%d)成功', level, gid)
        return gem

    def add_equip(self, eid, level=1, can_trade=False, forced=1):
        """ 添加命格 """
        item_mgr = self.player._game.item_mgr
        equip = item_mgr.new_equip(eid, is_trade=can_trade)
        equip.data.level = level
        rs_equip = self.player.bag.add_equip(equip, forced)
        if rs_equip is None:
            self.gm.log(u'装备(%d)添加失败，背包已满', eid)
        else:
            self.gm.log(u'装备(%d)添加成功', eid)
        self.player.pack_msg_data(equips=[rs_equip], send=1)
        return equip

    def wear_equip(self, rid, eid, is_base=1, send=1):
        """ 穿戴装备(rid, id) """
        equip = None
        if is_base:
            equips = self.player.bag.get_equips_by_eid(eid)
            #no used
            for e in equips:
                if not e.data.used:
                    equip = e
                    break
        else:
            equip = self.player.bag.get_equip(eid)
        role = self.player.roles.get_role_by_rid(rid)
        if not (equip and role):
            self.gm.log(u'装备(%d, %d)穿戴失败', rid, eid)
            return
        equip, res_equip = self.player.bag.get_equip_ex(equip.data.id)
        rs, data = role.wear_equip(self.player, equip, res_equip)
        if not rs:
            self.gm.log(u'装备(%d, %d)穿戴失败', rid, eid)
        else:
            if send:
                _, msg = data
                self.player.send_msg(msg)
            self.gm.log(u'装备(%d, %d)穿戴成功', rid, eid)

    def add_item(self, aIid, aCount, can_trade=False):
        """添加物品 id_count = {id:count}"""
        rs, c = self.player.bag.can_add_item(aIid, aCount, can_trade=can_trade)
        if not rs:
            self.gm.log(u'物品(%d, %d)添加失败', aIid, aCount)
            return
        res_item = self.player._game.item_mgr.get_res_item(aIid)
        items = self.player.bag.add_item(aIid, aCount, can_trade=can_trade)
        self.player.pack_msg_data(items=items, send=1)
        self.gm.log(u'物品(%s, %d)添加成功', res_item.name, aCount)

    def vip_level(self, level):
        """ 改变vip等级 """
        self.player.vip.vip = level
        self.gm.log(u'vip等级改变到(%d)', level)

    def vip_reward(self, rid):
        """设置gm命令的vip奖励"""
        t_dics = self.player._game.rpc_vip_mgr.get_goods()
        keys = [dic['rid'] for dic in t_dics]
        rid = int(rid)
        if rid not in keys:
            keys.sort()
            self.gm.log(u'设置失败, 目前的vip奖励ID可以是(%s)', keys)
            return
        coin = self.player._game.rpc_vip_mgr.get_good_coin(rid)
        self.player.pay_back(rid, None, coin)
        self.gm.log(u'vip奖励购买成功奖励ID是(%d)', rid)

    def use_item(self, id):
        """ 使用物品 """
        rs, data = self.player.use_item(id)
        if not rs:
            self.gm.log(u'使用物品失败:%s', data)
            return
        self.player.send_update_msg(data)
        self.gm.log(u'使用物品成功:%s', data)

    def use_item_ex(self, iid):
        """ 使用特定物品 """
        ids, res_item = self.player.bag.get_item_ids_ex(iid)
        if ids is None:
            self.gm.log(u'物品不存在')
            return
        rs, data = self.player.use_item(ids[0])
        if not rs:
            self.gm.log(u'使用物品失败:%s', data)
            return
        self.player.send_update_msg(data)
        self.gm.log(u'使用物品成功:%s', data)

    def show_bag(self):
        """ 显示背包物品列表 """
        log = self.gm.log
        log(u'玩家(%s)背包物品列表:', self.player.data.name)
        def _logs(items, name):
            for k, item in items.iteritems():
                log(u'  id:%s  %s:%s', k, name, item.to_dict())
        _logs(self.player.bag.items, u'物品')
        _logs(self.player.bag.equips, u'装备')
        _logs(self.player.bag.fates, u'命格')
        _logs(self.player.bag.cars, u'坐骑')

    def show_wait_bag(self):
        """ 显示待收取物品列表 """
        log = self.gm.log
        log(u'玩家(%s)待收取物品列表:', self.player.data.name)
        for k, witem in self.player.wait_bag.items.iteritems():
            log(u'  id:%d  %s', k, witem.to_dict())

    def update_bag(self, type_name, id, **kw):
        """ 更新背包数据(type_name[items,equips,fates,cars], id, **kw) """
        items = getattr(self.player.bag, type_name)
        item = items.get(id)
        item.update(kw)
        self.gm.log(u'背包数据(%s)更新成功: %s', id, item.to_dict())

    def add_arena_count(self, c):
        """增加竞技场次数"""
        pid = self.player.data.id
        self.player._game.rpc_arena_mgr.gm_add_count(pid = pid, c = c)
        self.gm.log(u'玩家(%s)增加竞技场(%s)挑战次数', pid, c)

    def change_arena_rank(self, rank):
        """ 改变改玩家在竞技场的排名 """
        pid = self.player.data.id
        vip = self.player.data.vip
        game = self.player._game
        rid = game.rpc_arena_mgr.gm_get_rid_byrank(rank)
        if not rid:
            self.gm.log(u'调整失败！等级超出')
            return
        #保存战报
        fp = '0'
        fp_id = game.rpc_report_mgr.save(REPORT_TYPE_ARENA,
            [rid, pid], fp)
        self.player._game.rpc_arena_mgr.gm_change_rank(pid, rid, fp_id, vip)
        rplayer = game.rpc_player_mgr.get_rpc_player(pid)
        if rplayer:
            r_resp = 'arenaRivalEnd'
            r_data = dict(rid = pid, isOK = 1, fp_id = fp_id)
            msg = pack_msg(r_resp, 1, data = r_data)
            rplayer.send_msg(msg)
        self.gm.log(u'调整成功！')

    def add_role(self, rid, active=True):
        """ 添加配将(rid, active=True) """
        role, err = self.player.roles.invite(rid, gm=True)
        if not role:
            self.gm.log(u'增加配将(%s)失败:%s', rid, err)
            return
        if active and self.player.roles.can_come_back():
            role.come_back()
        self.gm.log(u'增加配将(%s)成功:%s', rid, role.to_dict())

    def show_roles(self):
        """ 显示配将信息 """
        sleep(3)
        log = self.gm.log
        log(u'玩家(%s)配将列表:', self.player.data.name)
        for k, role in self.player.roles.roles.iteritems():
            log(u'  id:%s  %s', k, role.to_dict())

    def show_play_data(self):
        """ 显示角色信息 """
        log = self.gm.log
        log(u'玩家(%s)信息:', self.player.data)

    def update_role(self, id, **kw):
        """ 更新配将数据(id, **kw) """
        role = self.player.roles.get_role(id)
        role.update(kw)
        self.gm.log(u'配将(%s)数据更新成功: %s', id, role.to_dict())

    def del_player(self, pid):
        """ 通过修发player表中的uid隐藏角色 """
        self.player.data.uid = -self.player.data.uid
        self.gm.log(u'删除角色成功')

    def del_role(self, rid):
        """ 删除玩家角色 """
        rs, data = self.player.roles.del_role(rid, send_msg=1)
        if not rs:
            self.gm.log(u'删除配将失败')
        else:
            self.gm.log(u'删除配将成功')

    def get_role(self, rid):
        return self.player.roles.get_role_by_rid(rid)

    def role_come_back(self, id):
        """ 配将归队(id) """
        role = self.player.roles.get_role(id)
        role.come_back()
        self.gm.log(u'增加配将(%s)归队成功!', id)

    def position_study(self, pid):
        """ 学习阵型 """
        if self.player.positions.study(pid, forced=True):
            self.gm.log(u'学习阵型成功')

    def get_position(self, pid):
        return self.player.positions.get_active()

    def position_upgrade(self, id, level=None):
        """ 升级阵型(level=None)可以通过level指定直接升级到特定等级 """
        if self.player.positions.upgrade(id, level=level, forced=True):
            self.gm.log(u'升级阵型成功')

    def position_place(self, pid, rid, pos):
        """ 布置某角色到某阵型位置 """
        self.player.positions.place(pid, rid, pos)

    def scene_enter(self, mapId):
        """ 进入地图 """
        if self.player.scene_enter(mapId):
            self.gm.log(u'进入地图成功')

    def upgrade(self, level, pub=True):
        """ 升级到某级 """
        self.player.upgrade(level, pub=pub)

    def accept_tasks(self, utype=None, id_or_level=None):
        if utype is None:
            utype = TUL_LEVEL
            id_or_level = self.player.data.level
        self.player.task.accept_tasks(utype, id_or_level)

    def task_clear_ids(self, ids):
        ids = [int(item) for item in str(ids).split(',')]
        self.player.task.clear_tids(ids)
        self.gm.log(u'清理已完成任务列表成功')

    def task_complete(self, tid):
        task = self.player.task.get_task_by_tid(tid)
        if task:
            self.player.task.task_complete(task.data.id)
            self.gm.log(u'完成任务成功')

    def add_task(self, tid):
        task = self.player.task.add_task(tid, forced=True, send_msg=True)
        self.gm.log(u'添加任务成功:%s', task.to_dict())

    def turn_task(self, tid, auto=1):
        """ 转到特定任务
        如果tid比当前完成的任务id小,会清理已完成任务列表内容
        auto: 是否自动完成tid之前的所有任务id?
        """
        self.player.task.turn_to(tid, auto_complete=auto)

    def show_tasks(self):
        """ 显示玩家任务信息 """
        log = self.gm.log
        log(u'玩家(%s)任务列表:', self.player.data.name)
        for id, task in self.player.task.tids.iteritems():
            log(u'  id:%d  %s', id, task.to_dict())

    def reward(self, rid):
        """ 直接获取奖励(rid) """
        r = self.player._game.reward_mgr.get(rid)
        if not r:
            self.gm.log(u'获取奖励(%d)失败', rid)
            return
        sitems = r.reward(params=self.player.reward_params())
        bag_items = self.player.bag.add_items(sitems, log_type=ITEM_ADD_GM)
        bag_items.pack_msg(send=1)
        self.gm.log(u'获取奖励列表:%s', sitems)

    def kick(self):
        """ 踢下线 """
        self.player.user.logout()
        self.gm.log(u'踢下线成功')

    def attr_set(self, key, value):
        self.player.play_attr.set(key, value)

    def attr_get(self, key):
        value = self.player.play_attr.get(key)
        self.gm.log(u'%s', value)

    def add_car(self, cid):
        """ 添加坐骑 """
        self.player.bag.add_car(cid)
        self.gm.log(u'添加坐骑成功')

    def car_do(self, cid):
        """ 操作坐骑,骑或下马 """
        if cid is 0:
            self.player.car_do(cid)
            self.gm.log(u'操作坐骑成功')
        else:
            car = self.player.bag.has_car(cid)
            if car:
                self.player.car_do(car.data.id)
                self.gm.log(u'操作坐骑成功')
            else:
                self.gm.log(u'操作坐骑失败')

    def set_allyboss_start(self, delay_time=300):
        """ 开启同盟boss战，并清楚玩家该星期已参加boss战时间的属性 """
        game = self.player._game
        aid = game.rpc_ally_mgr.get_aid_by_pid(self.player.data.id)
        if not aid:
            self.gm.log(u'该玩家无同盟')
            return
        if game.rpc_boss_mgr.set_ally_start(aid, delay_time):
            self.gm.log(u'同盟boss战开启成功')
        else:
            self.gm.log(u'同盟boss开启失败')

    def fihgt_allyboss_clear(self):
        """ 清楚该周已参加同盟boss的状态 """
        tObjDict = self.player.play_attr.get(PLAYER_ATTR_BOSS)
        tObjDict['jt'] = 0
        self.player.play_attr.update_attr({PLAYER_ATTR_BOSS:tObjDict})
        self.gm.log(u'成功更新状态')

    def kill_boss(self, type=0):
        """ 秒杀boss type=0 世界 type!=0 同盟 """
        game = self.player._game
        p_data = self.player.data
        hurts = 999999999
        if type:
            aid = game.rpc_ally_mgr.get_aid_by_pid(p_data.id)
            if not aid:
                self.gm.log(u'该玩家无同盟')
                return
            game.rpc_boss_mgr.kill_boss(p_data.id, p_data.name, hurts, aid)
        else:
            game.rpc_boss_mgr.kill_boss(p_data.id, p_data.name, hurts)
        self.gm.log(u'成功秒杀')

    def one_hurt_boss(self, num):
        """ 单次击杀世界boss """
        game = self.player._game
        p_data = self.player.data
        game.rpc_boss_mgr.kill_boss(p_data.id, p_data.name, num)
        self.gm.log(u'成功击杀怪物 %d 血', num)

    def reset_shop(self):
        """ 刷新神秘商店的物品 """
        player_shop = self.player._game.shop_mgr.init_player_shop(self.player)
        player_shop.gm_reset_items()
        self.gm.log(u'成功重置')

    def next_sign(self):
        p_sign = self.player._game.day_sign_mgr.init_player(self.player)
        p_sign.data.t = 0
        p_sign.save(self.player._game.rpc_store, forced=True)
        self.gm.log(u'成功重置')

    def set_sign_day(self, day):
        p_sign = self.player._game.day_sign_mgr.init_player(self.player)
        p_sign.data.t = 0
        p_sign.data.finish = min(15, int(day))
        p_sign.save(self.player._game.rpc_store, forced=True)
        if int(day) > 15:
            return self.gm.log(u'成功重置, 设置的天数大于15 被设置为15')
        self.gm.log(u'成功重置')

    def bftask_clear(self):
        """ 清楚玩家身上已接的兵符任务 """
        tasks = self.player.task.tasks
        for task in tasks.values():
            tid = task.data.tid
            res_task = self.player._game.res_mgr.tasks.get(tid)
            if res_task is None or res_task.type != 3:
                continue
            self.player.task.del_task(task)
        p_bftask = self.player._game.bftask_mgr.init_player_bftask(self.player)
        p_bftask.bfTaskData.tids = []
        p_bftask.bfTaskData.ss = []
        p_bftask.bfTaskData.qs = []
        p_bftask.bfTaskData.exps = []
        p_bftask.bfTaskData.btid = 0
        self.gm.log(u"清楚成功")

SECTION = 100
class GameMaster(object):
    def __init__(self, player):
        self.globals = {}
        self.locals = {}
        self.player = player
        self.init()

    def init(self):
        self.logs = []
        for name in dir(self):
            if name.startswith(PRE_GM):
                self.globals[name[len(PRE_GM):]] = getattr(self, name)
        self.globals['my'] = GMPlayer(self, self.player)

    def uninit(self):
        self.globals = None
        self.locals = None
        self.player = None
        if 0:
            from game.player.player import Player
            self.player = Player()

    def sandbox_check(self, cmd):
##        if '._' in cmd:
##            return False
##        if 'getattr' in cmd or 'setattr' in cmd:
##            return False
##        if 'import' in cmd:
##            return False
##        if 'eval' in cmd or 'exec ' in cmd:
##            return False
        return True

    def execute(self, cmd, log_except=False, log_gm=True):
        """ 执行gm命令
        正常执行，返回成功执行的信息，
        执行失败或错误，抛出异常
        """
        try:
            self.logs = []
            cmd = cmd.replace('\r', '\n')
            if log_gm:
                self.player.log_gm(cmd)
            if self.sandbox_check(cmd):
                exec cmd in self.globals, self.locals
            else:
                return u'gm命令非法'
            return u'\n'.join(self.logs)
        except Exception as err:
            if log_except:
                log.log_except()
            else:
                return format_exc()
        finally:
            self.logs = []

    @property
    def mgr(self):
        return self.player._game.gm_mgr

    def log(self, msg, *args):
        self.logs.append(unicode(msg) % args)

    def gm_help(self, obj=None):
        """ 获取帮助 """
        import pydoc
        pre_classify_class_attrs = pydoc.classify_class_attrs
        pre_plainpager = pydoc.plainpager
        def my_classify_class_attrs(object):
            """Wrap inspect.classify_class_attrs, with fixup for data descriptors."""
            new_attrs = []
            attrs = pre_classify_class_attrs(object)
            for attr in attrs:
                if not object.__name__.startswith('GM') and not attr[0].startswith(PRE_GM):
                    continue
                new_attrs.append(attr)
                #new_attrs.append([attr[0][4:]] + list(attr[1:]))
            return new_attrs
        def my_plainpager(text):
            self.log(pydoc.plain(text))

        pydoc.plainpager = my_plainpager
        pydoc.classify_class_attrs = my_classify_class_attrs
        try:
            helper = pydoc.Helper(input=None, output=self)
            if obj is None:
                obj = self
            helper.help(obj)
        finally:
            pydoc.plainpager = pre_plainpager
            pydoc.classify_class_attrs = pre_classify_class_attrs

    def gm_profile(self, duration=60, profile=None, is_trace=False):
        """ profile """
        from corelib import tools
        if is_trace:
            is_trace = self
        rs, msg = tools.profile(duration, profile, trace_obj=is_trace)
        self.log(msg)

    def gm_meliae(self, file_path):
        """ 内存分析 """
        from corelib import tools
        tools.meliae_dump(file_path)
        self.log('success!')

    def gm_clear(self):
        """ 清理现场 """
        self.locals.clear()
        self.log(u'清理成功')

    def gm_arena_start(self, init=False):
        self.player._game.rpc_arena_mgr.start(init=init)
        self.log(u'开启竞技场成功')

    def gm_arena_stop(self):
        self.player._game.rpc_arena_mgr.stop()
        self.log(u'停止竞技场成功')

    def gm_status_get(self, key):
        v = self.player._game.rpc_status_mgr.get(key)
        self.log(u'status_get:%s', v)

    def gm_status_set(self, key, value, orig_value):
        rs = self.player._game.rpc_status_mgr.set(key, value, orig_value)
        self.log(u'status_set:%s', rs)

    def gm_status_inc(self, key, num):
        self.player._game.rpc_status_mgr.inc(key, num)

    def gm_send_mails(self, pids, t, title, content, items=None):
        """ 发送邮件, count:发送多少次 """
        mids = self.player._game.mail_mgr.send_mails(pids, t, title, content, items)
        self.log(u"发送邮件成功:%s", mids)

    def gm_notify_players(self, pids, msg):
        """ 向玩家推送消息 """
        Game.rpc_notify_svr.send_msgs(pids, msg)
        self.log(u"推送消息成功:%s", pids)

    def gm_finish_achi(self, t, aid, pids):
        """完成成就 t='day' 每日  t='ever' 永久 aid成就id  pids玩家列表"""
        i = 0
        n = 10
        for pid in pids:
            player = Game.rpc_player_mgr.get_rpc_player(pid)
            if player is None:
                offline = True
                player = Player.load_player(pid)
            if player is None:
                continue
            player.gm_finish_achi(t, aid)
            if offline:
                player.save()
            i += 1
            if i%n == 0:
                sleep(0)

    def gm_get_ally_members(self, name):
        """获得同盟成员信息"""
        pids = Game.rpc_ally_mgr.get_ally_pids_by_name(name)
        names = Game.rpc_player_mgr.get_names(pids)
        self.log('%s %s', pids, "   ".join(names.values()))

    def gm_del(self, name):
        """ 删除指定名称的玩家数据 """
        pid = PlayerData.name_to_id(name)
        self.gm_del_pid(pid)

    def gm_del_pid(self, pid):
        """ 删除玩家数据 """
        rs = Player.del_player(pid)
        if rs:
            self.log(u'删除玩家(%s)数据成功', pid)
        else:
            self.log(u'删除玩家(%s)数据失败', pid)

    def gm_del_player(self, pid):
        """ 删除玩家,不删除数据,只是将数据和user断开联系 """
        p = self._get_player(pid)
        if not p:
            uid = 'uid'
            tmp_player = PlayerData.get_values(pid, None)
            PlayerData.update_values(pid, dict(uid=-abs(tmp_player[uid])))
        else:
            p.data.uid = -abs(p.data.uid)
        self.log(u'修改角色(%d)成功', pid)
    gm_del_offline_player = gm_del_player

    def gm_get(self, name):
        """ 获取角色gm类 """
        pid = PlayerData.name_to_id(name)
        p = self.player._game.player_mgr.get_player(pid)
        if not p:
            self.log(u'获取玩家(%s)失败', name)
        else:
            return GMPlayer(self, p)

    def gm_get1(self, pid):
        """ 获取角色gm类 """
        p = self.player._game.player_mgr.get_player(pid)
        if not p:
            self.log(u'获取玩家(%s)失败', pid)
        else:
            return GMPlayer(self, p)

    def gm_get_pid_by_name(self, name):
        """ 通过角色名获取pid """
        pid = PlayerData.name_to_id(name)
        self.log(u'玩家PID：%s', pid[0])

    def gm_change_uid(self, pid, uid):
        PlayerData.update_values(pid, dict(uid=uid))
        self.log(u'更发UID成功')

    def _get_player(self, pid):
        p = self.player._game.player_mgr.get_player(pid)
        return p

    def gm_get_by_pid(self, pid):
        p = self._get_player(pid)
        if not p:
            self.log(u'获取玩家(%s)失败', pid)
        else:
            return GMPlayer(self, p)

    def gm_copy(self, from_id, to_id):
        """ 完全复制玩家数据 """
        player = self.player._game.player_mgr.get_player(to_id)
        if player is None:
            player = Player.load_player(to_id)
        if not player:
            self.log(u'拷贝失败:(%s)找不到', to_id)
            return
        if player.copy_player(from_id):
            self.log(u'拷贝成功')
        else:
            self.log(u'拷贝失败:(%s)找不到', from_id)

    def gm_add_task(self, pid, tid):
        """ 添加任务 """
        offline = 0
        gp = self.gm_get_by_pid(pid)
        if not gp: #离线
            offline = 1
            p = Player.load_player(pid)
            gp = GMPlayer(self, p)
        gp.add_task(tid)
        if offline:
            gp.player.save()

    def gm_info(self):
        """ 获取频道服务器信息 """

    def gm_close_server(self):
        """ 关闭服务器 """

    def gm_open_server(self):
        """ 开启服务器 """

    def gm_chat(self, chat_type, msg, pid=None):
        """ 发送聊天信息
        chat_type:1=世界, 2=系统, 3=大喇叭, 4=同盟, 5=密语
        """
        from game.mgr.chat import CT_SYS
        chat_mgr = self.player._game.chat_mgr
        if chat_type == CT_SYS:
            chat_mgr.sys_send(msg)
        else:
            chat_mgr.chat_send(self.player, chat_type, msg, pid=pid)

    def gm_forbid_chat(self, pid, times):
        """ 禁言到某某时间 """
        p = self._get_player(pid)
        if p:
            p.forbid_chat(times)
        else:
            PlayerData.update_values(pid, dict(fbChat=int(time.time())+times))
        self.log(u'禁言成功')

    def gm_change_CBE(self, pid, value):
        """ 设置用户CBE """
        querys = dict(pid=pid)
        tAttrs = Game.rpc_store.query_loads(TN_P_ATTR, querys)
        Game.rpc_store.update(TN_P_ATTR, tAttrs[0][FN_ID], dict(CBE=value))
        self.log(u'设置用户CBE成功')

    def gm_add_money(self, pid, coin1, coin2=0, coin3=0, is_set=False, vip=False):
        """ 增加金钱(coin1, coin2=0, coin3=0) """
        p = self._get_player(pid)
        if p:
            p.add_coin(aCoin1=coin1, aCoin2=coin2, aCoin3=coin3,
                is_set=is_set, vip=vip, log_type=COIN_ADD_GM)
            p.pack_msg_data(coin=1, send=1)
        else:
            str_coin1, str_coin2, str_coin3 = 'coin1', 'coin2', 'coin3'
            cols = [str_coin1, str_coin2, str_coin3]
            val = PlayerData.get_values(pid, cols)
            coin1 = val[str_coin1]+coin1
            coin2 = val[str_coin2]+coin2
            coin3 = val[str_coin3]+coin3
            PlayerData.update_values(pid, dict(coin1=coin1, coin2=coin2,coin3=coin3))
        self.log(u'增加银币成功，角色当前(银币,元宝,绑元宝)数：(%s, %s, %s)',
                coin1, coin2, coin3)

    def gm_player_pay_back(self, pid, rid):
        """ 模拟玩家充值行为,给予玩家充值奖励 """
        coin = Game.rpc_vip_mgr.get_good_coin(rid)
        rs, lv = Game.rpc_vip_mgr.player_pay_back(pid, rid, coin)
        if rs:
            Game.rpc_vip_mgr.safe_pub(msg_define.MSG_VIP_PAY, pid, rid, coin)
            self.log(u'玩家充值奖励完成')
        else:
            self.log(u'玩家充值奖励失败:%s, %s', rs, lv)


    def gm_unforbid_chat(self, pid):
        """ 取消禁言 """
        p = self._get_player(pid)
        if p:
            p.unforbid_chat()
        else:
            PlayerData.update_values(pid, dict(fbChat=0))
        self.log(u'取消禁言成功')

    def gm_forbid_login(self, pid, times):
        """ 禁止登录 """
        p = self._get_player(pid)
        if p:
            p.forbid_login(times)
        else:
            PlayerData.update_values(pid, dict(fbLogin=int(time.time())+times))
        self.log(u'禁止登录成功')

    def gm_player_func(self, pid, index):
        funcs = 'funcs'
        tmp_func = PlayerData.get_values(pid, None)
        tmp_func = tmp_func[funcs] | (1L << index)
        PlayerData.update_values(pid, dict(funcs=tmp_func))
        self.log(u'解锁成功')

    def gm_set_level(self, pid, level):
        """ 调等级 """
        player = Game.rpc_player_mgr.get_rpc_player(pid)
        if player:
            player.upgrade(level)
        else:
            PlayerData.update_values(pid, dict(level=level))
        self.log(u'更发等级成功')

    def gm_unforbid_login(self, pid):
        """ 解禁登录 """
        p = self._get_player(pid)
        if p:
            p.unforbid_login()
        else:
            PlayerData.update_values(pid, dict(fbLogin=0))
        self.log(u'取消禁止登录成功')

    def gm_scene_enter(self, pid, mapId):
        p = self._get_player(pid)
        if p:
            p.scene_enter(mapId)
        else:
            PlayerData.update_values(pid, dict(mapId=int(mapId)))
        self.log(u'进入地图成功')

    def gm_del_offline_player(self, pid):
        """ 删除角色 """
        uid = 'uid'
        tmp_player = PlayerData.get_values(pid, None)
        PlayerData.update_values(pid, dict(uid=-tmp_player[uid]))
        self.log(u'修改角色(%d)成功', pid)

    def gm_horn_msgs(self, msgs, times, interval):
        """ 大喇叭后台广播信息 """
        self.player._game.rpc_horn_mgr.manage_send(msgs, times, interval)
        self.log(u'信息：(%s)发送成功', msgs)

    def gm_horn_stop(self):
        """ 停止所有大喇叭 """
        self.player._game.rpc_horn_mgr.set_stop()
        self.log(u'停止所有大喇叭成功')

    def gm_worldboss_start(self, time=0, delay_time=300):
        """ 开启世界boss """
        self.player._game.rpc_boss_mgr.set_world_start(index=time, delay_time=delay_time)
        self.log(u'开启世界boss成功')

    def gm_start_awar(self, type, time=300):
        """ 开启狩龙战 """
        self.player._game.rpc_awar_mgr.gm_start_activity(type, time)
        self.log(u'开启狩龙战活动成功')

    def gm_hide_mail(self, pid):
        """ 隐藏 玩家的邮件 """
        change_pid = -1 * pid
        self._data_change(pid, change_pid)
        self.log(u"隐藏成功")

    def gm_view_mail(self, pid):
        """ 显示 玩家邮件 """
        find_pid = -1 * pid
        self._data_change(find_pid, pid)
        self.log(u'显示成功')

    def _data_change(self, find_pid, change_pid):
        """ 根据pid更新玩家邮件数据和邮件相关联的待收物品信息 """
        from game.store import TN_P_MAIL, TN_P_WAIT
        key = dict(pid=find_pid)
        mail_datas = Game.rpc_store.query_loads(TN_P_MAIL, key)
        mail_wait_ids = []
        for mail_data in mail_datas:
            mail_data['pid'] = change_pid
            wait_id = mail_data.get('wid')
            if not wait_id:
                continue
            mail_wait_ids.append(wait_id)
        wait_datas = Game.rpc_store.loads(TN_P_WAIT, mail_wait_ids)
        for wait_data in wait_datas:
            wait_data['pid'] = change_pid
        Game.rpc_store.saves(TN_P_MAIL, mail_datas)
        Game.rpc_store.saves(TN_P_WAIT, wait_datas)

    def gm_worldboss_level(self, level, time):
        """ 改变世界boss的等级 """
        self.player._game.rpc_boss_mgr.set_boss_level(level, time)
        self.log(u'boss等级修改为 %s',level)

    def gm_stop_bot(self):
        """ 关闭所有机器人 """
        self.player._game.rpc_scene_mgr.gm_stop_bot()
        self.log(u'关闭机器人成功')

    def gm_start_bot(self):
        """ 开启所有机器人 """
        self.player._game.rpc_scene_mgr.gm_start_bot()
        self.log(u'开启机器人成功')

    def _add_member_by_p_name(self, a_name, p_name):
        """p_name玩家名字"""
        from game.store import TN_PLAYER
        rpc_store = self.player._game.rpc_store
        lis = Game.rpc_store.query_loads(TN_PLAYER, dict(name=p_name))
        if not lis:
            self.log(u"该玩家不存在")
            return
        dic = lis[0]
        ally_mgr = Game.instance.rpc_ally_mgr
        pid = int(dic['id'])
        if ally_mgr.get_aid_by_pid(pid):
            self.log(u"玩家已经有帮会")
            return
        if not ally_mgr.set_gm_ally_by_name(a_name):
            self.log(u'公会名字不存在')
            return
        if ally_mgr.gm_add_ally(pid):
            self.log(u"添加成功")
            return
        self.log(u"添加失败")

    def gm_add_ally_members(self, a_name, p_name, num):
        """添加同盟成员的数目"""
        if p_name:
            return self._add_member_by_p_name(a_name, p_name)

        try:
            rpc_store = self.player._game.rpc_store
            ally_mgr = Game.instance.rpc_ally_mgr
            sum_num = 0                                                         #通过GM命令加入同盟的总数
            lev_in_num = PlayerData.count({FN_PLAYER_LEVEL:{FOP_GTE:1}})        #达到等级条件的总数
            us_list = []                                                        #本次使用到了的pid
            #每个段的起始和结束pid[(s1,e1), (s2,e2))]
            section_list = [(i*SECTION, (i+1)*SECTION) for i in xrange(lev_in_num/SECTION)]
            start_time = time.time()
            shuffle(section_list)
            if not ally_mgr.set_gm_ally_by_name(a_name):
                self.log(u'公会名字不存在')
                return
            for start_pid, end_pid in section_list:
                us_list.append((start_pid, end_pid))
                for pid in xrange(start_pid, end_pid):
                    if sum_num >= num:
                        self.log(u'申请添加%s个满足等级条件的%s个实际添加%s个成员', num, lev_in_num, sum_num)
                        ally_mgr.clear_gm_ally()
                        return
                    if not rpc_store.has("player", pid):
                        log.info("table player has no pid:%s", pid)
                        continue
                    sum_num += ally_mgr.gm_add_ally(pid)
        except:
            log.log_except()

    def gm_clear_ally_except_main(self, name):
        if Game.instance.rpc_ally_mgr.clear_ally(name):
            self.log(u"除了帮主其他职位清除成功")
            return
        self.log(u'公会名字不存在')

    def gm_change_ally_duty(self, pid, duty, name):
        """
        改变职务
        """
        pid = int(pid)
        duty = int(duty)
        ally_mgr = Game.instance.rpc_ally_mgr
        if not ally_mgr.set_gm_ally_by_name(name):
            return self.log(u'公会名字不存在')
        return self.log(ally_mgr.gm_change_duty(pid, duty))

    def gm_set_debug_data(self, ips, status):
        Game.rpc_player_mgr.set_debug_data(ips, status)
        return self.log(u'ips:%s, 状态:%s', ips, int(status))



class GameMasterMgr(BaseGameMgr):
    def __init__(self, game):
        super(GameMasterMgr, self).__init__(game)
        self.build_public_gm()

    def stop(self):
        self.gm_master.uninit()
        self.player._game = None
        self.player = None
        BaseGameMgr.stop(self)

    def build_public_gm(self):
        """创建公用GM对象执行具体命令"""
        class pseudoPlayer(object):
            def __init__(self, game):
                self.name = u"公共GM"
                self._game = game
            def log_gm(self, cmd):
                self._game.glog.log_gm(dict(p=0, cmd=cmd))
        self.player = player = pseudoPlayer(self._game)
        self.gm_master = GameMaster(player)

    def get_gm(self, player, forced=False):
        """ 根据角色，获取gm对象 """
        if not (forced or player.is_gm):
            return
        return GameMaster(player)

    def get_role(self, name):
        """ 获得GMPlayer对象"""
        player = Game.instance.scene_mgr.get_player_by_name(name)
        return GMPlayer(self.gm_master, player)





