#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time, math

from corelib import spawn, sleep, log
from corelib.message import observable
from store.store import StoreObj, GameObj

from game import Game, pack_msg
from game.base import common
from game.store import TN_BOSS
from game.glog.common import PL_WORLD_BOSS
from game.store.define import TN_PLAYER, TN_P_MAIL
from game.glog.common import COIN_BOSS_CD
from game.player.player import PlayerData
from game.base.msg_define import (MSG_START, MSG_LOGON, MSG_LOGOUT,
    MSG_ALLY_UP, MSG_REWARD_WORLDBOSS, MSG_REWARD_WORLDITEMS,MSG_WBOSS_RANK,
)
from game.base.errcode import (EC_BOSS_NOALLY, EC_BOSS_NOSTART, EC_BOSS_CD,
    EC_BOSS_FINISH, EC_BOSS_NO_CD, EC_COST_ERR, EC_BOSS_OVER, EC_BOSS_NOTIME,
    EC_BOSS_MAXBUFF, EC_VALUE)
from game.base.constant import (BOSS_NOTICE_START, BOSS_NOTICE_START_V, BOSS_START_TIME,
    BOSS_START_TIME_V, BOSS_HP_TIME, BOSS_HP_TIME_V, BOSS_RANK_TIME, BOSS_RANK_TIME_V,
    DIFF_TITEM_EXP, IT_ITEM_STR, IT_CAR_STR, MAIL_REWARD, RW_MAIL_ABOSS, DIFF_TITEM_COIN1,
    BOSS_ALLY_LEVEL, BOSS_ALLY_LEVEL_V, BOSS_ALLY_START, BOSS_ALLY_START_V, BOSS_ALLY_TIME,
    BOSS_ALLY_TIME_V, BOSS_TIME, BOSS_TIME_V, ALLY_BOSS_TIME, RW_MAIL_BOSS,
    BOSS_CD_COIN2, BOSS_CD_COIN2_V, BOSS_ALLYCD_COIN2, BOSS_ALLYCD_COIN2_V,
    HORN_TYPE_WORLDBOSSHP, HORN_TYPE_WORLDBOSSFIST, HORN_TYPE_WORLDBOSSEND,
    HORN_TYPE_WORLDBOSSFAIL, HORN_TYPE_WORLDNOTICE, BOSS_ENTER_LEVEL,
    BOSS_ENTER_LEVEL_V, HORN_TYPE_ALLYBOSSHP, HORN_TYPE_ALLYBOSSFIST,
    HORN_TYPE_ALLYBOSSFAIL, HORN_TYPE_ALLYNOTICE, HORN_TYPE_ALLYBOSSEND,
    BOSS_REWARD_VIP, BOSS_REWARD_VIP_V, BOSS_ADD_BUFF, BOSS_ADD_BUFF_V,
    BOSS_MAX_BUFF, BOSS_MAX_BUFF_V, CHATER_START, BOSS_KILL_TIME,
    BOSS_SAFE_TIME, BOSS_SAFE_TIME_V, RW_MAIL_BOSSVIP, BOSS_KILL_TIME_V
)

import language

#boss战 类型
WORLD_BOSS = 1   #世界
ALLY_BOSS = 2  #同盟

#同盟aid值特殊意义(世界boss)
AID_WORLD_BOSS = 0

#排名个数
RANK_MAX = 5

#天所对的秒数
DAY_SEC = 86400
#小时对秒数
HOUR_SEC = 3600
#分钟对饮秒数
MIN_SEC = 60

def wrap_ally_data(func):
    """ 通过pid获取同盟boss对象 """
    def _func(self, pid, *args, **kw):
        aid = Game.rpc_ally_mgr.get_aid_by_pid(pid)
        if not aid:
            return False, EC_BOSS_NOALLY
        if aid not in self.notices:
            return False, EC_BOSS_NOSTART
        boss_id = self.a_bosses.get(aid)
        boss = self.bosses.get(boss_id)
        #if not boss.is_start:
        #    return False, EC_BOSS_NOSTART
        kw['boss'] = boss
        return func(self, pid, *args, **kw)
    return _func

def wrap_boss_data(func):
    """ 通过同盟id获取同盟boss对象 """
    def _func(self, aid, *args, **kw):
        boss_id = self.a_bosses.get(aid)
        if not boss_id:
            return False, EC_BOSS_NOSTART
        kw['boss'] = self.bosses.get(boss_id)
        return func(self, aid, *args, **kw)
    return _func

def wrap_world_data(func):
    """ 获取世界boss对象 """
    def _func(self, *args, **kw):
        if not self.w_start_boss:
            return False, EC_BOSS_NOSTART
        kw['boss'] = self.w_start_boss
        return func(self, *args, **kw)
    return _func

def logon_by_boss(pid):
    #log.info('logon_by_boss:%s', pid)
    online, player_infos = Game.rpc_player_mgr.get_player_infos([pid])
    player_info = player_infos[pid]
    if player_info[2] >= Game.rpc_boss_mgr.fetch_boss_uplevel:
        spawn(Game.rpc_boss_mgr.player_logon, pid)

def logout_by_boss(pid):
    #log.info('logout_by_boss:%s', pid)
    spawn(Game.rpc_boss_mgr.player_logout, pid)

def ally_up(aid, level):
    """ 同盟升级 """
    log.info('ally_up :%s, %s', aid, level)
    spawn(Game.rpc_boss_mgr.new_ally_boss, aid, level)

def ally_close():
    """ 同盟解散 """
    pass

