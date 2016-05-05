#!/usr/bin/env python
# -*- coding:utf-8 -*-
import os
import datetime
import functools
import types
from collections import OrderedDict

from grpc import get_proxy_by_addr

from corelib import (log,
        wrap_dis_gc, spawn, spawn_later, message, client_rpc,
        un_reg_global, get_global, sleep, Semaphore, getcurrent, Timeout)
from corelib.common import custom_today
from corelib.tools import Monitor
from corelib.memory_cache import TimeMemCache

from game.base.constant import ONE_DAY_DELTA

import app_config

#启用json通讯
from corelib.client_rpc import (AbsExport, JsonClientRpc as ClientRpc,
            )
pack_msg = ClientRpc.pack_msg
prepare_send = ClientRpc.prepare_send
aes_encrypt = ClientRpc.aes_encrypt #aes加密数据

def get_union_mgr_funcs():
    """ 获取联合进程的模块创建方法列表,联合进程中的模块不能依赖game对象 """
    from .store import new_game_store
    from .client import new_client
    from player.player_mgr import new_player_mgr
    from scene.scene_mgr import new_scene_mgr
    from .glog.logger import new_game_logger
    from .mgr.status import new_status_mgr
    from .mgr.rewardcode import new_ex_code_mgr
    from ally.ally_mgr import new_ally_mgr
    from .mgr.report import new_report_mgr
    from .mgr.arena import new_arena_mgr
    from .boss.boss_mgr import new_boss_mgr
    from .player.vip import new_vip_mgr
    from .mgr.horn import new_horn_mgr
    from .mgr.tbox import new_tboxnews_mgr
    from .team.team_mgr import new_team_mgr
    from .mgr.reward import new_reward_mgr
    from .mgr.chat import new_notify_svr
    from .mgr.rank import new_rank_mgr
    from .mgr.ban_word_mgr import new_ban_word_mgr
    from .ally.war_mgr import new_awar_mgr
    rs = OrderedDict()
    rs['store'] = [new_game_store, new_status_mgr]
    rs['union'] = [new_client, new_reward_mgr, new_player_mgr, new_ally_mgr, new_vip_mgr, new_tboxnews_mgr, new_team_mgr, new_awar_mgr]
    rs['scene'] = [new_scene_mgr]
    rs['glog'] = [new_game_logger, new_report_mgr, new_notify_svr]
    rs['activity'] = [new_arena_mgr, new_ex_code_mgr, new_boss_mgr, new_horn_mgr, new_rank_mgr, new_ban_word_mgr]
    return rs

def new_logic_game():
    """ 新建逻辑游戏对象 """
    return LogicGame()


def get_obj(addr_or_app, name):
    """ 获取远程代理对象或者本地对象 """
    if hasattr(addr_or_app, 'get_proxy'):
        obj = addr_or_app.get_proxy(name)
    else:
        obj = get_proxy_by_addr(addr_or_app, name)
    return obj

class BaseGameMgr(object):
    def __init__(self, game):
        self._game = game
        if 0:
            self._game = LogicGame()

    def start(self):
        pass

    def stop(self):
        if self._game is not None:
            setattr(self, '_game', None)
            return True
        return False


