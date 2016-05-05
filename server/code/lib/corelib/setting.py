#!/usr/bin/env python
# -*- coding:utf-8 -*-
from UserDict import UserDict
import urlparse
import hashlib
from bson.code import Code

from . import log
import pymongo
from pymongo.collection import Collection
from pymongo.errors import OperationFailure
pymongo_ver = pymongo.version[0]
if pymongo.version <= '2.1':
    import mongo_pool

sum_map = Code(
"""
function (){
	emit("sum", this.%s);
}
""")

sum_reduce = Code(
"""
function (key, emits){
	var total = 0;
	for (var i in emits){
		total += emits[i];
	}
	return total;
}
""")

copy_collection = u"""
function (){
	db.getCollection('%s').find().forEach(function (x){db.getCollection('%s').insert(x)});
}
"""
def _get_value_new(item):
	item.pop('_id')
	return item

class _MongoDict(object):
	def __init__(self, owner, item):
		if 0:
			self._item = Collection()
			self._owner = MongoSetting()
		self._owner = owner
		self._item = item

	def _get_cursor_(self):
		cur = self._item.find(sort=[('_id', pymongo.ASCENDING)])
		return cur

	def __getattr__(self, item):
		if item[0] == '_':
			return object.__getattribute__(self, item)
		return _MongoDict(self._owner, getattr(self._item, item))

	def __getitem__(self, key):
		adict = self._item.find_one(dict(_id=key))
		if adict is None:
			raise KeyError
		return _get_value_new(adict)

	def __setitem__(self, key, value):
		adict = dict(value)
		adict['_id'] = key
		self._item.save(adict)

	def __delitem__(self, key):
		adict = dict(_id=key)
		self._item.remove(adict)

	def __iter__(self):
		cur = self._get_cursor_()
		for item in cur:
			yield item['_id']

	def __len__(self):
		return self._item.count()

	def __enter__(self):
		self._owner._auth()
		return self

	def __exit__(self, *args):
		self._item.database.connection.end_request()

	def keys(self):
		cur = self._get_cursor_()
		return [item['_id'] for item in cur]

	def values(self):
		cur = self._get_cursor_()
		func = _get_value_new
		return [func(item) for item in cur]

	def iterkeys(self):
		cur = self._get_cursor_()
		for item in cur:
			yield item['_id']

	def itervalues(self):
		cur = self._get_cursor_()
		for item in cur:
			yield func(item)

	def iteritems(self):
		cur = self._get_cursor_()
		func = _get_value_new
		for item in cur:
			yield item['_id'], func(item)

	def get(self, key, default=None):
		try:
			return self[key]
		except KeyError:
			return default

	def pop(self, key, default=None):
		value = self[key]
		del self[key]
		return value if value is not None else default

	def drop(self):
		self._item.drop()

	def get_mulit_dict(self, dict_name, keys):
		""" 多key字典
		keys: key名称列表，如：['key1', 'key2']
		"""
		return _MongoMulitDict(self._owner, getattr(self._item, dict_name), keys)

	def get_dict(self, name, **kwargs):
		return self._owner.get_dict(u"%s.%s" %(self._item.name, name), **kwargs)

	def get_sum(self, col_name, query=None):
		"""
		query={"query_col" : {"$gt" : value}, ...}
		$gt can be replace by $lt, etc.
		"""
		try:
			q = self._item.inline_map_reduce(sum_map % col_name, sum_reduce,
				query=query)
			if q:
				return q[0][u'value']
			return 0
		except OperationFailure as e:
			if 'ns doesn\'t exist' in e.args[0]:
				return 0
			else:
				raise

	def get_sort(self, col_name, limit, direction=1):
		""" 1=pymongo.ASCENDING, -1=pymongo.DESCENDING """
		direction = pymongo.ASCENDING if direction == 1 else pymongo.DESCENDING
		sort_cur = self._item.find(sort=[(col_name, direction)], limit=limit)
		return list(sort_cur)

	def get_sort_dict(self, col_name, limit, direction=1):
		""" 1=pymongo.ASCENDING, -1=pymongo.DESCENDING """
		direction = pymongo.ASCENDING if direction == 1 else pymongo.DESCENDING
		sort_cur = self._item.find(sort=[(col_name, direction)], limit=limit)
		func = _get_value_new
		def _func(item, index):
			item = func(item)
			item['_index'] = index
			return item
		return dict([(item['_id'], _func(item, index)) for index, item in enumerate(sort_cur)])

	def copy_table_to(self, target):
		"""
		Copy this mongo table to another at the same db
		"""
		_db = self._owner._db
		source_name, target_name = self._item.name, target._item.name
		_db.eval(copy_collection%(source_name, target_name))

	def eval(self, js_expression, *args):
		self._owner._db.eval(js_expression, *args)

	@property
	def exists(self):
		return self._item.name in self._owner._db.collection_names()

