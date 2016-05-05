//
//  DragonFightManager.m
//  TXSFGame
//
//  Created by efun on 13-9-7.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonFightManager.h"
#import "DragonMapNameInfo.h"
#import "DragonGloryInfo.h"
#import "DragonCannonInfo.h"
#import "DragonBookInfo.h"
#import "DragonFightData.h"
#import "DragonBossHpInfo.h"
#import "DragonShowInfo.h"
#import "FightManager.h"
#import "MapManager.h"
#import "Config.h"
#import "GameUI.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "MovingAlert.h"
#import "NPCManager.h"
#import "RoleManager.h"
#import "GameNPC.h"
#import "FightManager.h"
#import "GameLayer.h"
#import "DragonWorldMap.h"
#import "AnimationViewer.h"
#import "GameLayer.h"
#import "GameEffects.h"
#import "AlertManager.h"
#import "TaskTalk.h"
#import "GameLoading.h"

#define Dragon_box_button_tag			10315
#define Dragon_box_sprite_tag			10316
#define Dragon_box_shineOver_tag		10317
#define Dragon_box_shineUnder_tag		10318

#define Dragon_cd_wall_tag				10320
#define Dragon_info_tag					10321	// 开始信息，结果信息

typedef enum {
	Dragon_Info_start			= 1,	// 狩龙开始信息
	Dragon_Info_result_lose		= 2,	// 狩龙失败信息
	Dragon_Info_result_win		= 3,	// 狩龙胜利信息
} Dragon_Info_type;

static DragonFightManager *s_DragonFightManager = nil;

@implementation DragonFightManager

+(DragonFightManager*)shared
{
	if (s_DragonFightManager == nil) {
		s_DragonFightManager = [DragonFightManager node];
		[s_DragonFightManager retain];
	}
	return s_DragonFightManager;
}

+(void)startAll
{
	
}

+(void)stopAll
{
	[DragonFightManager removeDragonFight];
}

+(BOOL)checkCanEnter
{
	// 没有相关数据，返回NO
	if (![DragonFightData checkIsFight]) return NO;
	
	// 玩家正在战斗，返回NO
	if ([FightManager isFighting]) return NO;
	
	return YES;
}

+(void)enterDragonFight
{
	if (![DragonFightManager checkCanEnter]) {
		return;
	}
	
	[MovingAlert remove];
	[DragonWorldMap removeMap];
	
	[[DragonFightManager shared] enterMap];
}

+(void)removeDragonFight
{
	// 清除相关数据
	[DragonFightData remove];
	
	[[RoleManager shared].player stopMoveAndTask];
	if (s_DragonFightManager) {
		[NSTimer cancelPreviousPerformRequestsWithTarget:s_DragonFightManager];
		[s_DragonFightManager removeFromParent];
		[s_DragonFightManager release];
		s_DragonFightManager = nil;
	}
}

+(void)quitDragonFight
{
	[DragonFightManager removeDragonFight];
	
	[[RoleManager shared] otherPlayerVisible:YES];
	
	if ([MapManager shared].mapType == Map_Type_dragonFight) {
		[[Game shared] backToMap:nil call:nil];
	}
}

+(void)checkStatus
{
	if ([MapManager shared].mapType == Map_Type_dragonFight) {
		// 有数据，而且还没结束，可进入准备界面（如果捡了宝箱，就直接退出）
		if ([DragonFightData checkIsFight] && ![DragonFightData checkIsFinalOver]) {
			
			if (s_DragonFightManager != nil) {
				[s_DragonFightManager checkRestart];
			} else {
				[DragonFightManager enterDragonFight];
			}
			
		}
		// 无数据，或者有数据但是捡了宝箱，返回上一个记录的地图
		else {
			[DragonFightManager quitDragonFight];
		}
	} else {
		[DragonFightManager removeDragonFight];
	}
}

-(void)enterMap
{
	int mapId = [DragonFightData shared].mapId;
	if ([MapManager shared].mapId == mapId) {
		[self checkRestart];
	} else {
		[[Game shared] trunToMap:mapId target:nil call:nil];
	}
}

-(BOOL)checkExistParent
{
	return (self.parent != nil);
}

