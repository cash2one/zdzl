#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import json, log
from corelib.tools import http_post_ex

#平台类型
SNS_NONE = 0
SNS_91 = 1 #91
SNS_DPAY = 2 # 点金
SNS_EFUN = 3 # 官网
SNS_PP = 4  # pp助手
SNS_APP = 5 #app store
SNS_APPTW = 6 # app store 台湾
SNS_IDS = 7 #云顶
SNS_UC = 8 #uc
SNS_IDSC = 9 #云顶破解平台
SNS_TONGBU = 10 #同步推
SNS_DCN = 11 #当乐
SNS_PP_APPLE = 12 #PP苹果园

SNS_MAP = {
    SNS_NONE: u'不分平台',
    SNS_91: u'91',
    SNS_DPAY: u'点金',
    SNS_EFUN: u'官网',
    SNS_PP: u'pp助手',
    SNS_APP: u'app store',
    SNS_APPTW: u'app store 台湾',
    SNS_IDS: u'云顶',
    SNS_UC: u'uc',
    SNS_IDSC: u'云顶破解平台',
    SNS_TONGBU: u'同步推',
    SNS_DCN: u'当乐',
    SNS_PP_APPLE: u'PP苹果园'
}

#任务表类型描述
# TASK_TYPE_MAP = {1: u'主线任务', 4: u'隐藏任务', 3: u'特殊任务', 2: u'支线任务'}

#需要登陆检查的sns
SNS_LOGINS = tuple()# {SNS_PP}
SNS_ALL = {SNS_91, SNS_DPAY, SNS_EFUN, SNS_PP, SNS_APP, SNS_APPTW,
        SNS_IDS, SNS_IDSC, SNS_UC, SNS_TONGBU, SNS_DCN, SNS_PP_APPLE
        }

SNS_URLS = {
    SNS_91: 'sdk91',
    SNS_DPAY: 'dpay',
    SNS_PP: 'pp',
    SNS_PP_APPLE: 'pp',
    SNS_APP: 'app',
    SNS_APPTW: 'apptw',
    SNS_IDS: 'appyd',
    SNS_UC: 'uc',
    SNS_TONGBU: 'tongbu',
    SNS_IDSC: 'idsc',
    SNS_DCN: 'dcn',
    }

#平台账号互通配置
SNS_EQUALS = {
    SNS_PP: (SNS_PP, SNS_PP_APPLE),
    SNS_PP_APPLE: (SNS_PP, SNS_PP_APPLE),
    SNS_IDS: (SNS_IDS, SNS_IDSC),
    SNS_IDSC: (SNS_IDS, SNS_IDSC),
}


URL_LOGIN = 'login'
URL_HAS_PAY = 'hasPay'
URL_CHECK_PAY = 'checkPay'
URL_CALLBACK = 'callback'
URL_GETORDER = 'getorder'

#error code
EC_VALUE = 1            #数值错误
EC_NOFOUND = 11         #找不到
EC_NET_ERR = 18         #网络连接错误

class BaseAct(object):
    @classmethod
    def GET(cls, sdk, data):
        """ do http GET """

    @classmethod
    def pay_exist(cls, torder):
        raise NotImplementedError

    @classmethod
    def save_data(cls, porder, torder, status, price, data):
        """ 保存 """
        raise NotImplementedError

#    @classmethod
#    def save_torder(cls, torder, status, price, data):
#        """保存只有torder商家号的log"""
#        raise NotImplementedError
#
#    @classmethod
#    def pay_handle(cls, torder):
#        """保存只有torder商家号的log"""
#        raise NotImplementedError

    @classmethod
    def get_pre_pay(cls, porder):
        raise NotImplementedError

    @classmethod
    def save(cls, obj):
        raise NotImplementedError

class SNSClient(object):
    """ 客户端 """
    res_store = None
    def __init__(self, host, port, api_url):
        self.host, self.port = host, port
        self.url = api_url
#        self.init_url()

#    def init_url(self):
#        self.login_url = '%s/login' % self.url
#        self.pay_url = '%s/login' % self.url

    def get_url(self, sns, t):
        return '%s/%s/%s' % (self.url, SNS_URLS[sns], t)

    def login(self, sns, sid, session):
        """ 玩家登陆 """
        global snss
        #todo 91验证不是必要的,暂时屏蔽
        if sns not in SNS_LOGINS:
            return 1, None
        #改用本地模块直接和sns商通讯
        if sns not in snss:
            return 0, EC_NOFOUND
        return snss[sns].login(sid, session)

