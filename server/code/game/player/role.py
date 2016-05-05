#!/usr/bin/env python
# -*- coding:utf-8 -*-

import random

from corelib import log

from game import Game, pack_msg
from game.base.msg_define import MSG_ROLE_INVITE, MSG_MAIN_WEAR_EQUIP, MSG_RES_RELOAD
from game.store.define import TN_P_ROLE, FN_P_ATTR_KEY_ROLEUP
from game.store import StoreObj, GameObj, FN_KEY_ROLEUP
from game.base import errcode, common
from game.base.constant import (INIT_LEVEL, CANNOT_TRADE,
        ROLE_BACK_MAX, ROLE_BACK_MAX_V,
        QUALITY_GREEN,ROLETRAIN_COIN1_V,
        GREEN_ROLE_INIT_CMD, GREEN_ROLE_INIT_CMD_V,
        USED_NOT, USED_DO, IF_IDX_EID,
        ROLEUP_DAY_NUM, ROLEUP_DAY_NUM_V,
        ROLEUP_COST_ITEM, ROLEUP_COST_ITEM_V, ROLETRAIN_COIN1,
        ROLETRAIN_COIN2, ROLETRAIN_COIN2_V, ROLETRAIN_COST, ROLETRAIN_COST_V,
        ROLETRAIN_LOCKLEVEL, ROLETRAIN_LOCKLEVEL_V, IF_IDX_QUALITYS,
        )
from game.glog.common import ITEM_COST_INVITE, PL_ROLE, COIN_ROLEUP, COIN_ROLETARIN

from corelib.message import observable

#归队、离队状态
STATUS_COME = 1
STATUS_LEAVE = 0

#命格最高等级
FATE_LEVEL_MAX = 10

