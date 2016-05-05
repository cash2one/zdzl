#!/usr/bin/env python
# -*- coding:utf-8 -*-
import random
import time
import datetime
import urllib, json

from grpc import DictExport, DictItemProxy, wrap_pickle_result, get_proxy_by_addr


from corelib import tools
from corelib import (log, new_stream_server, new_stream_server_by_ports,
                     sleep, spawn, spawn_later, spawns, RLock, client_rpc)
from corelib.message import observable
from corelib.memory_cache import TimeMemCache

from game import BaseGameMgr, Game, prepare_send, pack_msg, ClientRpc, grpc_monitor, get_obj
from game.base import errcode, constant
from game.base.msg_define import MSG_INIT, MSG_LOGON, MSG_LOGONED, MSG_LOGOUT
from game.base.common import uuid
from game.store.define import FN_P_ATTR_CBE, GF_AREA_URLS, FOP_IN
from game.glog.common import PM_MAC

from game.player.player import User, UserData, PlayerData, Player

from game.store import TN_USER, TN_PLAYER, FN_ID, FN_NAME
from webapi import SNSClient, SNS_LOGINS, SNS_NONE, SNS_EQUALS
from game.base.constant import STATUS_DEBUG_FT

import config
import language



def wrap_distribute(func):
    def _func(self, *args, **kw):
        f = getattr(func, 'im_func', func)
        return self.distribute(f.func_name, *args, **kw)
    return _func

def wrap_wait4init(func):
    def _func(self, *args, **kw):
        while not Game.inited:
            sleep(0.5)
            if Game.inited:
                break
        return func(self, *args, **kw)
    return _func

def _get_level(player):
    return player.data.level
def _get_level_CBE(player):
    return player.data.level, player.play_attr.get(FN_P_ATTR_CBE)
def _get_dict(player):
    return player.to_dict()

@observable
class GPlayerMgr(object):
    """ 联合进程使用的总角色管理类 """
    _rpc_name_ = 'rpc_player_mgr'
    _rpc_attr_pre = 'rc_'
    TIME_OUT = 0.1
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        self.max_players = config.max_players
        self.logic_players = config.logic_players
        self._users = {}
        self._players = {}
        self._sub_mgrs = {}
        self.mgr2addrs = {}
        self.logons = TimeMemCache(size=10000, default_timeout=2, name='rpc_player_mgr.logons')
