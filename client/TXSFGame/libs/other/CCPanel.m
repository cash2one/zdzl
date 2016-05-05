//
//  CCPanel.m
//  Jinni
//
//  Created by shoujun huang on 13-1-6.
//  Copyright 2013年 __MyCompanyName__. All rights reserved.
//
#import "CCPanel.h"
#import "StretchingImg.h"
#import "Config.h"

@interface CCTouchDispatcher (CCPanelTargetedHandlersGetter)
- (id<NSFastEnumeration>) panelTargetedHandlers;
@end

@implementation CCTouchDispatcher (CCPanelTargetedHandlersGetter)
- (id<NSFastEnumeration>) panelTargetedHandlers
{
	return targetedHandlers;
}
@end

@implementation ClipLayer
@synthesize aligning;
@synthesize endTarget = _endTarget;
@synthesize endCall = _endCall;

-(void)addContent:(CCNode *)_layer{
	if (_layer) {
		[self removeAllChildrenWithCleanup:YES];
		[self addChild:_layer z:INT16_MAX tag:INT16_MAX];
		
		[self updateContent];
		
	}
}

/*
 -(CGSize)contentSize{
 CCNode * node = [self getChildByTag:INT16_MAX];
 if(node){
 return node.contentSize;
 }
 return CGSizeMake(0,0);
 }
 */

/*
 *返回当前层的坐标，作为绘制滚动的标记
 */
-(CGPoint)getContentPosition{
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if (_object) {
		return _object.position;
	}
	return CGPointZero;
}

/*
 *停止修正动作
 */
-(void)stopSwipe{
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if (_object) {
		[_object stopAllActions];
	}
}
/*
 *当位置偏移出界限，那么修正位置
 */
-(void)revisionSwipe{
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if (_object) {
		
		CGPoint target = [self getBasePoint];
		
		id move = [CCMoveTo actionWithDuration:1 position:target];
		id action = [CCEaseElasticOut actionWithAction:move period:0.8f];
//		[_object runAction:action];
		[_object runAction:[CCSequence actions:action, [CCCallFunc actionWithTarget:self selector:@selector(endMoveContent)], nil]];
	}
}
-(void)endMoveContent
{
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if (_object) {
		CGPoint point = _object.position;
		if (CGPointEqualToPoint(point, CGPointZero)) {
			if (_endTarget != nil && _endCall != nil) {
				[_endTarget performSelector:_endCall];
			}
		}
	}
}
-(CGPoint)getBasePoint{
	
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if (!_object) return ccp(0,0);
	
	CGPoint target = _object.position;
	
	CGSize lSize = _object.contentSize;
	CGSize sSize = self.contentSize;
	
	float lx = sSize.width - lSize.width;
	float rx = 0;
	float by = sSize.height - lSize.height;
	float ty = 0;
	
	if (target.x > rx) {
		target.x = rx;
	}else if (target.x < lx) {
		target.x = lx;
	}
	if (target.y > ty) {
		target.y = ty;
	}else if (target.y < by) {
		target.y = by;
	}
	
	if(lSize.width<sSize.width){
		target.x = (sSize.width-lSize.width)/2;
	}
	if(lSize.height<sSize.height){
		if (aligning == AligningType_top) {
			target.y = (sSize.height-lSize.height);
		}else
			target.y = (sSize.height-lSize.height)/2;
	}
	return target;
}
-(void)setContentToBottom{
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if (_object) {
		CGPoint target = ccp(0, 0);
		CGSize lSize = _object.contentSize;
		CGSize sSize = self.contentSize;
		if(lSize.width<sSize.width){
			target.x = (sSize.width-lSize.width)/2;
		}
		if(lSize.height<sSize.height){
			target.y = (sSize.height-lSize.height)/2;
		}
		_object.position=target;
	}
}
-(void)setContentToTop:(float)_height{
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if (_object) {
		CGPoint target = ccp(0, 0);
		CGSize lSize = _object.contentSize;
		CGSize sSize = self.contentSize;
		
		target.y = sSize.height - lSize.height;
		target.y += _height;
		
		_object.position = target;
	}
}
-(void)setContentToTop{
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if (_object) {
		CGPoint target = ccp(0, 0);
		CGSize lSize = _object.contentSize;
		CGSize sSize = self.contentSize;
		target.y = sSize.height - lSize.height;
		_object.position = target;
	}
}
/*
 *改变内容层的坐标
 */
