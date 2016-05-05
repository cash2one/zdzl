//
//  WorldBossManager.m
//  TXSFGame
//
//  Created by Soul on 13-4-6.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "WorldBossManager.h"
#import "GameConnection.h"
#import "MapManager.h"
#import "MovingAlert.h"
#import "GameDB.h"
#import "Game.h"
#import "GameUI.h"
#import "BossRank.h"
#import "BossInfo.h"
#import "BossAction.h"
#import "Monster.h"
#import "RolePlayer.h"
#import "RoleManager.h"
#import "GameLayer.h"
#import "MessageAlert.h"
#import "FightManager.h"
#import "Config.h"
#import "Window.h"
#import "ShowItem.h"
#import "BossBuff.h"
#import "WorldBossTips.h"
#import "InfoAlert.h"

#define WorldBossManager_debug 0

#define WorldBoss_map 1005

#define ConnPost_worldboss_system_start_fight @"ConnPost_worldboss_system_start_fight"
#define ConnPost_worldboss_system_start_fight_cool @"ConnPost_worldboss_system_start_fight_cool"
#define ConnPost_worldboss_die @"ConnPost_worldboss_die"

@implementation WorldBossManager

static WorldBossManager* s_WorldBossManager = nil;

static BOOL isAddEvent = NO;
static BOOL isNewWorldBossSystem = YES;
static BOOL isWaitNet = NO;

static bool isNetting = NO;

static NSTimer * s_SystemBossTimer = nil;

static SystemStatusStep	worldBossStatue = SystemStatusStep_none;
static SystemStatusInfo worldBossSystemInfo;
static BossData worldBossInfo;

static int worldBoss_hp = 0 ;
static int worldBoss_hurt = 0 ;
static int worldBoss_hurt_single = 0 ;
//
static NSTimeInterval s_worldBossStopTime = 0.0f;
//buff
static NSMutableDictionary * buffers;

+(void)enterBackground{
    s_worldBossStopTime = [[NSDate date] timeIntervalSince1970];
}

+(void)enterForeground{
    NSTimeInterval t_time = [[NSDate date] timeIntervalSince1970] - s_worldBossStopTime;
    
    if (worldBossSystemInfo.isCheckStart) {
        worldBossSystemInfo.startTime -= t_time;
        if(worldBossSystemInfo.startTime<0){
            worldBossSystemInfo.startTime = 0;
        }
    }
    if (worldBossSystemInfo.isCheckStop) {
        worldBossSystemInfo.stopTime -= t_time;
        if(worldBossSystemInfo.stopTime<0){
            worldBossSystemInfo.stopTime = 0;
        }
    }
    if (worldBossSystemInfo.isCheckCooling) {
        worldBossSystemInfo.combatCool._remain -= t_time;
        if(worldBossSystemInfo.combatCool._remain<0){
            worldBossSystemInfo.combatCool._remain = 0;
        }
    }
}

+(NSDictionary*)getWorldBossBuffs{
	return buffers;
}

+(void)addWorldBossBuffs:(NSDictionary*)_dict{
	if (_dict == nil) return;
	[WorldBossManager removeWorldBossBuffs];
	
	buffers = [NSMutableDictionary dictionaryWithDictionary:_dict];
	[buffers retain];
	
}

+(void)removeWorldBossBuffs{
	if (buffers != nil) {
		[buffers release];
		buffers = nil;
	}
}

+(void)updataWorldBossBuffs:(NSDictionary*)_dict{
	//TODO
	[WorldBossManager addWorldBossBuffs:_dict];
}

+(int)getStartTime{
	return worldBossSystemInfo.startTime;
}

+(WorldBossManager*)shared{
	if(s_WorldBossManager==nil){
		s_WorldBossManager = [WorldBossManager node];
		[s_WorldBossManager retain];
	}
	return s_WorldBossManager ;
}

+(void)startAll{
	
	worldBossInfo = BossDataZero();
	worldBossSystemInfo = SystemStatusInfoZero();
	isNewWorldBossSystem = YES;
	isWaitNet = NO;
	isNetting = NO;
	
	[WorldBossManager addEvent];
	
}

+(void)stopAll{
	
	if(s_WorldBossManager){
		[NSTimer cancelPreviousPerformRequestsWithTarget:s_WorldBossManager];
		[s_WorldBossManager removeFromParentAndCleanup:YES];
		[s_WorldBossManager release];
		s_WorldBossManager = nil;
	}
	
	[WorldBossManager removeEvent];
	[WorldBossManager removeWorldBossBuffs];
	
	worldBossInfo = BossDataZero();
	worldBossSystemInfo = SystemStatusInfoZero();
	
}

