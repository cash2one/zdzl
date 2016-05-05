#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys, os
import errno

import subprocess, atexit
import gevent

from corelib import log

BUFSIZE = 1024 * 10

class LocalProcessMgr(object):
	def __init__(self, cwd):
		self.pids = {}
		atexit.register(self.killall)
		self.default_cwd = cwd

	@staticmethod
	def split_cmd(s):
		"""
		str --> [], for subprocess.Popen()
		"""
		SC = '"'
		a	= s.split(' ')
		cl = []
		i = 0
		m = 0
		while i < len(a) :
			if a[i] == '' :
				i += 1
				continue
			if a[i][0] == SC :
				n = i
				loop = True
				while loop:
					if a[i] == '' :
						i += 1
						continue
					if a[i][-1] == SC :
						loop = False
						m = i
					i += 1
				cl.append((' '.join(a[n:m+1]))[1:-1])
			else:
				cl.append(a[i])
				i += 1
		return cl

	def _init_stdout_err(self, kw):
#		kw.update(dict(stdout=subprocess.PIPE, stderr=subprocess.PIPE))
		pass

	@property
	def count(self):
		return len(self.pids)

	def start_process(self, cmd, cwd=None, env=None):
		""" 启动进程 """
		executable, shell = None, False
		if cwd is None:
			cwd = self.default_cwd
		if sys.platform == 'win32':
			shell = False
		else:
			shell = False
			cmd = self.split_cmd(cmd)
			#cmd = ["/bin/sh", "-c", cmd]
		kw = dict(args=cmd,
				cwd=cwd,
				executable=executable,
				bufsize=BUFSIZE,
				shell=shell,
				env=env,
				)
		self._init_stdout_err(kw)

		#log.debug(u'启动子进程:%s', kw)
		popen = subprocess.Popen(**kw)
		self.pids[popen.pid] = popen
		return popen.pid

	def kill_process(self, pid):
		if pid in self.pids:
			popen = self.pids.pop(pid)
			if isinstance(popen, subprocess.Popen):
				try:
					popen.kill()
				except StandardError, e:
					if hasattr(e, 'errno') and e.errno == errno.ESRCH:
						pass
					else:
						log.error('kill subprocess error:%s - %s', type(e), e)

	def killall(self):
		log.info(u'进程退出，停止所有子进程')
		pids = self.pids.keys()
		while len(pids) > 0:
			pid = pids.pop()
			self.kill_process(pid)


