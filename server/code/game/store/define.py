#!/usr/bin/env python
# -*- coding:utf-8 -*-
from store.driver import MONGODB_ID

#类名定义
TN_P_TBOXNEWS = 'tbox_news'
TN_STATUS = 'status'
TN_F_REPORT = 'f_report'
TN_USER = 'user'
TN_PLAYER = 'player'
TN_P_ROLE = 'p_role'
TN_P_EQUIP = 'p_equip'
TN_P_ITEM = 'p_item'
TN_P_FATE = 'p_fate'
TN_P_CAR = 'p_car'
TN_P_TASK = 'p_task'
TN_P_WAIT = 'p_wait'
TN_P_ATTR = 'p_attr'
TN_P_POSITION = 'p_position'
TN_P_MAP = 'p_map'
TN_P_MAIL = 'p_mail'
TN_P_BUFF = 'p_buff'
TN_P_TBOX = 'p_tbox'
TN_P_DEEP = 'p_deep'
TN_SOCIAL = 'p_social'
TN_ALLY = 'ally'
TN_P_ALLY = 'ally_player'
TN_ALLY_LOG = "ally_log"
TN_SHOP = 'shop'
TN_ARENA_RANK = 'arena_rank'
TN_ARENA_RANKS = 'arena_ranks'
TN_P_ARENA = 'p_arena'
TN_BOSS = 'boss'
TN_ACTIVITY_LEVEL_GIFTS = 'activity_level_gifts'
TN_P_ACHI = 'p_achi'
TN_P_GEM = 'p_gem'
TN_P_DAYLUCKY = 'p_day_lucky'
TN_DAYSIGN = 'p_day_sign'
TN_P_ROLEUP = 'p_role_up'
TN_P_ACTIVE = 'p_active'

#类与表名关系 (tablename, key, indexs, autoInc)
GAME_MONGO_CLS_INFOS = {
    TN_F_REPORT:('f_report', 'id', [], True),
    TN_STATUS: ('status', 'id', ['key'], True),
    TN_USER: ('user', 'id', ['name', 'UDID', 'sns'], True),
    TN_PLAYER: ('player', 'id', ['uid', 'name', ], True),
    TN_P_ROLE: ('p_role', 'id', ['pid', 'rid'], True),
    #玩家物品表,将多个表合并在一个mongodb表里面处理
    TN_P_EQUIP: ('p_equip', 'id', ['pid', 'eid'], True),
    TN_P_ITEM: ('p_item', 'id', ['pid', 'iid'], True),
    TN_P_FATE: ('p_fate', 'id', ['pid', 'fid'], True),
    TN_P_CAR: ('p_car', 'id', ['pid', 'cid'], True),
    TN_P_TASK: ('p_task', 'id', ['pid', 'tid'], True),
    TN_P_WAIT: ('p_wait', 'id', ['pid', 'type'], True),
    TN_P_ATTR: ('p_attr', 'id', [('pid', dict(unique=True)), ], True),
    TN_P_POSITION: ('p_position', 'id', ['pid', ], True),
    TN_P_MAP: ('p_map', 'id', ['pid'], True),
    TN_P_MAIL: ('p_mail', 'id', ['pid'], True),
    TN_P_BUFF: ('p_buff', 'id', ['pid'], True),
    TN_P_TBOX: ('p_tbox', 'id', ['pid'], True),
    TN_P_TBOXNEWS:('tbox_news', 'id', [], True),
    TN_P_DEEP: ('p_deep', 'id', ['pid', 'at'], True),
    TN_ALLY: ('ally', 'id', ['pid'], True),
    TN_P_ALLY: ('ally_player', 'id', ['pid'], True),
    TN_ALLY_LOG: ('ally_log', 'id', [], True),
    TN_SHOP: ('shop', 'id', [], True),
    TN_ARENA_RANK: ('arena_rank', 'id', [], True),
    TN_ARENA_RANKS:('arena_ranks', 'id', [], True),
    TN_P_ARENA: ('p_arena', 'id', [], False), #id=pid,
    TN_BOSS:('boss', 'id', [], True),
    TN_SOCIAL:('p_social', 'id', [], True),
    TN_ACTIVITY_LEVEL_GIFTS:('activity_level_gifts', 'id', ['udid'], True),
    TN_P_ACHI:('p_achi', 'id', ['pid'], True),
    TN_P_GEM:('p_gem', 'id', ['pid'], True),
    TN_P_DAYLUCKY:('p_day_lucky', 'id', ['pid'], True),
    TN_DAYSIGN:('p_day_sign', 'id', ['pid'], True),
    TN_P_ROLEUP:('p_role_up', 'id', ['pid'], True),
    TN_P_ACTIVE:('p_active', 'id', ['aid', 'pid', 'ct'], True),
}

