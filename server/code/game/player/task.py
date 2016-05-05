#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time
import bisect
import random

from corelib import log, spawn, spawn_later, data

from game import pack_msg, Game
from game.base import common
from game.store import StoreObj, GameObj
from game.store.define import TN_P_TASK
from game.base.constant import (PLAYER_ATTR_TASKS, PLAYER_ATTR_TASK,
    TUL_EQUIP, TUL_ITEM, TUL_LEVEL, TUL_ROLE, TUL_TASK, TT_OFFER,
    GUIDE_PLAYER_CLEAR, GUIDE_PLAYER_CLEAR_V, NEW_PLAYER_CMD, NEW_PLAYER_CMD_V,
    BFTASK_ALREADY_ACCEPT, TASK_BFTASK_FINISH, TASK_ZXTASK_FINISH, TASK_YCTASK_FINISH,
    BFTASK_TYPE_FINISH, TT_MAIN, TT_BRANCH, TT_HIDE
    )
from game.glog.common import PL_ERROR, ITEM_ADD_TASK, PL_TASK_ACCEPT, PL_CHAPTER
from game.base.msg_define import (MSG_UPGRADE, MSG_CHAPTER_FINISH, MSG_TASK_COMPLETE,
    MSG_TASK_FINISH, MSG_ACHI_CHAPTER_FINISH,
)
from  game.base import errcode

import language

