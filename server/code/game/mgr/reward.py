#!/usr/bin/env python
# -*- coding:utf-8 -*-
""" 在线奖励模块 """

from random import randint
import sys
import copy
import bisect
import time
import functools


import app
from datetime import datetime

from corelib.message import observable
from corelib import spawn_later, sleep, log, spawn
from corelib.common import strptime, parse_time, make_lv_regions, make_lv_regions_list

from game import Game, BaseGameMgr
from game.item.reward import RewardItems
from store.store import StoreObj

from game.rpcs.player_handler import pack_msg
from game.glog.common import ITEM_ADD_REWARDCODE
from game.base import errcode, common

from game.base.constant import IT_CHUM
from game.base.constant import IT_FISH, IKEY_COUNT
from game.base.constant import DIFF_TITEM_EXP, IKEY_TYPE, IT_ITEM_STR, IKEY_ID
from game.base.constant import FISH_WHITE_MAX, FISH_WHITE_MAX_V
from game.base.constant import PLAYER_ATTR_REWARD, RW_MAIL_LEVEL_RANK, RW_MAIL_CBE_RANK
from game.base.constant import LEVELUPREWARD, LEVELUPREWARD_V, RW_MAIL_RECRUIT_ROLE
from game.base.constant import REWARDONLINE_TIME_END, REWARDONLINE_LOGIN_END, RW_MAIL_COST_COIN3
from game.base.constant import RW_MAIL_WEEKDAYTIME1, RW_MAIL_WEEKDAYTIME2
from game.base.constant import RW_MAIL_COIN3, RW_MAIL_LEVEL_UP, RW_MAIL_COIN3A, RW_MAIL_BOSSJOIN
from game.base.constant import REWARDONLINE_TYPE_TIME, REWARDONLINE_TYPE_LOGIN
from game.base.constant import RW_MAIL_LEVEL_GIFTS_SET, RW_MAIL_LEVEL_GIFTS_GET
from game.base.constant import RW_MAIL_FISHWATER, RW_MAIL_PAY_LEVEL, RW_MAIL_TBOX_NUM
from game.base.constant import MAIL_REWARD, MAIL_NORMAL, RW_MAIL_DAY, RW_MAIL_ONLINE, RW_MAIL_INTENSIFY
from game.base.constant import RW_MAIL_HOLDMAILTIME1, RW_MAIL_HOLDMAILTIME2
from game.base.constant import ACTIVEDATE1, ACTIVEDATE1_V, ACTIVEDATE2, ACTIVEDATE2_V
from game.base.constant import RW_MAIL_ARM, RW_MAIL_ROLE, RW_MAIL_ACTIVITY, RW_MAIL_SYS, RW_MAIL_HFATE
from game.base.constant import RW_MAIL_WORLDBOSSID, RW_WORLDBOSSID, RW_MAIL_VIP_PAY, RW_MAIL_BOSSDOUBLE
from game.base.constant import REWARDACTIVE_RECHARGE, REWARDACTIVE_WEPONUP, REWARDACTIVE_RECRUIT
from game.base.constant import COIN3REWARD, COIN3REWARD_V, COIN3REWARDPERSIST, COIN3REWARDPERSIST_V
from game.base.constant import REWARDACTIVE_RCH_DEFAULT, REWARDACTIVE_RCH_OPEN, REWARDACTIVE_RCH_CLOSE
from game.base.constant import REWARDACTIVE_CALL_BLUE, REWARDACTIVE_CALL_GREEN, REWARDACTIVE_CALL_PURPLE
from game.base.constant import RW_MAIL_WEEKDAYPAY
from game.base.constant import RW_MAIL_DAY1
from game.base.msg_define import MSG_START, MSG_COST_COIN3, MSG_REWARD_WORLDBOSS
from game.base.msg_define import MSG_EQUIP_UP, MSG_WEAPON_UP, MSG_ROLE_INVITE, MSG_LOGON, MSG_LOGOUT
from game.base.msg_define import MSG_UPGRADE, MSG_MAIL_FETCH, MSG_CHAPTER_FINISH, MSG_RES_RELOAD
from game.base.msg_define import MSG_VIP_PAY, MSG_HFATE_YB, MSG_SHOP_BUY, MSG_REWARD_BUY
from game.base.msg_define import MSG_FISH_USE_ITEM, MSG_TBOX_MDIE, MSG_DEEP_FLOOR_BOX, MSG_FISH_UP_CHANCE
from game.store.define import TN_P_ACTIVE

#from game.base.msg_define import MSG_VIP_ATTR_LOAD, MSG_VIP_ATTR_ACTIVE
from game.base.msg_define import MSG_REWARD_WORLDITEMS


from game.store.define import TN_ACTIVITY_LEVEL_GIFTS, TN_PLAYER, TN_P_ATTR

from .rank import CONST_LEVEL, CONST_ID, CONST_CBE, DESCENDING, CONST_EXP, CONST_PID

DAYTIME = 86400
fmt = '%y%m%d'
REWARD_STATUS = 'reward'
IN_COUNT = 1
OUT_COUNT = 2


def test_all_obj():
    """
    测试所有的活动， 主要打印日期，如果奖励id没有设置奖励则报错否则无反应
    """
    log.info("****global begin*****")
    Game.rpc_reward_mgr.test()
    log.info("****global end*****")
    log.info("****local begin*****")
    Game.instance.reward_mgr2.test()
    log.info("****local end*****")

def get_reward(rid, player):
    t_rw = player._game.reward_mgr.get(rid)
    if t_rw is None:
        return
    return t_rw.reward(params=player.reward_params())

def t_reward(rid):
    t_rw = Game.reward_mgr.get(rid)
    if t_rw is None:
        log.error("error rid:%s", rid)
        return
    r_items = t_rw.reward(params=None)
    #log.info("rid:%s, items:%s", rid, r_items)
    return r_items

def mk_time(t):
    k = time.mktime(t.timetuple())
    return k

@observable
class RpcRewardMgr(object):
    """全局奖励活动"""
    _rpc_name_ = 'rpc_reward_mgr'

    def __init__(self):
        self.rewards = {}
        app.sub(MSG_START, self.start)
        self.start_task = {}
        self.end_task = {}

    def start(self):
        self.load()
        Game.res_mgr.sub(MSG_RES_RELOAD, self.load)

    def clear_by_id(self, id):
        obj = self.rewards.get(id)
        if obj:
            obj.state = 0
            obj.clear()
            self.rewards.pop(id)

    def load(self):
        server_id = Game.rpc_client.get_server_id()
        ids = self.rewards.keys()
        for id, res in Game.res_mgr.reward_setts.iteritems():
            #判断数据记录删除了的
            if id in ids:
                ids.remove(id)
            #是否指定服
            if server_id not in res.sids and len(res.sids) > 0:
                log.info("global_reward id:%s is not in sids:%s, self_sid:%s", id, res.sids, server_id)
                self.clear_by_id(id)
                continue
            #关闭
            if not res.state:
                self.clear_by_id(id)
                log.info("global_reward id:%s state is close", id)
                continue
            #重新加载
            if id in self.rewards:
                obj = self.rewards[id]
                obj.reload(res)
                log.info("global_reward id:%s reload", id)
                #临时处理 自动启动功能
                if res.type in GLOBAL_AUTO_TASK:
                    self.auto_task(id, res)
                continue
            #新增
            cls = CLASS_LIST_SETT.get(res.type)
            if cls is None:
                log.info("global_reward type:%s is empty check the class is exit", res.type)
                continue
            if not cls.IS_GLOBAL:
                continue
            obj = cls(self)
            obj.id = id
            obj._build_data(res)
            obj.init()
            self.rewards[id] = obj
            log.info("add_new_reward type:%s id:%s, class:%s", res.type, id, cls.OBJ_NAME())
            #临时处理 自动启动功能
            if res.type in GLOBAL_AUTO_TASK:
                self.auto_task(id, res)
            #清除删除掉的奖励活动
        for id in ids:
            log.info("reward_set table remove _id:%d", id)
            self.clear_by_id(id)

    def _del_task(self, id):
        """
        删除
        """
        start_task = self.start_task.get(id, None)
        if start_task != None:
            start_task.kill(block=False)
        end_task = self.end_task.get(id, None)
        if end_task != None:
            end_task.kill(block=False)

    def auto_task(self, id, res):
        """设置活动的自动开启和结束"""
        now = common.current_time()
        self._del_task(id)
        if hasattr(res, 'begin') and now < res.begin:
            pass_time = res.begin - now
            self.start_task[id] = spawn_later(pass_time, self.auto_start, id, res)
            log.info("global_reward id: %s, will %s second start last", id, pass_time)
        if hasattr(res, 'end') and now < res.end:
            pass_time = res.end - now
            self.end_task[id] = spawn_later(pass_time, self.auto_end, id)
            log.info("global_reward id: %s, will %s second stop last", id, pass_time)

    def auto_start(self, id, res):
        obj = self.rewards[id]
        obj.reload(res)
        obj.init()
        self.start_task.pop(id)
        log.info("global_reward id:%s auto_start cur_time:%s", id, common.current_time())

    def auto_end(self, id):
        obj = self.rewards[id]
        obj.finish()
        self.clear_by_id(id)
        self.end_task.pop(id)
        log.info("global_reward id:%s auto_end cur_time:%s", id, common.current_time())

    def get_reward(self, id):
        return self.rewards.get(id)

    def test(self):
        log.info("len(%s)", len(self.rewards))
        for obj in self.rewards.values():
            obj.test()

def new_reward_mgr():
    mgr = RpcRewardMgr()
    return mgr

class RewardMgr(BaseGameMgr):
    """ 在线奖励管理 """

    def __init__(self, game):
        super(RewardMgr, self).__init__(game)
        self.r_code = RewardCode(self)
        self.rewards = {}
        self.start_task = {}
        self.end_task = {}

    def start(self):
        #监听玩家登录
        self.load()
        self._game.player_mgr.sub(MSG_LOGON, self.logon)
        self._game.res_mgr.sub(MSG_RES_RELOAD, self.load)

    def logon(self, player):
        p_onl_r = self.init_player(player)
        spawn_later(2, p_onl_r.delay_listen, player)

    def clear(self):
        for obj in self.rewards.itervalues():
            obj.clear()
            obj.state = 0
        self.rewards.clear()

    def clear_by_id(self, id):
        obj = self.rewards.get(id)
        if obj:
            obj.state = 0
            obj.clear()
            self.rewards.pop(id)

    def load(self):
        server_id = Game.rpc_client.get_server_id()
        ids = self.rewards.keys()
        PlayerOnlReward.build_old_sub_list()
        for id, res in Game.res_mgr.reward_setts.iteritems():
            #判断数据记录删除了的
            if id in ids:
                ids.remove(id)
            #是否指定服
            if server_id not in res.sids and len(res.sids) > 0:
                self.clear_by_id(id)
                self.clear_task(id)
                log.info("local_reward id:%s is not in sids:%s, self_sid:%s", id, res.sids, server_id)
                continue
            #关闭
            if not res.state:
                self.clear_by_id(id)
                self.clear_task(id)
                log.info("local_reward id:%s state is close", id)
                continue
            #重新加载
            if id in self.rewards:
                self.clear_task(id)
                obj = self.rewards[id]
                obj.reload(res)
                log.info("local_reward id:%s reload", id)
                #临时处理 自动启动功能
                if res.type in AUTO_TASK:
                    self.auto_task(id, res)
                continue
            #新增
            cls = CLASS_LIST_SETT.get(res.type)
            if cls is None:
                log.error("local_reward type:%s is empty check the class is exit", res.type)
                continue
            if cls.IS_GLOBAL:
                continue
            obj = cls(self)
            obj.id = id
            obj._build_data(res)
            obj.init()
            self.rewards[id] = obj
            log.info("local new_reward type:%s id:%s, class:%s", res.type, id, cls.OBJ_NAME())
            #临时处理 自动启动功能
            if res.type in AUTO_TASK:
                self.auto_task(id, res)
        #清除删除掉的奖励活动
        for id in ids:
            log.info("reward_set table remove _id:%d", id)
            self.clear_by_id(id)
        for p in self._game.player_mgr.players.values():
            p_onl_r = self.init_player(p)
            p_onl_r.re_sub()

    def clear_task(self, id):
        start_task = self.start_task.get(id, None)
        if start_task:
            start_task.kill()
            self.start_task.pop(id)

        end_task = self.end_task.get(id, None)
        if end_task:
            end_task.kill()
            self.end_task.pop(id)

    def _del_task(self, id):
        """
        删除
        """
        start_task = self.start_task.get(id, None)
        if start_task != None:
            start_task.kill(block=False)
        end_task = self.end_task.get(id, None)
        if end_task != None:
            end_task.kill(block=False)

    def auto_task(self, id, res):
        """设置活动的自动开启和结束"""
        now = common.current_time()
        self._del_task(id)
        if hasattr(res, 'begin') and now < res.begin:
            pass_time = res.begin - now
            self.start_task[id] = spawn_later(pass_time, self.auto_start, id, res)
            log.info("reward id: %s, will %s second start", id, pass_time)
        if hasattr(res, 'end') and now < res.end:
            pass_time = res.end - now
            self.end_task[id] = spawn_later(pass_time, self.auto_end, id)
            log.info("reward id: %s, will %s second stop", id, pass_time)

    def auto_start(self, id, res):
        obj = self.rewards[id]
        obj.reload(res)
        self.start_task.pop(id)
        log.info("reward auto_start cur_time:%s, sett_id is :%s", common.current_time(), id)

    def auto_end(self, id):
        obj = self.rewards[id]
        obj.finish()
        self.clear_by_id(id)
        self.end_task.pop(id)
        log.info("reward auto_end cur_time:%s, sett_id is :%s", common.current_time(), id)

    def init_player(self, player):
        try:
            p_onl_r = player.runtimes.p_onl_r
        except AttributeError:
            p_onl_r = PlayerOnlReward()
            p_onl_r.load(player)
            player.runtimes.p_onl_r = p_onl_r
        return p_onl_r

    def reward_time(self, player):
        """ 领取在线时长奖励 """
        p_onl_r = self.init_player(player)
        return True, None

    def active_enter(self, player):
        """ 活动奖励的进入 """
        p_onl_r = self.init_player(player)
        return p_onl_r.active_enter(player)

    def active_fetch(self, player, t, level):
        """ 活动奖励的领奖 """
        p_onl_r = self.init_player(player)
        rs, data = p_onl_r.active_fetch(player, t, level)
        if rs:
            return p_onl_r.active_enter(player)
        return rs, data

    def reward_code(self, player, strCode):
        """ 兑换码领取 """
        return self.r_code.reward(player, strCode)

    def get_reward(self, id):
        return self.rewards.get(id)

    def test(self):
        log.info("len(%s)", len(self.rewards))
        for obj in self.rewards.values():
            obj.test()


