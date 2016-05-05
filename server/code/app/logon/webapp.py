#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os
import web
import psutil

from corelib import log, json

import config as web_config
from model import game_servers

def init():
    """ web.py 设定 - 开始 """
    global app, render, template_render, api_url, snss
    global aes_encrypt

    from model import logon_store
    from game.store.define import (GF_webUrl,
            GF_SDK91_APP_ID, GF_SDK91_APP_KEY, GF_SDK91_URLS,
            GF_DPAY_APP_ID, GF_DPAY_APP_KEY, GF_DPAY_URLS,
            GF_CLIENTRPC_AESKEY)

    web.config['debug'] = web_config.auto_reload
    app = web.auto_application()
    web.config.session_parameters['timeout'] = 60 * 10 #缓存有效时间
    use_cache = web_config.use_cache
    loc = web_config.templates_path
    log.info('templates_path:%s', loc)
    base_layout = 'backstage/layout'
    session_initializer = {
        "login" : 0,
        "name" : None
    }
    globals_dict = {
        'hasattr' : hasattr,
    }
    render = web.template.Render(cache=use_cache, loc=loc)
    template_render = web.template.Render(cache=use_cache, loc=loc,
                                     base=base_layout, globals=globals_dict)
    log.debug(u'web参数:templates_path=%s, static_path=%s', loc, web_config.static_path)

    api_url = logon_store.get_config(GF_webUrl)

    #初始化sns模块
    from game import Game
    snss = Game.init_snss(get_config=logon_store.get_config,
            web_app=app, api_url=api_url,
            res_store=logon_store)


    from corelib.aes import new_aes_encrypt
    key = logon_store.get_config(GF_CLIENTRPC_AESKEY)
    aes_encrypt = new_aes_encrypt(key)

init()

def get_wsgi_app(*middleware):
    return app.wsgifunc(*middleware)


game_url = '%s/game' % api_url

AES = 1
def encode_json(data):
    """ 加密数据 """
    data = json.dumps(data, separators=(',', ':'))
    if not AES:
        return data
    return aes_encrypt(data)

class UserPlayers(app.page):
    """ 获取玩家列表
    http://172.16.40.2:8008/api/game/userPlayers?sns=1&sid=399367642
    http://172.16.40.13:8080/api/game/userPlayers?sns=1&sid=399367642&sids=10|1
    http://172.16.40.2:8008/api/game/userPlayers?sns=1&sid=399367642&sids=10|1
    """
    path = '%s/%s' % (game_url, 'userPlayers')
    def GET(self):
        data = web.input(_method='GET')
        sns, sid = int(data['sns']), data['sid']
        sids = data.get('sids')
        if sids:
            sids = map(int, sids.split('|'))
        if not (sids and sns and sid):
            return ''

        players = game_servers.get_players(sns, sid, sids=sids)
        return encode_json(players)


class CpuInfo(app.page):
    """ 获取里程cpu信息
    # 2、登陆进程状态监控(cpu=进程cpu使用量; )
    """
    path = '%s/%s' % (game_url, 'serverstats')

    def GET(self):
        p = psutil.Process(os.getpid())
        # blocking
        cpu = p.get_cpu_percent()
        return json.dumps({'cpu': cpu})

#---------------------
#---------------------
#---------------------
