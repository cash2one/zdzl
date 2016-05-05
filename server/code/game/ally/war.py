#!/usr/bin/env python
# -*- coding:utf-8 -*-

import math

from corelib import spawn, sleep, log

from game import Game, pack_msg
from game.base import common, errcode
from game.base.constant import (ALLY_WAR_FAIL_HARD, ALLY_WAR_WIN,
    ALLY_WORLD_WAR, BOAT_POW, AWAR_CONNON_MAX, AWAR_CONNON_MAX_V,
    ALLY_WAR_FAIL_SYSCLOSE, AWAR_FIRE_DESC, AWAR_FIRE_DESC_V,
    AWAR_BOAT_DESC, AWAR_BOAT_DESC_V, DIFF_TITEM_SITE_TIME,
    IT_ITEM_STR, IT_CAR_STR
)

#战胜该场景的方式
#1=战死所有小怪，2=战死小怪和大boss,3=给定时间内打去boss的血量百分比3=给定时间内打去boss的血量百分比
WAY_WIN_MONSTER = 1
WAY_WIN_ALL = 2
WAY_WIN_BOSSHP = 3


#boss血量是否继承到下一关
#继承
BOSS_HP_EXTEND = 1
#不继承
BOSS_HP_NOEXTEND = 0

#天舟血量变化类型
#天书加固
HARD_TYPE_BOOK = 1
#boss袭击
HARD_TYPE_BOSS = 2



