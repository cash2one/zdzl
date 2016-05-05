//
//  GameDefine.h
//  TXSFGame
//
//  Created by Soul on 13-5-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

//
//------------------------------------------------------------------------------
// 游戏中用的常量的定义
//------------------------------------------------------------------------------
//

#define GAME_VERSION 1
//#define GAME_DEBUGGER________ 0
#define DISPLAYFRAME YES
#define GAME_DEF_CHINESE_FONT @"STHeitiTC-Medium"

// 不再提醒
#define NO_REMIND_FUSION		@"no.remind.fusion"			// 合成弹框
#define NO_REMIND_SACRIFICE		@"no.remind.sacrifice.gold"	// 元宝祭天
#define NO_REMIND_REFRESH_PURPLE	@"no.remind.refresh.purple"	// 悬赏任务一键全紫
#define NO_REMIND_REFRESH_GOLD		@"no.remind.refresh.gold"	// 悬赏任务元宝刷新
#define NO_REMIND_DEEP_AUTO			@"no.remind.deep.auto"	// 深渊挂机
#define NO_ARENA_BUY_OPEN			@"no.arena.buy.open"		// 竞技场，元宝购买
#define NO_REMIND_SHOP_GOLD			@"no.remind.shop.gold"		// 神秘商人，元宝购买
#define NO_REMIND_SHOP_RESET_GOLD	@"no.remind.shop.reset.gold"		// 神秘商人，重设购买

#define NO_REMIDE_BAIT				@"no.remind.bait"	// 购买鱼饵
#define NO_REMIDE_ROLE_CULTIVATE_SYMBOL	@"no.remind.role.cultivate.symbol"	// 购买培养
#define NO_REMIDE_ROLE_UP_SYMBOL	@"no.remind.role.up.symbol"	// 购买升华符
#define NO_REMIDE_GEM_SHOP_GOLD		@"no.remind.gem.shop.gold"	// 元宝购买珠宝
#define NO_REMIDE_GEM_SHOP_UNLOCK	@"no.remind.gem.shop.unlock"	// 解锁珠宝购买选项
#define NO_REMIDE_GEM_SHOP_REFRESH	@"no.remind.gem.shop.refresh"	// 珠宝购买刷新

#define GAME_URL_HOME @"http://bbs.18183.com/forum-zhidianzhenlong-1.html"
#define GAME_URL_HELP @"http://bbs.18183.com/forum-zhidianzhenlong-1.html"
#define GAME_URL_SERVICE @"http://bbs.18183.com/forum-zhidianzhenlong-1.html"
#define GAME_URL_BBS @"http://bbs.18183.com/forum-zhidianzhenlong-1.html"

#define GAME_URL_UPGRADE @"http://zl.52yh.com/action/download.php"

#define GAME_RESOURCE_DAT @"zl"

#define GAME_PROMPT_FONT_SIZE (20)//提示字体大小

#define FONT_SIZE_SCALE   0.5f

#define GAME_MAP_MAX_Y 5000

#define EQUIPMENT_MAX_LEVEL 12

#define GAME_DB_DIR	@"GameData"
#define GAME_DB_Cache_DIR @"_tmp_"
#define GAME_Resources_DIR	@"Resources"

#define Window_debug 1

typedef enum
{
	FONT_1,
	FONT_2,
	FONT_3
}FONT_TYPE;

typedef enum
{
	BUTTON_LABEL_1,
	BUTTON_LABEL_2,
	BUTTON_LABEL_3
}BUTTON_LABEL_TYPE;

typedef enum {
    ICON_PLAYER_BIG = 1,  // 玩家大头像
    ICON_PLAYER_NORMAL,   // 玩家普通头像(四方形)
    ICON_PLAYER_SMALL     // 玩家小头像(圆形)
    // npc...
} ICON_HEAD_TYPE;

typedef enum{
	
	SuccessStatus_none = -1 ,
	SuccessStatus_undone = 0 ,
	SuccessStatus_unget = 1 ,
	SuccessStatus_done = 2 ,
	
}SuccessStatus;

typedef enum{
	
	SuccessType_none = 0 ,
	SuccessType_day = 1 ,
	SuccessType_ever = 2 ,
	
}SuccessType;

typedef enum{
	Activity_Type_main		= 1,
	Activity_Type_general	= 2,
	Activity_Type_recharge	= 3,
	Activity_Type_all		= 4,
}Activity_Type;

typedef enum {
	RoleDir_none		= 0,
	RoleDir_up			= 1,
	RoleDir_up_flat		= 2,
	RoleDir_flat		= 3,
	RoleDir_down_flat	= 4,
	RoleDir_down		= 5,
}RoleDir;

