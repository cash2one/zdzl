#!/usr/bin/env python
# -*- coding:utf-8 -*-

from .base import *
from .scene import PlayerScene
from .role import PlayerRole
from .bag import PlayerBag, WaitBag
from .gm import GameMaster
from .fish import PlayerFish
from .mining import PlayMining
from .deep import PlayerDeep
from .tbox import PlayerTbox
from .chat import PlayerChat
from .shop import PlayerShop
from .rank import PlayerRank
from .ally import Ally
from .awar import Awar
from .arena import PlayerArena
from .reward import Reward
from .boss import Boss
from .social import Social
from .vipattr import PlayerVipAttr
from .day_sign import Sign

DEBUG = 1

class User(object):
    def __init__(self):
        from .client import Client
        client = Client()
        self.client = client
        self.client.add_listener(self)
        if 0:
            from . client import Client
            self.client = Client()

    def connect(self, host, port):
        self.client.close()
        self.client.connect(host, port)

    def _login(self, user, rs):
        uid, key, ip, port = rs['uid'], rs['key'], rs['ip'], rs['port']
        print('login:%s:%s' % (ip, port))
        self.connect(ip, port)
        self.client.call_login1(user=uid, key=key)

    def login(self, user, pwd, main_addr, UDID='', DT=''):
        """ 登录流程 """
        self.connect(*main_addr)
        rs = self.client.call_login(user=user, pwd=pwd, UDID=UDID, DT=DT)
        return self._login(user, rs)

    def logout(self):
        self.client.call_logout()
        self.client.close()

    def loginSNS(self, main_addr, t, sid, session, UDID='', DT=''):
        self.connect(*main_addr)
        rs = self.client.call_loginSNS(t=t, sid=sid, session=session, UDID=UDID, DT=DT)
        return self._login(sid, rs)

    def get_players(self):
        rs = self.client.call_players()
        return rs

    def new_player(self, name, rid):
        rs = self.client.call_new(name=name, rid=rid)
        return rs

    def del_player(self, pid):
        rs = self.client.call_delete(pid=pid)
        return rs

    def del_all(self):
        print(u'删除所有玩家')
        players = self.get_players()
        for p in players:
            self.del_player(p['id'])

    def enter(self, pid):
        self.player = Player(self)
        rs = self.client.call_enter(id=pid)
        return self.player


class Player(object):
    def __init__(self, user):
        self.user = user
        self.client = user.client
        self.client.add_listener(self)
        self.info = None

        if 0:
            from . client import Client
            self.client = Client()

        self.role = PlayerRole(self)
        self.bag = PlayerBag(self)
        self.wait_bag = WaitBag(self)
        self.game_master = GameMaster(self)
        self.fish = PlayerFish(self)
        self.mining = PlayMining(self)
        self.deep = PlayerDeep(self)
        self.tbox = PlayerTbox(self)
        self.sit = Sit(self)
        self.chat = PlayerChat(self)
        self.mail = Mail(self)
        self.shop = PlayerShop(self)
        self.ally = Ally(self)
        self.awar = Awar(self)
        self.arena = PlayerArena(self)
        self.rank = PlayerRank(self)
        self.reward = Reward(self)
        self.boss = Boss(self)
        self.social = Social(self)
        self.vip_attr = PlayerVipAttr(self)
        self.sign = Sign(self)

    def gm(self, cmd, *args):
        """ 执行gm命令 """
        if args:
            cmd = cmd % args
        rs = self.client.call_gm(cmd=cmd)
        return rs['msg']

    def logout(self):
        rs = self.client.call_leave()
        self.scene.stop()
        self.client.del_listener(self)

