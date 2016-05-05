#-*- coding:utf-8 -*-
from datetime import timedelta
#一天
ONE_DAY_DELTA = timedelta(days=1)
ONE_DAY = 1
ONE_DAY_TIME = 60 * 60 * 24

#游戏服在线状态
#0=关闭,1=推荐,2=火爆,3=维护,4=内测结束

INT32_MAX = int((1 << 31) - 1)
INT32_MIN = int(-(1 << 31))
UINT32_MAX = (1 << 32) - 1

INT64_MAX = (1 << 63) - 1
INT64_MIN = -(1 << 63)
UINT64_MAX = (1 << 64) - 1

#初始化等级
INIT_LEVEL = 0
FATE_INIT_LEVEL = 1
GEM_INIT_LEVEL = 1

#交易类型
CANNOT_TRADE = 0
CAN_TRADE = 1

#品质定义
QUALITY_WHITE = 0
QUALITY_GREEN = 1
QUALITY_BLUE = 2
QUALITY_PURPLE = 3
QUALITY_ORANGE = 4
QUALITY_RED = 5
QCOLORS = 'qcolors'
QCOLORS_V = '0:ffffff|1:00FF00|2:0000FF|3:b469ab|4:f7941d|5:ff0000'

#是否使用
#没有使用
USED_NOT = 0
#使用
USED_DO = 1

#地图类型1:标准地图, 2:副本地图, 3=钓鱼, 4=采矿, 5=时光盒, 6=深渊, 7=同盟
MAP_NORMAL = 1
MAP_STAGE = 2
MAP_FISH = 3
MAP_MINE = 4
MAP_TBOX = 5
MAP_DEEP = 6
MAP_ALLY = 7
MAP_BOSS = 8
MAP_ALLY_BOSS = 9
MAP_ALLY_SKYWAR = 11   #同盟烛龙飞空战
MAP_ALLY_WORLDWAR = 12 #同盟魔龙降世战
MAP_ALLYS = {MAP_ALLY, MAP_ALLY_BOSS}
MAP_ALLY_WAR = {MAP_ALLY_SKYWAR, MAP_ALLY_WORLDWAR}

#场景玩家信息索引
IF_IDX_ID = 0
IF_IDX_NAME = 1
IF_IDX_LEVEL = 2
IF_IDX_RID = 3
IF_IDX_EID = 4
IF_IDX_CAR = 5
IF_IDX_POS = 6
IF_IDX_STATE = 7
IF_IDX_ALLY = 8
IF_IDX_QUALITYS = 9

#玩家信息索引
IPI_IDX_NAME = 0
IPI_IDX_RID = 1
IPI_IDX_LEVEL = 2
IPI_IDX_CBE = 3


#npc的方向
NPC_DIR_1 = 1
NPC_DIR_2 = 2
NPC_DIR_3 = 3
NPC_DIR_4 = 4
NPC_DIR_5 = 5
NPC_DIR_6 = 6
NPC_DIR_7 = 7
NPC_DIR_8 = 8
#保存位置的索引
PLAYER_POS_INDEX = 0
NPC_POS_INDEX = 1

#buff类型 1=食馆buff, 2=vipBuff
BUFF_TYPE_FOOD = 1
BUFF_TYPE_VIP = 2

#玄铁普通采集
MINING_COIN1 = 1
#玄铁高级采集
MINING_COIN2 = 2
#免费采集
MINING_FREE = 3

#物品列表键定义
IKEY_GROUP = 'g'
IKEY_TYPE = 't'
IKEY_COUNT = 'c'
IKEY_ID = 'i'
IKEY_IDS = 'is'
IKEY_TRADE = 'tr'
IKEY_QUALITY = 'q'
IKEY_EQSET = 's'
IKEY_LEVEL = 'lv'

#物品类型
IT_STUFF = 1 #材料
IT_USE = 2 #用品
IT_CHIP = 3 #装备碎片
IT_FISH = 4 #鱼获
IT_CHUM = 5 #鱼饵
IT_BF = 6 #兵符
IT_LEVEL_GIFT = 7#升级礼包
IT_USE_LIST = (IT_USE, IT_CHIP, IT_FISH, IT_LEVEL_GIFT)

#奖励列表中的物品类型
IT_ITEM_STR = 'i'
IT_EQUIP_STR = 'e'
IT_FATE_STR = 'f'
IT_CAR_STR = 'c'
IT_ROLE_STR = 'r' #配将
IT_GEM_STR = 'g' #珠宝

ITEM_TYPE_COLL_MAP = {
    IT_ITEM_STR: 'item',
    IT_EQUIP_STR: 'equip',
    IT_FATE_STR: 'fate',
    IT_CAR_STR: 'car',
    IT_ROLE_STR: 'role',
    IT_GEM_STR: 'gem',
}

#邮件类型
MAIL_NORMAL = 1 #弹出式
MAIL_REWARD = 2 #奖励  非弹出式
MAIL_BATTLE = 3 #战报  暂时不用
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
RW_MAIL_ACTIVITY = 11 #=活动礼包奖励
RW_MAIL_SYS = 12 #=系统补偿
SOCIAL_MAIL_FRIEND = 13 #社交好友添加
RW_MAIL_VIP = 14 #VIP奖励
RW_MAIL_LEVEL_UP = 15 #玩家升级奖励
RW_MAIL_COIN3 = 16	  #活动期间元宝登陆奖励
RW_MAIL_LEVEL_GIFTS_SET = 17 #第三次封测 升级送公测好礼 设置通知
RW_MAIL_LEVEL_GIFTS_GET = 18 #第三次封测 升级送公测好礼 领取通知
RW_MAIL_COIN3A = 19	  #活动期间元宝登陆奖励连续登陆的奖励
RW_MAIL_FIRST_CHARGE = 20 #vip首充奖励
RW_MAIL_RECRUIT_ROLE = 21 #玩家招募武将奖励
RW_MAIL_LEVEL_RANK = 22 #玩家等级排行奖励
RW_MAIL_CBE_RANK = 23 #玩家战斗力排行奖励
RW_MAIL_COST_COIN3 = 24 #累积消费大赠送
RW_MAIL_WORLDBOSSID = 25 #世界boss伤害奖励
RW_MAIL_VIP_PAY = 26 #充值奖励
RW_MAIL_DAY1 = 27 #等级达到天天领好礼
RW_MAIL_DAYLUCKY = 28 #每日抽奖奖励
RW_MAIL_BOSSVIP = 29 #世界boss vip奖励
RW_MAIL_BOSSJOIN = 30 #世界boss参战奖励
RW_MAIL_HFATE = 31 #星力伴成长活动(观星一定次数送奖励)
RW_MAIL_BOSSDOUBLE = 32 #世界boss双倍奖励
RW_MAIL_INTENSIFY = 33 #装备强化
RW_MAIL_WEEKDAYTIME1 = 34 #周末时长非最后的邮件奖励
RW_MAIL_WEEKDAYTIME2 = 35 #周末时长最后的邮件奖励

