#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time
import bisect
from functools import wraps

from corelib.common import make_lv_regions

from corelib import log, spawn, sleep, RLock
from corelib.message import observable

from ally_data import AllyAssist
from ally import Ally
from ally import init_vip_sett

from game.store import TN_ALLY
from game import Game
from game.base import errcode, common
from game.base.constant import ALLY_CREATE_LEVEL, ALLY_CREATE_LEVEL_V
from game.base.constant import ALLY_BOAT_LEVLES, ALLY_BOAT_LEVLES_V
from game.base.constant import ALLY_BOAT_CRYSTAL, ALLY_BOAT_CRYSTAL_V
from game.base.constant import ALLY_CREATE_COIN1, ALLY_CREATE_COIN1_V
from game.base.constant import ALLY_ALLYS_P_NUM, ALLY_ALLYS_P_NUM_V
from game.base.constant import ALLY_CAT_RID, ALLY_CAT_RID_V
from game.base.constant import ALLY_OP_SUCCEED

from game.base.msg_define import MSG_ALLY_UP, MSG_START, MSG_ALLY_JOIN, MSG_RES_RELOAD


def wrap_get_ally(func):
    @wraps(func)
    def _func(self, pid, *args, **kw):
        ally = self.get_ally_by_pid(pid)
        if not ally:
            return False, errcode.EC_PLAYER_NO
        kw['ally'] = ally
        return func(self, pid, *args, **kw)
    return _func

def wrap_lock_modify(func):
    @wraps(func)
    def _func(self, *args, **kw):
        with self._lock_modify:
            return func(self, *args, **kw)
    return _func

