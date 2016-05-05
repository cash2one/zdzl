#!/usr/bin/env python
# -*- coding:utf-8 -*-

def gevent_monkey():
    """ 修正monkey方法，修正threading过早加载问题，补充部分未考虑到的补丁 """
    global time_sleep, td_allocate_lock, td_start_new_thread, td_get_ident, \
            td_Event, td_Queue, td_Condition, td_RLock
    from gevent import monkey
    import gevent
    import threading, thread, time
    time_sleep = time.sleep
    td_allocate_lock = thread.allocate_lock
    td_start_new_thread = thread.start_new_thread
    td_get_ident = thread.get_ident
    if gevent.version_info[0] >= 1:
        from gevent import _threading
    else:
        import gevent_threading as _threading
    td_Event = _threading.Event
    td_Queue = _threading.Queue
    td_RLock = _threading.RLock
    td_Condition = _threading.Condition
    monkey.patch_all()

def gevent_tools():
    global Http10WSGIHandler
    from gevent.pywsgi import WSGIHandler
    class Http10WSGIHandler(WSGIHandler):
        def __init__(self, socket, address, server, rfile=None, timeout=60*5):
            super(Http10WSGIHandler, self).__init__(socket, address, server, rfile=None)
            self.close_task = spawn_later(timeout, self.close_socket)

        def handle_one_response(self):
            try:
                return WSGIHandler.handle_one_response(self)
            finally:
                self.close_connection = True
                self.close_task.kill()
                self.close_task = None

        def close_socket(self):
            from gevent import socket
            if getattr(self, 'socket', None) is not None:
                try:
                    log.warning('Http10WSGIHandler %s socket close', self.client_address)
                    self.socket._sock.close()
                    self.socket.close()
                except socket.error:
                    pass


def exception_fix():
    """ 修正异常的继承 """
    try:
        import bson
        bson.errors.BSONError.__bases__ = (StandardError, )
        from pymongo import errors as mongo_errors
        mongo_errors.PyMongoError.__bases__ = (StandardError, )
    except ImportError:
        pass

try:
    #改变系统默认转换编码格式
    import sys
    stderr, stdin, stdout = sys.stderr, sys.stdin, sys.stdout
    reload(sys); sys.setdefaultencoding('utf-8')
    sys.stderr, sys.stdin, sys.stdout = stderr, stdin, stdout
    gevent_monkey()
    gevent_tools()
    exception_fix()
    import log
    import common
    #import setting
    from grpc import rpc
    rpc.use_logging = True
    rpc.RECONNECT_TIMEOUT = 0
    rpc.HEARTBEAT_TIME = 0
    rpc.log_except = log.log_except

    from .common import (reg_global_for_let, un_reg_global_for_let,
            uninit, un_reg_global, get_global, CustomObject,
            SoltObject, StateObject, PersistObject,
            iter_id,
            get_md5, uuid, wrap_dis_gc, with_dis_gc, func_once, obj_func_once,
            TimerSet, sleep_time, tasklet, joinall,
            old_spawn, old_spawn_later,
            getcurrent, spawn_later, spawn, spawns, sleep, GreenletExit,
            Timeout, safe_func,
            Event, Semaphore, BoundedSemaphore, RLock, Timeout,
    )

except ImportError, e:
    print str(e)
    import sys
    sys.exit(1)

try:
    import ujson as json
    is_ujson = True
except ImportError:
    import json
    is_ujson = False

def json_dumps(data, ensure_ascii=False):
    """
    ensure_ascii=False时,json输出unicode, ujson输出utf8str
            u'[1, 2, 3, "\u4e2d\u56fd"]'
            '[1,2,3,"\xe4\xb8\xad\xe5\x9b\xbd"]'
        =True时,如果有unicode对象,json和ujson都会输出错误的编码
            '[1, 2, 3, "\\u4e2d\\u56fd"]'
            '[1,2,3,"\\u4e2d\\u56fd"]'

    """
    if is_ujson:
        s = json.dumps(data, ensure_ascii=False)
    else:
        s = json.dumps(data, ensure_ascii=False,
            default=str,
            separators=(',', ':'))
    if ensure_ascii and isinstance(s, unicode):
        return s.encode('utf-8')
    return s


def new_stream_server(addr, handle):
    from gevent.server import StreamServer
    if isinstance(addr, list):
        addr = tuple(addr)
    svr = StreamServer(addr, handle=handle)
    svr.reuse_addr = 1 #重用端口,防止重启异常
    svr.start()
    return svr

def new_stream_server_by_ports(host, ports, handle, is_random=False):
    import random, socket
    def _listen(port):
        try:
            svr = new_stream_server((host, port), handle)
            return svr
        except socket.error:#端口不可监听，换一个
            pass

    if is_random:
        choiced = []
        while 1:
            port = random.choice(ports)
            if port in choiced:
                if len(choiced) == len(ports):
                    raise ValueError, 'not free port for client'
                continue
            choiced.append(port)
            svr = _listen(port)
            if svr is not None:
                return svr
    else:
        for p in ports:
            svr = _listen(p)
            if svr is not None:
                return svr
        raise ValueError, 'not free port for client'





#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

