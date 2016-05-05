#!/usr/bin/env python
# -*- coding:utf-8 -*-

import copy
import json
from random import randint
from functools import partial
from types import CodeType

from corelib import log

from game.base.msg_define import MSG_RES_RELOAD
from game.base.constant import (
    TRADE_IDX, NOTRADE_IDX, GEM_INIT_LEVEL,
    IKEY_TYPE, IKEY_ID, IKEY_IDS, IKEY_QUALITY, IKEY_EQSET, IKEY_GROUP, IKEY_COUNT, IKEY_TRADE, IKEY_LEVEL,
    IT_ITEM_STR, IT_EQUIP_STR, IT_FATE_STR, IT_CAR_STR, IT_ROLE_STR, IT_GEM_STR,
    DIFF_TITEM_IDS,DIFF_TITEM_SITE_TIME, DIFF_TITEM_ARMEXP, DIFF_TITEM_TBOX,
    DIFF_TITEM_COIN1, DIFF_TITEM_COIN2, DIFF_TITEM_COIN3, DIFF_TITEM_EXP,
)
from game.base.common import RandomRegion, make_lv_regions

from game import Game
from game.store import GameObj
from game.res.item import ResReward

def rom(*args):
    """ rom((<count>,<rate>), (1,10), (2,25)) """
    return RandomRegion(args)

def ran(start, end):
    return partial(randint, start, end)

_evals = dict(rom=rom, ran=ran)

_default_item = dict(t=None, i=0, c=0, tr=0)
def merge_reward_items(sitems, ditems):
    """ 合并奖励物品列表, 暂时不考虑是否可交易的区别 """
    sd = dict(((v[IKEY_TYPE], v[IKEY_ID]), v) for v in sitems)
    dd = dict(((v[IKEY_TYPE], v[IKEY_ID]), v) for v in ditems)
    for k, v in sd.iteritems():
        if k not in dd:
            default = _default_item.copy()
            default[IKEY_TYPE] = k[0]
            default[IKEY_ID] = k[1]
            dv = dd[k] = default
        else:
            dv = dd[k]
        c = int(dv[IKEY_COUNT]) if IKEY_COUNT in dv else 1
        dv[IKEY_COUNT] = c + (int(v[IKEY_COUNT]) if IKEY_COUNT in v else 1)
    return dd.values()

class RewardItems(object):
    """ 奖励后获取的物品类 """
    def __init__(self, items=None):
        if items is None:
            self.rwitems = []
            self.init()
        else:
            self.rwitems = items
            self.parse()

    def add_special_item(self, _id, count):
        #特殊物品处理id(1=银币，2=元宝，3=绑定元宝，4=经验，5=打坐时间, 6=练历)
        if _id == DIFF_TITEM_COIN1:
            self.coin1 += count
        elif _id == DIFF_TITEM_COIN2:
            self.coin2 += count
        elif _id == DIFF_TITEM_COIN3:
            self.coin3 += count
        elif _id == DIFF_TITEM_EXP:
            self.exp += count
        elif _id == DIFF_TITEM_SITE_TIME:
            self.site_times += count
        elif _id == DIFF_TITEM_ARMEXP:
            self.train += count
        elif _id == DIFF_TITEM_TBOX:
            self.tbox.append(count)

    def init(self):
        self.items = {}
        self.equips = []
        self.fates = []
        self.cars = []
        self.roles = []
        self.coin1 = 0
        self.coin2 = 0
        self.coin3 = 0
        self.exp = 0
        self.site_times = 0
        self.train = 0
        self.tbox = []
        self.gem = []

    def parse(self):
        """ 分析 """
        self.init()
        for item in self.rwitems:
            t, _id = item[IKEY_TYPE], item[IKEY_ID]
            c = item.get(IKEY_COUNT, 1)
            tr = item.get(IKEY_TRADE, 0)
            if t == IT_ITEM_STR:
                if _id in DIFF_TITEM_IDS:
                    self.add_special_item(_id, c)
                else:
                    items = self.items.setdefault(_id, [0, 0])
                    if tr:
                        items[TRADE_IDX] += c
                    else:
                        items[NOTRADE_IDX] += c
            elif t == IT_EQUIP_STR:
                self.equips.append((_id, c, tr))
            elif t == IT_FATE_STR:
                self.fates.append((_id, c, tr))
            elif t == IT_ROLE_STR:
                self.roles.append(_id)
            elif t == IT_CAR_STR:
                self.cars.append(_id)
            elif t == IT_GEM_STR:
                lv = GEM_INIT_LEVEL
                if IKEY_LEVEL in item:
                    lv = item[IKEY_LEVEL]
                self.gem.append((_id, c, lv))

    def merge(self, items, parse=True):
        """ 合并 """
        self.rwitems = merge_reward_items(items, self.rwitems)
        if parse:
            self.parse()

    def get_price(self):
        """获得道具、装备、命格的总售价"""
        coin1 = 0
        for _id, data in self.items.iteritems():
            item = Game.item_mgr.get_res_item(_id)
            c = data[TRADE_IDX] + data[NOTRADE_IDX]
            coin1 += item.price * c
        for data in self.equips:
            _id = data[0]
            c = data[1]
            equip = Game.item_mgr.get_res_equip(_id)
            coin1 += equip.price * c
        for data in self.fates:
            _id = data[0]
            c = data[1]
            fate = Game.item_mgr.get_res_fate(_id)
            coin1 += fate.price * c
        return coin1