class _MongoMulitDict(object):
	def __init__(self, owner, item, keys):
		if 0:
			self._item = Collection()
			self._owner = MongoSetting()
		assert isinstance(keys, (tuple, list)), "MulitDict keys mush be tuple or list"
		self._owner = owner
		self._item = item
		self._keys = keys
		for key in keys:
			self._item.ensure_index([(key, pymongo.ASCENDING)])

	def __enter__(self):
		self._owner._auth()
		return self

	def __exit__(self, *args):
		self._item.database.connection.end_request()

	def _make_id(self, key_values):
		assert len(self._keys) == len(key_values), "MulitDict keys mush be tuple or list"
		return hashlib.md5('-'.join([str(v) for v in key_values])).hexdigest()

	def _make_keys_dict(self, key_values):
		#dict(zip(self._keys, key_values))
		adict = dict(_id = self._make_id(key_values))
		return adict

	def _get_cursor_(self, **kw):
		for key in kw.keys():
			assert key in self._keys, 'key(%s) not found' % key
		if not kw:
			kw = None
		cur = self._item.find(kw, sort=[('_id', pymongo.ASCENDING)])
		return cur

	def _iter_cursor_(self, cur, have_value):
		for item in cur:
			if have_value:
				yield tuple([item[key_name] for key_name in self._keys]), item['value']
			else:
				yield tuple([item[key_name] for key_name in self._keys])

	def __getitem__(self, key_values):
		assert isinstance(key_values, (tuple, list)) and len(self._keys) == len(key_values), "MulitDict keys mush be tuple or list"
		adict = self._item.find_one(self._make_keys_dict(key_values))
		if adict is None:
			raise KeyError
		return adict['value']

	def __setitem__(self, key_values, value):
		assert isinstance(key_values, (tuple, list)) and len(self._keys) == len(key_values), "MulitDict keys mush be tuple or list"
		adict = self._make_keys_dict(key_values)
		adict.update(zip(self._keys, key_values))
		adict['value'] = value
		self._item.save(adict)

	def __delitem__(self, key_values):
		assert isinstance(key_values, (tuple, list)) and len(self._keys) == len(key_values), "MulitDict keys mush be tuple or list"
		self._item.remove(self._make_keys_dict(key_values))

	def __len__(self):
		return self._item.count()

	def __iter__(self):
		cur = self._get_cursor_()
		return self._iter_cursor_(cur, False)

	def iteritems(self):
		cur = self._get_cursor_()
		return self._iter_cursor_(cur, True)

	def iter_items_by_key(self, **kw):
		assert bool(kw), 'kw is empty, etc:key1=value1, key2=value2'
		cur = self._get_cursor_(**kw)
		return self._iter_cursor_(cur, True)

	def del_by_key(self, **kw):
		assert bool(kw) and set(kw.keys()).issubset(self._keys), 'kw(%s) is empty or invaild, etc:key1=value1, key2=value2' % repr(kw)
		self._item.remove(kw)

	def get(self, key_values, default=None):
		try:
			return self[key_values]
		except KeyError:
			return default

	def pop(self, key_values, default=None):
		""" 注意，线程冲突问题 """
		value = self[key_values]
		del self[key_values]
		return value if value is not None else default

	def drop(self):
		""" 删除当前整个collection内容 """
		self._item.drop()

