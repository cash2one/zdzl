#!/usr/bin/env python
# -*- coding:utf-8 -*-
import time

from corelib import log, spawn, sleep
from game.store import GameObj, StoreObj, FOP_IN, FOP_GT, FOP_GTE, FOP_LT, FOP_LTE, FOP_NE, FOP_NIN

from game.store.define import TN_P_MAIL, TN_PLAYER
from game.base import errcode
from game.base.constant import WAITBAG_TYPE_EMAIL, RW_MAIL_ONLINE, MAIL_REWARD, RW_MAIL_HOLDMAILTIME1
from game.glog.common import ITEM_FETCH_EMAIL
from game import pack_msg, Game
from game.player.bag import WaitItem
from game.base.msg_define import MSG_MAIL_FETCH
from game.base.common import cur_day_hour_time, current_time

class MailMgr(object):
    """ 邮箱管理 """

    EXPIRE_TIME = 10*86400
    SLEEP_TIME = 86400
    LIMIT = 1000

    def start_expire_mail(self):
        if hasattr(self, '_expire_task'):
            return
        self._expire_task = spawn(self.del_expire_mail)

    def _del_mail(self, m_d, store):
        """
        删除邮件 删除待收物品
        """
        obj = Mail(adict=m_d)
        wait = WaitItem()
        wait.load(store, obj.data.wid)
        wait.delete(store)
        obj.delete(store)

    def del_expire_mail(self):
        """
        每日凌晨4点删除过期的邮件
        """
        four = cur_day_hour_time(4)
        ct = current_time()
        sleep_time = four-ct if ct<four else MailMgr.SLEEP_TIME-(ct-four)
        log.info("del_expire_mail sleep %s times", sleep_time)
        sleep(sleep_time)
        store = Game.rpc_store
        while 1:
            #计算段数
            limit = MailMgr.LIMIT
            a_n = store.count(Mail.TABLE_NAME, {'_id':{FOP_NE:0}})
            u_n = a_n/limit+1 if a_n%limit else a_n/limit
            sections = [i for i in xrange(u_n)]
            sections.append(u_n)
            sections.sort(reverse=True)

            ct = current_time()
            onls = Game.rpc_player_mgr.get_online_ids()
            del_time = ct - MailMgr.EXPIRE_TIME
            querys = {'pid':{FOP_NIN:onls}, 'ct':{FOP_LTE:del_time}}
            for section in sections:
                mails = store.query_loads(Mail.TABLE_NAME, querys=querys, limit=limit, skip=section*limit)
                for m_d in mails:
                    self._del_mail(m_d, store)
            sleep(MailMgr.SLEEP_TIME)

    def _send_mail(self, pid, t, title, content, items, param='', rid=0):
        store = Game.rpc_store
        if not store.has(TN_PLAYER, pid):
            return
        if items:
            witem = WaitItem.new(pid, WAITBAG_TYPE_EMAIL, items, rid=rid)
            witem.save(store)
            wid = witem.data.id
        else:
            wid = 0
        mail = Mail.new(pid, t, title, content, wid)
        if param:
            mail.data.param = str(param)
        mail.save(store)
        return mail.data.id

    def send_mails(self, pids, t, title, content, items, param='', notify_mgr=True, rid=0):
        """ 发送系统邮件
        pids: 玩家id或列表
        t: 邮件类型
        title: 邮件标题
        content: 邮件内容
        items: 奖励物品列表, 由reward产生,保存在待收物品表
        返回: {pid:mid}
        """
        mids = {}
        if isinstance(pids, int):
            pids = (pids, )
        for pid in pids:
            mid = self._send_mail(pid, t, title, content, items, param=param, rid=rid)
            if mid is None:
                continue
            mids[pid] = mid
        if notify_mgr:
            Game.rpc_player_mgr.player_mails(pids, mids, _no_result=True)
        return mids


