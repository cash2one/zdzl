#!/usr/bin/env python
# -*- coding:utf-8 -*-
"""
修正gevent+pymongo时，pool的问题；
如果有多个微线程同时使用同一个connection时，由于它们都在同一个真实线程里面，
这样会引起错误
"""

import os
import pymongo
pymongo_ver = pymongo.version[0]
try:
	import gevent
except ImportError:
	pass

def install():
	_Pool = pymongo.connection._Pool
	if _Pool.__name__ == 'GeventMongoPool':
		return
	if pymongo_ver == '1':
		from gevent.local import local
		class GeventMongoPool(local):
			"""
			Rewrited connection pool for working with global connections.
			"""
			# Non thread-locals
			__slots__ = ["sockets", "socket_factory", "pool_size"]
			def __init__(self, socket_factory, pool_size=8):
				self.pool_size = pool_size
				self.socket_factory = socket_factory
				self.sock = None
				if not hasattr(self, "sockets"):
					self.sockets = []

			def socket(self):
				# we store the pid here to avoid issues with fork /
				# multiprocessing - see
				# test.test_connection:TestConnection.test_fork for an example
				# of what could go wrong otherwise
				pid = os.getpid()

				if self.sock is not None and self.sock[0] == pid:
					return self.sock[1]
				let = gevent.getcurrent()
				if isinstance(let, gevent.Greenlet):
					let.rawlink(self.return_socket_by_greenlet)

				try:
					self.sock = (pid, self.sockets.pop(0))
				except IndexError:
					self.sock = (pid, self.socket_factory())

				return self.sock[1]

			def return_socket(self):
				if self.sock is None:
					return
				let = gevent.getcurrent()
				if isinstance(let, gevent.Greenlet):
					let.unlink(self.return_socket_by_greenlet)

				if len(self.sockets) < self.pool_size:
					self.sockets.append(self.sock[1])
				else:
					self.sock[1].close()
				self.sock = None

			def return_socket_by_greenlet(self, let):
				if let not in self._local__dicts:
					return
				sock = self._local__dicts.pop(let)['sock']
				if sock is None:
					return
				if len(self.sockets) < self.pool_size:
					self.sockets.append(sock[1])
				else:
					sock[1].close()

			def close_socket(self):
				if self.sock is None:
					return
				self.sock[1].close()
				self.sock = None
	else:
		class GeventMongoPool(_Pool):
			def get_socket(self, host, port):
				old_sock = self.sock
				data = _Pool.get_socket(self, host, port)
				if self.sock != old_sock:
					let = gevent.getcurrent()
					if isinstance(let, gevent.Greenlet):
						let.rawlink(self.return_socket_by_greenlet)
				return data

			def return_socket(self):
				if self.sock is not None:
					let = gevent.getcurrent()
					if isinstance(let, gevent.Greenlet):
						let.unlink(self.return_socket_by_greenlet)
				return _Pool.return_socket(self)

			def return_socket_by_greenlet(self, let):
				if let not in self._local__dicts:
					return
				sock = self._local__dicts.pop(let)['sock']
				if sock is None:
					return
				if len(self.sockets) < self.max_size:
					self.sockets.append(sock[1])
				else:
					sock[1].close()

	pymongo.connection._Pool = GeventMongoPool
	return True
install()

