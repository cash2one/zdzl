#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game import grpc_monitor

from corelib import log
from game.base.common import str2dict, str2dict2

from game.base.constant import ALL_PROPS, CALC_CBE, CALC_CBE_V, \
    CBE_FIX_TAG, CALC_PROP_ARGS, CALC_PROP_ARGS_V, PASS_PROP_ARGS, DATA_TYPE_KEY, DATA_TYPE_KEY_V
from game.base.constant import (
    PROP_STR, PROP_DEX, PROP_VIT, PROP_INT, PROP_HP, PROP_ATK, PROP_STK,
    PROP_DEF, PROP_SPD, PROP_MP, PROP_MPS, PROP_MPR, PROP_HIT, PROP_MIS,
    PROP_BOK, PROP_COT, PROP_COB, PROP_CRI, PROP_CPR, PROP_PEN, PROP_TUF,
    )
from game.store.define import FN_P_ATTR_CBE, FN_P_ATTR_CBES

class BaseProperty(object):
    """ 基础属性类 """
    def __init__(self):
        self.init()

    def init(self):
        for k in ALL_PROPS:
            setattr(self, k, 0)

    def add_prop(self, prop, filters=None):
        if not filters:
            filters = ALL_PROPS
        for k in filters:
            v = getattr(prop, k, 0)
            if not v:
                continue
            setattr(self, k, v + getattr(self, k))

    def add_dict(self, adict):
        """ 增加字典中的内容 """
        for k,v in adict.iteritems():
            if k not in ALL_PROPS:
                continue
            setattr(self, k, v + getattr(self, k))

class RoleProperty(BaseProperty):
    def __init__(self):
        super(RoleProperty, self).__init__()