typedef enum {
	RoleAction_stand	= 1,
	RoleAction_runing	= 2,
	RoleAction_siting	= 3,
}RoleAction;

typedef enum {
	Player_state_normal		= 0,//正常
	Player_state_sit		= 1,//打坐
	Player_state_action		= 2,//运龟
	Player_state_fishing	= 3,//运龟
}Player_state;

typedef enum {
	RoleStatus_out = 0,
	RoleStatus_in = 1,
}RoleStatus;

typedef enum {
	JewelStatus_unused = 0,//没使用
	JewelStatus_used = 1,//使用
}JewelStatus;

typedef enum {
	EquipmentStatus_unused = 0,//没使用
	EquipmentStatus_used = 1,//使用
}EquipmentStatus;

typedef enum {
	FateStatus_unused = 0,//没使用
	FateStatus_used = 1,//使用
}FateStatus;

typedef enum {
	TradeStatus_no = 0,//不可交易
	TradeStatus_yes = 1,//可交易
}TradeStatus;

typedef enum {
	DailyMainType_challenge=1,	// 挑战日常
	DailyMainType_union,		// 同盟日常
	DailyMainType_utility,		// 设施日常
	DailyMainType_relaxation,	// 休闲日常
} DailyMainType;

typedef enum {
	// 挑战日常
	DailyType_timeBox	=1,		// 时光盒
	DailyType_fight		=2,		// 竞技场
	DailyType_abyss		=3,		// 无尽深渊
	DailyType_mainFight	=4,		// 首领战
	// 同盟日常
	DailyType_cat		=11,	// 招财猫
	DailyType_engrave	=12,	// 宝具铭刻
	DailyType_teamFight	=13,	// 组队挑战
	DailyType_teamBoss	=14,	// 组队BOSS
	DailyType_fly		=15,	// 烛龙飞天
	DailyType_cometo	=16,	// 魔龙降世
	// 设施日常
	DailyType_mining	=21,	// 玄铁矿洞
	DailyType_star		=22,	// 观星阁
	DailyType_recruit	=23,	// 点将台
	DailyType_strengthen=24,	// 强化装备
	DailyType_shop		=25,	// 商店
	// 休闲日常
	DailyType_fishing	=31,	// 钓鱼
	DailyType_food		=32,	// 食馆
	DailyType_car		=33,	// 坐骑兑换
    DailyType_ctree		=34,	// 摇钱树
} DailyType;

typedef enum {
	RuleType_timeBox	=1,		// 时光盒 ok
	RuleType_fight		=2,		// 竞技场 ok
	RuleType_abyss		=3,		// 无尽深渊 ok
	RuleType_mainFight	=4,		// 首领战 ok
	
	RuleType_cat		=11,	// 招财猫 todo
	RuleType_engrave	=12,	// 宝具铭刻 ok
	RuleType_teamFight	=13,	// 组队挑战 todo
	RuleType_unoinBoss	=14,	// 同盟BOSS ok
	
	RuleType_mining		=21,	// 玄铁矿洞 ok
	RuleType_star		=22,	// 观星阁 ok
	RuleType_recruit	=23,	// 点将台 ok
	RuleType_strengthen	=24,	// 强化装备 ok
	RuleType_shop		=25,	// 商店 ok
	
	RuleType_fishing	=31,	// 钓鱼 ok
	RuleType_food		=32,	// 食馆 todo
	RuleType_car		=33,	// 坐骑兑换 ok
	
	RuleType_sacrifice	=41,	// 祭天 ok
	RuleType_starRoom	=42,	// 观星殿 ok
	RuleType_offerTask	=43,	// 悬赏任务 ok
    RuleType_roleSystem	=44,	// 角色系统 ok
	//RuleType_packSystem	=45,	// 行囊系统 todo
    RuleType_weaponSystem   =46,	// 宝具系统 ok
    RuleType_phalanxSystem   =47,	// 阵型系统 ok
    RuleType_guanxingSystem   =48,	// 观星系统 ok
    RuleType_dailySystem   =49,	// 日常系统 ok
    RuleType_unionSystem   =50,	// 同盟系统 ok
    RuleType_unionMap   =51,	// 同盟地图 ok
    RuleType_ctree   =52,	// 摇钱树 ok
    RuleType_EDLogin   =53,	// 每日抽奖 ok
    RuleType_sign   =54,	// 每日签到 ok
    
    RuleType_jewelMain   =55,	//珠宝主界面（预览界面）ok
    RuleType_jewelSet   =56,	//珠宝镶嵌 ok
    RuleType_jewelMine   =57,	//珠宝开采 ok
    RuleType_jewelPolish   =58,	//珠宝打磨 ok
    RuleType_jewelRefine   =59,	//珠宝提纯 ok
    RuleType_roleCultivate   =60,	//武将培养 ok
    RuleType_roleUp   =61,	//武将升级 ok
    RuleType_dragon_fly   =62,	//烛龙飞空 ok
    RuleType_dragon_cometo   =63,	//魔龙降世 ok
} RuleType;

