//
//  DragonTips.m
//  TXSFGame
//
//  Created by efun on 13-9-13.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonTips.h"
#import "MapManager.h"
#import "FightManager.h"
#import "TaskTalk.h"
#import "UnionPracticeConfigTeam.h"
#import "DragonReadyData.h"
#import "Config.h"
#import "GameUI.h"

static BOOL dragonTimeClose = NO;
static DragonTips *s_DragonTips;

@implementation DragonTips

@synthesize isStart;
@synthesize labelTime;

+(void)updateStatus
{
	if ([MapManager shared].mapType != Map_Type_Standard) {
		[DragonTips removeDragonTips];
		return;
	}
}

+(void)resetThisTimeClose
{
	dragonTimeClose = NO;
}

+(void)removeDragonTips
{
	if (s_DragonTips) {
		[s_DragonTips removeFromParent];
		s_DragonTips = nil;
	}
}

+(void)hide
{
	[DragonTips removeDragonTips];
}

+(void)show:(BOOL)_isShow
{
	if (dragonTimeClose						||
		[FightManager isFighting]			||
		[TaskTalk isTalking]				||
		[UnionPracticeConfigTeam isOpen]	||
		[MapManager shared].mapType != Map_Type_Standard) {
		[DragonTips removeDragonTips];
		return;
	}
	
	// 准备时间
	if (s_DragonTips == nil) {
		
		s_DragonTips = [DragonTips node];
		s_DragonTips.isStart = _isShow;
		id move=[CCMoveBy actionWithDuration:4 position:ccp(0,cFixedScale(470))];
		if (iPhoneRuningOnGame()) {
			[s_DragonTips setPosition:ccp([GameUI shared].contentSize.width-130/2.0f-227/4.0f, -300/2.0f)];
		}else{
			[s_DragonTips setPosition:ccp([GameUI shared].contentSize.width-[GameUI shared].contentSize.width/4, -300)];
		}
		[s_DragonTips runAction:move];
		[[GameUI shared] addChild:s_DragonTips];
		
		
	} else {
		s_DragonTips.isStart = _isShow;
		int time = [DragonCountdown getCountdown];
		s_DragonTips.labelTime.string = [NSString stringWithFormat:@"%.2d : %.2d",time/60,time%60];
	}
}

-(void)onEnter
{
	[super onEnter];
	
	dragonTimeClose = NO;
	
	CCSprite *bg=[CCSprite spriteWithFile:@"images/ui/worldboss/bg_tips.png"];
	bg.tag = 20010;
	
	CCSimpleButton *close_btn=[CCSimpleButton spriteWithFile:@"images/ui/worldboss/btn_tipsclose.png"];
	[close_btn setTarget:self];
	[close_btn setCall:@selector(closeAct)];
	
	float centerX = bg.contentSize.width/2;
	
	CCSprite *bosslogo=[CCSprite spriteWithFile:@"images/ui/richang_icon/richang4.png"];
	[bosslogo setPosition:ccp(cFixedScale(40), cFixedScale(80))];
	[bg addChild:bosslogo];
	
	int time=[DragonCountdown getCountdown];
	
	float fontSize=16;
	if (iPhoneRuningOnGame()) {
		fontSize=9;
	}
	labelTime=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%.2d : %.2d",time/60,time%60] fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	
	
	[close_btn setPosition:ccp(bg.contentSize.width-close_btn.contentSize.width/1.5, bg.contentSize.height-close_btn.contentSize.height/1.5)];
	
	
	labelTime.anchorPoint = ccp(1.0, 0.5);
	labelTime.position = ccp(centerX - cFixedScale(10), cFixedScale(40));
	
	
	[bg addChild:labelTime];
	[bg addChild:close_btn];
	[self addChild:bg];
	
	[DragonTips checkStatus];
}

-(void)onExit
{
	dragonTimeClose = YES;
	s_DragonTips = nil;
	
	[super onExit];
}

+(void)checkStatus
{
	float fontSize=20;
	if (iPhoneRuningOnGame()) {
		fontSize=22;
	}
	
	CCSprite *bg = (CCSprite*)[s_DragonTips getChildByTag:20010];
	float centerX = bg.contentSize.width/2;
	
	[bg removeChildByTag:20011];
	
	CCLOG(@"dragon_cometo_tips_open %d %d", [DragonCountdown getDragonType], DragonType_fly);
	
	NSString *tips = s_DragonTips.isStart?
	([DragonCountdown getDragonType]==DragonType_fly?NSLocalizedString(@"dragon_fly_tips_open",nil):NSLocalizedString(@"dragon_cometo_tips_open",nil)):
	([DragonCountdown getDragonType]==DragonType_fly?NSLocalizedString(@"dragon_fly_tips_will_open",nil):NSLocalizedString(@"dragon_cometo_tips_will_open",nil));
	CCSprite *str1=drawString(tips, CGSizeMake(300, 1) , getCommonFontName(FONT_1), fontSize, 24, @"ffffff");
	[str1 setPosition:ccp(cFixedScale(150), cFixedScale(70))];
	str1.tag = 20011;
	[bg addChild:str1];
	
	[bg removeChildByTag:20012];
	CCSprite *str2=drawString(s_DragonTips.isStart?NSLocalizedString(@"dragon_tips_enter",nil):NSLocalizedString(@"dragon_tips_will_enter",nil), CGSizeMake(300, 1) , getCommonFontName(FONT_1), fontSize, 24, @"ffff00");
	CCSimpleButton *b=[CCSimpleButton spriteWithNode:str2];
	b.tag = 20012;
	[b setTarget:s_DragonTips];
	[b setCall:@selector(enterAct)];
	b.anchorPoint = ccp(0,0.5);
	b.position = ccp(centerX + cFixedScale(10), cFixedScale(40));
	[bg addChild:b];
	
	s_DragonTips.labelTime.visible = !s_DragonTips.isStart;
}

-(void)closeAct{
	dragonTimeClose = YES;
	[self removeFromParent];
}

-(void)enterAct{
    if ([[Window shared] isHasWindow]) {
        return;
    }
	[self closeAct];
	
	if (isStart) {
		[GameConnection request:@"awarEnterRoom" data:[NSDictionary dictionary] target:[DragonReadyData class] call:@selector(beginWithData:)];
	}
}

@end