GAME_CLS_INFOS = {
    MONGODB_ID: GAME_MONGO_CLS_INFOS,
}

#全服设置
TN_GCONFIG = 'gconfig'
TN_SERVER = 'server'
TN_GUSER = 'guser'
#TN_PAY_SDK91 = 'pay_sdk91'
TN_PAY_LOG = 'pay_log'
TN_PRE_PAY = 'pay_pre'
TN_RES_GOODS = 'res_goods'

#gconfig key 列表
GF_CurrentSvrId = 'CurrentSvrId'
GF_dbVer = 'dbVer'
GF_ClientVer = 'ClientVer'
GF_ClientMinVer = 'minVer'
GF_dbPath = "dbPath"
GF_webUrl = 'webUrl' #/api
GF_SDK91_APP_ID = 'sdk91_app_id'
GF_SDK91_APP_KEY = 'sdk91_app_key'
GF_SDK91_URLS = 'sdk91_urls'
GF_DPAY_APP_ID = 'dpay_app_id'
GF_DPAY_APP_KEY = 'dpay_app_key'
GF_DPAY_URLS = 'dpay_urls'
GF_PP_RSA_KEY = 'pp_rsa_key'
GF_PP_URLS = 'pp_urls'
GF_PP_KEY = 'pp_key'
GF_APP_URLS = 'appstore_urls'
GF_UC_URLS = 'uc_urls'
GF_DCN_URLS = 'dcn_urls'
GF_TB_URLS = 'tb_urls'
GF_IDS_URLS = 'ids_urls'
GF_IDSC_URLS = 'idsc_urls'
GF_AREA_URLS = 'area_urls'
GF_BOT_START = 'bot_start'

GF_DEFAULT_PAY_BACK = 'defaultPayBack' #默认是否开启支付成功检查功能
GF_BUG_URL = 'bugUrl' #bug提交地址
GF_RES_URL = 'resUrl' #游戏资源下载地址
GF_NOTICE = 'notice' #公告
GF_ACCESS_IP = 'access_ip' #admin access ip re
GF_CLIENTRPC_AESKEY = 'clientRpcAESKey'
GF_GAME_URL = 'gameUrl' #游戏http接口
GF_ACTIVITY = 'activity' #前端游戏活动配置
GF_CLI_CURLS = 'cliUrls' #前端地址设置
GF_PLIST_URL = 'PlistUrl' #前端版本更新地址

#游戏全局的配置定义
TN_RES_SETTING = 'res_setting'
TN_RES_BAN_WORD = 'ban_word'

