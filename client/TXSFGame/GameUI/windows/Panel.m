
//
//  Panel.m
//  TXSFGame
//
//  Created by shoujun huang on 12-12-5.
//  Copyright 2012年 eGame. All rights reserved.
//

#import "Panel.h"

@implementation ContentLayer

@synthesize viewRect;

-(void)visit
{
    glScissor(viewRect.origin.x, viewRect.origin.y, viewRect.size.width, viewRect.size.height);
    glEnable(GL_SCISSOR_TEST);
    [super visit];
    glDisable(GL_SCISSOR_TEST);
}

@end

@implementation Panel

@synthesize touchType;
@synthesize isScrollPage;
@synthesize layer;
@synthesize touchLayer;

-(CGPoint)convertFromLayerPoint:(CGPoint)layerPoint
{
    float y = scrollOrginPoint.y - (1 - layerPoint.y / (self.contentSize.height - layer.contentSize.height)) * scrollRange;
    return ccp(scrollOrginPoint.x, y);
}

-(void)updateScroll
{
    scrollSprite.position = [self convertFromLayerPoint:layer.position];
}

-(void)initScroll
{
    scrollSprite.visible = NO;
    layer.position = ccp(0, self.contentSize.height - layer.contentSize.height);
    pageCount = layer.contentSize.height / pageDistance;
    
    if (layer.contentSize.height > self.contentSize.height) {
        scrollSprite.visible = YES;

        scrollOrginPoint = ccp(viewRect.origin.x + viewRect.size.width,
                               viewRect.origin.y + viewRect.size.height);
        
        float height = viewRect.size.height - scrollTop.contentSize.height - scrollBottom.contentSize.height;
        scrollContentHeight = self.contentSize.height * height / layer.contentSize.height;
        scrollRange = height - scrollContentHeight;
        
        scrollMiddle.scaleY = scrollContentHeight / scrollMiddle.contentSize.height;
        
        scrollSprite.contentSize = CGSizeMake(scrollTop.contentSize.width,
                                              scrollTop.contentSize.height * 2 + scrollContentHeight);
        
        scrollTop.position = ccp(scrollSprite.contentSize.width / 2, scrollSprite.contentSize.height);
        scrollMiddle.position = ccp(scrollSprite.contentSize.width / 2, scrollBottom.contentSize.height);
        scrollBottom.position = ccp(scrollSprite.contentSize.width / 2, 0);

        [self updateScroll];
    }
}

