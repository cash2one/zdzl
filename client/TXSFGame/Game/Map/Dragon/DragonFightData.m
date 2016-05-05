//
//  DragonFightData.m
//  TXSFGame
//
//  Created by efun on 13-9-7.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonFightData.h"
#import "GameConnection.h"
#import "ShowItem.h"
#import "DragonFightManager.h"
#import "DragonReadyManager.h"
#import "RoleManager.h"
#import "DragonReadyData.h"
#import "DragonWorldMap.h"
#import "GameConfigure.h"
#import "DragonScore.h"
#import "TaskTalk.h"
#import "GameLoading.h"

static int s_SelectMonsterId = 0;		// 选择的怪物的ancid

static BOOL isWaitNet		= NO;
static BOOL isAddEvent		= NO;
static BOOL isBookRequest	= NO;	// 天书

static NSDictionary		*s_DragonFightDict = nil;	// 数据
static DragonFightData	*s_DragonFightData = nil;	// 类实例

@implementation DragonFightData

@synthesize resultType;
@synthesize isCanMove;
@synthesize isFinalOver;
@synthesize isShowStartTitle;
@synthesize isShowResultTitle;
@synthesize shadowData;
@synthesize continueTime;
@synthesize installTime;
@synthesize boatHard;
@synthesize boatTotalHard;
@synthesize cannon;
@synthesize cannonUseData;

@synthesize cdTime;
@synthesize glory;
@synthesize booksData;
@synthesize booksCD;
@synthesize booksExchange;

@synthesize bossHp;
@synthesize bossTotalHp;
@synthesize aliveNpcs;
@synthesize currentFightData;

@synthesize captainName;
@synthesize startInfo;
@synthesize playerCount;
@synthesize playerMaxCount;
@synthesize normalTime;
@synthesize ascId;

@synthesize mapId;
@synthesize isCanHitBoss;
@synthesize dragonType;

+(DragonFightData*)shared
{
	if (s_DragonFightData == nil) {
		s_DragonFightData = [[DragonFightData alloc] init];
	}
	return s_DragonFightData;
}

+(void)startAll
{
	[DragonFightData addEvent];
}

+(void)stopAll
{
	[DragonFightData remove];
	[DragonFightData removeEvent];
}

+(void)remove
{
	if (s_DragonFightData) {
		[s_DragonFightData removeFightTimer];
		[s_DragonFightData removeCannonTimer];
		[s_DragonFightData removeBookTimer];
		[s_DragonFightData removeCDTimer];
		
		[s_DragonFightData release];
		s_DragonFightData = nil;
	}
	if (s_DragonFightDict) {
		[s_DragonFightDict release];
		s_DragonFightDict = nil;
	}
}

+(void)addEvent
{
	if (isAddEvent) return;
	isAddEvent = YES;
	
	// 进出房间
	[GameConnection addPost:ConnPost_Dragon_enterRoom target:[DragonFightData class] call:@selector(playerPassRoom:)];
	[GameConnection addPost:ConnPost_Dragon_exitRoom target:[DragonFightData class] call:@selector(playerPassRoom:)];
	
	// 开战广播
	[GameConnection addPost:ConnPost_Dragon_startFight target:[DragonFightData class] call:@selector(beginWithData:)];
	
	// 击杀怪物开始结束
	[GameConnection addPost:ConnPost_Dragon_killMonsterStart target:[DragonFightData class] call:@selector(killMonster:)];
	[GameConnection addPost:ConnPost_Dragon_killMonsterEnd target:[DragonFightData class] call:@selector(killMonster:)];
	
	// 打炮
	[GameConnection addPost:ConnPost_Dragon_fire target:[DragonFightData class] call:@selector(fire:)];
	
	// boss血量
	[GameConnection addPost:ConnPost_Dragon_bossHp target:[DragonFightData class] call:@selector(bossHp:)];
	
	// 耐久度
	[GameConnection addPost:ConnPost_Dragon_hard target:[DragonFightData class] call:@selector(boatHard:)];
	
	// 势力地图广播
	[GameConnection addPost:ConnPost_Dragon_worldMap target:[DragonFightData class] call:@selector(worldMap:)];
	
	// 选择路线
	[GameConnection addPost:ConnPost_Dragon_warChoose target:[DragonFightData class] call:@selector(warChoose:)];
	
	// 狩龙结果
	[GameConnection addPost:ConnPost_Dragon_result target:[DragonFightData class] call:@selector(result:)];
}

+(void)removeEvent
{
	isAddEvent = NO;
	
	[GameConnection removePostTarget:[DragonFightData class]];
}

+(BOOL)checkIsFight
{
	return (s_DragonFightData != nil);
}

