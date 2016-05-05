#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys, os
import gc
import weakref
import contextlib
from os.path import join, abspath, dirname, exists
import time, datetime
import random
import uuid as uuid_md
import hashlib
import base64
import functools
import copy
import json
import bisect

import gevent
from gevent.event import Event
from gevent.coros import Semaphore, BoundedSemaphore, RLock
from gevent import (spawn as old_spawn, spawn_later as old_spawn_later,
        joinall, sleep, getcurrent, GreenletExit, Timeout, with_timeout)
from types import (NoneType, IntType, LongType, FloatType,
    BooleanType, StringTypes, TupleType)

import log


if 'sys_encoding' in os.environ:
    sys_encoding = os.environ['sys_encoding']
else:
    import locale
    sys_encoding = locale.getdefaultlocale()[1]

_dis_gc_count = 0
def wrap_dis_gc(func):
    """ 停止gc行为 """
    def _func(*args, **kw):
        with with_dis_gc():
            return func(*args, **kw)
    return _func

@contextlib.contextmanager
def with_dis_gc():
    global _dis_gc_count
    try:
        if _dis_gc_count == 0:
            gc.disable()
        _dis_gc_count += 1
        yield
    finally:
        _dis_gc_count -= 1
        if _dis_gc_count == 0:
            gc.enable()


def safe_func(func, args=tuple(), kw=None, exc=Exception):
    try:
        if kw is None:
            kw = {}
        return func(*args, **kw)
    except exc:
        log.log_except()


def func_once(func):
    "A decorator that runs a function only once."
    def decorated(*args, **kwargs):
        try:
            return decorated._once_result
        except AttributeError:
            decorated._once_result = None
            decorated._once_result = func(*args, **kwargs)
            return decorated._once_result
    return decorated

def obj_func_once(func):
    "A decorator that runs a object's function only once."
    name = '_once_result_%s' % func.func_name
    def decorated(self, *args, **kwargs):
        try:
            return getattr(self, name)
        except AttributeError:
            setattr(self, name, None)
            _once_result = func(self, *args, **kwargs)
            setattr(self, name, _once_result)
            return _once_result
    return decorated


def import1(name):
    mname, name = name.rsplit('.', 1)
    __import__(mname)
    md = sys.modules[mname]
    return getattr(md, name)

def uuid():
    """ 32位uuid """
    return uuid_md.uuid4().hex

def uninit(obj, name):
    try:
        o = getattr(obj, name)
    except AttributeError:
        return
    try:
        if o is not None and hasattr(o, 'uninit'):
            o.uninit()
    except:
        log.log_except()
    setattr(obj, name, None)


class RandomRegion(object):
    """ 概率运算,regions是字典或列表([(k,v),...]), 每一个value都代表一个概率 """
    __slots__ = ('sum', 'items', 'rates', 'values')
    def __init__(self, regions):
        self.sum = 0
        if isinstance(regions, (str, unicode)): #<rid>:rate|<rid>:rate|...
            items = map(lambda i: tuple(map(int, i.strip().split(':'))), regions.split('|'))
        elif hasattr(regions, 'iteritems'):
            items = [(k, v) for k,v in regions.iteritems()]
        else:
            items = list(regions)
        items.sort()
        self.items = items
        self.values = None
        self.rates = []
        for item in items:
            self.sum += item[1]
            self.rates.append(self.sum)

    def random(self):
        """ 随机取值 """
        ran_num = random.randint(0, self.sum)
        i = bisect.bisect_left(self.rates, ran_num)
        return self.items[i][0]

    def randoms(self, count):
        """ 随机取特定数量的值,会保证返回的数量 """
        if not self.values:
            self.values = [(v,k) for k,v in self.items]
            self.values.sort(reverse=1)
        rs = set()
        n = min(100, max(5, count/2))
        for i in xrange(count + n):
            v = self.random()
            if v in rs:
                continue
            rs.add(v)
            if len(rs) == count:
                return rs
        for v,k in self.values:
            if k in rs:
                continue
            rs.add(k)
            if len(rs) == count:
                return rs
        return rs

    def __call__(self, *args, **kwargs):
        if args:
            return self.randoms(*args)
        return self.random()

    def left(self, num):
        i = bisect.bisect_left(self.rates, num)
        return self.items[i][0]

    def right(self, num):
        i = bisect.bisect_right(self.rates, num)
        return self.items[i][0]

