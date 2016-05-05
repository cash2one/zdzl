#!/usr/bin/env python
# -*- coding:utf-8 -*-
import socket
import hashlib
import gevent

import grpc

from . import log
from protobuf import chat_pb2, utils_pb2

def make_player_chat_id(game_name, big_area, area, user_name):
    return hashlib.md5('%s-%s-%s-%s' % (game_name, big_area, area, user_name)).hexdigest()

class GameChat(object):
    def __init__(self, **kw):
        self.net_host = None
        self.local_host = None
        self.port_for_flash = 0
        self.port_for_ctrl = 0
        self.prot_for_chat = 0
        self.count = 0
        self.max_count = 0
        self.net = None
        self.key = None
        self.__dict__.update(kw)
        for name in ['count', 'max_count', 'port_for_flash', 'port_for_ctrl', 'port_for_chat']:
            setattr(self, name, int(getattr(self, name)))


    @property
    def load(self):
        """ 负载值 """
        if self.max_count > 0:
            return self.count / (self.max_count * 1.0)
        else:
            return 0

    def logon(self, name, key):
        """ 登录请求 """
        proxy = None
        try:
            addr = (self.local_host, self.port_for_ctrl)
            proxy = grpc.get_proxy_by_addr(addr, 'chat')
            if proxy is None:
                return False
            rs = proxy.logon(name, key)
            return bool(rs)
        except socket.error:
            log.info(u'登录聊天服务器失败:%s:%s', self.local_host, self.port_for_ctrl)
            return False
        finally:
            pass

class GameChatMgr(object):
    def __init__(self, setting):
        self._setting = setting
        self._index = 0

    def _balance_select(self, chats, net_chats):
        """ 根据负载排序后优先选择 """
        chats.sort()
        net_chats.sort()
        for load, chat in net_chats + chats:
            yield chat

    def _order_select(self, chats, net_chats):
        """ 轮询选择 """
        pre_index = self._index
        cur_index = self._index + 1
        chats = net_chats + chats
        while 1:
            length = len(chats)
            if not length:
                return
            if cur_index >= length:
                cur_index = 0
            load, chat = chats[cur_index]
            self._index = cur_index
            yield chat
            if cur_index == pre_index:
                break
            cur_index += 1

    def logon_chat(self, name, key, net=None, best_chat_key=None):
        """ 请求登录到聊天服务器，name应该为用户uuid """
        with self._setting:
            chat_svrs = self._setting.chat_servers
            if len(chat_svrs) == 0:
                return
            if best_chat_key is not None:
                chat = GameChat(chat_svrs[best_chat_key])
                if chat.logon(name, key):
                    return chat

            chats, net_chats = [], []
            for chat_id, chat_value in chat_svrs.iteritems():
                is_actived = chat_value.get('is_actived', True)
                if not is_actived:
                    continue
                chat = GameChat(**chat_value)
                chat.key = chat_id
                sort_chat = (chat.load, chat)
                if net is not None and chat.net == net:
                    net_chats.append(sort_chat)
                else:
                    chats.append(sort_chat)

            for chat in self._order_select(chats, net_chats):
                if chat.logon(name, key):
                    return chat