#        self.names = TimeMemCache(size=10000, default_timeout=1*30) #缓存保证不重名
        self.name2pids = {}
        self.pid2names = {}
        self._name_lock = RLock()
        self._new_player_lock = RLock()
        self.names4ad = {}
        self.overload_time = 0
        self._debug_ips = None
        self._debug_status = False
        self._area_url = None
        self._area_legal = None
        import app
        from game.base import msg_define
        app.sub(msg_define.MSG_START, self.start)

    def start(self):
        self._svr = new_stream_server(config.player_addr,
                                      self._on_client_accept)
        self.sns_client = SNSClient(*config.logon_url)
        from game.base.msg_define import MSG_RES_RELOAD
        Game.res_mgr.sub(MSG_RES_RELOAD, self.load)
        Game.mail_mgr.start_expire_mail()
        self.load()

    def load(self):
        self._area_url = None
        self._area_legal = None
        op_lis = Game.rpc_status_mgr.get_config(GF_AREA_URLS)
        if not op_lis:
            return
        self._area_url = tuple(op_lis[:3])
        self._area_legal = op_lis[-1]

        data = Game.rpc_status_mgr.get(constant.STATUS_DEBUG_FT)
        if data:
            self._debug_ips = data['ip'].split(",")
            self._debug_status = bool(data['status'])

    def _on_client_accept(self, sock, addr):
        """ 处理玩家登陆请求 """
        log.debug(u'client发起连接(%s)', addr)
        _rpc = ClientRpc(sock, addr, self)
        _rpc.call_link_rpc = True
        _rpc.start()
        sleep(120)
        _rpc.stop()#该链接只用于登录接口,之后断开

    def on_close(self, rpcobj):
        pass

    def reg_sub_mgr(self, rpc_sub_mgr, sub_name, addr, _proxy=True):
        log.info('reg_player_mgr:%s', sub_name)
        self._sub_mgrs[sub_name] = [rpc_sub_mgr, set()]
        self.mgr2addrs[sub_name] = addr
        return sub_name

    def unreg_sub_mgr(self, sub_mgr_id, _no_result=True):
        log.info('unreg_player_mgr:%s', sub_mgr_id)
        self._sub_mgrs.pop(sub_mgr_id, None)
        self.mgr2addrs.pop(sub_mgr_id, None)

    def get_sub_mgr(self, pid):
        """ 获取玩家所在进程的player_mgr对象 """
        mid = self._players.get(pid)
        if not mid:
            return 0, None
        sub_mgr_ids = self._sub_mgrs.get(mid)
        if not sub_mgr_ids:
            return 0, None
        return mid, sub_mgr_ids[0]

    @wrap_pickle_result
    def get_sub_game(self, pid):
        """ 获取玩家所在进程的game对象 """
        mid, sub_mgr = self.get_sub_mgr(pid)
        if not mid:
            return
        addr = self.mgr2addrs.get(mid)
        return get_obj(addr, 'game')


    @grpc_monitor
    def pre_add(self, pid, uid):
        """ 玩家预备登陆,为防止重复,先踢在线的玩家 """
        old_mid, sub_mgr = self.get_sub_mgr(pid)
        if sub_mgr:
            sub_mgr.del_player_by_id(pid)
            self.delete(old_mid, pid, uid)
            return 1
        if not uid in self._users:
            return 1
        mid, _ = self._users[uid]
        sub_mgr = self._sub_mgrs[mid]
        sub_mgr[0].del_user_by_id(uid)
        return 1

    @grpc_monitor
    def add(self, mid, pid, name, rid, uid):
        """ 玩家登陆,防止在短时间内重复登录 """
        self._add_name_id(pid, name, rid)
        if self.logons.get(pid):
            log.info(u'禁止玩家(%s-%s)短时登录', pid, name)
            return False
        self.logons.set(pid, 1)
        self._users[uid] = mid, pid
        self._players[pid] = mid
        self._sub_mgrs[mid][1].add(pid)
        self.safe_pub(MSG_LOGON, pid)
        return True

    @grpc_monitor
    def delete(self, mid, pid, uid):
        """ sub_mgr调用,通知玩家退出 """
        self._users.pop(uid, None)
        self._players.pop(pid, None)
        if mid in self._sub_mgrs:
            pids = self._sub_mgrs[mid][1]
            if pid in pids:
                pids.remove(pid)
        self.safe_pub(MSG_LOGOUT, pid)

    @property
    def count(self):
        return len(self._players)

    def get_count(self):
        return self.count

    def have(self, pid):
        return pid in self._players

    def _add_name_id(self, pid, name, rid):
        if pid in self.pid2names:
            return
        self.name2pids[name] = pid
        self.pid2names[pid] = (name, rid)

    def change_name(self, pid, name, rid):
        """
        改名
        """
        if pid not in self.pid2names:
            return False, errcode.EC_VALUE
        self.del_player(pid)
        self.name2pids[name] = pid
        self.pid2names[pid] = (name, rid)
        return True, None

