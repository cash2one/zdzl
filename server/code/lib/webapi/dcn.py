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
    FIELDS = ['result', 'money',  'order',
              'mid','time', 'signature',
              'ext']

    F_STATUS = 'result' #是否成功支付
    F_TORDER = 'order'#商家订单号
    F_PORDER = 'ext' #本地订单号
    F_PRICE = 'money' #单位：元

    @classmethod
    def is_ok(cls, data):
        return data[cls.F_STATUS] == PAY_STATUS_SUCC

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
               log.warn('[DCN]Param not found:%s, data:%s', attr, data)
               return CODE_PARAM, ''

        #rsa验证
        sign = data['signature']
        sdata = sdk.get_pay_sign(data)
        if sdata != sign:
            log.warn('[DCN]sign data error, sign(%s) sdata(%s)', sign, sdata)
            return CODE_SIGN, 'sign data error'

        if cls.pay_exist(data[cls.F_TORDER]):
            return CODE_SUCC, 'payExistError'
            #保存
        try:
            if cls.save_data(
                data[cls.F_PORDER],
                data[cls.F_TORDER],
                cls.is_ok(data),
                data[cls.F_PRICE],
                data):
                return CODE_SUCC, 'save'
        except:
            log.log_except()
        return CODE_FAIL, 'systemError'

ACTS = {CB_ACT_PAY:AbsPay}


def make_result(code, desc):
    if code == CODE_SUCC:
        return 'success'
    return ''

def cb_init(sdk, app, api_url, callback=1):
    """ 设置回调处理 """
    sns = webapi.SNS_URLS[webapi.SNS_DCN]
    class Login(app.page):
        """ 登陆查询 """
        path = '%s/%s/%s' % (api_url, sns, webapi.URL_LOGIN)
        def POST(self):
            data = web.input()
            rs = sdk.login(data['mid'], data['token'])
            log.debug('[DCN]login:%s', rs)
            return rs
        GET = POST

    if callback:
        class CallBack(app.page):
            """支付回调"""
            path = '%s/%s/%s' % (api_url, sns, webapi.URL_CALLBACK)
            def GET(self):
                data = web.input()
                data.ip = web.ctx.ip
                log.info('[DCN]callback:%s', data)
                act_cls = ACTS[CB_ACT_PAY]
                code, desc = act_cls.GET(sdk, data)
                log.info('[DCN]callbacked:%s', (code, desc))
                return make_result(code, desc)
            POST = GET

class DCN(object):
    """ 当乐平台接口 """
    sdk_host = 'connect.d.cn'
    LOGIN_PATH = '/open/member/info'

    def __init__(self, params):
        if isinstance(params, (str, unicode)):
            params = eval(params)
        app_id, merchant_id, app_key, payment_key = params
        self.app_id = app_id
        self.merchant_id = merchant_id
        self.app_key = app_key
        self.payment_key = payment_key

    def cb_init(self, web_app, api_url, **kw):
        cb_init(self, web_app, api_url, **kw)

    def get_pay_sign(self, data):
        d = 'order=%s&money=%s&mid=%s&time=' \
            '%s&result=%s&ext=%s&key=%s' % (
            data['order'], data['money'], data['mid'],
            data['time'], data['result'], data['ext'],
            self.payment_key
            )
        return md5(d).hexdigest()

    def get_login_sign(self, token):
        d = '%s|%s' % (self.app_key, token)
        return md5(d).hexdigest()

    def login(self, mid, token):
        """ 登陆检查,查询结果直接返回给前端处理 """
        sig = self.get_login_sign(token)
        data = dict(
            app_id=self.app_id,
            mid=mid,
            token=token,
            sig=sig
        )
        rs = http_post_ex(self.sdk_host, 80, self.LOGIN_PATH, params=data)
        if not rs:
            return ''
        return rs