+(BOOL)checkIsCaptain
{
	NSString *captainName = nil;
	if ([DragonReadyData checkIsReady]) {
		captainName = [DragonReadyData shared].captainName;
	} else if ([DragonFightData checkIsFight]) {
		captainName = [DragonFightData shared].captainName;
	}
	
	if (captainName == nil) {
		return NO;
	}
	
	NSString *playerName = [[GameConfigure shared] getPlayerName];
	return [playerName isEqualToString:captainName];
}

+(BOOL)checkIsCD
{
	if (![DragonFightData checkIsFight]) return NO;
	
	return ([DragonFightData shared].cdTime > 0);
}

+(BOOL)checkExistCannon
{
	if (![DragonFightData checkIsFight]) return NO;
	
	return ([DragonFightData shared].cannon > 0);
}

+(BOOL)checkIsBoatHarm
{
	if (![DragonFightData checkIsFight]) return NO;
	
	int boatTotalHp = [DragonFightData shared].boatTotalHard;
	if (boatTotalHp <= 0) return NO;
	
	int boatHp = [DragonFightData shared].boatHard;
	return (boatHp < boatTotalHp);
}

+(BOOL)checkCanNet
{
	return (isWaitNet == NO);
}

+(void)setCanNet:(BOOL)_isCanNet
{
	isWaitNet = !_isCanNet;
}

+(BOOL)checkCanBookRequest
{
	return (isBookRequest == NO);
}

+(void)setCanBookRequest:(BOOL)_isCan
{
	isBookRequest = !_isCan;
}

+(BOOL)checkIsWin
{
	if (![DragonFightData checkIsFight]) return NO;
	
	return ([DragonFightData shared].resultType == DragonResult_win);
}

+(BOOL)checkIsLose
{
	if (![DragonFightData checkIsFight]) return NO;
	
	return ([DragonFightData shared].resultType == DragonResult_lose_time ||
			[DragonFightData shared].resultType == DragonResult_lose_boat ||
			[DragonFightData shared].resultType == DragonResult_gm_exit);
}

+(BOOL)checkIsOver
{
	return ([DragonFightData checkIsWin] || [DragonFightData checkIsLose]);
}

+(BOOL)checkIsFinalOver
{
	if (![DragonFightData checkIsFight]) return YES;
	return [DragonFightData shared].isFinalOver;
}

+(BOOL)checkIsShowStartTitle
{
	if (![DragonFightData checkIsFight]) return YES;
	return [DragonFightData shared].isShowStartTitle;
}

+(BOOL)checkIsShowResultTitle
{
	if (![DragonFightData checkIsFight]) return YES;
	return [DragonFightData shared].isShowResultTitle;
}

+(int)getSelectMonsterId
{
	return s_SelectMonsterId;
}

+(void)setSelectMonsterId:(int)monsterId
{
	s_SelectMonsterId = monsterId;
}

#pragma mark-
#pragma mark 广播

+(void)beginWithData:(NSNotification*)notification
{
	NSDictionary *_data = notification.object;
	if (_data == nil) return;
	
	if (s_DragonFightData != nil && s_DragonFightDict != nil) {
		int apcId = [[s_DragonFightDict objectForKey:@"apcid"] intValue];
		int newApcid = [[_data objectForKey:@"apcid"] intValue];
		
		// 屏蔽同一场重复发的数据
		if (apcId == newApcid) {
			return;
		}
	}
	
	[DragonFightManager removeDragonFight];
	
	s_DragonFightDict = [NSDictionary dictionaryWithDictionary:_data];
	[s_DragonFightDict retain];
	
	[[DragonFightData shared] enter];
}

// 玩家进出房间
+(void)playerPassRoom:(NSNotification*)notification
{
	if (![DragonFightData checkIsFight]) return;
	
	NSDictionary *data = notification.object;
	
	if ([notification.name isEqualToString:ConnPost_Dragon_enterRoom]) {
		
		[DragonFightData shared].playerCount = [[data objectForKey:@"pnum"] intValue];
		
		[GameConnection post:ConnPost_Dragon_local_playerCount object:nil];
		
	}
	else if ([notification.name isEqualToString:ConnPost_Dragon_exitRoom]) {
		
		if ([data objectForKey:@"tname"]) {
			[DragonFightData shared].captainName = [data objectForKey:@"tname"];
		}
		
		[DragonFightData shared].playerCount = [[data objectForKey:@"pnum"] intValue];
		
		[GameConnection post:ConnPost_Dragon_local_playerCount object:nil];
		[GameConnection post:ConnPost_Dragon_local_captainName object:nil];
	}
}

