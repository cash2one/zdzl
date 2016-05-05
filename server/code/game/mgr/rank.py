#!/usr/bin/evn python
#coding=utf-8

import bisect

from game.base import errcode, common
from game import Game
from game.base.constant import (
    IPI_IDX_CBE, IPI_IDX_NAME, IPI_IDX_RID, IPI_IDX_LEVEL, STATUS_RANK,
    STATUS_RANK_FT, STATUS_RANK_DEEP, STATUS_RANK_BOSS,
    )
from game.base.msg_define import MSG_START, MSG_DEEP_FLOOR, MSG_WBOSS_RANK
from game.store import TN_PLAYER, TN_P_ATTR, TN_RES_ROLE
from corelib.memory_cache import TimeMemCache
from corelib import log, spawn, sleep

#排行榜类型
RANK_LEVEL      = 1   #等级
RANK_CBE        = 2   #战斗力
RANK_ARENA      = 3   #竞技场
RANK_DEEP       = 4   #深渊
RANK_BOSS       = 5   #世界boss
RANK_ALLY       = 6   #同盟

CONST_NONE      = ''
CONST_ROLE      = 'res_role'
CONST_ID        = 'id'
CONST_NAME      = 'name'
CONST_ANAME     = 'aname'  #盟主名
CONST_RID       = 'rid'
CONST_LEVEL     = 'level'
CONST_DEEPFLOOR = 'deep'
CONST_BOSSHURTS = 'boss'
CONST_EXP       = 'exp'
CONST_PID       = 'pid'
CONST_OFFICE    = 'office'
CONST_CBE       = 'CBE'
CONST_IN        = '$in'
CONST_LT        = '$lt'
CONST_GT        = '$gt'
CONST_GTE       = '$gte'
CONST_R         = 'r'
CONST_N         = 'n'
CONST_L         = 'l'
CONST_O         = 'o'
CONST_RET       = 'ret'
CONST_NEXT      = 'next'
CONST_MINE      = 'mine'
CONST_VALUE     = 'value'
CONST_LIMIT     = 10
CONST_NEXT_YES  = 1
CONST_NEXT_NO   = 0
CONST_CBE_BASE  = 100

CONST_LAST_SKIP = 90

CONST_MAP_REDUCE_OUT        = 'map_reduce_level'

CONST_RPC_STORE             = 'rpc_store'
CONST_RPC_RES_STORE         = 'rpc_res_store'

ASCENDING                   = 1
DESCENDING                  = -1

PAGE_NUMS                   = 10
TIMES_NUMS                  = 100

INDEX_DATA_RET = 0
INDEX_DATA_PRETS = 1
INDEX_DATA_RANKS = 2

RESET_LOAD_TIME = 600
MAX_ARENA_RANK = 100

ONE_DAY_SECONDS = 86400

def deep_enter(pid, floor):
    """ 深渊该日进入最高层时广播处理 """
    spawn(Game.rpc_rank_mgr.handle_deep_enter, pid, floor)

def boss_rank(rank_data, p_rank):
    """ 世界boss """
    spawn(Game.rpc_rank_mgr.handle_boss_rank, rank_data, p_rank)


