//
//  GameTouchPoint.h
//  TXSFGame
//
//  Created by Max on 13-2-21.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameTouchPoint : CCLayer {
	NSArray *pointActAr;
}

+(void)start;
+(void)stopAll;

+(GameTouchPoint *)instance;

@end
