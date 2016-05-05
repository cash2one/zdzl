//
//  CCPanelPage.m
//  TXSFGame
//
//  Created by efun on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "CCPanelPage.h"
#import "CFPage.h"

@interface ClipPageLayer : ClipLayer
{
	id  page_target;
	SEL page_call;
}
@property(nonatomic,assign)id  page_target;
@property(nonatomic,assign)SEL page_call;

@end

@implementation ClipPageLayer

@synthesize page_call;
@synthesize page_target;

/*
 *转页，目前只做水平方向，而且CCPanel使转页类型才能出发这函数
 */
-(void)pageTurning:(int)_dir{
	//翻页
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if (_object) {
		BOOL _bx = (_dir == 1 || _dir == 2);//水平方向 1-> 2<-
		if (_bx) {
			id _move = nil;
			
			float _x = _object.position.x;
			float _w = [self getPageDimension:YES];
			if (_x > 0) {
				CGPoint pt = ccp(0, _object.position.y);
				_move = [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:0.5 position:pt]];
			}else if (_x < ((_object.contentSize.width - _w)*-1)){
				CGPoint pt = ccp((_object.contentSize.width - _w)*-1, _object.position.y);
				_move = [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:0.5 position:pt]];
			}else{
				if (_dir == 1) {
					//->
					int num = (int)(_x/_w);
					num -= 1;
					float cut = num*_w;
					float dis = fabsf(_x-cut);
					if (dis > (_w/3)) {
						CGPoint pt = ccp(cut + _w, _object.position.y);
						if (pt.x > 0) {
							pt.x = 0 ;
						}
						_move = [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:0.5 position:pt]];
					}else{
						CGPoint pt = ccp(cut, _object.position.y);
						_move = [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:0.5 position:pt]];
					}
					
				}else{
					//<-
					int num = (int)(_x/_w);
					float cut = num*_w;
					float dis = fabsf(_x-cut);
					if (dis > (_w/3)) {
						CGPoint pt = ccp(cut - _w, _object.position.y);
						if (pt.x < (_object.contentSize.width - _w)*-1) {
							pt.x = (_object.contentSize.width - _w)*-1 ;
						}
						_move = [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:0.5 position:pt]];
					}else{
						CGPoint pt = ccp(cut, _object.position.y);
						_move = [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:0.5 position:pt]];
					}
				}
			}
			if (_move) {
				if (page_target != nil && page_call != nil) {
					id act = [CCCallFunc actionWithTarget:page_target selector:page_call];
					[_object runAction:[CCSequence actions:_move,act,nil]];
				}else{
					[_object runAction:_move];
				}
			}
		}
	}
}
/*
 *获得当前的页数
 *参数代表使不使水平方向
 */
-(int)getCurrentPageCount:(BOOL)_bX{
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if (_object) {
		if (_bX) {
			float _x = _object.position.x;
			float _w = [self getPageDimension:YES];
			int num = (int)(_x/_w);
			return abs(num);
		}
		
	}
	return 0;
}
/*
 *获得全部的页数
 *参数代表使不使水平方向
 */
-(int)getPageCount:(BOOL)_bX{
	float _w = [self getPageDimension:_bX];
	CCNode *_object = [self getChildByTag:INT16_MAX];
	if (_object) {
		float total = _bX?_object.contentSize.width:_object.contentSize.height;
		int count = total/_w;
		return count;
	}
	return -1;
}
-(float)getPageDimension:(BOOL)_bX{
	return _bX?self.contentSize.width:self.contentSize.height;
}
-(void)updateContentPositionWithPage:(CGPoint)_pt{
	CCNode *_object = [self getChildByTag:INT16_MAX];
	
	if(_object.contentSize.width<=self.contentSize.width){
		_pt.x = (self.contentSize.width-_object.contentSize.width)/2;
	}
	if(_object.contentSize.height<=self.contentSize.height){
		_pt.y = (self.contentSize.height-_object.contentSize.height)/2;
	}
	
	if (_object) {
		_object.position = _pt;
	}
}

@end

@implementation CCPanelPage

+(CCPanelPage*)panelWithContent:(CCNode *)_content viewSize:(CGSize)_vSize{
	return [CCPanelPage panelWithContent:_content viewPosition:CGPointZero viewSize:_vSize];
}
+(CCPanelPage*)panelWithContent:(CCNode*)_content viewPosition:(CGPoint)_vPotion viewSize:(CGSize)_vSize{
	CCPanelPage *m_Panel = [CCPanelPage node];
	[m_Panel setView:_vPotion :_vSize];
	[m_Panel addContent:_content];
	return m_Panel;
}

-(void)onEnter
{
	[super onEnter];
	
	PageDot * pageBack = [PageDot node];
	[self addChild:pageBack z:INT16_MAX tag:PageDot_Tag];
	[pageBack setDotCount:[pageContent getPageCount:YES]];// YES为横向
	[pageBack setSize:CGSizeMake(content.contentSize.width,cFixedScale(26))];
	[pageBack setIndex:0];
	pageBack.position = ccp(content.contentSize.width/2,cFixedScale(20));
}

-(void)dealloc{
	[super dealloc];
}

-(void)createContent{
	pageContent = [ClipPageLayer node];
	pageContent.page_target=self;
	pageContent.page_call=@selector(showPageNumber);
	content = (ClipLayer *)pageContent;
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
- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
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
#ifdef PANEL_DEBUG
		CCLOG(@"%f|%f",temp.x,temp.y);
#endif
		// 设定为一滚一页
		//		if (swipeType_ == Swipe_volti) {
		if (YES) {
			CGPoint newPt = ccpAdd(temp, layerSwipe_);
			newPt.y = layerSwipe_.y;
			[pageContent updateContentPositionWithPage:newPt];
			//			[content updateContentPositionWithPage:newPt];
		}else{
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
	}
	
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if( scrollTouch_ != touch )
		return;
	
	scrollTouch_ = nil;
	CGPoint touchPoint = [touch locationInView:[touch view]];
	touchPoint = [[CCDirector sharedDirector] convertToGL:touchPoint];
	
#ifdef PANEL_DEBUG
	CGPoint temp = ccpSub(touchPoint, [content getContentPosition]);
	CCLOG(@"end %f|%f",temp.x,temp.y);
#endif
	
	// 设定为一滚一页
	//	if (swipeType_ == Swipe_volti) {
	if (YES) {
		[pageContent pageTurning:(touchPoint.x > touchSwipe_.x)?1:2];
	}else{
		if (content) {
			[content revisionSwipe];
		}
	}
}

#pragma mark Swipe_volti
-(void)showPageNumber{
	//	if (swipeType_ != Swipe_volti) {
	//		return ;
	//	}
	// 设定为一滚一页
	CCLOG(@"showPageNumber->%d",[pageContent getCurrentPageCount:YES]);
	
	PageDot *pageDot = (PageDot *)[self getChildByTag:PageDot_Tag];
	if (pageDot) {
		[pageDot setIndex:[pageContent getCurrentPageCount:YES]];
	}
}

-(void)updateContentPosition:(CGPoint)_pt
{
	[pageContent updateContentPositionWithPage:_pt];
	[self showPageNumber];
}

@end
