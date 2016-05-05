#!/usr/bin/env python
# -*- coding:utf-8 -*-

import random

from corelib import log
from corelib.common import RandomRegion
from game.base.constant import (USED_DO, USED_NOT, GEM_MAX_INDEX, GEM_MAX_INDEX_V, PLAYER_ATTR_GEM,
                                GEM_SANDING_QUALITY, GEM_SANDING_QUALITY_V, GEM_SANDING_LEVEL,
                                GEM_SANDING_LEVEL_V, GEM_SANDING_TYPE, GEM_SANDING_TYPE_V,
                                GEM_UPGRADE_RATE, GEM_UPGRADE_RATE_V, GEM_MAX_LEVEL,
                                GEM_MAX_LEVEL_V, GEM_MINE_FREE_NUM, GEM_MINE_FREE_NUM_V,
                                GEM_MINE_COIN3_NUM, GEM_MINE_COIN3_NUM_V,
                                GEM_MINE_COIN3_COST, GEM_MINE_COIN3_COST_V,
                                GEM_MINE_REWARD, GEM_MINE_REWARD_V,
                                GEM_MINE_REWARD_COIN_NUM, GEM_MINE_REWARD_COIN_NUM_V,
                                GEM_MINE_VIP_LEVEL, GEM_MINE_VIP_LEVEL_V)
from game.base.common import str2dict2, decode_list, str2dict3, is_today, current_time
from game.base import errcode
from game.glog.common import ITEM_ADD_GEM_MINE, COIN_GEM_MINE

from game.res.gem import ResGemUpRate
from game import BaseGameMgr