+(void)addEvent{
	if(isAddEvent) return;
	isAddEvent = YES;
	
	id target = [WorldBossManager class];
	SEL call = @selector(acceptPost:);
	
	[GameConnection addPost:ConnPost_WorldBoss_Start target:target call:call];
	[GameConnection addPost:ConnPost_WorldBoss_Hurts target:target call:call];
	[GameConnection addPost:ConnPost_WorldBoss_Rank target:target call:call];
	//
    [GameConnection addPost:ConnPost_gameEnterBackground target:target call:@selector(enterBackground)];
    [GameConnection addPost:ConnPost_gameEnterForeground target:target call:@selector(enterForeground)];
    
	s_SystemBossTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
													 target:[WorldBossManager class]
												   selector:@selector(checkSystemTime)
												   userInfo:nil
													repeats:YES];
}

+(void)removeEvent{
	[GameConnection removePostTarget:[WorldBossManager class]];
	isAddEvent = NO;
	//
    s_worldBossStopTime = 0.0f;
    
	if(s_SystemBossTimer){
		[s_SystemBossTimer invalidate];
		s_SystemBossTimer = nil;
	}
}

+(void)acceptPost:(NSNotification*)notification{
	NSDictionary * data = notification.object;
	
	if([notification.name isEqualToString:ConnPost_WorldBoss_Start]){
		worldBossSystemInfo.startTime = [[data objectForKey:@"times"] intValue];
		if(worldBossSystemInfo.startTime > 0){
			worldBossSystemInfo.isCheckStart = YES;
			worldBossStatue = SystemStatusStep_waitting;
			[WorldBossTips resetThisTimeClose];
			[WorldBossTips show:NO];
		}else{
			worldBossSystemInfo.startTime = 0;
			worldBossSystemInfo.isCheckStart = NO;
			worldBossStatue = SystemStatusStep_running;
			[WorldBossTips resetThisTimeClose];
			[WorldBossTips show:YES];
			
		}
	}
	
	if([notification.name isEqualToString:ConnPost_WorldBoss_Hurts]){
		int temp = [[data objectForKey:@"hp"] intValue];
		worldBossInfo.bossHP = temp;

		if (temp <= 0) {
			worldBossStatue = SystemStatusStep_end;
			[GameConnection post:ConnPost_worldboss_die
						  object:nil];
		}
	}
	
	if([notification.name isEqualToString:ConnPost_WorldBoss_Rank]){
		
	}
	
}

+(void)checkSystemTime{
	
	if (worldBossSystemInfo.isCheckStart) {
		worldBossSystemInfo.startTime--;
//		[GameConnection post:ConnPost_BossInfo_time_setting
//					  object:[NSNumber numberWithInt:(-1*worldBossSystemInfo.startTime)]];
		[GameConnection post:ConnPost_BossInfo_time_setting_worldboss
					  object:[NSNumber numberWithInt:(-1*worldBossSystemInfo.startTime)]];

		if (worldBossSystemInfo.startTime <= 0) {
			worldBossSystemInfo.isCheckStart = NO;
			worldBossStatue = SystemStatusStep_running;
			[GameConnection post:ConnPost_worldboss_system_start_fight object:nil];
		}
		[WorldBossTips show:NO];
	}
	
	if (worldBossSystemInfo.isCheckStop) {
		worldBossSystemInfo.stopTime--;
		
		if (!worldBossSystemInfo.isCheckStart) {
//			[GameConnection post:ConnPost_BossInfo_time_setting
//						  object:[NSNumber numberWithInt:worldBossSystemInfo.stopTime]];
			
			[GameConnection post:ConnPost_BossInfo_time_setting_worldboss
						  object:[NSNumber numberWithInt:worldBossSystemInfo.stopTime]];
		}
		
		if (worldBossSystemInfo.stopTime <= 0) {
			[GameConnection post:ConnPost_WorldBoss_timeOut
						  object:nil];
			worldBossSystemInfo.isCheckStop = NO;
			worldBossStatue = SystemStatusStep_end;
		}
	}
	
	if (worldBossSystemInfo.isCheckCooling) {
		worldBossSystemInfo.combatCool._remain--;
		if (worldBossSystemInfo.combatCool._remain <= 0) {
			worldBossSystemInfo.isCheckCooling = NO;
			worldBossSystemInfo.combatCool._remain = 0 ;
			worldBossSystemInfo.combatCool._total = 0 ;
			[GameConnection post:ConnPost_worldboss_system_start_fight object:nil];
		}
	}
	
}
+(BOOL)checkCanEnter{
	NSDictionary *dict = [[GameDB shared] getGlobalConfig];
	if (dict) {
		int enterLevel = [[dict objectForKey:@"enterBossLevel"] intValue];
		int playerLevel = [[GameConfigure shared] getPlayerLevel];
		if (playerLevel >= enterLevel){
			return YES;
		}
	}
	return NO;
}
+(void)enterWorldBoss{
	
	if (![WorldBossManager checkCanEnter]) {
		//[ShowItem showItemAct:@"未到达开放等级，请继续努力升级"];
        [ShowItem showItemAct:NSLocalizedString(@"world_boss_low_level_no_open",nil)];
		return ;
	}
	
	if(worldBossStatue == SystemStatusStep_waitting ||
	   worldBossStatue == SystemStatusStep_running){
		
		[MovingAlert remove];
		[[WorldBossManager shared] start];
		
	}else{
		
		if([MapManager shared].mapType==Map_Type_WorldBoss){
			[WorldBossManager quitWorldBoss];
		}else{
			[WorldBossManager removeWorldBoss];
		}
	}
}