class RWNode(object):
    @staticmethod
    def new(alist, name=None):
        if not len(alist):
            return RWNode()
        adict = alist[0]
        if IKEY_GROUP in adict:
            return RWGroup(alist, name)
        elif IKEY_TYPE in adict:
            return RWItems(alist, name)

    def __init__(self, name):
        self.name = name

    def reward(self, params):
        """ 获取奖励 """

class RWGroup(RWNode):
    """ 分组 """
    def __init__(self, alist, name):
        super(RWGroup, self).__init__(name)
        self.regions = []
        for index, adict in enumerate(alist):
            name = '%s.%d' % (self.name, index) if self.name is not None else str(index)
            obj = self.new(adict[IKEY_ID], name=name)
            item = ((index, obj), int(adict[IKEY_GROUP]))
            self.regions.append(item)
        self.ran_region = RandomRegion(self.regions)

    def reward(self, params):
        """ 获取奖励 """
        item = self.ran_region.random()[1]
        return item.reward(params)

class RWItems(RWNode):
    """ 物品 """
    SET_RANS = {}
    def __init__(self, alist, name):
        super(RWItems, self).__init__(name)
        self.items = alist
        self.rans = {}
        self.randoms = {}
        self.ids = {}
        self.sets = {}
        for index, item in enumerate(self.items):
            if IKEY_IDS in item:
                self.ids[index] = self._op_ids(item.pop(IKEY_IDS))
            self._count_process(item, index)
            self._id_process(item, index)
            #if isinstance(item[IKEY_COUNT], (str, unicode)):
            #    c = self._count_obj(item[IKEY_COUNT])
            #    if isinstance(c, int):
            #        item[IKEY_COUNT] = int(c)
            #    else:
            #        self.randoms[index] = c
            if IKEY_EQSET in item:
                self.sets[index] = self._op_sets(item.pop(IKEY_EQSET))

    def _count_process(self, item, index):
        """IKEY_COUNT的处理"""
        if isinstance(item[IKEY_COUNT], (str, unicode)):
            c = self._count_obj(item[IKEY_COUNT])
            if isinstance(c, int):
                item[IKEY_COUNT] = int(c)
            else:
                self.randoms[index] = c

    def _id_process(self, item, index):
        """IKEY_ID的处理"""
        if IKEY_ID in item and isinstance(item[IKEY_ID], (str, unicode)):
            c = self._count_obj(item[IKEY_ID])
            if isinstance(c, int):
                item[IKEY_ID] = int(c)
            else:
                self.rans[index] = c

    def _op_sets(self, sets):
        if isinstance(sets, int):
            return sets
        sets = tuple(sets)
        rfunc = self.SET_RANS.get(sets)
        if rfunc is None:
            res_mgr = Game.res_mgr
            lv_sids = []
            for sid in sets:
                s = res_mgr.equip_sets.get(sid)
                if s is None:
                    raise ValueError(u'[奖励%s]配置中,套装(%s)找不到' % (self.items, sid))
                lv_sids.append((s.lv, sid))
            rfunc = make_lv_regions(lv_sids)
            self.SET_RANS[sets] = rfunc
        return rfunc

    def _op_ids(self, ids):
        try:
            return make_lv_regions(ids)
        except Exception as e:
            raise ValueError(u'[奖励%s]ids(%s)配置错误:%s' % (self.items, ids, e))

    def _count_obj(self, data):
        if data.strip() == '':
            return 0
        try:
            return int(data)
        except ValueError:#rom, ran
            try:
                obj = eval(data)
                return obj
            except NameError:#公式
                return compile(data, 'c', 'eval')

    def reward(self, params):
        """ 获取奖励 """
        items = copy.deepcopy(self.items)
        item_mgr = Game.item_mgr
        if params is None:
            gparams = None
            lv = 1
        else:
            lv = params.get('level', 1)
            gparams = params.copy()

        for index, item in enumerate(items):
            if index in self.randoms:
                r = self.randoms[index]
                if callable(r):
                    item[IKEY_COUNT] = int(r())
                else:
                    item[IKEY_COUNT] = int(eval(r, gparams))
            if IKEY_ID in item and index in self.rans:
                r = self.rans[index]
                if callable(r):
                    item[IKEY_ID] = int(r())
                else:
                    item[IKEY_ID] = int(eval(r, gparams))
            #确定id
            if IKEY_QUALITY in item:
                quality = int(item[IKEY_QUALITY])
                #命格
                if item[IKEY_TYPE] == IT_FATE_STR:
                    item[IKEY_ID] = item_mgr.new_fate_id_by_quality(quality)
                #珠宝
                elif item[IKEY_TYPE] == IT_GEM_STR:
                    item[IKEY_ID] = item_mgr.new_gem_id_by_quality(quality)
                item.pop(IKEY_QUALITY)
            #套装
            elif index in self.sets:
                r = self.sets[index]
                sid = r(lv) if callable(r) else int(r)
                item[IKEY_ID] = item_mgr.new_equip_id_by_set(sid)
            #等级范围
            elif index in self.ids:
                r = self.ids[index]
                item[IKEY_ID] = r(lv)
        return self.name, items


