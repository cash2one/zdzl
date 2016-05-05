#!/usr/bin/env python
# -*- coding:utf-8 -*-

import language

import ally_data
from ally_data import  AllyAssist, AllyLog
from corelib import log, sleep, spawn, spawn_later

from game import Game
from game.store import StoreObj, GameObj
from game.store import TN_PLAYER
from game.store import TN_ALLY, TN_P_ALLY, TN_ALLY_LOG

from game.base import errcode, common
from corelib.common import make_lv_regions
from game.base.constant import ALLY_CAT_COUNT, ALLY_GRAVE_COUNT1, ALLY_GRAVE_COUNT2
from game.base.constant import ALLY_MAIN, ALLY_MEMBER, MAIL_NORMAL, MAIL_REWARD , ALLY_LOG_MAX_NUM
from game.base.constant import ALLY_OP_JOIN, ALLY_OP_EXIT, ALLY_OP_CONTRIBUTE, ALLY_OP_DUTY, ALLY_OP_TICK
from game.base.constant import ALLY_CAT_NUM, ALLY_CAT_NUM_V
from game.base.constant import ALLY_GRAVE_NUM, ALLY_GRAVE_NUM_V
from game.base.constant import ALLY_GRAVE1, ALLY_GRAVE2, ALLY_GRAVE3
from game.base.constant import ALLY_VIP_GRAVE1, ALLY_VIP_GRAVE2, ALLY_VIP_GRAVE3
from game.base.constant import ALLY_OP_SUCCEED
from game.base.constant import BOAT_HP, BOAT_POW, BOAT_CD, BOAT_DELAY, BOAT_LEVEL_TYPES

from game.player.player import PlayerData
from game.base import  msg_define


class KeyRemoveMgr(object):

    OWN_REMOVE = ["id", "mainId", "subId", "cPid", "apply"]

    def __init__(self):
        pass

class AllyMainData(StoreObj):
    """ 同盟的主表"""

    def init(self):
        self.id = None              #ID
        self.exp = 0                #贡献值
        self.cPid = 0               #创建玩家id
        self.tNew = 0               #创建时间
        self.name = None            #名称
        self.level = 1              #等级
        self.post = ""              #当前公告类容
        self.info = ""              #当前的介绍
        self.mainId = 0             #盟主id
        self.apply = []             #当前的申请者列表
        #狩龙系统
        self.exp1 = 0               #当前耐久度的经验值
        self.exp2 = 0               #当前火力的经验值
        self.exp3 = 0               #当前炮弹载荷的经验值
        self.exp4 = 0               #当前续航的经验值


get_max_cat = lambda x : None       #获得招财猫的次数 目前传玩家VIP等级可获得
get_max_grave = lambda x : None     #获得铭刻次数 目前传玩家vip等级可获得

def init_vip_sett():
    global get_max_cat
    global get_max_grave

    c_max_num = Game.setting_mgr.setdefault(ALLY_CAT_NUM, ALLY_CAT_NUM_V)
    get_max_cat = make_lv_regions(c_max_num)
    c_max_num = Game.setting_mgr.setdefault(ALLY_GRAVE_NUM, ALLY_GRAVE_NUM_V)
    get_max_grave = make_lv_regions(c_max_num)


PID = 'pid'
TIME = 't'
NAME = 'name'
LEVEL = 'lv'
PVP = 'pvp'

ONE_DAY_TIME = 86400

def sor_member(is_other, for_onl, mem_lis):
    #排序
    if not is_other:
        if for_onl:
            mem_lis = sorted(mem_lis, key=lambda dic:(dic['dt'], dic['duty'], -dic['exp']))
        else:
            mem_lis = sorted(mem_lis, key=lambda dic:(dic['duty'], -dic['exp']))
    else:
        mem_lis = sorted(mem_lis, key=lambda dic:dic['duty'])
    return mem_lis


