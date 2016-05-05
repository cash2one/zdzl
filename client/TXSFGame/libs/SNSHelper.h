//
//  SNSHelper.h
//  TXSFGame
//
//  Created by TigerLeung on 13-2-10.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef	enum SNSHELPER_VERSION {
	VERSION_NO_NEW_VERSION			= 1,
	VERSION_UPDATE_FORCE_CANCELED	= 2,
	VERSION_UPDATE_NORMAL_CANCELED	= 3,
	VERSION_DOWNLOAD_FAIL			= 4,
	VERSION_CHECK_FAIL				= 5,
}SNSHELPER_VERSION;

@class SNSHelper;

@protocol SNSHelperDelegate <NSObject>
-(void)didLogin:(SNSHelper*)helper;
-(void)didLogout:(SNSHelper*)helper;
-(void)didCheckVersion:(SNSHelper*)helper action:(SNSHELPER_VERSION)action;
-(void)pauseExit;
@end

@interface SNSHelper : NSObject{
	id<SNSHelperDelegate> delegate;
	
#if GAME_SNS_TYPE==8
	BOOL isLoginUC;
	NSString * ucid;
	NSString * ucname;
#endif
	
#if GAME_SNS_TYPE==11
	NSString * username;
#endif
	
}

+(SNSHelper*)shared;
+(void)updateOrientation;
+(void)checkOrientation;

+(void)initSNS:(NSDictionary*)launchOptions;
+(void)applicationDidBecomeActive;
+(void)applicationDidRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;
+(void)applicationDidReceiveRemoteNotification:(NSDictionary*)userInfo;
+(void)applicationOpenURL:(NSURL*)url application:(UIApplication*)application;


+(int)getHelperType;
+(BOOL)isMustVerify;

-(void)start:(id<SNSHelperDelegate>)target;
-(void)checkVersion;

-(void)pause;

-(NSString*)getUserId;
-(NSDictionary*)getUserInfo;

-(void)login;
-(void)loginUser;
-(void)guestRegist;
-(BOOL)isLogined;
-(void)logout;

-(void)userFeedback;
-(void)switchAccount;

-(void)enterUserCenter;
-(void)enterAppCenter;

-(void)enterUserInfo:(NSDictionary*)userInfo;

-(void)purchase:(NSDictionary*)info;
-(void)purchase:(NSDictionary*)info target:(id)target call:(SEL)call;
-(void)purchase:(NSDictionary*)info target:(id)target call:(SEL)call other:(NSDictionary*)other;

-(void)purchaseVerify:(BOOL)isPass;

@end


