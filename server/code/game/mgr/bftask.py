#!/usr/bin/env python
# -*- coding:utf-8 -*-


import time
import bisect
import random

from game import BaseGameMgr
from game.base import common
from game.base import errcode
from game.base.msg_define import MSG_LOGON, MSG_BF_BESTBOX
from game.base.constant import ( BF_BOX_REWARD_V,
    TT_OFFER, BF_TYPE_EXP, BF_TYPE_EXP_V, BF_BOX_MAX,
    BF_BOX_MAX_V, BF_BOX_NEEDEXP, BF_BOX_NEEDEXP_V, BF_BOX_REWARD,
    STATUS_BF_BEST_COUNT, BF_BOX_BEST, BF_BOX_BEST_V, PLAYER_ATTR_BFTASK,
    BF_RE_COIN2, BF_RE_COIN2_V,
    BF_RE_TIME, BF_RE_TIME_V, BF_FINSHIN_COIN1, BF_FINSHIN_COIN1_V,
    BF_RENUM_MAX, BF_RENUM_MAX_V, BFTASK_CAN_ACCEPT, BFTASK_ALREADY_ACCEPT,
    BFTASK_TYPE_FINISH, BF_RE_FREE, BFTASK_NUM_MAX, BF_RE_SYS, BF_RE_PASS,
    BF_FINSHIN_VIP, BF_FINSHIN_VIP_V, BF_RE_ALLCOIN2, BF_RE_ALLCOIN2_V,
    BF_RE_NUM, BF_RE_NUM_V,
)
from corelib import log, spawn, sleep, RLock
from game.glog.common import COIN_BFTASK_RESET, COIN_BFTASK_FINISH, ITEM_ADD_BFTASKBOX


#刷新方式（客户端）
#免费刷新
RESET_FREE = 1 #包括两种
#元宝刷新
RESET_COIN2 = 2
#全紫刷新
RESET_ALL = 3

#刷新类型
RESET_TYPE_FREE = 1
RESET_TYPE_SYS = 2
RESET_TYPE_COIN = 3
RESET_TYPE_ALL = 5

#紫色品质
QUALITY_MAX = 3

class BfTaskMgr(BaseGameMgr):
    """ 兵符任务管理器 """
    def __init__(self, game):
        super(BfTaskMgr, self).__init__(game)

    def start(self):
        self._game.player_mgr.sub(MSG_LOGON, self.player_logon)
        self.free_re = self.fetch_res(BF_RE_NUM, BF_RE_NUM_V)
        self.bf_boxes = self.fetch_res(BF_BOX_MAX, BF_BOX_MAX_V)



    def player_logon(self, player):
        """ 玩家登陆，初始化兵符数据 """
        if player:
            self.init_player_bftask(player)

    def init_player_bftask(self, player):
        """ 获取玩家兵符任务数据 """
        player_bftask = getattr(player.runtimes, PLAYER_ATTR_BFTASK, None)
        if player_bftask is None:
            player_bftask = PlayBfTask(player)
            player_bftask.load()
            setattr(player.runtimes, PLAYER_ATTR_BFTASK, player_bftask)
        return player_bftask

    def bf_task_enter(self, player):
        """ 进入兵符任务 """
        player_bftask = self.init_player_bftask(player)
        return player_bftask.enter()
    
    def bf_task_re(self, player, type):
        """ 刷新兵符任务 """
        player_bftask = self.init_player_bftask(player)
        return player_bftask.reset(type)

    def bf_task_box(self, player):
        """ 打开兵符宝箱 """
        player_bftask = self.init_player_bftask(player)
        return player_bftask.open_box()

    def bf_task_get(self, player, index):
        """ 接兵符任务 """
        player_bftask = self.init_player_bftask(player)
        return player_bftask.bf_task_get(index)
    
    def bf_finish(self, player):
        """ 立即完成的兵符任务 """
        player_bftask = self.init_player_bftask(player)
        return player_bftask.bf_finish()

    def fetch_res(self, key, value):
        res_num = self._game.setting_mgr.setdefault(key, value)
        return common.make_lv_regions(res_num)

