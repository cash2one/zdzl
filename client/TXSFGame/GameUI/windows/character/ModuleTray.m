//
//  ModuleTray.m
//  TXSFGame
//
//  Created by efun on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "ModuleTray.h"
#import "Item.h"
#import "CCNode+AddHelper.h"
#import "JewlIconViewerContent.h"
#import "ItemIconViewerContent.h"
#import "JewelHelper.h"

#define ModuleTray_size		CGSizeMake(cFixedScale(86), cFixedScale(86))
#define ModuleTray_Icon_tag		10010

@implementation ModuleTray

@synthesize xid = _xid;
@synthesize uxid = _uxid;
@synthesize belongId = _belongId;
@synthesize type = _type;
@synthesize takeOffTarget = _takeOffTarget;
@synthesize takeOffCall = _takeOffCall;

-(id)init
{
	if (self = [super init]) {
		self.contentSize = ModuleTray_size;
	}
	return self;
}

-(void)dealloc
{
	[super dealloc];
}

-(void)onEnter
{
	[super onEnter];
	
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-148 swallowsTouches:YES];
	
	CCSprite* background = [CCSprite spriteWithFile:@"images/ui/common/quatily0.png"];
	[self addChild:background z:-1];
	background.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
}

-(void)onExit
{
	CCDirector *director =  [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

+(ModuleTray*)create:(ItemTray_type)_t
{
	ModuleTray* tray = [ModuleTray node];
	
	tray.type = _t;
	
	return tray;
}

-(void)doTakeOffItem
{
	self.xid = 0;
	self.uxid = 0;
	self.belongId = 0;
	
	[self removeChildByTag:ModuleTray_Icon_tag];
}

-(void)updateWithDictionary:(int)_bid dict:(NSDictionary *)_dict
{
	[self doTakeOffItem];
	
	if (_dict == nil) {
		CCLOG(@"ModuleTray->updateWithDictionary->dict is nil");
		return;
	}
	
	self.belongId = _bid;
	self.uxid = [[_dict objectForKey:@"id"] intValue];
	
	int _level = [[_dict objectForKey:@"level"] intValue];
	int _quality = 0;
	
	CCSprite *icon = nil;
	
	if (_type == ItemTray_item_jewel) {
		
		self.xid = [[_dict objectForKey:@"gid"] intValue];
		_quality = [[JewelHelper shared] getJewelQuality:_xid];
		
		float upSucc = [[_dict objectForKey:@"upSucc"] floatValue];
		BOOL isHadRate = (BOOL)(upSucc > 0);
		
		JewlIconViewerContent *jewelIcon  = [JewlIconViewerContent create:_xid];
		jewelIcon.isHadRate = isHadRate;
		
		icon = jewelIcon;
		
	} else if (_type == ItemTray_item_stone) {
		
		self.xid = [[_dict objectForKey:@"iid"] intValue];
		_quality = [[JewelHelper shared] getItemQuality:_xid];
		icon = [ItemIconViewerContent create:_xid];
		
	}
	
	if (icon) {
		Item* _item = [Item createByIcon:icon quality:_quality count:0 level:_level];
		[self Category_AddChildToCenter:_item z:2 tag:ModuleTray_Icon_tag];
	}
}

-(void)updateWithDictionary:(NSDictionary *)_dict
{
	[self updateWithDictionary:0 dict:_dict];
}

-(void)takeOffItem
{
	if (_uxid <= 0) {
		return;
	}
	
	if (_takeOffTarget != nil && _takeOffCall != nil) {
		NSMutableDictionary* dict = [NSMutableDictionary dictionary];
		[dict setObject:[NSNumber numberWithInt:_uxid] forKey:@"uxid"];
		[dict setObject:[NSNumber numberWithInt:_belongId] forKey:@"belongId"];
		
		[_takeOffTarget performSelector:_takeOffCall
							 withObject:dict];
	}
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

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
	CCNode* ___node = [self getChildByTag:ModuleTray_Icon_tag];
	if (___node != nil) {
		if ([___node isKindOfClass:[Item class]]) {
			Item* _temp = (Item*)___node;
			[_temp showOther:YES];
		}
		___node.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	}
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	if ([self isTouchInSite:touch]) {
		CCLOG(@"ModuleTray->ccTouchBegan:%d",_uxid);
		touchSwipe_ = touchPoint;
		
		status_ = 1 ;
		
		return YES;
	}
	return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	
	if ( (status_ == 1)&&((fabsf(touchPoint.x-touchSwipe_.x)>= 10)||(fabsf(touchPoint.y-touchSwipe_.y) >= 10))){
		
		status_ = 2;
		touchSwipe_ = touchPoint;
		
		[self.parent reorderChild:self z:INT16_MAX];
		
		CCNode* ___node = [self getChildByTag:ModuleTray_Icon_tag];
		if (___node != nil) {
			if ([___node isKindOfClass:[Item class]]) {
				Item* _temp = (Item*)___node;
				[_temp showOther:NO];
			}
		}
		
	}
	
	if (status_ == 2) {
		CGPoint temp = ccpSub(touchPoint, touchSwipe_);
		CCLOG(@"touchMoved:x=%f|y=%f",temp.x,temp.y);
		CGPoint newPt = ccpAdd(temp, ccp(self.contentSize.width/2, self.contentSize.height/2));
		
		CCNode* ___node = [self getChildByTag:ModuleTray_Icon_tag];
		if (___node != nil) {
			___node.position = newPt;
		}
	}
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	if (status_ == 1) {
		if (self.uxid > 0) {
			[self doRequestShowInfo];
		}
	}
	
	if (status_ == 2) {
		[self.parent reorderChild:self z:INT16_MAX-10];
		
		CCNode* ___node = [self getChildByTag:ModuleTray_Icon_tag];
		if (___node != nil) {
			if ([___node isKindOfClass:[Item class]]) {
				Item* _temp = (Item*)___node;
				[_temp showOther:YES];
				_temp.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
			}
		}
		
		[self takeOffItem];
	}
}

-(void)doRequestShowInfo
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	[dict setObject:[NSNumber numberWithInt:self.uxid] forKey:@"id"];
	[dict setObject:[NSNumber numberWithInt:self.type] forKey:@"type"];
	[GameConnection post:ConnPost_request_showInfo object:dict];
}

@end
