//
//  ItemManager.m
//  TXSFGame
//
//  Created by Soul on 13-3-7.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ItemManager.h"
#import "Config.h"
#import "ItemTray.h"
#import "PlayerDataHelper.h"
#import "ItemTrayContainer.h"
#import "GameConfigure.h"
#import "JewelHelper.h"

#define DEBUG_2

#define PAGE_DOT_HEIGHT	cFixedScale(35)
#define POS_Pagedot_y	cFixedScale(15)
#define CGS_PageDot_y   cFixedScale(26)

/*
@interface CCTouchDispatcher (ItemManagerTargetedHandlersGetter)
- (id<NSFastEnumeration>) allTargetedHandlers;
@end

@implementation CCTouchDispatcher (ItemManagerTargetedHandlersGetter)
- (id<NSFastEnumeration>) allTargetedHandlers
{
	return targetedHandlers;
}
@end
 */


@implementation ItemCanvas

@synthesize focusIndex = _focusIndex;
@synthesize eachSize = _eachSize;

@synthesize target = _target;
@synthesize callPageCount = _callPageCount;


+(ItemCanvas*)createCanvas:(int)_cap{
	return [[[ItemCanvas alloc] initWithCapacity:_cap] autorelease];
}

-(id)initWithCapacity:(int)_cap{
	
	if ((self = [super init])) {
		
		if (_cap <= 0) {
			_cap = 1 ;
		}
		
		_maxCount = 5 ;
		
		NSDictionary *playerDict = [[GameConfigure shared] getPlayerInfo];
		int playerVip = [[playerDict objectForKey:@"vip"] intValue];
		_maxCount += playerVip;
		
	
		_freeIndex =  0;
		_startIndex = 0;
		
		_paintX = 0 ;
		_paintY = 0 ;
		
		self.contentSize = CGSizeZero;
		
		for (int i = 0 ; i < _cap ; i++) {
			[self capacity];
		}
		
	}
	
	return self;
}

-(ItemTrayContainer*)capacity{
	
	ItemTrayContainer* _cnt = [ItemTrayContainer initWithIndex:4 column:3 index:_startIndex];
	
	[self addChild:_cnt z:1];
	
	_eachSize = _cnt.contentSize;
	
	_cnt.position=ccp(_paintX, _paintY);
	
	_paintX += _cnt.contentSize.width; //绘制的位置
	
	_startIndex += 12 ;//每一个容器的开始INDEX
	
	self.contentSize = [self sizeAdd:self.contentSize :_cnt.contentSize];
	
	/*
	 if ([self.parent isKindOfClass:[ItemManager class]]){
	 ItemManager* mgr = (ItemManager*)self.parent;
	 [mgr.pageDot setDotCount:_children.count];
	 }
	 
	 if (_target != nil && _callPageCount != nil) {
	 CCLOG(@"call for update pagedot count");
	 NSNumber *_sender = [NSNumber numberWithInt:_children.count];
	 [_target performSelector:_callPageCount withObject:_sender];
	 }*/
	
	NSNumber *_sender = [NSNumber numberWithInt:_children.count];
	if ([ItemManager shared] != nil) {
		[[ItemManager shared] updatePageDotCount:_sender];
	}
	
	return _cnt ;
}

-(CGSize)sizeAdd:(CGSize)_s1 :(CGSize)_s2{
	
	float _h = (_s1.height > _s2.height)?_s1.height:_s2.height;
	
	CGSize _s3 = CGSizeMake(_s1.width+_s2.width,_h);
	
	return _s3;
	
}

-(void)dealloc{
	CCLOG(@"ItemCanvas->dealloc");
	
	[super dealloc];
}

-(void)openMarketModel:(BOOL)_isOpen{
	CCNode * ____node;
	CCARRAY_FOREACH(_children, ____node) {
		if ([____node isKindOfClass:[ItemTrayContainer class]]) {
			ItemTrayContainer* _cnt = (ItemTrayContainer*)____node;
			[_cnt openMarketModel:_isOpen];
		}
	}
}

