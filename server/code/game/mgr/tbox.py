#!/usr/bin/env python
# -*- coding:utf-8 -*-

import time

from corelib import log, RLock
from store.store import StoreObj, GameObj

from game import BaseGameMgr, Game
from game.base import common
from game.base.msg_define import (MSG_START, MSG_TBOX_FPASS,
    MSG_TBOX_MPASS, MSG_TBOX_PASS, MSG_TBOX_MDIE)
from game.store import TN_P_TBOX, TN_P_TBOXNEWS
from game.base.constant import (WAITBAG_TYPE_TIMEBOX, TBOX_FREE_NUM, TBOX_FREE_NUM_V,
    TBOX_COIN_NUM, TBOX_COIN_NUM_V, TBOX_COINS, TBOX_COINS_V, TBOX_KILL_LEVEL,
    TBOX_KILL_LEVEL_V, PLAYER_ATTR_TBOX, PT_FT, PT_CH, PT_WAITS, REPORT_TYPE_TBOX,
    REPORT_TBOX_URL, PT_VIP, TBOX_HITE_TIME,
)
from game.glog.common import COIN_TBOX_RESET
from game.base import errcode
from game.base.msg_define import MSG_RES_RELOAD

import app

#章节
PLAYER_TBOX_CHAPTER = 'chapter'

#怪物死活monster
MONSTER_DIE = 0
MONSTER_LIVE = 1
#每章怪物数目
MONSTER_NUM = 5

#最高星级
TBOX_LEVEL_MAX = 5

#每个怪物的排名个数
ORDER_MAX = 3

#战报
#初始化战报
INIT_NEWS = [None, None, None]

#player_data索引
INDEX_ID = 0
INDEX_NAME = 1
INDEX_LEVEL = 2

#防止多人同时访问
def _wrap_lock(func):
    def _func(self, *args, **kw):
        with self._lock:
            return func(self, *args, **kw)
    return _func

