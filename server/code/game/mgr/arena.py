#!/usr/bin/env python
# -*- coding:utf-8 -*-
import time
from functools import wraps
import random

from corelib import RLock, spawn_later, sleep, log, spawn
from corelib.message import observable
from corelib.memory_cache import TimeMemCache, HitMemCache

from game import Game, grpc_monitor
from game.store.define import (TN_ARENA_RANK, TN_P_ARENA,
    FN_ID, FN_PLAYER_LEVEL, TN_ARENA_RANKS,
    FN_P_ATTR_CBE, FN_P_ATTR_PID,
    )
from game.store import GameObj, StoreObj, FOP_GTE
from game.base import errcode, common
from game.base.common import (is_pass_day, make_lv_regions,
        str2dict2, week_time, zero_day_time, current_time)
from game.base.msg_define import MSG_START, MSG_RES_RELOAD, MSG_AREA_RANKFIRST
from game.base.constant import (\
        MAIL_REWARD, RW_MAIL_ARENA,
        ARENA_AUTO_START, ARENA_AUTO_START_V, ARENA_LEVEL, ARENA_LEVEL_V,
        ARENA_MAX_REWARD, ARENA_MAX_REWARD_V,
        ARENA_FREE_COUNT, ARENA_FREE_COUNT_V,
        ARENA_YB, ARENA_YB_V,
        ARENA_RANK, ARENA_RANK_V,
        ARENA_RW_SUCC, ARENA_RW_SUCC_v, ARENA_RW_FAIL, ARENA_RW_FAIL_v,
        ARENA_RW_WEEKDAY, ARENA_RW_WEEKDAY_V,
        ARENA_REWARDS, ARENA_REWARDS_V,
        ARENA_INFO_COUNT,
        IPI_IDX_CBE, IPI_IDX_LEVEL, IPI_IDX_NAME, IPI_IDX_RID,
    )


from game.player.player import PlayerData, Player
from game.player.attr import PlayerAttr
from game.player.bag import Bag
from game.player.role import PlayerRoles
from game.player.position import PlayerPositions
#from game.player.buff import PlayerBuff


import app
import language

ARENA_STATUS = 'arena' #竞技场服字段名
DEFAULT_STATUS = dict(status=0, rt=0)

FN_NEXT = 'n'
END = -1
RANK_PREV_R = '-' #相关
RANK_PREV_EQ = '=' #等于

MAX_COIN1_IDX = 0
MAX_TRAIN_IDX = 1

#挑战类型: 1=挑战胜利, 2=挑战失败, 3=被挑战胜利, 4=被挑战失败
LT_SUCC = 1
LT_FAIL = 2
LT_B_SUCC = 3
LT_B_FAIL = 4

#竞技场信息缓存时间
CACHE_TIME = 60 * 5
#竞技场信息缓存数量
CACHE_SIZE = 3000
#每隔多久保存排名数据
SAVE_RANK_TIME = 600
#单条数据保存的玩家的个数
SAVE_PER_LEN = 100000

arena_level = 0 #玩家开放竞技场等级
max_rewards = None #每日奖励上限
free_count = 0 #免费次数
arena_coin = 0 #元宝
arena_ranks = lambda x:None #竞技玩家列表规则
arena_rw_succ = None
arena_rw_fail = None
arena_rw_weekdays = None
arena_rewards = None
arena_auto_start = 0

#排名第一
RANK_FIRST = 1

#表中的键
KEY_SORT = 'sort'
KEY_PIDS = 'pids'
KEY_ID = 'id'