+(void)removeWorldBoss{
	//停止移动
	[[RoleManager shared].player stopMoveAndTask];
	if(s_WorldBossManager){
		[NSTimer cancelPreviousPerformRequestsWithTarget:s_WorldBossManager];
		[s_WorldBossManager removeFromParentAndCleanup:YES];
		[s_WorldBossManager release];
		s_WorldBossManager = nil;
	}
}

+(void)quitWorldBoss{
	
	[WorldBossManager removeWorldBoss];
	[WorldBossManager removeWorldBossBuffs];
	
	[[RoleManager shared] otherPlayerVisible:YES];
	
	if ([MapManager shared].mapType==Map_Type_WorldBoss) {
		[[Game shared] backToMap:nil call:nil];
	}
}

+(void)checkStatus{
	if([MapManager shared].mapType==Map_Type_WorldBoss){
		if(s_WorldBossManager != nil){
			[s_WorldBossManager checkRestart];
		}else{
			[WorldBossManager enterWorldBoss];
		}
	}else{
		[WorldBossManager removeWorldBoss];
	}
}

+(CGPoint)getObjectPosition:(NSString*)_key{
	
	if (_key == nil) {
		return CGPointZero;
	}
	
	NSMutableArray *array = [NSMutableArray arrayWithArray:[[MapManager shared] getFunctionRect:@"object" key:_key]];
	
	if (array != nil && array.count > 0) {
		CGPoint point = getTiledRectCenterPoint([[array objectAtIndex:0] CGRectValue]);
		return point ;
	}
	return CGPointZero;
}

+(BOOL)checkWorldBossTouch{
	if (s_WorldBossManager == nil) {
		return YES;
	}
	CGPoint pt1 = [WorldBossManager getObjectPosition:@"boss"];
	if (pt1.x == 0 && pt1.y == 0) {
		return YES;
	}
	if (worldBossStatue != SystemStatusStep_running) {
		return YES ;
	}
	if ([MapManager shared].mapType != Map_Type_WorldBoss) {
		return YES;
	}
	float dis = [[RoleManager shared] getPointDistanceWithPlayer:pt1];
	
	return (dis > 30);
}

+(BOOL)checkFightSelector{
	if ([FightManager isFighting] && [FightManager getFightType] == Fight_Type_bossFight) {
		CCLOG(@"FightManager Fight_Type_bossFight isFighting");
		return YES;
	}
	return NO;
}

-(void)start{
	if(worldBossStatue == SystemStatusStep_waitting ||
	   worldBossStatue == SystemStatusStep_running){
		[GameConnection request:@"bossEnter" format:@""
						 target:self call:@selector(didStart:)];
	}
}

