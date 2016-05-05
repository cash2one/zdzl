#!/usr/bin/env python
# -*- coding:utf-8 -*-
__all__ = [
		'init',
		'get_msg_id',
		'get_msg_class',
		'UnregisterMessageType',
		'UnregisterMessageId',
		]

class UnregisterMessageType(StandardError):pass
class UnregisterMessageId(StandardError):pass
class ProtocolError(StandardError):pass


full_name_map_msg_id = {}
msg_id_map_msg_class = {}

protocol_modules = {}

initialized = False

def check_init(f):
	def _f(*a, **k):
		if not initialized:
			raise Exception, 'use pb2 before init pb2.etc'
		return f(*a, **k)
	return _f

def check_uninit(f):
	def _f(*a, **k):
		if initialized:
			raise Exception, 'pb2.etc is already initialized.'
		return f(*a, **k)
	return _f

def init_full_name_map_msg_id(xml_file):
	import xml.etree.ElementTree as et
	elem = et.parse(xml_file)
	root = elem.getroot()
	for node in root.getchildren():
		k = node.text.strip()
		assert k
		v = int(node.get('msg_id'))
		full_name_map_msg_id[k] = v


def _init_sub_mod(sub_mod):
	for v in sub_mod.__dict__.itervalues():
		try:
			full_name = v.DESCRIPTOR.full_name
		except AttributeError:
			continue
		try:
			msg_id = full_name_map_msg_id[full_name]
		except KeyError:
			continue
		msg_id_map_msg_class[msg_id] = v

def init_msg_id_map_msg_class(protocol_dir):
	import sys, glob
	import os.path
	import imp
	from corelib import log

	# import package first
	path, mdname = os.path.split(protocol_dir)
	if path not in sys.path:
		sys.path.insert(0, path)
	try:
		file, filename, description = imp.find_module(mdname)
		md = imp.load_module(mdname, file, filename, description)
	except ImportError:
		log.error('ImportError:%s', mdname)
		raise

	pyfiles = glob.glob(os.path.join(protocol_dir, '*.py'))
	if not pyfiles:
		pyfiles = glob.glob(os.path.join(protocol_dir, '*.pyc'))
	for pyfile in pyfiles:
		name, ext = os.path.splitext(os.path.basename(pyfile))
		file, filename, description = imp.find_module(name, [protocol_dir])
		mod = imp.load_module('.'.join((mdname, name)), file, filename, description)
		#修正奇怪问题：from protobuf import xxxx会出现import错误,可能发生在：protobuf未导入之前，执行了上面的代码
		setattr(md, name, mod)
		_init_sub_mod(mod)
		protocol_modules[pyfile] = mod

def init_msg_id_map_msg_class_from_mod(protocol_mod):
	for name in dir(protocol_mod):
		if name.endswith('_pb2'):
			sub_mod = getattr(protocol_mod, name)
			_init_sub_mod(sub_mod)


#@check_uninit
def init(protocol_dir, full_name_map_msg_id_xml, mod=None):
	global initialized
	if initialized:
		return
	init_full_name_map_msg_id(full_name_map_msg_id_xml)
	if mod:
		init_msg_id_map_msg_class_from_mod(mod)
	else:
		init_msg_id_map_msg_class(protocol_dir)
	initialized = True

@check_init
def get_msg_id(msg_obj):
	try:
		return full_name_map_msg_id[msg_obj.DESCRIPTOR.full_name]
	except KeyError:
		raise UnregisterMessageType, str(msg_obj)
	except StandardError:
		raise ValueError, str(msg_obj)

@check_init
def get_msg_class(msg_id):
	try:
		return msg_id_map_msg_class[msg_id]
	except KeyError:
		raise UnregisterMessageId, msg_id

if __name__ == '__main__':
	init(r'C:\test_protobuf\src', r'.\test.xml')
	print full_name_map_msg_id
	print msg_id_map_msg_class
	print '*'*20
	cls = get_msg_class(0)
	print cls
	obj = cls()
	print get_msg_id(obj)