class GemMgr(BaseGameMgr):
    """珠宝系统"""
    def __init__(self, game):
        super(GemMgr, self).__init__(game)
        self.d_quality = {} #{quality:[(quality, rate)]}
        self.d_level = {} #{quality:[(level, rate)]}
        self.d_type = {} #{iid:[(type, rate)]}
        self.d_gid = {} #{(type, quality) : gid}
        self.d_rate = {} #{rate:[rate]}
        self.max_level = 0 #珠宝最大等级
        self.max_free = 0 #珠宝开采每日最大免费次数
        self.max_coin = 0 #珠宝开采每日最大元宝次数
        self.mime_cost = '' #珠宝开采元宝花费
        self.mine_reward = None #珠宝开采奖励id  元组(1,2,3)  （免费，元宝1，元宝2）
        self.mine_reward_coin_num = 0 #珠宝 元宝开采 到达指定次数后 更换奖励方式
        self.mine_vip_level = 0 #VIP批量开采等级

    def start(self):
        self.load()

    def decode_data(self, data):
        tmp = {}
        for k, v in data.items():
            d = []
            for _v in v:
                d.append(tuple(decode_list(_v)))
            tmp[int(k)] = d
        return tmp

    def load(self):
        self.d_quality = self._game.setting_mgr.setdefault(GEM_SANDING_QUALITY, GEM_SANDING_QUALITY_V)
        self.d_level = self._game.setting_mgr.setdefault(GEM_SANDING_LEVEL, GEM_SANDING_LEVEL_V)
        self.d_type = self._game.setting_mgr.setdefault(GEM_SANDING_TYPE, GEM_SANDING_TYPE_V)
        self.d_rate = self._game.setting_mgr.setdefault(GEM_UPGRADE_RATE, GEM_UPGRADE_RATE_V)
        self.max_level = int(self._game.setting_mgr.setdefault(GEM_MAX_LEVEL, GEM_MAX_LEVEL_V))
        self.max_free = int(self._game.setting_mgr.setdefault(GEM_MINE_FREE_NUM, GEM_MINE_FREE_NUM_V))
        self.max_coin = int(self._game.setting_mgr.setdefault(GEM_MINE_COIN3_NUM, GEM_MINE_COIN3_NUM_V))
        self.mime_cost = self._game.setting_mgr.setdefault(GEM_MINE_COIN3_COST, GEM_MINE_COIN3_COST_V)
        self.mine_reward = eval(self._game.setting_mgr.setdefault(GEM_MINE_REWARD, GEM_MINE_REWARD_V))
        self.mine_reward_coin_num = int(self._game.setting_mgr.setdefault(GEM_MINE_REWARD_COIN_NUM,
                                                                            GEM_MINE_REWARD_COIN_NUM_V))
        self.mine_vip_level = int(self._game.setting_mgr.setdefault(GEM_MINE_VIP_LEVEL, GEM_MINE_VIP_LEVEL_V))

        self.d_quality = str2dict3(self.d_quality)
        self.d_quality = self.decode_data(self.d_quality)
        self.d_level = str2dict3(self.d_level)
        self.d_level = self.decode_data(self.d_level)
        self.d_type = str2dict3(self.d_type)
        self.d_type = self.decode_data(self.d_type)
        self.d_rate = str2dict3(self.d_rate)
        self.d_rate = self.decode_data(self.d_rate)

        for gem in self._game.res_mgr.gem.itervalues():
            k = (gem.type, gem.quality)
            self.d_gid[k] = gem.id
        log.debug('GemMgr inited')

    def inlay(self, player, eid, gid, index):
        """镶嵌"""
        equip, res_eq = player.bag.get_equip_ex(eid)
        if equip is None or res_eq is None:
            return False, errcode.EC_GEM_NOT_FIND
        #已经镶嵌
        if index in equip.data.gem:
            return False, errcode.EC_GEM_INDEX_USED
        gem, res_gem = player.bag.get_gem_ex(gid)
        if gem is None or res_gem is None:
            return False, errcode.EC_GEM_NOT_FIND
        #部位检查
        if res_eq.part not in res_gem.parts:
            return False, errcode.EC_GEM_ERR_PART
        #是否已镶嵌同类型珠宝
        for _gid in equip.data.gem.itervalues():
            log.debug('_gid--- %s', _gid)
            _gem, _res_gem = player.bag.get_gem_ex(_gid)
            if _res_gem.type == res_gem.type:
                return False, errcode.EC_GEM_SAME_TYPE
        #合法的index
        max_index = 0
        data = player._game.setting_mgr.setdefault(GEM_MAX_INDEX, GEM_MAX_INDEX_V)
        data = str2dict2(data)
        for d_index, st_end in data.iteritems():
            start = int(st_end[0])
            end = int(st_end[1])
            if start <= res_eq.limit <= end:
                max_index = int(d_index)
                break
        if index > max_index:
            return False, errcode.EC_GEM_ERR_INDEX
        gem.data.used = USED_DO
        player.bag.update_gem(gem, used_count=-1)
        equip.data.gem[index] = gid
        player.bag.update_equip(equip)
        return True, player.pack_msg_data(equips=[equip], gem=[gem])

    def remove(self, player, eid, index):
        """移除"""
        equip = player.bag.get_equip(eid)
        if equip is None:
            return False, errcode.EC_GEM_NOT_FIND
        if index not in equip.data.gem:
            return False, errcode.EC_GEM_ERR_INDEX
        gid = equip.data.gem.get(index)
        gem = player.bag.get_gem(gid)
        if gem is None:
            return False, errcode.EC_GEM_NOT_FIND
        #背包已满
        if player.bag.size <= player.bag._used_count:
            return False, errcode.EC_BAG_FULL
        gem.data.used = USED_NOT
        player.bag.update_gem(gem, used_count=1)
        equip.data.gem.pop(index)
        player.bag.update_equip(equip)
        return True, player.pack_msg_data(equips=[equip], gem=[gem])

    def init_player(self, player):
        try:
            gem_mining = player.runtimes.gem_mining
        except AttributeError:
            gem_mining = PlayerGem(player)
            gem_mining.load()
            player.runtimes.gem_mining = gem_mining
        return gem_mining

    def enter_mine(self, player):
        """进入开采"""
        gem_mining = self.init_player(player)
        return gem_mining.enter_mine()

    def mine(self, player, t, num):
        """开采"""
        gem_mining = self.init_player(player)
        return gem_mining.mine(t, num)

    def reset_mine(self, player):
        """重置开采次数"""
        gem_mining = self.init_player(player)
        gem_mining.reset_mine()

    def sanding(self, player, stuff):
        """打磨"""
        res_stuff = []
        for iid in stuff:
            item, res_item = player.bag.get_item_ex(iid)
            if item is None or res_item is None:
                return False, errcode.EC_ITEM_NOFOUND
            res_stuff.append(res_item)
        quality = self._sanding_random(res_stuff, self.d_quality, 'quality')
        level = self._sanding_random(res_stuff, self.d_level, 'quality')
        _type = self._sanding_random(res_stuff, self.d_type, 'id')

        gid = self.d_gid.get((_type, quality), None)
        if gid is None:
            return False, errcode.EC_GEM_NOT_FIND
        gem = player._game.item_mgr.new_gem(gid, level)
        #背包已满
        if not player.bag.add_gem(gem):
            return False, errcode.EC_BAG_FULL
        player.bag.del_items(stuff)
        return True, player.pack_msg_data(gem=[gem], del_iids=stuff)

    def _sanding_random(self, res_stuff, d_rand, attr):
        data = []
        for res in res_stuff:
            d = d_rand.get(getattr(res, attr, None), None)
            if d is None:
                continue
            data.extend(d)
        ran = RandomRegion(data)
        return ran.random()

    def calculate(self, player, gid, stuff):
        """计算概率"""
        gem, res_gem = player.bag.get_gem_ex(gid)
        if gem is None or res_gem is None:
            return False, errcode.EC_GEM_NOT_FIND
        if gem.data.level >= self.max_level:
            return False, errcode.EC_GEM_MAX_LEVEL
        succ = gem.data.upSucc
        rate = []
        for sid in stuff:
            s_gem, s_res_gem = player.bag.get_gem_ex(sid)
            if s_gem is None or s_res_gem is None:
                continue
            key = (s_res_gem.quality, s_gem.data.level, res_gem.quality, gem.data.level)
            res_rate = player._game.res_mgr.gem_up_rate.get(key, None)
            if res_rate is None:
                continue
            rate.append(res_rate.succ)
        rate.sort(reverse=True)
        for i in xrange(len(rate)):
            if rate[i] >= 100:
                return True, 100
            k = rate[i]
            v = self.d_rate[k][0]
            if i < len(v):
                succ += v[i]
        return True, succ

    def upgrade(self, player, gid, stuff):
        """升级"""
        rs, succ = self.calculate(player, gid, stuff)
        if not rs:
            return False, succ
        gem = player.bag.get_gem(gid)

        rs = 0
        player.bag.del_gem(stuff)
        if succ >= random.randint(0, 100):
            gem.data.level += 1
            gem.data.upSucc = 0
            rs = 1
        if not rs:
            gem.data.upSucc = int(succ/2)
        player.bag.update_gem(gem)
        return True, dict(rs=rs, info=player.pack_msg_data(gem=[gem], del_gids=stuff))

    def transform(self, player, f_eid, t_eid):
        """转换"""
        f_eq = player.bag.get_equip(f_eid)
        t_eq = player.bag.get_equip(t_eid)
        if f_eq is None or t_eq is None:
            return False, errcode.EC_GEM_NOT_FIND
        tmp = f_eq.data.gem
        f_eq.data.gem = t_eq.data.gem
        t_eq.data.gem = tmp
        player.bag.update_equip(f_eq)
        player.bag.update_equip(t_eq)
        return True, player.pack_msg_data(equips=[f_eq, t_eq])