def make_lv_regions(regions, accept_low=1):
    """ 实现根据等级获取对应物品功能, regions=[(lv,i), ...] """
    if isinstance(regions, (str, unicode)):
        #格式:0:1|10:2|30:3  [0,10)范围对应id=1, [10,30)范围对应id=2, [30,~)范围对应id=3
        regions = map(lambda i: tuple(map(int, i.strip().split(':'))), regions.split('|'))
    else:
        regions = map(lambda v: (int(v[0]), v[1]), regions)
    regions.sort()
    lvs = list(r[0] for r in regions)
    def _lv_regions(lv):
        i = bisect.bisect_right(lvs, lv) - 1
        if i < 0:
            if not accept_low:
                return None
            i = 0
        return regions[i][1]
    return _lv_regions

def make_lv_regions_list(regions, accept_low=1):
    """ 实现根据等级获取对应物品功能, regions=[(lv,i), ...] """
    if isinstance(regions, (str, unicode)):
        #格式:0:1:1|10:2:2|30:3:3  [0,10)范围对应id=1,1, [10,30)范围对应id=2,2, [30,~)范围对应id=3,3
        regions = map(lambda i: tuple(map(int, i.strip().split(':'))), regions.split('|'))
    else:
        regions = map(lambda v: (int(v[0]), v[1]), regions)
    regions.sort()
    lvs = list(r[0] for r in regions)
    def _lv_regions(lv):
        i = bisect.bisect_right(lvs, lv) - 1
        if i < 0:
            if not accept_low:
                return None
            i = 0
        return regions[i][1:]
    return _lv_regions

_greenlets = {}
_globals = {}
def reg_global_for_let(global_obj, let=None):
    if let is None:
        let = getcurrent()
    #log.debug('****reg_global_for_let')
    _globals[let] = global_obj

def un_reg_global_for_let(let=None):
    if let is None:
        let = getcurrent()
    _globals.pop(let, None)

def un_reg_global(global_obj, disconnect_func=None):
    items = _globals.items()
    for k, v in items:
        if v == global_obj:
            _globals.pop(k)
            if disconnect_func is not None:
                disconnect_func(k)

def get_global():
    return _globals.get(getcurrent(), None)


def _spawn_enter(obj, func, *args, **kw):
    global _globals, _greenlets
    #防止在game对象stoped后，才运行的微线程启动
    if obj is not None and getattr(obj, 'stoped', False):
        return
    cur_let = getcurrent()
    _greenlets[cur_let] = None
    if obj is not None:
        #log.debug('****_spawn_enter.begin:%s-%s-%s', func.func_name, id(cur_let), len(_globals))
        reg_global_for_let(obj, let=cur_let)
    try:
        func(*args, **kw)
    except GreenletExit:
        pass
    except Exception:
        log.log_except()
    finally:
        un_reg_global_for_let(cur_let)
        _greenlets.pop(cur_let, None)
        #log.debug('****_spawn_enter.finally:%s-%s-%s', func.func_name, id(cur_let), len(_globals))

def spawn(func, *args, **kw):
    obj = get_global()
    let = old_spawn(_spawn_enter, obj, func, *args, **kw)
    return let

def spawn_later(sec, func, *args, **kw):
    obj = get_global()
    let = old_spawn_later(sec, _spawn_enter, obj, func, *args, **kw)
    return let

def tasklet(func):
    @functools.wraps(func)
    def _func(*a, **k):
        spawn(func, *a, **k)
        return
    return _func

def spawns(func, argss, timeout=-1):
    """ 启动多个线程，默认会等待,timeout=0不等待 """
    if not argss:
        return
    tasks = []
    for args in argss:
        tasks.append(spawn(func, *args))
    if timeout < 0:
        joinall(tasks)
    elif timeout > 0:
        joinall(tasks, timeout=timeout)
    return tasks


def sleep_time(seconds):
    """ 扩展gevent.sleep,返回实际sleep了的时间 """
    begin = time.time()
    gevent.sleep(seconds)
    used = time.time() - begin
    return used

def make_key(name):
    i = random.randint(0, 99999)
    return hashlib.md5('%s-%s' % (name, i)).hexdigest()

def get_md5(name, base64fmt=False, digest=False):
    md5 = hashlib.md5(str(name))
    if digest:
        data = md5.digest()
    else:
        data = md5.hexdigest()
    if base64fmt:
        return base64.encodestring(data)
    return data

def parse_time(tstr, fmt):
    start, end = tstr.split(":")
    start = strptime(start, fmt)
    end = strptime(end, fmt)
    return start, end

