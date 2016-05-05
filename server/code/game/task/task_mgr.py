#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.base.msg_define import MSG_RES_RELOAD
from game.base.constant import (TT_BRANCH, TT_HIDE, TT_MAIN, TT_OFFER,
    TUL_EQUIP, TUL_ITEM, TUL_LEVEL, TUL_ROLE, TUL_TASK,
    )
from corelib import log
from corelib.data import IntRegionMap


class TaskMgr(object):
    """ 玩家任务管理类 """
    def __init__(self, game):
        if 0:
            from game import LogicGame
            self._game = LogicGame()
        self._game = game
        self._game.res_mgr.sub(MSG_RES_RELOAD, self.loadResTask)
        self.loadResTask()

    def clear(self):
        #{role_id:{taskid:res_task}}
        self.roles = {}
        #{finish_taskid:{taskid:res_task}}
        self.tasks = {}
        #{item_id:{taskid:res_task}}
        self.objs = {}
        #{equ_id:{taskid:res_task}}
        self.equs = {}
        self.levels = IntRegionMap()
        #依赖等级并且同时依赖其它条件的任务列表
        self.adv_levels = IntRegionMap()
        self._levels_tasks_cache = {}
        self.nolimits = {}

    def loadResTask(self):
        """ 加载任务基础数据 """
        self.clear()
        #level:1|role:7|tid:1|obj:1:3|equ:5
        def _unlock(res_task, res_unlocks, unlocks):
            if not res_unlocks:
                return False
            for d in res_unlocks:
                if isinstance(d, (tuple, list)):
                    _id, v = d[0], (res_task, d[1])
                else:
                    _id, v = d, res_task
                tasks = unlocks.setdefault(_id, {})
                tasks[res_task.id] = v
            return True

        res_tasks = self._game.res_mgr.tasks
        for tid, res_task in res_tasks.iteritems():
            #悬赏令任务不处理
            if res_task.type == TT_OFFER:
                continue
            #后续任务不处理
            if res_task.parent:
                continue
            #非自动推的任务不处理
            if not res_task.auto:
                continue
            if not res_task.unlock:
                self.nolimits[res_task.id] = res_task
            has_other = False
            has_other |= _unlock(res_task, res_task.unlock_roles, self.roles)
            has_other |= _unlock(res_task, res_task.unlock_tasks, self.tasks)
            has_other |= _unlock(res_task, res_task.unlock_equs, self.equs)
            has_other |= _unlock(res_task, res_task.unlock_objs, self.objs)
            if res_task.unlock_level > 0:
                try:
                    self._init_unlock_level(res_task, has_other)
                except:
                    log.log_except('task:%s', res_task.id)
        self.adv_levels.init()
        self.levels.init()

    def _init_unlock_level(self, res_task, has_other):
        """ 处理等级依赖任务
        #('20', '999')
        """
        start, end = map(int, res_task.unlock_level)
        if has_other:
            self.adv_levels.add(start, end, res_task)
        else:
            self.levels.add(start, end, res_task)

    def get_tasks(self, unlock_type, id_or_level):
        """ 根据解锁条件类型和数值, 返回满足条件的任务列表 """
        if unlock_type == TUL_ROLE:
            tasks = self.roles.get(id_or_level)
        elif unlock_type == TUL_EQUIP:
            tasks = self.equs.get(id_or_level)
        elif unlock_type == TUL_ITEM:
            tasks = self.objs.get(id_or_level)
        elif unlock_type == TUL_TASK:
            tasks = self.tasks.get(id_or_level)
        elif unlock_type == TUL_LEVEL:
            try:
                tasks = self._levels_tasks_cache[id_or_level]
            except KeyError:
                tasks = self.levels.get(id_or_level)
                if tasks is None:
                    tasks = []
                tasks.extend(self.adv_levels.gets(1, id_or_level))
                self._levels_tasks_cache[id_or_level] = tasks
        else:
            raise ValueError('unlock type(%s) no found' % unlock_type)
        if tasks is None:
            return []
        if isinstance(tasks, dict):
            ts = []
            for tid, res_task in tasks.iteritems():
                ts.append(res_task)
            tasks = ts
        return tasks

    def get_res_task(self, tid):
        return self._game.res_mgr.tasks.get(tid)

    def get_next_res_task(self, tid, return_res=False):
        res_task = self._game.res_mgr.tasks.get(tid)
        if res_task is None:
            if return_res:
                return None, None
            return None
        if return_res:
            return self._game.res_mgr.tasks.get(res_task.nextId), res_task
        return self._game.res_mgr.tasks.get(res_task.nextId)