class PlayerTask(object):
    """ 玩家任务类 """
    def __init__(self, player):
        self.player = player
        #执行中的任务
        self.tasks = {} #task_id:task
        self.tids = {} #tid:task
        #IntBiteMap 保存完成的任务的tid 不包括兵符任务
        self.tid_bm = data.IntBiteMap()
        #正在做的任务
        self.run_task = None

        #玩家任务属性相关数据(保存完成次数)
        self.p_attr_task = {}

        self.player.sub(MSG_UPGRADE, self._handle_upgrade)
        self.player.sub(MSG_TASK_COMPLETE, self._handle_complete_task)
        if 0:
            from .player import Player
            self.player = Player()

    def uninit(self):
        self.player = None
        #执行中的任务
        self.tasks = {} #task_id:task
        self.tids = {} #tid:task
        #正在做的任务
        self.run_task = None
        #玩家任务属性相关数据(保存完成次数)
        self.p_attr_task = {}

    def load(self):
        """ 加载数据(执行中的任务) """
        store = self.player._game.rpc_store
        end_tasks = self.player.play_attr.setdefault(PLAYER_ATTR_TASKS, '')
        self.tid_bm.from_base64(end_tasks)

        querys = dict(pid=self.player.data.id, status=1)
        tasks = store.query_loads(TN_P_TASK, querys)
        for data in tasks:
            tid = data['tid']
            if tid in self.tids:#重复记录...
                log.warn('[task]player(%s) task(%s) repeat', self.player.data.id, tid)
                spawn(store.delete, TN_P_TASK, data['id'])
                continue

            task = Task.new_by_dict(data)
            if not task:
                log.warn('[task]res_task not found:%s', tid)
                continue
            if tid in self.tid_bm:#记录异常
                self.player.log_task(tid, data['id'], t=PL_ERROR)

            self.tasks[data['id']] = task
            self.tids[tid] = task
            if task.data.isRun:
                self.run_task = task

        if not end_tasks:#新玩家
            #log.debug(u'new player accept_tasks')
            def _fun():
                if not (self.player and self.player.logined):
                    return
                self.accept_tasks(TUL_LEVEL, 1)
            spawn_later(2, _fun)


        init_data = {TASK_BFTASK_FINISH:0, TASK_ZXTASK_FINISH:0, TASK_YCTASK_FINISH:0}
        self.p_attr_task = self.player.play_attr.setdefault(PLAYER_ATTR_TASK, init_data)
        if not self.p_attr_task:
            self.p_attr_task = init_data

    def save(self):
        """ 保存至数据库 """
        store = self.player._game.rpc_store
        for key in self.tids.keys():
            if key not in self.tids:
                continue
            task = self.tids[key]
            task.save(store)
        self.player.play_attr.set(PLAYER_ATTR_TASK, self.p_attr_task)

    def update_tid_bm(self):
        self.player.play_attr.set(PLAYER_ATTR_TASKS, self.tid_bm.to_base64())

    def clear(self):
        store = self.player._game.rpc_store
        for task in self.tids.itervalues():
            task.delete(store)
        self.tids.clear()
        self.tasks.clear()
        self.tid_bm.from_string('')
        self.update_tid_bm()

    def clear_tids(self, ids):
        """ 从已完成任务列表中,清除掉特定的id """
        for i in ids:
            self.tid_bm.delete(i)
        self.update_tid_bm()

    def copy_from(self, task):
        self.clear()
        self.tid_bm.from_string(task.tid_bm.to_string())
        self.update_tid_bm()
        for t in task.tids.itervalues():
            ni = Task(adict=t.data.to_dict())
            ni.data.pid = self.player.data.id
            ni.data.id = None
            ni.save(self.player._game.rpc_store)
        self.load()

    def to_dict(self):
        """ 获取玩家任务 """
        return dict(tasks=[r.to_dict() for r in self.tids.itervalues()],
            taskIds=self.tid_bm.to_base64())

    def turn_to(self, tid, auto_complete):
        """ 转到特定任务
        如果tid比当前完成的任务id小,会清理已完成任务列表内容
        """
        self.tid_bm.trunate(tid-1)
        data = self.tid_bm.to_string()
        self.clear()
        self.tid_bm.from_string(data)
        if auto_complete:
            for i in xrange(1, tid):
                self.tid_bm.insert(i)
        self.update_tid_bm()
        self.add_task(tid)

    def get_res_task(self, aId):
        """ 获取任务基础数据 """
        return self.player._game.res_mgr.tasks.get(aId)

    def get_task(self, id):
        """ 获取执行中的任务 """
        return self.tasks.get(id)

    def get_task_by_tid(self, tid):
        return self.tids.get(tid)

    def update_task(self, aTask):
        """ 更新任务数据 """
        aTask.modify()

    def add_task_by_res(self, res_task, aRid=None, forced=False):
        if not res_task or (not forced and not self.can_add(res_task)):
            return
        if res_task.id in self.tids:#已经存在
            return
        task = Task.new_by_res(res_task)
        task.data.pid = self.player.data.id
        if aRid:
            task.data.rid = aRid
        if not self.tids:
            self.task_active(task)
        self.tids[res_task.id] = task
        task.save(self.player._game.rpc_store)
        self.tasks[task.data.id] = task
        self.player.log_task(task.data.tid, task.data.id, t=PL_TASK_ACCEPT)
        return task

    def add_task(self, aTid, aRid=None, pid=0, forced=False, send_msg=False):
        """ 创建新任务
        aRid:奖励id, 有则是兵符符任务
        pid:父任务id
        send_msg:是否发送,并且用于表示延迟秒数
        """
        res_task = self.get_res_task(aTid)
        if not res_task:
            return
        task = self.add_task_by_res(res_task, aRid=aRid, forced=forced or bool(pid))
        if pid:
            if not task:
                log.error(u'(%s)玩家任务(%s)完成后,接后续任务(%s)失败:%s, %s',
                    self.player.data.id,
                    pid,
                    res_task.id,
                    self.tid_bm.to_base64(), self.tids.keys())
            else:
                self.task_active(task)
        if not task:
            return
        if send_msg:#延迟发送,保证先完成任务再发下一任务
            if type(send_msg) is bool:
                self.send_accept_tasks([task])
            else:
                spawn_later(float(send_msg), self.send_accept_tasks, [task])
        return task

    def del_task(self, task):
        try:
            self.tasks.pop(task.data.id)
            self.tids.pop(task.data.tid)
            task.delete(self.player._game.rpc_store)
        except:
            log.log_except()#_better=1)

    def can_add(self, res_task):
        """ 是否可以接任务 """
        if res_task is None or \
            res_task.id in self.tids or \
            res_task.id in self.tid_bm or \
           (res_task.parent and res_task.parent.id not in self.tid_bm):
            return False
        if not res_task.unlock:
            return True
        #检查解锁条件
        if (res_task.unlock_level and
                not (res_task.unlock_level[0] <= self.player.data.level < res_task.unlock_level[1])) or \
            (res_task.unlock_roles and
                [rid for rid in res_task.unlock_roles if rid not in self.player.roles]) or \
            (res_task.unlock_tasks and
                [tid for tid in res_task.unlock_tasks if tid not in self.tid_bm]) or \
            (res_task.unlock_equs and
                [eid for eid in res_task.unlock_equs if not self.player.bag.has_equip(eid)]) or \
            (res_task.unlock_objs and
                [oid for oid,c in res_task.unlock_objs if not self.player.bag.has_item(oid, c)]):
            return False
        return True

    def accept_tasks(self, unlock_type, id_or_level):
        """ 主动接满足条件的任务 """
        rs = []
        def _add(res_task):
            task = self.add_task_by_res(res_task)
            if task:
                rs.append(task)
        task_mgr = self.player._game.task_mgr
        #根任务
        for tid, task in task_mgr.nolimits.iteritems():
            if tid in self.tids or tid in self.tid_bm:
                continue
            _add(task)
        #隐藏、支线任务
        tasks = task_mgr.get_tasks(unlock_type, id_or_level)
        for task_or_count in tasks:
            if isinstance(task_or_count, (tuple, list)):
                task, count = task_or_count
            else:
                task = task_or_count
            _add(task)
        if rs:
            self.send_accept_tasks(rs)
        return rs

    def send_accept_tasks(self, tasks):
        """ 主动推送 """
        if self.player is None or not self.player.logined:
            return
        #log.debug('send_accept_tasks:%s', str([(t.data.tid, t.data.id) for t in tasks]))
        resp_f = 'taskPush'
        self.player.send_msg(pack_msg(resp_f, 1, data=[t.to_dict() for t in tasks]))

    def task_update(self, aId, aStep):
        """ 更新玩家任务状态"""
        tTask = self.get_task(aId)
        if not tTask:
            return False
        tTask.data.step = aStep
        self.update_task(tTask)

    def task_active(self, task):
        """ 激活任务 """
        if self.run_task ==  task:
            return
        if self.run_task:
            self.run_task.data.isRun = 0
            self.update_task(self.run_task)
        self.run_task = task
        task.data.isRun = 1
        self.update_task(task)

    @property
    def current_chapter(self):
        return self.player._game.res_mgr.chapters.get(self.player.data.chapter)

    @property
    def current_tid(self):
        return self.run_task.data.tid if self.run_task else 0

    @property
    def current_step(self):
        return self.run_task.data.step if self.run_task else 0

    def _skip_chapter(self):
        """ 跳过章节,限制初章 """
        cur_chapter = self.current_chapter
        pid = self.player.data.id
        if not cur_chapter.start: #只允许初章
            log.info('skip_chapter error(%s):not cur_chapter.start',
                    pid)
            return
        if cur_chapter.endTid in self.tids:
            log.info('skip_chapter error(%s):cur_chapter.endTid in self.tasks',
                    pid)
            return
        #跳过初章
        log.debug('_skip_chapter(%s):del_tasks=%s', pid, self.tids.keys())
        for task in self.tids.values():
            self.del_task(task)
        for i in xrange(cur_chapter.startTid, cur_chapter.endTid+1):
            self.tid_bm.insert(i)

        #策划要求跳过初章,并且跳过桃园走道部分任务,直接到桃园镇(tid=13)
        get_next_res_task = self.player._game.task_mgr.get_next_res_task
        def _next_task():
            #接下一章任务
            if 0:
                res_task = get_next_res_task(cur_chapter.endTid)
                return self.add_task(res_task.id, pid=cur_chapter.endTid)
            end_tid = 13
            res_task = get_next_res_task(cur_chapter.endTid)
            #获取奖励
            while res_task.id < end_tid:
                self.tid_bm.insert(res_task.id)
                self._reward(None, res_task)
                res_task = get_next_res_task(res_task.id)
            return self.add_task(res_task.id, pid=cur_chapter.endTid)

        task = _next_task()
        self.update_tid_bm()
        log.debug('_skip_chapter(%s):next_task=%s', pid, task)
        #spawn_later(1, self.send_accept_tasks, [task])



    def chapter_complete(self):
        """ 完成初章(新手引导),初始化数据 """
        game = self.player._game
        if self.player.is_guide:#初章后,还原玩家数据
            log.debug(u'玩家(%s-%s)完成初章', self.player.data.id, self.player.data.name)
            cmd_clear = game.setting_mgr.setdefault(GUIDE_PLAYER_CLEAR, GUIDE_PLAYER_CLEAR_V)
            cmd = game.setting_mgr.setdefault(NEW_PLAYER_CMD, NEW_PLAYER_CMD_V)
            self.player._gm_cmd([cmd_clear, cmd])
            with self.player.with_disable_msg():
                self._skip_chapter()