-(void)checkRestart
{
	if (![self checkExistParent]) {
		[[GameUI shared] addChild:self z:-1 tag:GameUi_SpecialSystem_dragonFight];
		
		if ([DragonFightData checkIsOver]) {
			
			DragonResultType type = [DragonFightData shared].resultType;
			switch (type) {
				case DragonResult_win:
					[self doWin];
					break;
				case DragonResult_lose_time:
					[self doLose:DragonResult_lose_time];
					break;
				case DragonResult_lose_boat:
					[self doLose:DragonResult_lose_boat];
					break;
					
				default:
					break;
			}
			
		}
	}
	
}

-(id)init{
    if ( NULL != (self=[super init]) ) {
        _responseArray = [NSMutableArray array];
        [_responseArray retain];
    }
    return self;
}

-(void)dealloc
{
    if (_responseArray) {
        [_responseArray removeAllObjects];
        [_responseArray release];
        _responseArray = NULL;
    }
    
	[super dealloc];
}

-(void)addResponse:(id)sender{
    if ( _responseArray && sender ) {
        [_responseArray addObject:sender];
    }
}

-(void)freeUI
{
	if (_dragonMapNameInfo != nil) {
		[_dragonMapNameInfo removeFromParent];
		_dragonMapNameInfo = nil;
	}
	if (_dragonGloryInfo != nil) {
		[_dragonGloryInfo removeFromParent];
		_dragonGloryInfo = nil;
	}
	if (_dragonCannonInfo != nil) {
		[_dragonCannonInfo removeFromParent];
		_dragonCannonInfo = nil;
	}
	if (_dragonBookInfo != nil) {
		[_dragonBookInfo removeFromParent];
		_dragonBookInfo = nil;
	}
	if (_dragonBossHpInfo != nil) {
		[_dragonBossHpInfo removeFromParent];
		_dragonBossHpInfo = nil;
	}
	if (_dragonShowInfo != nil) {
		[_dragonShowInfo removeFromParent];
		_dragonShowInfo = nil;
	}
}

-(void)showUI
{
	CGSize winSize = [CCDirector sharedDirector].winSize;
	
	DragonType _dragonType = [DragonFightData shared].dragonType;
	DragonTime _dragonTime = DragonTime_fight;
	
	if (_dragonMapNameInfo == nil) {
		_dragonMapNameInfo = [DragonMapNameInfo create:_dragonType time:_dragonTime];
		_dragonMapNameInfo.anchorPoint = ccp(1, 1);
		_dragonMapNameInfo.position = ccp(winSize.width, winSize.height);
		
		[self addChild:_dragonMapNameInfo z:1];
	}
	if (_dragonGloryInfo == nil) {
		_dragonGloryInfo = [DragonGloryInfo create:_dragonTime];
		_dragonGloryInfo.anchorPoint = ccp(1, 0);
		_dragonGloryInfo.position = ccp(winSize.width+cFixedScale(30.0f), cFixedScale(122.0f));
		
		[self addChild:_dragonGloryInfo z:1];
	}
	if (_dragonCannonInfo == nil) {
		_dragonCannonInfo = [DragonCannonInfo create:_dragonType time:_dragonTime];
		_dragonCannonInfo.anchorPoint = ccp(0, 1);
		_dragonCannonInfo.position = ccp(-cFixedScale(30.0f), winSize.height-cFixedScale(190));
		
		[self addChild:_dragonCannonInfo z:1];
	}
	if (_dragonBookInfo == nil) {
		_dragonBookInfo = [DragonBookInfo create:DragonTime_fight];
		_dragonBookInfo.anchorPoint = ccp(1, 0);
		_dragonBookInfo.position = ccp(winSize.width, 0);
		
		[self addChild:_dragonBookInfo z:1];
	}
	// 有boss血量数据才显示
	if ([DragonFightData shared].bossTotalHp > 0) {
		if (_dragonBossHpInfo == nil) {
			_dragonBossHpInfo = [DragonBossHpInfo node];
			_dragonBossHpInfo.anchorPoint = ccp(0, 1);
			_dragonBossHpInfo.position = ccp(cFixedScale(430.0f), winSize.height-cFixedScale(15.0f));
			
			[self addChild:_dragonBossHpInfo z:1];
		}
	}
	if (_dragonShowInfo == nil) {
		_dragonShowInfo = [DragonShowInfo node];
		
		[self addChild:_dragonShowInfo z:1];
	}
}

