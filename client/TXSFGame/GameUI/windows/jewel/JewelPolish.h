//
//  JewelPolish.h
//  TXSFGame
//
//  Created by efun on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "WindowComponent.h"

@class ItemManager;

// 珠宝打磨
@interface JewelPolish : WindowComponent
{
	int trayCount;
	BOOL isRequesting;
	
	CGPoint _panelPos;
	CGPoint _itemManagerPos;
	CGPoint _packageAmountPos;
	
	NSMutableArray *stoneIdArray;
	
	CCLayer *mainBg;
	
	ItemManager *itemManager;
}

-(id)requestShiftWithDictionary:(NSDictionary*)_dict;

@end
