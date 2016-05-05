#!/usr/bin/env python
# -*- coding:utf-8 -*-
import weakref
import time
import functools
import copy
from contextlib import contextmanager

from corelib import log, spawn, spawn_later, Event, RLock, sleep
from corelib.message import observable
from corelib.common import CustomObject
from corelib.data import IntBiteMap

from webapi import SNS_EQUALS

from game.base.constant import (USE_PLAYS_MAX, USE_PLAYS_MAX_V,
        PLAYER_LEVEL_MAX, IF_IDX_CAR,
        GUIDE_PLAYER_CMD, GUIDE_PLAYER_CMD_V,
        GUIDE_ROLES, GUIDE_ROLES_V, GUIDE_PASS,
        IF_IDX_STATE, IF_IDX_LEVEL,
        PLAYER_ATTR_WIN_FIGHTS,
        )
from game.base.msg_define import MSG_UPGRADE, MSG_ADDTRAIN, MSG_LOGON, MSG_TRAIN, MSG_COST_COIN3
from  game.base import errcode, common
from game import Game, pack_msg, ClientRpc, AbsExport
from game.store import (GameObj, StoreObj, TN_PLAYER, TN_USER,
        FOP_IN, FOP_GT, FOP_GTE, FOP_LT, FOP_LTE,
        FN_PLAYER_UID, FN_PLAYER_LEVEL, FN_ID, TN_P_TBOX, FN_P_ATTR_PID,
        FN_P_ATTR_CBE, FN_P_ATTR_CBES, FN_P_ATTR_ALLYTBOX,
        FN_USER_DT,
        )
from game.rpcs.player_handler import PlayerRpcHandler
from game.glog.common import PL_LOGIN, PL_LOGOUT, PL_UPGRADE, COIN_ADD_FIGHT_WIN
from game.mgr.horn import PlayHornMgr
from . import actions
from .bag import Bag, PlayerWaitBag
from .role import PlayerRoles
from .task import PlayerTask
from .attr import PlayerAttr
from .position import PlayerPositions
from .sit import PlayerSit
from .map import PlayerMap
from .mail import PlayerMail
from .buff import PlayerBuff
from .vip import PlayerVip
from vipattr import PlayerVipAttr
from game.achievement.achi_mgr import PlayerAchievement
from .property import PlayerProperty


import language
import game_config

class UserData(StoreObj):
    def init(self):
        self.id = None
        self.sns = 0 #平台类型
        self.name = ''
        self.pwd = ''
        self.UDID = ''
        self.DT = ''
        self.MAC = ''
        self.DEV = ''
        self.VER = ''
        self.tLogin = int(time.time())
        self.tLogout = int(time.time())
        self.tNew = 0
        self.fbLogin = 0
        self.fbChat = 0
        self.gm = 0

    @classmethod
    def is_gm(cls, uid):
        """ 判断是否gm账号 """
        values = Game.rpc_store.load(TN_USER, uid)
        return values and bool(values.get('gm', 0))

    @classmethod
    def user_by_sns(cls, t, sid):
        #不同平台账号相通:云顶破解=云顶, pp=pp苹果园
        snses = SNS_EQUALS.get(t, (t, ))
        u = Game.rpc_store.query_loads(TN_USER, dict(sns={FOP_IN:snses}, name=sid))
        return u

    @classmethod
    def user_players(cls, t, sid):
        u = cls.user_by_sns(t, sid)
        if not u:
            return None
        return PlayerData.user_players(u[0][FN_ID])

    @classmethod
    def user_tokens(cls, uids):
        query = {FN_ID: {FOP_IN:list(uids)} }
        rs = Game.rpc_store.values(TN_USER, [FN_USER_DT],
                query)
        return dict((v[FN_ID], v[FN_USER_DT]) for v in rs)


def wrap_inited(func):
    @functools.wraps(func)
    def _func(self, *args, **kw):
        if not self.inited:
            return 0, errcode.EC_VALUE
        return func(self, *args, **kw)
    return _func


class User(GameObj, AbsExport):
    """ 账号 """
    TABLE_NAME = TN_USER
    DATA_CLS = UserData
    INIT_TIMEOUT = 60
    LOGON_TIMEOUT = 60 * 5 #登录、新建角色
    def __init__(self, adict=None):
        if 0:
            from game.player.player_mgr import SubPlayerMgr
            self.mgr = SubPlayerMgr()
            self.player = Player()
        super(User, self).__init__(adict=adict)
        self.inited = 0
        self._init_waiter = Event()
        self.key = None
        self.player = None
        self.logouted = False
        self.player_datas = None
        self.players = {}
        self.sns_type = 0

    def start(self, mgr, sock, addr):
        self.mgr = mgr
        self.sock = sock
        self.addr = addr
        self._rpc = ClientRpc(self.sock, self.addr, self)
        self._rpc.start()

    def stoped(self):
        return self._rpc is None

    def stop(self):
        if self._rpc:
            rpc =self._rpc
            self._rpc = None
            rpc.stop()

    def on_close(self, rpcobj):
        """ 断线处理 """
        self.logout()

    def wait_for_init(self):
        """ 等待初始化和登陆 """
        self._init_waiter.wait(self.INIT_TIMEOUT)
        if not self.inited >= 2:
            self.stop()
