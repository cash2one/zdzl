#!/usr/bin/env python
# -*- coding:utf-8 -*-
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
PAY_STATUS_SUCC = '0'
PAY_STATUS_PASS = 1 #已兑换过并成功返回

#参数名

CMD_LOGIN = int('0xAA00F022', 0)
LEN_UINT32 = struct.calcsize('I')
LEN_UINT64 = struct.calcsize('Q')


class AbsPay(webapi.BaseAct):
    FIELDS = ('order_id', 'billno',
            'account', 'amount',
            'status', 'app_id',
            'uuid', 'roleid',
            'zone',
            'sign')
    F_STATUS = 'status' #是否成功支付
    F_PORDER = 'roleid' #billno是整形(厂商订单号),不合适,改用roleid
    F_TORDER = 'order_id'#兑换订单号
    F_PRICE = 'amount' #兑换PP币数量

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
#        log.info('[pp]PayCallBack:%s', data)
        for fn in cls.FIELDS:
            if fn not in data:
                log.warn('[pp]Param not found:%s', fn)
                return CODE_PARAM, ''

        #rsa验证
        sign = data['sign']
        sdata = sdk.decode_sign(sign)
        for k,v in sdata.iteritems():
            if k == cls.F_STATUS:
                if int(data[k]) != int(v):
                    return CODE_SIGN, 'sign data error'
            elif data[k] != v:
                return CODE_SIGN, 'sign data error'

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
        return 'success'
    return 'fail'
#    return json.dumps(dict(ErrorCode=code, ErrorDesc=desc))

def cb_init(sdk, app, api_url):
    """ 设置回调处理 """
    sns = webapi.SNS_URLS[webapi.SNS_PP]

    class CallBack(app.page):
        """
        """
        path = '%s/%s/%s' % (api_url, sns, webapi.URL_CALLBACK)
        def POST(self):
            data = web.input()
            data.ip = web.ctx.ip
            log.info('[pp]callback:%s', data)
            key = data['app_id']
            sns = sdk.sns.get(int(key), None)
            act_cls = ACTS.get((CB_ACT_PAY, sns), None)
            if act_cls is None:
                log.info('[pp]callback err act_cls is None sns:%s app_id:%s', sns, key)
                return 'fail'
            code, desc = act_cls.GET(sdk, data)
            log.info('[pp]callbacked:%s', (code, desc))
            return make_result(code, desc)
        GET = POST

class PSPool(object):
    LIFE_TIMES = 60 * 1 #sock生命周期
    def __init__(self, host, port, max_sock):
        self.host = host
        self.port = port
        self.max_sock = max_sock
        self.socks = Queue(maxsize=max_sock)
        self.threads = {}
        self.sock_times = {}

    def init_sock(self):
        """ 初始化和pp服务器的socket """
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((self.host, self.port))
        return sock

    def get(self):
        if self.socks.empty():
            sock = self.init_sock()
            self.sock_times[sock] = time.time()
            return  sock
        return self.socks.get()

    def put(self, sock):
        times = time.time() - self.sock_times[sock]
        if times >= self.LIFE_TIMES or self.socks.full():
            self.free(sock)
            return
        self.socks.put(sock)

    def free(self, sock):
        self.sock_times.pop(sock, None)
        try:
            sock.close()
        except:
            pass

    def __enter__(self):
        cur_thread = getcurrent()
        if cur_thread in self.threads:
            raise ValueError('not support reenter')
        self.threads[cur_thread] = self.get()
        return self.threads[cur_thread]

    def __exit__(self, exc_type, exc_val, exc_tb):
        sock = self.threads.pop(getcurrent())
        if exc_type is None:
            self.put(sock)
        else:
            self.free(sock)


class PP(object):
    """ 平台接口 """
    ACT_CHECKPAY = 1
    ACT_PLAYERS = 3
    ACT_LOGIN = 4

    RN_CODE = 'ErrorCode'
    RN_DESC = 'ErrorDesc'
    def __init__(self, urls, rsa_key, key, max_sock=10):
        self.init_key(key)
        if isinstance(rsa_key, unicode):
            rsa_key = rsa_key.encode('ascii')
        self.rsa_key = rsa_key
        self.init_rsa_M2C()

        if isinstance(urls, (str, unicode)):
            urls = eval(urls)
        self.host, self.port, self.url = urls
        self.pool = PSPool(self.host, self.port, max_sock=max_sock)

    def init_key(self, key):
        self.key = {}
        self.sns = {}
        key=eval(key)
        for o in key:
            app_id, app_key, sns = o
            self.key[app_id] = app_key
            self.sns[app_id] = sns

    def cb_init(self, web_app, api_url):
        cb_init(self, web_app, api_url)

    def decode_sign(self, sign):
        d = b64decode(sign)
        sign = self.rsa_decode(d)
        return json.loads(sign)

    def init_rsa_M2C(self):
        from M2Crypto import RSA, BIO
        self.rsa = RSA.load_pub_key_bio(BIO.MemoryBuffer(self.rsa_key))
        self.rsa_decode = lambda d: self.rsa.public_decrypt(d, RSA.pkcs1_padding)
        self.rsa_encode = lambda d: self.rsa.public_encrypt(d, RSA.pkcs1_padding)

#    def init_rsa_Cry(self):
#        """ 有问题,未完成 """
#        from Crypto.PublicKey import RSA
#        from Crypto.Cipher import PKCS1_v1_5
#        key = RSA.importKey(self.rsa_key)
#        self.rsa = PKCS1_v1_5.new(key)
#        self.rsa_decode = self.rsa.decrypt
#        self.rsa_decode = self.rsa.encrypt

    def recv(self, sock, size):
        rs = []
        l = 0
        while l < size:
            d = sock.recv(size - l)
            if not d:
                return ''
            l += len(d)
            rs.append(d)
        return ''.join(rs)

    def recv_pack(self, sock):
        """ 收取一包 """
        d = self.recv(sock, LEN_UINT32)
        l = struct.unpack('<I', d)[0]
        l = l - LEN_UINT32
        d = self.recv(sock, l)
        return d

    def login(self, sid, session_id):
        """ 登陆检查 """
        ltoken = len(session_id)
        l = LEN_UINT32 + LEN_UINT32 + ltoken
        d = struct.pack('<II%ds' % ltoken, l, CMD_LOGIN, session_id)

        data = None
        with self.pool as sock:
            sock.sendall(d)
            data = self.recv_pack(sock)

        if not data:
            return 0, webapi.EC_VALUE

        #解释返回数据
        lname = len(data) - LEN_UINT32 + LEN_UINT32 + LEN_UINT64
        cmd, status, name, uid = struct.unpack('<II%dsQ' % lname, data)
        if status != PAY_STATUS_SUCC:
            log.warn('[pp]login fail:%s', (cmd, status, name, uid))
            return 0, webapi.EC_NET_ERR
        return 1, uid