-(void)initPoint
{
	boxPoint = CGPointZero;
	wallPoint = CGPointZero;
	
	NSArray *positions = [[MapManager shared] getFunctionData:@"object" key:@"box"];
	if (positions.count > 0) {
		
		NSDictionary *position = [positions objectAtIndex:0];
		CGPoint point = CGPointMake([[position objectForKey:@"x"] floatValue],
									[[position objectForKey:@"y"] floatValue]);
		boxPoint = getTiledRectCenterPoint(CGRectMake(point.x, point.y, 0, 0));
	}
	positions = [[MapManager shared] getFunctionData:@"object" key:@"firewall"];
	if (positions.count > 0) {
		
		NSDictionary *position = [positions objectAtIndex:0];
		CGPoint point = CGPointMake([[position objectForKey:@"x"] floatValue],
									[[position objectForKey:@"y"] floatValue]);
		wallPoint = getTiledRectCenterPoint(CGRectMake(point.x, point.y, 0, 0));
	}
}

-(void)showResponseMessage{
    if( [FightManager isFighting] || [TaskTalk isTalking] || [GameLoading isShowing] ){
        [NSTimer scheduledTimerWithTimeInterval:0.8 target:self selector:@selector(showResponseMessage) userInfo:nil repeats:NO];
        return;
    }
    if (_responseArray && [_responseArray count]>0) {
        NSDictionary *dict = [_responseArray objectAtIndex:0];
        if (dict) {
            id sender = [dict objectForKey:@"sender"];
            //
            if (sender) {
                if ( checkResponseStatus(sender) ) {
                    NSDictionary *dict_ = getResponseData(sender);
                    if (dict_) {
                        // 显示更新的物品
                        NSArray *updateData = [dict objectForKey:@"updateData"];
                        if ( updateData && [updateData count]>0 ) {
                           [[AlertManager shared] showReceiveItemWithArray:updateData]; 
                        }
                    }
                    
                } else {
                    [ShowItem showErrorAct:getResponseMessage(sender)];
                }
            }
        }
        //
        [_responseArray removeObjectAtIndex:0];
    }
}
-(void)onEnter
{
	[super onEnter];
	
	[self freeUI];
	[self showUI];
    
	//show message
    [self showResponseMessage];
    
	[self initPoint];
	
	[GameConnection addPost:ConnPost_Dragon_local_player_fight_start target:self call:@selector(playerFightStart:)];
	[GameConnection addPost:ConnPost_Dragon_local_player_fight_end target:self call:@selector(playerFightEnd:)];
	[GameConnection addPost:ConnPost_Dragon_local_monster_fight_start target:self call:@selector(monsterFightStart:)];
	[GameConnection addPost:ConnPost_Dragon_local_monster_fight_end target:self call:@selector(monsterFightEnd:)];
	[GameConnection addPost:ConnPost_Dragon_local_monster_add target:self call:@selector(monsterAdd:)];
	[GameConnection addPost:ConnPost_Dragon_local_monster_remove target:self call:@selector(monsterRemove:)];
	[GameConnection addPost:ConnPost_Dragon_local_fight_fire target:self call:@selector(fire:)];
	[GameConnection addPost:ConnPost_Dragon_local_isCanMove target:self call:@selector(updateCanMoveStatus)];
	[GameConnection addPost:ConnPost_Dragon_local_fight_fire_remove target:self call:@selector(removeAllFire)];
	[GameConnection addPost:ConnPost_Dragon_local_result_win target:self call:@selector(win)];
	[GameConnection addPost:ConnPost_Dragon_local_result_lose_time target:self call:@selector(loseTime)];
	[GameConnection addPost:ConnPost_Dragon_local_result_lose_boat target:self call:@selector(loseBoat)];
	[GameConnection addPost:ConnPost_Dragon_local_result_gm_exit target:self call:@selector(loseByGm)];
	[GameConnection addPost:ConnPost_Dragon_local_box target:self call:@selector(showBox)];
	[GameConnection addPost:ConnPost_Dragon_local_did_openbox target:self call:@selector(didOpenBox)];
	[GameConnection addPost:ConnPost_Dragon_local_cd_update target:self call:@selector(updateCDStatus)];
	
	// 添加npc
	[self addAliveNpc];
	[self updateAliveNpc];
	
	// 更新打炮状态
	[self updateFireStatus];
	
	// 更新是否可移动状态
	[self updateCanMoveStatus];
	
	// 更新CD状态
	[self updateCDStatus];
	
	[self showStartInfo];
	[self showResultInfo];
}

