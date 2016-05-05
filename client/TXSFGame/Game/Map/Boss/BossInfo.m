//
//  BossInfo.m
//  TXSFGame
//
//  Created by Soul on 13-3-28.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "BossInfo.h"
#import "Config.h"
#import "WorldBossManager.h"
#import "CCNode+AddHelper.h"
#import "GameConnection.h"
#import "MonsterIconViewerContent.h"


@implementation BossInfo

@synthesize maxHp = _maxHp;
@synthesize curHp = _curHp;
@synthesize bossId = _bossId;
@synthesize bossInfoType = _bossInfoType;
@synthesize hurt = _hurt;

+(BossInfo*)create:(BossInfoType)__bossInfoType{
	BossInfo* _info = [BossInfo node];
	_info.bossInfoType = __bossInfoType;
	return _info;
}

-(void)onEnter{
	[super onEnter];
	
	if (self.bossInfoType == BossInfoType_world) {
		[GameConnection addPost:ConnPost_BossInfo_time_setting_worldboss target:self call:@selector(updateStopTime:)];
	}else if (self.bossInfoType == BossInfoType_union){
		[GameConnection addPost:ConnPost_BossInfo_time_setting_unionboss target:self call:@selector(updateStopTime:)];
	}
	
	//[GameConnection addPost:ConnPost_BossInfo_time_setting target:self call:@selector(updateStopTime:)];
	
	CCSprite* _sprite = [CCSprite spriteWithFile:@"images/ui/worldboss/boss_1.png"];
	self.contentSize = _sprite.contentSize;
	[self Category_AddChildToCenter:_sprite];
	
	_iconWidth = _iconHeight = self.contentSize.height ;
	
	_name = [CCLabelFX labelWithString:@""
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:getCommonFontName(FONT_1)
							  fontSize:26
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f
						   shadowColor:ccc4(20,20,20, 128)
							 fillColor:ccc4(255, 0, 0, 255)];
	[self addChild:_name z:1];
	_name.anchorPoint = ccp(0,0.5);
	_name.position = ccp(_iconWidth,
						 cFixedScale(45));
	
	_blood = [CCLabelFX labelWithString:@""
							 dimensions:CGSizeMake(0,0)
							  alignment:kCCTextAlignmentCenter
							   fontName:getCommonFontName(FONT_1)
							   fontSize:18
						   shadowOffset:CGSizeMake(-1.5, -1.5)
							 shadowBlur:1.0f
							shadowColor:ccc4(20,20,20, 128)
							  fillColor:ccc4(251, 237, 197, 255)];
	[self addChild:_blood z:10];
	
	_time = [CCLabelFX labelWithString:@""
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:getCommonFontName(FONT_1)
							  fontSize:18
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f
						   shadowColor:ccc4(20,20,20, 128)
							 fillColor:ccc4(251, 237, 197, 255)];
	[self addChild:_time z:10];
	
	
	
	_blood.position = ccp(self.contentSize.width/2 + _iconWidth/2,
						  self.contentSize.height - cFixedScale(45));
	
	_time.position = ccp(self.contentSize.width/2 + _iconWidth/2,
						 self.contentSize.height - cFixedScale(75));
	
	CCSprite * p1 = [CCSprite spriteWithFile:@"images/ui/worldboss/boss_2.png"];
	CCSprite * p2 = [CCSprite spriteWithFile:@"images/ui/worldboss/boss_3.png"];
	CCSprite * p3 = [CCSprite spriteWithFile:@"images/ui/worldboss/boss_4.png"];
	
	p1.anchorPoint = ccp(0,0.5);
	p2.anchorPoint = ccp(0,0.5);
	p3.anchorPoint = ccp(0,0.5);
	
	p1.opacity = 100;
	p2.opacity = 100;
	p3.opacity = 100;
	
	[self addChild:p1 z:2 tag:201];
	[self addChild:p2 z:1 tag:202];
	[self addChild:p3 z:2 tag:203];
	
	p1.position = ccp(_iconWidth - p1.contentSize.width,
					  self.contentSize.height - cFixedScale(45));
	
	[self updateBloodVolume:0];
	
	
	CCSprite * p4 = [CCSprite spriteWithFile:@"images/ui/worldboss/boss_2.png"];
	CCSprite * p5 = [CCSprite spriteWithFile:@"images/ui/worldboss/boss_3.png"];
	CCSprite * p6 = [CCSprite spriteWithFile:@"images/ui/worldboss/boss_4.png"];
	
	p4.anchorPoint = ccp(0,0.5);
	p5.anchorPoint = ccp(0,0.5);
	p6.anchorPoint = ccp(0,0.5);
	
	[self addChild:p4 z:5 tag:301];
	[self addChild:p5 z:4 tag:302];
	[self addChild:p6 z:5 tag:303];
	
	p4.position = ccp(_iconWidth - p4.contentSize.width,
					  self.contentSize.height - cFixedScale(45));
	
	[self updateBloodVolumeRealTime:0];
	
	
	
	[self unschedule:@selector(updateHurt:)];
	[self schedule:@selector(updateHurt:) interval:1/30.0f];
	
}

