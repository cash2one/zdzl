#!/usr/bin/env python
# -*- coding:utf-8 -*-
""" 角色行为
"""

import time

from contextlib import contextmanager
from corelib import log
from game import pack_msg
from game.base import errcode
from game.base import common
from game.base.msg_define import (MSG_WEAPON_UP, MSG_MAIN_EQUIP_UP, MSG_FISH_USE_ITEM,
    MSG_VIP_UP_GRADE, MSG_ADDTRAIN, MSG_EQUIP_UP, MSG_FISH_COIN3, MSG_MERGE_ITEM, MSG_VIP_COIN_ADD)
from game.scene.scene import make_scene_info
from game.base.constant import (MINING_COIN1, MINING_COIN2,
    ARM_LEVEL_SK1, ARM_LEVEL_SK1_V, ARM_LEVEL_SK2, ARM_LEVEL_SK2_V,
    ARENA_LEVEL, ARENA_LEVEL_V, ARENA_INFO_COUNT, MAIL_REWARD,
    ALLY_CAT_COUNT, ALLY_GRAVE_COUNT1, IKEY_ID, RW_MAIL_AWARWORLDCOPY_END,
    CAN_TRADE, IF_IDX_CAR, IF_IDX_ALLY, IT_FISH, IKEY_COUNT, DIFF_TITEM_COIN3,
    TRAIN_COIN2_NUM, TRAIN_COIN2_NUM_V, TRAIN_FREE_RATE, TRAIN_FREE_RATE_V, INIT_LEVEL,
    TRAIN_MIN_LEVEL, TRAIN_MIN_LEVEL_V, IKEY_TYPE, IT_ITEM_STR,
    VIP_BASE_COIN, VIP_BASE_COIN_V, ALLY_SKY_WAR, ALLY_WORLD_WAR
)

from game.glog.common import (
        PL_TASK, ITEM_COST_EXCHANGE, COIN_ALLY_CREATE,
        ITEM_ADD_MERGE, ITEM_ADD_USE, ITEM_ADD_PAY,
        ITEM_COST_MERGE, ITEM_COST_STRONG, ITEM_COST_USE,
        EQ_MOVE, EQ_STRONG, COIN_EXCHANGE_CAR,
        COIN_MERGE, COIN_EQ_MOVE, COIN_SKILL_BACK,
        TRAIN_BACK, TRAIN_ARM, COIN_FIRST_PAY, PL_MERGE_FATE,
        ITEM_ADD_ALLY_WAR,
)
from game.item.reward import merge_reward_items


TRAIN_TYPE_BACK_FREE = 1
TRAIN_TYPE_BACK_COIN2 = 2

if 0:
    from game.player.player import Player
    class AbsPlayer(Player):
        pass
else:
    class AbsPlayer(object):
        def __init__(self):
            raise NotImplemented

class OtherMixin(AbsPlayer):
    """ 第三方的监听添加可写在这个类 """

    def _handle_ally_train(self, aTrain):
        if self.has_ally():
            self._game.rpc_ally_mgr.contribute(self.data.id, self.data.name, aTrain)

    def other_init(self):
        self.sub(MSG_ADDTRAIN, self._handle_ally_train)

    def pub_vip_level(self):
        """玩家VIP等级升级"""
        self.pub(MSG_VIP_UP_GRADE, self.data.vip)