class PlayerRoles(object):
    """ 玩家配将管理类 """
    ROLE_INIT_CMDS = {
        QUALITY_GREEN: (GREEN_ROLE_INIT_CMD, GREEN_ROLE_INIT_CMD_V),
    }
    def __init__(self, player):
        if 0:
            from game.player.player import Player
            self.player = Player()
        self.player = player
        self.roles = {}
        self.rid2roles = {}
        self.main_role = None
        #保存武将随机培养值 {rid:attr}
        self.train_rand_data = None
        self.cls_init()

    setting_data = {}
    _sub_reloaded = False
    @classmethod
    def cls_init(cls):
        if cls._sub_reloaded:
            return
        cls._sub_reloaded = True
        Game.setting_mgr.sub(MSG_RES_RELOAD, cls.handle_setting)
        cls.handle_setting()

    @classmethod
    def handle_setting(cls):
        """ 处理修改资源表 """
        cls.setting_data = {}
        res_cost = Game.setting_mgr.setdefault(ROLEUP_COST_ITEM, ROLEUP_COST_ITEM_V)
        cls.setting_data[ROLEUP_COST_ITEM] = common.str2list(res_cost)
        #银币培养
        res_coin1 = Game.setting_mgr.setdefault(ROLETRAIN_COIN1, ROLETRAIN_COIN1_V)
        cls.setting_data[ROLETRAIN_COIN1] = common.str2dict2(res_coin1)
        #元宝培养
        res_coin2 = Game.setting_mgr.setdefault(ROLETRAIN_COIN2, ROLETRAIN_COIN2_V)
        cls.setting_data[ROLETRAIN_COIN2] = common.str2dict2(res_coin2)
        res_locklevel = Game.setting_mgr.setdefault(ROLETRAIN_LOCKLEVEL, ROLETRAIN_LOCKLEVEL_V)
        cls.setting_data[ROLETRAIN_LOCKLEVEL] = res_locklevel

    def uninit(self):
        self.player = None
        self.roles = {}
        self.rid2roles = {}
        self.main_role = None
        self.train_rand_data = None
        self.setting_data = {}

    def gm_add_num(self, num):
        """ gm改变升段次数 """
        for role in self.roles.itervalues():
            role.data.n = num
            role.modify()

    def load(self, querys=None):
        if querys is None:
            querys = dict(pid=self.player.data.id)
        roles = self.player._game.rpc_store.query_loads(TN_P_ROLE, querys)
        pass_day = self.player.play_attr.pass_day(FN_P_ATTR_KEY_ROLEUP)
        for r in roles:
            role = PlayerRole(self, adict=r)
            role.handle_roleup_data()
            if pass_day:
                role.pass_day()
            if role.is_main:
                self.main_role = role
            self.roles[role.data.id] = role
            self.rid2roles[role.data.rid] = role

    def load_used(self):
        querys = dict(pid=self.player.data.id)
        querys['status'] = STATUS_COME
        self.load(querys=querys)

    def save(self):
        store = self.player._game.rpc_store
        for r in self.roles.itervalues():
            r.save(store)

    def clear(self, clear_main=0):
        store = self.player._game.rpc_store
        for r in self.roles.itervalues():
            if not clear_main and r.is_main:
                continue
            r.delete(store)
        self.roles.clear()
        self.rid2roles.clear()
        if not clear_main and self.main_role:
            self.roles[self.main_role.data.id] = self.main_role
            self.rid2roles[self.main_role.data.rid] = self.main_role
        else:
            self.main_role = None

    def clear_attr(self):
        """ 清楚角色佩戴的命格和装备属性 """
        for role in self.roles.itervalues():
            for key, eid in role.iter_equips():
                if not eid:
                    continue
                setattr(role.data, key, 0)
                role.modify()
            for key, fid in role.iter_fates():
                if not fid:
                    continue
                setattr(role.data, key, 0)
                role.modify()

    def copy_from(self, roles, bag_items):
        """ 复制roles前,bag必须先复制好 """
        self.clear(clear_main=1)
        for r in roles.roles.itervalues():
            nr = PlayerRole(self, adict=r.data.to_dict())
            nr.data.id = None
            nr.data.pid = self.player.data.id
            nr.update_items(bag_items)
            nr.save(self.player._game.rpc_store)
        self.load()


    def __contains__(self, item):
        return item.data.id in self.roles

    def to_dict(self, used=0):
        if not used:
            return [r.to_dict() for r in self.roles.itervalues()]
        return [r.to_dict() for r in self.iter_come_back_roles()]

    def roles_to_dict(self, rids):
        data = []
        for r in self.roles.itervalues():
            if r.data.rid in rids:
                data.append(r.to_dict())
        return data

    def roles_bag_to_dict(self, rids):
        data = dict(equip = [], fate = [], gem = [])
        for rid in rids:
            role = self.get_role_by_rid(rid)
            if role is None:
                continue
            for key, fid in role.iter_fates():
                if not fid:
                    continue
                fate = self.player.bag.get_fate(fid)
                if fate is None:
                    continue
                data['fate'].append(fate.to_dict())
            for key, eid in role.iter_equips():
                if not eid:
                    continue
                equip = self.player.bag.get_equip(eid)
                if equip is None:
                    continue
                data['equip'].append(equip.to_dict())
                for gid in equip.data.gem.itervalues():
                    gem = self.player.bag.get_gem(gid)
                    if gem is None:
                        continue
                    data['gem'].append(gem.to_dict())
        return data

    def get_role(self, id):
        return self.roles.get(id)

    def iter_roles(self):
        return self.roles.itervalues()

    def get_role_by_rid(self, rid):
        return self.rid2roles.get(rid)

    def iter_fight_roles(self):
        """ 根据阵型,遍历角色 """
        pos = self.player.positions.get_active()
        if not pos:
            return
        for p, rid in pos.iter_rids():
            r = self.get_role_by_rid(rid)
            if not r or not r.is_come_back:
                continue
            yield r
    
