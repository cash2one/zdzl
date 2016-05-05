#!/usr/bin/env python
# -*- coding:utf-8 -*-
from game.store import StoreObj, GameObj

from game.store.define import TN_P_MAP

class PlayerMap(object):
    """ 玩家地图类 """
    def __init__(self, player):
        self.player = player
        self.maps = {}
        if 0:
            from .player import Player
            self.player = Player()

    def uninit(self):
        self.player = None
        self.maps = {}

    def load(self):
        store = self.player._game.rpc_store
        querys = dict(pid=self.player.data.id)
        maps = store.query_loads(TN_P_MAP, querys)
        for m in maps:
            map = Map(adict=m)
            self.maps[map.data.mid] = map

    def save(self):
        store = self.player._game.rpc_store
        for m in self.maps.itervalues():
            m.save(store)

    def clear(self):
        store = self.player._game.rpc_store
        for m in self.maps.itervalues():
            m.delete(store)
        self.maps.clear()

    def copy_from(self, maps):
        self.clear()
        for m in maps.maps.itervalues():
            mi = Map(adict=m.data.to_dict())
            mi.data.id = None
            mi.data.pid = self.player.data.id
            mi.save(self.player._game.rpc_store)
        self.load()

    def to_dict(self):
        return [m.to_dict() for m in self.maps.itervalues()]

    def update(self, mid, data):
        """ 更新地图信息 """
        map = self.maps.get(mid)
        if map is None:
            map = Map(adict=dict(pid=self.player.data.id, mid=mid, data=data))
            map.save(self.player._game.rpc_store)
            self.maps[map.data.mid] = map
        else:
            map.data.data = data
            map.modify()
        return map


class MapData(StoreObj):
    def init(self):
        self.id = None
        self.pid = 0
        self.mid = 0
        self.data = ''

class Map(GameObj):
    TABLE_NAME = TN_P_MAP
    DATA_CLS = MapData