+(void)killMonster:(NSNotification*)notification
{
	if (![DragonFightData checkIsFight]) return;
	
	NSDictionary *data = notification.object;
	
	if ([notification.name isEqualToString:ConnPost_Dragon_killMonsterStart]) {
		NSArray *allKeys = [data allKeys];
        
        NSString *finalKey = nil;
        NSString *finalValue = nil;
		for (NSString *key in allKeys) {
			NSString *value = [NSString stringWithFormat:@"%@", [data objectForKey:key]];
            
            if ([key isEqualToString:@"pid"]) {
                finalKey = value;
            } else if ([key isEqualToString:@"ancid"]) {
                finalValue = value;
            }
        }
		
        [[DragonFightData shared].currentFightData setObject:finalValue forKey:finalKey];
        
        [GameConnection post:ConnPost_Dragon_local_player_fight_start object:finalKey];
        [GameConnection post:ConnPost_Dragon_local_monster_fight_start object:finalValue];
        
	}
	else if ([notification.name isEqualToString:ConnPost_Dragon_killMonsterEnd]) {
		int playerId = [[data objectForKey:@"pid"] intValue];
		int ancid = [[data objectForKey:@"ancid"] intValue];
		int isWin = [[data objectForKey:@"isWin"] intValue];
		
		NSString *key = [NSString stringWithFormat:@"%d", playerId];
		[[DragonFightData shared].currentFightData removeObjectForKey:key];
		
		[GameConnection post:ConnPost_Dragon_local_player_fight_end object:[NSNumber numberWithInt:playerId]];
		if (isWin == 1) {
			for (NSString *value in [DragonFightData shared].aliveNpcs) {
				if (ancid == [value intValue]) {
					[[DragonFightData shared].aliveNpcs removeObject:value];
					break;
				}
			}
			
			[GameConnection post:ConnPost_Dragon_local_monster_remove object:[NSNumber numberWithInt:ancid]];
		} else {
			// 自己输了，并且狩龙战还没胜利，cd状态
			if (playerId == [[GameConfigure shared] getPlayerId] &&
				![DragonFightData checkIsWin]) {
				
				[GameConnection post:ConnPost_Dragon_local_cd_add object:nil];
				[GameConnection post:ConnPost_Dragon_local_cd_add_after object:nil];
			}
			[GameConnection post:ConnPost_Dragon_local_monster_fight_end object:[NSNumber numberWithInt:ancid]];
		}
		
		if ([data objectForKey:@"npcids"]) {
			
			[DragonFightData shared].aliveNpcs = [data objectForKey:@"npcids"];
			
			for (NSString *idString in [DragonFightData shared].aliveNpcs) {
				[GameConnection post:ConnPost_Dragon_local_monster_add object:idString];
			}
			
			[[DragonFightData shared].currentFightData removeAllObjects];	
		}
	}
}

+(void)fire:(NSNotification*)notification
{
	if (![DragonFightData checkIsFight]) return;
	
	NSDictionary *data = notification.object;
	
	int playerId = [[data objectForKey:@"pid"] intValue];
	int index = [[data objectForKey:@"index"] intValue];
	
	int time = [DragonFightData shared].installTime;
	
	NSString *key = [NSString stringWithFormat:@"%d", index];
	NSArray *value = [NSArray arrayWithObjects:
					  [NSNumber numberWithInt:playerId],
					  [NSNumber numberWithInt:time],
					  nil];
	[[DragonFightData shared].cannonUseData setObject:value forKey:key];
	if ([[DragonFightData shared] checkSomebodyFire]) {
		[[DragonFightData shared] startCannonCountdown];
	}
	[GameConnection post:ConnPost_Dragon_local_fight_fire object:[NSNumber numberWithInt:index]];
	
	// 更新是否可移动
	[[DragonFightData shared] updateCanMoveStatus];
	
	int cannon = [[data objectForKey:@"cannon"] intValue];
	[DragonFightData shared].cannon = cannon;
	[GameConnection post:ConnPost_Dragon_local_fight_cannonCount object:nil];
}

+(void)bossHp:(NSNotification*)notification
{
	if (![DragonFightData checkIsFight]) return;
	
	NSDictionary *data = notification.object;
	
	int _bossHp = [[data objectForKey:@"hp"] intValue];
	_bossHp = MAX(_bossHp, 0);
	[DragonFightData shared].bossHp = _bossHp;
	
	[GameConnection post:ConnPost_Dragon_local_bossHp object:nil];
	
	if ([data objectForKey:@"desc"]) {
		NSString *desc = [data objectForKey:@"desc"];
		
		[GameConnection post:ConnPost_Dragon_local_desc object:desc];
	}
}

