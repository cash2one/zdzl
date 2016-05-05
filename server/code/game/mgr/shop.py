#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store.define import TN_SHOP

from game.store import StoreObj, GameObj
from game import BaseGameMgr, Game
from game.glog.common import COIN_SHOP
from game.base.constant import  VIP_LV_SHOPS, VIP_LV_SHOPS_V, PLAYER_ATTR_SHOP, PLAYER_ATTR_GEM_SHOP
from game.base.constant import SHOP_TYPE_ITEM, SHOP_TYPE_FATE ,SHOP_ITEM_NUM , SHOP_ITEM_NUM_V
from game.base.constant import (GEM_SHOP_MAX_INDEX, GEM_SHOP_MAX_INDEX_V, GEM_SHOP_INDEX_COST,
                                GEM_SHOP_INDEX_COST_V, GEM_SHOP_DEFAULT_INDEX, GEM_SHOP_DEFAULT_INDEX_V,
                                GEM_SHOP_RESET_COST, GEM_SHOP_RESET_COST_V)
from game.base.common import RandomRegion
from game.base import errcode, common
import time
from corelib import log
from game.base.msg_define import MSG_SHOP_BUY, MSG_REWARD_BUY
from game.base.constant import SHOP_RESET_COST, SHOP_RESET_COST_V

FATE_QUALITY = 'quality'
GLOBAL_SHOP_BUY = 'global_shop_buy'
GLOBAL_SHOP_RARE = 'global_shop_rare'
CONST_NAME = 'name'
CONST_TYPE = 't'
CONST_IID = ''
CONST_RET = 'ret'
CONST_LATELY = 'lately'
CONST_ITEM_ID = 'iid'
CONST_RN = 'rn'
#CONST_LATELY_TYPE_ITEM = 1
#CONST_LATELY_TYPE_FATE = 2
CONST_LATELY_NUMS = 18


class ShopMgr(BaseGameMgr):
    """  商店管理器"""

    def __init__(self, game):
        super(ShopMgr, self).__init__(game)
        self.get_res_time = None
        self._active_mul = 1

    def start(self):
        from game.base.msg_define import MSG_RES_RELOAD
        self._game.res_mgr.sub(MSG_RES_RELOAD, self.lood)
        self.lood()

    def lood(self):
        res_objs = self._game.res_mgr.shop_rares
        sids = []
        fids = {}
        shop_rare = {'sids':sids,'fids':fids}
        item_mgr = Game.instance.item_mgr
        for obj in res_objs.itervalues():
            if obj.t == SHOP_TYPE_ITEM:
                if obj.id not in sids:
                    sids.append(obj.id)
            elif obj.t == SHOP_TYPE_FATE:
                while 1:
                    fid = item_mgr.new_fate_id_by_quality(obj.iid)
                    if fid not in fids:
                        fids[str(obj.id)] = fid
                        break
        self._game.rpc_status_mgr.set(GLOBAL_SHOP_RARE, shop_rare)

    def init_player_shop(self, player):
        """ 初始化playshop """
        player_shop = getattr(player.runtimes, PLAYER_ATTR_SHOP, None)
        if player_shop is None:
            player_shop = PlayShop(player, self)
            player_shop.load()
            setattr(player.runtimes, PLAYER_ATTR_SHOP, player_shop)
        return player_shop

    def enter(self, player, t):
        """ 进入商店 """
        eshop = self.init_player_shop(player)
        return eshop.enter(t)

    def buy(self, player, t, sid):
        """ 购买商品 """
        shopBuy = self.init_player_shop(player)
        return shopBuy.buy(player, t, sid)

    def dshopBuy(self, player, id, c):
        """可购买物品"""
        itemBuy = self.init_player_shop(player)
        return itemBuy.dshopBuy(id, c)

    def resetShop(self, player):
        shopBuy = self.init_player_shop(player)
        return shopBuy.re_set_shop()

    def set_active_mul(self, mul):
        """设置活动的翻倍系数"""
        self._active_mul = mul

    def get_active_mul(self):
        return self._active_mul

    #def set_rt_num(self, player, num):
    #    itemBuy = self.init_player_shop(player)
    #    itemBuy.set_rt_num(num)

    #@classmethod
    def get_rt_num(self, player):
        try:
            return self.get_res_time(player.data.vip)
        except TypeError:
            sett_str = player._game.setting_mgr.setdefault(VIP_LV_SHOPS, VIP_LV_SHOPS_V)
            self.get_res_time = common.make_lv_regions(sett_str)
            return self.get_res_time(player.data.vip)

    def reset_cost(self):
        return int(self._game.setting_mgr.setdefault(SHOP_RESET_COST, SHOP_RESET_COST_V))

    def init_lately(self):
        """
        得到购买列表的格式
        """
        return {str(ShopData.LUCK_ITEMS):[], str(ShopData.RARE_ITEMS):[]}

        #****************** 珠宝商店 *********************************

    def gem_enter(self, player):
        """进入珠宝商店"""
        eshop = self.init_player_shop(player)
        return eshop.gem_enter()

    def gem_buy(self, player, sid):
        """珠宝商店购买"""
        eshop = self.init_player_shop(player)
        return eshop.gem_buy(sid)

    def gem_add(self, player):
        """珠宝商店增加窗口"""
        eshop = self.init_player_shop(player)
        return eshop.gem_add()

    def gem_reset(self, player):
        eshop = self.init_player_shop(player)
        return eshop.gem_reset()