class GTboxNewsMgr(object):
    """ 时光盒战报管理 """
    _rpc_name_ = 'rpc_tboxnews_mgr'
    def __init__(self):
        setattr(Game, self._rpc_name_, self)
        app.sub(MSG_START, self.start)
        #保存战报 {(章节id1, 时光盒基础表id1):[第一名对象,第二名对象,第三名对象]...}
        #该章有部分无名次 保存None{(章节id1, 时光盒基础表id1):[第一名对象, None, None]...}
        self.news = {}
        #
        self._lock = RLock()

    def start(self):
        all_news = Game.rpc_store.load_all(TN_P_TBOXNEWS)
        for news in all_news:
            oTboxNews = TboxNews(news)
            key = (oTboxNews.data.chapter, oTboxNews.data.tbid)
            tNews = self.news.setdefault(key, INIT_NEWS[:])
            #log.debug('tews----%s  %s', oTboxNews.data.ranking, key)
            if oTboxNews.data.ranking > ORDER_MAX:
                continue
            tNews[oTboxNews.data.ranking-1] = oTboxNews
            self.news[key] = tNews

    def clear(self):
        """ 清楚战报数据 """
        store = Game.rpc_store
        for news in self.news.itervalues():
            if not news:
                continue
            for new in news:
                if not new:
                    continue
                new.delete(store)
        self.news.clear()

    @_wrap_lock
    def handle_rank(self, player_data, aChapter, aHitLevel, aFight, tResTBoxId):
        """ 处理排名 """
        #log.debug('handle_rank :: %s', aFight)
        if not aFight:
            return False
        key = (aChapter, tResTBoxId)
        #log.debug('achapter : %s, tResTBoxId: %s', aChapter, tResTBoxId)
        all_news = self.news.setdefault(key, INIT_NEWS[:])
        for index, news in enumerate(all_news):
            if not news:
                self._add_news(player_data, aChapter, aHitLevel, index+1, aFight, tResTBoxId)
                return True
            if player_data[INDEX_ID] == news.data.pid:
                return False
            if not self._is_updae_rank(player_data, aHitLevel, aFight, news):
                continue
            self._update_news_rank(player_data, news, aHitLevel, aFight)
            return True
        return False

    def _is_updae_rank(self, player_data, aHitLevel, aFight, news):
        """ 判断条件是否要更新排名 """
        if aHitLevel < news.data.hitLevel:
            return False
        elif aHitLevel == news.data.hitLevel:
            if player_data[INDEX_LEVEL] > news.data.level:
                return False
            elif player_data[INDEX_LEVEL] == news.data.level:
                if aFight >= news.data.fight:
                    return False
        return True

    def _add_news(self, player_data, aChapter, aHitLevel, aRank, aFight, aResTBoxId):
        """ 添加战报 """
        oTboxNews = self._new_news(player_data, aChapter, aHitLevel, aRank, aFight, aResTBoxId)
        key = (aChapter, aResTBoxId)
        self.news[key][aRank-1] = oTboxNews

    def _new_news(self, player_data, aChapter, aHitLevel, aRank, aFight, aResTBoxId):
        """ 添加战报 """
        oTboxNews = TboxNews()
        oTboxNews.data.chapter = aChapter
        oTboxNews.data.tbid = aResTBoxId
        oTboxNews.data.ranking = aRank
        oTboxNews.data.pid = player_data[INDEX_ID]
        oTboxNews.data.name = player_data[INDEX_NAME]
        oTboxNews.data.hitLevel = aHitLevel
        oTboxNews.data.level = player_data[INDEX_LEVEL]
        oTboxNews.data.fight = aFight
        #保存数据到数据库
        store = Game.rpc_store
        oTboxNews.save(store)
        return oTboxNews

    def _update_news_rank(self, player_data, aTboxNews, aHitLevel, aFight):
        """ 更新战报 """
        oTboxNews = self._new_news(player_data, aTboxNews.data.chapter,
            aHitLevel, aTboxNews.data.ranking, aFight, aTboxNews.data.tbid)
        key = (aTboxNews.data.chapter, aTboxNews.data.tbid)
        all_news = self.news[key]
        #log.debug('len(all_news) = %s',len(all_news))
        all_news.insert(oTboxNews.data.ranking-1, oTboxNews)
        all_len = len(all_news)
        store = Game.rpc_store
        while all_len > ORDER_MAX:
            all_len -= 1
            box_news = all_news.pop()
            if not box_news:
                continue
            store.delete(TN_P_TBOXNEWS, box_news.data.id)
        for index, tbox_news in enumerate(all_news):
            rank = index + 1
            if tbox_news and rank != tbox_news.data.ranking:
                tbox_news.data.ranking = rank
                store.save(TN_P_TBOXNEWS, tbox_news.to_dict())

    def sub_news(self, pid, chapter, tbid, war_news):
        """ 提交战报 """
        key = (chapter, tbid)
        #log.debug('sub_news--key = %s, len = %s', key, len(war_news))
        if not self.news.has_key(key):
            return False, errcode.EC_TBOX_NORANK
        newsList = self.news[key]
        o = None
        for o in newsList:
            if o is None:
                return False, errcode.EC_TBOX_NORANK
            if o.data.pid != pid:
                continue
            self.save_war_news(key, o, war_news)
            break
        if not o:
            return False, errcode.EC_TBOX_NORANK
        return True, None

    def save_war_news(self, key, news, war_news):
        """ 保存战报 """
        file = '%d_%d_%d_%d' % (key[0], key[1], news.data.ranking, int(time.time()))
        pids = [news.data.pid]
        fid = Game.rpc_report_mgr.save(REPORT_TYPE_TBOX, pids, war_news,
            url=[REPORT_TBOX_URL, file])
        news.data.fid = fid
        store = Game.rpc_store
        store.save(TN_P_TBOXNEWS, news.to_dict())

    def get_rank(self, aChapter, tbid):
        """ 获取排名 """
        key = (aChapter, tbid)
        if not self.news.has_key(key):
            return False, errcode.EC_TBOX_NORANK
        send = []
        for news in self.news[key]:
            if not news:
                continue
            send.append({'rank':news.data.ranking,
                         'name':news.data.name,
                         'fid':news.data.fid})
        return True, {'ranks': send}

    def get_news(self, key, rank):
        """ 获取战报 """
        if self.news.has_key(key):
            tBoxNews = self.news[key][rank-1]
            return True, tBoxNews.data.news
        return False, errcode.EC_TBOX_NORANK

