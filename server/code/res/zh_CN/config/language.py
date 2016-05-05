#!/usr/bin/env python
# -*- coding:utf-8 -*-

#通用
VALUE_ERROR = u'数值错误'
COST_COIN_ERR = u'扣除费用失败'
TIME_UNDUE = u'时间未到'
PLAYER_NOLEVEL = u'等级未达到'
PLAYER_NOVIP = u'玩家vip未达到'

#登录
STR_LOGON_ERROR = u'登陆错误'
STR_LOGON_NAME_DU = u'角色名重复'
STR_LOGON_NOINIT = u'未初始化'
STR_LOGON_NEW_ERR = u'新建错误'


STR_PLAYER_1 = u'用户名不能为空。'
STR_PLAYER_2 = u'用户重复登录:%s'
STR_PLAYER_3 = u'达到最大用户数'
STR_PLAYER_4 = u'登录key不正确'
STR_PLAYER_5 = u'未收到登录key或登录key过期'
STR_PLAYER_6 = u'角色不存在'
STR_PLAYER_7 = u'禁止角色登录'
STR_PLAYER_8 = u'角色初始化失败'

#资源
RES_NOFOUND = u'找不到资源'

#玩家
PLAY_TRAIN_ENOUGH = u'玩家练历不足'

#物品
ITEM_NOFOUND = u'找不到物品'
ITEM_NOUSE = u'物品不可以使用'
ITEM_COST_ERR = u'消耗物品失败'
ITEM_USE_ERR = u'使用错误物品'

#奖励
REWARD_NOFOUND = u'奖励数据错误'

#背包
BAG_NOENOUGH = u'背包空间不足'
BAG_COST_ERR = u'花费物品失败'


#配将
ROLE_NOFOUND = u'找不到配将'
ROLE_INVITE_ERR = u'配将招募失败'
ROLE_USE_ERR = u'花费物品招募配将失败'
ROLE_MAIN_REP = u'主将重复'

#命格
FATE_NOFOUND = u'找不到命格'
FATE_REPEAT = u'命格影响属性叠加'
FATE_PART_USED = u'该部位已有命格'
FATE_LEVEL_MAX = u'命格已达到最高等级，合并失败'
FATE_NOMERGE = u'命格无合成'
FATE_HIT_MAX = u'猎命次数达到上限'
FATE_HIT_ERR = u'猎命失败'
FATE_HIT_VIP = u'vip等级不到'

#装备
EQUIP_NOFOUND = u'找不到装备'
EQUIP_NOUSED = u'装备未使用'
EQUIP_STR_ERR = u'装备强化失败'
EQUIP_NOPART = u'无此部位'
EQUIP_PART_DIF = u'装备的部位不同'
#武器
ARM_NORES_ARMLEVEL = u'无武器升级资源表'
ARM_LEVEL_MAX = u'武器等级达到极限'
ARM_NO_SKILL = u'武器无该技能'
ARM_SKILLLEVEL_ENOUGH = u'武器未达到练历收取等级'

#祭天
FETE_HIT_MAX = u'祭天次数达到上限'


#阵型
POS_NOFOUND = u'找不到阵型'

#任务
#兵符任务
BFTASK_NOFOUND = u'当前无兵符任务'
BFTASK_NO_LEVEL = u'当前等级无兵符任务'
BFTASK_EXP_ENOUGH = u'当前经验未达到开启宝箱'
BFTASK_ACCEPTED = u'已接兵符任务'
BFTASK_NOFREE = u'兵符无免费刷新次数'
BFTASK_FINISH = u'该兵符任务已完成'

#钓鱼
FISH_NPC_TITLE = u'委托NPC钓鱼'
FISH_NPC_CONTENT = u'委托NPC收获'

#食馆
FOOD_UNDUE = u'时间未到'


#时光盒
TBOX_WAIT_ITEM = u'待收物品未收取'
TBOX_NORESET = u'无重置次数'
TBOX_NOCHAPTER = u'该章节没有开通'
TBOX_KILL_NOCOND = u'秒杀条件不足'
TBOX_KILL_NOMONSTER = u'无怪物秒杀'
TBOX_NORANK = u'无排名'

#采矿
MINING_NO_RIGHT = u"无批量挖矿权限"
MINING_NO_COIN1 = u"金钱不够"
MINING_NO_COIN2 = u"元宝不够"

#深渊
DEEP_ET_GUARD_ERR = u'亲,请先清了护卫才能进门'
DEEP_AUTO_TITLE = u'深渊'
DEEP_AUTO_CONTENT = u'尊敬的%(name)s玩家，通过本次深渊，您获得了下列物品。'

#打坐
SIT_STARTE = u'玩家属性不为空'
SIT_NOSIT = u'玩家没有打坐'
SIT_NOLEVEL = u'玩家等级未达到打坐功能'

#同盟
ALLY_APPLY_TITLE = u'入盟申请'
ALLY_APPLY_CONTENT = u'你成功加入了%(name)s'
ALLY_DISMISS_TITLE = u'解散同盟'
ALLY_DISMISS_CONTENT = u'%(name)s解散了同盟'
ALLY_TICK_TITLE = u'踢出同盟'
ALLY_TICK_CONTENT = u'你被%(n1)s的盟主%(n2)s踢出了同盟'
ALLY_CHANGE_POST = u'%(name)s更改了公告'
ALLY_BOSS_TIME_CHANGE = u'%s(name)s更改了BOSS时间'
ALLY_JOIN_CONTENT = u'%(name)s#ff0000|加入了同盟'
ALLY_CHANGE_DUTY = u'%(n1)s将%(n2)s的职位改为%(duty)s'
ALLY_TICK_OUT = u'%(n1)s将%(n2)s踢出了同盟'
ALLY_EXIT = u'%(name)s退出了同盟'
ALLY_APPLY_REFUSE = u"你申请加入%(name)s同盟被拒绝了"
ALLY_MAIN_NEW = u'%(name)s成为新盟主'

#boss战
ALLY_BOSS_REWARD = u"同盟boss奖励"
#在线奖励
REWARD_ONLIEN_TITLE = u'角色登录奖励'
REWARD_ONLIEN_CONTENT = u'登录次数达到，获得该奖励'
REWARD_ONLIEN_NEXT = u'背包空间不足，奖励下次登录再发送'

#竞技场
ARENA_START = u'竞技场开启!'
ARENA_RW_TITLE = u'竞技场排名奖励'

#大喇叭 广播中文
HORN_MAIN_ROLE = u'自己'
HORN_BFBOX_FATE = u'星力!'


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
