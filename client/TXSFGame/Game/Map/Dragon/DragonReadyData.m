//
//  DragonReadyData.m
//  TXSFGame
//
//  Created by efun on 13-9-7.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonReadyData.h"
#import "GameConnection.h"
#import "GameConfigure.h"
#import "GameDB.h"
#import "DragonReadyManager.h"
#import "DragonTips.h"

static DragonCountdown *s_DragonCountdown = nil;

@implementation DragonCountdown

@synthesize countdown = _countdown;
@synthesize dragonType = _dragonType;

+(DragonCountdown*)shared
{
	if (s_DragonCountdown == nil) {
		s_DragonCountdown = [[DragonCountdown alloc] init];
	}
	return s_DragonCountdown;
}

+(void)acceptPush:(NSDictionary*)dict
{
	[DragonCountdown shared].countdown = [[dict objectForKey:@"ltime"] intValue];
	[DragonCountdown shared].dragonType = [[dict objectForKey:@"type"] intValue];
	
	[[DragonCountdown shared] removeTimer];
	
	[DragonTips resetThisTimeClose];
	// 开始倒计时
	if ([DragonCountdown shared].countdown > 0) {
		[[DragonCountdown shared] addTimer];
		[DragonTips show:NO];
	}
	// 当前可以进入
	else {
		[DragonTips show:YES];
	}
}

+(int)getCountdown
{
	if (s_DragonCountdown) {
		return s_DragonCountdown.countdown;
	}
	return 0;
}

+(DragonType)getDragonType
{
	if (s_DragonCountdown) {
		return s_DragonCountdown.dragonType;
	}
	return DragonType_none;
}

-(void)addTimer
{
	_countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
													   target:self
													 selector:@selector(doCountdown)
													 userInfo:nil
													  repeats:YES];
}

-(void)removeTimer
{
	if (_countDownTimer != nil) {
		[_countDownTimer invalidate];
		_countDownTimer = nil;
	}
}

-(void)doCountdown
{
	_countdown--;
	if (_countdown <= 0) {
		[DragonTips resetThisTimeClose];
		[DragonTips show:YES];
		[DragonTips checkStatus];
		[self removeTimer];
	} else {
		[DragonTips show:NO];
	}
}

@end

static BOOL isWaitNet	= NO;
static BOOL isAddEvent	= NO;

static NSDictionary		*s_DragonReadyDict = nil;	// 数据
static DragonReadyData	*s_DragonReadyData = nil;	// 类实例

@implementation DragonReadyData

@synthesize isStart		= _isStart;
@synthesize roomNum		= _roomNum;
@synthesize countdown	= _countdown;
@synthesize playerCount = _playerCount;
@synthesize glory		= _glory;
@synthesize captainName	= _captainName;
@synthesize skyBookDict = _skyBookDict;

@synthesize mapId			= _mapId;
@synthesize playerMaxCount	= _playerMaxCount;
@synthesize dragonType		= _dragonType;

+(DragonReadyData*)shared
{
	if (s_DragonReadyData == nil) {
		s_DragonReadyData = [[DragonReadyData alloc] init];
	}
	return s_DragonReadyData;
}

+(void)startAll
{
	[DragonReadyData addEvent];
}

+(void)stopAll
{
	[DragonReadyData remove];
	[DragonReadyData removeEvent];
}

+(void)remove
{
	if (s_DragonReadyData) {
		[s_DragonReadyData removeTimer];
		[s_DragonReadyData release];
		s_DragonReadyData = nil;
	}
	if (s_DragonReadyDict) {
		[s_DragonReadyDict release];
		s_DragonReadyDict = nil;
	}
}

+(void)addEvent
{
	if (isAddEvent) return;
	isAddEvent = YES;
	
	[GameConnection addPost:ConnPost_Dragon_enterRoom
					 target:[DragonReadyData class]
					   call:@selector(playerPassRoom:)];
	[GameConnection addPost:ConnPost_Dragon_exitRoom
					 target:[DragonReadyData class]
					   call:@selector(playerPassRoom:)];
}

+(void)removeEvent
{
	isAddEvent = NO;
	
	[GameConnection removePostTarget:[DragonReadyData class]];
}

+(BOOL)checkIsReady
{
	return (s_DragonReadyData != nil);
}

+(BOOL)checkIsStart
{
	if (s_DragonReadyData != nil) {
		return s_DragonReadyData.isStart;
	}
	return NO;
}

+(void)setIsStart:(BOOL)__isStart
{
	if (s_DragonReadyData != nil) {
		s_DragonReadyData.isStart = __isStart;
	}
}

+(BOOL)checkCanNet
{
	return (isWaitNet == NO);
}

+(void)setCanNet:(BOOL)_isCanNet
{
	isWaitNet = !_isCanNet;
}

