#!/usr/bin/env python
# -*- coding:utf-8 -*-


#排序定义
ASCENDING = 1
DESCENDING = -1

#查询逻辑定义
OP_AND = '$and'
OP_OR = '$or'
OP_NOT = '$not'
OP_NOR = '$nor'

#字段操作定义
FOP_IN = '$in'
FOP_GT = '$gt'
FOP_LT = '$lt'
FOP_GTE = '$gte'
FOP_LTE = '$lte'
FOP_NE = '$ne'
FOP_NIN = '$nin'



DRIVERS = {}
_drivers = {}
MONGODB_ID = 'mongodb'

def get_driver(db_engine, **dbkw):
    global _drivers
    if db_engine in _drivers:
        return _drivers[db_engine]
    if db_engine.startswith("%s://" % MONGODB_ID):
        from . import mongodb #导入模块
        cls = DRIVERS[MONGODB_ID]
        store = cls()
        store.init(db_engine, **dbkw)
    else:
        raise ValueError, 'db_engine(%s) not found' % db_engine
    _drivers[db_engine] = store
    return store


class BaseDriver(object):
    engine_name = None
    def init_cls_infos(self, cls_infos):
        pass

    def get_key(self, tname):
        """ 获取key字段名 """
        pass

    def iter_keys(self, tname, querys, limit=None, sort_by=None):
        """ 根据查询条件，遍历获取key """
        pass

    def iter_values(self, tname, columns, querys, limit=None, sort_by=None):
        """ 根据名称列表，获取表的数据, 返回的是tuple """
        pass

    def count(self, tname, querys):
        """ 根据条件，获取结果数量 """
        pass

    def insert(self, tname, values):
        """ 新增,返回key """
        pass

    def save(self, tname, values):
        """ 保存,values必须包含key """
        pass

    def saves(self, tname, values_list):
        """ 保存,values必须包含key """
        pass

    def has(self, tname, key):
        pass

    def load(self, tname, key):
        pass

    def delete(self, tname, key):
        pass

    def clear(self, tname):
        """ 清除所有数据 """

    def update(self, tname, key, values):
        """ 更新部分数据 """

    ##    def updates(self, tname, values, querys):
    ##        """ 更新表数据,参数:
    ##            values: 是字典(列名=内容)
    ##            querys: 查询过滤参数
    ##        """
    ##        pass


    def execute(self, statement, params=None):
        """ 高级模式:根据不同后台执行sql或者js(mongodb) """
        pass


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