@message.observable
class Game(object):
    instance = None
    inited = False
    if 0:
        #跨进程对象
        instance = Game()
        from player.player_mgr import GPlayerMgr
        rpc_player_mgr = GPlayerMgr()
        from client import GameClient
        rpc_client = GameClient()
        from game.scene.scene_mgr import GSceneMgr
        rpc_scene_mgr = GSceneMgr()
        from game.store import GameStore, ResStore, PayStore
        rpc_store = GameStore()
        rpc_res_store = ResStore()
        rpc_pay_store = PayStore()
        from game.glog.logger import LoggerServer
        rpc_logger_svr = LoggerServer()
        from game.mgr.status import StatusMgr
        rpc_status_mgr = StatusMgr()
        from game.mgr.report import ReportMgr
        rpc_report_mgr = ReportMgr()
        from ally.ally_mgr import AllyMgr
        rpc_ally_mgr = AllyMgr()
        from game.mgr.arena import ArenaMgr
        rpc_arena_mgr = ArenaMgr()
        from game.mgr.boss import BossMgr
        rpc_boss_mgr = BossMgr()
        from game.player.vip import GVipMgr
        rpc_vip_mgr = GVipMgr()
        from game.mgr.rewardcode import ExchangeCodeMgr
        rpc_ex_code_mgr = ExchangeCodeMgr()
        from game.mgr.tbox import GTboxNewsMgr
        rpc_tboxnews_mgr = GTboxNewsMgr()
        from game.mgr.horn import HornMgr
        rpc_horn_mgr = HornMgr()
        from game.team.team_mgr import TeamMgr
        rpc_team_mgr = TeamMgr()
        from game.mgr.reward import RpcRewardMgr
        rpc_reward_mgr = RpcRewardMgr()
        from .mgr.chat import MyNotifyServer
        rpc_notify_svr = MyNotifyServer()
        from .mgr.rank import RankMgr
        rpc_rank_mgr = RankMgr()

        #本地全局对象
        from game.res.res_mgr import ResMgr
        res_mgr = ResMgr()
        from game.glog.logger import GameLogger
        glog = GameLogger()
        from .base.setting import SettingMgr
        setting_mgr = SettingMgr()
        from game.item.item_mgr import ItemMgr
        item_mgr = ItemMgr()
        from game.item.reward import RewardMgr
        reward_mgr = RewardMgr()
        from game.mgr import chat
        chat_mgr = chat.ChatMgr()
        from game.player import mail, vip
        mail_mgr = mail.MailMgr()
        vip_mgr = vip.VipMgr()
        from game.achievement import achi_mgr
        achi_mgr = achi_mgr.AchievementMgr()
        from game.mgr import gem
        gem_mgr = gem.GemMgr()


    main_app = None
    app = None
    name = ''
    parent_stoped = False
    rpc_names = set()
    games = {} #其它逻辑进程中的game对象, {addr:(game, pid)}
    rpc_init_funcs = {}
    #缓存,缓存数量待优化
    gcaches = TimeMemCache(size=1000, name='game.gcaches')
    lock_count = 9999
    def __init__(self):
        Game.instance = self
        self.stoping = False
        self.stoped = True
        self.big_area = None #大区名
        self.area = None #小区名
        self.stop_lock = Semaphore(self.lock_count)
        self.stop_mgrs = []

    @classmethod
    def _rpc_on_close(cls, proxy):
        """ 功能服关闭,等待重新链接 """
        name = proxy._rpc_name
        addr, key = proxy.get_proxy_id()
        if os.environ.get('PARENT_STOPED', None):
            return
        if Game.app.stoped:
            return
        log.info('reconnect rpc(%s):%s', name, addr)
        while 1:
            new = get_obj(addr, key)
            if new is None or not new.valid():
                sleep(0.1)
                continue
            cls.add_rpc_mgr(name, new)
            funcs = cls.rpc_init_funcs.get(name, [])
            for f in funcs:
                spawn(f, new)
            break

    @classmethod
    def iter_games(cls):
        addrs = Game.games.keys()
        for key in addrs:
            g = Game.games.get(key, None)
            if not g:
                continue
            yield g[0]

    @classmethod
    def one_game(cls):
        return Game.games.itervalues().next()[0]

    @classmethod
    def valid_games(cls):
        """ 返回有效的逻辑进程game对象 """
        import psutil
        return [game for game, pid in Game.games.values() if psutil.pid_exists(pid)]

    @classmethod
    def reg_other_game(cls, rpc_game, process_id, _pickle=True, _no_result=True):
        """ 注册其它进程的game对象 """
        log.debug('reg_other_game(%s)', rpc_game.get_addr())
        Game.games[rpc_game.get_addr()] = (rpc_game, process_id)

    @classmethod
    def unreg_other_game(cls, game_addr, _no_result=True):
        """ 反注册其它进程的game对象 """
        log.debug('unreg_other_game(%s)', game_addr)
        if isinstance(game_addr, list):
            game_addr = tuple(game_addr)
        Game.games.pop(game_addr, None)

    @classmethod
    def init_snss(cls, get_config=None, web_app=None, api_url=None, res_store=None):
        """ 初始化sns模块 """
        from game.store import get_sns_params
        from webapi import init_snss, SNSClient
        if res_store is None:
            res_store = Game.rpc_res_store
        SNSClient.res_store = res_store

        if get_config is None:
            get_config = Game.rpc_res_store.get_config
        params = get_sns_params(get_config)
        return init_snss(params, web_app=web_app, api_url=api_url)

    @classmethod
    def sub_rpc_mgr_init(cls, rpc_mgr, func):
        funcs = Game.rpc_init_funcs.setdefault(rpc_mgr._rpc_name, set())
        funcs.add(func)

    @classmethod
    def add_rpc_mgr(cls, name, mgr):
        if hasattr(mgr, 'sub_close'):
            #log.info('rpc_mgr sub_close:(%s, %s)', name, mgr)
            mgr.sub_close(cls._rpc_on_close)
        cls.rpc_names.add(name)
        mgr._rpc_name = name
        setattr(cls, name, mgr)

    @classmethod
    def init_res_mgr(cls):
        if getattr(cls, 'res_mgr', None):
            return
        from game.res.res_mgr import ResMgr
        Game.res_mgr = ResMgr()
        Game.res_mgr.load()

    @classmethod
    def init_logger(cls):
        if getattr(cls, 'glog', None):
            return
        from game.glog.logger import GameLogger
        Game.glog = GameLogger()

    @classmethod
    def init_mail_mgr(cls):
        if getattr(cls, 'mail_mgr', None):
            return
        from game.player.mail import MailMgr
        Game.mail_mgr = MailMgr()

    @classmethod
    def init_setting_mgr(cls):
        from .base.setting import SettingMgr
        Game.setting_mgr = SettingMgr()
        Game.setting_mgr.start()

    @classmethod
    def init_chat_mgr(cls):
        from game.mgr.chat import ChatMgr
        Game.chat_mgr = ChatMgr()
        Game.chat_mgr.start()

    @classmethod
    def init_item_mgr(cls):
        from .item.item_mgr import ItemMgr
        Game.item_mgr = ItemMgr()

    @classmethod
    def init_reward_mgr(cls):
        from .item.reward import RewardMgr
        Game.reward_mgr = RewardMgr()
        Game.reward_mgr.start()

    @classmethod
    def init_vip_mgr(cls):
        from .player.vip import VipMgr
        Game.vip_mgr = VipMgr()
        Game.vip_mgr.start()

    @classmethod
    def init_cls(cls):
        cls.init_res_mgr()
        cls.init_logger()
        cls.init_mail_mgr()
        cls.init_setting_mgr()
        cls.init_chat_mgr()
        cls.init_item_mgr()
        cls.init_reward_mgr()
        cls.init_vip_mgr()

    @classmethod
    def get_addr(cls):
        return Game.app.get_addr()

    def init_player_mgr(self):
        from player.player_mgr import SubPlayerMgr
        self.player_mgr = SubPlayerMgr(self)
        self.stop_mgrs.append(self.player_mgr)

    def init_scene_mgr(self):
        from scene.scene_mgr import SubSceneMgr
        self.scene_mgr = SubSceneMgr(self)
        self.stop_mgrs.append(self.scene_mgr)

    def init_task_mgr(self):
        """ 初始化任务管理器 """
        from task.task_mgr import TaskMgr
        self.task_mgr = TaskMgr(self)

    def init_gm_mgr(self):
        from game.gm import GameMasterMgr
        self.gm_mgr = GameMasterMgr(self)

    def init_mining_mgr(self):
        from .mgr.mining import MiningMgr
        self.mining_mgr = MiningMgr(self)
        self.stop_mgrs.append(self.mining_mgr)

    def init(self):
        #定时器
        from corelib.common import TimerSet
        self.timer_set = TimerSet(self)
        self.stop_mgrs.append(self.timer_set)
        #缓存,缓存数量待优化
        self.caches = TimeMemCache(size=500, name='game.caches')

        self.init_snss()
        self.init_res_mgr()
        self.init_gm_mgr()
        self.init_player_mgr()
        self.init_scene_mgr()
        self.init_task_mgr()
        self.init_mining_mgr()

        from game.mgr.deep import DeepMgr
        self.deep_mgr = DeepMgr(self)
        self.stop_mgrs.append(self.deep_mgr)


        from game.mgr.fish import FishMgr
        self.fish_mgr = FishMgr(self)
        self.stop_mgrs.append(self.fish_mgr)

        from game.mgr.coinstree import CTreeMgr
        self.ctree_mgr = CTreeMgr(self)
        self.stop_mgrs.append(self.ctree_mgr)

        from game.mgr.tbox import TboxMgr
        self.tbox_mgr = TboxMgr(self)
        self.stop_mgrs.append(self.tbox_mgr)

        from game.mgr.hfate import HitFateMgr
        self.hfate_mgr = HitFateMgr(self)
        self.stop_mgrs.append(self.hfate_mgr)

        from game.mgr.bftask import BfTaskMgr
        self.bftask_mgr = BfTaskMgr(self)
        self.stop_mgrs.append(self.bftask_mgr)

        from game.mgr.fete import FeteMgr
        self.fete_mgr = FeteMgr(self)
        self.stop_mgrs.append(self.fete_mgr)

        #'神秘商人'
        from game.mgr.shop import ShopMgr
        self.shop_mgr = ShopMgr(self)
        self.stop_mgrs.append(self.shop_mgr)

        from game.mgr.social import SocialMgr
        self.social_mgr = SocialMgr(self)
        self.stop_mgrs.append(self.social_mgr)

        from game.achievement.achi_mgr import AchievementMgr
        self.achi_mgr = AchievementMgr(self)
        self.stop_mgrs.append(self.achi_mgr)

        from game.mgr.gem import GemMgr
        self.gem_mgr = GemMgr(self)
        self.stop_mgrs.append(self.gem_mgr)

        from game.mgr.day_lucky import DayLuckyMgr
        self.day_lucky_mgr = DayLuckyMgr(self)
        self.stop_mgrs.append(self.day_lucky_mgr)

        from game.mgr.day_sign import DaySignMgr
        self.day_sign_mgr = DaySignMgr(self)
        self.stop_mgrs.append(self.day_sign_mgr)

        #玩家vip属性管理
        from game.mgr.vipattr import PlayerVipAttrMgr
        self.vip_attr_mgr = PlayerVipAttrMgr(self)
        self.stop_mgrs.append(self.vip_attr_mgr)

        #奖励奖励管理
        from game.mgr.reward import RewardMgr
        self.reward_mgr2 = RewardMgr(self)
        self.stop_mgrs.append(self.reward_mgr2)


    def start(self):
        if not self.stoped:
            return
        self.stoped = False
        self.timer_set.start()
        #每天定时清理
        self.cron_clean_data_zero(inited=True)  #0点
        for mgr in self.stop_mgrs:
            try:
                if not hasattr(mgr, 'start'):
                    continue
                mgr.start()
            except StandardError as e:
                log.log_except('stop mgr(%s) error:%s', mgr, e)

    def _stop(self):
        pass

    def stop(self):
        """ 进程退出 """
        if self.stoping:
            return
        self.stoping = True
        log.info(u'game模块停止')
        Game.parent_stoped = bool(os.environ.get('PARENT_STOPED', False))
        def _stop_func():
            try:
                self._stop()
            except StandardError:
                log.log_except()

            for mgr in self.stop_mgrs:
                try:
                    mgr.stop()
                except StandardError as e:
                    log.log_except('stop mgr(%s) error:%s', mgr, e)
            sleep(0.5) #允许其它线程切换
            #等待其它完成
            while self.stop_lock.wait() < self.lock_count:
                sleep(0.1)
        try:
            #保证在30分钟内处理完
            with Timeout.start_new(60 * 30):
                _stop_func()
        except:
            log.log_except()
        self.stoped = True


    def cron_clean_data_zero(self, inited=False):
        """
        定在每天凌晨0点初始化的处理
        """
        now = datetime.datetime.now()
        refresh_time = custom_today(hour=0, minute=0)
        refresh_time += ONE_DAY_DELTA
        sleep_times = (refresh_time - now).seconds + 5
        self.timer_set.call_later(sleep_times, self.cron_clean_data_zero)
        #执行游戏逻辑刷新
        if not inited:
            log.info(u"每日0点定时刷新开始")
            spawn(self.on_cron_clean_data_zero)
