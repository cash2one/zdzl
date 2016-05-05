//
//  FightPlayer.h
//  TXSFGame
//
//  Created by TigerLeung on 12-12-3.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

#define FIGHT_SPEED_MAX_COUNT 3

@class FightGroup;
@class FightCharacter;

@interface FightPlayer : CCLayer{
	
	NSDictionary * original;
	NSMutableArray * fightAry;
	
	FightGroup * group1;
	FightGroup * group2;
	
	Fight_Action_Log_Type parentAction;
	
	NSString * endString;
	
	NSMutableArray * todoTimers;
	NSMutableArray * overTimers;
	
	float touch_distance;
	float end_touch_distance;
	BOOL isMultiTouch;
	int touchCount;
	
	int speed_index;
	int speed_max_index;
	float speed_settings[FIGHT_SPEED_MAX_COUNT];
	
	BOOL isEndPlay;
    //fix chao
	//FightCharacter * targetCharacter;
	//CCSprite * characterInfo;
    //end
}

+(FightPlayer*)shared;
+(void)stopAll;

+(void)show:(NSString*)str;
+(void)showByDict:(NSDictionary*)info;
+(void)hide;

+(float)checkSpeed:(float)speed;
+(float)checkTime:(float)time;

-(void)startPlayFight;
-(void)actionFight;

-(FightCharacter*)getTargetCharacter:(NSString*)str;
-(void)shake;
-(void)showInfo:(FightCharacter*)target;
//fix chao
//-(void)unboundCharacter:(FightCharacter*)target;
-(BOOL)isEndPlay;
//end
@end

@interface FightTimer : NSObject{
	float time;
	float atime;
	
	id target;
	SEL action;
	BOOL isFire;
}
@property(nonatomic,assign) float time;
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL action;
@property(nonatomic,assign) BOOL isFire;
+(FightTimer*)timer:(float)time target:(id)target action:(SEL)action;

-(void)check:(float)ctime;

@end
