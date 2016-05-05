//
//  Monster.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-19.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

typedef enum {
	MOMSTER_CHECK_TYPE_X_M = 1,
	MOMSTER_CHECK_TYPE_X_L = 2,
	MOMSTER_CHECK_TYPE_Y_M = 3,
	MOMSTER_CHECK_TYPE_Y_L = 4,
}MOMSTER_CHECK_TYPE;

@class ActionMove;
@class AnimationMonster;

@interface Monster : CCSprite<CCTouchOneByOneDelegate>{
	int monsterId;
	int fightId;
	int index;
	
	MONSTER_TYPE type;
	
	CGPoint point;
	
	AnimationMonster * viewer;
	ActionMove * actionMove;
	
	float runTime;
	
	CCSprite * shadow;
	
	BOOL isFollow;
	BOOL isFirstCheckX;
	MOMSTER_CHECK_TYPE checkTypeX;
	MOMSTER_CHECK_TYPE checkTypeY;
	
}

@property(nonatomic,assign) int monsterId;
@property(nonatomic,assign) int fightId;
@property(nonatomic,assign) int index;
@property(nonatomic,assign) CGPoint point;
@property(nonatomic,assign) MONSTER_TYPE type;

+(Monster*)getMonsterByStageData:(NSArray*)ary;
+(Monster*)getMonster:(int)_mid point:(CGPoint)_pt;


-(void)restart;
-(void)startMonsterAction:(BOOL)isStop;

@end
