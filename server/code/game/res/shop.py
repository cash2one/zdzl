#!/usr/bin/env python
# -*- coding:utf-8 -*-
from corelib import log
from game.store import StoreObj, define
from game.base.common import current_time, uuid
from decimal import Decimal
PRICE_QUANTIZE = Decimal('1.00')

class ResShopItem(StoreObj):
    def init(self):
        self.id = None
        self.t = 0 #物品=1, 命格=3
        self.iid = 0 #物品id或命格品质
        self.r = 0 #概率
        self.c = 0 #每日限制
        self.coin1 = 0 #消耗银币
        self.coin2 = 0 #消耗元宝
        self.coin3 = 0 #消耗绑元宝
        self.start = 0 #开始时间
        self.end = 0    #结束时间
        self.qt = 0     #商店类型

class ResGemShopItem(StoreObj):
    def init(self):
        self.id = None
        self.gid = 0 #珠宝id
        self.lv = 0 #珠宝等级
        self.r = 0 #权重
        self.coin1 = 0 #消耗银币
        self.coin2 = 0 #消耗元宝
        self.coin3 = 0 #消耗绑元宝

class ResGoods(StoreObj):
    GT_HOT = 1
    GT_RUSH = 2
    GT_OFF = 3
    GT_FIRST = 4
    TABLE_NAME = define.TN_RES_GOODS
    def init(self):
        self.id = None
        self.name = ''
        self.info = ''
        self.act = ''
        self.type = 0 #1=热销,2=促销,3=特价,4=首充
        self.price = 0
        self.oprice = 0
        self.rid = 0
        self.status = 0 #1=上架,0=落架
        self.coin = 0 #真元宝数
        self.freeCoin = 0 #免费赠送的真元宝
        self.sns = None #sns对应产品id字典
        self.snsType = 0 #针对特定sns的产品

    def is_first_reward(self):
        return self.type == self.GT_FIRST

class PrePay(StoreObj):
    """ 待支付记录 """
    TABLE_NAME = define.TN_PRE_PAY
    def init(self):
        self.id = None
        self.ct = 0
        self.porder = ''
        self.t = 0
        self.sid = 0
        self.uid = 0
        self.pid = 0
        self.gid = 0
        self.price = 0
        self.rid = 0
        self.pd = '' #平台特有产品id
        self.torder = '' #sns商的支付id

    def prepare(self, t, sid, uid, pid, good, product_id):
        self.ct = current_time()
        self.porder = uuid()
        self.t = t
        self.sid = int(sid)
        self.uid = int(uid)
        self.pid = int(pid)
        self.gid = good.id
        self.pd = product_id
#        if isinstance(good.price, (int, float)):
#            self.price = Decimal(good.price).quantize(PRICE_QUANTIZE)
#        else:
#            self.price = good.price
        self.price = good.price
        self.rid = good.rid

    def check(self, price):
        """ 检查 """
        #检查价钱
        f = 100.0
        if int(float(self.price) * f) != int(float(price) * f):
            return False
        return True



class Pay(StoreObj):
    """ 支付记录 """
    TABLE_NAME = define.TN_PAY_LOG

    def init(self):
        self.id = None
        self.ct = 0
        self.porder = '' #游戏的支付id
        self.t = 0 #支付类型: 1=91助手
        self.torder = '' #sns商的支付id
        self.status = 0
        self.dt = 0
        self.sid = 0
        self.uid = 0
        self.pid = 0
        self.gid = 0
        self.price = 0
        self.rid = 0
        self.coin = 0 #获取的游戏元宝数
        self.data = {}
        self.lv = 0 #玩家当前等级

    def prepare(self, is_ok, torder, pre_pay, data):
        self.ct = current_time()
        self.torder = torder
        self.status = 1 if is_ok else 0
        self.t = pre_pay.t
        self.porder = pre_pay.porder
        self.sid = pre_pay.sid
        self.uid = pre_pay.uid
        self.pid = pre_pay.pid
        self.gid = pre_pay.gid
        self.price = pre_pay.price
        self.rid = pre_pay.rid
        self.data = data

    def prepare_torder(self, is_ok, torder, price, data):
        self.ct = current_time()
        self.torder = torder
        self.status = 1 if is_ok else 0
        self.price = price
        self.data = data

    def update_torder(self, pre_pay):
        self.t = pre_pay.t
        self.porder = pre_pay.porder
        self.sid = pre_pay.sid
        self.uid = pre_pay.uid
        self.pid = pre_pay.pid
        self.gid = pre_pay.gid
        self.price = pre_pay.price
        self.rid = pre_pay.rid

    @classmethod
    def pay_exist(cls, t, torder, store):
        """ 检查是否已经保存了 """
        rs = store.count(cls.TABLE_NAME,
            dict(t=t, torder=torder)
            ) == 1
        if rs:
            log.info('[sns(%s)]torder(%s) exist!', t, torder)
        return rs


    @classmethod
    def check(cls, porder, store):
        """ 在上面检查是否已保存之后,这里用于检查数据是否合理 """
        rs = store.count(cls.TABLE_NAME,
            dict(porder=porder),
            #{define.OP_OR:[dict(porder=porder), dict(torder=torder)]}
        ) == 0
        return rs


#---------------------
#---------------------
#---------------------