class RankMgr(object):
    """ 排行榜管理器 """
    _rpc_name_ = 'rpc_rank_mgr'
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        self.cache = TimeMemCache(default_timeout=600, name='rank_mgr.cache')
        #[[ret1,ret2...],{pid:ret索引}，{con:rank}]
        self.player_level_data = None
        self.player_cbe_data = None

        #当天第一次的排名时间
        self.first_time = None

        #深渊排名数据的保存
        #{层数:[pid1,pid2]...} 此数据保存数据库
        self.deep_floor_pids = {}
        #{pid1:层数,...}
        self.deep_pid_floor = {}

        #世界boss排名
        #[{排名:1, 名字:xx, 等级:22, 总伤害血量}...}
        self.boss_rank_datas = []
        #{pid1:(rank1, hurts),...} 此数据由世界boss广播而来 保存数据库
        self.boss_pid_data = {}

        #是否将当天排名数据保存到log_rank(当前只有深渊是每天零点更新)
        self.is_save_rank = False

        import app
        app.sub(MSG_START, self.start)

    def start(self):
        """ 开启 """
        self.load()
        spawn(self.loop)
        #保存前十
        spawn(self.rank_save)
        Game.rpc_horn_mgr.rpc_sub(deep_enter, MSG_DEEP_FLOOR, _proxy=True)
        Game.rpc_boss_mgr.rpc_sub(boss_rank, MSG_WBOSS_RANK, _proxy=True)

    def save(self):
        """ 保存数据 """
        deep_datas = self._change_data_type(self.deep_floor_pids, str)
        boss_datas = self._change_data_type(self.boss_pid_data, str)
        data = {STATUS_RANK_FT:self.first_time,
                STATUS_RANK_DEEP:deep_datas,
                STATUS_RANK_BOSS:boss_datas}
        Game.rpc_status_mgr.set(STATUS_RANK, data)

    def rank_save(self):
        """ 每天凌晨保存各排行榜前十名的数据 """
        now = common.current_time()
        #今日零晨
        zero_time = common.cur_day_hour_time(hour=24)
        sleep_time = zero_time - now
        log.debug('rank---save----sleep = %d', sleep_time)
        sleep(sleep_time)
        while 1:
            #保存排名
            log.debug('rank_save----')
            p_data = {'id':1, 'level':1, 'CBE':1}
            for type in range(1, 6):
                rs, data = self.enter(p_data, type, 1)
                if not rs:
                    continue
                rank_data = data[CONST_RET]
                Game.rpc_logger_svr.log_rank(dict(t=type, d=rank_data))
            self.is_save_rank = True
            sleep(ONE_DAY_SECONDS)

    def _change_data_type(self, data, ktype):
        """ 改变数据的类型 """
        rs_datas = {}
        for key, value in data.iteritems():
            rs_datas[ktype(key)] = value
        return rs_datas

    def load(self):
        """ 获取数据 """
        data = Game.rpc_status_mgr.get(STATUS_RANK)
        if data:
            #深渊
            self.first_time = data.get(STATUS_RANK_FT)
            self._load_deep_data(data.get(STATUS_RANK_DEEP))
            #世界boss
            boss_data = data.get(STATUS_RANK_BOSS)
            boss_data = self._change_data_type(boss_data, int)
            self.handle_boss_rank(boss_data, None)
        else:
            self.first_time = common.current_time()

    def _load_deep_data(self, deep_data):
        """ 处理深渊数据库中的排名数据 """
        if not deep_data:
            return
        if self.deep_pass_day():
            return
        self.deep_floor_pids = self._change_data_type(deep_data, int)
        for floor, pids in self.deep_floor_pids.iteritems():
            for pid in pids:
                self.deep_pid_floor[pid] = floor

    def loop(self):
        """ 定时获取排名数据 """
        level_rank = RankData()
        cbe_rank = RankData()
        while 1:
            level_rank.init()
            cbe_rank.init()
            spawn(self.loop_data, level_rank, cbe_rank)
            spawn(self.save)
            sleep(RESET_LOAD_TIME)

    def loop_data(self, level_rank, cbe_rank):
        """ 获取数据 """
        log.debug("rank--load--rank--start")
        self.loop_data_level(level_rank)
        self.loop_data_cbe(cbe_rank)
        log.debug("rank--load--rank--ok")

    def loop_data_level(self, level_rank):
        """ 等级排名数据载入 """
        while 1:
            #查询player表需要的字段
            player_fields = [CONST_ID, CONST_NAME, CONST_LEVEL, CONST_EXP, CONST_RID]
            #查询player表的排序
            player_sort_by = [(CONST_LEVEL, DESCENDING),(CONST_EXP, DESCENDING)]
            #初始化查询排名类
            player_list = level_rank.query(TN_PLAYER, player_fields, limit=TIMES_NUMS,
                sort_by=player_sort_by, rpc=CONST_RPC_STORE)
            #查询相对应的角色
            role_field = [CONST_ID, CONST_OFFICE]
            level_rank.queryByList(player_list, CONST_RID, TN_RES_ROLE, role_field, rpc=CONST_RPC_RES_STORE)
            del_key_list = [CONST_EXP]
            level_rank.getRet(player_list, CONST_RID, del_key_list,
                change_id=CONST_PID, type=RANK_LEVEL)
            sleep(0.1)
            if not level_rank.is_next:
                self.player_level_data = level_rank.data
                log.debug('rank--load-data-level')
                break

    def loop_data_cbe(self, cbe_rank):
        """ 战斗力排名数据载入 """
        while 1:
            cbe_fields = [CONST_PID, CONST_CBE]
            cbe_sort_by = [(CONST_CBE, DESCENDING)]
            cbe_list = cbe_rank.query(TN_P_ATTR, cbe_fields, limit=TIMES_NUMS,
                sort_by=cbe_sort_by, rpc=CONST_RPC_STORE)
            player_fields = [CONST_NAME, CONST_LEVEL, CONST_RID]
            cbe_rank.queryByList(cbe_list, CONST_PID, TN_PLAYER, player_fields,
                rpc=CONST_RPC_STORE)
            del_key_list = [CONST_ID]
            cbe_rank.getRet(cbe_list, CONST_PID, del_key_list, type=RANK_CBE)
            sleep(0.1)
            if not cbe_rank.is_next:
                self.player_cbe_data = cbe_rank.data
                log.debug("rank--load--data--cbe")
                break

    def deep_pass_day(self):
        """ 深渊数据根据每日凌晨清楚 """
        if self.is_save_rank and common.is_pass_day(self.first_time):
            self.first_time = common.current_time()
            self.deep_floor_pids.clear()
            self.deep_pid_floor.clear()
            self.is_save_rank = False
            return True
        return False

    def handle_deep_enter(self, pid, floor):
        """ 深渊进入最高的层的事件的监听 """
        self.deep_pass_day()
        old_floor = self.deep_pid_floor.get(pid)
        if old_floor is not None and old_floor > floor:
            return
        self.deep_pid_floor[pid] = floor
        old_floor_pids = self.deep_floor_pids.get(old_floor)
        if old_floor_pids and pid in old_floor_pids:
            old_floor_pids.remove(pid)
        new_floor_pids = self.deep_floor_pids.get(floor)
        if new_floor_pids is None:
            self.deep_floor_pids[floor] = [pid]
        else:
            new_floor_pids.append(pid)

    def handle_boss_rank(self, rank_data, p_ranks):
        """ 世界boss完成处理更改当前世界boss的排名 """
        if not rank_data:
            return
        if p_ranks is None:
            p_ranks = [0] * len(rank_data)
            for pid, (rank, hurts) in rank_data.iteritems():
                p_ranks[rank-1] = pid
        if p_ranks is None:
            return
        self.boss_pid_data = rank_data
        self.boss_rank_datas = []
        _, p_infos = Game.rpc_player_mgr.get_player_infos(p_ranks)
        for pid in p_ranks:
            data = p_infos.get(pid)
            if data is None:
                continue
            pname, rid, plevel = data
            rs = rank_data.get(pid)
            if rs is None:
                continue
            rank, hurts = rank_data.get(pid)
            d = {CONST_R:rank, CONST_NAME:pname,
                 CONST_LEVEL:plevel, CONST_BOSSHURTS:hurts,
                 CONST_RID:rid}
            self.boss_rank_datas.append(d)

    def enter(self, p_data, t, p):
        """ 进入排行榜 """
        #等级排名
        if t == RANK_LEVEL:
            return RankLevel.rank(self, p_data, p)
        #战斗力排名
        if t == RANK_CBE:
            return RankCBE.rank(self, p_data, p)
        #竞技场排名
        if t == RANK_ARENA:
            return RankArena.rank(self, p_data, p)
        #深渊排名
        if t == RANK_DEEP:
            return RankDeep.rank(self, p_data, p)
        #世界boss排名
        if t == RANK_BOSS:
            return RankBoss.rank(self, p_data, p)
        #同盟排名
        if t == RANK_ALLY:
            return RankAlly.rank(self, p_data, p)


