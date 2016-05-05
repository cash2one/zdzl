//
//  WidgetTable.h
//  TXSFGame
//
//  Created by Soul on 13-5-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "WidgetContainer.h"

typedef enum{
	AlignType_default  = 0,
	AlignType_linear_x = 1,
	AlignType_linear_y = 2,
}AlignType;

typedef enum
{
	
	touchLayerStateNo_, //没有动作
	
	touchLayerStateTopIn_, //点击顶层
	touchLayerStateBottomIn_,//点击下层
	
	touchLayerStateTopSlid_,//滑动顶层
	touchLayerStateBottomSlid_,//滑动下层
	
}TouchLayerState;

@interface WidgetTable : WidgetContainer {
    WidgetContainer* _canvas;
	CGPoint			 _alignPt;
	AlignType		 _alignType;
	float			 _alignGap;
	
	UITouch *scrollTouch_;
	CGPoint touchSwipe_;
	CGPoint layerSwipe_;
	CGPoint powerSwipe_;
	CGFloat minimumTouchLengthToSlide_;
	CGFloat minimumTouchLengthToChangePage_;
	
	TouchLayerState state_;
	BOOL stealTouches_;
	
	Widget*	focusWidget;
	
}

@property(nonatomic,assign)WidgetContainer* canvas;
@property(nonatomic,assign)CGPoint alignPt;
@property(nonatomic,assign)AlignType alignType;

-(void)removeCell:(Widget*)widget;
-(void)addCell:(Widget*)widget;
-(void)addCells:(NSArray*)array;
-(void)addCells:(NSArray*)array index:(int)index;

@end