#        if self.player.data.chapter % 2 == 0: #初章序号都是单数
#            return False
        self.player.log_normal(PL_CHAPTER, chapter=self.player.data.chapter)
        self.player.data.chapter += 1
        self.player.save()
        self.player.pub(MSG_CHAPTER_FINISH, self.player)
        self.player.pub(MSG_ACHI_CHAPTER_FINISH)
        return True

    def _reward(self, task, res_task):
        """ 任务奖励 """
        rid = None
        if task is not None:
            rid = task.data.rid
        if not rid:
            rid = res_task.rid
        reward = self.player._game.reward_mgr.get(rid)
        if not reward:
            return
        items = reward.reward(params=self.player.reward_params())
        return self.player.bag.add_items(items, log_type=ITEM_ADD_TASK, rid=rid)

    def task_complete(self, tid):
        """ 任务完成获取奖励 """
        tTask = self.get_task(tid)
        if tTask is None:
            return False, errcode.EC_VALUE

        rs, err = tTask.can_complete(self.player)
        if not rs:
            return False, err

        #log.debug('task_complete:%s-%s', tTask.data.tid, tid)
        old_exp = self.player.data.exp
        old_level = self.player.data.level
        self.run_task = None
        #奖励
        tResTask = self.player._game.res_mgr.tasks.get(tTask.data.tid)
        bag_items = self._reward(tTask, tResTask)
        #完成
        res_task = tTask.complete(self, old_exp, old_level)
        #删除
        self.del_task(tTask)
        if res_task:#先返回任务完成,再接下一任务
            self.add_task(res_task.id, pid=tid, send_msg=0.2)
        #广播支线任务的完成
        if tResTask.type == TT_BRANCH:
            self.player.pub(MSG_TASK_FINISH, TT_BRANCH)
            self.p_attr_task[TASK_ZXTASK_FINISH] += 1
        #广播隐藏任务的完成
        elif tResTask.type == TT_HIDE:
            self.player.pub(MSG_TASK_FINISH, TT_HIDE)
            self.p_attr_task[TASK_YCTASK_FINISH] += 1
        return True, bag_items

    def _handle_upgrade(self, level):
        """ 玩家升级 """
        self.accept_tasks(TUL_LEVEL, level)
    
    def _handle_add_item(self, iid, count):
        """ 添加物品 """
        self.accept_tasks(TUL_ITEM, iid)

    def _handle_add_role(self, role):
        """ 添加配将 """
        self.accept_tasks(TUL_ROLE, role.data.rid)

    def _handle_add_equip(self, equip):
        """ 添加装备 """
        self.accept_tasks(TUL_EQUIP, equip.data.eid)

    def _handle_complete_task(self, tid):
        """任务完成"""
        self.accept_tasks(TUL_TASK, tid)


