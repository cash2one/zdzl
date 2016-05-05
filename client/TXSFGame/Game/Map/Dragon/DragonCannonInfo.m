//
//  DragonCannonInfo.m
//  TXSFGame
//
//  Created by efun on 13-9-9.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonCannonInfo.h"
#import "DragonReadyData.h"
#import "DragonFightData.h"
#import "DragonFightManager.h"
#import "Config.h"

#define Time_exit				5

#define Tag_captain				101
#define Tag_cannon				102
#define Tag_fight				103

#define Offset_label_y			cFixedScale(6.0f)
#define Offset_label_width		cFixedScale(38.0f)
#define Offset_height			cFixedScale(3.0f)
#define Offset_bottom			cFixedScale(47.0f)
#define Pos_boat_x				cFixedScale(124.0f)
#define Pos_boat_y				cFixedScale(35.0f)

@implementation DragonCannonInfo

@synthesize dragonTime = _dragonTime;

+(DragonCannonInfo*)create:(DragonType)_type time:(DragonTime)_time
{
	DragonCannonInfo *dragonCannonInfo = [DragonCannonInfo node];
	dragonCannonInfo.dragonType = _type;
	dragonCannonInfo.dragonTime = _time;
	
	return dragonCannonInfo;
}

-(id)init
{
	if (self = [super init]) {
		maxCount = [[[[GameDB shared] getGlobalConfig] objectForKey:@"awarConnonMax"] intValue];
	}
	return self;
}

-(void)onEnter
{
	[super onEnter];

	CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/dragon/bg_font.png"];
	float bgHeight = bg.contentSize.height;
	
	int count = (_dragonTime == DragonTime_ready) ? 2 : 3;
	self.contentSize = CGSizeMake(bg.contentSize.width,
								  bgHeight*count+Offset_height*(count-1)+Offset_bottom);
	
	for (int i = 0; i < count; i++) {
		bg.anchorPoint = CGPointZero;
		bg.position = ccp(0, (bgHeight+Offset_height)*i+Offset_bottom);
		[self addChild:bg];
		
		if (i+1<count) {
			bg = [CCSprite spriteWithFile:@"images/ui/dragon/bg_font.png"];
		}
	}
	
	fontSize = 16;
	
	CCSprite *label = nil;
	
	// 队长
	label = drawBoundString(NSLocalizedString(@"dragon_captain_name_label",nil),
							8,
							GAME_DEF_CHINESE_FONT,
							fontSize,
							ccc3(251, 236, 201), ccBLACK);
	label.anchorPoint = ccp(0, 0.5f);
	label.position = ccp(Offset_label_width, bgHeight/2+Offset_label_y+Offset_bottom);
	[self addChild:label];
	
	captainPoint = ccp(label.position.x+cFixedScale(label.contentSize.width), label.position.y);
	
	// 天舟炮弹
	label = drawBoundString(NSLocalizedString(@"dragon_cannon_count_label",nil),
							8,
							GAME_DEF_CHINESE_FONT,
							fontSize,
							ccc3(251, 236, 201), ccBLACK);
	label.anchorPoint = ccp(0, 0.5f);
	label.position = ccp(Offset_label_width, (bgHeight+Offset_height)*1+bgHeight/2+Offset_label_y+Offset_bottom);
	[self addChild:label];
	
	cannonPoint = ccp(label.position.x+cFixedScale(label.contentSize.width), label.position.y);
	
	// 战斗时间
	if (count == 3) {
		fightPoint = ccp(Offset_label_width, (bgHeight+Offset_height)*2+bgHeight/2+Offset_label_y+Offset_bottom);
	}
	
	[self updateCannonCount];
	[self updateCaptainName];
	
	if (_dragonTime == DragonTime_fight) {
		// 天舟耐久度
		if ([DragonFightData shared].boatTotalHard > 0) {
			[self updateBoatHp];
		}
		
		[GameConnection addPost:ConnPost_Dragon_local_countdown target:self call:@selector(updateCountdown)];
		[GameConnection addPost:ConnPost_Dragon_local_exit target:self call:@selector(startExitCountdown)];
		[GameConnection addPost:ConnPost_Dragon_local_result_doWin target:self call:@selector(showWinResult)];
		[GameConnection addPost:ConnPost_Dragon_local_boatHard target:self call:@selector(updateBoatHp)];
	}
	[GameConnection addPost:ConnPost_Dragon_local_fight_cannonCount target:self call:@selector(updateCannonCount)];
	[GameConnection addPost:ConnPost_Dragon_local_captainName target:self call:@selector(updateCaptainName)];
}

