#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import log

from game import Game
from game.base import common
from game.store.define import (TN_P_ATTR, FOP_IN, FN_P_ATTR_FTIME,
    FN_ID, FN_P_ATTR_CBE, FN_P_ATTR_CBES, FN_P_ATTR_PID, DESCENDING,
    FN_P_ATTR_RESET, FN_P_ATTR_DAY
    )

class PlayerAttr(object):
    """ 玩家属性类管理 """
    PRE_CLIENT = 'cli_' #前端属性前缀
    LEN_CLIENT = len(PRE_CLIENT)
    def __init__(self, player):
        if 0:
            from .player import Player
            self.player = Player()
        self.player = player
        self.attr = {'id':None, 'pid':self.player.data.id}
        self.modified = False

    def uninit(self):
        self.player = None
        self.attr= {}

    @classmethod
    def get_CBE_ranks(cls, querys=None, limit=0, skip=0):
        """ 获取战斗力排行榜数据 """
        fields = [FN_P_ATTR_PID, FN_P_ATTR_CBE]
        sort_by = [(FN_P_ATTR_CBE, DESCENDING)]
        ranks = Game.rpc_store.values(TN_P_ATTR, fields, querys,
            sort_by=sort_by,
            limit=limit,
            skip=skip)
        return ranks

    @classmethod
    def get_CBEs(cls, pids):
        """ 获取战力数据 """
        fields = [FN_P_ATTR_PID, FN_P_ATTR_CBE]
        store = Game.rpc_store
        return store.values(TN_P_ATTR, fields, dict(pid={FOP_IN:list(pids)}))

    @property
    def CBE(self):
        return self.get(FN_P_ATTR_CBE, 0)
    @property
    def CBES(self):
        return self.get(FN_P_ATTR_CBES, 0)

    def load(self):
        """ 加载数据 """
        store = self.player._game.rpc_store
        querys = dict(pid=self.player.data.id)
        attrs = store.query_loads(TN_P_ATTR, querys)
        if not attrs:
            return
        #预防多条数据只那最早的那条
        min_attr = attrs[0]
        if len(attrs) > 1:
            min_id = 0
            min_attr = None
            for attr in attrs:
                attr_id = attr['id']
                if not min_id or attr_id < min_id:
                    min_id = attr_id
                    min_attr = attr
            log.debug('player_attr_err--pid %s, use_attr %s',min_attr['pid'], min_id)
        self.attr.clear()
        self.attr.update(min_attr)
        #if FN_ID not in self.attr:
        #    log.error('player(%d)attrs_load error:%s', self.player.data.id, self.attr)
        self.update()

    def _pass_day(self):
        """ 处理过一天 """
        if not self.attr.has_key(FN_P_ATTR_DAY) or common.is_pass_day(self.attr[FN_P_ATTR_DAY][FN_P_ATTR_FTIME]):
            self.attr[FN_P_ATTR_DAY] = {FN_P_ATTR_FTIME:common.current_time(), FN_P_ATTR_RESET:{}}

    def pass_day(self, key):
        """ 处理超过一天的信息 """
        self._pass_day()
        if key in self.attr[FN_P_ATTR_DAY][FN_P_ATTR_RESET]:
            return False
        self.attr[FN_P_ATTR_DAY][FN_P_ATTR_RESET][key] = 1
        return True

    def update(self):
        #更新战斗完成数据
        self.player.load_win_fight()

    def save(self):
        """ 保存更新 """
        #if 'id' not in self.attr or self.attr.has_key('id') and not self.attr['id']:
        if self.attr.get(FN_ID, None) is None:
            self.attr[FN_P_ATTR_PID] = self.player.data.id
            #防止插入多条记录 并打印出展信息
            store = self.player._game.rpc_store
            querys = dict(pid=self.player.data.id)
            attrs = store.query_loads(TN_P_ATTR, querys)
            if attrs:
                msg = 'player(%d) attrs(%s), curent(%s)' % (self.player.data.id, attrs, self.attr)
                log.log_stack(msg=msg)
                return
            _id = store.insert(TN_P_ATTR, self.attr)
            #log.debug('(%d)attr_save:%s-%s', self.player.data.id, _id, self.attr)
            self.attr[FN_ID] = _id
        else:
            self.player._game.rpc_store.save(TN_P_ATTR, self.attr)
        self.modified = False
        
    def clear(self):
        """ 清除 """
        if FN_ID not in self.attr:
            return
        #log.info('(%d)clear attr', self.player.data.id)
        self.player._game.rpc_store.delete(TN_P_ATTR, self.attr[FN_ID])
        self.attr.clear()

    def copy_from(self, play_attr):
        """拷贝玩家数据"""
        self.clear()
        _id, pid = self.attr.get(FN_ID, None), self.player.data.id
        self.attr.update(play_attr.attr)
        self.attr.update(dict(id=_id, pid=pid))
        self.modified = True

    def modify(self):
        self.modified = True

    def update_attr(self, aDict):
        """ 更新玩家属性 """
        self.attr.update(aDict)
        self.modified = True

    def set(self, key, value):
        self.attr[key] = value
        self.modified = True

    def get(self, key, default=None):
        return self.attr.get(key, default)

    def setdefault_by_objct(self, objct):
        """ 通过对象获取玩家属性 没有则更新属性记录 """
        objct_dict = objct.to_dict()
        tUpDict = {}
        for tAttr in objct_dict.iterkeys():
            if self.attr.has_key(tAttr):
                objct_dict[tAttr] = self.attr.get(tAttr)
            else:
                tUpDict[tAttr] = objct_dict[tAttr]
        if tUpDict:
            self.update_attr(tUpDict)
        return objct_dict

    def setdefault(self, key, defalut_value=None):
        """ 通过键获取属性值 没有则更新属性记录 """
        if self.attr.has_key(key):
            return self.attr.get(key)
        else:
            self.update_attr({key:defalut_value})
            self.modified = True
            return defalut_value

    def client_get(self, key):
        """ 获取前端属性 """
        key = '%s%s' % (self.PRE_CLIENT, key)
        return self.attr.get(key)

    def client_set(self, key, value):
        """ 设置前端属性 """
        key = '%s%s' % (self.PRE_CLIENT, key)
        self.attr[key] = value
        self.modified = True

    def iter_client_attrs(self):
        """ 遍历前端属性 """
        for k in self.attr.iterkeys():
            if not k.startswith(self.PRE_CLIENT):
                continue
            yield k[self.LEN_CLIENT:], self.attr[k]

    def client_to_dict(self):
        return dict((k, v) for k,v in self.iter_client_attrs())


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