##        self._init_waiter.clear()
##        self._init_waiter.wait(self.LOGON_TIMEOUT)
##        if not self.inited == 3:
##            self.stop()

    def send_msg(self, msg):
        """ 发送由pack_msg生成的消息 """
        if self._rpc is None:
            return
        self._rpc.send(msg)

    def logon(self):
        """ 账号登录 """
        uid, sns_type = self.mgr.check_logon(self.data.id, self.key)
        if uid is False:
            return False
        adict = Game.rpc_store.load(TN_USER, uid)
        self.data.update(adict)
        self.mgr.add_user(self)
        self.sns_type = sns_type
        return True

    def logout(self):
        """ 退出账号 """
        if self.logouted:
            return
        self.logouted = True
        if self.player:
            self.player.logout()
        self.mgr.del_user(self)
        self.stop()

    def player_login(self, pid):
        resp_f = 'enter'
        player_data = PlayerData.load(pid)
        player = Player()
        player.data.update(player_data)
        if player.data.id is None:
            log.error('player(%d)player_login load error:%s', pid, player_data)
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)

        if player.is_forbid_login:
            return pack_msg(resp_f, 0, err=errcode.EC_FORBID_LOGON)
        if not self.mgr.add_player(player):
            return pack_msg(resp_f, 0, err=errcode.EC_TIME_UNDUE)
        self.player = player
        try:
            player.set_rpc(self._rpc)
            player.login(self)
            map_id = player.data.mapId if player.data.mapId else 1
            player.scene_enter(map_id, login=True)
            self.mgr.logon_player(player)
            log.debug(u'(%s)玩家(%s)登陆成功', player.data.id, player.data.name)
            player.send_msg(player.get_init_msg())
            spawn(self.mgr.logoned_player, player)
            return pack_msg(resp_f, 1)
        except:
            log.log_except(u'玩家(%s)登陆初始化失败', player.data.id)
            self.player_logout()
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)


    def player_logout(self):
        try:
            self.player_leave()
            if not self.player:
                return
            p = self.player
            self.player = None
            self.mgr.del_player(p)
        except Exception:
            log.log_except()
        self.player = None

    def player_leave(self):
        if self._rpc:
            self._rpc.set_export(self)

    def rc_login1(self, user, key):
        """ client登陆到逻辑进程
        user: user id
        """
        if self.inited:
            return
        resp_f = 'login1'
        self.inited = 1
        log.info(u'账号(%s)登陆', user)
        self.key = key
        self.data.id = user
        if not self.logon():
            log.error(u'账号(%s)登陆错误', user)
            resp = pack_msg(resp_f, 0, err=errcode.EC_LOGIN_ERR)
        else:
            #resp.server_time = int(time.time())
            resp = pack_msg(resp_f, 1)
            self.inited = 2
        spawn_later(1, self._init_waiter.set)
        return resp

    def rc_logout(self):
        resp_f = 'logout'
        self.logout()
        return pack_msg(resp_f, 1)

    @wrap_inited
    def rc_players(self):
        """ 获取角色列表 """
        resp_f = 'players'
        if self.player_datas is None:
            self.player_datas = list(Game.rpc_store.query_loads(TN_PLAYER, dict(uid=self.data.id)))
            self.players = dict((v[FN_ID], i) for i, v in enumerate(self.player_datas))
        return pack_msg(resp_f, 1, data=self.player_datas)

    @wrap_inited
    def rc_delete(self, pid):
        """ 删除玩家,注意:数据未备份会永远删除掉 """
        resp_f = 'delete'
        if not self.player_datas:
            return pack_msg(resp_f, 0)
        for data in self.player_datas:
            if data['id'] != pid:
                continue
            self.players.pop(pid, None)
            self.player_datas.remove(data)
            rs = Player.del_player(pid, data=data)
            if rs:
                return pack_msg(resp_f, 1)
            else:
                return pack_msg(resp_f, 0, err=errcode.EC_VALUE)

    @wrap_inited
    def rc_new(self, name, rid):
        """ 新建player """
        resp_f = 'new'
        #log.debug(u'rc_new:%s', name)
        #判断该账号是否超过创建角色的数目
        name = name.strip()
        tPlayerNum = len(Game.rpc_store.query_loads(TN_PLAYER, dict(uid=self.data.id)))
        if tPlayerNum > Game.instance.setting_mgr.setdefault(USE_PLAYS_MAX, USE_PLAYS_MAX_V):
            return pack_msg(resp_f, 0, err=errcode.EC_USER_MAX)
        if not name or rid not in Game.res_mgr.roles:
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
        #敏感词
        if Game.rpc_ban_word_mgr.check_ban_word(name):
        #if Game.setting_mgr.check_ban_word(name):
            return pack_msg(resp_f, 0, err=errcode.EC_NAME_REPEAT)
        #名字长度截取
        player_dict = Game.rpc_player_mgr.new_player(self.data.id, name[:50], rid)
        if not player_dict:
            return pack_msg(resp_f, 0, err=errcode.EC_NAME_REPEAT)
        player = Player.new_player(player_dict)
        log.info(u'用户(%s)新建玩家(%s):%s', self.data.name, name, player.data.id)
        data = player.to_dict()
        self.player_datas.append(data)
        self.players[player.data.id] = len(self.player_datas) - 1
        return pack_msg(resp_f, 1, data=data)

    @wrap_inited
    def rc_enter(self, id):
        """ 进入player """
        resp_f = 'enter'
        if not id:
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
        if id not in self.players:
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
        if Game.rpc_player_mgr.pre_add(id, self.data.id):
            sleep(0.01)
        return self.player_login(id)


