#!/usr/bin/env python
# -*- coding:utf-8 -*-

#!/usr/bin/env python
# -*- coding:utf-8 -*-

from game import Game, pack_msg, grpc_monitor
from game.base import errcode, common
from game.glog.common import PL_VIP_UPGRADE
from game.base.common import make_lv_regions, current_time
from corelib import spawn, sleep, log
from corelib.message import observable
from game.base.msg_define import MSG_RES_RELOAD, MSG_START, MSG_VIP_PAY
from game.res.shop import ResGoods, PrePay, Pay
from game.store.define import GF_DEFAULT_PAY_BACK, FOP_NE

from game.base.constant import  RW_MAIL_VIP, MAIL_REWARD, RW_MAIL_FIRST_CHARGE
from game.base.constant import  BF_RE_NUM, BF_RE_NUM_V
from game.base.constant import  VIP_LEVELS, VIP_LEVELS_V, VIP_REWARD, VIP_REWARD_V
from game.base.constant import  VIP_LV_BAGS, VIP_LV_BAGS_V
from game.base.constant import  FETE_FREE_MAX, FETE_FREE_MAX_V, FETE_COIN2_MAX, FETE_COIN2_MAX_V
from game.base.constant import  DEEP_AUTO_TIMES, DEEP_AUTO_TIMES_V #,DEEP_RESET_TIMES, DEEP_RESET_TIMES_V
from game.base.constant import  HITFATE_COIN1_MAX,  HITFATE_COIN1_MAX_V, HITFATE_COIN2_MAX, HITFATE_COIN2_MAX_V, HITFATE_FREE_MAX, HITFATE_FREE_MAX_V

from webapi import SNS_ALL, SNS_URLS


import app
import config

get_vip_rid = None
def init_get_vips_func():
    global get_vip_rid
    vips = Game.setting_mgr.setdefault(VIP_REWARD, VIP_REWARD_V)
    get_vip_rid = make_lv_regions(vips)


class PlayerVip(object):
    """ 玩家vip类 """
    def __init__(self, player):
        self.player = player
        if 0:
            from .player import Player
            self.player = Player()

    def uninit(self):
        self.player = None

    def _set_vip(self, value):
        self.player.data.vip = value
        self.update()
    def _get_vip(self):
        return self.player.data.vip
    vip = property(_get_vip, _set_vip)

    def load(self):
        """ 初始化vip相关数据 """
        #背包格子数
        self.update()

    def _send_reward(self, vip_lev):
        """ 发送vip奖励 """
        p = self.player
        if self.vip > vip_lev:
            log.info('player(%s) cur vip:%s, upgrade vip:%s', p.data.name, self.vip, vip_lev)
            return
        rw_mail = Game.res_mgr.reward_mails.get(RW_MAIL_VIP)
        pid = p.data.id

        for vip in xrange(self.vip + 1, vip_lev + 1):
            try:
                cont_dict = dict(vip=vip)
                content = rw_mail.content % cont_dict
                rid = get_vip_rid(vip)
                t_rw = p._game.reward_mgr.get(rid)
                if not t_rw:
                    log.info('vip reward_item is %s, please check data', t_rw)
                    continue
                items = t_rw.reward(params=p.reward_params())
                log.info('player(%s) vip_lv:%s send:%s', p.data.name, vip, items)
                Game.mail_mgr.send_mails(pid, MAIL_REWARD, rw_mail.title,
                        RW_MAIL_VIP, items, param=content, rid=rid)
            except:
                log.log_except("the vip send_mail is error the vip level is:%s", vip)

    def _init_vip_level(self):
        """ 根据累计重置元宝数,确定vip等级
        只升级,不降级,方便实现送vip等级等人为调整功能
        """
        lv = self.player._game.vip_mgr.get_vip_level(self.player.data.vipCoin)
        if lv > self.player.data.vip:
            self.player.log_normal(PL_VIP_UPGRADE, lv=lv)
            log.info('player(%s)vip level up:%s', self.player.data.name, lv)
            self._send_reward(int(lv))
            self.vip = lv
            self.player.pub_vip_level()

    def update(self):
        p = self.player
        game = p._game
        mgr = game.vip_mgr
        vip = self.vip

    def first_charge(self, bag_item):
        """发送首冲奖励"""
        rw_mail = Game.res_mgr.reward_mails.get(RW_MAIL_FIRST_CHARGE)
        content = RW_MAIL_FIRST_CHARGE
        pid = self.player.data.id
        log.info("first_charge mailType:%s, pid:%s, items:%s", content, pid, bag_item)
        if not bag_item:
            return
        Game.mail_mgr.send_mails(pid, MAIL_REWARD, rw_mail.title, content,
                bag_item, param=rw_mail.content)

    def pay_back(self, bag_items):
        """ 支付回调,获取奖励 """
        #_last = self.player.data.vipCoin
        #调整vip
        self.player.data.vipCoin += bag_items.coin2
        #log.info("pay_back_vipCoin last:%s, now:%s", _last, self.player.data.vipCoin)
        self._init_vip_level()
        #支付奖励,马上保存
        self.player.save(full=1)
        #通知前端
        resp_f = 'goodsGive'
        data = dict(player=self.player.to_dict(),
            data=bag_items.pack_msg(),
            vipData=self.player.vip_attr.to_dict())
        self.player.send_msg(pack_msg(resp_f, 1, data=data))

    def copy_from(self, p_vip):
        """拷贝玩家数据"""
        self.vip = p_vip.vip

