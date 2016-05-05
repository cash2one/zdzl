#!/usr/bin/env python
# -*- coding:utf-8 -*-
from store.driver import MONGODB_ID

TN_ONLINE = 'online'
TN_RPC = 'rpc'
TN_INFO = 'info'
TN_ITEM = 'item'
TN_GM = 'gm'
TN_EQUIP = 'equip'
TN_COIN = 'coin'
TN_RANK = 'rank'

#类与表名关系 (tablename, key, indexs, autoInc)
LOG_MONGO_CLS_INFOS = {
    TN_ONLINE: ('log_online', 'id', [], True),
    TN_RPC: ('log_rpc', 'id', [], True),
    TN_INFO: ('log_info', 'id', ['ct', 'p', 't', ], True),
    TN_ITEM: ('log_item', 'id', ['ct', 'p', 't', 'st', 'rid'], True),
    TN_GM: ('log_gm', 'id', ['ct', 'p', ], True),
    TN_EQUIP: ('log_equip', 'id', ['ct', 'p', ], True),
    TN_COIN: ('log_coin', 'id', ['ct', 'p', ], True),
    TN_RANK: ('log_rank', 'id', ['ct', 't'], True),
}

LOG_CLS_INFOS = {
    MONGODB_ID: LOG_MONGO_CLS_INFOS,
}


#玩家行为类型
PL_TASK_ACCEPT = -4 #接受任务
PL_ERROR = 0 #错误
PL_LOGIN = 1 # 登录
PL_LOGOUT = 2 # 退出
PL_UPGRADE = 3 # 升级
PL_TASK = 4 #任务完成
PL_ROLE = 5 #招募配将
PL_STUDY_POS = 6 #学习阵型
PL_EAT = 7 #食馆进食
PL_DEEP_BOX = 11 #深渊开宝箱
PL_CHAPTER = 12 # 完成章节
PL_MAPUPDATE = 13 # 地图升级
PL_WORLDMAP = 14 # 世界地图升级
PL_FUNCSUPDATE = 15 # 函数升级
PM_MAC = 101 #记录特有的mac地址,设备信息
PL_WORLD_BOSS = 16  #击杀世界boss
PL_VIP_UPGRADE = 17 #vip升级
PL_MERGE_FATE = 18 #合并命格

PL_DISP_MAP = {
    PL_TASK_ACCEPT: u'接受任务',
    PL_ERROR: u'错误',
    PL_LOGIN: u'登录',
    PL_LOGOUT: u'退出',
    PL_UPGRADE: u'升级',
    PL_TASK: u'任务完成',
    PL_ROLE: u'招募配将',
    PL_STUDY_POS: u'学习阵型',
    PL_EAT: u'食馆进食',
    PL_DEEP_BOX: u'深渊开宝箱',
    PL_CHAPTER: u'完成章节',
    PL_MAPUPDATE: u'地图升级',
    PL_WORLDMAP: u'世界地图升级',
    PL_FUNCSUPDATE: u'函数升级',
    PM_MAC: u'记录特有的mac地址,设备信息',
    PL_WORLD_BOSS: u'击杀世界boss',
    PL_VIP_UPGRADE: u'vip升级',
    PL_MERGE_FATE: u'合并命格',
}

#道具跟踪定义
#type <= 50 添加
ITEM_ADD = 1 #所有的添加
ITEM_BUY = 2 #商店购买
ITEM_ADD_EMAIL = 3 #系统邮件
ITEM_ADD_TASK = 4 #任务获得
ITEM_ADD_FATE = 5 #命格获取
ITEM_ADD_MERGE = 6 #物品合成
ITEM_ADD_GM = 7 #通过gm命令添加的物品
ITEM_ADD_USE = 8 #物品使用添加类型
ITEM_ADD_PAY = 9 #支付成功购买的商品
ITEM_FETCH_HITFATE = 20 #收取猎命
ITEM_FETCH_TIMEBOX = 21 #收取时光盒
ITEM_FETCH_EMAIL = 22 #收取邮件
ITEM_ADD_MINING = 23 #采矿所得
ITEM_ADD_DAY_ACHI = 24 #每日成就所得
ITEM_ADD_EVER_ACHI = 25 #永久成就所得
ITEM_ADD_DAY_LUCKY = 26 #每日抽奖所得
ITEM_ADD_DAY_SIGN = 27  #每日签到所得
ITEM_ADD_BFTASKBOX = 28 #兵符宝箱所得
ITEM_ADD_DEEPBOX = 29   #深渊宝箱所得
ITEM_ADD_FETE = 30      #祭天所得
ITEM_ADD_REWARDCODE = 31#兑换码奖励所得
ITEM_ADD_ALLYCAT = 32   #同盟招财猫所得
ITEM_ADD_GEM_MINE = 33 #珠宝开采
ITEM_ADD_GLORY_EXCHANGE = 34 #龙晶捐献
ITEM_ADD_ALLY_WAR = 35 #狩龙战斗奖励添加