-(void)addItem:(NSDictionary*)_dict type:(ItemTray_type)_type{
	ItemTray* _tray = [self getFreeItemTray];
	if (_tray != nil) {
		[_tray addItem:_dict type:_type];
	}
}

-(void)addItem:(NSDictionary*)_dict type:(ItemTray_type)_type dataType:(DataHelper_type)_dataType
{
	ItemTray* _tray = [self getFreeItemTray];
	if (_tray != nil) {
		[_tray addItem:_dict type:_type dataType:_dataType];
	}
}

-(void)hideOther{
	for (int i = 0; i < _children.count; i++) {
		if (i != _focusIndex) {
			ItemTrayContainer* _cnt = (ItemTrayContainer*)[_children objectAtIndex:i];
			_cnt.visible = NO;
		}
	}
}

-(void)openAll{
	CCNode * ____node;
	CCARRAY_FOREACH(_children, ____node) {
		if ([____node isKindOfClass:[ItemTrayContainer class]]) {
			____node.visible = YES;
		}
	}
}

-(ItemTray*)getFreeItemTray{
	
	CCNode * ____node;
	CCARRAY_FOREACH(_children, ____node) {
		if ([____node isKindOfClass:[ItemTrayContainer class]]) {
			ItemTrayContainer* _cnt = (ItemTrayContainer*)____node;
			ItemTray* _tray = [_cnt getFreeTray];
			if (_tray) {
				return _tray;
			}
		}
	}
	
	//todo 检查是不是可以增加容器
	if (_children.count < _maxCount) {
		
		ItemTrayContainer* _newCnt = [self capacity];
		
		return [_newCnt getFreeTray];
	}
	
	return nil;
}

-(void)freeAllSelect{
	CCNode * ____node = nil;
	CCARRAY_FOREACH(_children, ____node) {
		if(____node!=NO){
			if ([____node isKindOfClass:[ItemTrayContainer class]]) {
				ItemTrayContainer* _tray = (ItemTrayContainer*)____node;
				[_tray freeAllSelect];
			}
		}
	}
}

-(ItemTray*)removeItemTrayWith:(int)_itemId type:(int)_pType{
	CCNode * ____node = nil;
	CCARRAY_FOREACH(_children, ____node) {
		if(____node!=NO){
			if ([____node isKindOfClass:[ItemTrayContainer class]]) {
				ItemTrayContainer* _tray = (ItemTrayContainer*)____node;
				ItemTray* _result = [_tray removeItemTrayWith:_itemId type:_pType];
				if (_result != nil) {
					return _result;
				}
			}
		}
	}
	
	return nil;
}

-(ItemTray*)getEventTray:(UITouch*)touch{
	int _index = _focusIndex;
	if (_index >= 0 && _index < _children.count) {
		ItemTrayContainer* _cnt = (ItemTrayContainer*)[_children objectAtIndex:_index];
		if (_cnt != nil) {
			return [_cnt getEventTray:touch];
		}
	}
	return nil;
}

-(void)setFocusIndex:(int)focusIndex{
	
	_lastIndex = _focusIndex;
	_focusIndex = focusIndex;
	
	/*
	 if ([self.parent isKindOfClass:[ItemManager class]]){
	 ItemManager* mgr = (ItemManager*)self.parent;
	 [mgr.pageDot setIndex:_focusIndex];
	 }*/
	
	if ([ItemManager shared] != nil) {
		[[ItemManager shared] updatePageDotIndex:_focusIndex];
	}
	
	if (_focusIndex < 0) {
		_focusIndex = 0 ;
	}
	
	if (_focusIndex >= _children.count ) {
		_focusIndex = _children.count - 1 ;
	}
	
	CCLOG(@"ItemCanvas->setFocusIndex:%d",_focusIndex);
	
	
	float targetX = -1*_eachSize.width*_focusIndex;
	float targetY = self.position.y;
	
	float nowX = self.position.x ;
	
	float distance = fabsf(nowX-targetX);
	ccTime _t = distance*(1.0/_eachSize.width);
	if (_t > 1.0) {
		_t = 1.0;
	}
	
	CCMoveTo *_act = [CCMoveTo actionWithDuration:_t position:ccp(targetX, targetY)];
	CCEaseBackOut* _out = [CCEaseBackOut actionWithAction:_act];
	CCLOG(@"ItemCanvas->setFocusIndex->runAction:%d",_focusIndex);
	
	[self stopAllActions];
	[self runAction:_out];
	
}