class MongoSetting(object):
	timeout = 60
	def __init__(self, name=''):
		if 0:
			from pymongo import database
			self._conn = pymongo.Connection()
			self._db = database.Database()
		self._conn = None
		self._db = None
		self._name = name
		self.username = None
		self.pwd = None
		self._pool = None

	def add_server(self, url):
		"""
		 url: mongodb://jhy:123456@192.168.0.110/jhy
		"""
		assert self._conn is None, 'already had server'
		urler = urlparse.urlparse(url)
		try:
			if pymongo_ver == '1':
				self._conn = pymongo.Connection(urler.hostname, urler.port,
					network_timeout=self.timeout)
				#hack 获取连接池，用于认证功能
				self._pool = self._conn._Connection__pool
				dbname = urler.path[1:]
				self._db = getattr(self._conn, dbname)
				if urler.username:
					self.username = urler.username
					self.pwd = urler.password
					self._auth()
					self.end_request()
			else:
				self._conn = pymongo.Connection(url, network_timeout=self.timeout)
				self._pool = self._conn._Connection__pool
				dbname = urler.path[1:]
				self._db = getattr(self._conn, dbname)
				if urler.username:
					self.username = urler.username
					self.pwd = urler.password
			self._setting = getattr(self._db, self._name) if self._name else self._db

		except pymongo.errors.AutoReconnect:
			log.error(u'连接mongoDB(%s:%s)失败', urler.hostname, urler.port)
			raise

	def drop_database(self):
		self._conn.drop_database(self._db)

	def add_user(self, name, password):
		#pymongo中的加了角色缺少readOnly属性
		#self._db.add_user(name, password)
		from pymongo import common, helpers
		pwd = helpers._password_digest(name, password)
		self._db.system.users.update({"user": name},
								 {"user": name,
								  "pwd": pwd,
								  "readOnly": False},
								 upsert=True, safe=True)

	if pymongo_ver == '1':
		def _auth(self):
			""" 权限认证 """
			sock = self._pool.socket()
			if hasattr(sock, '_setting_authed_'):
				return True
			if not self._db.authenticate(self.username, self.pwd):
				raise StandardError, 'authenticate fail!'
			sock._setting_authed_ = True
	else:
		_auth = lambda self:None

	def close(self):
		self._conn.disconnect()

	def end_request(self):
		""" 多线程(包含微线程)情况下，每个线程会创建独立的socket，
		当线程用完，需要手动调用下本函数，释放该socket资源
		"""
		self._conn.end_request()

	def __getattr__(self, item):
		return _MongoDict(self, getattr(self._setting, item))

	def __enter__(self):
		""" 判断是否需要认证,这里gevent.socket.socket可以被设置属性 """
		self._auth()
		return self

	def __exit__(self, *args):
		self._conn.end_request()

	def get_mulit_dict(self, dict_name, keys):
		""" 多key字典
		keys: key名称列表，如：['key1', 'key2']
		"""
		return _MongoMulitDict(self, getattr(self._setting, dict_name), keys)

	def get_dict(self, name, strict=False, **kwargs):
		""" 自定义创建collection,kwargs可以附带相关参数:
			- "size": desired initial size for the collection (in
				bytes). must be less than or equal to 10000000000. For
				capped collections this size is the max size of the
				collection.
			- "capped": if True, this is a capped collection
			- "max": maximum number of objects if capped (optional)
		"""
		#使用collection_names判断是否存在，还是用异常处理呢？