class VipMgr(object):
    def start(self):
        Game.setting_mgr.sub(MSG_RES_RELOAD, self.load)
        self.load()

    def _load(self, key, value):
        return make_lv_regions(Game.setting_mgr.setdefault(key, value))

    def load(self):
        init_get_vips_func()
        data = Game.setting_mgr.setdefault(VIP_LEVELS, VIP_LEVELS_V)
        data = common.str2dict(data, ktype=int, vtype=int)
        for k, v in data.iteritems():
            if v == 1:
                self.vip1_coin = k
                break
        self.get_vip_level = self._load(VIP_LEVELS, VIP_LEVELS_V)


@observable
class GVipMgr(object):
    """ vip单例管理器 """
    _rpc_name_ = 'rpc_vip_mgr'
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        app.sub(MSG_START, self.start)
        self._loop_task = None
        self.clear()

    def start(self):
        self.sid = Game.rpc_client.get_server_id()
        Game.res_mgr.sub(MSG_RES_RELOAD, self.load)
        self.load()
        is_pay_back = Game.rpc_status_mgr.get_config(GF_DEFAULT_PAY_BACK)
        if is_pay_back or config.vip_pay_back:
            self.start_pay_back()

    def start_pay_back(self):
        if self._loop_task:
            return
        self._loop_task = spawn(self._loop)

    def clear(self):
        self.goods = {}
        self.sns_goods = {}
        self.reward_goods = {}
        self.firsts = {} #首充奖励
        self.goods_data = None
        self.first_reward = 0

    def load(self):
        """ 加载商品列表 """
        self.clear()

        goods = Game.rpc_res_store.load_all(ResGoods.TABLE_NAME)
        for data in goods:
            if not data['status']:
                continue
            g = ResGoods(adict=data)
            if g.is_first_reward():
                self.firsts[g.id] = g
                self.first_reward = g.rid
            elif g.snsType:
                goods = self.sns_goods.setdefault(g.snsType, {})
                goods[g.id] = g
            else:
                self.goods[g.id] = g
            assert g.rid not in self.reward_goods, ValueError('goods rid double')
            self.reward_goods[g.rid] = g
        self.goods_data = [g.to_dict() for g in self.goods.itervalues()]

    @grpc_monitor
    def get_goods(self, sns_type=0):
        """ 获取商品列表 """
        if sns_type in self.sns_goods:
            goods = self.sns_goods[sns_type]
            return self.goods_data + [g.to_dict() for g in goods.itervalues()]
        return self.goods_data

    def get_good_coin(self, rid):
        """获得商品元宝数"""
        g = self.reward_goods.get(rid, None)
        if g:
            return g.coin
        return 0

    @property
    def pay_store(self):
        return Game.rpc_pay_store

    @grpc_monitor
    def buy_goods(self, t, gid, uid, pid):
        """ 购买物品
        t: 购买支付类型: 1=91助手
        gid: 商品id
        uid: 用户id
        pid: 玩家id
    return:
        rs, (order, price, product_id)
        """
        if gid not in self.goods:
            return 0, errcode.EC_NOFOUND
        if t not in SNS_ALL:
            return 0, errcode.EC_VALUE

        sid = self.sid
        g = self.goods[gid]
        good_sns_id = SNS_URLS[t]
        product_id = g.sns.get(good_sns_id, '')
        #待支付记录写入全服库,供logon进程访问
        pre_pay = PrePay()
        pre_pay.prepare(t, sid, uid, pid, g, product_id)
        self.pay_store.insert(PrePay.TABLE_NAME, pre_pay.to_dict())
        #return 1, (pre_pay.porder, 1)
        return 1, (pre_pay.porder, pre_pay.price, product_id)

    def _loop(self):
        """ 定时检查购买支付情况 """
        log.info('vip_pay_back start')
        querys = dict(sid=self.sid, dt=0, status=1, torder={FOP_NE:''})
        while 1:
            sleep(5)
            try:
                pays = self.pay_store.query_loads(Pay.TABLE_NAME,
                        querys)
                for pay in pays:
                    try:
                        self._pay_back(pay)
                    except:
                        log.log_except()
            except:
                log.log_except()

    def player_pay_back(self, pid, rid, coin):
        p = self.get_rpc_player(pid)
        if p:
            rs, lv = p.pay_back(rid, self.first_reward, coin)
            log.info('online pay_back(%s, %s):%s, %s', pid, rid, rs, lv)
        else:#离线状态
            g = Game.one_game()
            rs, lv = g.sync_exec(handle_pay_back,
                (pid, rid, self.first_reward, coin), _pickle=True)
            log.info('offline pay_back(%s, %s):%s, %s', pid, rid, rs, lv)
        return rs, lv

    def _pay_back(self, pay_data):
        """ 支付成功回调 """
        pay = Pay(adict=pay_data)
        goods = self.reward_goods.get(pay.rid, None)
        pay.coin = goods.coin if goods else 0 #首充翻倍要用到coin
        log.info('pay_back(%s)', pay_data)
        rs, lv = self.player_pay_back(pay.pid, pay.rid, pay.coin)
        if not rs:
            return

        log.info('pay_back(%s) done', pay.porder)
        pay.dt = current_time()
        pay.lv = lv
        pay.save(self.pay_store)
        self.safe_pub(MSG_VIP_PAY, pay.pid, pay.rid, pay.coin)


    def get_rpc_player(self, pid):
        return Game.rpc_player_mgr.get_rpc_player(pid)

def handle_pay_back(pid, rid, first_reward, coin):
    """ 离线支付回调 """
    from game.player.player import Player
    p = Player.load_player(pid)
    if not p:
        log.error('******pay_back error:player(%s) not found', pid)
        return 0, 0
    rs = p.pay_back(rid, first_reward, coin)
    p.save()
    return rs



def new_vip_mgr():
    return GVipMgr()