def strftime(fmt='%Y-%m-%d %H:%M:%S', dtime=None):
    """ 获取时间字符串,dt参数是时间对象，如果为None，返回当前时间字符串 """
    if dtime is None:
        dtime = datetime.datetime.now()
    return dtime.strftime(fmt)

def strptime(stime, fmt='%Y-%m-%d %H:%M:%S'):
    """ 根据时间字符串，返回时间对象 """
    return datetime.datetime.strptime(stime, fmt)

def custom_today(hour=0, minute=0, second=0, days=0):
    """ 返回今天的指定时间 """
    n = datetime.datetime.now()
    return datetime.datetime(n.year, n.month, n.day + days, hour, minute, second)

def get_token(key, fmt='%y%m%d%H%M'):
    """ 获取管理令牌 """
    d = datetime.datetime.now()
    return hashlib.md5(key + d.strftime('%y%m%d%H%M')).digest()


def get_local_ip():
    """ 获取本机ip,如果网络不通，反应会慢 """
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("baidu.com",80))
        return s.getsockname()[0]
    except :
        return socket.gethostbyname(socket.gethostname())


def iter_id_func(start=1, end = sys.maxint - 1000, loop=True):
    """ 类似itertools.count,不过有最大值限制，如果超过最大值，将返回从start开始 """
    _id = start
    while 1:
        yield _id
        _id += 1
        if _id >= end:
            if loop:
                _id = start
            else:
                raise StopIteration, \
                        'iter_id function arrive the end(%s) but loop==False' % end

def copy_attributes(from_object, to_object, names):
    """ 复制属性从一个对象到另外一个对象 """
    for name in names:
        value = getattr(from_object, name)
        setattr(to_object, name, value)


def module_to_dict(md):
    """ 过滤模块内容,返回可序列化的数据对象 """
    d1 = {}
    for name in dir(md):
        if name.startswith('_'):
            continue
        value = getattr(md, name)
        if type(value) not in (bool, int, str, unicode, float, tuple, list, dict):
            continue
        d1[name] = value
    return d1


def get_channel_status(cur_players, max_players):
    """获得频道状态"""
    import language
    per = float(cur_players) / max_players * 100.0
    if per <= 30:
        return language.LAN_STRING_43
    elif per <= 55:
        return language.LAN_STRING_43
    elif per <= 80:
        return language.LAN_STRING_44
    return language.LAN_STRING_45

class IterId(object):
    def __init__(self, start = 1, end = sys.maxint - 1000, loop = True):
        self.start = start
        self.end = end
        self.loop = loop
        self._cur_id = start

    def next(self):
        if self._cur_id >= self.end:
            if self.loop:
                self._cur_id = self.start
            else:
                raise StopIteration, \
                        'iter_id function arrive the end(%s) but loop==False' % self.end
        else:
            self._cur_id += 1
        return self._cur_id
iter_id = iter_id_func

def iter_cls_base(cls):
    """ 只支持单继承或多继承的第一个基类 """
    while cls is not None:
        yield cls
        cls = cls.__base__


class CustomObject(object):
    def __str__(self):
        return u'%s(%s) at %s' % (self.__class__.__name__, self.__dict__, id(self))

    def __repr__(self):
        return self.__str__()

##class DefaultConfig(object):
##stdin_file

class BaseApp(object):
    EXTRA_CMDS = []
    def init(self, config=None):
        app_name = getattr(config, 'app_name', None)
        log_path = getattr(config, 'log_path', None)
        pidfile = getattr(config, 'pidfile', None)
        if not app_name:
            app_name = os.environ.get('APP_NAME', 'std')
        if not log_path:
            log_path = os.environ.get('LOG_PATH', './log')
        if not pidfile:
            pidfile = os.environ.get('PIDFILE', './pidfile')
        log_path = os.path.abspath(log_path)
        pidfile = os.path.abspath(pidfile)

        if not os.path.exists(log_path):
            os.makedirs(log_path)
        os.environ['LOG_PATH'] = log_path
        config.log_path = log_path
        config.pidfile = pidfile
        log.info('log_path:%s', log_path)
        self.stdin_path = join(log_path, '%s_in.log' % app_name)
        self.stdout_path = join(log_path, '%s_out.log' % app_name)
        self.stderr_path = join(log_path, '%s_err.log' % app_name)

        pid_path = os.path.dirname(pidfile)
        if not os.path.exists(pid_path):
            os.makedirs(pid_path)
        self.pidfile_path = pidfile
        self.pidfile_timeout = 3
        with open(self.stdin_path, 'a'):
            pass