-(void)onExit
{
	[self removeBox];
	
	// 清除弹出框
	[[AlertManager shared] remove];
	
	[self removeCDWall];
	[MapManager shared].isBlock = NO;
	
	[self freeUI];
	[GameConnection removePostTarget:self];
	
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
    //
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
    //
	[super onExit];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	[ShowItem showItemAct:NSLocalizedString(@"dragon_cannon_no_move",nil)];
	return YES;
}

#pragma mark -
#pragma mark 显示进入场景信息，结束信息

-(void)showStartInfo
{
	// 已经显示过开始信息的时候，退出
	if ([DragonFightData checkIsShowStartTitle]) return;
	
	[self showInfoWithType:Dragon_Info_start];
	
	[DragonFightData shared].isShowStartTitle = YES;
}

-(void)showResultInfo
{
	// 还没结果的时候，退出
	if (![DragonFightData checkIsOver]) return;
	// 已经显示过结果信息的时候，退出
	if ([DragonFightData checkIsShowResultTitle]) return;
	
	if ([DragonFightData checkIsWin]) {
		[self showInfoWithType:Dragon_Info_result_win];
	} else if ([DragonFightData checkIsLose]) {
		[self showInfoWithType:Dragon_Info_result_lose];
	}
	
	[DragonFightData shared].isShowResultTitle = YES;
}

-(void)showInfoWithType:(Dragon_Info_type)_type
{
	[self removeChildByTag:Dragon_info_tag];
	
	CCSprite *sprite = nil;
	switch (_type) {
		case Dragon_Info_start:
		case Dragon_Info_result_lose:
		{
			sprite = [CCSprite spriteWithFile:@"images/ui/dragon/bg_start_info.png"];
			
			NSString *info = nil;
			if (_type == Dragon_Info_start) {
				info = [DragonFightData shared].startInfo;
			} else if ([DragonFightData shared].resultType == DragonResult_lose_time) {
				info = NSLocalizedString(@"dragon_result_timeout",nil);
			} else if ([DragonFightData shared].resultType == DragonResult_lose_boat) {
				info = NSLocalizedString(@"dragon_result_boatover",nil);
			}
			if (info == nil) info = @"";
			
			float fontSize = 30.0f;
			CCSprite *label = drawBoundString(info,
											  11,
											  GAME_DEF_CHINESE_FONT,
											  fontSize,
											  ccc3(251, 236, 201), ccBLACK);
			label.position = ccp(sprite.contentSize.width/2, sprite.contentSize.height/2);
			label.color = ccc3(248, 143, 3);
			[sprite addChild:label];
		}	
			break;
		case Dragon_Info_result_win:
		{
			NSString *path = ([DragonFightData shared].dragonType == DragonType_cometo) ? @"images/ui/dragon/bg_result_win_cometo.png" : @"images/ui/dragon/bg_result_win_fly.png";
			sprite = [CCSprite spriteWithFile:path];
		}
			break;
			
		default:
			break;
	}
	
	if (sprite != nil) {
		sprite.anchorPoint = CGPointZero;
		
		CCRenderTexture *texture = [CCRenderTexture renderTextureWithWidth:sprite.contentSize.width
																	height:sprite.contentSize.height];
		texture.sprite.anchorPoint= ccp(0.5f, 0.5f);
		texture.anchorPoint = ccp(0.5f, 0.5f);
		
		[texture begin];
		[sprite visit];
		[texture end];
		
		// 删除sprite
		sprite = nil;
		
		CGSize winSize = [CCDirector sharedDirector].winSize;
		CGPoint point = ccp(winSize.width/2, winSize.height/2+cFixedScale(80));
		
		texture.position = point;
		[self addChild:texture z:10000 tag:Dragon_info_tag];
		
		[texture.sprite runAction:[CCSequence actionOne:[CCDelayTime actionWithDuration:2.0f]
													two:[CCFadeOut actionWithDuration:0.8f]]];
	}
}

#pragma mark -
#pragma mark 玩家，角色的添加，删除，状态变化

-(void)playerFightStart:(NSNotification*)notification
{
}

-(void)playerFightEnd:(NSNotification*)notification
{
}

