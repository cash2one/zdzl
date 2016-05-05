//
//  GameNotify.h
//  TXSFGame
//
//  Created by Soul on 13-3-22.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"
#import "cocos2d.h"

/*
 * 通知有奖励
 * 通知有阵型升级
 * 通知各种
 */

@interface GameNotify : NSObject{
	NSMutableArray*			_notifys;
}
@property(nonatomic,assign)NSMutableArray*	notifys;

+(GameNotify*)shared;
+(void)stopAll;

-(void)start;

@end