+(void)boatHard:(NSNotification*)notification
{
	if (![DragonFightData checkIsFight]) return;
	
	NSDictionary *data = notification.object;
	
	int _boatHard = [[data objectForKey:@"hard"] intValue];
	[DragonFightData shared].boatHard = MAX(_boatHard, 0);
	
	if ([data objectForKey:@"mhard"]) {
		[DragonFightData shared].boatTotalHard = [[data objectForKey:@"mhard"] intValue];
	}
	
	if ([data objectForKey:@"type"]) {
		int type = [[data objectForKey:@"type"] intValue];
		// 2为boss击打
		if (type == 2) {
			[GameConnection post:ConnPost_Dragon_local_fight_boss object:nil];
		}
	}
	
	if ([data objectForKey:@"desc"]) {
		NSString *desc = [data objectForKey:@"desc"];
		[GameConnection post:ConnPost_Dragon_local_desc object:desc];
	}
	
	[GameConnection post:ConnPost_Dragon_local_boatHard object:nil];
}

+(void)worldMap:(NSNotification*)notification
{
	NSDictionary *data = notification.object;
	
	if ([DragonReadyData checkIsReady] || [DragonFightData checkIsFight]) {
		// 选择地图前先去掉弹框
		[[AlertManager shared] remove];
		
		[DragonWorldMap showMapWithSender:data];
	}
}

+(void)warChoose:(NSNotification*)notification
{
	if (![DragonReadyData checkIsReady] && ![DragonFightData checkIsFight]) return;
	
	NSDictionary *data = notification.object;
	[GameConnection post:ConnPost_Dragon_local_warChoose object:data];
}

+(void)result:(NSNotification*)notification
{
	if (![DragonFightData checkIsFight]) return;
	
	NSDictionary *data = notification.object;
	DragonResultType resultType = [[data objectForKey:@"type"] intValue];
	[DragonFightData shared].resultType = resultType;
	
	// 狩龙结束
	if ([DragonFightData checkIsOver]) {
		
		// 结束，删除战斗时间
		[[DragonFightData shared] removeFightTimer];
		
		// 移除所有打炮状态
		[[DragonFightData shared] removeCannonCountdown];
		[GameConnection post:ConnPost_Dragon_local_fight_fire_remove object:nil];
		
		[DragonFightData shared].isCanMove = YES;
		[GameConnection post:ConnPost_Dragon_local_isCanMove object:nil];
		
	}
	// 赢了
	if ([DragonFightData checkIsWin]) {
		
		[[DragonFightData shared] removeAllNpc];
		[GameConnection post:ConnPost_Dragon_local_result_win object:nil];
		
	}
	// 输了
	else if ([DragonFightData checkIsLose]) {
		
		if ([DragonFightData shared].resultType == DragonResult_lose_time) {
			[GameConnection post:ConnPost_Dragon_local_result_lose_time object:nil];
		} else if ([DragonFightData shared].resultType == DragonResult_lose_boat) {
			[GameConnection post:ConnPost_Dragon_local_result_lose_boat object:nil];
		} else if ([DragonFightData shared].resultType == DragonResult_gm_exit) {
			[DragonFightData shared].isFinalOver = YES;
			[GameConnection post:ConnPost_Dragon_local_result_gm_exit object:nil];
		}
		
	}
}

#pragma mark -
#pragma mark 请求回调

+(void)didUseBook:(id)sender arg:(id)arg
{
	if (![DragonFightData checkIsFight]) {
		isBookRequest = NO;
		return;
	}
	
	if (checkResponseStatus(sender)) {
		
		// 减少天书数量
		int bookId = [[arg objectForKey:@"bookId"] intValue];
		if ([[DragonFightData shared] checkUseNormalBook:bookId]) {
			[[DragonFightData shared] useNormalBook:bookId];
		} else if ([[DragonFightData shared] checkUseExchangeBook:bookId]) {
			[[DragonFightData shared] useExchangeBook:bookId];
		}
		
		// 添加cd时间
		NSString *key = [NSString stringWithFormat:@"%d", bookId];
		int bookCd = [[arg objectForKey:@"bookCd"] intValue];
		[[DragonFightData shared].booksCD setObject:[NSNumber numberWithInt:bookCd] forKey:key];
		if ([[DragonFightData shared] checkBookCD]) {
			[[DragonFightData shared] startBookCountdown];
		}
		
		// 移除玩家cd
		BOOL isRemoveCd = [[arg objectForKey:@"removeCd"] boolValue];
		if (isRemoveCd) {
			[GameConnection post:ConnPost_Dragon_local_cd_remove object:nil];
			[GameConnection post:ConnPost_Dragon_local_cd_remove_after object:nil];
		}
		
		NSString *bookDesc = [arg objectForKey:@"bookDesc"];
		if (bookDesc != nil) {
			[GameConnection post:ConnPost_Dragon_local_desc object:bookDesc];
		}
		
		// 同盟建设值改变
		NSDictionary *dict = getResponseData(sender);
		if (dict != nil) {
			
			if ([dict objectForKey:@"glory"]) {
				
				int glory = [[dict objectForKey:@"glory"] intValue];
				[DragonFightData shared].glory = glory;
				
				[GameConnection post:ConnPost_Dragon_local_glory object:nil];
			}
			
		}
		
		// 使用天书成功后
		[GameConnection post:ConnPost_Dragon_local_callback_useBook object:arg];
		
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
	isBookRequest = NO;
}

+(void)doFightEnd
{
	int win = [[FightManager shared] isWin] ? 1 : 0;
	int selectMonsterId = [DragonFightData getSelectMonsterId];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:selectMonsterId] forKey:@"ancid"];
	[dict setObject:[NSNumber numberWithInt:win] forKey:@"isWin"];
	
	// TODO
	// 假设输了
