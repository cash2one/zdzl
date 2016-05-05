#!/usr/bin/env python
# -*- coding:utf-8 -*-
from corelib import common

from game.base.common import str2dict2

from game.base.msg_define import MSG_RES_RELOAD#, MSG_VIP_ATTR_LOAD
from game.base.constant import VIP_FIGHT_MULTIPLE, VIP_FIGHT_MULTIPLE_V
from game.base.constant import VIP_FIGHT_SPEED_NUM, VIP_FIGHT_SPEED_NUM_V

class PlayerVipAttrMgr(object):

    def __init__(self, game):
        self._game = game
        self._fight_num = None
        self._fight_multiple = None
        self._fight_no_limit = None

    def start(self):
        self._game.sub(MSG_RES_RELOAD, self.lood)
        self.lood()

    def stop(self):
        pass

    def _no_limit(self, regions):
        def _fun(vip_lv):
            lv, num = vip_lv.strip().split(":")
            if int(num) == -1:
                self._fight_no_limit = int(lv)
        map(_fun, regions.split('|'))

    def lood(self):
        """
        资源加载
        """
        num_str = self._game.setting_mgr.setdefault(VIP_FIGHT_SPEED_NUM, VIP_FIGHT_SPEED_NUM_V)
        self._no_limit(num_str)
        multiple_str = self._game.setting_mgr.setdefault(VIP_FIGHT_MULTIPLE, VIP_FIGHT_MULTIPLE_V)
        self._fight_num = common.make_lv_regions(num_str)
        self._fight_multiple = self.make_lv_list(multiple_str)
        #self._game.pub(MSG_VIP_ATTR_LOAD)

    def set_for_active(self, multiple_str):
        """
        加载为活动的
        """
        self._fight_multiple = self.make_lv_list(multiple_str)


    def str2list(self, st):
        lis = []
        key_name, cur_mul, try_mul = st.strip().split(':')
        lis.append(int(key_name))
        lis.append(float(cur_mul))
        lis.append(float(try_mul))
        return tuple(lis)

    def make_lv_list(self, regions, accept_low=1):
        """ 实现根据等级获取对应物品功能, regions=[(lv,i), ...] """
        import bisect
        if isinstance(regions, (str, unicode)):
            #格式:0:1.0:1.5|1:1.5:2.0|4:2.0:2.0  [0:1.0:1.5)范围对应id=1, [1:1.5:2.0)范围对应id=2, [4:2.0,~)范围对应id=3
            regions = map(self.str2list, regions.split('|'))
        else:
            from corelib import log
            log.log_except(type(regions))
            return
        regions.sort()
        lvs = list(r[0] for r in regions)
        def _lv_regions(lv):
            i = bisect.bisect_right(lvs, lv) - 1
            if i < 0:
                if not accept_low:
                    return None
                i = 0
            return regions[i][1:]
        return _lv_regions

    def day_speed_num(self, player):
        return self._fight_num(player.data.vip)

    def dis_limit_vip(self):
        '''
        无限制使用vip战斗加速的等级
        '''
        return self._fight_no_limit

    def _multiple(self, player):
        return self._fight_multiple(player.data.vip)

    def current_multiple(self, player):
        return self._multiple(player)[0]

    def can_try_multiple(self, player):
        return self._multiple(player)[1]