-(void)onEnter
{
    [super onEnter];
    
    contentLayer = [[[ContentLayer alloc] initWithColor:ccc4(0, 0, 0, 0) width:self.contentSize.width height:self.contentSize.height] autorelease];
    [self addChild:contentLayer];
    
    CGPoint offsetPoint = [self.parent convertToWorldSpace:self.position];
    viewRect = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
    
    contentLayer.viewRect = CGRectMake(viewRect.origin.x + offsetPoint.x + 1,
                                       viewRect.origin.y + offsetPoint.y + 1,
                                       viewRect.size.width - 1,
                                       viewRect.size.height - 1);
    
    currentPage = 0;
    pageVelocity = 40;
    pageDuration = 0.5;
    pageDistance = self.contentSize.height;
    
    if (layer && !layer.parent) {
        [contentLayer addChild:layer];
    }
    
    // scroll
    if (!scrollSprite) {
        scrollTop = [CCSprite spriteWithFile:@"images/ui/common/scroll1.png"];
        scrollMiddle = [CCSprite spriteWithFile:@"images/ui/common/scroll2.png"];
        scrollBottom = [CCSprite spriteWithFile:@"images/ui/common/scroll1.png"];
        scrollBottom.flipY = YES;
        
        scrollTop.anchorPoint = ccp(0.5, 1);
        scrollMiddle.anchorPoint = ccp(0.5, 0);
        scrollBottom.anchorPoint = ccp(0.5, 0);
        
        scrollSprite = [CCSprite node];
        scrollSprite.anchorPoint = ccp(0.5, 1);
        [scrollSprite addChild:scrollTop];
        [scrollSprite addChild:scrollMiddle];
        [scrollSprite addChild:scrollBottom];
        
        [self addChild:scrollSprite z:1000];
    }
	
    [self initScroll];
    
    isScrollPage = YES;
    
    if (touchType == 0) {
        touchType = Panel_Touch_Ended;
    }
    
    CCDirector *director = [CCDirector sharedDirector];
    [[director touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority+1 swallowsTouches:YES];
}

-(int)getNextPageIndex:(BOOL)up
{
    BOOL isWhole = layer.position.y / _contentSize.height == 0 ? YES : NO;
    
    int nextPage = floor(ABS(layer.position.y) / _contentSize.height);
    if (up && isWhole) {
        nextPage--;
    }
    if (!up) {
        nextPage++;
    }
    nextPage = MIN(MAX(nextPage, 0), pageCount - 1);
    return nextPage;
}

-(int)getNextPageIndex
{
    int nextPage = ABS(round(layer.position.y / self.contentSize.height));
    return nextPage;
}

-(void)moveToPageIndex:(int)index
{
    CGPoint finalPoint = ccp(layer.position.x, -index * self.contentSize.height);
    
    float distance = ABS(layer.position.x - index * (-_contentSize.height));
    float duration = (distance - self.contentSize.height / 2 > 0) ? pageDuration : pageDuration / 2;
    CGPoint finalScrollPoint = [self convertFromLayerPoint:finalPoint];
    
    CCMoveTo *contentMoveTo = [CCMoveTo actionWithDuration:duration position:finalPoint];
    CCMoveTo *scrollMoveTo = [CCMoveTo actionWithDuration:duration position:finalScrollPoint];
    [layer runAction:[CCEaseOut actionWithAction:contentMoveTo rate:1]];
    [scrollSprite runAction:[CCEaseOut actionWithAction:scrollMoveTo rate:1]];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
    if (touchType == Panel_Touch_Begin || touchType == Panel_Touch_Begin_Ended) {
        if (touchLayer && [touchLayer respondsToSelector:@selector(ccTouchBegan:withEvent:)]) {
            [touchLayer ccTouchBegan:touch withEvent:event];
        }
    }
    
    isScroll = NO;
    
    if (CGRectContainsPoint(viewRect, touchLocation)) {
        [layer stopAllActions];
        [scrollSprite stopAllActions];
        
        return YES;
    }
    return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint pervisionPoint = [touch previousLocationInView:touch.view];
    CGPoint currentPoint = [touch locationInView:touch.view];
    CGPoint offsetPoint = ccpSub(currentPoint, pervisionPoint);
    
    float finalY = layer.position.y - offsetPoint.y;
    finalY = MIN(MAX(finalY, self.contentSize.height - layer.contentSize.height), 0);
    layer.position = ccp(layer.position.x, finalY);
    
    [self updateScroll];
    
    isScroll = YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint pervisionPoint = [touch previousLocationInView:touch.view];
    CGPoint currentPoint = [touch locationInView:touch.view];
    CGPoint offsetPoint = ccpSub(currentPoint, pervisionPoint);
    
    float scrollDuration = 0.2;
    // 按界面
    if (isScrollPage) {
        currentPage = floor(ABS(layer.position.y) / self.contentSize.height);
        
        // 翻滚页面
        if (ABS(offsetPoint.y) > pageVelocity) {
            [self moveToPageIndex:[self getNextPageIndex:(offsetPoint.y < 0)]];
        }
        // 判断位移下一页
        else {
            [self moveToPageIndex:[self getNextPageIndex]];
        }
    }
    // 当前停止
    else {
        float finalY = layer.position.y - offsetPoint.y * scrollDuration;
        finalY = MIN(MAX(finalY, self.contentSize.height - layer.contentSize.height), 0);
        
        CCMoveTo *contentMoveTo = [CCMoveTo actionWithDuration:scrollDuration position:ccp(layer.position.x, finalY)];
        CCMoveTo *scrollMoveTo = [CCMoveTo actionWithDuration:scrollDuration position:[self convertFromLayerPoint:ccp(layer.position.x, finalY)]];
        [layer runAction:[CCEaseOut actionWithAction:contentMoveTo rate:2]];
        [scrollSprite runAction:[CCEaseOut actionWithAction:scrollMoveTo rate:2]];
    }
    
    if (!isScroll && (touchType == Panel_Touch_Ended || touchType == Panel_Touch_Begin_Ended)) {
        if (touchLayer && [touchLayer respondsToSelector:@selector(ccTouchEnded:withEvent:)]) {
            [touchLayer ccTouchEnded:touch withEvent:event];
        }
    }
}

-(void)onExit
{
	
    [super onExit];
    
    CCDirector *director = [CCDirector sharedDirector];
    [[director touchDispatcher] removeDelegate:self];
}

@end
