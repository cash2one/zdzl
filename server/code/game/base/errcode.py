#!/usr/bin/env python
# -*- coding:utf-8 -*-

#通用错误编码 1~ 20
EC_VALUE = 1            #数值错误
EC_TIME_UNDUE = 2       #时间未到
EC_TIMEOUT = 3          #超时
EC_NOLEVEL = 4          #等级未到
EC_NOVIP = 5            #不是vip用户
EC_COST_ERR = 6         #扣费失败
EC_NO_RIGHT = 7         #无此权限
EC_HANDLED = 8          #操作已处理
EC_PLAYER_EMPTY = 9     #该玩家已经不存在
EC_NAME_REPEAT = 10     #重名
EC_NOFOUND = 11         #找不到
EC_PAY_FAIL = 12        #支付失败
EC_USER_MAX = 13        #达到最大玩家数
EC_NORES = 14           #无资源
EC_TIMES_FULL = 15      #使用次数已到达上限
EC_CLOSE = 16           #功能未开放
EC_PLAYER_OFFLINE = 17  #玩家不在线
EC_NET_ERR = 18         #网络连接错误
EC_LOGIN_ERR = 19       #登陆错误
EC_FORBID_STRING = 20   #敏感词

#背包 21~30
EC_BAG_FULL = 21        #背包满了
EC_BAG_NO = 22          #物品不在背包

#物品 31~50
EC_ITEM_NOFOUND = 31   #找不到该物品
EC_EQUIP_NOUSE = 32     #物品不可使用
EC_FATE_NOFOUND = 36    #找不到
EC_FATE_MAX = 37        #已经升级到最高级
EC_FATE_NOMERGE = 38    #无合成

#配将 51~55
EC_ROLE_NOFOUND = 51    #找不到配将
EC_ROLE_MAIN_REP = 52   #主将重复
EC_ROLE_WEAR_REP = 53   #重复穿戴
EC_ROLE_PART_USED = 54  #该部位被占用
EC_ROLE_WEARED = 55     #已被别的配将使用

#玩家56~79
#阵型
EC_POS_NOFOUND = 61     #找不到阵型
#深渊错误编码
EC_DEEP_HAVE_GUARD = 62 #没有守卫
EC_DEEP_NO_AUTO = 63 #今日已使用过挂机
EC_DEEP_BOSS_NO_AUTO = 64 #boss层不能挂机
EC_DEEP_OVER_DAY = 65 #挂机时间不能超过当日

#禁止
EC_FORBID_CHAT = 66     #禁言
EC_FORBID_LOGON = 67    #禁止登录
EC_TRAIN_ENOUGH = 68       #玩家历练不足


#同盟80~100
EC_NO_ALLY = 80       #没有该同盟
EC_PLAYER_OWN = 81    #玩家已经有同盟
EC_PLAYER_NO = 82     #玩家没有同盟
EC_DUTY_FULL = 83     #该职位已满
EC_MAIN_QUIT_ERR = 84 #盟主不能退出帮会除非解散
EC_ALLY_EXIT = 85     #该同盟已经存在
EC_APPLY_EXIT = 86     #玩家已经在申请列表中
EC_CAT_FULL = 87      #招财猫的次数已满
EC_QUIT_TIME_ERR = 88 #入会一定时间无法退会
EC_MEMBER_FULL = 89     #该同盟的人数已经满了
EC_BOSS_OVER = 90     #本周同盟boss战已打过
EC_CRYSTAL_NO = 91     #龙晶不足
EC_GLORY_NO = 92     #同盟建设点不足

#兵符 100~120
EC_BFTASK_NOCOIN = 101      #兵符任务还拥有免费刷新次数不能进行元宝刷新
EC_BFTASK_NOFREE =102       #兵符无免费刷新次数
EC_BFTASK_NOLEVEL =103      #当前等级无兵符任务
EC_BFTASK_EXPENOUGH =104    #当前经验未达到开启宝箱
EC_BFTASK_ACCEPTED = 105    #已接兵符任务
EC_BFTASK_NOFOUND = 106     #当前无兵符任务
EC_BFTASK_FINISH = 107      #该兵符任务已完成
EC_BFTASK_NOBOX = 108       #兵符任务宝箱已全部开启

