//
//  FishAction.m
//  TXSFGame
//
//  Created by huang shoujun on 13-1-21.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "FishAction.h"
#import "GameDB.h"
#import "Game.h"
#import "GameLayer.h"
#import "CCSimpleButton.h"
#import "AlertManager.h"

static FishAction* s_FishAction=nil;

@implementation FishAction
@synthesize iid;
@synthesize target;
@synthesize call;

+(id)show:(id)_target call:(SEL)call{
	[FishAction stopAll];
	s_FishAction = [FishAction node];
	s_FishAction.target=_target;
	s_FishAction.call=call;
	[[Game shared] addChild:s_FishAction z:INT32_MAX];
	return s_FishAction;
}
+(void)stopAll{
	if (s_FishAction) {
		[s_FishAction removeFromParentAndCleanup:YES];
		s_FishAction = nil;
	}
}
+(BOOL)checkFishing{
	if (s_FishAction != nil) {
		return YES ;
	}
	return NO;
}

-(void)dealloc{
	if (fishActionSetting != nil) {
		[fishActionSetting release];
		fishActionSetting = nil;
	}
	[super dealloc];
}

-(void)onExit{
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	s_FishAction = nil;
	
	[super onExit];
}
-(void)onEnter{
	[super onEnter];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-200 swallowsTouches:YES];
	
	CGSize win = [CCDirector sharedDirector].winSize;
	CCLayerColor *face = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 128) width:win.width height:win.height];
	[self addChild:face z:0];
	[self startFish];
	
	isDoneAction = NO;
}
-(void)startFish{
	CGSize win = [CCDirector sharedDirector].winSize;
	[self removeChildByTag:56 cleanup:YES];
	[self removeChildByTag:57 cleanup:YES];
	[self removeChildByTag:58 cleanup:YES];
	
	CCSprite *back = [CCSprite spriteWithFile:@"images/ui/fish/back.png"];
	[self addChild:back z:INT16_MAX tag:56];
	back.position=ccp(win.width/2, win.height/2);
	
	CCSprite *center = [CCSprite spriteWithFile:@"images/ui/fish/center.png"];
	[self addChild:center z:INT16_MAX tag:57];
	center.position=ccp(win.width/2, win.height/2);
	[back runAction:[CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:0.1 angle:5.0f]]];
	
	
	
	CCSprite *light = [CCSprite spriteWithFile:@"images/ui/fish/light.png"];
	[center addChild:light z:-1];
	light.position=ccp(center.contentSize.width/2, center.contentSize.height/2);
	
	m_Buoy = [CCSprite spriteWithFile:@"images/ui/fish/light.png"];
	[self addChild:m_Buoy];
	m_Buoy.position=ccp(win.width/2, win.height/2);
	
	m_Perfect = [CCSprite spriteWithFile:@"images/ui/fish/light1.png"];
	[self addChild:m_Perfect z:INT32_MAX];
	m_Perfect.position=ccp(win.width/2, win.height/2);
	m_Perfect.visible=NO;
	
	id act = [self getFishingAction];
	[m_Buoy runAction:act];
	
}
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	[self finishFish];
	return YES;
}
// 起钓
-(void)finishFish
{
	if (isDoneAction) {
		return;
	}
	
	fishUpType = FishUp_lose;
	if (m_Buoy) {
		float _value = m_Buoy.scale;
		if (_value >= 0.8f && _value <= 1.2f) {
			fishUpType = FishUp_perfect;
		}else if (_value < 0.8 && _value > 0.3f){
			fishUpType = FishUp_good;
		}
	}
	
	if (target != nil && call != nil) {
		if ([target respondsToSelector:call]) {
			[target performSelector:call withObject:[NSString stringWithFormat:@"%d", fishUpType]];
		}
	}
	
	[FishAction stopAll];
	isDoneAction = YES;
}

-(int)getRandomCount{
	if (fishActionSetting == nil) {
		NSDictionary* s_setting = [[GameDB shared] getGlobalConfig];
		fishActionSetting = [NSString stringWithFormat:@"%@",[s_setting objectForKey:@"fishActionSetting"]];
		[fishActionSetting retain];
	}
	
	NSArray* ary = [fishActionSetting componentsSeparatedByString:@"|"];
	if (ary != nil ) {
		for (NSString* info in ary) {
			NSArray* arry = [info componentsSeparatedByString:@":"];
			if ([arry count] == 3) {
				int vip = [[arry objectAtIndex:0] intValue];
				int num = [[arry objectAtIndex:1] intValue];
				int pVip = [[GameConfigure shared] getPlayerVipLevel];
				
				if (vip == pVip) {
					return num;
				}
			}
		}
	}
	
	return 15;
}

