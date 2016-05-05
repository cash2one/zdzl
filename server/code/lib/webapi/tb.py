#!/usr/bin/env python
# -*- coding:utf-8 -*-
from hashlib import md5
import struct
import socket
import time


import web
from gevent.queue import Queue

from corelib import json_dumps, json,  log, getcurrent
from corelib.tools import http_post_ex


import webapi

#ACT
CB_ACT_PAY = '1'
CB_ACT_LOGIN = '2'

#返回编码
CODE_FAIL = 0
CODE_SUCC = 1
CODE_APPID = 2
CODE_ACT = 3
CODE_PARAM = 4
CODE_SIGN = 5

#支付状态：
PAY_STATUS_FAIL = '0'
PAY_STATUS_SUCC = '1'

#参数名


class AbsPay(webapi.BaseAct):

    FIELDS = ['source', 'trade_no',  'amount',
              'partner','paydes', 'debug',
              'sign']

    F_STATUS = '' #是否成功支付
    F_TORDER = 'trade_no'#商家订单号
    F_PORDER = 'trade_no' #本地订单号
    F_PRICE = 'amount' #单位：分

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
        for attr in cls.FIELDS:
            if attr not in data:
                log.warn('[TongBu]Param not found:%s, data:%s', attr, data)
                return CODE_PARAM, ''

        #rsa验证
        sign = data['sign']
        sdata = sdk.get_sign(data)
        if sdata != sign:
            log.warn('[TongBu]sign data error, sign(%s) sdata(%s)', sign, sdata)
            return CODE_SIGN, 'sign data error'

        if cls.pay_exist(data[cls.F_TORDER]):
            return CODE_SUCC, 'payExistError'
            #保存
        try:
            if cls.save_data(
                data[cls.F_PORDER],
                data[cls.F_TORDER],
                cls.is_ok(data),
                int(data[cls.F_PRICE])/100,
                data):
                return CODE_SUCC, 'save'
        except:
            log.log_except()
        return CODE_FAIL, 'systemError'

ACTS = {CB_ACT_PAY:AbsPay}

def make_result(code, desc):
    if code == CODE_SUCC:
        return json.dumps({'status':'success'})
    return ''

def cb_init(sdk, app, api_url, callback=1):
    """ 设置回调处理 """
    sns = webapi.SNS_URLS[webapi.SNS_TONGBU]
    if callback:
        class CallBack(app.page):
            """支付回调"""
            path = '%s/%s/%s' % (api_url, sns, webapi.URL_CALLBACK)
            def GET(self):
                data = web.input()
                data.ip = web.ctx.ip
                log.info('[TongBu]callback:%s', data)
                act_cls = ACTS[CB_ACT_PAY]
                code, desc = act_cls.GET(sdk, data)
                log.info('[TongBu]callbacked:%s', (code, desc))
                return make_result(code, desc)
            POST = GET

class TongBu(object):
    """ 同步平台接口 """
    def __init__(self, params):
        if isinstance(params, (str, unicode)):
            params = eval(params)
        app_id, app_key = params
        self.app_id = app_id
        self.app_key = app_key

    def cb_init(self, web_app, api_url, **kw):
        cb_init(self, web_app, api_url, **kw)

    def get_sign(self, data):
        d = 'source=%s&trade_no=%s&amount=%s&partner='\
            '%s&paydes=%s&debug=%s&key=%s' % (
                data['source'], data['trade_no'], data['amount'],
                data['partner'], data['paydes'], data['debug'],
                self.app_key
                )
        return md5(d).hexdigest()