class RewardData(object):
    """ 在线奖励的数据 """
    def __init__(self):
        self.init()

    def init(self):
        self.ft = 0        #上次领取在线奖励的时间fetchtime
        self.fot = 0       #在线奖励邮件收取的次数
        self.ot = 0        #在线奖励发出去的次数onltimes
        self.wpl = 0       #该值代表玩家目前武器升阶的最高阶只加不减
        self.ccl = []      #召唤同伴的最高类型只加不减 1 = 蓝色 2 = 绿色 3 = 紫色
        self.outc = 0      #玩家当日登录的次数
        self.coin3a = 0    #元宝奖励登陆的天数非连续
        self.coin3aft = 0  #元宝奖励登陆的天数非连续
        self.coin3b = 0    #元宝奖励连续登陆的天数
        self.coin3bft = 0  #元宝奖励发放奖励的时间
        self.coin3c = 0    #天天送奖励
        self.coin3cft = 0  #天天送奖励的时间
        self.coinYb = 0    #累计消费元宝一定数量发送奖励(即时发送)
        self.fhn = 0       #钓鱼使用的次数
        self.wkt1 = 0      #周末时间登陆奖励计时开始点
        self.wkt2 = 0      #周末时间登陆奖励计时结束点
        self.wkn = 1       #周末时间奖励发送的次数
        self.mft1 = 0      #实时时间登陆奖励计时开始点
        self.mft2 = 0      #实时时间登陆奖励计时结束点
        self.mfm = 0       #当日是不是有邮件没领取
        self.mfn = 1       #实时时长邮件奖励发送的次数
        self.mfnew = 1     #实时时长邮件奖励是不是可以开始下一个邮件

    def to_dict(self):
        return self.__dict__

    def update_attr(self, player):
        """ 更新玩家属性表 """
        player.play_attr.update_attr({PLAYER_ATTR_REWARD:self.to_dict()})

    def update(self, adict):
        """ 更新 """
        __dict__ = self.__dict__
        for k in __dict__.iterkeys():
            if k not in adict:
                continue
            __dict__[k] = adict[k]

    def zero_coin3(self):
        self.coin3 = 0


class PlayerOnlReward(object):
    """ 玩家在线奖励 """

    LISTEN_NOSUB = []
    LISTEN_SUB = []
    OLD_LISTEN_SUB = []

    def __init__(self):
        self.data = RewardData()
        self.subs = {}
        self._player = None

    def __getstate__(self):
        return self.data

    def __setstate__(self, data):
        self.data = data

    def uninit(self):
        self._player = None
        self.data = None
        self.subs = {}

    def save(self, store):
        self.data.update_attr(self._player)

    def _reward_first(self):
        if self.data.ot <= 0 or self.data.fot <= 0:
            self.data.ot = 1
            self.data.fot = 1
            self.data.ft = common.current_time()

    def load(self, player):
        self._player =  player      #玩家等级升级时 未传参数player所以保存在自己对象
        p_onlr_attr = player.play_attr.get(PLAYER_ATTR_REWARD, None)
        if not p_onlr_attr:
            self.data.update_attr(player)
        else:
            self.data.update(p_onlr_attr)
        self._reward_first()
        self.handle_pass_day(player)

    def copy_from(self, player):
        p_onl_r = getattr(player.runtimes, 'p_onl_r')
        if p_onl_r:
            self.data = RewardData()
            self.data.update(p_onl_r.data.to_dict())

    def active_enter(self, player):
        """ 进入活动奖励面板获得剩下的活动奖励权限 """
        return True, dict()

    def active_fetch(self, player, t, level):
        """ 领取活动奖励 """
        return True, None

    def handle_pass_day(self, player):
        """ 处理超过一天(超过则更新数据) """
        if common.is_pass_day(self.data.ft):
            self.data.ot = REWARDONLINE_TIME_END + 1
            self.data.outc = 0
            self.data.fhn = 0
            self.data.update_attr(player)
            return True
        return False

    def _run(self, player):
        if not player:
            player = self._player
        player.unsub(MSG_CHAPTER_FINISH, self._run)
        for func in self.LISTEN_NOSUB:
            if not player.logined:
                return
            func(self, player)

        def _wrap_func(func):
            def _func(*args, **kw):
                func(self, self._player, *args, **kw)
            return _func
        for msg, func in self.LISTEN_SUB:
            wfunc = self.subs[(msg, func)] = _wrap_func(func)
            player.sub(msg, wfunc)

    def delay_listen(self, player):
        if not player:
            player = self._player
        if not player.logined:
            return
        if player.is_guide:
            player.sub(MSG_CHAPTER_FINISH, self._run)
            return
        self._run(player)

    def re_sub(self):
        """
        玩家一直在线活动开启的从新sub
        """
        def _wrap_func(func):
            def _func(*args, **kw):
                func(self, self._player, *args, **kw)
            return _func
        for msg, func in self.LISTEN_SUB:
            if (msg, func) in self.OLD_LISTEN_SUB:
                continue
            wfunc = self.subs[(msg, func)] = _wrap_func(func)
            self._player.sub(msg, wfunc)

    def unsub(self, msg, func):
        """ 注销监听 """
        wfunc = self.subs.pop((msg, func), None)
        if not wfunc:
            return False
        self._player.unsub(msg, wfunc)
        return True

    @classmethod
    def build_old_sub_list(cls):
        """
        得到旧的监听保存在本地
        """
        PlayerOnlReward.OLD_LISTEN_SUB = copy.copy(PlayerOnlReward.LISTEN_SUB)

    @classmethod
    def register_nosub_list(cls, func):
        """跳过初章就直接调用的注册这里"""
        if not callable(func):
            return
        if func in cls.LISTEN_NOSUB:
            return
        cls.LISTEN_NOSUB.append(func)

    @classmethod
    def unregister_nosub_list(cls, func):
        if func not in cls.LISTEN_NOSUB:
            return
        cls.LISTEN_NOSUB.remove(func)

    @classmethod
    def register_sub_list(cls, msg, func):
        """跳过初章开始监听当调用func时把self加传过去的注册这"""
        if not callable(func):
            return
        if (msg, func) in cls.LISTEN_SUB:
            return
        cls.LISTEN_SUB.append((msg, func))

    @classmethod
    def unregister_sub_list(cls, msg, func):
        if not callable(func):
            return
        if (msg, func) not in cls.LISTEN_SUB:
            return
        cls.LISTEN_SUB.remove((msg, func))

def wrap_handle(func):
    @functools.wraps(func)
    def _func(self, p_onl_r, player, *args, **kw):
        if self.state:
            func(self, p_onl_r, player, *args, **kw)
        else:
            self.unsub(p_onl_r)
    return _func

def wrap_handle_begin_end(func):
    @functools.wraps(func)
    def _func(self, p_onl_r, player, *args, **kw):
        #判断奖励开关是否打开
        if not self.state:
            self.unsub(p_onl_r)
            return
        #活动时间检测
        ct = common.current_time()
        if ct < self.begin:
            return
        if ct > self.end:
            self.unsub(p_onl_r)
            return
        func(self, p_onl_r, player, *args, **kw)
    return _func

def wrap_ghandle_begin_end(func):
    @functools.wraps(func)
    def _func(self, *args, **kw):
        #判断奖励开关是否打开
        if not self.state:
            self.unsub()
            return
        #活动时间检测
        ct = common.current_time()
        if ct < self.begin:
            return
        if ct > self.end:
            self.unsub()
            return
        func(self, *args, **kw)
    return _func

class Base(object):

    IS_GLOBAL = 0
    REWARD_TYPE = MAIL_REWARD
    REGISTER_CLASS = PlayerOnlReward
    TYPE = 1

    def __init__(self, mgr):
        self._mgr = mgr
        self.state = 1
        self.id = None

    def fmt_begin(self):
        if hasattr(self, "begin"):
            o = time.localtime(self.begin)
            log.info("%s:%s:%s:%s", o.tm_year, o.tm_mon, o.tm_mday,o.tm_hour)
            return
        log.info("%s has no begin attr", self.OBJ_NAME())
        return

    def fmt_end(self):
        if hasattr(self, "end"):
            o = time.localtime(self.end)
            log.info("%s:%s:%s:%s", o.tm_year, o.tm_mon, o.tm_mday,o.tm_hour)
            return
        log.info("%s has no end attr", self.OBJ_NAME())
        return

    def test_reward(self):
        """测试reward_sett表里面的rid能不能得到奖励"""
        log.info('is need add in class %s', self.OBJ_NAME())

    def test(self):
        log.info("-------begin---------- %s --------begin---------", self.OBJ_NAME())
        self.fmt_begin()
        self.test_reward()
        self.fmt_end()
        log.info("-------end------------ %s --------end-----------", self.OBJ_NAME())

    @classmethod
    def OBJ_NAME(cls):
        return cls.__name__

    def init(self):
        pass

    def clear(self):
        self.state = False

    def finish(self):
        """
        活动完成以后
        设置mgr里面的属性为非活动时间的状态或者有监听的需要撤销监听
        """
        self.clear()

    def reload(self, res):
        self._build_data(res)

    def _build_data(self, res):
        """构造要使用的数据"""
        pass

    def stop(self):
        pass

    def _send_mail(self, pid, items, cont_dict, mail_type=None, rid=0):
        """ 得到奖励 目前是直接发送邮件给玩家 """
        try:
            #存在不在线的活动奖励发放
            #if not Game.rpc_player_mgr.have(pid):
            #    return
            if mail_type is None:
                mail_type = self.REWARD_TYPE
            rw_mail = Game.res_mgr.reward_mails.get(mail_type)
            text = rw_mail.content if rw_mail.content == '' else  rw_mail.content % cont_dict
            log.info("pid:(%s) rid:(%s) send_mail the class is:%s", pid, rid, self.OBJ_NAME())
            param = text
            content = mail_type
            Game.mail_mgr.send_mails(pid, MAIL_REWARD, rw_mail.title, content, items, param=param, rid=rid)
            if items is None:
                log.error("send_mail class is:%s items is None, pid:%s", self.OBJ_NAME(), pid)
        except:
            log.log_except()


class RewardCode(Base):
    """ 兑换码奖励 """

    def _build_data(self):
        pass

    def reward(self, player, str_c, pack_msg = True):
        d = player.data
        rs, data = player._game.rpc_ex_code_mgr.pre_exchange(str_c, d.uid, d.id)
        if not rs:
            return rs, data
        items = get_reward(data, player)
        if items is None:
            return 0, errcode.EC_VALUE
        if player.bag.can_add_items(items):
            player._game.rpc_ex_code_mgr.exchange(str_c, d.uid, d.id)
            bag_items = player.bag.add_items(items, log_type=ITEM_ADD_REWARDCODE)
            return True, bag_items.pack_msg(coin=True)
        else:
            player._game.rpc_ex_code_mgr.pop_code(str_c)
            return False, errcode.EC_BAG_FULL