-(void)didStart:(NSDictionary*)_sender{
	if(checkResponseStatus(_sender)){
		NSDictionary * data = getResponseData(_sender);
		
		worldBossSystemInfo.stopTime = [[data objectForKey:@"eTime"] intValue];
		
		if(worldBossSystemInfo.stopTime > 0){
			worldBossSystemInfo.isCheckStop = YES;
		}
		
		int blid = [[data objectForKey:@"blid"] intValue];
		
		if(blid>0){
			NSDictionary * bossLevelInfo = [[GameDB shared] getBossLevelInfoBydId:blid];
			worldBossInfo.bossId = [[bossLevelInfo objectForKey:@"mid"] intValue];
			worldBossInfo.bossLevel = [[bossLevelInfo objectForKey:@"level"] intValue];
		}
		
		worldBossInfo.bossHP = [[data objectForKey:@"hp"] intValue];
		worldBossInfo.bossTotalHP = [[data objectForKey:@"mhp"] intValue];
		
		NSDictionary* bDict = [data objectForKey:@"buff"];
		[WorldBossManager addWorldBossBuffs:bDict];
		
		[self enterMap];
		
	}else{
		if([MapManager shared].mapId == WorldBoss_map){
			[WorldBossManager quitWorldBoss];
		}
	}
}

-(void)enterMap{
	if([MapManager shared].mapId == WorldBoss_map){
		[self checkRestart];
	}else{
		[[Game shared] trunToMap:WorldBoss_map target:nil call:nil];
	}
}

-(void)checkRestart{
	if(!self.parent){
		//[[GameUI shared] addChild:self z:-1];
		self.visible = YES ;
		[[GameUI shared] addChild:self z:-1 tag:GameUi_SpecialSystem_worldBoss];
	}
}

-(void)menuEvent:(CCSimpleButton*)_sender{
	if (_sender.tag == 555) {
		//tod 返回
		
		if((iPhoneRuningOnGame() && [[Window shared] isHasWindow])){
			return;
		}
		
		if (![WorldBossManager checkWorldBossTouch]) {
			return ;
		}
		
		[GameConnection request:@"bossExit" format:@"" target:nil call:nil];
		[WorldBossManager quitWorldBoss];
		
	}
	
//	if (_sender.tag == 556) {
//		//tod 帮助
//	}
	
	if (_sender.tag == 557) {
		//tod 隐藏
		BOOL _b = [[RoleManager shared] isOtherPlayerVisible];
		[[RoleManager shared] otherPlayerVisible:!_b];
	}
}

-(void)showSystemMenu{
	
	[self removeChildByTag:555 cleanup:YES];
	[self removeChildByTag:556 cleanup:YES];
	[self removeChildByTag:557 cleanup:YES];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	
	CCSimpleButton* bt1 = [CCSimpleButton spriteWithFile:@"images/ui/worldboss/bt_back.png"];
	bt1.target = self;
	bt1.call = @selector(menuEvent:);
	bt1.tag = 555 ;
	
//	CCSimpleButton* bt2 = [CCSimpleButton spriteWithFile:@"images/ui/worldboss/bt_help.png"];
//	bt2.target = self;
//	bt2.call = @selector(menuEvent:);
//	bt2.tag = 556 ;
    //fix chao
    RuleButton *bt2 = [RuleButton node];
    if (iPhoneRuningOnGame()) {
        bt2.scale = 1.19;
    }
    bt2.type = RuleType_mainFight;
    bt2.priority = -129;
    bt2.tag = 556 ;
    //end
    
	CCSimpleButton* bt3 = [CCSimpleButton spriteWithFile:@"images/ui/worldboss/bt_hide.png"];
	bt3.target = self;
	bt3.call = @selector(menuEvent:);
	bt3.tag = 557 ;
	
	bt1.position = ccp(winSize.width-bt1.contentSize.width/2 - cFixedScale(20),winSize.height-cFixedScale(25));
	//bt2.position = ccp(bt1.position.x - bt2.contentSize.width ,winSize.height-cFixedScale(25));
    bt2.position = ccp(bt1.position.x - bt1.contentSize.width ,winSize.height-cFixedScale(25));
	bt3.position = ccp(bt2.position.x - bt3.contentSize.width,winSize.height-cFixedScale(25));
	
	[self addChild:bt1 z:2];
	[self addChild:bt2 z:2];
	[self addChild:bt3 z:2];
	
}