typedef enum {
    RuleModelType_none	=0,		// 无
    RuleModelType_help,		// 帮助
    RuleModelType_ask,		// 问号
    RuleModelType_string,	// 字符
}RuleModelType;

typedef enum {
	EquipmentPart_head = 1,//头
	EquipmentPart_body, //身
	EquipmentPart_foot, //脚
	EquipmentPart_necklace, //项链
	EquipmentPart_sash, //腰带
	EquipmentPart_ring, //戒子
}EquipmentPart;//装备部位

//typedef enum {
//	EquipmentQuality_1 = 0,//木有品质
//	EquipmentQuality_1,//绿色
//	EquipmentQuality_2,//蓝色
//	EquipmentQuality_3,//红色
//	EquipmentQuality_4,//橙色
//}EquipmentQuality;//装备品质

typedef enum {
	Sociality_none=0,	// 好友
	Sociality_friend=1,	// 好友
	Sociality_online,	// 在线玩家
	Sociality_blacklist,// 黑名单
} SocialityType;

typedef enum{
	
	ItemManager_show_type_all = 0 ,
	ItemManager_show_type_equipment = 1 ,
	ItemManager_show_type_expendable = 2 ,
	ItemManager_show_type_fate = 3 ,
	ItemManager_show_type_fodder = 4 ,
	ItemManager_show_type_jewel = 5 ,
	ItemManager_show_type_stone = 6 ,
	
}ItemManager_show_type;


typedef enum{
	//1=材料、2=用品、3=装备碎片、4=鱼获、5=鱼饵、6=兵符、7=升级礼包
	Item_material = 1, //材料
	Item_expendable = 2, //消耗品
	Item_splinter = 3,//装备碎片，放在装备栏
	Item_fish_item  =4,//鱼获
	Item_fish_food = 5,//鱼饵
	Item_symbol = 6,//兵符
	Item_gift_bag = 7,//升级礼包
	Item_stone = 8,//原石
}Item_type;

typedef enum
{
	PackageItem_all = 1,	// 所有类型
	PackageItem_coin1,		// 银币
	PackageItem_coin2,		// 元宝
	PackageItem_coin3,		// 绑元宝
	PackageItem_exp,		// 经验
	PackageItem_train,		// 炼历
	PackageItem_equip,		// 装备
	PackageItem_item,		// 物品
	PackageItem_fate,		// 命格
	PackageItem_car,		// 坐骑
	PackageItem_role,		// 角色
	PackageItem_wait,		// 待收
	PackageItem_buff,		// buff
	PackageItem_all_excluding_exp,	// 所有类型,不包括经验
	PackageItem_gem,		// 珠宝
}PackageItemType;

typedef enum
{
	PlayerWaitItemType_1 = 1, //猎命
	PlayerWaitItemType_2, //时光盒
	PlayerWaitItemType_3,//渔获
	PlayerWaitItemType_4,//邮件
}PlayerWaitItemType;

typedef enum
{
	IQ_WHITE =0,//白 品质
	IQ_GREEN,//绿 品质
	IQ_BLUE,//蓝 品质
	IQ_PURPLE,//紫 品质
	IQ_ORANGE,//橙 品质
    IQ_RED,// 红 品质
}ItemQuality;

typedef enum {
	Abyss_Target_Type_none		= 0,
	Abyss_Target_Type_monster	= 1,
	Abyss_Target_Type_role		= 2,
	Abyss_Target_Type_boss		= 3,
}Abyss_Target_Type;

//任务解锁类型
typedef enum{
	TaskUnlock_failed = 0 ,
	TaskUnlock_task,
	TaskUnlock_level,
	TaskUnlock_role,
	TaskUnlock_item,
	TaskUnlock_equipment,
	TaskUnlock_success
}TaskUnlock_type;

//==============================================================================
//==============================================================================
typedef enum {
	
	Task_Action_none =  0,
	
	Task_Action_talk		= 1,
	Task_Action_move		= 2,
	Task_Action_moveToNPC	= 3,
	
	Task_Action_addNpc		= 4,
	Task_Action_moveNpc		= 5,
	Task_Action_removeNpc	= 6,
	
	Task_Action_effects		= 7,
	Task_Action_unlock		= 8,
	
	Task_Action_stage		= 9,
	Task_Action_fight		= 10,
	
	Task_Action_fightAction	= 11 ,//定制战斗
	
	Task_Action_openMap	= 12,//修改地图
	Task_Action_openExternalMap	= 13,//开启外传
	
	
	Task_Action_end				=	100,
	Task_Action_waitStart		=	101,
}Task_Action;