class BfTaskData(object):

    def __init__(self):
        self.init()

    def init(self):
        #当前可接兵符任务tids(基础表任务ids)(tids, json)
        self.tids = ''
        #当前兵符任务的品质(qs, json)
        self.qs = ''
        #兵符任务当状态(ss, json)1=可接,2=已接,3=完成
        self.ss = ''
        #任务奖励的经验(exps, json)0=未接任务和已接任务，非0=完成任务
        self.exps = ''
        #当前已接的兵符任务的任务id(作用判断是否已接任务)(btid, int)
        self.btid = 0
        #当前获得的经验点数(exp, int)
        self.exp = 0
        #刷新生成开始时间(st, time)
        self.st = 0
        #当天第一次兵符任务接收时间(ft, time)
        self.ft = 0
        #当天免费剩余刷新次数(n1, int)
        self.n1 = 0
        #当天剩余兵符宝箱的数目(boxes, int)
        self.bs = 0
        #当天兵符宝箱上限(bsm, int)
        self.bsm = 0
        #兵符刷新出现的类型(bt, int)1=系统免费,2=根据时间生成
        self.bt = 0

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
        player.play_attr.update_attr({PLAYER_ATTR_BFTASK:self.to_dict()})

def _wrap_lock(func):
    def _func(self, *args, **kw):
        with self._lock:
            return func(self, *args, **kw)
    return _func