-(NSString*)timeToString:(int)_value{
	
	int stopTime = _value;
	
	int s = stopTime%60;
	int m = stopTime/60%60;
	int h = stopTime/(60*60);
	
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


-(void)updateStopTime:(NSNotification*)notification{
	NSNumber * number = notification.object;
	if (number != nil) {
		if (_time != nil) {
			int _value = [number intValue];
			
			if (_value < 0) {
				_value = abs(_value);
				NSString* str = [self timeToString:_value];
				//NSString* string = [NSString stringWithFormat:@"倒计时：%@",str];
                NSString* string = [NSString stringWithFormat:NSLocalizedString(@"boss_count_down",nil),str];
				_time.string = string;
			}else{
				NSString* str = [self timeToString:_value];
				//NSString* string = [NSString stringWithFormat:@"剩余时间：%@",str];
                NSString* string = [NSString stringWithFormat:NSLocalizedString(@"boss_overplus_time",nil),str];
				_time.string = string;
			}
			
		}
	}
	
}

-(void)onExit{
	
	[self unschedule:@selector(updateHurt:)];
	[GameConnection removePostTarget:self];
	
	[super onExit];
}

-(void)updateHurt:(ccTime)_time{
	if (_curHp >= _hurt) {
		_curHp -= 10000;
		
		if (_curHp < _hurt) {
			_curHp = _hurt;
		}
		
		[self updateBloodVolume:_curHp];
	}
}

-(void)setHurt:(int)hurt{
	_hurt = hurt;
	[self updateBloodVolumeRealTime:_hurt];
}

-(void)setBossId:(int)bossId{
	_bossId = bossId;
	
	[self removeChildByTag:103 cleanup:YES];
	
	
	if (_name != nil) {
		_name.string = @"";
	}
	
	if (_bossId <= 0) {
		return ;
	}
	
	CCSprite * icon = [MonsterIconViewerContent create:_bossId];
	
	if(icon){
		icon.scaleX = -1;
		icon.anchorPoint = ccp(0.5, 0);
		icon.position = ccp(_iconWidth/2 , 0);
		[self addChild:icon z:1 tag:103];
	}
	
	NSDictionary* dict = [[GameDB shared] getMonsterInfo:_bossId];
	
	if (dict != nil) {
		NSString* ____name = [dict objectForKey:@"name"];
		if (____name && _name != nil) {
			_name.string = ____name;
		}
	}
}

-(void)updateBloodVolume:(float)_value{
	
	CCNode * p1 = [self getChildByTag:201];
	CCNode * p2 = [self getChildByTag:202];
	CCNode * p3 = [self getChildByTag:203];
	
	if (_value > 0 && _maxHp > 0) {
		
		p2.scaleX = _value/_maxHp ;
		
		if (p2.scaleX > 1.0) {
			p2.scaleX = 1.0f;
		}else if (p2.scaleX < 0){
			p2.scaleX = 0.0f;
		}
		
		p1.visible = YES;
		p2.visible = YES;
		p3.visible = YES;
		
		if(p2) p2.position = ccp(p1.position.x+p1.contentSize.width,p1.position.y);
		if(p3) p3.position = ccp(p2.position.x+p2.contentSize.width*p2.scaleX,p2.position.y);
		
	}else{
		p1.visible = NO;
		p2.visible = NO;
		p3.visible = NO;
	}
	
	if (_blood != nil) {
		//NSString* _info = [NSString stringWithFormat:@"剩余血量：%d/%d",(int)_value,(int)_maxHp];
        NSString* _info = [NSString stringWithFormat:NSLocalizedString(@"boss_overplus_hemo",nil),(int)_value,(int)_maxHp];
		_blood.string = _info;
	}
}

-(void)updateBloodVolumeRealTime:(float)_value{
	
	CCNode * p1 = [self getChildByTag:301];
	CCNode * p2 = [self getChildByTag:302];
	CCNode * p3 = [self getChildByTag:303];
	
	if (_value > 0 && _maxHp > 0) {
		
		p2.scaleX = _value/_maxHp ;
		
		if (p2.scaleX > 1.0) {
			p2.scaleX = 1.0f;
		}else if (p2.scaleX < 0){
			p2.scaleX = 0.0f;
		}
		
		p1.visible = YES;
		p2.visible = YES;
		p3.visible = YES;
		
		if(p2) p2.position = ccp(p1.position.x+p1.contentSize.width,p1.position.y);
		if(p3) p3.position = ccp(p2.position.x+p2.contentSize.width*p2.scaleX,p2.position.y);
		
	}else{
		p1.visible = NO;
		p2.visible = NO;
		p3.visible = NO;
	}
	
}

@end
