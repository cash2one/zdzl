//
//  DragonReadyManager.m
//  TXSFGame
//
//  Created by efun on 13-9-7.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonReadyManager.h"
#import "DragonReadyInfo.h"
#import "DragonStartButton.h"
#import "DragonMapNameInfo.h"
#import "DragonGloryInfo.h"
#import "DragonCannonInfo.h"
#import "DragonBookInfo.h"
#import "DragonReadyData.h"
#import "GameConnection.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "MapManager.h"
#import "GameUI.h"
#import "FightManager.h"
#import "MapManager.h"
#import "MovingAlert.h"

static DragonReadyManager* s_DragonReadyManager = nil;

@implementation DragonReadyManager

+(DragonReadyManager*)shared
{
	if (s_DragonReadyManager == nil) {
		s_DragonReadyManager = [DragonReadyManager node];
		[s_DragonReadyManager retain];
	}
	return s_DragonReadyManager;
}

+(void)startAll
{
	
}

+(void)stopAll
{
	[DragonReadyManager removeDragonReady];
}

+(BOOL)checkCanEnter
{
	// 没有相关数据
	if (![DragonReadyData checkIsReady]) {
		return NO;
	}
	
	// 玩家正在战斗
	if ([FightManager isFighting]) {
		// 如果在战斗，先设置要进入的地图
		[[MapManager shared] setTargetMapId:[DragonReadyData shared].mapId];
		return NO;
	}
	
	return YES;
}

+(void)enterDragonReady
{
	if (![DragonReadyManager checkCanEnter]) {
		return;
	}
	
	[MovingAlert remove];
	[[DragonReadyManager shared] enterMap];
}

+(void)removeDragonReady
{
	// 清除相关数据
	[DragonReadyData remove];
	
	[[RoleManager shared].player stopMoveAndTask];
	if (s_DragonReadyManager) {
		[NSTimer cancelPreviousPerformRequestsWithTarget:s_DragonReadyManager];
		[s_DragonReadyManager removeFromParent];
		[s_DragonReadyManager release];
		s_DragonReadyManager = nil;
	}
}

+(void)quitDragonReady
{
	[DragonReadyManager removeDragonReady];
	
	[[RoleManager shared] otherPlayerVisible:YES];
	
	if ([MapManager shared].mapType == Map_Type_dragonReady) {
		[[Game shared] backToMap:nil call:nil];
	}
}

+(void)checkStatus
{
	if ([MapManager shared].mapType == Map_Type_dragonReady) {
		// 有数据，可进入准备界面
		if ([DragonReadyData checkIsReady]) {
			
			if (s_DragonReadyManager != nil) {
				[s_DragonReadyManager checkRestart];
			} else {
				[DragonReadyManager enterDragonReady];
			}
			
		}
		// 无数据，返回上一个记录的地图
		else {
			[DragonReadyManager quitDragonReady];
		}
	} else {
		[DragonReadyManager removeDragonReady];
	}
}

+(void)didStartFight:(id)sender
{
	// 没有相关数据
	if (![DragonReadyData checkIsReady]) return;
	
	// 如果数据不正常，直接退出
	if (!checkResponseStatus(sender)) {
		
		[ShowItem showErrorAct:getResponseMessage(sender)];
		[DragonReadyManager quitDragonReady];
		
	}
}

-(void)enterMap
{
	int mapId = [DragonReadyData shared].mapId;
	if ([MapManager shared].mapId == mapId) {
		[self checkRestart];
	} else {
		[[Game shared] trunToMap:mapId target:nil call:nil];
	}
}

-(void)checkRestart
{
	if (self.parent == nil) {
		[[GameUI shared] addChild:self z:-1 tag:GameUi_SpecialSystem_dragonReady];
	}
}

-(void)freeUI
{
	if (_dragonReadyInfo != nil) {
		[_dragonReadyInfo removeFromParent];
		_dragonReadyInfo = nil;
	}
	if (_dragonStartButton != nil) {
		[_dragonStartButton removeFromParent];
		_dragonStartButton = nil;
	}
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
}

-(void)showUI
{
	CGSize winSize = [CCDirector sharedDirector].winSize;
	
	DragonType _dragonType = [DragonReadyData shared].dragonType;
	DragonTime _dragonTime = DragonTime_ready;
	
	if (_dragonReadyInfo == nil) {
		_dragonReadyInfo = [DragonReadyInfo create:_dragonType];
		_dragonReadyInfo.anchorPoint = ccp(1, 1);
		_dragonReadyInfo.position = ccp(winSize.width-cFixedScale(6), winSize.height-cFixedScale(50));
		
		[self addChild:_dragonReadyInfo z:1];
	}
	if (_dragonStartButton == nil) {
		_dragonStartButton = [DragonStartButton node];
		_dragonStartButton.position = ccp(winSize.width/2, winSize.height/2+cFixedScale(100));
		
		[self addChild:_dragonStartButton z:1];
	}
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
		_dragonBookInfo = [DragonBookInfo create:DragonTime_ready];
		_dragonBookInfo.anchorPoint = ccp(1, 0);
		_dragonBookInfo.position = ccp(winSize.width, 0);
		
		[self addChild:_dragonBookInfo z:1];
	}
}

-(void)onEnter
{
	[super onEnter];
	
	[self freeUI];
	[self showUI];
}

-(void)onExit
{
	[self freeUI];
	
	[super onExit];
}

@end
