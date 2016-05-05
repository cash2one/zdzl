//
//  GuanXingRoom.h
//  TXSFGame
//
//  Created by chao chen on 12-12-4.
//  Copyright 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCLayerList.h"
#import "Config.h"
#import "WindowComponent.h"

@class GXRCard;

@interface GuanXingRoom : WindowComponent <CCListDelegate> {
	CCMenu *menu;
    CCLayerList *cards;
	BOOL	isOpenHeight;//打开高级
	BOOL	isOpenBat;//打开批量
	//
	BOOL isDisplay;//已播放
	BOOL isFinished;//动画结束
	//
	NSInteger state;//状态
	NSInteger guanXingCount;//观星次数
	//
	CCLabelFX *vipFreeInfo;
	CCLabelFX *vipFreeCountInfo;
	NSInteger yinBiCount;//银币次数
	NSInteger yuanBaoCount;//元宝次数
	NSInteger yuanBaoFreeCount;//元宝免费次数
	//
	int hitFateCoin1Max;
	int hitFateCoin2Max;
	
	//返回的命格数组
	int backFateID;
	int backFateFRID;
	NSArray *backFateArray;
	//
	int waitFetchID;
	//
	BOOL isLayerTouch;
	BOOL isMenuTouch;
    //
    BOOL isBeganTouch;
    //
    BOOL isSend;
}
@property (nonatomic,assign) BOOL isOpenHeight;
@property (nonatomic,assign) BOOL isOpenBat;

+(void)create;

-(void)removeCard:(NSArray*)cardArray;
//-(void)reload;
//-(void)menuCallbackBack: (id) sender;
//-(void)updateMoneyWithYuanBao01:(NSInteger)value01 yuanBao02:(NSInteger)value02 yinBi:(NSInteger)value03;
@end