RW_MAIL_WEEKDAYPAY = 36   #周末只一次充值
RW_MAIL_JOINARMY = 37 #新兵入伍
RW_MAIL_PEERLESS = 38 #猛将无双
RW_MAIL_HOLYAPPEAR = 39 #神装显世
RW_MAIL_FISHWATER = 40 #雨水之欢
RW_MAIL_PAY_LEVEL = 41  #累计购买礼包
RW_MAIL_HOLDMAILTIME1 = 42 #实时在线时长非最后的邮件奖励
RW_MAIL_HOLDMAILTIME2 = 43 #实时在线时长最后的邮件奖励
RW_MAIL_TBOX_NUM = 44      #时光盒次数奖励
RW_MAIL_AWAR_NPC = 45      #狩龙战击杀npc获得的奖励(背包满)
RW_MAIL_AWARSKY_END = 46   #狩龙战飞龙在天完毕获得奖励(背包满)
RW_MAIL_AWARWORLD_END = 47   #狩龙战降龙完毕获得奖励(背包满)
RW_MAIL_AWARWORLDCOPY_END = 48 #狩龙战降龙影分身完毕获得奖励(背包满)

#世界boss奖励对应的id
RW_WORLDBOSSID = 15

#待收物品类型WaitItem
#猎命
WAITBAG_TYPE_HITFATE = 1
#时光盒
WAITBAG_TYPE_TIMEBOX = 2
#渔获
WAITBAG_TYPE_FISHING = 3
#邮件
WAITBAG_TYPE_EMAIL = 4

#初章
CHATER_START = 1

#交易列表索引
TRADE_IDX = 0
NOTRADE_IDX = 1

#特殊物品id区间
DIFF_TITEM_IDS = xrange(1, 21)
#特殊物品id(id<=20)(1=银币，2=元宝，3=绑定元宝，4=经验，5=打坐经验，6=练历, 7=时光盒)
DIFF_TITEM_COIN1 = 1
DIFF_TITEM_COIN2 = 2
DIFF_TITEM_COIN3 = 3
DIFF_TITEM_EXP = 4
DIFF_TITEM_SITE_TIME = 5
DIFF_TITEM_ARMEXP = 6
DIFF_TITEM_TBOX = 7

#钓鱼的鱼饵类型
#白色鱼饵
FISH_WHITE = 1

#钓鱼的进行的状态类型
#钓鱼空闲状态
FISH_FREE = 0
#一次钓鱼
FISH_ONCE   = 1
#批量钓鱼
FISH_BATCH  = 2
#委托NPC钓鱼
FISH_NPC    = 3
#玩家进入钓鱼地图 可进行的状态
FISH_ENTER_NEWSTART = 1
FISH_ENTER_RESTART = 2
#起钓的技巧品质
FISH_LOSE = 1                   #大圈在小圈外面
FISH_GOOD = 2                   #大圈在小圈里面
FISH_PERFECT = 3                #大小圈刚好重合
FISH_NPC_QUALITY = FISH_GOOD    #委托NPC的品质

#猎命的类型
#银币猎命
HITFATE_COIN1 = 1
#元宝猎命
HITFATE_COIN2 = 2
#vip免费使用次数
HITFATE_FREE = 3

#祭天的类型
#免费祭天
FETE_FREE = 1
#元宝祭天
FETE_COIN2 = 2
#祭天结果无获取
FETE_TYPE_NO = -1
#祭天记过当天下一次翻倍
FETE_TYPE_DOUBLE = -2

#食馆方案类型
FOOD_PLAN_1 = 1
FOOD_PLAN_2 = 2


#全局设置表的key
#绿色配将初始化
GREEN_ROLE_INIT_CMD = 'greenRoleInit'
GREEN_ROLE_INIT_CMD_V = """#-*- coding:utf-8 -*-
#全套侠客装
equips = []
with my.raw_return_context():
    for i in xrange(1, 7):
        equip = my.add_equip(i, forced=1)
        my.wear_equip(%(id)d, equip.data.id, is_base=0, send=0)
        equips.append(equip)
"""
#新手初始化设置
NEW_PLAYER_CMD = 'newPlayerCmd'
#测试用
#NEW_PLAYER_CMD_V = """#-*- coding:utf-8 -*-
#my.upgrade(1, False) #1级
#my.position_study(1)
#my.add_role(22)#孙尚香
#my.position_place(1, 22, 7)
##银币5000，绑定元宝100
##测试用
#my.add_money(coin1=99999, coin3=99999, is_set=True)
#for rid in [100001, 100007, 100011, 100023, 100024, 100025]:
#    my.reward(rid)
#my.add_item(24, 20)
#my.add_item(30, 10)
#my.add_equip(2)
#my.wear_equip(%(rid)d, 2)
#"""
#正式用
NEW_PLAYER_CMD_V = """#-*- coding:utf-8 -*-
my.upgrade(1, False) #1级
my.position_study(1)
my.add_role(22)#孙尚香
my.position_place(1, 22, 7)
#钱币
my.add_money(coin1=0, coin2=90, coin3=500, is_set=True, vip=1)
#升级礼包
my.add_item(11001, 1)

#材料
for i,c in [(24,40), (30, 10),
        ]:
    my.add_item(i, c)
#星力
for i,c in [(1,1), (2,1), (3,1), (4,1)]:
    for _ in xrange(c):
        my.add_fate(i)

#玩家全套侠客装
for i in xrange(1, 7):
    my.add_equip(i)
    my.wear_equip(%(rid)d, i)
"""


#新手引导角色配置
GUIDE_PLAYER_CMD = 'guidePlayerCmd'
GUIDE_PLAYER_CMD_V = """#-*- coding:utf-8 -*-
if not len(my.player.task.tasks):
    my.clear_player()
    my.add_task(1)#主任务
    my.add_role(%(rid)d)#主将
    my.add_role(35)#莲华
    my.add_equip(32)
    my.wear_equip(%(rid)d, 32)#主将换装
    my.position_study(1)
    my.position_place(1, 35, 9)
    my.position_place(1, %(rid)d, 5)
my.player.data.chapter = 1 #初章
my.upgrade(500, False)
my.scene_enter(9)
"""
#新手引导数据清理
GUIDE_PLAYER_CLEAR = 'guidePlayerClear'
GUIDE_PLAYER_CLEAR_V = """
my.del_role(35)#莲华
if my.player.roles.main_role is None:
    my.add_role(%(rid)d)#主将
else:
    my.player.roles.main_role.take_off_equips()
my.player.bag.clear()
my.position_place(1, 0, 9)
my.position_place(1, %(rid)d, 5)
"""
#引导角色id与主角id对应关系
GUIDE_ROLES = 'guideRoles'
GUIDE_ROLES_V = """{1:7,2:8,3:9,4:10,5:11,6:12}"""
GUIDE_PASS = 'guidePass'