##		if name in self._db.collection_names():
##			item = Collection(self._db, name)
##		else:
##			item = Collection(self._db, name, **kwargs)
		try:
			item = Collection(self._db, name, **kwargs)
		except OperationFailure as e:
			if strict:
				raise
			if e.args and 'exists' in e.args[0]:
				pass
			else:
				log.log_except()
			item = Collection(self._db, name)

		return _MongoDict(self, item)


class MongoConference(object):
	def __init__(self, name='conference'):
		self._conn = None
		self._db = None
		self._name = name

	def connection(self, url):
		"""
		url:mongodb://jhy:123456@192.168.0.110/jhy
		"""
		assert self._conn is None, 'already had server'
		url = urlparse.urlparse(url)
		self._conn = pymongo.Connection(url.hostname, url.port)
		print '++++++++++++++++++++++++'
		print self._conn
		print dir(self._conn)
		dbname = url.path[1:]
		print dbname
		self._db = pymongo.database.Database(self._conn, dbname)
		print '======================='
		print self._db.collection_names()
		print self._db
		print dir(self._db)
		self._conference = pymongo.collection.Collection(self._db, self._name)
		print '-----------------------'
		print self._conference
		print dir(self._conference)
		d = {'a':1, 'c':{'e':8888}, 'd':'eeeee'}
		self._conference.save(d)
		dd = self._conference.find({'a':1})
		print type(dd)
		print dd.explain()
		print type(dd[0])
		print dd[0]
		if url.username:
			if not self._db.authenticate(url.username, url.password):
				raise Exception, 'authenticate fail!'

	def close(self):
		self._conn.disconnect()

	def end_request(self):
		self._conn.end_request()

_settings = {}
def get_setting(setting_url):
	if setting_url in _settings:
		return _settings[setting_url]

	setting = MongoSetting()
	setting.add_server(setting_url)
	_settings[setting_url] = setting
	return setting


def test_dict(setting, end_request=False):
	test1 = setting.test.test1
	test1['a'] = [1,2,3]
	test1['b'] = dict(a=1, b=2, c=3)

	test2 = setting.test.test1
	del test2['a']
	test2['c'] = [1,2,3]
	test2['d'] = test2.pop('c')
	for k,v in test2.iteritems():
		print '%s=%s' % (k, v)
	if end_request:
		setting.end_request()

def test_mulit_dict(setting):
	mdict = setting.test.get_mulit_dict('mdict', ['key1', 'key2'])
	#删除整个collection
	mdict.drop()
	#新增
	mdict[(1,1)] = 1
	mdict[(1,2)] = 2
	mdict[(2,1)] = 3
	mdict[(2,2)] = 4
	#遍历
	for key1, key2 in mdict:
		print key1, key2
	for (key1, key2), value in mdict.iteritems():
		print key1, key2, value
	for (key1, key2), value in mdict.iter_items_by_key(key1=1):
		print key1, key2, value
	#新增
	mdict[(2,1)] = 6
	mdict[(2,2)] = 7
	mdict[(2,3)] = 3
	mdict[(1,3)] = 3
	mdict[(1,4)] = 3
	#删除方法
	mdict.del_by_key(key2=3)
	del mdict[(1,4)]
	for item in mdict.iteritems():
		print item

def test_thread(setting):
	import gevent
	setting.test.test1.drop()
	setting.end_request()
	tasks = [gevent.spawn(test_dict, setting, b) for b in [True, False, True, False]]
	gevent.joinall(tasks)
	tasks = [gevent.spawn(test_dict, setting) for i in [1,2,3]]
	gevent.joinall(tasks)

def test_conference():
	conference = MongoConference()
	conference.connection('mongodb://jhy:123456@192.168.0.110/jhy')


def main():
	from gevent import monkey
	monkey.patch_all()
	mongo_pool.install()

	setting = MongoSetting()
	setting.add_server('mongodb://jhy:123456@192.168.0.110/jhy')
	try:
		test_mulit_dict(setting)
		test_dict(setting)
		test_thread(setting)
	finally:
		setting.close()
if __name__ == '__main__':
	main()
	#test_conference()




