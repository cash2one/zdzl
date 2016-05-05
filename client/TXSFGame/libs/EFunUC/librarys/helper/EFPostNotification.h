//
//  EFPostNotification.h
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EFUN_UC_LOGIN @"EFUN_USER_CENTER_LOGIN"
#define EFUN_UC_LOGOUT @"EFUN_USER_CENTER_LOGOUT"

@interface EFPostNotification : NSObject

//+(void)postAction:(NSString*)action;

+(void)postLogin;
+(void)postLogout;

@end