-(void)showUi{
	
	CGSize size = [CCDirector sharedDirector].winSize;
	
	if (_bossInfo == nil) {
//		_bossInfo = [BossInfo node];
		_bossInfo = [BossInfo create:BossInfoType_world];
		[self addChild:_bossInfo z:1];
		
		_bossInfo.position = ccp(_bossInfo.contentSize.width/2 +cFixedScale(20),
								 size.height - _bossInfo.contentSize.height/2);
		
		_bossInfo.bossId = worldBossInfo.bossId;
		_bossInfo.maxHp = worldBossInfo.bossTotalHP;
		_bossInfo.curHp = worldBossInfo.bossHP;
		_bossInfo.hurt = worldBossInfo.bossHP;
		
	}
	
	if (_bossBank == nil) {
		_bossBank = [BossRank node];
		[self addChild:_bossBank z:1];
		
		float __x = size.width - _bossBank.contentSize.width/2 - cFixedScale(20);
		float __y = size.height/6*4;
		_bossBank.position = ccp(__x, __y);
		
	}
	
	if (_bossAction == nil) {
		_bossAction = [BossAction node];
		[self addChild:_bossAction z:2];
		
		float __x = size.width/2;
		float __y = size.height - cFixedScale(160);
		_bossAction.position = ccp(__x, __y);
		
	}
	
	//todo 暂时取消
	/*
	if (_bossBuff == nil) {
		_bossBuff = [BossBuff node];
		[self addChild:_bossBuff z:2];
		
		_bossBuff.target = self;
		_bossBuff.call = @selector(doBossAddBuff);
		
		float __x = size.width/2;
		float __y =  cFixedScale(160);
		_bossBuff.position = ccp(__x, __y);
	}*/
}

-(void)freeUi{
	if (_bossInfo) {
		[_bossInfo removeFromParentAndCleanup:YES];
		_bossInfo = nil ;
	}
	if (_bossBank) {
		[_bossBank removeFromParentAndCleanup:YES];
		_bossBank = nil ;
	}
	
	if (_bossAction) {
		[_bossAction removeFromParentAndCleanup:YES];
		_bossAction = nil;
	}
	
	if (_bossBuff) {
		[_bossBuff removeFromParentAndCleanup:YES];
		_bossBuff = nil;
	}
	
}

-(void)updateAction{
	if (worldBossStatue == SystemStatusStep_waitting) {
		[self bossAction_waitting];
	}
	
	if (worldBossStatue == SystemStatusStep_running) {
		
		if (worldBossSystemInfo.isCheckCooling) {
			[self bossAction_cooling];
		}else{
			[self bossAction_fightting];
		}
		
	}
}

-(void)bossAction_fightting{
	if (_bossAction) {
		CCLOG(@"bossAction_fightting");
		[self removeFire];
		_bossAction.type = BossAction_fight;
	}
}
-(void)bossAction_cooling{
	if (_bossAction) {
		CCLOG(@"bossAction_cooling");
		[self showFiveAnimation];
		_bossAction.type = BossAction_fightCd;
		_bossAction.stopTime = worldBossSystemInfo.combatCool._remain;
	}
}
-(void)bossAction_waitting{
	if (_bossAction) {
		CCLOG(@"bossAction_waitting");
		[self showFiveAnimation];
		_bossAction.type = BossAction_wait;
	}
}

-(void)updateData:(NSNotification*)notification{
	NSDictionary * data = notification.object;
	
	if([notification.name isEqualToString:ConnPost_WorldBoss_Hurts]){
		worldBossInfo.bossHP = [[data objectForKey:@"hp"] intValue];
		if (_bossInfo != nil) {
			[_bossInfo setHurt:worldBossInfo.bossHP];
		}
	}
	
	if([notification.name isEqualToString:ConnPost_WorldBoss_Rank]){
		
		NSArray * hurts = [NSArray arrayWithArray:[data objectForKey:@"hurts"]];
		NSArray * names = [NSArray arrayWithArray:[data objectForKey:@"names"]];
		
		if (hurts != nil && names != nil) {
			if (_bossBank != nil) {
				[_bossBank updateRank:names :hurts hp:worldBossInfo.bossTotalHP];
			}
		}
		
	}
	
}

