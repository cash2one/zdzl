//
//  BossAction.m
//  TXSFGame
//
//  Created by Soul on 13-3-28.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "BossAction.h"
#import "CCNode+AddHelper.h"
#import "CCSimpleButton.h"
#import "CCLabelFX.h"
#import "Config.h"
#import "WorldBossManager.h"
#import "AnimationViewer.h"
#import "MapManager.h"
#import "GameLayer.h"
#import "Window.h"
#import "GameConnection.h"

@implementation BossAction

@synthesize type = _type;
@synthesize stopTime = _stopTime;


-(void)onEnter{
	[super onEnter];
}

-(void)setStopTime:(int)stopTime{
	_stopTime = stopTime;
	[self unschedule:@selector(showTime:)];
	[self schedule:@selector(showTime:) interval:1.0f];
}

-(NSString*)timeToString{
	
	int s = _stopTime%60;
	int m = _stopTime/60%60;
	int h = _stopTime/(60*60);
	
	NSString* strH = nil ;
	NSString* strM = nil ;
	NSString* strS = nil ;
	
	if (h > 9) {
		strH = [NSString stringWithFormat:@"%d",h];
	}else{
		strH = [NSString stringWithFormat:@"0%d",h];
	}
	if (m > 9) {
		strM = [NSString stringWithFormat:@"%d",m];
	}else{
		strM = [NSString stringWithFormat:@"0%d",m];
	}
	if (s > 9) {
		strS = [NSString stringWithFormat:@"%d",s];
	}else{
		strS = [NSString stringWithFormat:@"0%d",s];
	}
	
	NSString* result = [NSString stringWithFormat:@"%@:%@:%@",strH,strM,strS];
	
	return result;
	
}

-(void)showTime:(ccTime)_t{
	_stopTime--;
	
	if (_stopTime < 0) {
		_stopTime = 0 ;
		[self unschedule:@selector(showTime:)];
	}
	
	if (_type == BossAction_wait || _type == BossAction_fightCd) {
		CCLabelFX* _time = (CCLabelFX*)[self getChildByTag:2012];
		if (_time) {
			_time.string = [self timeToString];
		}
	}
	
}

-(void)onExit{
	[self unschedule:@selector(showTime:)];
	[super onExit];
}

-(void)doEvent:(CCSimpleButton*)_sender{
	
	if ([[Window shared] isHasWindow]) {
		return ;
	}
	
	if (_type == BossAction_fightCd) {
		CCLOG(@"show abc");
		[self removeChildByTag:2014 cleanup:YES];//效果
		[GameConnection post:BossAction_start_over_cd object:nil];
	}
	
	if (_type == BossAction_fight) {
		CCLOG(@"show efg");
		[self removeChildByTag:2014 cleanup:YES];//效果
		[GameConnection post:BossAction_start_fight object:nil];
	}
	
}

-(void)setType:(BossAction_type)type{
	[MapManager shared].isBlock = NO;
	
	if (_type == type && _type != BossAction_none) {
		return ;
	}
	
	_type = type;
	
	[self unschedule:@selector(showTime:)];
	
	[self removeChildByTag:2013 cleanup:YES];//图
	[self removeChildByTag:2012 cleanup:YES];//字符串
	[self removeChildByTag:2014 cleanup:YES];//效果
	
	if (_type == BossAction_wait) {
		[MapManager shared].isBlock = YES;		
		CCSprite* _sprite = [CCSprite spriteWithFile:@"images/ui/worldboss/bt_wait1.png"];
		self.contentSize = _sprite.contentSize;
		[self Category_AddChildToCenter:_sprite z:1 tag:2013];
		
		CCLabelFX* _time = [CCLabelFX labelWithString:@""
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:getCommonFontName(FONT_1)
								  fontSize:18
							  shadowOffset:CGSizeMake(-1.5, -1.5)
								shadowBlur:1.0f
							   shadowColor:ccc4(20,20,20, 128)
								 fillColor:ccc4(251, 237, 197, 255)];
		
		_time.position = ccp(self.contentSize.width/2, 0);
		[self addChild:_time z:2 tag:2012];
		
	}
	
	if (_type == BossAction_fight) {
		[MapManager shared].isBlock = NO;
		[[[GameLayer shared] content] removeChildByTag:65645 cleanup:YES];
		
		CCSimpleButton* bnt = [CCSimpleButton spriteWithFile:@"images/ui/worldboss/bt_battle1.png"
													  select:@"images/ui/worldboss/bt_battle2.png"];
		self.contentSize = bnt.contentSize;
		//bnt.priority = -80;
		bnt.target = self;
		bnt.call = @selector(doEvent:);
		[self Category_AddChildToCenter:bnt z:1 tag:2013];
		
		AnimationViewer *ani = [AnimationViewer node];
		[self addChild:ani z:10 tag:2014];
		ani.anchorPoint=ccp(0.5, 0.5);
		ani.position=ccp(self.contentSize.width/2,self.contentSize.height/2);
		NSString * path = [NSString stringWithFormat:@"images/animations/task/"];
		NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
		[ani playAnimation:frames];
		
	}
	
	if (_type == BossAction_fightCd) {
		
		[MapManager shared].isBlock = YES;
		
		CCSimpleButton* bnt = [CCSimpleButton spriteWithFile:@"images/ui/worldboss/bt_cd1.png"
													  select:@"images/ui/worldboss/bt_cd2.png"];
		self.contentSize = bnt.contentSize;
		//bnt.priority = -80;
		bnt.target = self;
		bnt.call = @selector(doEvent:);
		[self Category_AddChildToCenter:bnt z:1 tag:2013];
		
		CCLabelFX* _time = [CCLabelFX labelWithString:@""
										   dimensions:CGSizeMake(0,0)
											alignment:kCCTextAlignmentCenter
											 fontName:getCommonFontName(FONT_1)
											 fontSize:18
										 shadowOffset:CGSizeMake(-1.5, -1.5)
										   shadowBlur:1.0f
										  shadowColor:ccc4(20,20,20, 128)
											fillColor:ccc4(251, 237, 197, 255)];
		
		_time.position = ccp(self.contentSize.width/2, 0);
		[self addChild:_time z:2 tag:2012];
		
		AnimationViewer *ani = [AnimationViewer node];
		[self addChild:ani z:10 tag:2014];
		ani.anchorPoint=ccp(0.5, 0.5);
		ani.position=ccp(self.contentSize.width/2,self.contentSize.height/2);
		NSString * path = [NSString stringWithFormat:@"images/animations/task/"];
		NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
		[ani playAnimation:frames];
		
	}
}

@end
