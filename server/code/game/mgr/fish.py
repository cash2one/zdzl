#!/usr/bin/env python
# -*- coding:utf-8 -*-
#钓鱼模块


from game import BaseGameMgr
from game.base.msg_define import MSG_LOGON, MSG_FISH_COIN3, MSG_FISH_UP, MSG_RES_RELOAD, MSG_FISH_UP_CHANCE
from game.base import common, errcode

from game.base.constant import VIP_FISH_BATCH, VIP_FISH_BATCH_V
from game.base.constant import PLAYER_ATTR_FISH, FISH_WHITE, IT_CHUM
from game.base.constant import FISH_WHITE_MAX, FISH_WHITE_MAX_V
from game.base.constant import FISH_WHITE_RID,FISH_WHITE_RID_V
from game.base.constant import FISH_NPC_TIME_V, FISH_NPC_TIME
from game.base.constant import FISH_FREE,FISH_ONCE,FISH_BATCH,FISH_NPC
from game.base.constant import FISH_ENTER_NEWSTART,FISH_ENTER_RESTART
from game.base.constant import MAIL_REWARD
from game.base.constant import FISH_LOSE,FISH_GOOD,FISH_PERFECT, FISH_NPC_QUALITY
from game.base.constant import IKEY_ID, IKEY_TYPE, IKEY_COUNT, IT_ITEM_STR
from game.base.constant import DIFF_TITEM_COIN3
from game.base.constant import WAITBAG_TYPE_FISHING
from game.glog.common import ITEM_COST_USE

from corelib    import log


def pack_msg_factory(src_d, dest_d):
    for k in src_d:
        if k in dest_d:
            dest_d[k].extend(src_d[k])
        else:
            dest_d[k] = src_d[k]

class FishMgr(BaseGameMgr):
    """ 玩家钓鱼系统的管理 """

    def __init__(self, game):
        super(FishMgr, self).__init__(game)
        self.judge_batch = None
        self.white_chums = self._game.setting_mgr.setdefault(FISH_WHITE_MAX, FISH_WHITE_MAX_V)
        self._active_chums = 0

    def start(self):
        self._game.player_mgr.sub(MSG_LOGON, self.player_logon)
        self._game.res_mgr.sub(MSG_RES_RELOAD, self.lood)
        self.lood()

    def init_player(self, player):
        fish = getattr(player.runtimes, PLAYER_ATTR_FISH, None)
        if fish is None:
            fish = PlayerFish(self, player)
            fish.load(player)
            setattr(player.runtimes, PLAYER_ATTR_FISH, fish)
        return fish

    def lood(self):
        """ 加载数据 """
        chum_max = self._game.setting_mgr.setdefault(FISH_WHITE_MAX, FISH_WHITE_MAX_V)
        self.set_white_chum_max(chum_max)

    def player_logon(self, player):
        self.init_player(player)

    def is_white_chum(self, iid):
        return iid == FISH_WHITE

    def is_chum(self, iid):
        """ 检查是不是鱼饵 """
        if not iid:
            return False
        check_item = self._game.res_mgr.items.get(iid)

        if check_item and check_item.type == IT_CHUM:
            return True
        return False

    def fish_enter(self, player):
        """ 进入钓鱼获取初始化数据 """
        fish = self.init_player(player)
        return fish.fish_enter(player)

    def fish_up(self, player, iid, num, qt):
        """ 起杆 """
        max_num = self.fish_max_num(player)
        if max_num < num:
            log.error("*******fish_up num:%s, max_num:%s, vip_level:%s*******", num, max_num, player.data.vip)
            return False, errcode.EC_NO_RIGHT
        fish = self.init_player(player)
        return fish.fish_up(player, iid, num, qt)

    def get_white_chum_max_sett(self):
        """ 得到全局设置中白色鱼饵钓鱼的最大允许次数 """
        return self.white_chums + self._active_chums

    def set_active_chum(self, num):
        self._active_chums = num

    def set_white_chum_max(self, num):
        """
        设置鱼饵的最大数量
        """
        self.white_chums = num

    def fish_max_num(self, player):
        try:
            num = self.judge_batch(player.data.vip)
        except TypeError:
            sett_str = player._game.setting_mgr.setdefault(VIP_FISH_BATCH, VIP_FISH_BATCH_V)
            self.judge_batch = common.make_lv_regions(sett_str)
            num = self.judge_batch(player.data.vip)
        return num


class FishData(object):
    def __init__(self):
        self.init()

    def init(self):
        self.zero_chum_num()
        self.flt = 0

    def zero_chum_num(self):
        #wn白色鱼饵使用次数
        self.wn = 0

    def increase_chum_num(self):
        self.wn += 1

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
        player.play_attr.update_attr({PLAYER_ATTR_FISH:self.to_dict()})

