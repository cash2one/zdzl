#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import log

from store.store import GameObj, StoreObj, Store
from store.driver import MONGODB_ID

from game.store.define import (GROUP_MONGO_CLS_INFOS,
        TN_SERVER, TN_GCONFIG, TN_GUSER,
        )
from game.base import errcode
from game.res.shop import Pay, PrePay, ResGoods

from games import GameServers
game_servers = GameServers()

import config
from webapi import (
    sdk91, dpay, pp, uc, dcn, tb, ids,
    SNS_91, SNS_DPAY, SNS_PP, SNS_UC, SNS_DCN, SNS_TONGBU, SNS_IDSC, SNS_PP_APPLE
    )

#类与表名关系 (tablename, key, indexs, autoInc)
CLS_INFOS = {
    MONGODB_ID: GROUP_MONGO_CLS_INFOS,
    }

class BasePay(object):
    SNS_TYPE = 0
    @classmethod
    def pay_exist(cls, torder):
        return Pay.pay_exist(cls.SNS_TYPE, torder, logon_store)

    @classmethod
    def get_pre_pay(cls, porder):
        return PrePay.load_ex(logon_store, dict(porder=porder))

    @classmethod
    def save(cls, obj):
        obj.save(logon_store)
        log.info('[sns(%s)]save(%s) done porder:%s torder:%s', cls.SNS_TYPE, obj.porder, obj.torder)

    @classmethod
    def save_data(cls, porder, torder, status, price, data):
        """ 保存 """
        pre_pay = cls.get_pre_pay(porder)
        if not pre_pay:
            log.error('[sns(%s)]****error: porder(%s) no found',
                cls.SNS_TYPE, porder)
            return False

        if not Pay.check(porder, logon_store):
            log.info('[sns(%s)]porder(%s) torder(%s) existed!',
                    cls.SNS_TYPE, porder, torder)
            return True

        #检查
        if not pre_pay.check(price):
            log.error('[sns(%s)]****error: price(%s != %s)',
                    cls.SNS_TYPE, pre_pay.price, price)
            return False

        pay = Pay()
        pay.prepare(status, torder, pre_pay, data)
        pay.save(logon_store)
        log.info('[sns(%s)]save_data(%s) done', cls.SNS_TYPE, porder)
        return True

#    @classmethod
#    def save_torder(cls, torder, status, price, data):
#        """保存只有torder商家号的log"""
#        pay = Pay()
#        pay.prepare_torder(status, torder, price, data)
#        pay.save(logon_store)
#        log.info('[sns(%s)]save_torder(%s) done', cls.SNS_TYPE, torder)
#        return True
#
#    @classmethod
#    def pay_handle(cls, torder):
#        """订单处理"""
#        pre_pay = PrePay.load_ex(logon_store, dict(torder=torder, t=cls.SNS_TYPE))
#        if not pre_pay:
#            log.error('[sns(%s)]****pay_handle error: torder(%s) pre_pay no found',
#                cls.SNS_TYPE, torder)
#            return
#
#        pay = Pay.load_ex(logon_store, dict(torder=torder, t=cls.SNS_TYPE))
#        if not pay:
#            log.error('[sns(%s)]****pay_handle error: torder(%s) pay no found',
#                cls.SNS_TYPE, torder)
#            return
#
#        if not Pay.check(pre_pay.porder, logon_store):
#            log.info('[sns(%s)]porder(%s) torder(%s) existed!',
#                cls.SNS_TYPE, pre_pay.porder, torder)
#            return
#
#        #检查
#        if not pre_pay.check(pay.price):
#            log.error('[sns(%s)]****error: price(%s != %s)',
#                cls.SNS_TYPE, pre_pay.price, pay.price)
#            return
#
#        pay.update_torder(pre_pay)
#        pay.save(logon_store)
#        log.info('[sns(%s)]pay_handle porder(%s) torder(%s) done', cls.SNS_TYPE, pre_pay.porder, torder)

class SDK91Pay(BasePay, sdk91.AbsPay):
    """ 支付记录 """
    SNS_TYPE = SNS_91
#    EXCLUDES = ('Act', 'ProductName', 'Sign', ) #不需要保存的字段
#    KEYS = ('ConsumeStreamId', 'CooOrderSerial', )

sdk91.ACTS[sdk91.CB_ACT_PAY] = SDK91Pay


class DPayPay(BasePay, dpay.AbsPay):
    """ 支付记录 """