class ActionMixin(AbsPlayer):
    """ 玩家类扩展 """
    @property
    def arena_level(self):
        return self._game.setting_mgr.setdefault(ARENA_LEVEL, ARENA_LEVEL_V)

    def can_arena(self):
        """ 是否可以竞技场 """
        return self.data.level >= self.arena_level

    def get_activity_infos(self, ally_only):
        """ 获取活动信息 """
        pid = self.data.id
        _game = self._game
        arena, fish, cat, grave, allyFight, allyBoss, allyBossTime, wBoss, wBossSecs = 0,0,0,0,0,0,0,0,0
        allyWarSky, allyWarWorld = 2, 2
        awar_sky_data, awar_world_data = '', ''
        vip = self.data.vip
        if not ally_only:
            #竞技场
            if self.can_arena():
                rs, data = _game.rpc_arena_mgr.enter(pid, vip)
                if rs:
                    arena = data[ARENA_INFO_COUNT]
            #fish
            rs, data = _game.fish_mgr.fish_enter(self)
            if rs:
                fish = data['n']
            #world boss
            rs, data = _game.rpc_boss_mgr.is_start_world_boss(pid)
            if rs:
                wBoss = 1
            wBossSecs = int(time.time() - common.zero_day_time())
        if self.ally:
            #cat
            rs, data = _game.rpc_ally_mgr.cat_enter(pid, self.data.vip)
            if rs:
                cat = data[ALLY_CAT_COUNT]
            #grave
            rs, data = _game.rpc_ally_mgr.grave_enter(pid, self.data.vip)
            if rs:
                grave = data[ALLY_GRAVE_COUNT1]

            #allyBoss, 检查是否可进入是否结束
            rs, data1 = _game.rpc_boss_mgr.ally_boss_get_time(self.ally['aid'], is_enter=True)
            rs, data2 = _game.rpc_boss_mgr.ally_boss_get_time(self.ally['aid'], is_fight=True)
            if rs:
                allyBossTime = data1[0]
                #0=不可进入已结束，1=可进入未结束，2=不可进入未结束
                if data1[1]:
                    allyBoss = 1
                elif not data1[1] and not data2[1]:
                    allyBoss = 2
            #
            rs, data = _game.rpc_awar_mgr.get_start_activity(pid)
            awar_sky_data, awar_world_data = _game.rpc_awar_mgr.get_activity_time(self.ally['aid'])
            if rs and data == ALLY_SKY_WAR:
                allyWarSky = 1
            elif rs and data == ALLY_WORLD_WAR:
                allyWarWorld = 1
            #allyFight
            #rs, data = _game.rpc_ally_mgr.
            #allyBoss = 1
        if ally_only:
            return dict(allyFight=allyFight, allyBoss=allyBoss,
                        allyBossTime=allyBossTime, cat=cat, grave=grave,
                        allyWarSky=allyWarSky, allyWarWorld=allyWarWorld,
                awar_sky_data=awar_sky_data, awar_world_data=awar_world_data)
        return dict(arena=arena, fish=fish,
                    ctreenum=_game.ctree_mgr.api_ctree_get_rest_quota(self),
                    cat=cat, grave=grave, allyFight=allyFight, allyBoss=allyBoss,
                    allyBossTime=allyBossTime, wBoss=wBoss, wBossSecs=wBossSecs,
                    allyWarSky=allyWarSky, allyWarWorld=allyWarWorld,
                    awar_sky_data=awar_sky_data, awar_world_data=awar_world_data)

    @property
    def is_forbid_chat(self):
        return self.data.fbChat > time.time()

    def forbid_chat(self, times):
        """ 禁言times秒 """
        self.data.fbChat = int(time.time()) + times

    def unforbid_chat(self):
        """ 取消禁言 """
        self.data.fbChat = 0

    @property
    def is_forbid_login(self):
        return self.data.fbLogin > time.time()

    def forbid_login(self, times):
        """ 禁止登录times秒 """
        self.data.fbLogin = int(time.time()) + times

    def unforbid_login(self, pid):
        """ 取消禁止登录 """
        self.data.fbLogin = 0

    def pay_back(self, rid, first_reward, coin):
        """ 支付回调 coin=奖励里的真元宝数"""
        reward = self._game.reward_mgr.get(rid)
        items = reward.reward(self.reward_params())
        #是否首充
        vip_base_coin = self._game.setting_mgr.setdefault(VIP_BASE_COIN, VIP_BASE_COIN_V)
        log.info("vipCoin:%s, charge origin:%s, first_reward:%s", self.data.vipCoin, vip_base_coin, first_reward)
        bag_items = self.bag.add_items(items, log_type=ITEM_ADD_PAY)
        if not self.data.Payed and first_reward:
            try:
                self.data.Payed = 1
                freward = self._game.reward_mgr.get(first_reward)
                fitems = freward.reward(self.reward_params())
                #发放首充奖励
                log.info(u'[pay_back](%d)首冲翻倍:%s', self.data.id, coin)
                self.add_coin(aCoin3=coin, log_type=COIN_FIRST_PAY)
                bag_items.coin3 += coin
                self.vip.first_charge(fitems)
            except:
                log.log_except()
        self.vip.pay_back(bag_items)
        self.pub(MSG_VIP_COIN_ADD, self.data.coin2)
        return 1, self.data.level

