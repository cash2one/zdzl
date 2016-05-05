//
//  UnionBossManager.h
//  TXSFGame
//
//  Created by Soul on 13-4-6.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class BossAction;
@class BossInfo;
@class BossRank;

@interface UnionBossManager : CCLayer {
	BossRank* _bossBank;
	BossInfo* _bossInfo;
	BossAction* _bossAction;
}

+(UnionBossManager*)shared;
+(void)startAll;
+(void)stopAll;

+(BOOL)checkAllyBossTouch;
+(void)enterUnionBoss;
+(void)quitUnionBoss;

+(void)checkStatus;

-(void)start;

@end
