#!/usr/bin/env python
# -*- coding:utf-8 -*-
import datetime
import time

from corelib import spawn, sleep, log
from game import pack_msg, Game, prepare_send
from game.base import errcode
from game.glog.common import ITEM_COST_HORN
from game.base.constant import HORN_COST_ID, HORN_COST_ID_V#, HORN_TYPE_PLAYER
from game.base.constant import NOTIFY_APNS
from game.base.msg_define import MSG_START
from webapi.notify import NotifyServer
from game.base.constant import HORN_TYPE_SYS_HORN, HORN_TYPE_PLAYER_HORN
from game.base.constant import HORN_TYPE_WORLD, HORN_TYPE_SYS, HORN_TYPE_ALLY, HORN_TYPE_SECRET

import config

#chat_type: 1=世界, 2=系统, 3=大喇叭, 4=同盟, 5=密语
CT_WORLD = 1
CT_SYS = 2
CT_SPEAK = 3
CT_ALLY = 4
CT_TALK = 5

IDT_ALL = -1

class ChatMgr(object):
    """ 聊天管理类 """
    BROADCAST_TIMES = 0.5 #广播消息间隔

    def __init__(self):
        self.msgs = []
        self.all_ids = set()

    def start(self):
        spawn(self._loop)
#        spawn(self._sys_test)

    def _sys_test(self):
        """ 发送测试用系统消息 """
        if not Game.instance:
            return
        while 1:
            sleep(10)
            self.sys_send(u'测试用系统消息(%s)\n' % datetime.datetime.now())# * 9999)

    def _loop(self):
        import app
        game = Game.instance
        while not app.stoped:
            sleep(self.BROADCAST_TIMES)
            if game and not game.stoped:
                self.all_ids = set(game.player_mgr.players.keys())
            try:
                self.broadcast()
            except:
                log.log_except()

    def broadcast(self):
        """ 广播多个聊天信息,
        """
        if not self.msgs:
            return
        #log.debug('broadcast:%s', self.msgs)
        msgs = self.msgs
        self.msgs = []
        for game in Game.iter_games():
            try:
                game.chat_broadcast(msgs, _no_result=True)
            except:
                log.exception('broadcast')
        self.receive_broadcast(msgs)

    def receive_broadcast(self, msgs):
        """ 接收到多个聊天信息,
        msgs: [data, data, ...]  data=[sid, t, ids, msg]
        """
        if not Game.instance:
            return
        #log.debug('receive_broadcast')
        #ct = int(time.time())
        all_ids = self.all_ids
        all_msgs = []
        id2msgs = {}
        for sender, t, ids, msg in msgs:
            data = (t, msg, sender)#打包消息, ct)
            if ids == IDT_ALL:
                all_msgs.append(data)
            else:
                if isinstance(ids, int):
                    ids = [ids]
                ss = all_ids.intersection(ids)
                if not ss:
                    continue
                for id in ss:
                    id_msgs = id2msgs.setdefault(id, [])
                    id_msgs.append(data)
        self._send_msgs(all_msgs, id2msgs)

    def _send_msgs(self, all_msgs, id2msgs):
        #log.debug('_send_msgs(%s, %s)', all_msgs, id2msgs)
        resp_f = 'chatMsg'
        if all_msgs:
            pids = Game.instance.player_mgr.players.iterkeys()
            all_msgs = prepare_send(pack_msg(resp_f, 1, data=all_msgs))
        elif id2msgs:
            pids = id2msgs.iterkeys()
        else:
            return
        for pid in pids:
            p = Game.instance.player_mgr.get_player(pid)
            if not p:
                continue
            if all_msgs:
                p.send_msg(all_msgs)
            if pid in id2msgs:
                p.send_msg(pack_msg(resp_f, 1, data=id2msgs[pid]))

    def get_ally_ids(self, ally_id):
        """ 获取同盟玩家列表 """
        pass

    def get_receiver_ids(self, player, chat_type, pid=None):
        """ 获取玩家对应聊天频道的接收者id """
        if chat_type == CT_TALK:
            if pid is None:
                return 0, errcode.EC_VALUE
            if not Game.rpc_player_mgr.have(pid):
                #return 1, None
                return 0, errcode.EC_PLAYER_OFFLINE
            rpc_player = Game.rpc_player_mgr.get_rpc_player(pid)
            #黑名单过滤
            try:
                if rpc_player.is_black(player.data.id):
                    return 1, None
            except:
                return 1, None
            return 1, int(pid)
        elif chat_type == CT_ALLY:#玩家同盟
            rs, ids = player._game.rpc_ally_mgr.member_pids_by_pid(player.data.id)
            if not rs:
                return 0, errcode.EC_NO_ALLY
            return 1, ids
        else: #代表广播到所有
            return 1, IDT_ALL

    def send(self, chat_type, pids, msg, sender=None):
        """ 自定义发送 """
        if sender is None:
            sender = ''
        else:
            sender = sender.data.name
        self.msgs.append((sender, chat_type, pids, msg))

    def add_color_msg(self, t, msg, player):
        """
        消息中添加颜色
        """
        if t == CT_WORLD:
            res_horn = Game.res_mgr.hornmsgs.get(HORN_TYPE_WORLD)
            pcolor=player.hron.get_player_color(player)
            msg = res_horn.msg%dict(pname=player.data.name, pcolor=pcolor, msg=msg)
        elif t == CT_SYS:
            res_horn = Game.res_mgr.hornmsgs.get(HORN_TYPE_SYS)
            msg = res_horn.msg%dict(msg=msg)
        elif t == CT_SPEAK:
            if player:
                res_horn = Game.res_mgr.hornmsgs.get(HORN_TYPE_PLAYER_HORN)
                pcolor=player.hron.get_player_color(player)
                msg = res_horn.msg%dict(pname=player.data.name, pcolor=pcolor, msg=msg)
            else:
                res_horn = Game.res_mgr.hornmsgs.get(HORN_TYPE_SYS_HORN)
                msg = res_horn.msg%dict(msg=msg)
        elif t == CT_ALLY:
            res_horn = Game.res_mgr.hornmsgs.get(HORN_TYPE_ALLY)
            pcolor=player.hron.get_player_color(player)
            msg = res_horn.msg%dict(pname=player.data.name, pcolor=pcolor, msg=msg)
        elif t == CT_TALK:
            res_horn = Game.res_mgr.hornmsgs.get(HORN_TYPE_SECRET)
            pcolor=player.hron.get_player_color(player)
            msg = res_horn.msg%dict(pname=player.data.name, pcolor=pcolor, msg=msg)
        return msg

    def chat_send(self, player, chat_type, msg, pid=None, name=None):
        """ 收到玩家发的聊天信息
        chat_type: 1=世界, 2=系统, 3=大喇叭, 4=同盟, 5=密语
        msg: 消息
        pid:私聊玩家id
        """
        if player.is_forbid_chat:
            return 0, errcode.EC_FORBID_CHAT
        #log.debug(u'chat_send(%s, %d, %s)', player.data.name, chat_type, msg)
        if chat_type not in (CT_WORLD, CT_SPEAK, CT_ALLY, CT_TALK):
            return 0, errcode.EC_CHATTYPE_ERR
        if chat_type == CT_SPEAK:
            iid = self.fetch_horn_item_iid
            rs = player.bag.cost_item(iid, 1, pack_msg=True, log_type=ITEM_COST_HORN)
            if not rs:
                return False, errcode.EC_ITEM_NOFOUND
            player.send_update_msg(rs[-1])
            #data = rs[-1]
        if name and pid is None:#根据名字得到pid
            pid = Game.rpc_player_mgr.get_id_by_name(name)
            if not pid:
                return 0, errcode.EC_PLAYER_EMPTY

        rs, ids = self.get_receiver_ids(player, chat_type, pid=pid)
        if not rs:
            return False, ids
        #私聊不在线不处理,用于机器人
        if chat_type == CT_TALK and ids is None:
            return True, None

        #msg = Game.setting_mgr.replace_ban_word(msg)
        msg = Game.rpc_ban_word_mgr.replace_ban_word(msg)
        c_msg= self.add_color_msg(chat_type, msg, player)
        self.send(chat_type, ids, c_msg, sender=player)
        return True, None

    def sys_send(self, msg):
        """ 发系统信息 """
        self.send(CT_SYS, IDT_ALL, msg)

    def ally_send(self, msg, pids):
        """ 同盟系统消息 """
        self.send(CT_ALLY, pids, msg)

    def bugle(self, msg, pids=None):
        """ 大喇叭 """
        res_horn = Game.res_mgr.hornmsgs.get(HORN_TYPE_SYS_HORN)
        msg = res_horn.msg%dict(msg=msg)
        if pids:
            self.send(CT_SPEAK, pids, msg)
        else:
            self.send(CT_SPEAK, IDT_ALL, msg)

    @property
    def fetch_horn_item_iid(self):
        """ 获取大喇叭消耗的物品id """
        game = Game.instance
        res = game.setting_mgr.setdefault(HORN_COST_ID, HORN_COST_ID_V)
        return int(res)