typedef enum {
	Task_Type_none = 0,
	Task_Type_main = 1,
	Task_Type_vice = 2,
	Task_Type_offer = 3,
	Task_Type_hide = 4,
}Task_Type;

typedef enum {
	Task_Status_runing = 1,
	Task_Status_complete = 2,
}Task_Status;

typedef enum{
	Mail_type_none		= 0,
	Mail_type_message	= 1, //信息
	Mail_type_reward	= 2, //奖励
	Mail_type_fight		= 3, //战报
}Mail_type;

//==============================================================================
//==============================================================================

typedef enum {
    BT_NONE_TAG = -1,//判断标记符，表示不存在按钮
	BT_CONTROL_TAG1	= 11, //右下角主按钮大范围
	BT_CONTROL_TAG	= 1, //右下角主按钮
	BT_ZAZEN_TAG,//打坐修炼
    BT_JEWEL_TAG,//珠宝
	BT_UNION_TAG,//同盟
	BT_RECRUIT_TAG,//点将
	//fix chao add guan xing
	BT_GUANXING_TAG,//观星
	//fix end
	BT_HAMMER_TAG,//锻造
	BT_PHALANX_TAG,//阵型
	//fix chao add weapon
	BT_WEAPON_TAG,//宝具武器weapon
	//fix end
	BT_PACKAGE_TAG,//背包
    BT_ROLE_TAG,//角色按钮
	/////-----------x---------
	
    BT_SETTING_TAG,//设置
    BT_FRIEND_TAG,//社交
	BT_TIMEBOX_TAG,//时光盒
	BT_ARENA_TAG,//竞技场
    //////---------y-----------
    
    BT_TRADE_TAG,//交易
    
    
	BT_SHOW_MAP_TAG,//展示地图
	BT_TASK_TAG,//任务按钮
	BT_TASK_TRACE_TAG,//任务追踪
	BT_DAILY_TAG,//日常
	BT_ACT_TAG,//活动
	BT_REWARD_TAG,//奖励
    BT_RANK_TAG,//排行榜
	BT_CASH_TAG,//摇钱树
	BT_BACK_WORLD_TAG,//返回游戏世界
	
	BT_CLOSE_WIN_TAG,//关闭按钮
	BT_FALLOUT_TAG,//离队
	BT_OPEN_WEAPON_TAG,//打开界面
	BT_OPEN_FATE_TAG,//打开命格界面
	BT_OPEN_ATTRIBUTE_TAG,//打开属性
	
	BT_HELEMT_TAG,//打开头盔属性
	BT_CUIRASS_TAG,//打开衣服属性
	BT_CALIGA_TAG,//打开鞋属性
	BT_LACE_TAG,//打开项链属性
	BT_SASH_TAG,//打开腰带属性
	BT_RING_TAG,//打开戒子属性
	
	//-----------------------------
	BT_SHIFT_HELEMT_TAG,//替换头
	BT_SHIFT_CUIRASS_TAG,//替换衣服
	BT_SHIFT_CALIGA_TAG,//替换鞋
	BT_SHIFT_LACE_TAG,//替换项
	BT_SHIFT_SASH_TAG,//替换腰带
	BT_SHIFT_RING_TAG,//替换戒子
	//-----------------------------
	
	BT_GET_TRACE_TAG,//取回历练
	BT_ACTIVATE_SKILL1_TAG,//技能符文1
	BT_ACTIVATE_SKILL2_TAG,//技能符文2
	BT_ARM_UPGRADE_TAG,//武器升级
	
	BT_GX_GET_XINGCHEN_TAG,//获得星尘
	BT_GX_ONEKEY_TAG,//一键合成
	BT_GX_HIDE_DEAL_TAG,//隐藏可交易
	BT_GX_NO_HIDE_DEAL_TAG,//不隐藏可交易
	BTT_GX_NO_HIDE_DEAL_TAG,//隐藏可交易复选
	
	BT_GXR_VIP_FREE_GET_TAG,//vip免费获取
	
	BT_GXR_HEIGHT_GET_TAG,//高级获取
	BT_GXR_BAT_HEIGHT_GET_TAG,//批量高级获取
	BT_GXR_RANDOM_GET_TAG,//随机获取
	BT_GXR_BAT_RANDOM_GET_TAG,//批量随机获取
	BT_GXR_RULE_TAG,//观星规则
	BT_GXR_GET_ALL_TAG,//全部拾取
	BT_GXR_LEFT_DIR_TAG,//左方向
	BT_GXR_RIGHT_DIR_TAG,//右方向
	
	BT_IS_SYNTHESIZE_TAG,//合成
	BT_IS_SYNTHESIZE_ALL_TAG,//合部合成
	
	BT_CONFIRM_TAG,//确认按钮
	BT_CANCEL_TAG,//取消按钮
	
	BT_GET_ORE_TAG,//获取矿石
	BT_STRENGTHEN_TAG,//强化
	
	BTT_NO_HIDE_GAMEMUSIC_TAG,//游戏音效复选
	BTT_NO_HIDE_BG_GAMEMUSIC_TAG,//游戏背景音乐复选
	
}MENU_TAG; //按钮的TAG，用于按钮函数回调

