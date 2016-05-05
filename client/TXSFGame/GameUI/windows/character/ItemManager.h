//
//  ItemManager.h
//  TXSFGame
//
//  Created by Soul on 13-3-7.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "ItemTray.h"
#import "CFPage.h"



//typedef enum
//{
//	kCCScrollLayerStateIdle_,
//	kCCScrollLayerStateSliding_,
//	
//}Touch_state_;

typedef enum
{
	
	tCCScrollLayerStateNo_, //没有动作
	
	tCCScrollLayerStateTopIn_, //点击顶层
	tCCScrollLayerStateBottomIn_,//点击下层
	
	tCCScrollLayerStateTopSlid_,//滑动顶层
	tCCScrollLayerStateBottomSlid_,//滑动下层
	
	
}Touch_state_;


@class ItemTrayContainer;
@class PageDot;

@interface ItemCanvas : CCLayer{
	float	_paintX;
	float	_paintY;
	
	int		_freeIndex;
	int		_startIndex;
	
	int		_maxCount;
	
	int		_focusIndex;
	int		_lastIndex;

	CGSize	_eachSize;
	
	id		_target;
	SEL		_callPageCount;
	
}
@property(nonatomic,assign)id	target;
@property(nonatomic,assign)SEL	callPageCount;

@property(nonatomic,assign)int focusIndex;
@property(nonatomic,assign)CGSize eachSize;

+(ItemCanvas*)createCanvas:(int)_cap;

@end

@interface ItemManager : CCLayer {
	
	//-------------------------------
	UITouch *scrollTouch_;
	CGPoint touchSwipe_;
	CGPoint layerSwipe_;
	CGPoint powerSwipe_;
	CGFloat minimumTouchLengthToSlide_;
	CGFloat minimumTouchLengthToChangePage_;
	int state_;
	BOOL stealTouches_;
	//-------------------------------
	
	ItemTray*	_itemTray;//用于记录那个被选中的物品格
	ItemCanvas* _canvas;//上面是物品的容器，包含N(N>0 && N < 玩家的最大物品页数)个容器
	PageDot*	_pageDot;//显示页码
	
	ItemManager_show_type _showType;
	
	BOOL	_isMarkModel;
	
	id				_shiftTarget;
	SEL				_shiftCall;
	ItemTray_type	_shiftType;
}
@property(nonatomic,assign)ItemManager_show_type showType;
@property(nonatomic,assign)CGPoint  touchSwipe;
@property(nonatomic,assign)PageDot* pageDot;
@property(nonatomic,assign)id shiftTarget;
@property(nonatomic,assign)SEL shiftCall;
@property(nonatomic,assign)ItemTray_type shiftType;
@property(nonatomic,assign)DataHelper_type dataType;

+(ItemManager*)shared;
+(ItemManager*)initWithDimension:(CGSize)_dimension;
-(int)getContainerAmount;

-(void)updateContainerWithType:(ItemManager_show_type)_stype;
-(void)updateJewelContainerWithPart:(EquipmentPart)_part;

-(void)updatePageDotCount:(NSNumber*)_sender;
-(void)updatePageDotIndex:(int)_inx;

-(void)eventForAddJewel:(NSDictionary*)_dict;
-(void)eventForAddEquipment:(NSDictionary*)_dict;
-(void)eventForAddStone:(NSDictionary*)_dict;
-(ItemTray*)eventForDeleteItemTray:(int)_id type:(int)_type;

-(void)openMarketModel:(BOOL)_isOpen;
-(BOOL)isMarkModel;
-(void)freeSelect;


//-(ItemTray*)eventForGetEquipment:(int)_prarm1 type:(int)_prarm2;

@end
