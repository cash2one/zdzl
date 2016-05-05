//
//  ScrollPanel.m
//  TXSFGame
//
//  Created by efun on 12-12-30.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "ScrollPanel.h"
#import "UnionPanel.h"

@implementation ScrollPanel

@synthesize delegate;
@synthesize hScrollSprite;
@synthesize contentLayer;

-(void)visit
{
    glScissor(cutRect.origin.x, cutRect.origin.y, cutRect.size.width, cutRect.size.height);
    glEnable(GL_SCISSOR_TEST);
    [super visit];
    glDisable(GL_SCISSOR_TEST);
}

-(void)onEnter
{
	[super onEnter];
	
	// 默认为0
	currentPageIndex = 0;
	
	// 滚动区域，裁剪区域
	if (scrollPanelDir == ScrollPanelDirVertical) {
		[self initScroll];
		
		CGPoint offsetPoint = [self.parent convertToWorldSpace:self.position];
		cutRect = CGRectMake(scrollRect.origin.x + offsetPoint.x,
							 scrollRect.origin.y + offsetPoint.y,
							 scrollRect.size.width,
							 scrollRect.size.height);
	}
	
	else
	{
//		float scrollWidth = [[CCSprite spriteWithFile:@"images/ui/common/scroll1.png"] contentSize].width;
//		scrollRect = CGRectMake(0, 0, self.contentSize.width+scrollWidth/2, self.contentSize.height);
//		
//		CGPoint offsetPoint = [self.parent convertToWorldSpace:self.position];
//		cutRect = CGRectMake(scrollRect.origin.x + offsetPoint.x,
//							 scrollRect.origin.y + offsetPoint.y,
//							 scrollRect.size.width,
//							 scrollRect.size.height);
	}
	
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:scrollPanelPriority swallowsTouches:YES];
}

-(id)initWithDelegate:(id)target direction:(ScrollPanelDir)dir size:(CGSize)size isScrollPage:(BOOL)_isScrollPage priority:(ScrollPanelPriority)priority type:(ScrollPanelType)type
{
	if (self = [super initWithColor:ccc4(0, 0, 0, 0) width:size.width height:size.height]) {
		self.delegate = target;
		scrollPanelDir = dir;
		scrollPanelType = type;
		scrollPanelPriority = priority;
		isScrollPage = _isScrollPage;
	}
	return self;
}

+(ScrollPanel *)create:(id)target direction:(ScrollPanelDir)dir size:(CGSize)size priority:(ScrollPanelPriority)priority isScrollPage:(BOOL)isScrollPage type:(ScrollPanelType)type
{
	return [[[ScrollPanel alloc] initWithDelegate:target direction:dir size:size isScrollPage:isScrollPage priority:priority type:type] autorelease];
}

+(ScrollPanel *)create:(id)target direction:(ScrollPanelDir)dir size:(CGSize)size priority:(ScrollPanelPriority)priority
{
	return [self create:target direction:dir size:size priority:priority isScrollPage:YES type:ScrollPanelTypeNormal];
}

+(ScrollPanel *)create:(id)target direction:(ScrollPanelDir)dir size:(CGSize)size
{
	return [self create:target direction:dir size:size priority:ScrollPanelPriorityNormal isScrollPage:YES type:ScrollPanelTypeNormal];
}

#pragma mark vertical methods begin

-(CGPoint)convertFromLayerPoint:(CGPoint)layerPoint
{
    float y = scrollOrginPoint.y - (1 - layerPoint.y / (self.contentSize.height - contentLayer.contentSize.height)) * scrollRange;
	y = MIN(MAX(y, scrollOrginPoint.y - scrollRange), scrollOrginPoint.y);
    return ccp(scrollOrginPoint.x, y);
}

#pragma mark vertical methods end

