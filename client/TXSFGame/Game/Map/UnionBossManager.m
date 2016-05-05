//
//  UnionBossManager.m
//  TXSFGame
//
//  Created by Soul on 13-4-6.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionBossManager.h"
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
#import "InfoAlert.h"


#define UnionBossManager_debug 0

#define UNION_MAP	1006

#define ConnPost_system_start_fight @"ConnPost_system_start_fight"
#define ConnPost_system_start_fight_cool @"ConnPost_system_start_fight_cool"
#define ConnPost_allyboss_die @"ConnPost_allyboss_die"

@implementation UnionBossManager

static UnionBossManager* s_UnionBossManager = nil;

static BOOL isSetEvent = NO;
static BOOL isNewSystem = YES;
static BOOL isWaitSocket = NO ;

static BOOL isAsking = NO;

static NSTimer * s_SystemTimer = nil;

static SystemStatusStep	allyBossStatue = SystemStatusStep_none;
static SystemStatusInfo allyBossSystemInfo;
static BossData allyBossInfo;

static int hp_record = 0 ;
static int hurt_record = 0;
static int hurt_record_single = 0;
//
static NSTimeInterval s_allyBossStopTime = 0.0f;

+(void)enterBackground{
    s_allyBossStopTime = [[NSDate date] timeIntervalSince1970];
}

+(void)enterForeground{
    NSTimeInterval t_time = [[NSDate date] timeIntervalSince1970] - s_allyBossStopTime;
    
    if (allyBossSystemInfo.isCheckStart) {
        allyBossSystemInfo.startTime -= t_time;
        if(allyBossSystemInfo.startTime<0){
            allyBossSystemInfo.startTime = 0;
        }
    }
    if (allyBossSystemInfo.isCheckStop) {
        allyBossSystemInfo.stopTime -= t_time;
        if(allyBossSystemInfo.stopTime<0){
            allyBossSystemInfo.stopTime = 0;
        }
    }
    if (allyBossSystemInfo.isCheckCooling) {
        allyBossSystemInfo.combatCool._remain -= t_time;
        if(allyBossSystemInfo.combatCool._remain<0){
            allyBossSystemInfo.combatCool._remain = 0;
        }
    }
}

+(UnionBossManager*)shared{
	if(s_UnionBossManager==nil){
		s_UnionBossManager = [UnionBossManager node];
		[s_UnionBossManager retain];
	}
	return s_UnionBossManager ;
}

+(void)startAll{
	
	allyBossInfo = BossDataZero();
	allyBossSystemInfo = SystemStatusInfoZero();
	isNewSystem = YES;
	isAsking = NO;
	
	[UnionBossManager addEvent];
	
}

+(void)stopAll{
	
	if(s_UnionBossManager){
		[NSTimer cancelPreviousPerformRequestsWithTarget:s_UnionBossManager];
		[s_UnionBossManager removeFromParentAndCleanup:YES];
		[s_UnionBossManager release];
		s_UnionBossManager = nil;
	}
	
	[UnionBossManager removeEvent];
	
	allyBossInfo = BossDataZero();
	allyBossSystemInfo = SystemStatusInfoZero();
	
}

+(void)addEvent{
	if(isSetEvent) return;
	isSetEvent = YES;
	
	id target = [UnionBossManager class];
	SEL call = @selector(acceptPost:);
	
	[GameConnection addPost:ConnPost_allyBossRank_Start target:target call:call];
	[GameConnection addPost:ConnPost_allyBossRank_Hurts target:target call:call];
	[GameConnection addPost:ConnPost_allyBossRank_Rank target:target call:call];
    //
    [GameConnection addPost:ConnPost_gameEnterBackground target:target call:@selector(enterBackground)];
    [GameConnection addPost:ConnPost_gameEnterForeground target:target call:@selector(enterForeground)];
    
	s_SystemTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
													 target:[UnionBossManager class]
												   selector:@selector(checkSystemTime)
												   userInfo:nil
													repeats:YES];
}

+(void)removeEvent{
	[GameConnection removePostTarget:[UnionBossManager class]];
	isSetEvent = NO;
	//
    s_allyBossStopTime = 0.0f;
    
	if(s_SystemTimer){
		[s_SystemTimer invalidate];
		s_SystemTimer = nil;
	}
}