def init_setting():
    """ 奖励上限,返回:(银币, 练历) """
    global arena_level, max_rewards, free_count, arena_coin, arena_ranks, \
            arena_rw_succ, arena_rw_fail, arena_rw_weekdays, arena_rewards, \
            arena_auto_start
    setting_mgr = Game.setting_mgr
    arena_level = setting_mgr.setdefault(ARENA_LEVEL, ARENA_LEVEL_V)
    auto_times = setting_mgr.setdefault(ARENA_MAX_REWARD, ARENA_MAX_REWARD_V)
    max_rewards = make_lv_regions(str2dict2(auto_times).items())
    free_count = setting_mgr.setdefault(ARENA_FREE_COUNT, ARENA_FREE_COUNT_V)
    arena_coin = setting_mgr.setdefault(ARENA_YB, ARENA_YB_V)
    ranks = setting_mgr.setdefault(ARENA_RANK, ARENA_RANK_V)
    arena_ranks = make_lv_regions(str2dict2(ranks).items())
    #奖励
    rw_succ = setting_mgr.setdefault(ARENA_RW_SUCC, ARENA_RW_SUCC_v)
    arena_rw_succ = map(int, rw_succ.split('|'))
    rw_fail = setting_mgr.setdefault(ARENA_RW_FAIL, ARENA_RW_FAIL_v)
    arena_rw_fail = map(int, rw_fail.split('|'))
    arena_rw_weekdays = setting_mgr.setdefault(ARENA_RW_WEEKDAY, ARENA_RW_WEEKDAY_V)
    arena_rw_weekdays = map(int, arena_rw_weekdays.split('|'))
    rewards = setting_mgr.setdefault(ARENA_REWARDS, ARENA_REWARDS_V)
    arena_rewards = make_lv_regions(rewards)
    arena_auto_start = setting_mgr.setdefault(ARENA_AUTO_START, ARENA_AUTO_START_V)

def is_bot(pid):
    """ 判断pid是否机器人 """
    return pid < END

class PlayerArenaData(StoreObj):
    def init(self):
        self.id = None #=pid
        self.t = 0
        self.coin1 = 0
        self.train = 0
        self.c = 0#挑战次数
        self.logs = []#战报列表

class PlayerArena(GameObj):
    TABLE_NAME = TN_P_ARENA
    DATA_CLS = PlayerArenaData
    MAX_REPORT = 5
    def __init__(self, pid, adict=None):
        super(PlayerArena, self).__init__(adict=adict)
        self.data.id = pid
        self.rival_id = None #挑战者id

    @property
    def rank(self):
        return Game.rpc_arena_mgr.get_rank(self.data.id)

    def pass_day(self):
        """ 玩家数据是否过期 """
        if not is_pass_day(self.data.t):
            return
        self.modified = True
        self.rival_id = None
        self.data.coin1 = 0
        self.data.train = 0
        self.data.c = 0
        self.data.t = current_time()

    def reward(self, vip, coin1, train, mul):
        """ 战斗
        """
        self.modified = True
        #self.data.train += train
        coin1, train = mul*coin1, mul*train
        tup = max_rewards(vip)
        max_coin1, max_train = int(tup[MAX_COIN1_IDX])*mul, int(tup[MAX_TRAIN_IDX])*mul
        if self.data.coin1 + coin1 > max_coin1:
            coin1 = max_coin1 - self.data.coin1
            self.data.coin1 = max_coin1
        else:
            self.data.coin1 += coin1
        if self.data.train + train > max_train:
            train = max_train - self.data.train
            self.data.train = max_train
        else:
            self.data.train += train
        return coin1, train

    def add_log(self, t, rid, rival_name, rk, fid):
        """ 添加战报 """
        self.modified = True
        logs = self.data.logs
        logs.append(dict(ct=current_time(), t=t, n=rival_name, rk=rk, fid=fid)) #id=rid,
        while len(logs) > self.MAX_REPORT:
            logs.pop(0)

    @property
    def free_count(self):
        """ 剩余次数 """
        return max(0, free_count - self.data.c)

    def buy(self, c):
        """ 购买次数 """
        self.data.c -= c
        self.modified = True
        return self.free_count

    def enter(self, vip, mul):
        """ 获取竞技场信息 """
        #ARENA_INFO_COUNT
        self.pass_day()
        tup = max_rewards(vip)
        change_logs = self.data.logs[:]
        if len(self.data.logs) > self.MAX_REPORT:
            change_logs = change_logs[-1*self.MAX_REPORT:]
        return dict(c=self.free_count,
                coin1=(self.data.coin1, str(int(tup[MAX_COIN1_IDX])*mul)),
                train=(self.data.train, str(int(tup[MAX_TRAIN_IDX])*mul)),
                logs=change_logs)

    def start_arena(self, rival_id):
        """ 开始挑战 """
        self.pass_day()
        if not self.free_count:#检查费用
            return 0, errcode.EC_COST_ERR
        self.data.t = current_time()
        self.rival_id = rival_id
        return 1, rival_id

    def check_cost(self, coin2):
        """ 检查玩家是否有足够元宝进行付费竞技 """
        return coin2 >= arena_coin

    def cost_arena(self):
        """ 挑战结束前调用,先次数, """
        self.modified = True
        if self.data.c < free_count:
            self.data.c += 1
            return 1
        else:
            return 0

