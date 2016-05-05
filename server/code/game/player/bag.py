#!/usr/bin/env python
# -*- coding:utf-8 -*-

import math
import copy
from itertools import chain

from corelib import log, json

from game import pack_msg, Game
from game.glog.common import (ITEM_FETCH_EMAIL, ITEM_FETCH_HITFATE, ITEM_SELL,
        COIN_ADD_ITEM, COIN_ADD_SELL, ITEM_FETCH_TIMEBOX, TRAIN_BAG)
from game.base.constant import (IT_CAR_STR, IT_EQUIP_STR, IT_FATE_STR, IT_ITEM_STR, IT_GEM_STR,
        IT_ROLE_STR, TRADE_IDX, NOTRADE_IDX,
        IKEY_COUNT, IKEY_ID, IKEY_TRADE, IKEY_TYPE,
        DIFF_TITEM_IDS, INIT_LEVEL, FATE_INIT_LEVEL,
        DIFF_TITEM_COIN1, DIFF_TITEM_COIN2, DIFF_TITEM_COIN3, DIFF_TITEM_EXP,
        DIFF_TITEM_SITE_TIME, DIFF_TITEM_ARMEXP, DIFF_TITEM_TBOX,
        BAG_SIZE, BAG_SIZE_V, PLAYER_ATTR_TBOX,
        WAITBAG_TYPE_HITFATE, WAITBAG_TYPE_EMAIL,
        WAITBAG_TYPE_TIMEBOX, PT_CH, PT_WAITS, PT_FT, PLAYER_ATTR_HITFATE
)
from game.base import errcode, common, msg_define
from game.store.define import TN_P_EQUIP, TN_P_ITEM, TN_P_FATE, TN_P_CAR, TN_P_WAIT, TN_P_TBOX, TN_P_GEM
from game.store import StoreObj, GameObj
from game.item.equip import Equip
from game.item.item import Item
from game.item.fate import Fate
from game.item.car import Car
from game.item.reward import RewardItems
from game.item.gem import Gem


class BagItems(object):
    def __init__(self, bag):
        self.bag = bag
        self.items = []
        self.equips = []
        self.fates = []
        self.cars = []
        self.roles = []
        self.gem = []
        #self.coin = False
        self.exp = 0
        self.train = 0
        self.tbox = False
        self.coin1 = 0
        self.coin2 = 0
        self.coin3 = 0
        self.reward_items = None

    def init(self, **kw):
        for k,v in kw.iteritems():
            setattr(self, k, v)

    def pack_msg(self, **kw):
        """ 打包成消息 """
        pack_rwitems = kw.pop('rwitems', False)
        coin = kw.pop('coin', False) or self.coin
        exp = kw.pop('exp', False) or self.exp
        train = kw.pop('train', False) or self.train
        data = self.bag.player.pack_msg_data(items=self.items, equips=self.equips,
            fates=self.fates, cars=self.cars, roles=self.roles, gem = self.gem,
            coin=coin, exp=exp, train=train,
            **kw)
        if self.tbox:
            data['tbox'] = True
        if pack_rwitems:
            data['rwitems'] = self.reward_items if self.reward_items else []
        return data

    def iter_all_items(self):
        objs = [self.items, self.equips, self.fates]
        while objs:
            alist = objs.pop(0)
            if alist is None:
                continue
            for i in alist:
                yield i

    @property
    def coin(self):
        return bool(self.coin1 or self.coin2 or self.coin3)

    def add_coin(self, coin1, coin2, coin3):
        self.coin1 += coin1
        self.coin2 += coin2
        self.coin3 += coin3