-(void)monsterFightStart:(NSNotification*)notification
{
	int ancId = [notification.object intValue];
	
	// 如果是boss，不处理
	NSDictionary *dragonNpc = [[GameDB shared] getAwarNpcConfig:ancId];
	if (dragonNpc != nil) {
		int bid = [[dragonNpc objectForKey:@"bid"] intValue];
		if (bid != 0) return;
	}
	
	[[[NPCManager shared] getNPCByTag:ancId] showFighting];
}

-(void)monsterFightEnd:(NSNotification*)notification
{
	int ancId = [notification.object intValue];
	
	// 如果是boss，不处理
	NSDictionary *dragonNpc = [[GameDB shared] getAwarNpcConfig:ancId];
	if (dragonNpc != nil) {
		int bid = [[dragonNpc objectForKey:@"bid"] intValue];
		if (bid != 0) return;
	}
	
	[[[NPCManager shared] getNPCByTag:ancId] removeFighting];
}

-(void)monsterAdd:(NSNotification*)notification
{
	int ancId = [notification.object intValue];
	
	[self addNpcWithAncId:ancId];
}

-(void)monsterRemove:(NSNotification*)notification
{
	int ancId = [notification.object intValue];
	
	[[NPCManager shared] removeNPCByTag:ancId];
}

-(void)addNpcWithAncId:(int)ancid
{
	NSDictionary *shadowData = [[DragonFightData shared] getShadow:ancid];
	if (shadowData != nil) {
		
		NSDictionary *npcDict = [[GameDB shared] getAwarNpcConfig:ancid];
		if (npcDict) {
			CGPoint point = CGPointFromString([npcDict objectForKey:@"pos"]);
			int direction = [[npcDict objectForKey:@"dir"] intValue];
			
			[[NPCManager shared] addNPCByPlayerDict:shadowData
										  tilePoint:point
										  direction:direction
											 target:self
											 select:@selector(moveToShadow:)
												tag:ancid];
		}
		
	} else {
		NSDictionary *npcDict = [[GameDB shared] getAwarNpcConfig:ancid];
		if (npcDict) {
			int npcId = [[npcDict objectForKey:@"mnpcid"] intValue];
			CGPoint point = CGPointFromString([npcDict objectForKey:@"pos"]);
			int direction = [[npcDict objectForKey:@"dir"] intValue];
			[[NPCManager shared] addNPCById:npcId
								  tilePoint:point
								  direction:direction
									 target:self
									 select:@selector(moveToMonster:)
										tag:ancid];
		}
	}

}

-(void)addAliveNpc
{
	NSArray *npcs = [DragonFightData shared].aliveNpcs;
	for (NSString *idString in npcs) {
		[GameConnection post:ConnPost_Dragon_local_monster_add object:idString];
	}
}

-(void)updateAliveNpc
{
	NSDictionary *__currentFightData = [NSDictionary dictionaryWithDictionary:[DragonFightData shared].currentFightData];
	NSArray *allKeys = [__currentFightData allKeys];
	for (NSString *key in allKeys) {
		NSString *value = [__currentFightData objectForKey:key];
		
		[GameConnection post:ConnPost_Dragon_local_player_fight_start object:key];
		[GameConnection post:ConnPost_Dragon_local_monster_fight_start object:value];
	}
}

#pragma mark -
#pragma mark 移动到怪物处，发生战斗

-(void)moveToMonster:(GameNPC*)npc
{
	selectMonsterId = npc.tag;
	[DragonFightData setSelectMonsterId:selectMonsterId];
	
	// 如果npc是boss，并且不可攻击的时候，不执行
	NSDictionary *npcDict = [[GameDB shared] getAwarNpcConfig:selectMonsterId];
	if (npcDict) {
		BOOL isBoss = !([[npcDict objectForKey:@"bid"] intValue] == 0);
		if (isBoss) {
			
			int apcid = [[npcDict objectForKey:@"apcid"] intValue];
			NSDictionary *apcDict = [[GameDB shared] getAwarPerConfig:apcid];
			if (apcDict) {
				BOOL isCanKillBoss = ([[apcDict objectForKey:@"kboss"] intValue] == 1);
				if (!isCanKillBoss) {
					[ShowItem showItemAct:NSLocalizedString(@"dragon_boss_no_kill",nil)];
					return;
				}
			}
			
		}
	}
	
	CGPoint point = ccpAdd(npc.position, ccp(0, cFixedScale(-50)));
	[[RoleManager shared] movePlayerTo:point
								target:self
								  call:@selector(doFightAction)
	 ];
}

