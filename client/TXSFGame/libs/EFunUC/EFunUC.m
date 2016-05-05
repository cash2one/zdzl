//
//  EFunUC.m
//  EFunUC
//
//  Created by TigerLeung on 13-4-24.
//  Copyright (c) 2013年 Turbo-X . All rights reserved.
//

#import "EFunUC.h"
#import "EFUserInfo.h"
#import "EFUserAction.h"
#import "EFPostNotification.h"
#import "EFUIWindow.h"

@implementation EFunUC
@synthesize appId;

static EFunUC * efunUserCenter;

+(EFunUC*)shared{
	if(efunUserCenter==nil){
		efunUserCenter = [[EFunUC alloc] init];
		[EFUserInfo start];
	}
	return efunUserCenter;
}

-(BOOL)isLogin{
	BOOL isLogin = ([EFUserInfo currentUserId]>0);
	return isLogin;
}
-(BOOL)isGuest{
	if([self isLogin]){
		EFUserInfo * userInfo = [EFUserInfo currentUserInfo];
		if(userInfo){
			return [userInfo isGuest];
		}
	}
	return YES;
}

-(int)userId{
	return [EFUserInfo currentUserId];
}
-(NSString*)userName{
	if([self isLogin]){
		EFUserInfo * userInfo = [EFUserInfo currentUserInfo];
		if(userInfo){
			return [userInfo getUserName];
		}
	}
	return @"游客";
}

#pragma mark actions

-(void)setAppId:(int)aid AppKey:(NSString*)key{
	if(appId==0){
		appId = aid;
		appKey = [[NSString alloc] initWithString:key];
	}
}

-(void)autoLogin{
	if([self isLogin]){
		[EFPostNotification postLogin];
		return;
	}
	[EFUserAction autoLogin];
}

-(void)login{
	if([self isLogin]){
		[EFPostNotification postLogin];
		return;
	}
	[EFUIWindow showLogin];
}

-(void)logout{
	[EFUserAction logout];
}

-(void)enterUserCenter{
	if([self isGuest]){
		[EFUIWindow showLogin];
		//[EFUIWindow showUserRegister];
	}else{
		[EFUIWindow showUserCenter];
	}
}


@end