ITEM_TRACE_DISPLAY_MAP = {
    ITEM_ADD: u'所有的添加',
    ITEM_BUY: u'商店购买',
    ITEM_ADD_EMAIL: u'系统邮件',
    ITEM_ADD_TASK: u'任务获得',
    ITEM_ADD_FATE: u'命格获取',
    ITEM_ADD_MERGE: u'物品合成',
    ITEM_ADD_GM: u'通过gm命令添加的物品',
    ITEM_ADD_USE: u'物品使用添加类型',
    ITEM_ADD_PAY: u'支付成功购买的商品',
    ITEM_FETCH_HITFATE: u'收取猎命',
    ITEM_FETCH_TIMEBOX: u'收取时光盒',
    ITEM_FETCH_EMAIL: u'收取邮件',
    ITEM_ADD_MINING: u'采矿所得',
    ITEM_ADD_DAY_ACHI: u'每日成就所得',
    ITEM_ADD_EVER_ACHI: u'永久成就所得',
    ITEM_ADD_DAY_LUCKY: u'每日抽奖所得',
    ITEM_ADD_DAY_SIGN: u'每日签到所得',
    ITEM_ADD_BFTASKBOX: u'兵符宝箱所得',
    ITEM_ADD_DEEPBOX: u'深渊宝箱所得',
    ITEM_ADD_FETE: u'祭天所得',
    ITEM_ADD_REWARDCODE: u'兑换码奖励所得',
    ITEM_ADD_ALLYCAT: u'同盟招财猫所得',
    ITEM_ADD_GEM_MINE: u'珠宝开采',
    ITEM_ADD_ALLY_WAR:u'狩龙战奖励添加',
}

#type > 50:消耗
ITEM_SELL = 51 #出售
ITEM_COST_INVITE = 52  #招募
ITEM_COST_MERGE = 53 #合成
ITEM_COST_STRONG = 54 #装备强化
ITEM_COST_USE = 55 #物品使用消耗
ITEM_COST_BFTASK = 56 #接兵符任务消耗
ITEM_COST_EXCHANGE = 57 #兑换坐骑消耗
ITEM_COST_HORN = 58 #大喇叭消耗
ITEM_COST_CRYSTAL = 59 #龙晶捐献

#装备定义
EQ_STRONG = 1 #装备强化
EQ_MOVE = 2 #装备转移

EQUIP_TYPE_MAP = {
EQ_STRONG: u'装备强化',
EQ_MOVE: u'装备转移',
}

#资金流转定义
#消耗1--100
COIN_MERGE = 1 #物品合成
COIN_SKILL_BACK = 2 #技能点取回
COIN_EQ_MOVE = 3 #强化等级转移
COIN_DEEP_AUTO = 4 #深渊挂机
COIN_BUFF_EAT = 5 #食馆
COIN_FETE = 6 #元宝祭天
COIN_POS_STUDY = 7 #阵型学习
COIN_POS_UP = 8 #阵型升级
COIN_HF_COIN1 = 9 #银币猎命
COIN_HF_COIN2 = 10 #元宝猎命
COIN_MINE_COIN1 = 11 #银币采矿
COIN_MINE_COIN2 = 12 #元宝采矿
COIN_TBOX_RESET = 13 #时光盒重置
COIN_BFTASK_RESET = 14 #刷新兵符任务
COIN_BFTASK_FINISH = 15 #兵符任务立即完成
COIN_ALLY_CREATE = 16 #同盟创建
COIN_ALLY_GRAVE = 17 #同盟宝具铭刻
COIN_ARENA = 18 #竞技场扣费
COIN_SHOP = 19 #神秘商店购买消耗
COIN_EXCHANGE_CAR = 20 #兑换坐骑
COIN_BOSS_CD = 21 #boss战的cd时间去除的消耗
COIN_ROLEUP = 22  #武将升段 段符消耗
COIN_ROLETARIN = 24 #武将培养 钱币消耗
COIN_GEM_MINE = 25 #珠宝开采

