#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time
import os

from hashlib import md5

from corelib.common import strftime
from corelib.threadPool import GlobalThreadPool
from corelib.memory_cache import TimeMemCache
from corelib import log
from store.store import StoreObj, GameObj

from game import Game, grpc_monitor
from game.store import TN_F_REPORT
from game.base.constant import REPORT_TYPE_TBOX

#战报信息
REPORT_ID = 'id'
REPORT_TYPE = 'type'
REPORT_URL = 'url'
REPORT_PIDS = 'pids'
REPORT_CT = 'ct'

class ReportMgr(object):
    """ 战报处理类 """
    _rpc_name_ = 'rpc_report_mgr'
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        self.cache = TimeMemCache(default_timeout=10, name='report_mgr.cache')
        self.thread_pool = GlobalThreadPool(max_pool_size=5)
        self.report_base_dir = None
        self.report_base_url = None

    def init(self, url, dir):
        self.report_base_dir = dir
        self.report_base_url = url
        if not os.path.exists(self.report_base_dir):
            log.info('mkdir report_base_dir:%s', self.report_base_dir)
            os.makedirs(self.report_base_dir)

    def get_cur_path(self):
        return strftime(fmt='%Y%m')

    @grpc_monitor
    def save(self, type, pids, news, url=None):
        """ 写战报:
        pids: 相关玩家id列表
        news:战报数据
        url:可以指定url, 路径列表如['tbox', 'file_name']
        返回: 战报id
        """
        if url is None:
            url = (self.get_cur_path(), md5(news).hexdigest())
        #目录
        path = os.path.join(self.report_base_dir, *url[:-1])
        if not os.path.exists(path):
            os.makedirs(path)
        file_path = os.path.join(path, url[-1])
        self.thread_pool.addTask(self._save_data, (file_path, news))
        #处理url
        return self._save_message(type, '/'.join(url), pids)

    def _save_data(self, url, news):
        """ 保存战报 """
        #保存数据
        with open(url, 'w') as file:
                file.writelines(news)

    def _save_message(self, type, url, pids):
        """ 保存战报信息 """
        #保存战报信息
        message = {}
        message[REPORT_TYPE] = type
        message[REPORT_URL] = url
        message[REPORT_PIDS] = pids
        message[REPORT_CT] = int(time.time())
        id = Game.rpc_store.insert(TN_F_REPORT, message)
        self.cache.set(id, (id, message))
        return id

    @grpc_monitor
    def get_url(self, id):
        """ 获取战报绝对地址url """
        #获取战报信息
        _id, v = self.cache.get(id, (None, None))
        if v is None:
            #从数据库读取数据
            querys = dict(id=id)
            values = Game.rpc_store.query_loads(TN_F_REPORT, querys)
            if not values:
                return False, None
            v = values[0]
            self.cache.set(id, (id, v))
        url = '%s/%s' % (self.report_base_url, v[REPORT_URL])
        return True, url

class ReportData(StoreObj):
    __slots__ = ('id', 'type', 'url', 'pids', 'ct')
    def init(self):
        self.id = None
        self.type = 0
        self.url = ''
        self.pids = ''
        self.ct = 0

class Report(GameObj):
    __slots__ = GameObj.__slots__
    TABLE_NAME = TN_F_REPORT
    DATA_CLS = ReportData
    def __init__(self, adict=None):
        super(Report, self).__init__(adict=adict)


def new_report_mgr():
    import config
    mgr = ReportMgr()
    mgr.init(config.fight_report_base_url, config.fight_report_base_dir)
    return mgr

