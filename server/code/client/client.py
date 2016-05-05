#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os
from gevent.event import AsyncResult
from corelib import log
from game import ClientRpc, pack_msg, AbsExport

sys_encoding = os.environ['sys_encoding']
if os.environ.get('CYGWIN', ''):
    sys_encoding = 'utf-8'

import config

AES = 1
if AES:
    ClientRpc.aes_init(config.client_rpc_aes_key, unpack=1)

class Client(AbsExport):
    def __init__(self):
        self.rpc = None
        self.listeners = []
        self.waits = {}

    def add_listener(self, listener):
        if listener in self.listeners:
            return
        self.listeners.append(listener)

    def del_listener(self, listener):
        if listener not in self.listeners:
            return
        self.listeners.remove(listener)

    def on_close(self, rpcobj):
        self.close()

    def connect(self, host, port):
        self.rpc = ClientRpc.rpc_client(host, port, self)
        self.rpc.raw_call_func()
        self.rpc.start()

    def close(self):
        if self.rpc:
            log.info('client stop!')
            self.rpc.stop()
            self.rpc = None
            exc = ValueError('client stop')
            for w in self.waits.itervalues():
                w.set_exception(exc)

    def send(self, msg_name, status=1, data=None, err=None):
        msg = pack_msg(msg_name, status, data=data, err=err)
        self.rpc.send(msg)

    def _recv(self, name, status, kw, err):
        """ 收到协议 """
        rs = self.waits.get(name)
        if rs is not None:
            rs.set((status, kw, err))
            return
        for l in self.listeners:
            func = getattr(l, 'on_%s' % name, None)
            if callable(func):
                func(status, kw, err)

    def call(self, name, kw):
        _no_result = kw.pop('_no_result', False)
        msg = pack_msg(name, 1, data=kw)
        self.rpc.send(msg)
        if _no_result:
            return None, None, None

        assert name not in self.waits, 'waits error'
        rs = AsyncResult()
        self.waits[name] = rs
        try:
            result = rs.get(timeout=300)
            if rs.exception:
                raise rs.exception
            return result
        finally:
            self.waits.pop(name)

    def __getattr__(self, attribute):
        if attribute.startswith('call_'):
            def _func_call(**kw):
                status, kw, err = self.call(attribute[5:], kw)
                if status is not None and status != 1:
                    if isinstance(err, (str, unicode)):
                        raise ValueError('call error1:%s' % err.decode('utf-8').encode(sys_encoding))
                    else:
                        raise ValueError(err)
                return kw
            return _func_call
        elif attribute.startswith(self._rpc_attr_pre):
            def _func_rc(msg, _status=None, _err=None):
                self._recv(attribute[len(self._rpc_attr_pre):], _status, msg, _err)
            return _func_rc
        raise ValueError('attribute(%s) not found'% attribute)


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


