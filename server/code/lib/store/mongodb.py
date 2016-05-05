#!/usr/bin/env python
# -*- coding:utf-8 -*-
import urlparse
import functools
import inspect

from bson.code import Code
import pymongo
from pymongo.collection import Collection
from pymongo.errors import ConnectionFailure

from corelib import log
from .driver import MONGODB_ID, DRIVERS
from .errors import ConnectionError

pymongo_ver = pymongo.version[0]

#类与表名关系 (tablename, key, indexs, autoInc)
##CLS_INFOS = {
##    #'Player': ('Player', 'uid', [('user_name', {}), ], False)
##}
TAB_IDX = 0
KEY_IDX = 1
AUTO_INC_IDX = 3
PARAMS_IDX = 4
AUTO_INC_TABLE = '_auto_inc_'

def init_indexs(store, info):
    """ 检查、创建索引 """
    table_name, key, indexs, autoInc = info[:PARAMS_IDX]
    table = store.get_table(table_name)
    for index in indexs:
        if isinstance(index, (tuple, list)):
            key_or_list, kwargs = index
        else:
            key_or_list, kwargs = index, {}
        table.ensure_index(key_or_list, **kwargs)
    #创建自增字段记录
    if autoInc:
        inc = store.get_table(AUTO_INC_TABLE)
        if inc.find_one({'name':table_name}) is None:
            inc.save({'name':table_name, 'id':0})


def auto_inc(store, table_name):
    """ 获取自增值 """
    inc = store.get_table(AUTO_INC_TABLE)
    v = inc.find_and_modify(query={'name':table_name}, update={'$inc':{'id':1}}, new=True)
    return int(v['id'])


class BaseProc:
    @classmethod
    def get_proc(cls, tname):
        return getattr(cls, tname) if hasattr(cls, tname) else cls.simple

class SaveProc(BaseProc):
    """ 保存(新增或者更新) """
    @staticmethod
    def simple(store, tname, values):
        """ 简单保存,保存序列化字典 """
        table_name, key_name = store.cls_infos[tname][:2]
        data = values.copy()
        _id = data.pop(key_name, None)
        if _id is None:
            if not store.cls_infos[tname][AUTO_INC_IDX]:
                raise KeyError
            _id = auto_inc(store, table_name)
            insert = 1
        else:
            insert = 0
        try:
            data['_id'] = _id
            table = store.get_table(table_name)
            if insert:
                rs = table.insert(data, w=1, manipulate=False, j=True)
                #log.debug('[****%s]%s, result=%s', tname, data, rs)
            else:
                #upsert:if the record(s) do not exist, insert one
                table.update({'_id':_id}, data, upsert=True, w=1)
            return _id
        finally:
            values[key_name] = data['_id']


class LoadProc(BaseProc):
    """ 加载 """
    @staticmethod
    def init_values(key_name, obj):
        if not obj:
            return obj
        obj[key_name] = obj.pop('_id')
        return obj

    @staticmethod
    def simple(store, tname, key):
        """ 简单加载,加载序列化字典 """
        table_name, key_name = store.cls_infos[tname][:2]
        table = store.get_table(table_name)
        obj = table.find_one(key)
        return LoadProc.init_values(key_name, obj)

    @staticmethod
    def iter_values(store, tname, columns, querys, limit=0, sort_by=None, skip=0):
        """ 根据名称列表，获取表的数据, 返回的是Cursor, [{}, {}, ...] """
        table_name, key_name = store.cls_infos[tname][:2]
        table = store.get_table(table_name)
        querys = store.tran_querys(tname, querys)
        init_values = LoadProc.init_values
        for values in table.find(spec=querys, fields=columns, limit=limit, sort=sort_by, skip=skip):
            yield init_values(key_name, values)

    @staticmethod
    def has(store, tname, key):
        """ 判断是否存在 """
        table_name, key_name = store.cls_infos[tname][:2]
        table = store.get_table(table_name)
        c = table.find({'_id':key}).count()
        return c



class DelProc(BaseProc):
    """ 删除 """
    @staticmethod
    def simple(store, tname, key):
        table_name, key_name = store.cls_infos[tname][:2]
        table = store.get_table(table_name)
        table.remove(key)