#    def join_roles(self):
#        """ 获取参战角色人数 """
#        pos = self.player.positions.get_active()
#        if not pos:
#            return 1
#        num = 0
#        for p, rid in pos.iter_rids():
#            if not rid:
#                continue
#            num += 1
#        return num

    def iter_come_back_roles(self):
        """ 遍历归队的角色 """
        for r in self.roles.itervalues():
            if not r.is_come_back:
                continue
            yield r

    def get_role_by_rid(self, rid):
        return self.rid2roles.get(rid)

    @property
    def come_back_count(self):
        """ 归队人数 """
        return len([r for r in self.roles.itervalues() if r.is_come_back])

    def can_come_back(self):
        """ 是否可以执行配将归队 """
        return self.come_back_count < Game.setting_mgr.setdefault(ROLE_BACK_MAX,
                ROLE_BACK_MAX_V)

    def update_role(self, aRole):
        """ 角色更新 """
        aRole.modify()

    def del_role(self, rid, send_msg=0):
        """ 删除角色 """
        role = self.rid2roles.get(rid)
        if role is None:
            return 0, None
        if self.main_role == role:
            self.main_role = None
        self.roles.pop(role.data.id, None)
        self.rid2roles.pop(rid, None)
        eids, fids = role.delete_role(self.player)
        if send_msg:
            self.player.pack_msg_data(roles=[role], del_eids=eids,
                    del_fids=fids, send=1)
        return 1, (role, eids, fids)

    def can_add(self, rid):
        if rid in self.rid2roles:
            return False, errcode.EC_ROLE_MAIN_REP
        res_role = Game.res_mgr.roles.get(rid)
        if res_role is None:
            return False, errcode.EC_ROLE_NOFOUND
        if res_role.is_main and self.main_role is not None:
            return False, errcode.EC_ROLE_MAIN_REP
        return True, res_role

    def add_role(self, res_role):
        """ 添加配将,不检查合法性，需要外面调用can_add """
        role = PlayerRole(self)
        role.handle_roleup_data(res_role)
        role.data.rid = res_role.id
        role.data.sk = res_role.sk2
        if res_role.is_main:
            self.main_role = role
            role.come_back()
        elif self.can_come_back():
            role.come_back()

        role.save(self.player._game.rpc_store)
        self.roles[role.data.id] = role
        self.rid2roles[role.data.rid] = role

        #配将初始化
        if res_role.quality in self.ROLE_INIT_CMDS:
            n, cmd_v = self.ROLE_INIT_CMDS[res_role.quality]
            cmd = self.player._game.setting_mgr.setdefault(n, cmd_v)
            gm = self.player._gm_cmd(cmd % res_role.to_dict())
            news = gm.locals['equips']
            self.player.pack_msg_data(equips=news, send=1)
        self.player.pub(MSG_ROLE_INVITE, role.data.rid, self.player)
        return role

    def invite(self, rid, gm=False, pack_msg=True):
        """ 招募配将,
        失败抛出异常
        成功返回: role, uses
        """
        #rid资源必须存在,并且不能多次招募同一个rid
        rs, err = self.can_add(rid)
        if not rs:
            return False, err
        res_role = err
        if not res_role.is_main and not gm: #花费
            use_id, use_num = res_role.useId, res_role.useNum
            uses = self.player.bag.cost_item(use_id, use_num,
                    log_type=ITEM_COST_INVITE, pack_msg=pack_msg)
            if uses is None:
                return False, errcode.EC_COST_ERR
            _, _, items = uses
        else:
            items = {}
        self.player.log_normal(PL_ROLE, rid=rid)
        role = self.add_role(res_role)
        return role, items

    def _check_rid_fate(self, rid, fate1, fate2):
        """ 检测玩家是否穿此命格 """
        role = self.roles.get(rid)
        used = 0
        for key, fid in role.iter_fates():
            if fid == fate1.data.id or fid == fate2.data.id:
                used += 1
        if used and used == fate1.data.used + fate2.data.used:
            return True, None
        log.debug('check-rid-fate rid %s, fate1 %s, fate2 %s', rid, fate1.data.id, fate2.data.id)
        return False, errcode.EC_ROLE_WEARED

    def _merge_fate_exp(self, res_fate1, res_fate2, fate1, fate2):
        """ 经验命格的合并处理 """
        if res_fate1.is_exp_fate:
            update_fate = self._merge_fate_handle(fate1, fate2)
            return True, update_fate
        if res_fate2.is_exp_fate:
            update_fate = self._merge_fate_handle(fate2, fate1)
            return True, update_fate
        return False, None

    def _merge_fate_noexp(self, rid, res_fate1, res_fate2, fate1, fate2):
        """ 非经验命格的合并处理 """
        if rid:
            if res_fate1.quality > res_fate2.quality:
                best_id = fate1.data.id
            else:
                best_id = fate2.data.id
                #移动的命格未必使用且它的品质高时 判断是否重叠效果
            if fate2.data.used and not fate1.data.used and best_id == fate1.data.id:
                fate, res_fate = self.player.bag.get_fate_ex(fate1.data.id)
                tRole = self.roles.get(rid)
                if tRole._is_fate_repeat(self.player, res_fate):
                    return False, errcode.EC_ROLE_WEAR_REP
        #品质高的吞噬底的，品质相同时aFtId2吞噬aFtId1
        if res_fate1.quality > res_fate2.quality:
            update_fate = self._merge_fate_handle(fate2, fate1)
        else:
            update_fate = self._merge_fate_handle(fate1, fate2)
        return True, update_fate

    def merge_fate(self, fid1, fid2, rid=0):
        """ 命格合并(fid1移动到fid2) """
        if fid1 == fid2:
            return False, errcode.EC_FATE_NOMERGE
        fate1 = self.player.bag.get_fate(fid1)
        fate2 = self.player.bag.get_fate(fid2)
        if not fate1 or not fate2:
            return False, errcode.EC_FATE_NOFOUND
        if rid:
            rs, data = self._check_rid_fate(rid, fate1, fate2)
            if not rs:
                return rs, data
        item_mgr = self.player._game.item_mgr
        res_fate1 = item_mgr.get_res_fate(fate1.data.fid)
        res_fate2 = item_mgr.get_res_fate(fate2.data.fid)
        if res_fate1.is_exp_fate and res_fate2.is_exp_fate:
            return False, errcode.EC_MERGE_EXPS
        #经验命格的处理
        is_exp_merge, data = self._merge_fate_exp(res_fate1, res_fate2, fate1, fate2)
        if not is_exp_merge:
            #非经验命格的处理
            rs, data = self._merge_fate_noexp(rid, res_fate1, res_fate2, fate1, fate2)
            if not rs:
                return rs, data
        update_fate = data
        #合并完成后 对多种操作进行判断
        if rid:
            tRs = self._wear_fate_update(rid, fate1, fate2, update_fate.data.id)
            if tRs:
                tRole, data = tRs
                update_fate.data.used = data
                self.player.bag.update_fate(update_fate)
                self.update_role(tRole)
        del_id = fid2 if update_fate.data.id == fid1 else fid1
        return True, self.player.pack_msg_data(fates=[update_fate], del_fids=[del_id])

    def _wear_fate_update(self, aRid, aFate1, aFate2, aFtIdBest):
        """ 处理穿着命格合并的多种情况
            然会更新的配将和命格是否使用
        """
        tRole = self.roles.get(aRid)
        if not tRole:
            return None, errcode.EC_ROLE_NOFOUND
        tRoleWearFates = self._role_wear_fate_data(tRole)
        #全在身上
        if aFate1.data.used and aFate2.data.used:
            setattr(tRole.data, tRoleWearFates[aFate1.data.id], 0)
            if aFtIdBest == aFate1.data.id:
                setattr(tRole.data, tRoleWearFates[aFate2.data.id], aFate1.data.id)
            return tRole, USED_DO
        #将身上的移到背包里
        elif aFate1.data.used:
            setattr(tRole.data, tRoleWearFates[aFate1.data.id], 0)
            return tRole, USED_NOT
        #将背包里移到身上
        elif aFate2.data.used and aFtIdBest == aFate1.data.id:
            setattr(tRole.data, tRoleWearFates[aFate2.data.id], aFate1.data.id)
            return tRole, USED_DO
        return

    def _role_wear_fate_data(self, aRole):
        """ 将配将身上的命格存为字典{WearFateId1:FatePlace,...} """
        tDict = {}
        for tFatePlace, tWearFateId in aRole.iter_fates():
            if tWearFateId:
                tDict[tWearFateId] = tFatePlace
        return tDict

    def _merge_fate_handle(self, aFate1, aFate2):
        """ 命格合并：aFate2将aFate1吞噬(固定吞噬方向)"""
        #写入log
        self.player.log_merge_fate(ufate=aFate2.to_dict(), dfate=aFate1.to_dict())
        tResFateLevels = self.player._game.res_mgr.fate_level_by_fid.get(aFate2.data.fid)
        tExp = aFate1.data.exp + aFate2.data.exp
        #获取当前经验所在的等级
        tNeedExp = 0
        tLevel = 1
        max_exp = 0
        max_level = 0
        for tResFateLevel in tResFateLevels:
            if tResFateLevel.exp > max_exp:
                max_exp = tResFateLevel.exp
                max_level = tResFateLevel.level
            if tExp < tResFateLevel.exp :
                tMoreExp = tResFateLevel.exp
            else:
                continue
            if not tNeedExp or tMoreExp<tNeedExp:
                tNeedExp = tMoreExp
                tLevel = tResFateLevel.level - 1
        #如果无此值则说明合成的等级已经超过上限
        if not tNeedExp:
            tExp = max_exp
            tLevel = max_level
        aFate2.data.level = tLevel
        aFate2.data.exp = tExp
        if not aFate1.data.isTrade or not aFate2.data.isTrade:
            aFate2.data.isTrade = CANNOT_TRADE
        #删除吞噬掉的命格
        self.player.bag.del_fate(aFate1.data.id)
        self.player.bag.update_fate(aFate2)
        return aFate2

    def merge_all_fate(self):
        """ 命格一键合成 """
        #保存数据格式为{效果字段:{品质:tFate...}...}
        tEffDict = {}
        tDelFateIds = []
        tUpdateFatesDict = {}
        for tFate in self.player.bag.fates.values():
            if tFate.data.used or tFate.data.level == FATE_LEVEL_MAX:
                continue
            tResFate = self.player._game.item_mgr.get_res_fate(tFate.data.fid)
            tKeys = (tFate.data.fid, INIT_LEVEL+1)
            res_mgr = self.player._game.res_mgr
            #经验命格不处理
            if not res_mgr.fate_level_by_keys.has_key(tKeys):
                tUpdateFatesDict[tFate.data.id] = tFate.to_dict()
                continue
            if tEffDict.has_key(tResFate.effect):
                if tEffDict[tResFate.effect].has_key(tResFate.quality):
                    #相同影响效果且相同品质进行合并
                    tFateUp = self._merge_fate_handle(tFate, tEffDict[tResFate.effect][tResFate.quality])
                    if tFateUp:
                        tDelFateIds.append(tFate.data.id)
                        tUpdateFatesDict[tFateUp.data.id] = tFateUp.to_dict()
                else:
                    tEffDict[tResFate.effect][tResFate.quality] = tFate
            else:
                tEffDict[tResFate.effect] = {tResFate.quality:tFate}
        if tDelFateIds:
            return True, {'delFids':tDelFateIds, 'fate':tUpdateFatesDict.values()}
        return False, errcode.EC_FATE_NOMERGE

    def role_up_enter(self):
        """ 进入武将升段 """
        pass_day = self.player.play_attr.pass_day(FN_P_ATTR_KEY_ROLEUP)
        if pass_day:
            rid2updatens = {}
            for role in self.roles.itervalues():
                rid2updaten = role.pass_day()
                if rid2updaten:
                    rid2updatens.update(rid2updaten)
            if rid2updatens:
                return True, dict(update=rid2updatens)
        return True, None

    def role_train_do(self, rid, type):
        """ 武将培养 产生随机值 """
        if self.player.data.level < self.fetch_train_locklevel:
            return False, errcode.EC_ROLETRAIN_UNLOCK
        role = self.rid2roles.get(rid)
        if not role:
            return False, errcode.EC_VALUE
        cost = self.train_cost(type)
        coin1 = coin3 = 0
        if type == 0:
            res_add = self.fetch_train_coin1
            coin1 = cost
        else:
            res_add = self.fetch_train_coin2
            coin3 = cost
        if not self.player.enough_coin_ex(coin1, aCoin3=coin3):
            return False, errcode.EC_COST_ERR
        #产生随机值
        rs, data = self._random_train(rid, self.player.data.level, res_add)
        if not rs:
            return rs, data
        if not self.player.cost_coin_ex(coin1, aCoin3=coin3, log_type=COIN_ROLETARIN):
            return False, errcode.EC_COST_ERR
        self.train_rand_data = (rid, data)
        pack = self.player.pack_msg_data(coin=True)
        return rs, dict(radd=data, update=pack)

    def _random_train(self, rid, level, res_add):
        """ 随机产生培养 """
        res_role_level = self.player._game.res_mgr.get_role_level(int(rid), level)
        if not res_role_level:
            return False, errcode.EC_NORES
        t_data = {}
        for attr, (start, end) in res_add.iteritems():
            value = getattr(res_role_level, attr)
            start = value * int(start) * 0.01
            end = value * int(end) * 0.01
            r_num = random.randint(int(start), int(end))
            t_data[attr] = r_num
        return True, t_data

    def role_train_ok(self, rid):
        """ 保存培养 """
        if not self.train_rand_data:
            return False, errcode.EC_ROLETRAIN_NO
        train_rid, attr = self.train_rand_data
        if rid != train_rid:
            return False, errcode.EC_ROLETRAIN_NO
        role = self.rid2roles.get(rid)
        if not role:
            return False, errcode.EC_ROLE_NOFOUND
        role.train_save(attr)
        self.train_rand_data = None
        return True, None

    def train_cost(self, type):
        """ 培养消耗 """
        res_cost = self.player._game.setting_mgr.setdefault(ROLETRAIN_COST, ROLETRAIN_COST_V)
        res = common.str2list(res_cost)
        return res[type]

    @property
    def fetch_up_num(self):
        """ 获取每位武将每天能获得升段次数 """
        return self.player._game.setting_mgr.setdefault(ROLEUP_DAY_NUM, ROLEUP_DAY_NUM_V)

    @property
    def fetch_up_cost(self):
        """ 获取武将升段所需要的物品id """
        return PlayerRoles.setting_data.get(ROLEUP_COST_ITEM)

    @property
    def fetch_train_coin1(self):
        """ 银币培养 """
        return PlayerRoles.setting_data.get(ROLETRAIN_COIN1)

    @property
    def fetch_train_coin2(self):
        """ 元宝培养 """
        return PlayerRoles.setting_data.get(ROLETRAIN_COIN2)
    
    @property
    def fetch_train_locklevel(self):
        """ 培养解锁等级 """
        return PlayerRoles.setting_data.get(ROLETRAIN_LOCKLEVEL)