+(void)acceptPost:(NSNotification*)notification{
	NSDictionary * data = notification.object;
	
	if([notification.name isEqualToString:ConnPost_allyBossRank_Start]){
		allyBossSystemInfo.startTime = [[data objectForKey:@"times"] intValue];
		if(allyBossSystemInfo.startTime > 0){
			allyBossSystemInfo.isCheckStart = YES;
			allyBossStatue = SystemStatusStep_waitting;
		}else{
			allyBossSystemInfo.startTime = 0;
			allyBossSystemInfo.isCheckStart = NO;
			allyBossStatue = SystemStatusStep_running;
		}
	}
	
	if([notification.name isEqualToString:ConnPost_allyBossRank_Hurts]){
		allyBossInfo.bossHP = [[data objectForKey:@"hp"] intValue];
		
		if (allyBossInfo.bossHP <= 0) {
			allyBossStatue = SystemStatusStep_end;
			[GameConnection post:ConnPost_allyboss_die
						  object:nil];
		}
		
	}
	
	if([notification.name isEqualToString:ConnPost_allyBossRank_Rank]){
	}
	
}

+(void)checkSystemTime{
	
	if (allyBossSystemInfo.isCheckStart) {
		allyBossSystemInfo.startTime--;
//		[GameConnection post:ConnPost_BossInfo_time_setting
//					  object:[NSNumber numberWithInt:(allyBossSystemInfo.startTime*-1)]];
		
		[GameConnection post:ConnPost_BossInfo_time_setting_unionboss
					  object:[NSNumber numberWithInt:(allyBossSystemInfo.startTime*-1)]];
		
		if (allyBossSystemInfo.startTime <= 0) {
			allyBossSystemInfo.isCheckStart = NO;
			allyBossStatue = SystemStatusStep_running;
			[GameConnection post:ConnPost_system_start_fight object:nil];
		}
	}
	
	if (allyBossSystemInfo.isCheckStop) {
		allyBossSystemInfo.stopTime--;
		
		if (!allyBossSystemInfo.isCheckStart) {
//			[GameConnection post:ConnPost_BossInfo_time_setting
//						  object:[NSNumber numberWithInt:allyBossSystemInfo.stopTime]];
			[GameConnection post:ConnPost_BossInfo_time_setting_unionboss
						  object:[NSNumber numberWithInt:allyBossSystemInfo.stopTime]];
		}
		
		if (allyBossSystemInfo.stopTime <= 0) {
			
			[GameConnection post:ConnPost_allyBoss_timeOut
						  object:nil];
			
			allyBossSystemInfo.isCheckStop = NO;
			allyBossStatue = SystemStatusStep_end;
		}
	}
	
	if (allyBossSystemInfo.isCheckCooling) {
		allyBossSystemInfo.combatCool._remain--;
		if (allyBossSystemInfo.combatCool._remain <= 0) {
			allyBossSystemInfo.isCheckCooling = NO;
			allyBossSystemInfo.combatCool._remain = 0 ;
			allyBossSystemInfo.combatCool._total = 0 ;
			[GameConnection post:ConnPost_system_start_fight object:nil];
		}
	}
	
}

+(void)enterUnionBoss{
	if(allyBossStatue == SystemStatusStep_waitting ||
	   allyBossStatue == SystemStatusStep_running){
		
		[MovingAlert remove];
		[[UnionBossManager shared] start];
		
	}else{
		if([MapManager shared].mapType==Map_Type_UnionBoss){
			[UnionBossManager quitUnionBoss];
		}else{
			[UnionBossManager removeUnionBoss];
		}
	}
}

+(void)removeUnionBoss{
	[[RoleManager shared].player stopMoveAndTask];
	if(s_UnionBossManager){
		[NSTimer cancelPreviousPerformRequestsWithTarget:s_UnionBossManager];
		[s_UnionBossManager removeFromParentAndCleanup:YES];
		[s_UnionBossManager release];
		s_UnionBossManager = nil;
	}
}

+(void)quitUnionBoss{
	
	[UnionBossManager removeUnionBoss];
	[[RoleManager shared] otherPlayerVisible:YES];
	
	if ([MapManager shared].mapType==Map_Type_UnionBoss) {
		[[Game shared] backToMap:nil call:nil];
	}
}

