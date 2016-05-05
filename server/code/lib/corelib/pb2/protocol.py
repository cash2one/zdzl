#!/usr/bin/env python
# -*- coding:utf-8 -*-

__all__ = [
	'ProtocolPb2',
	'Pb2Unpacker',
	'Pb2Packer',
#	'ProtocolPb2Factory',
]

# MAX_PACKAGE_LENGTH = 65535
DEFAULT_FORMAT = '!'
import struct
#from StringIO import StringIO
from cStringIO import StringIO
try:
	import corelib.pb2.etc as etc
except ImportError:
	import etc


from corelib import log, common
logger = log.getLogger()

from google.protobuf import message
Pb2Class = message.Message

class MsgObject(common.CustomObject):
	pass


def get_msg_obj(msg):
	if not isinstance(msg, Pb2Class):
		raise ValueError, 'msg(%s) mush be Message class' % (msg, )

	obj = MsgObject()
	for f, i in msg.ListFields():
		v = getattr(msg, f.name)
		setattr(obj, f.name, v)

	return obj


class Pb2Error(ValueError): pass
class SafePb2Error(Pb2Error): pass


class Unpacker(object):
	def __init__(self, fmt, unpack_func):
		self._fmt = fmt
		self._unpack_func = unpack_func
		self._buffer = StringIO()
		self._head_fmt = self._fmt + 'I'
		self._msg_id_size = self._need_size = struct.calcsize(self._head_fmt)
		self.min_size = self._need_size + self._msg_id_size

	def init(self):
		self._buffer.truncate(0)

	def _buffer_size(self):
		cur_pos = self._buffer.tell()
		self._buffer.seek(0, 2)
		size = self._buffer.tell()
		self._buffer.seek(cur_pos)
		return size - cur_pos


	def raw_unpack(self, data):
		""" 解一个没有长度的包数据 """
		fmt = '%sI%ds'%(self._fmt, len(data) - self._msg_id_size)
		try:
			id, msg = struct.unpack(fmt, data)
		except struct.error:
			return None
		return self._unpack_func(id, msg)

	def unpack(self, data):
		#往最后添加数据
		cur_pos = self._buffer.tell()
		self._buffer.seek(0, 2)
		self._buffer.write(data)
		#定位回当前位置
		self._buffer.seek(cur_pos)
		packages = []
		size = self._buffer_size()
		while size > self._need_size:
			need = struct.unpack(self._head_fmt, self._buffer.read(self._need_size))[0]
			if need == 0:#心跳
				logger.debug(u'收到心跳包')
				size -= self._need_size
				continue

			if need > size:
				self._buffer.seek(-self._need_size, 1)
				break

			size -= need
			data = self._buffer.read(need - 4)
			t = self.raw_unpack(data)
			if t is not None:
				packages.append(t)

		if not size and self._buffer.tell() > 0:
			self.init()
		return packages


class SafeUnpacker(Unpacker):
	def __init__(self, *args, **kw):
		Unpacker.__init__(self, *args, **kw)
		self.adler_value = 1

	def set_token(self, token):
		self.r_token = token

	def unpack(self, data):
		#往最后添加数据
		from absolute32 import adler, add
		cur_pos = self._buffer.tell()
		self._buffer.seek(0, 2)
		self._buffer.write(data)
		#定位回当前位置
		self._buffer.seek(cur_pos)
		packages = []
		size = self._buffer_size()
		while size >= 8:
			_sn = struct.unpack('!i', self._buffer.read(4))[0]
			need = struct.unpack(self._head_fmt, self._buffer.read(4))[0]
			if _sn == 0 and need == 4:#心跳
				#logger.debug(u'收到心跳包')
				size -= 8
				continue

			data_len = need + 4
			if data_len > size:
				self._buffer.seek(-8, 1)
				break
			size -= data_len
			data = self._buffer.read(need - 4)
			#序号检验
			adler_value = adler(data[self._msg_id_size:], self.adler_value)
			sn = add(self.r_token, need) ^ adler_value
			if _sn != sn:
				raise SafePb2Error, '%s != %s, %s, %s %s' % \
					(_sn, self.r_token, need, adler_value, sn)
			self.adler_value = adler_value
			self.r_token = sn

			t = self.raw_unpack(data)
			if t is not None:
				packages.append(t)

		if not size and self._buffer.tell() > 0:
			self.init()
		return packages



class Unpacker1(object):
	def __init__(self, fmt, unpack_func):
		self._fmt = fmt
		self._unpack_func = unpack_func
		self._buffer = ''
		self._need = 0
		self._msg_id_size = self._need_size = struct.calcsize(self._fmt + 'I')

	def init(self):
		self._buffer = ''
		self._need = 0

	def unpack(self, data):
		self._buffer += data
		packages = []
		while True:
			if not self._buffer:
				break
			if self._need <= 0:
				if not self._read_need():
					break
			assert self._need > 0
