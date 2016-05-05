//
//  Widget.m
//  TXSFGame
//
//  Created by Soul on 13-5-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "Widget.h"


@implementation Widget

@synthesize touchEvent = _touchEvent;
@synthesize target = _target;
@synthesize call = _call;
@synthesize arg = _arg;

-(id)init{
	if ((self = [super init]) != nil) {
		_anchorPoint =  ccp(0.5f, 0.5f);
	}
	return self;
}

-(void)dealloc{
	CCLOG(@"Widget->dealloc->%p",self);
	[self freeEvent];
	[super dealloc];
}

-(BOOL)focusWidget:(Widget*)widget{
	/*
	 * 子类重写这个方法，去实现不同的逻辑
	 */
	return NO;
}

-(void)resetStatus{
	/*
	 * 子类重写这个方法，去实现不同的逻辑
	 */
}

-(void)doEvent{
	if (_target != nil && _call != nil && _arg != nil) {
		[_target performSelector:_call withObject:_arg];
	}else if (_target != nil && _call != nil){
		[_target performSelector:_call];
	}
}

-(void)freeEvent{
	_target = nil;
	_call = nil;
	if (_arg != nil) {
		[_arg release];
		_arg = nil;
	}
}

-(BOOL)checkEvent:(UITouch *)touch{
	if (_touchEvent == NO) {
		return NO;
	}
	return [self isTouchInSite:touch];
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

-(BOOL)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return NO;
}

- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
}

- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
}

-(void)touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
}

@end