@observable
class BossMgr(object):
    """ boss战管理系统 """
    _rpc_name_ = 'rpc_boss_mgr'
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        self._loop_task = None
        self._game = Game
        #gm 使用
        self.gm_stoped = False
        self.gm_start = False
        self.gm_wboss = False
        self.gm_aboss = 0
        #{boss表id1:boss表对象1, ...}包括同盟和世界boss战
        self.bosses = {}

        #同盟boss保存 {同盟id1:boss表id1, ...}
        self.a_bosses = {}
        #世界boss保存 {resblid:boss表id1, ...}
        self.w_bosses = {}

        #boss开启提前广播列表[同盟id1, ...]
        self.notices = []

        #当前开启的世界boss战的(包括通知的时间)
        self.w_start_boss = None

        #广播世界boss剩余血量的条件
        self.w_horn_conds = []

        #广播同盟boss剩余血量的条件
        self.a_horn_conds = []

        import app
        app.sub(MSG_START, self.start)

    def set_stoped(self):
        """ gm使用停止boss战 """
        for boss_id in self.w_bosses.itervalues():
            w_boss = self.bosses.get(boss_id)
            if not w_boss:
                continue
            w_boss.gm_stoped = True
    
    def set_boss_level(self, level, index):
        """ 设置世界boss等级 """
        res_starts = self.fetch_start_time
        res = res_starts.keys()
        res.sort()
        res_time = res[index]
        res_blid = res_starts.get(res_time)
        boss_id = self.w_bosses[res_blid]
        #setting表的改动后建立新的boss数据
        if boss_id:
            w_boss = self.bosses.get(boss_id)
        else:
            w_boss = self._new_world_boss(res_blid)
        res_boss_level = Game.res_mgr.boss_level.get(w_boss.data.blid)
        key = (res_boss_level.mid, level)
        res_boss_level_up = Game.res_mgr.boss_level_by_midlevel.get(key)
        w_boss.data.blid = res_boss_level_up.id
        w_boss.data.deads = 0

    def kill_boss(self, pid, name, hurts, aid=0):
        """ 秒杀boss aid=0 世界 aid!=0同盟"""
        if aid:
            boss_id = self.a_bosses.get(aid)
            a_boss = self.bosses.get(boss_id)
            if not a_boss:
                return False
            a_boss.one_finish(pid, name, hurts)
            return True
        self.w_start_boss.one_finish(pid, name, hurts)
        return True

    def set_started(self, aid=0, time=0, delay_time=300):
        """ gm使用开始boss战斗 """
        if aid:
            boss_id = self.a_bosses.get(aid)
            if boss_id:
                #停止当前的boss
                a_boss = self.bosses.get(boss_id)
                if not a_boss:
                    return
                a_boss.gm_stoped = True
            else:
                self.new_ally_boss(aid, 1)
                boss_id = self.a_bosses.get(aid)
                a_boss = self.bosses.get(boss_id)
            #开启
            self.gm_aboss = aid
            a_boss.start(delay_time)
            a_boss.gm_stoped = False
            return
        #停止当前的boss
        self.set_stoped()
        #开启下一场boss战
        self.gm_start = True
        res_starts = self.fetch_start_time
        times = res_starts.keys()
        times.sort()
        start_blid = times[time]
        for start_sec, res_blid in res_starts.iteritems():
            if start_sec != start_blid:
                continue
            boss_id = self.w_bosses[res_blid]
            #setting表的改动后建立新的boss数据
            if boss_id:
                w_boss = self.bosses.get(boss_id)
            else:
                w_boss = self._new_world_boss(res_blid)
            self.gm_wboss = True
            w_boss.start(60)
            w_boss.gm_stoped = False
            #w_boss.start(w_boss.fetch_notice_start)

    def start(self):
        self._game.rpc_player_mgr.rpc_sub(logon_by_boss, MSG_LOGON, _proxy=True)
        self._game.rpc_player_mgr.rpc_sub(logout_by_boss, MSG_LOGOUT, _proxy=True)
        self._game.rpc_ally_mgr.rpc_sub(ally_up, MSG_ALLY_UP, _proxy=True)
        self.load()
        self._loop_task_ally = spawn(self._a_boss)
        self._loop_task_world = spawn(self._w_boos)
    
    def get_horn_conds(self, aid):
        """ 获取boos血量广播条件 """
        if not aid:
            if not self.w_horn_conds:
                self.w_horn_conds = self._game.rpc_horn_mgr.get_conds(HORN_TYPE_WORLDBOSSHP)
                self.w_horn_conds.sort(reverse=True)
            return self.w_horn_conds
        else:
            if not self.a_horn_conds:
                self.a_horn_conds = self._game.rpc_horn_mgr.get_conds(HORN_TYPE_ALLYBOSSHP)
                self.a_horn_conds.sort(reverse=True)
            return self.a_horn_conds
    @property
    def fetch_boss_uplevel(self):
        """ 获取boss解锁等级 """
        return Game.setting_mgr.setdefault(BOSS_ENTER_LEVEL, BOSS_ENTER_LEVEL_V)

    def player_logon(self, pid):
        """ 玩家登陆，检测boss战是否已开启 并广播 """
        sleep(10)
        if self.w_start_boss:
            self.w_start_boss.p_logon(pids=[pid])
        aid = Game.rpc_ally_mgr.get_aid_by_pid(pid)
        if aid and aid in self.notices:
            boss_id = self.a_bosses.get(aid)
            a_boss = self.bosses.get(boss_id)
            a_boss.p_logon(pids=[pid])

    def player_logout(self, pid):
        """ 玩家登出，退出boss场景 """
        if self.w_start_boss:
            self.w_start_boss.p_logout(pid=pid)
        aid = Game.rpc_ally_mgr.get_aid_by_pid(pid)
        if aid and aid in self.notices:
            boss_id = self.a_bosses.get(aid)
            a_boss = self.bosses.get(boss_id)
            a_boss.p_logout(pid=pid)

    def load(self):
        """ 加载boss战数据 """
        all_boss = Game.rpc_store.query_loads(TN_BOSS, {})
        res_starts = self.fetch_start_time
        for boss in all_boss:
            if boss['aid'] == AID_WORLD_BOSS:
                #根据setting表初始化boss数据
                res_starts_copy = res_starts.copy()
                is_init_boss = False
                for k, v in res_starts_copy.iteritems():
                    if v == boss['resblid']:
                        res_starts.pop(k)
                        is_init_boss = True
                if not is_init_boss:
                    continue
                oBoss = Boss.new_by_dict(self, boss)
                self.w_bosses[oBoss.data.resblid] = oBoss.data.id
            else:
                oBoss = Boss.new_by_dict(self, boss)
                self.a_bosses[oBoss.data.aid] = oBoss.data.id
            self.bosses[oBoss.data.id] = oBoss
            #创建世界boss
        if res_starts:
            #数据库中无资源指定的boss重新加入新boss
            self.new_world_bosses(res_starts)

    def new_world_bosses(self, res_starts):
        """ 添加世界boss """
        add_blids = []
        #同一个怪物id只加入一条
        for start_sec, res_blid in res_starts.iteritems():
            if res_blid in add_blids:
                continue
            add_blids.append(res_blid)
            self._new_world_boss(res_blid)

    def _new_world_boss(self, res_blid):
        """ 添加setting表指定的世界boss """
        oBoss = Boss.get_obj(AID_WORLD_BOSS, self)
        oBoss.new(res_blid)
        oBoss.data.aid = AID_WORLD_BOSS
        self.w_bosses[res_blid] = oBoss.data.id
        self.bosses[oBoss.data.id] = oBoss
        return oBoss

    def new_ally_boss(self, aid, level):
        """ 添加同盟boss """
        if level != self.fetch_aboss_level:
            return
        oBoss = Boss.get_obj(aid, self)
        oBoss.data.aid = aid
        oBoss.new(level)
        self.bosses[oBoss.data.id] = oBoss
        self.a_bosses[aid] = oBoss.data.id

    def _a_boss(self):
        """ 同盟boss开启提前广播(判断时间是否到达) """
        while 1:
            min_sec = 0
            now_sec = self.get_week_seconds()
            for aid, a_boss_id in self.a_bosses.iteritems():
                if not a_boss_id or aid in self.notices:
                    continue
                #防止gm开启的同盟战被再次开启
                if aid == self.gm_aboss:
                    continue
                a_boss = self.bosses.get(a_boss_id)
                self.handle_week(a_boss)
                if not a_boss or a_boss.data.c > 0:
                    continue
                min_sec = a_boss.handle_start_time(now_sec, min_sec)
            #log.debug("min_sec--time:: %s", min_sec)
            #还有多久通知min_sec
            #if min_sec <= 0:
            #    min_sec = self.fetch_notice_start
            #log.debug('ally---sleep %s', min_sec)
            sleep(1)

    def _w_boos(self):
        """ 世界boos开启提前广播(判断时间是否到达) """
        res_starts = self.fetch_start_time
        while 1:
            min_sec = 0
            now_sec = self.get_today_seconds()
            for start_sec, res_blid in res_starts.iteritems():
                if self.gm_start:
                    continue
                boss_id = self.w_bosses[res_blid]
                #setting表的改动后建立新的boss数据
                if boss_id:
                    w_boss = self.bosses.get(boss_id)
                else:
                    w_boss = self._new_world_boss(res_blid)
                l_sec = start_sec - now_sec
                #log.debug('world---boss----l_sec %s', l_sec)
                min_sec = w_boss.handle_start_time(l_sec, min_sec)
            #log.debug('shengyu boss start--------- %s', min_sec)
            #还有多久通知min_sec
            if min_sec <= 0:
                min_sec = self.fetch_notice_start
            #log.debug('world---sleep %s', min_sec)
            sleep(min_sec)

    @property
    def fetch_aboss_level(self):
        """ 获取同盟战开启的同盟等级 """
        return Game.setting_mgr.setdefault(BOSS_ALLY_LEVEL, BOSS_ALLY_LEVEL_V)

    @wrap_world_data
    def world_boss_enter(self, pid, boss=None):
        """ 进入世界boss战的场景 """
        return boss.enter(pid)

    @wrap_world_data
    def is_start_world_boss(self, pid, boss=None):
        """ 世界boss战是否开启 """
        return True, None

    @wrap_ally_data
    def ally_boss_enter(self, pid, boss=None):
        """ 进入同盟boss战的场景 """
        return boss.enter(pid)

    @wrap_ally_data
    def is_start_ally_boss(self, pid, boss=None):
        """ 同盟boss战斗是否开始 """
        if not boss.is_start:
            return False, EC_BOSS_NOSTART
        return True, None

    @wrap_world_data
    def world_boss_exit(self, pid, boss=None):
        """ 退出世界boss战的场景 """
        return boss.exit(pid)

    @wrap_world_data
    def world_cd_time(self, pid, boss=None):
        return boss.cd_times(pid)

    @wrap_world_data
    def world_cd_coin2(self, pid, boss=None):
        """ 获取取消cd时间所要扣的元宝数 """
        return boss.cd_end_coin2(pid)

    @wrap_world_data
    def world_cd_clear(self, pid, boss=None):
        return boss.cd_end_clear(pid)

    @wrap_ally_data
    def ally_boss_exit(self, pid, boss=None):
        """ 退出同盟boss战的场景 """
        return boss.exit(pid)

    @wrap_world_data
    def world_boss_start(self, pid, boss=None):
        """ 单场世界boss战开始 """
        return boss.one_start(pid)

    @wrap_ally_data
    def ally_cd_coin2(self, pid, boss=None):
        """ 获取取消cd时间所要扣的元宝数 """
        return boss.cd_end_coin2(pid)

    @wrap_ally_data
    def ally_cd_clear(self, pid, boss=None):
        return boss.cd_end_clear(pid)

    @wrap_ally_data
    def ally_cd_time(self, pid, boss=None):
        """ 获取同盟bosscd时间 """
        return boss.cd_times(pid)

    @wrap_ally_data
    def ally_boss_start(self, pid, boss=None):
        """ 单场同盟boss战开始 """
        return boss.one_start(pid)

    @wrap_world_data
    def world_boss_finish(self, pid, name, hurt, check_data, boss=None):
        """ 单场世界boss战结束 """
        if not self._check(boss, check_data, hurt, pid):
            return False, EC_VALUE
        return boss.one_finish(pid, name, hurt)

    def _check(self, boss, check_data, hurt, pid):
        """ 伤害值检测 """
        p_level, join_nums, m_atk = check_data
        boss_def = boss.get_boss_def()
        hurt1 = m_atk * (1 - boss_def * math.sqrt(p_level*10)
            /(boss_def * p_level + p_level * p_level * 180))
        check_hurt = join_nums * 5 * hurt1 * 3
        if check_hurt < hurt:
            log.debug('world_boss_finish - pid %d check_hurt %s, hurt %s, check-data %s', pid, check_hurt, hurt, check_data)
            return False
        return True
    #玩家等级LV，玩家上阵人数r，玩家上阵人数中最大ATK，BOSS防御DEF
    #Hurt = ATK * ( 1 - DEF * SQRT( LV * 100 )/( DEF * LV + LV * LV * 180))
    #总伤害=r*5*hurt*3

    @wrap_world_data
    def boss_add_buff(self, pid, boss=None):
        """ 世界bos添加buff """
        return boss.add_buff(pid)

    @wrap_ally_data
    def ally_boss_finish(self, pid, name, hurt, boss=None):
        """ 本次同盟boss战结束 """
        return boss.one_finish(pid, name, hurt)

    @wrap_boss_data
    def ally_boss_set_time(self, aid, times, boss=None):
        """ 同盟设置boss开启时间 """
        sec = self.get_week_seconds(times)
        self.handle_week(boss)
        week_time = common.week_time(1, zero=1)
        if not boss.data.c and sec < time.time() - week_time:
            return False, EC_BOSS_NOTIME
        boss.data.ct = sec
        boss.save(Game.rpc_store, forced=True)
        return True, None

    def handle_week(self, boss):
        """ 处理超过一个星期开启boss """
        week_time = common.week_time(1, zero=1, delta=0)
        if week_time > boss.data.st:
            boss.data.st = int(time.time())
            boss.data.c = 0
            boss.save(Game.rpc_store, forced=True)
            return True
        return False

    @wrap_boss_data
    def ally_boss_get_time(self, aid, boss=None, is_enter=False, is_fight=False):
        """ 获取boss同盟开启时间 """
        status = 0
        #log.debug('is_enter is_fight %s  %s', is_enter, is_fight)
        #log.debug('boss.data.dc boss.data.c %s  %s', boss.is_start, boss.data.c)
        if is_enter and aid in self.notices:
            status = 1
        if is_fight and (boss.data.c or aid in self.notices):
            status = 1
        return True, (self.get_strweek_sec(boss.data.ct), status)

    def get_today_seconds(self):
        """ 获取当前时间离零点的秒数 """
        t = time.localtime()
        return t.tm_hour * HOUR_SEC + t.tm_min * MIN_SEC + t.tm_sec

    def get_week_seconds(self, times=None):
        """ 获取离上周末零点的秒数 """
        if times is not None:
            values = times.split(ALLY_BOSS_TIME)
            values = map(int, values)
            return values[0] * DAY_SEC + values[1] * HOUR_SEC + values[2] * MIN_SEC
        t = time.localtime()
        return (t.tm_wday+1) * DAY_SEC + t.tm_hour * HOUR_SEC + t.tm_min * MIN_SEC + t.tm_sec

    def get_strweek_sec(self, sec):
        """ 获取离上周末零点的秒数 """
        week = sec / DAY_SEC
        hour_sec = sec % DAY_SEC
        hour = hour_sec / HOUR_SEC
        min_sec = hour_sec % HOUR_SEC
        min = min_sec / MIN_SEC
        if not min:
            return '%d-%d-%d0' % (week, hour, min)
        return '%d-%d-%d' % (week, hour, min)

    @property
    def fetch_notice_start(self):
        """ 获取boss开启通知时间 """
        return Game.setting_mgr.setdefault(BOSS_NOTICE_START, BOSS_NOTICE_START_V)

    @property
    def fetch_start_time(self):
        v = Game.setting_mgr.setdefault(BOSS_START_TIME, BOSS_START_TIME_V)
        values = v.split('|')
        rs = {}
        for value in values:
            value = value.split(':')
            value = map(int, value)
            rs[value[0]] = value[1]
        return rs

