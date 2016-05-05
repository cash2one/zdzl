#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store import StoreObj, GameObj
from game.store.define import TN_P_CAR

class CarData(StoreObj):

    def init(self):
        #标示
        self.id = None
        #玩家id
        self.pid = 0
        #坐骑id
        self.cid = 0

class Car(GameObj):
    TABLE_NAME = TN_P_CAR
    DATA_CLS = CarData
    def __init__(self, adict=None):
        super(Car, self).__init__(adict=adict)