class PlayerFish(object):

    def __init__(self, mgr, player):
        self._mgr = mgr
        self.player = player
        #self.b_batch = False
        self.data = FishData()

    def __getstate__(self):
        return self.data

    def __setstate__(self, data):
        self.data = data

    def uninit(self):
        self.player = None
        self._mgr = None
        self.data = None

    def save(self, store):
        self.data.update_attr(self.player)

    def load(self, player):
        tObjDict = player.play_attr.get(PLAYER_ATTR_FISH)
        if not tObjDict:
            self.data.update_attr(player)
        t_obj_dict = player.play_attr.get(PLAYER_ATTR_FISH)
        self.data.update(t_obj_dict)

    def copy_from(self, player):
        fish = getattr(player.runtimes, PLAYER_ATTR_FISH)
        if fish:
            self.data = FishData()
            self.data.update(fish.data.to_dict())

    def fish_enter(self, player):
        """ 进入钓鱼获取初始化数据 """
        self.handle_pass_day(player)
        num = self._mgr.get_white_chum_max_sett() - self.data.wn
        if num < 0:
            num = 0
        return True, {'n':num}

    def _fish_c_up(self, player, iid, num, qt):
        """ 有色鱼饵的消耗 """
        bag_num = player.bag.get_item_num_by_iid(iid)
        if bag_num < num:
            #如果背包中没有
            return False, errcode.FISH_NOT_ENOUGH
        t_list = []
        for i in range(num):
            t_rs_item = self._fish_up(player, iid, qt)
            for t_d in t_rs_item:
                t_list.append(t_d)
        res_item = player._game.res_mgr.items.get(iid)
        if not bool(t_list):
            player.bag.cost_item(iid, num, log_type=ITEM_COST_USE,  pack_msg=True)
            player.pub(MSG_FISH_UP, num, res_item.quality)
            return True, {}
        #添加到待收物品
        c_data = player.bag.cost_item(iid, num, log_type=ITEM_COST_USE,  pack_msg=True)
        c_data = c_data[-1]
        oWaitItem = self.player.wait_bag.add_waitItem(WAITBAG_TYPE_FISHING, t_list)
        player.pub(MSG_FISH_UP, num, res_item.quality)
        rs = self.player.pack_msg_data(waits=[oWaitItem])
        pack_msg_factory(c_data, rs)
        return True, rs

    def _fish_w_up(self, player, iid, num, qt):
        """ 白色鱼饵起杆 """
        left_num = self._mgr.get_white_chum_max_sett() - self.data.wn
        if left_num < num:
            return False, errcode.FISH_NOT_ENOUGH
        t_list = []
        for i in range(num):
            t_rs_item = self._fish_up(player, iid, qt)
            for t_d in t_rs_item:
                t_list.append(t_d)

        if not bool(t_list):
            self.data.wn += num
            self.data.flt = common.current_time()
            self.data.update_attr(player)
            player.pub(MSG_FISH_UP, num, 0)
            return True, {}

        #添加到待收物品
        oWaitItem = self.player.wait_bag.add_waitItem(WAITBAG_TYPE_FISHING, t_list)
        player.pub(MSG_FISH_UP, num, 0)
        self.data.wn += num
        self.data.flt = common.current_time()
        self.data.update_attr(player)
        rs = self.player.pack_msg_data(waits=[oWaitItem])
        return True, rs

    def _fish_up(self, player, iid, qt = FISH_LOSE):
        """ 起杆 """
        t_d = self._mgr._game.res_mgr.fish_qualitya.get(iid)
        obj = t_d.get(qt)
        rid = obj.rid
        if rid == 0:
            #白色的最低品质无奖励
            return []
        t_rw = self._mgr._game.reward_mgr.get(rid)
        t_rs_item = t_rw.reward(params=player.reward_params())
        player.pub(MSG_FISH_UP_CHANCE, iid, t_rs_item)
        return t_rs_item

    def fish_up(self, player, iid, num, qt):
        """
        起杆
        num:起杆数目
        qt:技巧等级
        """
        if self._mgr.is_white_chum(iid):
            return self._fish_w_up(player, iid, num, qt)
        else:
            if not self._mgr.is_chum(iid):
                return False, errcode.FISH_ITEM_ERR
            return self._fish_c_up(player, iid, num, qt)

    def handle_pass_day(self, player):
        """ 处理超过一天(超过则更新数据) """
        if common.is_pass_day(self.data.flt):
            self.data.zero_chum_num()
            self.data.update_attr(player)

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------