#同盟
#同盟操作成功
ALLY_OP_SUCCEED = 1
#创建同盟的金钱
ALLY_CREATE_COIN1 = 'allyCreateCoin1'
ALLY_CREATE_COIN1_V = 100000
#创建同盟的最低等级
ALLY_CREATE_LEVEL = 'allyCreateLevel'
ALLY_CREATE_LEVEL_V = 30
#同盟天舟等级
ALLY_BOAT_LEVLES = "allyBoatLevel"
ALLY_BOAT_LEVLES_V = "10000:1|40000:2|100000:3|500000:4|1000000:5|5000000:6|10000000:7|2000000:8"
#同盟天舟龙晶捐献对应的建设值
ALLY_BOAT_CRYSTAL = "allyCrystal"
ALLY_BOAT_CRYSTAL_V = "1500|1000"

#同盟日志的最多个数
ALLY_LOG_MAX_NUM = 50
#职责的定义
ALLY_MAIN = 1       #盟主
ALLY_ASSIST = 2     #副盟主
ALLY_ELDER = 3      #长老
ALLY_PROTECTER   = 4   #护法
ALLY_ESSENCER = 5   #精英
ALLY_MEMBER = 6     #盟友
#操作类型
ALLY_OP_JOIN = 1    #加入
ALLY_OP_EXIT = 2    #退出
ALLY_OP_CONTRIBUTE = 3  #贡献
ALLY_OP_DUTY = 6    #易职
ALLY_OP_TICK = 7    #踢人
#铭刻VIP类型
VIP_GRAVE = 4   #低级的VIP铭刻

ALLY_GRAVE1 = 1   #低级铭刻
ALLY_GRAVE2 = 2   #中级铭刻
ALLY_GRAVE3 = 3   #高级铭刻
ALLY_VIP_GRAVE1 = 4   #低级的VIP铭刻
ALLY_VIP_GRAVE2 = 5   #中级的VIP铭刻
ALLY_VIP_GRAVE3 = 6   #高级的VIP铭刻
#每页同盟的个数
ALLY_ALLYS_P_NUM = 'allyAllysPerNum'
ALLY_ALLYS_P_NUM_V = 6
#招财猫的次数
ALLY_CAT_NUM = 'allyCatMaxNum'
ALLY_CAT_NUM_V = "0:3|1:5|3:6"      #招财猫的奖励ID
ALLY_CAT_RID = "allyCatId"
ALLY_CAT_RID_V = 18
#招财猫返回给client的key
ALLY_CAT_COUNT = 'cn'
#宝具铭刻的次数
ALLY_GRAVE_NUM = 'allyGraveMaxNum'
ALLY_GRAVE_NUM_V = "0:3|1:5|3:6"      #宝具铭刻
#宝具铭刻返回给client的key
ALLY_GRAVE_COUNT1 = 'gn1'
ALLY_GRAVE_COUNT2 = 'gn2'
#同盟炼妖次数
ALLY_TBOX_NUM = 'allyTboxNum'
ALLY_TBOX_NUM_V = 5
#同盟炼妖奖励次数
ALLY_TBOX_RW_NUM = 'allyTboxRwNum'
ALLY_TBOX_RW_NUM_V = 1

#在线奖励
#在线奖励中 在线时长奖励结束
REWARDONLINE_TIME_END = 9
#在线奖励中 登录次数的奖励结束
REWARDONLINE_LOGIN_END = 13

#在线奖励的类型
REWARDONLINE_TYPE_TIME = 1
REWARDONLINE_TYPE_LOGIN = 2
#活动奖励的类型
REWARDACTIVE_RECHARGE = 1
REWARDACTIVE_WEPONUP = 2
REWARDACTIVE_RECRUIT = 3
#充值奖励为初始值
REWARDACTIVE_RCH_DEFAULT = 0
#充值奖励可以领
REWARDACTIVE_RCH_OPEN = 1
#充值奖励已领
REWARDACTIVE_RCH_CLOSE = 2
#招募蓝色同伴奖励
REWARDACTIVE_CALL_BLUE = 1
#招募绿色同伴奖励
REWARDACTIVE_CALL_GREEN = 2
#招募紫色同伴奖励
REWARDACTIVE_CALL_PURPLE = 1

#社交系统
#最近联系人的数目
SOCIAL_RECENTLY_NUM = 30

#背包默认开启格子数
BAG_SIZE = 'bagSize'
BAG_SIZE_V = 60
#白色钓鱼上线次数(fishWhiteMax)
FISH_WHITE_MAX = 'fishWhiteMax'
FISH_WHITE_MAX_V = 5
#委托npc钓鱼时间
FISH_NPC_TIME = "npcFishTime"
FISH_NPC_TIME_V = 1800
#白色鱼饵应该获取的奖励RID
FISH_WHITE_RID = 'fishWhiteRid'
FISH_WHITE_RID_V = 42

#采集矿石
#采集场景进入条件
MINING_LEV_LIMIT = "mineEnterLevel"
MINING_LEV_LIMIT_V = 20
MINING_BATCH_NUM = "mineBatchNum"
MINING_BATCH_NUM_V = 10
#挖矿批量权限
MINING_BATCH_VIP = "mineBatchVip"
MINING_BATCH_VIP_V = 5
#采矿银币折算上限
MINING_COIN1_LIMIT = "mineCoin1Limit"
MINING_COIN1_LIMIT_V = 1000 * 1000

##猎命银币上线次数(hitFateCoin1Max)
#HITFATE_COIN1_MAX = 'hitFateCoin1Max'
#HITFATE_COIN1_MAX_V = 50
#猎命高级vip开通等级(hitFateCoin2Vip)
HITFATE_COIN2_VIP = 'hitFateCoin2Vip'
HITFATE_COIN2_VIP_V = 1
#批量猎命vip开通等级(hitFateBatchVip)
HITFATE_BATCH_VIP = 'hitFateBatchVip'
HITFATE_BATCH_VIP_V = 6
#批量猎命一批多少次(hitFateBatchNum)
HITFATE_BATCH_NUM = 'hitFateBatchNum'
HITFATE_BATCH_NUM_V = 10
#祭天一次元宝的使用数量
FETE_COIN2_NUM = 'feteCoin2Num'
FETE_COIN2_NUM_V = 50
#一个账号最多能新建的角色数目(userPlaysMax)
USE_PLAYS_MAX = 'userPlaysMax'
USE_PLAYS_MAX_V = 20
#玩家最高允许等级
PLAYER_LEVEL_MAX = 'playerMaxLevel'
#PLAYER_LEVEL_MAX = '﻿playerMaxLevel' 存在特殊不可见字符"\uFEFF",引起错误
#同场景最多玩家数
MAP_ROLES_MAX = 'mapRolesMax'
MAP_ROLES_MAX_V = 50

