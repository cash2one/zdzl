//
//  UnlockAlert.h
//  TXSFGame
//
//  Created by shoujun huang on 13-1-3.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameAlert.h"
#import "Config.h"


@interface UnlockAlert : GameAlert<CCTouchOneByOneDelegate> {
	Unlock_object unlockId;
	NSString* info;
	BOOL		_isCanTouch;
}
@property(nonatomic,assign)Unlock_object unlockId;
@property(nonatomic,retain)NSString* info;

+(void)show:(NSDictionary*)_dict target:(id)_target call:(SEL)_call;
+(void)remove;
+(BOOL)isUnlocking;
+(UnlockAlert*)shared;

@end