class War(object):
    """ 战斗基类 """
    def __init__(self):
        #room
        self.room = None

        #当前战场的配置
        self.war_per_config = None

        #天舟数据
        self.boat = None
        #玩家数据{pid:playerWarData,...}
        self.pid2pdata = {}
        #战斗数据
        self.war_data = None


    def gm_kill_monsters(self, pid):
        """ 秒杀制定玩家该战场出现的怪物 """
        if not self.war_data.show_npcids:
            return False, None
        log.debug('gm---kill pid-%s, npcids-%s', pid, self.war_data.show_npcids)
        kill_npcids = self.war_data.show_npcids[:]
        for npcid in kill_npcids:
            log.debug('npcid---- %s', npcid)
            if npcid == self.war_data.b_npcid:
                continue
            self.war_monster_start(pid, npcid)
            self.war_monster_end(pid, npcid, 1, 0)
        return True, None
    
    def player_logout(self, pid):
        """ 掉线的处理 """
        if pid in self.war_data.war_pids:
            self.war_data.war_pids.remove(pid)
        if pid in self.war_data.pid2npcid:
            npcid = self.war_data.pid2npcid.get(pid)
            self.war_monster_end(pid, npcid, 0, 0)
        return True, self.war_data.is_win

    def data_init(self):
        """ 初始化战场数据 """
        #同盟获取
        self.boat = BoatData.new(self, self.room.aid)
        self.war_data = WarData.new(self)
        #玩家数据
        for pid in self.room.pids:
            p_data = PlayerWarData.new(self, pid)
            self.pid2pdata[pid] = p_data
            #初始化该场怪物数据
        return self.war_data.init_monster(self.war_per_config.id, self.room.pids)

    def get_data(self, pid):
        """ 获取当前战斗的所有数据 """
        data = dict(apcid=self.war_per_config.id)
        war_data = self.war_data.get_data()
        pdata = self.pid2pdata.get(pid)
        p_data = pdata.get_data()
        boat_data = self.boat.get_data()
        rs, room_data = Game.rpc_awar_mgr.get_room_data(pid)
        if rs:
            data.update(room_data)
        data.update(war_data)
        data.update(p_data)
        data.update(boat_data)
        return data

    def next_scene_data_init(self):
        """ 初始化下一关数据 """
        war_type = self.war_per_config.type
        key = (war_type, self.war_per_config.fnum+1)
        next_war_config = Game.res_mgr.awar_per_configs_bykeys.get(key)
        if next_war_config is None:
            return False, errcode.EC_NORES
        #进入下一关清楚不继承的记录
        for pid in self.room.pids:
            pdata = self.pid2pdata.get(pid)
            pdata.next_scene_clear()
        self.boat.cannon = self.fetch_mcannon
        self.boat.clear_cannon()
        self.war_data.clear()
        extend_boss_hp = 0
        #是否继承血量
        if self.war_per_config.ishp == BOSS_HP_NOEXTEND:
            extend_boss_hp = self.war_data.boss_hp
        self.war_per_config = next_war_config
        self.war_data.init_monster(next_war_config.id, extend_boss_hp=extend_boss_hp)
        #进入下一场广播
        self.start_broad()

    def _loop_broad(self):
        """ 数据广播 """
        #开战及时
        while not self.war_data.war_end:
            desc = self.handle_connon()
            if desc:
                self._boss_hp_broad(desc)
                is_pass = self.is_pass_scene()
                if is_pass:
                    self.pass_scene(self.room.aid)
            if self.war_data.boss_hp <= 0:
                break
            sleep(1)

    def _boss_hp_broad(self, desc=None):
        """ Boss血量广播 """
        resp_f = 'awarBossHp'
        if desc:
            data = dict(hp=self.war_data.boss_hp, desc=desc)
        else:
            data = dict(hp=self.war_data.boss_hp)
        self.send_msg(resp_f, data)

    def handle_connon(self):
        """ 处理打炮的结果 """
        rs = self.boat.loop_connon()
        if not rs:
            return
        desc = ''
        _, d = Game.rpc_player_mgr.get_player_infos(rs)
        for pid in rs:
            #扣血
            self.war_data.boss_hp -= self.boat.cfire
            if self.war_data.boss_hp < 0:
                self.war_data.boss_hp = 0
            desc = self.fetch_fire_desc % dict(pname=d[pid][0], hurt=self.boat.cfire)
            #desc += '%s 打了 boss %d 血! ' % (d[pid][0], self.boat.cfire)
            if self.war_data.boss_hp <= 0:
                reward_items = self.get_reward(self.war_data.b_npcid)
                self.war_finish(reward_items)
        return desc

    def reconnection(self, pid):
        """ 掉线重连进入 广播数据 """
        pass

    def war_monster_start(self, pid, npcid):
        """ 击杀怪物开始 """
        if npcid !=self.war_data.b_npcid and \
           npcid in self.war_data.pid2npcid.values():
            return False, errcode.EC_ALLY_WAR_ING
        if npcid not in self.war_data.show_npcids:
            return False, errcode.EC_ALLY_WAR_MDIE
        p_data = self.pid2pdata.get(pid)
        ktime = p_data.ktime
        if ktime and ktime + self.war_per_config.cdtime > common.current_time():
            return False, errcode.EC_ALLY_WAR_CD
        self.war_data.pid2npcid[pid] = npcid
        res_mconfig = Game.res_mgr.awar_npc_configs.get(npcid)
        data = self.war_data.get_moster_attr(npcid)
        self.war_monster_start_broad(pid, res_mconfig.id)
        pdata = self.pid2pdata.get(pid)
        pdata.save_monsster_fight(npcid)
        return True, dict(attrs=data, pbuff=pdata.pbuff)

    def war_monster_start_broad(self, pid, ancid):
        """ 击杀怪物开始广播 """
        resp_f = 'awarMosterStartB'
        data = dict(pid=pid, ancid=ancid)
        self.send_msg(resp_f, data)

    def get_reward(self, npcid, rid=None):
        """ 获取奖励 """
        if rid is None:
            res_mconfig = Game.res_mgr.awar_npc_configs.get(npcid)
            rid = res_mconfig.rid
        rw = Game.reward_mgr.get(rid)
        if rw is None:
            return
        return rw.reward({})

    def war_monster_end(self, pid, npcid, is_win, hurts):
        """ 击杀怪物结束 """
        if self.war_data.war_end:
            return True, None
        if pid in self.war_data.pid2npcid:
            self.war_data.pid2npcid.pop(pid)
        pdata = self.pid2pdata.get(pid)
        fight = pdata.get_monster_fight
        if not pdata or npcid != fight:
            return False, errcode.EC_ALLY_WAR_MDIE
        is_pass = False
        #怪物的特殊处理
        if npcid == self.war_data.b_npcid:
            self.war_data.boss_hp -= hurts
            if self.war_data.boss_hp <= 0 or is_win:
                self.war_data.boss_hp = 0
                is_pass = True
                is_win = 1
            self._boss_hp_broad()
        res_mconfig = Game.res_mgr.awar_npc_configs.get(npcid)
        reward_items = None
        if is_win:
            reward_items = self.get_reward(npcid, res_mconfig.rid)
            self.handle_reward(pid, reward_items)
            self.war_data.clear_npc(npcid)
            is_pass = self.is_pass_scene()
        else:
            #失败进入cd状态
            p_data = self.pid2pdata.get(pid)
            p_data.ktime = common.current_time()
        war_end = self.is_win_war() and is_pass
        self.war_monster_end_broad(pid, res_mconfig.id, is_win, is_pass, war_end)
        #通关
        log.debug('war_end---- %s',war_end)
        if war_end:
            self.war_finish(reward_items)
            return True, None
        return True, reward_items

    def handle_reward(self, pid, reward_items):
        """ 处理经验书添加的经验 """
        if not reward_items:
            return
        if not pid in self.pid2pdata:
            return
        pdata = self.pid2pdata.get(pid)
        if not pdata.book_addexp:
            return
        for reward_item in reward_items:
            if DIFF_TITEM_SITE_TIME != reward_item[IT_ITEM_STR]:
                continue
            all_exp = reward_item[IT_CAR_STR] * (1 + pdata.book_addexp * 0.01)
            reward_item[IT_CAR_STR] = int(all_exp)

    def pass_scene(self, aid):
        """ 通过本场 """
        pass

    def war_monster_end_broad(self, pid, ancid, is_win, is_pass, war_end):
        """ 击杀怪物结束广播 """
        resp_f = 'awarMosterEndB'
        data = dict(pid=pid, ancid=ancid, isWin=is_win)
        if self.war_data.refresh_monster():
            if self.war_data.show_npcids:
                data.update(dict(npcids=self.war_data.show_npcids))
        self.send_msg(resp_f, data)
        if not war_end and is_pass:
            self.pass_scene(self.room.aid)

    def book_effect(self, pid, p_data, res_book):
        """ 使用书产生的效果 """
        if res_book.uncd:
            p_data.ktime = 0
        elif res_book.hard:
            if self.boat.hard >= self.boat.mhard:
                return False, errcode.EC_ALLY_WAR_HARDMAX
            self.boat.hard += res_book.hard
            if self.boat.mhard < self.boat.hard:
                self.boat.hard = self.boat.mhard
            book_data = (pid, res_book.hard)
            self.boat.hard_broad(book_data)
        elif res_book.buff:
            p_data.add_buff(res_book.buff)
        elif res_book.rexp:
            p_data.add_bookexp(int(res_book.rexp))
        return True, None

    def use_book(self, pid, bid):
        """ 天书的使用 """
        if self.war_data.war_end:
            return False, errcode.EC_ALLY_WAR_END
        res_book = Game.res_mgr.awar_books.get(bid)
        if res_book is None:
            return False, errcode.EC_NORES
        bid = str(bid)
        p_data = self.pid2pdata.get(pid)
        rs, data = p_data.handle_book_use(bid, res_book)
        if rs is False:
            return rs, data
        rs, data = self.book_effect(pid, p_data, res_book)
        if rs is False:
            return rs, data
        #消耗一本天书
        p_data.cost_book(bid)
        _, glory = Game.rpc_ally_mgr.get_glory_by_pid(pid)
        return True, dict(glory=glory)

    def connon_fire(self, pid, index):
        """ 开炮 """
        rs = self.boat.is_use(index)
        if rs:
            return False, errcode.EC_ALLY_WAR_FIRED
        now = common.current_time()
        self.boat.set_cannon(index, (pid, now))
        self.boat.cannon -= 1
        self.connon_fire_braod(pid, index)
        return True, None

    def connon_fire_braod(self, pid, index):
        """ 开炮广播 """
        if self.war_data.war_end:
            return
        resp_f = 'awarFireB'
        data = dict(pid=pid,
                    index=index,
                    cannon=self.boat.cannon,
        )
        self.send_msg(resp_f, data)


    def is_pass_scene(self):
        """ 是否通过本场景 """
        pass_scene = False
        win_ways = common.str2dict(self.war_per_config.winway, ktype=int, vtype=int)
        for type, value in win_ways.iteritems():
            if type == WAY_WIN_MONSTER and not self.war_data.m_npcids:
                pass_scene = True
            elif type == WAY_WIN_BOSSHP and self.war_data.boss_hp <= 0.01 * value * self.war_data.mboss_hp:
                pass_scene = True
            elif type == WAY_WIN_ALL and not self.war_data.m_npcids \
                    and self.war_data.boss_hp <= 0:
                pass_scene = True
        return pass_scene

    def get_box(self, pid):
        """ 获取宝箱 """
        p_data = self.pid2pdata.get(pid)
        if p_data:
            return True, p_data.rbox
        return False, errcode.EC_ALLY_WAR_IN

    def war_finish(self, reward_item=None):
        """ 通关 """
        pass

    def enter_next_scene(self):
        """ 进入下一场 """
        pass

    def is_win_war(self):
        """ 是否胜利 """
        war_type = self.war_per_config.type
        key = (war_type, self.war_per_config.fnum+1)
        next_war_config = Game.res_mgr.awar_per_configs_bykeys.get(key)
        if next_war_config is None:
            return True
        return False
    
    def send_msg(self, resp_f, data, remove_pid=0, send_pids=None):
        """ 主动发给客户端的数据 """
        msg = pack_msg(resp_f, 1, data=data)
        if not send_pids:
            if self.war_data:
                send_pids = self.war_data.war_pids[:]
            else:
                send_pids = self.room.pids[:]
            if remove_pid and remove_pid in send_pids:
                send_pids.remove(remove_pid)
        if send_pids:
            log.debug('broad-- pids-%s, resp_f-%s, data- %s', send_pids, resp_f, msg)
            Game.rpc_player_mgr.player_send_msg(send_pids, msg)

    def get_ally_data(self):
        """ 获取同盟等级和火炮等级 """
        ally_level = Game.rpc_ally_mgr.ally_level_by_aid(self.room.aid)
        _, fire_level = Game.rpc_ally_mgr.get_boat_type_level(self.room.aid, BOAT_POW)
        return ally_level, fire_level

    def war_result_borad(self, type):
        """ 结束广播 """
        if self.war_data.war_end:
            return
        self.war_data.war_end = True
        if type == ALLY_WAR_WIN:
            self.win_handle()
        resp_f = 'awarRs'
        if self.war_per_config.type == ALLY_WORLD_WAR:
            utime = common.current_time() - self.war_data.stime
            self.record_utime(utime)
            self.record_rs_war(type)
        data = dict(type=type)
        self.send_msg(resp_f, data)

    def win_handle(self):
        """ 通关的处理 """
        self.war_data.is_win = True
        #获胜的玩家
        Game.rpc_awar_mgr.set_win_pids(self.war_data.war_pids)

    def stop_war(self):
        """ 停止战斗 """
        if self.war_data.war_end:
            return
        self.war_result_borad(ALLY_WAR_FAIL_SYSCLOSE)

    @property
    def fetch_mcannon(self):
        return Game.setting_mgr.setdefault(AWAR_CONNON_MAX, AWAR_CONNON_MAX_V)

    @property
    def fetch_fire_desc(self):
        return Game.setting_mgr.setdefault(AWAR_FIRE_DESC, AWAR_FIRE_DESC_V)

    @property
    def fetch_boat_desc(self):
        return Game.setting_mgr.setdefault(AWAR_BOAT_DESC, AWAR_BOAT_DESC_V)