typedef enum
{
	//TODO: add more
	PANEL_NONE				= 1 ,
	PANEL_CHARACTER			= 2, //人物属性
	PANEL_PACKAGE			= 3, //背包
	PANEL_ITEMSYNTHESIZE	= 4, //物品合成
	PANEL_TASK				= 5, //任务
    PANEL_PHALANX			= 6, //阵型
	PANEL_WEAPON			= 7, //武器
	PANEL_FATE				= 8, //命格
	PANEL_FATEROOM			= 9, //命格殿
    PANEL_RECRUIT			= 10,//点将
	PANEL_HAMMER			= 11,//锻造
    PANEL_SACRIFICE			= 12,//祭天
    PANEL_UNION				= 13,//同盟
	PANEL_SETTING			= 14,//设置
    PANEL_TIMEBOX			= 15,//时光合
	
	PANEL_MAIL				= 16,//邮件
	PANEL_REWARD			= 17,//奖励
	
	PANEL_FISHING			= 18,//钓鱼
	PANEL_DAILY				= 19,//日常
	PANEL_BUSINESSMAN		= 20,//神秘商人
	
	PANEL_RANK				= 21,//排行榜
	
	PANEL_UNION_Engrave		= 22,//同盟铭刻
	
	PANEL_FISH_Box			= 23,//南蛮宝箱
	
	PANEL_CAR				= 24,//坐骑
	PANEL_ARENA				= 25,//竞技场
	
	PANEL_EXCHANGE			= 26,//购买元宝
	PANEL_ACTIVITY			= 27,//活动
	
	PANEL_RANK_arena		= 28,//排行榜(竞技场)
	PANEL_OTHER_PLAYER_INFO	= 29,//其他角色的装备面板
	PANEL_FRIEND			= 30,//社交
	PANEL_CHAT				= 31,//聊天
	PANEL_UNION_Cat			= 32,//同盟招财猫
	PANEL_SUCCESS_LOG		= 33,//成就日志
	PANEL_UNION_Practice	= 34,//同盟组队炼妖
	
	PANEL_UNION_Practice_Team = 35,
	PANEL_CASHCOW			= 36,//摇钱树
	PANEL_TEAM_ARENA		= 37,//组队竞技场
	PANEL_EXCHANGE_ACTIVITY	= 38,//首充窗口
    //
	
	PANEL_JEWEL				= 39,//成就珠宝
	PANEL_JEWEL_set			= 40,//珠宝镶嵌
	PANEL_JEWEL_mine		= 41,//珠宝开采
	PANEL_JEWEL_polish		= 42,//珠宝打磨
	PANEL_JEWEL_refine		= 43,//珠宝提炼
	PANEL_JEWEL_buy			= 44,//珠宝购买(暂时没用到)
	
	PANEL_ROLE_CULTIVATE	= 45,//角色培养
	PANEL_ROLE_UP	= 46,//角色升级
    PANEL_CHAT_BIG			= 47,//聊天
    PANEL_NOTICE			= 48,//公告
    PANEL_UNION_Dragon_Donate		= 49,//同盟狩龙捐晶
    PANEL_UNION_Dragon_Exchange		= 50,//同盟狩龙兑换
	PANEL_UNION_Dragon_Union_Rank		= 51,//狩龙同盟排行
    PANEL_UNION_Dragon_World_Rank		= 52,//狩龙全服排行
    PANEL_UNION_Dragon_World_Map		= 53,//狩龙战战图
    WINDOW_type_end,//这里是必须是最后一个，由于各种判断
	
}WINDOW_TYPE; //用于Window中显示不同的界面