class MyNotifyServer(NotifyServer):
    _rpc_name_ = 'rpc_notify_svr'
    def __init__(self):
        import app
        app.sub(MSG_START, self.start)

    def start(self):
        store = Game.rpc_res_store
        apns = store.get_config(NOTIFY_APNS, None)
        if apns is not None:
            if isinstance(apns, (str, unicode)):
                apns = eval(apns)
            sanbox, pem = apns
            self.start_apns(pem, config.cfg_path, sanbox)
            log.info('*****[notify]APNS service start!')

    def get_tokens(self, pids):
        from game.player.player import UserData, PlayerData
        uids = PlayerData.get_uids(pids)
        return UserData.user_tokens(uids)

    def send_msgs(self, pids, msg, **kw):
        """ 向某玩家推送消息 """
        if isinstance(msg, unicode):
            msg = msg.encode('utf-8')
        tokens = self.get_tokens(pids)
        for uid, token in tokens.iteritems():
            if not token:
                continue
            self.send_msg_by_token(uid, token, msg, **kw)

    def send_msg_by_token(self, uid, token, msg, **kw):
        if self.apns_started:
            try:
                self.send_apns_msg(token, msg, **kw)
            except Exception, e:
                log.error('[apns]send_msg_by_token error:(%s, %s) %s', uid, token, e)

def new_notify_svr():
    return MyNotifyServer()



#---------------------
#---------------------
#---------------------