def wrap_exit(func):
    @functools.wraps(func)
    def _func(self, *args, **kw):
        self.__enter__()
        try:
            return func(self, *args, **kw)
        except ConnectionFailure as e:
            raise ConnectionError(str(e))
        except Exception as e:
            log.log_except('args(%s) kw(%s)', args, kw)
        finally:
            self.__exit__()
    _func.store = 1 #标示是数据库操作接口
    args = inspect.getargspec(func)
    if len(args.args) > 1 and args.args[1] == 'tname':
        _func.tname = 1
    return _func

class MongoDriver(object):
    engine_name = MONGODB_ID
    def __init__(self):
        if 0:
            from pymongo import database
            self._conn = pymongo.Connection()
            self._db = database.Database()
        self._conn = None
        self._db = None
        self.cls_infos = None
        self.url = None
        self.dbkw = None

    def init_cls_infos(self, cls_infos):
        if self.cls_infos == cls_infos:
            return True
        if self.cls_infos is not None:
            return False
        self.cls_infos = cls_infos
        with self:
            for k, info in self.cls_infos.iteritems():
                try:
                    init_indexs(self, info)
                except:
                    log.log_except('info:%s', info)
                    raise
        return True

    def init(self, url, **dbkw):
        """
         url: mongodb://jhy:123456@192.168.0.110/jhy
        """
        assert self._conn is None, 'already had server'
        self.url = url
        self.dbkw = dbkw
        self.timeout = dbkw.get('timeout', None)
        urler = urlparse.urlparse(url)
        try:
            self._conn = pymongo.Connection(url,
                network_timeout=self.timeout, use_greenlets=True)
            dbname = urler.path[1:]
            self._db = getattr(self._conn, dbname)
            if urler.username:
                self.username = urler.username
                self.pwd = urler.password
        except pymongo.errors.AutoReconnect:
            log.error(u'连接mongoDB(%s:%s)失败', urler.hostname, urler.port)
            raise

    def __enter__(self):
        """  """
        return self

    def __exit__(self, *args):
        self._conn.end_request()


    def initdb(self, tables):
        """ 清除数据库 """
        tables = set(tables)
        with self:
            for tname in tables:
                table = self.get_table(self.cls_infos[tname][TAB_IDX])
                table.drop()



    @classmethod
    def register(cls):
        """ 注册到store中 """
        DRIVERS[MONGODB_ID] = cls

    def get_table(self, item):
        """ 返回pymongo.Collection对象 """
        return getattr(self._db, item)

    def get_key(self, tname):
        """ 获取key字段名 """
        return self.cls_infos[tname][KEY_IDX]

    def tran_querys(self, tname, querys):
        if not querys:
            return
        key = self.get_key(tname)
        if key in querys:
            querys['_id'] = querys.pop(key)
        return querys

    def iter_values(self, tname, columns, querys, limit=0, sort_by=None, skip=0):
        """ 根据名称列表，获取表的数据, 返回的是Cursor, [{}, {}, ...] """
        return LoadProc.iter_values(self, tname, columns, querys, limit=limit, sort_by=sort_by, skip=skip)

    def iter_keys(self, tname, querys, limit=0, sort_by=None, skip=0):
        """
          - `sort` (optional): a list of (key, direction) pairs
            specifying the sort order for this query. See
            :meth:`~pymongo.cursor.Cursor.sort` for details.
        """
        key = self.get_key(tname)
        for v in LoadProc.iter_values(self, tname, [], querys, limit=limit, sort_by=sort_by, skip=skip):
            yield v[key]

    @wrap_exit
    def save(self, tname, values):
        func = SaveProc.get_proc(tname)
        return func(self, tname, values)

    insert = save

    @wrap_exit
    def saves(self, tname, values_list):
        """ 保存,values必须包含key """
        func = SaveProc.get_proc(tname)
        for values in values_list:
            func(self, tname, values)

    @wrap_exit
    def has(self, tname, key):
        return LoadProc.has(self, tname, key)

    @wrap_exit
    def load(self, tname, key):
        func = LoadProc.get_proc(tname)
        return func(self, tname, key)


##    @wrap_exit
##    def loads(self, tname, querys):
##        return list(self.iter_loads(tname, querys))
##
##    def iter_loads(self, tname, querys):
##        func = LoadProc.get_proc(tname)
##        for _id in self.iter_keys(tname, querys):
##            yield func(self, tname, _id)

    @wrap_exit
    def delete(self, tname, key):
        if key is None:#防止清除所有数据
            return
        func = DelProc.get_proc(tname)
        return func(self, tname, key)

    @wrap_exit
    def clear(self, tname):
        """ 清除所有数据 """
        table = self.get_table(self.cls_infos[tname][TAB_IDX])
        table.remove()


