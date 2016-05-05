//
//  ActivityTabGroup.m
//  TXSFGame
//
//  Created by Soul on 13-4-16.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ActivityTabGroup.h"
#import "ActivityTab.h"
#import "ActivityViewerContent.h"

@implementation CCLayer(LinearLayout)

-(void)LinearLayout:(float)_offset{
	CCNode* _temp = nil ;
	float paintY = -1*_offset;
	CCARRAY_FOREACH(_children, _temp){
		_temp.position = ccp(_temp.contentSize.width/2, paintY - _temp.contentSize.height/2);
		paintY = paintY - _temp.contentSize.height;
		paintY = paintY - _offset;
	}
	
	self.contentSize = CGSizeMake(self.contentSize.width, fabsf(paintY));
	CCARRAY_FOREACH(_children, _temp){
		CGPoint pt = _temp.position;
		pt = ccpAdd(pt, ccp(0, fabsf(paintY)));
		_temp.position = pt;
	}
	
}

-(ActivityTab*)checkEvent:(UITouch *)_touch{
	if (_touch == nil) return nil;
	
	CCNode* _temp = nil ;
	CCARRAY_FOREACH(_children, _temp){
		if ([_temp isKindOfClass:[ActivityTab class]]) {
			ActivityTab* tab = (ActivityTab*)_temp;
			if ([tab checkTouch:_touch]) {
				return tab;
			}
		}
	}
	return nil;
}

-(void)setFocus:(ActivityTab *)_tab{
	CCNode* _temp = nil ;
	CCARRAY_FOREACH(_children, _temp){
		if ([_temp isKindOfClass:[ActivityTab class]]) {
			ActivityTab* tab = (ActivityTab*)_temp;
			if (tab == _tab) {
				tab.isSelected = YES ;
			}else{
				tab.isSelected = NO ;
			}
		}
	}
}
-(void)setDefaultFoucus{
	CCNode* _temp = nil ;
	CCARRAY_FOREACH(_children, _temp){
		if ([_temp isKindOfClass:[ActivityTab class]]) {
			ActivityTab* tab = (ActivityTab*)_temp;
			tab.isSelected = YES;
			return ;
		}
	}
}
@end

@implementation ActivityTabGroup

@synthesize menuUIData;

+(ActivityTabGroup*)initActivityTabGroup:(float)_width height:(float)_height{
	return [[[ActivityTabGroup alloc] initActivityTabGroup:_width height:_height] autorelease];;
}

-(id)initActivityTabGroup:(float)_width height:(float)_height{
	if ((self=[super init]) == nil) {
		return nil;
	}
	
	self.contentSize = CGSizeMake(_width, _height);
	if (canvas) {
		[canvas removeFromParentAndCleanup:YES];
		canvas = nil;
	}
	
	canvas = [CCLayer node];
	canvas.contentSize = self.contentSize;
	
	[self addChild:canvas z:1];
	
	
	return self;
}

-(void)visit{
	CGPoint pt = [self.parent convertToWorldSpace:self.position];
	int clipX = pt.x;
	int clipY = pt.y;
	int clipW = self.contentSize.width;
	int clipH = self.contentSize.height;
	float zoom = [[CCDirector sharedDirector] contentScaleFactor];
	glScissor(clipX*zoom, clipY*zoom, clipW*zoom, clipH*zoom);
	glEnable(GL_SCISSOR_TEST);
	[super visit];
	glDisable(GL_SCISSOR_TEST);
}

-(void)onEnter{
	[super onEnter];
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-170 swallowsTouches:YES];
	menuUIData = [[NSMutableArray alloc]init];
}

-(void)onExit{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	[super onExit];
}