class RankData(object):
    """ 排行榜排序查询实现 """
    def __init__(self):
        self.init()

    def init(self):
        """ 初始化 """
        self.is_next = CONST_NEXT_YES
        #_others纪录关联表所需要的数据
        self.others = {}
        self.times = 1

        self.ret = []
        self.p_rets = {}
        self.ranks = {}

    @property
    def data(self):
        return self.ret, self.p_rets, self.ranks

    def query(self, table, columns, querys=None, limit=0, sort_by=None, rpc=CONST_RPC_STORE):
        """ 查询排行 """
        rpc_store = self.getRpc(rpc=rpc)
        count = rpc_store.count(table, None)
        skip = (self.times-1) * TIMES_NUMS
        if self.times * TIMES_NUMS - TIMES_NUMS <= count <= self.times *TIMES_NUMS:
            self.is_next = CONST_NEXT_NO
        return rpc_store.values(table, columns, querys, limit=limit, sort_by=sort_by, skip=skip)

    def queryByList(self, alist, key, table, columns, query_key=CONST_ID, rpc=CONST_RPC_STORE):
        """ 根据排行query返回的列表中的某个key去查询关联表所需要的信息 """
        query_list = [item[key] for item in alist]
        querys = {query_key:{CONST_IN:query_list}}
        self.others[table] = {}
        [self.others[table].update({item.pop(query_key):item}) for item in self._query(table, columns,
            querys=querys, rpc=rpc)]

    def _query(self, table, columns, querys=None, rpc=CONST_RPC_STORE):
        """ 查询 """
        rpc_store = self.getRpc(rpc=rpc)
        return rpc_store.values(table, columns, querys)

    def getRet(self, main_list, query_key, del_key=None, change_id=None, type=None):
        """ 将query主排行，
        queryByList关联表数据组合得出最终数据
        返回 data:
            ret=【排行榜数据】
            p_rets={pid:ret的索引}
            ranks={con:rank}
                """
        for i, item in enumerate(main_list):
            rank = (self.times - 1) * TIMES_NUMS + i + 1
            if type == RANK_LEVEL:
                self.p_rets[item[CONST_ID]] = rank - 1
                self.ranks[item[CONST_LEVEL]] = rank
            else:
                self.p_rets[item[CONST_PID]] = rank - 1
                if not item.has_key(CONST_CBE):
                    self.ranks[0] = rank
                    break
                cbe = item[CONST_CBE] / CONST_CBE_BASE * CONST_CBE_BASE
                self.ranks[cbe] = rank
            for key in self.others.keys():
                try:
                    self.others[key][item[query_key]].pop(CONST_ID, None)
                except:
                    pass
                try:
                    item.update(self.others[key][item[query_key]])
                except:
                    pass
            if change_id:
                item[change_id] = item.pop(CONST_ID)
            item.update({CONST_R:rank})
            if del_key:
                [item.pop(tmp) for tmp in del_key]
            if CONST_NAME not in item:
                item[CONST_NAME] = CONST_NONE
            if CONST_LEVEL not in item:
                item[CONST_LEVEL] = CONST_NEXT_NO
            self.ret.append(item)
        self.times += 1

    def getRpc(self, rpc=CONST_RPC_STORE):
        if rpc == CONST_RPC_STORE:
            return Game.rpc_store
        elif rpc == CONST_RPC_RES_STORE:
            return Game.rpc_res_store