//	[dict setObject:[NSNumber numberWithInt:0] forKey:@"isWin"];
	
	if ( 0 == win ) {
        int npc_id = selectMonsterId;
        NSDictionary *dict_ = [[GameDB shared] getAwarNpcConfig:selectMonsterId];
        if (dict_) {
            NSDictionary *f_dict_ = [[GameDB shared] getFightInfo:[[dict_ objectForKey:@"fid"] intValue]];
            if (f_dict_) {
                npc_id = [[f_dict_ objectForKey:@"icon"] intValue];
            }
        }
        int	_value = [[FightManager shared] getTargetDamage:npc_id];//当前的伤害
        [dict setObject:[NSNumber numberWithInt:_value] forKey:@"hurts"];
    }
	
	[GameConnection request:@"awarMosterEnd" data:dict target:[DragonFightData class] call:@selector(didFightEnd:)];
}

+(void)didFightEnd:(id)sender
{
    if( [FightManager isFighting] || [TaskTalk isTalking] || [GameLoading isShowing] ){
        //TODO chao
        NSMutableDictionary *m_dict = [NSMutableDictionary dictionary];
        [m_dict setObject:sender forKey:@"sender"];
        //
        if (checkResponseStatus(sender)) {
            NSDictionary *dict = getResponseData(sender);
            if (dict) {
                // 显示更新的物品
                NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict];
                [m_dict setObject:updateData forKey:@"updateData"];
                // 更新的物品
                [[GameConfigure shared] updatePackage:dict];
            }
        }
        [[DragonFightManager shared] addResponse:m_dict];
		return;
	}
    //
	if (checkResponseStatus(sender)) {
		
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			
			// 显示更新的物品
			NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict];
			[[AlertManager shared] showReceiveItemWithArray:updateData];
			
			[[GameConfigure shared] updatePackage:dict];
			
		}
		
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
}

+(void)didAssess:(id)sender
{
	if (![DragonFightData checkIsFight]) return;
	
	if (checkResponseStatus(sender)) {
		
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			// 弹出评价界面
			[DragonScore showScoreWithSender:dict];
		}
		
	} else {
		[GameConnection post:ConnPost_Dragon_local_exit object:nil];
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
}