typedef enum {
	EffectsAction_none		= 0, //没有效果ID
	EffectsAction_loshing	= 1, //晃动
	EffectsAction_twinkle	= 2, // 闪屏
	EffectsAction_zoomIn	= 3, // 放大屏幕
	EffectsAction_zoomOut	= 4, // 缩少屏幕
	EffectsAction_scrollMsg	= 5, // 滚动字体 全屏黑屏,中间滚动other文本
	EffectsAction_sceeenMsg	= 6, // 屏幕信息  全屏黑屏,中间提示other文本
	EffectsAction_loading	= 7, // 读条 屏幕中间提示进度,显示过度other文本
	EffectsAction_showUI	= 8, // 显示游戏的UI
	EffectsAction_hideUI	= 9, // 隐藏游戏的UI
	EffectsAction_chapter	= 10, //提示章节
	EffectsAction_whiteScreen	= 11, //白屏
	EffectsAction_joinPartner = 12,//角色加入
	EffectsAction_showNpcEffect = 13,//播放npc动画
	EffectsAction_showPlayerEffect = 14,//播放角色动画
	EffectsAction_loshingDirect	= 15, //晃动（不关闭弹出框）
	EffectsAction_Inbetweening	= 16, //插画
}EffectsAction;

typedef enum{
	MONSTER_TYPE_MONSTER = 1 ,
	MONSTER_TYPE_BOSS = 2 ,
}MONSTER_TYPE; //用于Window中显示不同的界面

//攻击模式
typedef enum{
	Attack_mode_target_single		= 1, //单个
	
	Attack_mode_target_upright		= 11, //目标及后面
	Attack_mode_target_later		= 12, //目标及身后一竖
	Attack_mode_target_surrounding	= 13, //目标及周围
	Attack_mode_target_sector		= 14, //目标及扇形
	Attack_mode_target_aboutRank	= 15, //目标及左右两列
	
	Attack_mode_across				= 21,//一横
	Attack_mode_Attack_mode_full	= 22,//敌全体
}Attack_mode;

typedef enum{
	Fight_member_type_role			= 1,
	Fight_member_type_monster		= 2,
	Fight_member_type_boss			= 3,
	Fight_member_type_player		= 4,
	Fight_member_type_npc			= 5,
	Fight_member_type_single_role	= 6,
}Fight_member_type;

typedef enum{
	Fight_team_icon_type_role = 1,
	Fight_team_icon_type_momster = 2,
	Fight_team_icon_type_npc = 3,
}Fight_team_icon_type;

//状态类型
typedef enum{
	Fight_Status_Type_general	= 1, //一般加成类型 (标准BA加成与伤害加成,结束时会扣回)
	Fight_Status_Type_harm		= 2, //伤害类型(中毒等按触发类型扣目标的上一次伤害的bhp%)
	Fight_Status_Type_cure		= 3, //治疗类型(按对主目标伤害的ahp%添加自己或队友的HP)
	Fight_Status_Type_add		= 4, //加数类型(直加mp或HP,不会扣)
}Fight_Status_Type;

//状态执行类型
typedef enum{
	Fight_Action_Type_atonce	= 0,
	Fight_Action_Type_attack	= 1,
	Fight_Action_Type_gethurt	= 2,
	Fight_Action_Type_endround	= 3,
}Fight_Action_Type;

//战斗行为类型
typedef enum{
	Fight_Action_Log_Type_hp	= 1,
	Fight_Action_Log_Type_power	= 2,
	Fight_Action_Log_Type_die	= 3,
	
	Fight_Action_Log_Type_ready_skill	= 4,
	Fight_Action_Log_Type_remove_skill	= 5,
	
	Fight_Action_Log_Type_move = 11,
	Fight_Action_Log_Type_back = 12,
	
	Fight_Action_Log_Type_atk = 21,
	Fight_Action_Log_Type_skl = 22,
	
	Fight_Action_Log_Type_add = 51,
	Fight_Action_Log_Type_bok = 52,
	Fight_Action_Log_Type_cob = 53,
	Fight_Action_Log_Type_cot = 54,
	Fight_Action_Log_Type_cpr = 55,
	Fight_Action_Log_Type_mis = 56,
	Fight_Action_Log_Type_pen = 57,
	
	Fight_Action_Log_Type_addStatus		= 31,
	Fight_Action_Log_Type_updateStatus	= 32,
	Fight_Action_Log_Type_removeStatus	= 33,
	
	Fight_Action_Log_Type_effect_single = 41,
	Fight_Action_Log_Type_effect_all = 42,
	
	Fight_Action_Log_Type_delay = 70,
	//Fight_Action_Log_Type_Talk	= 71,
	
	Fight_Action_Log_Type_round = 98,
	Fight_Action_Log_Type_end = 99,
	
}Fight_Action_Log_Type;


typedef enum{
	ROLE_ACTION_TYPE_none = 0,
	ROLE_ACTION_TYPE_swap = 1,
	ROLE_ACTION_TYPE_convert = 2,
}ROLE_ACTION_TYPE;