class ActionSceneMixin(AbsPlayer):
    """ 场景操作 """
    @property
    def is_scene(self):
        """ 是否有场景 """
        return self.rpc_scene is not None

    def scene_changes(self, changes):
        """ 同步信息 """
        self.send_msg(changes)

    def scene_enter(self, scene_id, login=False):
        """ 进入场景 """
        if not scene_id:
            return False, errcode.EC_NOFOUND
        if 0:
            from game.scene.scene import Scene
            self.rpc_scene = Scene()
        self.data.mapId = scene_id
        if not login:#跳转地图,清空坐标,登陆状态除外
            self.data.pos = ''
        if self.logined:
            rpc_scene = self._game.scene_mgr.enter_scene(self, scene_id, self.data.pos)
            self.rpc_scene = rpc_scene
        return True, None

    def scene_leave(self):
        """ 离开当前场景 """
        if not self.logined or self.rpc_scene is None:
            return
        if self._game.rpc_scene_mgr.leave_scene(self.data.id):
            self.rpc_scene = None

    def scene_move(self, x_y):
        """ 移动 """
        self.data.pos = x_y
        if self.rpc_scene:
            self.rpc_scene.player_move(self.data.id, x_y, _no_result=True)

    def get_scene_info(self):
        """ 返回场景广播用的玩家信息 """
        return make_scene_info(self)

    def update_scene_info(self, info=None):
        """ 更新玩家场景信息到场景管理器
        info:字典{idx:value},允许部分更新
        """
        if not self.is_scene:
            return
        if info is None:
            info = make_scene_info(self)
        self.rpc_scene.player_update(self.data.id, info, _no_result=True)


def wrap_log(func):
    def _func(self, *args, **kw):
        if getattr(self, '_disable_log', False):
            return
        return func(self, *args, **kw)
    return _func

class ActionLogMixin(AbsPlayer):

    @contextmanager
    def with_disable_log(self):
        self._disable_log = True
        try:
            yield True
        finally:
            self._disable_log = False

    @wrap_log
    def log_normal(self, type, **kw):
        """ 玩家信息:玩家id, 类型, 描述, 子类型,  """
        if kw:
            self._game.glog.log(dict(p=self.data.id, t=type, d=kw))
        else:
            self._game.glog.log(dict(p=self.data.id, t=type))

    @wrap_log
    def log_task(self, tid, ttid, t=PL_TASK):
        """ 任务记录,
        tid: 基础任务表id
        ttid: 玩家任务表id
        """
        self._game.glog.log(dict(p=self.data.id, t=t, tid=tid, ttid=ttid))

    @wrap_log
    def log_merge_fate(self, ufate, dfate, t=PL_MERGE_FATE):
        """ 命格合并
        ufate:被更新前的命格数据
        dfate:被删除的命格数据
        uuid: 被更新命格的用户表命格id
        ufid: 被更新命格的基础表命格id
        dfid: 删除命格的基础表命格id
        dexp: 删除命格的经验
        dlv:  删除命格的等级
        dq:   删除命格的品质
        """
        self._game.glog.item(dict(p=self.data.id, t=t, ufate=ufate, dfate=dfate))

    @wrap_log
    def log_item(self, iid, count, type, **kw):
        """ 玩家添加物品 """
        self._game.glog.item(dict(i=iid, p=self.data.id, t=type, c=count, d=kw))

    @wrap_log
    def log_items(self, items, type, rid=0, **kw):
        """ 玩家添加物品 """
        self._game.glog.item(dict(p=self.data.id, t=type, i=str(items), rid=rid, d=kw))

    @wrap_log
    def log_gm(self, cmd):
        """ gm执行命令 """
        self._game.glog.log_gm(dict(p=self.data.id, cmd=cmd))

    @wrap_log
    def log_equip(self, type, **kw):
        """ 装备强化(升级、等级转移) """
        self._game.glog.log_equip(dict(p=self.data.id, t=type, d=kw))

    @wrap_log
    def log_coin(self, type, coin1, coin2, coin3):
        """ 虚拟币记录 """
        self._game.glog.log_coin(dict(p=self.data.id, t=type,
            c1=coin1, c2=coin2, c3=coin3))

    @wrap_log
    def log_train(self, type, train):
        """ 练厉记录 """
        self._game.glog.log_coin(dict(p=self.data.id, t=type,
            tr=train))