#----------------------------目前是永久开启的----------------------------
class Online(Base):
    """ 在线时长奖励 """

    REWARD_TYPE = RW_MAIL_ONLINE
    LEVEL_START = 5
    TYPE = 1

    def __init__(self, mgr):
        super(Online, self).__init__(mgr)
        self.pid2tasks = {}             #{pid:one_task}

    def init(self):
        #注册登陆的消息
        self.REGISTER_CLASS.register_nosub_list(self.handle_login)
        #注册等级升级
        self.REGISTER_CLASS.register_sub_list(MSG_UPGRADE, self.handle_level_up)
        #注册邮件收取的
        self.REGISTER_CLASS.register_sub_list(MSG_MAIL_FETCH, self.handle_mail_fetch)

    def clear(self):
        self.REGISTER_CLASS.unregister_nosub_list(self.handle_login)
        for pid in self.pid2tasks:
            self.del_task(pid)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_UPGRADE, self.handle_level_up)
        p_onl_r.unsub(MSG_MAIL_FETCH, self.handle_mail_fetch)

    def test_reward(self):
        log.info("rid_dict:%s, time_dict:%s", self.rid_dict, self.time_dict)
        for rid in self.rid_dict.values():
            t_reward(rid)

    def _build_data(self, res):
        #分解一个元素->(奖励条件:能获得奖励的次数:奖励id)
        self.rid_dict = {}
        self.time_dict = {}
        rid_strs = res.data.split("|")
        for comp in rid_strs:
            value, num, rid = comp.split(":")
            value, num, rid = int(value), int(num), int(rid)
            self.rid_dict[value] = rid
            self.time_dict[value] = num

    def run(self, p_onl_r, player):
        data = p_onl_r.data
        if player.data.level < self.LEVEL_START:
            return False
        else:#反注册升级监听,释放资源
            p_onl_r.unsub(MSG_UPGRADE, self.handle_level_up)

        if not (0 < data.ot <= REWARDONLINE_TIME_END):
            return False
        if p_onl_r.data.fot == p_onl_r.data.ot:
            self.new_task(p_onl_r, player)
            return True
        return False

    def handle_login(self, p_onl_r, player):
        """处理登陆的"""
        if p_onl_r.handle_pass_day(player):
            self.unsub(p_onl_r)
            return
        self.run(p_onl_r, player)

    @wrap_handle
    def handle_level_up(self, p_onl_r, player, level):
        """处理升级的"""
        if p_onl_r.handle_pass_day(player):
            self.unsub(p_onl_r)
            return
        self.run(p_onl_r, player)

    @wrap_handle
    def handle_mail_fetch(self, p_onl_r, player, email_type):
        """处理邮件收取的,玩家收取上一封在线奖励后才开始计算下一次奖励"""
        if p_onl_r.handle_pass_day(player):
            self.unsub(p_onl_r)
            return
        if int(email_type) != self.REWARD_TYPE:
            return
        data = p_onl_r.data
        data.fot += 1
        data.ft = common.current_time()
        data.update_attr(player)
        self.del_task(player.data.id)
        self.run(p_onl_r, player)

    def player_logout(self, pid):
        """处理玩家下线"""
        self.del_task(pid)

    def del_task(self, pid):
        task_ = self.pid2tasks.get(pid, None)
        if task_ is None:
            return
        task_.kill(block=False)
        del self.pid2tasks[pid]

    def reward(self, p_onl_r, player):
        """奖励"""
        if p_onl_r.handle_pass_day(player):
            self.unsub(p_onl_r)
            return
        d = p_onl_r.data
        rid = self.rid_dict.get(d.ot)
        times = self.time_dict.get(d.ot)
        items = get_reward(rid, player)
        self._send_mail(player.data.id, items, dict(times=(max(times/60, 1))), rid=rid)
        d.ot += 1
        d.update_attr(player)

    def get_sleep_times(self, p_onl_r, player):
        d = p_onl_r.data
        times = self.time_dict.get(d.ot)
        tLogout = player.data.tLogout
        if tLogout == 0:
            #玩家初次创建未下过线
            sleep_times = times
        elif d.ft >= tLogout:
            #该次计算前绝对已领过一次或者多次奖
            already_t = common.current_time() - d.ft
            sleep_times = times - already_t
        else:
            #上次玩家下线时已经经过的时间
            already_t = tLogout - d.ft
            sleep_times = times - already_t
        return max(0, sleep_times)

    def new_task(self, p_onl_r, player):
        """新建一个线程"""
        task_ = self.pid2tasks.get(player.data.id, None)
        if task_ is not None:
            return
        #监听退出消息
        player.reg_logout(self)
        sleep_times = self.get_sleep_times(p_onl_r, player)
        fmt_string = "login_time reward start at %s times later"# current time:%s"
        time_obj = time.localtime(common.current_time())
        log.info(fmt_string, sleep_times)#, (str(time_obj.tm_hour) + ":" + str(time_obj.tm_min)+ ":" + str(time_obj.tm_sec)))
        self.pid2tasks[player.data.id] = spawn_later(sleep_times, self.reward, p_onl_r, player)

class Land(Base):
    """ 每日登陆次数奖励 """
    REWARD_TYPE = RW_MAIL_DAY
    TYPE = 2

    def init(self):
        self.REGISTER_CLASS.register_nosub_list(self.reward)

    def clear(self):
        self.REGISTER_CLASS.unregister_nosub_list(self.reward)

    def test_reward(self):
        log.info("rid_dict:%s, land_dict:%s", self.rid_dict, self.land_dict)
        for rid in self.rid_dict.values():
            t_reward(rid)

    def _build_data(self, res):
        #分解一个元素->(奖励条件:能获得奖励的次数:奖励id)
        self.land_dict = {}
        self.rid_dict = {}
        self._dict_keys = []
        rid_strs = res.data.split("|")
        for comp in rid_strs:
            value, num, rid = comp.split(":")
            value, num, rid = int(value), int(num), int(rid)
            self.rid_dict[value] = rid
            self.land_dict[num] = value
            self._dict_keys.append(num)
        self._dict_keys.sort()

    def reward(self, p_onl_r, player):
        data = p_onl_r.data
        data.outc += 1
        log.info("reward_land(%s) data.ot is :%s, fot is: %s",player.data.id,
                data.ot, data.fot)
        #在[REWARDONLINE_TIME_END, REWARDONLINE_LOGIN_END]这个范围是登录次数奖励
        if not (REWARDONLINE_TIME_END < data.ot < REWARDONLINE_LOGIN_END):
            data.update_attr(player)
            return
        pid = player.data.id
        for num in self._dict_keys:
            value = self.land_dict.get(num)
            if data.outc >= num and value + REWARDONLINE_TIME_END >= data.ot:
                rid = self.rid_dict.get(value)
                items = get_reward(rid, player)
                data.ot += 1
                data.ft = common.current_time()
                data.update_attr(player)
                self._send_mail(pid, items, dict(c=num), rid=rid)
                break


class Invite(Base):
    """ 配将招募奖励 """

    REWARD_TYPE = RW_MAIL_ROLE
    TYPE = 3

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_ROLE_INVITE, self.reward)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_ROLE_INVITE, self.reward)

    def test_reward(self):
        log.info("rid_dict:%s, dict_keys:%s", self.rid_dict, self.dict_keys)
        for rid in self.rid_dict.values():
            t_reward(rid)

    def _build_data(self, res):
        self.rid_dict = {}
        self.dict_keys = []
        rid_strs = res.data.split("|")
        for comp in rid_strs:
            level, rid = comp.split(":")
            level, rid = int(level), int(rid)
            self.rid_dict[level] = rid
            self.dict_keys.append(level)
        self.item_mgr = self._mgr._game.item_mgr

    def update_old(self, data, player):
        """
        转类型修复招募了蓝色英雄却无法招募绿色的英雄的问题
        """
        cg_list = []
        for qt in xrange(data.ccl):
            cg_list.append(qt+1)
        data.ccl = cg_list
        data.update_attr(player)

    @wrap_handle
    def reward(self, p_onl_r, player, rid, _player):
        data = p_onl_r.data
        res_role = Game.res_mgr.roles.get(rid)
        if isinstance(data.ccl, int):
            self.update_old(data, player)
        if res_role.is_main or res_role.quality in data.ccl:
            return
        data.ccl.append(res_role.quality)
        if res_role.quality in self.dict_keys:
            color = '#' + self.item_mgr.get_color(res_role.quality)
            rid = self.rid_dict.get(res_role.quality)
            items = get_reward(rid, player)
            self._send_mail(player.data.id, items,
                dict(rname=res_role.name, color=color), rid=rid)
        data.update_attr(player)


class Weapon(Base):
    """ 武器升级奖励 """
    REWARD_TYPE = RW_MAIL_ARM
    TYPE = 4

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_WEAPON_UP, self.reward)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_WEAPON_UP, self.reward)

    def test_reward(self):
        log.info("rid_dict:%s, dict_keys:%s", self.rid_dict, self.dict_keys)
        for rid in self.rid_dict.values():
            t_reward(rid)

    def _build_data(self, res):
        self.rid_dict = {}
        self.dict_keys = []
        rid_strs = res.data.split("|")
        for comp in rid_strs:
            level, rid = comp.split(":")
            level, rid = int(level), int(rid)
            self.rid_dict[int(level)] = rid
            self.dict_keys.append(level)
        self.arms = self._mgr._game.res_mgr.arms
        self.item_mgr = self._mgr._game.item_mgr

    @wrap_handle
    def reward(self, p_onl_r, player, level, arm_id, _player, role_id):
        data = p_onl_r.data
        if level <= data.wpl:
            return
        data.wpl = level
        if level in self.dict_keys:
            arm_obj = self.arms.get(arm_id)
            color = '#' + self.item_mgr.get_color(arm_obj.quality)
            rid = self.rid_dict.get(level)
            items = get_reward(rid, player)
            self._send_mail(player.data.id, items, dict(armLv = level,
                    arm=arm_obj.name, color=color), rid=rid)
        data.update_attr(player)


class LevelUp(Base):
    """ 玩家升级奖励 """

    REWARD_TYPE = RW_MAIL_LEVEL_UP
    TYPE = 7

    def __init__(self, mgr):
        super(LevelUp, self).__init__(mgr)
        self.mail_types = {}
        self.rids = {}

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_UPGRADE, self.reward)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_UPGRADE, self.reward)

    @wrap_handle_begin_end
    def reward(self, p_onl_r, player, level, pack_msg = True):
        rid = self.rids.get(level, None)
        mail_type = self.mail_types.get(level, None)
        if not rid or not mail_type:
            return
        items = get_reward(rid, player)
        self._send_mail(player.data.id, items, dict(level = level), mail_type=mail_type, rid=rid)

    def test_reward(self):
        log.info("rids:%s, mail_types:%s", self.rids, self.mail_types)
        for rid in self.rids.values():
            t_reward(rid)

    def _build_data(self, res):
        """
        res.data = 等级:邮件类型:奖励id
        """
        self.rids = {}
        self.mail_types = {}
        for one_comp in res.data.split("|"):
            lv, mail_type, rid = one_comp.split(":")
            lv, mail_type, rid = int(lv), int(mail_type), int(rid)
            self.mail_types[lv] = mail_type
            self.rids[lv] = rid
        self.begin = res.begin
        self.end = res.end


class RecruitRole(Base):
    """玩家招募武将奖励"""
    TYPE = 11

    def _build_data(self, res):
        #data  n:1|q:1|rid:1
        self.print_res_data = res.data
        self.data = common.str2dict(res.data, ktype=str, vtype=int)
        self.begin = res.begin
        self.end = res.end

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_ROLE_INVITE, self.get_role)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_ROLE_INVITE, self.get_role)

    @wrap_handle
    def get_role(self, p_onl_r, player, rid, _player):
        #活动时间检测
        ct = common.current_time()
        if ct < self.begin or ct > self.end:
            return
        #招募武将检测
        if not self.check(player, rid):
            return
        num = 0
        for role in player.roles.iter_roles():
            if self.check(player, role.data.rid):
                num += 1
        #奖励发放判断
        if num == self.data['n']:
            rid = self.data['rid']
            items = get_reward(rid, player)
            if items is None:
                log.error('RecruitRole items is None, pid(%s), rid(%s)', player.data.id, rid)
                return
            cont_dict = dict()
            self._send_mail(player.data.id, items, cont_dict, mail_type=RW_MAIL_RECRUIT_ROLE, rid=rid)

    def check(self, player, rid):
        res_role = player._game.res_mgr.roles.get(rid)
        if res_role is None:
            log.error('RecruitRole res_role is None, pid(%s), rid(%s)', player.data.id, rid)
            return False
        if res_role.quality != self.data['q']:
            return False
        return True



#----------------------------需要动态开启关闭----------------------------
class Interval(Base):
    """开服元宝奖励无连续登陆的处理"""

    REWARD_TYPE = RW_MAIL_COIN3
    TYPE = 5

    def init(self):
        self.REGISTER_CLASS.register_nosub_list(self.reward)

    def clear(self):
        super(Interval, self).clear()
        self.REGISTER_CLASS.unregister_nosub_list(self.reward)

    def first_in_do(self, p_onl_r, player):
        """玩家第一次进入活动奖励要做的临界点处理"""
        data = p_onl_r.data
        if data.coin3aft <= self.begin:
            data.coin3a = 0
            data.coin3aft = 0
            data.update_attr(player)

    def reward(self, p_onl_r, player):
        data = p_onl_r.data
        if not common.is_pass_day(data.coin3aft):
            return False, None
        if not (self.begin <= common.current_time() <= self.end):
            return False, errcode.EC_VALUE
        self.first_in_do(p_onl_r, player)
        coin3a = data.coin3a + 1
        rid, lv = self.get_rid(coin3a)
        if not rid or lv > player.data.level:
            return False, errcode.EC_VALUE
        items = get_reward(rid, player)
        self._send_mail(player.data.id, items, dict(), rid=rid)
        data.coin3a = coin3a
        data.coin3aft = common.current_time()
        data.update_attr(player)

    def test_reward(self):
        log.info("res.data:%s", self.print_data)
        l = self.print_data.split("|")
        for item in l:
            n, rid, lv  = item.split(":")
            n, rid, lv = int(n), int(rid), int(lv)
            t_reward(rid)

    def _build_data(self, res):
        t_str = res.data
        self.print_data = res.data
        self.get_rid = make_lv_regions_list(t_str)
        self.begin = res.begin
        self.end = res.end