class Bag(object):
    """ 玩家物品列表管理类 """
    def __init__(self, player):
        self.player = player
        self.equips = {}
        self.items = {}
        self.fates = {}
        self.cars = {}
        self.gem = {}
        if 0:
            from game.player.player import Player
            self.player = Player()
        #default_size = Game.setting_mgr.setdefault(BAG_SIZE, BAG_SIZE_V)
        #self.set_size(default_size)
        #物品快速索引
        #{iid1:([id1, id2, ...],[id3, id4]), ...}
        #{物品基础表id:([可交易物品id...],[不可交易物品id...])...}
        self.iid_to_items = {}
        self._used_count = 0

    def uninit(self):
        self.player = None
        self.equips = {}
        self.items = {}
        self.fates = {}
        self.cars = {}
        self.gem = {}
        self.iid_to_items = {}


    def _load_items(self, items):
        for item_dict in items:
            id = item_dict['id']
            obj = self.items[id] = Item(adict=item_dict)
            self._add_bag_item(obj)
        self._used_count = len(items)

    def _load_single(self, mydict, items, cls):
        for item_dict in items:
            mydict[item_dict["id"]] = cls(adict=item_dict)
            if not item_dict['used']:
                self._used_count += 1

    def load(self):
        """ 加载数据 """
        store = self.player._game.rpc_store
        querys = dict(pid=self.player.data.id)
        tItemDicts = store.query_loads(TN_P_ITEM, querys)
        self._load_items(tItemDicts)
        tEquipDicts = store.query_loads(TN_P_EQUIP, querys)
        self._load_single(self.equips, tEquipDicts, Equip)
        tFateDicts = store.query_loads(TN_P_FATE, querys)
        self._load_single(self.fates, tFateDicts, Fate)
        tCarDicts = store.query_loads(TN_P_CAR, querys)
        for tCarDict in tCarDicts:
            self.cars[tCarDict["id"]] = Car(adict=tCarDict)
        tGemDicts = store.query_loads(TN_P_GEM, querys)
        self._load_single(self.gem, tGemDicts, Gem)

    def load_used(self):
        """ 加载配将使用中的装备和命格 """
        store = self.player._game.rpc_store
        querys = dict(pid=self.player.data.id, used=1)
        tEquipDicts = store.query_loads(TN_P_EQUIP, querys)
        self._load_single(self.equips, tEquipDicts, Equip)
        tFateDicts = store.query_loads(TN_P_FATE, querys)
        self._load_single(self.fates, tFateDicts, Fate)
        tGemDicts = store.query_loads(TN_P_GEM, querys)
        self._load_single(self.gem, tGemDicts, Gem)

    def to_dict(self, used=0):
        """ 获取玩家物品列表 """
        if not used:
            return {
                "equip":[equip.to_dict() for equip in self.equips.itervalues()],
                "item":[item.to_dict() for item in self.items.itervalues()],
                "fate":[fate.to_dict() for fate in self.fates.itervalues()],
                "car": [car.to_dict() for car in self.cars.itervalues()],
                "gem":[gem.to_dict() for gem in self.gem.itervalues()],
                }
        return {
            "equip":[equip.to_dict() for equip in self.equips.itervalues() if equip.data.used],
            "item":[],
            "fate":[fate.to_dict() for fate in self.fates.itervalues() if fate.data.used],
            "car": [],
            "gem":[gem.to_dict() for gem in self.gem.itervalues()],
        }

    def save(self):
        """ 保存至数据库 """
        store = self.player._game.rpc_store
        for key in self.items.keys():
            if key not in self.items:
                continue
            tItem = self.items[key]
            tItem.save(store)
        for key in self.fates.keys():
            if key not in self.fates:
                continue
            tFate = self.fates[key]
            tFate.save(store)
        for key in self.equips.keys():
            if key not in self.equips:
                continue
            tEq = self.equips[key]
            tEq.save(store)
        for key in self.cars.keys():
            if key not in self.cars:
                continue
            tCar = self.cars[key]
            tCar.save(store)
        for key in self.gem.keys():
            if key not in self.gem:
                continue
            tGem = self.gem[key]
            tGem.save(store)


    def clear(self):
        """ 清除所有数据 """
        store = self.player._game.rpc_store
        for i in self.items.itervalues():
            i.delete(store)
        for i in self.fates.itervalues():
            i.delete(store)
        for i in self.equips.itervalues():
            i.delete(store)
        for i in self.cars.itervalues():
            i.delete(store)
        for i in self.gem.itervalues():
            i.delete(store)
        self.player.roles.clear_attr()
        self.player.clear_attr_car()
        self.items.clear()
        self.fates.clear()
        self.equips.clear()
        self.cars.clear()
        self.gem.clear()
        self.iid_to_items.clear()
        self._used_count = 0

    def copy_from(self, bag):
        #新旧id关联
        items = {}
        self.clear()
        def _add(cls, data):
            item = cls(adict=data.to_dict())
            item.data.id = None
            item.data.pid = self.player.data.id
            item.save(self.player._game.rpc_store)
            items[data.id] = item.data.id
        for i in bag.items.itervalues():
            _add(Item, i.data)
        for i in bag.equips.itervalues():
            _add(Equip, i.data)
        for i in bag.fates.itervalues():
            _add(Fate, i.data)
        for i in bag.cars.itervalues():
            _add(Car, i.data)
        for i in bag.gem.itervalues():
            _add(Gem, i.data)
        self.load()
        return items

    #def set_size(self, aSize):
    #    """ 背包大小设置 """
    #    self.size = aSize

    def check_item(self, iid, count, uses=None):
        """ 检查是否有足够物品消耗,
        uses: 指定使用的id列表
        返回：是否足够,不可交易数,使用id列表"""
        ids = self.iid_to_items[iid]
        ids = ids[NOTRADE_IDX] + ids[TRADE_IDX]
        if uses:
            for i in uses[:]:
                if i not in ids:
                    uses.remove(i)
                else:
                    ids.remove(i)
            ids = uses + ids
        no_trade = 0
        trade = 0
        uses = []
        for id in ids:
            item = self.get_item(id)
            if not item.data.isTrade:
                no_trade += item.data.count
            else:
                trade += item.data.count
            if item.data.count <= count:
                uses.append(id)
                count -= item.data.count
            else:
                uses.append((item, count))
                count = 0
            if not count:
                return True, trade, no_trade, uses
        return False, trade, no_trade, uses

    def has_item(self, iid, count):
        """ 是否有特定数量的物品 """
        rs, trade, no_trade, uses = self.check_item(iid, count)
        return rs

    def cost_item(self, iid, count, unit=None, log_type=None, pack_msg=False, uses=None):
        """ 物品消耗
            uses: 指定使用的物品id列表
            成功返回
            [[删除物品的id...],
            更新后的item]
            #TODO: aUnit: 分组单位数量,要求返回1:可交易2:不可交易数3:两者都有
            失败返回None
            成功返回:可交易组数,不可交易组数,删除物品id列表,更新物品
        """
        iid = int(iid)
        count = int(count)
        if not self.iid_to_items.has_key(iid):
            return
        rs, trade_num, no_trade_num, use_ids = self.check_item(iid, count, uses=uses)
        if not rs:
            return

        up_item = None
        for id in use_ids:
            if isinstance(id, int):
                #删除使用的物品
                self.del_item(id)
                continue
            #扣除使用的数目(更新物品)
            id[0].data.count -= id[1]
            up_item = id[0]
            self.update_item(up_item)
        #写物品消耗记录
        if log_type:
            self.player.log_item(iid, count, log_type)

        if up_item:#最后一个是更新物品
            use_ids = use_ids[:-1]
            up_item = [up_item]
        if unit:
            no_trade = int(math.ceil(no_trade_num / unit))
            trade = count / unit - no_trade
        else:
            trade, no_trade = (0, 1) if no_trade_num else (1, 0)
        if pack_msg:
            return trade, no_trade, self.player.pack_msg_data(del_iids=use_ids, items=up_item)
        return trade, no_trade,  use_ids, up_item

    def sell_all(self, equip_ids, item_ids, fate_ids, gem_ids):
        """ 批量卖出 """
        tCoin1 = 0
        del_eids, del_iids, del_fids, del_gids = [], [], [], []
        item_mgr = self.player._game.item_mgr
        if equip_ids:
            gem_tmp = []
            for tEquipId in equip_ids:
                tEquip = self.get_equip(tEquipId)
                if not tEquip:
                    return False, errcode.EC_BAG_NO
                del_eids.append((tEquip.data.eid, tEquip.data.level))
                gem_tmp.extend(tEquip.data.gem.values())
                tResEquip = item_mgr.get_res_equip(tEquip.data.eid)
                tCoin1 += tResEquip.price
            if gem_ids is None:
                gem_ids = gem_tmp
            else:
                gem_ids.extend(gem_tmp)
        if item_ids:
            for tItemId in item_ids:
                tItem = self.get_item(tItemId)
                if not tItem:
                    return False, errcode.EC_BAG_NO
                del_iids.append((tItem.data.iid, tItem.data.count))
                tResItem = item_mgr.get_res_item(tItem.data.iid)
                tCoin1 += tResItem.price*tItem.data.count
        if fate_ids:
            for tFateId in fate_ids:
                tFate = self.get_fate(tFateId)
                if not tFate:
                    return False, errcode.EC_BAG_NO
                del_fids.append((tFate.data.fid, tFate.data.exp))
                tResFate = item_mgr.get_res_fate(tFate.data.fid)
                tCoin1 += tResFate.price
        if gem_ids:
            for tGemId in gem_ids:
                tGem = self.get_gem(tGemId)
                if not tGem:
                    return False, errcode.EC_BAG_NO
                del_gids.append((tGem.data.gid, tGem.data.level))
                tRemGem = item_mgr.get_res_gem(tGem.data.gid)
                tCoin1 += tRemGem.price
        #加钱
        if tCoin1:
            self.player.add_coin(aCoin1=tCoin1, log_type=COIN_ADD_SELL)
        #删除物品
        self.del_items(item_ids)
        self.del_equips(equip_ids)
        self.del_fates(fate_ids)
        self.del_gem(gem_ids)

        dels = {}
        if del_iids:
            dels['i'] = del_iids
        if del_eids:
            dels['e'] = del_eids
        if del_fids:
            dels['f'] = del_fids
        if del_gids:
            dels['g'] = del_gids
        self.player.log_item(dels, 0, ITEM_SELL)
        return True, self.player.pack_msg_data(coin=True, del_iids=item_ids,
            del_eids=equip_ids, del_fids=fate_ids, del_gids=gem_ids)

    def get_item(self, id):
        """ 物品获取 """
        return self.items.get(id)

    def get_item_ex(self, id):
        """ 获取物品和其资源对象 """
        item = self.items.get(id)
        if item is None:
            return None, None
        res_item = self.player._game.item_mgr.get_res_item(item.data.iid)
        return item, res_item

    def get_item_ids_ex(self, iid):
        """ 通过基础物品id获取物品 """
        ids = self.iid_to_items.get(iid)
        if ids is None:
            return None, None
        res_item = self.player._game.item_mgr.get_res_item(iid)
        return ids[NOTRADE_IDX] + ids[TRADE_IDX], res_item

    def update_item(self, aItem):
        """ 物品更新 """
        aItem.modify()

    def _add_bag_item(self, item, insert=False):
        """ 添加单个物品 """
        self.items[item.data.id] = item
        iids = self.iid_to_items.setdefault(item.data.iid, ([], []))
        if insert:
            if item.data.isTrade:
                iids[TRADE_IDX].insert(0, item.data.id)
            else:
                iids[NOTRADE_IDX].insert(0, item.data.id)
            self._used_count += 1
        else:
            if item.data.isTrade:
                iids[TRADE_IDX].append(item.data.id)
            else:
                iids[NOTRADE_IDX].append(item.data.id)
                self._used_count += 1

    def _add_items(self, res_item, count):
        """ 物品添加 """
        def _add(aIid, add_count):
            tItem = Item()
            tItem.data.pid = self.player.data.id
            tItem.data.iid = aIid
            tItem.data.count = add_count
            tItem.save(self.player._game.rpc_store)
            self._add_bag_item(tItem, insert=True)
            return tItem.data.id, tItem

        items = []
        tStack = res_item.stack
        tCnt = int(math.ceil(float(count)/tStack))
        for i in xrange(tCnt):
            if count <= tStack:
                tAddCnt = count
            else:
                count -= tStack
                tAddCnt = tStack
            tId, tItemDict = _add(res_item.id, tAddCnt)
            items.append(tItemDict)
        return items

    def _stack_count(self, item, stack, count, update=True):
        """ update 是否更新数据
        将count个物品堆叠到item物品上
            返回 0 全部放上 非0则放不下
        """
        if stack <= item.data.count:
            return count
        free = stack - item.data.count
        if free >= count:
            if update:
                item.data.count += count
                self.update_item(item)
            return 0
        count -= free
        if update:
            item.data.count += free
            self.update_item(item)
        return count

    def _stack_item(self, res_item, count, can_trade):
        """ 添加堆叠物品 """
        stack = res_item.stack
        tItemIds = self.iid_to_items.get(res_item.id)
        rs = count, []
        if not tItemIds:
            return rs
        tItemIds = tItemIds[TRADE_IDX if can_trade else NOTRADE_IDX]
        if not tItemIds:
            return rs
        rs = []
        for tItemId in tItemIds:
            tItem = self.items.get(tItemId)
            tCount = count
            count = self._stack_count(tItem, stack, count)
            if count == tCount:
                continue
            rs.append(tItem)
            if count <= 0:
                break
        return count, rs

    def get_item_num_by_iid(self, iid):
        """得到物品的数目通过物品id"""
        num = 0
        if iid not in self.iid_to_items:
            return num
        op_tuple = self.iid_to_items[iid]
        ids = op_tuple[NOTRADE_IDX] + op_tuple[TRADE_IDX]
        for id in ids:
            item = self.get_item(id)
            num += item.data.count
        return num

    def add_item(self, aIid, count, can_trade=False, log_type=None):
        """ 物品放入背包(包括更新或者增加) """
        rs = None
        if aIid in DIFF_TITEM_IDS:
            rwitems = RewardItems()
            #处理特殊物品的添加
            rwitems.add_special_item(aIid, count)
            self._add_special_item(rwitems)
        else:
            tResItem = self.player._game.item_mgr.get_res_item(aIid)
            if not tResItem:
                return
            aCount, stack_items = self._stack_item(tResItem, count, can_trade)
            new_items = []
            if aCount:
                new_items = self._add_items(tResItem, aCount)
            rs = stack_items + new_items
        #写入log
        if log_type:
            self.player.log_item(aIid, count, log_type)
        #背包物品变化
        self.player.safe_pub(msg_define.MSG_BAG_ITEM_CHANGE, aIid)
        return rs

    def has_car(self, cid):
        """ 判断是否已经有该坐骑,返回对应的car对象 """
        for c in self.cars.itervalues():
            if c.data.cid == cid:
                return c

    def add_car(self, cid):
        """ 添加坐骑 """
        car = self.has_car(cid)
        if car is not None:
            return car
        car = Car()
        car.data.pid = self.player.data.id
        car.data.cid = cid
        car.save(self.player._game.rpc_store)
        self.cars[car.data.id] = car
        return car

    def can_add_item(self, aIid, aCount, can_trade=False, other_used=0):
        """ 是否可以添加物品,
        返回:(是否可以, 占用新格子数)
        """
        if aIid in DIFF_TITEM_IDS:
            return True, 0
        res_item = self.player._game.item_mgr.get_res_item(aIid)
        if res_item is None:
            return False, 0
        stack = res_item.stack
        free = self.size - self._used_count - other_used
        ids = self.iid_to_items.get(aIid)
        if ids is None:
            c = int(math.ceil(float(aCount) / stack))
            return (True, c) if c <= free else (False, 0)

        ids = ids[TRADE_IDX] if can_trade else ids[NOTRADE_IDX]
        for id in ids:
            item = self.items[id]
            aCount = self._stack_count(item, stack, aCount, update=False)
            if aCount <=0:
                return True, 0
        c = int(math.ceil(float(aCount) / stack))
        return (True, c) if c <= free else (False, 0)

    def _add_special_item(self, rwitems, bag_items=None):
        #特殊物品处理id(1=银币，2=元宝，3=绑定元宝，4=经验，5=打坐时间, 6=练历)
        player = self.player
        #钱
        coin = bool(rwitems.coin1 or rwitems.coin2 or rwitems.coin3)
        if coin:
            player.add_coin(aCoin1=rwitems.coin1, aCoin2=rwitems.coin2,
                    aCoin3=rwitems.coin3, log_type=COIN_ADD_ITEM)
            if bag_items:
                #bag_items.coin = coin
                bag_items.add_coin(rwitems.coin1, rwitems.coin2,
                        rwitems.coin3)
        #经验
        site_exp = player._game.item_mgr.get_site_exp(player.data.level,
                rwitems.site_times)
        exp = site_exp + rwitems.exp
        if bool(exp):
            if bag_items:
                bag_items.exp += exp
            player.add_exp(exp)
        #练历
        if bool(rwitems.train):
            if bag_items:
                bag_items.train += rwitems.train
            player.add_train(rwitems.train, log_type=TRAIN_BAG)
        #时光盒
        if rwitems.tbox:
            if bag_items:
                bag_items.tbox = True
            tbox_mgr = player._game.tbox_mgr
            for bid in rwitems.tbox:
                tbox_mgr.add_monster(player, bid)

    def add_items(self, items, log_type=None, rid=0):
        """ 添加待收物品列表、奖励物品列表,
         返回: BagItems对象
        """
        bag_items = BagItems(self)
        bag_items.reward_items = items
        rwitems = RewardItems(items)
        self._add_special_item(rwitems, bag_items=bag_items)
        item_mgr = self.player._game.item_mgr
        for _id, counts in rwitems.items.iteritems():
            if counts[TRADE_IDX]:
                add_items = self.add_item(_id, counts[TRADE_IDX], 1)
                if add_items:
                    bag_items.items.extend(add_items)
            if counts[NOTRADE_IDX]:
                add_items = self.add_item(_id, counts[NOTRADE_IDX], 0)
                if add_items:
                    bag_items.items.extend(add_items)
        for _id, c, tr in rwitems.equips:
            for i in xrange(c):
                equip = item_mgr.new_equip(_id, is_trade=tr)
                if not equip:
                    continue
                if self.add_equip(equip) is None:
                    continue
                bag_items.equips.append(equip)
        for _id, c, tr in rwitems.fates:
            for i in xrange(c):
                fate = item_mgr.new_fate(_id, is_trade=tr)
                if not fate:
                    continue
                if self.add_fate(fate) is None:
                    continue
                bag_items.fates.append(fate)
        for rid in rwitems.roles:
            rs, err = self.player.roles.can_add(rid)
            if not rs:
                log.error(u'奖励配将失败:%s', err)
            else:
                bag_items.roles.append(self.player.roles.add_role(err))
        for _id in rwitems.cars:
            res_car = self.player._game.res_mgr.cars.get(_id)
            if res_car:
                t_car = self.add_car(_id)
                bag_items.cars.append(t_car)
            else:
                log.error(u'奖励的坐骑id在资源标表中不存在')
        for _id, c, lv in rwitems.gem:
            for i in xrange(c):
                gem = item_mgr.new_gem(_id, lv)
                if not gem:
                    continue
                if self.add_gem(gem) is None:
                    continue
                bag_items.gem.append(gem)
        if log_type:
            self.player.log_items(items, log_type, rid=rid)
        return bag_items

    def can_add_items(self, items):
        """ 是否能添加待收物品列表、奖励物品列表 """
        add, not_add = self.get_can_add_items(items)
        if len(not_add) == 0:
            return True
        return False

    def get_can_add_items(self, items):
        """ 是否能添加待收物品列表、奖励物品列表 """
        used_count = 0
        add = []
        not_add = []
        free = self.size - self._used_count
        waits = {}
        add_items = copy.deepcopy(items)
        for item in add_items:
            t = item[IKEY_TYPE]
            if t in (IT_CAR_STR, ):
                add.append(item)
                continue
            elif t in (IT_EQUIP_STR, IT_FATE_STR, IT_GEM_STR):
                if used_count + 1 > free:
                    not_add.append(item)
                else:
                    add.append(item)
                    used_count += 1
                continue
            elif t == IT_ITEM_STR:
                if int(item[IKEY_ID]) in DIFF_TITEM_IDS:
                    add.append(item)
                    continue
                iid = item[IKEY_ID]
                if waits.has_key(iid):
                    o_item = waits[iid]
                    o_item[IKEY_COUNT] = int(o_item[IKEY_COUNT]) + int(item[IKEY_COUNT])
                else:
                    waits[iid] = item
        for item in waits.itervalues():
            id = int(item[IKEY_ID])
            c = int(item.get(IKEY_COUNT, 1))
            can_trade = int(item.get(IKEY_TRADE, 0))
            rs, used = self.can_add_item(id, c, can_trade, other_used=used_count)
            if rs:
                add.append(item)
                used_count += used
            else:
                not_add.append(item)
        return add, not_add

    def del_item(self, id, store_delete=True):
        """ 物品删除 """
        tItem = self.items.pop(id)
        if tItem.data.isTrade:
            self.iid_to_items[tItem.data.iid][TRADE_IDX].remove(id)
        else:
            self.iid_to_items[tItem.data.iid][NOTRADE_IDX].remove(id)
        if store_delete:
            self.player._game.rpc_store.delete(TN_P_ITEM, id)
        self._used_count -= 1
        #背包物品变化
        self.player.safe_pub(msg_define.MSG_BAG_ITEM_CHANGE, tItem.data.iid)

    def del_items(self, ids):
        if not ids:
            return
        for iid in ids:
            self.del_item(iid, store_delete=False)
        self.player._game.rpc_store.deletes(TN_P_ITEM, ids)

    def get_fate(self, id):
        """ 命格获取"""
        return self.fates.get(id)

    def get_fate_ex(self, fid):
        """ 获取命格和其资源对象 """
        fate = self.fates.get(fid)
        if fate is None:
            return None, None
        res_fate = self.player._game.item_mgr.get_res_fate(fate.data.fid)
        return fate, res_fate

    def add_fate(self, fate):
        """ 将命格添加到背包 """
        if self.size <= self._used_count:
            return
        fate.data.pid = self.player.data.id
        fate.save(self.player._game.rpc_store)
        self.fates[fate.data.id] = fate
        self._used_count += 1
        #发送背包命格变化消息
        self.player.safe_pub(msg_define.MSG_BAG_FATE_CHANGE, fid = fate.data.fid)
        return fate

    def update_fate(self, fate, used_count=0):
        """ 命格更新: used_count:增加或减少占用的格子数 """
        fate.modify()
        if used_count in (1, -1):
            self._used_count += used_count

    def get_fate_num_by_quality(self, quality):
        num = 0
        for fate in self.fates.itervalues():
            res_fate = self.player._game.item_mgr.get_res_fate(fate.data.fid)
            if res_fate.quality == quality:
                num += 1
        return num

    def del_fate(self, fid, store=1):
        """ 命格删除 """
        if fid not in self.fates:
            return None
        fate = self.fates.pop(fid)
        if not fate.data.used:
            self._used_count -= 1
        if store:
            self.player._game.rpc_store.delete(TN_P_FATE, fid)
        #发送背包命格变化消息
        self.player.safe_pub(msg_define.MSG_BAG_FATE_CHANGE, fid = fate.data.fid)
        return fid

    def del_fates(self, ids):
        """ 多命格删除 """
        if not ids:
            return
        rs = []
        for fid in ids:
            if self.del_fate(fid, store=0):
                rs.append(fid)
        self.player._game.rpc_store.deletes(TN_P_FATE, ids)
        return rs

    def add_equip(self, equip, forced=0):
        """ 添加装备 """
        if not forced and self.size <= self._used_count:
            return
        equip.data.pid = self.player.data.id
        equip.save(self.player._game.rpc_store)
        self.equips[equip.data.id] = equip
        self._used_count += 1
        return equip

    def get_equip(self, id):
        """ 装备获取 """
        return self.equips.get(id)

    def get_equip_ex(self, eid):
        """ 获取装备和其资源对象 """
        equip = self.equips.get(eid)
        if equip is None:
            return None, None
        res_equip = self.player._game.item_mgr.get_res_equip(equip.data.eid)
        return equip, res_equip

    def get_equips_by_eid(self, eid):
        """ 通过基础装备id获取装备 """
        return [e for e in self.equips.itervalues() if e.data.eid==eid]


    def has_equip(self, eid):
        """ 是否有特定装备 """
        for e in self.equips.itervalues():
            if eid == e.data.eid:
                return True
        return False

    def update_equip(self, equip, used_count=0):
        """ 装备更新: used_count增加或减少暂用的格子数"""
        equip.modify()
        if used_count in (1, -1):
            self._used_count += used_count

    def del_equips(self, ids):
        """ 多装备删除 """
        if not ids:
            return
        rs = []
        for eid in ids:
            if self.del_equip(eid, store=0):
                rs.append(eid)
        self.player._game.rpc_store.deletes(TN_P_EQUIP, ids)
        return rs

    def del_equip(self, id, store=1):
        """ 装备删除 """
        if id not in self.equips:
            return None
        equip = self.equips.pop(id)
        if not equip.data.used:
            self._used_count -= 1
        if store:
            self.player._game.rpc_store.delete(TN_P_EQUIP, id)
        return id

    def get_gem(self, id):
        """珠宝获取"""
        return self.gem.get(id)

    def get_gem_ex(self, gid):
        gem = self.gem.get(gid)
        if gem is None:
            return None, None
        res_gem = self.player._game.item_mgr.get_res_gem(gem.data.gid)
        return gem, res_gem

    def add_gem(self, gem):
        if self.size <= self._used_count:
            return
        gem.data.pid = self.player.data.id
        gem.save(self.player._game.rpc_store)
        self.gem[gem.data.id] = gem
        self._used_count += 1
        return gem

    def del_gem(self, ids):
        if not ids:
            return
        for gid in ids:
            if gid not in self.gem:
                continue
            gem = self.gem.pop(gid)
            if not gem.data.used:
                self._used_count -= 1
        self.player._game.rpc_store.deletes(TN_P_GEM, ids)

    def update_gem(self, gem, used_count=0):
        """ 珠宝更新: used_count:增加或减少占用的格子数 """
        gem.modify()
        if used_count in (1, -1):
            self._used_count += used_count

    def bag_free(self):
        """ 返回背包格子剩余数 """
        return self.size - self._used_count

    @property
    def size(self):
        return Game.setting_mgr.fetch_size(self.player.data.vip)