def wrap_arena(func):
    @wraps(func)
    def _func(self, pid, *args, **kw):
        if self.stoped:
            return 0, errcode.EC_CLOSE
        kw['parena'] = self.init_player(pid)
        try:
            return func(self, pid, *args, **kw)
        finally:
            kw['parena'].save(Game.rpc_store)
    return _func

def wrap_arena_rival(func):
    @wraps(func)
    def _func(self, pid, rid, *args, **kw):
        if self.stoped:
            return 0, errcode.EC_CLOSE
        kw['parena'] = self.init_player(pid)
        kw['rival'] = self.init_player(rid)
        try:
            return func(self, pid, rid, *args, **kw)
        finally:
            kw['parena'].save(Game.rpc_store)
            kw['rival'].save(Game.rpc_store)
    return _func

def wrap_lock(func):
    @wraps(func)
    def _func(self, *args, **kw):
        with self._lock:
            return func(self, *args, **kw)
    return _func

@observable
class ArenaMgr(object):
    """ 竞技场管理类 """
    _rpc_name_ = 'rpc_arena_mgr'
    PLAYER_TIMEOUT = 60 * 0.1
    BOT_RANK = 1000 #机器人预留排名数
    def __init__(self):
        self.arenas = TimeMemCache(size = CACHE_SIZE, default_timeout = CACHE_TIME) #玩家信息 {pid:PlayerArena}
        self.rivals = TimeMemCache(size = CACHE_SIZE, default_timeout = CACHE_TIME) # {pid:[name, rid]}
        self.rewards = HitMemCache(size = CACHE_SIZE)
        self.bots = {}

        self._lock = RLock()
        self.stoped = True
        self._reward_task = None
        self._auto_start_task = None
        self.clear()
        app.sub(MSG_START, self.start)
        self._active_mul = 1

        self.sorts = {} #数据库中保存，方便修改 {sort:id}

    def _get_status(self):
        status = Game.rpc_status_mgr.get(ARENA_STATUS)
        if status is None:
            self.arena_status = DEFAULT_STATUS
            return DEFAULT_STATUS
        return status
    def _set_status(self, value):
        Game.rpc_status_mgr.set(ARENA_STATUS, value)
    arena_status = property(_get_status, _set_status)

    def _get_is_start(self):
        """ 竞技场是否开启 """
        return self.arena_status['status']
    def _set_is_start(self, value):
        arena_status = self.arena_status
        arena_status['status'] = int(bool(value))
        self.arena_status = arena_status
    #竞技场是否处于启动状态
    is_start = property(_get_is_start, _set_is_start)

    def _get_reward_time(self):
        """ 获取上一次奖励时间 """
        return self.arena_status['rt']
    def _set_reward_time(self, value):
        arena_status = self.arena_status
        arena_status['rt'] = int(value)
        self.arena_status = arena_status
    reward_time = property(_get_reward_time, _set_reward_time)

    def clear(self):
        self.ranks = [] #排行榜 [pid, ...]
        self.pid2ranks = {} # {pid:rk}

    def reload(self):
        """ 重新加载资源数据 """
        self.rewards.clear()
        init_setting()

    def start(self, init=False):
        if not self.stoped:
            return
        init_setting()
        if not self.is_start:#开启自动启动线程
            if self._auto_start_task is None:
                self._auto_start_task = spawn_later(0, self._auto_start)
            return
        log.debug(u'arena_mgr start!')
        spawn(self.lood_save)
        Game.setting_mgr.sub(MSG_RES_RELOAD, self.reload)
        if init:
            self.init()
        else:
            self.load()
        self.arena_reward()
        Game.chat_mgr.sys_send(language.ARENA_START)
        self.stoped = False

    def stop(self):
        if self.stoped:
            return
        self.stoped = True
        self.save()
        if self._reward_task:
            self._reward_task.kill(block=False)
            self._reward_task= None

    def _auto_start(self):
        global arena_auto_start, arena_level
        sleep_times = 60 * 5
        log.info('arena auto_start(%s) running', arena_auto_start)
        while 1:
            sleep(sleep_times)
            c = PlayerData.count({FN_PLAYER_LEVEL:{FOP_GTE:arena_level}})
            if c >= arena_auto_start:
                log.info('arena auto start:%d', c)
                self.init()
                self.is_start = True
                self.start()
                self._auto_start_task = None
                return

    def lood_save(self):
        """ 保存 """
        while 1:
            #保存排名
            sleep(SAVE_RANK_TIME)
            self.save()

    def save(self):
        """ 保存 """
        #保存排名
        log.debug('------arena-rank-save---------')
        if not self.ranks:
            return
        num = len(self.ranks) / SAVE_PER_LEN + 1
        for i in xrange(num):
            start = i * SAVE_PER_LEN
            end = start + SAVE_PER_LEN
            pids = self.ranks[start:end]
            sort = i + 1
            if sort in self.sorts:
                dic = dict(id=self.sorts[sort], sort=sort, pids=pids)
                Game.rpc_store.save(TN_ARENA_RANKS, dic)
            else:
                dic = dict(id=sort, sort=sort, pids=pids)
                insert_id = Game.rpc_store.insert(TN_ARENA_RANKS, dic)
                self.sorts[sort] = insert_id
        log.debug('-----arena-rank-save--ok-----')

    @wrap_lock
    def init(self):
        """ 初始化竞技场数据:根据30级以上的玩家战斗力排名,得到竞技场排名 """
        log.warn(u"初始化竞技场")
        self.clear()
        #删除记录
        Game.rpc_store.deletes(TN_ARENA_RANKS)
        Game.rpc_store.deletes(TN_P_ARENA)
        #Game.rpc_store.insert(TN_ARENA_RANK, {FN_ID:0, FN_NEXT:END})
        #根据30级以上玩家战斗力排名
        CBEs = [(i[FN_P_ATTR_PID], i.get(FN_P_ATTR_CBE, index))
                for index, i in enumerate(PlayerAttr.get_CBE_ranks())]
        levels = PlayerData.get_players_levels(None)
        #插入机器人
        for i in xrange(self.BOT_RANK):
            self.update_rank(END, END-(i+1))

        #真实玩家
        for pid, CBE in CBEs:
            if pid not in levels or levels[pid] < arena_level:
                continue
            self.update_rank(END, pid)

    @wrap_lock
    def load(self):
        """ 使用新方法的加载 """
        self.clear()
        ranks = Game.rpc_store.load_all(TN_ARENA_RANKS)
        if ranks is None:
            return
        rank_sort = sorted(ranks, key=lambda dic:dic[KEY_SORT])
        for rank in rank_sort:
            self.ranks.extend(rank[KEY_PIDS])
        for index, pid in enumerate(self.ranks):
            rk = index + 1
            self.pid2ranks[pid] = rk

    def get_rank(self, pid):
        return self.pid2ranks.get(pid)

    def get_pid(self, rank):
        if rank < 1 or rank > len(self.ranks):
            return 0
        return self.ranks[rank - 1]

    def update_rank(self, rank, pid):
        """ 更新排名 """
        orank = self.pid2ranks.get(pid, END)
        assert rank <= orank, ValueError('update_rank error:%s <= %s' % (rank, orank))
        #内存数据修改, rank 必须 <= orank
        if rank == END:
            self.ranks.append(pid)
            self.pid2ranks[pid] = len(self.ranks)
        else:
            self.ranks.pop(orank-1)
            self.ranks.insert(rank-1, pid)
            for index, pid in enumerate(self.ranks[rank-1:orank]):
                self.pid2ranks[pid] = rank + index

    def init_player(self, pid):
        """ 加载并返回玩家信息 """
        parena =  self.arenas.get(pid, add_time = CACHE_TIME)
        if parena is None:
            parena = PlayerArena(pid)
            self.arenas.set(pid, parena)
            data = Game.rpc_store.load(TN_P_ARENA, pid)
            if data is not None:
                parena.update(data)
                parena.pass_day()
            else:
                parena.modify()
            if pid not in self.pid2ranks:
                with self._lock:
                    self.update_rank(END, pid)
        return parena

    def _get_rivals(self, pids):
        """ 批量获取对手信息 """
        rs = {}
        ids = []
        for i in pids:
            rival = self.rivals.get(i)
            if rival:
                rs[i] = rival
            elif is_bot(i):
                bot = self.get_bot(i)
                rs[i] = bot._bot_rival
            else:
                ids.append(i)
        if ids:
            onlines, nids = Game.rpc_player_mgr.get_player_infos(ids, CBE=1)
            #nids = Game.rpc_player_mgr.get_name_rids(ids)
            self.rivals.update(nids)
            rs.update(nids)
        return rs
    get_rival_infos = _get_rivals

    def get_name(self, pid):
        rival = self.rivals.get(pid)
        if rival:
            return rival[0]
        else:
            rs = self._get_rivals([pid])
            return rs[pid][0]

    def get_rivals(self, parena):
        """ 获取对手列表 """
        base_rk = parena.rank
        base_pid = parena.data.id
        ranks = arena_ranks(base_rk)
        ids = []
        rks = []
        for r in ranks[1:]:
            if ranks[0] == RANK_PREV_R:
                    rk = base_rk - int(r)
            elif ranks[0] == RANK_PREV_EQ:
                    rk = int(r)
            else:
                raise ValueError('ARENA_RANK error:%s' % ranks)
            rks.append(rk)
            pid = self.get_pid(rk)
            if pid:
                ids.append(pid)
        if base_pid not in ids:
            rks.append(base_rk)
            ids.append(base_pid)
        rivals = self._get_rivals(ids)
        rs = []
        for index, i in enumerate(ids):
            rival = rivals.get(i)
            if not rival:
                continue
            CBE = 0 if rival[IPI_IDX_CBE] is None else rival[IPI_IDX_CBE]
            rs.append(dict(rk=rks[index], pid=i,
                n=rival[IPI_IDX_NAME],
                rid=rival[IPI_IDX_RID],
                level=rival[IPI_IDX_LEVEL],
                CBE=CBE))
        return rs

    def get_bot(self, bid):
        assert is_bot(bid), ValueError('bid(%s) is not bot' % bid)
        try:
            return self.bots[bid]
        except KeyError:
            #从数据库中随机选择某等级区间的玩家作为基础数据
            key = 'arena_bot_pids'
            pids = Game.gcaches.get(key)
            if not pids:
                pids = PlayerData.get_level_pids(arena_level, arena_level + 10)
                Game.gcaches.set(key, pids, timeout=60*5)
            pid = random.choice(pids)
            bot = Player.load_player(pid)
            data = bot.data
            data.id = bid
            data.name = Game.res_mgr.get_random_name()
            bot._bot_rival = (data.name, data.rid, data.level, bot.play_attr.CBE)
            self.bots[bid] = bot
            return bot


    def look_bot(self, bid):
        """ 获取机器人信息
        result:rs, info
        """
        bot = self.get_bot(bid)
        try:
            return 1, bot._bot_look
        except AttributeError:
            bot._bot_look = bot.look()
            return 1, bot._bot_look

    @grpc_monitor
    @wrap_arena
    def enter(self, pid, vip, parena=None):
        """ 玩家进入竞技场获取相关信息 """
        msg_dict = parena.enter(vip, self._active_mul)
        msg_dict['rk'] = self.get_rank(pid)
        msg_dict['rivals'] = self.get_rivals(parena)
        return 1, msg_dict

    @grpc_monitor
    @wrap_arena
    def start_arena(self, pid, rival_id, parena=None):
        """ 开始挑战排位,获取被挑战者数据, rk:挑战的玩家id """
        return parena.start_arena(rival_id)

    @grpc_monitor
    @wrap_arena
    def buy_arena(self, pid, c, coin2, parena=None):
        """ 购买次数 """
        cost = c * arena_coin
        if cost > coin2:
            return 0, errcode.EC_COST_ERR
        c = parena.buy(c)
        return 1, (c, cost)

    @grpc_monitor
    @wrap_arena_rival
    @wrap_lock
    def end_arena(self, pid, rid, is_ok, fp_id, vip, parena=None, rival=None, gm=False):
        """ 结束挑战,更新信息
        """
        if not gm and (not rid or rid != parena.rival_id):
            return 0, errcode.EC_VALUE
        if not gm and not parena.cost_arena():
            return 0, errcode.EC_COST_ERR
        parena.rival_id = None
        return self._end_arena(is_ok, parena, rival, fp_id, vip)

    def _end_arena(self, is_ok, parena, rival, fp_id, vip):
        """ 挑战胜利
        挑战类型: 1=挑战胜利, 2=挑战失败, 3=被挑战胜利, 4=被挑战失败
        """
        pid, rpid = parena.data.id, rival.data.id
        pname, rname = self.get_name(pid), self.get_name(rpid)
        parena_rank = self.get_rank(pid)
        rival_rank = self.get_rank(rpid)
        if is_ok:
            if rival_rank < parena_rank: #排位调整
                self.update_rank(rival_rank, pid)
                parena_rank, rival_rank = rival_rank, rival_rank + 1
                #竞技场第一名广播事件
                if parena_rank == RANK_FIRST:
                    self.safe_pub(MSG_AREA_RANKFIRST, pid, pname, rpid, rname)
            #奖励
            coin, train = arena_rw_succ
            coin, train = parena.reward(vip, coin, train, self._active_mul)
            lt_p, lt_r = LT_SUCC, LT_B_FAIL
        else:
            #奖励
            coin, train = arena_rw_fail
            coin, train = parena.reward(vip, coin, train, self._active_mul)
            lt_p, lt_r = LT_FAIL, LT_B_SUCC
        #战报
        parena.add_log(lt_p, rpid, rname, parena_rank, fp_id)
        rival.add_log(lt_r, pid, pname, rival_rank, fp_id)
        return 1, (coin, train)

    def set_active_reward(self, mul):
        """活动奖励的设置"""
        self._active_mul = mul

    #@property
    #def next_reward_times(self):
    #    """ 到下一次奖励的秒数
    #    :rtype : int
    #    """
    #    reward_time = self.reward_time
    #    zero_time = zero_day_time()
    #    for index, weekday in enumerate(arena_rw_weekdays):
    #        t = week_time(weekday, zero=1)
    #        delay_time = t - zero_time
    #        if delay_time < -60:#前几天
    #            continue
    #        if delay_time < 60:
    #            if not is_pass_day(reward_time):#今天刚奖励完
    #                continue
    #            return 1
    #        return int(t - time.time())+2     #计算可用23:59:59发送奖励必须往后移一点否则一秒会执行多次
    #    #返回下周奖励时间
    #    return int(week_time(arena_rw_weekdays[0], zero=1, delta=1) - time.time())
    #    #raise ValueError('next_reward_times:%s' % str(arena_rw_weekdays))

    @property
    def next_reward_time(self):
        """ 到下一次奖励的具体时间
        :rtype : int
        """
        reward_time = self.reward_time
        zero_time = zero_day_time()
        for index, weekday in enumerate(arena_rw_weekdays):
            t = week_time(weekday, zero=1)
            delay_time = t - zero_time
            if delay_time < 0:#前几天
                continue
            if delay_time == 0:
                if reward_time == t:#今天刚奖励完
                    continue
            return  t
            #返回下周奖励时间
        return week_time(arena_rw_weekdays[0], zero=1, delta=1)

    def arena_reward(self):
        """ 定时发放奖励 """
        #安装定时器
        #t = self.next_reward_times
        next_time = self.next_reward_time
        times = next_time - time.time() if next_time > time.time() else 0
        times += 10
        log.info('arena_reward after %s times', times)
        self._reward_task = spawn_later(times, self._reward_nomal, next_time)

    def _reward_nomal(self, r_t):
        """
        正常的发放奖励
        """
        global arena_rewards
        self.reward_time = r_t
        #下一个定时发放
        if not self.stoped:
            self.arena_reward()
        self._reward()

    def reward_active(self):
        """
        活动的发放奖励
        """
        if not self.stoped:
            self._reward()
            return
        log.error('%s is stop _reward_active is not send', self)

    def _reward(self):
        """ 发放奖励 """
        log.info(u'竞技场排名:%s', self.ranks[:500])
        #log.info('arena_ranks:%s', self.pid2ranks)

        mail_mgr = Game.mail_mgr
        rw_mail = Game.res_mgr.reward_mails.get(RW_MAIL_ARENA)
        levels = {}
        lv_count = 30 #批量读取等级 global arena_level
        ranks = self.ranks[:]
        log.info('arena_reward:%s', len(ranks))
        for index, pid in enumerate(ranks):
            rank = index + 1
            pids = ranks[index:index + lv_count]
            if pid not in levels:#批量获取等级
                self._get_rivals(pids)
                rs = PlayerData.get_players_levels(pids)
                if rs:
                    levels.update(rs)
            if pid not in levels:#玩家不存在
                continue
            rs, items, rid = self.get_reward(rank, levels[pid])
            if not rs:
                break
            #content = rw_mail.content % dict(name=self.get_name(pid), rank=rank)
            content = rw_mail.content % dict(rank=rank)
            mail_mgr.send_mails(pid, MAIL_REWARD, rw_mail.title, RW_MAIL_ARENA,
                    items, param=content, rid=rid)

    @grpc_monitor
    def get_reward(self, rk, level):
        """ 获取排行榜奖励内容 """
        key = (rk, level)
        v = self.rewards.get(key)
        if v:
            return v

        rid = arena_rewards(rk)
        if not rid:
            v = (0, errcode.EC_NOFOUND, 0)
        else:
            reward = Game.reward_mgr.get(rid)
            items = reward.reward(dict(level=level, rank=rk))
            v = (1, items, rid)
        self.rewards.set(key, v)
        return v

    @grpc_monitor
    def get_ranks(self, start, end):
        """ 获取排名列表 """
        #rs = [pid for pid in self.ranks if not is_bot(pid)]
        #return rs[start:end]
        return self.ranks[start:end]


    def gm_add_count(self, pid, c):
        parena = self.init_player(pid)
        parena.buy(c)

    def gm_get_rid_byrank(self, rank):
        """ gm听过竞技场获取排名 """
        if rank > len(self.ranks):
            return
        return self.ranks[rank-1]

    def gm_change_rank(self, pid, rid, fp_id, vip):
        """ gm改变排行榜等级 """
        self.end_arena(pid, rid, 1, fp_id, vip, gm=True)

def new_arena_mgr():
    mgr = ArenaMgr()
    return mgr
