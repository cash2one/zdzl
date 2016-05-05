#!/usr/bin/env python
# -*- coding:utf-8 -*-


from .base import PlayerProp

class PlayerTbox(PlayerProp):
    def __init__(self, player):
        super(PlayerTbox, self).__init__(player)
        self.info =None

    def enter(self, chapter):
        """ 进入 """
        rs = self.player.client.call_tBoxEnter(chapter=chapter)
        return rs

    def hit_end(self, chapter, fight=0, level=0):
        """ 猎怪结束 """
        return self.player.client.call_tBoxHitEnd(chapter=chapter, fight=fight, level=level)

    def reset(self, chapter):
        """ 重置 """
        return self.player.client.call_tBoxReset(chapter=chapter)
    
    def kill(self, chapter):
        """ 秒杀 """
        return self.player.client.call_tBoxKill(chapter=chapter)
    
    def rank(self, chapter, tbid):
        """ 获取排名 """
        return self.player.client.call_tBoxRank(chapter=chapter, tbid=tbid)

    def get_news(self, id):
        """ 获取战报 """
        return self.player.client.call_fightReport(id=id)

    def sub_news(self, chapter, tbid, news):
        """ 提交战报 """
        return self.player.client.call_tBoxSub(chapter=chapter, tbid=tbid, news=news)