#            for player in self.scene_mgr.players.itervalues():
#                spawn(self.on_player_cron_clean_data_zero, player)

    def on_cron_clean_data_zero(self):
        """ channel,battle都需要的0点清理 """
        pass

    def on_player_cron_clean_data_zero(self, player):
        """ channel,battle都需要的0点角色清理 """
        pass

    def is_gm(self, uid):
        """ 根据用户名，检查是否gm """
        from game.player.player import UserData
        return UserData.is_gm(uid)

    def sync_exec(self, func, args, _pickle=True):
        """ 由该进程执行func, func内独立使用各自的lock,保证同步执行 """
        try:
            if args:
                return func(*args)
            return func()
        except:
            log.log_except()
            raise

class LogicGame(Game):
    _rpc_name_ = 'game'
##    @classmethod
##    def _init_mgr(cls):
##        """ 初始化有可能是远程的管理对象 """
##        funcs = get_union_mgr_funcs()
##        for name, func in funcs.iteritems():
##            if hasattr(cls, name):
##                continue
##            mgr = func()
##            cls._add_mgr(mgr)


    @classmethod
    def init_subgame(cls, app, main_app, subgames):
        """ 根据联合进程情况，初始化模块 """
        from game.store.define import GF_CLIENTRPC_AESKEY

        Game.main_app = main_app
        Game.app = app
        Game.name = app.name
        for name, addr_or_apps in subgames.iteritems():
            #只有game的name才会有多个
            if len(addr_or_apps) != 1:
                continue
            if name == cls._rpc_name_:
                continue
            addr_or_app = addr_or_apps[0]
            mgr = get_obj(addr_or_app, name)
            Game.add_rpc_mgr(name, mgr)
        Game.init_cls()
        cls.init_shell()
        client_rpc_aes_key = Game.rpc_res_store.get_config(GF_CLIENTRPC_AESKEY)
        ClientRpc.aes_init(client_rpc_aes_key, pack=1)
        Game.inited = True


    @classmethod
    def init_shell(cls):
        import grpc
        gl = dict(g=Game,)
        grpc.shell_locals.update(Game.app.names)
        grpc.shell_locals.update(gl)



    def start(self):
        return Game.start(self)

    def reg_obj(self, obj):
        return self.app.reg_obj(obj)

    def get_count(self):
        return self.player_mgr.count

    def execute(self, cmd, log_except=False, log_gm=True):
        """ 执行gm命令 """
        return self.gm_mgr.gm_master.execute(cmd, log_except=log_except, log_gm=log_gm)

    def chat_broadcast(self, msgs, _no_result=True):
        """ 广播多个聊天信息,
        msgs: [data, data, ...]  data=[ids, msg]
        """
        self.chat_mgr.receive_broadcast(msgs)

    def reload_ban_words(self):
        log.info(u'重新加载敏感词数据')
        self.setting_mgr._load_words()
        log.info(u'加载敏感词数据完成')


