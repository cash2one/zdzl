//
//  EfunUserCenter.h
//  EFunUserCenter
//
//  Created by TigerLeung on 13-4-24.
//  Copyright (c) 2013年 Turbo-X . All rights reserved.
//

#import <Foundation/Foundation.h>

#define EFUN_USER_CENTER_VERSION 0x0000001

#define EFUN_LOAD_TOUCH_JSON 1

#define EFUN_USER_CENTER_LOGIN @"EFUN_USER_CENTER_LOGIN"
#define EFUN_USER_CENTER_LOGOUT @"EFUN_USER_CENTER_LOGOUT"
//TODO more...

@interface EfunUserCenter : NSObject{
	
	int appId;
	NSString * appKey;
	
	BOOL isLogin;
	NSDictionary * userInfo;
}

+(EfunUserCenter*)shared;

-(BOOL)isLogin;
-(int)userId;
-(NSString*)userName;

#pragma mark actions

-(void)login;//免注册登陆接口

@end