-(void)updateContentPosition:(CGPoint)_pt{
	
	CCNode *_object = [self getChildByTag:INT16_MAX];
	
	if(_object.contentSize.width<=self.contentSize.width){
		_pt.x = (self.contentSize.width-_object.contentSize.width)/2;
	}
	if(_object.contentSize.height<=self.contentSize.height){
		if (aligning == AligningType_top) {
			_pt.y = (self.contentSize.height-_object.contentSize.height);
		}else
			_pt.y = (self.contentSize.height-_object.contentSize.height)/2;
	}
	
	if (_object) {
		_object.position = _pt;
	}
	
}

-(void)updateContent{
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if(_object){
		_object.position = [self getBasePoint];
	}
}

/*
 *结束拖拽
 */
-(void)swipeEnd:(CGPoint)_start end:(CGPoint)_end{
	
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
#if PANEL_DEBUG
-(void)draw{
	[super draw];
	//ccDrawColor4B(255, 0, 0, 128);
	//ccDrawRect(CGPointZero, ccp(self.contentSize.width, self.contentSize.height));
}
#endif
@end

@implementation CCPanel

@synthesize isTouchValid = _isTouchValid;
@synthesize isLock = _isLock;
@synthesize swipeDir = swipeDir_;
@synthesize touchSwipe = touchSwipe_;
@synthesize stealTouches = stealTouches_;
@synthesize inertia;
@synthesize endTarget = _endTarget;
@synthesize endCall = _endCall;

+(void)makeNodeQueue:(CCNode*)n vertical:(bool)vert ascending:(bool)asc gep:(int)gep{
	CCArray *nodes=[n children];
	if(asc){
		[nodes reverseObjects];
	}
	int gh=0;
	int gw=0;
	for(CCNode *node in nodes){
		if(!vert){
			[node setPosition:ccp(gw, 0)];
			gw+=node.contentSize.width+gep;
			gh=node.contentSize.height;
		}else{
			[node setPosition:ccp(0, gh)];
			gh+=node.contentSize.height+gep;
			gw=node.contentSize.width;
		}
	}
	[n setContentSize:CGSizeMake(gw, gh)];

}

+(CCPanel*)panelWithContent:(CCNode *)_content viewSize:(CGSize)_vSize{
	return [CCPanel panelWithContent:_content viewPosition:CGPointZero viewSize:_vSize];
}
+(CCPanel*)panelWithContent:(CCNode*)_content viewPosition:(CGPoint)_vPotion viewSize:(CGSize)_vSize{
	CCPanel *m_Panel = [CCPanel node];
	[m_Panel setView:_vPotion :_vSize];
	[m_Panel addContent:_content];
	return m_Panel;
}
-(void)onExit{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	[super onExit];
}


-(void)onEnter{
	[super onEnter];
	self.ignoreAnchorPointForPosition=YES;
	self.touchEnabled=YES;
	self.stealTouches=YES;
	self.swipeDir=Swipe_none;
}

-(id)init
{
	if (self = [super init]) {
		_isLock = NO;
	}
	return self;
}

-(void)registerWithTouchDispatcher{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-255 swallowsTouches:NO];
}
//#if PANEL_DEBUG
-(void)draw{
	[super draw];
	//ccDrawColor4B(0, 0, 255, 128);
	//ccDrawRect(CGPointZero, ccp(self.contentSize.width, self.contentSize.height));
}
//#endif
-(void)createContent{
	content = [ClipLayer node];
	[self addChild:content z:INT16_MAX];
}
-(void)setView:(CGPoint)_vPotion :(CGSize)_vSize{
	if (!content) {
		[self createContent];
	}
	content.position = _vPotion;
	content.contentSize = _vSize;
	float fWidth = _vPotion.x*2 + _vSize.width;
	float fHeight = _vPotion.y*2 + _vSize.height;
	self.contentSize=CGSizeMake(fWidth, fHeight);
}
-(void)addContent:(CCNode*)_layer{
	if (!content) {
		[self createContent];
	}
	[content addContent:_layer];
}
-(CCNode*)getContent{
	return [content getChildByTag:INT16_MAX];
}
#pragma mark touch

