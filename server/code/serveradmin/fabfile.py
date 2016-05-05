#!/usr/bin/env python
# -*- coding:utf-8 -*-
__author__ = 'kainwu'

from datetime import datetime
from fabric.api import *

# 登录用户和主机名：
env.user = 'kainwu'
#env.hosts = ['172.16.40.2'] # 如果有多个主机，fabric会自动依次部署
env.hosts = ['dev.zl.efun.com'] # 如果有多个主机，fabric会自动依次部署


def pack():
    """ 打包应用 """
    tar_files = ['*.py', 'luffy/*', '*.txt']
    local('rm -f serveradmin.tar.gz')
    local('tar -czvf serveradmin.tar.gz --exclude=\'*.tar.gz\' --exclude=\'*.pyc\' %s' % ' '.join(tar_files))

def publish(*args):
    """ 将打包应用发布至服务器 """
    # 远程服务器临时文件
    remote_tmp_tar = '/tmp/serveradmin.tar.gz'
    #推送打包文件
    put('serveradmin.tar.gz', remote_tmp_tar)
    # 解压
    remote_serveradmin = '/home/game/serveradmin'
    remote_serveradmin91 = '/home/game/serveradmin91'
    run('rm -rf %s' % remote_serveradmin)
    run('mkdir %s' % remote_serveradmin)
    with cd(remote_serveradmin):
        run('tar -xzvf %s' % remote_tmp_tar)

def test(host=''):
    print ha



# class _DB_Backup(object):
#     """docstring for _DB_Backup"""
#     def __init__(self):
#         super(_DB_Backup, self).__init__()
#         self._init()

#     def _init(self):
#         self.remote_host = "s1.zl.52yh.com"
#         self.remote_port = "17017"
#         self.remote_username = "pointing_king"
#         self.remote_password = "5f987c8a88060906abc522eaeb100c74"
#         self.local_host = ''
#         self.local_port = ''
#         self.local_username = ''
#         self.local_password = ''
#         self.local_db, self.local_collection = None
#         self.remote_db, self.remote_collection = None

#     def set_opt(local_db, local_collection, remote_db, remote_collection):
#         self.local_db = local_db
#         self.local_collection = local_collection
#         self.remote_db = remote_db
#         self.remote_collection = remote_collection

#     def pull():
#         mongo_export = ['mongoexport', '-h',]

#     def push():
#         pass