class Hold(Base):
    """开服元宝奖励有连续登陆的处理"""

    REWARD_TYPE = RW_MAIL_COIN3A
    TYPE = 6

    def init(self):
        self.REGISTER_CLASS.register_nosub_list(self.reward)

    def clear(self):
        super(Hold, self).clear()
        self.REGISTER_CLASS.unregister_nosub_list(self.reward)

    def is_interval(self, p_onl_r):
        """是不是间断了一天登陆"""
        return common.zero_day_time() - p_onl_r.data.coin3bft >= DAYTIME

    def first_in_do(self, p_onl_r, player):
        """玩家第一次进入活动奖励要做的临界点处理"""
        data = p_onl_r.data
        if data.coin3bft <= self.begin:
            data.coin3b = 0
            data.coin3bft = 0
            data.update_attr(player)

    def reward(self, p_onl_r, player):
        data = p_onl_r.data
        if not common.is_pass_day(data.coin3bft):
            return False, None
        if not (self.begin <= common.current_time() <= self.end):
            return False, errcode.EC_VALUE
        self.first_in_do(p_onl_r, player)
        if self.is_interval(p_onl_r):
            #间断一天从第二天开始领取
            data.coin3b = 0
        coin3b = data.coin3b + 1
        rid, lv = self.get_rid(coin3b)
        if not rid or lv > player.data.level:
            return False, errcode.EC_VALUE
        items = get_reward(rid, player)
        self._send_mail(player.data.id, items, dict(), rid=rid)
        data.coin3b = coin3b
        data.coin3bft = common.current_time()
        data.update_attr(player)

    def test_reward(self):
        log.info("res.data:%s", self.print_data)
        l = self.print_data.split("|")
        for item in l:
            n, rid, lv  = item.split(":")
            n, rid, lv = int(n), int(rid), int(lv)
            t_reward(rid)

    def _build_data(self, res):
        self.print_data = res.data
        t_str = res.data
        self.get_rid = make_lv_regions_list(t_str)
        self.begin = res.begin
        self.end = res.end


class DateTo(Interval):
    """天天送登陆送奖励活动 活动期间指定的日期获得指定的奖励"""

    REWARD_TYPE = RW_MAIL_DAY1
    TYPE = 15

    def first_in_do(self, p_onl_r, player):
        """玩家第一次进入活动奖励要做的临界点处理"""
        data = p_onl_r.data
        if data.coin3cft <= self.begin:
            data.coin3c = 0
            data.coin3cft = 0
            data.update_attr(player)

    def reward(self, p_onl_r, player):
        data = p_onl_r.data
        if not common.is_pass_day(data.coin3cft):
            return False, None
        ct = common.current_time()
        if not (self.begin <= ct <= self.end):
            return False, errcode.EC_VALUE
        self.first_in_do(p_onl_r, player)
        days = int((ct - self.begin)/DAYTIME)
        rid, lv = self.get_rid(days)
        if not rid or player.data.level < lv:
            return False, errcode.EC_VALUE
        items = get_reward(rid, player)
        self._send_mail(player.data.id, items, dict(), rid=rid)
        data.coin3c = days
        data.coin3cft = common.current_time()
        data.update_attr(player)


class Fish(Base):
    """钓鱼翻倍活动"""

    TYPE = 16

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_FISH_USE_ITEM, self.reward)

    def clear(self):
        super(Fish, self).clear()
        self.REGISTER_CLASS.unregister_sub_list(MSG_FISH_USE_ITEM, self.reward)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_FISH_USE_ITEM, self.reward)

    def test_reward(self):
        log.info("*****res.data no rid can not print*****")

    def _build_data(self, res):
        try:
            self.multiple, self.max_num = res.data.split("|")
            self.multiple = int(self.multiple)
            self.max_num = int(self.max_num)
        except:
            self.multiple, self.max_num = 2, 10
        self.begin = res.begin
        self.end = res.end

    @wrap_handle
    def reward(self, p_onl_r, player, items, res_item):
        if res_item.type != IT_FISH:
            return
        data = p_onl_r.data
        if data.fhn >= self.max_num:
            return
        if not (self.begin <= common.current_time() <= self.end):
            return False, errcode.EC_VALUE
        for item in items:
            item[IKEY_COUNT] *= self.multiple
        data.fhn += 1
        data.update_attr(player)


class FishHarvest(Base):
    """玩家钓鱼丰收活动"""

    TYPE = 21

    def reload(self, res):
        super(FishHarvest, self).reload(res)
        self.init()

    def _build_data(self, res):
        self.data = int(float(res.data))
        self.begin = res.begin
        self.end = res.end

    def init(self):
        if self.begin <= common.current_time()<= self.end:
            log.info('FishHarvests open <%s, %s>', self.begin, self.end)
            self._mgr._game.fish_mgr.set_active_chum(self.data)

    def clear(self):
        super(FishHarvest, self).clear()
        self._mgr._game.fish_mgr.set_active_chum(0)


class FishWater(Base):
    """玩家鱼水之欢活动"""

    REWARD_TYPE = RW_MAIL_FISHWATER
    TYPE = 33

    def init(self):
        self.REGISTER_CLASS.register_nosub_list(self.reward)

    def clear(self):
        self.REGISTER_CLASS.unregister_nosub_list(self.reward)

    def test_reward(self):
        rid = self.data
        t_reward(rid)

    def _build_data(self, res):
        #分解一个元素->(奖励条件:能获得奖励的次数:奖励id)
        self.data = int(float(res.data))
        self.begin = res.begin
        self.end = res.end

    def _exist(self, dics):
        """数据库中有的处理"""
        dic = dics[0]
        if common.is_pass_day(dic['ct']):
            dic['ct'] = common.current_time()
            Game.rpc_store.save(TN_P_ACTIVE, dic)
            return IN_COUNT
        return OUT_COUNT

    def _empty(self, querys):
        """数据库中没有的处理"""
        querys['data'] = 1
        querys['ct'] = common.current_time()
        Game.rpc_store.insert(TN_P_ACTIVE, querys)

    def unsub(self):
        self.clear()

    def reward(self, p_onl_r, player):
        if not self.state:
            return
        #活动时间检测
        ct = common.current_time()
        if ct < self.begin:
            return
        if ct > self.end:
            self.unsub()
            return
        pid = player.data.id
        querys=dict(aid=self.TYPE, pid=pid)
        dics = Game.rpc_store.query_loads(TN_P_ACTIVE, querys=querys)
        if dics:
            if self._exist(dics) == OUT_COUNT:
                return
        else:
            self._empty(querys)
        rid = self.data
        t_rw = Game.reward_mgr.get(rid)
        if t_rw is None:
            return
        items = t_rw.reward(params=None)
        self._send_mail(pid, items, dict(), rid=rid)
        return


class FightSpeed(Base):
    """玩家战斗加速"""

    TYPE = 17

    def reload(self, res):
        super(FightSpeed, self).reload(res)
        self.init()

    def test_reward(self):
        log.info("%s, params:%s", self.OBJ_NAME(), self._mgr._game.vip_attr_mgr._fight_multiple)

    def _build_data(self, res):
        self.data = res.data
        self.begin = res.begin
        self.end = res.end

    def init(self):
        now = common.current_time()
        if self.begin <= now <= self.end:
            self._mgr._game.vip_attr_mgr.set_for_active(self.data)
            log.info('reward_active:%s open <%s, %s>', self.OBJ_NAME(), self.begin, self.end)
        else:
            log.info('reward_active:%s is close', self.OBJ_NAME())

    def clear(self):
        super(FightSpeed, self).clear()
        log.info('reward_active:%s is finish', self.OBJ_NAME())
        from game.base.constant import VIP_FIGHT_MULTIPLE, VIP_FIGHT_MULTIPLE_V
        multiple_str = self._mgr._game.setting_mgr.setdefault(VIP_FIGHT_MULTIPLE, VIP_FIGHT_MULTIPLE_V)
        self._mgr._game.vip_attr_mgr.set_for_active(multiple_str)


class TBox(Base):
    """神奇时光盒"""

    TYPE = 22

    def reload(self, res):
        super(TBox, self).reload(res)
        self.init()

    def test_reward(self):
        log.info("%s, params:%s", self.OBJ_NAME(), self.data)

    def _build_data(self, res):
        self.data = int(float(res.data))
        self.begin = res.begin
        self.end = res.end

    def init(self):
        if self.begin <= common.current_time()<= self.end:
            log.info('TBox open <%s, %s>', self.begin, self.end)
            self._mgr._game.tbox_mgr.set_active_num(self.data)

    def clear(self):
        super(TBox, self).clear()
        self._mgr._game.tbox_mgr.set_active_num(0)


class TBoxNum(Base):
    """时光盒次数"""

    TYPE = 38
    REWARD_TYPE = RW_MAIL_TBOX_NUM

    def test_reward(self):
        rid = self.rid
        t_reward(rid)

    def _build_data(self, res):
        self.data, self.rid = res.data.split("|")
        self.data = int(self.data)
        self.rid  = int(self.rid)
        self.begin = res.begin
        self.end  = res.end

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_TBOX_MDIE, self.reward)

    def clear(self):
        super(TBoxNum, self).clear()
        self.REGISTER_CLASS.unregister_sub_list(MSG_TBOX_MDIE, self.reward)

    def _update(self, dics, num, player):
        """数据库中有的处理"""
        dic = dics[0]
        if dic['ct'] < self.begin or common.is_pass_day(dic['ct']):
            dic['data'] = 0
        begin = dic['data']
        dic['data'] += num
        end = dic['data']
        dic['ct'] = common.current_time()
        Game.rpc_store.save(TN_P_ACTIVE, dic)
        self._reward(begin, end, player)
        return IN_COUNT

    def _install(self, querys, num, player):
        """数据库中没有的处理"""
        querys['data'] = num
        querys['ct'] = common.current_time()
        Game.rpc_store.insert(TN_P_ACTIVE, querys)
        self._reward(0, num, player)

    def _reward(self, begin, end, player):
        for num in xrange(begin, end):
            if (num + 1) % self.data:
                continue
            items = get_reward(self.rid, player)
            self._send_mail(player.data.id, items, dict(c=num+1), rid=self.rid)

    @wrap_handle
    def reward(self, p_onl_r, player, num):
        querys=dict(aid=self.TYPE, pid=player.data.id)
        dics = Game.rpc_store.query_loads(TN_P_ACTIVE, querys=querys)
        dic = querys
        if dics:
            dic = dics[0]
            self._update(dics, num, player)
            return
        self._install(querys, num, player)


class DeepBoxOpen(Base):
    """深渊盒子层数对应奖励活动"""

    TYPE = 39

    def test_reward(self):
        for rid in self.data.values():
            t_reward(rid)

    def _build_data(self, res):
        self.data = {}
        rid_strs = res.data.split("|")
        for comp in rid_strs:
            num, rid = comp.split(":")
            self.data[int(num)] = int(rid)
        self.begin = res.begin
        self.end = res.end

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_DEEP_FLOOR_BOX, self.reward)

    def clear(self):
        super(DeepBoxOpen, self).clear()
        self.REGISTER_CLASS.unregister_sub_list(MSG_DEEP_FLOOR_BOX, self.reward)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_DEEP_FLOOR_BOX, self.reward)

    @wrap_handle
    def reward(self, p_onl_r, player, floor, deep_items):
        rid = self.data.get(int(floor))
        if not rid:
            return
        items = get_reward(rid, player)
        if items:
            deep_items.extend(items)


class FishChance(Base):
    """钓鱼概率获得奖励"""

    TYPE = 40

    def test_reward(self):
        for qt in self.qt2rid.keys():
            rid = self.qt2rid[qt]
            t_reward(rid)

    def _build_data(self, res):
        self.qt2rd = {}
        self.qt2rid = {}
        components = res.data.split("|")
        for component in components:
            qt, r, rid = component.split(":")
            qt, r, rid = int(qt), int(r), int(rid)
            self.qt2rd[qt] = r
            self.qt2rid[qt] = rid
        self.begin = res.begin
        self.end = res.end

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_FISH_UP_CHANCE, self.reward)

    def clear(self):
        super(FishChance, self).clear()
        self.REGISTER_CLASS.unregister_sub_list(MSG_FISH_UP_CHANCE, self.reward)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_FISH_UP_CHANCE, self.reward)

    @wrap_handle
    def reward(self, p_onl_r, player, iid, fish_items):
        res_item = player._game.res_mgr.items.get(iid)
        if res_item.type != IT_CHUM:
            return
        drd = self.qt2rd.get(res_item.quality)
        rd = (randint(0, 100))
        if drd < rd:
            return
        rid = self.qt2rid.get(res_item.quality)
        if not rid:
            return
        items = get_reward(rid, player)
        if items:
            fish_items.extend(items)