class RankBase(object):
    def __init__(self):
        pass

    @classmethod
    def rank(cls, mgr, p_data, page):
        """ 获取排名数据 """
        rs, data = cls.get_data(mgr, p_data)
        if rs is False:
            return rs, data
        #根据页数获取排名数据
        rs, rdata = cls.get_ranks(page, data)
        if rs is False:
            return rs, rdata
        ranks, next = rdata
        #获取本人排名数据
        p_rank = cls.get_prank(p_data, data)
        return True, cls.pack_msg(ranks, p_rank, next)

    @classmethod
    def pack_msg(cls, ranks, p_rank, next):
        """ 打包 """
        if p_rank:
            prank, value = p_rank
            p = {CONST_MINE:{CONST_R:prank, CONST_VALUE:value}}
        else:
            p = {CONST_MINE:{}}
        d = {CONST_RET:ranks, CONST_NEXT:next}
        d.update(p)
        return d
    
    @classmethod
    def get_data(cls, mgr, p_data):
        """ 通过排名管理器获得数据 """        
        pass

    @classmethod
    def get_ranks(cls, page, data):
        """ 根据页数获取排名数据并返回下页是否有数据 """
        ret, _, _ = data
        rs, data = cls.page_row(page, len(ret))
        if rs is False:
            return rs, data
        start, end = data
        return True, cls.cut_datas(start, end, ret)

    @classmethod
    def get_prank(cls, p_data, data):
        """ 获取玩家排名信息 """
        pass

    @classmethod
    def page_row(cls, page, max_row):
        """ 根据页数返回起始行数和终止行数 终止页码超出返回None """
        start = page * PAGE_NUMS - PAGE_NUMS
        end = start + PAGE_NUMS
        if not max_row or start > MAX_ARENA_RANK or start > max_row:
            return False, errcode.EC_RANK_NO
        return True, (start, end)

    @classmethod
    def cut_datas(cls, start, end, data):
        """ 截取数据 返回下页是否有内容和截取的数据"""
        next = 0
        if len(data) > end:
            cut_data = data[start:end]
            if end < TIMES_NUMS:
                next = 1
        else:
            cut_data = data[start:]
        return cut_data, next

