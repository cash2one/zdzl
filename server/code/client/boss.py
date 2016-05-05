#!/usr/bin/env python
# -*- coding:utf-8 -*-

from  .base import PlayerProp

class Boss(PlayerProp):
    def __init__(self, player):
        super(Boss, self).__init__(player)
        self.player.client.add_listener(self)
        self.info = None
        self.client = player.client

    def on_allyBossNotice(self, status, kw, err):
        """ boss广播开启时间 """
        print 'on_allyBossNotice----', kw

    def on_allyBossHp(self, status, kw, err):
        """ 同盟广播数据 包括boss剩余血量 """
        print 'on_allyBossHp-----', kw

    def on_allyBossRank(self, status, kw, err):
        """ 同盟广播数据 包括boss排名 """
        print 'on_allyBossRank-----', kw

    def on_bossNotice(self, status, kw, err):
        """ boss广播开启时间 """
        print 'on_bossNotice----', kw

    def on_bossHp(self, status, kw, err):
        """ 同盟广播数据 包括boss剩余血量 """
        print 'on_bossHp-----', kw

    def on_bossRank(self, status, kw, err):
        """ 同盟广播数据 包括boss排名 """
        print 'on_bossRank-----', kw

    def ally_boss_enter(self):
        return self.client.call_allyBossEnter()

    def ally_boss_exit(self):
        return self.client.call_allyBossExit()

    def ally_boss_start(self):
        return self.client.call_allyBossStart()

    def ally_boss_finish(self, hurt):
        return self.client.call_allyBossFinish(hurt=hurt)

    def boss_enter(self):
        return self.client.call_bossEnter()

    def boss_exit(self):
        return self.client.call_bossExit()

    def boss_start(self):
        return self.client.call_bossStart()

    def boss_finish(self, hurt):
        return self.client.call_bossFinish(hurt=hurt)

    def boss_cd_end(self):
        return self.client.call_bossCdEnd()
