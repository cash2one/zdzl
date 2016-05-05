//
//  EFUserInfo.h
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum{
	EFUserInfo_USER_TYPE_GUEST	= 1,
	EFUserInfo_USER_TYPE_3RD	= 2,
	EFUserInfo_USER_TYPE_USER	= 3,
}EFUserInfo_USER_TYPE;

@interface EFUserInfo : NSObject{
	int userId;
	NSDictionary * userInfo;
}

+(void)start;
+(void)synchronize;

+(NSString*)token;
+(void)saveToken:(NSString*)token;
+(void)saveUser:(NSDictionary*)user;

+(void)chooseUser:(NSDictionary*)user;
+(int)chooseUserId;
+(EFUserInfo*)chooseUserInfo;

+(void)currentUser:(NSDictionary*)user;
+(int)currentUserId;
+(EFUserInfo*)currentUserInfo;
+(void)logoutCurrrentUser;

#pragma mark -

-(id)initWithUserInfo:(NSDictionary*)info;
-(int)userId;
-(NSString*)getUserId;
-(NSString*)getUserName;
-(NSString*)getUserEmail;
//-(NSString*)getUserToken;
-(BOOL)isGuest;

@end
