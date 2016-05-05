#!/usr/bin/env python
# -*- coding:utf-8 -*-

from corelib import memory_cache
from store.store import GameObj, StoreObj, CacheStore
from game import Game, monitor_store

from .define import *

class BaseGameStore(CacheStore):
    def init(self, url, **dbkw):
        rs = super(BaseGameStore, self).init(url, **dbkw)
        #监控接口
        monitor_store(self.store)
        return rs


class GameStore(BaseGameStore):
    _rpc_name_ = 'rpc_store'
    STORE_INFOS = GAME_CLS_INFOS
    CACHE_SIZE = 500000
    CACHE_TIMEOUT = 10 * 60
    CACHE_TNAMES = {TN_PLAYER, TN_P_ROLE, TN_P_EQUIP,
            TN_P_FATE, TN_P_ITEM, TN_P_CAR, TN_P_TASK,
            TN_P_ATTR, TN_P_POSITION, TN_P_MAP, TN_P_MAIL,
            }
    INITDBS = {
            TN_P_TBOXNEWS,
            TN_STATUS,
            TN_F_REPORT,
            TN_USER,
            TN_PLAYER,
            TN_P_ROLE,
            TN_P_EQUIP,
            TN_P_ITEM,
            TN_P_FATE,
            TN_P_CAR,
            TN_P_TASK,
            TN_P_WAIT,
            TN_P_ATTR,
            TN_P_POSITION,
            TN_P_MAP,
            TN_P_MAIL,
            TN_P_BUFF,
            TN_P_TBOX,
            TN_P_DEEP,
            TN_SOCIAL,
            TN_ALLY,
            TN_P_ALLY,
            TN_ALLY_LOG,
            TN_SHOP,
            TN_ARENA_RANK,
            TN_ARENA_RANKS,
            TN_P_ARENA,
            TN_BOSS,
#            TN_ACTIVITY_LEVEL_GIFTS,
            TN_P_ACHI,
            }
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        super(GameStore, self).__init__()

    def init_cache(self):
        """ 覆盖缓存初始化 """
        self.cache = memory_cache.TimeMemCache(size=self.CACHE_SIZE,
                default_timeout=self.CACHE_TIMEOUT, name='rpc_store.cache')


class ResStore(BaseGameStore):
    _rpc_name_ = 'rpc_res_store'
    STORE_INFOS = RES_CLS_INFOS
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        BaseGameStore.__init__(self)

    def get_config(self, key, default=None):
        value = self.query_loads(
            TN_GCONFIG, dict(key=key))
        if value:
            return value[0]['value']
        return default

    def get_db_ver(self):
        return self.get_config(GF_dbVer)

class PayStore(BaseGameStore):
    _rpc_name_ = 'rpc_pay_store'
    STORE_INFOS = RES_CLS_INFOS
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        BaseGameStore.__init__(self)

    def get_config(self, key, default=None):
        value = self.query_loads(
            TN_GCONFIG, dict(key=key))
        if value:
            return value[0]['value']
        return default

    def get_db_ver(self):
        return self.get_config(GF_dbVer)

##	def save(self, *args, **kw):
##		print('PayStore.save')
##		return BaseGameStore.save(self, *args, **kw)

def new_game_store():
    import config
    store = GameStore()
    store.init(config.db_engine, **config.db_params)
    store.start()
    res_store = ResStore()
    res_store.init(config.db_engine_res, **config.db_params_res)
    res_store.start()
    pay_store = PayStore()
    if getattr(config, 'db_engine_pay', None) is not None:
        pay_store.init(config.db_engine_pay, **config.db_params_pay)
    else:
        pay_store.init(config.db_engine_res, **config.db_params_res)
    pay_store.start()
    return store, res_store, pay_store

def get_sns_params(get_config):
    from webapi import (
        SNS_91, SNS_DPAY, SNS_EFUN, SNS_PP,
        SNS_APP, SNS_APPTW, SNS_IDS, SNS_UC,
        SNS_DCN, SNS_TONGBU, SNS_IDSC
    )
    from .define import (
        GF_SDK91_URLS, GF_SDK91_APP_ID, GF_SDK91_APP_KEY,
        GF_DPAY_APP_ID, GF_DPAY_APP_KEY, GF_DPAY_URLS,
        GF_PP_KEY, GF_PP_URLS, GF_PP_RSA_KEY, GF_IDS_URLS,
        GF_APP_URLS, GF_UC_URLS, GF_DCN_URLS, GF_TB_URLS, GF_IDSC_URLS,
        )
    def _get_values(*args):
        rs = []
        for arg in args:
            rs.append(get_config(arg))
        if not rs[0]:
            return None
        return tuple(rs)

    params = {}
    #sdk91
    params[SNS_91] = _get_values(GF_SDK91_APP_ID,
            GF_SDK91_APP_KEY,
            GF_SDK91_URLS)
    #dpay
    params[SNS_DPAY] = _get_values(GF_DPAY_APP_ID,
            GF_DPAY_APP_KEY,
            GF_DPAY_URLS)
    #pp
    params[SNS_PP] = _get_values(GF_PP_URLS, GF_PP_RSA_KEY, GF_PP_KEY)

    #efun
    params[SNS_EFUN] = None
    #app
    params[SNS_APP] = _get_values(GF_APP_URLS)
    params[SNS_APPTW] = params[SNS_APP]
    #ids 云顶
    params[SNS_IDS] = _get_values(GF_IDS_URLS)
    #idsc 云顶破解
    params[SNS_IDSC] = _get_values(GF_IDSC_URLS)

    #uc
    params[SNS_UC] = _get_values(GF_UC_URLS)
    #dcn 当乐
    params[SNS_DCN] = _get_values(GF_DCN_URLS)

    #同步
    params[SNS_TONGBU] = _get_values(GF_TB_URLS)

    return params




#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