#武器练历可收回的最低等级(trainMinLevel)
TRAIN_MIN_LEVEL = 'trainMinLevel'
TRAIN_MIN_LEVEL_V = 5
#武器练历元宝收回每阶使用的元宝数(trainCoin2Num)
TRAIN_COIN2_NUM = 'trainCoin2Num'
TRAIN_COIN2_NUM_V = 5
#武器练历免费收回的百分比(trainFreeRate)
TRAIN_FREE_RATE = 'trainFreeRate'
TRAIN_FREE_RATE_V = 90
#打坐的经验按每多长时间发放一次(sitExpPerTime)
SIT_EXPPER_TIME = 'sitExpPerTime'
SIT_EXPPER_TIME_V = 60
#打坐限时(sitTimeMax)
SIT_TIME_MAX = 'sitTimeMax'
SIT_TIME_MAX_V = 86400
#武器开通第一个技能的等级(armLevelSk1)
ARM_LEVEL_SK1 = 'armLevelSk1'
ARM_LEVEL_SK1_V = 3
#武器开通第二个技能的等级(armLevelSk2)
ARM_LEVEL_SK2 = 'armLevelSk2'
ARM_LEVEL_SK2_V = 6
#大喇叭消耗的物品iid
HORN_COST_ID = 'hornCostId'
HORN_COST_ID_V = '44'

#狩龙战
#队长选择势力地图的时间限制
AWAR_WORLD_CHOOSE_TIME= 'awarWorldChooseTime'
AWAR_WORLD_CHOOSE_TIME_V = 10

#珠宝系统
GEM_MAX_INDEX = 'gemMaxIndex'
GEM_MAX_INDEX_V = '2:1:1|3:10:30|4:50:60'
GEM_MAX_LEVEL = 'gemMaxLevel'
GEM_MAX_LEVEL_V = 10
GEM_SANDING_QUALITY = 'gemSandingQuality'
GEM_SANDING_QUALITY_V = '1:1:80|2:2:50|3:3:20'
GEM_SANDING_LEVEL = 'gemSandingLevel'
GEM_SANDING_LEVEL_V = '1:1:100|2:1:80|2:2:20|3:1:80|3:2:20|3:3:10'
GEM_SANDING_TYPE = 'gemSandingType'
GEM_SANDING_TYPE_V = '63:5:50|63:1:50|64:5:50|64:9:50|64:1:50|65:5:50|65:9:50|' \
                     '65:1:50|65:12:50|66:4:50|66:3:50|67:4:50|67:11:50|67:3:50|' \
                     '68:4:50|68:11:50|68:3:50|68:17:50|69:6:50|69:14:50|70:6:50|' \
                     '70:16:50|70:14:50|71:6:50|71:16:50|71:14:50|71:15:50|72:7:50|' \
                     '72:8:50|72:2:50|73:7:50|73:8:50|73:2:50|73:13:50|74:7:50|' \
                     '74:8:50|74:2:50|74:10:50|74:13:50'
GEM_UPGRADE_RATE = 'gemUpgradeRate'
GEM_UPGRADE_RATE_V = '50:50:35:23:13:5|35:35:23:13:5:1|25:25:15:7:1:1|23:23:13:5:1:1|' \
                     '17:17:8:2:1:1|13:13:5:1:1:1|12:12:5:1:1:1|11:11:4:1:1:1|8:8:2:1:1:1|' \
                     '6:6:1:1:1:1|5:5:1:1:1:1|3:3:1:1:1:1|2:2:1:1:1:1|1:1:1:1:1:1'
GEM_MINE_FREE_NUM = 'gemMineFreeNum'
GEM_MINE_FREE_NUM_V = 10
GEM_MINE_COIN3_NUM = 'gemMineCoin3Num'
GEM_MINE_COIN3_NUM_V = 30
GEM_MINE_COIN3_COST = 'gemMineCoin3Cost'
GEM_MINE_COIN3_COST_V = '20+(%s-1)*5'
GEM_MINE_REWARD = 'gemMineReward'
GEM_MINE_REWARD_V = '218,219,220'
GEM_MINE_REWARD_COIN_NUM = 'gemMineRewardCoinNum'
GEM_MINE_REWARD_COIN_NUM_V = 16
GEM_MINE_VIP_LEVEL = 'gemMineVipLevel'
GEM_MINE_VIP_LEVEL_V = 5
GEM_SHOP_MAX_INDEX = 'gemShopMaxIndex'
GEM_SHOP_MAX_INDEX_V = 20
GEM_SHOP_INDEX_COST = 'gemShopIndexCost'
GEM_SHOP_INDEX_COST_V = '1:50|2:100|3:150|4:200|5:250|6:300|7:350|8:400|9:450|10:500'
GEM_SHOP_DEFAULT_INDEX = 'gemShopDefaultIndex'
GEM_SHOP_DEFAULT_INDEX_V = 10
GEM_SHOP_RESET_COST = 'gemShopResetCost'
GEM_SHOP_RESET_COST_V = '10:1:10|20:11:20|50:21:10000000'


VIP_BASE_COIN = "vipBaseCoin"
VIP_BASE_COIN_V= 90
#涉及到VIP等级而变化的全局变量>>>>>>>>>>start
VIP_LEVELS = 'vipLevels'                            #累计充值元宝对应vip等级
VIP_LEVELS_V = '0:0|1:1|10:2|50:3|100:4|200:5|300:6'
VIP_REWARD = 'vipLevRewards'                        #vip等级的奖励
VIP_REWARD_V = '0:0|1:1|2:3|3:4'

VIP_LV_BAGS = 'vipLvBags'                           #背包大小
VIP_LV_BAGS_V = '0:60|1:65'

VIP_LV_FRIENDS = 'vipLvFriends'                     #社交好友数量
VIP_LV_FRIENDS_V = '0:30|3:55'

VIP_LV_SHOPS = 'vipLvShops'                         #神秘商人重置次数
VIP_LV_SHOPS_V = '0:0|2:1|3:2|5:3|8:4|9:5'
SHOP_RESET_COST = 'shopResetCost'                         #神秘商人重置元宝花费
SHOP_RESET_COST_V= '50'

DEEP_AUTO_TIMES = 'deepAutoTimes'                   #深渊自动挂机时间
DEEP_AUTO_TIMES_V = '0:45|1:40|2:35'
DEEP_RESET_TIMES = 'deepResetTimes'                 #深渊重置时间
DEEP_RESET_TIMES_V = "0:86400|3:43200|5:21600"     #秒

FETE_FREE_MAX = 'feteFreeMax'                       #祭天免费上限次数(feteFreeMax)
FETE_FREE_MAX_V = "0:20|1:25|3:30|5:50"
FETE_COIN2_MAX = 'feteCoin2Max'                     #祭天元宝上限次数(feteCoin2Max)
FETE_COIN2_MAX_V = "0:20|1:25|3:30|5:50"

HITFATE_FREE_MAX = 'hitFateFreeMax'                 #猎命免费次数(hitFateCoin1Max)
HITFATE_FREE_MAX_V = '0:20|1:25|3:30'
HITFATE_COIN1_MAX = 'hitFateCoin1Max'               #猎命银币上线次数(hitFateCoin1Max)
HITFATE_COIN1_MAX_V = '0:50|1:60|3:70'
HITFATE_COIN2_MAX = 'hitFateCoin2Max'               #猎命元宝上限次数(hitFateCoin2Max)
HITFATE_COIN2_MAX_V = '0:20|1:25|3:30'