#ifdef DEBUG_1
-(void)draw{
	[super draw];
	ccDrawColor4F(0, 255, 255, 128);
	ccDrawRect(CGPointZero, ccp(self.contentSize.width-1, self.contentSize.height-1));
}
#endif

@end

@implementation ItemManager

@synthesize showType = _showType;
@synthesize touchSwipe = touchSwipe_;
@synthesize pageDot = _pageDot;
@synthesize shiftTarget = _shiftTarget;
@synthesize shiftCall = _shiftCall;
@synthesize shiftType = _shiftType;
@synthesize dataType;

static ItemManager *s_ItemManager = nil;

+(ItemManager*)shared{
	return s_ItemManager;
}

+(ItemManager*)initWithDimension:(CGSize)_dimension{
	return [[[ItemManager alloc] initWithDimension:_dimension] autorelease];
}

-(id)initWithDimension:(CGSize)_dimension{
	
	if ((self = [super init])) {
		CGSize size = CGSizeMake(_dimension.width, _dimension.height + PAGE_DOT_HEIGHT);
		self.contentSize = size;
		
		dataType = DataHelper_player;
	}
	
	s_ItemManager = self ;
	
	return self;
}

-(void)dealloc{
	CCLOG(@"ItemManager->dealloc");
	s_ItemManager = nil ;
	
	[super dealloc];
}

-(void)onExit{
	
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
	[super onExit];
}

-(void)onEnter{
	[super onEnter];
	
	CCDirector *director = [CCDirector sharedDirector];
	//[[director touchDispatcher] addTargetedDelegate:self priority:-170 swallowsTouches:NO];
	[[director touchDispatcher] addTargetedDelegate:self priority:-170 swallowsTouches:YES];
	
	stealTouches_ = YES;
	_isMarkModel = NO ;
	
	if (_pageDot == nil) {
		_pageDot = [PageDot node];
		[self addChild:_pageDot z:1 tag:2033];
		[_pageDot setDotCount:1];
		[_pageDot setSize:CGSizeMake(self.contentSize.width,CGS_PageDot_y)];
		[_pageDot setIndex:0];
		_pageDot.position = ccp(self.contentSize.width/2,POS_Pagedot_y);
	}
	
}

#ifdef DEBUG_1
-(void)draw{
	[super draw];
	ccDrawColor4F(255, 255, 0, 128);
	ccDrawRect(CGPointZero, ccp(self.contentSize.width-1, self.contentSize.height-1));
}
#endif

-(void)visit{
	if (state_ == tCCScrollLayerStateBottomSlid_) {
		[super visit];
	}else{
		CGPoint pt = [self.parent convertToWorldSpace:self.position];
		int clipX = pt.x;
		int clipY = pt.y;
		int clipW = self.contentSize.width;
		int clipH = self.contentSize.height;
		float zoom = [[CCDirector sharedDirector] contentScaleFactor];//高清时候需要放大
		glScissor(clipX*zoom, clipY*zoom, clipW*zoom, clipH*zoom);
		glEnable(GL_SCISSOR_TEST);
		[super visit];
		glDisable(GL_SCISSOR_TEST);
	}
}

#pragma mark touch
/*
-(void)cutOffTouch: (UITouch *) aTouch
{
    CCTouchDispatcher *dispatcher = [[CCDirector sharedDirector] touchDispatcher];
	
	for ( CCTargetedTouchHandler *handler in [dispatcher allTargetedHandlers] )
	{
		if (handler.delegate == self)
		{
			if (![handler.claimedTouches containsObject: aTouch])
			{
				[handler.claimedTouches addObject: aTouch];
			}
		}
        else
        {
            if ([handler.claimedTouches containsObject: aTouch])
            {
                if ([handler.delegate respondsToSelector:@selector(ccTouchCancelled:withEvent:)])
                {
                    [handler.delegate ccTouchCancelled: aTouch withEvent: nil];
                }
                [handler.claimedTouches removeObject: aTouch];
            }
        }
	}
	
}*/

