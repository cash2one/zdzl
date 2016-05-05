//
//  WorldBossTips.m
//  TXSFGame
//
//  Created by Max on 13-4-16.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "WorldBossTips.h"
#import "GameUI.h"
#import "WorldBossManager.h"
#import "MapManager.h"
#import "FightManager.h"
#import "TaskTalk.h"
#import "UnionPracticeConfigTeam.h"

@implementation WorldBossTips


@synthesize isStart;
static bool thisTimeClose;
static WorldBossTips *wbt;


+(void)updateStatus{
	if([MapManager shared].mapType != Map_Type_Standard){
		if(wbt){
			[wbt removeFromParentAndCleanup:true];
			wbt = nil ;
		}
		return;
	}
}

+(void)resetThisTimeClose{
	thisTimeClose=false;
}

@synthesize labelTime;
+(void)show:(bool)b{
	if(thisTimeClose){
		if(wbt){
			[wbt removeFromParentAndCleanup:true];
			wbt = nil ;
		}
		return;
	}
	if([FightManager isFighting]){
		if(wbt){
			[wbt removeFromParentAndCleanup:true];
			wbt = nil ;
		}
		return;
	}
	if([TaskTalk isTalking]){
		if(wbt){
			[wbt removeFromParentAndCleanup:true];
			wbt = nil ;
		}
		return;
	}
	if ([UnionPracticeConfigTeam isOpen]) {
		if(wbt){
			[wbt removeFromParentAndCleanup:true];
			wbt = nil ;
		}
		return ;
	}
	if([MapManager shared].mapType!=Map_Type_Standard){
		if(wbt){
			[wbt removeFromParentAndCleanup:true];
			wbt = nil ;
		}
		return;
	}
	
	if ([WorldBossManager getStartTime] <= 0) {
		if(wbt){
			[wbt removeFromParentAndCleanup:true];
			wbt = nil ;
		}
		return ;
	}
	
	if(!wbt){
		wbt=[WorldBossTips node];
		wbt.isStart=b;
		id move=[CCMoveBy actionWithDuration:4 position:ccp(0,cFixedScale(470))];
		if (iPhoneRuningOnGame()) {
			[wbt setPosition:ccp([GameUI shared].contentSize.width-130/2.0f-227/4.0f, -300/2.0f)];
		}else{
			[wbt setPosition:ccp([GameUI shared].contentSize.width-[GameUI shared].contentSize.width/4, -300)];
		}
		[wbt runAction:move];
		[[GameUI shared]addChild:wbt];
	}else{
		int time=[WorldBossManager getStartTime];
		[wbt.labelTime setString:[NSString stringWithFormat:@"%.2d:%.2d",time/60,time%60]];
		if(time<=0){
			[wbt closeAct];
		}
	}
}

+(void)hide{
	if(wbt){
		[wbt removeFromParentAndCleanup:true];
		wbt = nil ;
	}
}

-(void)onEnter{
	[super onEnter];
	thisTimeClose=false;
	CCSprite *bg=[CCSprite spriteWithFile:@"images/ui/worldboss/bg_tips.png"];
	CCSimpleButton *close_btn=[CCSimpleButton spriteWithFile:@"images/ui/worldboss/btn_tipsclose.png"];
	float fontSize=20;
	if (iPhoneRuningOnGame()) {
		fontSize=22;
	}
	
	float centerX = bg.contentSize.width/2;
	
	//CCSprite *str1=drawString(isStart?@"首领战#ffff00|已经开始":@"首领战#ffff00|即将开始", CGSizeMake(300, 1) , getCommonFontName(FONT_1), fontSize, 24, @"ffffff");
    CCSprite *str1=drawString(isStart?NSLocalizedString(@"world_boss_tips_open",nil):NSLocalizedString(@"world_boss_tips_will_open",nil), CGSizeMake(300, 1) , getCommonFontName(FONT_1), fontSize, 24, @"ffffff");
    //CCSprite *str2=drawString(@"点击加入", CGSizeMake(300, 1) , getCommonFontName(FONT_1), fontSize, 24, @"ffff00");
    CCSprite *str2=drawString(NSLocalizedString(@"world_boss_tips_enter",nil), CGSizeMake(300, 1) , getCommonFontName(FONT_1), fontSize, 24, @"ffff00");
	CCSimpleButton *b=[CCSimpleButton spriteWithNode:str2];
	[b setTarget:self];
	[b setCall:@selector(enterAct)];
	
	[close_btn setTarget:self];
	[close_btn setCall:@selector(closeAct)];
	CCSprite *bosslogo=[CCSprite spriteWithFile:@"images/ui/richang_icon/richang4.png"];
	
	int time=[WorldBossManager getStartTime];
	fontSize=16;
	if (iPhoneRuningOnGame()) {
		fontSize=9;
	}
	
	labelTime=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%.2d : %.2d",time/60,time%60] fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	
	[str1 setPosition:ccp(cFixedScale(150), cFixedScale(70))];
	[close_btn setPosition:ccp(bg.contentSize.width-close_btn.contentSize.width/1.5, bg.contentSize.height-close_btn.contentSize.height/1.5)];
	//[b setPosition:ccp(cFixedScale(150), cFixedScale(40))];
	b.anchorPoint = ccp(0,0.5);
	b.position = ccp(centerX + cFixedScale(10), cFixedScale(40));
	
	//[labelTime setPosition:ccp(cFixedScale(40), cFixedScale(40))];
	labelTime.anchorPoint = ccp(1.0, 0.5);
	labelTime.position = ccp(centerX - cFixedScale(10), cFixedScale(40));
	
	[bosslogo setPosition:ccp(cFixedScale(40), cFixedScale(80))];
	
	
	[bg addChild:bosslogo];
	[bg addChild:labelTime];
	[bg addChild:str1];
	[bg addChild:b];
	[bg addChild:close_btn];
	[self addChild:bg];
	
}

-(void)closeAct{
//    if ([[Window shared] isHasWindow]) {
//        return;
//    }
	thisTimeClose=true;
	[self removeFromParentAndCleanup:true];
}

-(void)enterAct{
    if ([[Window shared] isHasWindow]) {
        return;
    }
	[self closeAct];
	[WorldBossManager enterWorldBoss];
}

-(void)onExit{
	thisTimeClose=true;
	wbt=nil;
	[super onExit];
}



@end