def daemon(app):
    sys.modules['APP'] = app

    if sys.platform in ['win32', 'cygwin']:
        app.run()
        return

    from daemon import daemon, runner
    from daemon.runner import make_pidlockfile, DaemonRunnerStopFailureError, DaemonRunner

    def gevent_set_signal_handlers(signal_handler_map):
        signals = {}
        for (signal_number, handler) in signal_handler_map.items():
            #gevent.signal have not params, but, signal handler want params(signal_number, stack_frame)
            signals[signal_number] = gevent.signal(signal_number, handler, signal_number, None)
        app.signals = signals
    #use gevent signal to register terminate
    daemon.set_signal_handlers = gevent_set_signal_handlers

    class MyDaemonRunner(DaemonRunner):
        START_CMDS = ('start', 'restart')
        def __init__(self, app):
            for cmd in app.EXTRA_CMDS:
                DaemonRunner.action_funcs[cmd] = getattr(app, cmd)
            self.parse_args()
            self._stdout_path = app.stdout_path
            self._stdin_path = app.stdin_path
            self._stderr_path = app.stderr_path
            if self.action not in self.START_CMDS:
                app.stdin_path = '/dev/null'
                app.stdout_path = '/dev/null'
                app.stderr_path = '/dev/null'
            elif self.action in self.START_CMDS:
                self.pidfile = make_pidlockfile(
                    app.pidfile_path, app.pidfile_timeout)
                status = self._get_status()
                if status[0] == 1:
                    print 'app is running.'
                    raise ValueError, 'app is running'

                self._rename_log(app.stdout_path)
                self._rename_log(app.stderr_path)

            #主微线程
            self._main_let = getcurrent()
            def _wrap_run(func):
                """守护模式后,没有下面sleep,
                某些(admin进程在socket.getaddrinfo)会在卡死
                怀疑是gevent微线程切换问题,暂时这么处理
                """
                def _func(*args, **kw):
                    sleep(0.05)
                    return func(*args, **kw)
                return _func
            app.run = _wrap_run(app.run)
            DaemonRunner.__init__(self, app)
            self._init_signal()

        def _init_signal(self):
            """ 初始化signal """
            import signal
            SIGNAL_MAP = daemon.make_default_signal_map()
            SIGNAL_MAP.update({signal.SIGUSR1:'signal_user',})
            log.debug('init_signal:%s', SIGNAL_MAP)
            self.daemon_context.signal_map = SIGNAL_MAP
            self.daemon_context.terminate = self.terminate
            self.daemon_context.signal_user = self.signal_user

        def signal_user(self, signal_number, stack_frame):
            log.warn("signal user: %r", signal_number)

        def terminate(self, signal_number, stack_frame):
            """ 收到关闭的信号,在主线程上抛出异常 """
            log.warn("Terminating on signal %r", signal_number)
            exception = SystemExit(
                    "Terminating on signal %(signal_number)r"
                            % vars())
            self._main_let.throw(exception)

        def _rename_log(self, log_path):
            """ 备份之前的log文件,名字后加上当前时间 """
            import shutil
            from os.path import exists, basename, dirname, join
            if exists(log_path):
                dir_path, name = dirname(log_path), basename(log_path)
                name += '.' + strftime(fmt='%Y%m%d-%H%M%S')
                try:
                    shutil.move(log_path, join(dir_path, name))
                except shutil.Error:
                    pass


        def domain_restart(self):
            """ 重启守护进程 """
            import config, os
            argv = os.environ['APP_ARGV']
            self.pidfile.break_lock()
            restart_path = os.path.join(config.root_path, 'restart.py')
            if not os.path.exists(restart_path):
                restart_path = os.path.join(config.root_path, 'restart.pyc')

            args = '%s %s' % (sys.executable, argv)
            log.info(u'重启服务:%s', args)
            os.system('python %s %s' % (restart_path, args))


        def _run(self):
            self.app.run()

        def _get_status(self):
            pidfile_path = self.pidfile.path
            if not self.pidfile.is_locked():
                return 0, None
            elif runner.is_pidfile_stale(self.pidfile):
                pid = self.pidfile.read_pid()
                self.pidfile.break_lock()
                return -1, pid
            else:
                return 1, None

        def _status(self):
            status, pid = self._get_status()
            if status == 0:
                print "app is stoped."
            elif status == -1:
                print "pidfile existed but app(%s) is stoped!" % pid
            else:
                print 'app is running.'

        def _reload(self):
            if not hasattr(self.app, 'reload'):
                return
            pid = self.pidfile.read_pid()
            self.app.reload(pid)

        def _log(self, err=False):
            print 'log path:\n%s\n%s' %(self._stdout_path, self._stderr_path)
            tail_cmd = 'tail -f %s'
            if err:
                tail_cmd = tail_cmd % (self._stderr_path, )
            else:
                tail_cmd = tail_cmd % (self._stdout_path, )
            print tail_cmd
            os.system(tail_cmd)

        def _vim(self):
            """ 编辑log """
            tail_cmd = 'vim %s'
            tail_cmd = tail_cmd % (self._stdout_path, )
            print tail_cmd
            os.system(tail_cmd)

        def _terminate_daemon_process(self):
            """ Terminate the daemon process specified in the current PID file.
            """
            if 1:
                DaemonRunner._terminate_daemon_process(self)
            else: #用app.stop
                import config
                from grpc import get_proxy_by_addr, uninit
                app = get_proxy_by_addr(config.admin_addr, 'app')
                app.stop(_no_result=True)
                sleep(0.5)
                del app
                uninit()
            timeout = 60
            while timeout > 0:
                timeout -= 1
                time.sleep(1)
                if not self.pidfile.is_locked():
                    break
            if timeout <= 0:
                sys.exit('stop error:Timeout')

        #命令
        DaemonRunner.action_funcs['vim'] = _vim
        DaemonRunner.action_funcs['log'] = _log
        DaemonRunner.action_funcs['err'] = functools.partial(_log, err=True)
        DaemonRunner.action_funcs['run'] = _run
        DaemonRunner.action_funcs['status'] = _status
        DaemonRunner.action_funcs['reload'] = _reload

    myrunner = MyDaemonRunner(app)
    app.daemon_runner = myrunner
    #daemon.close_file_descriptor_if_open may be crack, don't use it
    myrunner.daemon_context.files_preserve = range(0, 1025)
    try:
        myrunner.do_action()
    except DaemonRunnerStopFailureError as err:
        log.exception('do_action')
        if not myrunner.pidfile.is_locked():
            print 'pidfile no found, app is running?'
    except:
        log.exception('do_action')