-(BOOL)checkIn:(CGPoint)_pt start:(CGPoint)_stPt end:(CGPoint)_ePt{
	BOOL isIn = YES;
	isIn = isIn && (_pt.x >= _stPt.x);
	isIn = isIn && (_pt.x <= _ePt.x);
	isIn = isIn && (_pt.y >= _stPt.y);
	isIn = isIn && (_pt.y <= _ePt.y);
	return isIn;
}
/*
 -(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
 if( scrollTouch_ == touch ) {
 scrollTouch_ = nil;
 }
 }
 -(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
 if( scrollTouch_ == nil ) {
 scrollTouch_ = touch;
 } else {
 return NO;
 }
 
 CGPoint touchPoint = [touch locationInView:[touch view]];
 touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
 CGPoint sPt = [self.parent convertToWorldSpace:self.position];
 
 float rx = sPt.x + self.contentSize.width;
 float ty = sPt.y + self.contentSize.height;
 
 if ([self checkIn:touchPoint start:sPt end:ccp(rx, ty)]) {
 touchSwipe_ = touchPoint;
 state_ = kCCScrollLayerStateIdle_;
 return YES;
 }else {
 scrollTouch_ = nil;
 [self cutOffTouch:touch];
 return NO;
 }
 
 return NO;
 }
 - (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
 if( scrollTouch_ != touch ) {
 return;
 }
 
 CGPoint touchPoint = [touch locationInView:[touch view]];
 touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
 
 if ( (state_ != kCCScrollLayerStateSliding_)
 && ((fabsf(touchPoint.x-touchSwipe_.x) >= minimumTouchLengthToSlide_)
 ||(fabsf(touchPoint.y-touchSwipe_.y) >= minimumTouchLengthToSlide_) ) ){
 state_ = kCCScrollLayerStateSliding_;
 
 touchSwipe_ = touchPoint;
 
 if (_canvas) {
 [_canvas stopAllActions];
 layerSwipe_ = _canvas.position;
 }
 
 if (stealTouches_)
 {
 CCLOG(@"ccTouchMoved---1");
 [self cutOffTouch:touch];
 CCLOG(@"ccTouchMoved---1");
 }
 }
 
 if (state_ == kCCScrollLayerStateSliding_){
 CGPoint temp = ccpSub(touchPoint, touchSwipe_);
 temp.y = 0 ;
 CGPoint newPt = ccpAdd(temp, layerSwipe_);
 if (_canvas) {
 _canvas.position = newPt;
 }
 }
 
 }
 
 - (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
 if( scrollTouch_ != touch )
 return;
 
 CCLOG(@"ccTouchEnded---1");
 
 scrollTouch_ = nil;
 CGPoint touchPoint = [touch locationInView:[touch view]];
 touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
 
 if (state_ == kCCScrollLayerStateSliding_){
 CGPoint temp = ccpSub(touchPoint, touchSwipe_);
 
 if (_canvas != nil) {
 
 BOOL isAction = NO ;
 if (fabs(temp.x) > _canvas.eachSize.width/3) {
 isAction = YES ;
 }
 if (isAction) {
 int _count = abs((int)(temp.x/_canvas.eachSize.width));
 
 if (_count == 0) {
 _count = 1;
 }
 
 _count = temp.x > 0 ? (_count * -1):(_count * 1);
 
 _count += _canvas.focusIndex ;
 _canvas.focusIndex = _count;
 
 }else{
 _canvas.focusIndex = _canvas.focusIndex;
 }
 
 }
 
 }
 
 }*/