class PlayBfTask(object):
    """ 玩家兵符任务 """
    def __init__(self, player):
        self.player = player
        #兵符任务
        self.bfTaskData = None
        self._lock = RLock()

    def __getstate__(self):
        return self.bfTaskData

    def __setstate__(self, data):
        self.bfTaskData = data

    def uninit(self):
        self.player = None
        self.bfTaskData = None

    def load(self, player = None):
        """ 加载数据 """
        #兵符任务数据导入
        tObjDict = self.player.play_attr.get(PLAYER_ATTR_BFTASK)
        oBfTaskData = BfTaskData()
        if tObjDict:
            oBfTaskData.update(tObjDict)
        else:
            vip = self.player.data.vip
            vip_max = self.player._game.bftask_mgr.bf_boxes(vip)
            oBfTaskData.ft = int(time.time())
            oBfTaskData.n1 = self.fetch_bf_renum
            oBfTaskData.bs = vip_max
            oBfTaskData.bsm = vip_max
            oBfTaskData.bt = BF_RE_PASS
        self.bfTaskData = oBfTaskData
        #判断是否更新
        self.handle_pass_day()

    def save(self, store):
        """ 保存玩家数据 """
        self.bfTaskData.update_attr(self.player)

    def copy_from(self, player):
        """拷贝角色数据"""
        player_bftask = getattr(player.runtimes, PLAYER_ATTR_BFTASK)
        if player_bftask:
            self.bfTaskData = BfTaskData()
            adict = player_bftask.bfTaskData.to_dict()
            self.bfTaskData.update(adict = adict)

    def handle_pass_day(self):
        """ 处理超过一天(超过则更新数据) """
        #判断是否已过一天
        if common.is_pass_day(self.bfTaskData.ft):
            #是否是兵符任务且是否过期更新
            btid = 0
            for t in self.player.task.tasks.itervalues():
                tResTask = self.player._game.res_mgr.tasks.get(t.data.tid)
                if tResTask.type == TT_OFFER:
                    btid = t.data.id
                    accept_tid = t.data.tid
                    break
            accept_index = -1
            if btid:
                #已接任务不处理,其他任务刷新
                for index, state in enumerate(self.bfTaskData.ss):
                    if state == BFTASK_ALREADY_ACCEPT:
                        accept_index = index
                        break
                self._produce_bf_task(BF_RE_PASS, accept_index)
                if accept_index in self.bfTaskData.tids and accept_tid != self.bfTaskData.tids[accept_index]:
                    self.bfTaskData.tids[accept_index] = accept_tid
            else:
                #无任务全部刷新
                self.bfTaskData.tids = []
                self.bfTaskData.ss = []
                self.bfTaskData.qs = []
                self.bfTaskData.exps = []

            boxes = self._get_box_nums()
            self.bfTaskData.ft = int(time.time())
            #兵符宝箱的累计计算
            self.bfTaskData.bs = boxes
            self.bfTaskData.bsm = boxes
            self.bfTaskData.btid = btid
            self.bfTaskData.n1 = self.fetch_bf_renum
            self.bfTaskData.bt = BF_RE_PASS
            return True
        return False

    def _get_box_nums(self):
        """ 获取兵符宝箱的累计计算 """
        vip = self.player.data.vip
        base = self.player._game.bftask_mgr.bf_boxes(0)
        vip_max = self.player._game.bftask_mgr.bf_boxes(vip)
        pass_day = common.get_days(self.bfTaskData.ft)
        nums = base + self.bfTaskData.bs
        while pass_day > 1:
            nums += base
            pass_day -= 1
        if nums > vip_max:
            nums = vip_max
        return nums

    def enter(self):
        """ 进入兵符任务 """
        #是否有兵符宝箱
        tRs = {}
        if self.bfTaskData.bs > 0 and self.bfTaskData.exp >= self.fetch_bfbox_needexp:
            tRs['isBox'] = 1
        else:
            tRs['isBox'] = 0
        tRs['exp'] = self.bfTaskData.exp
        tRs['boxes'] = self.bfTaskData.bs
        #有产生刷新兵符时间时处理
        if self.bfTaskData.st:
            now = int(time.time())
            t = now - self.bfTaskData.st
            num = int(t / self.fetch_bf_retime)
            add_time = t % self.fetch_bf_retime
            self.bfTaskData.n1 += num
            if self.bfTaskData.n1 >= self.fetch_bfrenum_max:
                self.bfTaskData.n1 = self.fetch_bfrenum_max
                self.bfTaskData.st = 0
            else:
                if num:
                    self.bfTaskData.st += num * self.fetch_bf_retime
                tRs['times'] = self.fetch_bf_retime - add_time
        #没有任务，产生任务
        if not self.bfTaskData.tids:
            self._produce_bf_task(self.bfTaskData.bt)
        else:
            #有任务，判断未接任务的解锁条件已过期 过期重新产生新的任务其他不变
            ss = self.bfTaskData.ss[:]
            del_indexs = []
            for index,status in enumerate(ss):
                if status != BFTASK_CAN_ACCEPT:
                    continue
                tid = self.bfTaskData.tids[index]
                res_task = self.player._game.res_mgr.tasks.get(tid)
                max_level = res_task.unlock_level[1]
                if max_level and max_level <= self.player.data.level:
                    unlock_tasks = self._get_unlock_tasks()
                    if not unlock_tasks:
                        del_indexs.append(index)
                        continue
                    #产生新任务
                    tRanBfTask = random.choice(unlock_tasks)
                    self.bfTaskData.tids[index] = tRanBfTask.id
            if del_indexs:
                del_indexs.sort(reverse=True)
                for del_index in del_indexs:
                    self.bfTaskData.tids.pop(del_index)
                    self.bfTaskData.qs.pop(del_index)
                    self.bfTaskData.ss.pop(del_index)
                    self.bfTaskData.exps.pop(del_index)
        tRs['bMax'] = self.bfTaskData.bsm
        tRs['exps'] = self.bfTaskData.exps
        if self.bfTaskData.btid:
            self._err_safe()
        data = self._pack_data()
        data.update(tRs)
        return True, data
    
    def _err_safe(self):
        """ 防范代码 """
        #防范代码 判断当期接的悬赏任务是否是 悬赏令界面中所接任务
        #如不是将悬赏令任务界面更新为 接的悬赏领任务
        t = self.player.task.tasks.get(self.bfTaskData.btid)
        if t:
            accept_tid = t.data.tid
            try:
                accept_index = self.bfTaskData.ss.index(BFTASK_ALREADY_ACCEPT)
                if self.bfTaskData.tids[accept_index] != accept_tid:
                    self.bfTaskData.tids[accept_index] = accept_tid
            except:
                accept_index = 0
                if self.bfTaskData.tids:
                    self.bfTaskData.tids[accept_index] = accept_tid
                    self.bfTaskData.ss[accept_index] = BFTASK_ALREADY_ACCEPT
                else:
                    self.bfTaskData.tids = [accept_tid]
                    self.bfTaskData.qs = [0]
                    self.bfTaskData.ss = [BFTASK_ALREADY_ACCEPT]
                    self.bfTaskData.exps = [0]
    
    def _pack_data(self):
        """ 处理特殊数据 """
        data = {}
        data['tids'] = self.bfTaskData.tids
        data['qualitys'] = self.bfTaskData.qs
        data['status'] = self.bfTaskData.ss
        data['n1'] = self.bfTaskData.n1
        return data

    def reset(self, type):
        """ 刷新兵符任务 """
        if type < RESET_FREE or type > RESET_ALL:
            return False, errcode.EC_VALUE
        #保留已接的任务
        accept_index = -1
        if self.bfTaskData.btid:
            t = self.player.task.tasks.get(self.bfTaskData.btid)
            if t:
                try:
                    accept_index = self.bfTaskData.ss.index(BFTASK_ALREADY_ACCEPT)
                except:
                    pass
            else:
                self.bfTaskData.btid = 0
        data = {}
        if type == RESET_FREE:
            if self.bfTaskData.n1 <= 0:
                return False, errcode.EC_BFTASK_NOFREE
            self.bfTaskData.n1 -= 1
            self._produce_bf_task(self.bfTaskData.bt, accept_index)
        else:
            rs, data = self._rest_coin2(type, accept_index)
            if not rs:
                return rs, data
        if not self.bfTaskData.n1 or self.bfTaskData.bt == BF_RE_SYS:
            self.bfTaskData.bt = BF_RE_SYS
            self.bfTaskData.st = int(time.time())
            data['times'] = self.fetch_bf_retime
        tRs = self._pack_data()
        tRs.update(data)
        return True, tRs

    def _rest_coin2(self, type, accept_index):
        """ 付费的刷新(元宝，全紫) """
        if type == RESET_COIN2:
            coin2 = self.fetch_bf_recoin2
        else:
            coin2 = self.fetch_bf_all
        if not self.player.cost_coin(aCoin2=coin2, log_type=COIN_BFTASK_RESET):
            return False, errcode.EC_COST_ERR
        if type == RESET_COIN2:
            if self.bfTaskData.n1 > 0:
                return False, errcode.EC_BFTASK_NOCOIN
            self._produce_bf_task(RESET_TYPE_COIN, accept_index)
        else:
            self._produce_bf_task(RESET_TYPE_ALL, accept_index)
        tRs = self.player.pack_msg_data(coin=True)
        return True, tRs

    def _get_unlock_tasks(self):
        """ 根据玩家等级获取所有解锁兵符任务 """
        res_bftask_unlocks = self.player._game.res_mgr.bf_task_by_unlock
        tPlayLevel = self.player.data.level
        tAllBfTask = []
        for uplock, tBfTasks in res_bftask_unlocks.iteritems():
            if tPlayLevel < uplock[0] or tPlayLevel >= uplock[1]:
                continue
            if uplock[2] and uplock[2] not in self.player.task.tid_bm:
                continue
            tAllBfTask.extend(tBfTasks)
        return tAllBfTask

    def _produce_bf_task(self, type, accept_index=-1):
        """
        产生任务 接的任务不刷新
         type=1 免费刷新
         type=2 系统时间生成的免费刷新
         type=3 元宝刷新
         type=4 全紫色的刷新(另类)
         accep_index=-1  无接的任务 非-1 接任务的位置
        """
        unlock_tasks = self._get_unlock_tasks()
        ran_tids = []
        ran_qss = []
        ss = []
        self.bfTaskData.exps = []
        if unlock_tasks:
            for i in xrange(BFTASK_NUM_MAX, 0, -1):
                #随任务
                tRanBfTask = random.choice(unlock_tasks)
                ran_tids.append(tRanBfTask.id)
                #状态
                ss.append(BFTASK_CAN_ACCEPT)
                #全紫色
                if type == RESET_TYPE_ALL:
                    ran_qss.append(QUALITY_MAX)
                    continue
                #随品质
                k = (type, i)
                tResBfRate = self.player._game.res_mgr.get_tp_by_rate(k)
                ran_qss.append(tResBfRate.quality)
            self.bfTaskData.exps = BFTASK_NUM_MAX * [0]
        self._handle_accept_task(accept_index, ran_tids, ran_qss, ss)
        if type == BF_RE_PASS:
            self.bfTaskData.bt = BF_RE_FREE

    def _handle_accept_task(self, accept_index, ran_tids, ran_qss, ss):
        """ 处理已接的任务 """
        if accept_index != -1:
            if accept_index in ran_tids:
                ran_tids[accept_index] = self.bfTaskData.tids[accept_index]
                ran_qss[accept_index] = self.bfTaskData.qs[accept_index]
                ss[accept_index] = self.bfTaskData.ss[accept_index]
            else:
                ran_tids.append(self.bfTaskData.tids[accept_index])
                ran_qss.append(self.bfTaskData.qs[accept_index])
                ss.append(self.bfTaskData.ss[accept_index])
            big = len(ran_tids) - BFTASK_NUM_MAX
            if big > 0:
                ran_tids = ran_tids[big:]
                ran_qss = ran_qss[big:]
                ss = ss[big:]
        self.bfTaskData.tids = ran_tids
        self.bfTaskData.qs = ran_qss
        self.bfTaskData.ss = ss


    @_wrap_lock
    def open_box(self):
        """ 打开兵符宝箱 """
        if self.bfTaskData.exp < self.fetch_bfbox_needexp:
            return False, errcode.EC_BFTASK_EXPENOUGH
        if self.bfTaskData.bs <= 0:
            return False, errcode.EC_BFTASK_NOBOX
        if self.player.bag.bag_free() <= 0:
            return False, errcode.EC_BAG_FULL
        #获取兵符极品出现次数
        bfBestCount = self.player._game.rpc_status_mgr.get(STATUS_BF_BEST_COUNT)
        if not bfBestCount:
            bfBestCount = 0
            self.player._game.rpc_status_mgr.set(STATUS_BF_BEST_COUNT, bfBestCount)
        #获取奖励id
        tResBfRewards = self.fetch_bf_reward
        l = tResBfRewards.keys()
        l.sort()
        tIndex = bisect.bisect_right(l, bfBestCount) -1
        tBfRid = tResBfRewards[l[tIndex]]
        #获取奖励物品
        tRw = self.player._game.reward_mgr.get(int(tBfRid))
        tName, tRsItems = tRw.reward(params=self.player.reward_params(), back_name=True)
        if not self.player.bag.can_add_items(tRsItems):
            return False, errcode.EC_BAG_FULL
        #是否极品装备
        if tName in self.fetch_bf_best[tIndex]:
            self.player._game.rpc_status_mgr.inc(STATUS_BF_BEST_COUNT)
            self.player.pub(MSG_BF_BESTBOX, tRsItems)
        bag_item = self.player.bag.add_items(tRsItems, log_type=ITEM_ADD_BFTASKBOX)
        #更新兵符任务属性
        self.bfTaskData.bs -= 1
        self.bfTaskData.exp -= self.fetch_bfbox_needexp
        return True, bag_item.pack_msg()

    def bf_task_get(self, index):
        """ 接兵符任务 """
        #已接兵符任务返回
        if self.bfTaskData.btid:
            return False, errcode.EC_BFTASK_ACCEPTED
        try:
            tid = self.bfTaskData.tids[index]
        except:
            return False, errcode.EC_VALUE
        #判断是否已完成
        if self.bfTaskData.ss[index] == BFTASK_TYPE_FINISH:
            return False, errcode.EC_BFTASK_FINISH
        #获取兵符任务的奖励
        tkey = (tid, self.bfTaskData.qs[index])
        tResBfTask = self.player._game.res_mgr.bf_task_by_tbid.get(tkey)
        if not tResBfTask:
            return False, errcode.EC_NORES
        #添加兵符任务至列表
        tBfTask = self.player.task.add_task(tid, aRid=tResBfTask.rid)
        if not tBfTask:
            return False, errcode.EC_BFTASK_NOLEVEL
        #更新属性
        self.bfTaskData.ss[index] = BFTASK_ALREADY_ACCEPT
        self.bfTaskData.btid = tBfTask.data.id
        return True, {'task':tBfTask.to_dict()}

    def bf_finish(self):
        """ 立即完成 """
        if not self.bfTaskData.btid:
            return False, errcode.EC_BFTASK_NOLEVEL
        if self.player.data.vip < self.fetch_bffinish_vip:
            return False, errcode.EC_NOVIP
        if not self.player.cost_coin(aCoin1=self.fetch_bf_finishcoin1, log_type=COIN_BFTASK_FINISH):
            return False, errcode.EC_COST_ERR
        rs, bag_items = self.player.task.task_complete(self.bfTaskData.btid)
        if not rs:
            return rs, bag_items
        data = bag_items.pack_msg(coin=True)
        return rs, data

    @property
    def fetch_bf_finishcoin1(self):
        return self.player._game.setting_mgr.setdefault(BF_FINSHIN_COIN1, BF_FINSHIN_COIN1_V)

    @property
    def fetch_bf_retime(self):
        return self.player._game.setting_mgr.setdefault(BF_RE_TIME, BF_RE_TIME_V)

    @property
    def fetch_bffinish_vip(self):
        return self.player._game.setting_mgr.setdefault(BF_FINSHIN_VIP, BF_FINSHIN_VIP_V)

    @property
    def fetch_bf_recoin2(self):
        return self.player._game.setting_mgr.setdefault(BF_RE_COIN2, BF_RE_COIN2_V)

    @property
    def fetch_bf_all(self):
        return self.player._game.setting_mgr.setdefault(BF_RE_ALLCOIN2, BF_RE_ALLCOIN2_V)

    @property
    def fetch_bfbox_needexp(self):
        return self.player._game.setting_mgr.setdefault(BF_BOX_NEEDEXP, BF_BOX_NEEDEXP_V)

    @property
    def fetch_bfrenum_max(self):
        return self.player._game.setting_mgr.setdefault(BF_RENUM_MAX, BF_RENUM_MAX_V)

    @property
    def fetch_bf_exp(self):
        tValue = self.player._game.setting_mgr.setdefault(BF_TYPE_EXP, BF_TYPE_EXP_V)
        return tValue.split('|')

    @property
    def fetch_bf_reward(self):
        tValue = self.player._game.setting_mgr.setdefault(BF_BOX_REWARD, BF_BOX_REWARD_V)
        tValues = tValue.split('|')
        tRsDict = {}
        for t in tValues:
            attrs = t.split(':')
            tRsDict[int(attrs[0])] = attrs[1]
        return tRsDict

    @property
    def fetch_bf_best(self):
        tValue = self.player._game.setting_mgr.setdefault(BF_BOX_BEST, BF_BOX_BEST_V)
        tValues = tValue.split('|')
        tRsDict = {}
        for idex, t in enumerate(tValues):
            tRsDict[idex] = t.split(',')
        return tRsDict

    @property
    def fetch_bf_renum(self):
        vip = self.player.data.vip
        return self.player._game.bftask_mgr.free_re(vip)