#资源库类名定义
TN_RES_ROLE = 'res_role'
TN_RES_ROLE_LEVEL = 'res_role_level'
TN_RES_ROLE_EXP = 'res_role_exp'
TN_RES_ARM = 'res_arm'
TN_RES_SKILL = 'res_skill'
TN_RES_ARM_LEVEL = 'res_arm_level'
TN_RES_ARM_EXP = 'res_arm_exp'
TN_RES_EQUIP = 'res_equip'
TN_RES_EQ_LEVEL = 'res_eq_level'
TN_RES_EQ_SET = 'res_eq_set'
TN_RES_STR_EQ = 'res_str_eq'
TN_RES_FATE = 'res_fate'
TN_RES_FATE_LEVEL = 'res_fate_level'
TN_RES_FATE_RATE = 'res_fate_rate'
TN_RES_FATE_COST = 'res_fate_cost'
TN_RES_ITEM = 'res_item'
TN_RES_FUSION = 'res_fusion'
TN_RES_REWARD = 'res_reward'
TN_RES_MONSTER = 'res_monster'
TN_RES_MONSTER_LEVEL = 'res_monster_level'
TN_RES_NPC = 'res_npc'
TN_RES_CAR = 'res_car'
TN_RES_GROUP_LEVEL = 'res_group_level'
TN_RES_MAP = 'res_map'
TN_RES_STAGE = 'res_stage'
TN_RES_FIGHT = 'res_fight'
TN_RES_POSITION = 'res_position'
TN_RES_POS_LEVEL = 'res_pos_level'
TN_RES_CHAPTER = 'res_chapter'
TN_RES_TASK = 'res_task'
TN_RES_BF_TASK = 'res_bf_task'
TN_RES_BF_RATE = 'res_bf_rate'
TN_RES_FETE_REATE = 'res_fete_rate'
TN_RES_FISH = 'res_fish'
TN_RES_BUFF = 'res_buff'
TN_RES_TBOX = 'res_tbox'
TN_RES_DEEP_BOX = 'res_deep_box'
TN_RES_DEEP_POS = 'res_deep_pos'
TN_RES_DEEP_GUARD = 'res_deep_guard'
TN_RES_MINING = 'res_mine'
TN_RES_SHOP = 'res_shop'
TN_RES_DIRECT_SHOP = 'res_direct_shop'
TN_RES_ALLY_LEVELS = 'res_ally_level'
TN_RES_ALLY_RIGHTS = 'res_ally_right'
TN_RES_ALLY_GRAVES = 'res_ally_grave'
TN_RES_ALLY_EXCHANGE = 'res_ally_boat_exchange'
TN_RES_ALLY_BOAT_LEVEL = 'res_ally_boat_level'
IN_RES_BOSS_CD = 'res_boss_cd'
IN_RES_BOSS_REWARD = 'res_boss_reward'
IN_RES_BOSS_LEVEL = 'res_boss_level'
TN_RES_REWARD_ONL = 'res_reward_onl'
TN_RES_REWARD_SETT = 'res_reward_setting'
TN_RES_REWARD_ACTIVE = 'res_reward_active'
TN_RES_REWARD_MAIL = 'res_reward_mail'
TN_RES_ALLY_TTBOX_REWARD = 'res_ally_ttbox_reward'
TN_RES_HORN_MSG = 'res_horn_msg'
TN_RES_EXCHANGE_CODE = 'res_exchange_code'
TN_RES_EXCHANGE_CODE_LOG = 'res_exchange_log'
TN_RES_ACHI_DAY = 'res_achi_day'
TN_RES_ACHI_ETERNAL = 'res_achi_eternal'
TN_RES_GEM = 'res_gem'
TN_RES_GEM_LEVEL = 'res_gem_level'
TN_RES_GEM_UP_RATE = 'res_gem_up_rate'
TN_RES_GEM_SHOP = 'res_gem_shop'
TN_RES_NAMES = 'names'
TN_RES_DAYLUCKY = 'res_day_lucky'
TN_RES_ROLEUP = 'res_roleup'
TN_RES_ROLEUP_TYPE = 'res_roleup_type'
TN_RES_LANG_MAP = 'res_lang_map'
TN_RES_AWAR_START_CONFIG = 'res_awar_start_config'
TN_RES_AWAR_PER_CONFIG = 'res_awar_per_config'
TN_RES_AWAR_NPC_CONFIG = 'res_awar_npc_config'
TN_RES_AWAR_BOOK = 'res_awar_book'
TN_RES_AWAR_STRONG_MAP = 'res_awar_strong_map'
TN_RES_AWAR_WORLD_SCORE = 'res_awar_world_score'
TN_RES_AWAR_WORLD_ASSESS = 'res_awar_world_assess'


#全服表配置
GROUP_MONGO_CLS_INFOS = {
    TN_GCONFIG: ('gconfig', 'id', ['key', ], True),
    TN_SERVER: ('server', 'id', [], True),
    TN_GUSER: ('guser', 'id', [], True),
    #TN_PAY_SDK91: ('pay_sdk91', 'id', [], True),
    TN_PAY_LOG: ('pay_log', 'id', ['t', 'ct', 'dt', 'sid',
            'gid', 'status',
            'torder',
            ('porder', dict(unique=True))], True),
    TN_PRE_PAY: ('pay_pre', 'id', [('porder', dict(unique=True)), ], True),
    TN_RES_GOODS: ('goods', 'id', [], True),
    }