class AllyMixin(AbsPlayer):
    """ 同盟操作 """
    @property
    def ally_id(self):
        return self.ally.get('aid', None) if self.ally else None

    @property
    def ally_name(self):
        return self.ally.get('n', '') if self.ally else ''

    def ally_create(self, name):
        """ 创建同盟,从ally_handler移动到这 """
        #if self._game.setting_mgr.check_ban_word(name):
        if self._game.rpc_ban_word_mgr.check_ban_word(name):
            return 0, errcode.EC_FORBID_STRING
        d = self.data
        rs, data = self._game.rpc_ally_mgr.pre_create(d.id, d.level, name)
        if not rs:
            return 0, data
        if not self.enough_coin(data, 0, 0):
            return 0, errcode.EC_COST_ERR
        self.cost_coin_ex(data, 0, 0, log_type=COIN_ALLY_CREATE)
        rs, data = self._game.rpc_ally_mgr.create_ally(d.id, name)
        if not rs:
            return 0, data
        ally_id, data = data
        self.set_ally(dict(aid=ally_id, n=name))
        pack_data = self.pack_msg_data(coin=True)
        for key, val in pack_data.items():
            data[key] = val
        return 1, data

    def attach_ally(self, aid, n, dic):
        resp_f = "allyUpdate"
        self.set_ally(dict(aid=aid, n=n))
        self.send_msg(pack_msg(resp_f, 1, data=dic))

    def set_ally(self, info):
        self.ally = info
        self.update_scene_info({IF_IDX_ALLY:self.ally_name})

    def detach_ally(self, dic):
        """ 被踢 自己退出 解散同盟 """
        self.detach_ally1()
        resp_f = "allyUpdate"
        self.send_msg(pack_msg(resp_f, 1, data=dic))

    def detach_ally1(self):
        """ 被踢 自己退出 解散同盟 兼容以前的 """
        self.set_ally(None)

    def has_ally(self):
        """ 是不是有同盟 """
        return bool(self.ally)

    def ally_pub(self, ally_msg, level):
        """玩家同盟消息的发布主要针对成就系统"""
        self.safe_pub(ally_msg, level)
    
    def awar_copy_reward(self, rid):
        """ 击打影分数发放奖励 """
        rw = self._game.reward_mgr.get(rid)
        reward_items = rw.reward({})
        log.debug('awar_copy_reward-reward_items1- %s', reward_items)
        if not reward_items:
            return
        self._game.rpc_awar_mgr.handle_reward(self.data.id, reward_items)
        log.debug('awar_copy_reward-reward_items2- %s', reward_items)
        if self.bag.can_add_items(reward_items):
            bag_item = self.bag.add_items(reward_items, log_type=ITEM_ADD_ALLY_WAR)
            bag_item.pack_msg(send=1)
            return
        res_rw_mail = self._game.res_mgr.reward_mails.get(RW_MAIL_AWARWORLDCOPY_END)
        self._game.mail_mgr.send_mails(self.data.id, MAIL_REWARD,
            res_rw_mail.title, RW_MAIL_AWARWORLDCOPY_END, reward_items, param=res_rw_mail.content)
        self.send_update_msg(errcode.EC_ALLY_WAR_FULLBAG, rs=0)