class LevelGifts(Base):
    """第三次封测  升级送公测好礼"""

    TYPE = 8

    def __init__(self, mgr):
        super(LevelGifts, self).__init__(mgr)
        self.type = 0

    def _build_data(self, res):
        self.lv_gifts = common.str2dict(res.data, ktype=int, vtype=int)
        self.type = self.lv_gifts.pop(0)
        if self.type:
            self.REGISTER_CLASS.register_nosub_list(self.get_level_gift)
            self.get_time = dict(start = res.begin, end = res.end)
        else:
            self.REGISTER_CLASS.register_sub_list(MSG_UPGRADE, self.set_level_gift)
            self.set_time = dict(start = res.begin, end = res.end)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_UPGRADE, self.set_level_gift)

    def clear(self):
        super(LevelGifts, self).clear()
        if self.type:
            self.REGISTER_CLASS.unregister_nosub_list(self.get_level_gift)
        else:
            self.REGISTER_CLASS.unregister_sub_list(MSG_UPGRADE, self.set_level_gift)

    @wrap_handle
    def set_level_gift(self, p_onl_r, player, level):
        """设置奖励"""
        if level not in self.lv_gifts:return
        #时间 2013年4月10日-4月16日
        now = datetime.now()
        now = time.mktime(now.timetuple())
        start = self.set_time['start']
        end = self.set_time['end']
        if now < start or now > end:return
        #查询同一台机器的记录
        querys = dict(udid = player.user.data.UDID)
        d_udid = player._game.rpc_store.query_loads(TN_ACTIVITY_LEVEL_GIFTS, querys)
        if len(d_udid):
            old = d_udid[0]
            #如果等级低，直接返回
            if level <= old['level']:return

        #数据打包
        data = {'id': None}
        data['udid'] = player.user.data.UDID
        data['level'] = level
        data['suid'] = player.user.data.id

        #清除同uid数据
        querys = dict(suid = player.user.data.id)
        player._game.rpc_store.query_deletes(TN_ACTIVITY_LEVEL_GIFTS, querys)
        #清除同机器码数据
        querys = dict(udid = player.user.data.UDID)
        player._game.rpc_store.query_deletes(TN_ACTIVITY_LEVEL_GIFTS, querys)
        #保存新数据
        player._game.rpc_store.insert(TN_ACTIVITY_LEVEL_GIFTS, data)
        #获得奖励列表
        items, rid = self.get_items(player, data['level'])
        if items is None: return
        #发送邮件
        rwitems = RewardItems(items)
        items = None
        cont_dict = dict(level = level, coin1 = rwitems.coin1,
                train = rwitems.train, coin3 = rwitems.coin3)
        self._send_mail(player.data.id, items, cont_dict, mail_type=RW_MAIL_LEVEL_GIFTS_SET)

    def get_level_gift(self,  p_onl_r, player):
        """获得奖励"""
        #时间检测 活动截止时间至2013年5月31日
        now = datetime.now()
        now = time.mktime(now.timetuple())
        start = self.get_time['start']
        end = self.get_time['end']
        if now < start or now > end: return
        #查询机器码数据
        querys = dict(udid = player.user.data.UDID)
        d_udid = player._game.rpc_store.query_loads(TN_ACTIVITY_LEVEL_GIFTS, querys)
        if len(d_udid) == 0: return
        #同一账号只能领取一次
        querys = dict(guid = player.user.data.id)
        d_guid = player._game.rpc_store.query_loads(TN_ACTIVITY_LEVEL_GIFTS, querys)
        if len(d_guid) > 0:  return
        #状态判断
        data = d_udid[0]
        state = data.get('state', 0)
        if state: return
        #获得奖励列表
        items, rid = self.get_items(player, data['level'])
        if items is None: return
        #发送奖励邮件
        cont_dict = ''
        self._send_mail(player, items, cont_dict, mail_type=RW_MAIL_LEVEL_GIFTS_GET, rid=rid)
        #保存数据
        data['state'] = 1
        data['time'] = time.time()
        data['guid'] = player.user.data.id
        player._game.rpc_store.save(TN_ACTIVITY_LEVEL_GIFTS, data)

    def get_items(self, player, level):
        rw = self.lv_gifts
        if level not in rw:
            return None, 0
        rw_code = rw.get(level)
        items = get_reward(rw_code, player)
        return items, rw_code


class CostCoin3(Base):
    """累积消费大赠送"""

    TYPE = 12

    @property
    def cls_name(self):
        return self.__class__.__name__

    def test_reward(self):
        l = self.print_data.split("|")
        for item in l:
            n, rid = item.split(":")
            rid = int(rid)
            t_reward(rid)

    def _build_data(self, res):
        self.print_data = res.data
        self.data = make_lv_regions(res.data)
        self.begin = res.begin
        self.end = res.end

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_COST_COIN3, self.write_in)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_COST_COIN3, self.write_in)

    def clear(self):
        super(CostCoin3, self).clear()
        self.REGISTER_CLASS.unregister_nosub_list(self.write_in)

    def _update(self, dics, coin3):
        """数据库中有的处理"""
        dic = dics[0]
        if dic['ct'] < self.begin:
            dic['data'] = 0
        dic['data'] += coin3
        dic['ct'] = common.current_time()
        Game.rpc_store.save(TN_P_ACTIVE, dic)

    def _install(self, querys, coin3):
        """数据库中没有的处理"""
        querys['data'] = coin3
        querys['ct'] = common.current_time()
        Game.rpc_store.insert(TN_P_ACTIVE, querys)

    @wrap_handle_begin_end
    def write_in(self, p_onl_r, player, coin3):
        querys=dict(aid=self.TYPE, pid=player.data.id)
        dics = Game.rpc_store.query_loads(TN_P_ACTIVE, querys=querys)
        self._update(dics, coin3) if dics else self._install(querys, coin3)

    def reward(self):
        querys=dict(aid=self.TYPE)
        dics = Game.rpc_store.query_loads(TN_P_ACTIVE, querys=querys)
        for dic in dics:
            pid = dic['pid']
            coin3 = dic['data']
            rid = self.data(coin3)
            if not rid:
                continue
            if not (self.begin < dic['ct'] < self.end):
                continue
            t_rw = Game.reward_mgr.get(rid)
            if t_rw is None:
                continue
            items = t_rw.reward(params=None)
            if items is None:
                log.error('CostCoin3 items is None, pid(%s), rid(%s)', pid, rid)
                return
            cont_dict = dict(coins = coin3)
            self._send_mail(pid, items, cont_dict, mail_type=RW_MAIL_COST_COIN3, rid=rid)

    def finish(self):
        super(CostCoin3, self).finish()
        return pile_cost_reward(self.id)


def pile_cost_reward(rid):
    """累计消费奖励发送"""
    log.info("costCoin3 pub reward: %s", time.localtime(common.current_time()))
    oReward = Game.instance.reward_mgr2.get_reward(int(rid))
    if oReward:
        spawn(oReward.reward)


class FateLuck(Base):
    """每日幸运星"""

    TYPE = 18

    def __init__(self, mgr):
        super(FateLuck, self).__init__(mgr)

    def reload(self, res):
        super(FateLuck, self).reload(res)
        self.init()

    def test_reward(self):
        mgr = self._mgr._game.hfate_mgr
        luck_num1 = mgr.luck_num1
        luck_num2 = mgr.luck_num2
        log.info("%s luck_num1:%s, luck_num2:%s", self.OBJ_NAME(), luck_num1, luck_num2)

    def _build_data(self, res):
        """
        res.data = 银币观星|元宝观星
        """
        self.data = map(int, res.data.split("|"))
        self.begin = res.begin
        self.end = res.end

    def init(self):
        if self.begin <= common.current_time()<= self.end:
            log.info('FateDrop start, end time:%s', self.end)
            self._mgr._game.hfate_mgr.luck_num1 = self.data[0]
            self._mgr._game.hfate_mgr.luck_num2 = self.data[1]

    def clear(self):
        super(FateLuck, self).clear()
        self._mgr._game.hfate_mgr.luck_num1 = 0
        self._mgr._game.hfate_mgr.luck_num2 = 0


class FateDrop(Base):
    """天外坠星活动"""

    TYPE = 35

    def reload(self, res):
        super(FateDrop, self).reload(res)
        self.init()

    def test_reward(self):
        mgr = self._mgr._game.hfate_mgr
        drop_num1 = mgr.drop_num1
        drop_num2 = mgr.drop_num2
        log.info("%s drop_num1:%s, drop_num2:%s", self.OBJ_NAME(), drop_num1, drop_num2)

    def _build_data(self, res):
        """
        res.data = 银币观星|元宝观星
        """
        self.data = map(int, res.data.split("|"))
        self.begin = res.begin
        self.end = res.end

    def init(self):
        now = common.current_time()
        if self.begin <= now <= self.end:
            log.info('FateDrop start, end time:%s', self.end)
            self._mgr._game.hfate_mgr.drop_num1 = self.data[0]
            self._mgr._game.hfate_mgr.drop_num2 = self.data[1]

    def clear(self):
        super(FateDrop, self).clear()
        self._mgr._game.hfate_mgr.drop_num1 = 0
        self._mgr._game.hfate_mgr.drop_num2 = 0


class MiningRebate(Base):
    """采矿打折活动"""

    TYPE = 19

    def reload(self, res):
        super(MiningRebate, self).reload(res)
        self.init()

    def test_reward(self):
        log.info("%s rebate:%s", self.OBJ_NAME(), self._mgr._game.mining_mgr.rebate)

    def _build_data(self, res):
        self.data = float(res.data)
        self.begin = res.begin
        self.end = res.end

    def init(self):
        now = common.current_time()
        if self.begin <= now <= self.end:
            log.info('MiningRebate start, end time:%s', self.end)
            self._mgr._game.mining_mgr.rebate = self.data

    def clear(self):
        super(MiningRebate, self).clear()
        self._mgr._game.mining_mgr.rebate = 1


class Arena(Base):
    """竞技场翻倍"""

    TYPE = 23

    def reload(self, res):
        super(Arena, self).reload(res)
        self.init()

    def test_reward(self):
        log.info("%s params:%s", self.OBJ_NAME(), self.data)

    def _build_data(self, res):
        self.data = int(float(res.data))
        self.begin = res.begin
        self.end = res.end

    def init(self):
        if self.begin <= common.current_time() <= self.end:
            log.info('Arena start, end time:%s', self.end)
            self._mgr._game.rpc_arena_mgr.set_active_reward(self.data)

    def clear(self):
        super(Arena, self).clear()
        self._mgr._game.rpc_arena_mgr.set_active_reward(1)


class Shop(Base):
    """神秘商店打折"""

    TYPE = 24

    def reload(self, res):
        super(Shop, self).reload(res)
        self.init()

    def test_reward(self):
        log.info("%s params:%s", self.OBJ_NAME(), self.data)

    def _build_data(self, res):
        self.data = float(res.data)
        self.begin = res.begin
        self.end = res.end

    def init(self):
        if self.begin <= common.current_time() <= self.end:
            log.info('Shop start, end time:%s', self.end)
            self._mgr._game.shop_mgr.set_active_mul(self.data)

    def clear(self):
        super(Shop, self).clear()
        self._mgr._game.shop_mgr.set_active_mul(1)


class HFate(Base):
    """ 观星 星力伴成长奖励 """

    REWARD_TYPE = RW_MAIL_HFATE
    TYPE = 25

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_HFATE_YB, self.reward)

    def clear(self):
        super(HFate, self).clear()
        self.REGISTER_CLASS.unregister_sub_list(MSG_HFATE_YB, self.reward)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_HFATE_YB, self.reward)

    def test_reward(self):
        log.info("%s data:%s", self.OBJ_NAME(), self.data)
        rid = self.rid
        t_reward(rid)

    def _build_data(self, res):
        self.data, self.rid = res.data.split("|")
        self.data = int(self.data)
        self.rid  = int(self.rid)
        self.begin = res.begin
        self.end  = res.end

    @wrap_handle
    def reward(self, p_onl_r, player, h_num):
        if h_num != self.data:
            return
        if self.begin< common.current_time()<self.end:
            items = get_reward(self.rid, player)
            self._send_mail(player.data.id, items, dict(num=h_num), rid=self.rid)
            return
        log.info("rewardHFate is over, edtime:%s", self.end)


class CostYBAtOnce(Base):
    """累积消费大赠送立即发送"""

    TYPE = 27

    def test_reward(self):
        log.info("%s data:%s", self.OBJ_NAME(), self.data)
        rid = self.rid
        t_reward(rid)

    def _build_data(self, res):
        self.data, self.rid= map(int, res.data.split("|"))
        self.begin = res.begin
        self.end = res.end

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_COST_COIN3, self.add_coin_cost)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_COST_COIN3, self.add_coin_cost)

    def clear(self):
        super(CostYBAtOnce, self).clear()
        self.REGISTER_CLASS.unregister_sub_list(MSG_COST_COIN3, self.add_coin_cost)

    def reward(self, p_onl_r, player):
        items = get_reward(self.rid, player)
        if not items:
            log.error("rid: %s is None, please check", self.rid)
            return
        cont_dict = dict(coins=self.data)
        self._send_mail(player.data.id, items, cont_dict, mail_type=RW_MAIL_COST_COIN3, rid=self.rid)

    @wrap_handle
    def add_coin_cost(self, p_onl_r, player, coin):
        #时间检测
        if not (self.begin <= common.current_time() <= self.end):
            return
        data = p_onl_r.data
        data.coinYb += coin
        #发送次数
        m_n = int(data.coinYb/self.data)
        #剩余的数据
        rls = data.coinYb%self.data
        if not m_n:
            data.update_attr(player)
            return
        log.info("%s pid:%s, coinYb:%s, condition:%s mail_num:%s, left:%s",
                self.OBJ_NAME(), player.data.id, data.coinYb, self.data, m_n, rls)
        for i in xrange(m_n):
            self.reward(p_onl_r, player)
        data.coinYb = rls
        data.update_attr(player)


