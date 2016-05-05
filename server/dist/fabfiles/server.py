#!/usr/bin/env python
# -*- coding:utf-8 -*-

from os import path
from fab_util import (_tool, _ssh, _init_, _load_cfg,
                      lastest_back_prefix, lastest_file, env_name, svr_name, pub_name, cfg_config,
                      GAME_NAME, HOME_PATH, BIN_PATH, PUB_PATH,
                      )

dist_path = path.abspath(path.dirname(__file__))

#ssh 目录
CFG_PATH = _ssh.join(PUB_PATH, 'config')
ENV_PATH = _ssh.join(PUB_PATH, env_name)
GAME_PATH = _ssh.join(PUB_PATH, svr_name)
PY_BIN = _ssh.join(ENV_PATH, 'bin', 'python')
GAME_MAIN = _ssh.join(GAME_PATH, 'main.pyc')

class _Publish(object):
    """ 执行实际发布动作 """
    def update_svr(self, ver=None):
        """ 上传新的服务端压缩包 """
        _ssh.mkdir(PUB_PATH)
        _ssh.mkdir(CFG_PATH)
        if ver:
            name = '%s%s' % (lastest_back_prefix, ver)
        else:
            name = lastest_file

        with _ssh.cd(PUB_PATH):
            _ssh.rm(lastest_file)
            _ssh.put('config/%s' % cfg_config, _ssh.join(CFG_PATH, cfg_config))
            _ssh.put('%s/%s' % (pub_name, name), _ssh.join(PUB_PATH, lastest_file))
            _ssh.rm(env_name)
            _ssh.rm(svr_name)
            _ssh.run('tar -xzf %s' % lastest_file)


    def pub_init(self):
        """ 安装，需要手动启动 """
#        _ssh.rm(PUB_PATH)
#        _ssh.mkdir(PUB_PATH)
#        self.update_svr()
        #bin
        bin_file = _ssh.join(BIN_PATH, GAME_NAME)
        bin_cmd = '%s %s $*' % (PY_BIN, GAME_MAIN)
        _ssh.mk_sh(bin_file, bin_cmd)
        #ln -s
        _ssh.ln(PY_BIN, _ssh.join(BIN_PATH, 'tdpy'))

    def pub(self, ver=None):
        """ 更新版本 """
        self.update_svr(ver=ver)

    def game_exe(self, svr, *args):
        _ssh.run('%s -c %s %s' % (GAME_NAME, svr, ' '.join(args)), pty=False)

    def start(self, svr):
        """ 启动 """
        self.game_exe(svr, 'start')

    def stop(self, svr):
        """ 停止 """
        self.game_exe(svr, 'stop')

    def restart(self, svr):
        """ 重启 """
        self.stop(svr)
        self.start(svr)

    def status(self, svr):
        """ 状态 """
        self.game_exe(svr, 'status')


_cfg = _load_cfg(path.join(dist_path, 'config', 'dist.json'))
_funcs = _init_([_Publish])
globals().update(_funcs)


#-------------------------------------------------------------------------------