#时光盒 120~140
EC_TBOX_WAITITEM = 120      #u'待收物品未收取'
EC_TBOX_NORESET = 121       #u'无重置次数'
EC_TBOX_NOCHAPTER = 122     #u'该章节没有开通'
EC_TBOX_KILL_NOCOND = 123   #u'秒杀条件不足'
EC_TBOX_KILL_NOMONSTER = 124 #无怪物秒杀
EC_TBOX_NORANK = 125        #无排名


#boss战 140~160
EC_BOSS_NOALLY = 141        #玩家不在同盟中
EC_BOSS_NOSTART = 142       #boss战还未开启
EC_BOSS_CD = 143            #玩家正处于cd时间
EC_BOSS_FINISH = 144        #boss战已结束
EC_BOSS_NO_CD = 145         #不在cd状态
EC_BOSS_NOJOIN = 146        #本周已参加过同盟boss战
EC_BOSS_NOTIME = 147        #不能设置为过去的时间
EC_BOSS_MAXBUFF = 148       #buff已经达到上线

#在线奖励 160~170
REWARDONLINE_OVER = 161     #在线奖励当日已经领完

#钓鱼 170～180
FISH_NOT_ENOUGH = 171       #鱼铒数目不足
FISH_STATE_NPC = 172        #NPC委托钓鱼中不可垂钓
FISH_CANT_ENTRUST = 173     #钓鱼状态中不可委托NPC
FISH_UP_ERR = 174           #无垂钓不能起杆
FISH_NO_MORE = 175          #无法进行多次垂钓
FISH_ITEM_ERR = 176         #非鱼饵

#武器 装备  181~200
EC_ARMLEVEL_MAX = 181         #武器等级达到极限
EC_ARMNO_SKILL = 182          #武器无该技能
EC_ARMSKILLLEVEL_ENOUGH = 183 #武器未达到练历收取等级
EC_EQUIP_NOFOUND = 184        #装备未找到
EC_EQUIPPART_DIF = 185        #装备的部位不同

#打坐 201~210
EC_SIT_STARTE = 201           #玩家属性不为空
EC_SIT_NOSIT = 202            #玩家没有打坐
EC_SIT_NOLEVEL = 203          #玩家等级未达到打坐功能

#祭天 211~220
EC_FETEHIT_MAX = 211          #祭天次数达到上限

#命格 221~230
EC_FATEHIT_MAX = 221          #猎命次数达到上限
EC_EXP_FATE = 222             #经验命格不可以穿
EC_MERGE_EXPS = 223           #都为经验命格不能合并
#社交 230~240
EC_SOCIAL_FRIEND_IN = 231      #已经在朋友列表中
EC_SOCIAL_BLACK_IN = 232       #已经在黑名单列表中
EC_SOCIAL_FRIEND_DEL_ERR = 233 #删除的玩家不在朋友列表中
EC_SOCIAL_BLACK_DEL_ERR = 234  #删除的玩家不在黑名单中
EC_SOCIAL_MAX_ERR = 235        #玩家好友数量已达上线
EC_SOCIAL_FIGHT_ERR = 236      #不能和自己决战


#兑换码奖励 240~250
EC_CODE_EXCHANGE_PASS = 241    #兑换码过期
EC_CODE_EXCHANGE_NOMORE = 242  #兑换码不能领多次
EC_CODE_EXCHANGE_INVALID = 243 #无效的兑换码


#坐骑 251~270
EC_CAR_NOT_EXCHANGE = 251       #不可交易的坐骑
EC_CAR_ENOUGH = 252             #兑换的材料不够
EC_CAR_NOFIND = 253             #用户无此坐骑

#采矿 260~265
EC_MINING1_BATCH_ERR = 261      #批量的次数大于免费采矿次数无法批量
EC_MINING1_FREE_ERR = 262       #免费采矿次数已用完

#神秘商店   265~270
EC_SHOP_RESET_NUM_ERR = 266     #商店重置次数已用完

#聊天模块 271～280
EC_CHATTYPE_ERR = 271           #聊天类型错误

