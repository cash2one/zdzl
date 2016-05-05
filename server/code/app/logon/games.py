#!/usr/bin/env python
# -*- coding:utf-8 -*-
import time

import model
import grpc
from gevent import with_timeout
from corelib import log
from corelib.memory_cache import TimeMemCache


class GameServers(object):
    """ 游戏服组管理类 """
    TIMEOUT = 30
    def __init__(self):
        self.server_time = 0
        self.servers = None
        self.rpc_caches = TimeMemCache(default_timeout=60)

    def _init_servers(self):
        """ 初始化游戏服数据 """
        if self.servers and (time.time() - self.server_time < self.TIMEOUT):
            return
        self.server_time = time.time()
        servers = model.logon_store.get_servers(all=1)
        self.servers = dict([(s.sid, s) for s in servers
                if s.status in s.OPEN_STATUSES])

    def get_servers(self):
        self._init_servers()
        return self.servers

    def iter_servers(self, sids=None):
        self._init_servers()
        if sids is None:
            sids = self.servers.keys()
        for sid in sids:
            if sid not in self.servers:
                continue
            s = self.servers.get(sid)
            host, port = s.host, s.port
            log.debug('iter_servers, host:%s, port:%s', host, port)
            rpc_client = with_timeout(3, grpc.get_proxy_by_addr,
                (host, port-1), 'rpc_client',
                timeout_value=None)
            if not rpc_client:
                continue
            #缓存代理类,保持连接一段时间
            self.rpc_caches.set(sid, rpc_client)
            yield sid, rpc_client


    def get_players(self, sns, sns_id, sids=None):
        """ 获取账号在对应服务器上的角色列表 """
        rs = {}
        def _players(rpc_client):
            try:
                return with_timeout(3, rpc_client.user_players,
                    sns, sns_id,
                    timeout_value=None)
            except:
                return None

        for sid, rpc_client in self.iter_servers(sids):
            log.debug('get_players, sid:%s', sid)
            if not rpc_client:
                continue
            players = _players(rpc_client)
            log.debug('get_players, sid:%s, players:%s', sid, players)
            if not players:
                continue
            rs[str(sid)] = players
        return rs


