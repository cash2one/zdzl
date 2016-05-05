#!/usr/bin/env python
# -*- coding:utf-8 -*-
import sys
import web
import psutil

from corelib import json, log, json_dumps
from game import Game, aes_encrypt

import config
web.config['debug'] = False #disable autoreload
app = web.auto_application()

game_url = '/api/game'

AES = 1

def encode_json(data):
    """ 加密数据 """
    data = json_dumps(data)
    if not AES:
        return data
    return aes_encrypt(str(data))

def _wrap_except(func):
    def _func(*args, **kw):
        try:
            return func(*args, **kw)
        except:
            log.log_except()
        return ''
    return _func

class UserPlayers(app.page):
    """ 获取玩家列表
    http://172.16.40.2:8008/api/game/userPlayers?sns=1&sid=399367642
    http://172.16.40.13:8080/api/game/userPlayers?sns=1&sid=399367642&sids=10|1
    http://172.16.40.2:8008/api/game/userPlayers?sns=1&sid=399367642&sids=10|1
    """
    path = '%s/%s' % (game_url, 'userPlayers')

    @_wrap_except
    def GET(self):
        data = web.input(_method='GET')
        sns, sid = int(data.get('sns', 0)), data.get('sid')
        if not (sns and sid):
            return ''
        players = Game.rpc_client.user_players(sns, sid)
        return encode_json(players)
# 游戏监控(json):
# 1、游戏服状态监控(cpu_scene, cpu_glog, cpu_activity,
#    cpu_union, cpu_store=store进程cpu使用量;
# max_logics=最大逻辑进程数; logics=逻辑进程数; user=当前在线用户数; max_user=允许最大用户数);


class ServerStats(app.page):
    """ 服务器运行信息
    """
    path = '%s/%s' % (game_url, 'serverstats')
    prefix = 'cpu_'

    @_wrap_except
    def GET(self):
        mainapp = sys.modules['app']
        subgame_mgr = mainapp.sub_mgr
        unions_mgr = subgame_mgr.union_mgr
        unions = unions_mgr.unions
        ret_val = {}
        for items in unions.values():
            pid = items[0]
            name = items[1]
            p = psutil.Process(int(pid))
            if p:
                perc = p.get_cpu_percent()
                key = self.prefix + name
                ret_val.update({key: perc})

        logics = len(subgame_mgr.logic_mgr.logics)
        max_logics = config.max_subgame
        user = Game.rpc_player_mgr.get_count()
        max_user = config.max_players
        ret_val.update({'logics': logics, 'max_logics': max_logics,
                        'user': user, 'max_user': max_user})

        return json.dumps(ret_val)

inited = 0
def init_app():
    global inited
    if inited:
        return
    inited = 1
    #游戏功能子进程,自己初始化sns
    Game.init_snss()
    from webapi import snss, SNS_UC
    #uc接口
    if SNS_UC in snss:
        uc = snss[SNS_UC]
        uc.cb_init(app, game_url, callback=0)
    log.info('app mapping:\n%s', '\n'.join(map(str, app.mapping)))


def get_wsgi_app(*middleware):
    init_app()
    return app.wsgifunc(*middleware)
