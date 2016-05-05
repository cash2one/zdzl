#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os
from os.path import join, exists
import time

from game import Game, grpc_monitor

from . import common

class LoggerServer(object):
    """ 游戏记录类 """
    _rpc_name_ = 'rpc_logger_svr'
    def __init__(self):
        if 0:
            from store.mongodb import MongoDriver
            self.driver = MongoDriver()

        from game import Game
        setattr(Game, self._rpc_name_, self)


    def init(self, url, **dbkw):
        from store.driver import get_driver
        self.driver = get_driver(url, **dbkw)
        self.driver.init_cls_infos(common.LOG_CLS_INFOS[self.driver.engine_name])
        self._init_logger()

    def _init_logger(self):
        #logger
        from logging import handlers, Formatter
        from corelib import log
        import config
        log_path = join(config.log_path, 'glog')
        if not exists(log_path):
            os.makedirs(log_path)
        shortformat = '[%(asctime)s]-%(message)s'
        shortdatefmt = '%m-%d %H:%M:%S'
        self.logger = log.getLogger('logger_svr')
        hd = handlers.RotatingFileHandler(join(log_path, 'game.log'), maxBytes=1024*1024*10, backupCount=50)
        fmt = Formatter(shortformat, shortdatefmt)
        hd.setFormatter(fmt)
        self.logger.addHandler(hd)
        self.logger.propagate = 0

    def initdb(self):
        tables = common.LOG_MONGO_CLS_INFOS.keys()
        self.driver.initdb(tables)

    def insert(self, tname, d):
        d['ct'] = int(time.time())
        self.logger.info('%s:%s', tname, d)
        self.driver.insert(tname, d)

    @grpc_monitor
    def log(self, kw, _no_result=True):
        """ 玩家信息:玩家id, 类型, 描述, 子类型,  """
        self.insert(common.TN_INFO, kw)

    @grpc_monitor
    def item(self, kw, _no_result=True):
        """ 物品购买、消耗、其它获得、其它失去 """
        self.insert(common.TN_ITEM, kw)

    @grpc_monitor
    def log_gm(self, kw, _no_result=True):
        """ gm执行命令 """
        self.insert(common.TN_GM, kw)

    @grpc_monitor
    def log_equip(self, kw, _no_result=True):
        """ 装备强化升级、等级转移 """
        self.insert(common.TN_EQUIP, kw)

    @grpc_monitor
    def log_rpc(self, kw, _no_result=True):
        """ 记录游戏接口信息 """
        self.insert(common.TN_RPC, kw)

    @grpc_monitor
    def log_online(self, kw, _no_result=True):
        """ 记录游戏接口信息 """
        self.insert(common.TN_ONLINE, kw)

    @grpc_monitor
    def log_coin(self, kw, _no_result=True):
        """ 虚拟币的记录(包括消耗和添加) """
        self.insert(common.TN_COIN, kw)

    @grpc_monitor
    def log_rank(self, kw, _no_result=True):
        """ 凌晨保存排行榜数据 """
        self.insert(common.TN_RANK, kw)

def new_game_logger():
    import config
    logger = LoggerServer()
    logger.init(config.db_engine_log, **config.db_params_log)
    return logger

def wrap_noresult(func):
    def _func(self, kw):
        rpc_func = getattr(Game.rpc_logger_svr, func.func_name)
        return rpc_func(kw, _no_result=True)
    return _func

class GameLogger(object):
    def __init__(self):
        pass

    @wrap_noresult
    def log(self, kw):
        """ 玩家信息:玩家id, 类型, 子类型,  """

    @wrap_noresult
    def item(self, kw):
        """ 物品购买、消耗、其它获得、其它失去 """

    @wrap_noresult
    def log_gm(self, kw):
        """ gm执行命令 """

    @wrap_noresult
    def log_equip(self, kw):
        """ 装备强化升级、等级转移 """

    @wrap_noresult
    def log_rpc(self, kw):
        """ 记录游戏接口信息 """

    @wrap_noresult
    def log_online(self, kw):
        """ 记录游戏在线信息 """

    @wrap_noresult
    def log_coin(self, kw):
        """ 花费记录 """

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
