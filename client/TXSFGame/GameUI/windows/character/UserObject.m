//
//  UserObject.m
//  TXSFGame
//
//  Created by Soul on 13-3-4.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UserObject.h"
#import "CCNode+AddHelper.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "PlayerDataHelper.h"

#pragma mark UserObject
@implementation UserObject

@synthesize rid = _rid;
@synthesize objectId = _objectId;
@synthesize quality = _quality;

@synthesize event = _event ;

-(int)getType{
	return 0;
}

@end



#define TOUCH_LEVEL			-100
#define BNT_SHIFT_OFFSET	10

#pragma mark UserEquipment
@implementation UserEquipment

@synthesize ueid = _ueid;
@synthesize part = _part;
@synthesize level = _level;

@synthesize isSelect = _isSelect;
@synthesize isPick = _isPick;

@synthesize showInfoCall = _showInfoCall;
@synthesize takeOffCall = _takeOffCall;
@synthesize target = _target ;


+(UserEquipment*)makeEquipment:(int)_eid level:(int)_lv quality:(int)_qua{
	UserEquipment* uquip = [UserEquipment node];
	
	uquip.objectId = _eid ;
	uquip.level = _lv;
	uquip.quality = _qua;
	
	return uquip;
}

-(void)dealloc{
	[super dealloc];
}

-(id)init{
	if (self=[super init]) {
		self.contentSize=CGSizeMake(86, 86);
	}
	return self;
}

-(void)onEnter{
	[super onEnter];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:TOUCH_LEVEL swallowsTouches:YES];
	
}

-(void)onExit{
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

-(int)getType{
	return UIObject_equipment;
}

-(void)setQuality:(ItemQuality)quality{
	_quality = quality;
	
	[self removeChildByTag:2007 cleanup:YES];
	[self removeChildByTag:2008 cleanup:YES];
	
	if (quality < IQ_WHITE) return ;
	
	NSString* path = [NSString stringWithFormat:@"images/ui/common/quality%d.png",quality];
	CCSprite* __sprite = [CCSprite spriteWithFile:path];
	__sprite.tag = 2007 ;
	__sprite.visible= YES;
	[self Category_AddChildToCenter:__sprite];
	
	NSString* path2 = [NSString stringWithFormat:@"images/ui/common/quality%dSelect.png",quality];
	CCSprite* __sprite2 = [CCSprite spriteWithFile:path2];
	__sprite2.tag = 2008;
	__sprite2.visible= NO;
	[self Category_AddChildToCenter:__sprite2];
	
}

-(void)setIsSelect:(BOOL)isSelect{
	_isSelect = isSelect;
	
	CCNode* n1 = [self getChildByTag:2007];
	CCNode* n2 = [self getChildByTag:2008];
	if (isSelect) {
		if (n1 != nil) {
			n1.visible = NO ;
		}
		if (n2 != nil) {
			n2.visible = YES ;
		}
	}else{
		if (n1 != nil) {
			n1.visible = YES ;
		}
		if (n2 != nil) {
			n2.visible = NO ;
		}
	}
	
}

-(void)setObjectId:(int)eid{
	_objectId = eid ;
	
	[self removeChildByTag:3008 cleanup:YES];
	
	if (eid <= 0) return ;
	
	CCSprite* __sprite = getEquipmentIcon(eid);
	
	if (__sprite != nil) {
		__sprite.tag = 3008;
		[self Category_AddChildToCenter:__sprite z:1];
	}
}

-(void)setIsPick:(BOOL)isPick{
	_isPick = isPick ;
	
	CCNode* n1 = [self getChildByTag:2007];//品质
	CCNode* n2 = [self getChildByTag:2008];//品质
	
	CCNode* n3 = [self getChildByTag:2009];//加号
	CCNode* n4 = [self getChildByTag:2010];//数字
	
	CCNode* n5 = [self getChildByTag:2012];//替换
	
	//拿起那个东西的时候就隐藏
	//放下就显示
	if (n1 != nil) {
		n1.visible = !isPick ;
	}
	
	if (n2 != nil) {
		n2.visible = !isPick ;
	}
	
	if (n3 != nil) {
		n3.visible = !isPick ;
	}
	
	if (n4 != nil) {
		n4.visible = !isPick ;
	}
	
	if (n5 != nil) {
		n5.visible = !isPick ;
	}
	
}

-(void)setLevel:(int)level{
	_level = level ;
	
	[self removeChildByTag:2009 cleanup:YES];
	[self removeChildByTag:2010 cleanup:YES];
	
	if (_level <= 0) return ;
	
	CGRect rect = CGRectMake(15*10, 0, 15, 25) ;
	CCSprite *num_1 = [CCSprite spriteWithFile:@"images/ui/num/num-1.png" rect:rect];
	
	CCSprite *num_2 = getImageNumber(@"images/ui/num/num-1.png", 15, 20, _level);
	
	[self addChild:num_1 z:5];
	[self addChild:num_2 z:5];
	
	num_1.anchorPoint = num_2.anchorPoint = ccp(0, 1.0);
	
	num_1.tag = 2009 ;
	num_2.tag = 2010 ;
	
	num_1.position=ccp(0, self.contentSize.height);
	num_2.position=ccp(15, self.contentSize.height);
	
}

-(BOOL)isTouchInSite:(UITouch*)touch{
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	
	CGSize size = self.contentSize;
	if(p.x<-size.width*self.anchorPoint.x)		return NO;
	if(p.x>size.width*(1-self.anchorPoint.x))	return NO;
	if(p.y<-size.height*self.anchorPoint.y)		return NO;
	if(p.y>size.height*(1-self.anchorPoint.y))	return NO;
	
	return YES;
}

-(void)checkLondClick{
	if (self.event == Touch_begin) {
		//TODO long touch event!!
	}
}


- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	if (self.visible == NO) return NO ;
	if ([self isTouchInSite:touch]) {
		CCLOG(@"UserEquipment->ccTouchBegan");
		
		self.event = Touch_begin;
		self.isSelect = YES ;
		
		return YES;
	}
	
	return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	self.event = Touch_move;
	
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	self.event = Touch_end;
	if ([self isTouchInSite:touch]) {
		//TODO
		CCLOG(@"UserEquipment->ccTouchEnded");
		
	}
	self.isSelect = NO;
}

@end