#    def valid_name(self, name):
#        """ 检查角色名是否没重复,可以用来新建角色 """
#        with self._name_lock:
#            pid = self.names.get(name)
#            if pid is not None:
#                return False
#            rs = Game.rpc_store.values(TN_PLAYER, ['name'], dict(name=name))
#            if rs:
#                pid = rs[0]['id']
#                self.names.set(name, pid)
#                return False
#            self.names.set(name, 0)
#            return True

    def get_id_by_name(self, name):
        """ 根据名称获取对应玩家id """
        try:
            return self.name2pids[name]
        except KeyError:
            pid_rid = PlayerData.name_to_id(name)
            if pid_rid is None:
                return
            self._add_name_id(pid_rid[0], name, pid_rid[1])
            return pid_rid[0]

    def get_name_by_id(self, pid, rid=0):
        """ 查询pid,
        rid: 1 一起查询主配将id
        return:
           name,
           name, rid
        """
        try:
            if rid:
                return self.pid2names[pid]
            return self.pid2names[pid][0]
        except KeyError:
            name_rid = PlayerData.id_to_name(pid)
            if name_rid is None:
                return
            self._add_name_id(pid, name_rid[0], name_rid[1])
            if rid:
                return name_rid
            return name_rid[0]

    def get_names(self, ids):
        """ 获取玩家名列表 """
        rs = {}
        for i in ids:
            n = self.get_name_by_id(i)
            if n is None:
                continue
            rs[i] = n
        return rs

    def get_name_rids(self, ids):
        """ 获取玩家名rid列表 """
        rs = {}
        for i in ids:
            n = self.get_name_by_id(i, rid=1)
            if n is None:
                continue
            rs[i] = n
        return rs

    def get_player_infos(self, pids, CBE=0):
        """ 获取玩家信息
        返回: onlines, {pid:(name, rid, level, CBE)}
        """
        onlines = self.get_online_ids(pids)
        rs = {}
        #等级
        if CBE:
            levels = self.exec_players_func(onlines, _get_level_CBE, has_result=1, _pickle=True)
        else:
            levels = self.exec_players_func(onlines, _get_level, has_result=1, _pickle=True)
        off_ids = set(pids).difference(levels.keys())
        if off_ids:
            off_lvs = PlayerData.get_players_levels(off_ids, CBE=CBE)
            if off_lvs:
                levels.update(off_lvs)

        for pid in pids:
            n_rid = self.get_name_by_id(pid, rid=1)
            if not n_rid:
                continue
            if CBE:
                lv, cbe = levels.get(pid, (1, 0))
                rs[pid] = (n_rid[0], n_rid[1], lv, cbe)
            else:
                rs[pid] = (n_rid[0], n_rid[1], levels.get(pid, 1))
        return onlines, rs

    def get_pids_by_level(self, level, start_chapter=False):
        """ 获取大于等于指定等级的所有在线pid """
        all_pids = []
        for sub_mgr in self._sub_mgrs.itervalues():
            player_mgr = sub_mgr[0]
            pids = player_mgr.get_partpids_by_level(level, start_chapter)
            all_pids.extend(pids)
        return all_pids

    def get_player_detail(self, pids, cols):
        """ 返回玩家详细信息 """
        return PlayerData.get_players_values(pids, cols)

    def get_user_detail_by_playername(self, name, *argv, **kw):
        """ 返回玩家详细信息 """
        return PlayerData.userinfo_from_name(name, *argv, **kw)



    @grpc_monitor
    def get_onlines(self, start, end, name=0, rid=0):
        """ 返回在线玩家列表,
        返回 根据传入的参数:
            默认: [pid, ....]
            name=1: [(pid, name), ....]
            rid=1: [(pid, name, rid), ...]
            level=1: [(pid, name, rid, level), ...]
        """
        rs = []
        for index, pid in enumerate(self._players.iterkeys()):
            if index < start:
                continue
            if index >= end:
                break
            if name or rid:
                n_rid = self.get_name_by_id(pid, rid=1)
            if rid:
                rs.append((pid, n_rid[0], n_rid[1]))
            elif name:
                rs.append((pid, n_rid[0]))
            else:
                rs.append(pid)
        return rs

    @grpc_monitor
    def get_online_ids(self, pids=None, random_num=None):
        """ 返回在线的玩家id列表,
        pids: 查询的玩家列表,返回在线的ids
        random:整形, 随机选择random个pid返回
        """
        if random_num is not None:
            if len(self._players) <= random_num:
                return self._players.keys()
            return random.sample(self._players, random_num)
        if not pids:
            return self._players.keys()
        return [pid for pid in pids if pid in self._players]

    @grpc_monitor
    def new_player(self, uid, name, rid):
        """ 创建玩家对象,防止重名 """
        with self._new_player_lock:
            if self.get_id_by_name(name) is not None:
                return
            pid, data = PlayerData.new_player(uid, name, rid)
            self._add_name_id(pid, name, rid)
            return data

    def del_player(self, pid):
        name = self.pid2names.pop(pid, None)
        self.name2pids.pop(name, None)

    def _new_user(self, t, user, pwd, UDID, DT, MAC, DEV, VER):
        u = dict(sns=t, name=user, pwd=pwd, UDID=UDID, DT=DT,
                MAC=MAC, DEV=DEV, VER=VER,
                tNew=int(time.time()))
        u = User(adict=u)
        u.save(Game.rpc_store)
        return u

    def _get_login_params(self, user, uid, sns_type=0):
        """ 选择一个逻辑进程,返回登录用参数 """
        if uid in self._users:#重复登陆
            mid, pid = self._users.get(uid)
            self.pre_add(pid, uid)
            self._users.pop(uid, None)

        key = uuid()
        rs, address = self._login_sub(user, uid, key, sns_type)
        return dict(uid=uid, key=key, time=int(time.time()),
            ip=address[0], port=address[1])

    @wrap_wait4init
    @grpc_monitor
    def rc_login(self, user, pwd, UDID, DT, MAC='', DEV='', VER='', **kw):
        """ 用户登录请求 """
        log.debug(u'收到用户登录请求:%s, %s, %s, %s, %s, %s, %s, %s',
                user, pwd, UDID, DT, MAC, DEV, VER, kw)
        resp_f = 'login'
        if self.count >= self.max_players:
            return pack_msg(resp_f, 0, err=language.STR_PLAYER_3)

        if not user:#游客登录
            u = Game.rpc_store.query_loads(TN_USER, dict(UDID=UDID, name=''))
        else:
            #检查user,pwd是否正确,返回uid
            u = Game.rpc_store.query_loads(TN_USER, dict(name=user))
        if not u:
            #不存在自动增加
            u = self._new_user(SNS_NONE, user, pwd, UDID, DT,
                    MAC, DEV, VER)
        else:
            u = u[0]
            u = User(adict=u)
        if u.data.pwd != pwd:
            return pack_msg(resp_f, 0, err=language.LOGIN_PWD_ERROR)
        params = self._get_login_params(user, u.data.id)
        return pack_msg(resp_f, 1, data=params)

    def bindSNS(self, uid, t, sid, session):
        """ 绑定平台账号 """
        rs, data = self.sns_client.login(t, sid, session)
        if not rs:
            return 0, data
        u = Game.rpc_store.load(TN_USER, uid)
        if not u:
            return 0, errcode.EC_NOFOUND
        Game.rpc_store.update(TN_USER, uid, dict(name=sid))
        return 1, None

    def area_legal(self):
        """登陆时区域是不是合法"""
        if not self._area_url or not self._area_legal:
            #未配置则所有人合法登陆
            return True
        rpc = client_rpc.get_cur_rpc()
        data = urllib.urlencode({'ip':rpc.addr[0], 'check':str(0)})
        host, port, url = self._area_url
        try:
            area = tools.http_post_ex(host, port, url, params=data, timeout=GPlayerMgr.TIME_OUT)
            area = json.loads(area)
            country = area['country']
            log.debug('area_legal:%s in %s', rpc.addr[0], country)
            return not country or country in self._area_legal
        except BaseException as e:
            log.warn("area_legal error:%s", e)
            return True

    def is_debug_time(self):
        """
        测试期间只允许特定IP登陆
        """
        if not self._debug_status or not self._debug_ips:
            return True
        rpc = client_rpc.get_cur_rpc()
        ip = rpc.addr[0]
        if ip in self._debug_ips:
            return True
        log.info('during debug time in_ip:%s forbid :%s', self._debug_ips, ip)
        return False

    @wrap_wait4init
    @grpc_monitor
    def rc_loginSNS(self, t, sid, session, UDID, DT,
            MAC='', DEV='', VER='', **kw):
        """ 平台登录接口 """
        resp_f = 'loginSNS'
        if not self.area_legal():
            return pack_msg(resp_f, 0, err=errcode.EC_LOGIN_AREA_ERR)
        if not self.is_debug_time():
            return pack_msg(resp_f, 0, err=errcode.EC_LOGIN_DEBUG_TIME)

        log.debug(u'平台(%s)用户登录请求:%s, %s, %s, %s, %s, %s, %s, %s',
                t, sid, session, UDID, DT, MAC, DEV, VER, kw)
        if self.count >= self.max_players:
            return pack_msg(resp_f, 0, err=errcode.EC_TEAM_ROLE_FULL)

        if not sid and t not in SNS_LOGINS:#游客登录
            return pack_msg(resp_f, 0, err=errcode.EC_VALUE)
            #u = Game.rpc_store.query_loads(TN_USER, dict(UDID=UDID, name=''))
        else:
            rs, data = self.sns_client.login(t, sid, session)
            if not rs:
                return pack_msg(resp_f, 0, err=data)
            if data:#login返回sid
                sid = data
            u = UserData.user_by_sns(t, sid)
        if not u:
            #不存在自动增加
            u = self._new_user(t, sid, '', UDID, DT, MAC, DEV, VER)
        else:
            u = u[0]
            u = User(adict=u)
            #如果mac地址不同,记录
            if u.data.UDID != UDID or u.data.DT != DT or \
                u.data.DEV != DEV or \
                u.data.MAC != MAC or u.data.VER != VER:
                def _log_mac():
                    if 1: #强制保存更新信息, not u.data.MAC:
                        u.data.UDID = UDID
                        u.data.DT = DT
                        u.data.MAC = MAC
                        u.data.DEV = DEV
                        u.data.VER = VER
                        u.save(Game.rpc_store)
                    else:
                        self.glog(PM_MAC, u=u.data.id,
                                UDID=UDID, MAC=MAC, DEV=DEV, VER=VER)
                spawn(_log_mac)

        params = self._get_login_params(sid, u.data.id, t)
        log.debug(u'loginSNS finish:%s', params)
        return pack_msg(resp_f, 1, data=params)


    def glog(self, type, **kw):
        kw['t'] = type
        Game.glog.log(kw)


    def _login_sub(self, user_name, uid, key, sns_type):
        """ 选取subgame """
        sub_ids = None
        while not sub_ids:
            sub_ids = self._sub_mgrs.keys()
            if sub_ids:
                break
            log.info('_login_sub wait game init')
            sleep(1)

        sub_ids.sort()
        for sub_mgr_id in sub_ids:
            mgr, pids = self._sub_mgrs[sub_mgr_id]
            if len(pids) < self.logic_players:
                rs, address = mgr.logon(user_name, uid, key, sns_type)
                return rs, address
        #如果全部都满人，随机选择
        sub_id = random.choice(sub_ids)
        mgr, count = self._sub_mgrs[sub_id]
        rs, address = mgr.logon(user_name, uid, key, sns_type)
        return rs, address

    @grpc_monitor
    def distribute(self, func_name, pids, *args, **kw):
        """ 分发方法调用到各个自进程:
         func_name: SubPlayerMgr中的方法名
         pids: 玩家id列表, pids=None广播所有玩家
        """
        if pids is not None:
            pids = set(pids)
        for mid, (mgr, mids) in self._sub_mgrs.items():
            if not mids:
                continue
            if pids is None:
                mpids = None
            else:
                mpids = list(pids.intersection(mids))
            func = getattr(mgr, func_name)
            try:
                func(mpids, *args, **kw)
            except Exception as err:
                log.log_except('distribute error:%s(%s, %s)', func_name, args, kw)

    @wrap_distribute
    def player_mails(self, pids, mids, _no_result=True):
        """ 玩家收到新的邮件 """

    @wrap_distribute
    def player_send_msg(self, pids, msg, _no_result=True):
        """
        广播消息给玩家
        pids:None 时广播所有在线玩家
       """

    @wrap_pickle_result
    def get_rpc_player(self, pid):
        mid, sub_mgr = self.get_sub_mgr(pid)
        if not mid:
            return
        addr = self.mgr2addrs.get(mid)
        proxy = SubPlayerMgr.cls_get_player_proxy(pid, addr=addr, local=0)
        return proxy

    @wrap_pickle_result
    @grpc_monitor
    def get_rpc_players(self, pids):
        """ 获取rpc_player列表,用于少量玩家操作 """
        rs = []
        for pid in pids:
            proxy = self.get_rpc_player(pid)
            if proxy:
                rs.append(proxy)
        return rs

    @grpc_monitor
    def exec_players_func(self, pids, func, has_result=False, _pickle=True):
        """ 在玩家所在的逻辑进程执行方法,用于一般的玩家操作
        func: 定义: def func(player)
        """
        pids = set(pids)
        rs = {}
        for mid, (mgr, mids) in self._sub_mgrs.iteritems():
            mpids = pids.intersection(mids)
            if not mpids:
                continue
            mpids = tuple(mpids)
            if has_result:
                sub_rs = mgr.exec_players_func(mpids, func, _pickle=True)
                rs.update(sub_rs)
            else:
                mgr.exec_players_func(mpids, func, _pickle=True, _no_result=True)
        return rs

    def overload(self, m):
        """ 启动压力测试m分钟 """
        self.overload_time = time.time() + m * 60
        log.warn('overload start to %s',
                datetime.datetime.fromtimestamp(self.overload_time))

    def is_overload(self):
        """ 是否处于压力测试状态 """
        return time.time() < self.overload_time


    def set_debug_data(self, ips, status):
        """
        设置测试的数据
        """
        self._debug_ips = ips
        self._debug_status = bool(status)
        self._players.keys()
        #状态开启了
        if not self._debug_status:
            return
        pids = self.get_online_ids()
        for pid in pids:
            rpc = self.get_rpc_player(pid)
            if rpc and rpc.get_ip() not in self._debug_ips:
                rpc.debug_kick()


