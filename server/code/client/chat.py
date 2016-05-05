#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import PlayerProp

DEBUG = 1

class PlayerChat(PlayerProp):
    def __init__(self, player):
        super(PlayerChat, self).__init__(player)
        self.player.client.add_listener(self)

    def on_chatMsg(self, status, kw, err):
        if DEBUG:
            print 'chat:', u'\n'.join(map(lambda c: u''.join(map(unicode, c)), kw))

    def chat_send(self, t, m, id=None):
        self.player.client.call_chatSend(t=t, m=m, id=id, _no_result=True)