#资源库类与表名关系 (tablename, key, indexs, autoInc)
RES_MONGO_CLS_INFOS = {
    TN_RES_SETTING: ('setting', 'id', [], True),
    TN_RES_BAN_WORD: ('ban_word', 'id', [], True),
    TN_RES_ROLE: ('role', 'id', [], True),
    TN_RES_ROLE_LEVEL: ('role_level', 'id', [], True),
    TN_RES_ROLE_EXP: ('role_exp', 'level', [], True),
    TN_RES_ARM: ('arm', 'id', [], True),
    TN_RES_ARM_LEVEL: ('arm_level', 'id', ['aid'], True),
    TN_RES_ARM_EXP: ('arm_exp', 'id', [], True),
    TN_RES_SKILL: ('skill', 'id', [], True),
    TN_RES_EQUIP: ('equip', 'id', [], True),
    TN_RES_EQ_LEVEL: ('eq_level', 'id', [], True),
    TN_RES_EQ_SET: ('eq_set', 'id', [], True),
    TN_RES_STR_EQ: ('str_eq', 'id', [], True),
    TN_RES_FATE: ('fate', 'id', [], True),
    TN_RES_FATE_LEVEL: ('fate_level', 'id', [], True),
    TN_RES_FATE_RATE: ('fate_rate', 'id', [], True),
    TN_RES_FATE_COST: ('fate_cost', 'id', [], True),
    TN_RES_ITEM: ('item', 'id', [], True),
    TN_RES_FUSION: ('fusion', 'id', [], True),
    TN_RES_REWARD: ('reward', 'id', [], True),
    TN_RES_MONSTER: ('monster', 'id', [], True),
    TN_RES_MONSTER_LEVEL: ('monster_level', 'id', [], True),
    TN_RES_NPC: ('npc', 'id', [], True),
    TN_RES_CAR: ('car', 'id', [], True),
    TN_RES_GROUP_LEVEL: ('group_level', 'id', [], True),
    TN_RES_MAP: ('map', 'id', [], True),
    TN_RES_STAGE: ('stage', 'id', [], True),
    TN_RES_FIGHT: ('fight', 'id', [], True),
    TN_RES_POSITION: ('position', 'id', [], True),
    TN_RES_POS_LEVEL: ('pos_level', 'id', [], True),
    TN_RES_CHAPTER: ('chapter', 'id', [], True),
    TN_RES_TASK: ('task', 'id', [], True),
    TN_RES_BF_TASK:('bf_task', 'id', [], True),
    TN_RES_BF_RATE:('bf_rate', 'id', [], True),
    TN_RES_FETE_REATE: ('fete_rate', 'id', [], True),
    TN_RES_FISH: ('fish', 'id', [], True),
    TN_RES_BUFF: ('buff', 'id', [], True),
    TN_RES_TBOX:('tbox', 'id', [], True),
    TN_RES_DEEP_BOX: ('deep_box', 'id', [], True),
    TN_RES_DEEP_POS: ('deep_pos', 'id', [], True),
    TN_RES_DEEP_GUARD: ('deep_guard', 'id', [], True),
    TN_RES_MINING:('mine_rate', 'id', [], True),
    TN_RES_SHOP:('shop', 'id', [], True),
    TN_RES_DIRECT_SHOP:('direct_shop','id',[], True),
    TN_RES_ALLY_LEVELS:('ally_level', 'id', [], True),
    TN_RES_ALLY_RIGHTS:('ally_right', 'id', [], True),
    TN_RES_ALLY_GRAVES:('ally_grave', 'id', [], True),
    TN_RES_ALLY_EXCHANGE:('ally_boat_exchange', 'id', [], True),
    TN_RES_ALLY_BOAT_LEVEL:('ally_boat_level', 'id', [], True),
    IN_RES_BOSS_CD:('boss_cd', 'id', [], True),
    IN_RES_BOSS_REWARD:('boss_reward', 'id', [], True),
    IN_RES_BOSS_LEVEL:('boss_level', 'id', [], True),
    TN_RES_REWARD_ONL:('reward_online', 'id', [], True),
    TN_RES_REWARD_SETT:('reward_setting', 'id', [], True),
    TN_RES_REWARD_ACTIVE:('reward_activity', 'id', [], True),
    TN_RES_REWARD_MAIL:('reward_mail', 'id', [], True),
    TN_RES_ALLY_TTBOX_REWARD:('ally_ttbox_reward', 'id', [], True),
    TN_RES_HORN_MSG:('horn', 'id', [], True),
    TN_RES_EXCHANGE_CODE:('exchange_code', 'id', [ 'name', ('code', dict(unique=True))], True),
    TN_RES_EXCHANGE_CODE_LOG:('exchange_log', 'id', ['code'], True),
    TN_RES_ACHI_DAY:('achi_day', 'id', [], True),
    TN_RES_ACHI_ETERNAL:('achi_eternal', 'id', [], True),
    TN_RES_GEM:('gem', 'id', [], True),
    TN_RES_GEM_LEVEL:('gem_level', 'id', [], True),
    TN_RES_GEM_UP_RATE:('gem_up_rate', 'id', [], True),
    TN_RES_GEM_SHOP:( 'gem_shop', 'id', [], True),
    TN_RES_NAMES:('names', 'id', [], True),
    TN_RES_DAYLUCKY:('day_lucky', 'id', [], True),
    TN_RES_ROLEUP:('roleup', 'id', [], True),
    TN_RES_ROLEUP_TYPE:('roleup_type', 'id', [], True),
    TN_RES_LANG_MAP: ('LangMap', 'id', [], True),
    TN_RES_AWAR_START_CONFIG:('awar_start_config', 'id', [], True),
    TN_RES_AWAR_PER_CONFIG:('awar_per_config', 'id', [], True),
    TN_RES_AWAR_NPC_CONFIG:('awar_npc_config', 'id', [], True),
    TN_RES_AWAR_BOOK:('awar_book', 'id', [], True),
    TN_RES_AWAR_STRONG_MAP:('awar_strong_map', 'id', [], True),
    TN_RES_AWAR_WORLD_SCORE:('awar_world_score', 'id', [], True),
    TN_RES_AWAR_WORLD_ASSESS:('awar_world_assess', 'id', [], True),
    }