class PlayerData(StoreObj):
    def init(self):
        """ 初始化对象属性 """
        self.id = None
        self.uid = 0
        self.name = ''
        self.level = 1
        self.exp = 0
        self.rid = 0
        self.coin1 = 0 #银币
        self.coin2 = 0 #元宝
        self.coin3 = 0 #绑定元宝
        self.train = 0
        self.vip = 0
        self.vipCoin = 0 #累计充值元宝数
        self.car = 0
        self.tNew = 0 #创建时间
        self.tTotal = 0
        self.tLogin = 0 #最后登录时间
        self.tLogout = 0 #最后登出时间
        self.mapId = 0
        self.preMId = 0#上一次大地图id
        self.wMap = ''#世界地图信息
        self.pos = '' #坐标 '{10, 10}'
        self.state = 0 #玩家状态:0=普通, 1=打坐, 2=运龟 ....

        self.posId = 0 #阵型id
        self.stage = '' #副本数据
        self.chapter = 1 #1=初章,2=1章,3=2章初章,4=2章
        self.funcs = 0 #开放的功能列表
        self.fbLogin = 0 #禁止登录时间
        self.fbChat = 0 #禁言时间
        self.Payed = 0 #是否已经充值过

    def load_from_pid(self, pid):
        data = PlayerData.load(pid)
        if data:
            self.update(data)
            return 1
        return 0

#    def update(self, data):
#        super(PlayerData, self).update(data)
#        if 'Payed' not in data and 'vipCoin' in data:
#            self.Payed = 1 if  self.vipCoin >= Game.vip_mgr.vip1_coin else 0

    @classmethod
    def load(cls, pid):
        return Game.rpc_store.load(TN_PLAYER, pid)

    @classmethod
    def name_to_id(cls, name):
        rs = Game.rpc_store.values(TN_PLAYER, ['rid'], dict(name=name))
        if rs:
            return rs[0]['id'], rs[0]['rid']

    @classmethod
    def userinfo_from_name(cls, name, player_fs=None):
        if player_fs and 'uid' not in player_fs:
            player_fs.append('uid')
        else:
            player_fs = ['uid']
        rs = Game.rpc_store.values(TN_PLAYER, player_fs, dict(name=name))
        if not rs:
            return None, None
        uid = rs[0]['uid']
        u = Game.rpc_store.load(TN_USER, uid)
        return u, rs[0]

    @classmethod
    def id_to_name(cls, pid):
        rs = Game.rpc_store.values(TN_PLAYER, ['name', 'rid'], dict(id=pid))
        if rs:
            return rs[0]['name'], rs[0]['rid']

    @classmethod
    def user_players(cls, uid):
        return Game.rpc_store.query_loads(TN_PLAYER, dict(uid=uid))

    @classmethod
    def get_uids(cls, pids):
        querys = {FN_ID: {FOP_IN:list(pids)}}
        rs = Game.rpc_store.values(TN_PLAYER, [FN_PLAYER_UID],
                querys=querys)
        return set(v[FN_PLAYER_UID] for v in rs)

    @classmethod
    def new_player(cls, uid, name, rid):
        """ 新建角色,返回:角色id,字典 """
        player = cls.new_dict(uid=uid, name=name, rid=rid, tNew=int(time.time()))
        pid = Game.rpc_store.insert(TN_PLAYER, player)
        player['id'] = pid
        return pid, player

    @classmethod
    def get_values(cls, pid, cols, store=None, sort_by=None):
        """ pid=None:查询所有数据 """
        if store is None:
            store = Game.rpc_store
        if pid:
            rs = store.values(TN_PLAYER, cols, dict(id=pid))
            if rs:
                return rs[0]
        else:
            return store.values(TN_PLAYER, cols, None, sort_by=sort_by)

    @classmethod
    def get_level_pids(cls, begin, end, store=None, limit=0, skip=0):
        """ 获取某等级区间段的玩家id """
        if store is None:
            store = Game.rpc_store
        querys = dict(level={FOP_GTE:begin, FOP_LTE:end}, uid={FOP_GT:0})
        return [v[FN_ID] for v in store.values(TN_PLAYER, [],
                querys, limit=limit, skip=skip)]

    @classmethod
    def get_level_pvalue(cls, begin, end, cols, limit=0):
        """ 获取某等级区间段的玩家的信息 """
        querys = dict(level={FOP_GTE:begin, FOP_LTE:end}, uid={FOP_GT:0})
        store = Game.rpc_store
        players = store.values(TN_PLAYER, cols, querys, limit=limit)
        return players

    @classmethod
    def get_players_values(cls, pids, cols, store=None, sort_by=None):
        """ pids=None:查询所有数据
            pids=字典:是查询条件
            pids=list:是id列表
        """
        if store is None:
            store = Game.rpc_store
        if pids is not None and not pids:
            return []

        if isinstance(pids, dict):
            return store.values(TN_PLAYER, cols, pids, sort_by=sort_by)
        elif pids:
            return store.values(TN_PLAYER, cols, dict(id={FOP_IN:list(pids)}))
        else:
            return store.values(TN_PLAYER, cols, None, sort_by=sort_by)

    @classmethod
    def get_players_levels(cls, pids, CBE=0, store=None):
        rs = cls.get_players_values(pids, [FN_PLAYER_LEVEL], store=store)
        if not rs:
            return None
        if CBE:
            CBEs = PlayerAttr.get_CBEs(pids)
            CBEs = dict([(i[FN_P_ATTR_PID], i.get(FN_P_ATTR_CBE, 1)) for i in CBEs])
            return dict([(i[FN_ID], (i[FN_PLAYER_LEVEL],
                    CBEs.get(i[FN_ID], 0))) for i in rs])
        return dict([(i[FN_ID], i[FN_PLAYER_LEVEL]) for i in rs])

    @classmethod
    def count(cls, querys, store=None):
        if store is None:
            store = Game.rpc_store
        return store.count(TN_PLAYER, querys)

    @classmethod
    def update_values(cls, pid, values, store=None):
        """ 更新部分数据 """
        if store is None:
            store = Game.rpc_store
        return store.update(TN_PLAYER, pid, values)