-(void)onEnter{
	[super onEnter];
	
	[self freeUi];
	
	[self showUi];
	[self showSystemMenu];
	[self showBossAnimation];
	[self updateAction];
	
	//通知开始战斗
	[GameConnection addPost:ConnPost_worldboss_system_start_fight
					 target:self
					   call:@selector(bossAction_fightting)];
	
	
	//通知冷却时间结束
	[GameConnection addPost:BossAction_start_over_cd
					 target:self
					   call:@selector(startOverCombatCool)];
	
	//绘制BOSS伤害
	[GameConnection addPost:ConnPost_WorldBoss_Hurts
					 target:self
					   call:@selector(updateData:)];
	//绘制BOSS伤害排行榜
	[GameConnection addPost:ConnPost_WorldBoss_Rank
					 target:self
					   call:@selector(updateData:)];
	//开始战斗
	[GameConnection addPost:BossAction_start_fight
					 target:self
					   call:@selector(startFightWorldBoss)];
	
	[GameConnection addPost:ConnPost_WorldBoss_timeOut
					 target:self
					   call:@selector(endSystem)];
	
	[GameConnection addPost:ConnPost_worldboss_die
					 target:self
					   call:@selector(endSystem)];
	
	//检测 是不是 在冷却中
	if (isNewWorldBossSystem) {
		//?????
		[self checkCombatCool];
		isNewWorldBossSystem = NO;
	}
}

-(void)onExit{
	
	[GameConnection removePostTarget:self];
	[self freeUi];
	[self removeBossAnimation];
	[self removeFire];
	//[GameConnection freeRequest:self];
	[super onExit];
}

-(void)endSystem{
	if ([WorldBossManager checkFightSelector]) {
		return ;
	}
	if (isWaitNet) {
		return ;
	}
	[NSTimer scheduledTimerWithTimeInterval:1.0f
									 target:[WorldBossManager class]
								   selector:@selector(quitWorldBoss)
								   userInfo:nil
									repeats:NO];
}

-(void)startCombatCool:(int)_t1 time:(int)_t2{
	worldBossSystemInfo.combatCool._remain = _t1;
	worldBossSystemInfo.combatCool._total = _t2;
	if (_t1 > 0 && _t2 > 0) {
		worldBossSystemInfo.isCheckCooling = YES;
		[self bossAction_cooling];
	}
}

-(void)checkCombatCool{
	[GameConnection request:@"bossCdTimes"
					 format:@""
					 target:self
					   call:@selector(endCheckCombatCool:)];
}

-(void)endCheckCombatCool:(NSDictionary*)_sender{
	if (checkResponseStatus(_sender)) {
		NSDictionary* data = getResponseData(_sender);
		int time1 = [[data objectForKey:@"times"] intValue];
		int time2 = [[data objectForKey:@"mtimes"] intValue];
		[self startCombatCool:time1 time:time2];
	}
}

-(void)showBossAnimation{
	[[[GameLayer shared] content] removeChildByTag:8888 cleanup:YES];
	Monster* monster = [Monster getMonster:worldBossInfo.bossId
									 point:[WorldBossManager getObjectPosition:@"boss"]];
	monster.type = MONSTER_TYPE_BOSS;
	monster.tag = 8888 ;
	monster.zOrder = -1;
}

-(void)removeBossAnimation{
	[[[GameLayer shared] content] removeChildByTag:8888 cleanup:YES];
}

-(void)removeFire{
	[[[GameLayer shared] content] removeChildByTag:656456 cleanup:YES];
}

-(void)showFiveAnimation{
	[self removeFire];
	AnimationViewer *ani = [AnimationViewer node];
	ani.tag = 656456;
	ani.anchorPoint = ccp(0.5, 0.5);
	CGPoint pt =[WorldBossManager getObjectPosition:@"firewall"] ;
	ani.position= pt ;
	[[[GameLayer shared] content] addChild:ani z:0];
	
	ani.scale = 2.0f;
	[ani showAnimationByPath:@"images/animations/fire/%d.png"];
	
}