-(void)cutOffTouch: (UITouch *) aTouch
{
    CCTouchDispatcher *dispatcher = [[CCDirector sharedDirector] touchDispatcher];
	
	for ( CCTargetedTouchHandler *handler in [dispatcher panelTargetedHandlers] )
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
}
-(BOOL)checkIn:(CGPoint)_pt start:(CGPoint)_stPt end:(CGPoint)_ePt{
	BOOL isIn = YES;
	isIn = isIn && (_pt.x >= _stPt.x);
	isIn = isIn && (_pt.x <= _ePt.x);
	isIn = isIn && (_pt.y >= _stPt.y);
	isIn = isIn && (_pt.y <= _ePt.y);
	return isIn;
}
-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event {
    if( scrollTouch_ == touch ) {
        scrollTouch_ = nil;
    }
}
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	if (_isLock) return NO;
	
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
		self.touchSwipe = touchPoint;
		beginTouch=touchPoint;
		isDropEDGE=NO;
		[[self getContent]stopAllActions];
		state_ = kCCScrollLayerStateIdle;
		if(scrollbar && !isRunAct){
			[scrollbar stopAllActions];
			id ap=[CCFadeIn actionWithDuration:0.2];
			[scrollbar runAction:ap];
			isRunAct=true;
		}
		if(scrollHorzbar && !isRunAct){
			[scrollHorzbar stopAllActions];
			id ap=[CCFadeIn actionWithDuration:0.2];
			[scrollHorzbar runAction:ap];
			isRunAct=true;
		}
		self.isTouchValid = YES ;
		NSDate *dat=[NSDate dateWithTimeIntervalSinceNow:0];
		dropDelayTime=[dat timeIntervalSince1970]*1000;
		
		return YES;
	}else {
		self.isTouchValid = NO ;
		scrollTouch_ = nil;
		return NO;
	}
}
- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	if (_isLock) return;
	
	if( scrollTouch_ != touch ) {
		return;
	}
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	
	if ( (state_ != kCCScrollLayerStateSliding)
		&& ((fabsf(touchPoint.x-touchSwipe_.x) >= minimumTouchLengthToSlide_)
			||(fabsf(touchPoint.y-touchSwipe_.y) >= minimumTouchLengthToSlide_) ) ){
			state_ = kCCScrollLayerStateSliding;
			
			touchSwipe_ = touchPoint;
			if (content) {
				[content stopSwipe];
				layerSwipe_ = [content getContentPosition];
			}
			
			if (stealTouches_)
			{
				[self cutOffTouch:touch];
			}
		}
	
	if (state_ == kCCScrollLayerStateSliding){
		CGPoint temp = ccpSub(touchPoint, touchSwipe_);
#if PANEL_DEBUG
		CCLOG(@"%f|%f| dir:%i",temp.x,temp.y,swipeDir_);
#endif
		CCLOG(@"%f|%f| dir:%i",[self getContent].position.x,[self getContent].position.y,swipeDir_);
		CGPoint newPt = ccpAdd(temp, layerSwipe_);
		if (swipeDir_ == Swipe_none) {
		}else if (swipeDir_ == Swipe_vertical) {
			newPt.x = layerSwipe_.x;
		}else if (swipeDir_ == Swipe_horizon) {
			newPt.y = layerSwipe_.y;
		}
		if (content) {
			[content updateContentPosition:newPt];
		}
	}
	
	if(scrollbar){
		float contenth=[self getContent].contentSize.height-scrollbar.contentSize.height;
		float selfh=self.contentSize.height;
		float proportion=selfh/contenth;
		float posy=abs([self getContent].position.y)*proportion;
		if([self getContent].position.y<0){
			[scrollbar setPosition:ccp(scrollbar.position.x,posy)];
			isDropEDGE=NO;
		}else{
			isDropEDGE=YES;
			[scrollbar setPosition:ccp(scrollbar.position.x,0)];
		}
		if(scrollbar.position.y+scrollbar.contentSize.height>self.contentSize.height){
			[scrollbar setPosition:ccp(scrollbar.position.x,self.contentSize.height-scrollbar.contentSize.height)];
			isDropEDGE=YES;
		}
	}
	if(scrollHorzbar){
		float contentw=[self getContent].contentSize.width-scrollHorzbar.contentSize.width;
		float selfw=self.contentSize.width;
		float proportion=selfw/contentw;
		float posx=abs([self getContent].position.x)*proportion;
		if([self getContent].position.x<0){
			[scrollHorzbar setPosition:ccp(posx,scrollHorzbar.position.y)];
			isDropEDGE=NO;
		}else{
			isDropEDGE=YES;
			[scrollHorzbar setPosition:ccp(0,scrollHorzbar.position.y)];
		}
		if(scrollHorzbar.position.x+scrollHorzbar.contentSize.height>self.contentSize.width){
			[scrollHorzbar setPosition:ccp(self.contentSize.width-scrollHorzbar.contentSize.height,scrollHorzbar.position.y)];
			isDropEDGE=YES;
		}
	}
}
- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if (_isLock) return;
	
	if( scrollTouch_ != touch )
		return;
	if(scrollHorzbar && isRunAct){
		[scrollHorzbar stopAllActions];
		id ap=[CCFadeOut actionWithDuration:1];
		[scrollHorzbar runAction:ap];
		isRunAct=false;
	}
	
	if(isRunAct && scrollbar){
		[scrollbar stopAllActions];
		id ap=[CCFadeOut actionWithDuration:1];
		[scrollbar runAction:ap];
		isRunAct=false;
	}
	
	
