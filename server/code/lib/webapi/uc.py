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
PAY_STATUS_FAIL = 'F'
PAY_STATUS_SUCC = 'S'

#参数名


class AbsPay(webapi.BaseAct):
    FIELDS = {'data': {'orderId': None, 'gameId': None, 'serverId': None,
                        'ucid': None, 'payWay': None, 'amount': None,
                        'callbackInfo': None, 'orderStatus': None,
                        'failedDesc': None},
              'sign': None
            }

    F_STATUS = 'orderStatus' #是否成功支付
    F_TORDER = 'orderId'#商家订单号
    F_PORDER = 'callbackInfo' #本地订单号
    F_PRICE = 'amount' #单位：元

    @classmethod
    def is_ok(cls, data):
        return data[cls.F_STATUS] == PAY_STATUS_SUCC

    @classmethod
    def has_pay(cls, CooOrderSerial):
        """ 被动接口: 检查是否支付成功 """
        raise NotImplementedError

    @classmethod
    def check_attr(cls, adict, data):
        for k, v in adict.iteritems():
            if k not in data:
                log.warn('[uc]Param not found:%s, data:%s', k, data)
                return False
            if isinstance(v, dict):
                rs = cls.check_attr(v, data[k])
                if not rs:
                    return False
        return True

    @classmethod
    def GET(cls, sdk, data):
        """ 收到回调,处理数据 """
        #校验
        rs = cls.check_attr(cls.FIELDS, data)
        if not rs:
            return CODE_PARAM, ''
        #rsa验证
        sign = data['sign']
        data = data['data']
        sdata = sdk.get_sign(data)
        if sdata != sign:
            log.warn('[uc]sign data error, sign(%s) sdata(%s)', sign, sdata)
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
        return 'SUCCESS'
    return 'FAILURE'

def cb_init(sdk, app, api_url, callback=1):
    """ 设置回调处理 """
    sns = webapi.SNS_URLS[webapi.SNS_UC]
    class Login(app.page):
        """ 登陆查询 """
        path = '%s/%s/%s' % (api_url, sns, webapi.URL_LOGIN)
        def POST(self):
            data = web.input()
            rs = sdk.login(data['sid'])
            log.debug('[UC]login:%s', rs)
            return rs
        GET = POST

    if callback:
        class CallBack(app.page):
            """支付回调"""
            path = '%s/%s/%s' % (api_url, sns, webapi.URL_CALLBACK)
            def POST(self):
                d = web.data()
                data = json.loads(d)
                data['ip'] = web.ctx.ip
                log.info('[UC]callback:%s', str(data))
                act_cls = ACTS[CB_ACT_PAY]
                code, desc = act_cls.GET(sdk, data)
                log.info('[UC]callbacked:%s', (code, desc))
                return make_result(code, desc)
            GET = POST


class UC(object):
    """ uc平台接口 """
    ACT_CHECKPAY = 1
    ACT_PLAYERS = 3
    ACT_LOGIN = 4

    RN_CODE = 'ErrorCode'
    RN_DESC = 'ErrorDesc'
    sdk_host = 'sdk.g.uc.cn'
    LOGIN_PATH = '/ss'
    LOGIN_SERVICE = "ucid.user.sidInfo"
    def __init__(self, params):
        if isinstance(params, (str, unicode)):
            params = eval(params)
        cpId, gameId, channelId, serverId, app_key = params
        self.cpId = cpId
        self.gameId = gameId
        self.app_key = app_key
        self.channelId = channelId
        self.serverId = serverId
        self.init()

    def init(self):
        self.game = dict(cpId=self.cpId, gameId=self.gameId,
                channelId=self.channelId, serverId=self.serverId)

    def cb_init(self, web_app, api_url, **kw):
        cb_init(self, web_app, api_url, **kw)

    def get_sign(self, kw):
        keys = kw.keys()
        keys.sort()
        l = []
        for k in keys:
            l.append('%s=%s' % (k, kw[k]))

        d = '%s%s%s' % (self.cpId, ''.join(l), self.app_key)
        return md5(d).hexdigest()

    def login(self, sid):
        """ 登陆检查,查询结果直接返回给前端处理 """
        kw = dict(sid=sid)
        sign = self.get_sign(kw)
        data = dict(id=time.time(), service=self.LOGIN_SERVICE,
                game=self.game,
                data=kw,
                sign=sign
                )
        rs = http_post_ex(self.sdk_host, 80, self.LOGIN_PATH, data=json_dumps(data))
        if not rs:
            return ''
        return rs