class BossData(StoreObj):
    __slots__ = ('id', 'aid', 'resblid', 'blid', 'deads', 'st', 'ct', 'c')
    def init(self):
        self.id = None
        #同盟id(0=世界boss战，非零=同盟boss战)
        self.aid = 0
        #boss等级表id基础表(等级为一级)(resblid, int)
        self.resblid = 0
        #随着等级改变的boss等级表id基础表(blid, int)
        self.blid = 0
        #boss死亡次数(deads, int)
        self.deads = 0
        #同盟boss开启时间秒数(ct, time)
        self.ct = 0
        #本星期第一次开启的时间(st, time)
        self.st = 0
        #已开次数周期为周(c, int)
        self.c = 0

class Boss(GameObj):
    TABLE_NAME = TN_BOSS
    DATA_CLS = BossData
    def __init__(self, mgr, adict=None):
        super(Boss, self).__init__(adict=adict)
        self.boss_mgr = mgr

        self.data_task = None
        #boss是否开打(不包括通知的时间)
        self.is_start = False

        #是否完成第一次击杀怪物
        self.is_first = True

        #同盟id
        self.aid = 0
        #boss战开启时间
        self.boss_start = 0
        #boss剩余血量
        self.boss_hp = 0
        #boss总血量
        self.max_hp = 0
        #boss剩余存活时间
        self.boss_time = 0
        #进入场景的玩家id [pid1, pid2,...]
        self.enter_pids = []
        #玩家本次战斗结束时间{pid1:time1,... }
        self.finish_time = {}
        #参加boss战玩家pid:累加伤害值{pid1:hurt1...}
        self.pid_hurts = {}
        #参加boss战玩家pid:本次伤害值{pid1:hurt1...}
        self.pid_hurt = {}
        #记录前五名玩家id [pid1, pid2...]
        self.rank_pids = []
        #记录前五名玩家名
        self.rank_names = []
        #记录玩家积累的buff {pid:{atk:2,hp:2}...}
        self.pid_buff = {}

        #boss的防御力
        self.boss_def = 0


    @classmethod
    def new_by_dict(cls, mgr, adict):
        type = adict.get('aid')
        obj = cls.get_obj(type, mgr)
        obj.update(adict)
        return obj

    @classmethod
    def get_obj(cls, type, mgr):
        if type == AID_WORLD_BOSS:
            return WorldBoss(mgr)
        else:
            return AllyBoss(mgr)

    def p_logon(self, pids):
        """ 玩家登陆通知 """
        t = self.boss_start - int(time.time())
        self.notice(t, pids)

    def notice(self, times, pids=None):
        """ boss广播开启时间 """
        if self.aid:
            resp_f = 'allyBossNotice'
            if not pids:
                pids = Game.rpc_ally_mgr.member_pids_by_aid(self.data.aid)
        else:
            resp_f = 'bossNotice'
            pids = Game.rpc_player_mgr.get_pids_by_level(self.fetch_boss_uplevel, start_chapter=True)
        #log.debug('login _------notice ---- %s', resp_f)
        msg = pack_msg(resp_f, 1, data={'times': times})
        Game.rpc_player_mgr.player_send_msg(pids, msg)

    def p_logout(self, pid):
        """ 玩家登出通知 """
        if self.is_start and pid in self.enter_pids:
            self.enter_pids.remove(pid)

    def _init_boss(self, aid, l_sec, max_hp):
        """ 初始化boss数据 开启后的数据 """
        self.aid = aid
        #log.debug('l_sec----%s', l_sec)
        self.boss_start = int(time.time()) + l_sec
        self.boss_hp = max_hp
        self.max_hp = max_hp

    def cd_times(self, pid):
        """ 获取剩余cd时间 """
        now = int(time.time())
        finish_time = self.finish_time.get(pid)
        times, boss_type = self.get_cd_time(pid)
        if not finish_time: return 0, times
        ls_time = times - (now - finish_time)
        if ls_time > 0:
            return ls_time, times
        return 0, times

    def _get_max_hp(self):
        """ 获取boss的总血量 """
        res_boss_level = Game.res_mgr.boss_level.get(self.data.blid)
        key = (res_boss_level.mid, res_boss_level.level)
        max_hp = Game.res_mgr.boss_hp_by_keys.get(key)
        return int(max_hp)

    def enter(self, pid):
        """ 进入boss战的场景 """
        now = time.time()
        #if self.boss_start > now:
        #    return False, EC_BOSS_NOSTART
        self.enter_pids.append(pid)
        e_time = int(self.fetch_world_boss_times - (now - self.boss_start))
        send_data = {'hp':self.boss_hp, 'eTime':e_time, 'mhp':self.max_hp, 'blid':self.data.blid}
        rs, data = self._get_rank()
        #世界boss发送buff值
        if not self.aid:
            buff = self.pid_buff.get(pid)
            if buff:
                send_data.update({'buff':buff})
        if not rs:
            return True, send_data
        hurt = self.pid_hurts.setdefault(pid, 0)
        send_data.update(data)
        send_data.update({'hurt':hurt})
        return True, send_data

    def get_boss_def(self):
        """ 获取世界boss的防御力 """
        if not self.boss_def:
            res_boss_level = Game.res_mgr.boss_level.get(self.data.blid)
            keys = (res_boss_level.mid, res_boss_level.level)
            self.boss_def = Game.res_mgr.boss_def_by_keys.get(keys)
        return self.boss_def

    def exit(self, pid):
        """ 退出boss战场景 """
        if not self.is_start:
            return False, EC_BOSS_FINISH
        if pid in self.enter_pids:
            self.enter_pids.remove(pid)
        return True, None

    def cd_end_coin2(self, pid):
        """ 计算接触cd扣除的元宝数 """
        times, boss_type = self.get_cd_time(pid)
        if not times:
            return False, EC_BOSS_NO_CD
        if boss_type == WORLD_BOSS:
            res_per = self.fetch_bosscd_coin2
        else:
            res_per = self.fetch_allbosscd_coin2
        return True, res_per * times

    def cd_end_clear(self, pid):
        """ 元宝结束cd时间 """
        times, boss_type = self.get_cd_time(pid)

        if not times:
            return False, EC_BOSS_NO_CD
        self.pid_hurt[pid] = 0
        return True, None

    def one_start(self, pid):
        """ 单场boss战开始 计算cd时间 """
        log.debug('world-one_start-pid-%s boss_hp-%s', pid, self.boss_hp)
        now = time.time()
        if self.boss_start > now:
            return False, EC_BOSS_NOSTART
        times, boss_type = self.get_cd_time(pid)
        #首次boss击杀的广播(世界和同盟)
        if self.is_first and self.boss_hp:
            if not self.aid:
                self.handle_horn(HORN_TYPE_WORLDBOSSFIST, pid=pid)
            else:
                self.handle_horn(HORN_TYPE_ALLYBOSSFIST, pid=pid, aid=self.aid)
            self.is_first = False

        if not self.finish_time.has_key(pid):
            return True, None
        finish_time = self.finish_time[pid]
        if now - finish_time > times:
            return True, None
        return False, EC_BOSS_CD

    def handle_horn(self, type, pid=0, old_boss_hp=0, pname=None, aid=0):
        """ boss战广播处理(包括世界和同盟) """
        hord_rhp = 0
        if type == HORN_TYPE_WORLDBOSSHP or type == HORN_TYPE_ALLYBOSSHP:
            max_hp = float(self.max_hp)
            #boss剩余血量百分比.
            old_rhp = old_boss_hp / max_hp * 100
            new_rhp = self.boss_hp / max_hp * 100
            for cond in self.boss_mgr.get_horn_conds(aid):
                if new_rhp <= cond < old_rhp:
                    hord_rhp = cond
            if not hord_rhp:
                return
        if pid and not pname:
            pname = Game.rpc_player_mgr.get_name_by_id(pid)
        res_boss_level = Game.res_mgr.boss_level.get(self.data.resblid)
        res_monster = Game.res_mgr.monsters.get(res_boss_level.mid)
        if not res_monster:
            return
        Game.rpc_horn_mgr.horn_boss(type, pid, pname, res_monster.name, rhp=hord_rhp, aid=aid)

    def get_cd_time(self, pid):
        """ 获取cd时间 """
        hurts = self.pid_hurt.get(pid)
        if self.aid:
            boss_type = ALLY_BOSS
        else:
            boss_type = WORLD_BOSS
        if not hurts:
            times = 0
        else:
            times = self._get_cd_times(boss_type, hurts)
        if times:
            return times, boss_type
        return 0, boss_type

    def add_buff(self, pid):
        """ 添加buff """
        buff = self.pid_buff.get(pid)
        if buff and not self.is_maxbuff(buff):
            return False, EC_BOSS_MAXBUFF
        add_buff = self.fetch_add_buff
        if not buff:
            self.pid_buff[pid] = add_buff
            return True, add_buff
        return True, self.merge_buff(add_buff, buff)

    def merge_buff(self, add_buff, buff):
        """ 添加buff """
        for k,v in add_buff.iteritems():
            b = buff.setdefault(k, 0)
            buff[k] = b + v
        return buff

    def is_maxbuff(self, buff):
        """ 是否达到最大buff """
        max_buff = self.fetch_max_buff
        for k,v in buff.iteritems():
            max = max_buff.setdefault(k, 0)
            if max <= v:
                return False
        return True

    def one_finish(self, pid, name, hurt):
        """ 单场boss战结束 """
        if self.boss_hp <= 0:
            return False, EC_BOSS_FINISH
        now = int(time.time())
        #防范短时间内多次提交
        finish_time = self.finish_time.get(pid)
        if finish_time and now - finish_time < self.fetch_boss_safetimes:
            return False, EC_BOSS_CD
        max_hp = self._get_max_hp()
        rhurt = hurt / float(max_hp) * 100
        if rhurt >= 5:
            log.debug('world--boss---(pid, one_hurt) = (%d, %d)', pid, hurt)
        old_boss_hp = self.boss_hp
        self.finish_time[pid] = now
        self.pid_hurt[pid] = hurt
        if self.pid_hurts.has_key(pid):
            self.pid_hurts[pid] += hurt
        else:
            self.pid_hurts.setdefault(pid, hurt)
        #排名
        self._handle_rank(pid, name)
        rs, data = self._get_rank()
        #扣血要在排名数据后
        self.boss_hp -= hurt
        #boss剩余血量的广播
        if not self.aid:
            self.handle_horn(HORN_TYPE_WORLDBOSSHP, pid=pid, pname=name, old_boss_hp=old_boss_hp)
        else:
            self.handle_horn(HORN_TYPE_ALLYBOSSHP, pid=pid, pname=name, old_boss_hp=old_boss_hp, aid=self.aid)
        if self.boss_hp <= 0:
            self.boss_hp = 0
            #世界boss最后一击广播
            if not self.aid:
                self.handle_horn(HORN_TYPE_WORLDBOSSEND, pid=pid, pname=name)
            else:
                self.handle_horn(HORN_TYPE_ALLYBOSSEND, pid=pid, pname=name, aid=self.aid)
        if self.pid_hurts.has_key(pid):
            data.update({'hurt':self.pid_hurts[pid]})
        #Game.rpc_boss_mgr.world_boss_cdend(pid)
        return True, data

    def _get_rank(self):
        """ 获取排名 """
        rank_pids = self.rank_pids
        #无排名数据的返回
        if not rank_pids:
            return False, None
        hurts = []
        for rank_pid in rank_pids:
            hurts.append(self.pid_hurts[rank_pid])
        names = self.rank_names
        return True, {'names':names, 'hurts':hurts}

    def _handle_rank(self, pid, name):
        """ 处理排名 """
        hurts = self.pid_hurts[pid]
        if not self.rank_pids:
            self.rank_pids.append(pid)
            self.rank_names.append(name)
            return
        rank = -1
        if pid in self.rank_pids:
            rank = self.rank_pids.index(pid)
        now_rank_len = len(self.rank_pids)
        for index, rank_pid in enumerate(self.rank_pids[:]):
            if self.pid_hurts[rank_pid] > hurts:
                #处理排名还未加满的情况
                insert_index = index + 1
                if insert_index == now_rank_len and now_rank_len < RANK_MAX:
                    self._insert_rank(insert_index, pid, name)
                    return
                continue
            if rank == index:
                return
            if rank != -1:
                self.rank_pids.pop(rank)
                self.rank_names.pop(rank)
            self._insert_rank(index, pid, name)
            if len(self.rank_pids) > RANK_MAX:
                self.rank_pids = self.rank_pids[:RANK_MAX]
                self.rank_names = self.rank_names[:RANK_MAX]
            return

    def _insert_rank(self, index, pid, name):
        """ 加入排名 """
        self.rank_pids.insert(index, pid)
        self.rank_names.insert(index, name)

    def _get_cd_times(self, type, hurts):
        """ 通过boss类型和伤害获cd时间 """
        objs = Game.res_mgr.boss_cd_by_type.get(type)
        for o in objs:
            if o.h1 > hurts or o.h2 <= hurts:
                continue
            if isinstance(o.times, int):
                return int(o.times)
            else:
                return eval(o.times)

    def _get_reward(self, key, hurts, p_level, a_level=None):
        """ 获取奖励 """
        rid = Game.res_mgr.boss_reward_by_keys.get(key)
        #世界boss大于某等级后的奖励
        if not rid and key[0] == WORLD_BOSS:
            rid = Game.res_mgr.boss_reward_by_keys.get((WORLD_BOSS,0))
        rw = Game.reward_mgr.get(rid)
        rs_items = rw.reward(dict(level=p_level, hurt=hurts, allyLv=a_level))
        return rs_items

    def save_data(self, is_win):
        """ boss数据的保存 """
        #log.debug('boss--end--is_win %s', is_win)
        self.data.c += 1
        if not is_win:
            self.save(Game.rpc_store, forced=True)
            #挑战世界boss失败广播
            if not self.data.aid:
                self.handle_horn(HORN_TYPE_WORLDBOSSFAIL)
            else:
                self.handle_horn(HORN_TYPE_ALLYBOSSFAIL, aid=self.aid)
            return
        self.data.deads += 1
        res_boss_level = Game.res_mgr.boss_level.get(self.data.blid)
        key = (res_boss_level.mid, res_boss_level.level+1)
        res_boss_level_up = Game.res_mgr.boss_level_by_midlevel.get(key)
        log.debug('kill-time %s',common.current_time() - self.boss_start)
        if common.current_time() - self.boss_start < self.fetch_bosskill_time or\
           self.data.deads >= res_boss_level_up.deads:
            self.data.blid = res_boss_level_up.id
            self.data.deads = 0
        self.save(Game.rpc_store, forced=True)

    def _clear_data(self):
        """ 清楚数据 """
        show_num = 5
        rank_num = len(self.rank_pids)
        if rank_num < show_num:
            show_num = rank_num
        for index in xrange(show_num):
            pid = self.rank_pids[index]
            log.debug('rs ---- pid %d , rank %d, hurts %d', pid, index+1, self.pid_hurts[pid])
        self.is_start = False
        self.data_task = None
        self.is_first = True
        self.enter_pids = []
        self.finish_time = {}
        self.pid_hurts = {}
        self.pid_hurt = {}
        self.rank_pids = []
        self.rank_names = []
        self.pid_buff = {}

    @property
    def fetch_boss_safetimes(self):
        """ boss防范短时间内多次提交 """
        return Game.setting_mgr.setdefault(BOSS_SAFE_TIME, BOSS_SAFE_TIME_V)

    @property
    def fetch_boss_uplevel(self):
        """ 获取boss解锁等级 """
        return Game.setting_mgr.setdefault(BOSS_ENTER_LEVEL, BOSS_ENTER_LEVEL_V)

    @property
    def fetch_add_buff(self):
        """ 获取没此添加的buff值 """
        buff_str = Game.setting_mgr.setdefault(BOSS_ADD_BUFF, BOSS_ADD_BUFF_V)
        return common.str2dict(buff_str)

    @property
    def fetch_max_buff(self):
        """ buff上线 """
        buff_str = Game.setting_mgr.setdefault(BOSS_MAX_BUFF, BOSS_MAX_BUFF_V)
        return common.str2dict(buff_str)

    @property
    def fetch_bosscd_coin2(self):
        """ 世界boss获取cd每秒钟消耗的元宝数 """
        return Game.setting_mgr.setdefault(BOSS_CD_COIN2, BOSS_CD_COIN2_V)

    @property
    def fetch_allbosscd_coin2(self):
        """ 同盟boss获取cd每秒钟消耗的元宝数 """
        return Game.setting_mgr.setdefault(BOSS_ALLYCD_COIN2, BOSS_ALLYCD_COIN2_V)

    @property
    def fetch_hp_time(self):
        """ 每隔多长时间通知当前剩余血量 """
        return Game.setting_mgr.setdefault(BOSS_HP_TIME, BOSS_HP_TIME_V)

    @property
    def fetch_rank_time(self):
        """ 每隔多长时间排行榜通知 """
        return Game.setting_mgr.setdefault(BOSS_RANK_TIME, BOSS_RANK_TIME_V)

    @property
    def fetch_notice_start(self):
        """ 获取boss开启通知时间 """
        return Game.setting_mgr.setdefault(BOSS_NOTICE_START, BOSS_NOTICE_START_V)

    @property
    def fetch_world_boss_times(self):
        return Game.setting_mgr.setdefault(BOSS_TIME, BOSS_TIME_V)

    @property
    def fetch_bosskill_time(self):
        return Game.setting_mgr.setdefault(BOSS_KILL_TIME, BOSS_KILL_TIME_V)