#    def init(self):
#        rs = self.client.call_init()
#        self.update_info(rs['player'])
#        self.update_roles(roles=rs['roles'])
#        self.update_ilist(ilist=rs['ilist'])
#        self.update_task(tasks=rs['task'])
#        self.scene = PlayerScene(self)

    def on_init(self, status, kw, err):
        self._init(kw)
    def _init(self, rs):
        self.update_info(rs['player'])
        self.update_roles(roles=rs['roles'])
        self.update_ilist(ilist=rs['ilist'])
        self.update_task(tasks=rs['task'])
        self.update_buff(rs['buff'])
        self.mail.init_mails(rs['mail'])
        self.scene = PlayerScene(self)

    def reinit(self):
        rs = self.client.call_init()
        self._init(rs)

    def on_addSitExp(self, status, kw, err):
        """ 打坐经验 """
        rs = kw
        print 'on_addSitExp-kw -------------- ', rs

    def update_info(self, info=None):
        if info is None:
            info = self.client.call_player()
        self.info = info
        self.id = info['id']
        self.uid = info['uid']
        self.name = info['name']

    def update_roles(self, roles=None):
        if roles is None:
            roles = self.client.call_roles()
        self.roles = Roles(self, roles)

    def update_ilist(self, ilist=None):
        if ilist is None:
            ilist = self.client.call_ilist()
        self.bag.update(ilist)

    def update_task(self, tasks=None):
        if tasks is None:
            tasks = self.client.call_task()
        self.tasks = Tasks(self, tasks)

    def update_buff(self, buffs=None):
        if buffs is None:
            buffs = self.client.call_buff()
        self.buffs = Buffs(self, buffs)

    def update_sit(self, sit=None):
        if sit is None:
            sit = self.client.call_sit()
        self.sit = Sit(self, sit)

    def arm_upgrade(self, rid):
        """ 装备升级 """
        rs = self.client.call_armUpgrade(rid=rid)
        return rs
    
    def skill_back(self, rid, type):
        """ 取回技能点 """
        rs = self.client.call_skillBack(rid=rid, type=type)
        return rs

    def clear_all(self):
        """ 清理所有数据 """
        self.client.call_clear_player_data()

    def valid_gm(self):
        """ 使gm模块生效 """
        self.client.call_valid_gm()
    
    def look_player(self, pid, name):
        """ 查看别人的信息 """
        return self.client.call_lookPlayer(pid=pid, name=name)
    
class Roles(PlayerProp):
    def __init__(self, player, roles):
        super(Roles, self).__init__(player)
        self.roles = roles

    def get_main(self):
        for r in self.roles:
            if r['rid'] == self.player.info['rid']:
                return r


class Tasks(PlayerProp):
    def __init__(self, player, tasks):
        super(Tasks, self).__init__(player)
        self.tasks = tasks['tasks']
        self.ids = tasks['taskIds']
        player.client.add_listener(self)

    def on_taskPush(self, status, kw, err):
        if DEBUG:
            print '---on_taskPush', kw
        self.tasks.extend(kw)

    def complete(self, task_id):
        """ 完成任务 """
        rs = self.player.client.call_taskComplete(id=task_id)
        return rs

    def complete_chapter(self):
        """ 完成章节 """
        return self.player.client.call_chapterComplete()

    def bf_task_enter(self):
        """ 进入兵符任务 """
        return self.player.client.call_bfTaskEnter()
    
    def bf_task_re(self, type):
        """ 刷新兵符任务 """
        return self.player.client.call_bfTaskRe(type=type)

    def bf_task_box(self):
        """ 打开兵符宝箱 """
        return self.player.client.call_bfTaskBox()

    def bf_task_get(self, index):
        """ 接兵符任务 """
        return self.player.client.call_bfTaskGet(index=index)

    def bf_task_finish(self):
        """ 立即完成兵符任务 """
        return self.player.client.call_bfTaskFinish()


class Buffs(PlayerProp):
    def __init__(self, player, buffs):
        super(Buffs, self).__init__(player)
        self.buffs = buffs

    def eat(self, id, t):
        """ 进食 id=食物id, t=花费类型 """
        return self.player.client.call_foodEat(id=id, t=t)


class Sit(PlayerProp):
    def __init__(self, player):
        super(Sit, self).__init__(player)

    def start_sit(self):
        """ 开始打坐 """
        return self.player.client.call_startSit()

    def stop_sit(self):
        """ 停止打坐 """
        return self.player.client.call_stopSit()

    def online_sit(self):
        """ 上线获取打坐信息 """
        return self.player.client.call_onlineSitExp()

class Mail(PlayerProp):
    def __init__(self, player):
        super(Mail, self).__init__(player)
        self.player.client.add_listener(self)
        self.mails = {}

    @property
    def count(self):
        return len(self.mails)

    def on_mailPush(self, status, kw, err):
        if DEBUG:
            print 'mailPush', kw
        if not status:
            print('mailPush error:%s' % str(kw))
            return
        self.init_mails(kw['mail'], clear=0)

    def receive(self, mid):
        rs = self.player.client.call_mailReceive(id=mid)
        self.mails.pop(mid, None)
        return rs


    def init_mails(self, mails, clear=1):
        if clear:
            self.mails.clear()
        for m in mails:
            self.mails[int(m['id'])] = m

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


