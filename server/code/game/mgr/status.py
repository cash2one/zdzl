#!/usr/bin/env python
# -*- coding:utf-8 -*-

from gevent.coros import RLock
from corelib import spawn
from corelib.memory_cache import TimeMemCache

from game.store.define import TN_STATUS, TN_GCONFIG
from game import Game

class StatusMgr(object):
    """ 单服状态管理类 """
    _rpc_name_ = 'rpc_status_mgr'
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        self.cache = TimeMemCache(default_timeout=10, name='status_mgr.cache')
        self._slock = RLock()

    def _get(self, key):
        querys = dict(key=key)
        values = Game.rpc_store.query_loads(TN_STATUS, querys)
        if values:
            return values[0]['id'], values[0]['value']
        return None, None

    def get(self, key, default=None):
        """ 获取服状态 """
        _id, v = self.cache.get(key, (None, None))
        if v is not None:
            return v
        with self._slock:
            _id, v = self._get(key)
            if _id is None:
                return default
            self.cache.set(key, (_id, v))
        return v

    def _set(self, id, key, value):
        if id is None:
            id = Game.rpc_store.insert(TN_STATUS, dict(key=key, value=value))
            self.cache.set(key, (id, value))
        else:
            self.cache.set(key, (id, value))
            Game.rpc_store.save(TN_STATUS, dict(id=id, key=key, value=value))
        return id

    def set(self, key, value, orig_value=None):
        """ 设置服状态,
        orig_value=None 强制覆盖
        失败返回False """
        with self._slock:
            _id, v = self.cache.get(key, (None, None))
            if v is not None and orig_value is not None and orig_value != v:
                return False
            if v is None or _id is None:
                _id, v = self._get(key)
            if v is not None and orig_value is not None and v != orig_value:
                return False
            self._set(_id, key, value)
            return True

    def update_dict(self, key, adict):
        """更新 值 是字典类型的数据"""
        with self._slock:
            _id, v = self._get(key)
            if v is None:
                v = adict
            else:
                v.update(adict)
            self._set(_id, key, v)

    def _add(self, key, num=None):
        """ num=None时,清零 """
        with self._slock:
            _id, v = self.cache.get(key, (None, None))
            if _id is not None:
                v += num if num is not None else -v
                self.cache.set(key, (_id, v))
            else:
                _id, v = self._get(key)
                if v is None:
                    v = 0
                v += num if num is not None else -v
            self._set(_id, key, v)

    def inc(self, key, num=1):
        """ key对应的值+1 """
        spawn(self._add, key, num)

    def dec(self, key, num=-1):
        spawn(self._add, key, num)
    
    def zero(self, key):
        """ 清零 """
        spawn(self._add, key)

    def get_config(self, key, default=None):
        """ 获取gconfig全局配置 """
        return Game.rpc_res_store.get_config(key, default=default)



def new_status_mgr():
    mgr = StatusMgr()
    return mgr