class ShopData(object):

    RARE_ITEMS = 1
    LUCK_ITEMS = 2

    def __init__(self):
        self.init()

    def init(self):
    #        重置使用的次数
        self.rn = 0
        #        商店商品列表
        self.sids = []
        #        特殊物品纪录相应id
        self.fids = {}
        #        startTime首次打开商店时间
        self.st = int(time.time())-86400

    def update(self, aDict):
        """ 更新 """
        __dict__ = self.__dict__
        for k in __dict__.iterkeys():
            if k not in aDict:
                continue
            __dict__[k] = aDict[k]

    def to_dict(self):
        return self.__dict__

    def update_attr(self, player):
        player.play_attr.update_attr({PLAYER_ATTR_SHOP:self.to_dict()})

class GemShopData(object):
    def __init__(self):
        self.init()

    def init(self):
        #商店商品列表
        self.sids = []
        #商店激活的窗口数
        self.n = Game.setting_mgr.setdefault(GEM_SHOP_DEFAULT_INDEX, GEM_SHOP_DEFAULT_INDEX_V)
        #上一次定时刷新时间
        self.t = 0
        #上一次刷新次数重置时间
        self.rt = 0
        #今日刷新次数
        self.rc = 0

    def update(self, adict):
        __dict__ = self.__dict__
        for k in __dict__.iterkeys():
            if k not in adict:
                continue
            __dict__[k] = adict[k]

    def to_dict(self):
        return self.__dict__

    def update_attr(self, player):
        player.play_attr.update_attr({PLAYER_ATTR_GEM_SHOP : self.to_dict()})