-(void)checkTrayEvent{
	if (state_  == tCCScrollLayerStateTopIn_) {
		CCLOG(@"checkTrayEvent set up");
		if (scrollTouch_ != nil) {
			state_ = tCCScrollLayerStateBottomIn_;
			_itemTray = nil;
			if (_canvas != nil) {
				_itemTray = [_canvas getEventTray:scrollTouch_];
				if (_itemTray != nil) {
					[_itemTray doStartMove];
				}
			}
		}
	}
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
    if( scrollTouch_ == touch ) {
		scrollTouch_ = nil;
		
		
		if (state_ == tCCScrollLayerStateBottomSlid_) {
			if (_canvas != nil) {
				[_canvas openAll];
			}
		}
		
		state_ = tCCScrollLayerStateNo_;
		
		if (_itemTray != nil) {
			[_itemTray doEndMove];
		}
		
		
		if (_canvas != nil) {
			_canvas.focusIndex = _canvas.focusIndex;
		}
		
		
		[self unschedule:@selector(checkTrayEvent)];
		
		_itemTray = nil ;
    }
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	CGPoint sPt = [self.parent convertToWorldSpace:self.position];
	
	float rx = sPt.x + self.contentSize.width;
	float ty = sPt.y + self.contentSize.height;
	
	if (scrollTouch_ != nil) {
		return NO;
	}
	
	if ([self checkIn:touchPoint start:sPt end:ccp(rx, ty)]) {
		scrollTouch_ = touch;
		touchSwipe_ = touchPoint;
		
		[self unschedule:@selector(checkTrayEvent)];
		[self scheduleOnce:@selector(checkTrayEvent) delay:0.2];
		state_ = tCCScrollLayerStateTopIn_;
		
		return YES;
	}
	
	return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	
	//
	//把顶层的操作点击指派为顶层的滑动
	//
	if ( (state_  == tCCScrollLayerStateTopIn_)
		&& ((fabsf(touchPoint.x-touchSwipe_.x) >= minimumTouchLengthToSlide_)
			||(fabsf(touchPoint.y-touchSwipe_.y) >= minimumTouchLengthToSlide_) ) ){
			
			//结束检查
			[self unschedule:@selector(checkTrayEvent)];
			
			state_ = tCCScrollLayerStateTopSlid_;
			
			CCLOG(@"Begin-Scroll-top-layer");
			touchSwipe_ = touchPoint;
			
			if (_canvas) {
				[_canvas stopAllActions];
				layerSwipe_ = _canvas.position;
			}
			
		}
	
	//
	//把底层的操作点击指派为底层的滑动
	//
	if (state_ == tCCScrollLayerStateBottomIn_) {
		state_ = tCCScrollLayerStateBottomSlid_;
		CCLOG(@"Begin-Scroll-bottom-layer");
		
		//????
		[self.parent reorderChild:self z:INT16_MAX];
		
		if (_canvas != nil) {
			[_canvas hideOther];
		}
		
		if (_itemTray != nil) {
			[_itemTray.parent reorderChild:_itemTray z:20];
			[_itemTray touchBegan:touch];
		}
		
	}
	
	//上层滑动
	if (state_ == tCCScrollLayerStateTopSlid_){
		CCLOG(@"Scroll-top-layer");
		CGPoint temp = ccpSub(touchPoint, touchSwipe_);
		temp.y = 0 ;
		CGPoint newPt = ccpAdd(temp, layerSwipe_);
		if (_canvas != nil) {
			_canvas.position = newPt;
		}
	}
	
	//下层滑动
	if (state_ == tCCScrollLayerStateBottomSlid_) {
		CCLOG(@"Scroll-bottom-layer");
		if (_itemTray != nil) {
			[_itemTray touchMoved:touch];
		}
	}
	
	
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	
	[self unschedule:@selector(checkTrayEvent)];
	
	scrollTouch_ = nil;
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	
	//单纯的点击事件
	if (state_ == tCCScrollLayerStateTopIn_ ||
		state_ == tCCScrollLayerStateBottomIn_) {
		CCLOG(@"Finish-only-click");
		
		if (_itemTray == nil) {
			_itemTray = [_canvas getEventTray:touch];
		}
		
		//销售模式的时候
		if (_itemTray != nil) {
			if (_itemTray.model == ItemTray_market) {
				_itemTray.isSelect = !_itemTray.isSelect;
			}else{
				
				if (![_itemTray isNone]) {
					//??????
					//[[PlayerPanel shared] requestShowItemTrayDescribe:_itemTray.number type:_itemTray.type];
					[_itemTray doRequestShowInfo];
				}
				
			}
		}
		
		if (_itemTray != nil) {
			[_itemTray doEndMove];
		}
	}
	
	//结束顶层拖拽
	if (state_ == tCCScrollLayerStateTopSlid_){
		CCLOG(@"Finish-top-layer-slid");
		CGPoint temp = ccpSub(touchPoint, touchSwipe_);
		
		if (_canvas != nil) {
			
			BOOL isAction = NO ;
			if (fabs(temp.x) > _canvas.eachSize.width/3) {
				isAction = YES ;
			}
			if (isAction) {
				int _count = abs((int)(temp.x/_canvas.eachSize.width));
				
				if (_count == 0) {
					_count = 1;
				}
				
				_count = temp.x > 0 ? (_count * -1):(_count * 1);
				
				_count += _canvas.focusIndex ;
				_canvas.focusIndex = _count;
				
			}else{
				_canvas.focusIndex = _canvas.focusIndex;
			}
			
		}
	}
	
	//结束底层拖拽
	if (state_ == tCCScrollLayerStateBottomSlid_) {
		CCLOG(@"Finish-bottom-layer-slid");
		[self.parent reorderChild:self z:INT16_MAX-10];
		
		if (_itemTray != nil) {
			[_itemTray.parent reorderChild:_itemTray z:10];
			
			// 指定类型有效
			if (_itemTray.type == _shiftType) {
				
				if (_shiftTarget != nil && _shiftCall != nil) {
					
					NSMutableDictionary *dict = [NSMutableDictionary dictionary];
					[dict setObject:[NSValue valueWithCGPoint:touchPoint] forKey:@"point"];
					[dict setObject:[NSNumber numberWithInt:_itemTray.number] forKey:@"id"];
					
					id result = [_shiftTarget performSelector:_shiftCall
												   withObject:dict];
					BOOL isEnd = [result boolValue];
					if (!isEnd) {
						[_itemTray doEndMove];
					}
					
				} else {
					[_itemTray doEndMove];
				}
				
			} else {
				
				[_itemTray doEndMove];
				
			}
		}
		
		if (_canvas != nil) {
			[_canvas openAll];
		}
		
	}
	
	state_ = tCCScrollLayerStateNo_;
	_itemTray = nil ;
	
}