def new_tboxnews_mgr():
    mgr = GTboxNewsMgr()
    return mgr


class TboxMgr(BaseGameMgr):
    """ 时光盒管理类 """
    def __init__(self, game):
        super(TboxMgr, self).__init__(game)
        self._free_nums = 0
        self.set_active_num(0)


    def start(self):
        """ 开启时光盒管理器 """
        self._game.sub(MSG_RES_RELOAD, self.lood)
        self.lood()

    def init_player_tbox(self, player):
        """ 获取玩家时光管理对象 """
        oPTboxDatas = getattr(player.runtimes, TN_P_TBOX, None)
        if oPTboxDatas is None:
            oPTboxDatas = PlayTbox(player, self)
            oPTboxDatas.load()
            setattr(player.runtimes, TN_P_TBOX, oPTboxDatas)
        return oPTboxDatas
    
    def enter(self, player, aChapter):
        """ 进入指定章节的时光盒 """
        ptbox = self.init_player_tbox(player)
        return ptbox.enter(aChapter)

    def hit_end(self, player, aChapter, aFight=0, aLevel=0):
        """ 猎怪结束 """
        ptbox = self.init_player_tbox(player)
        rs, data, tResTBoxId = ptbox.hit_end(aChapter, aLevel)
        if rs is False:
            return rs, data
        if data['sub']:
            rpc_news = self._game.rpc_tboxnews_mgr
            player_data = (player.data.id, player.data.name, player.data.level)
            rs = rpc_news.handle_rank(player_data, aChapter, aLevel, aFight, tResTBoxId)
            data['sub'] = rs
        return True, data

    def reset(self, player, aChapter):
        """ 重置 """
        ptbox = self.init_player_tbox(player)
        return  ptbox.reset(aChapter)

    def kill(self, player, aChapter):
        """ 秒杀 """
        ptbox = self.init_player_tbox(player)
        return ptbox.kill(aChapter)

    def get_rank(self, aChapter, tbid):
        """ 获取排名 """
        return self._game.rpc_tboxnews_mgr.get_rank(aChapter, tbid)

    def get_news(self, chapter, tbid, rank):
        """ 获取战报 """
        if rank > 3 or rank < 1:
            return False, errcode.EC_VALUE
        key = (chapter, tbid)
        return self._game.rpc_tboxnews_mgr.get_news(key, rank)

    def sub_news(self, pid, chapter, tbid, war_news):
        """ 提交战报 """
        return self._game.rpc_tboxnews_mgr.sub_news(pid, chapter, tbid, war_news)

    def add_monster(self, player, res_tbox_id):
        """ 完成某任务将怪物添加到时光盒 """
        if 1:
            return
        tResTbox = self._game.res_mgr.tboxs.get(res_tbox_id)
        if not tResTbox:
            return False, errcode.EC_NORES
        ptbox = self.init_player_tbox(player)
        if not ptbox.p_tboxs.has_key(tResTbox.chapter):
            #添加章节
            obox = self._new_box(player, ptbox, tResTbox.chapter, res_tbox_id)
            ptbox.p_tboxs[tResTbox.chapter] = obox
            return
        #更新章节
        tPTbox = ptbox.p_tboxs[tResTbox.chapter]
        if len(tPTbox.data.tbids) >= MONSTER_NUM or res_tbox_id in tPTbox.data.tbids:
            return
        tPTbox.data.tbids.append(res_tbox_id)
        tPTbox.data.isLives.append(MONSTER_LIVE)
        tPTbox.data.levels.append(0)
        ptbox.p_tboxs[tResTbox.chapter] = tPTbox
        ptbox.update_tbox(tPTbox)
        return

    def _new_box(self, player, ptbox, chapter, res_tbox_id):
        """ 新建时光盒数据 """
        free_num =  self.get_free_num(ptbox.p_attr[PT_VIP])
        tCoinNum = self._game.setting_mgr.setdefault(TBOX_COIN_NUM, TBOX_COIN_NUM_V)
        oTbox = TBox()
        oTbox.data.pid = player.data.id
        oTbox.data.chapter = chapter
        oTbox.data.tbids = [res_tbox_id]
        oTbox.data.isLives = [MONSTER_LIVE]
        oTbox.data.levels = [0]
        oTbox.data.re1 = free_num
        oTbox.data.re2 = tCoinNum
        return oTbox

    def get_free_num(self, vip):
        """ 根据玩家vip获取免费重置次数 """
        return self._free_nums(vip) + self._active_num

    def lood(self):
        free_nums = self._game.setting_mgr.setdefault(TBOX_FREE_NUM, TBOX_FREE_NUM_V)
        self.set_max_free_num(free_nums)

    def set_max_free_num(self, num_str):
        self._free_nums = common.make_lv_regions(num_str)

    def set_active_num(self, num):
        self._active_num = num


