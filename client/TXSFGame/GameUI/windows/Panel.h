//
//  Panel.h
//  TXSFGame
//
//  Created by shoujun huang on 12-12-5.
//  Copyright 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


typedef enum  
{
    SlideDirNone = 0,
    SlideDirHorizon,
    SlideDirVertical,
}SlideDir;

typedef enum
{
    Panel_Touch_Begin = 1,      // 传递touch begin事件
    Panel_Touch_Begin_Ended,    // 传递touch begin事件，如果不滚动，还会传递touch ended事件
    Panel_Touch_Ended,          // 如果不滚动，传递touch ended事件(默认)
} Panel_Touch_Type;

@interface ContentLayer : CCLayerColor

@property (nonatomic) CGRect viewRect;

@end

@interface Panel : CCLayerColor {
    int currentPage;
    int pageCount;
    float pageDistance;
    float pageVelocity;
    float pageDuration;
    
    CCSprite *scrollTop;
    CCSprite *scrollMiddle;
    CCSprite *scrollBottom;
    CCSprite *scrollSprite;
    CGPoint scrollOrginPoint;
    
    float scrollContentHeight;
    float scrollRange;
    BOOL isScroll;
    
    CGRect viewRect;
    
    UIPanGestureRecognizer *panGesture;
    
    ContentLayer *contentLayer;
}
@property (nonatomic) Panel_Touch_Type touchType;
@property (nonatomic) BOOL isScrollPage;        // 是否滚动一个界面为一个页
@property (nonatomic, assign) CCLayer *layer;
@property (nonatomic, assign) CCLayer *touchLayer;          // 如果不移动，像touchLayer传递ccTouchEnded事件
-(void)initScroll;
@end
