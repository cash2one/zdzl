//
//  EFUserAction.h
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EFUserAction : NSObject

+(void)autoLogin;
+(void)login:(NSDictionary*)userInfo;
+(void)logout;

+(void)createGuest;
+(void)registerUser:(NSDictionary*)userInfo;
+(void)modifyUser:(NSDictionary*)userInfo;
+(void)changeNickname:(NSString*)nickname;
+(void)forget:(NSString*)email;
+(BOOL)isSend;
@end
