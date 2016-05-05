#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys, os
import glob
import imp
import locale
from os.path import join, exists, abspath

executable = abspath(sys.executable)
if hasattr(sys, 'frozen') and sys.frozen:
    frozen = True
    if sys.platform in ['linux2']:
        #sys.executable变成archiveName啦，pyinstaller中的lanuch.c会将sys.argv[0]改成archiveName，不知道为什么这样
        os.environ['executable'] = executable[:-4]
    else:
        os.environ['executable'] = executable
else:
    frozen = False
    if os.path.exists('main.py'):
        main_py = ' main.py'
    else:
        main_py = ' main.pyc'
    os.environ['executable'] = executable + main_py
#sys.frozen = frozen

#编码
LOCALE_CODE, sys_encoding = locale.getdefaultlocale()
if sys_encoding is None:
    sys_encoding = 'UTF-8'
os.environ['sys_encoding'] = sys_encoding

#默认参数 'store', 'union', 'scene', 'glog', 'activity', 'logic1', ...
os.SUBGAME_DEBUG = ''
use_cpp_protobuf = 0
use_psyco = 0
use_dead_check = 0

try:
    from main_config import *
except ImportError:
    pass

#cygwin check
is_cygwin = False
if sys.platform in ['win32', 'cygwin']:
    if sys.platform == 'cygwin':
        is_cygwin = True
    elif os.environ.get('GOOS', None) in ['linux']:
        is_cygwin = True
    elif os.environ.get('PWD', '').find('/') >= 0:
        is_cygwin = True
os.environ['CYGWIN'] = '1' if is_cygwin else ''

if frozen:
    root_path = abspath(os.path.dirname(executable)).decode(sys_encoding)
else:
    root_path = abspath(os.path.dirname(__file__)).decode(sys_encoding)
    lib_path = join(root_path, 'lib')

os.environ['ROOT_PATH'] = root_path.encode('utf-8')
#lib path
sys.path.insert(0, lib_path)


#减少周期性检查
sys.setcheckinterval(1000)

import socket
##if REMOTE_DEBUG:
##    #调试状态下，将socket的timeout时间加长
##    socket.setdefaulttimeout(6000)
##else:
##    socket.setdefaulttimeout(60.0)



def log(*args):
    for arg in args:
        if isinstance(arg, unicode):
            print arg.encode(sys_encoding)
        else:
            print arg,
    print '\n'

def log_utf8(msg):
    log(msg.decode('utf8').encode(sys_encoding))


def install_psyco():
    """ 使用psyco包，提高速度，但在linux下，很耗内存 """
    try:
        import psyco
        psyco.full()
        log('***psyco installed.')
    except ImportError:
        pass

def install_cpp_protobuf():
    """ 使用protobuf 2.4中开始引入的c扩展模块，提高速度 """
    #protobuf use cpp
    os.environ['PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION'] = 'cpp'
    try:
        from google.protobuf.internal import cpp_message
        log('use cpp protobuf')
    except ImportError:
        os.environ['PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION'] = 'python'

def read_svn_version():
    root_path = os.environ['ROOT_PATH']
    file_path = os.path.join(root_path, 'svn_version')
    try:
        with open(file_path, 'r') as fh:
            version = fh.readline().strip()
            os.environ['APP_VERSION'] = version
    except IOError:
        pass

def init():
    """ 初始化 """
    if use_psyco:
        install_psyco()
    if use_cpp_protobuf:
        install_cpp_protobuf()

    if is_cygwin and sys_encoding not in ['UTF8']:
        from corelib import log as corelib_log
        corelib_log.locale_encode = 'UTF8'

##    #protobuf
##    from corelib.pb2 import etc
##    pb2_path = join(root_path, 'lib')
##    xml_path = join(pb2_path, 'full_name_map_msg_id', 'full_name_map_msg_id.xml')
##    if frozen:
##        import support
##        import protobuf as mod
##        support.load_sub_mods(mod)
##    else:
##        mod = None
##    etc.init(join(pb2_path, 'protobuf'), xml_path, mod=mod)
    read_svn_version()
    #log('main.init success')


##def _cmd_log(app, *args):
##    tail_cmd = 'tail -f %s/log/%s_out.log' % (root_path, args[0], )
##    os.system(tail_cmd)