#    EXCLUDES = ('Sign', ) #不需要保存的字段
    SNS_TYPE = SNS_DPAY

dpay.ACTS[dpay.CB_ACT_PAY] = DPayPay


class PPPay(BasePay, pp.AbsPay):
    """ 支付记录 """
    #    EXCLUDES = ('Sign', ) #不需要保存的字段
    SNS_TYPE = SNS_PP

pp.ACTS[(pp.CB_ACT_PAY, SNS_PP)] = PPPay

class PPApplePay(BasePay, pp.AbsPay):
    """ pp苹果园 """
    SNS_TYPE = SNS_PP_APPLE

pp.ACTS[(pp.CB_ACT_PAY, SNS_PP_APPLE)] = PPApplePay

class UCPay(BasePay, uc.AbsPay):
    """支付记录"""
    SNS_TYPE = SNS_UC

uc.ACTS[uc.CB_ACT_PAY] = UCPay

class DCNPay(BasePay, dcn.AbsPay):
    """支付记录"""
    SNS_TYPE = SNS_DCN

dcn.ACTS[dcn.CB_ACT_PAY] = DCNPay

class TongBuPay(BasePay, tb.AbsPay):
    """支付记录"""
    SNS_TYPE = SNS_TONGBU

tb.ACTS[tb.CB_ACT_PAY] = TongBuPay

class IDSCPay(BasePay, ids.AbsPay):
    """云顶破解"""
    SNS_TYPE = SNS_IDSC

    @classmethod
    def check_pay(cls, data):
        try:
            money = int(float(data['money']))
            t = cls.SNS_TYPE
            sid = data['serv_id']
            pid = data['player_id']
            uid = 0
            product_id = ''
            g = ResGoods.load_ex(logon_store, dict(price=money))
            if g is None:
                log.info('[idsc]check_pay goods is not find price:%s', data['money'])
                return False, 'price error: money != price'
            pre_pay = PrePay()
            pre_pay.prepare(t, sid, uid, pid, g, product_id)
            logon_store.insert(PrePay.TABLE_NAME, pre_pay.to_dict())
            return True, pre_pay.porder
        except:
            log.log_except()
            return False, 'save error'

    @classmethod
    def check_accout(cls, sdk, data):
        player_info_fs = ['rid', 'level']
        log.info('[idsc]Server:%s', data)
        ret_msg = None
        try:
            sid = int(data['serv_id'])
            name = data.get('usr_name')
            for sid, rpc_client in game_servers.iter_servers([sid]):
                u, p = rpc_client.get_rpc_user_by_name(name, player_fs=player_info_fs)
                ss = game_servers.get_servers()
                server = ss.get(sid)
                ret_msg = {"err_code":0, "usr_id":u['name'] , "usr_name": name,
                                "usr_rank":p['level'], "player_id":p['id'], "app_id":server.app}
        except:
            log.log_except()
        if ret_msg is None:
            ret_msg = {'err_code':1, 'desc': u'没有该用户'}
        return ret_msg

    @classmethod
    def get_server_list(cls, sdk, data):
        ss = game_servers.get_servers()
        serv = []
        if not ss:
            return {'err_code':1, 'desc': u'服务器列表为空'}
        for s in ss.values():
            if not s.app:
                continue
            serv.append({'serv_id': s.sid, 'serv_name': s.name})
        return {'err_code':0, 'serv':serv}


ids.ACTS[ids.CB_ACT_PAY] = IDSCPay

class ServerData(StoreObj):
    OPEN_STATUSES = set(range(-1, 10))
    def init(self):
        self.id = None
        self.name = ''
        self.host = ''
        self.port = 0
        #-1=服务器过滤掉,0=关闭,1=推荐,2=火爆,3=维护,4=内测结束
        self.status = 0
        self.sid = 0 #服务器id
        self.app = 0 #对应的appId

class LogonStore(Store):
    STORE_INFOS = CLS_INFOS
    def get_servers(self, all=0):
        servers = [s for s in self.load_all(TN_SERVER) if all or s['status']>=0]
        servers.sort(key=lambda s:s['id'])
        return ServerData.new_from_list(servers)

    def get_config(self, key, default=None):
        """ gconfig全局配置 """
        value = self.query_loads(
            TN_GCONFIG, dict(key=key))
        if value:
            return value[0]['value']
        return default

logon_store = LogonStore()
logon_store.init(config.db_engine, **config.db_params)

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