+(void)didGetBox:(id)sender
{
	if (checkResponseStatus(sender)) {
		
		NSDictionary *dict = getResponseData(sender);
		if (dict) {
			
			// 显示更新的物品
			NSArray *updateData = [[GameConfigure shared] getPackageAddData:dict];
			[[AlertManager shared] showReceiveItemWithArray:updateData];
			
			[[GameConfigure shared] updatePackage:dict];
			
			[GameConnection post:ConnPost_Dragon_local_did_openbox object:nil];
			
		}
		
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
	
	if (![DragonFightData checkIsFinalOver]) {
		[GameConnection post:ConnPost_Dragon_local_exit object:nil];
	}
	
	if ([DragonFightData checkIsFight]) {
		[DragonFightData shared].isFinalOver = YES;
	}
}

#pragma mark -

-(id)init
{
	if (self = [super init]) {
		isCanMove = YES;
		isFinalOver = NO;
		isShowStartTitle = NO;
		isShowResultTitle = NO;
		isWaitNet = NO;
		isBookRequest = NO;
		resultType = DragonResult_none;
		
		[self releaseAll];
		
		NSDictionary *_data = s_DragonFightDict;
		
		shadowData = [NSArray arrayWithArray:[_data objectForKey:@"copys"]];
		[shadowData retain];
		continueTime = [[_data objectForKey:@"gtime"] intValue];
		installTime = [[_data objectForKey:@"ctime"] intValue];
		boatHard = [[_data objectForKey:@"hard"] intValue];
		boatTotalHard = [[_data objectForKey:@"mhard"] intValue];
		cannon = [[_data objectForKey:@"cannon"] intValue];
		cannonUseData = [NSMutableDictionary dictionaryWithDictionary:[_data objectForKey:@"connon2data"]];
		[cannonUseData retain];
		
		cdTime = [[_data objectForKey:@"cdtime"] intValue];
		glory = [[_data objectForKey:@"glory"] intValue];
		booksData = [NSMutableDictionary dictionaryWithDictionary:[_data objectForKey:@"books"]];
		[booksData retain];
		booksCD = [NSMutableDictionary dictionaryWithDictionary:[_data objectForKey:@"cdbooks"]];
		[booksCD retain];
		booksExchange = [NSMutableDictionary dictionaryWithDictionary:[_data objectForKey:@"exbooks"]];
		[booksExchange retain];
		
		bossHp = [[_data objectForKey:@"boss_hp"] intValue];
		bossTotalHp = [[_data objectForKey:@"mboss_hp"] intValue];
		aliveNpcs = [NSMutableArray arrayWithArray:[_data objectForKey:@"npcids"]];
		[aliveNpcs retain];
		currentFightData = [NSMutableDictionary dictionaryWithDictionary:[_data objectForKey:@"pid2npcid"]];
		[currentFightData retain];
		
		captainName = [NSString stringWithFormat:@"%@", [_data objectForKey:@"tname"]];
		[captainName retain];
		playerCount = [[_data objectForKey:@"pnum"] intValue];
		playerMaxCount = [[_data objectForKey:@"mpnum"] intValue];
		normalTime = [[_data objectForKey:@"ltime"] intValue];
		ascId = [[_data objectForKey:@"asid"] intValue];
		
		// 战斗开炮
		NSArray *cannonAllkeys = [cannonUseData allKeys];
		for (NSString *key in cannonAllkeys) {
			[GameConnection post:ConnPost_Dragon_local_fight_fire object:key];
		}
		
		// 战斗表id
		int apcId = [[_data objectForKey:@"apcid"] intValue];
		NSDictionary *dict = [[GameDB shared] getAwarPerConfig:apcId];
		if (dict != nil) {
			
			mapId = [[dict objectForKey:@"mapid"] intValue];
			isCanHitBoss = ([[dict objectForKey:@"kboss"] intValue] == 1);
			dragonType = [[dict objectForKey:@"type"] intValue];
			maxCDTime = [[dict objectForKey:@"cdtime"] intValue];
			
			startInfo = [NSString stringWithFormat:@"%@", [dict objectForKey:@"infor"]];
			[startInfo retain];
		}
		
		// 更新是否可移动
		[self updateCanMoveStatus];
		
		// 战斗倒计时
		[self startFightCountdown];
		
		// 炮弹装载倒计时
		if ([self checkSomebodyFire]) {
			[self startCannonCountdown];
		}
		
		// 天书cd倒计时
		if ([self checkBookCD]) {
			[self startBookCountdown];
		}
		
		// 玩家死亡cd
		if ([self checkCD]) {
			[self startCDCountdown];
		}
		
		[GameConnection addPost:ConnPost_Dragon_local_cd_add target:self call:@selector(addCD)];
		[GameConnection addPost:ConnPost_Dragon_local_cd_remove target:self call:@selector(removeCD)];
	}
	return self;
}

-(void)dealloc
{
	[GameConnection removePostTarget:self];
	
	isCanMove = YES;
	isWaitNet = NO;
	isBookRequest = NO;
	
	[self releaseAll];
	[self removeFightTimer];
	[self removeCannonTimer];
	[self removeBookTimer];
	[self removeCDTimer];
	
	[super dealloc];
}

-(void)releaseAll
{
	if (shadowData != nil) {
		[shadowData release];
		shadowData = nil;
	}
	if (cannonUseData != nil) {
		[cannonUseData release];
		cannonUseData = nil;
	}
	if (booksData != nil) {
		[booksData release];
		booksData = nil;
	}
	if (booksCD != nil) {
		[booksCD release];
		booksCD = nil;
	}
	if (booksExchange != nil) {
		[booksExchange release];
		booksExchange = nil;
	}
	if (aliveNpcs != nil) {
		[aliveNpcs release];
		aliveNpcs = nil;
	}
	if (currentFightData != nil) {
		[currentFightData release];
		currentFightData = nil;
	}
	if (captainName != nil) {
		[captainName release];
		captainName = nil;
	}
	if (startInfo != nil) {
		[startInfo release];
		startInfo = nil;
	}
}

-(void)setCaptainName:(NSString *)__captainName
{
	if (captainName != nil) {
		[captainName release];
		captainName = nil;
	}
	captainName = [NSString stringWithFormat:@"%@", __captainName];
	[captainName retain];
}

-(void)setAliveNpcs:(NSMutableArray *)__aliveNpcs
{
	if (aliveNpcs != nil) {
		[aliveNpcs release];
		aliveNpcs = nil;
	}
	aliveNpcs = [NSMutableArray arrayWithArray:__aliveNpcs];
	[aliveNpcs retain];
}

-(void)enter
{
	// 删除狩龙准备数据
	[DragonReadyManager removeDragonReady];
	[[RoleManager shared] otherPlayerVisible:YES];
	
	// 进入狩龙战斗地图
	[DragonFightManager enterDragonFight];
	
	[GameConnection post:ConnPost_Dragon_local_countdown object:nil];
}

#pragma mark -

-(void)updateCanMoveStatus
{
	int currentPlayerId = [[GameConfigure shared] getPlayerId];
	
	NSArray *allKeys = [cannonUseData allKeys];
	for (NSString *key in allKeys) {
		NSArray *value = [cannonUseData objectForKey:key];
		if (value.count >= 2) {
			
			int playerId = [[value objectAtIndex:0] intValue];
			if (playerId == currentPlayerId) {
				// 先停止当前玩家移动
				[[RoleManager shared] stopMovePlayer];
				
				isCanMove = NO;
				[GameConnection post:ConnPost_Dragon_local_isCanMove object:nil];
				return;
			}
			
		}
	}
	isCanMove = YES;
	[GameConnection post:ConnPost_Dragon_local_isCanMove object:nil];
}

#pragma mark -
#pragma mark 倒计时，CD相关

-(void)addCD
{
	cdTime = maxCDTime;
	[self startCDCountdown];
	
	[GameConnection post:ConnPost_Dragon_local_cd_update object:nil];
}

-(void)removeCD
{
	[self removeCDTimer];
	[GameConnection post:ConnPost_Dragon_local_cd_update object:nil];
}

-(void)removeCannonCountdown
{
	[cannonUseData removeAllObjects];
	[self removeCannonTimer];
}

-(void)removeAllNpc
{
	for (NSString *value in [DragonFightData shared].aliveNpcs) {
		int ancid = [value intValue];
		[GameConnection post:ConnPost_Dragon_local_monster_remove object:[NSNumber numberWithInt:ancid]];
	}
	
	[[DragonFightData shared].aliveNpcs removeAllObjects];
}

-(void)removeFightTimer
{
	if (fightTimer != nil) {
		[fightTimer invalidate];
		fightTimer = nil;
	}
}

-(void)removeCannonTimer
{
	if (cannonTimer != nil) {
		[cannonTimer invalidate];
		cannonTimer = nil;
	}
}

-(void)removeBookTimer
{
	if (bookTimer != nil) {
		[bookTimer invalidate];
		bookTimer = nil;
	}
}

-(void)removeCDTimer
{
	cdTime = 0;
	if (cdTimer != nil) {
		[cdTimer invalidate];
		cdTimer = nil;
	}
}

-(void)doFightCountdown
{
	normalTime = MAX(--normalTime, -1*continueTime);
	if (![DragonFightData checkIsOver]) {
		[GameConnection post:ConnPost_Dragon_local_countdown object:nil];
	}
	
	if ([DragonFightData checkIsOver] || normalTime <= -1*continueTime) {
		[self removeFightTimer];
	}
}

-(void)doCannonCountdown
{
	[self cannonCountdownOnce];
	
	if (![self checkSomebodyFire]) {
		[self removeCannonTimer];
	}
}

-(void)doBookCountdown
{
	[self bookCountdownOnce];
	
	if (![self checkBookCD]) {
		[self removeBookTimer];
	}
}

-(void)doCDCountdown
{
	[self cdCountdownOnce];
	
	if (![self checkCD]) {
		[self removeCDTimer];
	}
}

-(void)startCannonCountdown
{
	if (cannonTimer == nil) {
		cannonTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
													   target:self
													 selector:@selector(doCannonCountdown)
													 userInfo:nil
													  repeats:YES];
	}
}

