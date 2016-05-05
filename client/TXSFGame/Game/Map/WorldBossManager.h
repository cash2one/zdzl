//
//  WorldBossManager.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


@class BossAction;
@class BossInfo;
@class BossRank;
@class BossBuff;

@interface WorldBossManager : CCLayer {
	BossRank* _bossBank;
	BossInfo* _bossInfo;
	BossAction* _bossAction;
	BossBuff* _bossBuff;
}

+(WorldBossManager*)shared;
+(void)startAll;
+(void)stopAll;

+(BOOL)checkWorldBossTouch;
+(void)enterWorldBoss;
+(void)quitWorldBoss;
+(int)getStartTime;

+(void)checkStatus;

-(void)start;

@end