def _cmd_shell(app, *args):
    """ 连接远程控制台 """
    if len(args) != 2:
        log(u'连接远程控制台使用方法: main.py shell ip port')
        log(u'启动本地shell')
        _shell()
        sys.exit(0)

    import grpc
    addr = (args[0], int(args[1]))
    client = grpc.RpcClient()
    client.connect(addr)
    client.start()
    client.svc.start_console()


def _shell(local=None):
    try:
        import IPython
        try:
            import IPython.Shell
            IPython.Shell.start(user_ns=local).mainloop()
            return
        except ImportError as e:
            pass

        from IPython.frontend.terminal import ipapp
        app = ipapp.TerminalIPythonApp.instance()
        app.initialize(argv={})
        if local:
            app.shell.user_ns.update(local)
        app.start()
    except ImportError:
        import code
        code.interact(local=local)


def execute(app):
    CMDS = {}
    for name, value in globals().iteritems():
        if name.startswith('_cmd_'):
            CMDS[name[5:]] = value

    app_path = join(root_path, 'app', app)
    if frozen or app in CMDS or os.path.exists(app_path):
        pass
    else:
        log_utf8('子项目(%s)找不到!' % app)
        sys.exit(0)

    #初始化
    init()

    def _init_config(app_path):
        #加载app/config.py
        from corelib import common
        sys_config = sys.modules.get('config')
        try:
            rs = imp.find_module('config', [app_path])
            config = imp.load_module('config', *rs)
            if sys_config:
                config.__dict__.update(sys_config.__dict__)
            common.update_config(config)
        except ImportError:
            log("app(%s) config no found" % app_path)

    if app in CMDS:
        app_path = join(root_path, 'app', 'game')
        sys.path.insert(0, app_path)
        _init_config(app_path)
        CMDS[app](*sys.argv[1:])
    else:
        os.environ['APP_NAME'] = app
        os.environ['LOG_PATH'] = os.path.join(root_path, 'runtime', 'log')
        os.environ['PIDFILE'] = '%s.pid' % os.path.join(root_path, 'runtime', app)

        #死循环检查功能：只会在子应用进程安装
        if use_dead_check and sys.platform not in ('win32', ) and \
                app in ['web', 'logon', 'channel', 'battle', 'chat']:
            from gevent import spawn_later
            from corelib.tools import start_dead_check
            sec = 20
            spawn_later(sec, start_dead_check)
            log('install dead check after %d second' % sec)

        # pop app, 子项目使用sys.argv
        if len(sys.argv) > 2:
            sys.argv.pop(1)


        if not frozen:
            if os.path.exists(join(app_path, '__init__.py')):
                app_mod = __import__('%s.main' % app)
                main_md = app_mod.main
            elif os.path.exists(app_path):
                sys.path.insert(0, app_path)
                _init_config(app_path)
                file, filename, _ = imp.find_module('main', [app_path])
                main_md = imp.load_module('main', file, filename, _)
        else:
            sub_path = os.path.join(root_path, '%s.dat' % app)
            if not os.path.exists(sub_path):
                app_mod = __import__('%s.main' % app)
                main_md = app_mod.main
            else:
                sys.path.insert(0, sub_path)
                import main as main_md
        main_md.main()


message = """
启动方式:
.运行程序:
    python main.py <app> <start|stop|status|run>

.运行测试:
    python main.py test

.log 信息显示
    python main.py log <app>

.远程shell:
    python main.py shell ip port

.用meliae分析内存文件:
    python main.py tools meliae file_path
"""

def load_config():
    """ 加载配置 """
    #wingide必须在corelib之前加载
    if sys.argv[-1] == 'subgame_debug':
        sys.argv.pop()
        try:
            log_utf8('启动wingide调试')
            import wingdbstub
        except ImportError:
            log_utf8('启动wingide调试失败')

    from corelib import common
    app = None
    #解释运行参数,确定应用名称
    config = common.parse_config()
    if config:
        common.update_config(config)
        if hasattr(config, 'app'):
            app = config.app
    if app is None:
        app = sys.argv[1]
    return app

def main():
    #log('sys.argv:', sys.argv)
    if len(sys.argv) < 2:
        log_utf8(message)
        sys.exit(0)
    os.environ['APP_ARGV'] = ' '.join(sys.argv[1:])

    app = load_config()
    execute(app)

if __name__ == '__main__':
    main()

