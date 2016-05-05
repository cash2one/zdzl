//
//  DragonGloryInfo.h
//  TXSFGame
//
//  Created by efun on 13-10-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "GameDefine.h"

@interface DragonGloryInfo : CCSprite
{
	float fontSize;
	
	CGPoint cdPoint;
	CGPoint gloryPoint;
	
	DragonTime _dragonTime;
	
	CCSprite *cdBg;
	CCSprite *cdLabel;
}
@property (nonatomic, assign) DragonTime dragonTime;

+(DragonGloryInfo*)create:(DragonTime)_time;

@end