class RankLevel(RankBase):
    """ 玩家等级排名 """
    def __init__(self):
        super(RankLevel, self).__init__()

    @classmethod
    def get_data(cls, mgr, p_data):
        """ 获取玩家排名信息 """
        if mgr.player_level_data is None:
            return False, errcode.EC_TIME_UNDUE
        return True, mgr.player_level_data

    @classmethod
    def get_prank(cls, p_data, data):
        """ 获取玩家等级排名数据 """
        pid = p_data[CONST_ID]
        ret, p_rets, rdata = data
        index = p_rets.get(pid)
        if index:
            p_ret = ret[index]
            p_rank, p_level = p_ret[CONST_R], p_ret[CONST_LEVEL]
        else:
            p_level = p_data[CONST_LEVEL]
            if rdata.has_key(p_level):
                p_rank = rdata.get(p_level)
            else:
                p_rank = MAX_ARENA_RANK + 1
        return p_rank, p_level

class RankCBE(RankBase):
    """ 玩家战斗力排名 """
    def __init__(self):
        super(RankCBE, self).__init__()

    @classmethod
    def get_data(cls, mgr, p_data):
        """ 通过排名管理器获得数据 """
        if mgr.player_cbe_data is None:
            return False, errcode.EC_TIME_UNDUE
        return True, mgr.player_cbe_data

    @classmethod
    def get_prank(cls, p_data, data):
        """ 获取玩家战斗力排名数据 """
        pid = p_data[CONST_ID]
        ret, p_rets, p_ranks = data
        index = p_rets.get(pid)
        if index:
            p_ret = ret[index]
            p_rank, p_cbe = p_ret[CONST_R], p_ret[CONST_CBE]
        else:
            p_cbe = p_data[CONST_CBE]
            rank_cbe = p_cbe / CONST_CBE_BASE * CONST_CBE_BASE
            if not p_ranks.has_key(rank_cbe):
                cbes = p_ranks.keys()
                cbes.sort()
                index = bisect.bisect_left(cbes, rank_cbe) - 1
                rank_cbe = cbes[index]
            p_rank = p_ranks[rank_cbe]
        return p_rank, p_cbe

class RankArena(RankBase):
    """ 竞技场排名 """
    def __init__(self):
        super(RankArena, self).__init__()

    @classmethod
    def get_data(cls, mgr, p_data):
        """ 通过排名管理器获得数据 """
        v = mgr.cache.get(RANK_ARENA, None)
        if v is None:
            ranks = Game.rpc_arena_mgr.get_ranks(0, MAX_ARENA_RANK)
            v = [ranks, {}]
            mgr.cache.set(RANK_ARENA, v)
        ranks_data, page_ranks = v
        mine_v = mgr.cache.get((p_data[CONST_ID], RANK_ARENA), None)
        if not mine_v:
            mine_v = []
            mgr.cache.set((p_data[CONST_ID], RANK_ARENA), mine_v)
        return True, (ranks_data, page_ranks, mine_v)

    @classmethod
    def get_ranks(cls, page, data):
        """ 根据页数获取排名数据并返回下页是否有数据 """
        ranks_data, page_ranks, _ = data
        if page in page_ranks:
            next = int(page * PAGE_NUMS < len(ranks_data))
            return True, (page_ranks[page], next)
        rs, data = cls.page_row(page, len(ranks_data))
        if rs is False:
            return rs, data
        start, end = data
        cut_data, next = cls.cut_datas(start, end, ranks_data)
        info_null = ('', 0, 0, 0)
        pv = []
        infos = Game.rpc_arena_mgr.get_rival_infos(cut_data)
        for index, rpid in enumerate(cut_data):
            info = infos.get(rpid, info_null)
            pv.append({CONST_R: start+index+1,
                       CONST_NAME: info[IPI_IDX_NAME],
                       CONST_LEVEL: info[IPI_IDX_LEVEL],
                       CONST_PID: rpid,
                       CONST_RID: info[IPI_IDX_RID],
                       CONST_CBE: info[IPI_IDX_CBE],
                       })
        #字典为引用 修改此处 就改了内存中cache的数据
        page_ranks[page] = pv
        return True, (pv, next)

    @classmethod
    def get_prank(cls, p_data, data):
        """ 获取玩家战斗力排名数据 """
        ranks_data, page_ranks, mine_v= data
        pid = p_data[CONST_ID]
        if not mine_v:
            #自身排名
            mine_rank = Game.rpc_arena_mgr.get_rank(pid)
            if not mine_rank:mine_rank = CONST_NEXT_NO
            mine_cbe = p_data[CONST_CBE]
            if mine_rank:
                #字典为引用 修改此处 就改了内存中cache的数据
                mine_v.append(mine_rank)
                mine_v.append(mine_cbe)
        return mine_v

