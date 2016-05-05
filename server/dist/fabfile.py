#!/usr/bin/env python
# -*- coding:utf-8 -*-

import os
from os import path
from fab_util import (_tool, _ssh, _init_, _load_cfg,
        lastest_back_prefix, lastest_file, env_name, svr_name, pub_name, cfgs,
        USER_NAME, GAME_NAME, HOME_PATH, BIN_PATH, DIST_PATH,
    )

#本地路径
dist_path = path.dirname(path.abspath(__file__))
app_path = path.dirname(dist_path)
svr_path = path.join(app_path, 'code')

#发布机路径
CFG_PATH = _ssh.join(DIST_PATH, 'config')
GAME_PATH = _ssh.join(DIST_PATH, svr_name)
ENV_PATH = _ssh.join(DIST_PATH, env_name)
PY_BIN = _ssh.join(ENV_PATH, 'bin', 'python')
GAME_MAIN = _ssh.join(GAME_PATH, 'main.pyc')
MODULES_FOLDER = _ssh.join(HOME_PATH, '%smodules'%GAME_NAME)
PUB_PATH = _ssh.join(DIST_PATH, pub_name)

class _Dist(object):
    """ 发布机 """
    DEBIAN_PKGS =["python-setuptools",
                  "python-pip",
                  "python-virtualenv",
                  "libevent-1.4-2",
                  ]
    PY_PKGS = [
        "cython",
        "python-daemon", #lockfile, distribute
        "pymongo",
        "absolute32",
        "psutil",
        "web.py",
        "gunicorn",
        "ujson",
        #"protobuf",
        'M2Crypto',
        'pycrypto',
        "msgpack-python",
        "urllib3",
        "gevent", #greenlet
        "grpc",
    ]
    WEB_PY_PKGS = [
        "Flask",
        "Flask-Admin",
        "xlrd",
        "xlwt",
        "Flask-MongoAlchemy",
        "Flask-Mongoengine",
        "Flask-Principal",
        "Flask-WTF",
        "Flask-Script",
        "pyExcelerator",
        "flask_cache",
        ]

    def __init__(self):
        pass

    def init_debian(self):
        print 'init debian:', '\n'.join(self.DEBIAN_PKGS)

    def pkg_down(self):
        """ py模块下载 """
        down_cmd = 'pip install --no-install -d %s %s'
        _ssh.mkdir(MODULES_FOLDER)
        for m in self.PY_PKGS:
            _ssh.run(down_cmd % (MODULES_FOLDER, m))
        for m in self.WEB_PY_PKGS:
            _ssh.run(down_cmd % (MODULES_FOLDER, m))


    def dist_create(self):
        """ 创建发布目录 """
        _ssh.mkdir(DIST_PATH)
        _ssh.mkdir(BIN_PATH)
        _ssh.rm(ENV_PATH)
        create_cmd = 'virtualenv --no-site-packages  --python=python2.7 %s'
        _ssh.run(create_cmd % ENV_PATH)


    def dist_pkg(self):
        """ 安装py模块 """
        easy_install = _ssh.join(ENV_PATH, 'bin', 'easy_install')
        #easy_install = _ssh.join(ENV_PATH, 'bin', 'pip')
        cmd = '%s -f %s %s'
        for m in self.PY_PKGS:
            _ssh.run(cmd % (easy_install, MODULES_FOLDER, m))

    def web_pkg(self):
        """ 安装web需要的模块 """
        easy_install = _ssh.join(ENV_PATH, 'bin', 'pip install ')
        cmd = '%s -f %s %s'
        for m in self.WEB_PY_PKGS:
            _ssh.run(cmd % (easy_install, MODULES_FOLDER, m))


    def up_cfg(self):
        """ 更新全局配置 """
        _ssh.mkdir(CFG_PATH)
        cfg_local = path.join(dist_path, 'config', '*')
        _ssh.put(cfg_local, CFG_PATH)