class PlayerRoleData(StoreObj):
    def init(self):
        """ 初始化对象属性 """
        self.id = None
        self.pid = 0
        self.rid = 0
        self.status = 0 #0=离队、1=归队
        self.sk = 0
        self.armLevel = 0
        self.eq1 = 0
        self.eq2 = 0
        self.eq3 = 0
        self.eq4 = 0
        self.eq5 = 0
        self.eq6 = 0
        self.fate1 = 0
        self.fate2 = 0
        self.fate3 = 0
        self.fate4 = 0
        self.fate5 = 0
        self.fate6 = 0
        self.fate7 = 0
        self.fate8 = 0
        self.q = 0      #品质
        self.g = 0      #段
        self.c = 0      #格
        self.n = 0    #每日升段数
        self.tr = {}  #培养加成


class PlayerRole(GameObj):
    TABLE_NAME = TN_P_ROLE
    DATA_CLS = PlayerRoleData
    FATE_RANGE = range(1, 9)
    FATE_ATTR = 'fate%d'
    EQ_RANGE = range(1, 7)
    EQ_ATTR = 'eq%d'
    def __init__(self, roles, adict=None):
        super(PlayerRole, self).__init__(adict=adict)
        self.roles = roles
        self.data.pid = roles.player.data.id
        if 0:
            self.roles = PlayerRoles()
            self.data = PlayerRoleData()

    @property
    def is_main(self):
        return self.roles.player.data.rid == self.data.rid

    @property
    def is_come_back(self):
        """ 是否归队状态 """
        return self.data.status == STATUS_COME

    @property
    def body_equip_id(self):
        """ 返回主将body基础装备id """
        equip = self.roles.player.bag.get_equip(self.data.eq2)
        return equip.data.eid if equip else 0

    def get_res_role(self):
        return self.roles.player._game.res_mgr.roles.get(self.data.rid)

    def get_res_role_level(self):
        player = self.roles.player
        return player._game.res_mgr.get_role_level(self.data.rid, player.data.level)

    def is_body_place(self, place):
        return place == 2 or place == '2'

    def leave(self):
        """ 离队 """
        self.data.status = STATUS_LEAVE
        self.modify()

    def come_back(self):
        """ 归队 """
        self.data.status = STATUS_COME
        self.modify()

    def iter_fates(self):
        for i in self.FATE_RANGE:
            key = self.FATE_ATTR % i
            yield key, getattr(self.data, key)

    def iter_equips(self):
        for i in self.EQ_RANGE:
            key = self.EQ_ATTR % i
            yield key, getattr(self.data, key)

    def get_fate(self, place):
        assert place in self.FATE_RANGE, ValueError('no found:%s' % place)
        return getattr(self.data, self.FATE_ATTR % place)

    def set_fate(self, place, value):
        """ place:int 或者 由iter_fates返回的属性名 """
        if isinstance(place, int):
            assert place in self.FATE_RANGE, ValueError('no found:%s' % place)
            setattr(self.data, self.FATE_ATTR % place, value)
        else:
            setattr(self.data, place, value)
        self.modified = True

    def get_equip(self, place):
        assert place in self.EQ_RANGE
        return getattr(self.data, self.EQ_ATTR % place)

    def set_equip(self, place, value):
        """ place:int 或者 由iter_equips返回的属性名 """
        if isinstance(place, int):
            assert place in self.EQ_RANGE, ValueError('no found:%s' % place)
            setattr(self.data, self.EQ_ATTR % place, value)
        else:
            setattr(self.data, place, value)
        self.modified = True

    def update_items(self, items):
        """ 更新新旧id """
        for key, eid in self.iter_equips():
            if not eid:
                continue
            self.set_equip(key, items.get(eid, 0))
        for key, fid in self.iter_fates():
            if not fid:
                continue
            self.set_fate(key, items.get(fid, 0))

    def take_off_equips(self, bag=None):
        """ 脱所有装备 """
        modified = False
        for key, eid in self.iter_equips():
            if not eid:
                continue
            modified = True
            if bag:
                equip = bag.get_equip(eid)
                equip.data.used = USED_NOT
                equip.modify()
            setattr(self.data, key, 0)
        if modified:
            self.modify()

    def wear_equip(self, player, equip, res_equip, pack_msgd=1):
        """ 穿装备 """
        uid = self.get_equip(res_equip.part)
        if uid == equip.data.id:
            return False, errcode.EC_VALUE
        if equip.data.used:
            return False, errcode.EC_EQUIP_NOUSE
        if uid:
            rs, off_equip = self.take_off_equip(player, res_equip.part, forced=1)
            if not rs:
                off_equip = None
        else:
            off_equip = None
        self.set_equip(res_equip.part, equip.data.id)
        equip.data.used = USED_DO
        if off_equip:
            player.bag.update_equip(equip)
        else:
            player.bag.update_equip(equip, used_count=-1)
        self.modified = True
        if self.is_main:
            if self.is_body_place(res_equip.part): #主将换装
                player.update_scene_info({IF_IDX_EID:res_equip.id})
            #监听主将传装备
            player.safe_pub(MSG_MAIN_WEAR_EQUIP, self, equip, res_equip)
        if pack_msgd:
            resp_f = 'wearEq'
            data = dict(id=equip.data.id, rid=self.data.id)
            if off_equip:
                data['uid'] = uid
            return True, (off_equip, pack_msg(resp_f, 1, data=data))
        return True, off_equip

    def take_off_equip(self, player, place, forced=0):
        """ 脱装备 """
        if not forced and player.bag.bag_free() <= 0:
            return False, errcode.EC_BAG_FULL
        uid = self.get_equip(place)
        equip = player.bag.get_equip(uid)
        if equip is None:
            return False, errcode.EC_VALUE
        self.set_equip(place, 0)
        equip.data.used = USED_NOT
        player.bag.update_equip(equip, used_count=1)
        self.modified = True
        if self.is_main and self.is_body_place(place): #主将换装
            player.update_scene_info({IF_IDX_EID:0})
        return True, equip

    def take_off_fate(self, player, fate, place):
        """ 脱命格 """
        if player.bag.bag_free() <= 0:
            return False, errcode.EC_BAG_FULL
        fid = self.get_fate(place)
        if fid != fate.data.id:
            return False, errcode.EC_VALUE
        self.set_fate(place, 0)
        fate.data.used = USED_NOT
        player.bag.update_fate(fate, used_count=1)
        return True, None

    def _is_fate_repeat(self, player, res_fate, use_fid=0):
        """ 命格影响属性是否叠加(如果是移动则将原来位置改为零) """
        for place_key, fid in self.iter_fates():
            if not fid:
                continue
            if use_fid and fid == use_fid:
                self.set_fate(place_key, 0)
                return False
            f, res_f = player.bag.get_fate_ex(fid)
            if res_f is None:
                self.set_fate(place_key, 0)
                continue
            if res_f.effect == res_fate.effect:
                return True
        return False

    def _is_wear_fate(self, id):
        """ 是否已被该角色穿戴 """
        for place_key, fid in self.iter_fates():
            if fid == id:
                return True
        return False

    def wear_fate(self, player, fate, res_fate, place):
        """ 穿命格,还包括移动位置 """
        tKeys = (fate.data.fid, INIT_LEVEL+1)
        #经验命格不处理
        if not player._game.res_mgr.fate_level_by_keys.has_key(tKeys):
            return False, errcode.EC_EXP_FATE
        used = fate.data.used
        if fate.data.used:
            rs = self._is_wear_fate(fate.data.id)
            if not rs:
                return False, errcode.EC_ROLE_WEARED
        #该部位是否已佩戴命格
        w_fid = self.get_fate(place)
        if w_fid and w_fid in player.bag.fates:
            return False, errcode.EC_ROLE_PART_USED
        rs = self._is_fate_repeat(player, res_fate, use_fid=fate.data.id)
        if rs:
            return False, errcode.EC_ROLE_WEAR_REP
        fate.data.used = USED_DO
        if not used:
            player.bag.update_fate(fate, used_count=-1)
        else:
            player.bag.update_fate(fate)
        self.set_fate(place, fate.data.id)
        return True, None

    def delete_role(self, player):
        """ 删除配将 """
        #TODO: 删除角色,穿戴的如何处理?, 先一起删除
        eids = [eid for key,eid in self.iter_equips() if eid]
        eids = player.bag.del_equips(eids)
        fids = [fid for key,fid in self.iter_fates() if fid]
        fids = player.bag.del_fates(fids)
        self.delete(player._game.rpc_store)
        return eids, fids

    def handle_roleup_data(self, res_role=None):
        """ 处理武将升段数据 """
        if self.data.g:
            return
        res_mgr = self.roles.player._game.res_mgr
        if res_role is None:
            rid = self.data.rid
            res_role = res_mgr.roles.get(rid)
        else:
            rid = res_role.id
        #该配将是否可升段
        if not res_mgr.roleup_type_by_rid.get(rid):
            return
        self._new_roleup_data(res_role)

    def pass_day(self):
        """ 处理超过一天 """
        if self.data.n == self.roles.fetch_up_num:
            return
        self.data.n = self.roles.fetch_up_num
        return {str(self.data.id):self.data.n}

    def _new_roleup_data(self, res_role):
        """ 创建武将升段数据 """
        self.data.q = res_role.quality
        self.data.g = 1
        self.data.c = 0
        self.data.n = self.roles.fetch_up_num
        self.modify()
    
    def role_up_do(self):
        """ 武将升段 """
        player = self.roles.player
        if self.data.n <= 0:
            return False, errcode.EC_ROLEUP_ERR_NUM
        #处理升段
        rs, data = self._handle_roleup()
        if not rs:
            return rs, data
        #物品消耗
        iid, num = self.roles.fetch_up_cost
        rs_cost = player.bag.cost_item(iid, num, log_type=COIN_ROLEUP, pack_msg=True)
        if rs_cost is None:
            return False, errcode.EC_ITEM_NOFOUND
        old_q = self.data.q
        #成功消耗物品后升级
        self.data.c, self.data.g, self.data.q, _ = data
        if old_q != self.data.q:
            player.update_scene_info({IF_IDX_QUALITYS:self.data.q})
        _, _, pack = rs_cost
        self.data.n -= 1
        self.modify()
        return True, dict(update=pack, c=self.data.c, g=self.data.g, q=self.data.q, n=self.data.n)

    def _handle_roleup(self):
        """ 处理升段 """
        player = self.roles.player
        roleup_type = player._game.res_mgr.roleup_type_by_rid.get(self.data.rid)
        if not roleup_type:
            return False, errcode.EC_NORES
        key = [self.data.c, self.data.g, self.data.q, roleup_type]
        next = None
        num = len(key) - 1
        for i in xrange(num):
            key[i] += 1
            for j in xrange(i):
                key[j] = 1
            next = player._game.res_mgr.roleup_by_keys.get(tuple(key))
            if next:
                break
        if not next:
            return False, errcode.EC_ROLEUP_MAX
        return True, key

    def train_save(self, attr):
        """ 保存培养值 """
        self.data.tr = attr
        self.modify()

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
