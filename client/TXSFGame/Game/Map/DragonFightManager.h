//
//  DragonFightManager.h
//  TXSFGame
//
//  Created by efun on 13-9-7.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"

@class GameNPC;
@class DragonMapNameInfo;
@class DragonGloryInfo;
@class DragonCannonInfo;
@class DragonBookInfo;
@class DragonBossHpInfo;
@class DragonShowInfo;

@interface DragonFightManager : CCLayer
{
	CGPoint boxPoint;
	CGPoint wallPoint;
	
	BOOL isBoxFly;
	int selectMonsterId;
	
	DragonMapNameInfo	*_dragonMapNameInfo;
	DragonGloryInfo		*_dragonGloryInfo;
	DragonCannonInfo	*_dragonCannonInfo;
	DragonBookInfo		*_dragonBookInfo;
	DragonBossHpInfo	*_dragonBossHpInfo;
	DragonShowInfo		*_dragonShowInfo;
    NSMutableArray      *_responseArray;
}

+(DragonFightManager*)shared;
+(void)startAll;
+(void)stopAll;

+(void)enterDragonFight;
+(void)removeDragonFight;
+(void)quitDragonFight;

+(void)checkStatus;

-(void)doFireByTurret:(GameNPC*)npc;

//
-(void)addResponse:(id)sender;
@end