#组队模块 281~310
EC_TEAM_SAME_POS = 297           #站位重复
EC_TEAM_CAN_NOT_NEW = 298        #今天已经不能创建队伍
EC_TEAM_NOT_IN_TEAM = 299        #尚未加入这个队伍
EC_TEAM_NO_RIVAL = 300           #未找到匹配的队伍
EC_TEAM_TYPE_ERR = 301           #队伍类型错误
EC_TEAM_NOT_FIND = 302           #队伍不存在
EC_TEAM_IS_FIGHT = 303           #队伍正在战斗
EC_TEAM_ROLE_FULL = 304          #人数已满
EC_TEAM_SAME_NEW = 305           #已经加入了一个同类型的队伍
EC_TEAM_ERR_NAME = 306           #队伍名称已存在
EC_TEAM_ERR_REQUEST = 307        #你已经在申请列表中
EC_TEAM_NO_POWER = 308           #权限不足
EC_TEAM_NO_REQUEST = 309         #玩家未在申请列表中
EC_TEAM_ERR_STATE = 310          #队伍不是出战状态

#战斗相关 311~350
EC_FIGHT_WIN = 311 #主线战斗胜利

#成就相关 351~380
EC_ACHI_REWARD =  351

#珠宝相关 381~400
EC_GEM_NOT_FIND = 381  #无效的装备或珠宝
EC_GEM_INDEX_USED = 382 #该位置已经镶嵌了珠宝
EC_GEM_ERR_PART = 383 #无效的镶嵌部位
EC_GEM_ERR_INDEX = 384 #无效的镶嵌位置
EC_GEM_SAME_TYPE = 385 #已镶嵌同类型珠宝
EC_GEM_MAX_LEVEL = 386 #已达最高等级

EC_GEM_NOT_SID = 390 #无效的珠宝商店物品
EC_GEM_SHOP_IS_MAX = 391 #已达上限


#每日抽奖 401~410
EC_DAYLUCKY_NONUM = 401     #家抽奖次数已使用完

# 摇钱树 411-420
EC_CTREE_LOW_LEVEL = 411     # 等级不够
EC_CTREE_NOT_ENOUGH_COINS = 412  # 真元宝不够
EC_CTREE_QUOTA_USE_UP = 413  # 对换次数已用完
EC_CTREE_OPER_FAIL = 414     # 本次操作内部错误
#登陆错误 420-430
EC_LOGIN_AREA_ERR = 421      #不在允许区域范围中
EC_LOGIN_DEBUG_TIME = 422    #游戏在测试阶段


#武将升段 431-440
EC_ROLEUP_ERR_NUM = 431     #该武将已无次数
EC_ROLEUP_MAX = 432         #该武将已达到满段
EC_ROLETRAIN_NO = 433       #该武将未经过培养
EC_ROLETRAIN_UNLOCK = 434   #主角30级后方可使用

#排名 441-450
EC_RANK_NO = 441            #暂无排名

#同盟狩龙战 451--470
EC_ALLY_WAR_ENTERED = 451   #玩家已进入此房间
EC_ALLY_WAR_ROOMMAX = 452   #房间已满
EC_ALLY_WAR_NOROOM = 453    #该角色未加入房间
EC_ALLY_WAR_CD = 454        #处于cd时间
EC_ALLY_WAR_NOBOOK = 455    #玩家无天书
EC_ALLY_WAR_FIRED = 456     #此炮已被申请
EC_ALLY_WAR_MDIE = 457      #该怪物不存在
EC_ALLY_WAR_IN = 458        #该玩家未参与战斗
EC_ALLY_WAR_NOTEAMER = 459  #该玩家不是队长
EC_ALLY_WAR_NOCOPY = 460    #该节点无影分身
EC_ALLY_ACTIVIY_END = 461       #活动已结束
EC_ALLY_WAR_ROOMED = 462    #该房间已过期
EC_ALLY_WAR_ING = 463       #战斗中
EC_ALLY_WAR_NOCHANGE = 464  #无兑换次数
EC_ALLY_WAR_NOGLORY = 465   #建设点不足
EC_ALLY_WAR_OUTTIME = 466   #操作已超时
EC_ALLY_WAR_FULLBAG = 467   #背包已满，奖励以邮件形式发送
EC_ALLY_WAR_WINED = 468     #已取得胜利
EC_ALLY_WAR_HARDMAX = 469   #天舟耐久度已达到最大值
EC_ALLY_LEVEL_LOW = 470     #同盟等级不够
EC_ALLY_WAR_END = 471       #该场战斗已结束