-(float)getCourseTime{
	if (fishActionSetting == nil) {
		NSDictionary* s_setting = [[GameDB shared] getGlobalConfig];
		fishActionSetting = [NSString stringWithFormat:@"%@",[s_setting objectForKey:@"fishActionSetting"]];
		[fishActionSetting retain];
	}
	
	NSArray* ary = [fishActionSetting componentsSeparatedByString:@"|"];
	if (ary != nil ) {
		for (NSString* info in ary) {
			NSArray* arry = [info componentsSeparatedByString:@":"];
			if ([arry count] == 3) {
				int vip = [[arry objectAtIndex:0] intValue];
				float times = [[arry objectAtIndex:2] floatValue];
				int pVip = [[GameConfigure shared] getPlayerVipLevel];
				if (vip == pVip) {
					return times;
				}
			}
		}
	}
	
	return 0.0f;
}

-(id)getFishingAction{
	int actTime = [self getRandomCount];
	
	int mun = getRandomInt(5,actTime);
	NSMutableArray* array = [NSMutableArray array];
	float _rate_in = 1.8;
	float _rate_out = 2.0;
	
	m_Buoy.scale = 1.3f;
	float _amx = 2.5f;
	
	id start = [CCEaseBackOut actionWithAction:[CCScaleTo actionWithDuration:1 scale:_amx]];
	[array addObject:start];
	
	BOOL _result = YES ;
	for (int i = 0; i < mun; i++) {
		
		int _value = getRandomInt(1300, 2100);
	    float fvalue = _value*0.001f;
		
		float t = fabsf(_amx - fvalue);
		if (t < 0.3) {
			int temp = 0 ;
			while (temp < mun) {
				_value = getRandomInt(1300, 2100);
				fvalue = _value*0.001f;
				t = fabsf(_amx - fvalue);
				if (t > 0.3) {
					break ;
				}
				temp++;
			}
		}
		
		if (_amx > fvalue) {
			_result = YES ;
			t = t*_rate_in;
		}else{
			_result = NO ;
			t = t*_rate_out;
		}
		
		_amx = fvalue;
		id act1 = [CCScaleTo actionWithDuration:t scale:fvalue];
		if (_result) {
			id a1 = [CCEaseBounceIn actionWithAction:act1];
			[array addObject:a1];
		}else{
			id a1 = [CCEaseBackOut actionWithAction:act1];
			[array addObject:a1];
		}
		
	}
	
	//-------------------------------------------------
	float t2 = fabsf(_amx - 1.0f);
	t2 = t2*_rate_in/5;
	id act2 = [CCScaleTo actionWithDuration:t2 scale:1.0f];
	[array addObject:act2];
	//-------------------------------------------------
	id act3 = [CCCallFunc actionWithTarget:self selector:@selector(setPerfect)];
	[array addObject:act3];
	//-------------------------------------------------
	float t3 = fabsf(1.0f - 0.2f);
	t3 = t3*_rate_in/4;
	id act4 = [CCScaleTo actionWithDuration:t3 scale:0.2f];
	[array addObject:act4];
	//-------------------------------------------------
	id act5 = [CCCallFunc actionWithTarget:self selector:@selector(setReStart)];
	[array addObject:act5];
	//-------------------------------------------------
	
	return [CCSequence actionWithArray:array];
}

-(void)setPerfect{
	m_Perfect.visible=YES;
	int delayTime = [self getCourseTime];
	
	id act1 = [CCDelayTime actionWithDuration:delayTime];
	id act2 = [CCCallFunc actionWithTarget:self selector:@selector(showPerfect)];
	[m_Perfect runAction:[CCSequence actionOne:act1 two:act2]];
}
-(void)showPerfect{
	if (m_Perfect) {
		m_Perfect.visible=NO;
	}
}
-(void)setReStart{
	[m_Buoy stopAllActions];
	id act = [self getFishingAction];
	[m_Buoy runAction:act];
}

@end

