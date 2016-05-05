//
//  ItemSynthesize.h
//  TXSFGame
//
//  Created by chao chen on 12-12-8.
//  Copyright 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCLayerList.h"
#import "GameDB.h"
#import "CFDialog.h"
#import "ShowItem.h"
#import "GameConnection.h"
#import "WindowComponent.h"

@interface ItemSynthesize : WindowComponent <CCListDelegate,CCDialogDelegate> {
	CCMenu		*menu;
    CCLayerList *cardLayer01;
	CCLayerList *cardLayer02;
	////
	NSInteger needValue;//合一个需要多少原料
	NSInteger needMoney;//合一个需要多少钱
    NSInteger needAllValue;//一共有多少原料
    NSInteger moneyAllValue;//钱数目
    NSInteger desId;//目标Id
	NSInteger needId;//原料Id
	NSInteger fusionValue;//合成数目
	
	CCSprite *remindSelectedDone;
	
	int currentItemTag;
	int currentLevelTag;
	
	NSMutableArray *levelMenus;
	NSMutableArray *menuItems;
}
@property (nonatomic, assign) NSMutableArray *levelMenus;
@property (nonatomic, assign) NSMutableArray *menuItems;
@end