def update_config(config):
    """ 更新配置 """
    #设置为app_config,供其它模块调用
    sys.modules['config'] = config
    sys.modules['app_config'] = config
    log.console_config(getattr(config, 'debug', False),
        log_file=getattr(config, 'log_file', None))

    #初始化其它模块
    res_base_dir = getattr(config, 'res_base_dir', None)
    locale_code = getattr(config, 'locale_code', None)
    if res_base_dir and locale_code:
        res_dir = join(res_base_dir, locale_code)
        setattr(config, 'res_dir', res_dir)
        cfg_path = join(res_dir, 'config')
        sys.path.insert(0, cfg_path)
        #加载语言包
        import language
    if not hasattr(config, 'cfg_path'):
        config.cfg_path = abspath(dirname(config.__file__))

def _load_config(config_name):
    """ 从网上下载配置 """
    import json, urllib2
    root_path = os.environ['ROOT_PATH']
    config_root_path = join(dirname(root_path), 'config')
    if not exists(config_root_path):
        err = u'配置目录不存在:%s' % config_root_path
        raise ValueError(err)
    #读取全局配置
    global_cfg_path = join(config_root_path, 'config.json')
    if not exists(global_cfg_path):
        err = u'全局配置文件不存在:%s' % global_cfg_path
        raise ValueError(err)
    with open(global_cfg_path, 'rb') as f:
        global_config = json.load(f)

    config_path = join(config_root_path, config_name)
    if not exists(config_path):
        os.mkdir(config_path)
    cfg_url = global_config['url'] + config_name + '.py'
    cfg_file = join(config_path, 'config.py')
    try:
        cfg_data = urllib2.urlopen(cfg_url, timeout=3).read()
        with open(cfg_file, 'wb') as f:
            f.write(cfg_data)
    except:
        print(u'****读取网络配置超时,尝试使用本地配置****')
        with open(cfg_file, 'rb') as f:
            cfg_data = f.read()
    config = CustomObject()
    exec cfg_data in globals(), config.__dict__
    #配置文件所在目录,linux系统下用于存放配置、sock等文件
    config.cfg_path = config_path
    config.log_path = join(config_path, 'log')
    if not exists(config.log_path):
        os.mkdir(config.log_path)
    config.pidfile = join(config_path, 'pidfile.pid')
    config.app_name = config_name
    return config

