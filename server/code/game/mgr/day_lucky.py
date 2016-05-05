#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import json, sleep
from store.store import  StoreObj, GameObj


from game import BaseGameMgr
from game.base import errcode
from game.store import TN_P_DAYLUCKY
from game.glog.common import ITEM_ADD_DAY_LUCKY
from game.base.constant import (DAYLUCKY_MDRAW_NUM, DAYLUCKY_MDRAW_NUM_V,
    DAYLUCKY_DRAW_NUM, DAYLUCKY_DRAW_NUM_V, DAYLUCKY_CRATE_DAYS,
    DAYLUCKY_TYPE_BLOGIN, DAYLUCKY_TYPE_ALOGIN, MAIL_REWARD,
    IT_ROLE_STR, IKEY_TYPE, IT_ITEM_STR, RW_MAIL_DAYLUCKY,
    DAYLUCKY_CRATE_DAYS_V, DAYLUCKY_TYPE_NO,
)
from game.base.common import (current_time, is_pass_day, is_yesterday,
    get_days, RandomRegion, make_lv_regions,
)

#玩家相关数据key
#产生奖品的时间(ctime, int)
PLAYER_ATTR_CTIME = 'ctime'
#最高购买次数(mdraw, int)
PLAYER_ATTR_MDRAW = 'mdraw'
#本日购买次数(draw, int)
PLAYER_ATTR_DRAW = 'draw'
#已招到的配将对应资源表抽奖奖励id
PLAYER_ATTR_RIDS = 'rids'
#玩家抽奖时vip等级
PLAYER_ATTR_STATE = 'state'
#抽奖格子的总数量
MAX_BOXES = 9

class DayLuckyMgr(BaseGameMgr):
    """ 每日抽奖管理器 """
    def __init__(self, game):
        super(DayLuckyMgr, self).__init__(game)

    def start(self):
        self.vip_mdraw = self.fetch_res(DAYLUCKY_MDRAW_NUM, DAYLUCKY_MDRAW_NUM_V)
        self.vip_draw = self.fetch_res(DAYLUCKY_DRAW_NUM, DAYLUCKY_DRAW_NUM_V)

    def init_player_dayluck(self, player):
        """ 获取玩家每日抽奖数据 """
        player_dayluck = getattr(player.runtimes, TN_P_DAYLUCKY, None)
        if player_dayluck is None:
            player_dayluck = PlayDayLucky(player)
            player_dayluck.load()
            setattr(player.runtimes, TN_P_DAYLUCKY, player_dayluck)
        return player_dayluck

    def day_luck_enter(self, player):
        """ 玩家进入每日抽奖 """
        player_daylucky = self.init_player_dayluck(player)
        return player_daylucky.enter()

    def day_luck_draw(self, player, index):
        """ 玩家进行抽奖 """
        player_daylucky = self.init_player_dayluck(player)
        return player_daylucky.draw(index)

    def fetch_res(self, key, value):
        res_num = self._game.setting_mgr.setdefault(key, value)
        return make_lv_regions(res_num)

class DayLuckData(StoreObj):
    __slots__ = ('id', 'pid', 'ps', 'items', 'd')
    def init(self):
        self.id = None
        #玩家pid
        self.pid = 0
        #物品位置(ps, 列表)0=位置未确定, 确定的是已买入的位置
        self.ps = None
        #物品(items, 列表)
        self.items = ''
        #玩家的相关数据
        self.d = None

class DayLuck(GameObj):
    __slots__ = GameObj.__slots__
    TABLE_NAME = TN_P_DAYLUCKY
    DATA_CLS = DayLuckData
    def __init__(self, adict=None):
        super(DayLuck, self).__init__(adict=adict)