-(void)onExit
{
	[GameConnection removePostTarget:self];
	[super onExit];
}

-(void)updateCannonCount
{
	[self removeChildByTag:Tag_cannon];
	
	int cannon = 0;
	if (_dragonTime == DragonTime_ready) {
		cannon = maxCount;
	} else {
		cannon = [DragonFightData shared].cannon;
	}
	
	NSString *cannonString = [NSString stringWithFormat:@"%d / %d", cannon, maxCount];
	CCSprite *label = drawBoundString(cannonString,
									  8,
									  GAME_DEF_CHINESE_FONT,
									  fontSize,
									  ccc3(254, 235, 132), ccBLACK);
	label.anchorPoint = ccp(0, 0.5);
	label.position = cannonPoint;
	label.tag = Tag_cannon;
	[self addChild:label];
}

-(void)updateCaptainName
{
	[self removeChildByTag:Tag_captain];
	
	NSString *captainName = nil;
	if (_dragonTime == DragonTime_ready) {
		captainName = [DragonReadyData shared].captainName;
	} else {
		captainName = [DragonFightData shared].captainName;
	}
	CCSprite *label = drawBoundString(captainName,
									  8,
									  GAME_DEF_CHINESE_FONT,
									  fontSize,
									  ccc3(5, 171, 236), ccBLACK);
	label.anchorPoint = ccp(0, 0.5);
	label.position = captainPoint;
	label.tag = Tag_captain;
	[self addChild:label];
}

-(void)showFightInfo:(NSString*)info
{
	if (info == nil) return;
	
	[self removeChildByTag:Tag_fight];
	
	CCSprite *label = drawBoundString(info,
									  8,
									  GAME_DEF_CHINESE_FONT,
									  fontSize,
									  ccc3(251, 236, 201), ccBLACK);
	label.anchorPoint = ccp(0, 0.5);
	label.position = fightPoint;
	label.tag = Tag_fight;
	[self addChild:label];
}

-(void)updateCountdown
{
	if (_dragonTime == DragonTime_ready) return;
	
	[self removeChildByTag:Tag_fight];
	
	NSString *string = nil;
	
	int countdown = [DragonFightData shared].normalTime;;
	// 没有使用续航时间
	if (countdown >= 0) {
		string = NSLocalizedString(@"dragon_fight_time_label",nil);
	}
	// 使用续航时间
	else {
		countdown += [DragonFightData shared].continueTime;
		string = NSLocalizedString(@"dragon_continue_time_label",nil);
	}
	
	NSString *finalString = [NSString stringWithFormat:string, getTimeFormat(countdown)];
	[self showFightInfo:finalString];
}

-(NSString*)getExitCountdownString
{
	NSString *exitTimeString = getTimeFormat(exitTime);
	
	NSString *string = nil;
	if ([DragonFightData checkIsWin]) {
		string = [NSString stringWithFormat:NSLocalizedString(@"dragon_quit_countdown_label",nil), exitTimeString];
	} else {
		NSString *reason = nil;
		if ([DragonFightData shared].resultType == DragonResult_lose_time) {
			reason = NSLocalizedString(@"dragon_fail_time_countdown_label",nil);
		} else {
			reason = NSLocalizedString(@"dragon_fail_boat_countdown_label",nil);
		}
		
		string = [NSString stringWithFormat:reason, exitTimeString];
	}
	return string;
}

-(void)exitCountdown
{
	exitTime--;
	[self showFightInfo:[self getExitCountdownString]];
	
	if (exitTime <= 0) {
		[DragonFightManager quitDragonFight];
	}
}

-(void)startExitCountdown
{
	[self unschedule:@selector(exitCountdown)];
	[self schedule:@selector(exitCountdown) interval:1.0f];
	
	exitTime = Time_exit;
	[self showFightInfo:[self getExitCountdownString]];
}

