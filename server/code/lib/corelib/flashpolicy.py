#!/usr/bin/env python
# -*- coding:utf-8 -*-
import socket
import gevent
from gevent.server import StreamServer
from . import log

allow_all_domain_policy = """<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
   <allow-access-from domain="*" to-ports="*"/>
</cross-domain-policy>
\0"""

class FlashPolicyServer(object):
    def __init__(self):
        self.policy = allow_all_domain_policy

    def start(self):
        self.server = StreamServer(('0.0.0.0', 8843), self.handler)
        try:
            self.server.start()
            log.info(u'Flash沙箱认证服务启动:\n%s', self.policy[:1000])
        except socket.error:
            pass

    def stop(self):
        self.server.stop()

    def set_policy(self, policy):
        if policy:
            self.policy = '%s\0' % policy

    def handler(self, socket, address):
        try:
            socket.sendall(self.policy)
            gevent.sleep(0.5)
        except Exception:
            pass
        finally:
            socket.close()