class PlayDayLucky(object):
    """ 玩家每日抽奖 """
    def __init__(self, player):
        self.player = player
        self.day_lucky = None

        #保存出现抽奖物品的配将的位置对应的资源表抽奖每日抽奖的奖励id
        #{index1:rid, ...}
        self.index_rid = {}

    def load(self):
        """ 获取玩家数据 """
        cond = dict(pid=self.player.data.id)
        obj_dicts = self.player._game.rpc_store.query_loads(TN_P_DAYLUCKY, cond)
        if obj_dicts:
            o = DayLuck(obj_dicts[0])
        else:
            o = DayLuck()
            o.data.pid = self.player.data.id
            o.data.ps = MAX_BOXES * [0]
            o.data.d = {PLAYER_ATTR_CTIME:current_time(), PLAYER_ATTR_MDRAW:self.fetch_draw,
                        PLAYER_ATTR_DRAW:0, PLAYER_ATTR_RIDS:[], PLAYER_ATTR_STATE:self.get_state}
        self.day_lucky = o

    def save(self, store):
        """ 保存数据 """
        self.day_lucky.save(store, forced=True)
    
    @property
    def get_state(self):
        """ 获取状态 """
        if self.player.data.vip:
            return 1
        return 0

    def handle_pass_day(self):
        """ 处理超过一天 """
        ctime = self.day_lucky.data.d[PLAYER_ATTR_CTIME]
        if is_pass_day(ctime):
            #判断是否是昨天(用来验证是否连续登陆)
            now = current_time()
            mdraw = self.day_lucky.data.d[PLAYER_ATTR_MDRAW]
            if is_yesterday(ctime):
                if self.day_lucky.data.d.has_key(PLAYER_ATTR_STATE) and \
                not self.day_lucky.data.d[PLAYER_ATTR_STATE] and \
                self.get_state:
                    mdraw += 1
                self.day_lucky.data.d[PLAYER_ATTR_MDRAW] = mdraw + 1
                if self.day_lucky.data.d[PLAYER_ATTR_MDRAW]  > self.fetch_mdraw:
                    self.day_lucky.data.d[PLAYER_ATTR_MDRAW] = self.fetch_mdraw
            else:
                self.day_lucky.data.d[PLAYER_ATTR_MDRAW] = self.fetch_draw
            self.day_lucky.data.d[PLAYER_ATTR_CTIME] = now
            self.day_lucky.data.d[PLAYER_ATTR_DRAW] = 0
            self.day_lucky.data.d[PLAYER_ATTR_STATE] = self.get_state
            self.day_lucky.data.ps = MAX_BOXES * [0]
            self.day_lucky.data.items = None

    def enter(self):
        """ 玩家进入每日抽奖(直接计算出生成抽取的物品和抽取的结果) """
        self.handle_pass_day()
        if not self.day_lucky.data.items:
            draw_rates = self._produce_items()
            self._lucky_darw(draw_rates)
        return True, self._pack_msg_data()

    def draw(self, index):
        """ 玩家进行抽奖 """
        mdraws = self.day_lucky.data.d[PLAYER_ATTR_MDRAW]
        draws = self.day_lucky.data.d[PLAYER_ATTR_DRAW]
        if draws >= mdraws:
            return False, errcode.EC_DAYLUCKY_NONUM
        d_draws = draws + 1
        v = -1 * d_draws
        if v not in self.day_lucky.data.ps:
            return False, errcode.EC_VALUE
        i = self.day_lucky.data.ps.index(v)
        self.day_lucky.data.d[PLAYER_ATTR_DRAW] = d_draws
        self.day_lucky.data.ps[i] = index
        res_item = self.day_lucky.data.items[i]
        #配将特殊处理
        res_items = [res_item]
        if res_item[IKEY_TYPE] == IT_ROLE_STR:
            rid = res_item[IT_ITEM_STR]
            bag_item = self.player.bag.add_items(res_items, log_type=ITEM_ADD_DAY_LUCKY, rid=rid)
            #记录抽到的配将
            res_rid = self.index_rid.get(i)
            res_rids = self.day_lucky.data.d[PLAYER_ATTR_RIDS]
            res_rids.append(res_rid)
        else:
            if not self.player.bag.can_add_items(res_items):
            #邮件通知玩家
                game = self.player._game
                res_rw_mail = game.res_mgr.reward_mails.get(RW_MAIL_DAYLUCKY)
                content = res_rw_mail.content
                game.mail_mgr.send_mails(self.player.data.id, MAIL_REWARD,
                res_rw_mail.title, RW_MAIL_DAYLUCKY, res_items, param=content)
                return True, self._pack_msg_data()
            else:
                bag_item = self.player.bag.add_items(res_items, log_type=ITEM_ADD_DAY_LUCKY)
        update_msg = bag_item.pack_msg()
        msg = {'update':update_msg}
        msg.update(self._pack_msg_data())
        return True, msg

    def _pack_msg_data(self):
        """ 打包抽奖数据返给客户端 """
        mdraws = self.day_lucky.data.d[PLAYER_ATTR_MDRAW]
        draws = self.day_lucky.data.d[PLAYER_ATTR_DRAW]
        is_draw = False
        items = []
        if self.day_lucky.data.d.has_key(PLAYER_ATTR_STATE):
            state = self.day_lucky.data.d[PLAYER_ATTR_STATE]
        else:
            self.day_lucky.data.d[PLAYER_ATTR_STATE] = self.get_state
            state = self.get_state
        if draws < mdraws:
            for index, q in enumerate(self.day_lucky.data.ps):
                if q < 0:
                    continue
                item = self.day_lucky.data.items[index].copy()
                item['index'] = q
                items.append(item)
                is_draw = True
            if is_draw:
                return {'mdraws':mdraws, 'draws':draws, 'items':items, 'state':state}
            return {'mdraws':mdraws, 'draws':draws, 'state':state}
        for index, item in enumerate(self.day_lucky.data.items):
            sitem = item.copy()
            sitem['index'] = self.day_lucky.data.ps[index]
            items.append(sitem)
        return {'mdraws':mdraws, 'draws':draws, 'items':items, 'state':state}

    def _produce_items(self):
        """ 随机生成抽奖的所有物品并返回抽奖概率 """
        rates, role_rates = self._get_rates()
        res_mgr = self.player._game.res_mgr
        res_daylucky_ids = []
        for (res_id, rate) in role_rates:
            res_daylucky_ids.append(res_id)
        ran = RandomRegion(rates)
        ran_daylucky_ids = ran.randoms(MAX_BOXES-len(role_rates))
        res_daylucky_ids.extend(ran_daylucky_ids)
        items = []
        draw_rates = []
        for index, res_daylucky_id in enumerate(res_daylucky_ids):
            res_daylucky = res_mgr.day_luckys.get(res_daylucky_id)
            rw = self.player._game.reward_mgr.get(res_daylucky.rid)
            res_item = rw.reward(params=self.player.reward_params())
            items.append(res_item[0])
            draw_rate = (index, res_daylucky.lrate)
            draw_rates.append(draw_rate)
            if res_item[0][IKEY_TYPE] == IT_ROLE_STR:
                self.index_rid[index] = res_daylucky.rid
        self.day_lucky.data.items = items
        return draw_rates

    def _get_rates(self):
        """ 获取物品出现的概率，返回物品出现概率和配将出现概率 """
        days = get_days(self.player.data.tNew)
        res_mgr = self.player._game.res_mgr
        no_rates = res_mgr.daylucky_cond_rates.get(DAYLUCKY_TYPE_NO)
        rates = no_rates[:]
        #注册号时间
        if days < self.fetch_days:
            login_type = DAYLUCKY_TYPE_BLOGIN
        else:
            login_type = DAYLUCKY_TYPE_ALOGIN
        login_rates = res_mgr.daylucky_cond_rates.get(login_type)
        rates.extend(login_rates)
        luckyed_roleids = self.day_lucky.data.d[PLAYER_ATTR_RIDS]
        role_rates = []
        rs_rates = []
        for (res_id, rate) in rates:
            res_daylucky = res_mgr.day_luckys.get(res_id)
            if res_daylucky.srate < 0 and res_daylucky.rid not in luckyed_roleids:
                role_rates.append((res_id, rate))
                continue
            rs_rates.append((res_id, rate))
        return rs_rates, role_rates

    def _lucky_darw(self, draw_rates):
        """ 计算抽奖结果 """
        draw_num = self.day_lucky.data.d[PLAYER_ATTR_MDRAW]
        ran = RandomRegion(draw_rates)
        #预防同时抽到两配将
        while 1:
            draw_role_num = 0
            ps = MAX_BOXES * [0]
            rs = ran.randoms(draw_num)
            for i, index  in enumerate(rs):
                ps[index] = -1 * (i + 1)
                item = self.day_lucky.data.items[index]
                if item[IKEY_TYPE] == IT_ROLE_STR:
                    draw_role_num += 1
            if draw_role_num < 2:
                self.day_lucky.data.ps = ps
                break
            sleep(1)

    @property
    def fetch_mdraw(self):
        """ 获取最多抽奖次数 """
        vip = self.player.data.vip
        return self.player._game.day_lucky_mgr.vip_mdraw(vip)

    @property
    def fetch_draw(self):
        """ 获取起始抽奖次数 """
        vip = self.player.data.vip
        return self.player._game.day_lucky_mgr.vip_draw(vip)

    @property
    def fetch_days(self):
        """ 创号多少天有特殊奖励 """
        return self.player._game.setting_mgr.setdefault(DAYLUCKY_CRATE_DAYS, DAYLUCKY_CRATE_DAYS_V)

