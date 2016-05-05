#!/usr/bin/env python
# -*- coding:utf-8 -*-
import time
from hashlib import md5

from functools import partial
from socket import error
from collections import OrderedDict

from corelib import sleep, spawn, log, message, json
from corelib.common import strptime

from game import Game
from game.base.constant import (TT_OFFER, DAYLUCKY_TYPE_NO,
    DAYLUCKY_TYPE_BLOGIN, DAYLUCKY_TYPE_ALOGIN,
)
from game.base.msg_define import MSG_RES_RELOAD
from game.base.common import RandomRegion, str2dict, str2list, str2dict2
from game.store.define import *
from .role import *
from .arm import *
from .equip import *
from .fate import *
from .group import *
from .item import *
from .scene import *
from .sprite import *
from .task import *
from .fete import *
from .fish import *
from .buff import *
from .tbox import *
from .deep import *
from .mining import *
from .shop import *
from .ally import *
from .direct_shop import *
from .boss import *
from .reward_online import *
from .horn import *
from .achievement import *
from .gem import *
from .day_lucky import *
from .roleup import *
from .ally_war import *

import config
from langcvt import langconv

def res_load(self, adict, tname, cls, querys=None):
    rpc_store = Game.rpc_res_store
    if querys is None:
        objs = cls.new_from_list(rpc_store.load_all(tname))
    else:
        objs = cls.new_from_list(rpc_store.query_loads(tname, querys))
    adict.clear()
    func_name = '_init_%s' % tname
    func = getattr(self, func_name, None)
    if callable(func):
        rs = func(objs)
        if rs: #已经处理,直接退出
            return
    adict.update(dict([(o.id, o) for o in objs]))
    func = getattr(self, '_after_init_%s' % tname, None)
    if callable(func):

        func()
def mk_time(st, fmt):
    """
    改变时间
    """
    t = strptime(str(st), fmt)
    return time.mktime(t.timetuple())

