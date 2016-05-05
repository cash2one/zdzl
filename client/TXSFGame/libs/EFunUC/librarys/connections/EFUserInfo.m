//
//  EFUserInfo.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFUserInfo.h"
#import "EFDeviceInfo.h"

@implementation EFUserInfo

static int currentUserId;
static NSMutableDictionary * userData;

+(void)start{
	if(userData==nil){
		NSDictionary * path = [EFDeviceInfo getCacheData];
		if(path){
			userData = [[NSMutableDictionary alloc] initWithDictionary:path];
		}else{
			userData = [[NSMutableDictionary alloc] init];
		}
	}
}

+(void)synchronize{
	[EFDeviceInfo saveCacheData:userData];
}

+(NSString*)token{
	NSString * token = [userData objectForKey:@"token"];
	if([token length]>0){
		return token;
	}
	return nil;
}
+(void)saveToken:(NSString*)token{
	if(token){
		[userData setObject:token forKey:@"token"];
	}
}

+(void)saveUser:(NSDictionary*)user{
	
	if([user isKindOfClass:[NSNull class]]) return;
	
	if(user){
		NSMutableDictionary * result = [NSMutableDictionary dictionary];
		NSDictionary * users = [userData objectForKey:@"users"];
		if(users){
			[result addEntriesFromDictionary:users];
		}
		NSString * key = [NSString stringWithFormat:@"%d",[[user objectForKey:@"id"] intValue]];
		[result setObject:user forKey:key];
		[userData setObject:result forKey:@"users"];
	}
}

+(EFUserInfo*)getUserInfoByID:(int)uid{
	if(uid>0){
		NSDictionary * users = [userData objectForKey:@"users"];
		NSString * key = [NSString stringWithFormat:@"%d",uid];
		NSDictionary * info = [users objectForKey:key];
		if(info){
			return [[[EFUserInfo alloc] initWithUserInfo:info] autorelease];
		}
	}
	return nil;
}

+(void)chooseUser:(NSDictionary*)user{
	if([user isKindOfClass:[NSNull class]]) return;
	if(user){
		int tid = [[user objectForKey:@"id"] intValue];
		[userData setObject:[NSNumber numberWithInt:tid] forKey:@"chooseUserId"];
	}
}

+(int)chooseUserId{
	return [[userData objectForKey:@"chooseUserId"] intValue];
}
+(EFUserInfo*)chooseUserInfo{
	return [self getUserInfoByID:[self chooseUserId]];
}

+(void)currentUser:(NSDictionary*)user{
	if([user isKindOfClass:[NSNull class]]) return;
	if(user){
		currentUserId = [[user objectForKey:@"id"] intValue];
	}
}
+(int)currentUserId{
	return currentUserId;
}
+(EFUserInfo*)currentUserInfo{
	return [self getUserInfoByID:currentUserId];
}
+(void)logoutCurrrentUser{
	[self saveToken:@""];
	currentUserId = 0;
	[self synchronize];
}

#pragma mark -
-(id)initWithUserInfo:(NSDictionary*)info{
	if(self=[super init]){
		if(info){
			userId = [[info objectForKey:@"id"] intValue];
			userInfo = [[NSDictionary alloc] initWithDictionary:info];
		}
    }
    return self;
}
-(void)dealloc{
	userId = 0;
	[userInfo release];
	[super dealloc];
}
#pragma mark -

-(int)userId{
	return userId;
}
-(NSString*)getUserId{
	return [NSString stringWithFormat:@"%d",userId];
}
-(NSString*)getUserName{
	NSString * nikeName = [userInfo objectForKey:@"nickName"];
	if([nikeName length]>1){
		return nikeName;
	}
	return [userInfo objectForKey:@"userName"];
}
-(NSString*)getUserEmail{
	return [userInfo objectForKey:@"email"];
}
/*
-(NSString*)getUserToken{
	return [userInfo objectForKey:@"token"];
}
*/

-(BOOL)isGuest{
	int type = [[userInfo objectForKey:@"type"] intValue];
	if(type==EFUserInfo_USER_TYPE_GUEST){
		return YES;
	}
	return NO;
}

@end