##    @wrap_exit
##    def deletes(self, tname, querys):
##        """ 根据条件，删除一批数据 """
##        func = DelProc.get_proc(tname)
##        for _id in self.iter_keys(tname, querys):
##            func(self, tname, _id)

    @wrap_exit
    def update(self, tname, key, values):
        """ 更新部分数据 """
        if key is None:
            raise ValueError('update error:(%s, %s, %s)' % (tname, key, values))
        table = self.get_table(self.cls_infos[tname][TAB_IDX])
        table.update({"_id": key}, {"$set": values})


##    @wrap_exit
##    def updates(self, tname, values, querys):
##        """ 更新表数据,参数:
##            values: 是字典(列名=内容)
##            querys: 查询过滤参数
##        """
##        table = self.get_table(self.cls_infos[tname][TAB_IDX])
##        table.update(querys, values, multi=True)

    @wrap_exit
    def count(self, tname, querys):
        """ 根据条件，获取结果数量 """
        querys = self.tran_querys(tname, querys)
        table = self.get_table(self.cls_infos[tname][TAB_IDX])
        return table.find(spec=querys).count()

    @wrap_exit
    def execute(self, statement, params=None):
        return self._db.eval(statement, *params)

    @wrap_exit
    def map_reduce(self, tname, map, reduce, out=None, inline=1, full_response=False, **kwargs):
        table = self.get_table(self.cls_infos[tname][TAB_IDX])
        if inline:
            return table.inline_map_reduce(map, reduce, full_response=full_response, **kwargs)
        assert out is not None, ValueError('out mush not None if not inline')
        return table.map_reduce(map, reduce, out, full_response=full_response, **kwargs)

##    def join_left(self, cls1, cls2, cls1_query='1', relation=('_id', '_id')):
##        """ 实现sql的left join语法功能 """
##        d1 = {}
##        d1['cls2_name'] = cls2._mdb_table_
##        d1['cls1_query'] = cls1_query
##        d1['cls1_rel_name'] = relation[0]
##        d1['cls2_rel_name'] = relation[1]
##        sum_map = u"""
##function (){
##    cls1_query = %(cls1_query)s;
##    tb = db.getCollection('%(cls2_name)s');
##    f = tb.find({'%(cls2_rel_name)s':this.%(cls1_rel_name)s});
##    if (cls1_query && f.count() != 0) {
##        r = f.next();
##        emit(this._id, {'value':this.value, 'chl_name':r.value.chl_name});
##    } else {
##        emit('', '');
##    }
##}
##        """ % d1
##        sum_reduce = """
##function (key, emits){
##    return emits[0];
##}
##        """
##        table = getattr(self, cls1._mdb_table_)
##        r = table.inline_map_reduce(sum_map, sum_reduce)
##        rs = dict((d['_id'], d['value']) for d in r)
##        rs.pop('', None)
##        return rs

MongoDriver.register()

copy_collection = u"""
function (){
    db.getCollection('%s').find().forEach(function (x){db.getCollection('%s').insert(x)});
}
"""

sum_map = Code(
u"""
function (){
    b = this.value.damage != null
    tb = db.getCollection('setting.logon.telcom-广东区-八月十五.players')
    f = tb.find({'_id':this._id})
    if (b && f.count() != 0) {
        r = f.next();
        emit(this._id, {'value':this.value, 'chl_name':r.value.chl_name});
    } else {
        emit('', '');
    }
}
""".encode('utf-8'))
##    r = db.getCollection('setting.logon.telcom-广东区-八月十五.players').find({'_id':this._id});

sum_reduce = Code(
u"""
function (key, emits){
    return emits[0];
}
""".encode('utf-8'))
##    r = db.getCollection('setting.logon.telcom-广东区-八月十五.players').find({'_id':key});
##    rs = emits[0];
##    return {'chl_name':r.value.chl_name, 'value':rs.value};



def test_join():
    con = pymongo.Connection('mongodb://dev.zl.efun.com/test')
    db = getattr(con, 'jhy_new')

    cl = Collection(db, u'setting.logon.telcom-广东区-八月十五.players')
    print cl.count()

    cl = Collection(db, u'setting.logon.telcom-广东区-八月十五.temp_world_boss')
    r= cl.inline_map_reduce(sum_map, sum_reduce, limit=10)
    print len(r)
    print r


if __name__ == '__main__':
    test_join()