class Intensify(Base):
    """装备强化活动"""

    REWARD_TYPE = RW_MAIL_INTENSIFY
    TYPE = 28

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_EQUIP_UP, self.reward)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_EQUIP_UP, self.reward)

    def clear(self):
        super(Intensify, self).clear()
        self.REGISTER_CLASS.unregister_sub_list(MSG_EQUIP_UP, self.reward)

    def test_reward(self):
        rid_strs = self.print_data.split("|")
        for comp in rid_strs:
            level, mail_type, rid = comp.split(":")
            rid = int(rid)
            log.info("%s, level:%s mail_type:%s", self.OBJ_NAME(), level, mail_type)
            t_reward(rid)

    def _build_data(self, res):
        """
        res.data = 阶:邮件类型:奖励ID
        """
        self.print_data = res.data
        self.rid_dict = {}
        self.dict_keys = []
        self.mail_types = {}
        rid_strs = res.data.split("|")
        for comp in rid_strs:
            level, mail_type, rid = comp.split(":")
            level, mail_type, rid = int(level), int(mail_type), int(rid)
            self.rid_dict[int(level)] = rid
            self.dict_keys.append(level)
            self.mail_types[level] = mail_type
        self.equips = self._mgr._game.res_mgr.equips
        self.begin = res.begin
        self.end = res.end

    @wrap_handle_begin_end
    def reward(self, p_onl_r, player, eid, lv):
        """
        装备升级
        """
        if lv in self.dict_keys:
            eqp_obj = self.equips.get(eid)
            if not eqp_obj:
                log.error("equip_id: %s is None, please check", eid)
                return
            rid = self.rid_dict.get(lv)
            if not rid:
                return
            items = get_reward(rid, player)
            mail_type = self.mail_types.get(lv, None)
            if not mail_type:
                mail_type = self.REWARD_TYPE
            self._send_mail(player.data.id, items, dict(eqpLv = lv, eqp=eqp_obj.name), mail_type=mail_type, rid=rid)


class ShopSeven(Base):
    """ 七夕神蜜礼包 """

    TYPE = 32

    def __init__(self, mgr):
        super(ShopSeven, self).__init__(mgr)

    def init(self):
        self.REGISTER_CLASS.register_sub_list(MSG_SHOP_BUY, self.shop_buy)
        self.REGISTER_CLASS.register_sub_list(MSG_REWARD_BUY, self.reward_buy)

    def unsub(self, p_onl_r):
        p_onl_r.unsub(MSG_SHOP_BUY, self.shop_buy)
        p_onl_r.unsub(MSG_REWARD_BUY, self.reward_buy)

    @wrap_handle
    def shop_buy(self, p_inl_r, player, sid):
        """ 记录玩家购买活动的物品的次数 """
        now = common.current_time()
        if now < self.begin or now > self.end:
            return
        if sid != self.sid:
            return
        querys=dict(aid=self.TYPE, pid=player.data.id)
        dics = Game.rpc_store.query_loads(TN_P_ACTIVE, querys=querys)
        if dics:
            if dics[0]['data'] >= self.mbuy:
                log.info("ShopSeven reward is limit return")
                return
            else:
                dics[0]['data'] += 1
                Game.rpc_store.save(TN_P_ACTIVE, dics)
                return
        querys['ct'] = common.current_time()
        querys['data'] = 1
        Game.rpc_store.insert(TN_P_ACTIVE, querys)

    @wrap_handle
    def reward_buy(self, p_onl_r, player, reward_sids):
        """ 活动必然出现的商品id """
        now = common.current_time()
        if now < self.begin or now > self.end:
            return
        querys=dict(aid=self.TYPE, pid=player.data.id)
        dics = Game.rpc_store.query_loads(TN_P_ACTIVE, querys=querys)
        if dics and dics[0]['data'] >= self.mbuy:
            return
        reward_sids.append(self.sid)

    def clear(self):
        super(ShopSeven, self).clear()
        self.REGISTER_CLASS.unregister_sub_list(MSG_SHOP_BUY, self.shop_buy)
        self.REGISTER_CLASS.unregister_sub_list(MSG_REWARD_BUY, self.reward_buy)

    def _build_data(self, res):
        sid, mbuy = res.data.split(":")
        self.sid  = int(sid)
        self.mbuy = int(mbuy)
        self.begin = res.begin
        self.end  = res.end


class WeekDayOnline(Base):
    """周末在线时长奖励活动"""

    TYPE = 30

    def __init__(self, mgr):
        super(WeekDayOnline, self).__init__(mgr)
        self.pid2tasks = {}             #{pid:one_task}
        self.pid2obj = {}               #{pid:p_onl_r}

    def init(self):
        self.REGISTER_CLASS.register_nosub_list(self.handle_login)

    def player_logout(self, pid):
        """处理玩家下线"""
        self._remove_pid2(pid)

    def clear(self):
        ks = self.pid2tasks.keys()
        for pid in ks:
            self._remove_pid2(pid)
        self.REGISTER_CLASS.unregister_nosub_list(self.reward)
        self.pid2obj = {}

    def unsub(self):
        self.clear()

    def test_reward(self):
        for comp in self.print_data.split("|"):
            num, t, rid = comp.split(":")
            rid = int(rid)
            log.info("%s, num:%s online_time:%s", self.OBJ_NAME(), num, t)
            t_reward(rid)

    def _build_data(self, res):
        #分解一个元素->(奖励条件:能获得奖励的次数:奖励id)
        self.rid_dict = {}
        self.time_dict = {}
        self.begin = res.begin
        self.end = res.end
        self.print_data = res.data
        rid_strs = res.data.split("|")
        self.max_num = len(rid_strs) + 1
        for comp in rid_strs:
            num, t, rid = comp.split(":")
            num, t, rid = int(num), int(t), int(rid)
            self.rid_dict[num] = rid
            self.time_dict[num] = t

    def del_task(self, pid):
        """删除任务"""
        if pid not in self.pid2tasks:
            return "+task_None"
        task_ = self.pid2tasks.get(pid, None)
        task_.kill(block=False)
        del self.pid2tasks[pid]
        return "+del_task"

    def del_obj(self, pid):
        #删除对象
        if pid not in self.pid2obj:
            return "+p_onl_r_None1"
        p_onl_r = self.pid2obj.get(pid, None)
        del self.pid2obj[pid]
        if p_onl_r.data:
            p_onl_r.data.wkt1 = common.current_time()
            p_onl_r.save(None)
            return "+del_p_onl_r"
        return "+p_onl_r_None2"

    def _remove_pid2(self, pid):
        KILL_DES = "_remove_pid2 kill pid:%s"%pid
        KILL_DES += self.del_task(pid)
        KILL_DES += self.del_obj(pid)
        log.info(KILL_DES)

    def reward(self, p_onl_r, player):
        pid = player.data.id
        if pid not in self.pid2tasks:
            return
        data = p_onl_r.data
        if not data:
            self._remove_pid2(pid)
            return
        rid = self.rid_dict.get(data.wkn, None)
        if not rid:
            log.error("%s reward num:%s error check data", self.OBJ_NAME(), data.wkn)
            return
        items = get_reward(rid, player)
        data.wkn += 1
        if data.wkn >= self.max_num:
            del self.pid2tasks[pid]
            log.info("%s pid:%s, mail_over task remove",self.OBJ_NAME(), pid)
            self._send_mail(pid, items, dict(), rid=rid, mail_type=RW_MAIL_WEEKDAYTIME2)
            return
        self.set_reward_time(data, player)
        min = int(self.time_dict.get(data.wkn)/60)
        del self.pid2tasks[pid]
        log.info("%s pid:%s, mail_send task remove",self.OBJ_NAME(), pid)
        self._send_mail(pid, items, dict(c=min), rid=rid, mail_type=RW_MAIL_WEEKDAYTIME1)
        self.handle_login(p_onl_r, player)

    def fist_in_do(self, p_onl_r, player):
        #活动新开启初次进入
        data = p_onl_r.data
        ct = common.current_time()
        if not hasattr(data, 'wkt1') or common.is_pass_day(data.wkt1) or data.wkt1 < self.begin:
            data.wkt1 = ct
            data.wkn = 1
            data.wkt2 = self.time_dict.get(data.wkn) + ct
        data.update_attr(player)

    def set_reward_time(self, data, player):
        times = self.time_dict.get(data.wkn, None)
        if not times:
            data.update_attr(player)
            return
        ct = common.current_time()
        data.wkt1 = ct
        data.wkt2 = ct + times
        data.update_attr(player)

    def get_sleep_times(self, p_onl_r, player):
        d = p_onl_r.data
        if d.wkt2 == 0:
            self.set_reward_time(d, player)
        s_t = d.wkt2 - d.wkt1
        s_t = 0 if s_t<0 else s_t
        return s_t

    def new_task(self, p_onl_r, player):
        """新建一个线程"""
        task_ = self.pid2tasks.get(player.data.id, None)
        if task_ is not None:
            return
            #监听退出消息
        sleep_times = self.get_sleep_times(p_onl_r, player)
        fmt_string = "%s,pid:(%s),later:%s(second)"#,current time:%s"
        time_obj = time.localtime(common.current_time())
        log.info(fmt_string, self.OBJ_NAME(), player.data.id, sleep_times)
                #(str(time_obj.tm_hour) + ":" + str(time_obj.tm_min)+ ":" + str(time_obj.tm_sec)))
        self.pid2tasks[player.data.id] = spawn_later(sleep_times, self.reward, p_onl_r, player)

    @wrap_ghandle_begin_end
    def handle_login(self, p_onl_r, player):
        player.reg_logout(self)
        if not Game.rpc_player_mgr.have(player.data.id):
            return
        self.fist_in_do(p_onl_r, player)
        data = p_onl_r.data
        if data.wkn >= self.max_num:
            self._remove_pid2(player.data.id)
            return False
        self.pid2obj[player.data.id] = p_onl_r
        self.new_task(p_onl_r, player)


