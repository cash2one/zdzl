//
//  AbyssManager.h
//  TXSFGame
//
//  Created by TigerLeung on 12-12-30.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "AnimationViewer.h"
#import "CCSimpleButton.h"
#import "ClickAnimation.h"

typedef enum {
	Abyss_Door_type_general	= 1,
	Abyss_Door_type_high	= 2,
	Abyss_Door_type_back	= 3,
}Abyss_Door_type;

typedef enum {
	Abyss_Status_normal		= 1,
	Abyss_Status_auto		= 2,
	Abyss_Status_complete	= 3,
}Abyss_Status;

@class AbyssLayer;
@interface AbyssManager : CCLayer{
	
	Abyss_Status status;
	
	int floorIndex;
	int chooseNpcId;
	BOOL isAutoFight;
	int autoTimes;
	
	NSMutableDictionary * info;
	
	CCMenu * menu;
	
	//fix chao
	CGPoint npcPoint;
	//ClickAnimation *buffAnimation;
	//end

	
	NSMutableArray *transportArray;
	NSMutableArray *npcInfoArray;
	
	BOOL isEndFight;	// 宝箱第一次出现有飞下效果
	BOOL isEndOpen;		// 宝箱打开时，添加npc有传送效果
	BOOL isFirstEnter;	// 第一次进入某层
	
	int deepBossStart;	// BOSS开始层数
	int deepAutoFloor;  // 挂机到达层数
}
@property(nonatomic,readonly) NSMutableDictionary * info;

+(AbyssManager*)shared;
+(void)stopAll;

+(void)enterAbyss;
+(void)quitAbyss;
+(void)checkStatus;

@end