# 			if self._need > MAX_PACKAGE_LENGTH:
# 				self._need = 0
# 				self._buffer = ''
# 				break
			t = self._unpack()
			if t is None:
				self._need = 0
				self._buffer = ''
				break
			packages.append(t)
		return packages

	def _read_need(self):
		assert self._need == 0
		while True:
			if len(self._buffer) < self._need_size:
				return False
			try:
				self._need = struct.unpack('%sI'%(self._fmt), self._buffer[:self._need_size])[0]
			except struct.error:
				return False
			self._need -= self._need_size
			self._buffer = self._buffer[self._need_size:]

			if self._need > 0:
				return True

		return False

	def _unpack(self):
		assert self._need > 0
		if len(self._buffer) < self._need:
			return None
		fmt = '%sI%ds'%(self._fmt, self._need - self._msg_id_size)
		try:
			id, msg = struct.unpack(fmt, self._buffer[:self._need])
		except struct.error:
			return None
		self._buffer = self._buffer[self._need:]
		self._need = 0
		return self._unpack_func(id, msg)

class Packer(object):
	def __init__(self, fmt, pack_func):
		self._fmt = fmt
		self._pack_func = pack_func
		self._msg_id_size = self._need_size = struct.calcsize(self._fmt + 'I')

	def pack(self, data):
		_id, pkg = self._pack_func(data)
		return struct.pack('%sII%ds'%(self._fmt, len(pkg)),
				len(pkg) + self._need_size + self._msg_id_size,
				_id,
				pkg)

	def raw_pack(self, data):
		'''返回一个没有包长度的二进制包。
		'''
		_id, pkg = self._pack_func(data)
		return struct.pack('%sI%ds'%(self._fmt, len(pkg)),
				_id,
				pkg)

class SafePacker(Packer):
	def safe_pack_raw(self, raw_data, token, adler_value):
		import absolute32
		slen = len(raw_data) + self._need_size
		adler_value = absolute32.adler(raw_data[self._msg_id_size:], adler_value)
		sn = absolute32.add(token, slen) ^ adler_value
		rs = struct.pack('%siI' % self._fmt, sn, slen) + raw_data
		return rs, sn, adler_value

	def safe_pack(self, data, token, adler_value):
		import absolute32
		_id, pkg = self._pack_func(data)
		len_pkg = len(pkg)
		slen = len_pkg + self._need_size + self._msg_id_size
		adler_value = absolute32.adler(pkg, adler_value)
		sn = absolute32.add(token, slen) ^ adler_value
		rs = struct.pack('%siII%ds'%(self._fmt, len_pkg),
				sn,
				slen,
				_id,
				pkg)
		return rs, sn, adler_value


def unpack_func(_id, msg):
	cls = etc.get_msg_class(_id)
	obj = cls()
	obj.ParseFromString(msg)
	return obj

def pack_func(data):
	_id = etc.get_msg_id(data)
	try:
		pkg = data.SerializeToString()
	except Exception, e:
		cls = etc.get_msg_class(_id)
		log.error(u'pack_func(id=%s, class=%s, data=%s) error:%s', \
			_id, cls, data, e)
		raise
#	logger.debug(u'打包数据:%s - %s - %s' % (_id, type(data),
#			repr(struct.pack('%sI%ds'%(DEFAULT_FORMAT, len(pkg)),	_id, pkg))))
	return _id, pkg

class Pb2Unpacker(Unpacker):
	def __init__(self, fmt = DEFAULT_FORMAT):
		Unpacker.__init__(self, fmt, unpack_func)

class Pb2Packer(Packer):
	def __init__(self, fmt = DEFAULT_FORMAT):
		Packer.__init__(self, fmt, pack_func)

class SafePb2Unpacker(SafeUnpacker):
	def __init__(self, fmt = DEFAULT_FORMAT):
		SafeUnpacker.__init__(self, fmt, unpack_func)

class SafePb2Packer(SafePacker):
	def __init__(self, fmt = DEFAULT_FORMAT):
		SafePacker.__init__(self, fmt, pack_func)


_pb2packer = Pb2Packer()
def pack(data):
	return _pb2packer.pack(data)

def raw_pack(data, fmt = DEFAULT_FORMAT, pack_func=pack_func):
	'''返回一个没有包长度的二进制包。'''
	_id, pkg = pack_func(data)
	return struct.pack('%sI%ds'%(fmt, len(pkg)),
			_id,
			pkg)

def raw_unpack(data, fmt = DEFAULT_FORMAT, unpack_func=unpack_func):
	""" 解一个没有长度的包数据 """
	fmt = '%sI'% fmt
	size = struct.calcsize(fmt)
	id, msg = struct.unpack(fmt, data[:size])[0], data[size:]
	return unpack_func(id, msg)


# class ProtocolPb2(object):
# 	def __init__(self, fmt, uf, pf):
# 		self._fmt = fmt
# 		self._uf = uf
# 		self._pf = pf
# 		self._unpacker = Unpacker(fmt, uf)
# 		self._packer = Packer(fmt, pf)
# 		self.auto_init = False
#
# 	def clone(self):
# 		return self.__class__(self._fmt, self._uf, self._pf)
#
# 	def init(self):
# 		self._unpacker.init()
#
# 	def unpack(self, data):
# 		try:
# 			rs = self._unpacker.unpack(data)
# 			return rs
# 		finally:
# 			if self.auto_init:
# 				self.init()
#
# 	def pack(self, data):
# 		return self._packer.pack(data)
#
# 	is_valid_pack_data = staticmethod(is_valid_msg_obj)
#
# def ProtocolPb2Factory():
# 	return ProtocolPb2(DEFAULT_FORMAT, unpack_func, pack_func)

if __name__ == '__main__':
	pass