-(void)initScroll{
	if (scrollPanelDir == ScrollPanelDirVertical) {
		if (!vScrollSprite) {
			scrollTop = [CCSprite spriteWithFile:@"images/ui/common/scroll1.png"];
			scrollMiddle = [CCSprite spriteWithFile:@"images/ui/common/scroll2.png"];
			scrollBottom = [CCSprite spriteWithFile:@"images/ui/common/scroll1.png"];
			scrollBottom.flipY = YES;
			
			scrollTop.anchorPoint = ccp(0.5, 1);
			scrollMiddle.anchorPoint = ccp(0.5, 0);
			scrollBottom.anchorPoint = ccp(0.5, 0);
			
			vScrollSprite = [CCSprite node];
			vScrollSprite.anchorPoint = ccp(0.5, 1);
			vScrollSprite.visible = NO;
			[vScrollSprite addChild:scrollTop];
			[vScrollSprite addChild:scrollMiddle];
			[vScrollSprite addChild:scrollBottom];
			[self addChild:vScrollSprite z:ScrollVerticalTag];
			
			// 设置scrollRect
			scrollRect = CGRectMake(0, 0, self.contentSize.width+scrollTop.contentSize.width/2, self.contentSize.height);
		}
	} else if (scrollPanelDir == ScrollPanelDirHorizon) {
		hScrollSprite = [CCLayer node];
		[hScrollSprite retain];
	}
}

-(void)resetScroll
{
	if (scrollPanelDir == ScrollPanelDirVertical) {
		pageCount = ceil(contentLayer.contentSize.height / self.contentSize.height);
		vScrollSprite.visible = NO;
		if (contentLayer && contentLayer.contentSize.height > self.contentSize.height) {
			
			vScrollSprite.visible = YES;
			
			scrollOrginPoint = ccp(scrollRect.origin.x + scrollRect.size.width - scrollTop.contentSize.width / 2,
								   scrollRect.origin.y + scrollRect.size.height);
			
			float height = scrollRect.size.height - scrollTop.contentSize.height - scrollBottom.contentSize.height;
			scrollContentHeight = self.contentSize.height * height / contentLayer.contentSize.height;
			scrollRange = height - scrollContentHeight;
			
			scrollMiddle.scaleY = scrollContentHeight / scrollMiddle.contentSize.height;
			vScrollSprite.contentSize = CGSizeMake(scrollTop.contentSize.width,
												   scrollTop.contentSize.height * 2 + scrollContentHeight);
			
			scrollTop.position = ccp(vScrollSprite.contentSize.width / 2, vScrollSprite.contentSize.height);
			scrollMiddle.position = ccp(vScrollSprite.contentSize.width / 2, scrollBottom.contentSize.height);
			scrollBottom.position = ccp(vScrollSprite.contentSize.width / 2, 0);
			
			[self updateScroll];
			[self showFirstPanel];
		}
	}
	else if (scrollPanelDir == ScrollPanelDirHorizon) {
		
	}
}

-(void)updateScroll
{
	if (scrollPanelDir == ScrollPanelDirVertical) {
		vScrollSprite.position = [self convertFromLayerPoint:contentLayer.position];
	}
	else if (scrollPanelDir == ScrollPanelDirHorizon) {
		
	}
}

-(void)setContentLayer:(CCLayer*)_contentLayer
{
	if (_contentLayer) {
		contentLayer = _contentLayer;
		
		[self addChild:_contentLayer];
		
		if (scrollPanelDir == ScrollPanelDirVertical) {
			if (isScrollPage) {
				pageCount = ceil(contentLayer.contentSize.height / self.contentSize.height);
			}
			
			[self initScroll];
			[self resetScroll];
		}
		else if (scrollPanelDir == ScrollPanelDirHorizon) {
			if (isScrollPage) {
				pageCount = ceil(contentLayer.contentSize.width / self.contentSize.width);
			}
			
			CCLOG(@"add clid horizon");
		}
		
		[self showFirstPanel];
	}
	
}

-(void)removeContentLayer
{
	if (contentLayer) {
		[contentLayer removeFromParentAndCleanup:YES];
		contentLayer = nil;
	}
	// 处理纵向
	if (vScrollSprite) {
		[vScrollSprite removeFromParentAndCleanup:YES];
		contentLayer = nil;
	}
	// 处理横向
	if (hScrollSprite) {
		[hScrollSprite removeFromParentAndCleanup:YES];
		[hScrollSprite release];
		hScrollSprite = nil;
	}
}