class PlayerGemData(object):
    """玩家珠宝数据"""
    def __init__(self):
        self.mfree = 0 #今日免费挖矿
        self.mcoin3 = 0 #今日元宝挖矿
        self.t = 0 #刷新时间

    def update(self, adict):
        """ 更新 """
        __dict__ = self.__dict__
        for k in __dict__.iterkeys():
            if k not in adict:
                continue
            __dict__[k] = adict[k]

    def to_dict(self):
        return self.__dict__

    def update_attr(self, player):
        """ 更新玩家属性表 """
        player.play_attr.update_attr({PLAYER_ATTR_GEM:self.to_dict()})

    def pass_day(self):
        if not is_today(self.t):
            self.mfree = 0 #今日免费挖矿
            self.mcoin3 = 0 #今日元宝挖矿
            self.t = current_time()

class PlayerGem(object):
    """玩家珠宝类"""
    FREE_MINE = 1 #免费开采
    COIN_MINE = 2 #元宝开采

    def __init__(self, player):
        self.player = player
        self.data = PlayerGemData()

    def save(self, store):
        self.data.update_attr(self.player)

    def load(self):
        data = self.player.play_attr.get(PLAYER_ATTR_GEM)
        if data:
            self.data.update(data)

    def copy_from(self, player):
        gem_mining = getattr(player.runtimes, 'gem_mining')
        if gem_mining:
            self.data = PlayerGemData()
            self.data.update(gem_mining.data.to_dict())

    def enter_mine(self):
        self.data.pass_day()
        self.player._game.setting_mgr.setdefault(GEM_SANDING_QUALITY, GEM_SANDING_QUALITY_V)
        return dict(num1=self.get_free_mine(), num2=self.get_coin_mine())

    def get_free_mine(self):
        mgr = self.player._game.gem_mgr
        num = mgr.max_free - self.data.mfree
        return num

    def get_coin_mine(self):
        mgr = self.player._game.gem_mgr
        num = mgr.max_coin - self.data.mcoin3
        return num

    def reset_mine(self):
        self.data.mfree = 0
        self.data.mcoin3 = 0

    def mine(self, t, num):
        self.data.pass_day()
        if num > 1 and self.player.data.vip < self.player._game.gem_mgr.mine_vip_level:
            return False, errcode.EC_NO_RIGHT
        if t == self.FREE_MINE:
            return self.free_mine(num)
        elif t == self.COIN_MINE:
            return self.coin_mine(num)

    def free_mine(self, num):
        n = self.get_free_mine()
        if n < num:
            return False, errcode.EC_TIMES_FULL
        items = []
        for i in xrange(num):
            rid = self.player._game.gem_mgr.mine_reward[0]
            t_rw = self.player._game.reward_mgr.get(rid)
            if t_rw is None:
                log.error("gem reward is None rid:%s", rid)
                continue
            d = t_rw.reward(params=None)
            if len(d):
                items.append(d[0])
        if not self.player.bag.can_add_items(items):
            return False, errcode.EC_BAG_FULL
        bag_items = self.player.bag.add_items(items, log_type=ITEM_ADD_GEM_MINE)
        self.data.mfree += num
        return True, bag_items.pack_msg()

    def coin_mine(self, num):
        n = self.get_coin_mine()
        if n < num:
            return False, errcode.EC_TIMES_FULL
        cost = 0
        mcoin3 = self.data.mcoin3
        items = []
        for i in xrange(num):
            cost += eval(self.player._game.gem_mgr.mime_cost % (mcoin3 + 1))
            if mcoin3 < self.player._game.gem_mgr.mine_reward_coin_num:
                rid = self.player._game.gem_mgr.mine_reward[1]
            else:
                rid = self.player._game.gem_mgr.mine_reward[2]
            t_rw = self.player._game.reward_mgr.get(rid)
            if t_rw is None:
                log.error("gem reward is None rid:%s", rid)
                continue
            d = t_rw.reward(params=None)
            if len(d):
                items.append(d[0])
            mcoin3 += 1

        if not self.player.enough_coin(aCoin1=0, aCoin2=cost):
            return False, errcode.EC_COST_ERR
        if not self.player.bag.can_add_items(items):
            return False, errcode.EC_BAG_FULL
        self.player.cost_coin(aCoin1=0, aCoin2=cost, log_type=COIN_GEM_MINE)
        self.data.mcoin3 += num
        bag_items = self.player.bag.add_items(items, log_type=ITEM_ADD_GEM_MINE)
        return True, bag_items.pack_msg(coin=True)