+(void)checkStatus{
	if([MapManager shared].mapType==Map_Type_UnionBoss){
		if(s_UnionBossManager != nil){
			[s_UnionBossManager checkRestart];
		}else{
			[UnionBossManager enterUnionBoss];
		}
	}else{
		[UnionBossManager removeUnionBoss];
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

+(BOOL)checkAllyBossTouch{
	if (s_UnionBossManager == nil) {
		return YES;
	}
	CGPoint pt1 = [UnionBossManager getObjectPosition:@"boss"];
	if (pt1.x == 0 && pt1.y == 0) {
		return YES;
	}
	if (allyBossStatue != SystemStatusStep_running) {
		return YES ;
	}
	if ([MapManager shared].mapType != Map_Type_UnionBoss) {
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

//______________________________________________________________________________
// instance!!
//______________________________________________________________________________
-(void)start{
	if(allyBossStatue == SystemStatusStep_waitting ||
	   allyBossStatue == SystemStatusStep_running){
		[GameConnection request:@"allyBossEnter" format:@""
						 target:self call:@selector(didStart:)];
	}
}

-(void)didStart:(NSDictionary*)_sender{
	if(checkResponseStatus(_sender)){
		NSDictionary * data = getResponseData(_sender);
		
		allyBossSystemInfo.stopTime = [[data objectForKey:@"eTime"] intValue];
		
		if(allyBossSystemInfo.stopTime > 0){
			allyBossSystemInfo.isCheckStop = YES;
		}
		
		int blid = [[data objectForKey:@"blid"] intValue];
		
		if(blid>0){
			NSDictionary * bossLevelInfo = [[GameDB shared] getBossLevelInfoBydId:blid];
			allyBossInfo.bossId = [[bossLevelInfo objectForKey:@"mid"] intValue];
			allyBossInfo.bossLevel = [[bossLevelInfo objectForKey:@"level"] intValue];
		}
		
		allyBossInfo.bossHP = [[data objectForKey:@"hp"] intValue];
		allyBossInfo.bossTotalHP = [[data objectForKey:@"mhp"] intValue];
		
		[self enterMap];
		
	}else{
		if([MapManager shared].mapId == UNION_MAP){
			[UnionBossManager quitUnionBoss];
		}
	}
}

-(void)enterMap{
	if([MapManager shared].mapId == UNION_MAP){
		[self checkRestart];
	}else{
		[[Game shared] trunToMap:UNION_MAP target:nil call:nil];
	}
}

-(void)checkRestart{
	if(!self.parent){
		//[[GameUI shared] addChild:self z:-1];
		self.visible = YES ;
		[[GameUI shared] addChild:self z:-1 tag:GameUi_SpecialSystem_unionBoss];
	}
}

-(void)menuEvent:(CCSimpleButton*)_sender{
	if (_sender.tag == 555) {
		//tod 返回
		if((iPhoneRuningOnGame() && [[Window shared] isHasWindow])){
			return;
		}
		
		if (![UnionBossManager checkAllyBossTouch]) {
			return ;
		}
		
		[GameConnection request:@"allyBossExit" format:@"" target:nil call:nil];
		[UnionBossManager quitUnionBoss];
	}
	
	if (_sender.tag == 556) {
		//tod 帮助
	}
	
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
    bt2.type = RuleType_unoinBoss;
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
		_bossInfo = [BossInfo create:BossInfoType_union];
		[self addChild:_bossInfo z:1];
		
		_bossInfo.position = ccp(_bossInfo.contentSize.width/2 +cFixedScale(20),
								 size.height - _bossInfo.contentSize.height/2);
		
		_bossInfo.bossId = allyBossInfo.bossId;
		_bossInfo.maxHp = allyBossInfo.bossTotalHP;
		_bossInfo.curHp = allyBossInfo.bossHP;
		_bossInfo.hurt = allyBossInfo.bossHP;
		
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
}

-(void)updateAction{
	if (allyBossStatue == SystemStatusStep_waitting) {
		[self bossAction_waitting];
	}
	
	if (allyBossStatue == SystemStatusStep_running) {
		
		if (allyBossSystemInfo.isCheckCooling) {
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
		_bossAction.stopTime = allyBossSystemInfo.combatCool._remain;
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
	
	if([notification.name isEqualToString:ConnPost_allyBossRank_Hurts]){
		allyBossInfo.bossHP = [[data objectForKey:@"hp"] intValue];
		if (_bossInfo != nil) {
			[_bossInfo setHurt:allyBossInfo.bossHP];
		}
	}
	
	if([notification.name isEqualToString:ConnPost_allyBossRank_Rank]){
		
		NSArray * hurts = [NSArray arrayWithArray:[data objectForKey:@"hurts"]];
		NSArray * names = [NSArray arrayWithArray:[data objectForKey:@"names"]];
		
		if (hurts != nil && names != nil) {
			if (_bossBank != nil) {
				[_bossBank updateRank:names :hurts hp:allyBossInfo.bossTotalHP];
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
	[GameConnection addPost:ConnPost_system_start_fight
					 target:self
					   call:@selector(bossAction_fightting)];
	
	
	//通知冷却时间结束
	[GameConnection addPost:BossAction_start_over_cd
					 target:self
					   call:@selector(startOverCombatCool)];
	
	//绘制BOSS伤害
	[GameConnection addPost:ConnPost_allyBossRank_Hurts
					 target:self
					   call:@selector(updateData:)];
	//绘制BOSS伤害排行榜
	[GameConnection addPost:ConnPost_allyBossRank_Rank
					 target:self
					   call:@selector(updateData:)];
	//开始战斗
	[GameConnection addPost:BossAction_start_fight
					 target:self
					   call:@selector(startFightAllyBoss)];
	
	[GameConnection addPost:ConnPost_allyBoss_timeOut
					 target:self
					   call:@selector(endSystem)];
	
	[GameConnection addPost:ConnPost_allyboss_die
					 target:self
					   call:@selector(endSystem)];
	
	//检测 是不是 在冷却中
	if (isNewSystem) {
		//?????
		[self checkCombatCool];
		isNewSystem = NO;
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
	if ([UnionBossManager checkFightSelector]) {
		return ;
	}
	if (isWaitSocket) {
		return ;
	}
	[NSTimer scheduledTimerWithTimeInterval:1.0f
									 target:[UnionBossManager class]
								   selector:@selector(quitUnionBoss)
								   userInfo:nil
									repeats:NO];
}

-(void)startCombatCool:(int)_t1 time:(int)_t2{
	allyBossSystemInfo.combatCool._remain = _t1;
	allyBossSystemInfo.combatCool._total = _t2;
	if (_t1 > 0 && _t2 > 0) {
		allyBossSystemInfo.isCheckCooling = YES;
		[self bossAction_cooling];
	}
}

-(void)checkCombatCool{
	[GameConnection request:@"allybossCdTimes"
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
	Monster* monster = [Monster getMonster:allyBossInfo.bossId
									 point:[UnionBossManager getObjectPosition:@"boss"]];
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
	CGPoint pt =[UnionBossManager getObjectPosition:@"firewall"] ;
	ani.position= pt ;
	[[[GameLayer shared] content] addChild:ani z:0];
	
	ani.scale = 2.0f;
	[ani showAnimationByPath:@"images/animations/fire/%d.png"];
	
}

-(void)startFightAllyBoss{
	CCLOG(@"startFightBoss");
	if (allyBossStatue != SystemStatusStep_running) {
		return ;
	}
	
	CGPoint pt = [UnionBossManager getObjectPosition:@"boss"];
	if (pt.x != 0 && pt.y != 0) {
		
		[[[GameLayer shared] content] removeChildByTag:65645 cleanup:YES];
		[[RoleManager shared].player moveTo:pt target:self call:@selector(didStartFightAllyBoss)];
		
	}
}
-(void)didStartFightAllyBoss{
	
	if (allyBossStatue != SystemStatusStep_running) {
		return ;
	}
	
	if (allyBossSystemInfo.isCheckCooling) {
		return ;
	}
	
	if (allyBossInfo.bossHP > 0) {
		[GameConnection request:@"allyBossStart" format:@"" target:nil call:nil];
		
		NSMutableDictionary* dict = [NSMutableDictionary dictionary];
		[dict setObject:@"skyfight" forKey:@"bg"];
		[dict setObject:[NSNumber numberWithInt:allyBossInfo.bossId] forKey:@"mid"];
		[dict setObject:[NSNumber numberWithInt:allyBossInfo.bossLevel] forKey:@"level"];
		[dict setObject:[NSNumber numberWithInt:allyBossInfo.bossHP] forKey:@"curHp"];
		
		hp_record = allyBossInfo.bossHP;
		//如果战斗系统还没开始的话 就开始
		if (![FightManager isFighting]) {
			[[FightManager shared] startFightBoss:dict target:self call:@selector(endFightAllyBoss)];
		}
	}
}
-(void)endFightAllyBoss{
	[[RoleManager shared] movePlayerToStartPoint];
	if (allyBossStatue == SystemStatusStep_running) {
		
		int	_value = [[FightManager shared] getTargetDamage:allyBossInfo.bossId];//当前的伤害
		//int	_before = allyBossInfo.bossTotalHP - hp_record;//进战斗前的伤害
		//todo for test
#if UnionBossManager_debug == 1
		[self debug_showHurt:_value];
#endif
		//_value = hp_record - _value;
		
		/*
		 if ([FightManager isWinFight]) {
		 _value = _before ;
		 }else{
		 _value = _value - _before; //实际伤害
		 }*/
		
		isWaitSocket = YES ;
		
		hurt_record_single = _value ;
		NSString* _str = [NSString stringWithFormat:@"hurt::%d",_value];
		[GameConnection request:@"allyBossFinish" format:_str
						 target:self call:@selector(didFinishAllyBoss:)];
		
	}else if(allyBossStatue == SystemStatusStep_end){
		//战斗中 BOSS死了
		//[self endSystem];
		[UnionBossManager quitUnionBoss];
	}
}
-(void)didFinishAllyBoss:(NSDictionary*)_sender{
	if (allyBossStatue == SystemStatusStep_running) {
		if(checkResponseStatus(_sender)){
			NSDictionary * data = getResponseData(_sender);
			//int lastHurt = hurt_record;
			
			isWaitSocket = NO;
			
			hurt_record = [[data objectForKey:@"hurt"] intValue];
			int _value = hurt_record_single ;//hurt_record - lastHurt;
			
			if ((allyBossInfo.bossHP - _value) <= 0) {
				[self endSystem];
			}else{
				
				NSArray * hurts = [NSArray arrayWithArray:[data objectForKey:@"hurts"]];
				NSArray * names = [NSArray arrayWithArray:[data objectForKey:@"names"]];
				
				if (allyBossStatue == SystemStatusStep_running) {
					int _cool = getCombatCool(_value);
					if (_cool > 0) {
						[self startCombatCool:_cool time:_cool];
					}
				}
				
				if (hurts != nil && names != nil) {
					if (_bossBank != nil) {
						[_bossBank updateRank:names :hurts hp:allyBossInfo.bossHP];
					}
				}
				
				if (hurt_record > 0) {
					float _rate = (float)hurt_record/(float)allyBossInfo.bossTotalHP;
					if (_bossBank != nil) {
						[_bossBank updatePlayerHurt:_rate hurt:hurt_record];
					}
				}else{
					if (_bossBank != nil) {
						[_bossBank updatePlayerHurt:0.0f hurt:hurt_record];
					}
				}
				
			}
		}else{
			[UnionBossManager quitUnionBoss];
		}
	}else if(allyBossStatue == SystemStatusStep_end){
		//战斗中 BOSS死了
		//[self endSystem];
		[UnionBossManager quitUnionBoss];
	}
	
}
-(void)startOverCombatCool{
	CCLOG(@"startOverCombatCool");
	if (allyBossSystemInfo.isCheckCooling) {
		
		if ([self getChildByTag:878798]) {
			return ;
		}
		
		if (isAsking) {
			return ;
		}
		
		isAsking = YES;
		
		NSDictionary* dict = [[GameDB shared] getGlobalConfig];
		int _value = [[dict objectForKey:@"bossCdCoin2"] intValue];
		
		_value = allyBossSystemInfo.combatCool._total*_value;
		
		//NSString* tips = [NSString stringWithFormat:@"是否花费(%d)元宝购买加速？",_value];
        NSString* tips = [NSString stringWithFormat:NSLocalizedString(@"union_boss_spend",nil),_value];
		
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
	isAsking = YES;
	[GameConnection request:@"allybossCdEnd" format:@""
					 target:self call:@selector(endRunOverCombatCool:)];
}
-(void)endRunOverCombatCool:(NSDictionary*)_sender{
	isAsking = NO;
	if (checkResponseStatus(_sender)) {
		NSDictionary* data = getResponseData(_sender);
		
		
        if ([data objectForKey:@"update"]) {
            NSArray *updateData = [[GameConfigure shared] getPackageAddData:[data objectForKey:@"update"] type:PackageItem_all];
            [[AlertManager shared] showReceiveItemWithArray:updateData];
            [[GameConfigure shared] updatePackage:[data objectForKey:@"update"]];
        }
		//[[GameConfigure shared] updatePackage:data];
		
		allyBossSystemInfo.combatCool._remain = 0 ;
        //
        [ShowItem showItemAct:NSLocalizedString(@"union_boss_deduct_ok",nil)];
        //
	}else{
		[ShowItem showErrorAct:getResponseMessage(_sender)];
	}
}
-(void)canelOverCombatCool{
	isAsking = NO;
	[self removeChildByTag:878798];
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
