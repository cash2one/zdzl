//
//  JewelMine.h
//  TXSFGame
//
//  Created by efun on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "WindowComponent.h"

@class ItemManager;

// 珠宝开采
@interface JewelMine : WindowComponent
{
	CCLabelTTF *freeTimesLabel;
	CCLabelTTF *goldTimesLabel;
	
	int totalGoldTimes;
	int startGold;
	int perGold;
	
	int freeTimes;
	int goldTimes;
	int batchTimes;
	
	CGPoint _panelPos;
	CGPoint _itemManagerPos;
	CGPoint _packageAmountPos;
	CGPoint _freeTimesPos;
	CGPoint _goldTimesPos;
	
	BOOL isRequesting;
	BOOL isBatchActive;		// vip5级可以批量开采
	BOOL isBatch;			// 当前是否批量
	
	BOOL isCanExit;			// 是否点击退出
	BOOL isExiting;			// 正在退出
	
	NSArray *updateData;
	NSMutableDictionary *stoneDict;
	
	CCLayer *mainBg;
	
	ItemManager *itemManager;
}

@end