class RankDeep(RankBase):
    """ 深渊排名 """
    def __init__(self):
        super(RankDeep, self).__init__()

    @classmethod
    def get_data(cls, mgr, p_data):
        """ 通过排名管理器获得数据 """
        mgr.deep_pass_day()
        return True, (mgr.deep_pid_floor, mgr.deep_floor_pids)

    @classmethod
    def get_ranks(cls, page, data):
        """ 通过页数获取排名的数据和下页是否有内容 """
        pid_floor, floor_pids = data
        rs, data = cls.page_row(page, len(pid_floor))
        if rs is False:
            return rs, data
        start, end = data
        floors = floor_pids.keys()
        floors.sort(reverse=True)
        tmp_num = 0
        rank_pids = []
        for floor in floors:
            pids = floor_pids.get(floor)
            tmp_num += len(pids)
            rank_pids.extend(pids)
            if tmp_num > end:
                break
        rank_pids, next = cls.cut_datas(start, end, rank_pids)
        rank_data = []
        rank = start
        _, p_infos = Game.rpc_player_mgr.get_player_infos(rank_pids)
        for rank_pid in rank_pids:
            rank += 1
            data =  p_infos.get(rank_pid)
            if data is None:
                continue
            pname, rid, plevel = data
            floor = pid_floor.get(rank_pid)
            d = {CONST_R:rank, CONST_NAME:pname,
                 CONST_LEVEL:plevel, CONST_DEEPFLOOR:floor,
                 CONST_RID:rid}
            rank_data.append(d)
        return True, (rank_data, next)

    @classmethod
    def get_prank(cls, p_data, data):
        """ 获取玩家深渊排名数据 """
        pid_floor, floor_pids = data
        pid = p_data[CONST_ID]
        pfloor = pid_floor.get(pid)
        if pfloor is None:
            return
        floors = floor_pids.keys()
        floors.sort(reverse=True)
        rank = 0
        for floor in floors:
            pids = floor_pids.get(floor)
            if floor == pfloor:
                index = len(pids)
                if pid in pids:
                    index = pids.index(pid)
                rank = rank + index + 1
                break
            rank += len(pids)
        return rank, pfloor

class RankBoss(RankBase):
    """ 世界boss排名 """
    def __init__(self):
        super(RankBoss, self).__init__()

    @classmethod
    def get_data(cls, mgr, p_data):
        """ 通过排名管理器获得数据 """
        return True, (mgr.boss_rank_datas, mgr.boss_pid_data, None)

    @classmethod
    def get_prank(cls, p_data, data):
        """ 获取世界boss个人排名数据 """
        _, pid_data, _ = data
        return pid_data.get(p_data[CONST_ID])

class RankAlly(RankBase):
    """ 同盟排名 """
    def __init__(self):
        super(RankAlly, self).__init__()

    @classmethod
    def rank(cls, mgr, p_data, page):
        """ 通过页数获取排名的数据和下页是否有内容 """
        pid = p_data[CONST_ID]
        rs, rdata = Game.rpc_ally_mgr.get_ally_rank(pid, page)
        if rs is False:
            return False, rdata
        ranks, p_rank, next = rdata
        return True, cls.pack_msg(ranks, p_rank, next)


def new_rank_mgr():
    mgr = RankMgr()
    return mgr


