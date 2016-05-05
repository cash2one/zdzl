//
//  DragonStartButton.m
//  TXSFGame
//
//  Created by efun on 13-10-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonStartButton.h"
#import "DragonReadyData.h"
#import "DragonReadyManager.h"
#import "Config.h"
#import "Arena.h"
#import "GameStart.h"
#import "GameConnection.h"
#import "CCSimpleButton.h"

@implementation DragonStartButton

-(void)onEnter
{
	[super onEnter];
	
	startButton = [CCSimpleButton spriteWithFile:@"images/ui/worldboss/bt_battle1.png"
										  select:@"images/ui/worldboss/bt_battle2.png"
										  target:self
											call:@selector(doStartFight)];
	startButton.anchorPoint = CGPointZero;
	startButton.visible = NO;
	[self addChild:startButton];
	
	self.contentSize = startButton.contentSize;
	
	[self updateCaptain];
	
	[GameConnection addPost:ConnPost_Dragon_local_captainName target:self call:@selector(updateCaptain)];
}

-(void)onExit
{
	[GameConnection removePostTarget:self];
	[super onExit];
}

-(void)updateCaptain
{
	BOOL _isCaption = [[DragonReadyData shared] checkIsCaption];
	startButton.visible = _isCaption;
}

-(void)doStartFight
{
    if(!self.visible || ([[Window shared] isHasWindow]) || [Arena arenaIsOpen] || [GameStart isOpen] ){
		return;
	}
    
	if ([DragonReadyData checkIsStart]) return;
	
	[DragonReadyData setIsStart:YES];
	[GameConnection request:@"awarStart" data:[NSDictionary dictionary] target:[DragonReadyManager class] call:@selector(didStartFight:)];
}

@end