class Reward(GameObj):
    TABLE_NAME = None
    DATA_CLS = ResReward

    @classmethod
    def new_by_res(cls, res_reward):
        o = cls()
        o.data = res_reward
        return o

    def __init__(self, adict=None):
        super(Reward, self).__init__(adict=adict)
        self.counts = {} #统计数据
        if 0:
            self.data = ResReward()

    def parse(self):
        """ 预解释奖励字符串
        奖励(reward, str)
	    [{g:<概率(int)>,i:<分组或物品>},...]
	    <分组>定义:[{g:<概率(int)>,i:<>}, ...]
		分组支持嵌套
	    <物品>定义:[{t:<type>,i:<id>,c:<count>,t:<canTrade>}, ...]
		<type>=物品类型(物品=i, 装备=e, 命格=f, 坐骑=c, 珠宝=g)
        """
        try:
            self.rewards = None
            if not self.data.reward:
                return
            #log.debug('rewards=====[%s]', self.data.reward)
            rewards = json.loads(self.data.reward)
            self.rewards = RWNode.new(rewards)
        except Exception as err:
            log.log_except(u'奖励记录(%d, %s)错误:%s', self.data.id, self.data.reward, err)

    def reward(self, params, back_name=False):
        """ 获取奖励 """
        if self.rewards is None:
            return []
        name, items = self.rewards.reward(params)
        #下面记录的信息暂时没用,先屏蔽掉
#        self.counts.setdefault(name, 0)
#        self.counts[name] += 1
        if back_name:
            return name, items
        return items

    def clear(self):
        """ 清除统计数据 """
        self.counts.clear()


class RewardMgr(object):
    def __init__(self):
        self.rewards = {}

    def start(self):
        """ 预处理 """
        Game.res_mgr.sub(MSG_RES_RELOAD, self.init)
        #self.init()

    def init(self):
        self.rewards.clear()
#        for rid in Game.res_mgr.rewards.iterkeys():
#            self.get(rid)


    def get(self, rid):
        try:
            return self.rewards[rid]
        except KeyError:
            res_reward = Game.res_mgr.rewards.get(rid)
            if not res_reward:
                self.rewards[rid] = None
                return
            rw = Reward.new_by_res(res_reward)
            rw.parse()
            self.rewards[res_reward.id] = rw
            return rw


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
