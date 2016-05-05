//
//  DragonReadyInfo.m
//  TXSFGame
//
//  Created by efun on 13-10-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonReadyInfo.h"
#import "DragonReadyData.h"
#import "DragonReadyManager.h"
#import "Config.h"
#import "Arena.h"
#import "GameStart.h"
#import "GameConnection.h"
#import "CCSimpleButton.h"

#define Tag_Player_Count	10010
#define Tag_Ready_Time		10011

@implementation DragonReadyInfo

@synthesize dragonType = _dragonType;

+(DragonReadyInfo*)create:(DragonType)_type
{
	DragonReadyInfo *dragonReadyInfo = [DragonReadyInfo node];
	dragonReadyInfo.dragonType = _type;
	
	return dragonReadyInfo;
}

-(void)onEnter
{
	[super onEnter];
	
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/dragon/bg_ready.png"];
	bg.anchorPoint = CGPointZero;
	[self addChild:bg z:-1];
	
	self.contentSize = bg.contentSize;
	
	fontSize = 16;
	
	NSString *readyName = (_dragonType == DragonType_fly) ?
							NSLocalizedString(@"dragon_fly_name",nil) :
							NSLocalizedString(@"dragon_cometo_name",nil);
	NSString *readyString = [NSString stringWithFormat:NSLocalizedString(@"dragon_ready_label",nil), readyName];
	CCSprite *readyLabel = drawBoundString(readyString,
										   8,
										   GAME_DEF_CHINESE_FONT,
										   fontSize,
										   ccc3(242, 172, 46), ccBLACK);
	readyLabel.position = ccp(self.contentSize.width/2, cFixedScale(150.0f));
	[self addChild:readyLabel];
	
	CCSprite *label = nil;
	
	label = drawBoundString(NSLocalizedString(@"dragon_ready_time_label",nil),
							8,
							GAME_DEF_CHINESE_FONT,
							fontSize,
							ccc3(251, 236, 201), ccBLACK);
	label.anchorPoint = ccp(1, 0.5);
	label.position = ccp(self.contentSize.width/2, cFixedScale(120.0f));
	[self addChild:label];
	
	label = drawBoundString(NSLocalizedString(@"dragon_player_count_label",nil),
							8,
							GAME_DEF_CHINESE_FONT,
							fontSize,
							ccc3(251, 236, 201), ccBLACK);
	label.anchorPoint = ccp(1, 0.5);
	label.position = ccp(self.contentSize.width/2, cFixedScale(90.0f));
	[self addChild:label];
	
	if (_dragonType == DragonType_fly) {
		_inviteButton = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_invite_1.png"
												select:@"images/ui/button/bts_invite_2.png"
												target:self
												  call:@selector(doInvite)];
		_inviteButton.position = ccp(self.contentSize.width/2,
									 cFixedScale(40.0f));
		_inviteButton.visible = NO;
		[self addChild:_inviteButton];
	}
	
	[self updatePlayerCount];
	[self updateCaptain];
	
	[GameConnection addPost:ConnPost_Dragon_local_countdown target:self call:@selector(updateCountdown)];
	[GameConnection addPost:ConnPost_Dragon_local_captainName target:self call:@selector(updateCaptain)];
	[GameConnection addPost:ConnPost_Dragon_local_playerCount target:self call:@selector(updatePlayerCount)];
}

-(void)onExit
{
	[GameConnection removePostTarget:self];
	[super onExit];
}

-(void)doInvite
{
    if(!self.visible || ([[Window shared] isHasWindow]) || [Arena arenaIsOpen] || [GameStart isOpen] ){
		return;
	}
    
	if ([DragonReadyData checkIsStart]) return;
	
	NSString *inviteInfo = [NSString stringWithFormat:@"msg:DRA%i", [DragonReadyData shared].roomNum];
	[GameConnection request:@"awarSkyInvite" format:inviteInfo target:nil call:nil];
	
	_inviteButton.visible = NO;
	
	[self scheduleOnce:@selector(showInvite) delay:5.0f];
}

-(void)showInvite
{
	_inviteButton.visible = YES;
}

-(void)updateCountdown
{
	[self removeChildByTag:Tag_Ready_Time];
	
	int countdown = [DragonReadyData shared].countdown;
	NSString *countdownString = [NSString stringWithFormat:@"%@", getTimeFormat(countdown)];
	
	CCSprite *label = drawBoundString(countdownString,
									  8,
									  GAME_DEF_CHINESE_FONT,
									  fontSize,
									  ccc3(251, 236, 201), ccBLACK);
	label.anchorPoint = ccp(0, 0.5);
	label.position = ccp(self.contentSize.width/2, cFixedScale(120.0f));
	label.tag = Tag_Ready_Time;
	[self addChild:label];
}

-(void)updateCaptain
{
	BOOL _isCaption = [[DragonReadyData shared] checkIsCaption];
	
	if ([DragonReadyData shared].dragonType == DragonType_fly) {
		_inviteButton.visible = _isCaption;
	}
}

-(void)updatePlayerCount
{
	[self removeChildByTag:Tag_Player_Count];
	
	int count = [DragonReadyData shared].playerCount;
	int maxCount = [DragonReadyData shared].playerMaxCount;
	
	NSString *numString = [NSString stringWithFormat:@"%d / %d", count, maxCount];
	
	CCSprite *label = drawBoundString(numString,
									  8,
									  GAME_DEF_CHINESE_FONT,
									  fontSize,
									  ccc3(251, 236, 130), ccBLACK);
	label.anchorPoint = ccp(0, 0.5);
	label.position = ccp(self.contentSize.width/2, cFixedScale(90.0f));
	label.tag = Tag_Player_Count;
	[self addChild:label];
}

@end
