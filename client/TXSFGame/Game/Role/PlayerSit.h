//
//  PlayerSit.h
//  TXSFGame
//
//  Created by Max on 13-1-31.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface PlayerSitManager : NSObject{
	BOOL isInSitting;
	NSTimer * checkTimer;
	int timerCount;
	int totalExp;
	int endSitTime;
	
}
@property(nonatomic,assign) BOOL isInSitting;
@property(nonatomic,assign) int totalExp;
@property(nonatomic,assign) int endSitTime;


+(PlayerSitManager*)shared;
+(void)stopAll;

-(void)start;
-(void)startSit;
-(void)stopSit;


@end

@interface PlayerSit : CCLayer {
    CCLabelTTF * labelexp;
	CCLabelTTF * labelspeed;
	CCLabelTTF * labeltime;
	//int exp;
}
//@property (assign) int get_have_time;

+(BOOL)isPlayerShowSit;
+(void)show;
+(void)hide;

+(void)update;

/*
+(int)getSitTime;
+(void)setSitTime:(int)i;

+(void)setExp:(int)i;
+(int)getExp;
 
-(void)cancelSit;
+(PlayerSit*)share;
*/



@end
