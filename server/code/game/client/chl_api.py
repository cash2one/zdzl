#!/usr/bin/env python
# -*- coding:utf-8 -*-
import functools
import inspect

from grpc import wrap_pickle_result
from game import Game
from corelib import log, common, sleep
from game.player.player import Player, UserData

class ChannelApi(object):
    """ 管理服务,支持动态加载 """
    def __init__(self):
        """ 这个初始化方法失效 """
        raise NotImplemented

    def user_players(self, sns, sid):
        rs = UserData.user_players(sns, sid)
        #log.debug('user_players:%s', rs)
        return rs

    def get_onlines(self, start, end, name=1):
        """ 获取在线玩家列表 """
        rs = Game.rpc_player_mgr.get_onlines(start, end, name=name)
        return rs

    def get_count(self):
        """ 获取在线总人数 """
        return Game.rpc_player_mgr.get_count()

    def get_rpc_game(self, pid):
        """ 获取在线玩家所在的game进程对象 """
        return Game.rpc_player_mgr.get_sub_game(pid)

    def get_rpc_player(self, pid):
        return Game.rpc_player_mgr.get_rpc_player(pid)

    def get_rpc_player_info(self, pids, cols):
        return Game.rpc_player_mgr.get_player_detail(pids, cols)

    def get_rpc_user_by_name(self, name, *argv, **kw):
        return Game.rpc_player_mgr.get_user_detail_by_playername(name, *argv, **kw)

    def update(self, tbname, key, values):
        return Game.rpc_store.update(tbname, key, values)

    def gm(self, pid, cmd, strict=0):
        game = self.get_rpc_game(pid)
        if not game and strict:
            return '获取角色失败'
        if not game:
            #随便返回一个
            func = Game.iter_games()
            game = func.next()
        return game.execute(cmd)

    def del_player(self, pid):
        """ 删除玩家,断开uid关联 """
        return self.gm(pid, "del_player(%d)" % pid)


    def forbid_chat(self, pid, times):
        """ 禁言到某某时间 """
        return self.gm(pid, 'forbid_chat(%d, %d)' % (pid, times))

    def unforbid_chat(self, pid):
        """ 取消禁言 """
        return self.gm(pid, 'unforbid_chat(%d)' % (pid, ))

    def forbid_login(self, pid, times):
        return self.gm(pid, 'forbid_login(%d, %d)' % (pid, times))

    def unforbid_login(self, pid):
        return self.gm(pid, 'unforbid_login(%d)' % (pid, ))

    def scene_enter(self, pid, mapId):
        return self.gm(pid, 'scene_enter(%d, %d)' % (pid, mapId))

    def tbox_reset(self, pid, num):
        game = self.get_rpc_game(pid)
        cmd = """p=get_by_pid(%d);p.add_re(%d)""" % (pid, num)
        return game.execute(cmd)

#    def player_func(self, pid, index):
#        return self.gm(pid, 'player_func(%d, %d)' % (pid, index))

    def send_mail(self,pids, t, title, content, items, param='', notify_mgr=True):
        Game.mail_mgr.send_mails(pids, t, title, content, items, param=param, notify_mgr=notify_mgr)
        return u'发送成功'

    def restart(self, mins):
        Game.main_app.restart(mins)
        return u'重启成功'

    def restart_stop(self, mins):
        Game.main_app.app_stop(mins)
        return u'停止成功'

#    def update(self, tbname, key, values):
#        return Game.rpc_store.update(tbname, key, values)

    def arena_init(self):
        return Game.rpc_arena_mgr.init()

    def reload_ban_words(self):
        """ 重新加载敏感词数据 """
        for g in Game.iter_games():
            g.reload_ban_words()
        return u'加载成功'




#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
