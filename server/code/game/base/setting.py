#!/usr/bin/env python
# -*- coding:utf-8 -*-
from collections import OrderedDict

from corelib import message
from corelib.data import Trie
from game import Game
from game.store.define import TN_RES_SETTING
from game.base.msg_define import MSG_RES_RELOAD
from game.base import common
from game.base.constant import VIP_LV_BAGS, VIP_LV_BAGS_V
@message.observable
class SettingMgr(object):
    """ 游戏全局的一些属性设置(读表获得) """
    def __init__(self):
        self.settings = OrderedDict()

    def start(self):
        """ 将数据库里的所有k:v 保存到set_dict里 """
        Game.res_mgr.sub(MSG_RES_RELOAD, self.load)
        self.load()

    def load(self):
        #settings = Game.rpc_res_store.query_loads(TN_RES_SETTING, None)
        settings = Game.rpc_res_store.load_all(TN_RES_SETTING)
        for setting in settings:
            self.settings[setting['key']] = setting['value']
            if isinstance(setting['value'], (int, float)):
                continue
            try:
                if setting['value'].isdigit():
                    f = int(setting['value'])
                else:
                    f = float(setting['value'])
                    if setting['value'].endswith('.0'):
                        f = int(f)
                self.settings[setting['key']] = f
            except (ValueError, AttributeError):
                continue
        res_size = self.setdefault(VIP_LV_BAGS, VIP_LV_BAGS_V)
        self.fetch_size = common.make_lv_regions(res_size)
        self.safe_pub(MSG_RES_RELOAD)

    def save(self):
        """ 保存,非自动保存,可以手动 """
        settings = [dict(id=i, key=k, value=v) for i, (k,v) in enumerate(self.settings.iteritems())]
        Game.rpc_res_store.save(TN_RES_SETTING, settings)

    def setdefault(self, key, default):
        """ 获取key对应的全局属性值 """
        return self.settings.setdefault(key, default=default)

