//
//  ScrollPanel.h
//  TXSFGame
//
//  Created by efun on 12-12-30.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "cocos2d.h"

#define Scroll_Time_MAX		300.0f
#define Scroll_Velocity		2.0f

@class ScrollPanel;

// 优先级
typedef enum {
	ScrollPanelPriorityNormal = kCCMenuHandlerPriority+1,	// 滚动层有菜单时候用(默认)
	ScrollPanelPriorityHigh = kCCMenuHandlerPriority-1,		// 
} ScrollPanelPriority;

// 滚动方向
typedef enum {
	ScrollPanelDirVertical = 1,	// 垂直
	ScrollPanelDirHorizon,		// 水平
} ScrollPanelDir;

// 滚动形式
typedef enum {
	ScrollPanelTypeItem = 1,	// 可拖拽物品
	ScrollPanelTypeNormal,		// (默认)
} ScrollPanelType;

// Tag
typedef enum {
	ScrollVerticalTag = 5000,	// 垂直滚动
	ScrollHorizonTag,			// 水平
	ScrollPanelContentTag,		// 内容层
} ScrollPanelTag;

@protocol ScrollPanelDelegate <NSObject>

@optional
-(BOOL)ccSPTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event;	// 有用到touch事件，具体实现在以下三个方法实现
-(void)ccSPTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event;
-(void)ccSPTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event;
-(void)scrollDoneCallback:(ScrollPanel*)scrollPanel;	// 滚动完成后回调

@end

@interface ScrollPanel : CCLayerColor
{
	int pageCount;			// 页数
	int currentPageIndex;	// 当前页码(默认显示第一页，即0)
	
	CGFloat touchTime;		// 点击时间touchTime = [NSDate timeIntervalSinceReferenceDate];
	
	CGRect scrollRect;		// 滚动检测区域
	CGRect cutRect;			// 裁剪区域
	
	BOOL isMoved;			// Began后是否运行Moved，如果移动了，返回YES
	BOOL isScrollPage;		// 一次翻一页(默认)
	
	// 纵向滚动条
	CCSprite *scrollTop;
    CCSprite *scrollMiddle;
    CCSprite *scrollBottom;
    CCSprite *vScrollSprite;
    CGPoint scrollOrginPoint;
	float scrollContentHeight;
    float scrollRange;
	
	ScrollPanelDir scrollPanelDir;
	ScrollPanelType scrollPanelType;
	ScrollPanelPriority scrollPanelPriority;
}

@property (nonatomic, assign) NSObject<ScrollPanelDelegate> *delegate;
@property (nonatomic, assign) CCLayer *hScrollSprite;	// 横向滚动当前页(可能要调整位置)
@property (nonatomic, assign) CCLayer *contentLayer;

/*
 *	dir				滚动方向
 *	size			滚动面板大小
 *	priority		该layer touch优先级(默认比Menu高级)
 *	isScrollPage	是否一次滚动一页(默认是)
 */
+(ScrollPanel *)create:(id)target direction:(ScrollPanelDir)dir size:(CGSize)size priority:(ScrollPanelPriority)priority isScrollPage:(BOOL)isScrollPage type:(ScrollPanelType)type;
+(ScrollPanel *)create:(id)target direction:(ScrollPanelDir)dir size:(CGSize)size priority:(ScrollPanelPriority)priority;
+(ScrollPanel *)create:(id)target direction:(ScrollPanelDir)dir size:(CGSize)size;

// 删掉内容
-(void)removeContentLayer;
// 显示某页内容
-(void)showWithPageIndex:(int)_pageIndex;
// 重置滚动
-(void)resetScroll;

@end