PUB_MAIL = set([str(RW_MAIL_ONLINE), str(RW_MAIL_HOLDMAILTIME1)])
class PlayerMail(object):
    """ 玩家邮箱 """
    def __init__(self, player):
        self.player = player
        self.mails = {}
        if 0:
            from .player import Player
            self.player = Player()

    def uninit(self):
        self.player = None
        self.mails = {}

    def load(self):
        #log.debug('(%s)load.mail', self.player.data.id)
        store = self.player._game.rpc_store
        querys = dict(pid=self.player.data.id)
        mails = store.query_loads(TN_P_MAIL, querys)
        for m in mails:
            mail = Mail(adict=m)
            self.mails[mail.data.id] = mail

    def save(self):
        store = self.player._game.rpc_store
        for key in self.mails.keys():
            if key not in self.mails:
                continue
            m = self.mails[key]
            m.save(store)

    def clear(self):
        #log.debug('(%s)clear.mail', self.player.data.id)
        store = self.player._game.rpc_store
        for m in self.mails.itervalues():
            m.delete(store)
        self.mails.clear()

    def copy_from(self, mail, witems):
        self.clear()
        for m in mail.mails.itervalues():
            nm = Mail(adict=m.data.to_dict())
            nm.data.id = None
            nm.data.pid = self.player.data.id
            nm.save(self.player._game.rpc_store)
            nm.data.wid = witems.get(m.data.wid, 0)
        self.load()

    def to_dict(self):
        return [m.to_dict() for m in self.mails.itervalues()]

    def send_mail(self):
        """ 玩家发送邮件 """
        raise ValueError('no no no')
    
    def recv_mails(self, mids):
        """ 接收发送到玩家的新邮件 """
        if not self.player:
            return
        if isinstance(mids, int):
            mids = [mids]
        news = []
        waits = []
        for mid in mids:
            m = self.player._game.rpc_store.load(TN_P_MAIL, mid)
            if not m:
                continue
            if not self.player:
                return
            mail = Mail(adict=m)
            news.append(mail)
            #log.debug('(%s)recv_mails.mail:%s', self.player.data.id, mid)
            self.mails[mid] = mail
            if mail.data.wid:
                wait = self.player.wait_bag.load_item(mail.data.wid)
                if wait:
                    waits.append(wait)
        if news and self.player and self.player.logined: #主动推送消息
            resp_f = 'mailPush'
            self.player.send_msg(pack_msg(resp_f, 1,
                    data=self.player.pack_msg_data(mails=news, waits=waits)))

    def receive(self, mid):
        """ 收取删除邮件 """
        delete = 1
        mail = self.mails.get(mid)
        if not mail:
            #log.debug('(%s)receive.error:%s************', self.player.data.id, mid)
            return False, errcode.EC_VALUE
        #log.debug('(%s)receive.mail:%s', self.player.data.id, mid)
        wid = mail.data.wid
        msg = None
        try:
            rs, msg = self.player.wait_bag.fetch(WAITBAG_TYPE_EMAIL, wid,
                    delete=delete, log_type=ITEM_FETCH_EMAIL)
            if not rs and msg == errcode.EC_NOFOUND:
                msg = None
            elif not rs:
                return False, msg
        except:
            log.log_except()
        if delete:
            self.delete(mail)
        return True, msg

    def delete(self, mail):
        #log.debug('(%s)delete.mail:%s', self.player.data.id, mail.data.id)
        mail.delete(self.player._game.rpc_store)
        self.mails.pop(mail.data.id)
        if mail.data.t == MAIL_REWARD and str(mail.data.content) in PUB_MAIL:
            self.player.pub(MSG_MAIL_FETCH, mail.data.content)


class MailData(StoreObj):
    def init(self):
        self.id = None
        self.pid = 0
        self.t = 0 #1=普通邮件, 2=奖励, 3=战报
        self.ct = 0
        self.title = ''
        self.content = ''
        self.wid = 0 #待收物品id, 战报表id
        self.param = '' #奖励邮件记录邮件内容

class Mail(GameObj):
    TABLE_NAME = TN_P_MAIL
    DATA_CLS = MailData

    @classmethod
    def new(cls, pid, t, title, content, wid):
        o = cls()
        o.data.pid = pid
        o.data.ct = current_time()
        o.data.t = t
        o.data.title = title
        o.data.content = str(content)
        o.data.wid = wid
        return o




