//
//  TimeBox.h
//  TXSFGame
//
//  Created by Max on 12-12-28.
//  Copyright 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "AnimationViewer.h"
#import "RoleManager.h"
#import "CCSimpleButton.h"
#import "MapManager.h"
#import "TaskPattern.h"
#import "GameMoney.h"
#import "GameEffects.h"
#import "GameMoneyMini.h"

@class RuleButton;

@class PageConsole;

@interface TimeBox : CCLayer {
	
    CCMenu *menu;
	CCMenu *boxmenu;
	int currenChapter;
	int currenMaxChapter;
	int maxChapter;
	int freeResetTime;
	int resetTime;
	int dieCount;
	
	NSMutableArray *point6;
	NSMutableArray *boss_npc;
	NSValue *m;
	int currenNPCid;
	int currenOtherNPCid;
	bool isOpened;
	bool isOpenedGetItem;
	bool isclickMnpc;
	int boxzOrder;
	bool isPlaySendEf;
	bool isBuyResetBack;
	bool isPlayDieEf;
	bool isFightBack;
	bool hasBoss;
	CCSimpleButton *currenBox;
	GameMoneyMini *moneyBox;
	int needmoney;
	NSString *figthSub;
	
	CCMenuItemImage *cityNameLeft;
	CCMenuItemImage *cityNameRight;
	
	RuleButton *ruleButton;
    //
    BOOL isSend;
}

+(TimeBox*)share;
+(void)stopAll;


+(void)visibleTimeBox:(BOOL)_visable;
+(void)enterTimeBox;
+(void)quitTimeBox;
+(void)checkStatus;

@property (nonatomic,assign)bool isOpened;

@end
