//
//  WidgetContainer.m
//  TXSFGame
//
//  Created by Soul on 13-5-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "WidgetContainer.h"
#import "Widget.h"

enum {
	Layout_defaulepadding =  4,
};

@implementation WidgetContainer

-(id)init{
	if ((self = [super init]) != nil) {
		_anchorPoint =  ccp(0, 0);
	}
	return self;
}

-(void)resetStatus{
	CCLOG(@"WidgetContainer->resetStatus");
	CCNode * ____node = nil;
	CCARRAY_FOREACH(_children, ____node) {
		if(____node!=NO){
			if ([____node isKindOfClass:[Widget class]]) {
				Widget* _temp = (Widget*)____node;
				[_temp resetStatus];
			}
		}
	}
}

-(Widget*)touchWidget:(UITouch *)touch{
	CCNode * ____node = nil;
	CCARRAY_FOREACH(_children, ____node) {
		if(____node!=NO){
			if ([____node isKindOfClass:[Widget class]]) {
				Widget* _temp = (Widget*)____node;
				if ([_temp checkEvent:touch]) {
					return _temp;
				}
			}
		}
	}
	return nil;
}

-(void)adjustPosition:(CGPoint)pt{
	if (self.parent != nil) {
		layoutPt = pt;
		CGSize pSize = self.parent.contentSize;
		CGSize sSize = self.contentSize;
		
		float __x = 0;
		float __y = 0;
		
		if (pt.x == 0) {
			__x = 0;
		}else if (pt.x == 0.5) {
			__x = (pSize.width - sSize.width)/2;
		}else if (pt.x == 1.0) {
			__x = pSize.width - sSize.width;
		}
		
		if (pt.y == 0) {
			__y = 0;
		}else if (pt.y == 0.5) {
			__y = (pSize.height - sSize.height)/2;
		}else if (pt.y == 1.0) {
			__y = pSize.height - sSize.height;
		}
		CCLOG(@"adjustPosition:%f|%f",__x,__y);
		self.position = ccp(__x, __y);
		
	}
}

-(void)returning{
	CCLOG(@"returning");
}

-(void)slidToPosition:(CGPoint)pt{
	
	if (self.parent != nil) {
		CGSize pSize = self.parent.contentSize;
		CGSize sSize = self.contentSize;
		
		CGPoint pos = self.position;
		float disX = pt.x - pos.x;
		float disY = pt.y - pos.y;
		
		float posX = pt.x;
		float posY = pt.y;
		
		if (disX > 0) {
			if (posX > (pSize.width - sSize.width)) {
				posX = (pSize.width - sSize.width);
			}
		}else if (disX < 0){
			if ([self checkHorizontally]) {
				if (posX < (pSize.width - sSize.width)) {
					posX = (pSize.width - sSize.width);
				}
			}else{
				if (posX < 0) {
					posX = 0;
				}
			}
		}
		
		if (disY > 0) {
			if ([self checkVertically]) {
				if (posY > 0) {
					posY = 0;
				}
			}else{
				if (posY > (pSize.height - sSize.height)) {
					posY = (pSize.height - sSize.height);
				}
			}
		}else if (disY < 0){
			if (posY < (pSize.height - sSize.height)) {
				posY = (pSize.height - sSize.height);
			}
		}
		
		self.position = ccp(posX, posY);
	}
}

-(BOOL)checkHorizontally{
	if (self.parent != nil) {
		CGSize pSize = self.parent.contentSize;
		CGSize sSize = self.contentSize;
		if (sSize.width > pSize.width) {
			return YES;
		}
	}
	return NO;
}

-(BOOL)checkVertically{
	if (self.parent != nil) {
		CGSize pSize = self.parent.contentSize;
		CGSize sSize = self.contentSize;
		if (sSize.height > pSize.height) {
			return YES;
		}
	}
	return NO;
}

-(void)alignWidgets{
	
}

-(void) alignWidgetsVertically{
	[self alignWidgetsVerticallyWithPadding:Layout_defaulepadding];
}

-(void) alignWidgetsVerticallyWithPadding:(float)padding{
	CCNode* _temp = nil ;
	float paintY = -1*padding;
	
	float _width = 0 ;
	CCARRAY_FOREACH(_children, _temp){
		if (_temp.contentSize.width > _width) {
			_width = _temp.contentSize.width;
		}
		_temp.position = ccp(_temp.contentSize.width/2, paintY - _temp.contentSize.height/2);
		paintY = paintY - _temp.contentSize.height;
		paintY = paintY - padding;
	}
	
	self.contentSize = CGSizeMake(_width, fabsf(paintY));
	
	CCARRAY_FOREACH(_children, _temp){
		CGPoint pt = _temp.position;
		pt = ccpAdd(pt, ccp(0, fabsf(paintY)));
		_temp.position = pt;
	}
}

-(void) alignWidgetsHorizontally{
	[self alignWidgetsHorizontallyWithPadding:Layout_defaulepadding];
}

-(void) alignWidgetsHorizontallyWithPadding:(float)padding{
	
	CCNode* _temp = nil ;
	float paintX = -1*padding;
	
	float _height = 0 ;
	CCARRAY_FOREACH(_children, _temp){
		if (_temp.contentSize.height > _height) {
			_height = _temp.contentSize.height;
		}
		_temp.position = ccp(paintX + _temp.contentSize.width/2, _height/2);
		paintX = paintX + _temp.contentSize.width;
		paintX = paintX + padding;
	}
	
	self.contentSize = CGSizeMake(paintX, _height);
	
}

//-(void)draw{
//	[super draw];
//	ccDrawColor4B(255, 0, 0, 255);
//	ccDrawRect(CGPointZero, ccp(self.contentSize.width, self.contentSize.height));
//}

@end