typedef enum{
	Equipment_action_none = 0,
	Equipment_action_swap = 1,
	Equipment_action_convert = 2,
}EQUIPMENT_ACTION_TYPE;


//战斗方向
typedef enum{
	FightAnimation_DIR_U = 1,
	FightAnimation_DIR_D = 2,
}FightAnimation_DIR;

//战斗BUFF类型
typedef enum{
	Fight_Buff_Type_none		= 0,//没有Buff
	Fight_Buff_Type_abyss		= 1,//深渊Buff
	Fight_Buff_Type_foot		= 2,//食馆Buff
	Fight_Buff_Type_worldBoss	= 3,//首领战Buff
	//TOOD other buff type
}Fight_Buff_Type;

typedef enum{
	Buff_Type_foot	= 1,	//食馆Buff
	Buff_Type_vip	= 2,	//vip Buff
}Buff_Type;

typedef enum {
	ROLE_STATUS_NONE = 0,		// 
    ROLE_STATUS_RECRUIT,		// 招募
    ROLE_STATUS_AGAIN,          // 重新招募
    ROLE_STATUS_OWN,            // 已拥有
    ROLE_STATUS_CANT_OWN,       // 不能拥有
	ROLE_STATUS_GET,			// 获取帅印
} ROLE_STATUS;


static NSString *attribute_map[]={
	/*
	 @"STR|勇力",
	 @"DEX|迅捷",
	 @"VIT|体魄",
	 @"INT|智略",
	 //
	 @"HP|生命",
	 @"MP|聚气",
	 @"ATK|攻击",
	 @"STK|绝攻",
	 //
	 @"DEF|防御",
	 @"SPD|速度",
	 @"MPS|初聚气",
	 @"MPR|回气值",
	 //
	 @"HIT|命中率|",
	 @"MIS|回避率|",
	 @"BOK|格挡率|",
	 @"COT|反击率|",
	 @"CRI|暴击率|",
	 @"CPR|爆伤率|",
	 @"PEN|破甲率|",
	 @"TUF|免伤率|",
	 @"COB|连击率|",//21---------装备到这
	 //
	 @"hurt_p|伤害率|",//22
	 @"addHp|恢复量",//23
	 @"addHp_p|治愈率|",//24
	 */
    @"config_attribute_str",
    @"config_attribute_dex",
    @"config_attribute_vit",
    @"config_attribute_int",
    @"config_attribute_hp",
    @"config_attribute_mp",
    @"config_attribute_atk",
    @"config_attribute_stk",
    @"config_attribute_def",
    @"config_attribute_spd",
    @"config_attribute_mps",
    @"config_attribute_mpr",
    @"config_attribute_hit",
    @"config_attribute_mis",
    @"config_attribute_bok",
    @"config_attribute_cot",
    @"config_attribute_cri",
    @"config_attribute_cpr",
    @"config_attribute_pen",
    @"config_attribute_tuf",
    @"config_attribute_cob",
    @"config_attribute_hurt_p",
    @"config_attribute_addHp",
    @"config_attribute_addHp_p",
};

/*
static NSString *property_map[]={
    
//	 @"STR|勇力",
//	 @"DEX|迅捷",
//	 @"VIT|体魄",
//	 @"INT|智略",
//	 //
//	 @"HP|生命",
//	 @"MP|聚气",
//	 @"ATK|攻击",
//	 @"STK|绝攻",
//	 //
//	 @"DEF|防御",
//	 @"SPD|速度|",
//	 @"MPS|初聚气",
//	 @"MPR|回气值",
//	 //
//	 @"HIT|命中率|",
//	 @"MIS|回避率|",
//	 @"BOK|格挡率|",
//	 @"COT|反击率|",
//	 @"CRI|暴击率|",
//	 @"CPR|爆伤率|",
//	 @"PEN|破甲率|",
//	 @"TUF|免伤率|",
//	 @"COB|连击率|",//21---------装备到这
//	 //
//	 @"hurt_p|伤害率|",//22
//	 @"addHp|恢复量",//23
//	 @"addHp_p|治愈率|",//24
 
    @"config_property_str",
    @"config_property_dex",
    @"config_property_vit",
    @"config_property_int",
    @"config_property_hp",
    @"config_property_mp",
    @"config_property_atk",
    @"config_property_stk",
    @"config_property_def",
    @"config_property_spd",
    @"config_property_mps",
    @"config_property_mpr",
    @"config_property_hit",
    @"config_property_mis",
    @"config_property_bok",
    @"config_property_cot",
    @"config_property_cri",
    @"config_property_cpr",
    @"config_property_pen",
    @"config_property_tuf",
    @"config_property_cob",
    @"config_property_hurt_p",
    @"config_property_addHp",
    @"config_property_addHp_p",
};
*/