def parse_config():
    """ 分析运行参数，加载并返回config """
    if '-c' in sys.argv:
        index = sys.argv.index('-c')
        config_name = sys.argv.pop(index + 1)
        sys.argv.pop(index)
        return _load_config(config_name)

class TimerSet(object):
    """ 定时触发事件的管理类
    注意：每个小逻辑功能内部尽量不能做io，否则会影响其它功能
    用处：
        针对大量需要定时执行小量逻辑的功能，
            如：回血，回气，buff
        小逻辑功能，必须是使用yield方式实现的函数、方法，
            或者支持yield相关方法的对象
            next(): 第一次调用，返回下一次触发时间
            send(经过的时间):返回下一次触发时间
        备注：
            时间使用毫秒，
            如果需要停止，抛出StopIteration

        yield函数例子：
    def _test1():
        #间隔时间
        i_time = 500.0
        pass_time = i_time
        while 1:
            s_time = (i_time + i_time - pass_time)
            if s_time < 0:
                s_time = i_time
            pass_time = yield s_time
            #pass_time是从上一次到这次执行过去的时间
            #下面可以执行具体的逻辑

    """
    default_wait = 2 * 60
    max_seconds = 3600 * 24 * 100 #最大秒数
    max_error = 'TimerSet error: seconds(%%s) > max(%s)' % max_seconds
    def __init__(self, owner):
        if 0:
            self._pause_waiter = Event()
        self._loop_task = None
        self._timers = []
        self._yields = []
        self._waiter = Event()
        self._pause_waiter = None
        self.owner = weakref.ref(owner)

    def register(self, yield_func):
        self._yields.append(yield_func)
        self._waiter.set()

    def unregister(self, yield_func):
        if yield_func in self._yields:
            self._yields.remove(yield_func)
            return
        for index, (times, yfunc) in enumerate(self._timers):
            if yfunc == yield_func:
                self._timers.pop(index)
                return

    def update_later(self, yield_func, seconds):
        """ 更新某yield_func的调用时间，常配合call_later使用 """
        if yield_func in self._yields:
            return True
        for value in self._timers:
            times, yfunc = value
            if yfunc == yield_func:
                self._timers.remove(value)
                times = time.time() + seconds
                self._timers.append((times, yfunc))
                self._timers.sort()
                return True
        return False

    def call_later(self, seconds, func, *args, **kw):
        """ 延迟一段时间调用某函数，只调用一次 """
        #回调的时间太长啦
        if seconds > self.max_seconds:
            raise ValueError, self.max_error % seconds
        @functools.wraps(func)
        def _yield_func():
            yield seconds * 1000.0
            try:
                spawn(func, *args, **kw)
            except StandardError:
                log.log_except()
        yfunc = _yield_func()
        self.register(yfunc)
        return yfunc

    def call_loop(self, seconds, func, *args, **kw):
        """ 延迟一段时间循环调用某函数，持续调用,直到函数返回False """
        @functools.wraps(func)
        def _yield_func():
            params = [1, 0] #[是否结束, 是否正在执行]
            i_time = seconds * 1000.0 #1秒
            @functools.wraps(func)
            def _myfunc():
                try:
                    rs = func(*args, **kw)
                    params[0] = rs
                except StandardError:
                    log.log_except()
                    params[0] = 0
                finally:
                    params[1] = 0

            while params[0]:
                yield i_time
                #回调的时间太长啦
                if seconds > self.max_seconds:
                    raise ValueError, self.max_error % seconds + ':func=%s' % func
                #启用微线程跑，防止阻塞本线程, _calling用于防止重复进入
                if params[0] and not params[1]:
                    params[1] = 1
                    spawn(_myfunc)
        yfunc = _yield_func()
        self.register(yfunc)
        return yfunc


    def empty(self):
        return not (len(self._timers) or len(self._yields))

    @property
    def stoped(self):
        return self._loop_task is None

    @property
    def owner_stoped(self):
        return self.owner() is None or \
            getattr(self.owner(), 'stoped', False)

    def start(self):
        if self.stoped:
            #log.debug(u'************TimerSet.start')
            self._loop_task = spawn(self._loop)

    def stop(self):
        if not self.stoped:
            #log.debug(u'************TimerSet.stop')
            self._loop_task.kill(block=False)
            self._loop_task = None
            self._waiter.set()

    def clear(self):
        self._timers = []
        self._yields = []
        self._waiter.set()
        self.stop()

    def pause(self):
        if self._pause_waiter is None:
            self._pause_waiter = Event()
        self._pause_waiter.clear()

    def resume(self):
        if self._pause_waiter is None or self._pause_waiter.is_set():
            return
        self._pause_waiter.set()

    def _loop(self):
        while not (self.stoped or self.owner_stoped):
            if self._pause_waiter is not None:
                self._pause_waiter.wait(timeout=self.default_wait)

            cur_time = int(time.time() * 1000.0)
            #触发
            while len(self._timers):
                if self._timers[0][0] <= cur_time:
                    timer = self._timers.pop(0)
                    try:
                        next_time = timer[1].send(0) + cur_time
                        if next_time > cur_time:
                            #log.debug('****append:%s, %s', timer, next_time)
                            self._timers.append((next_time, timer[1]))
                        else:
                            raise ValueError, 'yield(%s) error: next_time <= cur_time' % str(timer[1])
                    except StopIteration:
                        pass
                    except GreenletExit:
                        return
                    except Exception, e:
                        log.error('timer(%s) error:%s', timer[1], e)
                else:
                    break
                cur_time = int(time.time() * 1000.0)


            #处理新的功能
            for func in self._yields:
                try:
                    next_time = func.next() + cur_time
                    self._timers.append((next_time, func))
                except GreenletExit:
                    return
                except Exception, e:
                    log.error('timer(%s) error:%s', func, e)
            self._yields = []

            #准备下一次唤醒
            self._timers.sort()
            self._waiter.clear()
            len_timer = len(self._timers)
            if len_timer:
