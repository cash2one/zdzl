#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time, bisect

from corelib import log
from store.store import StoreObj, GameObj

from game import Game, pack_msg
from game.base import common
from game.store import TN_BOSS
from game.base.errcode import (EC_BOSS_NOSTART, EC_BOSS_CD,
                               EC_BOSS_FINISH, EC_BOSS_NO_CD,
                               EC_BOSS_MAXBUFF, )
from game.base.constant import (
    BOSS_HP_TIME, BOSS_HP_TIME_V, BOSS_RANK_TIME, BOSS_RANK_TIME_V,
    BOSS_CD_COIN2, BOSS_CD_COIN2_V, BOSS_ALLYCD_COIN2, BOSS_ALLYCD_COIN2_V,
    HORN_TYPE_WORLDBOSSHP, HORN_TYPE_WORLDBOSSFIST, HORN_TYPE_WORLDBOSSEND,
    HORN_TYPE_WORLDBOSSFAIL,  BOSS_ENTER_LEVEL,
    BOSS_ENTER_LEVEL_V, HORN_TYPE_ALLYBOSSHP, HORN_TYPE_ALLYBOSSFIST,
    HORN_TYPE_ALLYBOSSFAIL, HORN_TYPE_ALLYBOSSEND,
    BOSS_ADD_BUFF, BOSS_ADD_BUFF_V, BOSS_TIME, BOSS_TIME_V,
    BOSS_MAX_BUFF, BOSS_MAX_BUFF_V, BOSS_KILL_TIME,
    BOSS_SAFE_TIME, BOSS_SAFE_TIME_V, BOSS_KILL_TIME_V
    )

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
        self.init()

    def init(self):
        self.data_task = None
        self.loop_task = None
        #停止
        self.stoped = False
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
        #记录前五名的伤害值 (已排序由小到大)
        self.rank_hurts = []
        #记录玩家积累的buff {pid:{atk:2,hp:2}...}
        self.pid_buff = {}

        #boss的防御力
        self.boss_def = 0

    def stop(self, type):
        """ 停止boss战斗 """
        data = {'hp':0}
        if type == WORLD_BOSS:
            resp_f = 'bossHp'
            data['mhp'] = self.max_hp
            self.boss_mgr.world_boss_clear()
        else:
            resp_f = 'allyBossHp'
            self.boss_mgr.ally_boss_clear(self.data.aid)
        self.send_msg(resp_f, data)
        self.stoped = True
        if self.loop_task is not None:
            self.loop_task.kill(block=0)
        self.init()
        
    def send_msg(self, resp_f, data, pids=None):
        """ 主动发给客户端的数据 """
        msg = pack_msg(resp_f, 1, data=data)
        if not pids:
            pids = self.enter_pids
        Game.rpc_player_mgr.player_send_msg(pids, msg)

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
        self.send_msg(resp_f, {'times':times}, pids)

    def p_logout(self, pid):
        """ 玩家登出通知 """
        if self.is_start and pid in self.enter_pids:
            self.enter_pids.remove(pid)

    def _init_boss(self, aid, l_sec, max_hp):
        """ 初始化boss数据 开启后的数据 """
        self.aid = aid
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

    def one_finish(self, pid, name, hurt, is_cd=True):
        """ 单场boss战结束 """
        if self.boss_hp <= 0:
            return False, EC_BOSS_FINISH
        now = int(time.time())
        #防范短时间内多次提交
        finish_time = self.finish_time.get(pid)
        if is_cd and finish_time and now - finish_time < self.fetch_boss_safetimes:
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
        self._horn_hp(pid, name, old_boss_hp)
        if self.pid_hurts.has_key(pid):
            data.update({'hurt':self.pid_hurts[pid]})
        return True, data

    def _horn_hp(self, pid, name, old_boss_hp):
        """ boss剩余血量广播 """
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
        return True, dict(names=names, hurts=hurts)

    def _handle_rank(self, pid, name):
        """ 处理排名 """
        if pid in self.rank_pids:
            pop_index = self.rank_pids.index(pid)
            hurts_pop = len(self.rank_hurts) - pop_index - 1
            self._pop_data(pop_index, hurts_pop)
        rank_num = len(self.rank_hurts)
        hurts = self.pid_hurts[pid]
        rank_hurts_index = bisect.bisect_left(self.rank_hurts, hurts)
        insert_index = rank_num - rank_hurts_index
        if  rank_num < RANK_MAX or rank_hurts_index:
            self.rank_pids.insert(insert_index, pid)
            self.rank_names.insert(insert_index, name)
            self.rank_hurts.insert(rank_hurts_index, hurts)
        if len(self.rank_pids) > RANK_MAX:
            self._pop_data(-1, 0)

    def _pop_data(self, index1, index2):
        """ 去除排名列表数据 """
        self.rank_pids.pop(index1)
        self.rank_names.pop(index1)
        self.rank_hurts.pop(index2)

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

    def fail_horn(self):
        """ 失败广播 """
        #挑战boss失败广播
        aid = self.data.aid
        if not aid:
            self.handle_horn(HORN_TYPE_WORLDBOSSFAIL)
        else:
            self.handle_horn(HORN_TYPE_ALLYBOSSFAIL, aid=aid)

    def save_data(self, is_win):
        """ boss数据的保存 """
        #log.debug('boss--end--is_win %s', is_win)
        self.data.c += 1
        if not is_win:
            self.save(Game.rpc_store, forced=True)
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
        self.init()

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
    def fetch_world_boss_times(self):
        return Game.setting_mgr.setdefault(BOSS_TIME, BOSS_TIME_V)

    @property
    def fetch_bosskill_time(self):
        return Game.setting_mgr.setdefault(BOSS_KILL_TIME, BOSS_KILL_TIME_V)


