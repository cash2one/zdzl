//
//  BossRank.m
//  TXSFGame
//
//  Created by Soul on 13-4-10.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "BossRank.h"
#import "CCLabelFX.h"
#import "Config.h"
#import "CCNode+AddHelper.h"

#define POS_PLAYER_NAME_OFFSET_W	20
#define POS_PLAYER_NAME_OFFSET_h	50

@implementation RankMember

@synthesize des = _des;

+(RankMember*)memberWithDimension:(CGSize)_size :(NSString *)_info{
	
	RankMember* _member = [[[RankMember alloc] initWithDimension:_size
																:_info] autorelease];
	return _member;
	
}

-(id)initWithDimension:(CGSize)_size :(NSString*)_str{
	if ((self=[super init])) {
		self.contentSize = _size;
		self.des = _str;
	}
	return self;
}

-(void)onEnter{
	[super onEnter];
	
	if (_des) {
		NSArray* array = [_des componentsSeparatedByString:@"|"];
		if (array.count < 3) {
			return ;
		}
		
		NSString* str1 = [array objectAtIndex:0];
		CCLOG(@"RankMember->e1");
		
		CCLabelFX *label1 = [CCLabelFX labelWithString:str1
											dimensions:CGSizeMake(0,0)
											 alignment:kCCTextAlignmentCenter
											  fontName:getCommonFontName(FONT_1)
											  fontSize:18
										  shadowOffset:CGSizeMake(-1.5, -1.5)
											shadowBlur:1.0f
										   shadowColor:ccc4(20,20,20, 128)
											 fillColor:ccc4(238, 227, 205, 255)];
		
		label1.anchorPoint = ccp(0, 0.5);
		[self addChild:label1 z:1];
		label1.position = ccp(cFixedScale(2),self.contentSize.height/2);
		
		
		NSString* str2 = [array objectAtIndex:1];
		CCLOG(@"RankMember->e2");
		CCLabelFX *label2 = [CCLabelFX labelWithString:str2
											dimensions:CGSizeMake(0,0)
											 alignment:kCCTextAlignmentCenter
											  fontName:getCommonFontName(FONT_1)
											  fontSize:18
										  shadowOffset:CGSizeMake(-1.5, -1.5)
											shadowBlur:1.0f
										   shadowColor:ccc4(20,20,20, 128)
											 fillColor:ccc4(255, 235, 123, 255)];
		
		label2.anchorPoint = ccp(0, 0.5);
		[self addChild:label2 z:1];
		label2.position = ccp(cFixedScale(2) + label1.contentSize.width ,self.contentSize.height/2);
		
		
		
		NSString* str3 = [array objectAtIndex:2];
		CCLOG(@"RankMember->e3");
		CCLabelFX *label3 = [CCLabelFX labelWithString:str3
											dimensions:CGSizeMake(0,0)
											 alignment:kCCTextAlignmentCenter
											  fontName:getCommonFontName(FONT_1)
											  fontSize:18
										  shadowOffset:CGSizeMake(-1.5, -1.5)
											shadowBlur:1.0f
										   shadowColor:ccc4(20,20,20, 128)
											 fillColor:ccc4(246, 147, 28, 255)];
		
		label3.anchorPoint = ccp(1.0, 0.5);
		[self addChild:label3 z:1];
		label3.position = ccp(self.contentSize.width - cFixedScale(8),self.contentSize.height/2);
		
	}
	
}

-(void)onExit{
	if (_des) {
		[_des release];
		_des = nil ;
	}
	[super onExit];
}

@end

#pragma mark History
@implementation BossRank

-(void)onEnter{
	[super onEnter];
	
	CCSprite* _sprite = [CCSprite spriteWithFile:@"images/ui/worldboss/boss_5.png"];
	_sprite.scaleY = 1.3f;
	_sprite.scaleX = 1.2f;
	
	//Kevin added
	if (iPhoneRuningOnGame()) {
		_sprite.scaleY = 1.3f;
		_sprite.scaleX = 1.4f;
	}
	//---------------------------//
	self.contentSize = CGSizeMake(_sprite.contentSize.width*_sprite.scaleX,
								  _sprite.contentSize.height*_sprite.scaleY);
	[self Category_AddChildToCenter:_sprite];
	
	CCSprite* _line = [CCSprite spriteWithFile:@"images/ui/panel/p18.png"];
	float _zoom = self.contentSize.width / _line.contentSize.width;
	_line.scaleX = _zoom;
	[self addChild:_line z:10 tag:988787];
	_line.position = ccp(self.contentSize.width/2, self.contentSize.height - cFixedScale(65));
	
//	CCLabelFX *label = [CCLabelFX labelWithString:@"伤害统计"
//									   dimensions:CGSizeMake(0,0)
//										alignment:kCCTextAlignmentCenter
//										 fontName:getCommonFontName(FONT_1)
//										 fontSize:28
//									 shadowOffset:CGSizeMake(-1.5, -1.5)
//									   shadowBlur:1.0f
//									  shadowColor:ccc4(20,20,20, 128)
//										fillColor:ccc4(255, 235, 123, 255)];
	CCLabelFX *label = [CCLabelFX labelWithString:NSLocalizedString(@"boss_hurt_count",nil)
									   dimensions:CGSizeMake(0,0)
										alignment:kCCTextAlignmentCenter
										 fontName:getCommonFontName(FONT_1)
										 fontSize:28
									 shadowOffset:CGSizeMake(-1.5, -1.5)
									   shadowBlur:1.0f
									  shadowColor:ccc4(20,20,20, 128)
										fillColor:ccc4(255, 235, 123, 255)];
	label.anchorPoint = ccp(0.5, 1.0);
	[self addChild:label z:10];
	label.position = ccp(self.contentSize.width/2,self.contentSize.height - cFixedScale(20));
	
	
	CCSprite* _lined = [CCSprite spriteWithFile:@"images/ui/panel/p18.png"];
	_lined.scaleX = _zoom;
	[self addChild:_lined z:10 tag:988789];
	_lined.position = ccp(self.contentSize.width/2, cFixedScale(70));
	
	
}