class TBoxNewsData(StoreObj):
    __slots__ = ('id', 'chapter', 'tbid', 'ranking', 'fid', 'pid',
                 'name', 'hitLevel','level', 'fight'
        )
    def init(self):
        #ID(id, int)
        self.id = None
        #章节(chapter, int)
        self.chapter = 0
        #基础表时光盒id(tbid, int)
        self.tbid = 0
        #名次(ranking, int)
        self.ranking = 0
        #战报id(fid, int)
        self.fid = 0
        #角色id(pid, str)
        self.pid = 0
        #角色名字(name, str)
        self.name = ""
        #猎怪星级(hitLevel, int)
        self.hitLevel = 0
        #角色等级(level, int)
        self.level = 0
        #角色战斗力(fight, int)
        self.fight = 0

class TboxNews(GameObj):
    __slots__ = GameObj.__slots__
    TABLE_NAME = TN_P_TBOXNEWS
    DATA_CLS = TBoxNewsData
    def __init__(self, adict=None):
        super(TboxNews, self).__init__(adict=adict)

    def update(self, adict):
        super(TboxNews, self).update(adict)

class TBoxData(StoreObj):
    __slots__ = ('id', 'pid', 'chapter', 'tbids', 'isLives', 'levels', 're1', 're2')
    def init(self):
        #ID(id, int)
        self.id = None
        #玩家id
        self.pid = 0
        #章节(chapter, int)
        self.chapter = 0
        #时光盒boss id(tbids, str)
        self.tbids = []
        #怪物是否存活(isLives, str)
        self.isLives = []
        #猎怪的最好星级(Levels, str)
        self.levels = []
        #当天免费剩余重置次数(re1, int)
        self.re1 = 0
        #当天元宝剩余重置次数(re2, int)
        self.re2 = 0