SIT_ADD_EXP = 'vipLevSit'                           #vip打坐提速
SIT_ADD_EXP_V = '0:0|1:10|12:10'

BF_RE_NUM = 'bfReNum'                                #兵符免费刷新次数(bfReNum)
BF_RE_NUM_V = "0:3|2:4|3:5"

VIP_FISH_BATCH = "vipFishBatch"                     #钓鱼批量的权限
VIP_FISH_BATCH_V = "0:0|5:1"

VIP_MINING_FREE = "vipLvMinings"                    #挖矿免费次数
VIP_MINING_FREE_V = "0:10|1:3|5:10"

ARENA_MAX_REWARD = 'arenaMaxReward'                 #竞技场最高银币和历练奖励
ARENA_MAX_REWARD_V = '0:5000:500|1:6000:600|2:7000:700|3:8000:800'

TBOX_FREE_NUM = 'tboxFreeNum'                       #时光盒免费重置次数(tboxFreeNum)
TBOX_FREE_NUM_V = '0:1|3:2|6:3'

#狩龙战
AWAR_CONNON_MAX = 'awarConnonMax'
AWAR_CONNON_MAX_V = 100
AWAR_FIRE_DESC = 'awarFireDesc'
AWAR_FIRE_DESC_V = 'BOSS遭到|%(pname)s|的炮轰，造成伤害 |%(hutrt)s| 点！'
AWAR_BOAT_DESC = 'awarHitBoatDesc'
AWAR_BOAT_DESC_V = '危险！天舟遭到BOSS袭击，耐久度损失 |%(hutrt)s| 点！'

#活动奖励
#奖励的期限范围
ACTIVEDATE1 = 'activeDate1'                             #非连续的
ACTIVEDATE1_V = '130315:130331'                         #2013.3.15---2013.3.31
ACTIVEDATE2 = 'activeDate2'                             #有连续登陆判断的
ACTIVEDATE2_V = '130406:130416'                         #2013.4.10---2013.4.16
#等级奖励
LEVELUPREWARD = "levelUpReward"
LEVELUPREWARD_V =  '30:30|40:40|50:50|60:60'           #{等级:奖励id}
#2013.3.15---2013.3.31的元宝奖励
COIN3REWARD = "coin3Reward"                              #非连续的
COIN3REWARD_V =  '1:11|2:21|18:0'
COIN3REWARDPERSIST = "coin3PersistReward"               #有连续登陆判断的
COIN3REWARDPERSIST_V = '1:11|2:21|18:0'

#第三次封测  升级送公测好礼
REWARD_LEVEL_GIFTS = 'RewardLevelGifts'
REWARD_LEVEL_GIFTS_V = '40:205001|50:205002|55:205003'
REWARD_LEVEL_GIFTS_SET_TIME = 'RewardLevelGiftsSetTime'
REWARD_LEVEL_GIFTS_SET_TIME_V = '130410:130417'
REWARD_LEVEL_GIFTS_GET_TIME = 'RewardLevelGiftsGetTime'
REWARD_LEVEL_GIFTS_GET_TIME_V =  '130423:130601'

VIP_FIGHT_MULTIPLE = 'vipFightMultiple'
VIP_FIGHT_MULTIPLE_V = '0:1:1.5|1:1.5:2|4:2:2'
VIP_FIGHT_SPEED_NUM = 'vipFightSpeedNum'
VIP_FIGHT_SPEED_NUM_V = '0:3|1:3|4:-1'

#涉及到VIP等级而变化的变量>>>>>>>>>>end

# 摇钱树的资源定义
CTREE_VIP_LEVEL_MAP_COUNT = 'ctreeVipNum'
CTREE_VIP_LEVEL_MAP_COUNT_V = '1:10|6:12|8:15|10:20|12:30'
CTREE_EXCHANGE_MAP = 'ctreeExchangeMap'
CTREE_EXCHANGE_MAP_V = '2.5+2.5*n|c2*(2000+50*(n-1))'
CTREE_PLAYER_ATTR_COINSTREE = 'ctree'
CTREE_OPEN_LEVEL_K = 'ctreeLevel'
CTREE_OPEN_LEVEL_V = 40

# 摇钱树的资源定义 -----------------------end

#兵符任务获取宝箱积累的上限(bfBoxMax)
BF_BOX_MAX = 'bfBoxMax'
BF_BOX_MAX_V = '0:15|3:20|4:30'
#兵符免费产生上限(bfReNumMax)
BF_RENUM_MAX = 'bfReNumMax'
BF_RENUM_MAX_V = 5
#兵符刷新产生的时间(bfReTime, int)
BF_RE_TIME = 'bfReTime'
BF_RE_TIME_V = 1800
#兵符元宝刷新所需元宝的数量(bfReCoin2)
BF_RE_COIN2 = 'bfReCoin2'
BF_RE_COIN2_V = 10
#兵符全紫刷新所使用的元宝数(bfReAllCoin2)
BF_RE_ALLCOIN2 = 'bfReAllCoin2'
BF_RE_ALLCOIN2_V = 100
#兵符任务开启直接完成的最低vip等级(bfFinishVip)
BF_FINSHIN_VIP = 'bfFinishVip'
BF_FINSHIN_VIP_V = 4
#兵符任务立即完成花费银币数量(bfFinishCoin1)
BF_FINSHIN_COIN1 = 'bfFinishCoin1'
BF_FINSHIN_COIN1_V = 2500
#兵符任务宝箱开启所需的经验值(bfBoxNeedExp)
BF_BOX_NEEDEXP = 'bfBoxNeedExp'
BF_BOX_NEEDEXP_V = 8
#兵符宝箱奖励id设置(bfBoxReward)
BF_BOX_REWARD = 'bfBoxReward'
BF_BOX_REWARD_V = '0:77|20:76|35:78'
#兵符宝箱极品物品位置(bfBoxBest)
BF_BOX_BEST = 'bfBoxBest'
BF_BOX_BEST_V = '1,2,3|2,4|5,7'
#兵符任务完成不同兵符对应的经验点(bfTypeExp)
BF_TYPE_EXP = 'bfTypeExp'
BF_TYPE_EXP_V = '1|2|4|8'


#食馆上次使用时间
FOOD_USE_TIME = 'foodUseTime'
#食馆buff持续时长
FOOD_BUFF_TIME = 'foodBuffTime'
FOOD_BUFF_TIME_V = 8 * 60 * 60 #8小时
#点卷id
FOOD_ROLL = 'foodRoll'
FOOD_ROLL_V = 10001
#时光盒付费重置次数(tboxCoinNum)
#深渊普通怪战士,法师id
DEEP_GUARD_IDS = 'deepGuardIds'
DEEP_GUARD_IDS_V = '1002|1003'
DEEP_GUARD_BUFF = 'deepGuardBuff'
DEEP_GUARD_BUFF_V = 'ATK_P:10|HP_P:10'