-(void)onExit{
	[super onExit];
}

-(void)updateRank:(NSArray *)_array1 :(NSArray *)_array2 hp:(float)_hp{
	
	for (int i = 1000; i < 1010; i++) {
		[self removeChildByTag:i cleanup:YES];
	}
	
	float _x = self.contentSize.width/2;
	float _y = self.contentSize.height - cFixedScale(80);
	
	if (_array1.count > 0 && _array2.count > 0) {
		for (int i = 0; i < _array1.count; i++) {
			NSString* str = [self getRankString:i];
			float _value = [[_array2 objectAtIndex:i] floatValue]/_hp;
			_value = _value*100;
			str = [str stringByAppendingFormat:@"|%@",[_array1 objectAtIndex:i]];
			str = [str stringByAppendingFormat:@"|%.2f%@",_value,@"%"];
			RankMember* _member = [RankMember memberWithDimension:CGSizeMake(self.contentSize.width, cFixedScale(24))
																 :str];
			_member.anchorPoint = ccp(0.5, 1.0);
			[self addChild:_member z:5 tag:1000+i];
			_member.position = ccp(_x, _y);
			
			_y -= _member.contentSize.height;
		}
	}
}

-(void)updatePlayerHurt:(float)_value hurt:(float)_total{
	CCLabelFX *label3 = (CCLabelFX*)[self getChildByTag:768585];
	
	//100% 嘛!!!
	_value = _value * 100;
//	NSString* _info = [NSString stringWithFormat:@"我的伤害:%d(%.2f%@)",
//					   (int)_total,
//					   _value,
//					   @"%"];
	NSString* _info = [NSString stringWithFormat:NSLocalizedString(@"boss_my_hurt",nil),
					   (int)_total,
					   _value,
					   @"%"];
	if (label3 == nil) {
		label3 = [CCLabelFX labelWithString:_info
								 dimensions:CGSizeMake(0,0)
								  alignment:kCCTextAlignmentCenter
								   fontName:getCommonFontName(FONT_1)
								   fontSize:16
							   shadowOffset:CGSizeMake(-1.5, -1.5)
								 shadowBlur:1.0f
								shadowColor:ccc4(20,20,20, 128)
								  fillColor:ccc4(255, 235, 123, 255)];
		
		label3.anchorPoint = ccp(0, 0.5);
		[self addChild:label3 z:1];
		label3.position = ccp(cFixedScale(8),
							  cFixedScale(POS_PLAYER_NAME_OFFSET_h));
	}else{
		label3.string = _info;
	}
	
}

-(NSString*)getRankString:(int)_index{
	NSString* str = [NSString stringWithFormat:@""];
	if (_index == 0) {
		//str = [NSString stringWithFormat:@"第一名："];
        str = [NSString stringWithFormat:NSLocalizedString(@"boss_rank_first",nil)];
	}else if (_index == 1){
		//str = [NSString stringWithFormat:@"第二名："];
        str = [NSString stringWithFormat:NSLocalizedString(@"boss_rank_second",nil)];
	}else if (_index == 2){
		//str = [NSString stringWithFormat:@"第三名："];
        str = [NSString stringWithFormat:NSLocalizedString(@"boss_rank_third",nil)];
	}else if (_index == 3){
		//str = [NSString stringWithFormat:@"第四名："];
        str = [NSString stringWithFormat:NSLocalizedString(@"boss_rank_fourthly",nil)];
	}else if (_index == 4){
		//str = [NSString stringWithFormat:@"第五名："];
        str = [NSString stringWithFormat:NSLocalizedString(@"boss_rank_fifthly",nil)];
	}
	return str;
}

@end
