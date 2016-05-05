//
//  DragonShowInfo.m
//  TXSFGame
//
//  Created by efun on 13-9-23.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonShowInfo.h"
#import "Config.h"
#import "GameConnection.h"
#import "DragonFightData.h"

#define Tag_show_info		101

@implementation DragonShowInfo

-(id)init
{
	if (self = [super init]) {
		_isShowNow = NO;
		_infoArray = [NSMutableArray array];
		[_infoArray retain];
	}
	return self;
}

-(void)dealloc
{
	if (_infoArray != nil) {
		[_infoArray release];
		_infoArray = nil;
	}
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	[GameConnection addPost:ConnPost_Dragon_local_desc target:self call:@selector(addInfo:)];
}

-(void)onExit
{
	[GameConnection removePostTarget:self];
	[super onExit];
}

-(void)addInfo:(NSNotification*)notification
{
	NSString *info = [NSString stringWithFormat:@"%@", notification.object];
	[_infoArray addObject:info];
	
	// 当前没有就显示
	if (!_isShowNow) {
		[self startShow];
	}
}

-(void)startShow
{
	CCNode *node = [self getChildByTag:Tag_show_info];
	if (node != nil) {
		[node removeFromParent];
		node = nil;
	}
	
	if (_infoArray.count <= 0) {
		_isShowNow = NO;
	} else {
		
		_isShowNow = YES;
		
		NSString *info = [NSString stringWithFormat:@"%@", [_infoArray objectAtIndex:0]];
		[_infoArray removeObjectAtIndex:0];
		
		[self showInfo:info];
		
	}
}

-(void)showInfo:(NSString*)info
{
	float fontSize = 30.0f;
	CCSprite *label = drawBoundString(info,
									  11,
									  GAME_DEF_CHINESE_FONT,
									  fontSize,
									  ccc3(251, 236, 201), ccBLACK);
//	label.opacity = 0;
	label.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	label.tag = Tag_show_info;
	
	[self addChild:label];
	
	[label runAction:[CCSequence actions:
//					  [CCFadeIn actionWithDuration:0.5f],
					  [CCDelayTime actionWithDuration:2.5f],
					  [CCMoveBy actionWithDuration:0.6f position:ccp(0, cFixedScale(80))],
//					  [CCFadeOut actionWithDuration:0.5f],
					  [CCCallFunc actionWithTarget:self selector:@selector(startShow)],
					  nil]];
}

@end