class ActionItemMixin(AbsPlayer):
    def use_item(self, id, pack_msg=True):
        """ 使用物品,获取东西
        返回:成功, (items, equips, fates, cars, dels)
             失败, 失败原因
        """
        if self.bag.bag_free() <= 0:
            return False, errcode.EC_BAG_FULL
        item, res_item = self.bag.get_item_ex(id)
        if item is None or not res_item.can_use():
            return False, errcode.EC_EQUIP_NOUSE
        if res_item.lv > self.data.level:
            return False, errcode.EC_NOLEVEL

        reward = self._game.reward_mgr.get(res_item.rid)
        if reward is None:
            return False, errcode.EC_VALUE
        use_id, use_num = reward.data.useId, reward.data.useNum
        trade, no_trade,  use_ids, up_items = 0, 0, None, None
        #添加物品列表
        items = reward.reward(params=self.reward_params())
        self.safe_pub(MSG_FISH_USE_ITEM, items, res_item)
        #检测是否可以加入
        if not self.bag.can_add_items(items):
            return False, errcode.EC_BAG_FULL

        if use_id:#需要花费物品(碎片使用)
            cost_ok = self.bag.cost_item(use_id, use_num,
                    log_type=ITEM_COST_USE, uses=[id])
            if cost_ok is None:
                return False, errcode.EC_EQUIP_NOUSE
            trade, no_trade,  use_ids, up_items = cost_ok

        bag_items = self.bag.add_items(items, log_type=ITEM_ADD_USE)
        if res_item.type == IT_FISH:
            self._handle_horn(items)
        if use_id:
            if trade: #是否可交易处理
                for i in bag_items.iter_all_items():
                    i.data.isTrade = CAN_TRADE
                    i.modify()
            if up_items is not None:
                bag_items.items.extend(up_items)
        if pack_msg:
            return True, bag_items.pack_msg(del_iids=use_ids)
        return True, bag_items

    def _handle_horn(self, reward_items):
        """ 处理广播 """
        for reward_item in reward_items:
            if reward_item[IKEY_TYPE] == IT_ITEM_STR\
            and reward_item[IKEY_ID] == DIFF_TITEM_COIN3:
                num = reward_item[IKEY_COUNT]
                self.pub(MSG_FISH_COIN3, num)

    def car_exchange(self, cid):
        """ 兑换坐骑 """
        res_car = self._game.res_mgr.cars.get(cid)
        if not res_car:
            return False, errcode.EC_NORES
        if not res_car.isExchange:
            return False, errcode.EC_CAR_NOT_EXCHANGE
        if res_car.coin1 or res_car.coin2 and not self.enough_coin(res_car.coin1, res_car.coin2):
            return False, errcode.EC_PAY_FAIL
        if res_car.coin3 and not self.enough_coin(0, res_car.coin3, use_bind=False):
            return False, errcode.EC_PAY_FAIL
        cost_ok = self.bag.cost_item(res_car.useId, res_car.count, log_type=ITEM_COST_EXCHANGE, uses=[id])
        if cost_ok is None:
            return False, errcode.EC_CAR_ENOUGH
        trade, no_trade,  use_ids, up_item = cost_ok
        add_car = self.bag.add_car(cid)
        cost_coin = False
        if res_car.coin1 or res_car.coin2 or res_car.coin3:
            cost_coin = True
            self.cost_coin_ex(res_car.coin1, res_car.coin2, res_car.coin3, log_type=COIN_EXCHANGE_CAR)
        if up_item and use_ids:
            data = self.pack_msg_data(coin=cost_coin, items=up_item, cars=[add_car], del_iids=use_ids)
            return True, data
        elif up_item:
            return True, self.pack_msg_data(coin=cost_coin, items=up_item, cars=[add_car])
        else:
            return True, self.pack_msg_data(coin=cost_coin,del_iids=use_ids, cars=[add_car])

    def car_do(self, cid):
        """ 操作坐骑(cid非零为骑，零为下马) """
        if cid is 0:
            self.data.car = cid
            self.update_scene_info({IF_IDX_CAR:cid})
            return True, None
        car = self.bag.cars.get(cid)
        if car is None:
            return False, errcode.EC_CAR_NOFIND
        self.data.car = car.data.cid
        self.update_scene_info({IF_IDX_CAR:car.data.cid})
        return True, None

    def merge_item(self, aDesId, aCount, aSrcId):
        """ 物品合成 """
        tFusion = self._game.item_mgr.get_item_fusion(aDesId, aSrcId)
        if not tFusion:
            return False, errcode.EC_NORES
        #判断钱是否够用
        coin1, coin2 = aCount * tFusion.coin1, aCount * (tFusion.coin2 + tFusion.coin3)
        if not self.enough_coin(coin1, coin2):
            return False, errcode.EC_COST_ERR
        tNeedCnt = aCount * tFusion.count
        #消耗物品判断
        rs, trade, no_trade, uses = self.bag.check_item(aSrcId, tNeedCnt)
        if not rs:
            return False, errcode.EC_EQUIP_NOUSE
        #判断是否能入包
        if trade and not self.bag.can_add_item(aDesId, trade, can_trade=True)[0] or\
           no_trade and not self.bag.can_add_item(aDesId, no_trade, can_trade=False)[0]:
            return False, errcode.EC_BAG_FULL
        tRsCost = self.bag.cost_item(aSrcId, tNeedCnt, tFusion.count, log_type=ITEM_COST_MERGE)
        #消耗物品
        if tRsCost is None:
            return False, errcode.EC_EQUIP_NOUSE
        trade, no_trade, del_ids, up_item = tRsCost
        #扣钱
        self.cost_coin(coin1, coin2, log_type=COIN_MERGE)
        #新物品入包(入包后判断是更新物品还是创建物品)
        tItems = []
        if trade and not no_trade:
            tItems.extend(self.bag.add_item(aDesId, aCount, can_trade=True, log_type=ITEM_ADD_MERGE))
        else:
            tItems.extend(self.bag.add_item(aDesId, aCount, can_trade=False, log_type=ITEM_ADD_MERGE))
        #添加消耗物品中更新的对象
        if up_item:
            tItems.append(up_item[0])
        tSend = self.pack_msg_data(coin=True)
        tSend.update({'delIids':del_ids, 'item':[i.to_dict() for i in tItems]})
        #抛出物品合成消息
        self.pub(MSG_MERGE_ITEM, aDesId, aCount, aSrcId)
        return True, tSend

    def arm_upgrade(self, aRole):
        """ 武器升级 """
        if not aRole:
            return False, errcode.EC_ROLE_NOFOUND
        tUplevel = aRole.data.armLevel + 1
        tResMgr = self._game.res_mgr
        tResRole = tResMgr.roles.get(aRole.data.rid)
        tResArmLevel = tResMgr.arm_level_by_keys.get((tResRole.armId, tUplevel))
        if not tResArmLevel:
            return False, errcode.EC_NORES
        tResArmExp = tResMgr.arm_exp_by_level.get(tUplevel)
        if not tResArmExp or tResArmExp.limit > self.data.level:
            return False, errcode.EC_ARMLEVEL_MAX
        if not self.cost_train(tResArmExp.exp, log_type=TRAIN_ARM):
            return False, errcode.EC_TRAIN_ENOUGH
        aRole.data.armLevel = tUplevel
        self.pub(MSG_WEAPON_UP, tUplevel, tResRole.armId, self, aRole.data.rid)
        self.roles.update_role(aRole)
        #激活
        if tUplevel == self.fetch_arm_level_sk1:
            tResArm = self._game.res_mgr.arms.get(tResRole.armId)
            aRole.data.sk = tResArm.sk1
        return True, {'rid':aRole.data.id, 'train':self.data.train, 'armLevel':tUplevel}

    def arm_skill(self, aRole, aSid):
        """ 激活技能 """
        if not aRole:
            return False, errcode.EC_ROLE_NOFOUND
        tResRole = self._game.res_mgr.roles.get(aRole.data.rid)
        tResArm = self._game.res_mgr.arms.get(tResRole.armId)
        if not aSid in (tResArm.sk1, tResArm.sk2):
            return False, errcode.EC_ARMNO_SKILL
        if aSid == tResArm.sk1 and aRole.data.armLevel < self.fetch_arm_level_sk1:
            return False, errcode.EC_ARMLEVEL_MAX
        if aSid == tResArm.sk2 and aRole.data.armLevel < self.fetch_arm_level_sk2:
            return False, errcode.EC_ARMLEVEL_MAX
        aRole.data.sk = aSid
        self.roles.update_role(aRole)
        return True, {'rid':aRole.data.id, 'sid':aSid}

    def _get_setting_v(self, aKey, aDefault):
        """ 获取全局表的值 """
        return self._game.setting_mgr.setdefault(aKey, aDefault)

    def skill_back(self, aRole, aType):
        """ 取回技能点 """
        if not aRole:
            return False, errcode.EC_ROLE_NOFOUND
        #是否到达可取回等级
        tResMinLv = self._get_setting_v(TRAIN_MIN_LEVEL, TRAIN_MIN_LEVEL_V)
        if aType == TRAIN_TYPE_BACK_COIN2 and tResMinLv > aRole.data.armLevel:
            return False, errcode.EC_ARMSKILLLEVEL_ENOUGH
        tBackTrain = 0
        for i in xrange(aRole.data.armLevel):
            tResArmExp = self._game.res_mgr.arm_exp_by_level.get(i + 1)
            tBackTrain += tResArmExp.exp
        if aType == TRAIN_TYPE_BACK_FREE:
            tResRote = self._get_setting_v(TRAIN_FREE_RATE, TRAIN_FREE_RATE_V)
            tBackTrain = tBackTrain * tResRote / 100
        elif aType == TRAIN_TYPE_BACK_COIN2:
            tResPerCoin2 = self._get_setting_v(TRAIN_COIN2_NUM, TRAIN_COIN2_NUM_V)
            tCostCoin2 = tResPerCoin2 * aRole.data.armLevel
            if not self.cost_coin(aCoin2=tCostCoin2, log_type=COIN_SKILL_BACK):
                return False, errcode.EC_COST_ERR
        else:
            return False, errcode.EC_VALUE
        self.add_train(tBackTrain, msg=0, log_type=TRAIN_BACK)
        aRole.data.armLevel = INIT_LEVEL
        #技能还原到角色的技能
        tResRole = self._game.res_mgr.roles.get(aRole.data.rid)
        aRole.data.sk = tResRole.sk2
        self.roles.update_role(aRole)
        tSend = self.pack_msg_data(coin=True)
        tSend.update({'rid':aRole.data.id, 'train':self.data.train})
        return True, tSend

    def equip_strong(self, aEid):
        """ 强化装备(升级) """
        #写入log
        self.log_equip(EQ_STRONG, id1=aEid)
        tEq = self.bag.get_equip(aEid)
        if not tEq:
            return False, errcode.EC_EQUIP_NOFOUND
        tResStrEq = self._game.item_mgr.get_res_str_eq(tEq.data.level + 1)
        if not tResStrEq:
            return False, errcode.EC_NORES
        #消耗物品
        tRsCost = self.bag.cost_item(tResStrEq.useId, tResStrEq.count, log_type=ITEM_COST_STRONG)
        if tRsCost is None:
            return False, errcode.EC_EQUIP_NOUSE
        trade, no_trade, del_ids, up_item = tRsCost
        #更新装备等级
        tEq.data.level += 1
        self.bag.update_equip(tEq)
        tSendData = {'equip':[tEq.to_dict()], 'delIids':del_ids}
        if up_item:
            tSendData['item'] = [up_item[0].to_dict()]
        #准备升级广播
        self.pub(MSG_EQUIP_UP, tEq.data.eid, tEq.data.level)
        #发送主将升级装备消息
        role = self.roles.get_role_by_rid(self.data.rid)
        if role:
            equip, res_equip = self.bag.get_equip_ex(aEid)
            self.safe_pub(MSG_MAIN_EQUIP_UP, role, equip, res_equip)
        return True, tSendData

    def equip_move_level(self, aRole, aEid1, aEid2):
        """ 强化装备等级(等级转移) eid1低 eid2高 """
        if not aRole:
            return False, errcode.EC_ROLE_NOFOUND
        tEq1 = self.bag.get_equip(aEid1)
        tEq2 = self.bag.get_equip(aEid2)
        if not tEq1 or not tEq2:
            return False, errcode.EC_EQUIP_NOFOUND
        tResEq1 = self._game.item_mgr.get_res_equip(tEq1.data.eid)
        tResEq2 = self._game.item_mgr.get_res_equip(tEq2.data.eid)
        if tResEq1.part != tResEq2.part:
            return False, errcode.EC_EQUIPPART_DIF
        if not self._cost_coin1(tEq1, tEq2, tResEq1, tResEq2, log_type=COIN_EQ_MOVE):
            return False, errcode.EC_COST_ERR
        #更新装备等级 更新角色属性
        tEq1.data.level, tEq2.data.level = tEq2.data.level, tEq1.data.level
        tEq1.data.used, tEq2.data.used = tEq2.data.used, tEq1.data.used
        self.bag.update_equip(tEq1)
        self.bag.update_equip(tEq2)
        tPlace = 'eq%d' % tResEq2.part
        setattr(aRole.data, tPlace, tEq2.data.id)
        self.roles.update_role(aRole)
        #写入log
        self.log_equip(EQ_MOVE, id1=aEid1, id2=aEid2)
        tSend = self.pack_msg_data(coin=True)
        tSend.update({'eid1':aEid1, 'eid2':aEid2})
        return True, tSend

    def _cost_coin1(self, aEq1, aEq2, aResEq1, aResEq2, log_type):
        """ 消费硬币（还验证了相同等级穿在身上的品质大于背包的） """
        if aEq1.data.level == aEq2.data.level:
            tResEqSet1 = self._game.res_mgr.equip_sets.get(aResEq1.sid)
            tResEqSet2 = self._game.res_mgr.equip_sets.get(aResEq2.sid)
            if tResEqSet1.quality >= tResEqSet2.quality:
                return
            tNeedCoin1 = 0
        elif aEq1.data.level and aEq2.data.level:
            tResStrEq1 = self._game.item_mgr.get_res_str_eq(aEq1.data.level)
            tResStrEq2 = self._game.item_mgr.get_res_str_eq(aEq2.data.level)
            tNeedCoin1 = tResStrEq1.mvCoin1 - tResStrEq2.mvCoin1
        else:
            tResStrEq = self._game.item_mgr.get_res_str_eq(aEq1.data.level)
            tNeedCoin1 = tResStrEq.mvCoin1
            #扣钱
        if tNeedCoin1 and not self.cost_coin(tNeedCoin1, log_type=log_type):
            return
        return True

    def mining_xt(self, aType):
        """ 采集玄铁 """
        if aType == MINING_COIN1:
            pass
        elif aType == MINING_COIN2:
            pass


    @property
    def fetch_arm_level_sk1(self):
        return self._game.setting_mgr.setdefault(ARM_LEVEL_SK1, ARM_LEVEL_SK1_V)

    @property
    def fetch_arm_level_sk2(self):
        return self._game.setting_mgr.setdefault(ARM_LEVEL_SK2, ARM_LEVEL_SK2_V)