-(void)doFightAction
{
	// 该怪战斗状态不执行
	GameNPC *npc = [[NPCManager shared] getNPCByTag:selectMonsterId];
	if (npc == nil || npc.isFighting) {
		[ShowItem showItemAct:NSLocalizedString(@"dragon_monster_fight_now",nil)];
		return;
	}
	
	// 狩龙战已结束
	if ([DragonFightData checkIsOver]) {
		[ShowItem showItemAct:NSLocalizedString(@"dragon_fight_end",nil)];
		return;
	}
	
	// 该怪存在并且不是战斗状态
	[[FightManager shared] startFightDragonByNPCId:selectMonsterId target:[DragonFightData class] call:@selector(doFightEnd)];
}

-(void)moveToShadow:(GameNPC*)npc
{
	selectMonsterId = npc.tag;
	[DragonFightData setSelectMonsterId:selectMonsterId];
	
	CGPoint point = ccpAdd(npc.position, ccp(0, cFixedScale(-50)));
	[[RoleManager shared] movePlayerTo:point
								target:self
								  call:@selector(doFightWithShadowAction)
	 ];
}

-(void)doFightWithShadowAction
{
	// 该影分身战斗状态不执行
	GameNPC *npc = [[NPCManager shared] getNPCByTag:selectMonsterId];
	if (npc == nil || npc.isFighting) {
		[ShowItem showItemAct:NSLocalizedString(@"dragon_shadow_fight_now",nil)];
		return;
	}
	
	// 狩龙战已结束
	if ([DragonFightData checkIsOver]) {
		[ShowItem showItemAct:NSLocalizedString(@"dragon_fight_end",nil)];
		return;
	}
	
	// 该影分身存在并且不是战斗状态
	[[FightManager shared] startFightDragonByPlayerId:selectMonsterId target:[DragonFightData class] call:@selector(doFightEnd)];
}

#pragma mark -
#pragma mark 移动到炮塔处，开炮

// 移除所有打炮状态
-(void)removeAllFire
{
	NSArray *npcArray = [NSArray arrayWithArray:[[NPCManager shared] getAllNPC]];
	for (GameNPC *npc in npcArray) {
		
		if (npc.userObject != nil) {
			NSString *string = npc.userObject;
			NSArray *array = [string componentsSeparatedByString:@":"];
			if (array != nil && array.count >= 1) {
				
				// 如果当前npc为炮塔，去除打炮状态
				NSString *cannonString = [array objectAtIndex:0];
				if ([cannonString isEqualToString:@"cannon"]) {
					[npc removeFire];
				}
				
			}
		}
		
	}
}

-(void)updateFireStatus
{
	NSDictionary *_cannonUseData = [NSDictionary dictionaryWithDictionary:[DragonFightData shared].cannonUseData];
	NSArray *allKeys = [_cannonUseData allKeys];
	for (NSString *key in allKeys) {
		
		int index = [key intValue];
		[self fireWithIndex:index];
		
	}
}

// 开炮
-(void)doFireByTurret:(GameNPC*)npc
{
	// 正在装载炮弹
	if (npc.isFire) {
		[ShowItem showItemAct:NSLocalizedString(@"dragon_cannon_use_now",nil)];
		return;
	}
	
	// 狩龙战已结束
	if ([DragonFightData checkIsOver]) {
		[ShowItem showItemAct:NSLocalizedString(@"dragon_fight_end",nil)];
		return;
	}
	
	// 炮弹不足
	if (![DragonFightData checkExistCannon]) {
		[ShowItem showItemAct:NSLocalizedString(@"dragon_cannon_no_exist",nil)];
		return;
	}
	
	// 玩家在cd时间
	if ([DragonFightData checkIsCD]) return;
	
	if (npc.userObject != nil) {
		
		NSString *string = npc.userObject;
		NSArray *array = [string componentsSeparatedByString:@":"];
		if (array != nil && array.count >= 2) {
			int index = [[array objectAtIndex:1] intValue];
			NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:@"index"];
			[GameConnection request:@"awarFire" data:dict target:nil call:nil];
		}
		
	}
}

-(void)fire:(NSNotification*)notification
{
	int index = [notification.object intValue];
	[self fireWithIndex:index];
}

