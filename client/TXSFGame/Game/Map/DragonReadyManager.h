//
//  DragonReadyManager.h
//  TXSFGame
//
//  Created by efun on 13-9-7.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"

@class DragonReadyInfo;
@class DragonStartButton;
@class DragonMapNameInfo;
@class DragonGloryInfo;
@class DragonCannonInfo;
@class DragonBookInfo;

@interface DragonReadyManager : CCLayer
{
	DragonReadyInfo			*_dragonReadyInfo;
	DragonStartButton		*_dragonStartButton;
	DragonMapNameInfo		*_dragonMapNameInfo;
	DragonGloryInfo			*_dragonGloryInfo;
	DragonCannonInfo		*_dragonCannonInfo;
	DragonBookInfo			*_dragonBookInfo;
}

+(DragonReadyManager*)shared;
+(void)startAll;
+(void)stopAll;

+(void)enterDragonReady;
+(void)removeDragonReady;
+(void)quitDragonReady;

+(void)checkStatus;

@end
