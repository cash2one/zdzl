//
//  EFPostNotification.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFPostNotification.h"

#import "EFunUC.h"

@implementation EFPostNotification

+(void)postAction:(NSString*)action{
	[[NSNotificationCenter defaultCenter] postNotificationName:action object:nil];
}

+(void)postLogin{
	[self postAction:EFUN_UC_LOGIN];
}
+(void)postLogout{
	[self postAction:EFUN_UC_LOGOUT];
}

@end
