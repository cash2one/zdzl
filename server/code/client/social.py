#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import *

class Social(PlayerProp):

    def __init__(self, player):
        super(Social, self).__init__(player)
        self.client = player.client

    def socialEnter(self):
        return self.client.call_socialEnter()

    def socialGetInfo(self, t, page):
        return self.client.call_socialGetInfo(t=t, page=page)

    def socialaddFriend(self, pid):
        return self.client.call_socialAddFriend(pid=pid)

    def socialDelFriend(self, pid):
        return self.client.call_socialDelFriend(pid=pid)

    def socialAddBlack(self, pid):
        return self.client.call_socialAddBlack(pid=pid)

    def socialAddBlackName(self, name):
        return self.client.call_socialAddBlack(name=name)

    def socialDelBlack(self, pid):
        return self.client.call_socialDelBlack(pid=pid)

    def socialChangeName(self, n):
        return self.client.call_changeName(n=n)