#深渊单次战斗buff加成(deepBuff, str, 'ATK:2|HP:2')
DEEP_BUFF = 'deepBuff'
DEEP_BUFF_V = 'ATK_P:2|HP_P:2'
#深渊宝箱npc id
DEEP_BOX_NPC = 'deepBoxNpc'
DEEP_BOX_NPC_v = 1006
#深渊地图起始id(深渊0层的地图id)
DEEP_MAP_ID = 'deepMapId'
DEEP_MAP_ID_v = 10001
DEEP_AUTO_COST = 'deepAutoCost'
DEEP_AUTO_COST_V = 0.5 #元宝
#深渊进入等级限制
DEEP_ENTER_LEVEL = "deepEnterLevel"
DEEP_ENTER_LEVEL_V = 30
#竞技场
ARENA_AUTO_START = 'arenaAutoStart'
ARENA_AUTO_START_V = 5
ARENA_LEVEL = 'arenaLevel' #玩家竞技场开放等级
ARENA_LEVEL_V = 30 #玩家竞技场开放等级
ARENA_FREE_COUNT = 'arenaFreeCount'
ARENA_FREE_COUNT_V = 20
ARENA_YB = 'arenaYB'
ARENA_YB_V = 5
ARENA_RANK = 'arenaRank' #竞技玩家列表规则
ARENA_RANK_V = '1:=:1:2:3:4:5:6|9:-:5:4:3:2:1|21:-:15:10:5:2:1'
#竞技成功与失败的奖励
ARENA_RW_SUCC = 'arenaRWSucc'
ARENA_RW_SUCC_v = '1000|100'
ARENA_RW_FAIL = 'arenaRWFail'
ARENA_RW_FAIL_v = '500|50'
#竞技排行榜奖励时间(周几)
ARENA_RW_WEEKDAY = 'arenaRWWeekday'
ARENA_RW_WEEKDAY_V = '3|7'
#竞技场排行榜奖励
ARENA_REWARDS = 'arenaRewards'
#格式:排名:奖励id|..., 如下:[1,2)=1, 最后需要指定奖励id=0标记奖励结束
ARENA_REWARDS_V = '1:1|2:2|3:3|4:4|10:10|51:51|101:101|501:501|1001:1001|2001:0'
ARENA_INFO_COUNT = 'c'

#时光盒付费充值次数(tboxCoinNum)
TBOX_COIN_NUM = 'tboxCoinNum'
TBOX_COIN_NUM_V = 1
#时光盒付费重置所需元宝(tboxCoins,第一次|第二次|第三次 如：35|50|60)
TBOX_COINS = 'tboxCoins'
TBOX_COINS_V = '20'
#时光盒秒杀开通等级(tboxKillLevel)
TBOX_KILL_LEVEL = 'tboxKillLevel'
TBOX_KILL_LEVEL_V = 60
#神秘商店显示数目
SHOP_ITEM_NUM = 'shopItemNum'
SHOP_ITEM_NUM_V = 6
#boss
#获取boss开启的通知时长（bossNoticeTime）
BOSS_NOTICE_START = 'bossNoticeTime'
BOSS_NOTICE_START_V = 300
#世界boss战开启的时间(bossStartTime, str)
BOSS_START_TIME = 'bossStart'
BOSS_START_TIME_V = '45000:1|68400:31'
#世界boss战vip奖励
BOSS_REWARD_VIP = 'bossRewardVip'
BOSS_REWARD_VIP_V = 6

#boss血量每隔多久广播(bossHpTime, int)
BOSS_HP_TIME = 'bossHpTime'
BOSS_HP_TIME_V = 2
#每隔多久广播一次排名(bossRankTime, int)
BOSS_RANK_TIME = 'bossRankTime'
BOSS_RANK_TIME_V = 2
#同盟boss开启的同盟等级(bossAllyLevel, int)
BOSS_ALLY_LEVEL = 'bossAllyLevel'
BOSS_ALLY_LEVEL_V = 1
#同盟boss战总时长(bossAllyTimes, int)
BOSS_ALLY_TIME = 'bossAllyTimes'
BOSS_ALLY_TIME_V = 1800
#同盟boss开启的默认时间
BOSS_ALLY_START = 'bossAllyStart'
BOSS_ALLY_START_V = '7-18-30'
#世界boss战总时长(bossTimes, int)
#todo
#BOSS_TIME = 'bossTimessssss'
#BOSS_TIME_V = 40
BOSS_TIME = 'bossTimes'
BOSS_TIME_V = 1800
#世界boss获取cd每秒钟消耗元宝数
BOSS_CD_COIN2 = 'bossCdCoin2'
BOSS_CD_COIN2_V = 1
#世界boss获取cd每秒钟消耗元宝数
BOSS_ALLYCD_COIN2 = 'bossAllyCdCoin2'
BOSS_ALLYCD_COIN2_V = 1
#世界boss战解锁等级
BOSS_ENTER_LEVEL = 'enterBossLevel'
BOSS_ENTER_LEVEL_V = 30
#世界boss每次用元宝添加buff的值
BOSS_ADD_BUFF = 'bossBuff'
BOSS_ADD_BUFF_V = 'PATK:2|PHP:2'
#世界bossbuff加成上线(bossMaxBuff, str, 'PATK:2|PHP:2')
BOSS_MAX_BUFF = 'bossMaxBuff'
BOSS_MAX_BUFF_V = 'PATK:20|PHP:20'
#防止boss战斗多次提交伤害的时间间隔
BOSS_SAFE_TIME = 'bossSafeTimes'
BOSS_SAFE_TIME_V = 10
#世界boss在多少秒内被击杀后升级(bossKillTime, int)
BOSS_KILL_TIME = 'bossKillTime'
BOSS_KILL_TIME_V = 600
#每日连续登陆可累计抽奖次数上限(dayLuckyMDraws, str)<vip>:<次数> = 0:3|2:4|3:5
DAYLUCKY_MDRAW_NUM = 'dayLuckyMDraws'
DAYLUCKY_MDRAW_NUM_V = '0:3|1:4'
#vip起始抽奖次数(dayLuckyDraws, str)
DAYLUCKY_DRAW_NUM = 'dayLuckyDraws'
DAYLUCKY_DRAW_NUM_V = '0:1|1:2'
#创号前几天有特殊奖励(dayLuckyCDays, int)
DAYLUCKY_CRATE_DAYS = 'dayLuckyCDays'
DAYLUCKY_CRATE_DAYS_V = 3

#武将升段
#每日每个武将能升段的次数
ROLEUP_DAY_NUM = 'roleUpNum'
ROLEUP_DAY_NUM_V = 3
#武将升段消耗的物品
ROLEUP_COST_ITEM = 'roleUpCost'
ROLEUP_COST_ITEM_V = '33|1'
#武将免费培养
ROLETRAIN_COIN1 = 'roleTrainCoin1'
ROLETRAIN_COIN1_V = ''
#武将元宝培养j
ROLETRAIN_COIN2 = 'roleTrainCoin2'
ROLETRAIN_COIN2_V = ''
#武将培养消耗
ROLETRAIN_COST = 'roleTrainCost'
ROLETRAIN_COST_V = '5000|50'
#武将培养解锁等级
ROLETRAIN_LOCKLEVEL = 'roleTrainlockLevel'
ROLETRAIN_LOCKLEVEL_V = 30