-(void)fireWithIndex:(int)index
{
	id userObj = [NSString stringWithFormat:@"cannon:%d", index];
	
	GameNPC *npc = [[NPCManager shared] getNPCByUserObject:userObj];
	if (npc != nil && !npc.isFire) {
		
		float percent = [[DragonFightData shared] getFirePercent:index];
		[npc showFire:percent];
		
	}
}

#pragma mark -
#pragma mark 是否可移动

-(void)updateCanMoveStatus
{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	BOOL isCanMove = [DragonFightData shared].isCanMove;
	if (!isCanMove) {
		[[director touchDispatcher] addTargetedDelegate:self priority:-257 swallowsTouches:YES];
	}
}

#pragma mark -
#pragma mark CD区相关

// 玩家cd状态改变
-(void)updateCDStatus
{
	[self updatePosition];
	[self updateCDWall];
	[self updateCDBlock];
}

// 如果是cd时间，传送到起始点
-(void)updatePosition
{
	BOOL isCD = [DragonFightData checkIsCD];
	if (isCD) {
		[[RoleManager shared] movePlayerToStartPoint];
	}
}

-(void)removeCDWall
{
	[[[GameLayer shared] content] removeChildByTag:Dragon_cd_wall_tag cleanup:YES];
}

// cd障碍，如果是cd时间，加上cd墙
-(void)updateCDWall
{
	[self removeCDWall];
	
	BOOL isCD = [DragonFightData checkIsCD];
	if (isCD) {
		AnimationViewer *wall = [AnimationViewer node];
		wall.tag = Dragon_cd_wall_tag;
		wall.anchorPoint = ccp(0.5, 0.5);
		wall.position = wallPoint;
		[[[GameLayer shared] content] addChild:wall z:0];
		
		wall.scale = 2.0f;
		[wall showAnimationByPath:@"images/animations/fire/%d.png"];
	}
}

// 可移动区域，如果是cd时间，只能在cd区域移动
-(void)updateCDBlock
{
	BOOL isCD = [DragonFightData checkIsCD];
	[MapManager shared].isBlock = isCD;
}

#pragma mark -
#pragma mark 狩龙结果处理

// 胜利
-(void)win
{
	if ([self checkExistParent]) {
		[self doWin];
	}
}

// 失败（时间到）
-(void)loseTime
{
	CCLOG(@"失败（时间到）");
	[self doLose:DragonResult_lose_time];
}

// 失败（天舟被摧毁）
-(void)loseBoat
{
	CCLOG(@"失败（天舟被摧毁）");
	[self doLose:DragonResult_lose_boat];
}

// Gm重新开狩龙
-(void)loseByGm
{
	CCLOG(@"Gm指令重新开");
	[DragonFightManager quitDragonFight];
}

// 处理胜利业务
-(void)doWin
{
	CCLOG(@"处理胜利业务");
	
	[self showResultInfo];
	
	// 清除cd
	if ([DragonFightData checkIsCD]) {
		[[DragonFightData shared] removeCD];
	}
	
	[self initBox];
	[GameConnection post:ConnPost_Dragon_local_result_doWin object:nil];
	
	// 烛龙飞空
	if ([DragonFightData shared].dragonType == DragonType_fly) {
		// 掉宝箱
		[GameConnection post:ConnPost_Dragon_local_box object:nil];
	}
	// 魔龙降世
	else if ([DragonFightData shared].dragonType == DragonType_cometo) {
		// 弹出评价
		[GameConnection request:@"awarWorldAssess" data:[NSDictionary dictionary] target:[DragonFightData class] call:@selector(didAssess:)];
	}
}

// 处理失败业务
-(void)doLose:(DragonResultType)type
{
	if (type != DragonResult_lose_time &&
		type != DragonResult_lose_boat) {
		return;
	}
	
	[self showResultInfo];
	[GameConnection post:ConnPost_Dragon_local_exit object:nil];
}