-(void)startFightWorldBoss{
	CCLOG(@"startFightWorldBoss");
	if (worldBossStatue != SystemStatusStep_running) {
		return ;
	}
	
	CGPoint pt = [WorldBossManager getObjectPosition:@"boss"];
	if (pt.x != 0 && pt.y != 0) {
		
		[[[GameLayer shared] content] removeChildByTag:65645 cleanup:YES];
		[[RoleManager shared].player moveTo:pt target:self call:@selector(didStartFightWorldBoss)];
		
	}
}
-(void)didStartFightWorldBoss{
	
	if (worldBossStatue != SystemStatusStep_running) {
		return ;
	}
	
	if (worldBossSystemInfo.isCheckCooling) {
		return ;
	}
	
	if (worldBossInfo.bossHP > 0) {
		[GameConnection request:@"bossStart" format:@"" target:nil call:nil];
		
		NSMutableDictionary* dict = [NSMutableDictionary dictionary];
		[dict setObject:@"sysbossfight" forKey:@"bg"];
		[dict setObject:[NSNumber numberWithInt:worldBossInfo.bossId] forKey:@"mid"];
		[dict setObject:[NSNumber numberWithInt:worldBossInfo.bossLevel] forKey:@"level"];
		[dict setObject:[NSNumber numberWithInt:worldBossInfo.bossHP] forKey:@"curHp"];
		
		//战斗添加BUFF
		if (buffers) {
			[dict setObject:[NSDictionary dictionaryWithDictionary:buffers] forKey:@"buff"];
		}
		
		worldBoss_hp = worldBossInfo.bossHP;
		
		//如果战斗系统还没开始的话 就开始
		if (![FightManager isFighting]) {
			[[FightManager shared] startFightBoss:dict target:self call:@selector(endFightWorldBoss)];
		}
	}
}
-(void)endFightWorldBoss{
	
	[[RoleManager shared] movePlayerToStartPoint];
	
	if (worldBossStatue == SystemStatusStep_running) {
		
		int	_value = [[FightManager shared] getTargetDamage:worldBossInfo.bossId];//当前的伤害
		//_value = worldBoss_hp - abs(_value);
		
		//todo for test
#if WorldBossManager_debug == 1
		[self debug_showHurt:_value];
#endif
		
		isWaitNet = YES ;
		NSString* _str = nil ;
		
		//todo send Fighting in to server!
		float percent = (float)_value/(float)worldBossInfo.bossTotalHP;
		if (percent > 0.1f) { //0.1*100% = 10%
			//TODO send data
			_str = [NSString stringWithFormat:@"hurt::%d|news:%@",_value,[[FightManager shared] getFigthSub]];
		}else{
			_str = [NSString stringWithFormat:@"hurt::%d",_value];
		}
		//
		worldBoss_hurt_single = _value ;
		[GameConnection request:@"bossFinish" format:_str
						 target:self call:@selector(didFinishWorldBoss:)];
		
	}else if(worldBossStatue == SystemStatusStep_end){
		//战斗中 BOSS死了
		//[self endSystem];
		[WorldBossManager quitWorldBoss];
	}
}
-(void)didFinishWorldBoss:(NSDictionary*)_sender{
	if (worldBossStatue == SystemStatusStep_running) {
		if(checkResponseStatus(_sender)){
			NSDictionary * data = getResponseData(_sender);
			//int lastHurt = worldBoss_hurt;
			
			isWaitNet = NO ;
			worldBoss_hurt = [[data objectForKey:@"hurt"] intValue];
			//int _value = worldBoss_hurt - lastHurt;
			int _value = worldBoss_hurt_single ;//worldBoss_hurt - lastHurt;
			
			if ((worldBossInfo.bossHP - _value) <= 0) {
				
				[WorldBossManager quitWorldBoss];
				
			}else{
				
				NSArray * hurts = [NSArray arrayWithArray:[data objectForKey:@"hurts"]];
				NSArray * names = [NSArray arrayWithArray:[data objectForKey:@"names"]];
				
				if (worldBossStatue == SystemStatusStep_running) {
					int _cool = getCombatCool(_value);
					if (_cool > 0) {
						[self startCombatCool:_cool time:_cool];
					}
				}
				
				if (hurts != nil && names != nil) {
					if (_bossBank != nil) {
						[_bossBank updateRank:names :hurts hp:worldBossInfo.bossHP];
					}
				}
				
				if (worldBoss_hurt > 0) {
					float _rate = (float)worldBoss_hurt/(float)worldBossInfo.bossTotalHP;
					if (_bossBank != nil) {
						[_bossBank updatePlayerHurt:_rate hurt:worldBoss_hurt];
					}
				}else{
					if (_bossBank != nil) {
						[_bossBank updatePlayerHurt:0.0f hurt:worldBoss_hurt];
					}
				}
				
			}
		}else{
			[WorldBossManager quitWorldBoss];
		}
	}else if (worldBossStatue == SystemStatusStep_end){
		//[self endSystem];
		[WorldBossManager quitWorldBoss];
	}

}
-(void)startOverCombatCool{
	
	if (worldBossSystemInfo.isCheckCooling) {
		
		if ([self getChildByTag:878798]) {
			return ;
		}
		
		if (isNetting) {
			return ;
		}
		
		isNetting = YES;
		
		NSDictionary* dict = [[GameDB shared] getGlobalConfig];
		int _value = [[dict objectForKey:@"bossCdCoin2"] intValue];
		
		_value = worldBossSystemInfo.combatCool._total*_value;
		
		//NSString* tips = [NSString stringWithFormat:@"是否花费(%d)元宝购买加速？",_value];
        NSString* tips = [NSString stringWithFormat:NSLocalizedString(@"world_boss_spend",nil),_value];
		
		MessageAlert *alert = [MessageAlert node];
		alert.message=tips;
		alert.target=self;
		alert.call=@selector(runOverCombatCool);
		alert.canel=@selector(canelOverCombatCool);
		alert.isUrgent = YES ;
		alert.type=MessageAlert_all;
		[self addChild:alert z:INT32_MAX tag:878798];
		alert.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
	}
}
-(void)runOverCombatCool{
	if (!worldBossSystemInfo.isCheckCooling) {
		isNetting = NO;
		return ;
	}
	isNetting = YES;
	[GameConnection request:@"bossCdEnd" format:@""
					 target:self call:@selector(endRunOverCombatCool:)];
}

