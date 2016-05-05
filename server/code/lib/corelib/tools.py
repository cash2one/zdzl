#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os, sys
import time
import socket
import urllib
from functools import partial, wraps

from .common import sleep, spawn_later, spawn, sys_encoding, with_timeout

from . import log

def get_rel_urls(url, params):
    if params is not None:
        if isinstance(params, dict):
            s = urllib.urlencode(params)
        else:
            s = str(params)
        return '%s?%s' %(url, s)
    else:
        return url

def get_urls(host, port, url, params, ssl=False):
    if port is None:
        port = ''
    else:
        port = ':%s' % port
    http = 'http'
    if ssl:
        http = 'https'
    return '%s://%s%s%s' % (http, host, port, get_rel_urls(url, params))

def _wrap_time_out(func):
    @wraps(func)
    def _func(*args, **kw):
        timeout = kw.pop('timeout', 5)
        return with_timeout(timeout, func, *args, **kw)
    return _func

@_wrap_time_out
def http_httplib(host, port, url, params=None, data=None, raise_err=False, con=None, headers=None, ssl=False):
    """ 用http方式发送数据 """
    import httplib
    if headers is None:
        headers = {}
    err_msg = u'发送数据到HTTP服务器(%s:%d%s)时出错' % (host, port, url)
    want_close = (con is None)
    if want_close:
        HC = httplib.HTTPConnection if not ssl else httplib.HTTPSConnection
        con = HC(host, port)
    try:
        urls = get_rel_urls(url, params)
        con.request('POST' if data is not None else 'GET', urls, body=data, headers=headers)
        rs = con.getresponse()
        if rs.status != 200:
            if raise_err:
                raise ValueError, rs.status, rs.read()
            log.error(u'%s:%s - %s', err_msg, rs.status, rs.read())
        else:
            return rs.read()
    except socket.error, e:
        if raise_err:
            raise ValueError, e
        log.error(u'%s:%s', err_msg, str(e).decode(sys_encoding))
    except StandardError:
        if raise_err:
            raise
        log.log_except()
    finally:
        if want_close:
            con.close()

try:
    import urllib3
    from urllib3 import connectionpool
    _http_pool = urllib3.PoolManager(maxsize=10)
    connectionpool.log.setLevel(connectionpool.logging.WARN)
except ImportError:
    urllib3 = None

@_wrap_time_out
def http_urllib3(host, port, url, params=None, data=None, raise_err=False, headers=None, ssl=False):
    """ 用http方式发送数据 """
    err_msg = u'发送数据到HTTP服务器(%s:%s%s)时出错' % (host, port, url)
    try:
        urls = get_urls(host, port, url, params, ssl=ssl)
        rs = _http_pool.urlopen('POST' if data is not None else 'GET',
                urls, body=data, headers=headers)
        if rs.status != 200:
            if raise_err:
                raise ValueError, rs.status, rs.data[:50]
            log.error(u'%s:%s - %s', err_msg, rs.status, rs.data[:50])
        else:
            return rs.data
    except socket.error, e:
        if raise_err:
            raise ValueError, e
        log.error(u'%s:%s', err_msg, str(e).decode(sys_encoding))
    except StandardError:
        if raise_err:
            raise
        log.log_except()

http_post = http_httplib
if urllib3:
    http_post_ex = http_urllib3
else:
    http_post_ex = http_httplib


class Monitor(object):
    _instance = None
    def __init__(self):
        self.values = {}

    @classmethod
    def instance(cls):
        if Monitor._instance is None:
            cls._instance = Monitor()
        return cls._instance

    def func_status(self, t, func, args, kw):
        return self.func_status_ex(t, func.__name__, func, args, kw)

    def func_status_ex(self, t, func_name, func, args, kw):
        flag = False
        starttime = time.time()
        try:
            return func(*args, **kw)
        except Exception:
            flag = True
            raise
        finally:
            data = self.values.setdefault(func_name, [t, 0, 0, 0])
            endtime = time.time()
            consuming_time = endtime - starttime
            if flag:
                data[3] += 1
            data[1] += 1
            data[2] += consuming_time

    def pop_report(self):
        data = self.values
        self.values = {}
        return data
        
    def get_report_pb2(self):
        """ 获取rpc监控包 """
        data = self.values
        if not data:
            return

        from protobuf import online_report_pb2
        rpc_package = online_report_pb2.RPCPackageStatusReport()
        for func_name, result in data.iteritems():
            status = rpc_package.statuses.add()
            status.func_name = func_name
            status.call_count = result[0]
            status.consuming_time = result[1]
            status.call_err = result[2]
        return rpc_package


