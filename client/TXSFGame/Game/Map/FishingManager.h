//
//  FishingManager.h
//  TXSFGame
//
//  Created by huang shoujun on 13-1-16.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"
#import "FishAction.h"
#import "FishBait.h"
#import "FishGear.h"

@interface FishingManager : CCLayer {
	int times;
	FishUpType fishUpType;
	NSMutableArray *catchs;	// 渔获
	CCMenu * menu;
	
	int fishGearIndex;
	FishGear *fishGear;
	NSMutableArray *fishGearPoints;
	
	CCMenu *boxmenu;
}
@property (nonatomic) BaitType baitQuality;
@property (nonatomic) int fishCount;

+(FishingManager*)shared;
+(void)stopAll;

+(void)checkStatus;
+(void)enterFishing;
+(void)exitFishing;
//finshing
+(BOOL)checkIsFishing;
@end
