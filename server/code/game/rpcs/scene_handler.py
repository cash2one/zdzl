#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import log
from game.glog.common import PL_MAPUPDATE, PL_WORLDMAP

from .player_handler import pack_msg, reg_player_handler, BasePlayerRpcHander

import config

class PlayerSceneHandler(BasePlayerRpcHander):
    def rc_map(self):
        """ 读取地图信息 """
        resp_f = 'map'
        return pack_msg(resp_f, 1, data=self.player.maps.to_dict())

    def rc_enterMap(self, mid):
        """ 进入场景 """
        resp_f = 'enterMap'
        rs, data = self.player.scene_enter(mid)
        if rs:
            return pack_msg(resp_f, 1, data=dict(mid=mid))
        else:
            return pack_msg(resp_f, 0, err=data)

    def rc_mapPlayers(self):
        """ 获取场景玩家信息 """
        resp_f = 'mapPlayers'
        infos = self.player.rpc_scene.get_infos()
        return pack_msg(resp_f, 1, data=infos)

    def rc_move(self, pos):
        """ 玩家移动,没返回 """
        #log.debug(u'玩家(%s)移动(%s)', self.player.data.name, pos)
        self.player.scene_move(pos)

    def rc_stageUpdate(self, stage):
        """ 更新副本数据 """
        self.player.data.stage = stage

    def rc_mapUpdate(self, mid, data):
        """ 更新地图信息 """
        resp_f = 'mapUpdate'
        self.player.maps.update(mid, data)
#        if config.debug:
#            self.player.log_normal(PL_MAPUPDATE, mid=mid, d=data,
#                tid=self.player.task.current_tid,
#                step=self.player.task.current_step)
        return pack_msg(resp_f, 1)

    def rc_preMapUpdate(self, pmid):
        """ 更新上次大地图信息 """
        resp_f = 'preMapUpdate'
        self.player.data.preMId = pmid
        return pack_msg(resp_f, 1)

    def rc_worldMap(self, data):
        """ 更新世界地图信息 """
        resp_f = 'worldMap'
        self.player.data.wMap = data
#        if config.debug:
#            self.player.log_normal(PL_WORLDMAP, d=data,
#                    tid=self.player.task.current_tid)
        return pack_msg(resp_f, 1)

reg_player_handler(PlayerSceneHandler)

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



