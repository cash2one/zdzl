#!/usr/bin/env python
# -*- coding:utf-8 -*-

TBOX_TASK_ID1 = 18
TBOX_TASK_ID2 = 32
TBOX_TASK_ID3 = 40
TBOX_TASK_ID4 = 47
TBOX_TASK_ID5 = 55
CHAPTER_ID2 = 2
TBOX_TASK_ID6 = 92

CHAPTER_ID3 = 3

#基础时光盒id
RES_TBOX1 = 1
RES_TBOX2 = 2
RES_TBOX3 = 3
RES_TBOX4 = 4
RES_TBOX5 = 5


def tbox_test(player, add_task=0, add_all=0):
    """ 时光盒测试 """
    if add_task:
        #清楚任务数据
        player.game_master.clear_part_data('task')
        #添加任务
        player.game_master.add_task(TBOX_TASK_ID3)
        player.update_task()
        print 'task =====',player.tasks.tasks
        task = player.tasks.tasks[0]
        print 'task =====',task
        #完成任务
        rs = player.tasks.complete(task)
        print 'complete --------', rs
    if add_all:
        for id in (
                   TBOX_TASK_ID4, TBOX_TASK_ID5 ):
            #清楚任务数据
            player.game_master.clear_part_data('task')
            #添加任务
            player.game_master.add_task(id)
            player.update_task()
            task = player.tasks.tasks[0]
            #完成任务
            rs = player.tasks.complete(task['id'])
            print 'complete-all --------', rs
    #进入
    rs = player.tbox.enter(CHAPTER_ID2)
    print 'enter --------', rs
    #获取排名
    rs = player.tbox.rank(CHAPTER_ID2, RES_TBOX1)
    print 'rank1 --------', rs
    #结束
    rs = player.tbox.hit_end(CHAPTER_ID2, fight=100, level=5)
    print 'hit_end -------', rs
    #重置
    #rs = player.tbox.reset(CHAPTER_ID2)
    print 'reset -------', rs
    #秒杀
    #rs = player.tbox.kill(CHAPTER_ID)
    print 'kill -------', rs
    #获取排名
    rs = player.tbox.rank(CHAPTER_ID2, RES_TBOX1)
    print 'rank2 --------', rs
    #获取战报
    #rs = player.tbox.get_news(27)
    print 'get_news -------------- ', rs
    #提交战报
    #rs = player.tbox.sub_news(CHAPTER_ID, RES_TBOX5, 11*'111122a22aaaaaaaaaaaaa')
    print 'sub_news -------------- ', rs