class WaitItemData(StoreObj):
    __slots__ = ('id', 'pid', 'type', 'items', 'rid')
    def init(self):
        self.id = None
        self.pid = 0
        self.type = 0 #类型:1=猎命,2=时光盒,3=渔获,4=邮件
        self.items = ''
        self.rid = 0

class WaitItem(GameObj):
    """ 待收取物品 """
    __slots__ = GameObj.__slots__ + ('items', )
    TABLE_NAME = TN_P_WAIT
    DATA_CLS = WaitItemData

    @classmethod
    def new(cls, pid, type, items, rid=0):
        o = cls()
        o.data.pid = pid
        o.data.type = type
        o.data.items = json.dumps(items) #items是列表对象
        o.data.rid = rid
        o.items = items
        return o

    def update(self, adict):
        """ 更新 """
        super(WaitItem, self).update(adict)
        if self.data.items:
            self.items = json.loads(self.data.items)

class PlayerWaitBag(object):
    """ 待收取物品列表 """
    TYPE_TO_LOG = {
        WAITBAG_TYPE_HITFATE: ITEM_FETCH_HITFATE,
        WAITBAG_TYPE_TIMEBOX: ITEM_FETCH_TIMEBOX,
        WAITBAG_TYPE_EMAIL: ITEM_FETCH_EMAIL,
    }
    VALID_TYPES = (tuple, list, set)
    def __init__(self, player):
        if 0:
            from game.player.player import Player
            self.player = Player()
        self.items = {}
        self.types = {}
        self.player = player

    def uninit(self):
        self.player = None
        self.items = {}
        self.types = {}


    def add(self, witem):
        wid = witem.data.id
        self.items[wid] = witem
        ids = self.types.setdefault(witem.data.type, [])
        ids.append(wid)

    def delete(self, wid):
        if not self.items.has_key(wid):
            return
        witem = self.items.pop(wid)
        wtype = witem.data.type
        ids = self.types[wtype]
        ids.remove(wid)
        if not ids:
            self.types.pop(wtype)
        witem.delete(self.player._game.rpc_store)

    def deletes(self, type):
        witems = self.types.get(type)
        if not witems:
            return
        del_wids = []
        for id in witems[:]:
            self.delete(id)
            del_wids.append(id)
        return del_wids

    def load(self):
        """ 加载数据 """
        store = self.player._game.rpc_store
        querys = dict(pid=self.player.data.id)
        waits = store.query_loads(TN_P_WAIT, querys)
        for w in waits:
            item = WaitItem(adict=w)
            self.add(item)

    def load_item(self, wid):
        """ 动态加载待收物品 """
        if wid in self.items:
            return
        data = self.player._game.rpc_store.load(TN_P_WAIT, wid)
        if data:
            item = WaitItem(adict=data)
            self.add(item)
            return item

    def save(self):
        store = self.player._game.rpc_store
        for key in self.items.keys():
            if key not in self.items:
                continue
            w = self.items[key]
            w.save(store)

    def clear(self):
        store = self.player._game.rpc_store
        for w in self.items.itervalues():
            w.delete(store)
        self.items.clear()
        self.types.clear()

    def copy_from(self, wait_bag):
        items = {}
        self.clear()
        for i in wait_bag.items.itervalues():
            ni = WaitItem(adict=i.data.to_dict())
            ni.data.id = None
            ni.data.pid = self.player.data.id
            ni.save(self.player._game.rpc_store)
            items[i.data.id] = ni.data.id
        self.load()
        return items


    def to_dict(self):
        return [i.to_dict() for i in self.items.itervalues()]

    def get_log_type(self, wtype):
        try:
            return self.TYPE_TO_LOG[wtype]
        except:
            return 100 + wtype

    def fetch(self, wtype, id=None, pack_msg=True, delete=True,
                log_type=None):
        """ 收取物品 """
        if id is not None:
            ids = [id]
        else:
            ids = self.types.get(wtype, None)
            if not ids:
                return False, errcode.EC_VALUE
            ids = ids[:]
        witems = [self.items[i] for i in ids if i in self.items]
        if not witems:
            return False, errcode.EC_NOFOUND
        items = []
        bag = self.player.bag
        rid = 0
        for witem in witems:
            if not isinstance(witem.items, self.VALID_TYPES):
                continue
            items.extend(witem.items)
            if witem.data.rid:
                rid = witem.data.rid

        #是否可添加
        if not bag.can_add_items(items):
            return False, errcode.EC_BAG_FULL

        if log_type is None:
            log_type = self.get_log_type(wtype)
        #添加背包
        bag_items = bag.add_items(items, log_type=log_type, rid=rid)

        #删除
        for item in witems:
            if delete:
                self.delete(item.data.id)
        #时光盒数据特殊处理
        if wtype == WAITBAG_TYPE_TIMEBOX:
            ptbox_attr = self.player.play_attr.get(PLAYER_ATTR_TBOX)
            if ptbox_attr[PT_CH]:
                ptbox_attr[PT_CH] = 0
                ptbox_attr[PT_WAITS] = []
        if pack_msg:
            return True, bag_items.pack_msg(del_wids=ids)
        return True, bag_items

    def _handle_type_data(self, type):
        """ 处理特殊类型凌晨刷新的数据(主动发给客户端) """
        #猎命
        if type == WAITBAG_TYPE_HITFATE:
            hfate = getattr(self.player.runtimes, PLAYER_ATTR_HITFATE)
            if hfate.handle_pass_day(fetch=True):
                resp_f = 'enterHitFate'
                rs, data = hfate.enter()
                if rs:
                    self.player.send_msg(resp_f, 1, data=data)
        #时光盒
        elif type == WAITBAG_TYPE_TIMEBOX:
            ptbox = getattr(self.player.runtimes, TN_P_TBOX)
            ch = ptbox.handle_pass_day(fetch=True)
            if ch:
                resp_f = 'tBoxEnter'
                rs, data = ptbox.enter(ch)
                if rs:
                    pack = pack_msg(resp_f, 1, data={'tbox':data.to_dict()})
                else:
                    pack = pack_msg(resp_f, 0, data=data)
                self.player.send_msg(pack)


    def add_waitItem(self, aType, aItems):
        """ 添加待收物品 """
        if not isinstance(aItems, self.VALID_TYPES):
            raise ValueError('add_waitItem:aItems mush list type')
        oWaitItem = WaitItem.new(self.player.data.id, aType, aItems)
        oWaitItem.save(self.player._game.rpc_store, forced=True)
        self.add(oWaitItem)
        return oWaitItem


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
