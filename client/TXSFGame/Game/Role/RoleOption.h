//
//  RoleOption.h
//  TXSFGame
//
//  Created by Soul on 13-3-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@class RolePlayer;
@class CCSimpleButton;


@interface RoleOption : CCLayer {
    
	RolePlayer*			_role;
	
	BOOL				_battleDelay;
	
}
@property(nonatomic,assign)RolePlayer* role;

+(RoleOption*)shared;
+(void)stopAll;


-(void)binding:(RolePlayer*)_role;

@end