class TaskData(StoreObj):
    __slots__ = ('id', 'pid', 'tid', 'step', 'status', 'isRun', 'rid')
    def init(self):
        #标示
        self.id = None
        #玩家id
        self.pid = 0
        #任务id
        self.tid = 0
        #当前步骤
        self.step = 0
        #用户状态(1:执行中,2:完成)
        self.status = 1
        #是否当前在进行中
        self.isRun = 0
        #特定任务奖励id,悬赏令用
        self.rid = 0

class Task(GameObj):
    TABLE_NAME = TN_P_TASK
    DATA_CLS = TaskData
    UNIQUE = 1
    def __init__(self, adict=None):
        super(Task, self).__init__(adict=adict)

    @classmethod
    def get_cls(cls, type):
        if type == TT_OFFER:
            return BFTask
        return Task

    @classmethod
    def new_by_dict(cls, adict):
        res_task = Game.res_mgr.tasks.get(adict['tid'])
        if not res_task:
            return
        obj = cls.new_by_res(res_task)
        obj.update(adict)
        return obj

    @classmethod
    def new_by_res(cls, res_task):
        task = cls.get_cls(res_task.type)()
        task.data.tid = res_task.id
        return task

    def can_complete(self, player):
        """ 是否可以完成 """
        if getattr(self, 'completed', None):
            return False, errcode.EC_VALUE
        res_task, my_res_task = player._game.task_mgr.get_next_res_task(
            self.data.tid, return_res=True)
        if my_res_task.type == TT_MAIN and res_task is None:
            #主线任务没下一个任务,不允许完成,该任务用于占位
            return False, errcode.EC_NOLEVEL
        return True, 0


    def complete(self, player_task, old_exp, old_level):
        """ 任务完成
        返回:下一个任务 """
        self.completed = True
        player = player_task.player
        if self.UNIQUE:
            #记录
            player.log_task(self.data.tid, self.data.id)
            player_task.tid_bm.insert(self.data.tid)
            player_task.update_tid_bm()
            #任务完成
            player.pub(MSG_TASK_COMPLETE, self.data.tid)
            res_task = player._game.task_mgr.get_next_res_task(self.data.tid)
            if res_task:
                player_task.add_task(res_task.id,
                    pid=self.data.tid, send_msg=1)

    def __str__(self):
        return '%s(id=%s, tid=%s)' % (self.__class__.__name__,
                self.data.id, self.data.tid)

