#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import log
from game.base.msg_define import MSG_TBOX_MDIE, MSG_TBOX_PASS
from .player_handler import pack_msg, reg_player_handler, BasePlayerRpcHander

class PlayerTboxHandler(BasePlayerRpcHander):

    def rc_tBoxEnter(self, chapter):
        """ 进入时光盒 """
        resp_f = 'tBoxEnter'
        rs, data = self.player._game.tbox_mgr.enter(self.player, chapter)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_tBoxHitEnd(self, chapter, fight=0, level=0):
        """ 猎怪结束 """
        resp_f = 'tBoxHitEnd'
        rs, data = self.player._game.tbox_mgr.hit_end(self.player, chapter, fight, level)
        if rs:
            self.player.pub(MSG_TBOX_MDIE, 1)
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_tBoxReset(self, chapter):
        """ 重置 """
        resp_f = 'tBoxReset'
        rs, data = self.player._game.tbox_mgr.reset(self.player, chapter)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_tBoxKill(self, chapter):
        """ 秒杀 """
        resp_f = 'tBoxKill'
        rs, data = self.player._game.tbox_mgr.kill(self.player, chapter)
        if rs:
            self.player.pub(MSG_TBOX_PASS, chapter)
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_tBoxRank(self, chapter, tbid):
        """ 获取排名 """
        resp_f = 'tBoxRank'
        rs, data = self.player._game.tbox_mgr.get_rank(chapter, tbid)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_tBoxNews(self, chapter, tbid, rank):
        """ 获取战报 """
        resp_f = 'tBoxNews'
        rs, data = self.player._game.tbox_mgr.get_news(chapter, tbid, rank)
        if rs:
            return pack_msg(resp_f, 1, data=data)
        return pack_msg(resp_f, 0, err=data)

    def rc_tBoxSub(self, chapter, tbid, news):
        """ 提交战报 """
        resp_f = 'tBoxSub'
        rs, data = self.player._game.tbox_mgr.sub_news(self.player.data.id, chapter, tbid, news)
        if rs:
            return pack_msg(resp_f, 1)
        return pack_msg(resp_f, 0, err=data)

reg_player_handler(PlayerTboxHandler)