-(BOOL)checkIn:(CGPoint)_pt start:(CGPoint)_stPt end:(CGPoint)_ePt{
	BOOL isIn = YES;
	isIn = isIn && (_pt.x >= _stPt.x);
	isIn = isIn && (_pt.x <= _ePt.x);
	isIn = isIn && (_pt.y >= _stPt.y);
	isIn = isIn && (_pt.y <= _ePt.y);
	return isIn;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	CGPoint sPt = [self.parent convertToWorldSpace:self.position];
	
	float rx = sPt.x + self.contentSize.width;
	float ty = sPt.y + self.contentSize.height;
	
	
	
	if ([self checkIn:touchPoint start:sPt end:ccp(rx, ty)]) {
		touchEvent = touch;
		beginPoint = touchPoint;
		status = 1;
		return YES;
	}
	
	return NO;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	touchEvent = nil;
	//CGPoint touchPoint = [touch locationInView:[touch view]];
	//touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	
	if (status == 1) {
		if (canvas != nil) {
			ActivityTab* tab = [canvas checkEvent:touch];
			if (tab) {
				[canvas setFocus:tab];
			}
		}
		
	}
	
	if (status == 2) {
		[self revisionSwipe];
	}
	
	status = 0 ;
	
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	
	if (status == 1) {
		if (fabsf(beginPoint.x - touchPoint.x) >= 2
			|| fabsf(beginPoint.y - touchPoint.y) >= 2 ) {
			if (canvas != nil) {
				status = 2;
				[canvas stopAllActions];
				canvasPoint = canvas.position;
				beginPoint = touchPoint;
			}
		}
	}
	
	if (status == 2){
		CGPoint temp = ccpSub(touchPoint, beginPoint);
		temp.x = 0 ;
		CGPoint newPt = ccpAdd(temp, canvasPoint);
		if (canvas != nil) {
			canvas.position = newPt;
		}
	}
	
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event{
	touchEvent = nil;
	status = 0;
}

-(void)removeAllTabs{
	if (canvas) {
		[canvas removeAllChildren];
	}
}

-(void)addTabs:(NSArray *)array target:(id)_t call:(SEL)_c{
	if (array == nil || array.count <= 0) {
		return ;
	}
	
	BOOL isStart = YES ;
	for (NSDictionary* dict in array) {
		
		NSString* name = [dict objectForKey:@"name"];
		NSString* tips = [dict objectForKey:@"info"];
		
		int __id = [[dict objectForKey:@"id"] intValue];
		int __type = [[dict objectForKey:@"type"] intValue];
		
		ActivityTab* tab = [ActivityTab node];
		tab.target = _t;
		tab.call = _c;
		
		[tab setName:name];
//		NSString* tipds=@"这是一个提示测试，你看看";
		[tab setTips:tips];
		[tab setActivityId:__id];
		[tab setType:__type];
		
		[tab setIsSelected:NO];
		[canvas addChild:tab z:0];
		[menuUIData addObject:tab];
		
		NSString* cmd = [ActivityViewerContent getFunctionType:dict];
		if(isEqualToKey(cmd, FUNC_input)){
			[canvas setFocus:tab];
			isStart = NO;
		}
		
	}
	
	if (isStart) {
		[canvas setDefaultFoucus];
	}
	
	[canvas LinearLayout:8];
	if (iPhoneRuningOnGame()) {
		canvas.position = ccp(4, self.contentSize.height - canvas.contentSize.height);
	}else{
		canvas.position = ccp(4, self.contentSize.height - canvas.contentSize.height);
	}
}

-(void)revisionSwipe{
	if (canvas != nil) {
		id move = nil;
		
		if (canvas.contentSize.height > self.contentSize.height) {
			if (canvas.position.y > 0) {
				move = [CCMoveTo actionWithDuration:1
										   position:ccp(4, 0)];
			} else if (canvas.position.y+canvas.contentSize.height < self.contentSize.height) {
				move = [CCMoveTo actionWithDuration:1
										   position:ccp(4, self.contentSize.height-canvas.contentSize.height)];
			}
		}else{
			if (canvas.position.y > (self.contentSize.height - canvas.contentSize.height)) {
				move = [CCMoveTo actionWithDuration:1
										   position:ccp(4, self.contentSize.height - canvas.contentSize.height)];
			} else if (canvas.position.y+canvas.contentSize.height < self.contentSize.height) {
				move = [CCMoveTo actionWithDuration:1
										   position:ccp(4, self.contentSize.height-canvas.contentSize.height)];
			}
		}
		
		if (move) {
			[canvas stopAllActions];
			id action = [CCEaseElasticOut actionWithAction:move period:0.8f];
			[canvas runAction:action];
		}
	}
}

@end









