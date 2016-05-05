//
//  DragonBossHpInfo.m
//  TXSFGame
//
//  Created by efun on 13-9-9.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "DragonBossHpInfo.h"
#import "Config.h"
#import "GameConnection.h"
#import "DragonFightData.h"

#define Tag_bossHp				101
#define Offset_x				cFixedScale(8.5f)
#define Offset_label_y			cFixedScale(7.0f)

@implementation DragonBossHpInfo

-(void)onEnter
{
	[super onEnter];
	
	bossScrollBg = [CCSprite spriteWithFile:@"images/ui/dragon/bg_hp_1.png"];
	bossScrollBg.anchorPoint = CGPointZero;
	[self addChild:bossScrollBg];
	
	self.contentSize = bossScrollBg.contentSize;
	
	bossHpPoint = ccp(self.contentSize.width/2, self.contentSize.height/2+Offset_label_y);
	
	bossScrollBg1 = [CCSprite spriteWithFile:@"images/ui/dragon/bg_hp_1_1.png"];
	bossScrollBg1.anchorPoint = ccp(0, 0.5f);
	bossScrollBg1.position = ccp(Offset_x, cFixedScale(13.5f));
	
	[self addChild:bossScrollBg1];
	
	bossScrollBg2 = [CCSprite spriteWithFile:@"images/ui/dragon/bg_hp_1_2.png"];
	bossScrollBg2.anchorPoint = ccp(0, 0.5f);
	bossScrollBg2.position = ccp(bossScrollBg1.position.x+bossScrollBg1.contentSize.width,
								 bossScrollBg1.position.y);
	
	[self addChild:bossScrollBg2];
	
	bossScrollBg3 = [CCSprite spriteWithFile:@"images/ui/dragon/bg_hp_1_3.png"];
	bossScrollBg3.anchorPoint = ccp(0, 0.5f);
	
	[self addChild:bossScrollBg3];
	
	[self updateHp];
	[GameConnection addPost:ConnPost_Dragon_local_bossHp target:self call:@selector(updateHp)];
}

-(void)onExit
{
	[GameConnection removePostTarget:self];
	[super onExit];
}

-(void)updateHp
{
	[self removeChildByTag:Tag_bossHp];
	
	float currentHp = [DragonFightData shared].bossHp;
	float totalHp = [DragonFightData shared].bossTotalHp;
	
	float fontSize = 16.0f;
	
	NSString *bossHpString = [NSString stringWithFormat:NSLocalizedString(@"dragon_boss_hp_label",nil), currentHp, totalHp];
	CCSprite *label = drawBoundString(bossHpString,
									  8,
									  GAME_DEF_CHINESE_FONT,
									  fontSize,
									  ccc3(251, 236, 201), ccBLACK);
	label.anchorPoint = ccp(0.5, 0.5);
	label.position = bossHpPoint;
	label.tag = Tag_bossHp;
	[self addChild:label z:100];
	
	if (currentHp <= 0) {
		bossScrollBg1.visible = NO;
		bossScrollBg2.visible = NO;
		bossScrollBg3.visible = NO;
	} else {
		if (totalHp <= 0) {
			CCLOG(@"ERROR totalHp is 0");
			return;
		}
		
		bossScrollBg1.visible = YES;
		bossScrollBg2.visible = YES;
		bossScrollBg3.visible = YES;
		
		float radio = currentHp / totalHp;
		float width = bossScrollBg.contentSize.width-bossScrollBg1.contentSize.width-bossScrollBg3.contentSize.width-Offset_x*2;
		float finalWidth = width * radio;
		
		bossScrollBg2.scaleX = finalWidth/bossScrollBg2.contentSize.width;
		
		bossScrollBg3.position = ccpAdd(bossScrollBg2.position, ccp(finalWidth, 0));
	}
}

@end