class ActionSocial(AbsPlayer):
    """ 社交 """

    def is_friend(self, pid):
        return self._game.social_mgr.is_friend(self, pid)

    def is_black(self, pid):
        return self._game.social_mgr.is_black(self, pid)

    def force_add_friend(self, pid):
        """被迫加好友"""
        self._game.social_mgr.add_friend(self, pid)

    def apply_friend(self, name):
        from game.base.constant import MAIL_REWARD, SOCIAL_MAIL_FRIEND
        fd_mail = self._game.res_mgr.reward_mails.get(SOCIAL_MAIL_FRIEND)
        res_role = self._game.res_mgr.roles.get(self.data.rid)
        color = '#' + self._game.item_mgr.get_color(res_role.quality)
        content = fd_mail.content % dict(name=name, color=color)
        self._game.mail_mgr.send_mails(self.data.id, MAIL_REWARD, fd_mail.title,
                SOCIAL_MAIL_FRIEND, [], param=content)

    def social_online_info(self):
        return dict(name=self.data.name, level=self.data.level, rid=self.data.rid, id=self.data.id, st=1)

class PlayerActionMixin(
        ActionMixin,
        ActionSceneMixin,
        ActionLogMixin,
        ActionItemMixin,
        AllyMixin,
        ActionSocial,
        OtherMixin,
    ):
    pass

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