// 加载宝箱信息
-(void)initBox
{
	// 没有宝箱数据时候，退出
	if (CGPointEqualToPoint(boxPoint, CGPointZero)) return;
	
	int z = (GAME_MAP_MAX_Y - boxPoint.y);
	
	// 宝箱相关
	NSString *fullPath1 = @"images/animations/boxopen/1/";
	NSString *fullPath2 = @"images/animations/boxopen/2/";
	NSArray *frames1 = [AnimationViewer loadFileByFileFullPath:fullPath1 name:@"%d.png"];
	NSArray *frames2 = [AnimationViewer loadFileByFileFullPath:fullPath2 name:@"%d.png"];
	
	// 宝箱闪烁
	AnimationViewer *shineOver = [AnimationViewer node];
	shineOver.scale = 0.7f;
	shineOver.visible = NO;
	shineOver.position = boxPoint;
	[shineOver playAnimation:frames1];
	[[[GameLayer shared] content] addChild:shineOver z:10 tag:Dragon_box_shineOver_tag];
	
	AnimationViewer *shineUnder = [AnimationViewer node];
	shineUnder.scale = 0.7f;
	shineUnder.visible = NO;
	shineUnder.position = boxPoint;
	[shineUnder playAnimation:frames2];
	[[[GameLayer shared] content] addChild:shineUnder z:-1 tag:Dragon_box_shineUnder_tag];
	
	CCSprite *boxSprite = [CCSprite spriteWithFile:@"images/ui/timebox/box_open.png"];
	boxSprite.visible = NO;
	boxSprite.position = boxPoint;
	[[[GameLayer shared] content] addChild:boxSprite z:z tag:Dragon_box_sprite_tag];
	
	CCSimpleButton *boxButton = [CCSimpleButton spriteWithFile:@"images/ui/timebox/box_close.png"
														select:@"images/ui/timebox/box_close.png"
														target:self
														  call:@selector(openBox)
													  priority:-1];
	boxButton.visible = NO;
	boxButton.position = ccp(boxPoint.x, boxPoint.y + cFixedScale(800));
	[[[GameLayer shared] content] addChild:boxButton z:z tag:Dragon_box_button_tag];
}

// 掉宝箱
-(void)showBox
{
	CCNode *boxButton = [[[GameLayer shared] content] getChildByTag:Dragon_box_button_tag];
	if (boxButton != nil) {
		
		CCNode *boxSprite = [[[GameLayer shared] content] getChildByTag:Dragon_box_sprite_tag];
		if (boxSprite != nil) {
			
			boxButton.visible = YES;
			
			id moveAction = [CCMoveTo actionWithDuration:1.0f position:boxSprite.position];
			[boxButton runAction:[CCSequence actionOne:moveAction two:[CCCallFunc actionWithTarget:self selector:@selector(boxActionDone)]]];
			
			isBoxFly = YES;
			
		}
		
	}
}

-(void)removeBox
{
	// 清除宝箱相关
	[[[GameLayer shared] content] removeChildByTag:Dragon_box_button_tag];
	[[[GameLayer shared] content] removeChildByTag:Dragon_box_sprite_tag];
	[[[GameLayer shared] content] removeChildByTag:Dragon_box_shineUnder_tag];
	[[[GameLayer shared] content] removeChildByTag:Dragon_box_shineOver_tag];
}

-(void)boxActionDone
{
	isBoxFly = NO;
	[[GameEffects share] showEffects:EffectsAction_loshing target:nil call:nil];
}

-(void)openBox
{
	if (isBoxFly) return;
	
	// 如果已经了点击打开宝箱，再次点击无效
	if ([DragonFightData checkIsFinalOver]) return;
	
	[[GameConfigure shared] markPlayerProperty];
	
	[GameConnection request:@"awarGetBox" data:[NSDictionary dictionary] target:[DragonFightData class] call:@selector(didGetBox:)];
}

-(void)didOpenBox
{
	CCNode *boxSprite = [[[GameLayer shared] content] getChildByTag:Dragon_box_sprite_tag];
	if (boxSprite) {
		boxSprite.visible = YES;
	}
	
	CCNode *boxButton = [[[GameLayer shared] content] getChildByTag:Dragon_box_button_tag];
	if (boxButton) {
		boxButton.visible = NO;
	}
	
	CCNode *shineOver = [[[GameLayer shared] content] getChildByTag:Dragon_box_shineOver_tag];
	if (shineOver) {
		shineOver.visible = YES;
	}
	CCNode *shineUnder = [[[GameLayer shared] content] getChildByTag:Dragon_box_shineUnder_tag];
	if (shineUnder) {
		shineUnder.visible = YES;
	}
	
	[self scheduleOnce:@selector(removeBox) delay:1.5f];
}

#pragma mark -

@end