class BoatData(object):

    def __init__(self):
        #管理类
        self.war_mgr = None
        #天舟续航时间
        self.gtime = 0
        #天舟装炮时间
        self.ctime = 0
        #天舟炮弹火力
        self.cfire = 0
        #天舟耐久度
        self.hard = 0
        #天舟总的耐久度
        self.mhard = 0
        #天舟炮弹数目
        self.cannon = 0
        #开炮数据的保存{第几个炮index:(开炮玩家id, 开炮时间)}
        self.connon2data = {}


    def get_data(self):
        """ 获取当前的数据 """
        #当boss击打龙舟的时候发送耐久度给客户端
        pack_data = dict(gtime=self.gtime, ctime=self.ctime, cannon=self.cannon)
        if self.war_mgr.war_per_config.hurts:
            pack_data.update(dict(hard=self.hard, mhard=self.mhard))
        if self.connon2data:
            dic = {}
            now = common.current_time()
            for index, (pid, t) in self.connon2data.iteritems():
                l =  self.ctime - (now - t)
                if l > 0:
                    dic[index] = (pid, l)
            if dic:
                pack_data.update({'connon2data':dic})
        return pack_data

    @classmethod
    def new(cls, mgr, aid):
        _, (hard, cfire, ctime, gtime) = Game.rpc_ally_mgr.get_boat_init_params(aid)
        #gtime, ctime, cfire, hard = 60, 10, 40, 30000
        #cfire = 500000
        #ctime = 4
        log.debug('--------- %s, %s, %s, %s', gtime, ctime, cfire, hard)
        o = cls()
        o.war_mgr = mgr
        o.cannon = mgr.fetch_mcannon
        o.gtime = gtime
        o.ctime = ctime
        o.cfire = cfire
        o.hard = hard
        o.mhard = hard
        return o
    
    def hard_broad(self, book_data=None, boss_data=None):
        """ 广播天舟耐久度 """
        if self.war_mgr.war_data.war_end:
            return
        resp_f = 'awarHardB'
        data = dict(hard=self.hard)
        if book_data:
            data.update(dict(type=HARD_TYPE_BOOK, mhard=self.mhard))
        if boss_data:
            boss_hurts = boss_data
            desc = self.war_mgr.fetch_boat_desc % dict(hurt=boss_hurts)
            #desc = 'boss 袭击了天舟 天舟失去了 %d 耐久度' % boss_hurts
            data.update(dict(desc=desc, type=HARD_TYPE_BOSS))
        self.war_mgr.send_msg(resp_f, data)
        if self.hard <= 0:
            log.debug('self.hard %s',self.hard)
            self.war_mgr.war_result_borad(ALLY_WAR_FAIL_HARD)

    def get_cannon(self, index):
        """ 获取炮的数据 """
        return self.connon2data.get(index)

    def set_cannon(self, index, value):
        """ 设置炮的数据 """
        self.connon2data[index] = value

    def is_use(self, index):
        """ 该炮是否能使用中 """
        data = self.get_cannon(index)
        if data is None:
            return False
        _, use_time = data
        now = common.current_time()
        if now - use_time > self.ctime:
            self.connon2data.pop(index)
            return False
        return True

    def clear_cannon(self):
        """ 清楚炮数据 """
        self.connon2data.clear()
        log.debug('clear----------- %s', self.connon2data)

    def loop_connon(self):
        """ 处理打炮 """
        if not self.connon2data or self.war_mgr.war_data.war_end:
            return
        log.debug('loop_connon----------- %s', self.connon2data)
        now = common.current_time()
        hurt_pids = []
        for index, (pid, use_time) in self.connon2data.items():
            if now < use_time + self.ctime:
                continue
            hurt_pids.append(pid)
            self.connon2data.pop(index)
        return hurt_pids

    def add_hard(self, hard):
        """ 添加耐久度 """
        self.hard += hard

    def reduce_hard(self, hard):
        """ 减少耐久度 """
        self.hard -= hard


