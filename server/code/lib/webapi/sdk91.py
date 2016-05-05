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
    FIELDS = ('AppId', 'Act', 'ProductName', 'ConsumeStreamId', 'CooOrderSerial',
            'Uin', 'GoodsId', 'GoodsInfo', 'GoodsCount', 'OriginalMoney',
            'OrderMoney', 'Note', 'PayStatus', 'CreateTime', 'Sign')

    F_PORDER = 'CooOrderSerial' #待支付流水号
    F_TORDER = 'ConsumeStreamId'#支付商流水号
    F_STATUS = 'PayStatus' #是否成功支付:'1'=成功, '0'=失败
    F_PRICE = 'OrderMoney' #实际总价(格式:0.00)

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
#        log.info('[sdk91Pay]PayCallBack:%s', data)
        for fn in cls.FIELDS:
            if fn not in data:
                log.warn('[sdk91Pay]Param not found:%s', fn)
                return CODE_PARAM, ''
        #算md5需要用utf8编码
        data_utf8 = dict([(k,v.encode('utf8')) for k,v in data.iteritems()])
        sign = data['Sign']
        sign_t = ''.join(['%%(%s)s' % fn for fn in cls.FIELDS[:-1]])
        sign_str = '%s%s' % (sign_t % data_utf8, sdk.app_key)
        md5_str = md5(sign_str).hexdigest()
        if sign != md5_str:
            log.warn('[sdk91Pay]sign error:%s != %s (%s)', sign, md5_str, sign_str)
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
    return json.dumps(dict(ErrorCode=code, ErrorDesc=desc))

def cb_init(sdk91, app, api_url):
    """ 设置回调处理 """
    sns = webapi.SNS_URLS[webapi.SNS_91]
    class Api91Login(app.page):
        """ 玩家登录 """
        path = '%s/%s/%s' % (api_url, sns, webapi.URL_LOGIN)
        def GET(self):
            """ /api/91login?sid=xxxx&session=xxxxx """
            data = web.input(_method='GET')
            log.debug('sdk91.login:%s', data)
            rs, code, desc = sdk91.login(data['sid'], data['session'])
            return json.dumps((int(rs), code, desc))

    class Api91HasPay(app.page):
        """ 查询支付结果,被动式 """
        path = '%s/%s/%s' % (api_url, sns, webapi.URL_HAS_PAY)
        def GET(self):
            """ /api/91pay?CooOrderSerial=xxxx """
            data = web.input(_method='GET')
            rs, desc = sdk91.has_pay(data['CooOrderSerial'])
            return json.dumps((int(rs), desc))

    class Api91CheckPay(app.page):
        """ 查询支付结果,主动式 """
        path = '%s/%s/%s' % (api_url, sns, webapi.URL_CHECK_PAY)
        def GET(self):
            """ /api/91pay?CooOrderSerial=xxxx """
            data = web.input(_method='GET')
            rs, code, desc = sdk91.check_pay(data['CooOrderSerial'])
            return json.dumps((int(rs), code, desc))

#    class Api91PlayerList(app.page):
#        """ 查询应用的用户列表 """
#        path = '%s/sdk91/players' % api_url
#        def GET(self):
#            """ ?page=1&size=10 """
#            data = web.input(_method='GET')
#            rs, code, desc = sdk91.check_pay(data['page'], data['size'])
#            return json.dumps((int(rs), code, desc))

    class CallBack(app.page):
        """
        例子:
        [03-04 17:04:22]p2640{sdk91:127}INFO-91.callback:<Storage
        {'ProductName': u'\u6307\u70b9\u771f\u9f99', 'GoodsInfo': u'\u554aSee',
        'OriginalMoney': u'10.00', 'Act': u'1', 'Uin': u'385577041',
        'Note': u'sdfsfsdfsfddfsdfsf',
        'CooOrderSerial': u'e6d214e87a9f4e24be76bec400007500',
        'GoodsId': u'10001', 'OrderMoney': u'9.00',
        'ConsumeStreamId': u'5-26905-20130304170422-900-1627',
        'AppId': u'104946', 'PayStatus': u'1',
        'Sign': u'62d38c67c2b52150b7e007e8dbd2fc0f',
        'CreateTime': u'2013-03-04 17:04:22',
        'GoodsCount': u'1', 'ProductId': u'104946'}>
        """
        path = '%s/%s/%s' % (api_url, sns, webapi.URL_CALLBACK)
        def GET(self):
            data = web.input(_method='GET')
            ip = web.ctx.environ.get('HTTP_X_REAL_IP', None)
            data.ip = ip if ip else web.ctx.ip
            log.info('[sd91]callback:%s', data)
            act = data['Act']
            if act not in ACTS:
                return make_result(CODE_ACT, 'no found')
            act_cls = ACTS[act]
            code, desc = act_cls.GET(sdk91, data)
            log.info('[sd91]callback:%s', (code, desc))
            return make_result(code, desc)

