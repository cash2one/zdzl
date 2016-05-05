#!/usr/bin/env python
# -*- coding:utf-8 -*-
#摇钱树模块

# 作者： 彭柏流
# created at： 2013: 05: 21


from corelib.common import make_lv_regions
from game import BaseGameMgr
from game.base.common import current_time, is_today
from game.base import errcode
# from game.base.common import str2dict2
# from game.glog.common import ITEM_COST_USE
from game.base.constant import CTREE_PLAYER_ATTR_COINSTREE

from game.base.constant import CTREE_VIP_LEVEL_MAP_COUNT
from game.base.constant import CTREE_VIP_LEVEL_MAP_COUNT_V
from game.base.constant import CTREE_EXCHANGE_MAP, CTREE_EXCHANGE_MAP_V
from game.base.constant import CTREE_OPEN_LEVEL_K, CTREE_OPEN_LEVEL_V
from game.glog.common import COIN_SUB_CTREE
# from game.glog.common import COIN_ADD_CTREE
from game.base.msg_define import MSG_RES_RELOAD


import logging
CTREE_LOG = logging.getLogger()


class CTreeMgr(BaseGameMgr):
    """ 这个类实现摇钱树的功能"""
    _KEY_NUM = 'num'
    _KEY_UPDATE_TIME = 't'

    def __init__(self, game):
        """ keep a reference to 'game' the global instance """

        super(CTreeMgr, self).__init__(game)
        self.init()

    def init(self):
        self.quota_map = None
        self.door_level = None
        self.exmap = None

    def start(self):
        self._game.res_mgr.sub(MSG_RES_RELOAD, self.init)

    def bind_player(self, player):
        pass
        # coinstree = getattr(player.runtimes,
        #                     CTREE_PLAYER_ATTR_COINSTREE, None)
        # if coinstree is None:
        #     setattr(player.runtimes, CTREE_PLAYER_ATTR_COINSTREE, self)
        # player_attr = player.play_attr.get(CTREE_PLAYER_ATTR_COINSTREE)
        # if not player_attr:
        #     self._load_data_to_player(player, self._ctree_data_to_dict(0))

    def _ctree_data_to_dict(self, ctreenum, ctreet=None):
        if ctreet is None:
            ctreet = current_time()
        return {CTreeMgr._KEY_NUM: ctreenum, CTreeMgr._KEY_UPDATE_TIME: ctreet}

    def _load_data_to_player(self, player, ctree_store_dict):
        """将摇钱树相关数据加载到玩家身上"""
        p_attr = player.play_attr
        p_attr.update_attr({CTREE_PLAYER_ATTR_COINSTREE: ctree_store_dict})

    def _get_map_quota(self, vip_level):
        if not self.quota_map:
            smgr = self._game.setting_mgr
            quota_map = smgr.setdefault(CTREE_VIP_LEVEL_MAP_COUNT,
                                        CTREE_VIP_LEVEL_MAP_COUNT_V)
            self.quota_map = make_lv_regions(quota_map)
        return self.quota_map(vip_level)

    def _get_consume_quota(self, player):
        p_data = player.play_attr.get(CTREE_PLAYER_ATTR_COINSTREE)
        if not p_data:
            p_data = self._ctree_data_to_dict(0, 0)
        last_up_time = p_data.get(CTreeMgr._KEY_UPDATE_TIME, 0)
        if not is_today(last_up_time):
            p_data = self._ctree_data_to_dict(0, 0)

        return (p_data.get(CTreeMgr._KEY_NUM, 0),
                p_data.get(CTreeMgr._KEY_UPDATE_TIME, 0))

    def _get_exchange_map_v(self, player):
        if not self.exmap:
            smgr = self._game.setting_mgr
            ex_map = smgr.setdefault(CTREE_EXCHANGE_MAP, CTREE_EXCHANGE_MAP_V)
            counters = ex_map.split('|')
            self.exmap = (compile(counters[0], 'c2', 'eval'),
                          compile(counters[1], 'c1', 'eval'))
        used_quota, time = self._get_consume_quota(player)
        c2 = eval(self.exmap[0], dict(n=used_quota + 1))
        c2 = round(c2)
        c1 = round(eval(self.exmap[1], dict(n=used_quota + 1, c2=c2)))
        return c2, c1

    def _get_open_level(self):
        if not self.door_level:
            smgr = self._game.setting_mgr
            self.door_level = smgr.setdefault(CTREE_OPEN_LEVEL_K,
                                              CTREE_OPEN_LEVEL_V)
        return self.door_level

    def api_ctree_get_rest_quota(self, player):
        """
        获取剩余兑换次数
        """
        if player.data.level < self._get_open_level():
            return 0
        quota = self._get_map_quota(player.data.vip)
        use_quota, last_time = self._get_consume_quota(player)
        return quota - use_quota

    def enter(self, player):
        if player.data.level < self._get_open_level():
            return False, errcode.EC_CTREE_LOW_LEVEL
        # CTREE_LOG.info("peng print: " + str(quota)
        #+ '--' + str(use_quota) + '--' + str(last_time))
        (c2, c1) = self._get_exchange_map_v(player)
        return True, dict(num=self.api_ctree_get_rest_quota(player),
                          c2toc1='{c2}:{c1}'.format(c2=c2, c1=c1))

    def exchange(self, player):
        if player.data.level < self._get_open_level():
            return False, errcode.EC_CTREE_LOW_LEVEL

        quota = self._get_map_quota(player.data.vip)
        use_quota, last_time = self._get_consume_quota(player)
        if use_quota >= quota:
            return False, errcode.EC_CTREE_QUOTA_USE_UP

        (c2, c1) = self._get_exchange_map_v(player)
        orig_c2 = player.get_coin2(use_bind=False)
        if orig_c2 < c2:
            return False, errcode.EC_CTREE_NOT_ENOUGH_COINS
        rs = (player.cost_coin(aCoin2=c2, use_bind=False,
              log_type=COIN_SUB_CTREE)
              and player.add_coin(aCoin1=c1, log_type=COIN_SUB_CTREE))
        if rs:
            use_quota = use_quota + 1
            self._load_data_to_player(player,
                                      self._ctree_data_to_dict(use_quota))
        else:
            return False, errcode.EC_CTREE_OPER_FAIL
        (c2, c1) = self._get_exchange_map_v(player)

        return (rs, dict(items=player.pack_msg_data(coin=True),
                         c2toc1='{c2}:{c1}'.format(c2=c2, c1=c1)))