#if PANEL_DEBUG
	//CGPoint touchPoint = [touch locationInView:[touch view]];
	//touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	CGPoint temp = ccpSub(touchPoint, [content getContentPosition]);
	CCLOG(@"end %f|%f",temp.x,temp.y);
#endif
	
	NSDate *dat=[NSDate dateWithTimeIntervalSinceNow:0];
	NSTimeInterval time=[dat timeIntervalSince1970]*1000;
	dropDelayTime=time-dropDelayTime;
	
	
	CGPoint disp=getGLpoint(touch);
	
	int disy=(beginTouch.y-disp.y)*-1;
	
	int gotoPos=[self getContent].position.y+disy;
	int TopEdge=(gotoPos+[self getContent].contentSize.height);
	
	if(gotoPos>0 || TopEdge<self.contentSize.height){
		if (content) {
			[content revisionSwipe];
		}
	}else{
		if(dropDelayTime<1000){
			id bfun=[CCCallBlock actionWithBlock:^{
				CCLOG(@"gotopos :%f",[self getContent].position.y);
				if (content) {
					[content revisionSwipe];
				}
			}];
			id move=[CCMoveBy actionWithDuration:2 position:ccp(0,disy)];
			id movebuffer=[CCEaseIn actionWithAction:move rate:0.5];
			id seq=[CCSequence actions:movebuffer,bfun,nil];
			[[self getContent]runAction:seq];
		}else{
			if (content) {
				[content revisionSwipe];
			}
		}
	}
	
	dropDelayTime=0;
	if (state_ == kCCScrollLayerStateIdle) {
		self.isTouchValid = YES ;
	}else{
		self.isTouchValid = NO ;
	}
	
	scrollTouch_ = nil;
}

-(void)setEndTarget:(id)endTarget_
{
	_endTarget = endTarget_;
	if (content) {
		content.endTarget = endTarget_;
	}
}

-(void)setEndCall:(SEL)endCall_
{
	_endCall = endCall_;
	if (content) {
		content.endCall = endCall_;
	}
}

