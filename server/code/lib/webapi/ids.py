#!/usr/bin/env python
# -*- coding:utf-8 -*-
#云顶平台

from hashlib import md5
from base64 import b64decode
import struct
import socket
import time

import web
from gevent.queue import Queue

from corelib import json, log, getcurrent
from corelib.tools import http_post_ex


import webapi

#ACT
CB_ACT_PAY = '1'

#返回编码
CODE_FAIL = 0
CODE_SUCC = 1
CODE_APPID = 2
CODE_ACT = 3
CODE_PARAM = 4
CODE_SIGN = 5

#支付状态：
PAY_STATUS_FAIL = '0'
PAY_STATUS_SUCC = 0
PAY_STATUS_PASS = 1 #已兑换过并成功返回



class AbsPay(webapi.BaseAct):
    FIELDS = ('appid', 'uid',
              'apporderid',
              'appmoney', 'money', 'createtime',
              'sign')
    F_STATUS = '' #是否成功支付
    F_PORDER = 'apporderid' #本地订单号
    F_TORDER = 'apporderid'#运营商订单号
    F_PRICE = 'money' #单位：元

    CHECK_FILEDS = ('serv_id', 'usr_id', 'app_id',
                    'player_id', 'order_id',
                    'coin', 'money', 'create_time',
                    'sign'
                    )

    @classmethod
    def is_ok(cls, data):
        return True

    @classmethod
    def has_pay(cls, CooOrderSerial):
        """ 被动接口: 检查是否支付成功 """
        raise NotImplementedError

    @classmethod
    def GET(cls, sdk, data):
        """ 收到回调,处理数据 """
        #校验
        for fn in cls.FIELDS:
            if fn not in data:
                log.warn('[idsc]callback Param not found:%s', fn)
                return CODE_PARAM, ''

        #rsa验证
        sign = data['sign']
        sdata = sdk.get_pay_sign(data)
        if sdata != sign:
            log.warn('[idsc]callback sign data error, sign(%s) sdata(%s)', sign, sdata)
            return CODE_SIGN, 'sign data error'

        #保存
        try:
            if cls.save_data(data[cls.F_PORDER],
                data[cls.F_TORDER],
                cls.is_ok(data),
                data[cls.F_PRICE],
                data):
                return CODE_SUCC, 'save'
        except:
            log.log_except()
        return CODE_FAIL, 'systemError'

    @classmethod
    def ChenckPay(cls, sdk, data):
        #校验
        for fn in cls.CHECK_FILEDS:
            if fn not in data:
                log.warn('[idsc]ChenckPay Param not found:%s', fn)
                return CODE_PARAM, 'Param not found:%s' % fn

        #rsa验证
        sign = data['sign']
        sdata = sdk.get_check_pay_sign(data)
        if sdata != sign:
            log.warn('[idsc]ChenckPay sign data error, sign(%s) sdata(%s)', sign, sdata)
            return CODE_SIGN, 'sign data error'

        rs, desc = cls.check_pay(data)
        if rs:
            return CODE_SUCC, desc
        return CODE_FAIL, desc


ACTS = {CB_ACT_PAY:AbsPay}


def cb_init(sdk, app, api_url):
    """ 设置回调处理 """
    sns = webapi.SNS_URLS[webapi.SNS_IDSC]
    class Server(app.page):
        """请求区服数据"""
        path = '%s/%s/%s' % (api_url, sns, 'server')
        def POST(self):
            data = web.input()
            act_cls = ACTS[CB_ACT_PAY]
            rs = act_cls.get_server_list(sdk, data)
            log.debug('[ids]Server:%s', rs)
            return json.dumps(rs)
        GET = POST

    class Login(app.page):
        """登录"""
        path = '%s/%s/%s' % (api_url, sns, webapi.URL_LOGIN)
        def POST(self):
            data = web.input()
            act_cls = ACTS[CB_ACT_PAY]
            rs = act_cls.check_accout(sdk, data)
            log.debug('[ids]Login:%s', rs)
            return json.dumps(rs)
        GET = POST

    class ChenckPay(app.page):
        """支付请求"""
        path = '%s/%s/%s' % (api_url, sns, webapi.URL_CHECK_PAY)
        def POST(self):
            data = web.input()
            data.ip = web.ctx.ip
            log.info('[idsc]ChenckPay:%s', data)
            act_cls = ACTS[CB_ACT_PAY]
            code, desc = act_cls.ChenckPay(sdk, data)
            log.info('[idsc]finish ChenckPay:%s', (code, desc))
            if code == CODE_SUCC:
                return json.dumps({'err_code':0, 'desc':desc})
            else:
                return json.dumps({'err_code':1, 'desc':desc})
        GET = POST

    class CallBack(app.page):
        """支付回调"""
        path = '%s/%s/%s' % (api_url, sns, webapi.URL_CALLBACK)
        def POST(self):
            data = web.input()
            data.ip = web.ctx.ip
            log.info('[idsc]callback:%s', data)
            act_cls = ACTS[CB_ACT_PAY]
            try:
                code, desc = act_cls.GET(sdk, data)
            except:
                log.log_except()
                return json.dumps({'success':0, 'desc':'sys error'})
            log.info('[idsc]callbacked:%s', (code, desc))
            if code == CODE_SUCC:
                return json.dumps({'success':1, 'desc':desc})
            else:
                return json.dumps({'success':0, 'desc':desc})
        GET = POST


class IDS(object):
    """ 云顶破解 """
    ACT_CHECKPAY = 1
    ACT_PLAYERS = 3
    ACT_LOGIN = 4

    RN_CODE = 'ErrorCode'
    RN_DESC = 'ErrorDesc'
    def __init__(self, params):
        if isinstance(params, (str, unicode)):
            params = eval(params)
        self.app_keys = params
#        app_id, app_key = params
#        self.app_id = app_id
#        self.app_key = app_key

    def cb_init(self, web_app, api_url):
        cb_init(self, web_app, api_url)

    def get_app_key(self, app_id):
        return self.app_keys[str(app_id)]

    def get_pay_sign(self, data):
        app_id = data['appid']
        app_key = self.get_app_key(app_id)
        d = '%s%s%s%s%s%s%s' % (
                app_id, data['apporderid'], data['uid'],
                data['appmoney'], data['money'],  data['createtime'],
                app_key
                )
        return md5(d).hexdigest()

    def get_check_pay_sign(self, data):
        app_id = data['app_id']
        app_key = self.get_app_key(app_id)
        d = '%s%s%s%s%s%s%s%s%s' % (
                app_id, data['serv_id'], data['usr_id'],
                data['player_id'], data['order_id'],
                data['coin'], data['money'], data['create_time'],
                app_key
                )
        return md5(d).hexdigest()









