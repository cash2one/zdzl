//
//  FishAction.h
//  TXSFGame
//
//  Created by huang shoujun on 13-1-21.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum {
	FishUp_lose		=1,
	FishUp_good		=2,
	FishUp_perfect	=3,
} FishUpType;

@interface FishAction : CCLayer {
    id	target;
	SEL call;
	CCSprite* m_Buoy;
	CCSprite* m_Perfect;
	
	FishUpType fishUpType;
	
	
	NSString* fishActionSetting;
	
	BOOL isDoneAction;
}
@property(nonatomic) int iid;
@property(nonatomic,assign)id  target;
@property(nonatomic,assign)SEL call;

+(id)show:(id)_target call:(SEL)call;
+(void)stopAll;
+(BOOL)checkFishing;

@end