-(void)freeSelect{
	if (_canvas != nil) {
		[_canvas freeAllSelect];
	}
}

#pragma mark logic

-(BOOL)isMarkModel{
	return _isMarkModel;
}

-(void)openMarketModel:(BOOL)_isOpen{
	_isMarkModel = _isOpen;
	if (_canvas != nil) {
		[_canvas openMarketModel:_isOpen];
	}
}

-(void)updatePageDotIndex:(int)_inx{
	if (_pageDot != nil) {
		[_pageDot setIndex:_inx];
	}
}

-(void)updatePageDotCount:(NSNumber*)_sender{
	if (_pageDot != nil) {
		[_pageDot setDotCount:[_sender intValue]];
	}
}

-(void)deleteAllContainer{
	if (_canvas) {
		if (_itemTray) {
			[_itemTray removeFromParent];
			_itemTray = nil;
		}
		
		[_canvas removeFromParentAndCleanup:YES];
		_canvas = nil;
	}
}

-(ItemTray*)eventForDeleteItemTray:(int)_id type:(int)_type{
	
	if (_canvas != nil) {
		return [_canvas removeItemTrayWith:_id type:_type];
	}
	
	return nil;
}

-(void)eventForAddJewel:(NSDictionary *)_dict
{
	if (_dict == nil) return ;
	
	if (self.showType == ItemManager_show_type_all ||
		self.showType == ItemManager_show_type_jewel){
		
		if (_canvas != nil) {
			[_canvas addItem:_dict type:ItemTray_item_jewel dataType:dataType];
		}
	}
}