-(void)showWinResult
{
	[self showFightInfo:NSLocalizedString(@"dragon_fight_success_label",nil)];
}

-(void)updateBoatHp
{
	float currentHp = [DragonFightData shared].boatHard;
	float totalHp = [DragonFightData shared].boatTotalHard;
	
	if (boatHpBg == nil) {
		boatHpBg = [CCSprite spriteWithFile:@"images/ui/dragon/bg_font.png"];
		boatHpBg.anchorPoint = CGPointZero;
		boatHpBg.position = CGPointZero;
		
		[self addChild:boatHpBg];
	}
	
	if (boatHpSprite == nil) {
		boatHpSprite = drawBoundString(NSLocalizedString(@"dragon_boat_name_label",nil),
									   8,
									   GAME_DEF_CHINESE_FONT,
									   fontSize,
									   ccc3(242, 171, 44), ccBLACK);
		boatHpSprite.anchorPoint = ccp(0.5f, 0.5f);
		boatHpSprite.position = ccp(Pos_boat_x,
									boatHpSprite.contentSize.height/2+Offset_label_y);
		[self addChild:boatHpSprite];
	}
	
	if (boatHpLabel == nil) {
		float labelSize = 14.0f;
		if (iPhoneRuningOnGame()) {
			labelSize = 8.0f;
		}
		boatHpLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:labelSize];
		boatHpLabel.position = ccp(Pos_boat_x, Pos_boat_y);
		boatHpLabel.color = ccc3(238, 228, 204);
		
		[self addChild:boatHpLabel z:10];
	}
	boatHpLabel.string = [NSString stringWithFormat:@"%.f/%.f", currentHp, totalHp];
	
	if (boatScrollBg == nil) {
		boatScrollBg = [CCSprite spriteWithFile:@"images/ui/dragon/bg_hard.png"];
		boatScrollBg.position = ccp(Pos_boat_x, Pos_boat_y);
		
		[self addChild:boatScrollBg];
	}
	
	float x = cFixedScale(0.5f);
	
	// 进度条
	if (boatScrollBg1 == nil) {
		boatScrollBg1 = [CCSprite spriteWithFile:@"images/ui/panel/recruit_detail_scroll_1.png"];
		boatScrollBg1.anchorPoint = ccp(0, 0.5f);
		boatScrollBg1.position = ccp(x, boatScrollBg.contentSize.height/2);
		
		[boatScrollBg addChild:boatScrollBg1];
	}
	if (boatScrollBg2 == nil) {
		boatScrollBg2 = [CCSprite spriteWithFile:@"images/ui/panel/recruit_detail_scroll_2.png"];
		boatScrollBg2.anchorPoint = ccp(0, 0.5f);
		boatScrollBg2.position = ccp(boatScrollBg1.position.x+boatScrollBg1.contentSize.width,
									 boatScrollBg1.position.y);
		
		[boatScrollBg addChild:boatScrollBg2];
	}
	if (boatScrollBg3 == nil) {
		boatScrollBg3 = [CCSprite spriteWithFile:@"images/ui/panel/recruit_detail_scroll_3.png"];
		boatScrollBg3.anchorPoint = ccp(0, 0.5f);
		
		[boatScrollBg addChild:boatScrollBg3];
	}
	if (currentHp <= 0) {
		boatScrollBg1.visible = NO;
		boatScrollBg2.visible = NO;
		boatScrollBg3.visible = NO;
	} else {
		if (totalHp <= 0) {
			CCLOG(@"ERROR totalHp is 0");
			return;
		};
		
		boatScrollBg1.visible = YES;
		boatScrollBg2.visible = YES;
		boatScrollBg3.visible = YES;
		
		float radio = currentHp / totalHp;
		float width = boatScrollBg.contentSize.width-boatScrollBg1.contentSize.width-boatScrollBg3.contentSize.width-x*2;
		float finalWidth = width * radio;
		
		boatScrollBg2.scaleX = finalWidth/boatScrollBg2.contentSize.width;
		boatScrollBg3.position = ccpAdd(boatScrollBg2.position, ccp(finalWidth, 0));
	}
}

@end