// touch静止时
-(int)getTargetPageIndex
{
	int targetPageIndex = 0;
	if (scrollPanelDir == ScrollPanelDirVertical) {
		if (contentLayer.position.y > 0) {
			targetPageIndex = pageCount - 1;
		}
		else {
			targetPageIndex = pageCount - round(ABS(contentLayer.position.y / self.contentSize.height)) - 1;
		}
	}
	else if (scrollPanelDir == ScrollPanelDirHorizon) {
		targetPageIndex = round(ABS(contentLayer.position.x / self.contentSize.width));
	}
	
	int  _temp = targetPageIndex > 0 ? targetPageIndex : 0 ; //MAX(targetPageIndex, 0) ;
	return MIN(_temp, pageCount-1);
}
// 获取目标页码
// next为index增加
// touch拖拽时
-(int)getTargetPageIndex:(BOOL)next
{
	int targetPageIndex = [self getTargetPageIndex];
	targetPageIndex = targetPageIndex + (next ? 1 : -1);
	return MIN(MAX(targetPageIndex, 0), pageCount-1);
}

// 通过pageIndex获得最终坐标
-(CGPoint)getPointWithPageIndex:(int)_pageIndex position:(CGPoint)__position
{
	CGPoint point = ccp(0,0);
	if (scrollPanelDir == ScrollPanelDirVertical) {
		point = ccp(__position.x,
					(_pageIndex + 1 - pageCount) * self.contentSize.height);
	}
	else if (scrollPanelDir == ScrollPanelDirHorizon) {
		point = ccp(-_pageIndex * self.contentSize.width, __position.y);
	}
	return point;
}

-(void)moveToPosition:(CGPoint)__position
{
	if (contentLayer) {
		float duration = 0.3;
		
		CCMoveTo *contentMoveTo = [CCMoveTo actionWithDuration:duration position:__position];
		[contentLayer runAction:[CCEaseOut actionWithAction:contentMoveTo rate:1]];
		
		if (scrollPanelDir == ScrollPanelDirVertical) {
			CGPoint finalVerticalScrollPoint = [self convertFromLayerPoint:__position];
			CCMoveTo *scrollMoveTo = [CCMoveTo actionWithDuration:duration position:finalVerticalScrollPoint];
			if (vScrollSprite) {
				[vScrollSprite runAction:[CCEaseOut actionWithAction:scrollMoveTo rate:1]];// 回调
			}
		}
	}
}

// 移到某一页
-(void)moveToPageIndex:(int)_pageIndex
{
	if (contentLayer) {
		
		CGPoint finalPoint = [self getPointWithPageIndex:_pageIndex position:contentLayer.position];
		[self moveToPosition:finalPoint];
		
	}
}

// 更新滚动条
-(void)updateScrollWithPageIndex:(int)_pageIndex
{
	if (scrollPanelDir == ScrollPanelDirVertical) {
//		[self updateVerticalScroll];
		[self updateScroll];
	}
	else if (scrollPanelDir == ScrollPanelDirHorizon) {
		CCLOG(@"水平页码 %d", _pageIndex);
	}
}

-(void)showWithPageIndex:(int)_pageIndex
{
	// 不是一次滚动一页，return
	if (!isScrollPage) {
		return;
	}
	
	if (_pageIndex < 0 || _pageIndex >= pageCount) {
		return;
	}
	
	contentLayer.position = [self getPointWithPageIndex:_pageIndex position:contentLayer.position];
	
	[self updateScrollWithPageIndex:_pageIndex];
	
	currentPageIndex = _pageIndex;
}

// 显示前面的内容
-(void)showFirstPanel
{
	if (isScrollPage) {
		[self showWithPageIndex:0];
	} else {
		
		if (scrollPanelDir == ScrollPanelDirVertical) {
			// x == 0?
			contentLayer.position = ccp(0, self.contentSize.height - contentLayer.contentSize.height);
//			[self updateVerticalScroll];
			[self updateScroll];
		}
	}
}

// 滚动完成回调
-(void)scrollDoneCallback:(id)sender
{
	if (delegate && [delegate respondsToSelector:@selector(scrollDoneCallback:)]) {
		[delegate scrollDoneCallback:self];
	}
}