/*
static NSString *quality_str[]={
	@"ffffff",
	@"00ff00",
	@"0000ff",
	@"b469ab",
	@"f7941d",
	@"ff0000"
};*/


typedef enum{
	Unlock_phalanx = 1, //阵型
	Unlock_recruit = 2,//点将
	Unlock_hammer = 3,//锻造
	Unlock_food = 4,//食馆
	Unlock_monger = 5,//商人
	Unlock_weapon = 6,//武器
	Unlock_star = 7 ,//观星
	Unlock_timebox = 8 ,//时光盒
	Unlock_friend = 9 ,//社交
	Unlock_fish = 10,//钓鱼
	Unlock_daily = 11,//日常
	Unlock_union = 12,//同盟
	Unlock_zazen = 13,//修炼
	Unlock_mine =14,//采矿
	Unlock_boss =15,//世界BOSS
	Unlock_vice=16,//支线任务
	Unlock_offer=17,//悬赏任务
	Unlock_hide=18,//隐藏任务
	Unlock_partner=19,//同伴
	Unlock_abyss = 20 ,//深渊
	Unlock_arena = 21 ,//竞技场
}Unlock_object;//解锁类型

typedef enum{
	ItemTray_none = 0  ,
	ItemTray_armor = 1 ,
	ItemTray_fate = 2  ,
	ItemTray_item = 3  ,
	ItemTray_item_armor = 4  ,
	ItemTray_item_gift = 5  ,
	ItemTray_item_jewel = 6  ,
	ItemTray_item_stone = 7 ,// 原石
}ItemTray_type;

typedef enum {
	DataHelper_player	= 0 ,	// 角色面板相关
	DataHelper_jewel	= 1 ,	// 珠宝面板相关
} DataHelper_type;

struct BaseAttribute {
	float STR; //勇力
	float INT; //智略
	float VIT; //体魄
	float DEX; //迅捷
	
	float HP;  //生命
	float MP;  //聚气
	float ATK; //攻击
	float STK; //绝攻
	
	float DEF; //防御
	float SPD; //速度
	float MPS; //初聚气
	float MPT; //回气值
	
	float HIT; //命中率
	float MIS; //回避率
	float BOK; //挡格率
	float COT; //反击率
	float CRI; //爆击率 命中
	float CPR; //爆伤率 倍率
	float PEN; //破甲率 命中 +1/3
	float TUF; //免伤率
	float COB; //连击率
	
	float CBE; //战斗力
	float FAE; //命格力
};
typedef struct BaseAttribute BaseAttribute;

typedef enum{
	SystemStatusStep_none = 0 ,
	SystemStatusStep_waitting = 1 ,
	SystemStatusStep_running = 2 ,
	SystemStatusStep_end = 3 ,
}SystemStatusStep;

typedef enum{
	GameUi_SpecialSystem_start_enum = 880 ,
	GameUi_SpecialSystem_worldBoss,
	GameUi_SpecialSystem_unionBoss,
	GameUi_SpecialSystem_timebox,
	GameUi_SpecialSystem_fishing,
	GameUi_SpecialSystem_mining,
	GameUi_SpecialSystem_unionManager,
	GameUi_SpecialSystem_abyssManager,
	GameUi_SpecialSystem_dragonReady,
	GameUi_SpecialSystem_dragonFight,
	GameUi_SpecialSystem_end_enum,
}GameUi_SpecialSystem;

struct BossData {
	int bossId;
	int bossLevel;
	int bossHP;
	int bossTotalHP;
};
typedef struct BossData BossData;

struct CombatCool{
	int		_remain;
	int		_total;
};
typedef struct CombatCool CombatCool;

struct SystemStatusInfo {
	BOOL	isCheckStart;
	BOOL	isCheckStop;
	BOOL	isCheckCooling;
	
	int		startTime;
	int		stopTime;
	CombatCool combatCool;
};
typedef struct SystemStatusInfo SystemStatusInfo;

typedef enum
{
	CHANNEL_ALL			=0,
	CHANNEL_WORLD		=1,
	CHANNEL_TUBA		=3,
	CHANNEL_UNION		=4,
	CHANNEL_PRIVATE		=5,
	CHANNEL_SYSTEM		=6,
}Channel_type;

typedef enum
{
	GoodType_none = 0 ,
	GoodType_item = 1 ,
	GoodType_fate = 2 ,
}GoodType;

typedef enum {
	DragonType_none		= 0,	// 无
	DragonType_fly		= 1,	// 烛龙飞天
	DragonType_cometo	= 2,	// 魔龙降世
} DragonType;

typedef enum {
	DragonTime_ready,	// 准备
	DragonTime_fight,	// 战斗
} DragonTime;