-(void)eventForAddEquipment:(NSDictionary *)_dict{
	if (_dict == nil) return ;
	
	if (self.showType == ItemManager_show_type_all ||
		self.showType == ItemManager_show_type_equipment){
		
		if (_canvas != nil) {
			[_canvas addItem:_dict type:ItemTray_armor];
		}
	}

}

-(void)eventForAddStone:(NSDictionary *)_dict
{
	if (_dict == nil) return;
	if (self.showType == ItemManager_show_type_all ||
		self.showType == ItemManager_show_type_fodder ||
		self.showType == ItemManager_show_type_stone) {
		
		if (_canvas != nil) {
			[_canvas addItem:_dict type:ItemTray_item_stone dataType:dataType];
		}
	}
}

-(void)updateContainerWithType:(ItemManager_show_type)_stype{
	
	[self deleteAllContainer];
	self.showType = _showType ;
	_isMarkModel = NO ;
	
	if (_stype == ItemManager_show_type_all) {//全部显示
		[self showAll];
	}else if (_stype == ItemManager_show_type_equipment){//显示装备
		[self showEquipment];
	}else if (_stype == ItemManager_show_type_expendable){//显示消耗品
		[self showExpendable];
	}else if (_stype == ItemManager_show_type_fate){//显示命格
		[self showFate];
	}else if (_stype == ItemManager_show_type_fodder){//显示材料
		[self showFodder];
	}else if (_stype == ItemManager_show_type_jewel){
		[self showJewel];
	}else if (_stype == ItemManager_show_type_stone){
		[self showStone];
	}
}

-(void)updateJewelContainerWithPart:(EquipmentPart)_part
{
	[self deleteAllContainer];
	self.showType = ItemManager_show_type_jewel;
	_isMarkModel = NO ;
	
	[self showJewel:_part];
}

-(void)showJewel:(EquipmentPart)_part
{
	_canvas = [ItemCanvas createCanvas:1];
	_canvas.position = ccp(0, PAGE_DOT_HEIGHT);
	_canvas.focusIndex = 0 ;
	[self addChild:_canvas z:2];
	
	NSArray *jewels = nil;
	if (dataType == DataHelper_jewel) {
		jewels = [JewelHelper shared].jewels;
	} else {
		jewels = [PlayerDataHelper shared].jewels;
	}
	for (NSDictionary* _info in jewels) {
		if ([_info intForKey:@"used"] == FateStatus_unused) {
			int gid = [_info intForKey:@"gid"];
			NSDictionary *jewelInfo;
			if (dataType == DataHelper_jewel) {
				jewelInfo = [[JewelHelper shared] getJewelInfoBy:gid];
			} else {
				jewelInfo = [[PlayerDataHelper shared] getJewelInfoBy:gid];
			}
			if (jewelInfo) {
				if (_part == 0) {
					[_canvas addItem:_info type:ItemTray_item_jewel dataType:dataType];
					continue;
				}
				
				NSString *_parts = [jewelInfo objectForKey:@"parts"];
				NSArray *_partArray = [_parts componentsSeparatedByString:@"|"];
				NSString *partString = [NSString stringWithFormat:@"%d", _part];
				if ([_partArray containsObject:partString]) {
					[_canvas addItem:_info type:ItemTray_item_jewel dataType:dataType];
				}
			}
		}
	}
}

-(void)showStone{
	_canvas = [ItemCanvas createCanvas:1];
	_canvas.position = ccp(0, PAGE_DOT_HEIGHT);
	_canvas.focusIndex = 0 ;
	[self addChild:_canvas z:2];
	
	NSArray *stones = [[JewelHelper shared] getStones];
	for (NSDictionary* _info in stones) {
		[_canvas addItem:_info type:ItemTray_item_stone dataType:dataType];
	}
}