##                if len_timer > 50:
##                    log.error('TimerSet error:len(self._timers) > 50, it is may be an error?')
##                    for nt, func in self._timers:
##                        log.info('  next_time=%s, func=%s', nt, func)
##                    raise StandardError, 'TimerSet error:len(self._timers) > 50, it is may be an error?'
                s_time = (self._timers[0][0] - cur_time) / 1000.0
                #log.debug('****wait(%s) _timers(%s)', s_time, self._timers)
                self._waiter.wait(timeout=min(s_time, self.default_wait))
            else:
                if self.stoped:
                    return
                self._waiter.wait(timeout=self.default_wait)

        self.stop()
        if 0:
            log.debug(u'TimerSet._loop stoped')

def dict_key_int_to_str(obj):
    """
    {1:1} -> {"1":1}
    """
    adict = {}
    if isinstance(obj, dict):
        for key, value in obj.iteritems():
            adict[str(key)] = dict_key_int_to_str(value)
        return adict
    else:
        return obj

def dict_key_str_to_int(obj):
    """
    {"1":1} -> {1:1}
    """
    adict = {}
    if isinstance(obj, dict):
        for key, value in obj.iteritems():
            try:
                adict[int(key)] = dict_key_str_to_int(value)
            except ValueError:
                adict[key] = dict_key_str_to_int(value)
        return adict
    else:
        return obj

class Counter(object):
    """
    一段時間內計數器，如果超出（默認一天的時間）範圍，重新計數
    """
    def __init__(self, days=1):
        self.last_time_stamp = datetime.datetime.now().date()#時間戳
        self._count = 0
        if days and isinstance(days,int):
                self._delay = datetime.timedelta(days)
        else:
            self._delay = datetime.timedelta(1) #計數器重新計數間隔，默認一天

    @property
    def count(self):
        """返回計數值"""
        if self.is_over:
            self._reset()
        return self._count

    def increase(self):
        if  self.is_over:#如果超时，重置
            self._reset()
        self._count += 1

    def _reset(self):
        """計數值重設為0"""
        self._count = 0

    @property
    def is_over(self):
        """判斷當前時間與最後時間戳這段時間是否超出設定的範圍，如果超過返回 True
            否則False
        """
        today = datetime.datetime.now().date()
        if today - self.last_time_stamp >= self._delay:
            self.last_time_stamp = today
            return True
        else:
            return False


def persist_obj_reconstructor(cls):
    new_cls = getattr(cls, '_CLS_')
    if new_cls is None:
        new_cls = cls
    try:
        obj = new_cls()
    except StandardError:
        obj = new_cls.__new__(new_cls)
##    obj.__setstate__(state)
    return obj


class SoltObject(object):
    """  """
    def __getstate__(self):
        d1 = {}
        for k in self.__slots__:
            d1[k] = getattr(self, k)
        return d1

    def __setstate__(self, adict):
        for k in self.__slots__:
            if not k in adict:
                continue
            setattr(self, adict[k])