class PlayerWarData(object):

    def __init__(self):
        self.war_mgr = None
        self.pid = 0
        #玩家死亡时间记录
        self.ktime = 0
        #玩家拥有天书的保存{天书id:数目,...}
        self.bid2bookn = {}
        #天书使用时间记录{天书id:使用时间}
        self.bid2bookut = {}
        #天书可兑换的数量{天书id:可兑换的数目}
        self.bid2ebookn = {}
        #玩家buff保存{atk:2,hp:2...}
        self.pbuff = {}
        #玩家通关后的宝箱的奖励物品
        self.rbox = []
        #保存玩家开战的npcid
        self.fight_npcid = 0
        #使用成长天书额外添加经验百分比
        self.book_addexp = 0

    def get_data(self):
        """ 当前的数据 """
        pcdtime = self.war_mgr.war_per_config.cdtime
        _, glory = Game.rpc_ally_mgr.get_glory_by_pid(self.pid)
        pack_data = dict(glory=glory, books=self.bid2bookn, exbooks=self.bid2ebookn)
        now = common.current_time()
        l = pcdtime - (now - self.ktime)
        if l > 0:
            pack_data['cdtime'] = l
        if self.bid2bookut:
            dic = {}
            for bid, ut in self.bid2bookut.iteritems():
                res_book = Game.res_mgr.awar_books.get(int(bid))
                bcdtime = res_book.time
                l = bcdtime - (now - ut)
                if l > 0:
                    dic[bid] = l
            if dic:
                pack_data.update({'cdbooks':dic})
        return pack_data

    def save_monsster_fight(self, npcid):
        """ 保存当前玩家击打的npcid """
        self.fight_npcid = npcid

    @property
    def get_monster_fight(self):
        """ 获取玩家击打的npcid """
        return self.fight_npcid

    @classmethod
    def new(cls, mgr, pid):
        o = cls()
        o.war_mgr = mgr
        o.pid = pid
        o.bid2bookn = mgr.room.books.copy()
        o.bid2ebookn = mgr.room.ebooks.copy()
        return o

    def enough_book(self, bid):
        """ 是否有书的使用 """
        if self.bid2bookn.has_key(bid) and self.bid2bookn.get(bid) > 0:
            return True
        return False

    def exchange_book(self, bid, res_glory):
        """ 兑换天书 """
        num = self.bid2ebookn.get(bid)
        if num <= 0:
            return False, errcode.EC_ALLY_WAR_NOCHANGE
        self.bid2ebookn[bid] = num - 1
        #获取贡献值
        _, glory = Game.rpc_ally_mgr.get_glory_by_pid(self.pid)
        if glory < res_glory:
            return False, errcode.EC_ALLY_WAR_NOGLORY
        Game.rpc_ally_mgr.cost_glory(self.pid, res_glory)
        return True, None

    def handle_book_use(self, bid, res_book):
        """ 是否有足够的天书 如没有使用建设点兑换 """
        now = common.current_time()
        utime = self.bid2bookut.get(bid)
        if utime and utime + res_book.time > now:
            return False, errcode.EC_ALLY_WAR_CD
        num = self.bid2bookn.get(bid)
        if num is None:
            return False, errcode.EC_VALUE
        is_exchange = False
        if num <= 0:
            rs, data = self.exchange_book(bid, res_book.exchange)
            if rs is False:
                return rs, data
            is_exchange = True
        return True, is_exchange

    def cost_book(self, bid):
        """ 消耗天书 """
        self.bid2bookn[bid] -= 1
        self.bid2bookut[bid] = common.current_time()

    def add_buff(self, res_buff):
        """ 添加buff """
        res_buff = common.str2dict(res_buff)
        if not self.pbuff:
            self.pbuff = res_buff
        else:
            for k,v in res_buff.iteritems():
                if self.pbuff.has_key(k):
                    self.pbuff[k] += v
                else:
                    self.pbuff[k] = v
    
    def add_bookexp(self, rexp):
        """ 使用成长书添加经验百分比 """
        self.book_addexp += rexp
    
    def next_scene_clear(self):
        """ 进入下一场，还原不继承的数据 """
        #玩家的死亡记录(玩家死亡cd不记录到下一场战斗)
        self.ktime = 0