class BFTask(Task):
    """ 兵符 """
    UNIQUE = 0
    def complete(self, player_task, old_exp, old_level):
        """ 兵符任务完成处理 """
        self.completed = True
        #记录
        player_task.player.log_task(self.data.tid, self.data.id)
        super(BFTask, self).complete(player_task, old_exp, old_level)
        player = player_task.player
        player_bftask = player._game.bftask_mgr.init_player_bftask(player)
        bfTaskData = player_bftask.bfTaskData
        if BFTASK_ALREADY_ACCEPT not in bfTaskData.ss:
            log.debug('pid=%d bfTaskData= (%s, %s) tid=%d ttid=%d', player.data.id, bfTaskData.ss, bfTaskData.tids, self.data.id, self.data.tid)
            return
        index = bfTaskData.ss.index(BFTASK_ALREADY_ACCEPT)
        q = bfTaskData.qs[index]
        tExp = int(player_bftask.fetch_bf_exp[q])
        bfTaskData.exp += tExp
        bfTaskData.ss[index] = BFTASK_TYPE_FINISH
        bfTaskData.btid = 0
        if player.data.level > old_level:
            tExpLevel = player._game.res_mgr.exps_by_level.get(old_level+1)
            addExp = tExpLevel.exp - old_exp + player.data.exp
        else:
            addExp = player.data.exp - old_exp
        bfTaskData.exps[index] = addExp
        player.pub(MSG_TASK_FINISH, TT_OFFER)
        player.task.p_attr_task[TASK_BFTASK_FINISH] += 1



#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