#每日签到
DAYSIGN_DAY2RID = 'daySignDay2Rid'
DAYSIGN_DAY2RID_V = '1:10001|2:10002|3:10003' \
                    '|4:10004|5:10005|6:10006' \
                    '|7:10007|8:10008|9:10009' \
                    '|10:10010|11:10011|12:10012' \
                    '|13:10013|14:10014|15:10015'
DAYSIGN_OVERTASKID = 'daySignOverTaskId'
DAYSIGN_OVERTASKID_V = 35

#buff聚气加成(buffMp, int, 5)
BUFF_MP = 'buffMp'
BUFF_MP_V = 5

#神秘商店的商店类型
SHOP_TYPE_RARE = 1
SHOP_TYPE_LUCK = 2
#神秘商店商品类型
SHOP_TYPE_ITEM = 1
SHOP_TYPE_FATE = 2

#每日抽奖活动条件类型
#无条件
DAYLUCKY_TYPE_NO = 0
#创号前三天登陆
DAYLUCKY_TYPE_BLOGIN = 1
#创号后三天登陆
DAYLUCKY_TYPE_ALOGIN = 2

#玄铁矿id列表
IRON_IDS = 'iron_ids'
IRON_IDS_V = '(30, 31, 32, 33, 34)'

#服状态表(status)
#兵符极品出现次数(bfBestCount)
STATUS_BF_BEST_COUNT = 'bfBestCount'
#深渊全服数据开始时间(deep_ft, time)
STATUS_DEEP_FT = 'deep_ft'
#配将归队人数上限(含主将)
ROLE_BACK_MAX = 'rolesMax'
ROLE_BACK_MAX_V = 7
#排名数据
STATUS_RANK = 'rank1'        #排名数据键
STATUS_RANK_FT = 'rft'      #排名每日第一次排名时间
STATUS_RANK_DEEP = 'rdeep'  #深渊排名数据
STATUS_RANK_BOSS = 'rboss'  #世界boss排名
#是不是阶段
STATUS_DEBUG_FT = 'debug_time'

#玩家属性表
#玩家状态定义
STATE_NORMAL = 0 #普通
STATE_SIT = 1 #打坐




#任务类型
TT_MAIN = 1
TT_BRANCH = 2
TT_OFFER = 3
TT_HIDE = 4
#任务状态定义
TASK_RUN = 1
TASK_COMPLETE = 2

#任务限制条件类型
TUL_LEVEL = 1
TUL_TASK = 2
TUL_EQUIP = 3
TUL_ITEM = 4
TUL_ROLE = 5

#玩家属性表
PLAYER_ATTR_WIN_FIGHTS = 'winFs'
PLAYER_ATTR_TASKS = 'tks' #已完成任务列表
#时光盒
PLAYER_ATTR_TBOX = 'tbox'
#猎命
PLAYER_ATTR_HITFATE = 'fate'
#兵符
PLAYER_ATTR_BFTASK = 'bf'
#祭天
PLAYER_ATTR_FETE = 'fete'
#打坐
PLAYER_ATTR_SIT = 'sit'
#商店
PLAYER_ATTR_SHOP = 'shop'
#钓鱼
PLAYER_ATTR_FISH = 'fish'
#采矿
PLAYER_ATTR_MINING = 'mine'
#同盟
PLAYER_ATTR_ALLY = 'ally'
#玩家战力
PLAYER_ATTR_CBE = 'CBE'
#在线奖励
PLAYER_ATTR_REWARD = 'rd'
#vip相关
PLAYER_ATTR_VIP = 'vip'
FSPEEDNUM = 'FSpeedNum'
#商店
PLAYER_ATTR_SHOP = 'shop'
#珠宝商店
PLAYER_ATTR_GEM_SHOP = 'gshop'
#珠宝
PLAYER_ATTR_GEM = 'gem'
#同盟boss
PLAYER_ATTR_BOSS = 'boss'
#任务的相关记录
PLAYER_ATTR_TASK = 'task'

#玩家战斗属性标签
FIGHT_ATTR_MP = 'MP' #聚气


#时光盒当天第一次猎怪时间(ft, time)
PT_FT = 'ft'
#时光盒当前章节(ch, int, 0/1)
PT_CH = 'ch'
#时光盒待收物品id
PT_WAITS = 'wids'
#玩家产生免费重置上限的vip等级
PT_VIP = 'vl'
#时光盒 防止猎怪结束多次提交
TBOX_HITE_TIME = 8

#打坐开始时间
SIT_START_TIME = 'st'
#打坐经验积累
SIT_EXP = 'exp'
#保存登出时间(忽略短时间登陆未处理离线打坐经验)
SIT_LOGOUT_TIME = 'lt'

#兵符任务完成次数
TASK_BFTASK_FINISH = 'bffn'
#支线任务完成次数
TASK_ZXTASK_FINISH = 'zxfn'
#隐藏任务完成次数
TASK_YCTASK_FINISH = 'ycfn'



#战报类型
#时光盒
REPORT_TYPE_TBOX = 1
#竞技场
REPORT_TYPE_ARENA = 2
#同盟组队炼妖
REPORT_TYPE_ALLY_TBOX = 3
#竞技场组队战
REPORT_TYPE_ARENA_TEAM = 4

#世界boss高伤害值
REPORT_WBOSS_HURTS = 5

#时光盒url部分定义
REPORT_TBOX_URL = 'tbox'

#boss url部分定义
REPORT_BOSS_URL = 'boss'

#兵符任务
BFTASK_NUM_MAX = 4  #兵符任务最多条数
#兵符任务状态
#可接
BFTASK_CAN_ACCEPT = 1
#已接
BFTASK_ALREADY_ACCEPT = 2
#完成
BFTASK_TYPE_FINISH = 3
#兵符刷新的生成类型
#系统免费
BF_RE_FREE = 1
#系统时间生成
BF_RE_SYS = 2
#元宝刷新
BF_RE_COIN = 3
#4=超过一天的刷新
BF_RE_PASS = 4

#boss战
#同盟战设置时间的间隔字符
ALLY_BOSS_TIME = '-'



#scene key
SCENE_ALLY = 'scene_ally'

#大喇叭类型

#武器升级
HORN_TYPE_ARMUP = 1
#招募
HORN_TYPE_UNROLE = 2
#观星获得绑元宝
HORN_TYPE_HFATE = 3
#兵符宝箱获得极品装备
HORN_TYPE_BFBOX = 4
#装备的强化
HORN_TYPE_EQSTRONG = 5
#钓鱼获得绑元宝
HORN_TYPE_FISH = 6
#竞技场获取第一名
HORN_TYPE_AREA = 7
#时光盒第一次通关
HORN_TYPE_PASS = 8
#时光盒第一次五星通关
HORN_TYPE_MPASS = 9
#世界boss剩余血量广播
HORN_TYPE_WORLDBOSSHP = 10
#世界boss首杀广播
HORN_TYPE_WORLDBOSSFIST = 11
#世界boss结束广播
HORN_TYPE_WORLDBOSSEND = 12
#世界boss失败
HORN_TYPE_WORLDBOSSFAIL = 13
#世界boss开启通知广播
HORN_TYPE_WORLDNOTICE = 14

