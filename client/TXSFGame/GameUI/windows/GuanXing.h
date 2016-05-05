//
//  GuanXing.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-28.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCLayerList.h"
#import "Config.h"
#import "CFPage.h"
#import "WindowComponent.h"

#pragma mark - GuanXing
@interface GuanXing : WindowComponent <CCListDelegate> {
    CCMenu *menu;
	CCLayerList *cards;//头像
	//NSMutableArray *fateArray;//元神数组
	NSMutableArray *usedFateArray;//元神数组
	NSMutableArray *UnUsedFateArray;//元神数组
	//
	BOOL isTouchGXItem;	
	Card *touchCard;
	Card *tagetCard;////目标卡
	NSInteger cardPlace;////位置
	NSInteger cardRoleID;////角色ID
	NSInteger cardRoleRID;////角色RID
	////
	BOOL isMenuTouch;
	BOOL isLayerTouch;
	BOOL isCardsTouch;
	////
	CGFloat touchStartTime;//开始触碰时间
	UITouch *startTouch;//开始的触点
	BOOL isMoveItem;//移动物品
	BOOL isMovePackage;//移动背包
	BOOL isMoveTouch;//移动手指
	//fix chao
	BOOL isTouch;
    BOOL isSend;
	//end
	
	NSMutableDictionary* fate_level;
	
}

@property(nonatomic,assign) BOOL isTouchGXItem;
@property(nonatomic,assign) BOOL isSend;

+(void)setRoleID:(int)rid;
-(void)changeTouchGXCard:(Card*)card;
-(void)changeTouchGXCard:(Card*)card touch:(UITouch *)touch;
-(void)showMessageWithCard:(Card*)card;
+(GuanXing*)create;
-(Card*)getPartCard:(NSInteger)part;
//-(void)reload;
-(void)menuCallbackBack: (id) sender;
@end
