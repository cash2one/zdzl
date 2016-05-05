//
//  GameTipsHelper.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-25.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"

#define Post_GameTipsHelper_message	@"Post_GameTipsHelper_message"

@interface GameTipsHelper : NSObject{
	
	__block int totalCanUpArm;
	__block int totalCanUpPos;
	__block int totalCanAddRole;
	__block int totalCbe;
	int			checkCount;
	BOOL		isChecking;
}

+(void)start;
+(void)stopAll;

@end