#15=同盟boss首杀聊天广播
HORN_TYPE_ALLYBOSSFIST = 15
#16=同盟boss广播血量聊天广播
HORN_TYPE_ALLYBOSSHP = 16
#17=同盟boss失败聊天广播
HORN_TYPE_ALLYBOSSFAIL = 17
#18=同盟boss开启通知聊天广播
HORN_TYPE_ALLYNOTICE = 18
#19=同盟boss最后一击聊天广播
HORN_TYPE_ALLYBOSSEND = 19
##20=玩家大喇叭格式
#HORN_TYPE_PLAYER = 20
#-----------------------------------聊天频道消息
#21=系统消息
HORN_TYPE_SYS = 21
#22=系统喇叭
HORN_TYPE_SYS_HORN = 22
#23=个人喇叭
HORN_TYPE_PLAYER_HORN = 23
#24=世界消息
HORN_TYPE_WORLD = 24
#25=同盟消息
HORN_TYPE_ALLY = 25
#26=私聊信息
HORN_TYPE_SECRET = 26

#战斗用属性定义
PROP_STR = 'STR'  #勇力  int
PROP_DEX = 'DEX'  #迅捷  int
PROP_VIT = 'VIT'  #体魄  int
PROP_INT = 'INT'  #智略  int
PROP_HP = 'HP'    #生命  int
PROP_ATK = 'ATK'  #攻击  int
PROP_STK = 'STK'  #绝攻  int
PROP_DEF = 'DEF'  #防御  int
PROP_SPD = 'SPD'  #速度  int
PROP_MP = 'MP'    #聚气  int
PROP_MPS = 'MPS'  #初聚气  int
PROP_MPR = 'MPR'  #回气值  int
PROP_HIT = 'HIT'  #命中率  double
PROP_MIS = 'MIS'  #回避率  double
PROP_BOK = 'BOK'  #格挡率  double
PROP_COT = 'COT'  #反击率  double
PROP_COB = 'COB'  #连击率  double
PROP_CRI = 'CRI'  #爆击率  double
PROP_CPR = 'CPR'  #高爆率  double
PROP_PEN = 'PEN'  #破甲率  double
PROP_TUF = 'TUF'  #免伤率  double

ALL_PROPS = (
    PROP_STR,
    PROP_DEX,
    PROP_VIT,
    PROP_INT,
    PROP_HP,
    PROP_ATK,
    PROP_STK,
    PROP_DEF,
    PROP_SPD,
    PROP_MP,
    PROP_MPS,
    PROP_MPR,
    PROP_HIT,
    PROP_MIS,
    PROP_BOK,
    PROP_COT,
    PROP_COB,
    PROP_CRI,
    PROP_CPR,
    PROP_PEN,
    PROP_TUF
    )

#CEB战斗力计算公式
#"""计算角色战力
#           战斗力 =
#               勇力*0.8 + 迅捷*2 + 体魄*2
#             + 智略*0.7 + 攻击*0.5 + 防御*2
#             + 速度*2 + 生命*0.2 + （命中率—95）*100
#             + 回避率*200 + 格挡率*200 + 反击率*200
#             + 暴击率*50 +爆伤率*50 + 破甲率*50
#             + 免伤率*100 + 连击率*100
#       """
CALC_CBE = 'calc_CBE'
CALC_CBE_V = 'STR:0.8|DEX:2|VIT:2|INT:0.7|' \
             'ATK:0.5|DEF:2|SPD:2|HP:0.2|HIT:1|' \
             'HIT_V:-95|MIS:2|BOK:2|COT:2|COB:1|TUF:1|' \
             'CIR:0.5|CPR:0.5|PEN:0.5'
CBE_FIX_TAG = '_V'

CALC_PROP_ARGS = 'calc_prop_args'
CALC_PROP_ARGS_V = 'STR:ATK:COT|DEX:SPD:COB:MIS|VIT:HP:DEF'
PASS_PROP_ARGS = (PROP_ATK, PROP_COT, PROP_SPD, PROP_COB, PROP_MIS, PROP_HP, PROP_DEF)

DATA_TYPE_KEY = 'display_now'
DATA_TYPE_KEY_V = 'STR:勇力|DEX:迅捷|VIT:体魄|HP:生命|ATK:攻击力|DEF:防御力|SPD:速度|INT:智略|'\
'STK:绝攻|MP:聚气|MPS:初聚气|MPR:回气值|HIT:命中率:0|MIS:回避率:0|COT:反击率:0|CRI:暴击率:0|PEN:破甲率:0|'\
'COB:连击率:0|BOK:格挡率:0|TUF:免伤率:0|CPR:暴伤率:0|hurt_p:伤害:0|addHp:治愈|addHp_p:治愈:0'

#notify
NOTIFY_APNS = 'notify_apns'

#同盟狩龙战类型
#守龙战
ALLY_SKY_WAR = 1
#降龙战
ALLY_WORLD_WAR = 2

#狩龙战结果类型
#通过
ALLY_WAR_WIN = 1
#2=时间用完失败，
ALLY_WAR_FAIL_TIME = 2
#3=天舟耐久度为零失败
ALLY_WAR_FAIL_HARD = 3
#4=系统关闭
ALLY_WAR_FAIL_SYSCLOSE = 4

#耐久度
BOAT_HP = 1
#火力伤害
BOAT_POW = 2
#开炮CD时间
BOAT_CD = 3
#续航时间
BOAT_DELAY = 4
BOAT_LEVEL_TYPES = [BOAT_HP, BOAT_POW, BOAT_CD, BOAT_DELAY]



#狩龙战 评级类型
#1=终极战场胜利
AWAR_TYPE_1 = 1
#2=玩家CD次数
AWAR_TYPE_2 = 2
#3=耗费时间
AWAR_TYPE_3 = 3
#4=狩龙天书使用
AWAR_TYPE_4 = 4
#5=降龙炮使用
AWAR_TYPE_5 = 5
#6=启用天舟续航时间
AWAR_TYPE_6 = 6

DATA_TYPE_KEY = 'display_now'
DATA_TYPE_KEY_V = 'STR:勇力|DEX:迅捷|VIT:体魄|HP:生命|ATK:攻击力|DEF:防御力|SPD:速度|INT:智略|'\
                  'STK:绝攻|MP:聚气|MPS:初聚气|MPR:回气值|HIT:命中率:0|MIS:回避率:0|COT:反击率:0|CRI:暴击率:0|PEN:破甲率:0|'\
                  'COB:连击率:0|BOK:格挡率:0|TUF:免伤率:0|CPR:暴伤率:0|hurt_p:伤害:0|addHp:治愈|addHp_p:治愈:0'


#---------------------
#---------------------
#---------------------
#---------------------
