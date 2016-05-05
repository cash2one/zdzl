#!/usr/bin/env python
# -*- coding:utf-8 -*-

"""
    游戏场景物件
"""
from game.base.common import Position

class ActionData(object):
    __slots__ = ('pos', 'facing_direction',
            'act_id', 'volume')
    def __init__(self):
        self.pos = Position() #位置
        self.facing_direction = FACE_RIGHT #面向
        self.act_id = 0 #动作

    def __getstate__(self):
        return dict(pos=self.pos,
                facing_direction=self.facing_direction,
                act_id=self.act_id,
                )

    def __setstate__(self, adict):
        self.pos = adict['pos']
        self.facing_direction = adict['facing_direction']
        self.act_id = adict['act_id']

    def assign_to(self, pb2obj):
        self.pos.assign_to(pb2obj.pos)
        pb2obj.facing_direction = self.facing_direction
        pb2obj.act_id = self.act_id
        return pb2obj


class SceneItem(object):
    __slots__ = ('scene', 'action', 'id', 'item')
    def __init__(self, scene, item):
        if 0:
            from game.scene import Scene
            self.scene = Scene()

        self.scene = scene
        self.id = self.scene.get_next_id()
        self.item = item
        self.action = ActionData()
        #item.scene_item = self
        self.scene.items[self.id] = self





#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