def new_player_mgr():
    mgr = GPlayerMgr()
    #mgr.start()
    return mgr

@observable
class SubPlayerMgr(BaseGameMgr, DictExport):
    """ 逻辑进程使用的角色管理类 """
    _rpc_name_ = 'player_mgr'
    #定时保存时间 5分钟
    _SAVE_TIME_ = 60 * 5
    def __init__(self, game):
        BaseGameMgr.__init__(self, game)
        self._svr = None
        self._keys = TimeMemCache(size=1000, default_timeout=5*60, name='player_mgr._keys')
        self.users = {}
        self.players = {}
        self.others = TimeMemCache(size=1000, default_timeout=(self._SAVE_TIME_-1), name='player_mgr.others')
        self._game.reg_obj(self)
        self._loop_task = None

    def _rpc_mgr_init(self, rpc_mgr):
        if not self._game:
            return
        self.key = rpc_mgr.reg_sub_mgr(self, self._game.name,
                self._game.get_addr(), _proxy=True)

    def start(self):
        self._svr = new_stream_server_by_ports('0.0.0.0',
                                               config.player_ports,
                                               self._on_client_accept)
        self.address = config.inet_ip, self._svr.address[1]
        self.key = Game.rpc_player_mgr.reg_sub_mgr(self, self._game.name,
            self._game.get_addr(), _proxy=True)
        Game.sub_rpc_mgr_init(Game.rpc_player_mgr, self._rpc_mgr_init)
        self._loop_task = spawn(self._loop)

    def stop(self):
        if not BaseGameMgr.stop(self):
            return
        if self._svr:
            self._svr.stop()
            self._svr = None
        if self._loop_task:
            self._loop_task.kill(block=False)
            self._loop_task= None
        spawns(lambda u: u.logout(),
               [(u,) for u in self.users.itervalues()])
        if not Game.parent_stoped:
            Game.rpc_player_mgr.unreg_sub_mgr(self.key, _no_result=True)

    def _on_client_accept(self, sock, addr):
        log.debug(u'client发起连接(%s)', addr)
        user = User()
        user.start(self, sock, addr)
        user.wait_for_init()

    def _loop(self):
        """ 定时保存等处理 """
        stime = 30
        while 1:
            sleep(stime)
            try:
                for pid in self.players.keys():
                    p = self.players.get(pid)
                    if p is None or not p.logined:
                        continue
                    #是否需要定时保存
                    if p.save_time + self._SAVE_TIME_ <= time.time():
                        p.save()
            except:
                log.log_except()


    @property
    def global_count(self):
        """ 全服在线玩家总数 """
        return Game.rpc_player_mgr.get_count()

    @property
    def count(self):
        return len(self.users)

    @classmethod
    def cls_get_player_proxy(cls, pid, addr=None, local=1):
        if addr is None:
            addr = Game.get_addr()
        if local:
            proxy = DictItemProxy(cls._rpc_name_, dict_name='players',
                    key=pid, addr=addr)
        else:
            proxy = get_proxy_by_addr(addr, cls._rpc_name_, DictItemProxy)
            proxy.dict_name = 'players'
            proxy.key = pid
        return proxy

    def get_player_proxy(self, pid, check=True):
        if check and pid not in self.players:
            raise ValueError('player id(%d) not in player_mgr' % pid)
        return self.cls_get_player_proxy(pid)

    def logon(self, user_name, uid, key, sns_type):
        """ logon服务器发来的用户登录请求 """
        if self._game.stoped:
            return False, ''
        #log.debug('subPlayerMgr.logon:%s, %s, %s', user_name, uid, key)
        self._keys.set(uid, (uid, key, sns_type))
        return True, self.address

    def check_logon(self, uid, key):
        """ 检查角色登录情况,
        返回: 成功(uid, sns_type)
            失败(False, 0)
        """
        v = self._keys.delete(uid)
        #log.debug('subPlayerMgr.check_logon:%s, %s', user_name, v)
        if v is not None and v[1] == key:
            return v[0], v[2]
        return False, 0

    def add_user(self, user):
        self.users[user.data.id] = user

    def del_user(self, user):
        return self.users.pop(user.data.id, None)

    def del_user_by_id(self, uid):
        """ 全局管理器调用，强制玩家退出 """
        user = self.users.get(uid)
        if not user:
            return
        user.logout()

    def add_player(self, player):
        """ 玩家进入游戏 """
        pid = player.data.id
        rs = Game.rpc_player_mgr.add(self.key, pid, player.data.name, player.data.rid, player.data.uid)
        if not rs:
            return False
        self.players[pid] = player
        log.debug('sub_player_mgr.add_player:%s', pid)
        return True

    def logon_player(self, player):
        self.safe_pub(MSG_LOGON, player)

    def logoned_player(self, player):
        """ 已经发送初始化数据给前端,触发已登陆消息,其他模块可以正常发消息给前端 """
        self.safe_pub(MSG_LOGONED, player)

    def del_player(self, player):
        """ 玩家退出 """
        pid = player.data.id
        if pid not in self.players:
            return
        log.debug('sub_player_mgr.del_player:%s', pid)
        assert self.players[pid] == player, 'player != p'
        self.players.pop(pid)
        Game.rpc_player_mgr.delete(self.key, pid, player.data.uid)
        self.safe_pub(MSG_LOGOUT, player)

    def del_player_by_id(self, pid):
        """ 玩家退出,由全局管理器调用 """
        player = self.players.get(pid)
        if player is None:
            return
        player.user.logout()

    def get_player(self, pid):
        return self.players.get(pid)

    def send_msg_to_all(self, msg):
        data = prepare_send(msg)
        for user in self.users.itervalues():
            user.send_msg(data)

    def iter_players(self, pids):
        if pids is None:
            pids = self.players.keys()
        for pid in pids:
            p = self.players.get(pid)
            if p is None:
                continue
            yield pid, p

    def player_mails(self, pids, mids):
        """ 玩家接受邮件 """
        for pid, p in self.iter_players(pids):
            mid = mids.get(pid)
            if not mid:
                continue
            try:
                p.mail.recv_mails(mid)
            except:
                log.log_except()

    def get_partpids_by_level(self, level, start_chapter=False):
        """ 获取大于等于指定等级的所有玩家 start_chapter 是否包括初章"""
        pids = []
        for pid, player in self.iter_players(None):
            if player.data.level >= level:
                if start_chapter and player.data.chapter == constant.CHATER_START:
                    continue
                pids.append(pid)
        return pids

    def player_send_msg(self, pids, msg):
        data = prepare_send(msg)
        for pid, p in self.iter_players(pids):
            p.send_msg(data)

    def exec_players_func(self, pids, func, _pickle=True):
        """ 在玩家所在的逻辑进程执行方法,用于一般的玩家操作 """
        rs = {}
        for pid, p in self.iter_players(pids):
            try:
                rs[pid] = func(p)
            except Exception:
                log.log_except()
        return rs

    def look(self, pid):
        """ 查看其它玩家信息 """
        return self._get_other(pid)

    def _get_other(self, pid, cache=1):
        """ 获取其它玩家信息 """
        if cache:
            v = self.others.get(pid)
            if v is not None:
                return v
        p = self.get_player(pid)
        if not p:
            p = self._game.rpc_player_mgr.get_rpc_player(pid)
        if not p:#不在线
            p = Player.load_player(pid)