@message.observable
class ResMgr(object):
    def __init__(self):
        self.init()
        self._loop_task = None
        if 0:
            from game.store import CacheStore
            self.rpc_store = CacheStore()

    @property
    def rpc_store(self):
        return Game.rpc_res_store

    def init(self):
        self.tables = OrderedDict()
        self.roles = {}
        self.role_levels = {}
        self.role_exps = {}
        self.arms = {}
        self.arm_levels = {}
        self.arm_exps = {}
        self.skills = {}
        self.equips = {}
        self._equip_rates = {} #装备不同套装概率表

        self.equip_levels = {}
        self.equip_sets = {}
        self.strong_equips = {}
        self.fates = {}
        self._fate_rates = {} #命格不同属性概率表
        self.fate_levels = {}
        self.fate_rates = {}
        self.fate_costs = {}
        self.items = {}
        self.fusions = {}
        self.rewards = {}
        self.monsters = {}
        self.monster_levels = {}
        self.npcs = {}
        self.cars = {}
        self.group_levels = {}
        self.maps = {}
        self.stages = {}
        self.fights = {}
        self.positions = {}
        self.position_levels = {} #以(pid, level)作为键
        self.chapters = {}
        self.tasks = {}
        self.bftasks = {}
        self.bfrates = {}
        self._bf_rates = {} #不同(类型，位置)的概率表
        self.fete_rates = {}
        self.fish_qualitya = {}
        self.buffs = {}
        self.tboxs = {}
        self.mines_normals = {}
        self.mines_vips = {}
        self.deep_boxs = {}
        self.deep_poses = {}
        self.deep_guards = {}
        self.shop_items = {}
        self.shop_rares = {}
        self.direct_shop = {}
        self.ally_levels = {}
        self.ally_rights = {}
        self.ally_graves = {}
        self.ally_exchanges = {}
        self.ally_boat_levels = {}
        self.reward_onls = {}
        self.reward_setts = {}
        self.reward_actives = {}
        self.reward_mails = {}
        self.boss_cd = {}
        self.boss_level = {}
        self.boss_reward = {}
        self.hornmsgs = {}
        self.achi_day = {}
        self.achi_eternal = {}
        self.gem = {}
        self.gem_levels = {} #key (gid, level)
        self.gem_up_rate = {}
        self.gem_shop_items = {}
        self.names = {}
        self.day_luckys = {}
        self.roleups = {}
        self.roleup_typs = {}
        self.awar_start_configs = {}
        self.awar_per_configs = {}
        self.awar_npc_configs = {}
        self.awar_books = {}
        self.awar_strong_maps = {}
        self.awar_world_scores = {}
        self.awar_world_assesses = {}

        self.tables[TN_RES_ROLE] = partial(res_load, self, self.roles, TN_RES_ROLE, ResRole)
        self.tables[TN_RES_ROLE_LEVEL] = partial(res_load, self, self.role_levels, TN_RES_ROLE_LEVEL, ResRoleLevel)
        self.tables[TN_RES_ROLE_EXP] = partial(res_load, self, self.role_exps, TN_RES_ROLE_EXP, ResRoleExp)
        self.tables[TN_RES_ARM] = partial(res_load, self, self.arms, TN_RES_ARM, ResArm)
        self.tables[TN_RES_ARM_LEVEL] = partial(res_load, self, self.arm_levels, TN_RES_ARM_LEVEL, ResArmLevel)
        self.tables[TN_RES_ARM_EXP] = partial(res_load, self, self.arm_exps, TN_RES_ARM_EXP, ResArmExp)
        self.tables[TN_RES_SKILL] = partial(res_load, self, self.skills, TN_RES_SKILL, ResSkill)
        self.tables[TN_RES_EQUIP] = partial(res_load, self, self.equips, TN_RES_EQUIP, ResEquip)
        self.tables[TN_RES_EQ_LEVEL] = partial(res_load, self, self.equip_levels, TN_RES_EQ_LEVEL, ResEquipLevel)
        self.tables[TN_RES_EQ_SET] = partial(res_load, self, self.equip_sets, TN_RES_EQ_SET, ResEquipSet)
        self.tables[TN_RES_STR_EQ] = partial(res_load, self, self.strong_equips, TN_RES_STR_EQ, ResStrongEquip)
        self.tables[TN_RES_FATE_LEVEL] = partial(res_load, self, self.fate_levels, TN_RES_FATE_LEVEL, ResFateLevel)
        self.tables[TN_RES_FATE] = partial(res_load, self, self.fates, TN_RES_FATE, ResFate)
        self.tables[TN_RES_FATE_RATE] = partial(res_load, self, self.fate_rates, TN_RES_FATE_RATE, ResFateRate)
        self.tables[TN_RES_FATE_COST] = partial(res_load, self, self.fate_costs, TN_RES_FATE_COST, ResFateCost)
        self.tables[TN_RES_ITEM] = partial(res_load, self, self.items, TN_RES_ITEM, ResItem)
        self.tables[TN_RES_FUSION] = partial(res_load, self, self.fusions, TN_RES_FUSION, ResFusion)
        self.tables[TN_RES_REWARD] = partial(res_load, self, self.rewards, TN_RES_REWARD, ResReward)
        self.tables[TN_RES_MONSTER] = partial(res_load, self, self.monsters, TN_RES_MONSTER, ResMonster)
        self.tables[TN_RES_MONSTER_LEVEL] = partial(res_load, self, self.monster_levels, TN_RES_MONSTER_LEVEL, ResMonsterLevel)
        self.tables[TN_RES_NPC] = partial(res_load, self, self.npcs, TN_RES_NPC, ResNpc)
        self.tables[TN_RES_CAR] = partial(res_load, self, self.cars, TN_RES_CAR, ResCar)
        self.tables[TN_RES_GROUP_LEVEL] = partial(res_load, self, self.group_levels, TN_RES_GROUP_LEVEL, ResGroupLevel)
        self.tables[TN_RES_MAP] = partial(res_load, self, self.maps, TN_RES_MAP, ResMap)
        self.tables[TN_RES_STAGE] = partial(res_load, self, self.stages, TN_RES_STAGE, ResStage)
        self.tables[TN_RES_FIGHT] = partial(res_load, self, self.fights, TN_RES_FIGHT, ResFight)
        self.tables[TN_RES_POSITION] = partial(res_load, self, self.positions, TN_RES_POSITION, ResPosition)
        self.tables[TN_RES_POS_LEVEL] = partial(res_load, self, self.position_levels, TN_RES_POS_LEVEL, ResPositionLevel)
        self.tables[TN_RES_FETE_REATE] = partial(res_load, self, self.fete_rates, TN_RES_FETE_REATE, ResFeteRate)
        self.tables[TN_RES_CHAPTER] = partial(res_load, self, self.chapters, TN_RES_CHAPTER, ResChapter)
        self.tables[TN_RES_TASK] = partial(res_load, self, self.tasks, TN_RES_TASK, ResTask)
        self.tables[TN_RES_BF_TASK] = partial(res_load, self, self.bftasks, TN_RES_BF_TASK, ResBfTask)
        self.tables[TN_RES_BF_RATE] = partial(res_load, self, self.bfrates, TN_RES_BF_RATE, ResBfRate)
        self.tables[TN_RES_FISH] = partial(res_load, self, self.fish_qualitya, TN_RES_FISH, FishQuality)
        self.tables[TN_RES_BUFF] = partial(res_load, self, self.buffs, TN_RES_BUFF, ResBuff)
        self.tables[TN_RES_MINING] = partial(res_load, self, self.mines_normals, TN_RES_MINING, ResMining)
        self.tables[TN_RES_TBOX] = partial(res_load, self, self.tboxs, TN_RES_TBOX, ResTbox)
        self.tables[TN_RES_DEEP_BOX] = partial(res_load, self, self.deep_boxs, TN_RES_DEEP_BOX, ResDeepBox)
        self.tables[TN_RES_DEEP_POS] = partial(res_load, self, self.deep_poses, TN_RES_DEEP_POS, ResDeepPos)
        self.tables[TN_RES_DEEP_GUARD] = partial(res_load, self, self.deep_guards, TN_RES_DEEP_GUARD, ResDeepGuard)
        self.tables[TN_RES_SHOP] = partial(res_load, self, self.shop_items, TN_RES_SHOP, ResShopItem)
        self.tables[TN_RES_DIRECT_SHOP] = partial(res_load, self, self.direct_shop, TN_RES_DIRECT_SHOP, ResDirectShop)
        self.tables[TN_RES_ALLY_LEVELS] = partial(res_load, self, self.ally_levels, TN_RES_ALLY_LEVELS, ResAllyLevel)
        self.tables[TN_RES_ALLY_RIGHTS] = partial(res_load, self, self.ally_rights, TN_RES_ALLY_RIGHTS, ResAllyRight)
        self.tables[TN_RES_ALLY_GRAVES] = partial(res_load, self, self.ally_graves, TN_RES_ALLY_GRAVES, ResAllyGrave)
        self.tables[TN_RES_ALLY_EXCHANGE] = partial(res_load, self, self.ally_exchanges, TN_RES_ALLY_EXCHANGE, ResAllyExchange)
        self.tables[TN_RES_ALLY_BOAT_LEVEL] = partial(res_load, self, self.ally_boat_levels, TN_RES_ALLY_BOAT_LEVEL, ResAllyBoatLevel)

        self.tables[TN_RES_REWARD_ONL] = partial(res_load, self, self.reward_onls, TN_RES_REWARD_ONL, ResRewardOnline)
        self.tables[TN_RES_REWARD_SETT] = partial(res_load, self, self.reward_setts, TN_RES_REWARD_SETT, ResRewardSett)
        self.tables[TN_RES_REWARD_ACTIVE] = partial(res_load,self, self.reward_actives, TN_RES_REWARD_ACTIVE, ResRewardActive)
        self.tables[TN_RES_REWARD_MAIL] = partial(res_load,self, self.reward_mails, TN_RES_REWARD_MAIL, ResRewardMail)
        self.tables[IN_RES_BOSS_CD] = partial(res_load, self, self.boss_cd, IN_RES_BOSS_CD, ResBossCd)
        self.tables[IN_RES_BOSS_REWARD] = partial(res_load, self, self.boss_reward, IN_RES_BOSS_REWARD, ResBossReward)
        self.tables[IN_RES_BOSS_LEVEL] = partial(res_load, self, self.boss_level, IN_RES_BOSS_LEVEL, ResBossLevel)
        self.tables[TN_RES_HORN_MSG] = partial(res_load, self, self.hornmsgs, TN_RES_HORN_MSG, ResHornMsg)
        self.tables[TN_RES_ACHI_DAY] = partial(res_load, self, self.achi_day, TN_RES_ACHI_DAY, ResEveryDayAchievement)
        self.tables[TN_RES_ACHI_ETERNAL] = partial(res_load, self, self.achi_eternal, TN_RES_ACHI_ETERNAL, ResEternalAchievement)
        self.tables[TN_RES_GEM] = partial(res_load, self, self.gem, TN_RES_GEM, ResGem)
        self.tables[TN_RES_GEM_LEVEL] = partial(res_load, self, self.gem_levels, TN_RES_GEM_LEVEL, ResGemLevel)
        self.tables[TN_RES_GEM_UP_RATE] = partial(res_load, self, self.gem_up_rate, TN_RES_GEM_UP_RATE, ResGemUpRate)
        self.tables[TN_RES_GEM_SHOP] = partial(res_load, self, self.gem_shop_items, TN_RES_GEM_SHOP, ResGemShopItem)
        self.tables[TN_RES_NAMES] = partial(res_load, self, self.names, TN_RES_NAMES, ResNames)
        self.tables[TN_RES_DAYLUCKY] = partial(res_load, self, self.day_luckys, TN_RES_DAYLUCKY, ResDayLuckys)
        self.tables[TN_RES_ROLEUP] = partial(res_load, self, self.roleups, TN_RES_ROLEUP, ResRoleUps)
        self.tables[TN_RES_ROLEUP_TYPE] = partial(res_load, self, self.roleup_typs, TN_RES_ROLEUP_TYPE, ResRoleUpType)
        self.tables[TN_RES_AWAR_START_CONFIG] = partial(res_load, self, self.awar_start_configs, TN_RES_AWAR_START_CONFIG, ResAwarstartConfig)
        self.tables[TN_RES_AWAR_PER_CONFIG] = partial(res_load, self, self.awar_per_configs, TN_RES_AWAR_PER_CONFIG, ResAwarperConfig)
        self.tables[TN_RES_AWAR_NPC_CONFIG] = partial(res_load, self, self.awar_npc_configs, TN_RES_AWAR_NPC_CONFIG, ResAwarNpcConfig)
        self.tables[TN_RES_AWAR_BOOK] = partial(res_load, self, self.awar_books, TN_RES_AWAR_BOOK, ResAwarBook)
        self.tables[TN_RES_AWAR_STRONG_MAP] = partial(res_load, self, self.awar_strong_maps, TN_RES_AWAR_STRONG_MAP, ResAwarStrongMap)
        self.tables[TN_RES_AWAR_WORLD_SCORE] = partial(res_load, self, self.awar_world_scores, TN_RES_AWAR_WORLD_SCORE, ResAwarWorldScore)
        self.tables[TN_RES_AWAR_WORLD_ASSESS] = partial(res_load, self, self.awar_world_assesses, TN_RES_AWAR_WORLD_ASSESS, ResAwarWorldAssess)

        #角色
        #将角色经验表保存为{level1:o1,...}
        self.exps_by_level = {}

        #物品
        #将物品合成保存为 {(desId, srcId):fusion...}
        self.fusions_by_keys = {}

        #装备
        #将装备强化表保存为 {level:strEq...}
        self.str_eq_by_level = {}

        #武器
        #武器历练升级表保存为 {level1:o1,...}
        self.arm_exp_by_level = {}
        #武器等级表另存为{(aid, arm_level):o1}
        self.arm_level_by_keys = {}

        #命格
        #猎命次数消耗表保存为 {num: fateCost...}
        self.fate_cost_by_num = {}
        #猎命概率表保存为 {type1:[o1,o2...], type2:[o3, ...]}
        self.fate_rate_by_type = {}
        #通过(fid, level)获取列表等级表{(fid, level):fateLevel...}
        self.fate_level_by_keys = {}
        #通过fid获取列表等级表多条数据{fid1:[level1,level2...]...}
        self.fate_level_by_fid = {}

        #祭天
        #祭天概率表保存为 {type1:[o1,o2...], type2:[o3, ...]}
        self.fete_rate_by_type = {}

        #任务
        #将兵符任务保存为{(level1, level2):[o1,o2,o3...] ...}
        self.bf_task_by_unlock = {}
        #兵符任务表{(tid, quality):o, ...}
        self.bf_task_by_tbid = {}

        #boss战
        #boss战cd时间数据保存为 {type1:[o1, o2,...],...}
        self.boss_cd_by_type = {}
        #boss战奖励 {(type, target): rid}
        #世界target=rank 同盟target=ally_lv, rank 或 target=ally_lv
        self.boss_reward_by_keys = {}
        #boss战登记表 {(type, level):o}
        self.boss_level_by_keys = {}
        #boss等级表{(mid, level):o}
        self.boss_level_by_midlevel = {}

        #怪物等级表
        #{(mid, level):hp, ...}
        self.boss_hp_by_keys = {}
        #{(mid, level):def, ...}
        self.boss_def_by_keys = {}

        #获取大喇叭信息 通过类型
        self.horn_msg_by_keys = {}

        #神秘商店必然出现的物品
        self.shop_items_must = {}

        #珠宝商店品质对应珠宝
        self.q_gem = {} #{quality : [gem] }

        #每日抽奖条件对应的概率
        self.daylucky_cond_rates = {}

        #武将升段类型表
        self.roleup_type_by_rid = {}
        #武将升段表
        self.roleup_by_keys = {}


        #时光盒通过章节获取时光盒id列表
        self.tboxs_by_chapter = {}


        #同盟狩龙战{(开战类型, 第几场战斗):id}
        self.awar_per_configs_bykeys = {}
        #同过战场配置表的id获取该场战斗出现的怪物的属性
        #{pwid:[obj1,obj2]...}
        self.awar_npc_configs_bykey = {}


        #狩龙战 评级{type:{num1:obj1,...}}
        self.awar_world_score_bykeys = {}

    def load(self, app=None):
        if self._loop_task is None:
            self._loop_task = spawn(self._loop)
        for tname, load_func in self.tables.iteritems():
            try:
                load_func()
            except error: #网络错误
                log.log_except()
                return 0
            except:
                log.log_except()
            if app and app.stoped:
                return 0
        self.db_ver = self._get_db_ver()
        return 1


    def _get_db_ver(self):
        return Game.rpc_res_store.get_db_ver()

    def _loop(self):
        """ 定时判断资源库版本号,更新资源 """
        import app
        while not app.stoped:
            sleep(30)
            db_ver = self._get_db_ver()
            if db_ver != self.db_ver:
                log.warn(u'更新资源库(%s)', db_ver)
                if self.load(app):
                    log.warn(u'更新资源库(%s)完成', db_ver)
                    self.pub(MSG_RES_RELOAD)
                else:
                    log.warn(u'更新资源库(%s)失败', db_ver)

    def get_role_level(self, rid, level):
        return self.role_levels.get((rid, level))

    def get_site_exp(self, level):
        exps = self.exps_by_level.get(level)
        if not exps:
            return 0
        return exps.siteExp

    def get_fate_by_rate(self, quality):
        rates = self._fate_rates.get(quality)
        if not rates:
            return
        fid = rates()
        return self.fates[fid]

    def get_equip_by_rate(self, set_id):
        rates = self._equip_rates.get(set_id)
        if not rates:
            return
        eid = rates()
        return self.equips[eid]

    def get_shop_by_rate(self):
        rates = self._shop_luck
        if not rates:
            return
        sid = rates()
        return self.shop_items[sid]

    #def get_rare_by_rate(self):
    #    self.shop_rares
    #    rates = self._shop_rares
    #    if not rates:
    #        return
    #    sid = rates()
    #    return self.shop_items[sid]

    def get_gem_shop_by_rate(self, c, sids=None):
        if sids is None:
            sids = []
        rates = self._gem_shop_rates
        if not rates:
            return
        for i in xrange(c):
            sid = rates()
            while sid in sids:
                sid = rates()
            sids.append(sid)
        return sids

    def get_tp_by_rate(self, type_part):
        rates = self._bf_rates.get(type_part)
        if not rates:
            return
        rid = rates()
        return self.bfrates[rid]

    def get_fight_rid(self, fid):
        fight = self.fights.get(fid)
        if fight:
            return fight.rid

    def get_random_name(self, sex=None):
        """ 根据性别取名 """
        male = 1
        if not hasattr(self, '_names_'):
            #[<姓区间>, <男名区间>, <女名区间>]
            self._names_ = [[0, 0], [0, 0], [0, 0]]
            keys = self.names.keys()
            keys.sort()
            for k in keys:
                n = self.names[k]
                if n.t == 1:
                    rg = self._names_[0]
                elif n.sex == male:
                    rg = self._names_[1]
                else:
                    rg = self._names_[2]
                if rg[0] == 0 or k < rg[0]:
                    rg[0] = k
                if rg[1] == 0 or k > rg[1]:
                    rg[1] = k
            log.debug('names range:%s', self._names_)

        if sex is None:
            sex = random.choice([1, 2])

        xr = self._names_[0]
        xi = random.randint(xr[0], xr[1])
        mr = self._names_[1] if sex == male else self._names_[2]
        mi = random.randint(mr[0], mr[1])
        return '%s%s' % (self.names[xi].n, self.names[mi].n)

    def _after_init_res_task(self):
        for task in self.tasks.itervalues():
            task.runtime_init(self.tasks)

    def _init_res_task(self, objs):
        """ 任务表提取兵符任务 """
        self.bf_task_by_unlock.clear()
        for o in objs:
            if o.type == TT_OFFER:
                unlock = str2dict2(o.unlock)
                level = unlock['level']
                if unlock.has_key('tid'):
                    tid = int(unlock['tid'][0])
                else:
                    tid = 0
                tKey = (int(level[0]),int(level[1]), tid)
                self.bf_task_by_unlock.setdefault(tKey, [])
                self.bf_task_by_unlock[tKey].append(o)

    def _init_res_pos_level(self, objs):
        """ 初始化阵型等级,以(pid, level)作为键 """
        self.position_levels.clear()
        self.position_levels.update(dict([[(o.pid, o.level), o] for o in objs]))
        return True

    def _init_res_role_level(self, objs):
        """ 角色等级 """
        self.role_levels.clear()
        for o in objs:
            self.role_levels[(o.rid, o.level)] = o
        return True

    def _init_res_role_exp(self, objs):
        """ 处理角色经验表 """
        self.exps_by_level.clear()
        for o in objs:
            self.exps_by_level[o.level] = o

    def _init_res_equip(self, objs):
        """ 初始化装备 """
        set_id_rates = {}
        for o in objs:
            sid = o.sid
            rates = set_id_rates.setdefault(sid, [])
            rates.append((o.id, o.rate))
        self._equip_rates = dict([(k, RandomRegion(rates)) for k,rates in set_id_rates.iteritems()])

    def _init_res_eq_level(self, objs):
        self.equip_levels.clear()
        for o in objs:
            self.equip_levels[(o.part, o.level)] = o
            o.runtime_init()
        return True

    def _init_res_fate(self, objs):
        """ 初始化命格概率 """
        qrates = {}
        assert len(self.fate_level_by_fid), 'much init fate_level first'
        for o in objs:
            o.init_fate(self.fate_level_by_fid.get(o.id))
            q = o.quality
            rates = qrates.setdefault(q, [])
            rates.append((o.id, o.rate))
        self._fate_rates = dict([(k, RandomRegion(rates)) for k,rates in qrates.iteritems()])

    def _init_res_fate_level(self, objs):
        """ 将命格的影响效果字段保存为枚举变量里 变量名effect"""
        self.fate_level_by_keys.clear()
        self.fate_level_by_fid.clear()
        for o in objs:
            self.fate_level_by_keys[(o.fid, o.level)] = o
            levels = self.fate_level_by_fid.setdefault(o.fid, [])
            levels.append(o)

    def _init_res_fate_cost(self, objs):
        """ 猎命次数消耗表保存为 {num: fateCost} """
        self.fate_cost_by_num.clear()
        for o in objs:
            self.fate_cost_by_num[o.num] = o

    def _init_res_fate_rate(self, objs):
        """ 猎命概率表保存为 {type1:[o1,o2...], type2:[o3, ...]} """
        self.fate_rate_by_type.clear()
        for o in objs:
            tRs = self.fate_rate_by_type.setdefault(o.type, [o])
            if tRs:
                self.fate_rate_by_type[o.type].append(o)

    def _init_res_fusion(self, objs):
        """ 将物品合成保存为 {(desId, srcId):fusion...} """
        self.fusions_by_keys.clear()
        for o in objs:
            self.fusions_by_keys[(o.desId, o.srcId)] = o

    def _init_res_str_eq(self, objs):
        """ 将装备强化表保存为 {level:strEq...} """
        self.str_eq_by_level.clear()
        for o in objs:
            self.str_eq_by_level[o.level] = o

    def _init_res_arm_exp(self, objs):
        """ 武器历练升级表保存为 {level1:o1,...} """
        self.arm_exp_by_level.clear()
        for o in objs:
            self.arm_exp_by_level[o.level] = o

    def _init_res_fish(self, objs):
        """ 钓鱼的技巧品质 """
        self.fish_qualitya.clear()
        for o in objs:
            t_d = dict()
            self.fish_qualitya.setdefault(o.fid, dict())
            self.fish_qualitya[o.fid][o.qt] = o
        return self.fish_qualitya

    def _init_res_fete_rate(self, objs):
        """ 祭天概率表保存为 {type1:[o1,o2...], type2:[o3, ...]} """
        self.fete_rate_by_type.clear()
        for o in objs:
            tRs = self.fete_rate_by_type.setdefault(o.type, [o])
            if tRs:
                self.fete_rate_by_type[o.type].append(o)

    def _init_res_arm_level(self, objs):
        """ 武器等级表 """
        self.arm_level_by_keys.clear()
        for o in objs:
            self.arm_level_by_keys[(o.aid, o.level)] = o

    def _init_res_bf_task(self, objs):
        """ 兵符任务 """
        for o in objs:
            self.bf_task_by_tbid[(o.tid, o.quality)] = o

    def _init_res_bf_rate(self, objs):
        """ 兵符任务获取概率 """
        type_part_rates = {}
        for o in objs:
            k = (o.type, o.part)
            rates = type_part_rates.setdefault(k, [])
            rates.append((o.id, o.rate))
        self._bf_rates = dict([(k, RandomRegion(rates)) for k,rates in type_part_rates.iteritems()])

    def _init_res_mine(self, objs):
        """ 采矿 """
        from game.base.constant import MINING_COIN1
        from game.base.constant import MINING_COIN2
        self.mines_normals.clear()
        self.mines_vips.clear()
        #dict会改成{(1,30): obj, (31, 50): obj}
        for o in objs:
            k = (o.level1, o.level2)
            o.rids = str2dict(o.rids, ktype=int, vtype=int)
            if o.type == MINING_COIN1:
                self.mines_normals[k] = o
            elif o.type == MINING_COIN2:
                self.mines_vips[k] = o
        return self.mines_normals

    def _init_res_ally_level(self, objs):
        """ 同盟等级 """
        self.ally_levels.clear()
        for o in objs:
            self.ally_levels[o.level] = o
        return self.ally_levels

    def _init_res_ally_right(self, objs):
        """ 同盟权限 """
        self.ally_rights.clear()
        for o in objs:
            self.ally_rights[o.duty] = o
        return self.ally_rights

    def _init_res_ally_grave(self, objs):
        """ 同盟铭刻 """
        self.ally_graves.clear()
        for o in objs:
            self.ally_graves[o.t] = o
        return self.ally_graves

    def _init_res_ally_boat_exchange(self, objs):
        """同盟建设度兑换"""
        self.ally_exchanges.clear()
        for o in objs:
            self.ally_exchanges[o.id] = o
        return self.ally_exchanges

    def _init_res_ally_boat_level(self, objs):
        """同盟天舟各类型的等级"""
        self.ally_boat_levels.clear()
        for o in objs:
            self.ally_boat_levels[o.id] = o
        return self.ally_boat_levels

    def _init_res_boss_cd(self, objs):
        """ boss战cd时间 """
        self.boss_cd_by_type.clear()
        for o in objs:
            rs = self.boss_cd_by_type.setdefault(o.type, [])
            rs.append(o)

    def _init_res_monster_level(self, objs):
        """ 怪物等级表 """
        self.boss_hp_by_keys.clear()
        self.boss_def_by_keys.clear()
        for o in objs:
            o.update_data()
            key = (o.mid, o.level)
            self.boss_hp_by_keys[key] = o.HP
            self.boss_def_by_keys[key] = o.DEF

    def _init_res_horn_mgr(self, objs):
        """ 大喇叭信息 """
        self.horn_msg_by_keys.clear()
        for o in objs:
            self.horn_msg_by_keys[o.type] = o

    def _init_res_boss_reward(self, objs):
        """ boss战奖励 """
        self.boss_reward_by_keys.clear()
        for o in objs:
            if o.target.find('|') > 0:
                values = o.target.split('|')
                lvs = values[0].split(':')
                rank = values[1].split(':')
                lvs_min = int(lvs[1])
                lvs_max = int(lvs[2]) + 1
                rank_min = int(rank[1])
                rank_max = int(rank[2]) + 1
                for i in xrange(lvs_min, lvs_max):
                    for j in xrange(rank_min, rank_max):
                        self.boss_reward_by_keys[(o.type, i, j)] = o.rid
            else:
                values = o.target.split(':')
                min = int(values[1])
                max = int(values[2]) + 1
                if not max:
                    self.boss_reward_by_keys[(o.type, max)] = o.rid
                    continue
                for i in xrange(min, max):
                    self.boss_reward_by_keys[(o.type, i)] = o.rid

    def _init_res_boss_level(self, objs):
        """ 获取boss战等级表id """
        self.boss_level_by_keys.clear()
        self.boss_level_by_midlevel.clear()
        for o in objs:
            key1 = (o.type, o.level)
            key2 = (o.mid, o.level)
            self.boss_level_by_keys[key1] = o
            self.boss_level_by_midlevel[key2] = o

    def _init_res_reward_onl(self, objs):
        """ 在线奖励 """
        #self.reward_onls = {1:{1:ResRewardOnline, 2:ResRewardOnline}, 2:{1:obj, 4:obj, 10:obj, 20:obj}}
        from game.base.constant import REWARDONLINE_TYPE_TIME, REWARDONLINE_TYPE_LOGIN
        self.reward_onls = {REWARDONLINE_TYPE_TIME : {}, REWARDONLINE_TYPE_LOGIN : {}}
        td = dict()
        tl = []
        for o in objs:
            if o.t == REWARDONLINE_TYPE_TIME:
                self.reward_onls[REWARDONLINE_TYPE_TIME][o.tNum] = o
            elif o.t == REWARDONLINE_TYPE_LOGIN:
                td[o.val] = o
                tl.append(o.val)
            else:
                log.error(">>>>>>>>>>>>>>>reward_online type:%s or tNum:%s error", o.t, o.tNum)
        tl.sort()
        n = 0
        for val in tl:
            n += val
            self.reward_onls[REWARDONLINE_TYPE_LOGIN][n] = td[val]
        return self.reward_onls

    def _init_res_reward_setting(self, objs):
        """奖励设置"""
        fmt = '%y%m%d'
        for obj in objs:
            if obj.sids == '':
                obj.sids = '()'
            obj.sids = eval(obj.sids) #(1,2,3,4)
            if isinstance(obj.sids, float):
                obj.sids = [int(obj.sids)]
            if isinstance(obj.sids, int):
                obj.sids = (obj.sids, )
            if len(obj.sids) > 1: obj.sids = map(lambda x:int(float(x)), obj.sids)
            if obj.begin:
                t = strptime(str(obj.begin), fmt)
                obj.begin = time.mktime(t.timetuple())
            if obj.end:
                t = strptime(str(obj.end), fmt)
                obj.end = time.mktime(t.timetuple())
            self.reward_setts[obj.id] = obj
        return self.reward_setts

    def _init_res_shop(self, objs):
        """ 神秘商店物品有效时间 """
        from game.base.constant import SHOP_TYPE_ITEM,SHOP_TYPE_FATE
        from game.base.constant import SHOP_TYPE_RARE, SHOP_TYPE_LUCK
        fmt = '%y%m%d'
        luck_rates = []
        rare_rates = []
        for obj in objs:
            if obj.qt == SHOP_TYPE_RARE:
                self.shop_rares[obj.id] = obj
            elif obj.qt == SHOP_TYPE_LUCK:
                luck_rates.append((obj.id, obj.r))
            if obj.r == -1:
                self.shop_items_must[obj.id] = obj
            if obj.start:
                obj.start = mk_time(obj.start, fmt)
            if obj.end:
                obj.end = mk_time(obj.end, fmt)
            self.shop_items[obj.id] = obj
        self._shop_luck = RandomRegion(luck_rates)
        return self.shop_items

    def _init_res_day_lucky(self, objs):
        """ 每日抽奖 """
        self.daylucky_cond_rates = {DAYLUCKY_TYPE_NO:[], DAYLUCKY_TYPE_BLOGIN:[], DAYLUCKY_TYPE_ALOGIN:[]}
        for obj in objs:
            self.day_luckys[obj.id] = obj
            rate = (obj.id, obj.srate)
            if obj.cond == DAYLUCKY_TYPE_NO:
                self.daylucky_cond_rates[DAYLUCKY_TYPE_NO].append(rate)
            elif obj.cond == DAYLUCKY_TYPE_BLOGIN:
                self.daylucky_cond_rates[DAYLUCKY_TYPE_BLOGIN].append(rate)
            elif obj.cond == DAYLUCKY_TYPE_ALOGIN:
                self.daylucky_cond_rates[DAYLUCKY_TYPE_ALOGIN].append(rate)
        return self.daylucky_cond_rates

    def _init_res_awar_start_config(self, objs):
        """ 同盟狩龙战开启房间配置表 """
        for obj in objs:
            self.awar_start_configs[obj.id] = obj

    def _init_res_awar_per_config(self, objs):
        """ 同盟狩龙战每场战斗的配置表 """
        self.awar_per_configs_bykeys.clear()
        for obj in objs:
            self.awar_per_configs[obj.id] = obj
            key = (obj.type, obj.fnum)
            self.awar_per_configs_bykeys[key] = obj

    def _init_res_awar_npc_config(self, objs):
        """ 同盟狩龙npc的配置表 """
        self.awar_npc_configs_bykey.clear()
        for obj in objs:
            self.awar_npc_configs[obj.id] = obj
            l = self.awar_npc_configs_bykey.setdefault(obj.apcid, [])
            l.append(obj)

    def _init_res_awar_world_score(self, objs):
        """ 同盟狩龙 """
        self.awar_world_score_bykeys.clear()
        for obj in objs:
            self.awar_world_scores[obj.id] = obj
            d = self.awar_world_score_bykeys.setdefault(obj.type, {})
            d[obj.num] = obj


    def _init_res_awar_book(self, objs):
        """ 同盟狩龙天书 """
        for obj in objs:
            self.awar_books[obj.id] = obj

    def _init_res_awar_strong_map(self, objs):
        """ 同盟降龙势力图 """
        for obj in objs:
            self.awar_strong_maps[obj.id] = obj

    def _init_res_roleup(self, objs):
        """ 武将升段 """
        for obj in objs:
            self.roleups[obj.id] = obj
            key = (obj.check, obj.grade, obj.quality, obj.type)
            self.roleup_by_keys[key] = (obj.check, obj.grade, obj.quality)

    def _init_res_tbox(self, objs):
        """ 时光盒 """
        self.tboxs_by_chapter.clear()
        for obj in objs:
            rs = self.tboxs_by_chapter.setdefault(obj.chapter, [])
            rs.append(obj.id)

    def _init_res_roleup_type(self, objs):
        """ 武将升段类型 """
        for obj in objs:
            self.roleup_typs[obj.id] = objs
            self.roleup_type_by_rid[obj.rid] = obj.type

    def _init_res_reward_active(self, objs):
        """ 活动奖励 """
        from game.base.constant import REWARDACTIVE_RECHARGE, REWARDACTIVE_WEPONUP, REWARDACTIVE_RECRUIT
        self.reward_actives = {REWARDACTIVE_RECHARGE : {}, REWARDACTIVE_WEPONUP : {}, REWARDACTIVE_RECRUIT : {}}
        for o in objs:
            if o.t == REWARDACTIVE_RECHARGE:
                self.reward_actives[REWARDACTIVE_RECHARGE] = o
            elif o.t == REWARDACTIVE_WEPONUP:
                self.reward_actives[REWARDACTIVE_WEPONUP][o.val] = o
            elif o.t == REWARDACTIVE_RECRUIT:
                self.reward_actives[REWARDACTIVE_RECRUIT][o.val] = o
            else:
                log.error(">>>>>>>>>>>>>>>reward_active type:%s or tNum:%s error", o.t, o.tNum)
        return self.reward_actives


    def _init_res_reward_mail(self, objs):
        """ 邮件格式定义 """
        rpc_store = Game.rpc_res_store
        encobjs = []
        config_lang_id = rpc_store.get_config(LANG_ID_KEY, default='zh-CN')
        for o in objs:
            if config_lang_id.lower() != 'zh-cn':
                if config_lang_id.lower() == 'zh-hk':     # 繁体中文
                    o.title = langconv.cn2hk(o.title)
                    o.content = langconv.cn2hk(o.content)
                else:
                    key = md5(o.title.decode('utf-8')).hexdigest()
                    trans_str = rpc_store.load(TN_RES_LANG_MAP, key)
                    if trans_str:
                        o.title = trans_str
                    key = md5(o.content.decode('utf-8')).hexdigest()
                    trans_str = rpc_store.load(TN_RES_LANG_MAP, key)
                    if trans_str:
                        o.content = trans_str


            encobjs.append((o.t, o))

        self.reward_mails = dict(encobjs)
        return self.reward_mails

    def _init_res_gem(self, objs):
        """珠宝"""
        for obj in objs:
            obj.parts = str2list(obj.parts)
            self.gem[obj.id] = obj
            q_gem = self.q_gem.setdefault(obj.quality, [])
            q_gem.append(obj)

    def _init_res_gem_level(self, objs):
        """珠宝等级"""
        for obj in objs:
            key = (obj.gid, obj.level)
            self.gem_levels[key] = obj

    def _init_res_gem_up_rate(self, objs):
        """珠宝升级概率"""
        for obj in objs:
            self.gem_up_rate[(obj.fq, obj.flv, obj.tq, obj.tlv)] = obj

    def _init_res_gem_shop(self, objs):
        """珠宝商店"""
        rates = []
        for obj in objs:
            self.gem_shop_items[obj.id] = obj
            rates.append((obj.id, obj.r))
        self._gem_shop_rates = RandomRegion(rates)


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------