@observable
class Player(actions.PlayerActionMixin):
    _wrefs = weakref.WeakValueDictionary()
    Data = PlayerData
    no_game = False

    @classmethod
    def new_player(cls, player_dict):
        """ 新建玩家,初始化数据 """
        p = cls()
        p.data.update(player_dict)
        p.save(full=False)
        return p

    @classmethod
    def load_player(cls, pid):
        """ 根据pid,加载创建player对象,必须在逻辑进程执行 """
        p = cls()
        if not p.data.load_from_pid(pid):
            return
        p.load_p()
        return p

    @classmethod
    def del_player(cls, pid, data=None):
        """ 删除玩家数据 """
        if data is None:
            data = Game.rpc_store.load(TN_PLAYER, pid)
        if data is None:
            return False
        player = cls()
        player.data.update(data)
        player.load()
        player.clear()
        Game.rpc_store.delete(TN_PLAYER, player.data.id)
        Game.rpc_player_mgr.del_player(pid)
        return True

    def __init__(self):
        Player._wrefs[id(self)] = self

        self.data = PlayerData()
        self._game = Game.instance
        if self._game is None:
            self._game = Game
            Player.no_game = True

        self.user = None
        self._rpc = None
        self._disable_send = 0
        self._proxy = None
        self.logined = False
        self.save_time = 0
        self._save_lock = RLock()

        #保存其它的运行期对象 player保存时,调用对象方法: obj.save(store)
        self.runtimes = CustomObject()
        #保存角色退出时需要调用清理方法的对象
        self.logout_objs = set([])

        #场景
        self.rpc_scene = None
        #物品列表
        self.bag = Bag(self)
        #待收取物品列表
        self.wait_bag = PlayerWaitBag(self)
        #配将
        self.roles = PlayerRoles(self)
        #任务信息
        self.task = PlayerTask(self)
        #玩家属性
        self.play_attr = PlayerAttr(self)
        #玩家阵型
        self.positions = PlayerPositions(self)
        #玩家打坐
        self.sit = PlayerSit(self)
        #玩家地图信息
        self.maps = PlayerMap(self)
        #邮件
        self.mail = PlayerMail(self)
        #buff
        self.buffs = PlayerBuff(self)
        #vip
        self.vip = PlayerVip(self)
        #大喇叭
        self.hron = PlayHornMgr(self)
        #玩家成就信息(每日成就， 永久成就)
        self.achievement = PlayerAchievement(self)
        #角色属性
        self.property = PlayerProperty(self)

        #玩家胜利战斗id(仅内存中，不存数据库,为防止作弊)
        self.win_fights = IntBiteMap()
        self.vip_attr = PlayerVipAttr(self)

        #ally = {'aid': 同盟ID, 'n': 同盟名字}
        self.ally = None
        self.other_init()

        if 0:
            from game.scene.scene import Scene
            self.user = User()
            self._rpc = ClientRpc()
            self._game = Game()
            self.rpc_scene = Scene()

    def init(self):
        if not self.is_guide:
            self.property.update_CBE()

    def uninit(self):
        """ 清理数据,防止内存泄露 """
        #log.debug('player(%s)uninit', self.data.id)
        def _uninit(obj):
            try:
                if hasattr(obj, 'uninit'):
                    obj.uninit()
                else:
                    obj.player = None
                    obj._player = None
            except:
                log.log_except()

        self.message_clear()
        _uninit(self.bag)
        del self.bag
        _uninit(self.wait_bag)
        del self.wait_bag
        _uninit(self.roles)
        del self.roles
        _uninit(self.task)
        del self.task
        _uninit(self.play_attr)
        del self.play_attr
        _uninit(self.positions)
        del self.positions
        _uninit(self.sit)
        del self.sit
        _uninit(self.maps)
        del self.maps
        _uninit(self.mail)
        del self.mail
        _uninit(self.buffs)
        del self.buffs
        _uninit(self.vip)
        del self.vip
        _uninit(self.hron)
        del self.hron
        _uninit(self.achievement)
        del self.achievement
        _uninit(self.property)
        del self.property
        del self.win_fights
        _uninit(self.vip_attr)
        del self.vip_attr
        self._game = None
        self._runtimes_exec('', _uninit)

    def _rpc_proxy_(self):
        """ 返回对应的代理对象 """
        if self._proxy is None:
            self._proxy = self.user.mgr.get_player_proxy(self.data.id)
        return self._proxy

    def set_rpc(self, rpc):
        self._rpc = rpc
        self._handler = PlayerRpcHandler(self)
        self._handler.init_by_rpc(rpc)

    @property
    def gm(self):
        try:
            return self._gm
        except AttributeError:
            self._gm = self._game.gm_mgr.get_gm(self)
            return self._gm

    @property
    def is_gm(self):
        return UserData.is_gm(self.data.uid)

    @property
    def is_close(self):
        return self._rpc is None

    @property
    def is_guide(self):
        return self.data.chapter <= 1

    @contextmanager
    def with_disable_msg(self):
        self._disable_send = 1
        try:
            yield
        finally:
            self._disable_send = 0

    def _gm_cmd(self, cmds):
        if not isinstance(cmds, (tuple, list)):
            cmds = [cmds]
        gm = self._game.gm_mgr.get_gm(self, forced=True)
        with self.with_disable_log():
            with self.with_disable_msg():
                data = self.data.to_dict()
                for cmd in cmds:
                    gm.execute(cmd % data, log_except=True,
                        log_gm=False)
        return gm

    def on_close(self):
        """ 断线处理 """
        log.info(u'player(%s) on_close', self.data.name)
        if self.user:
            self.user.logout()
        #TODO: 断线延迟释放，允许重连等优化

    def debug_kick(self):
        """测试T非测试玩家下线"""
        log.info(u'pid:(%s),during_debug_time(%s)', self.data.id, self.data.name)
        self.user.logout()

    def to_dict(self):
        return self.data.to_dict()

    def _runtimes_exec(self, name, func):
        for obj in self.runtimes.__dict__.values():
            if name and not hasattr(obj, name):
                continue
            try:
                func(obj)
            except:
                log.log_except()

    def reward_params(self):
        """ 获取奖励用参数 """
        return dict(level=self.data.level)

    def _init_guide(self):
        """ 初始化为初章数据 """
        if self._game.rpc_status_mgr.get(GUIDE_PASS):
            self.task.chapter_complete()
            return

        cmd = self._game.setting_mgr.setdefault(GUIDE_PLAYER_CMD, GUIDE_PLAYER_CMD_V)
        self._gm_cmd(cmd)

    def reg_logout(self, obj):
        """注册玩家下线调用的数据清理obj"""
        self.logout_objs.add(obj)

    def unreg_logout(self, obj):
        if obj in self.logout_objs:
            self.logout_objs.remove(obj)

    def login(self, user):
        """ 登录 """
        log.debug('player(%s-%s) login, sns(%s)', self.data.id, self.data.name, user.sns_type)
        self.logon_time = int(time.time())
        self.log_normal(PL_LOGIN, u=self.data.uid, ip=self._rpc.addr[0])
        self.user = user
        self.save_time = int(time.time())
        self.load()
        if self.is_guide:
            self._init_guide()
        self.logined = True
        self.init()
        self.safe_pub(MSG_LOGON)

    def _logout(self):
        self.sit.close()
        for obj in self.logout_objs:
            if not hasattr(obj, 'player_logout'):
                continue
            try:
                obj.player_logout(self.data.id)
            except Exception:
                log.log_except()

    def logout(self):
        """ 登出 """
        log.debug('player(%s-%s) logout', self.data.id, self.data.name)
        self._handler.close_handler()
        self.log_normal(PL_LOGOUT)
        try:
            self._logout()
        except:
            log.log_except(u'player(%s) logout error', self.data.name)
        logout_time = int(time.time())
        self.data.tTotal += logout_time - self.logon_time
        self.data.tLogin = self.logon_time
        self.data.tLogout = int(time.time())
        self.save()
        self._runtimes_exec('logout', lambda obj: obj.logout(self))
        self.logined = False
        self.user.player_logout()
        self.uninit()

    def leave(self):
        """ 退出player """
        self.logout()

    def send_msg(self, msg):
        """ 发送由pack_msg生成的消息 """
        if self._disable_send or self._rpc is None:
            return
        self._rpc.send(msg)

    def get_ip(self):
        if self._rpc is None:
            return
        return self._rpc.addr[0]

    def get_init_msg(self):
        """ 发送玩家初始化数据 """
        resp_f = 'init'
        CBE = {FN_P_ATTR_CBE:self.play_attr.CBE,
               FN_P_ATTR_CBES:self.play_attr.CBES}
        d = dict(player=self.to_dict(),
            roles=self.roles.to_dict(),
            ilist=self.bag.to_dict(),
            iwait=self.wait_bag.to_dict(),
            task=self.task.to_dict(),
            position=self.positions.to_dict(),
            cliAttr=self.play_attr.client_to_dict(),
            map=self.maps.to_dict(),
            mail=self.mail.to_dict(),
            buff=self.buffs.to_dict(),
            vip=self.vip_attr.to_dict(),
            CBE=CBE,
            #reward = self._game.reward_mgr2.reward_init_msg(self)
            )
        if self.ally:
            d['ally'] = self.ally
        return pack_msg(resp_f, 1, data=d)

    def base_load(self):
        """ 加载玩家数据 """
        self.play_attr.load()
        self.roles.load()
        self.bag.load()
        self.wait_bag.load()
        self.task.load()
        self.positions.load()
        self.maps.load()
        self.buffs.load()
        self.mail.load()
        self.vip.load()
        self.hron.load()
        self.achievement.load()
        self.vip_attr.load()
        self.ally = self._game.rpc_ally_mgr.to_dict(self.data.id)

    def load(self):
        """ 加载玩家数据 """
        self.base_load()
        self.sit.load()

    def load_p(self):
        """ 玩家不在线时，其他模块使用(如机器人) """
        self.base_load()


    def save(self, full=True):
        """ 保存玩家数据, """
        #未完成初章,初章的数据是特殊的保存会污染其它功能,需要调整
        if self.is_guide:
            self.data.level = 1
        self._game.rpc_store.save(TN_PLAYER, self.to_dict())
        if not full:
            return
        with self._save_lock:
            self.save_time = int(time.time())
            self.roles.save()
            self.bag.save()
            self.wait_bag.save()
            self.task.save()
            self.positions.save()
            self.maps.save()
            self.sit.save()
            self.buffs.save()
            self.mail.save()
            self.achievement.save()
            store = self._game.rpc_store
            self._runtimes_exec('save', lambda obj: obj.save(store))
            if not self.is_guide:
                self.property.update_CBE()
            #玩家属性应最后保存(别的模块有玩家属性点更新)
            log.debug('player(%s)_attr-save', self.data.name)
            self.play_attr.save()

    def clear_attr_car(self):
        """ 清楚玩家坐骑属性 """
        self.data.car = 0
        self.update_scene_info({IF_IDX_CAR:0})

    def clear(self, all=True, dels=tuple()):
        """ 清理玩家所有数据 """
        if dels:
            all = False
        if all or 'role' in dels:
            self.roles.clear()
        if all or 'bag' in dels:
            self.bag.clear()
        if all or 'wait_bag' in dels:
            self.wait_bag.clear()
        if all or 'task' in dels:
            self.task.clear()
        if all or 'positions' in dels:
            self.positions.clear()
        if all or 'play_attr' in dels:
            self.play_attr.clear()
        if all or 'maps' in dels:
            self.maps.clear()
        if all or 'buffs' in dels:
            self.buffs.clear()
        if all or 'mail' in dels:
            self.mail.clear()
        if all or 'deep' in dels:
            self._game.deep_mgr.clear(self)
        if all or 'achievement' in dels:
            self.achievement.clear()

    def update_state(self, state):
        """ 更新状态 """
        self.data.state = state
        self.update_scene_info({IF_IDX_STATE:state})

    def get_coin2(self, use_bind=1):
        """ 获取元宝数 """
        return self.data.coin2 + self.data.coin3 if use_bind else self.data.coin2

    def enough_coin(self, aCoin1, aCoin2=0, use_bind=True):
        """ 消耗的钱币是否够 """
        return 0 <= aCoin1 <= self.data.coin1 and \
                0 <= aCoin2 <= self.get_coin2(use_bind=use_bind)

    def enough_coin_ex(self, aCoin1, aCoin2=0, aCoin3=0):
        """ 消耗的钱币是否够 """
        if aCoin2 and aCoin3:
            return False
        use_bind = bool(aCoin3)
        yb = aCoin3 if use_bind else aCoin2
        return 0 <= aCoin1 <= self.data.coin1 and\
               0 <= yb <= self.get_coin2(use_bind=use_bind)

    def cost_coin_ex(self, aCoin1=0, aCoin2=0, aCoin3=0, log_type=None):
        """ 花费 """
        if aCoin2 and aCoin3:
            return False
        use_bind = bool(aCoin3)
        yb = aCoin3 if use_bind else aCoin2
        return self.cost_coin(aCoin1=aCoin1, aCoin2=yb, use_bind=use_bind, log_type=log_type)

    def cost_coin(self, aCoin1=0, aCoin2=0, use_bind=True, log_type=None):
        """ 花费钱币(aCoin1:银币,aCoin2:元宝, use_bind:是否使用绑定元宝 """
        if not self.enough_coin(aCoin1, aCoin2=aCoin2, use_bind=use_bind):
            return False
        c2, c3 = 0, 0
        if aCoin1:
            self.data.coin1 -= aCoin1
        if aCoin2:
            if use_bind:
                #先消耗绑定元宝再消耗元宝
                if self.data.coin3 < aCoin2:
                    c3 = self.data.coin3
                    c2 = aCoin2 - c3
                    self.data.coin2 -= c2
                    self.data.coin3 = 0
                else:
                    c3 = aCoin2
                    self.data.coin3 -= aCoin2
            else:
                c2 = aCoin2
                self.data.coin2 -= aCoin2
            self.safe_pub(MSG_COST_COIN3, aCoin2)
            self.save(full=False)
        if log_type:
            self.log_coin(log_type, aCoin1, c2, c3)
        return True

    def add_coin(self, aCoin1=0, aCoin2=0, aCoin3=0,
            is_set=False, vip=False, log_type=None):
        """ 添加钱币(银币\元宝\绑元宝) """
        if is_set:
            self.data.coin1 = aCoin1
            self.data.coin2 = aCoin2
            self.data.coin3 = aCoin3
            if vip:
                self.data.vipCoin = aCoin2
        else:
            if aCoin1:
                self.data.coin1 += aCoin1
            if aCoin2:
                self.data.coin2 += aCoin2
            if aCoin3:
                self.data.coin3 += aCoin3
            if vip:
                self.data.vipCoin += aCoin2
        if aCoin2 or aCoin3:
            self.save(full=False)
        if log_type:
            self.log_coin(log_type, aCoin1, aCoin2, aCoin3)
        return True

    def is_max_level(self, level=None):
        """ 是否达到最大等级 """
        if level is None:
            level = self.data.level
        return level >= self._game.setting_mgr.setdefault(PLAYER_LEVEL_MAX, 9999)

    def add_exp(self, aExp):
        """ 添加经验
            返回：0 失败 1 成功 2 升级
        """
        if aExp < 0:
            return 0
        tReturn = 1
        tNewExp = self.data.exp + aExp
        if self.is_max_level():
            tNextExpLevel = self._game.res_mgr.exps_by_level.get(self.data.level+1)
            if tNextExpLevel:
                if tNewExp < tNextExpLevel.exp:
                    self.data.exp = tNewExp
                else:
                    self.data.exp = tNextExpLevel.exp - 1
            return tReturn

        #进行升级级检查
        tNewLevel = self.data.level
        tNextLevel = self.data.level
        while True:
            tNextLevel += 1
            tNextExpLevel = self._game.res_mgr.exps_by_level.get(tNextLevel)
            if not tNextExpLevel:
                return 0
            if tNewExp >= tNextExpLevel.exp:
                #升一级
                tNewLevel += 1
                tNewExp -= tNextExpLevel.exp
                continue
            break
        if tNewLevel > self.data.level:
            self.data.exp = tNewExp
            self.upgrade(tNewLevel)
            tReturn = 2
        else:
            self.data.exp = tNewExp
        #self.save(full=False)
        return tReturn

    def upgrade(self, level, pub=True):
        """ 玩家升级 """
        if not self.is_guide and self.is_max_level(level-1):
            return
        old_lv = self.data.level
        self.data.level = level
        self.log_normal(PL_UPGRADE, lv=level)
        #升级主动推
        if self.logined:
            self.up_level()
        if pub:
            #跨等级升级,发送多次消息
            for lv in xrange(old_lv+1, level+1):
                self.pub(MSG_UPGRADE, lv)

    def up_level(self):
        """ 升级主动推给客户端 """
        resp_f = 'upLevel'
        self.send_msg(pack_msg(resp_f, 1, data={'player':self.data.to_dict()}))
        self.update_scene_info({IF_IDX_LEVEL:self.data.level})


    def add_site_time(self, site_time):
        """ 添加打坐时间经验 """
        site_exp = self._game.res_mgr.get_site_exp(self.data.level)
        return self.add_exp(int(site_exp * site_time))

    def add_train(self, aTrain, msg=1, log_type=None):
        """ 添加练历 """
        if aTrain <= 0:
            return
        old_train = self.data.train
        self.data.train += aTrain
        if old_train / 1000 != self.data.train / 1000:
            self.pub(MSG_TRAIN)
        if msg:
            self.pub(MSG_ADDTRAIN, aTrain)
        if log_type:
            self.log_train(log_type, aTrain)
        return True

    def cost_train(self, aTrain, log_type=None):
        """ 消耗练历 """
        if aTrain <= 0 or aTrain > self.data.train:
            return
        self.data.train -= aTrain
        if log_type:
            self.log_train(log_type, aTrain)
        #self.save(full=False)
        return True

    def pack_msg_data(self, coin=False, exp=False, train=False,
                     items=None, equips=None, fates=None, cars=None, roles=None,
                     waits=None, buffs=None, mails=None, gem=None,
                     del_iids=None, del_eids=None, del_fids=None, del_cids=None,
                     del_wids=None, del_bids=None, del_mids=None, del_gids=None, send=0):
        """ 打包物品更新结构 """
        data = self.data
        rs = dict()
        if coin:
            rs['coin1'] = data.coin1
            rs['coin2'] = data.coin2
            rs['coin3'] = data.coin3
        if exp:
            rs['exp'] = data.exp
        if train:
            rs['train'] = data.train
        if items:
            rs['item'] = [i.to_dict() for i in items]
        if equips:
            rs['equip'] = [i.to_dict() for i in equips]
        if fates:
            rs['fate'] = [i.to_dict() for i in fates]
        if gem:
            rs['gem'] = [i.to_dict() for i in gem]
        if cars:
            rs['car'] = [i.to_dict() for i in cars]
        if waits:
            rs['wait'] = [i.to_dict() for i in waits]
        if buffs:
            rs['buff'] = [i.to_dict() for i in buffs]
        if roles:
            rs['role'] = [i.to_dict() for i in roles]
        if mails:
            rs['mail'] = [i.to_dict() for i in mails]
        if del_iids:
            rs['delIids'] = tuple(del_iids)
        if del_eids:
            rs['delEids'] = tuple(del_eids)
        if del_fids:
            rs['delFids'] = tuple(del_fids)
        if del_cids:
            rs['delCids'] = tuple(del_cids)
        if del_wids:
            rs['delWids'] = tuple(del_wids)
        if del_bids:
            rs['delBids'] = tuple(del_bids)
        if del_mids:
            rs['delMids'] = tuple(del_mids)
        if del_gids:
            rs['delGids'] = tuple(del_gids)
        if send:
            self.send_msg(pack_msg('update', 1, data=rs))
        return rs

    def send_update_msg(self, msg_data, rs=1):
        if rs:
            self.send_msg(pack_msg('update', rs, data=msg_data))
        else:
            self.send_msg(pack_msg('update', rs, err=msg_data))

    def init_all_runtimes(self):
        """初始化所有动态模块"""
        self._game.bftask_mgr.init_player_bftask(self)
        self._game.deep_mgr.init_player(self)
        self._game.fete_mgr.init_player_fete(self)
        self._game.fish_mgr.init_player(self)
        self._game.ctree_mgr.bind_player(self)
        self._game.hfate_mgr.init_player_hitfate(self)
        self._game.mining_mgr.init_player(self)
        self._game.reward_mgr2.init_player(self)
        self._game.shop_mgr.init_player_shop(self)
        self._game.social_mgr.init_player(self)
        self._game.tbox_mgr.init_player_tbox(self)

    def copy_from(self, player):
        pid, uid, name = self.data.id, self.data.uid, self.data.name
        self.data.copy_from(player.data)
        self.data.update(dict(id=pid, uid=uid, name=name))

        items = self.bag.copy_from(player.bag)
        self.roles.copy_from(player.roles, items)
        self.play_attr.copy_from(player.play_attr)
        witems = self.wait_bag.copy_from(player.wait_bag)
        self.task.copy_from(player.task)
        self.positions.copy_from(player.positions, player.data.posId)
        self.maps.copy_from(player.maps)
        self.sit.copy_from(player.sit)
        self.buffs.copy_from(player.buffs)
        self.mail.copy_from(player.mail, witems)
        self.vip.copy_from(player.vip)
        self.achievement.copy_from(player.achievement)

        #拷贝动态模块
        self.init_all_runtimes()
        player.init_all_runtimes()
        self._runtimes_exec('copy_from', lambda obj: obj.copy_from(player))

    def copy_player(self, pid):
        """ 完全复制玩家数据 """
        p = self.load_player(pid)
        if not p:
            return 0
        self.copy_from(p)
        return 1

    def look(self):
        """ 返回查看,战斗用信息 """
        CBE = {FN_P_ATTR_CBE:self.play_attr.CBE,
               FN_P_ATTR_CBES:self.play_attr.CBES}
        info = dict(player=self.data.to_dict(),
            roles=self.roles.to_dict(used=1),
            ilist=self.bag.to_dict(used=1),
            position=self.positions.to_dict(used=1),
            CBE=CBE,
        )
        return info

    def team_look(self, rids):
        """返回组队战斗用信息"""
        CBE = {FN_P_ATTR_CBE:self.play_attr.CBE,
               FN_P_ATTR_CBES:self.play_attr.CBES}
        roles = self.roles.roles_to_dict(rids)
        ilist = self.roles.roles_bag_to_dict(rids)
        info = dict(player=self.data.to_dict(),
            roles=roles,
            ilist=ilist,
            CBE=CBE,
        )
        return info

    def fight_win(self, fid):
        """主线战斗胜利"""
        fid = int(fid)
        if fid in self.win_fights:
            return
        rid = self._game.res_mgr.get_fight_rid(fid)
        if not rid:
            return
        rw = self._game.reward_mgr.get(rid)
        if rw is None:
            return
        items = rw.reward(params=self.reward_params())
        if items is None:
            return
        if self.bag.can_add_items(items):
            self.set_win_fight(fid)
            bag_items = self.bag.add_items(items, log_type=COIN_ADD_FIGHT_WIN)
            return bag_items.pack_msg(coin = True)

    def set_win_fight(self, fid):
        self.win_fights.insert(fid)
        self.play_attr.set(PLAYER_ATTR_WIN_FIGHTS,
                self.win_fights.to_base64())

    def load_win_fight(self):
        win_fights = self.play_attr.attr.get(PLAYER_ATTR_WIN_FIGHTS)
        if win_fights:
            self.win_fights.from_base64(win_fights)

    def get_main_role_eid(self):
        """获取主将装备（用于组队战斗显示）"""
        rid = self.data.rid
        role = self.roles.get_role_by_rid(rid)
        return rid, role.body_equip_id

    def get_ally_tbox_data(self):
        return self.play_attr.get(FN_P_ATTR_ALLYTBOX, dict(bids = [], t = 0, cr=0))

    def set_ally_tbox_data(self, data):
        self.play_attr.set(FN_P_ATTR_ALLYTBOX, data)

    def gm_finish_achi(self, t, aid):
        self.achievement.gm_finish(t, aid)
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