class SDK91(object):
    """ sdk91接口 """
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
        self.host, self.port, self.url = urls

    def cb_init(self, web_app, api_url):
        cb_init(self, web_app, api_url)

    def has_pay(self, CooOrderSerial):
        """ 检查是否支付成功,被动式 """
        pay_cls = ACTS[CB_ACT_PAY]
        rs, err = pay_cls.has_pay(CooOrderSerial)
        return rs, err

    def login(self, sid, session_id):
        """ 登陆验证 """
#        return 1, 0, None
        sign = md5('%s%s%s%s%s' % \
            (self.app_id, self.ACT_LOGIN, sid, session_id, self.app_key)).hexdigest()
        params = dict(AppId=self.app_id, Act=self.ACT_LOGIN,
                Uin=sid, Sign=sign, SessionID=session_id)
        data = http_post_ex(self.host, self.port, self.url, params)
        if data is None:
            return 0, CODE_FAIL, 'timeout'
        data = json.loads(data)
        return data[self.RN_CODE] == '1', data[self.RN_CODE], data[self.RN_DESC]

    def check_pay(self, CooOrderSerial):
        """ 检查是否支付成功,主动式 """
        sign = md5('%s%s%s%s' %\
                   (self.app_id, self.ACT_CHECKPAY, CooOrderSerial, self.app_key)).hexdigest()
        params = dict(AppId=self.app_id, Act=self.ACT_CHECKPAY,
            CooOrderSerial=CooOrderSerial, Sign=sign,)
        data = http_post_ex(self.host, self.port, self.url, params)
        if data is None:
            return False, CODE_FAIL, 'timeout'
        data = json.loads(data)
        return data[self.RN_CODE] == '1', data[self.RN_CODE], data[self.RN_DESC]

    def get_players(self, PageNo, PageSize):
        """ 获取应用的玩家列表 """
        sign = md5('%s%s%s%s%s' %\
                   (self.app_id, self.ACT_PLAYERS, PageNo, PageSize, self.app_key)).hexdigest()
        params = dict(AppId=self.app_id, Act=self.ACT_PLAYERS,
            PageNo=PageNo, PageSize=PageSize,
            Sign=sign,)
        data = http_post_ex(self.host, self.port, self.url, params)
        if data is None:
            return False, CODE_FAIL, 'timeout'
        data = json.loads(data)
        return data[self.RN_CODE] == '1', data[self.RN_CODE], data

#class SDK91Client(object):
#    """ 客户端 """
#    def __init__(self, host, port, api_url):
#        self.host, self.port = host, port
#        self.url = '%s/sdk91' % api_url
#        self.init_url()
#
#    def init_url(self):
#        self.login_url = '%s/login' % self.url
#        self.pay_url = '%s/login' % self.url
#
#    def login(self, sid, session):
#        """ 玩家登陆 """
#        data = http_post_ex(self.host, self.port, self.login_url,
#                params=dict(sid=sid, session=session))
#        if not data:
#            return 0, errcode.EC_NET_ERR
#        rs, code, desc = json.loads(data)
#        if not rs:
#            log.error('sdk91Client.login error:%s, %s, %s', rs, code, desc)
#            return 0, (code, desc)
#        return 1, None
#
#    def has_pay(self, CooOrderSerial):
#        """ 查询支付结果 """
#        params = dict(CooOrderSerial=CooOrderSerial)
#        data = http_post_ex(self.port, self.port, self.url, params=params)
#        if not data:
#            return 0, errcode.EC_NET_ERR
#        rs, code, desc = json.loads(data)
#        if not rs:
#            log.error('sdk91Client.has_pay error:%s, %s, %s', rs, code, desc)
#            return 0, (code, desc)
#        return 1, None




