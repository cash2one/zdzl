#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os, sys
from os import path
import posixpath
import datetime
import json
import commands

from fabric import state
from fabric.operations import local, run, sudo, put, get, env
from fabric.context_managers import cd
from fabric.contrib.files import exists as exists_ssh
from fabric.contrib.project import rsync_project as fab_rsync_project


class _ssh:
    @staticmethod
    def join(path, *args):
        return posixpath.join(path, *args)
#        if path[-1] == '/':
#            path = path[:-1]
#        return '/'.join((path,) + args)

    @staticmethod
    def dirname(path):
        return posixpath.dirname(path)

    @staticmethod
    def mkdir(path):
        if not _ssh.exists(path):
            run('mkdir -p %s' % path)


    @staticmethod
    def rm(path):
        if _ssh.exists(path):
            run('rm -rf %s' % path)

    @staticmethod
    def mk_sh(cmd_file, cmd):
        #TODO: mk_sh创建执行脚本有问题待处理
        print('mk_sh:', cmd, cmd_file)
        cmd_path = _ssh.dirname(cmd_file)
        _ssh.mkdir(cmd_path)
        run("echo '%s' > %s" % (cmd, cmd_file))
        run('chmod +x %s' % cmd_file, shell=False)

    @staticmethod
    def ln(src_file, dest_file):
        _ssh.run("ln -s %s %s" % (src_file, dest_file))

    @staticmethod
    def rsync_project(*args, **kw):
        fab_rsync_project(*args, **kw)
        #cygwin环境，在执行完rsync后，fabric的连接会断掉
        if sys.platform == 'cygwin':
            state.connections.clear()

    exists = staticmethod(exists_ssh)
    cd = staticmethod(cd)
    run = staticmethod(run)
    put = staticmethod(put)

class _tool:
    @staticmethod
    def strftime(fmt='%Y%m%d_%H%M%S', dtime=None):
        """ 获取时间字符串,dt参数是时间对象，如果为None，返回当前时间字符串 """
        if dtime is None:
            dtime = datetime.datetime.now()
        return dtime.strftime(fmt)

    @staticmethod
    def compile_pyc(src_path):
        #指定使用python版本编译pyc
        compile_pyc = """python2.7 -c "import compileall;compileall.compile_dir('%s',force=1,quiet=1)" """
        info = sys.version_info
        if info[:2] != (2, 7):
            os.chdir(src_path)
            os.system(compile_pyc % src_path)
            return
        import compileall
        compileall.compile_dir(src_path, force=1, quiet=1)

    @staticmethod
    def cython(pyx_file):
        """ 编译pyx文件到c """
        cmd = 'cython %s' % pyx_file
        print('******cython:%s*********' % cmd)
        os.system(cmd)

    @staticmethod
    def shell(cmd):
        """ shell """
        return commands.getstatusoutput(cmd)


lastest_file = 'latest.tar.gz'
lastest_back_prefix = '%s.' % lastest_file
env_name = 'env'
svr_name = 'svr'
pub_name = 'pub'

GAME_NAME = 'td'
USER_NAME = 'game'
cfg_dist = 'dist.json'
cfg_config = 'config.json'
cfgs = [cfg_dist, cfg_config]

assert env.user == USER_NAME, 'env.user(%s) != %s' % (env.user, USER_NAME)
HOME_PATH = '/home/%s' % env.user
BIN_PATH = _ssh.join(HOME_PATH, 'bin')
DIST_PATH = _ssh.join(HOME_PATH, '%sdist' % GAME_NAME)
PUB_PATH = _ssh.join(HOME_PATH, '%spub' % GAME_NAME)


def _load_cfg(cfg_path):
    with open(cfg_path, 'rb') as f:
        cfg = json.loads(f.read())
    return cfg

def _init_(cls_list):
    g = {}
    def _add(obj):
        for name in dir(obj):
            if name.startswith('_'):
                continue
            func = getattr(obj, name)
            if not callable(func):
                continue
            g[name] = func
    for cls in cls_list:
        _add(cls())
    return g

