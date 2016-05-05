//
//  WidgetTable.m
//  TXSFGame
//
//  Created by Soul on 13-5-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "WidgetTable.h"
#import "Widget.h"
#import "WidgetContainer.h"

@implementation WidgetTable

@synthesize canvas = _canvas;
@synthesize alignPt = _alignPt;
@synthesize alignType = _alignType;


-(id)init{
	if ((self = [super init]) != nil) {
		
		state_ = touchLayerStateNo_;
		minimumTouchLengthToSlide_ = 4;
		_alignGap = 4;
		
	}
	return self;
}

-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	focusWidget = nil;
	[super onExit];
}

-(void)setDefaultContainer{
	if (_canvas == nil) {
		_canvas = [WidgetContainer node];
		[self addChild:_canvas z:0];
	}
}

-(void)adjustPosition:(CGPoint)pt{
	if (_canvas != nil) {
		[_canvas adjustPosition:pt];
	}
}

-(void)addCell:(Widget*)widget{
	CCLOG(@"addCell");
	[self setDefaultContainer];
	if (widget) {
		[_canvas addChild:widget];
	}
}

-(void)removeCell:(Widget *)widget{
	if (_canvas != nil) {
		if (widget == focusWidget) {
			focusWidget = nil;
		}
		[_canvas removeChild:widget];
		[self alignWidgets];
	}
}

-(void)addCells:(NSArray*)array{
	CCLOG(@"addCells");
	[self addCells:array index:0];
}

-(void)addCells:(NSArray*)array index:(int)index{
	CCLOG(@"addCells and index = %d",index);
	if (array !=nil && array.count >0) {
		for (Widget* widget in array) {
			[self addCell:widget];
		}
		[self alignWidgets];
	}
}

-(void)setCanvas:(WidgetContainer *)canvas_{
	if (canvas_ == nil) {
		return ;
	}
	if (_canvas != nil) {
		[_canvas removeFromParentAndCleanup:YES];
		_canvas = nil;
	}
	_canvas = canvas_;
	[self addChild:_canvas];
}

-(void)alignWidgets{
	if (_alignType == AlignType_linear_x) {
		[self alignWidgetsHorizontallyWithPadding:_alignGap];
	}
	
	if (_alignType == AlignType_linear_y) {
		[self alignWidgetsVerticallyWithPadding:_alignGap];
	}
}

-(BOOL)checkIn:(CGPoint)_pt start:(CGPoint)_stPt end:(CGPoint)_ePt{
	BOOL isIn = YES;
	isIn = isIn && (_pt.x >= _stPt.x);
	isIn = isIn && (_pt.x <= _ePt.x);
	isIn = isIn && (_pt.y >= _stPt.y);
	isIn = isIn && (_pt.y <= _ePt.y);
	return isIn;
}

-(void)touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
	scrollTouch_ = nil;
	state_ = touchLayerStateNo_;
}

-(BOOL)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	
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
		
		state_ = touchLayerStateTopIn_;
		
		return YES;
	}
	
	return NO;
}


-(void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	
	if ( (state_  == touchLayerStateTopIn_)
		&& ((fabsf(touchPoint.x-touchSwipe_.x) >= minimumTouchLengthToSlide_)
			||(fabsf(touchPoint.y-touchSwipe_.y) >= minimumTouchLengthToSlide_) ) ){
			
			state_ = touchLayerStateTopSlid_;
			
			touchSwipe_ = touchPoint;
			
			if (_canvas) {
				[_canvas stopAllActions];
				layerSwipe_ = _canvas.position;
			}
			
		}
	
	if (state_ == touchLayerStateTopSlid_){
		CGPoint temp = ccpSub(touchPoint, touchSwipe_);
		CCLOG(@"touchSwipe_-(%f,%f)",touchSwipe_.x,touchSwipe_.y);
		CCLOG(@"touchPoint-(%f,%f)",touchPoint.x,touchPoint.y);
		CCLOG(@"temp-(%f,%f)",temp.x,temp.y);
		
		if (_canvas != nil) {
			if (![_canvas checkVertically]) {
				temp = ccp(temp.x, 0);
			}
			if (![_canvas checkHorizontally]) {
				temp = ccp(0, temp.y);
			}
			CGPoint newPt = ccpAdd(temp, layerSwipe_);
			CCLOG(@"newPt-(%f,%f)",newPt.x,newPt.y);
			CCLOG(@"\n");
			[_canvas slidToPosition:newPt];
		}
	}
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	
	
	//TODO
	/*
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	*/
	
	if (state_ == touchLayerStateTopIn_) {
		if (_canvas != nil) {
			Widget* widget = [_canvas touchWidget:touch];
			if (widget) {
				[self focusWidget:widget];
			}
		}
	}
	
	if (state_ == touchLayerStateTopSlid_){
		if (_canvas != nil) {
			[_canvas returning];
		}
	}
	
	state_ = touchLayerStateNo_;
	scrollTouch_ = nil;
	
}

-(void) alignWidgetsVertically{
	if (_canvas != nil) {
		[_canvas alignWidgetsVertically];
	}
}

-(void) alignWidgetsVerticallyWithPadding:(float)padding{
	if (_canvas != nil) {
		[_canvas alignWidgetsVerticallyWithPadding:padding];
	}
}

-(void) alignWidgetsHorizontally{
	if (_canvas != nil) {
		[_canvas alignWidgetsHorizontally];
	}
}

-(void) alignWidgetsHorizontallyWithPadding:(float)padding{
	if (_canvas != nil) {
		[_canvas alignWidgetsHorizontallyWithPadding:padding];
	}
}

-(BOOL)focusWidget:(Widget *)widget{
	if (widget == nil) {
		return NO;
	}
	if (widget == focusWidget) {
		return NO;
	}
	focusWidget = widget;
	return YES;
}

-(void)resetStatus{
	CCLOG(@"WidgetTable resetStatus");
	if (_canvas != nil) {
		[_canvas resetStatus];
	}
}
-(void)visit{
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

@end