-(void)startFightCountdown
{
	if (fightTimer == nil) {
		fightTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
													  target:self
													selector:@selector(doFightCountdown)
													userInfo:nil
													 repeats:YES];
	}
}

-(void)startBookCountdown
{
	if (bookTimer == nil) {
		bookTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
													 target:self
												   selector:@selector(doBookCountdown)
												   userInfo:nil
													repeats:YES];
	}
}

-(void)startCDCountdown
{
	if (cdTimer == nil) {
		cdTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
												   target:self
												 selector:@selector(doCDCountdown)
												 userInfo:nil
												  repeats:YES];
	}
}

// 判断是否有人在开炮
-(BOOL)checkSomebodyFire
{
	NSArray *allKeys = [cannonUseData allKeys];
	for (NSString *key in allKeys) {
		NSArray *value = [cannonUseData objectForKey:key];
		if (value.count >= 2) {
			
			int time = [[value objectAtIndex:1] intValue];
			if (time > 0) {
				return YES;
			}
			
		}
	}
	return NO;
}

// 判断是否有书是cd状态
-(BOOL)checkBookCD
{
	NSArray *allKeys = [booksCD allKeys];
	for (NSString *key in allKeys) {
		
		int time = [[booksCD objectForKey:key] intValue];
		if (time > 0) {
			return YES;
		}
	}
	return NO;
}

