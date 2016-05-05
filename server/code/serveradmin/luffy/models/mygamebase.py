#coding=utf-8
import pymongo
import time
from flask import current_app, g

DEFAULT_HOST = '127.0.0.1'
DEFAULT_PORT = 27017

class MongoFive(object):
    def __init__(self, db, collection, host=DEFAULT_HOST, port=DEFAULT_PORT):
        self.conn = g.conns
        self.db = self.conn[db]
        self.collection = collection

    def filter(self, dic,show=None, sort=None, sort_by=1):
        try:
            if sort is None:
                sort = '_id'
            if show is None:
                ret = self.db[self.collection].find(dic).sort(sort, sort_by)
            else:
                ret = self.db[self.collection].find(dic,show).sort(sort, sort_by)
            return [r for r in ret]
        except:
            return None

    def count(self, dic=None):
        if dic:
            return self.db[self.collection].find(dic).count()
        else:
            return self.db[self.collection].count()

    def distinct(self,key):
        return self.db[self.collection].distinct(key)

    def all(self, isShow=None):
        if isShow:
            ret = self.db[self.collection].find({},isShow).sort('_id')
        else:
            ret = self.db[self.collection].find().sort('_id')
        return [r for r in ret]

    def first(self, dic={},show=None):
        if show:
            return self.db[self.collection].find_one(dic,show)
        else:
            return self.db[self.collection].find_one(dic)

    def last(self, dic=None):
        if dic:
            ret = self.db[self.collection].find(dic).sort('_id', pymongo.DESCENDING).limit(1)
        else:
            ret = self.db[self.collection].find().sort('_id', pymongo.DESCENDING).limit(1)
        ret = [r for r in ret]
        if ret == []:return None
        else:return ret[0]

    def insert(self, args, inc=True):
        if inc:
            if self.db['_auto_inc_'].find_one({'name':self.collection}) is None:
                self.db['_auto_inc_'].insert({'name':self.collection, 'id':0})
            inc = self.db['_auto_inc_'].find_and_modify(query={'name':self.collection}, update={'$inc':{'id':1}}, new=True)
            args['_id'] = inc['id']
        id = self.db[self.collection].insert(args)
        action = 'insert'
#        self.log(action=action)
        return id

    def update(self, args,upsert=True):
        self.db[self.collection].update(args['condition'], args['data'],upsert=upsert)
        action = 'update condition: %s' % args['condition']
#        self.log(action=action)

    def delete(self,id):
        self.db[self.collection].remove({'_id':id})
        action = 'delete id: %s' %  id
#        self.log(action=action)

    def remove(self, dic):
        self.db[self.collection].remove(dic)

    def paginate(self, page=1, per_page=100, dic=None, sort='_id'):
        self.per_page = per_page
        if dic is None:
            ret = self.db[self.collection].find().limit(per_page).skip((page-1)*per_page).sort(sort, pymongo.DESCENDING)
        else:
            ret = self.db[self.collection].find(dic).limit(per_page).skip((page-1)*per_page).sort(sort, pymongo.DESCENDING)
        return [r for r in ret]

    def get_by_id(self, id):
        return self.db[self.collection].find_one({'_id':id})

    def page_count(self, dic={}):
        if self.per_page: per_page = self.per_page
        else:per_page = 100
        count = self.db[self.collection].find(dic).count()
        if count%per_page==0:
            return count/per_page
        else:
            return count/per_page + 1

    def find(self, condition, show=None):
        if show:
            return [r for r in self.db[self.collection].find(condition,show).sort('_id',pymongo.ASCENDING)]
        else:
            return [r for r in self.db[self.collection].find(condition).sort('_id',pymongo.ASCENDING)]

    def find_one(self, condition):
        return self.db[self.collection].find_one(condition)

    def drop(self):
        self.db[self.collection].drop()
        action = 'drop'
#        self.log(action=action)

    def log(self, action):
        logdb = self.conn['efun']
        ret = { 'action':action, 'collection':self.collection, 'addtime':time.time()}
        logdb['log'].insert(ret)

    def group(self, key, condition, initial, reduce, finalize=None):
        return self.db[self.collection].group(key, condition, initial, reduce, finalize=None)

    def distince(self, key):
        return self.db[self.collection].distinct(key)

    def distince_filter(self, key, querys):
        return self.db[self.collection].find(querys).distinct(key)

    def reset(self, key, id, val=0):
        self.db[self.collection].update({'_id':id}, {'$set':{key, val}})

    def inline_map_reduce(self, map_f, reduce_f, full_response=False, **kwargs):
        return self.db[self.collection].inline_map_reduce(map_f, reduce_f, full_response=full_response, **kwargs)


class MongoDrive(object):
    def __init__(self):
        self.conn = None
        self.db = None
        self.table = None

    def db_table(self, db, table):
        self.db = db
        self.table = table

    def connect(self, host, ip):
        """ 连接数据库 """
        self.conn = pymongo.Connection(host=host, port=ip)
        return self

    def update(self, db, table, querys, inserts, upsert=True, _set=True):
        """ 更新数据库 """
        if _set:
            inserts = {'$set':inserts}
        self.conn[db][table].update(querys, inserts, upsert=upsert)

    def remove(self, db, table, querys):
        """ 移除某条纪录 """
        self.conn[db][table].remove(querys)

    def find_one(self, db, table, querys):
        """ 查询一条纪录 """
        return self.conn[db][table].find_one(querys)

    # def filter(self, db, table, querys):
    #     return self.conn[db][table].filter(querys)

    def distinct(self, db, table, key, querys=None):
        return self.conn[db][table].find(querys).distinct(key)

    # def find(self, db, table, querys=None, show=None):
    def all(self, db, table, querys=None, sort='_id'):
        """ 查询所有纪录 """
        return self.conn[db][table].find(querys).sort(sort, pymongo.ASCENDING)

    def first(self, db, table, querys=None, sort='_id',sortby=pymongo.ASCENDING,
                limit=1):
        return self.last(db, table, querys, sort, sortby, limit)

    def last(self, db, table, querys=None, sort='_id', sortby=pymongo.DESCENDING,
                limit=1):
        """ 获取最后一条纪录 """
        ret = self.conn[db][table].find(querys).sort(sort, sortby).limit(limit)
        ret = [r for r in ret]
        if ret == []:
            return None
        if limit == 1:
            return ret[0]
        return ret

    def paginate(self, db, table, page=1, per_page=100, querys=None, sort='_id'):
        ret = self.conn[db][table].find(querys).limit(per_page).skip((page-1)*per_page).sort(sort, pymongo.DESCENDING)
        return [r for r in ret]

    def drop(self, db, table):
        self.conn[db][table].drop()

    def filter(self, db, table, querys=None, show=None, sort=None, sort_by=1):
        try:
            if sort is None:
                sort = '_id'
            if show is None:
                ret = self.conn[db][table].find(querys).sort(sort, sort_by)
            else:
                ret = self.conn[db][table].find(querys,show).sort(sort, sort_by)
            return [r for r in ret]
        except:
            return None