class AllyBoss(Boss):
    """ 同盟boss """
    def __init__(self, mgr):
        super(AllyBoss, self).__init__(mgr)
        self.gm_stoped = False

    def handle_start_time(self, now_sec, min_sec):
        """ 根据时间判断是否开启 """
        #log.debug('now_sec, test, %s %s',now_sec, test)
        l_sec = self.data.ct - now_sec
        #log.debug('ally---boss----l_sec %s', l_sec)
        if l_sec <= 0:
            return min_sec
        if l_sec <= self.fetch_notice_start:
            self.start(l_sec)
        else:
            seconds = l_sec - self.fetch_notice_start
            if not min_sec or seconds < min_sec:
                min_sec = seconds
        return min_sec

    def start(self, l_sec):
        """ 开启同盟boss战并初始化数据 """
        max_hp = self._get_max_hp()
        self._init_boss(self.data.aid, l_sec, max_hp)
        #log.debug('notices------%s', self.data.aid)
        self.boss_mgr.notices.append(self.data.aid)
        #广播boss战斗开始通知
        self.handle_horn(HORN_TYPE_ALLYNOTICE, aid=self.data.aid)
        #广播通知即将开始
        self.notice(l_sec)
        #开启等待数据的广播
        self.loop_task = spawn(self._notice_data, l_sec)

    def new(self, level):
        """ 创建同盟boss数据 """
        need_level = self.boss_mgr.fetch_aboss_level
        if level != need_level:
            return
        start_time = self.fetch_ally_boss_start
        key = (ALLY_BOSS, 51)
        #log.debug('key---[%s]', key)
        res_boss_level = Game.res_mgr.boss_level_by_keys.get(key)
        if not res_boss_level:
            return
        self.data.resblid = res_boss_level.id
        self.data.blid = res_boss_level.id
        self.data.ct = start_time
        self.data.st = int(time.time())
        self.save(Game.rpc_store, forced=True)

    def _notice_data(self, l_sec, stop=False):
        """ 同盟广播数据 包括boss剩余血量和排名 """
        #log.debug('_a_data %s', l_sec)
        hp_resp_f = 'allyBossHp'
        rank_resp_f = 'allyBossRank'
        hp_time = self.fetch_hp_time
        c = self.fetch_rank_time / hp_time
        sleep(l_sec)
        tmp = 0
        self.is_start = is_win = True
        while not stop and not self.gm_stoped:
            sleep(hp_time)
            msg = pack_msg(hp_resp_f, 1, data={'hp':self.boss_hp})
            Game.rpc_player_mgr.player_send_msg(self.enter_pids, msg)
            if self.boss_hp <= 0:
                break
            if self.boss_start + self.fetch_ally_boss_times < time.time():
                is_win = False
                break
            tmp += 1
            if tmp != c:
                continue
            tmp = 0
            rs, data = self._get_rank()
            if not rs:
                continue
            msg = pack_msg(rank_resp_f, 1, data=data)
            Game.rpc_player_mgr.player_send_msg(self.enter_pids, msg)
        #log.debug('ally_isWin %s', is_win)
        if self.data.aid in self.boss_mgr.notices:
            self.boss_mgr.notices.remove(self.data.aid)
        if self.gm_stoped:
            is_win = False
        if is_win:
            try:
                #发放奖励
                self._reward()
            except:
                log.log_except()
        #清楚数据
        self._clear_data()
        #记录数据
        self.save_data(is_win)
        if self.boss_mgr.gm_aboss:
            self.boss_mgr.gm_aboss = 0
            self.gm_stoped = False

    def _reward(self):
        """ 同盟boss战发放奖励并 """
        a_level = Game.rpc_ally_mgr.ally_level_by_aid(self.data.aid)
        pid_levels = PlayerData.get_players_levels(self.pid_hurts.keys())
        for rank, pid in enumerate(self.rank_pids):
            key = (ALLY_BOSS, a_level, rank+1)
            hurt = self.pid_hurts.get(pid)
            rs_items = self._get_reward(key, hurt, pid_levels[pid], a_level)
            #邮件通知玩家
            Game.mail_mgr.send_mails(pid, MAIL_REWARD,
                language.ALLY_BOSS_REWARD, RW_MAIL_ABOSS, rs_items)
        for pid, hurt in self.pid_hurts.iteritems():
            if pid in self.rank_pids:
                continue
            key = (ALLY_BOSS, a_level)
            rs_items = self._get_reward(key, hurt, pid_levels[pid], a_level)
            #邮件通知玩家
            Game.mail_mgr.send_mails(pid, MAIL_REWARD,
                language.ALLY_BOSS_REWARD, RW_MAIL_ABOSS, rs_items)

    def get_week_seconds(self, times=None):
        """ 获取离上周末零点的秒数 """
        if times is not None:
            values = times.split(ALLY_BOSS_TIME)
            values = map(int, values)
            return values[0] * DAY_SEC + values[1] * HOUR_SEC + values[2] * MIN_SEC
        t = time.localtime()
        return t.tm_wday * DAY_SEC + t.tm_hour * HOUR_SEC + t.tm_min * MIN_SEC + t.tm_sec

    def get_strweek_sec(self, sec):
        """ 获取离上周末零点的秒数 """
        week = sec / DAY_SEC
        hour_sec = sec % DAY_SEC
        hour = hour_sec / HOUR_SEC
        min_sec = hour_sec % HOUR_SEC
        min = min_sec / MIN_SEC
        return '%d-%d-%d' % (week, hour, min)

    @property
    def fetch_ally_boss_start(self):
        time_str = Game.setting_mgr.setdefault(BOSS_ALLY_START, BOSS_ALLY_START_V)
        sec = self.get_week_seconds(time_str)
        return sec

    @property
    def fetch_ally_boss_times(self):
        return Game.setting_mgr.setdefault(BOSS_ALLY_TIME, BOSS_ALLY_TIME_V)