-(void)endRunOverCombatCool:(NSDictionary*)_sender{
	isNetting = NO;
	if (checkResponseStatus(_sender)) {
		NSDictionary* result = getResponseData(_sender);
		
		NSDictionary* data = [result objectForKey:@"update"];
		NSDictionary* bDict = [result objectForKey:@"buff"];
		
		[WorldBossManager updataWorldBossBuffs:bDict];
		
		
		if (data) {
            NSArray *updateData = [[GameConfigure shared] getPackageAddData:data type:PackageItem_all];
            [[AlertManager shared] showReceiveItemWithArray:updateData];
            [[GameConfigure shared] updatePackage:data];
        }
		//[[GameConfigure shared] updatePackage:data];
		
		worldBossSystemInfo.combatCool._remain = 0 ;
		//
        [ShowItem showItemAct:NSLocalizedString(@"boss_deduct_ok",nil)];
        //
		[self showBuffTips];
		
	}else{
		[ShowItem showErrorAct:getResponseMessage(_sender)];
	}
}
-(void)canelOverCombatCool{
	isNetting = NO;
	[self removeChildByTag:878798];
}

-(void)showBuffTips{
}

-(void)doBossAddBuff{
	
	NSDictionary* dict = [[GameDB shared] getGlobalConfig];
	int bossBuffCoin2 = [[dict objectForKey:@"bossBuffCoin2"] intValue];
	
	NSString* tips = [NSString stringWithFormat:NSLocalizedString(@"world_boss_buff",nil),bossBuffCoin2];
	
	MessageAlert *alert = [MessageAlert node];
	alert.message=tips;
	alert.target=self;
	alert.call=@selector(runDoBossAddBuff);
	alert.canel=@selector(canelDoBossAddBuff);
	alert.isUrgent = YES ;
	alert.type=MessageAlert_all;
	[self addChild:alert z:INT32_MAX tag:456657];
	alert.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
}

-(void)runDoBossAddBuff{
	isNetting = YES;
	[GameConnection request:@"bossAddBuff" format:@""
					 target:self call:@selector(endBossAddBuff:)];
}

-(void)canelDoBossAddBuff{
	isNetting = NO;
	[self removeChildByTag:456657];
}

-(void)endBossAddBuff:(NSDictionary*)sender{
	isNetting = NO;
	if (checkResponseStatus(sender)) {
		NSDictionary* dict = getResponseData(sender);
		dict = [dict objectForKey:@"buff"];
		[WorldBossManager updataWorldBossBuffs:dict];
	}
}

-(void)debug_showHurt:(int)_value{
	CCLabelTTF *tipsLabel = (CCLabelTTF*)[self getChildByTag:54364364];
	if (tipsLabel == nil) {
		tipsLabel = [CCLabelTTF labelWithString:@""
									   fontName:@"Helvetica-Bold"
									   fontSize:28 dimensions:CGSizeMake(260, 100)
									 hAlignment:kCCTextAlignmentLeft];
		CGSize size = [CCDirector sharedDirector].winSize ;
		tipsLabel.anchorPoint = ccp(1.0, 0);
		tipsLabel.position = ccp(size.width, 0);
		[self addChild:tipsLabel z:INT32_MAX tag:54364364];
	}
	tipsLabel.string = [NSString stringWithFormat:@"上次伤害：%d",_value];
}

@end