class PlayerProperty(object):
    """ 玩家属性类 """
    def __init__(self, player):
        self.roles = {}
        self.player = player
        self.CBE = 0
        self.CBES = {} #rid:CBE

    def uninit(self):
        self.player = None
        self.roles = {}
        self.CBES = {} #rid:CBE

    @grpc_monitor
    def calc(self):
        """ 计算玩家属性,计算战力 """
        self.roles.clear()
        for role in self.player.roles.iter_roles():
            prop = self._calc_role(role)
            self.roles[role.data.rid] = prop

    def join_war_data(self):
        """ 当前启用阵型数据 """
        join_nums = 0
        max_atk = 0
        for role in self.player.roles.iter_fight_roles():
            join_nums += 1
            prop = self.roles.get(role.data.rid)
            if prop is None:
                prop = self._calc_role(role)
                self.roles[role.data.rid] = prop
            if not prop.ATK or prop.ATK > max_atk:
                max_atk = prop.ATK
        return join_nums, max_atk


    def _calc_base(self, res, calc_args, is_all=True):
        """基础数据加工"""
        data = {}
        if res is None:
            return data
        for k in ALL_PROPS:
            res_v = getattr(res, k)
            if res_v is None:
                continue
            data.setdefault(k, 0)
            if not is_all and k in PASS_PROP_ARGS:
                continue
            data[k] += res_v
            #数据加工 体魄 影响 生命，防御
            if k not in calc_args:
                continue
            args = calc_args[k]
            for attr, arg in args.iteritems():
                if attr in data:
                    data[attr] += res_v * arg
                else:
                    data[attr] = res_v * arg
        return data

    def _calc_base_dict(self, adict, calc_args):
        """基础数据加工"""
        data = {}
        if adict is None:
            return data
        for k, v in adict.iteritems():
            data[k] = v
            #数据加工 体魄 影响 生命，防御
            if k not in calc_args:
                continue
            args = calc_args[k]
            for attr, arg in args.iteritems():
                if attr in data:
                    data[attr] += v * arg
                else:
                    data[attr] = v * arg
        return data

    def get_calc_args(self, role, calc_args):
        """获得属性计算参数 VIT:HP:DEF --> {VIT:{HP:0.1, DEF:1}}"""
        data = {}
        res = role.get_res_role_level()
        if res is None:
            log.error('get_calc_args res is None pid(%s) rid(%s) level(%s)',
                self.player.data.id, role.data.rid, self.player.data.level)
            return data
        for k in calc_args:
            _data = {}
            for n in calc_args[k]:
                v = getattr(res, n)
                if v is None:
                    continue
                _data[n] = v
            data[k] = _data
        return data

    @grpc_monitor
    def _calc_role(self, role):
        """ 计算角色属性 """
        prop = RoleProperty()
        setting = self.player._game.setting_mgr
        item_mgr = self.player._game.item_mgr
        res_mgr = self.player._game.res_mgr
        bag = self.player.bag

        calc_args = setting.setdefault(CALC_PROP_ARGS, CALC_PROP_ARGS_V)
        calc_args = str2dict2(calc_args)
        calc_args = self.get_calc_args(role, calc_args)

        #角色基础属性
        res_role_level = role.get_res_role_level()
        if res_role_level:
            role_level = self._calc_base(res_role_level, calc_args, is_all=False)
            prop.add_dict(role_level)

        #武器(宝具)
        r = res_mgr.roles.get(role.data.rid)
        if r:
            key = (r.armId, role.data.armLevel)
            res_arm_leve = res_mgr.arm_level_by_keys.get(key)
            arm_leve = self._calc_base(res_arm_leve, calc_args)
            prop.add_dict(arm_leve)

        #装备
        suit = {}  #套装
        for _, eid in role.iter_equips():
            equip, res_equip = bag.get_equip_ex(eid)
            if not res_equip:
                continue
            #基础
            base_equip = self._calc_base(res_equip, calc_args)
            prop.add_dict(base_equip)
            #珠宝
            for gid in equip.data.gem.itervalues():
                gem = self.player.bag.get_gem(gid)
                if gem is None:
                    continue
                key = (gem.data.gid, gem.data.level)
                res_gem_level = self.player._game.res_mgr.gem_levels.get(key)
                if res_gem_level is None:
                    continue
                prop_gem = self._calc_base(res_gem_level, calc_args)
                prop.add_dict(prop_gem)

            #强化
            if equip.data.level > 0:
                res_equip_level = item_mgr.get_res_equip_level(
                    res_equip.part, equip.data.level)
                equip_level = self._calc_base(res_equip_level, calc_args)
                prop.add_dict(equip_level)
            #套装
            suit.setdefault(res_equip.sid, 0)
            suit[res_equip.sid] += 1
        for sid, num in suit.iteritems():
            res = res_mgr.equip_sets.get(sid)
            if res is None:
                continue
            effect = res.get_effect(num)
            if effect is None:
                continue
            effect = self.str2dict1(effect, ktype=str, vtype=float)
            if effect is None:
                continue
            effect = self._calc_base_dict(effect, calc_args)
            prop.add_dict(effect)

        #命格
        for _, fid in role.iter_fates():
            fate, res_fate = bag.get_fate_ex(fid)
            if not res_fate:
                continue
            res_fate_level = item_mgr.get_res_fate_level(res_fate.id,
                fate.data.level)
            fate_level = self._calc_base(res_fate_level, calc_args)
            prop.add_dict(fate_level)

        #阵型
        position = self.player.positions.get_active()
        position_level = None
        if position:
            key = (position.data.posId, position.data.level)
            position_level = res_mgr.position_levels.get(key)
        if position_level:
            for pos, rid in position.iter_rids():
                if rid != role.data.rid:
                    continue
                n = position.POS_TMP % pos
                attrs = getattr(position_level, n)
                if attrs:
                    attrs = self.str2dict1(attrs, ktype=str, vtype=float)
                    attrs = self._calc_base_dict(attrs, calc_args)
                    prop.add_dict(attrs)
        return prop

    def str2dict1(self, s, ktype=str, vtype=float):
        """ k:v|k1:v|...
        返回: {k:v, k1:v, ... }
        """
        s = s.strip()
        if not s:
            return
        datas = s.strip().split('|')
        d = {}
        for data in datas:
            r = data.strip().split(':')
            k = ktype(r[0])
            v = vtype(r[1])
            if d.has_key(k):
                d[k] += v
            else:
                d[k] = v
        return d

    def update_CBE(self):
        self.calc()
        self.calc_CBE()
        #if self.CBE != self.player.play_attr.CBE:
        self.player.play_attr.update_attr({
            FN_P_ATTR_CBE: self.CBE,
            FN_P_ATTR_CBES: dict((str(k), v)
                    for k,v in self.CBES.iteritems())
            })


    def calc_CBE(self):
        """计算总战力"""
        self.CBE = 0
        self.CBES.clear()
        #只计算上阵人数
        position = self.player.positions.get_active()
        if position is None:
            return
        for pos, rid in position.iter_rids():
            prop = self.roles.get(rid)
            if prop is None:
                continue
            self.CBES[rid] = self._calc_CBE(prop)
            self.CBE += self.CBES[rid]

    def _calc_CBE(self, prop):
        """计算角色战力
            战斗力 =
                勇力*0.8 + 迅捷*2 + 体魄*2
              + 智略*0.7 + 攻击*0.5 + 防御*2
              + 速度*2 + 生命/5+ （命中率—95）*100
              + 回避率*200 + 格挡率*200 + 反击率*200
              + 暴击率*50 +爆伤率*50 + 破甲率*50
              + 免伤率*100 + 连击率*100
        """
        CBE = 0
        setting = self.player._game.setting_mgr
        data = setting.setdefault(CALC_CBE, CALC_CBE_V)
        data = str2dict(data, ktype=str, vtype=float)
        type_data = setting.setdefault(DATA_TYPE_KEY, DATA_TYPE_KEY_V)
        setting_type = str2dict2(type_data)
        for k, v in data.iteritems():
            if CBE_FIX_TAG in k:
                CBE += v
                continue
            if setting_type.has_key(k) and len(setting_type[k]) > 1:
                value = float(getattr(prop, k, 0))
            else:
                value = int(getattr(prop, k, 0))
            CBE += value * v
        return int(CBE)