class PlayShop(object):

    REFURBISH_TIME = 21600

    def __init__(self, player, mgr):
        self.player = player
        self.shopData = None
        self.gemShopData = None
        self._mgr = mgr
        #self.rt_num = 0
    #        self.shopRet = self.player._game.res_mgr.shop_items

    def __getstate__(self):
        return self.shopData, self.gemShopData

    def __setstate__(self, data):
        self.shopData, self.gemShopData = data

    def uninit(self):
        self.player = None
        self.shopData = None
        self._mgr = None
        self.gemShopData = None


    def load(self, player = None):
        #神秘商店
        shopObjDict = self.player.play_attr.get(PLAYER_ATTR_SHOP)
        tmpShopData = ShopData()
        if shopObjDict:
            tmpShopData.update(shopObjDict)
        self.shopData = tmpShopData
        #珠宝商店
        gemShopObjDict = self.player.play_attr.get(PLAYER_ATTR_GEM_SHOP)
        tmpGemShopData = GemShopData()
        if gemShopObjDict:
            tmpGemShopData.update(gemShopObjDict)
        self.gemShopData = tmpGemShopData

    def save(self, store):
        self.shopData.update_attr(self.player)
        self.gemShopData.update_attr(self.player)

    def copy_from(self, player):
        #神秘商店
        p_shop = getattr(player.runtimes, PLAYER_ATTR_SHOP)
        if p_shop:
            self.shopData = ShopData()
            self.shopData.update(p_shop.shopData.to_dict())
            #珠宝商店
        p_gem_shop = getattr(player.runtimes, PLAYER_ATTR_GEM_SHOP, None)
        if p_gem_shop:
            self.gemShopData = GemShopData()
            self.gemShopData.update(p_gem_shop.gemShopData.to_dict())

    def need_refurbish(self):
        """ 处理超过一天(超过则更新数据) """
        curt = common.current_time()
        if curt - self.shopData.st > PlayShop.REFURBISH_TIME:
            self.shopData = ShopData()
            self.shopData.st = curt
            return True

    def dshopBuy(self, id, c):
        """ 直接购买 """
        itemList = None
        direct_shop = self.player._game.res_mgr.direct_shop
        direct_shop = direct_shop.get(id)
        if not self.player.enough_coin_ex(aCoin1=direct_shop.coin1*c, aCoin2=direct_shop.coin2*c, aCoin3=direct_shop.coin3*c):
            return False, errcode.EC_COST_ERR
        if not self.player.bag.can_add_item(aIid=direct_shop.iid, aCount=c)[0]:
            return False, errcode.EC_BAG_FULL
        itemList = self.player.bag.add_item(aIid=direct_shop.iid, count=c)
        self.player.cost_coin_ex(aCoin1=direct_shop.coin1*c,
            aCoin2=direct_shop.coin2*c, aCoin3=direct_shop.coin3*c, log_type=COIN_SHOP)
        rs = self.player.pack_msg_data(coin=True,items=itemList)
        return True, rs

    def _buy(self, sid, shop_type, shop_ret):
        """
        购买
        """
        if shop_type == ShopData.RARE_ITEMS:
            shop_rares = Game.rpc_status_mgr.get(GLOBAL_SHOP_RARE)
            sids = shop_rares['sids']
            fids = shop_rares['fids']
        elif shop_type == ShopData.LUCK_ITEMS:
            fids = self.shopData.fids
            sids = self.shopData.sids
        fid = str(sid)
        fate_list = []
        item_list = []
        if sid not in sids and fid not in fids:
            return False, errcode.EC_ITEM_NOFOUND
        mul = self._mgr.get_active_mul()
        coin1, coin2, coin3 = shop_ret.coin1*mul, shop_ret.coin2*mul, shop_ret.coin3*mul
        if not self.player.enough_coin_ex(coin1, aCoin2=coin2, aCoin3=coin3):
            return False, errcode.EC_COST_ERR
        if sid in sids:
            if not self.player.bag.can_add_item(shop_ret.iid, shop_ret.c)[0]:
                return False, errcode.EC_BAG_FULL
            item_list = self.player.bag.add_item(shop_ret.iid, shop_ret.c, log_type=COIN_SHOP)
            lately_iid = shop_ret.iid
            #it_type = CONST_LATELY_TYPE_ITEM
            if shop_type == ShopData.LUCK_ITEMS:
                sids.remove(sid)
        elif fid in fids:
            if self.player.bag.bag_free()<1:
                return False, errcode.EC_BAG_FULL
            fate_obj = self.player._game.item_mgr.new_fate(fids[str(sid)], is_trade=False)
            fate_list = [self.player.bag.add_fate(fate_obj)]
            lately_iid = fids[fid]
            #it_type = CONST_LATELY_TYPE_FATE
            if shop_type == ShopData.LUCK_ITEMS:
                fids.pop(str(sid))
        self.player.cost_coin_ex(aCoin1=coin1, aCoin2=coin2, aCoin3=coin3, log_type=COIN_SHOP)
        rs = self.player.pack_msg_data(coin=True,items=item_list, fates=fate_list)
        self.shopData.update_attr(self.player)
        self.update_lately(shop_type, lately_iid, shop_ret.t)
        self.player.pub(MSG_SHOP_BUY, sid)
        return True, rs

    def buy(self, player, t, sid):
        """ 神秘商店购买 """
        shop_ret = self.player._game.res_mgr.shop_items.get(sid)
        # 提前判断所需长件是否符合
        if shop_ret is None:
            return False, errcode.EC_ITEM_NOFOUND
        if t == ShopData.LUCK_ITEMS:
            return self._buy(sid, ShopData.LUCK_ITEMS, shop_ret)
        elif t == ShopData.RARE_ITEMS:
            return self._buy(sid, ShopData.RARE_ITEMS, shop_ret)
        return False, errcode.EC_VALUE

    def update_lately(self, t, iid, itype):
        """ 更新最近购买列表 """
        t = str(t)
        lately = Game.rpc_status_mgr.get(GLOBAL_SHOP_BUY)

        if not lately:
            l = self._mgr.init_lately()
            lately = l
        if isinstance(lately, list):
            l = self._mgr.init_lately()
            l[str(ShopData.LUCK_ITEMS)] = lately
            lately = l
        typelately = lately[t]

        if len(typelately) >= CONST_LATELY_NUMS:
            typelately.pop(-1)
        typelately.insert(0, {CONST_NAME:self.player.data.name,
                              CONST_ITEM_ID:iid,
                              CONST_TYPE:itype}
        )
        Game.rpc_status_mgr.set(GLOBAL_SHOP_BUY, lately)

    def _handle_fate(self, shop_ret, fids):
        """ 处理特殊的命格物品 """
        item_mgr = Game.instance.item_mgr
        if shop_ret.t == SHOP_TYPE_FATE:
            while 1:
                fid = item_mgr.new_fate_id_by_quality(shop_ret.iid)
                if fid not in fids:
                    fids[str(shop_ret.id)] = fid
                    break

    def _new_items(self, reset=False):
        """ 生成新物品 """
        #获取活动中出现的商品id
        reward_sids = []
        self.player.pub(MSG_REWARD_BUY, reward_sids)

        sids_tmp = {}
        fids_tmp = {}
        shop_item_num = self.shop_item_num
        #处理必然出现的物品
        #活动必然出
        for reward_sid in reward_sids:
            res_shop = self.player._game.res_mgr.shop_items.get(reward_sid)
            sids_tmp[(res_shop.t, res_shop.iid)] = res_shop.id
            if res_shop.t == SHOP_TYPE_FATE:
                self._handle_fate(res_shop, fids_tmp)
            if len(sids_tmp)==shop_item_num:
                break
        #本身商店必然出现的物品
        must_shops = self.player._game.res_mgr.shop_items_must
        if not reset and must_shops:
            for must_shop in must_shops.itervalues():
                if not (must_shop.start <= common.current_time() <= must_shop.end):
                    continue
                sids_tmp[(must_shop.t, must_shop.iid)] = must_shop.id
                if must_shop.t == SHOP_TYPE_FATE:
                    self._handle_fate(must_shop, fids_tmp)
                if len(sids_tmp)==shop_item_num:
                    break
        while len(sids_tmp) < shop_item_num:
            shop_ret = self.player._game.res_mgr.get_shop_by_rate()
            if shop_ret.start and shop_ret.start\
            and not (shop_ret.start <= common.current_time() <= shop_ret.end):
                continue
            if (shop_ret.t, shop_ret.iid) not in sids_tmp:
                sids_tmp[(shop_ret.t, shop_ret.iid)] = shop_ret.id
                if shop_ret.t == SHOP_TYPE_FATE:
                    self._handle_fate(shop_ret, fids_tmp)
        self.shopData.sids = sids_tmp.values()
        self.shopData.fids = fids_tmp
        self.shopData.st = int(time.time())

    def enter(self, t):
        """ 神秘商店进入 """
        lately = Game.rpc_status_mgr.get(GLOBAL_SHOP_BUY)
        if not lately:
            l = self._mgr.init_lately()
            lately = l
        if isinstance(lately, list):
            l = self._mgr.init_lately()
            l[str(ShopData.LUCK_ITEMS)] = lately
            lately = l
        lately = lately[str(t)]
        if self.need_refurbish():
            self._new_items()
        r_d = self.shopData if t == ShopData.LUCK_ITEMS else Game.rpc_status_mgr.get(GLOBAL_SHOP_RARE)
        return True, {CONST_RET:r_d, CONST_LATELY:lately, CONST_RN:self.free_num}

    def re_set_shop(self):
        """
        重置商店
        """
        if self.shopData.rn > self._mgr.get_rt_num(self.player):
            return False, errcode.EC_SHOP_RESET_NUM_ERR
        coin3 = self._mgr.reset_cost()
        if not self.player.enough_coin_ex(0, aCoin3=coin3):
            return False, errcode.EC_COST_ERR
        self.player.cost_coin_ex(aCoin3=coin3, log_type=COIN_SHOP)
        lately = Game.rpc_status_mgr.get(GLOBAL_SHOP_BUY)
        if not lately:
            l = self._mgr.init_lately()
            lately = l
        if isinstance(lately, list):
            l = self._mgr.init_lately()
            l[str(ShopData.LUCK_ITEMS)] = lately
            lately = l
        lately = lately[str(ShopData.LUCK_ITEMS)]
        self.shopData.rn += 1
        self._new_items()
        rs = self.player.pack_msg_data(coin=1)
        return True, {CONST_RET:self.shopData, CONST_LATELY:lately, CONST_RN:self.free_num, "up":rs}

    def gm_reset_items(self):
        """ gm重置物品 """
        self._new_items()

    @property
    def free_num(self):
        rn = self._mgr.get_rt_num(self.player) - self.shopData.rn
        rs = rn if rn >0 else 0
        return rs

    @property
    def shop_item_num(self):
        return self.player._game.setting_mgr.setdefault(SHOP_ITEM_NUM, SHOP_ITEM_NUM_V)

    #*******************珠宝商店**************************

    def gem_enter(self):
        """进入珠宝商店"""
        nt = self.gem_next_time()
        if nt - self.gemShopData.t >= 3600*6:
            self._new_gem_items()
        return True, dict(n = self.gemShopData.n, sids = self.gemShopData.sids,
            t = nt - common.current_time(), rc = self.gemShopData.rc)

    def _new_gem_items(self):
        """刷新珠宝商店物品"""
        self.gemShopData.sids = self.player._game.res_mgr.get_gem_shop_by_rate(self.gemShopData.n)
        self.gemShopData.t = common.current_time()

    def gem_next_time(self):
        """珠宝商店下次刷新时间"""
        ct = common.current_time()
        t = common.zero_day_time()
        for i in xrange(4):
            t = t + 3600*6
            if t >= ct:
                break
        return t

    def gem_buy(self, sid):
        """珠宝商店购买"""
        if sid not in self.gemShopData.sids:
            return False, errcode.EC_GEM_NOT_SID
        shop_item = self.player._game.res_mgr.gem_shop_items.get(sid)
        if shop_item is None:
            return False, errcode.EC_GEM_NOT_SID
        gem = self.player._game.item_mgr.new_gem(shop_item.gid, shop_item.lv)
        if gem is None:
            return False, errcode.EC_GEM_NOT_SID
        if not self.player.enough_coin_ex(shop_item.coin1, shop_item.coin2, shop_item.coin3):
            return False, errcode.EC_COST_ERR
        if not self.player.bag.add_gem(gem):
            return False, errcode.EC_BAG_FULL
        self.player.cost_coin_ex(shop_item.coin1, shop_item.coin2, shop_item.coin3)
        index = self.gemShopData.sids.index(sid)
        self.gemShopData.sids.remove(sid)
        self.gemShopData.sids.insert(index, 0)
        nt = self.gem_next_time()
        return True, dict(n=self.gemShopData.n, sids=self.gemShopData.sids, t=nt - common.current_time(),
            data=self.player.pack_msg_data(coin=True, gem=[gem]), rc = self.gemShopData.rc)

    def gem_add(self):
        """增加珠宝商店窗口"""
        num = self.player._game.setting_mgr.setdefault(GEM_SHOP_MAX_INDEX, GEM_SHOP_MAX_INDEX_V)
        if self.gemShopData.n >= num:
            return False, errcode.EC_GEM_SHOP_IS_MAX
        d_cost = self.player._game.setting_mgr.setdefault(GEM_SHOP_INDEX_COST, GEM_SHOP_INDEX_COST_V)
        default_num = self.player._game.setting_mgr.setdefault(GEM_SHOP_DEFAULT_INDEX, GEM_SHOP_DEFAULT_INDEX_V)
        d_cost = common.str2dict(d_cost, ktype=int, vtype=int)
        cost = d_cost.get(self.gemShopData.n - default_num + 1)
        if cost is None:
            return False, errcode.EC_VALUE
        if not self.player.enough_coin_ex(0, aCoin3=cost):
            return False, errcode.EC_COST_ERR
        self.player.cost_coin_ex(aCoin3=cost)
        self.gemShopData.n += 1
        self.gemShopData.sids = self.player._game.res_mgr.get_gem_shop_by_rate(1, self.gemShopData.sids)
        nt = self.gem_next_time()
        return True, dict(n = self.gemShopData.n, sids = self.gemShopData.sids, t=nt - common.current_time(),
            data = self.player.pack_msg_data(coin=True), rc = self.gemShopData.rc)

    def gem_reset(self):
        """珠宝商店重置"""
        d_cost = self.player._game.setting_mgr.setdefault(GEM_SHOP_RESET_COST, GEM_SHOP_RESET_COST_V)
        if d_cost is None:
            return False, errcode.EC_VALUE
        if not common.is_today(self.gemShopData.rt):
            self.gemShopData.rc = 0
            self.gemShopData.rt = common.current_time()
        d_cost = common.str2dict2(d_cost)
        cost = 0
        for k, v in d_cost.iteritems():
            start, end = int(v[0]), int(v[1])
            cs = 0
            if start <= self.gemShopData.rc + 1 <= end:
                index = range(start, end + 1).index(self.gemShopData.rc + 1) + 1
                cost = int(k) * index + cs
                break
            cs += int(k) * end
        if not self.player.enough_coin_ex(0, aCoin3=cost):
            return False, errcode.EC_COST_ERR
        self.player.cost_coin_ex(aCoin3=cost)
        self.gemShopData.rc += 1
        self.gemShopData.sids = self.player._game.res_mgr.get_gem_shop_by_rate(self.gemShopData.n)
        nt = self.gem_next_time()
        return True, dict(n = self.gemShopData.n, sids = self.gemShopData.sids, t=nt - common.current_time(),
            data = self.player.pack_msg_data(coin=True), rc = self.gemShopData.rc)