class OnlineMailHold(Base):
    """邮件领取登陆时长奖励"""

    TYPE = 37
    REWARD_TYPE = RW_MAIL_HOLDMAILTIME1

    def __init__(self, mgr):
        super(OnlineMailHold, self).__init__(mgr)
        self.pid2tasks = {}             #{pid:one_task}
        self.pid2obj = {}               #{pid:p_onl_r}

    def init(self):
        self.REGISTER_CLASS.register_nosub_list(self.handle_login)
        self.REGISTER_CLASS.register_sub_list(MSG_MAIL_FETCH, self.handle_mail_fetch)

    def del_obj(self, pid):
        #删除对象
        p_onl_r = self.pid2obj.get(pid, None)
        if not p_onl_r:
            return "+p_onl_r_None1"
        del self.pid2obj[pid]
        if p_onl_r.data:
            p_onl_r.data.wkt1 = common.current_time()
            p_onl_r.save(None)
            return "+del_p_onl_r"
        return "+p_onl_r_None2"

    def del_task(self, pid):
        """删除任务"""
        if pid not in self.pid2tasks:
            return "+task_None"
        del self.pid2tasks[pid]
        task_ = self.pid2tasks.get(pid, None)
        task_.kill(block=False)
        return "+del_task"

    def del_obj(self, pid):
        #删除对象
        if pid not in self.pid2obj:
            return "+p_onl_r_None1"
        p_onl_r = self.pid2obj.get(pid, None)
        #data已经释放直接删除返回
        if not p_onl_r.data:
            del self.pid2obj[pid]
            return "+p_onl_r_None2"
        if p_onl_r.data.mfm:
            p_onl_r.data.mfnew = 0
            p_onl_r.save(None)
            del self.pid2obj[pid]
            return "+del_p_onl_r1"
        del self.pid2obj[pid]
        p_onl_r.data.mft1 = common.current_time()
        p_onl_r.data.mfnew = 1
        p_onl_r.save(None)
        return "+del_p_onl_r2"

    def _remove_pid2(self, pid):
        KILL_DES = "%s _remove_pid2 kill pid:%s"%(self.OBJ_NAME(), pid)
        KILL_DES += self.del_task(pid)
        KILL_DES += self.del_obj(pid)
        log.info(KILL_DES)

    def player_logout(self, pid):
        """处理玩家下线"""
        self._remove_pid2(pid)

    def clear(self):
        ks = self.pid2tasks.keys()
        for pid in ks:
            self._remove_pid2(pid)
        self.REGISTER_CLASS.unregister_nosub_list(self.handle_login)
        self.REGISTER_CLASS.unregister_sub_list(MSG_MAIL_FETCH, self.handle_mail_fetch)
        self.pid2obj = {}

    def unsub(self):
        self.clear()

    def test_reward(self):
        for comp in self.print_data.split("|"):
            num, t, rid = comp.split(":")
            rid = int(rid)
            log.info("%s, num:%s online_time:%s", self.OBJ_NAME(), num, t)
            t_reward(rid)

    def _build_data(self, res):
        #分解一个元素->(奖励条件:能获得奖励的次数:奖励id)
        self.rid_dict = {}
        self.time_dict = {}
        self.begin = res.begin
        self.end = res.end
        self.print_data = res.data
        rid_strs = res.data.split("|")
        self.max_num = len(rid_strs) + 1
        for comp in rid_strs:
            num, t, rid = comp.split(":")
            num, t, rid = int(num), int(t), int(rid)
            self.rid_dict[num] = rid
            self.time_dict[num] = t

    def reward(self, p_onl_r, player):
        pid = player.data.id
        data = p_onl_r.data
        if not data:
            self._remove_pid2(pid)
            return
        rid = self.rid_dict.get(data.mfn, None)
        if not rid:
            log.error("%s reward num:%s error check data", self.OBJ_NAME(), data.wkn)
            return
        items = get_reward(rid, player)
        data.mfn += 1
        if data.mfn >= self.max_num:
            self._send_mail(pid, items, dict(), rid=rid, mail_type=RW_MAIL_HOLDMAILTIME2)
            self._remove_pid2(pid)
            data.mfm = 1
            data.mfnew = 0
            data.update_attr(player)
            return
        min = int(self.time_dict.get(data.mfn)/60)
        self._send_mail(pid, items, dict(c=min), rid=rid, mail_type=RW_MAIL_HOLDMAILTIME1)
        data.mfm = 1
        data.mfnew = 0
        data.update_attr(player)

    def set_reward_time(self, data, player):
        times = self.time_dict.get(data.mfn, 600)
        if not times:
            data.update_attr(player)
            return
        ct = common.current_time()
        data.mft1 = ct
        data.mft2 = ct + times
        data.update_attr(player)

    def get_sleep_times(self, p_onl_r, player):
        d = p_onl_r.data
        s_t = d.mft2 - d.mft1
        s_t = 0 if s_t<0 else s_t
        return s_t

    def new_task(self, p_onl_r, player):
        """新建一个线程"""
        data = p_onl_r.data
        task_ = self.pid2tasks.get(player.data.id, None)
        if task_ is not None:
            return
        if not data.mfnew:
            return
        s_t = data.mft2 - data.mft1
        sleep_times = 0 if s_t<0 else s_t
        fmt_string = "%s,pid:(%s),later:%s(second)"#,current time:%s"
        time_obj = time.localtime(common.current_time())
        log.info(fmt_string, self.OBJ_NAME(), player.data.id, sleep_times)
                #(str(time_obj.tm_hour) + ":" + str(time_obj.tm_min)+ ":" + str(time_obj.tm_sec)))
        self.pid2tasks[player.data.id] = spawn_later(sleep_times, self.reward, p_onl_r, player)
        data.mfnew = 0
        data.update_attr(player)

    def fist_in_do(self, p_onl_r, player):
        #活动新开启初次进入
        data = p_onl_r.data
        ct = common.current_time()
        if not hasattr(data, 'mft1') or common.is_pass_day(data.mft1) or data.mft1 < self.begin:
            data.mfm = 0
            data.mfn = 1
            data.mfnew = 1
            data.mft1 = ct
            data.mft2 = self.time_dict.get(data.mfn) + ct
            data.update_attr(player)
            return True
        return False

    @wrap_ghandle_begin_end
    def handle_login(self, p_onl_r, player):
        player.reg_logout(self)
        state = self.fist_in_do(p_onl_r, player)
        #新的一天或者活动新激活
        if state:
            #创建新时间
            self.set_reward_time(p_onl_r.data, player)
        data = p_onl_r.data
        if data.mfm or data.mfn >= self.max_num:
            return False
        self.pid2obj[player.data.id] = p_onl_r
        self.new_task(p_onl_r, player)

    @wrap_ghandle_begin_end
    def handle_mail_fetch(self, p_onl_r, player, email_type):
        if int(email_type) != self.REWARD_TYPE:
            return
        data = p_onl_r.data
        if self.fist_in_do(p_onl_r, player):
            self.set_reward_time(p_onl_r.data, player)
        else:
            if data.mfn >= self.max_num:
                data.mfnew = 0
                data.update_attr(player)
                return False
            data.mfm = 0
            data.mfnew = 1
            self.set_reward_time(data, player)
        data.update_attr(player)
        self.new_task(p_onl_r, player)


#----------------------------全局活动----------------------------
class WorldBoss(Base):
    """ 世界boss伤害奖励 """
    TYPE = 13
    IS_GLOBAL = 1  #全局活动df

    def test_reward(self):
        for hurt, rid in self.data.items():
            rid = int(rid)
            log.info("%s, hurt:%s", self.OBJ_NAME(), hurt)
            t_reward(rid)

    def _build_data(self, res):
        self.data = common.str2dict(res.data, ktype=str, vtype=int)
        self.begin = res.begin
        self.end = res.end

    def finish(self):
        self.unsub()

    def unsub(self):
        Game.rpc_boss_mgr.rpc_unsub(reward_worldboss, MSG_REWARD_WORLDBOSS,
            data=self.id, _proxy=True)

    def init(self):
        Game.rpc_boss_mgr.rpc_sub(reward_worldboss, MSG_REWARD_WORLDBOSS,
            data=self.id, _proxy=True)

    @wrap_ghandle_begin_end
    def reward(self, rank_data, max_hp):
        h_rates = self.data.keys()
        h_rates = map(int, h_rates)
        h_rates.sort()
        for pid, hurts in rank_data:
            h_rate = float(hurts) / max_hp * 100
            index = bisect.bisect_left(h_rates, h_rate)
            if not index:
                break
            rid = self.data.get(str(h_rates[index - 1]))
            t_rw = Game.reward_mgr.get(rid)
            if t_rw is None:
                continue
            items = t_rw.reward(params=None)
            hurts_rate = '%d%%' % int(h_rate)
            cont_dict = dict(hurts=hurts_rate)
            self._send_mail(pid, items, cont_dict, mail_type=RW_MAIL_WORLDBOSSID, rid=rid)

def reward_worldboss(rank_data, max_hp, _data):
    """ 活动世界boss奖励 """
    oReward = Game.rpc_reward_mgr.get_reward(int(_data))
    if oReward:
        spawn(oReward.reward, rank_data, max_hp)


class Pay(Base):
    """购买礼包送奖励"""
    TYPE = 14
    IS_GLOBAL = 1  #全局活动

    def test_reward(self):
        for payid, rid in self.data.items():
            rid = int(rid)
            log.info("pay_id:%s", payid)
            t_reward(rid)


    def _build_data(self, res):
        self.data = common.str2dict(res.data, ktype=int, vtype=int)
        self.begin = res.begin
        self.end = res.end

    def unsub(self):
        Game.rpc_vip_mgr.rpc_unsub(reward_vip_pay, MSG_VIP_PAY, data=self.id, _proxy=True)

    def init(self):
        Game.rpc_vip_mgr.rpc_sub(reward_vip_pay, MSG_VIP_PAY,
            data=self.id, _proxy=True)

    @wrap_ghandle_begin_end
    def reward(self, pid, rid, coin):
        """ 奖励 """
        rid = self.data.get(rid)
        t_rw = Game.reward_mgr.get(rid)
        if t_rw is None:
            return
        items = t_rw.reward(params=None)
        self._send_mail(pid, items, dict(coins=coin), mail_type=RW_MAIL_VIP_PAY, rid=rid)

    def clear(self):
        super(Pay, self).clear()
        self.unsub()


def reward_vip_pay(pid, rid, coin, _data):
    """ 监听支付消息 """
    oReward = Game.rpc_reward_mgr.get_reward(int(_data))
    if oReward:
        spawn(oReward.reward, pid, rid, coin)


class LevelRank(Base):
    """玩家等级排行奖励"""
    TYPE = 9
    IS_GLOBAL = 1  #全局活动

    def reload(self, res):
        if self._task:
            self._task.kill(block=False)
        super(LevelRank, self).reload(res)
        self.init()

    def test_reward(self):
        l = self.print_data.split("|")
        for comp in l:
            rk, rid = comp.split(":")
            log.info("%s, rank:%s", self.OBJ_NAME(), rk)
            t_reward(int(rid))

    def _build_data(self, res):
        self.print_data = res.data
        self.data = make_lv_regions(res.data)
        self.begin = res.begin
        self.end = res.end
        self._task = None

    def init(self):
        status = Game.rpc_status_mgr.get(REWARD_STATUS)
        if status is None:
            status = dict()
        state = status.get(self.OBJ_NAME())
        if state and state >= self.end:
            return
        now = common.current_time()
        delay = self.end - now
        if delay > 0:
            self._task = spawn_later(delay, self.reward)
        else:
            self.reward()

    def reward(self):
        columns = [CONST_ID]
        sort_by = [(CONST_LEVEL, DESCENDING),(CONST_EXP, DESCENDING)]
        querys = None
        pids = Game.rpc_store.values(TN_PLAYER, columns, querys, limit=10, sort_by=sort_by)
        log.info('LevelRank:%s', pids)
        for index, pid in enumerate(pids):
            rid = self.data(index + 1)
            t_rw = Game.reward_mgr.get(rid)
            if t_rw is None:
                continue
            items = t_rw.reward(params=None)
            if items is None:
                continue
            cont_dict = dict(rank = index + 1)
            self._send_mail(pid['id'], items, cont_dict, mail_type=RW_MAIL_LEVEL_RANK, rid=rid)
        Game.rpc_status_mgr.update_dict(REWARD_STATUS, {self.OBJ_NAME(): self.end})


class CBERank(Base):
    """玩家战斗力排行奖励"""
    TYPE = 10
    IS_GLOBAL = 1  #全局活动

    def reload(self, res):
        if self._task:
            self._task.kill(block=False)
        super(CBERank, self).reload(res)
        self.init()

    def test_reward(self):
        l = self.print_data.split("|")
        for comp in l:
            cbe, rid = comp.split(":")
            log.info("%s, CBE:%s", self.OBJ_NAME(), cbe)
            t_reward(int(rid))

    def _build_data(self, res):
        self.print_data = res.data
        self.data = make_lv_regions(res.data)
        self.begin = res.begin
        self.end = res.end
        self._task = None

    def init(self):
        status = Game.rpc_status_mgr.get(REWARD_STATUS)
        if status is None:
            status = dict()
        state = status.get(self.OBJ_NAME())
        if state and state >= self.end:
            return
        now = common.current_time()
        delay = self.end - now
        if delay > 0:
            self._task = spawn_later(delay, self.reward)
        else:
            self.reward()

    def reward(self):
        columns = [CONST_PID]
        sort_by = [(CONST_CBE, DESCENDING)]
        querys = None
        pids = Game.rpc_store.values(TN_P_ATTR, columns, querys, limit=10, sort_by=sort_by)
        log.info('CBERank:%s', pids)
        for index, pid in enumerate(pids):
            rid = self.data(index + 1)
            t_rw = Game.reward_mgr.get(rid)
            if t_rw is None:
                continue
            items = t_rw.reward(params=None)
            if items is None:
                continue
            cont_dict = dict(rank = index + 1)
            self._send_mail(pid['pid'], items, cont_dict, mail_type=RW_MAIL_CBE_RANK, rid=rid)
        Game.rpc_status_mgr.update_dict(REWARD_STATUS, {self.OBJ_NAME() : self.end})


DOUBLE_ITEMS = 1
DOUBLE_EXP = 2
DOUBLE_EXP_ITEMS = 4
OPEN_DICT = {DOUBLE_EXP:"EXP", DOUBLE_ITEMS:"ITEMS", DOUBLE_EXP_ITEMS:"EXP and ITEMS"}

class BossDouble(Base):
    """世界boss双倍奖励(除去经验)"""

    TYPE = 26
    IS_GLOBAL = 1  #全局活动df
    REWARD_TYPE = RW_MAIL_BOSSDOUBLE

    def test_reward(self):
        log.info("%s is open %s double", self.OBJ_NAME(), OPEN_DICT.get(int(self.data)))

    def _build_data(self, res):
        self.data, self.start_type = map(lambda x: int(float(x)), res.data.split(":"))
        self.begin = res.begin
        self.end = res.end

    def clear(self):
        super(BossDouble, self).clear()
        self.unsub()

    def finish(self):
        self.unsub()

    def unsub(self):
        Game.rpc_boss_mgr.rpc_unsub(reward_boss_double, MSG_REWARD_WORLDITEMS,
            data=self.id, _proxy=True)

    def init(self):
        Game.rpc_boss_mgr.rpc_sub(reward_boss_double, MSG_REWARD_WORLDITEMS,
            data=self.id, _proxy=True)

    @wrap_ghandle_begin_end
    def reward(self, pid, start_type, items):
        if int(start_type) != self.start_type:
            return
        cp_items = copy.deepcopy(items)
        #经验和物品都双倍
        if DOUBLE_EXP_ITEMS == self.data:
            self._send_mail(pid, cp_items, dict())
            return
        #只经验双倍
        elif DOUBLE_EXP == self.data:
            for item in cp_items:
                if item[IKEY_ID] == DIFF_TITEM_EXP and item[IKEY_TYPE] == IT_ITEM_STR:
                    items = [item]
                    self._send_mail(pid, items, dict())
                    return
        #只物品双倍
        elif DOUBLE_ITEMS == self.data:
            for item in cp_items:
                if item[IKEY_ID] == DIFF_TITEM_EXP and item[IKEY_TYPE] == IT_ITEM_STR:
                    items.remove(item)
            self._send_mail(pid, items, dict())
        #错误
        else:
            log.error("pid:(%s) in %s get nothing please check", pid, self.OBJ_NAME())

def reward_boss_double(pid, start_type, items, _data):
    """ 活动世界boss奖励 """
    oReward = Game.rpc_reward_mgr.get_reward(int(_data))
    if oReward:
        spawn(oReward.reward, pid, start_type, items)