+(void)beginWithData:(id)sender
{
	if (checkResponseStatus(sender)) {
		
		NSDictionary *_data = getResponseData(sender);
		if (_data == nil) return;
		
		if (s_DragonReadyData != nil && s_DragonReadyDict != nil) return;
		
		[DragonReadyData remove];
		
		s_DragonReadyDict = [NSDictionary dictionaryWithDictionary:_data];
		[s_DragonReadyDict retain];
		
		[[DragonReadyData shared] enter];
		
	} else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
	}
}

// 玩家进出房间
+(void)playerPassRoom:(NSNotification*)notification
{
	if (![DragonReadyData checkIsReady]) return;
	
	NSDictionary *data = notification.object;
	
	if ([notification.name isEqualToString:ConnPost_Dragon_enterRoom]) {
		
		s_DragonReadyData.playerCount = [[data objectForKey:@"pnum"] intValue];
		
		[GameConnection post:ConnPost_Dragon_local_playerCount object:nil];
		
	}
	else if ([notification.name isEqualToString:ConnPost_Dragon_exitRoom]) {
		
		if ([data objectForKey:@"tname"]) {
			[DragonReadyData shared].captainName = [data objectForKey:@"tname"];
		}
		
		[DragonReadyData shared].playerCount = [[data objectForKey:@"pnum"] intValue];
		
		[GameConnection post:ConnPost_Dragon_local_playerCount object:nil];
		[GameConnection post:ConnPost_Dragon_local_captainName object:nil];
	}
}

-(id)init
{
	if (self = [super init]) {
		isWaitNet = NO;
		_isStart = NO;
		
		[self releaseAll];
		
		NSDictionary *_data = s_DragonReadyDict;
		
		_roomNum		= [[_data objectForKey:@"rnum"] intValue];
		_countdown		= [[_data objectForKey:@"rtime"] intValue];
		_playerCount	= [[_data objectForKey:@"pnum"] intValue];
		_glory			= [[_data objectForKey:@"glory"] intValue];
		_captainName	= [NSString stringWithFormat:@"%@", [_data objectForKey:@"tname"]];
		_skyBookDict	= [NSDictionary dictionaryWithDictionary:[_data objectForKey:@"books"]];
		
		[_captainName retain];
		[_skyBookDict retain];
		
		// 活动开启配置表
		int asid = [[_data objectForKey:@"asid"] intValue];
		NSDictionary *dict = [[GameDB shared] getAwarStartConfig:asid];
		if (dict) {
			
			_mapId			= [[dict objectForKey:@"mid"] intValue];
			_playerMaxCount	= [[dict objectForKey:@"mplayer"] intValue];
			_dragonType		= [[dict objectForKey:@"type"] intValue];
			
		} else {
			CCLOG(@"ERROR 活动开启配置表 %d", asid);
		}
		
		countDownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
														  target:self
														selector:@selector(doCountdown)
														userInfo:nil
														 repeats:YES];
	}
	return self;
}

-(void)dealloc
{
	isWaitNet = NO;
	[self releaseAll];
	[self removeTimer];
	
	[super dealloc];
}

-(void)releaseAll
{
	if (_captainName != nil) {
		[_captainName release];
		_captainName = nil;
	}
	if (_skyBookDict != nil) {
		[_skyBookDict release];
		_skyBookDict = nil;
	}
}

-(void)setCaptainName:(NSString *)__captainName
{
	if (_captainName != nil) {
		[_captainName release];
		_captainName = nil;
	}
	_captainName = [NSString stringWithFormat:@"%@", __captainName];
	[_captainName retain];
}

-(void)enter
{
	// 进入狩龙准备地图
	[DragonReadyManager enterDragonReady];
	
	[GameConnection post:ConnPost_Dragon_local_countdown object:nil];
}

-(void)removeTimer
{
	if (countDownTimer != nil) {
		[countDownTimer invalidate];
		countDownTimer = nil;
	}
}

-(void)doCountdown
{
	_countdown = MAX(--_countdown, 0);
	[GameConnection post:ConnPost_Dragon_local_countdown object:nil];
	
	if (_countdown <= 0) {
		[self removeTimer];
	}
}

-(BOOL)checkIsCaption
{
	NSString *playerName = [[GameConfigure shared] getPlayerName];
	return ([playerName isEqualToString:_captainName]);
}

-(int)getBookCount:(int)__bookId
{
	if (_skyBookDict == nil) return 0;
	
	NSString *key = [NSString stringWithFormat:@"%d", __bookId];
	if ([[_skyBookDict allKeys] containsObject:key]) {
		return [[_skyBookDict objectForKey:key] intValue];
	}
	
	return 0;
}

@end
