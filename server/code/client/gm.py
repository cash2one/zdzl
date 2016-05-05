#!/usr/bin/env python
# -*- coding:utf-8 -*-

class GameMaster(object):
    def __init__(self, player):
        self.player = player
        self.gm = player.gm

    def attr_set(self, key, value):
        return self.gm('my.attr_set("%s", %s)', key, value)
    def attr_get(self, key):
        return self.gm('my.attr_get("%s")', key)

    def status_get(self, key):
        return self.gm('status_get("%s")', key)

    def status_set(self, key, value, orig_value):
        if isinstance(value, (str, unicode)):
            return self.gm('status_set("%s", "%s", "%s")', key, value, orig_value)
        return self.gm('status_set("%s", %s, %s)', key, value, orig_value)

    def send_mails(self, pids, t, title, content, items=''):
        return self.gm('send_mails(%s, %s, "%s", "%s", %s)',
                pids, t, title, content, items)

    def del_player(self, pid):
        return self.gm('del_player(%d)', pid)

    def status_inc(self, key, num=1):
        return self.gm('status_inc("%s", %d)', key, num)

    def clear_player(self):
        return self.gm('my.clear_player()')

    def clear_part_data(self, *arg):
        return self.gm('my.clear_part_data(%s)', arg)

    def add_coin(self, aCoin1=0, aCoin2=0, aCoin3=0):
        """ 添加钱币 """
        return self.gm('my.add_money(%d, %d, %d)' % (aCoin1, aCoin2, aCoin3))

    def add_wait_item(self, wtype, items):
        return self.gm("my.add_wait_item(%d, %s)", wtype, items)

    def add_item(self, aIid, aCount, can_trade=False):
        """ 添加物品 """
        return self.gm("my.add_item(%d, %d, %s)" % (aIid, aCount, can_trade))

    def use_item(self, id):
        return self.gm('my.use_item(%d)', id)

    def use_item_ex(self, iid):
        return self.gm('my.use_item_ex(%d)', iid)

    def add_fate(self, aFid, can_trade=False):
        """ 添加命格 """
        return self.gm("my.add_fate(%d, %s)" % (aFid, can_trade))

    def add_equip(self, aEid, can_trade=False):
        """ 添加装备 """
        return self.gm("my.add_equip(%d, %s)" % (aEid, can_trade))

    def show_bag(self):
        return self.gm("my.show_bag()")

    def show_wait_bag(self):
        return self.gm("my.show_wait_bag()")

    def update_bag(self, type_name, id, **kw):
        return self.gm('my.update_bag(%s, %d, %s',
                type_name, id,
                ','.join(['%s=%s' % (k,v) for k,v in kw.iteritems()]))

    def add_role(self, rid, active=True):
        return self.gm('my.add_role(%d, active=%s)', rid, active)

    def show_roles(self):
        return self.gm('my.show_roles()')

    def show_play_data(self):
        return self.gm('my.show_play_data()')

    def role_come_back(self, rid):
        return self.gm('my.role_come_back(%d)', rid)

    def show_tasks(self):
        return self.gm('my.show_tasks()')

    def accept_tasks(self, utype=None, id_or_level=None):
        return self.gm('my.accept_tasks(%s, %s)', utype, id_or_level)

    def add_task(self, tid):
        return self.gm('my.add_task(%d)', tid)

    def reward(self, rid):
        return self.gm('my.reward(%d)', rid)

    def vip_level(self, level):
        return self.gm('my.vip_level(%d)', level)

    def add_re(self, num):
        return self.gm('my.add_re(%d)', num)

    def copy(self, pid):
        return self.gm('my.copy(%d)', pid)

    def add_car(self, cid):
        return self.gm('my.add_car(%d)', cid)

    def car_do(self, cid):
        return self.gm('my.car_do(%d)', cid)

#-------------------------------------------------------------------------------