#            p = OtherPlayer.new(pid)
        if not p:
            v = 0, errcode.EC_NOFOUND
        else:
            #先计算出战斗力
            p.init()
            v = 1, p.look()
        self.others.set(pid, v)
        return v

#class OtherPlayer(object):
#    """ 其它玩家信息 """
#    @classmethod
#    def new(cls, pid):
#        p = cls(pid)
#        if p.exist():
#            return p
#
#    def __init__(self, pid):
#        from .bag import Bag
#        from .role import PlayerRoles
#        from .position import PlayerPositions
#        self._game = Game
#        player_data = PlayerData.load(pid)
#        self.data = PlayerData(adict=player_data)
#        if not self.exist():
#            return
#        #物品列表
#        self.bag = Bag(self)
#        #配将
#        self.roles = PlayerRoles(self)
#        #玩家阵型
#        self.positions = PlayerPositions(self)
#        self.load()
#
#    def exist(self):
#        return self.data.id is not None
#
#    def load(self):
#        self.bag.load_used()
#        self.roles.load_used()
#        self.positions.load_used()
#        self.ally = self._game.rpc_ally_mgr.to_dict(self.data.id)
#
#    def look(self):
#        """ 返回信息 """
#        info = dict(player=self.data.to_dict(),
#            roles=self.roles.to_dict(),
#            ilist=self.bag.to_dict(),
#            position=self.positions.to_dict(),
#        )
#        return info


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
