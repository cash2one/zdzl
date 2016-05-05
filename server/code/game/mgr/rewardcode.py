#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time

from game import Game
from game.base import errcode
from game.base import common
from game.base.msg_define import MSG_START, MSG_RES_RELOAD
from game.store import GameObj, StoreObj
from game.store.define import  TN_RES_EXCHANGE_CODE, TN_RES_EXCHANGE_CODE_LOG

from corelib import sleep, spawn_later, log

class CodeLogData(StoreObj):
    def init(self):
        self.id = None
        self.name = ''         #批次名称
        self.code = ''         #兑换码
        self.gt = 0             #领取时间
        self.svr = 0           #领取服
        self.uid = 0            #领取账号id
        self.pid = 0            #领取角色id

class CodeLog(GameObj):
    TABLE_NAME = TN_RES_EXCHANGE_CODE_LOG
    DATA_CLS = CodeLogData

    @classmethod
    def find(cls, name, uid, pid):
        return Game.rpc_res_store.query_loads(cls.TABLE_NAME, dict(name=name, uid=uid, pid=pid))

    def new(self, data):
        self.data.name = data['name']
        self.data.gt = data['gt']
        self.data.code = data['code']
        self.data.uid = data['uid']
        self.data.pid = data['pid']
        self.data.svr = Game.rpc_client.get_server_id()
        self.save(Game.rpc_res_store, forced = True)

class CodeData(StoreObj):

    def init(self):
        self.id = None
        self.name = ''          #批次名称
        self.ct = 0             #创建批次时间
        self.et = 0             #结束时间
        self.one = 0            #一个角色是否只能领取一次
        self.code = ""          #兑换码
        self.rid = 0            #奖励id
        self.svrs = ""         #特定服列表
        self.num = 0            #可用次数


class ExchangeCode(GameObj):

    TABLE_NAME = TN_RES_EXCHANGE_CODE
    DATA_CLS = CodeData

    @property
    def is_one(self):
        return bool(int(self.data.one))

    def exchange(self, uid, pid):
        """ 奖励完成保存要保存的数据 """
        d = self.data
        d.num = d.num - 1 if d.num > 0 else 0
        c_log = CodeLog()
        data ={}
        data['gt'] = common.current_time()
        data['code'] = self.data.code
        data['uid'] = uid
        data['pid'] = pid
        data['name'] = self.data.name
        c_log.new(data)
        self.save(Game.rpc_res_store, forced = True)

class ExchangeCodeMgr(object):
    _rpc_name_ = 'rpc_ex_code_mgr'

    def __init__(self):
        self.codes = {} #{codestr : obj}

    def pre_exchange(self, strcode, uid, pid):
        """ 领取之前的检测 """
        t_lis = Game.rpc_res_store.query_loads(ExchangeCode.TABLE_NAME, dict(code=strcode))
        if not t_lis:
            return False, errcode.EC_CODE_EXCHANGE_INVALID
        if len(t_lis) > 1:
            log.error("the exchange code :%s must exit only one but exit %s", strcode, len(t_lis))

        #特定服

        _obj = ExchangeCode(t_lis[0])
        if _obj.data.num <= 0:
            return False, errcode.EC_CODE_EXCHANGE_INVALID

        if common.current_time() > _obj.data.et:
            return False, errcode.EC_CODE_EXCHANGE_PASS

        if _obj.is_one:
            lis = CodeLog.find(_obj.data.name, uid, pid)
            if lis:
                return False, errcode.EC_CODE_EXCHANGE_NOMORE

        self.codes[strcode] = _obj
        rid = _obj.data.rid
        return True, rid

    def exchange(self, strcode, uid, pid):
        """ 兑换, 已经通过检测pre_exchange """
        _obj = self.pop_code(strcode)
        _obj.exchange(uid, pid)

    def pop_code(self, strcode):
        return self.codes.pop(strcode)


def new_ex_code_mgr():
    mgr = ExchangeCodeMgr()
    return mgr
