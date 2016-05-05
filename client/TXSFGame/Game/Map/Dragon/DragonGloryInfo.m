//
//  DragonGloryInfo.m
//  TXSFGame
//
//  Created by efun on 13-10-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonGloryInfo.h"
#import "DragonReadyData.h"
#import "DragonFightData.h"
#import "DragonFightManager.h"
#import "Config.h"

#define Tag_cd			101
#define Tag_glory		102

#define Pos_x		cFixedScale(140.0f)

#define Offset_label_y			cFixedScale(6.0f)
#define Offset_height			cFixedScale(3.0f)

@implementation DragonGloryInfo

@synthesize dragonTime = _dragonTime;

+(DragonGloryInfo*)create:(DragonTime)_time
{
	DragonGloryInfo *dragonGloryInfo = [DragonGloryInfo node];
	dragonGloryInfo.dragonTime = _time;
	
	return dragonGloryInfo;
}

-(void)onEnter
{
	[super onEnter];
	
	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/dragon/bg_font.png"];
	float bgHeight = bg.contentSize.height;
	
	int count = 2;
	self.contentSize = CGSizeMake(bg.contentSize.width,
								  bgHeight*count+Offset_height*(count-1));
	
	bg.anchorPoint = CGPointZero;
	bg.position = ccp(0, (bgHeight+Offset_height)*0);
	[self addChild:bg];
	
	cdBg = [CCSprite spriteWithFile:@"images/ui/dragon/bg_font.png"];
	cdBg.anchorPoint = CGPointZero;
	cdBg.position = ccp(0, (bgHeight+Offset_height)*1);
	cdBg.visible = NO;
	[self addChild:cdBg];
	
	fontSize = 16;
	
	CCSprite *label = nil;
	
	// 同盟贡献点
	label = drawBoundString(NSLocalizedString(@"dragon_glory_label",nil),
							8,
							GAME_DEF_CHINESE_FONT,
							fontSize,
							ccc3(251, 236, 201), ccBLACK);
	label.anchorPoint = ccp(1, 0.5f);
	label.position = ccp(Pos_x, bgHeight/2+Offset_label_y);
	[self addChild:label];
	
	gloryPoint = ccp(Pos_x, label.position.y);
	
	// CD
	cdLabel = drawBoundString(NSLocalizedString(@"dragon_player_cd_label",nil),
							  8,
							  GAME_DEF_CHINESE_FONT,
							  fontSize,
							  ccc3(251, 236, 201), ccBLACK);
	cdLabel.anchorPoint = ccp(1, 0.5f);
	cdLabel.position = ccp(Pos_x, (bgHeight+Offset_height)*1+bgHeight/2+Offset_label_y);
	cdLabel.visible = NO;
	[self addChild:cdLabel];
	
	cdPoint = ccp(Pos_x, cdLabel.position.y);
	
	[self updateGlory];
	
	[GameConnection addPost:ConnPost_Dragon_local_cd_countdown target:self call:@selector(updateCD)];
	[GameConnection addPost:ConnPost_Dragon_local_cd_remove_after target:self call:@selector(updateCD)];
	[GameConnection addPost:ConnPost_Dragon_local_glory target:self call:@selector(updateGlory)];
}

-(void)onExit
{
	[GameConnection removePostTarget:self];
	[super onExit];
}

-(void)updateGlory
{
	[self removeChildByTag:Tag_glory];
	
	int glory = 0;
	if (_dragonTime == DragonTime_ready) {
		glory = [DragonReadyData shared].glory;
	} else {
		glory = [DragonFightData shared].glory;
	}
	
	// 要这样的
	NSString *numString = [NSString stringWithFormat:@"%d       ", glory];
	CCSprite *label = drawBoundString(numString,
									  8,
									  GAME_DEF_CHINESE_FONT,
									  fontSize,
									  ccc3(251, 236, 130), ccBLACK);
	label.anchorPoint = ccp(0, 0.5);
	label.position = gloryPoint;
	label.tag = Tag_glory;
	[self addChild:label];
}

-(void)updateCD
{
	[self removeChildByTag:Tag_cd];
	
	BOOL isCD = [DragonFightData checkIsCD];
	if (isCD) {
		if (!cdLabel.visible) cdLabel.visible = YES;
		if (!cdBg.visible) cdBg.visible = YES;

		NSString *cdString = getTimeFormat([DragonFightData shared].cdTime);
		CCSprite *label = drawBoundString(cdString,
										  8,
										  GAME_DEF_CHINESE_FONT,
										  fontSize,
										  ccc3(251, 236, 201), ccBLACK);
		label.anchorPoint = ccp(0, 0.5);
		label.position = cdPoint;
		label.tag = Tag_cd;
		[self addChild:label];
		
	} else {
		if (cdLabel.visible) cdLabel.visible = NO;
		if (cdBg.visible) cdBg.visible = NO;
	}
}

@end