constant_types = (NoneType, IntType, LongType, FloatType,
        BooleanType, TupleType) + StringTypes

class StateObject(object):
    _state_unfields_ = set()
    _state_objfields_ = set()
    def get_states(self):
        """ 返回由普通类型组成的字典,供store使用 """
        if hasattr(self, '__getstate__'):
            adict = self.__getstate__()
        else:
            adict = self.__dict__.copy()
        for f in self._state_unfields_:
            adict.pop(f, None)
        for f in self._state_objfields_:
            if f not in adict:
                continue
            v = adict[f]
            if hasattr(v, 'get_states'):
                adict[f] = v.get_states()
            else:
                adict[f] = v.__getstate__()

        return adict

    def set_states(self, states):
        if hasattr(self, '__setstate__'):
            self.__setstate__(states)
        else:
            self.__dict__.update(states)


class PersistObject(StateObject):
    _CLS_ = None #指定实例化的类
    _PROTECT_UPDATE_ = True #是否启用update保护
    _un_persist_fields_ = set() #不持续化的字段名
    _default_fields_ = {}
    _init_fields_ = set()
    def __init__(self, **kw):
        self._init_persist_cls()
        self.update(**kw)
        self._set_defaults()

    def __contains__(self, item):
        return item not in self._un_persist_fields_ and \
            (item in self.__dict__ or item in self.__class__.__dict__)

    def __setstate__(self, adict):
        self._init_persist_cls()
        my_dict = self.__dict__
        _un_persist_fields_ = self._un_persist_fields_
        for k,v in adict.iteritems():
            if k not in _un_persist_fields_:
                my_dict[k] = v
        self._set_defaults()

    def _set_defaults(self):
        my_dict = self.__dict__
        deepcopy = copy.deepcopy
        defaults = self._default_fields_
        for k in self._init_fields_:
            if k in my_dict:
                continue
            v = defaults.get(k, None)
            my_dict[k] = v if type(v) in constant_types else (v() if callable(v) else deepcopy(v))

    def __getstate__(self):
        """ pickle持续化时调用 """
        return dict((k, v) for k, v in self.iter_field_values())

    def _reduce(self):
        """ 支持pickle的自定义序列化方法(方法名为:__reduce__才有效)
        __reduce__返回3元数组,
            1:创建对象的方法
            2:上面方法的参数(对象的类继承关系)
            3:对象的数据
        """
        return (persist_obj_reconstructor,
                (self.__class__,),
                self.__getstate__()
                )


    def update(self, **kw):
        for key, value in kw.iteritems():
            if not self._PROTECT_UPDATE_ or key in self.__dict__:
                setattr(self, key, value)


    _un_persist_fields_init_clses_ = []
    @classmethod
    def _init_persist_cls(cls):
        if cls not in PersistObject._un_persist_fields_init_clses_:
            PersistObject._un_persist_fields_init_clses_.append(cls)
            if not hasattr(cls, '_un_persist_fields_'):
                cls._un_persist_fields_ = set()
            if not hasattr(cls, '_default_fields_'):
                cls._default_fields_ = {}
            if not hasattr(cls, '_state_unfields_'):
                cls._state_unfields_ = set()
            if not hasattr(cls, '_state_objfields_'):
                cls._state_objfields_ = set()
            base = cls.__base__
            if hasattr(base, '_init_persist_cls'):
                _un_per, _defaults, state_unfields, state_objs = base._init_persist_cls()
                cls._un_persist_fields_.update(_un_per)
                cls._default_fields_.update(_defaults)
                cls._state_unfields_.update(state_unfields)
                cls._state_objfields_.update(state_objs)
            cls._init_fields_ = set(cls._default_fields_.keys())
            cls._init_fields_.update(cls._un_persist_fields_)
        return (cls._un_persist_fields_, cls._default_fields_,
                cls._state_unfields_, cls._state_objfields_)


    def iter_field_values(self):
        """ 测速表明:用set.difference的并不能提高速度 """
        _un_persist_fields_ = self._un_persist_fields_
        for k, v in self.__dict__.iteritems():
            if k not in _un_persist_fields_:
                yield k, v

    def iter_fields(self):
        _un_persist_fields_ = self._un_persist_fields_
        for k in self.__dict__.iterkeys():
            if k not in _un_persist_fields_:
                yield k

    def get_fields(self):
        return [k for k in self.iter_fields()]

    def clone(self):
        return copy.deepcopy(self)

    def dumps(self):
        return pickle.dumps(self)



#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