-(void)revisionSwipe{
	if (content) {
		[content revisionSwipe];
	}
}

-(void)updateContent{
	if(content){
		[content updateContent];
	}
}

-(void)updateContentToTop:(float)_height{
	if (content) {
		[content setContentToTop:_height];
		if(scrollbar){
			float contenth=[self getContent].contentSize.height-scrollbar.contentSize.height;
			float selfh=self.contentSize.height;
			float proportion=selfh/contenth;
			float posy=abs([self getContent].position.y)*proportion;
			if([self getContent].position.y<0){
				[scrollbar setPosition:ccp(scrollbar.position.x,posy)];
				isDropEDGE=NO;
			}else{
				isDropEDGE=YES;
				[scrollbar setPosition:ccp(scrollbar.position.x,0)];
			}
			if(scrollbar.position.y+scrollbar.contentSize.height>self.contentSize.height){
				[scrollbar setPosition:ccp(scrollbar.position.x,self.contentSize.height-scrollbar.contentSize.height)];
				isDropEDGE=YES;
			}
		}
	}
}

-(void)updateContentToTopAndSetAligning:(AligningType)_t{
	if (content) {
		content.aligning = AligningType_top;
		if(scrollbar){
			[scrollbar setPosition:ccp(self.contentSize.width, self.contentSize.height-scrollbar.contentSize.height)];
		}
		[content setContentToTop];
	}
}

-(void)updateContentToTop{
	if (content) {
		if(scrollbar){
			[scrollbar setPosition:ccp(self.contentSize.width, self.contentSize.height-scrollbar.contentSize.height)];
		}
		[content setContentToTop];
	}
}

-(void)updateContentToBottom{
	if (content) {
		[content setContentToBottom];
	}
}

-(void)showScrollBar:(NSString*)path{
	if(scrollbar){
        [scrollbar stopAllActions];
		[scrollbar removeFromParentAndCleanup:true];
        scrollbar = nil;
	}
	scrollbar=[CCSprite spriteWithFile:path];
	CGSize size=[self getContent].contentSize;
	float scrollLength=self.contentSize.height/size.height;
	scrollLength=scrollLength*self.contentSize.height;
	scrollLength=scrollLength>self.contentSize.height?self.contentSize.height:scrollLength;
	scrollLength=scrollLength<scrollbar.contentSize.height?scrollbar.contentSize.height+1:scrollLength;
	scrollbar=[StretchingImg stretchingImg:path width:2 height:scrollLength capx:0 capy:scrollbar.contentSize.height/2];
	[scrollbar setAnchorPoint:ccp(0.5, 0)];
	[scrollbar setPosition:ccp(self.contentSize.width, 0)];
	[self addChild:scrollbar z:INT16_MAX];
	[scrollbar stopAllActions];
	id ap=[CCFadeOut actionWithDuration:2];
	[scrollbar runAction:ap];
}

-(void)showHorzScrollBar:(NSString*)path{
	if(scrollHorzbar){
        [scrollbar stopAllActions];
		[scrollHorzbar removeFromParentAndCleanup:true];
        scrollbar = nil;
	}
	scrollHorzbar =[CCSprite spriteWithFile:path];
	CGSize size=[self getContent].contentSize;
	float scrollLength=self.contentSize.width/size.width;
	scrollLength=scrollLength*self.contentSize.width;
	scrollLength=scrollLength<scrollHorzbar.contentSize.height?scrollbar.contentSize.height+1:scrollLength;
	scrollHorzbar=[StretchingImg stretchingImg:path width:1 height:scrollLength capx:0 capy:scrollHorzbar.contentSize.height/2];
	[scrollHorzbar setAnchorPoint:ccp(0.5, 0)];
	[scrollHorzbar setPosition:ccp(0, 0)];
	[scrollHorzbar setRotation:90];
	[self addChild:scrollHorzbar z:INT16_MAX];
	[scrollHorzbar stopAllActions];
	id ap=[CCFadeOut actionWithDuration:2];
	[scrollHorzbar runAction:ap];
}

@end