class BossEvery(Base):
    """世界boss针对所有参加战斗的玩家奖励"""

    TYPE = 20
    IS_GLOBAL = 1  #全局活动df
    REWARD_TYPE = RW_MAIL_BOSSJOIN

    def test_reward(self):
        log.info("%s", self.OBJ_NAME())
        t_reward(int(self.data))

    def _build_data(self, res):
        self.data = int(float(res.data))
        self.begin = res.begin
        self.end = res.end

    def clear(self):
        super(BossEvery, self).clear()
        self.unsub()

    def unsub(self):
        Game.rpc_boss_mgr.rpc_unsub(reward_boss_every, MSG_REWARD_WORLDBOSS,
            data=self.id, _proxy=True)

    def init(self):
        Game.rpc_boss_mgr.rpc_sub(reward_boss_every, MSG_REWARD_WORLDBOSS,
            data=self.id, _proxy=True)

    @wrap_ghandle_begin_end
    def reward(self, rank_data, max_hp):
        rid = self.data
        for pid, hurts in rank_data:
            t_rw = Game.reward_mgr.get(rid)
            if t_rw is None:
                log.error("reward is None rid:%s", rid)
                continue
            items = t_rw.reward(params=None)
            self._send_mail(pid, items, dict(), rid=rid)

def reward_boss_every(rank_data, max_hp, _data):
    """ 活动世界boss奖励 """
    oReward = Game.rpc_reward_mgr.get_reward(int(_data))
    if oReward:
        spawn(oReward.reward, rank_data, max_hp)

class PayOnce(Base):

    TYPE = 31
    IS_GLOBAL = 1  #全局活动df
    REWARD_TYPE = RW_MAIL_WEEKDAYPAY

    def test_reward(self):
        for payid, rid in self.data.items():
            log.info("%s pay_id:%s", self.OBJ_NAME(), payid)
            t_reward(rid)

    def _build_data(self, res):
        self.count = 1
        self.data = common.str2dict(res.data, ktype=int, vtype=int)
        self.begin = res.begin
        self.end = res.end

    def clear(self):
        super(PayOnce, self).clear()
        self.unsub()

    def unsub(self):
        Game.rpc_vip_mgr.rpc_unsub(reward_vip_pay_once, MSG_VIP_PAY, data=self.id, _proxy=True)

    def init(self):
        Game.rpc_vip_mgr.rpc_sub(reward_vip_pay_once, MSG_VIP_PAY, data=self.id, _proxy=True)

    def _update(self, dics):
        """数据库中有的处理"""
        dic = dics[0]
        if dic['ct'] < self.begin:
           dic['data'] = 0
        if dic['data'] >= self.count:
            log.info("VipOnce reward is limit return")
            return OUT_COUNT
        dic['data'] += 1
        dic['ct'] = common.current_time()
        Game.rpc_store.save(TN_P_ACTIVE, dic)
        return IN_COUNT

    def _install(self, querys):
        """数据库中没有的处理"""
        querys['data'] = 1
        querys['ct'] = common.current_time()
        Game.rpc_store.insert(TN_P_ACTIVE, querys)

    @wrap_ghandle_begin_end
    def reward(self, pid, rid, coin):
        querys=dict(aid=self.TYPE, pid=pid)
        dics = Game.rpc_store.query_loads(TN_P_ACTIVE, querys=querys)
        if dics:
            if self._update(dics) == OUT_COUNT:
                return
        else:
            self._install(querys)
        rid = self.data.get(rid)
        t_rw = Game.reward_mgr.get(rid)
        if t_rw is None:
            return
        items = t_rw.reward(params=None)
        self._send_mail(pid, items, dict(), mail_type=RW_MAIL_WEEKDAYPAY, rid=rid)
        return

def reward_vip_pay_once(pid, rid, coin, _data):
    """周末充值活动只送一次"""
    oReward = Game.rpc_reward_mgr.get_reward(int(_data))
    if oReward:
        spawn(oReward.reward, pid, rid, coin)


class PayLevel(Base):
    """累计充值领好礼"""

    TYPE = 36
    IS_GLOBAL = 1  #全局活动df
    REWARD_TYPE = RW_MAIL_PAY_LEVEL

    def test_reward(self):
        l = self.print_data.split("|")
        for comp in l:
            n, coin2, rid = comp.split(":")
            log.info("%s, num:%s, coin2:%s", self.OBJ_NAME(), n, coin2)
            t_reward(int(rid))

    def _build_data(self, res):
        self.data = make_lv_regions_list(res.data)
        lvs = ""
        rids = ""
        coins = ""

        self.print_data = res.data
        for items in res.data.split("|"):
            lv, coin, rid = items.split(":")

        fmt = "%s:%s|"
        for items in res.data.split("|"):
            lv, coin, rid = items.split(":")
            lv, coin, rid = int(lv), int(coin), int(rid)
            lvs += fmt%(coin, lv)
            rids += fmt%(lv, rid)
            coins += fmt%(lv, coin)
        lvs = lvs[:-1]
        rids = rids[:-1]
        coins = coins[:-1]
        self.lvs = make_lv_regions(lvs)
        self.rids = make_lv_regions(rids)
        self.coins = make_lv_regions(coins)
        self.begin = res.begin
        self.end = res.end

    def clear(self):
        super(PayLevel, self).clear()
        self.unsub()

    def unsub(self):
        Game.rpc_vip_mgr.rpc_unsub(reward_pay_level, MSG_VIP_PAY, data=self.id, _proxy=True)

    def init(self):
        Game.rpc_vip_mgr.rpc_sub(reward_pay_level, MSG_VIP_PAY, data=self.id, _proxy=True)

    def _update(self, dics, coin):
        """数据库中有的处理"""
        dic = dics[0]
        if dic['ct'] < self.begin:
            dic['data'] = 0
        dic['data'] += coin
        dic['ct'] = common.current_time()
        Game.rpc_store.save(TN_P_ACTIVE, dic)

    def _install(self, querys, coin):
        """数据库中没有的处理"""
        querys['data'] = coin
        querys['ct'] = common.current_time()
        Game.rpc_store.insert(TN_P_ACTIVE, querys)

    @wrap_ghandle_begin_end
    def reward(self, pid, rid, coin):
        querys=dict(aid=self.TYPE, pid=pid)
        dics = Game.rpc_store.query_loads(TN_P_ACTIVE, querys=querys)
        lv2 = lv1 = 0
        if dics:
            dic = dics[0]
            lv1 = self.lvs(dic['data'])
            self._update(dics, coin)
            lv2 = self.lvs(dic['data'])
        else:
            self._install(querys, coin)
            lv2 = self.lvs(querys['data'])

        for lv in xrange(lv1 + 1, lv2 + 1):
            rid = self.rids(lv)
            if not rid:
                continue
            t_rw = Game.reward_mgr.get(rid)
            if t_rw is None:
                return
            items = t_rw.reward(params=None)
            coin = self.coins(lv)
            self._send_mail(pid, items, dict(coin=coin), mail_type=self.REWARD_TYPE, rid=rid)

def reward_pay_level(pid, rid, coin, _data):
    """累计充值领好礼"""
    oReward = Game.rpc_reward_mgr.get_reward(int(_data))
    if oReward:
        spawn(oReward.reward, pid, rid, coin)


class HeroTrouble(Base):

    TYPE = 34
    IS_GLOBAL = 1  #全局活动df
    REWARD_TYPE = RW_MAIL_WEEKDAYPAY

    def __init__(self, mgr):
        super(HeroTrouble, self).__init__(mgr)
        self._task = None

    def reload(self, res):
        super(HeroTrouble, self).reload(res)
        self.init()

    def _build_data(self, res):
        self.begin = res.begin
        self.end = res.end
        l = map(lambda x: (x, "%y%m%d%H"), res.data.split("|"))
        self.print_data = res.data
        self.data = map(time.mktime, map(lambda tup:time.strptime(tup[0], tup[1]), l))
        self.data.sort()

    def clear(self):
        super(HeroTrouble, self).clear()
        self.unsub()

    def unsub(self):
        if self._task != None:
            self._task.kill(block=False)
            self._task = None

    def init(self):
        self.unsub()
        n_r_t = self._next_reward_time()
        slpt = n_r_t - common.current_time()
        if slpt < 0:
            return
        slpt += 10
        log.info("%s will start reward at late %s", self.OBJ_NAME(), slpt)
        self._task = spawn_later(slpt, self.reward)

    def _next_reward_time(self):
        ct = common.current_time()
        for n_r_t in self.data:
            if ct < n_r_t:
                log.info("%s the next reward time is %s", self.OBJ_NAME(), n_r_t)
                return n_r_t
        log.info("%s the reward is send over", self.OBJ_NAME())
        return -1

    @wrap_ghandle_begin_end
    def reward(self):
        log.info("%s send reward time is:%s", self.OBJ_NAME(), time.localtime(common.current_time()))
        Game.rpc_arena_mgr.reward_active()
        self.init()


CLASS_LIST_SETT = {
    #目前是永久开启的
    Online.TYPE:Online,
    Land.TYPE:Land,
    Invite.TYPE:Invite,
    Weapon.TYPE:Weapon,
    RecruitRole.TYPE:RecruitRole,
    #需要动态开启关闭
    LevelUp.TYPE:LevelUp,
    Interval.TYPE:Interval,
    Hold.TYPE:Hold,
    DateTo.TYPE:DateTo,
    Fish.TYPE:Fish,
    FishHarvest.TYPE:FishHarvest,
    FishWater.TYPE:FishWater,
    FightSpeed.TYPE:FightSpeed,
    TBox.TYPE:TBox,
    LevelGifts.TYPE:LevelGifts,
    CostCoin3.TYPE:CostCoin3,
    FateDrop.TYPE:FateDrop,
    FateLuck.TYPE:FateLuck,
    MiningRebate.TYPE:MiningRebate,
    Arena.TYPE:Arena,
    Shop.TYPE:Shop,
    HFate.TYPE:HFate,
    CostYBAtOnce.TYPE:CostYBAtOnce,
    Intensify.TYPE:Intensify,
    WeekDayOnline.TYPE:WeekDayOnline,
    ShopSeven.TYPE:ShopSeven,
    OnlineMailHold.TYPE:OnlineMailHold,
    FishChance.TYPE:FishChance,
    DeepBoxOpen.TYPE:DeepBoxOpen,
    TBoxNum.TYPE:TBoxNum,
    #全局活动
    WorldBoss.TYPE:WorldBoss,
    Pay.TYPE:Pay,
    LevelRank.TYPE:LevelRank,
    CBERank.TYPE:CBERank,
    BossDouble.TYPE:BossDouble,
    BossEvery.TYPE:BossEvery,
    PayOnce.TYPE:PayOnce,
    HeroTrouble.TYPE:HeroTrouble,
    PayLevel.TYPE:PayLevel,
}


#目前活动开启PlayerOnlReward会调用 re_sub
#RE_SUB代码中未使用
RE_SUB = \
{
    LevelUp.TYPE:LevelUp,
    Fish.TYPE:Fish,
    LevelGifts.TYPE:LevelGifts,
    CostCoin3.TYPE:CostCoin3,
    HFate.TYPE:HFate,
    CostYBAtOnce.TYPE:CostYBAtOnce,
    Intensify.TYPE:Intensify,
    ShopSeven.TYPE:ShopSeven,
    FishChance.TYPE:FishChance,
    DeepBoxOpen.TYPE:DeepBoxOpen,
    TBoxNum.TYPE:TBoxNum
    #Interval.TYPE:Interval,
    #Hold.TYPE:Hold,
    #DateTo.TYPE:DateTo,
    #FishHarvest.TYPE:FishHarvest,
    #FishWater.TYPE:FishWater,
    #FightSpeed.TYPE:FightSpeed,
    #TBox.TYPE:TBox,
    #FateDrop.TYPE:FateDrop,
    #FateLuck.TYPE:FateLuck,
    #MiningRebate.TYPE:MiningRebate,
    #Arena.TYPE:Arena,
    #Shop.TYPE:Shop,
    #WeekDayOnline.TYPE:WeekDayOnline,
    #OnlineMailHold.TYPE:OnlineMailHold,
}

#自动开启关闭活动
AUTO_TASK = [
    LevelUp.TYPE,
    Interval.TYPE,
    Hold.TYPE,
    DateTo.TYPE,
    Fish.TYPE,
    FishHarvest.TYPE,
    FishWater.TYPE,
    FightSpeed.TYPE,
    TBox.TYPE,
    LevelGifts.TYPE,
    CostCoin3.TYPE,
    FateDrop.TYPE,
    FateLuck.TYPE,
    MiningRebate.TYPE,
    Arena.TYPE,
    Shop.TYPE,
    HFate.TYPE,
    CostYBAtOnce.TYPE,
    Intensify.TYPE,
    WeekDayOnline.TYPE,
    ShopSeven.TYPE,
    OnlineMailHold.TYPE,
    FishChance.TYPE,
    DeepBoxOpen.TYPE,
    TBoxNum.TYPE,
]

#自动开启关闭的全局活动
GLOBAL_AUTO_TASK = [
    BossDouble.TYPE,
    WorldBoss.TYPE,
    Pay.TYPE,
    PayOnce.TYPE,
    HeroTrouble.TYPE,
    CBERank.TYPE,
    BossEvery.TYPE,
    LevelRank.TYPE,
    PayLevel.TYPE
    ]


#--------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------