#        url = self.get_url(sns, URL_LOGIN)
#        data = http_post_ex(self.host, self.port, url,
#            params=dict(sid=sid, session=session))
#        log.debug('sns.login:%s, %s', url, data)
#        if not data:
#            return 0, EC_NET_ERR
#        rs, code, desc = json.loads(data)
#        if not rs:
#            log.error('SNSClient.login error:%s, %s, %s', rs, code, desc)
#            return 0, EC_VALUE
#            #return 0, (code, desc)
#        return 1, None

    def has_pay(self, sns, CooOrderSerial):
        """ 查询支付结果 """
        params = dict(CooOrderSerial=CooOrderSerial)
        url = self.get_url(sns, URL_HAS_PAY)
        data = http_post_ex(self.port, self.port, url, params=params)
        if not data:
            return 0, EC_NET_ERR
        rs, code, desc = json.loads(data)
        if not rs:
            log.error('SNSClient.has_pay error:%s, %s, %s', rs, code, desc)
            return 0, (code, desc)
        return 1, None

    @classmethod
    def pay(cls, porder, pay_id, **kw):#, res_store):
        """ 主动检查式 """
        from game.base import errcode
        from game.res.shop import PrePay, Pay
        res_store = cls.res_store


        pre_pay = PrePay.load_ex(res_store, dict(porder=porder))
        if not pre_pay:
            log.error('[sns]****error: porder(%s) no found', porder)
            return False, errcode.EC_VALUE

        sns_type = pre_pay.t
        log.info('[pay-%d](%s)(%s, %s)', sns_type, pre_pay.pid, porder, pay_id)
        #检查是否支付成功
        sns = snss[pre_pay.t]
        c = 3
        rs, torder, data = False, None, None
        while c > 0:
            try:
                rs, torder, data = sns.pay(pay_id, pre_pay.pd, **kw)
                if not rs:
                    log.error('[sns(%s)]pay error:%s', pre_pay.t, data)
                    return False, errcode.EC_VALUE
                break
            except:
                log.log_except('[sns(%s)]pay error', pre_pay.t)
                c -= 1
        if not rs:
            return False, errcode.EC_VALUE

        #是否已经存在
        if Pay.pay_exist(sns_type, torder, res_store):
            log.info('[sns(%s)]torder(%s) exist!', sns_type, torder)
            return True, None

        if not Pay.check(porder, res_store):
            log.info('[sns(%s)]porder(%s) exist!', sns_type, porder)
            return False, errcode.EC_VALUE


        #支付检查成功后,保存数据
        pay = Pay()
        pay.prepare(True, torder, pre_pay, data)
        pay.save(res_store)
        log.info('[sns(%s)]save_data(%s) done', pre_pay.t, porder)
        return True, None

#    @classmethod
#    def pay1(cls, t, torder, pre_pay, res_store):
#        from game.base import errcode
#        from game.res.shop import PrePay, Pay
#
#        pay = Pay.load_ex(res_store, dict(torder=torder, t=t))
#        if not pay:
#            log.error('[sns(%s)]****pay1 error: torder(%s) pay no found',
#                t, torder)
#            return
#
#        pay.update_torder(pre_pay)
#        pay.save(res_store)
#        log.info('[sns(%s)]save_data(%s) done', pre_pay.t, pre_pay.porder)


snss = None
def init_snss(params, web_app=None, api_url=None):
    """ 初始化sns对象 """
    global snss
    if snss is not None:
        return snss
    from . import sdk91, dpay, pp, app_store, uc, dcn, tb, ids

    snss = {}
    if params[SNS_91]:
        snss[SNS_91] = sdk91.SDK91(*params[SNS_91])
        log.info('[init_sns]SNS_91 ok')

    if params[SNS_DPAY]:
        snss[SNS_DPAY] = dpay.DPay(*params[SNS_DPAY])
        log.info('[init_sns]SNS_DPAY ok')

    if params[SNS_PP]:
        snss[SNS_PP] = pp.PP(*params[SNS_PP])
        log.info('[init_sns]SNS_PP ok')

    if params[SNS_APP]:
        snss[SNS_APP] = app_store.AppStore(SNS_APP, *params[SNS_APP])
        log.info('[init_sns]SNS_APP ok')

    if params[SNS_APPTW]:
        snss[SNS_APPTW] = app_store.AppStore(SNS_APPTW, *params[SNS_APPTW])
        log.info('[init_sns]SNS_APPTW ok')

    if params[SNS_UC]:
        snss[SNS_UC] = uc.UC(*params[SNS_UC])
        log.info('[init_sns]SNS_UC ok')

    if params[SNS_DCN]:
        snss[SNS_DCN] = dcn.DCN(*params[SNS_DCN])
        log.info('[init_sns]SNS_DCN ok')

    if params[SNS_TONGBU]:
        snss[SNS_TONGBU] = tb.TongBu(*params[SNS_TONGBU])
        log.info('[init_sns]SNS_TONGBU ok')

    if params[SNS_IDS]:
        snss[SNS_IDS] = app_store.AppStore(SNS_IDS, *params[SNS_IDS])
        log.info('[init_sns]SNS_IDS ok')

    if params[SNS_IDSC]:
        snss[SNS_IDSC] = ids.IDS(*params[SNS_IDSC])
        log.info('[init_sns]SNS_IDSC ok')

    if web_app is not None:
        for sns in snss.itervalues():
            if not hasattr(sns, 'cb_init'):
                continue
            sns.cb_init(web_app, api_url)

#        if SNS_91 in snss:
#            snss[SNS_91].cb_init(web_app, api_url)
#        if SNS_DPAY in snss:
#            snss[SNS_DPAY].cb_init(web_app, api_url)
#        if SNS_PP in snss:
#            snss[SNS_PP].cb_init(web_app, api_url)
#        if SNS_UC in snss:
#            snss[SNS_UC].cb_init(web_app, api_url)
#        if SNS_DCN in snss:
#            snss[SNS_DCN].cb_init(web_app, api_url)
#        if SNS_TONGBU in snss:
#            snss[SNS_TONGBU].cb_init(web_app, api_url)

    return snss