@observable
class AllyMgr(object):
    _rpc_name_ = 'rpc_ally_mgr'
    _instance = None
    MAX_RANK = 10
    REFURBISH_TIME = 600
    RANK_NUM = 10
    RANK_SUM = 100

    def __init__(self):
        AllyMgr._instance = self
        #全部声望和glory_pid一起使用
        self.glorys = []
        #声望对应的pid, 和glory一起使用
        self.glory_pids = []
        #同盟的主表
        self.allys = {}
        #PID->ally
        self.pid2ally = {}
        #同盟的排名,改存储ally_id
        self.allys_rank = []
        self.clear_gm_ally()
        self._lock_modify = RLock()
        self.deco_types = {}
        self._boat_types = {}
        self.boat_lv2exp = {}
        self.boat_exp2lv = {}
        self.boat_type_num = {}
        #龙晶捐献同盟增加的建设度
        self.crystal_ally_v = 0
        #龙晶捐献玩家增加的建设度
        self.crystal_player_v = 0

    @property
    def _game(self):
        return Game

    @property
    def rpc_store(self):
        return Game.rpc_store

    @property
    def setting_mgr(self):
        return Game.setting_mgr

    @property
    def mail_mgr(self):
        return Game.mail_mgr

    @property
    def res_mgr(self):
        return Game.res_mgr

    @property
    def rpc_player_mgr(self):
        return Game.rpc_player_mgr

    def to_dict(self, pid):
        ally = self.get_ally_by_pid(pid)
        if ally:
            return dict(aid = ally.data.id, n = ally.data.name)
        return None

    def attach_ally(self, pid, ally):
        """ 玩家的ID对应一个Ally() """
        self.pid2ally[pid] = ally
        _obj = ally.assist_objs.get(pid)
        self.glory_add(pid, _obj.data.exp)

    def detach_ally(self, pid):
        try:
            del self.pid2ally[pid]
            self.glory_remove(pid)
        except KeyError:
            log.error("____dis_all_obj func in all_mgr.py is error pid:%s", pid)

    def start(self):
        import app
        app.sub(MSG_START, self.load)

    def _stream_in_mgrs(self, ally):
        ally_id = ally.data.id
        self.allys[ally_id] = ally
        #过滤盟主为空得情况
        if not ally.main_name():
            return
        if ally_id not in self.allys_rank:
            self.allys_rank.append(ally_id)

    def lood(self):
        self._boat_types = {}
        self.boat_exp2lv = {}
        self.boat_lv2exp = {}
        self.boat_type_num = {}
        #全局龙晶对应的建设值
        v = self._game.setting_mgr.setdefault(ALLY_BOAT_CRYSTAL, ALLY_BOAT_CRYSTAL_V)
        self.crystal_ally_v, self.crystal_player_v = map(int, v.split("|"))
        #self.crystal_player = int(self._game.setting_mgr.setdefault(ALLY_BOAT_CRYSTAL, ALLY_BOAT_CRYSTAL_V))
        #每种天舟类型对应的等级
        #boat_types = {type1:{lv1:obj1,lv2:obj2}, type2:{lv1:obj1,lv2:obj2}}
        boat_types = {}
        for obj in Game.res_mgr.ally_boat_levels.values():
            d = boat_types.setdefault(obj.t,{})
            d[obj.lv] = obj

        fmt = "%s:%s|"
        #for t, dic in self._boat_types.items():
        self.deco_types = boat_types
        for t, dic in boat_types.items():
            str_ = fmt%(0,1)
            ed = []
            ld = []
            self.boat_type_num[t] = 0
            for obj in dic.values():
                str_ += fmt%(obj.exp, obj.lv)
                ed.append((int(obj.exp), int(obj.lv)))
                ld.append((int(obj.lv), int(obj.exp)))
                self.boat_type_num[t] += 1
            str_ = str_[:-1]
            self._boat_types[t] = make_lv_regions(str_)
            self.boat_exp2lv[t] = make_lv_regions(ed)
            self.boat_lv2exp[t] = make_lv_regions(ld)

    def load(self):
        Game.res_mgr.sub(MSG_RES_RELOAD, self.lood)
        self.lood()
        init_vip_sett()
        allys = self.rpc_store.load_all(TN_ALLY)
        for one_ally in allys:
            ally = Ally(self, adict = one_ally)
            ally.load()
            self._stream_in_mgrs(ally)
        self._loop_sort = spawn(self.refurbish)

    def save(self):
        pass

    def refurbish(self):
        """ 10分钟刷新一次同盟排名 """
        def sort_rank(ally_id):
            if ally_id not in self.allys:
                return 0, 0, 0
            ally = self.allys[ally_id]
            return -ally.data.level, -ally.data.exp, -ally.member_num
        while 1:
            self.allys_rank.sort(key=sort_rank)
            i = 0
            for aid in self.allys_rank:
                i += 1
                ally = self.allys[aid]
                d = ally.data
                num = ally.member_num
                aid = d.id
                log.info("aid:%s rank: %s, lv:%s, member_num:%s, exp:%s", aid, i, d.level, num, d.exp)
                if i > AllyMgr.MAX_RANK:
                    break
            sleep(AllyMgr.REFURBISH_TIME)

    def enter(self, player):
        """ 得到玩家自己的同盟信息 """
        ally = self.pid2ally.get(player.data.id, None)
        if not ally:
            return False, errcode.EC_NO_ALLY
        ent_dic = dict()
        ent_dic['aid'] = ally.data.id
        ent_dic['n'] = ally.data.name
        return True, ent_dic

    @wrap_get_ally
    def player_own(self, pid, ally = None):
        """ 得到玩家自己的同盟信息 """
        r_dict = ally.own(pid)
        i = self.allys_rank.index(ally.data.id) + 1
        r_dict['rank'] = i
        d = ally.data
        num = ally.member_num
        log.info("aid:%s rank: %s, lv:%s, member_num:%s, exp:%s", d.id, i, d.level, num, d.exp)
        return True, r_dict

    def _level_check(self, level):
        """ 等级检测 """
        create_level = self.setting_mgr.setdefault(ALLY_CREATE_LEVEL, ALLY_CREATE_LEVEL_V)
        if level < create_level:
            return False, errcode.EC_NOLEVEL
        return True, None

    def pre_create(self, pid, level, ally_name):
        #创建者是否已有同盟
        ally = self.get_ally_by_pid(pid)
        if ally:
            return False, errcode.EC_PLAYER_OWN
        state, code = self._level_check(level)
        if not state:
            return state, code
        #是否重名
        for ally_id in self.allys_rank:
            ally = self.allys[ally_id]
            if ally.data.name == ally_name:
                return False, errcode.EC_ALLY_EXIT
        return True, self.setting_mgr.setdefault(ALLY_CREATE_COIN1, ALLY_CREATE_COIN1_V)

    def _create_main(self, mainId, ally_name):
        """ 主表的创建 """
        ally = AllyMgr.new(mainId, ally_name)
        ally.save(self.rpc_store)
        return ally

    def _create_assist(self, mainId, ally):
        """ 从表的创建 """
        ally_assist_obj = Ally.create_master(mainId, ally.data.id, self.rpc_store)
        ally_assist_obj.save(self.rpc_store, forced=True)
        return ally_assist_obj

    @wrap_lock_modify
    def create_ally(self, mainId, ally_name):
        """ 创建同盟 ally_name是同盟名 """
        #创建者是盟主并写入数据库的表ally 表ally_player中
        ally = self._create_main(mainId, ally_name)
        assist_obj = self._create_assist(mainId, ally)

        #写入内存中
        ally.stream_assist(assist_obj)
        self._stream_in_mgrs(ally)
        self.safe_pub(MSG_ALLY_UP, ally.data.id, ally.data.level)
        rpc_player = self.rpc_player_mgr.get_rpc_players([mainId])
        if rpc_player:
            rpc_player[0].ally_pub(MSG_ALLY_JOIN, 1)
        return True, (ally.data.id, ally.create_ally(mainId))

    @wrap_get_ally
    def change_post(self, pid, ct, inf, ally = None):
        """ 更改公告 """
        return ally.change_post(pid, ct, inf)

    def apply_join(self, pid, name, level, aid):
        """ 申请加入同盟 """
        ally = self.get_ally_by_pid(pid)
        if ally:
            return False, errcode.EC_PLAYER_OWN
        ally = self.get_ally_by_aid(aid)
        if not ally:
            return False, errcode.EC_NO_ALLY
        return ally.apply_join( pid, name, level)

    @wrap_get_ally
    def applicants(self, pid, ally = None):
        """ 获得申请者的信息 """
        return ally.applicants(pid)

    @wrap_get_ally
    @wrap_lock_modify
    def handle_apply(self, pid, pid2, state, ally = None):
        """ 处理入盟申请 """
        if self.get_ally_by_pid(pid2):
            ally.del_apply_by_pid(pid2)
            return False, errcode.EC_PLAYER_OWN
        rs , data = ally.handle_apply(pid, pid2, state)
        if rs:
            return rs, ALLY_OP_SUCCEED
        return rs, data

    @wrap_get_ally
    def change_duty(self, pid, name, pid2, duty, ally = None):
        """ 改变职责 """
        return ally.change_duty(pid, name, pid2, duty)

    @wrap_get_ally
    @wrap_lock_modify
    def kick_out(self, pid, name,pid2, ally = None):
        """ 踢人 """
        return ally.kick_out( pid, name, pid2)

    @wrap_get_ally
    @wrap_lock_modify
    def quit(self, pid, name, ally = None):
        """ 退出同盟 """
        return ally.quit(pid, name)

    @wrap_get_ally
    def members(self, pid, ally = None):
        """ 获取自己同盟成员"""
        return True, ally.members()

    def other_members(self, aid):
        """ 获取他人同盟成员"""
        ally = self.get_ally_by_aid(aid)
        if not ally:
            return False, errcode.EC_NO_ALLY
        return True, ally.members(is_other = True)

    def _ally_by_page(self, pid, begin, end):
        ally_list = []
        for index, ally_id in enumerate(self.allys_rank[begin:end]):
            ally = self.allys[ally_id]
            t_dict = dict()
            d = ally.data
            t_dict['aid'] = d.id
            t_dict['n'] = d.name
            t_dict['rank'] = begin + index + 1
            t_dict['pn'] = ally.main_name()
            t_dict['lv'] = d.level
            t_dict['c'] = ally.member_num
            t_dict['ps'] = d.post
            t_dict['info'] = d.info
            pin = 0
            for _dic in ally.data.apply:
                if pid == _dic['pid']:
                    pin = 1
                    break
            t_dict['pin'] = pin
            ally_list.append(t_dict)
        return ally_list

    def ally_by_page(self, pid, page, ally = None):
        """ 获取某一页的同盟信息 """
        b_num, e_num = self.get_page_range(ALLY_ALLYS_P_NUM, ALLY_ALLYS_P_NUM_V, page)
        return True, self._ally_by_page(pid, b_num, e_num)

    def get_ally_rank(self, pid, page):
        """ 通过排名的行数和pid 获取排名信息 """
        from game.mgr.rank import RankBase, CONST_R, CONST_ANAME, CONST_NAME, CONST_LEVEL
        max_num = len(self.allys_rank)
        rs, data = RankBase.page_row(page, max_num)
        if rs is False:
            return rs, data
        start, end = data
        allys_rank, next = RankBase.cut_datas(start, end, self.allys_rank)
        ranks = []
        rank = start
        for ally_id in allys_rank:
            rank += 1
            ally = self.allys[ally_id]
            dic = dict()
            dic[CONST_R] = rank
            dic[CONST_NAME] = ally.data.name
            dic[CONST_ANAME] = ally.main_name()
            dic[CONST_LEVEL] = ally.data.level
            ranks.append(dic)
        ally = self.get_ally_by_pid(pid)
        p_rank = None
        if ally and ally.data.id in self.allys_rank:
            rank = self.allys_rank.index(ally.data.id) + 1
            p_rank = (rank, ally.data.level)
        return True, (ranks, p_rank, next)

    @wrap_get_ally
    def active_log(self, pid, ally = None):
        """ 获取自己同盟的活动日志 """
        data = ally.active_log()
        return True, data

    def _stream_out_mgrs(self, ally):
        try:
            del self.allys[ally.data.id]
            self.allys_rank.remove(ally.data.id)
        except:
            log.log_except()

    @wrap_get_ally
    def dismiss(self, pid, ally = None):
        """ 解散同盟 """
        rs, data = ally.dismiss(pid)
        if not rs:
            return rs, data
        self._stream_out_mgrs(ally)
        return True, ALLY_OP_SUCCEED

    @wrap_get_ally
    def set_boss_time(self, pid, t, ally = None):
        """ 设置BOSS时间 t的格式:'day-hour(24制)-min'"""
        rs, data = self._game.rpc_boss_mgr.ally_boss_set_time(ally.data.id, t)
        if not rs:
            return rs, data
        return ally.set_boss_time(pid)

    @wrap_get_ally
    def get_boss_time(self, pid, ally = None):
        """ 得到BOSS的时间 """
        return self._game.rpc_boss_mgr.ally_boss_get_time(ally.data.id, is_fight=True)

    @wrap_get_ally
    def cat_enter(self, pid, vip, ally = None):
        return True, ally.cat_enter(pid, vip)

    @wrap_get_ally
    def cat(self, pid, vip, ally = None):
        """
        一次招财
        只做检测不做具体逻辑
        """
        rs, data = ally.cat(pid, vip)
        if not rs:
            return rs, data
        return True, self._game.setting_mgr.setdefault(ALLY_CAT_RID, ALLY_CAT_RID_V)

    @wrap_get_ally
    def grave_enter(self, pid, vip, ally = None):
        """ 铭刻进入 """
        return True, ally.grave_enter(pid, vip)

    @wrap_get_ally
    def grave_have(self, pid, t, vip, ally = None):
        rs, data = ally.grave_have(pid, t, vip)
        if not rs:
            return rs, data
        res_grave = self._game.res_mgr.ally_graves.get(t, None)
        coin1 = res_grave.coin1
        coin3 = res_grave.coin3
        arm = getattr(res_grave, "lv%sarm"%ally.data.level)
        return True, (coin1, coin3, arm)

    @wrap_get_ally
    def grave(self, pid, t, vip, ally = None):
        """ 宝具铭刻 """
        return ally.grave(pid, t, vip)

    @wrap_get_ally
    def contribute(self, pid, name, train, ally = None):
        main_data = ally.data
        ally_levels = self.res_mgr.ally_levels
        #配成从0开始所以判断下一级需要加1
        level_obj = ally_levels.get(main_data.level + 1)
        if level_obj:
            up_exp = level_obj.exp
            main_data.exp += train
            if main_data.exp >= up_exp and main_data.level < len(ally_levels):
                ally.level_up()
                self.safe_pub(MSG_ALLY_UP, main_data.id, main_data.level)
                log.info("contribute ally_id:%s,cur_exp:%s,lev_up_exp:%s", main_data.id, main_data.exp, up_exp)
                main_data.exp -= up_exp
            ally.contribute(pid, name, train)
            return True, None
        else:
            log.error('contribute in ally.py level:%s', ally.data.level)
            return False, None

    def get_ally_by_aid(self, aid):
        """ 通过同盟Id得到Ally() """
        return self.allys.get(aid, None)

    def get_allypids_by_level(self, level):
        """ 同盟大于等于某同盟等级的同盟的所有玩家 """
        pids = []
        for ally in self.allys.itervalues():
            if ally.data.level >= level:
                pids.extend(ally.get_member_pids())
        return pids

    def get_ally_pids_by_name(self, name):
        pids = []
        for ally in self.allys.itervalues():
            if ally.data.name != name:
                continue
            pids = ally.get_member_pids()
        return pids

    def get_ally_by_pid(self, pid):
        """ 通过pid得到Ally() """
        return self.pid2ally.get(pid, None)

    def get_aid_by_pid(self, pid):
        try:
            return self.get_ally_by_pid(pid).data.id
        except:
            return 0

    def ally_level_by_aid(self, aid):
        ally = self.get_ally_by_aid(aid)
        if ally:
            return ally.data.level
        return 0

    def ally_name_by_aid(self, aid):
        """ 通过同盟id获取同盟名 """
        ally = self.get_ally_by_aid(aid)
        if ally:
            return ally.data.name
        return

    def ally_level_by_pid(self, pid):
        ally = self.get_ally_by_pid(pid)
        if ally:
            return ally.data.level
        return 0

    def member_pids_by_aid(self, aid):
        ally = self.get_ally_by_aid(aid)
        if ally:
            return ally.get_member_pids()
        return []

    @wrap_get_ally
    def member_pids_by_pid(self, pid, ally = None):
        return 1, ally.get_member_pids()

    def get_page_range(self, sett_key, sett_val, page):
        n_per_p = self.setting_mgr.setdefault(sett_key, sett_val)
        page -= 1
        b_num = max(page, 0) * n_per_p
        e_num = b_num + n_per_p
        return b_num, e_num

    @classmethod
    def new(cls, mainId, ally_name):
        """ 主表的创建 """
        ally = Ally(cls._instance)
        d = ally.data
        d.cPid = mainId
        d.tNew = int(time.time())
        d.name = ally_name
        d.mainId = mainId
        ally.init_boat_level()
        ally.glory_task_start()
        return ally

    #---------------------------------狩龙系统-------------------------------------------
    def boat_lv_by_exp(self, t, exp):
        """得到狩龙类型等级通过经验"""
        return self._boat_types.get(t)(exp)

    @wrap_get_ally
    def crystal_enter(self, pid, ally = None):
        return ally.crystal_enter(pid)

    @wrap_get_ally
    def crystal_offer(self, pid, t, n, ally = None):
        return ally.crystal_offer(pid, t, n)

    @wrap_get_ally
    def glory_exchange_enter(self, pid, ally = None):
        #TODO 条件判断
        return ally.glory_exchange_enter(pid)

    @wrap_get_ally
    def pre_glory_exchange(self, pid, iid, ally = None):
        return ally.pre_glory_exchange(pid, iid)

    @wrap_get_ally
    def glory_exchange(self, pid, iid, ally = None):
        return ally.glory_exchange(pid, iid)

    def glory_remove(self, pid):
        if pid in self.glory_pids:
            index = self.glory_pids.index(pid)
            if len(self.glory_pids) <= len(self.glorys):
                self.glorys.pop(index)
            self.glory_pids.pop(index)

    def glory_add(self, pid, glory):
        self.glory_remove(pid)
        index = bisect.bisect_right(self.glorys, glory)
        bisect.insort_right(self.glorys, glory)
        self.glory_pids.insert(index, pid)

    @wrap_lock_modify
    def set_glory_rank(self, pid, glory):
        """由外界调用排序"""
        try:
            self.glory_remove(pid)
            self.glory_add(pid, glory)
        except Exception as e:
            log.error(e)

    @wrap_get_ally
    def in_glory_rank(self, pid, ally = None):
        return ally.glory_rank()

    @wrap_get_ally
    def all_glory_rank(self, pid, page, ally = None):
        """全局的声望"""
        r_l = []
        sum = len(self.glory_pids)
        s = sum - page*AllyMgr.RANK_NUM if sum > AllyMgr.RANK_NUM else 0
        e = s + AllyMgr.RANK_NUM
        limt = sum - AllyMgr.RANK_SUM
        if s < limt:
            s = limt
            e = limt + AllyMgr.RANK_NUM
        l = self.glory_pids[s:e]
        for p in l:
            t_ally = self.get_ally_by_pid(p)
            _dic = t_ally.glory_rank_by_pid(p, gl=True)
            _dic['rk'] = sum - self.glory_pids.index(p)
            r_l.append(_dic)
        r_l.sort(key=lambda x: x['rk'])
        prk = sum - self.glory_pids.index(pid)
        return True, dict(prk=prk, l=r_l)

    def get_boat_init_params(self, aid):
        ally = self.get_ally_by_aid(aid)
        if not ally:
            return False, (0, 0, 0, 0)
        return True, ally.get_boat_init_params()

    def get_boat_type_level(self, aid, t=3):
        """得到天舟某一类型等级"""
        ally = self.get_ally_by_aid(aid)
        if not ally:
            return False, errcode.EC_NO_ALLY
        return True, ally.get_boat_type_level(int(t))

    @wrap_get_ally
    def get_glory_by_pid(self, pid, ally=None):
        return ally.get_glory(pid)

    @wrap_get_ally
    def cost_glory(self, pid, glory, ally=None):
        return ally.cost_glory(pid, glory)

    #---------------------------------GM功能使用-------------------------------------------
    def clear_ally(self, name):
        """GM命令删除除帮主已外的成员"""
        from game.base.constant import ALLY_MAIN
        if not self.set_gm_ally_by_name(name):
            return 0
        pids = []
        for assist_obj in self.gm_ally.assist_objs.values():
            if assist_obj.data.duty != ALLY_MAIN:
                pids.append(assist_obj.data.pid)
        for pid in pids:
            self.gm_ally._kick_out("test_gm", pid)
            log.info("+++del player ok pid: %s++", pid)
        return 1

    def set_gm_ally_by_name(self, name):
        self.clear_gm_ally()
        for ally in self.allys.values():
            if ally.data.name == name:
                self.gm_ally = ally
                return True
        return False

    def clear_gm_ally(self):
        self.gm_ally = None

    def gm_add_ally(self, pid):
        """GM同盟添加成员"""
        if not self.gm_ally:
            log.info("+++gm_ally have no value++")
            return 0
        aid = self.get_aid_by_pid(pid)
        if aid:
            log.info("+++pid :%s had ally_id: %s++", pid, aid)
            return 0
        log.info("###pid :%s add in ally", pid)
        self.gm_ally._handle_apply(pid, True)
        return 1

    def gm_change_duty(self, pid, duty):
        return self.gm_ally.gm_change_duty(pid, duty)


def new_ally_mgr():
    mgr = AllyMgr()
    mgr.start()
    return mgr

