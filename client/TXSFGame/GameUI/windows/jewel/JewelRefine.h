//
//  JewelRefine.h
//  TXSFGame
//
//  Created by efun on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "WindowComponent.h"

@class ItemManager;
@class ModuleTray;

// 珠宝提炼
@interface JewelRefine : WindowComponent
{
	int successRate;
	int trayCount;
	int maxLevel;
	BOOL isRequesting;
	
	BOOL isCanExit;			// 是否点击退出
	BOOL isExiting;			// 正在退出
	
	CGPoint _panelPos;
	CGPoint _itemManagerPos;
	CGPoint _packageAmountPos;
	
	NSMutableArray *jewelIdArray;
	NSMutableDictionary *upgradeRateDict;
	
	NSDictionary *changeDict;
	NSDictionary *otherDict;
	
	CCLayer *mainBg;
	
	ItemManager *itemManager;
}

-(id)requestShiftWithDictionary:(NSDictionary*)_dict;

@end