res_len = len(RES_MONGO_CLS_INFOS) + len(GROUP_MONGO_CLS_INFOS)
#资源库和全服库合并,暂时不考虑分开,商品购买记录表会被logon和game同时访问
RES_MONGO_CLS_INFOS.update(GROUP_MONGO_CLS_INFOS)
assert res_len == len(RES_MONGO_CLS_INFOS), 'name conflict error'

RES_CLS_INFOS = {
    MONGODB_ID: RES_MONGO_CLS_INFOS,
}

#排序定义, 字段操作定义
from store.driver import (ASCENDING, DESCENDING,
        OP_AND, OP_NOR, OP_NOT, OP_OR,
        FOP_IN, FOP_GTE, FOP_GT, FOP_LT, FOP_LTE, FOP_NE, FOP_NIN,
    )

#字段名定义
FN_ID = 'id'
FN_NAME = 'name'
#user
FN_USER_DT = 'DT'
#player
FN_PLAYER_UID = 'uid'
FN_PLAYER_NAME = 'name'
FN_PLAYER_LEVEL = 'level'

#p_attr
FN_P_ATTR_PID = 'pid'
FN_P_ATTR_CBE = 'CBE'
FN_P_ATTR_CBES = 'CBES'
FN_P_ATTR_ALLYTBOX = 'allyTbox'

FN_P_ATTR_DAY = 'day'
FN_P_ATTR_FTIME = 't'
FN_P_ATTR_RESET = 'r'

FN_P_ATTR_KEY_ROLEUP = 'roleup'

#lang_id
LANG_ID_KEY = 'lang_id_id'
#武将升段
FN_KEY_ROLEUP = '1'

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------