-(void)showJewel{
	_canvas = [ItemCanvas createCanvas:1];
	_canvas.position = ccp(0, PAGE_DOT_HEIGHT);
	_canvas.focusIndex = 0 ;
	[self addChild:_canvas z:2];
	
	NSArray *jewels = nil;
	if (dataType == DataHelper_jewel) {
		jewels = [JewelHelper shared].jewels;
	} else {
		jewels = [PlayerDataHelper shared].jewels;
	}
	for (NSDictionary* _info in jewels) {
		if ([_info intForKey:@"used"] == FateStatus_unused) {
			[_canvas addItem:_info type:ItemTray_item_jewel dataType:dataType];
		}
	}
	
}

-(void)showAll{
	CCLOG(@"ItemManager->showAll->begin");
	
	_canvas = [ItemCanvas createCanvas:1];
	_canvas.position = ccp(0, PAGE_DOT_HEIGHT);
	_canvas.focusIndex = 0 ;
	[self addChild:_canvas z:2];
	
	for (NSDictionary* _info in [PlayerDataHelper shared].equips) {
		if ([_info intForKey:@"used"] == EquipmentStatus_unused) {
			[_canvas addItem:_info type:ItemTray_armor];
		}
	}
	
	for (NSDictionary* _info in [PlayerDataHelper shared].fates) {
		if ([_info intForKey:@"used"] == FateStatus_unused) {
			[_canvas addItem:_info type:ItemTray_fate];
		}
	}
	
	for (NSDictionary* _info in [PlayerDataHelper shared].items) {
		[_canvas addItem:_info type:ItemTray_item];
	}
	
	for (NSDictionary* _info in [PlayerDataHelper shared].jewels) {
		if ([_info intForKey:@"used"] == FateStatus_unused) {
			[_canvas addItem:_info type:ItemTray_item_jewel];
		}
	}
	
	CCLOG(@"ItemManager->showAll->end");
}

-(void)showFate{
	_canvas = [ItemCanvas createCanvas:1];
	_canvas.position = ccp(0, PAGE_DOT_HEIGHT);
	_canvas.focusIndex = 0 ;
	[self addChild:_canvas z:2];
	
	for (NSDictionary* _info in [PlayerDataHelper shared].fates) {
		if ([_info intForKey:@"used"] == FateStatus_unused) {
			[_canvas addItem:_info type:ItemTray_fate];
		}
	}
	
}

-(void)showFodder{
	//todo
	_canvas = [ItemCanvas createCanvas:1];
	_canvas.position = ccp(0, PAGE_DOT_HEIGHT);
	_canvas.focusIndex = 0 ;
	[self addChild:_canvas z:2];
	
	//获得材料
	NSArray* array = [[PlayerDataHelper shared] getItemArrayWithType:1];
	
	for (NSDictionary* _info in array) {
		
		[_canvas addItem:_info type:ItemTray_item];
		
	}
}

-(void)showExpendable{
	//todo
	//物品表 2 4 5
	_canvas = [ItemCanvas createCanvas:1];
	_canvas.position = ccp(0, PAGE_DOT_HEIGHT);
	_canvas.focusIndex = 0 ;
	[self addChild:_canvas z:2];
	
	//获得消耗品
	NSArray* array = [[PlayerDataHelper shared] getItemArrayWithType:2];
	
	for (NSDictionary* _info in array) {
		
		[_canvas addItem:_info type:ItemTray_item];
		
	}
}

-(void)showEquipment{
	_canvas = [ItemCanvas createCanvas:1];
	_canvas.position = ccp(0, PAGE_DOT_HEIGHT);
	_canvas.focusIndex = 0 ;
	[self addChild:_canvas z:2];
	
	for (NSDictionary* _info in [PlayerDataHelper shared].equips) {
		if ([_info intForKey:@"used"] == EquipmentStatus_unused) {
			[_canvas addItem:_info type:ItemTray_armor];
		}
	}
	//获得装备碎片
	NSArray* array = [[PlayerDataHelper shared] getItemArrayWithType:3];
	
	for (NSDictionary* _info in array) {
		
		//[_canvas addItem:_info type:ItemTray_item_armor];
		[_canvas addItem:_info type:ItemTray_item];
	}
}

-(int)getContainerAmount{
	return 0;
}


@end