class TBox(GameObj):
    __slots__ = GameObj.__slots__
    TABLE_NAME = TN_P_TBOX
    DATA_CLS = TBoxData
    def __init__(self, adict=None):
        super(TBox, self).__init__(adict=adict)

    def new_tbox(self, pid, chapter, res_tboxids, re1, re2):
        """ 直接添加某章的所有怪物 """
        self.data.pid = pid
        self.data.chapter = chapter
        self.data.tbids = res_tboxids
        self.data.isLives = [MONSTER_LIVE] * MONSTER_NUM
        self.data.levels = [0] * MONSTER_NUM
        self.data.re1 = re1
        self.data.re2 = re2
    
    def update_tbox(self, res_tboxids):
        """ 补全该章未出现的怪物 """
        self.data.tbids = res_tboxids
        self.data.isLives = [MONSTER_LIVE] * MONSTER_NUM
        self.data.levels = [0] * MONSTER_NUM

class PlayTbox(object):
    """ 玩家数据管理类 """
    def __init__(self, player, tbox_mgr):
        self.player = player
        self.tbox_mgr = tbox_mgr
        #玩家数据 {章节id1：o1时间盒,...}
        self.p_tboxs = {}
        #玩家属性数据 {k:v, ...}
        self.p_attr = {}
        #记录打完怪物的时间
        self.hit_end_time = 0

    def __getstate__(self):
        return self.p_tboxs, self.p_attr, self.hit_end_time

    def __setstate__(self, data):
        self.p_tboxs, self.p_attr, self.hit_end_time = data


    def uninit(self):
        self.player = None
        self.p_tboxs = {}
        self.p_attr = {}

    def load(self, player = None):
        """ 获取数据 """
        tTBoxs = self.player._game.rpc_store.query_loads(TN_P_TBOX, dict(pid=self.player.data.id))
        for tTBox in tTBoxs:
            o = TBox(tTBox)
            self.p_tboxs[tTBox[PLAYER_TBOX_CHAPTER]] = o    
        v = self.player.play_attr.get(PLAYER_ATTR_TBOX)
        if v is None:
            v = self.make_tbox_data()
            self.player.play_attr.set(PLAYER_ATTR_TBOX, v)
        if not v.has_key(PT_VIP):
            v[PT_VIP] = self.player.data.vip
        self.p_attr = v
        self.add_monster()

    def add_monster(self):
        """ 添加所有的时光盒怪物 """
        chapter_id = self.player.data.chapter
        pid = self.player.data.id
        r1 =  self.tbox_mgr.get_free_num(self.p_attr[PT_VIP])
        r2 = self.player._game.setting_mgr.setdefault(TBOX_COIN_NUM, TBOX_COIN_NUM_V)
        res_mgr = self.player._game.res_mgr
        while chapter_id > 1:
            res_tbox_ids = res_mgr.tboxs_by_chapter.get(chapter_id)
            res_tbox_ids.sort()
            if self.p_tboxs.has_key(chapter_id):
                tbox = self.p_tboxs.get(chapter_id)
                if len(tbox.data.tbids) < MONSTER_NUM:
                    tbox.update_tbox(res_tbox_ids)
            else:
                res_chapter = res_mgr.chapters.get(chapter_id)
                #第一章直接加入
                if chapter_id == 2 or res_chapter.startTid in self.player.task.tid_bm:
                    oTbox = TBox()
                    oTbox.new_tbox(pid, chapter_id, res_tbox_ids, r1, r2)
                    self.p_tboxs[chapter_id] = oTbox
            chapter_id -= 1

    def gm_change_data(self, chapter, tbids):
        """ gm改变时光盒数据 """
        tbox = self.p_tboxs.get(chapter)
        if not tbox or not tbids:
            return False
        tbids = tbids.split(',')
        tbids = map(int, tbids)
        old_tbids_len = len(tbox.data.tbids)
        tbox.data.tbids = tbids
        new_tbids_len = len(tbids)
        if new_tbids_len == old_tbids_len:
            return True
        if new_tbids_len > old_tbids_len:
            add_num = new_tbids_len - old_tbids_len
            for i in xrange(add_num):
                tbox.data.isLives.append(MONSTER_LIVE)
                tbox.data.levels.append(0)
        else:
            tbox.data.isLives = tbox.data.isLives[:new_tbids_len]
            tbox.data.levels = tbox.data.levels[:new_tbids_len]
        return True

    def make_tbox_data(self):
        """ 创建玩家属性表结构 """
        return {PT_FT:int(time.time()), PT_CH:0, PT_WAITS:[], PT_VIP:self.player.data.vip}

    def save(self, store):
        """ 保存数据 """
        for tPTbox in self.p_tboxs.itervalues():
                tPTbox.save(store)
        self.player.play_attr.update_attr({PLAYER_ATTR_TBOX:self.p_attr})

    def copy_from(self, player):
        from_p_tboxs = getattr(player.runtimes, TN_P_TBOX)
        if from_p_tboxs is None:
            return
        import copy
        from_p_tboxs = copy.deepcopy(from_p_tboxs.p_tboxs)
        if self.p_tboxs:
            for o in self.p_tboxs.itervalues():
                o.delete(self.player._game.rpc_store)
            self.p_tboxs = {}
        if not from_p_tboxs and not self.p_tboxs:
            return
        for o in from_p_tboxs.itervalues():
            #log.debug('chapter1---[%s]', o.data.chapter)
            no = TBox(adict=o.data.to_dict())
            no.data.id = None
            no.data.pid = self.player.data.id
            no.save(self.player._game.rpc_store)
            self.p_tboxs[no.data.chapter] = no

    def handle_pass_day(self, fetch=False):
        """ 处理超过一天(超过则更新数据)
        fetch 处理待收取 超过凌晨时更新数据 """
        #判断是否已过一天
        if common.is_pass_day(self.p_attr[PT_FT]):
            #更新时光盒数据
            setting_mgr = self.player._game.setting_mgr
            tCoinNum = setting_mgr.setdefault(TBOX_COIN_NUM, TBOX_COIN_NUM_V)
            #log.debug('p_tboxs::[%s]', self.p_tboxs)
            for tbox in self.p_tboxs.itervalues():
                tbox.data.isLives = [MONSTER_LIVE]*len(tbox.data.tbids)
                tbox.data.re1 = self.tbox_mgr.get_free_num(self.player.data.vip)
                tbox.data.re2 = tCoinNum
                self.update_tbox(tbox)
            #更新玩家属性
            if not fetch:
                del_wids = []
                for wid in self.p_attr[PT_WAITS]:
                    #删除待收物品
                    self.player.wait_bag.delete(wid)
                    del_wids.append(wid)
                self.p_attr[PT_CH] = 0
                self.p_attr[PT_WAITS] = []
                self.p_attr[PT_FT] = int(time.time())
                self.p_attr[PT_VIP] = self.player.data.vip
                return del_wids
        return

    def _handle_vip_up(self):
        """ vip升级增加差值的免费重置次数 """
        if isinstance(self.p_attr[PT_WAITS], int):
            self.p_attr[PT_WAITS] = []
        now_vip = self.player.data.vip
        old_vip = self.p_attr[PT_VIP]
        if now_vip == old_vip:
            return
        old_free_num = self.tbox_mgr.get_free_num(old_vip)
        now_free_num = self.tbox_mgr.get_free_num(now_vip)
        add_num = now_free_num - old_free_num
        for tbox in self.p_tboxs.itervalues():
            tbox.data.re1 += add_num
            self.update_tbox(tbox)
        self.p_attr[PT_VIP]= now_vip


    def enter(self, aChapter):
        """ 进入指定章节的时光盒 """
        if not self.p_tboxs:
            return False, errcode.EC_TBOX_NOCHAPTER
        self._handle_vip_up()
        #处理超过一天的待收物品
        del_wids = self.handle_pass_day()
        data = {}
        if del_wids:
            data = self.player.pack_msg_data(del_wids=del_wids)
        #是否有待收物品
        if self.p_attr[PT_CH] and self.p_attr[PT_WAITS]:
            aChapter = self.p_attr[PT_CH]
        keys = self.p_tboxs.keys()
        keys.sort()
        max_cid = keys[-1]
        if self.player.data.chapter > max_cid:
            self.add_monster()
        if not self.p_tboxs.has_key(aChapter):
            aChapter = max_cid
        data.update({'tbox':self.p_tboxs[aChapter].to_dict(), 'maxc':max_cid})
        #log.debug('enter - aChapter::[%s]', aChapter)
        return True, data

    def get_bids(self):
        """获取所有通过的时光盒BOSS id"""
        rs = {}
        for tbox in self.p_tboxs.itervalues():
            bids = rs.setdefault(tbox.data.chapter, [])
            win_tbids = []
            for i, level in enumerate(tbox.data.levels):
                if level:
                    win_tbids.append(tbox.data.tbids[i])
            bids.extend(win_tbids)
        return rs

    def hit_end(self, chapter, aLevel=0):
        """ 猎怪结束 """
        #log.debug('hit_end::[%s]', chapter)
        now = common.current_time()
        use_time = now - self.hit_end_time
        self.hit_end_time = now
        if use_time < TBOX_HITE_TIME:
            return False, errcode.EC_VALUE, None
        if not self.p_tboxs.has_key(chapter):
            return False, errcode.EC_TBOX_NOCHAPTER, None
        tPTbox = self.p_tboxs[chapter]
        tPlace = tPTbox.data.isLives.count(MONSTER_DIE)
        is_kill_first = tPTbox.data.levels[tPlace]
        #当前星级高于上一次星级才保存
        if aLevel and aLevel > tPTbox.data.levels[tPlace]:
            old_level = tPTbox.data.levels[tPlace]
            tPTbox.data.levels[tPlace] = aLevel
            self.handle_horn(tPTbox, old_level, chapter)
        tPTbox.data.isLives[tPlace] = MONSTER_DIE
        #获取奖励
        tResTBoxId = tPTbox.data.tbids[tPlace]
        tResTBox = self.player._game.res_mgr.tboxs.get(tResTBoxId)
        tRw = self.player._game.reward_mgr.get(tResTBox.rid)
        tRsTtem = tRw.reward(params=self.player.reward_params())
        #添加到待收物品
        oWaitItem = self.player.wait_bag.add_waitItem(WAITBAG_TYPE_TIMEBOX, tRsTtem)
        #更新时光盒数据
        self.update_tbox(tPTbox)
        rs = self.player.pack_msg_data(waits=[oWaitItem])
        #更新玩家属性
        self.p_attr[PT_CH] = chapter
        self.p_attr[PT_WAITS] = [oWaitItem.data.id]
        #判断是否能排到名词
        rs['sub'] = False
        if not is_kill_first:
            rs['sub'] = True
        rs['tbox'] = tPTbox.to_dict()
        #log.debug('tResTBoxId::[%s]', tResTBoxId)
        #通关广播
        if tPlace +1 == MONSTER_NUM:
            self.player.pub(MSG_TBOX_PASS, chapter)
        return True, rs, tResTBoxId

    def handle_horn(self, p_tbox, old_level, chapter_id):
        """ 处理大喇叭广播 """
        num = len(p_tbox.data.tbids)
        if num != MONSTER_NUM:
            return
        is_levels_max = True
        is_pass = True
        if old_level:
            is_pass = False
        for level in p_tbox.data.levels:
            if is_pass and not level:
                is_pass = False
            if is_levels_max and level != TBOX_LEVEL_MAX:
                is_levels_max = False
        #本章第一次通关
        if is_pass:
            self.player.pub(MSG_TBOX_FPASS, chapter_id)
        #本章第一次五星通关广播
        if is_levels_max:
            self.player.pub(MSG_TBOX_MPASS, chapter_id)

    def reset(self, chapter):
        """ 重置 """
        if not self.p_tboxs.has_key(chapter):
            return False, errcode.EC_TBOX_NOCHAPTER
        tPTbox = self.p_tboxs[chapter]
        if not tPTbox.data.re1 and not tPTbox.data.re2:
            return False, errcode.EC_TBOX_NORESET
        data = {}
        if tPTbox.data.re1:
            tPTbox.data.re1 -= 1
        else:
            tCoin2 = self._get_reset_coin(tPTbox.data.re2)
            tCoin2 = tCoin2 * tPTbox.data.isLives.count(MONSTER_DIE)
            if not self.player.cost_coin(aCoin2 = tCoin2, log_type=COIN_TBOX_RESET):
                return False, errcode.EC_COST_ERR
            tPTbox.data.re2 -= 1
            data = self.player.pack_msg_data(coin=True)
        #更新时waitFetch光盒
        tPTbox.data.isLives = len(tPTbox.data.isLives) * [MONSTER_LIVE]
        self.update_tbox(tPTbox)
        #清空待收物品
        self.delete_wait()
        data.update({'tbox':tPTbox.to_dict()})
        return True, data

    def delete_wait(self):
        """ 清楚玩家待收物品 """
        if self.p_attr[PT_CH]:
            self.p_attr[PT_CH] = 0
            for wid in self.p_attr[PT_WAITS]:
                self.player.wait_bag.delete(wid)
            self.p_attr[PT_WAITS] = []

    def kill(self, aChapter):
        """ 秒杀 """
        if not self.p_tboxs.has_key(aChapter):
            return False, errcode.EC_TBOX_NOCHAPTER
        tPTbox = self.p_tboxs[aChapter]
        tResLevel = self.player._game.setting_mgr.setdefault(TBOX_KILL_LEVEL, TBOX_KILL_LEVEL_V)
        if self.player.data.level < tResLevel:
            return False, errcode.EC_NOLEVEL
        if len(tPTbox.data.tbids) != MONSTER_NUM:
            return False, errcode.EC_TBOX_KILL_NOCOND
        wait_ids = []
        tRsTtems = []
        #首先检查是否全部5星,否则不处理
        for i in xrange(MONSTER_NUM):
            if tPTbox.data.levels[i] != TBOX_LEVEL_MAX:
                return False, errcode.EC_TBOX_KILL_NOCOND
        kill_num = 0
        for i in xrange(MONSTER_NUM):
            if not tPTbox.data.isLives[i]:
                continue
            kill_num += 1
            tPTbox.data.isLives[i] = MONSTER_DIE
            tResTBoxId = tPTbox.data.tbids[i]
            tResTBox = self.player._game.res_mgr.tboxs.get(tResTBoxId)
            tRw = self.player._game.reward_mgr.get(tResTBox.rid)
            tRsTtem = tRw.reward(params=self.player.reward_params())
            tRsTtems.extend(tRsTtem)
        self.player.pub(MSG_TBOX_MDIE, kill_num)
        #添加到待收物品
        oWaitItem = self.player.wait_bag.add_waitItem(WAITBAG_TYPE_TIMEBOX, tRsTtems)
        if not oWaitItem:
            return False, errcode.EC_TBOX_KILL_NOMONSTER
        #更新玩家属性
        self.p_attr[PT_CH] = aChapter
        self.p_attr[PT_WAITS] = wait_ids
        #更新时光盒数据
        self.update_tbox(tPTbox)
        rs = self.player.pack_msg_data(waits=[oWaitItem])
        rs['tbox'] = tPTbox.to_dict()
        return True, rs

    def _get_reset_coin(self, aNum):
        """ 获取元宝重置的元宝数 """
        tRes = self.player._game.setting_mgr.setdefault(TBOX_COINS, TBOX_COINS_V)
        if isinstance(tRes, int):
            return tRes
        tValues = tRes.split('|')
        return int(tValues[-aNum])

    def update_tbox(self, aPTbox):
        """ 玩家时光盒更新 """
        aPTbox.modify()