// 移动时，返回位置
-(CGPoint)boundConentLayerPosition:(CGPoint)position offset:(CGPoint)offset
{
	if (scrollPanelDir == ScrollPanelDirVertical) {
		if (isScrollPage) {
			position = ccp(position.x, MIN(MAX(position.y - offset.y, -pageCount * self.contentSize.height), self.contentSize.height));
		} else {
			position = ccp(position.x, MIN(MAX(position.y - offset.y, self.contentSize.height-contentLayer.contentSize.height), 0));
		}
	}
	else if (scrollPanelDir == ScrollPanelDirHorizon) {
		
		// isScrollPage
		
		// offset.x + or -
		position = ccp(MIN(MAX(position.x + offset.x, -pageCount * self.contentSize.width), self.contentSize.width), position.y);
	}
	return position;
}

// 释放拖拽后位置调整
-(void)checkContentLayerWithOffsetPosition:(CGPoint)offset
{
	if (contentLayer) {
		if (isScrollPage) {
			
			BOOL next = NO;
			BOOL inertia = NO;	// 惯性
			
			if (scrollPanelDir == ScrollPanelDirHorizon) {
				// offset.x < 0 or > 0
				next = offset.x < 0;
				inertia = ABS(offset.x) >= Scroll_Velocity;
			}
			// 可拖拽物品
			else if (scrollPanelDir == ScrollPanelDirVertical) {
				next = offset.y < 0;
				inertia = ABS(offset.y) >= Scroll_Velocity;
			}
			
			int pageIndex;
			if (inertia) {
				pageIndex = [self getTargetPageIndex:next];
			} else {
				pageIndex = [self getTargetPageIndex];
			}
			
			[self moveToPageIndex:pageIndex];
		}
		
		else {
			CGPoint finalPoint = [self boundConentLayerPosition:contentLayer.position offset:offset];
			[self moveToPosition:finalPoint];
		}
	}
}

#pragma mark touch action

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
	
	// 没有滚动条
	if (scrollPanelDir == ScrollPanelDirVertical && !vScrollSprite) {
		return NO;
	} else if (scrollPanelDir == ScrollPanelDirHorizon && !hScrollSprite) {
		return NO;
	}
	
	if (CGRectContainsPoint(scrollRect, touchLocation)) {
		isMoved = NO;
		
		if (contentLayer) {
			[contentLayer stopAllActions];
			
			// 不可拖拽物品
			if (scrollPanelType == ScrollPanelTypeNormal) {
				
				if (delegate && [delegate respondsToSelector:@selector(ccSPTouchBegan:withEvent:)]) {
					return [delegate ccSPTouchBegan:touch withEvent:event];
				}
			}
			// 可拖拽物品
			else if (scrollPanelType == ScrollPanelTypeItem) {
				
			}
		}
		
		return YES;
	}
	return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	
	// 不可拖拽物品
	if (scrollPanelType == ScrollPanelTypeNormal) {
		
		isMoved = YES;
		
		CGPoint pervisionPoint = [touch previousLocationInView:touch.view];
		CGPoint currentPoint = [touch locationInView:touch.view];
		CGPoint offsetPoint = ccpSub(currentPoint, pervisionPoint);
		
		if (contentLayer) {
			contentLayer.position = [self boundConentLayerPosition:contentLayer.position offset:offsetPoint];
			[self updateScroll];
		}
		
	}
	// 可拖拽物品
	else if (scrollPanelType == ScrollPanelTypeItem) {
		
	}
	
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	// 不可拖拽物品
	if (scrollPanelType == ScrollPanelTypeNormal) {
		
		CGPoint pervisionPoint = [touch previousLocationInView:touch.view];
		CGPoint currentPoint = [touch locationInView:touch.view];
		CGPoint offsetPoint = ccpSub(currentPoint, pervisionPoint);
		
		// 检查位置
		[self checkContentLayerWithOffsetPosition:offsetPoint];
		
		// 普通情况下Moved后不再传递Ended事件
		if (!isMoved && delegate && [delegate respondsToSelector:@selector(ccSPTouchEnded:withEvent:)]) {
			[delegate ccSPTouchEnded:touch withEvent:event];
		}
	}
	// 可拖拽物品
	else if (scrollPanelType == ScrollPanelTypeItem) {
		
	}
	
}

-(void)onExit
{
	
	[self removeContentLayer];
	
	[super onExit];
	
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	
}

@end
