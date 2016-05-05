//
//  DragonDefine.h
//  TXSFGame
//
//  Created by efun on 13-9-14.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#ifndef TXSFGame_DragonDefine_h
#define TXSFGame_DragonDefine_h

typedef enum {
	DragonResult_none		= 0,
	DragonResult_win		= 1,	// 通关
	DragonResult_lose_time	= 2,	// 失败（时间到）
	DragonResult_lose_boat	= 3,	// 失败（天舟被摧毁）
	DragonResult_gm_exit	= 4,	// gm指令退出
} DragonResultType;

#define ConnPost_Dragon_local_cd_add				@"ConnPost_Dragon_local_cd_add"
#define ConnPost_Dragon_local_cd_remove				@"ConnPost_Dragon_local_cd_remove"
#define ConnPost_Dragon_local_cd_update				@"ConnPost_Dragon_local_cd_update"

#define ConnPost_Dragon_local_cd_add_after			@"ConnPost_Dragon_local_cd_add_after"
#define ConnPost_Dragon_local_cd_remove_after		@"ConnPost_Dragon_local_cd_remove_after"

#define ConnPost_Dragon_local_countdown				@"ConnPost_Dragon_local_countdown"
#define ConnPost_Dragon_local_cd_countdown			@"ConnPost_Dragon_local_cd_countdown"
#define ConnPost_Dragon_local_playerCount			@"ConnPost_Dragon_local_playerCount"
#define ConnPost_Dragon_local_captainName			@"ConnPost_Dragon_local_captainName"
#define ConnPost_Dragon_local_glory					@"ConnPost_Dragon_local_glory"// 同盟建设点有改变

#define ConnPost_Dragon_local_fight_cannonCount		@"ConnPost_Dragon_local_fight_cannonCount"
#define ConnPost_Dragon_local_fight_fire			@"ConnPost_Dragon_local_fight_fire"
#define ConnPost_Dragon_local_fight_fire_remove		@"ConnPost_Dragon_local_fight_fire_remove"// 去除打炮状态
#define ConnPost_Dragon_local_fight_boss			@"ConnPost_Dragon_local_fight_boss"// boss击打天舟

#define ConnPost_Dragon_local_player_fight_start	@"ConnPost_Dragon_local_player_fight_start"
#define ConnPost_Dragon_local_player_fight_end		@"ConnPost_Dragon_local_player_fight_end"
#define ConnPost_Dragon_local_monster_fight_start	@"ConnPost_Dragon_local_monster_fight_start"
#define ConnPost_Dragon_local_monster_fight_end		@"ConnPost_Dragon_local_monster_fight_end"
#define ConnPost_Dragon_local_monster_add			@"ConnPost_Dragon_local_monster_add"
#define ConnPost_Dragon_local_monster_remove		@"ConnPost_Dragon_local_monster_remove"

#define ConnPost_Dragon_local_bossHp				@"ConnPost_Dragon_local_bossHp"
#define ConnPost_Dragon_local_boatHard				@"ConnPost_Dragon_local_boatHard"
#define ConnPost_Dragon_local_desc					@"ConnPost_Dragon_local_desc"

#define ConnPost_Dragon_local_worldMap				@"ConnPost_Dragon_local_worldMap"
#define ConnPost_Dragon_local_warChoose				@"ConnPost_Dragon_local_warChoose"

#define ConnPost_Dragon_local_isCanMove				@"ConnPost_Dragon_local_isCanMove"
#define ConnPost_Dragon_local_box					@"ConnPost_Dragon_local_box"// 扔宝箱
#define ConnPost_Dragon_local_did_openbox			@"ConnPost_Dragon_local_did_openbox"// 打开了箱子

#define ConnPost_Dragon_local_result_win			@"ConnPost_Dragon_local_result_win"
#define ConnPost_Dragon_local_result_doWin			@"ConnPost_Dragon_local_result_doWin"// 执行doWin
#define ConnPost_Dragon_local_result_lose_time		@"ConnPost_Dragon_local_result_lose_time"
#define ConnPost_Dragon_local_result_lose_boat		@"ConnPost_Dragon_local_result_lose_boat"
#define ConnPost_Dragon_local_result_gm_exit		@"ConnPost_Dragon_local_result_gm_exit"

#define ConnPost_Dragon_local_exit					@"ConnPost_Dragon_local_exit"// 直接退出，比如评价或掉宝箱回调s=0

// 回调
#define ConnPost_Dragon_local_callback_useBook		@"ConnPost_Dragon_local_callback_useBook"

#endif