def analyze_mem():
    """ 内存分析 """
    import gc, sys
    d = {}
    objects = gc.get_objects()
    print 'gc objects size:', len(objects)
    for o in objects:
        o_type = type(o)
        if o_type in d:
            data = d[o_type]
        else:
            data = [0, 0, sys.getsizeof(0)]
        data[0] += 1
        data[1] += data[2]
        d[o_type] = data
    lmem = [[v, k] for k, v in d.iteritems()]
    lmem.sort()

    return lmem, d


def get_quit_players():
    from game.player import Player
    refs = Player._wrefs
    return [p for p in refs.values() if p.quited]

def froot(id, roots=None, rels=None):
    if roots is None:
        roots = []
        rels = []
    if isinstance(id, int):
        obj = fo1(id)
    else:
        obj = id
    if obj in rels or obj in roots:
        return
    rels.append(obj)
    for p in fp1(id):
        pid = p.address
        if p in rels or p in roots:
            continue
        if p.num_parents == 0:
            roots.append(p)
            continue
        froot(p.address, roots, rels)
    return roots#, rels

def meliae_dump(file_path):
    """ 内存分析
辅助函数：
objs = om.objs
ft=lambda tname: [o for o in objs.values() if o.type_str == tname]
fp=lambda id: [objs.get(rid) for rid in objs.get(id).parents]
fr=lambda id: [objs.get(rid) for rid in objs.get(id).children]
#exec 'def fp1(id):\n obj = fo1(id)\n return fp(obj)'
exec 'def fps(obj, rs=None):\n    if rs is None:\n        rs = []\n    if len(rs) > 2000:\n        return rs\n    if obj is not None and obj not in rs:\n        rs.append(obj)\n        for p in fr(obj):\n            fps(p, rs=rs)\n    return rs'
exec 'def fps1(obj, rs=None):\n    if rs is None:\n        rs = []\n    if len(rs) > 2000:\n        return rs\n    if obj is not None and obj not in rs:\n        if obj.num_parents == 0:\n                rs.append(obj)\n        for p in fp(obj):\n            fps(p, rs=rs)\n    return rs'
fo=lambda id: objs.get(id)

运行时辅助：
import gc
get_objs = lambda :dict([(id(o), o) for o in gc.get_objects()])
fid = lambda oid: [o for o in gc.get_objects() if (id(o) == oid)]
fr = lambda o: gc.get_referents(o)
fp = lambda o: gc.get_referrers(o)
"""
    from meliae import scanner
    scanner.dump_all_objects(file_path)

def profile(duration=60, profile=None, trace_obj=None):
    """ 性能分析 """
    import os
    from . import gevent_profiler, common

    if gevent_profiler._attach_expiration is not None:
        return False, 'profile has running!\n'

    start_time = common.strftime('%y%m%d-%H%M%S')
    if profile is None:
        save_path = os.environ.get('LOG_PATH', None)
        if not save_path:
            save_path = os.path.join(os.environ['ROOT_PATH'], 'log')
        profile = os.path.join(save_path, 'profile-%s.profile' % start_time)
    gevent_profiler.set_summary_output(profile)
    gevent_profiler._attach_duration = duration

    if trace_obj:
        gevent_profiler.set_trace_output(trace_obj)
        gevent_profiler.enable_trace_output(True)
    else:
        gevent_profiler.set_trace_output(None)
        gevent_profiler.enable_trace_output(False)

    gevent_profiler.attach()
    return True, 'profile start:%s\n' % start_time


_dead_checker = None

def start_dead_check():
    global _dead_checker
    if _dead_checker:
        return True
    _dead_checker = DeadChecker()
    _dead_checker.start()
    return True

class DeadCheckError(StandardError):
    pass

class DeadChecker(object):
    """ 进程挂起的检查类 """
    DEAD_TIME = 60
    def __init__(self):
        self._hb_task = None


    def start(self):
        self._hb_time = time.time()
        sys.settrace(self._globaltrace)
        self._hb_task = spawn(self._heartbeat)


    def _heartbeat(self):
        while True:
            self._hb_time = time.time()
            sleep(1)

    def _globaltrace(self, frame, event, arg):
        return self._localtrace

    def _localtrace(self, frame, event, arg):
        if time.time() - self._hb_time > self.DEAD_TIME:
            log.log_stack('dead check')
            raise DeadCheckError
        return self._localtrace


########################
########################

