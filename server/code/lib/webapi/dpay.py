#!/usr/bin/env python
# -*- coding:utf-8 -*-
from hashlib import md5
import web

from corelib import json, log
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

#支付状态：0=失败，1=成功
PAY_STATUS_FAIL = '0'
PAY_STATUS_SUCC = '1'

#参数名



class AbsPay(webapi.BaseAct):
    FIELDS = ('App_Id', 'Create_Time',
              'Extra', 'Pay_Status',
              'Recharge_Gold_Count', 'Recharge_Money',
              'Uin', 'Urecharge_Id',
              'Sign')
    F_STATUS = 'Pay_Status' #是否成功支付
    F_PORDER = 'Urecharge_Id' #待支付流水号
    F_TORDER = 'Urecharge_Id'#开发者自身订单 ID
    F_PRICE = 'Recharge_Money' #充值金额-人民币, 单位元,精确到分

    @classmethod
    def is_ok(cls, data):
        return data[cls.F_STATUS] == PAY_STATUS_SUCC

    @classmethod
    def has_pay(cls, CooOrderSerial):
        """ 91被动接口: 检查是否支付成功 """
        raise NotImplementedError

    @classmethod
    def GET(cls, sdk, data):
        """ 收到回调,处理数据 """
        #校验
#        log.info('[dpay]PayCallBack:%s', data)
        for fn in cls.FIELDS:
            if fn not in data:
                log.warn('[dpay]Param not found:%s', fn)
                return CODE_PARAM, ''
        #算md5需要用utf8编码
        data_utf8 = dict([(k,v.encode('utf8')) for k,v in data.iteritems()])
        sign = data['Sign']
        sign_t = '&'.join(['%s=%%(%s)s' % (fn, fn) for fn in cls.FIELDS[:-1]])
        sign_str = '%s%s' % (sign_t % data_utf8, sdk.app_key)
        if isinstance(sign_str, unicode):
            sign_str = sign_str.encode('ascii')
        md5_str = md5(sign_str).hexdigest()
        if sign != md5_str:
            log.warn('[dpay]sign error:%s != %s (%s)', sign, md5_str, sign_str)
            return CODE_SIGN, ''
        if cls.pay_exist(data[cls.F_TORDER]):
            return CODE_SUCC, ''
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

ACTS = {CB_ACT_PAY:AbsPay}

def make_result(code, desc):
    if code == CODE_SUCC:
        return 'Success'
    return json.dumps(dict(ErrorCode=code, ErrorDesc=desc))

def cb_init(sdk, app, api_url):
    """ 设置回调处理 """
    sns = webapi.SNS_URLS[webapi.SNS_DPAY]

    class CallBack(app.page):
        """
        """
        path = '%s/%s/%s' % (api_url, sns, webapi.URL_CALLBACK)
        def GET(self):
            data = web.input()
            data.ip = web.ctx.ip
            log.info('[dpay]callback:%s', data)
            act_cls = ACTS[CB_ACT_PAY]
            code, desc = act_cls.GET(sdk, data)
            log.info('[dpay]callbacked:%s', (code, desc))
            return make_result(code, desc)
        POST = GET

class DPay(object):
    """ 点金平台接口 """
    ACT_CHECKPAY = 1
    ACT_PLAYERS = 3
    ACT_LOGIN = 4

    RN_CODE = 'ErrorCode'
    RN_DESC = 'ErrorDesc'
    def __init__(self, app_id, app_key, urls):
        self.app_id = app_id
        self.app_key = app_key
        if isinstance(urls, (str, unicode)):
            urls = eval(urls)
#        log.debug('[dpay]urls:%s', urls)
        self.host, self.port, self.url = urls

    def cb_init(self, web_app, api_url):
        cb_init(self, web_app, api_url)

    def has_pay(self, CooOrderSerial):
        """ 检查是否支付成功,被动式 """
        pay_cls = ACTS[CB_ACT_PAY]
        rs, err = pay_cls.has_pay(CooOrderSerial)
        return rs, err





