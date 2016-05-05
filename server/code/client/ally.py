#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import *

class Ally(PlayerProp):
    
    def __init__(self, player):
        super(Ally, self).__init__(player)
        self.client = player.client

    def allyOwn(self):
        return self.client.call_allyOwn()

    def allyCreate(self, name):
        return self.client.call_allyCreate(name=name)
    
    def allyApply(self, aid):
        return self.client.call_allyApply(aid=aid)
    
    def allyHDApply(self, pid, state):
        return self.client.call_allyHDApply(pid=pid, state=state)
    
    def allyCDuty(self, pid, duty):
        return self.client.call_allyCDuty(pid=pid, duty=duty)
    
    def allyKick(self, pid):
        return self.client.call_allyKick(pid=pid)
    
    def allyQuit(self):
        return self.client.call_allyQuit()
    
    def allyMembers(self):
        return self.client.call_allyMembers()
         
    def allyOtherMembers(self, aid):
        return self.client.call_allyOtherMembers(aid=aid)

    def allyAllyList(self, page):
        return self.client.call_allyAllyList(page=page)

    def allyAllyPost(self, aid):
        return self.client.call_allyPost(aid=aid)

    def allyLog(self):
        return self.client.call_allyLog()

    def allyDismiss(self):
        return self.client.call_allyDismiss()

    def allyCPost(self, ct):
        return self.client.call_allyCPost(ct=ct)

    def allyApplicants(self):
        return self.client.call_allyApplicants()

    def allyEnterCat(self):
        return self.client.call_allyCatEnter()

    def allyCat(self):
        return self.client.call_allyCat()

    def allyGraveEnter(self):
        return self.client.call_allyGraveEnter()

    def allyGrave(self, t):
        return self.client.call_allyGrave(type=t)

    def allyTTBoxEnter(self):
        return self.client.call_allyTTBoxEnter()

    def allyTTBoxList(self):
        return self.client.call_allyTTBoxList()

    def allyTTBoxNew(self, tbid):
        return self.client.call_allyTTBoxNew(tbid=tbid)

    def allyTTBoxInfo(self, tid):
        return self.client.call_allyTTBoxInfo(tid=tid)