class WorldBoss(Boss):
    """ 世界boss """
    def __init__(self, mgr):
        super(WorldBoss, self).__init__(mgr)
        self.gm_stoped = False

    def handle_start_time(self, l_sec, min_sec):
        """ 根据时间判断是否开启 """
        if l_sec <= 0:
            return min_sec
        if l_sec <= self.fetch_notice_start:
            self.start(l_sec)
        else:
            seconds = l_sec - self.fetch_notice_start
            if not min_sec or seconds < min_sec:
                min_sec = seconds
        return min_sec

    def start(self, l_sec):
        """ 开启boss战并初始化数据 """
        max_hp = self._get_max_hp()
        self._init_boss(AID_WORLD_BOSS, l_sec, max_hp)
        self.boss_mgr.w_start_boss = self
        #log.debug('start--------')
        #大喇叭广播boss战斗开始通知
        self.handle_horn(HORN_TYPE_WORLDNOTICE)
        #广播通知即将开始
        self.notice(l_sec)
        #开启等待数据的广播
        self.loop_task = spawn(self._notice_data, l_sec)

    def new(self, res_blid):
        """ 创建boss数据 """
        self.data.resblid = res_blid
        self.data.blid = res_blid
        self.data.st = int(time.time())
        #self.data.ct = self.boss_mgr.get_week_seconds(self.boss_mgr.fetch_ally_boss_start)
        self.save(Game.rpc_store, forced=True)

    def _notice_data(self, l_sec):
        """ 广播数据 包括世界boss剩余血量和排名 """
        #log.debug('(%s)WorldBoss_notice_data %s', self.data.blid, l_sec)
        hp_resp_f = 'bossHp'
        rank_resp_f = 'bossRank'
        hp_time = self.fetch_hp_time
        c = self.fetch_rank_time / hp_time
        sleep(l_sec)
        tmp = 0
        self.is_start = is_win =True
        while not self.gm_stoped:
            sleep(hp_time)
            msg = pack_msg(hp_resp_f, 1, data={'hp':self.boss_hp, 'mhp':self.max_hp})
            Game.rpc_player_mgr.player_send_msg(self.enter_pids, msg)
            #log.debug('world hp enter_pids %s %s', self.boss_hp, self.enter_pids)
            if self.boss_hp <= 0:
                break
            if self.boss_start + self.fetch_world_boss_times < time.time():
                is_win = False
                break
            tmp += 1
            if tmp != c:
                continue
            tmp = 0
            rs, data = self._get_rank()
            #log.debug('world_rank %s', data)
            if not rs:
                continue
            msg = pack_msg(rank_resp_f, 1, data=data)
            Game.rpc_player_mgr.player_send_msg(self.enter_pids, msg)
        self.boss_mgr.w_start_boss = None
        log.debug('is_win------- %s, gm %s, join-player %s', is_win, self.gm_stoped, len(self.pid_hurts))
        if self.gm_stoped:
            is_win = False
        #if is_win:
        #更改为不管怪物是否死都发奖励
        try:
            #发放奖励
            self._reward()
            #vip不参加也发奖励
            self._reward_vip()
        except:
            log.log_except()
        #写入log 记录伤害
        self._log_info()
        #清楚数据
        self._clear_data()
        #记录数据
        self.save_data(is_win)
        if self.boss_mgr.gm_wboss:
            self.boss_mgr.gm_wboss = False
            self.boss_mgr.gm_start = False
            self.gm_stoped = False
    
    def _log_info(self):
        """ 记录玩家在该场boss中的伤害值 """
        for pid, hurts in self.pid_hurts.iteritems():
            Game.glog.log(dict(p=pid, t=PL_WORLD_BOSS, d=dict(hurts=hurts)))

    def _reward_vip(self):
        """ 达到vip等级后不参与世界boss发奖励 """
        vip = self.fetch_reward_vip
        querys = dict(vip={"$gte":vip}, level={"$gte":self.fetch_boss_uplevel}, chapter={"$gt":CHATER_START})
        players = Game.rpc_store.query_loads(TN_PLAYER, querys)
        #获取奖励
        rid = Game.res_mgr.boss_reward_by_keys.get((WORLD_BOSS,0))
        rw = Game.reward_mgr.get(rid)
        join_boss_pids = self.pid_hurts.keys()

        for player in players:
            pid = player['id']
            if pid in join_boss_pids:
                continue
            mail_querys = dict(pid=pid, t=MAIL_REWARD, content=str(RW_MAIL_BOSSVIP))
            mails = Game.rpc_store.query_loads(TN_P_MAIL, mail_querys)
            if len(mails):
                continue
            items = rw.reward(dict(level=player['level'], hurt=0))
            rs_items = []
            for item in items:
                if not item[IT_CAR_STR]:
                    continue
                rs_items.append(item)
            #发送邮件
            res_rw_mail = Game.res_mgr.reward_mails.get(RW_MAIL_BOSSVIP)
            content = res_rw_mail.content % dict(rank=0)
            Game.mail_mgr.send_mails(pid, MAIL_REWARD,
                res_rw_mail.title, RW_MAIL_BOSSVIP, rs_items, param=content)

    def _reward(self):
        """ 世界boss战发放奖励并 """
        rank_data = sorted(self.pid_hurts.iteritems(), key=lambda x:x[1], reverse=True)
        #活动奖励广播
        self.boss_mgr.safe_pub(MSG_REWARD_WORLDBOSS, rank_data, self.max_hp)
        pid_levels = PlayerData.get_players_levels(self.pid_hurts.keys())
        res_rw_mail = Game.res_mgr.reward_mails.get(RW_MAIL_BOSS)
        p_ranks = {}
        for index, (pid, hurts) in enumerate(rank_data):
            rank = index + 1
            key = (WORLD_BOSS, rank)
            rs_items = self._get_reward(key, hurts, pid_levels[pid])
            #邮件通知玩家
            content = res_rw_mail.content % dict(rank=rank)
            Game.mail_mgr.send_mails(pid, MAIL_REWARD,
                res_rw_mail.title, RW_MAIL_BOSS, rs_items, param=content)
            self.boss_mgr.safe_pub(MSG_REWARD_WORLDITEMS, pid, rs_items)
            p_ranks[str(pid)] = (rank, hurts)
        self.boss_mgr.safe_pub(MSG_WBOSS_RANK, p_ranks)

    def get_today_seconds(self):
        """ 获取当前时间离零点的秒数 """
        t = time.localtime()
        return t.tm_hour * HOUR_SEC + t.tm_min * MIN_SEC + t.tm_sec

    @property
    def fetch_world_boss_times(self):
        return Game.setting_mgr.setdefault(BOSS_TIME, BOSS_TIME_V)

    @property
    def fetch_start_time(self):
        v = Game.setting_mgr.setdefault(BOSS_START_TIME, BOSS_START_TIME_V)
        values = v.split('|')
        rs = {}
        for value in values:
            value = value.split(':')
            value = map(int, value)
            rs[value[0]] = value[1]
        return rs

    @property
    def fetch_reward_vip(self):
        return Game.setting_mgr.setdefault(BOSS_REWARD_VIP, BOSS_REWARD_VIP_V)



def new_boss_mgr():
    mgr = BossMgr()
    return mgr