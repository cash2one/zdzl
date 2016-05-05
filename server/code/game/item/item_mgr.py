#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game import Game
from corelib.common import RandomRegion

from .item import Item
from .fate import Fate
from .car import Car
from .equip import Equip
from .gem import Gem
from game.base.common import str2dict
from game.base.msg_define import MSG_START, MSG_RES_RELOAD
from game.base.constant import (\
    QCOLORS, QCOLORS_V, IRON_IDS, IRON_IDS_V,
    QUALITY_BLUE, QUALITY_GREEN, QUALITY_ORANGE, QUALITY_PURPLE, QUALITY_RED, QUALITY_WHITE,
)


class ItemMgr(object):
    """ 物品、命格、装备、坐骑等管理类 """
    def __init__(self):
        import app
        app.sub(MSG_START, self.start)

    def start(self):
        Game.setting_mgr.sub(MSG_RES_RELOAD, self.load)
        self.load()

    def load(self):
        #品质颜色定义
        qcolors = Game.setting_mgr.setdefault(QCOLORS, QCOLORS_V)
        self.qcolors = str2dict(qcolors, ktype=str, vtype=str)

    @property
    def res_mgr(self):
        return Game.res_mgr

    def new_item(self, iid, count, is_trade):
        """ 新建物品对象 """
        res_item = self.get_res_item(iid)
        if res_item is None:
            return
        return Item.new_by_res(res_item, count, is_trade=is_trade)

    def new_fate(self, fid, is_trade=0):
        res_fate = self.get_res_fate(fid)
        if res_fate is None:
            return
        return Fate.new_by_res(res_fate, is_trade=is_trade)

    def new_fate_id_by_quality(self, quality):
        """ 根据命格品质,随机出对应的命格id """
        res_fate = self.res_mgr.get_fate_by_rate(quality)
        return res_fate.id

    def new_gem(self, gid, level, is_trade=0):
        res_gem = self.get_res_gem(gid)
        if res_gem is None:
            return
        return Gem.new_by_res(res_gem, level, is_trade=is_trade)

    def new_gem_id_by_quality(self, quality):
        """ 根据珠宝品质,随机出对应的珠宝id """
        q_gem = self.res_mgr.q_gem.get(quality, [])
        items = [(gem.id, gem.rate) for gem in q_gem]
        ran = RandomRegion(items)
        return ran.random()

    def new_equip(self, eid, is_trade=0):
        res_equip = self.get_res_equip(eid)
        if res_equip is None:
            return
        return Equip.new_by_res(res_equip, is_trade=is_trade)
    
    def new_equip_id_by_set(self, set_id):
        """ 根据装备套装id,随机出对应的一件装备id """
        res_equip = self.res_mgr.get_equip_by_rate(set_id)
        return res_equip.id

    def get_res_fate(self, aId):
        """ 获取命格基础数据 """
        return self.res_mgr.fates.get(aId)

    def get_res_fate_level(self, fid, level):
        return self.res_mgr.fate_level_by_keys.get((fid, level))

    def get_res_gem(self, gid):
        """获得珠宝基础数据"""
        return self.res_mgr.gem.get(gid)

    def get_res_gem_level(self, gid, level):
        return self.res_mgr.gem_levels.get((gid, level))

    def get_item_fusion(self, aDesId, aSrcId):
        """ 物品合成基础数据表(通过目标和源获取) """
        return self.res_mgr.fusions_by_keys.get((aDesId, aSrcId))

    def get_res_equip(self, aId):
        """ 获取装备基础数据 """
        return self.res_mgr.equips.get(aId)
    
    def get_res_eq_set(self, sid):
        """ 通过套装id获取套装基础数据 """
        return self.res_mgr.equip_sets.get(sid)

    def get_res_equip_level(self, part, level):
        return  self.res_mgr.equip_levels.get((part, level))

    def get_res_str_eq(self, aLevel):
        """ 通过登记获取强化表(aLevel上升到的等级) """
        return self.res_mgr.str_eq_by_level.get(aLevel)

    def get_res_item(self, aId):
        """ 获取物品基础数据 """
        return self.res_mgr.items.get(aId)

    def get_res_reward(self, aId):
        """ 获取奖励表基础数据 """
        return self.res_mgr.rewards.get(aId)

    def get_site_exp(self, level, site_times):
        """ 打坐时间经验 """
        if site_times <= 0:
            return 0
        site_exp = self.res_mgr.get_site_exp(level)
        return int(site_exp * site_times)

    def get_color(self, quality_or_name):
        """ 根据品质,获取显示用的颜色字符串 """
        return self.qcolors.get(str(quality_or_name))

    def is_iron(self, iid):
        """判断物品是否玄铁"""
        iron_ids = eval(Game.setting_mgr.setdefault(IRON_IDS, IRON_IDS_V))
        return iid in iron_ids