#添加101--200
COIN_ADD_GM = 101 #gm指令的添加
COIN_ADD_SELL = 102 #卖出物品的添加
COIN_ADD_ITEM = 103 #特殊物品的添加
COIN_ADD_ARENA = 104 #活动挑战奖励的添加
COIN_ADD_MINING_SELL = 105 #采矿背包不足自动变卖银币所得
COIN_ADD_FIGHT_WIN = 106 #主线战斗胜利奖励
COIN_FIRST_PAY = 107 #首次充值

# 摇钱树兑换 301-350
COIN_SUB_CTREE = 301  # 元宝摇钱树
COIN_ADD_CTREE = 302  #  摇钱树银元


#练厉 范围必须和coin分开 201--250
TRAIN_ARM = 201 #武器升级
TRAIN_BACK = 202 #练厉取回
TRAIN_BAG = 203 #奖励添加
TRAIN_ARENA = 204 #竞技场挑战奖励
TRAIN_GRAVE = 205 #同盟铭刻
TRAIN_GM = 206 #GM添加

COIN_RUNNING_MAP = {
    COIN_MERGE: u'物品合成',
    COIN_SKILL_BACK: u'技能点取回',
    COIN_EQ_MOVE: u'强化等级转移',
    COIN_DEEP_AUTO: u'深渊挂机',
    COIN_BUFF_EAT: u'食馆',
    COIN_FETE: u'元宝祭天',
    COIN_POS_STUDY: u'阵型学习',
    COIN_POS_UP: u'阵型升级',
    COIN_HF_COIN1: u'银币猎命',
    COIN_HF_COIN2: u'元宝猎命',
    COIN_MINE_COIN1: u'银币采矿',
    COIN_MINE_COIN2: u'元宝采矿',
    COIN_TBOX_RESET: u'时光盒重置',
    COIN_BFTASK_RESET: u'刷新兵符任务',
    COIN_BFTASK_FINISH: u'兵符任务立即完成',
    COIN_ALLY_CREATE: u'同盟创建',
    COIN_ALLY_GRAVE: u'同盟宝具铭刻',
    COIN_ARENA: u'竞技场扣费',
    COIN_SHOP: u'神秘商店购买消耗',
    COIN_EXCHANGE_CAR: u'兑换坐骑',
    COIN_BOSS_CD: u'boss战的cd时间去除的消耗',
    COIN_ROLEUP: u'武将升段',
    COIN_ROLETARIN: u'武将培养',
    COIN_GEM_MINE: u'珠宝开采',
    COIN_ADD_GM: u'gm指令的添加',
    COIN_ADD_SELL: u'卖出物品的添加',
    COIN_ADD_ITEM: u'特殊物品的添加',
    COIN_ADD_ARENA: u'活动挑战奖励的添加',
    COIN_ADD_MINING_SELL: u'采矿背包不足自动变卖银币所得',
    COIN_ADD_FIGHT_WIN: u'主线战斗胜利奖励',
    COIN_FIRST_PAY: u'首次充值',
    COIN_SUB_CTREE: u'元宝摇钱树',
    COIN_ADD_CTREE: u'摇钱树银元',
    TRAIN_ARM: u'武器升级',
    TRAIN_BACK: u'练厉取回',
    TRAIN_BAG: u'奖励添加',
    TRAIN_ARENA: u'竞技场挑战奖励',
    TRAIN_GRAVE: u'同盟铭刻',
    TRAIN_GM: u'GM添加',
}
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