class WarData(object):

    def __init__(self):

        self.war_mgr = None
        #保存在战场玩家的pids(只在战场玩家)
        self.war_pids = None
        #当前场景boss血量
        self.boss_hp = 0
        #boss的总血量
        self.mboss_hp = 0
        #当前战场剩余小怪物的战斗npc配置表id
        self.m_npcids = []
        #当前战场出现怪物的npc配置表id
        self.show_npcids = []
        #当前战场大boss的配置表id
        self.b_npcid = 0
        #保存怪物属性{战斗npc配置表id:{怪物等级表id:{怪物属性}...}...}
        self.moster2mattr = {}
        #战斗中的保存{玩家id:怪物npc配置表...}
        self.pid2npcid = {}
        #当场战斗开启时间
        self.stime = 0
        #战斗结束
        self.war_end = False
        #战斗是否胜利
        self.is_win = False

    def clear(self):
        """ 到达第二关 """
        self.m_npcids = []
        self.show_npcids = []
        self.pid2npcid.clear()

    def clear_npc(self, npcid):
        """ 清楚战死的npc """
        if npcid in self.m_npcids:
            self.m_npcids.remove(npcid)
        if npcid in self.show_npcids:
            self.show_npcids.remove(npcid)

    def only_boss(self):
        """ 是否只有boss """
        if len(self.show_npcids) == 1 and\
           self.b_npcid in self.show_npcids:
            return True
        return False

    def start(self):
        """ 战斗开始 """
        self.stime = common.current_time()

    @classmethod
    def new(cls, mgr):
        o = cls()
        o.war_mgr = mgr
        o.war_pids = mgr.room.pids[:]
        return o

    def get_data(self):
        """ 获取当前战场数据 """
        self.refresh_monster()
        if self.b_npcid and self.boss_hp and self.b_npcid not in self.show_npcids:
            self.show_npcids.append(self.b_npcid)
        #npcids = self.m_npcids.extend(self.b_npcid)
        pack_data = dict(npcids=self.show_npcids)
        if self.boss_hp:
            pack_data.update(dict(boss_hp=self.boss_hp, mboss_hp=self.mboss_hp))
        #战场的剩余时间
        if self.stime:
            ltime = self.war_mgr.war_per_config.wtime - (common.current_time() - self.stime)
            pack_data.update(dict(ltime=ltime))
        if self.pid2npcid:
            waring_data = dict(pid2npcid=self.pid2npcid)
            pack_data.update(waring_data)
        return pack_data

    def init_monster(self, wpcid, extend_boss_hp=None):
        """ 初始化本场战斗的怪物数据 """
        res_war_npcs = Game.res_mgr.awar_npc_configs_bykey.get(wpcid)
        if res_war_npcs is None:
            return False, errcode.EC_NORES
        pids = self.war_mgr.room.pids[:]
        #获取参与玩家的信息
        a_level, a_cbe = self.player_average()
        for res_war_npc in res_war_npcs:
            if res_war_npc.bid:
                self.b_npcid = res_war_npc.id
            else:
                self.m_npcids.append(res_war_npc.id)
            data = {}
            #计算出每个怪物的属性
            res_mlids = common.str2list(res_war_npc.mlids, vtype=float)
            res_mlids = map(int, res_mlids)
            for res_mlid in res_mlids:
                m_attr = self.init_monster_attr(int(res_mlid), len(pids), a_level, a_cbe)
                data[res_mlid] = m_attr
                if res_war_npc.bid and not extend_boss_hp:
                    self.mboss_hp = self.boss_hp = m_attr['HP']
            self.moster2mattr[res_war_npc.id] = data
        return True, None

    def player_average(self):
        """ 计算玩家平均值 """
        pids = self.war_mgr.room.pids[:]
        _, p_infos = Game.rpc_player_mgr.get_player_infos(pids, CBE=1)
        a_level = 1
        a_cbe = 1
        num = len(pids)
        for p_info in p_infos.itervalues():
            _, _, level, cbe = p_info
            #TODO
            #cbe = level

            a_level *= level
            a_cbe *= cbe
        a_level = math.pow(a_level, 1.0/num)
        a_cbe = math.pow(a_cbe, 1.0/num)
        return a_level, a_cbe

    def refresh_monster(self):
        """ 刷出一波怪物 """
        refresh = 0
        if not self.show_npcids:
            refresh = 1
        elif len(self.show_npcids) == 1 and self.b_npcid in self.show_npcids:
            refresh = 1
        if refresh:
            self.show_npcids.extend(self.m_npcids[:self.war_mgr.war_per_config.refresh])
        return refresh


    def init_monster_attr(self, mlid, R, L, CBE):
        """ 初始化怪物的属性 """
        #获取同盟等级
        res_monster_level = Game.res_mgr.monster_levels.get(mlid)
        ally_level, fire_level = self.war_mgr.get_ally_data()
        res = res_monster_level.get_attr(R=R, L=L, CBE=CBE, AL=ally_level, FL=fire_level)
        return res

    def get_moster_attr(self, res_mconfig_id):
        """ 战斗怪物配置表获取怪物属性 """
        res_npc_config = Game.res_mgr.awar_npc_configs.get(res_mconfig_id)
        m_attr = self.moster2mattr.get(res_mconfig_id)
        if m_attr is None:
            return False
        if res_mconfig_id == self.b_npcid and m_attr.has_key(res_npc_config.bid):
            m_attr[res_npc_config.bid]['HP'] = self.boss_hp
        return m_attr