class Ally(GameObj):

    TABLE_NAME = TN_ALLY
    DATA_CLS = AllyMainData
    GLORY_SORT_TIME = 60*5

    def __init__(self, mgr, adict = None):
        self._mgr          = mgr
        self.lv1           = 0           #耐久度等级
        self.lv2           = 0           #火力等级
        self.lv3           = 0           #载荷等级
        self.lv4           = 0           #续航等级
        self._glorys       = []          #声望值
        self._glory_task   = None        #排序
        self._log_objs     = []          #活动日志
        self.r_tick_out    = []          #移除盟友
        self.assist_objs   = {}          #同盟的从表
        self.duty2objs     = {}          #职责对应从表对象
        self.r_duty_change = []          #设定盟友职位
        self.r_post        = []          #修改公告的权限
        self.r_apply       = []          #查看并审核入盟申请
        self.r_boss_t      = []          #修改BOSS战时间的权限
        self.members_list  = []          #每个同盟的所有成员列表
        self.pid2applyjson = {}          #用来保存申请者的字典{pid : Ally.new_apply_json()}
        super(Ally, self).__init__(adict = adict)
        if 0:
            from ally_mgr import AllyMgr
            self._mgr = AllyMgr()
            self.data = AllyMainData()

    @property
    def rpc_store(self):
        return self._mgr.rpc_store

    @property
    def setting_mgr(self):
        return self._mgr.setting_mgr

    @property
    def mail_mgr(self):
        return self._mgr.mail_mgr

    @property
    def res_mgr(self):
        return self._mgr.res_mgr

    @property
    def member_num(self):
        return len(self.assist_objs)

    @property
    def log_objs(self):
        if not self._log_objs:
            querys = dict(gid = self.data.id)
            logs = self.rpc_store.query_loads(TN_ALLY_LOG, querys)
            for log in logs:
                obj = AllyLog(adict = log)
                self._log_objs.append(obj)
        return self._log_objs


    def add_in_applys(self, apply_dic):
        self.data.apply.append(apply_dic)

    def _remove_rights(self, obj, pid):
        if pid in obj:
            obj.remove(pid)

    def _remove_duty2obj(self, pid):
        assist_obj = self.assist_objs.get(pid)
        t_list = self.duty2objs.get(assist_obj.data.duty)
        if not t_list:
            return
        t_list.remove(assist_obj)

    def remove_rights(self, pid):
        """ 移除该pid的职责 """
        self._remove_rights(self.r_apply, pid)
        self._remove_rights(self.r_tick_out, pid)
        self._remove_rights(self.r_duty_change, pid)
        self._remove_rights(self.r_post, pid)
        self._remove_rights(self.r_boss_t, pid)
        self._remove_duty2obj(pid)

    def _add_right(self, op_list, pid):
        """ 操作权限的链表操作 """
        if pid not in op_list:
            op_list.append(pid)

    def _build_rights(self, assist_data):
        """ 创建<查看 踢人 改变职责 修改公告>的权限"""
        duty = assist_data.duty
        right_dic = self.res_mgr.ally_rights
        if duty and right_dic:
            res_right = right_dic[duty]
            if not res_right:
                log.error("_build_rights in ally.ally.py duty:%s", duty)
                return
            pid = assist_data.pid
            if res_right.check:
                self._add_right(self.r_apply, pid)
            if res_right.kick:
                self._add_right(self.r_tick_out, pid)
            if res_right.change:
                self._add_right(self.r_duty_change, pid)
            if res_right.post:
                #设置BOSS的时间和改变公告的权限
                self._add_right(self.r_post, pid)
                self._add_right(self.r_boss_t, pid)

    def build_rights(self, assist_obj):
        self._build_rights(assist_obj.data)
        self._build_duty2obj(assist_obj)

    def _build_member(self, assist_data):
        self._mgr.attach_ally(assist_data.pid, self)
        self.members_list.append(assist_data)

    def _build_duty2obj(self, assist_obj):
        t_list = self.duty2objs.setdefault(assist_obj.data.duty, [])
        t_list.append(assist_obj)

    def stream_assist(self, assist_obj):
        """ 对从表obj的加工流程 """
        assist_data = assist_obj.data
        self.assist_objs[assist_data.pid] = assist_obj
        self.build_rights(assist_obj)
        self._build_member(assist_data)
        self._glorys.append(assist_obj.data.pid)

    def memory_json(self, apply_json):
        """  """
        if not apply_json:
            return
        try:
            #1个
            self.pid2applyjson[int(apply_json['pid'])] = apply_json
        except TypeError:
            #多个
            for t_dict in apply_json:
                self.pid2applyjson[int(t_dict['pid'])] = t_dict

    def _init_boat_level(self, t):
        lv_attr = 'lv%s'%t
        exp = 'exp%s'%t
        lv_value = self._mgr.boat_lv_by_exp(t, getattr(self.data, exp))
        setattr(self, lv_attr, lv_value)

    def init_boat_level(self):
        """初始化狩龙等级"""
        for t in BOAT_LEVEL_TYPES:
            self._init_boat_level(t)
            #if not self.data.id %10:
            #    print "*"*30, self.data.id, getattr(self, "lv%s"%t), getattr(self.data, "exp%s"%t)

    def refurbish_glory(self):
        def _sort(_id):
            if _id not in self.assist_objs:
                return 0
            _obj = self.assist_objs[_id]
            return -_obj.data.glory
        while 1:
            self._glorys.sort(key=_sort)
            for pid in self._glorys:
                _obj = self.assist_objs.get(pid)
                if not _obj:
                    continue
                self._mgr.set_glory_rank(pid, _obj.data.glory)
            sleep(Ally.GLORY_SORT_TIME)

    def load(self):
        querys = dict(gid = self.data.id)
        self.memory_json(self.data.apply)
        assistDicts = self.rpc_store.query_loads(TN_P_ALLY, querys)
        for assistDict in assistDicts:
            assist_obj = AllyAssist(adict = assistDict)
            self.stream_assist(assist_obj)
        self.init_boat_level()
        self.glory_task_start()

    def glory_task_start(self):
        if self._glory_task != None:
            self._glory_task.kill(block=0)
        self._glory_task = spawn(self.refurbish_glory)

    def own(self, pid, m_count = True, duty = True):
        """ 发送得到玩家自己工会 """
        own_dict = dict()
        if m_count:
            own_dict['mCount'] = self.member_num
        if duty:
            own_dict['duty'] = self.get_duty_by_pid(pid)
        td = self.data.to_dict().copy()
        td['pn'] = self.main_name()
        for ky in KeyRemoveMgr.OWN_REMOVE:
            if td.has_key(ky):
                del td[ky]
            else:
                log.error("key error:%s in ally.py:", ky)
        own_dict['ally'] = td
        return own_dict

    def create_ally(self, mainId):
        """ 发送创建同盟的 """
        return self.own(mainId, m_count = False, duty = False)

    def change_post(self, pid, ct, inf):
        """ 更改公告 """
        if not pid in self.r_post:
            return False, errcode.EC_NO_RIGHT
        self.data.post = ct
        self.data.info = inf
        p_dict = dict(id=pid, name=Ally.get_name(pid))
        self.save(self.rpc_store, forced = True)
        self.tell_online_members(language.ALLY_CHANGE_POST%p_dict)
        return True, ALLY_OP_SUCCEED

    def apply_join(self, pid, name, level):
        """ 申请加入同盟 """
        pvp_l = self._mgr._game.rpc_arena_mgr.get_rank(pid)
        t_dict = Ally.new_apply_json(pid, name, level, pvp_l)
        if pid in self.pid2applyjson:
            return False, errcode.EC_APPLY_EXIT
        self.add_in_applys(t_dict)
        self.save(self.rpc_store, forced = True)
        self.memory_json(t_dict)
        return True, None

    def kill_out_apply(self):
        """ 处理申请过期的申请者 """
        cur_time = common.current_time()
        u_d = self.pid2applyjson.copy()
        for pid, js in u_d.iteritems():
            if cur_time - js[TIME] >= ONE_DAY_TIME:
                self.del_apply_by_pid(pid)
                log.info("player :%s apply is out time was killed", pid)

    def applicants(self,pid):
        """ 获得page页的申请者的信息 """
        if not pid in self.r_apply:
            return False, errcode.EC_NO_RIGHT
        self.kill_out_apply()
        return True, self.data.apply

    def _handle_apply(self, pid, state):
        #移除申请表中的该玩家
        data = None
        if state:
            querys = dict(pid=pid)
            assist_dic = self.rpc_store.query_loads(TN_P_ALLY, querys)
            if assist_dic:
                #删除了的玩家重新使用(只是让gid和duty赋值为-1, 数据库中未删除)
                assist_obj = AllyAssist.re_use(self.data.id, pid, ALLY_MEMBER, assist_dic[0])
            else:
                #任职并保存到数据库中
                assist_obj = AllyAssist.new(pid, self.data.id, ALLY_MEMBER)
            assist_obj.save(self.rpc_store, forced=True)
            self.stream_assist(assist_obj)

            p_dict = dict(id=pid, name=Ally.get_name(pid))
            self._add_in_log(ALLY_OP_JOIN, p_dict['name'], 0, 0, 0)
            cont = language.ALLY_APPLY_CONTENT
            self.tell_online_members(language.ALLY_JOIN_CONTENT % p_dict)
        else:
            #拒绝通知
            cont = language.ALLY_APPLY_REFUSE
        content = cont%dict(name = self.data.name)
        #邮件通知玩家
        self.mail_mgr.send_mails(pid, MAIL_REWARD, language.ALLY_APPLY_TITLE, content, [])
        self.data.at = 0
        data = self.own(pid)
        return True, data

    def del_apply_by_pid(self, pid):
        """ 移除申请者的列表 """
        if pid in self.pid2applyjson:
            apply_json = self.pid2applyjson.get(pid)
            self.data.apply.remove(apply_json)
            self.save(self.rpc_store, forced = True)
            del self.pid2applyjson[pid]
            return

    def num_check(self):
        """成员数量的检测是不是可以继续添加成员入同盟"""
        ally_levels = self.res_mgr.ally_levels
        lev_obj = ally_levels.get(self.data.level)
        if not lev_obj:
            lev_obj = ally_levels.get(len(ally_levels))
        if lev_obj.maxNum <= self.member_num:
            return False, errcode.EC_MEMBER_FULL
        return True, None

    def handle_apply(self, pid1, pid2, state):
        """ 处理申请者 """
        if not pid1 in self.r_apply:
            return False, errcode.EC_NO_RIGHT
        if not pid2 in self.pid2applyjson:
            return False, errcode.EC_HANDLED
        self.del_apply_by_pid(pid2)
        rs, err = self.num_check()
        if not rs:
            return rs, err
        r_rs, r_data = self._handle_apply(pid2, state)
        if state:
            rpc_player = self._mgr.rpc_player_mgr.get_rpc_players([pid2])
            if rpc_player:
                dic = self.pack_msg(apply=r_data)
                rpc_player[0].attach_ally(self.data.id, self.data.name, dic)
                rpc_player[0].ally_pub(msg_define.MSG_ALLY_JOIN, self.data.level)
        return r_rs, r_data

    def _change_duty(self, assist_obj1, name, assist_obj2, duty):
        #得到该职位的个数
        lev_obj = self.res_mgr.ally_levels.get(self.data.level)
        if duty != ALLY_MEMBER:
            num = getattr(lev_obj, "dt%sNum"%duty)
            duty_list = self.duty2objs.get(duty)
            dt_num = 0 if not duty_list else len(duty_list)
            #是否已经达到上限
            if num <= dt_num:
                return False, errcode.EC_DUTY_FULL
        #改变职责
        pid2 = assist_obj2.data.pid
        self.remove_rights(pid2)
        assist_obj2.data.duty = duty
        self.build_rights(assist_obj2)
        assist_obj2.save(self.rpc_store, forced=True)

        self._add_in_log(ALLY_OP_DUTY, name, pid2, duty, 0)
        right_obj = self.res_mgr.ally_rights.get(duty, None)
        if not right_obj:
            log.error('ResAllyRight duty:%s', duty)
        cd_dict = dict(n1 = name,
                      n2 = Ally.get_name(pid2),
                      duty = right_obj.name)
        self.tell_online_members(language.ALLY_CHANGE_DUTY%cd_dict)
        return True, ALLY_OP_SUCCEED

    def change_duty(self, pid1, name, pid2, duty):
        """改变职责"""
        if pid1 == pid2:
            return False, errcode.EC_MAIN_QUIT_ERR
        if not pid1 in self.r_duty_change:
            return False, errcode.EC_NO_RIGHT
        assist_obj2 = self.assist_objs.get(pid2)
        if not assist_obj2:
            return False, errcode.EC_PLAYER_NO
        if duty == ALLY_MAIN:
            return False, errcode.EC_NO_RIGHT
        assist_obj1 = self.assist_objs.get(pid1)
        if assist_obj1.data.duty > duty:
            return False, errcode.EC_NO_RIGHT 
        return self._change_duty(assist_obj1, name, assist_obj2, duty)

    def _remove_member(self, pid):
        assist_obj = self.assist_objs.get(pid, None)
        if not assist_obj:
            return False, errcode.EC_PLAYER_NO
        self.remove_rights(pid)

        del self.assist_objs[pid]
        self.members_list.remove(assist_obj.data)
        self._mgr.detach_ally(pid)
        assist_obj.remove_member(self.rpc_store)
        #玩家如果在线解除玩家的ally属性
        rpc_player = self._mgr.rpc_player_mgr.get_rpc_players([pid])
        if rpc_player:
            rpc_player[0].detach_ally(self.pack_msg(kick=True))
        self._glorys.remove(assist_obj.data.pid)

    def _kick_out(self, name, pid2):
        self._remove_member(pid2)
        name2 = Ally.get_name(pid2)
        if name2:
            p_dict = dict(n2 = name2)
            p_dict['n1'] = name
            self.tell_online_members(language.ALLY_TICK_OUT%p_dict)
            p_dict['n1'] = self.data.name
            p_dict['n2'] = name
            self.mail_mgr.send_mails(pid2, MAIL_REWARD, language.ALLY_TICK_TITLE,
                                     language.ALLY_TICK_CONTENT % p_dict, [], notify_mgr=False)
            self._add_in_log(ALLY_OP_TICK,name, pid2, 0, 0)
            return True, ALLY_OP_SUCCEED
        return False, errcode.EC_PLAYER_EMPTY

    def kick_out(self, pid1, name, pid2):
        """踢人"""
        if not pid1 in self.r_tick_out:
            return False, errcode.EC_NO_RIGHT
        assist_obj = self.assist_objs.get(pid2, None)
        if not assist_obj:
            return False, errcode.EC_PLAYER_NO
        if assist_obj.data.duty == ALLY_MAIN:
            return False, errcode.EC_NO_RIGHT
        if common.current_time() - assist_obj.data.tJoin < ONE_DAY_TIME:
            return False, errcode.EC_QUIT_TIME_ERR
        return self._kick_out(name, pid2)

    def _main_quit(self, pid, name):
        """帮主退出同盟的操作"""
        #该同盟只有一个玩家就是帮主自己
        if len(self.duty2objs) == 1:
            return self.dismiss(pid)
        #退出通知
        self._remove_member(pid)
        params = dict(name=name)
        self.tell_online_members(language.ALLY_EXIT%params)
        self._add_in_log(ALLY_OP_EXIT, name, 0, 0, 0)
        #获得要操作从表的对象
        keys = self.duty2objs.keys()
        keys.remove(ALLY_MAIN)
        keys.sort()
        near_duty = keys[0]
        t_list = self.duty2objs[near_duty]
        t_list.sort(key=lambda obj:obj.data.tJoin)
        new_main = t_list[0]
        #先在内存中移除
        self._remove_member(new_main.data.pid)
        #从新写入内存中
        new_main.data.duty = ALLY_MAIN
        self.stream_assist(new_main)
        new_main.save(self.rpc_store)
        #新任命通知
        new_name = Ally.get_name(new_main.data.pid)
        params = dict(name=new_name)
        self.tell_online_members(language.ALLY_MAIN_NEW%params)
        self._add_in_log(ALLY_OP_DUTY, name, 0, 0, 0)
        return True, ALLY_OP_SUCCEED

    def quit(self, pid, name):
        """ 玩家自己退出同盟 """
        assist_obj = self.assist_objs.get(pid, None)
        if assist_obj.data.duty == ALLY_MAIN:
            return self._main_quit(pid, name)

        if not assist_obj:
            return False, errcode.EC_PLAYER_NO
        if common.current_time() - assist_obj.data.tJoin < ONE_DAY_TIME:
            return False, errcode.EC_QUIT_TIME_ERR

        self._remove_member(pid)
        params = dict(name = name)
        self.tell_online_members(language.ALLY_EXIT%params)
        self._add_in_log(ALLY_OP_EXIT, name, 0, 0, 0)
        return True, ALLY_OP_SUCCEED

    def members(self, is_other = False):
        """ 获取自己同盟某页成员"""
        onls = []
        dis_onls = []
        pids = self.get_member_pids()
        online_pids = self._mgr.rpc_player_mgr.get_online_ids(pids)
        p_dicts= dict((data['id'], data) for data in PlayerData.get_players_values(
                pids, ['name', 'level', 'tLogout'], store=self.rpc_store))

        for assist_data in self.members_list:
            try:
                t_dit = dict()
                pid = assist_data.pid
                if pid not in p_dicts:#玩家不存在
                    log.error(u'同盟(%s)玩家(%s)不存在', self.data.name, pid)
                    continue
                p_dic = p_dicts[pid]
                t_dit['pid'] = pid
                t_dit['n'] = p_dic['name']
                t_dit['lv'] = p_dic['level']
                t_dit['duty'] = assist_data.duty
                t_dit['pvp'] = 2000
                pvp = self._mgr._game.rpc_arena_mgr.get_rank(pid)
                if pvp:
                    t_dit['pvp'] = pvp
                #是不是查看其他的同盟 是就不加载exp和dt
                dis_onls.append(t_dit)
                if not is_other:
                    t_dit['exp'] = assist_data.exp
                    if pid in online_pids:
                        t_dit['dt'] = 0
                        dis_onls.remove(t_dit)
                        onls.append(t_dit)
                    else:
                        t_dit['dt'] = p_dic['tLogout']
            except:
                log.error("PlayerData.get_values is None pid:%s in ally.py func->members", assist_data.pid)
        if onls or dis_onls:
            onls = sor_member(is_other, True, onls)
            dis_onls = sor_member(is_other, False, dis_onls)
        mems = onls
        mems.extend(dis_onls)
        return mems

    def active_log(self):
        """ 获得同盟的日志活动 """
        return [obj.to_dict() for obj in  self.log_objs]

    def dismiss(self, pid):
        """ 解散同盟 """
        assist_obj = self.assist_objs.get(pid)
        if assist_obj.data.duty != ALLY_MAIN:
            return False, errcode.EC_NO_RIGHT
        if common.current_time() - self.data.tNew < ONE_DAY_TIME:
            return False, errcode.EC_QUIT_TIME_ERR
        params = dict(name=self.main_name())
        pids = []
        for assist_obj in self.assist_objs.itervalues():
            assist_obj.remove_member(self.rpc_store)
            self._mgr.detach_ally(assist_obj.data.pid)
            pids.append(assist_obj.data.pid)
        #玩家如果在线解除玩家的ally属性
        rpc_players = self._mgr.rpc_player_mgr.get_rpc_players(pids)
        for rpc_player in rpc_players:
            rpc_player.detach_ally(self.pack_msg(kick=True))
        #邮件通知所有同盟玩家
        self.mail_mgr.send_mails(pids, MAIL_REWARD, language.ALLY_DISMISS_TITLE,
                                     language.ALLY_DISMISS_CONTENT % params, [], notify_mgr=False)
        self.delete(self.rpc_store)
        for log_obj in self.log_objs:
            log_obj.delete(self.rpc_store)
        return True, ALLY_OP_SUCCEED

    def set_boss_time(self, pid):
        """ 设置BOSS战时间 """
        if pid in self.r_boss_t:
            return True, ALLY_OP_SUCCEED
        p_dict = Ally.get_name(pid)
        self.tell_online_members(language.ALLY_BOSS_TIME_CHANGE % p_dict)
        return False, errcode.EC_NO_RIGHT

    def level_up(self):
        """同盟升级"""
        self.data.level += 1
        level = self.data.level
        #通知在线成员->成就系统
        for assist_obj in self.assist_objs.itervalues():
            rpc_player = self._mgr.rpc_player_mgr.get_rpc_players([assist_obj.data.pid])
            if rpc_player:
                rpc_player[0].ally_pub(msg_define.MSG_ALLY_UP, level)

    def contribute(self, pid, name, exp):
        """ 添加贡献值 """
        assist_obj = self.assist_objs.get(pid)
        if assist_obj:
            assist_obj.data.exp += exp
            assist_obj.save(self.rpc_store, forced=True)
            self.save(self.rpc_store, forced=True)
            self._add_in_log(ALLY_OP_CONTRIBUTE, name, 0, exp, exp)

    def cat_enter(self, pid, vip):
        """ 招财猫进入 out_time是玩家上次退出游戏的时间"""
        assist_obj = self.assist_objs.get(pid)
        if not assist_obj:
            return False, errcode.EC_PLAYER_NO
        time = assist_obj.data.ct
        func = assist_obj.data.day_pass_cat
        self.handle_pass_day(time, func)
        c_max_num = int(get_max_cat(vip))
        return {ALLY_CAT_COUNT : c_max_num - assist_obj.data.cn}

    def cat(self, pid, vip):
        """ 招财一次 """
        assist_obj = self.assist_objs.get(pid)
        if not assist_obj:
            return False, errcode.EC_PLAYER_NO
        time = assist_obj.data.ct
        func = assist_obj.data.day_pass_cat
        self.handle_pass_day(time, func)
        c_max_num = int(get_max_cat(vip))
        if c_max_num > assist_obj.data.cn:
            assist_obj.data.cn += 1
            assist_obj.data.ct = common.current_time()
            assist_obj.save(self.rpc_store, forced=True)
            return True, None
        return False, errcode.EC_TIMES_FULL

    def grave_enter(self, pid, vip):
        """ 铭刻进入   out_time是玩家上次退出游戏的时间"""
        assist_obj = self.assist_objs.get(pid)
        if not assist_obj:
            return False, errcode.EC_PLAYER_NO
        time = assist_obj.data.gt
        func = assist_obj.data.day_pass_grave
        self.handle_pass_day(time, func)
        g_max_num = int(get_max_grave(vip))
        r_gn1 = g_max_num - assist_obj.data.gn1
        r_gn2 = assist_obj.data.gn2
        return {ALLY_GRAVE_COUNT1:r_gn1, ALLY_GRAVE_COUNT2 : r_gn2}

    def grave_have(self, pid, t, vip):
        """是不是有铭刻"""
        assist_obj = self.assist_objs.get(pid)
        if not assist_obj:
            return False, errcode.EC_PLAYER_NO
        time = assist_obj.data.gt
        func = assist_obj.data.day_pass_grave
        self.handle_pass_day(time, func)
        #非vip的铭刻
        if t in (ALLY_GRAVE1, ALLY_GRAVE2, ALLY_GRAVE3):
            g_max_num = int(get_max_grave(vip))
            if g_max_num > assist_obj.data.gn1:
                return True, None
            return False, errcode.EC_TIMES_FULL
            #vip的铭刻
        if t in (ALLY_VIP_GRAVE1,ALLY_VIP_GRAVE2, ALLY_VIP_GRAVE3):
            #vip的铭刻
            log.error('this function is not open please check allyGrave type')
        return False, errcode.EC_TIMES_FULL

    def grave(self, pid, t, vip):
        """ 一次铭刻  out_time是玩家上次退出游戏的时间 t是铭刻类型"""
        assist_obj = self.assist_objs.get(pid)
        if not assist_obj:
            return False, errcode.EC_PLAYER_NO
        #非vip的铭刻
        if t in (ALLY_GRAVE1, ALLY_GRAVE2, ALLY_GRAVE3):
            assist_obj.data.gn1 += 1
            assist_obj.data.gt = common.current_time()
            assist_obj.save(self.rpc_store, forced=True)
            return True, None
        #vip的铭刻
        if t in (ALLY_VIP_GRAVE1,ALLY_VIP_GRAVE2, ALLY_VIP_GRAVE3):
            #vip的铭刻
            log.error('this function is not open please check allyGrave type')
        return False, errcode.EC_TIMES_FULL

    def handle_pass_day(self, time, func):
        """ 超过一天清理招财的数据 """
        if common.is_pass_day(time):
            func()

    def _add_in_log(self, t, n1, pid, v1, v2):
        n2 = ""
        if t > 5:
            p_dict = self.rpc_store.load(TN_PLAYER, pid)
            if p_dict:
                n2 = p_dict['name']
        log_obj = AllyLog.new(self.data.id, t, n1, n2, v1, v2, self.rpc_store)
        self.log_objs.insert(0, log_obj)
        #设置日志的总数目为ALLY_LOG_MAX_NUM
        if len(self.log_objs) >= ALLY_LOG_MAX_NUM:
            log_list = self.log_objs[ALLY_LOG_MAX_NUM-1:]
            for i in xrange(len(log_list)):
                d_obj = self.log_objs.pop()
                d_obj.delete(self.rpc_store)


    def get_member_pids(self):
        return self.assist_objs.keys()

    def get_duty_by_pid(self, pid):
        assist_obj = self.assist_objs.get(pid, 0)
        if not assist_obj:
            return 0
        return assist_obj.data.duty

    def tell_online_members(self, msg):
        """ 通知所有在线的成员 """
        self._mgr._game.chat_mgr.ally_send(msg, self.get_member_pids())

    def main_name(self):
        return Ally.get_name(self.data.mainId)

    def pack_msg(self, kick=False, apply=False):
        """同盟更新结构"""
        if kick:
           return dict(kick=dict(ally=0))
        if apply:
           return {"apply":apply}

    @classmethod
    def get_name(cls, pid):
        return Game.rpc_player_mgr.get_name_by_id(pid)

    @classmethod
    def create_master(cls, mainId, gid, rpc_store):
        """ 帮主数据的创建 """
        querys = dict(pid=mainId)
        assist_dic = rpc_store.query_loads(TN_P_ALLY, querys)
        if assist_dic:
            assist_obj = AllyAssist.re_use(gid, mainId, ALLY_MAIN, assist_dic[0])
        else:
            assist_obj = AllyAssist.new(mainId, gid, ALLY_MAIN)
        return assist_obj

    @classmethod
    def new_apply_json(cls, pid, n, level, pvp):
        return {PID : pid, TIME : common.current_time(), NAME : n, LEVEL : level, PVP : pvp}

    #----------------------------------------------------------------------------
    #狩龙系统
    def crystal_enter(self, pid):
        """龙晶捐献进入"""
        _obj = self.assist_objs.get(pid)
        if not _obj:
            return False, errcode.EC_PLAYER_NO
        r_d = dict(alv=self.data.level, glory=_obj.data.glory)
        for t in BOAT_LEVEL_TYPES:
            lv_attr = 'lv%s'%t
            lv = getattr(self, lv_attr)
            exp_attr = 'exp%s'%t
            lv2exp = self._mgr.boat_lv2exp[t](lv)
            now_exp = getattr(self.data, exp_attr)
            r_d[lv_attr] = lv
            #等级大于最大等级的时候经验不再上升
            r_d[exp_attr] = lv2exp if lv >= self._mgr.boat_type_num[t] else now_exp - lv2exp
            #if lv > self._mgr.boat_types[t]:
            #    r_d[exp_attr] = sub_exp
            #else:
            #    r_d[exp_attr] = now_exp - sub_exp
        return True, r_d
        #return True, dict(alv=self.data.level, lv1=self.lv1, lv2=self.lv2, lv3=self.lv3, lv4=self.lv4,
        #        exp1=self.data.exp1, exp2=self.data.exp2, exp3=self.data.exp3, exp4=self.data.exp4,
        #        glory=_obj.data.glory)

    def _offer_lev_check(self, t):
        """捐献等级检测"""
        #当前同盟的等级是不是大于该类型的捐献等级
        attr_lv = 'lv%s'%t
        deco_types = self._mgr.deco_types.get(t)
        type_lev = getattr(self, attr_lv)
        res_obj = deco_types.get(type_lev)
        if self.data.level < res_obj.nlv:
            return False, errcode.EC_ALLY_LEVEL_LOW
        return True, None

    def crystal_offer(self, pid, t, n):
        """龙晶捐献"""
        t=int(t)
        if t not in BOAT_LEVEL_TYPES:
            return False, errcode.EC_VALUE
        rs, data = self._offer_lev_check(t)
        if not rs:
            return rs, data
        _obj = self.assist_objs.get(pid)
        attr_lv = 'lv%s'%t
        attr_exp = 'exp%s'%t
        #同盟增加的建设度
        ag = n*self._mgr.crystal_ally_v
        #玩家增加的建设度
        pg = n*self._mgr.crystal_player_v
        #捐献
        data_exp = getattr(self.data, attr_exp)
        #设置经验值
        now_exp = data_exp + ag
        setattr(self.data, attr_exp, now_exp)
        #设置等级
        lv = self._mgr.boat_exp2lv[t](now_exp)
        setattr(self, attr_lv, lv)
        self.save(self.rpc_store, forced=True)
        #得到当前的经验值
        lv2exp = self._mgr.boat_lv2exp[t](lv)
        #写入辅表对象的捐献个数
        _obj.data.cryn += n
        _obj.data.glory += pg
        _obj.save(self.rpc_store, forced=True)
        #等级大于最大等级的时候经验不再上升
        exp = lv2exp if lv >= self._mgr.boat_type_num[t] else now_exp - lv2exp
        return True, {'t':t, 'lv':lv, 'exp':exp, 'glory':_obj.data.glory}

    def glory_exchange_enter(self, pid):
        """声望兑换进入"""
        _obj = self.assist_objs.get(pid)
        if not _obj:
            return False, errcode.EC_PLAYER_NO
        return True, {"glory":_obj.data.glory}

    def pre_glory_exchange(self, pid, cid):
        """声望兑换预判断"""
        _obj = self.assist_objs.get(pid)
        if not _obj:
            return False, errcode.EC_PLAYER_NO
        res = Game.res_mgr.ally_exchanges.get(cid, None)
        if not res:
            return False, errcode.EC_NOFOUND
        if _obj.data.glory < res.glory:
            return False, errcode.EC_GLORY_NO
        return True, res.rid

    def glory_exchange(self, pid, cid):
        """声望兑换"""
        res = Game.res_mgr.ally_exchanges.get(cid, None)
        if not res:
            return False, errcode.EC_NOFOUND
        rs, glory = self.cost_glory(pid, res.glory)
        if not rs:
            return rs, glory
        return rs, {"glory":glory}

    def glory_rank_by_pid(self, pid, gl=False):
        """gl是不是全局"""
        r_d = {}
        _obj = self.assist_objs.get(pid)
        if _obj:
            r_d['rk'] = self._glorys.index(pid) + 1
            r_d['n'] = Ally.get_name(pid)
            r_d['dt'] = _obj.data.duty
            r_d['gy'] = _obj.data.glory
            if gl:
                r_d['an'] = self.data.name
        return r_d

    def glory_rank(self):
        """声望排名"""
        r_l = []
        for pid in self._glorys:
            r_d = self.glory_rank_by_pid(pid)
            if r_d:
                r_l.append(r_d)
        return True, r_l

    def get_boat_init_params(self):
        us1 = self._mgr.deco_types.get(BOAT_HP).get(self.lv1).us
        us2 = self._mgr.deco_types.get(BOAT_POW).get(self.lv2).us
        us3 = self._mgr.deco_types.get(BOAT_CD).get(self.lv3).us
        us4 = self._mgr.deco_types.get(BOAT_DELAY).get(self.lv4).us
        return us1, us2, us3, us4

    def get_boat_type_level(self, t):
        if t not in BOAT_LEVEL_TYPES:
            return errcode.EC_VALUE
        attr = "lv%s"%t
        return getattr(self, attr)

    def get_glory(self, pid):
        if pid not in self.assist_objs:
            return False, errcode.EC_PLAYER_NO
        _obj = self.assist_objs.get(pid)
        return True, _obj.data.glory

    def cost_glory(self, pid, glory):
        """
        消耗声望
        """
        if pid not in self.assist_objs:
            return False, errcode.EC_PLAYER_NO
        _obj = self.assist_objs.get(pid)
        if _obj.data.glory < glory:
            return False, errcode.EC_VALUE
        _obj.data.glory -= glory
        _obj.save(self.rpc_store, forced=True)
        return True, _obj.data.glory


    #----------------------------------------------------------------------------

    def gm_change_duty(self, pid, duty):
        """
        改变职责
        pid1 是操作者
        pid2 是被操作者
        """
        obj = self.assist_objs.get(pid)
        if not obj:
            return u"玩家不在该同盟"
        if ALLY_MAIN == duty:
            l = self.duty2objs.get(ALLY_MAIN, None)
            if l:
                m = l[0]
                return u"先免去帮主(pid:%s)的职务再任命帮主"%m.data.pid
        rs, code = self._change_duty(0, 'gm易职', obj, duty)
        if not rs:
            return u"错误码%s"%code
        if ALLY_MAIN == duty:
            self.data.mainId = pid
            self.save(self.rpc_store, forced=True)
        return u"职务任命成功"

