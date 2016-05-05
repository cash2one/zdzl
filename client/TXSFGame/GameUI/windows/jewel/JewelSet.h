//
//  JewelSet.h
//  TXSFGame
//
//  Created by efun on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "WindowComponent.h"

@class ItemManager;

// 珠宝镶嵌滚动层
@interface JewelSetScroll : CCLayer
{
	int index;
	int roleId;
	int part;
	
	id target;
	SEL call;
	
	CCSprite *upIcon;
	CCSprite *downIcon;
	CCLabelTTF *typeLabel;
	
	NSMutableArray *partArray;
}

@property (nonatomic, assign) int roleId;
@property (nonatomic, assign) int part;
@property (nonatomic, assign) id target;
@property (nonatomic, assign) SEL call;

+(JewelSetScroll*)create:(int)_roleId part:(int)_part;

-(void)updateScroll:(int)_roleId part:(int)_part;

@end

// 珠宝镶嵌
@interface JewelSet : WindowComponent
{
	BOOL isRequesting;
	
	int part;
	int ueid;
	int roleId;
	
	CGPoint _panelPos;
	CGPoint _itemManagerPos;
	CGPoint _packageAmountPos;
	CGPoint _dialPos;
	CGPoint _scrollPos;
	
	BOOL isFirstPart;
	int maxCount;
	NSMutableArray *countArray;
	
	CCSprite *dialBg;
	CCSprite *dialBg2;
	
	JewelSetScroll *scrollLayer;
	
	ItemManager *itemManager;
}

@property (nonatomic, assign) int part;
@property (nonatomic, assign) int ueid;
@property (nonatomic, assign) int roleId;
@property (nonatomic, assign) BOOL isRequesting;

+(JewelSet*)create:(NSDictionary*)jInfo;
+(JewelSet*)create:(int)_roleId part:(int)_part;
+(JewelSet*)create;

-(id)requestShiftWithDictionary:(NSDictionary*)_dict;

@end