#        for cfg in cfgs:
#            cfg_local = path.join(dist_path, 'config', cfg)
#            _ssh.put(cfg_local, _ssh.join(CFG_PATH, cfg))

    def up_svn_info(self):
        """ 更新svn信息到文件 """
        os.chdir(svr_path)
        status, info = _tool.shell('svn info')
        if status:
            status, info = _tool.shell('hg svn info')
        if status:
            print('*****up_svn_info error:', status, info)
            return
        d = info.split()
        i = d.index('Revision:')
        if i < 0:
            print('*****up_svn_info error:', status, info)
            return
        svn_info = d[i+1]
        _tool.shell('echo %s > svn_version' % svn_info)
        print('****up_svn_info:', _tool.shell('cat svn_version'))

    def up_svr(self):
        """ 更新服务器代码 """
        self.up_svn_info()
        corelib = ('lib', 'corelib')
        _corelib_pyx = corelib + ('_corelib.pyx', )
        #编译pyx
        _tool.cython(path.join(svr_path, *_corelib_pyx))
        #
        _tool.compile_pyc(svr_path)

        rpath = GAME_PATH
        if _ssh.exists(rpath):
            _ssh.rm(rpath)
        _ssh.mkdir(rpath)
        _ssh.mkdir(PUB_PATH)
        exclude = ('.hg/', '.svn/', 'pkg/', 'runtime/', '*.py', '*.log', '*.profile',
                   '*.pyx', '*/build/', '*.so', '*.pyd',
                   '.*', 'dist/', '**local_config.pyc', '*.rar')
        _ssh.rsync_project(local_dir=path.join(svr_path, '*'), remote_dir=rpath+'/',
            delete=True, exclude=exclude, extra_opts='--delete-excluded')

        with _ssh.cd(DIST_PATH):
            #编译
            with _ssh.cd(_ssh.join(DIST_PATH, 'svr', *corelib)):
                _ssh.run('%s setup.pyc build_ext --inplace' % PY_BIN)
            # 打包
            _ssh.run('tar -czf %s/%s ./%s ./%s' % (pub_name, lastest_file, env_name, svr_name))
            #备份处理
            _ssh.run('cp %s/%s %s/%s%s' % (pub_name, lastest_file, pub_name, lastest_back_prefix, _tool.strftime()))

    def backups(self, show=1):
        """ 获取备份的tar.gz文件列表(show=1) """
        back_len = len(lastest_back_prefix)
        with _ssh.cd(PUB_PATH):
            out = _ssh.run('ls %s*' % lastest_back_prefix)
        backfiles = out.split()
        rs = []
        if show: print 'backup name:'
        for bf in backfiles:
            n = bf[back_len:]
            rs.append(n)
        rs.sort()
        if show:
            for n in rs:
                print ' ',n
        return rs

    def clear_backup(self, remain=5):
        """ 清理备份的tar.gz文件，保留remain个(remain=5) """
        backfiles = self.backups(show=0)
        backfiles.sort()
        l = len(backfiles)
        if l > remain:
            clears = backfiles[:-remain]
            with _ssh.cd(PUB_PATH):
                for n in clears:
                    _ssh.run('rm %s%s' % (lastest_back_prefix, n))



def _wrap_up_fab(func):
    def _func(self, *args, **kw):
        self._up_fab()
        return func(self, *args, **kw)
    return _func

def _wrap_fab(func):
    def _func(self, *args, **kw):
        self._fab(func.func_name, *args, **kw)
    _func.func_doc = func.func_doc
    return _func

class _Publish(object):
    """ 发布类 """
    _names = set()
    _svrs = {}
    def names(self, *args):
        """ 设定发布机器名列表:name1,name2,name3,...可附带运行的游戏服名,如:name1[td1-td2],name2[n21-n22] """
        for arg in args:
            if '[' not in arg:
                self._names.update(args)
            else:
                i = arg.index('[')
                name = arg[:i]
                data = arg[i+1:-1]
                self._names.add(name)
                svrs = self._svrs.setdefault(name, set())
                svrs.update(data.split('-'))

    def _up_fab(self):
        """ 上传fabric脚本 """
        if getattr(self, '_up_fabed', False):
            return
        self._up_fabed = True

        fab_local = path.join(dist_path, 'fabfiles', 'server.py')
        fab_ssh = _ssh.join(DIST_PATH, 'fabfile.py')
        _ssh.put(fab_local, fab_ssh)
        util_local = path.join(dist_path, 'fab_util.py')
        util_ssh = _ssh.join(DIST_PATH, 'fab_util.py')
        _ssh.put(util_local, util_ssh)

    @_wrap_up_fab
    def _fab(self, cmd, *args, **kw):
        params = ','.join(list(args) + ['%s=%s' % (k,v) for k,v in kw.iteritems()])
        print(self._svrs, self._names)
        with _ssh.cd(DIST_PATH):
            for n in self._names:
                host = _cfg['names'].get(n)
                if not host:
                    print(u'***机器名(%s)找不到对应配置***' % n)
                    continue
                svrs = self._svrs.get(n)
                if svrs is None:
                    if params:
                        _ssh.run('fab -u %s -H %s %s:%s' % (USER_NAME, host, cmd, params))
                    else:
                        _ssh.run('fab -u %s -H %s %s' % (USER_NAME, host, cmd))
                else:
                    print(svrs)
                    for svr in svrs:
                        if params:
                            _ssh.run('fab -u %s -H %s %s:%s,%s' % (USER_NAME, host, cmd, svr, params))
                        else:
                            _ssh.run('fab -u %s -H %s %s:%s' % (USER_NAME, host, cmd, svr))



    @_wrap_fab
    def pub(self, *args, **kw):
        """ 发布代码: ver:版本名: pub:[ver=1] """

    @_wrap_fab
    def pub_init(self, *args, **kw):
        """ 安装初始化发布环境 """

    @_wrap_fab
    def start(self):
        """ 启动 """
    @_wrap_fab
    def stop(self):
        """ 停止 """
    @_wrap_fab
    def restart(self):
        """ 重启 """
    @_wrap_fab
    def status(self):
        """ 查看状态 """

        
_cfg = _load_cfg(path.join(dist_path, 'config', 'dist.json'))
_funcs = _init_([_Dist, _Publish])
globals().update(_funcs)

#-------------------------------------------------------------------------------