def _monitor_disable(f):
    if Game.app is None:
        raise NotImplementedError('Game have not init!')
    return f
client_monitor_export = _monitor_disable
grpc_monitor = _monitor_disable
monitor_store = _monitor_disable

_func_status = Monitor.instance().func_status_ex
def _monitor_func(func, n=None, t=0):
    if not n:
        n = func.__name__
    if n == 1:
        n = '%s.%s' % (func.__module__, func.__name__)
    @functools.wraps(func)
    def _func(*args, **kw):
        if callable(n):
            return _func_status(t, n(func, args, kw), func, args, kw)
        return _func_status(t, n, func, args, kw)
    return _func
_grpc_monitor = functools.partial(_monitor_func, n=1, t=1)

def monitor_export(export_cls):
    """ client_rpc monitor """
    attr_pre = export_cls._rpc_attr_pre
    for n in dir(export_cls):
        if not n.startswith(attr_pre):
            continue
        func = getattr(export_cls, n)
        setattr(export_cls, n, _monitor_func(func))

def _monitor_store(drv_obj):
    """ driver monitor """
    def _get_tname(func, args, kw):
        return '%s@%s' % (func.__name__, args[0])

    for name in dir(drv_obj):
        func = getattr(drv_obj, name)
        if not isinstance(func, types.MethodType):
            continue
        if not callable(func) or not getattr(func, 'store', 0):
            continue
        if getattr(func, 'tname', 0):
            n = _get_tname
        else:
            n = None
        setattr(drv_obj, name, _monitor_func(func, n=n, t=2))

def init_monitor():
    global client_monitor_export, grpc_monitor, monitor_store
    if not getattr(app_config, 'monitor', None):
        return
    if client_monitor_export == monitor_export:
        log.info('init_monitor has done')
        return
    log.info('init_monitor')
    client_monitor_export = monitor_export
    grpc_monitor = _grpc_monitor
    monitor_store = _monitor_store
    def report():
        try:
            import app
        except ImportError:
            return
        st = 30 * 60
        m = Monitor.instance()
        while not app.stoped:
            data = m.pop_report()
            for fn, (t, total, use, err) in data.iteritems():
                Game.glog.log_rpc(dict(func=fn, t=t, total=total, use=use, err=err))
            sleep(st)
    spawn(report)

def init(app):
    Game.app = app
    init_monitor()

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



