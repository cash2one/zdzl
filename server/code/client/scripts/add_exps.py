#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .player import *


#终止的任务tid
END_TASKID = 58

#支线开始任务tid
START_TASKID = 79

#初章终止的任务tid
END_INIT_TASKID = 8

def test_tasks(player):
    """ 任务流程测试 """
    for task in player.tasks.tasks:
        print 'task---',task
        player.game_master.accept_tasks()
        print 'complete----tid----------',task['tid']
        player.tasks.complete(task['id'])
        if task['tid'] == END_INIT_TASKID:
            player.tasks.complete_chapter()
        if task['tid'] == END_TASKID:
            break

#    for task in tasks:
#        if START_TASKID == task['tid']:
#            player.game_master.accept_tasks()
#            print 'other_task-complete----tid----------',other_task
#            player.tasks.complete(task['id'])

#    player.tasks.complete_chapter()
#    player.game_master.add_task(9)
#    for tid in TASK_TIDS:
#        print 'tid--',tid
#        tasks = player.tasks.tasks
#        #print 'tasks----',player.tasks.tasks
#        for task in tasks:
#            if tid == task['tid']:
#                player.game_master.accept_tasks()
#                print 'complete----tid----------',tid
#                player.tasks.complete(task['id'])
#
#    for other_task in TASK_OTHER:
#        tasks = player.tasks.tasks
#        for task in tasks:
#            if other_task == task['tid']:
#                player.game_master.accept_tasks()
#                print 'other_task-complete----tid----------',other_task
#                player.tasks.complete(task['id'])
#        sleep(2)
#        print 'tasks----',player.tasks.tasks
#
#        task = player.tasks.tasks[0]
#
#        player.tasks.complete(task['id'])
#        print 'complete----',task['id']


#    player.tasks.tasks = []
#    player.game_master.accept_tasks()
#    for i in xrange(5):
#        sleep(0.5)
#        if not player.tasks.tasks:
#            continue
#        print 'player.show_tasks--',player.game_master.show_tasks()
#        task = player.tasks.tasks[0]
#        player.tasks.complete(task['id'])
#        return