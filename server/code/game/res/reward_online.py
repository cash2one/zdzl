#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game.store import StoreObj

class ResRewardOnline(StoreObj):

    def init(self):
        self.id = None
        self.t = 0      #第一次登陆的在线奖励 2 = 每天登陆次数的奖励
        self.tNum = 0   #能获得奖励的次数
        self.val = 0    #获得奖励条件 t = 1时val代表时间 t = 2时val代表登录的次数
        self.rid = 0    #奖励ID


class ResRewardActive(StoreObj):

    def init(self):
        self.id = None
        self.t = 0      #奖励类型 1 = 充值 2 = 武器升阶 3 = 召募 4 = 礼品兑换
        self.val = 0    #获得奖励条件
        self.rid = 0    #奖励ID


class ResRewardSett(StoreObj):

    def init(self):
        self.id = None
        self.type = 0                       #奖励类型
        self.begin = ""                     #开始日期
        self.end = ""                       #结束日期
        self.data = ""                      #奖励的数据
        self.state = 0                      #该奖励是不是开启
        self.sids = ""                      #服务器的ids 本次修改对哪些服务器起作用


class ResRewardMail(StoreObj):
    """ 奖励邮件格式定义表
#奖励邮件类型 content为整数定义
RW_MAIL_ARENA = 1 #=竞技场奖励
RW_MAIL_DEEP = 2 #=深渊挂机奖励
RW_MAIL_FISH = 3 #钓鱼委托奖励
RW_MAIL_BOSS = 4 #=世界BOSS奖励
RW_MAIL_ABOSS = 5 #同盟BOSS奖励
RW_MAIL_ATBOX = 6 #=同盟组队炼妖奖励
RW_MAIL_DAY = 7 #=每日登录次数奖励
RW_MAIL_ONLINE = 8 #=在线时间奖励
RW_MAIL_ARM = 9 #武器升级奖励
RW_MAIL_ROLE = 10 #首招配将奖励
    """
    def init(self):
        self.id = None
        self.t = 0
        self.title = ''
        self.content = ''


