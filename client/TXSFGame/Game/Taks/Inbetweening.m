//
//  Inbetweening.m
//  TXSFGame
//
//  Created by Soul on 13-5-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "Inbetweening.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "InbetweeningViewerContent.h"

static Inbetweening *s_Inbetweening = nil;

@implementation Inbetweening

@synthesize ikonInfo;
@synthesize target;
@synthesize call;

+(Inbetweening*)createInbetweening:(NSDictionary*)_info target:(id)_target call:(SEL)_call{
	if (s_Inbetweening == nil && _info != nil) {
		s_Inbetweening = [Inbetweening node];
		s_Inbetweening.ikonInfo = _info;
		s_Inbetweening.target = _target;
		s_Inbetweening.call = _call;
		return s_Inbetweening;
	}
	return nil;
}

-(void)onEnter{
	[super onEnter];
	timeLong = 0;
	endLong = 3;
	isEnd = NO;
	
	[self showInbetweening];
	[self schedule:@selector(checkTime) interval:1.0];
	
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-255 swallowsTouches:YES];
	
	CCSimpleButton* bt_skip = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_skip_1.png"
													  select:@"images/ui/button/bts_skip_2.png"
													  target:self
														call:@selector(skipInbetweening:)
													priority:-50];
	
	if (bt_skip != nil) {
		[self addChild:bt_skip z:10];
		CGSize size = [CCDirector sharedDirector].winSize;
		bt_skip.position = ccp(size.width/2, cFixedScale(100));
	}
}

-(void)onExit{
	[self unscheduleAllSelectors];
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	if (ikonInfo != nil) {
		[ikonInfo release];
		ikonInfo = nil;
	}
	s_Inbetweening = nil;
	[super onExit];
}

-(void)showInbetweening{
	InbetweeningViewerContent *viewer = [InbetweeningViewerContent create:ikonInfo];
	[self addChild:viewer];
	viewer.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
}

-(void)checkTime{
	timeLong++;
	CCLOG(@"Inbetweening->checkTime->%d",timeLong);
	if (timeLong > endLong) {
		[self endInbetweening];
		timeLong = 0 ;
	}
}

-(void)endInbetweening{
	[self unschedule:@selector(checkTime)];
	if (isEnd) {
		return ;
	}
	if (target != nil && call != nil) {
		isEnd = YES;
		[target performSelector:call];
		target = nil;
		call = nil;
	}
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	CCLOG(@"Inbetweening->ccTouchEnded");
	if (timeLong < (endLong - 1)) {
		[self endInbetweening];
	}
}

-(void)skipInbetweening:(id)sender{
	CCLOG(@"Inbetweening->skipInbetweening");
	if (timeLong < (endLong - 1)) {
		[self endInbetweening];
	}
}

@end
