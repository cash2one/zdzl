#!/usr/bin/env python
# -*- coding:utf-8 -*-
import socket
import chl_api

from game import Game, grpc_monitor
from corelib import log, sleep, spawn, json
from corelib.tools import http_post_ex
from game.base import msg_define
from game.store.define import GF_dbVer, TN_SERVER

import config
import app

class GameReport(object):
    """频道服务器统计报告"""

    def __init__(self, client):
        if 0:
            self.client = GameClient()
        self.client = client
        self.logouts = []

    def start(self):
        self._loop_task = spawn(self._loop)

    def stop(self):
        self._loop_task.kill(block=False)
        #self.update_report()

    def _loop(self):
        while 1:
            sleep(config.report_times)
            try:
                self.update_report()
            except socket.error as err:
                log.warn('socket error:%s', err)
            except:
                log.log_except()

    def update_report(self):
        """ 更新报表 """
        #在线人数
        count = Game.rpc_player_mgr.get_count()
        Game.glog.log_online(dict(c=count))

class BaseClient(chl_api.ChannelApi):
    def reload(self):
        """ 动态加载chl_api，并继承 """
        try:
            reload(chl_api)
        except StandardError:
            log.log_except()
            return
        BaseClient.__bases__ = (chl_api.ChannelApi, )

class GameClient(BaseClient):
    """ 游戏逻辑与外部其它进程(web,logon)的交互 """
    _rpc_name_ = 'rpc_client'
    SERVERS_JSON = 'servers.json'
    TIMEOUT = 10
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        self.db_ver = 0
        self.server_id = 0
        self.stoped = True
        app.sub(msg_define.MSG_START, self.start)

    def start(self):
        if not self.stoped:
            return
        self.stoped = False
        self.report = GameReport(self)
        self.report.start()

    def stop(self):
        if self.stoped:
            return
        self.stoped = True
        try:
            self.report.stop()
        except:
            log.log_except()
        self.report = None

    @grpc_monitor
    def sync_exec(self, func, args, _pickle=True):
        """ 由该进程执行func, func内独立使用各自的lock,保证同步执行 """
        try:
            if args:
                return func(*args)
            return func()
        except:
            log.log_except()
            raise


#    def _find_server_id(self, servers):
#        """ 查找本服对应的服务器id """
#        host, port = config.inet_ip, config.player_addr[1]
#        for s in servers:
#            if s['host'] == host and s['port'] == port:
#                if self.server_id != s['sid']:
#                    log.warn('*****update serverId:%s', s['sid'])
#                self.server_id = s['sid']
#                return
#        log.error('********servers.json: not found server id for (%s, %s)',
#                host, port)
#        if not self.server_id:
#            raise ValueError('server id not found')
#
#
#    def _update_info1(self):
#        """ 读取servers.json """
#        v = Game.gcaches.get(self.SERVERS_JSON)
#        if v:
#            return 0
#        try:
#            rs = http_post_ex(*config.servers_json_url)
#            if not rs:
#                log.error('*********get servers.json error!:%s', rs)
#                return 0
#            data = json.loads(rs)
#            self.db_ver = int(data['db_ver'])
#            self._find_server_id(data['servers'])
#            Game.gcaches.set(self.SERVERS_JSON, 1, timeout=self.TIMEOUT)
#            return 1
#        except:
#            log.log_except()
#        return 0

    @grpc_monitor
    def get_server_id(self):
        """ 服id """
        if not self.server_id:
            #server id
            host, port = config.inet_ip, config.player_addr[1]
            try:
                servers = Game.rpc_res_store.query_loads(TN_SERVER,
                    dict(host=host, port=port))
                if len(servers) != 1:
                    log.error(u'server id error:%s', str(servers))
                    raise ValueError('server id error')
                self.server_id = servers[0]['sid']
                log.info('server_id:%s', self.server_id)
            except:
                if not self.server_id:
                    raise
        return self.server_id


def new_client():
    mgr = GameClient()
    return mgr


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
