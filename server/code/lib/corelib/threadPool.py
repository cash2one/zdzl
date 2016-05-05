#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import td_start_new_thread, td_Queue
from corelib import log

class WorkerTask(object):
    """ 工作任务 """
    def __init__(self, function, args=()):
        self.function = function
        self.args = args

    def __call__(self):
        self.function(*self.args)

def _thread(pool):
    while pool.started:
        task = pool.getTask()
        try:
            task()
        except:
            #TODO 添加到log
            log.debug("多线程战报写入错误")
            pass

class ThreadPool(object):
    """ 线程池管理 """
    def __init__(self, max_pool_size=10):
        self.max_pool_size = max_pool_size
        self.threads = []
        self.tasks = td_Queue()
        self.started = False
        self.start()

    def start(self):
        self.started = True
        for i in xrange(self.max_pool_size):
            td_start_new_thread(_thread, (self,))

    def addTask(self, function, args=()):
        task = WorkerTask(function, args)
        self.tasks.put(task)

    def getTask(self):
        return self.tasks.get()

class GlobalThreadPool(object):
    """ 单列化 """

    _instance = None

    def __init__(self, max_pool_size=10):
        if GlobalThreadPool._instance is None:
            GlobalThreadPool._instance = ThreadPool(max_pool_size)

    def __getattr__(self, attr):
        return getattr(self._instance, attr)

    def __setattr__(self, attr, val):
        return setattr(self._instance, attr, val)