// 判断玩家是否cd状态
-(BOOL)checkCD
{
	return (cdTime > 0);
}

// 开炮剩余时间减1秒
-(void)cannonCountdownOnce
{
	BOOL isRemoveOne = NO;
	
	NSArray *allKeys = [cannonUseData allKeys];
	for (NSString *key in allKeys) {
		NSArray *value = [cannonUseData objectForKey:key];
		if (value.count >= 2) {
			
			int time = [[value objectAtIndex:1] intValue];
			time--;
			
			// 删除
			if (time <= 0) {
				[cannonUseData removeObjectForKey:key];
				isRemoveOne = YES;
			}
			// 改变时间
			else {
				NSArray *newValue = [NSArray arrayWithObjects:
									 [value objectAtIndex:0],
									 [NSNumber numberWithInt:time],
									 nil];
				[cannonUseData setObject:newValue forKey:key];
			}
			
		}
	}
	
	if (isRemoveOne) {
		[self updateCanMoveStatus];
	}
}

// 书的cd剩余时间减1秒
-(void)bookCountdownOnce
{
	NSArray *allKeys = [booksCD allKeys];
	for (NSString *key in allKeys) {
		
		int time = [[booksCD objectForKey:key] intValue];
		time--;
		
		// 删除
		if (time <= 0) {
			[booksCD removeObjectForKey:key];
		}
		// 改变时间
		else {
			[booksCD setObject:[NSNumber numberWithInt:time] forKey:key];
		}
		
	}
}

// 玩家死亡cd
-(void)cdCountdownOnce
{
	cdTime = MAX(--cdTime, 0);
	if (cdTime <= 0) {
		[GameConnection post:ConnPost_Dragon_local_cd_remove object:nil];
		[GameConnection post:ConnPost_Dragon_local_cd_remove_after object:nil];
	} else {
		[GameConnection post:ConnPost_Dragon_local_cd_countdown object:nil];
	}
}

-(float)getFirePercent:(int)index
{
	NSString *key = [NSString stringWithFormat:@"%d", index];
	NSArray *array = [cannonUseData objectForKey:key];
	if (array.count >= 2) {
		int time = [[array objectAtIndex:1] intValue];
		if (installTime > 0) {
			return time*100.0f/installTime*1.0f;
		}
	}
	return 0;
}

-(NSDictionary*)getShadow:(int)__ancId
{
	if (shadowData != nil) {
		for (NSDictionary *dict in shadowData) {
			
			int ancid = [[dict objectForKey:@"ancid"] intValue];
			if (ancid == __ancId) {
				return dict;
			}
			
		}
	}
	return nil;
}

#pragma mark -
#pragma mark 天书

// 获取天书cd时间
-(float)getBookCD:(int)__bookId
{
	NSString *key = [NSString stringWithFormat:@"%d", __bookId];
	return (float)[[booksCD objectForKey:key] intValue];
}

// 获取普通天书数量
-(int)getBookCount:(int)__bookId
{
	if (booksData == nil) return 0;
	
	NSString *key = [NSString stringWithFormat:@"%d", __bookId];
	if ([booksData objectForKey:key]) {
		return [[booksData objectForKey:key] intValue];
	}
	
	return 0;
}

// 获取剩余兑换天书数量
-(int)getExchangeBookCount:(int)__bookId
{
	if (booksExchange == nil) return 0;
	
	NSString *key = [NSString stringWithFormat:@"%d", __bookId];
	if ([booksExchange objectForKey:key]) {
		return [[booksExchange objectForKey:key] intValue];
	}
	
	return 0;
}

// 能否使用普通的天书
-(BOOL)checkUseNormalBook:(int)__bookId
{
	int count = [self getBookCount:__bookId];
	return (count > 0);
}

// 能否使用兑换的天书
-(BOOL)checkUseExchangeBook:(int)__bookId
{
	int count = [self getExchangeBookCount:__bookId];
	return (count > 0);
}

-(void)useNormalBook:(int)__bookId
{
	if (booksData == nil) return;
	
	int count = [self getBookCount:__bookId];
	if (count > 0) {
		count--;
		
		NSString *key = [NSString stringWithFormat:@"%d", __bookId];
		[booksData setObject:[NSNumber numberWithInt:count] forKey:key];
	}
}

-(void)useExchangeBook:(int)__bookId
{
	if (booksExchange == nil) return;
	
	int count = [self getExchangeBookCount:__bookId];
	if (count > 0) {
		count--;
		
		NSString *key = [NSString stringWithFormat:@"%d", __bookId];
		[booksExchange setObject:[NSNumber numberWithInt:count] forKey:key];
	}
}

#pragma mark -

@end
