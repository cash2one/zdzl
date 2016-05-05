//
//  SNSHelper.m
//  TXSFGame
//
//  Created by TigerLeung on 13-2-10.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "SNSHelper.h"
#import "UIDevice+IdentifierAddition.h"
#import "GameConnection.h"

//TODO choose target SNS SDK by DEFINE GAME_SNS_TYPE
#if GAME_SNS_TYPE==1
#import <NdComPlatform/NdComPlatform.h>
#import <NdComPlatform/NdComPlatform+ApplicationPromotion.h>
#import <NdComPlatform/NdComPlatformAPIResponse.h>
#import <NdComPlatform/NdCPNotifications.h>
#endif

#if GAME_SNS_TYPE==2
#import <DJGame/DJGame.h>
@interface SNSHelper (DJGame) <DPayPlatformProtocol>
@end
#endif

#if GAME_SNS_TYPE==4
#import <PPAppPlatformKit/PPAppPlatformKit.h>
#import <PPAppPlatformKit/PPWebView.h>
#endif

#if GAME_SNS_TYPE==5
#import "EFunUC.h"
#import "InAppPurchasesHelper.h"
#endif

#if GAME_SNS_TYPE==6
#import "EfunUserCenter.h"
#import "InAppPurchasesHelper.h"
#endif

#if GAME_SNS_TYPE==7
#import <IDS/IDSHeader.h>
#import "InAppPurchasesHelper.h"
#endif

#if GAME_SNS_TYPE==8
#import <UCGameSdk/UCGameSdk.h>
#import "ASIFormDataRequest.h"
#import "CJSONDeserializer.h"
#endif

#if GAME_SNS_TYPE==9
#import <IDS/IDSHeader.h>
//#import "InAppPurchasesHelper.h"
#endif

#if GAME_SNS_TYPE==10
#import <TBPlatform/TBPlatform.h>
@interface SNSHelper (TBGame) <TBPlatformUpdateProtocol>
@end
#endif

#if GAME_SNS_TYPE==11
#import <DownjoySDK_framework/DJPlatform.h>
#import <DownjoySDK_framework/DJPlatformMemberInfo.h>
#import <DownjoySDK_framework/DJPlatformNotify.h>
#endif

#if GAME_SNS_TYPE==12
#import <PPAppPlatformKit/PPAppPlatformKit.h>
#import <PPAppPlatformKit/PPWebView.h>
#endif

static UIInterfaceOrientation orientation = UIInterfaceOrientationLandscapeLeft;

@implementation SNSHelper

static NSString * getGUID(){
	CFUUIDRef theUUID = CFUUIDCreate(NULL);
	CFStringRef guid = CFUUIDCreateString(NULL, theUUID);
	CFRelease(theUUID);
	NSString * uuidString = [((NSString *)guid) stringByReplacingOccurrencesOfString:@"-" withString:@""];
	CFRelease(guid);
	return [uuidString lowercaseString];
}

static SNSHelper * helper;

+(SNSHelper*)shared{
	if(helper==nil){
		helper = [[SNSHelper alloc] init];
	}
	return helper;
}

+(void)updateOrientation{
	if([[UIDevice currentDevice] orientation]==UIInterfaceOrientationLandscapeLeft){
		orientation = UIInterfaceOrientationLandscapeLeft;
	}
	if([[UIDevice currentDevice] orientation]==UIInterfaceOrientationLandscapeRight){
		orientation = UIInterfaceOrientationLandscapeRight;
	}
}

+(void)checkOrientation{
#if GAME_SNS_TYPE==1
	if((UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)){
		[[NdComPlatform defaultPlatform] NdSetScreenOrientation:orientation];
	}
#endif
	
#if GAME_SNS_TYPE==2
	if((UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)){
		DPayPlatform * dpay = [DPayPlatform defaultPlatform];
		[dpay setViewOrientation:orientation];
	}
#endif
}

+(void)initSNS:(NSDictionary*)launchOptions{
	
	SNSHelper * helper = [SNSHelper shared];
	
	//TODO init SNS SDK by DEFINE GAME_SNS_TYPE
	
#if GAME_SNS_TYPE==1
	
	//[[NdComPlatform defaultPlatform] setAppId:104946];
	//[[NdComPlatform defaultPlatform] setAppKey:@"a1baf815e750e20d8fb9590cbbb5592d0da65b8cbef3f8d9"];
	
	//[[NdComPlatform defaultPlatform] setAppId:105890];
	//[[NdComPlatform defaultPlatform] setAppKey:@"0bebf35469f49bfa350de6db39369da4a56479e6a3f74e4b"];
	//[[NdComPlatform defaultPlatform] NdSetDebugMode:0];
	
	NdInitConfigure * config = [[[NdInitConfigure alloc] init] autorelease];
	config.appid = 104946;
	config.appKey = @"a1baf815e750e20d8fb9590cbbb5592d0da65b8cbef3f8d9";
	
	//[[NdComPlatform defaultPlatform] NdSetDebugMode:0];
	
	[[NdComPlatform defaultPlatform] NdInit:config];
	[[NdComPlatform defaultPlatform] NdShowToolBar:NdToolBarAtMiddleLeft];
	
	if((UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)){
		[[NdComPlatform defaultPlatform] NdSetAutoRotation:YES];
		[[NdComPlatform defaultPlatform] NdSetScreenOrientation:orientation];
	}else{
		[[NdComPlatform defaultPlatform] NdSetScreenOrientation:orientation];
		//[[NdComPlatform defaultPlatform] NdSetAutoRotation:NO];
	}
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:helper selector:@selector(loginResult91:) name:(NSString *)kNdCPLoginNotification object:nil];
	[center addObserver:helper selector:@selector(sessionInvalid91:) name:(NSString *)kNdCPSessionInvalidNotification object:nil];
	[center addObserver:helper selector:@selector(leavePlatform91:) name:(NSString *)kNdCPLeavePlatformNotification object:nil];
	[center addObserver:helper selector:@selector(purchaseResult91:) name:kNdCPBuyResultNotification object:nil];
	[center addObserver:helper selector:@selector(initResult91:) name:kNdCPInitDidFinishNotification object:nil];
	[center addObserver:helper selector:@selector(pauseExit:) name:kNdCPPauseDidExitNotification object:nil];
	
#endif
	
#if GAME_SNS_TYPE==2
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	[center addObserver:helper selector:@selector(loginResult:) name:DPay_kNotificationUserLoginSuccess object:nil];
	[center addObserver:helper selector:@selector(loginOut:) name:DPay_kNotificationUserLoginOut object:nil];
	[center addObserver:helper selector:@selector(loginCancel:) name:DPay_kNotificationUserCancelLogin object:nil];
	//[center addObserver:helper selector:@selector(rechargeDidFinish:) name:DPay_DPay_kNotificationRechargeDidFinish object:nil];
	
	DPayPlatform * dpay = [DPayPlatform defaultPlatform];
	[dpay setAppId:364 andAppKey:@"90d2962ba4c88f10c409ba2b9d270e0f"];
	if((UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)){
		[dpay setViewAutoRotate:YES];
		[dpay setViewOrientation:UIInterfaceOrientationLandscapeLeft];
	}else{
		//[platform NdSetAutoRotation:NO];
		//[platform NdSetScreenOrientation:UIInterfaceOrientationLandscapeLeft];
	}
	
#endif
	
#if GAME_SNS_TYPE==4
	
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	
	//添加监听请求登陆【只成功有效】
	[nc addObserver:helper selector:@selector(loginCallBack:) name:PP_CLIENT_LOGIN_NOTIFICATION object:nil];
	//添加监听关闭客户端页面信息
	[nc addObserver:helper selector:@selector(closePageViewCallBack:) name:PP_CLIENT_CLOSEPAGEVIEW_NOTIFICATION object:nil];
	//添加监听兑换结果返回信息
	[nc addObserver:helper selector:@selector(payResultCallBack:) name:PP_CLIENT_EXCHANGE_NOTIFICATION object:nil];
	//添加监听注销
	[nc addObserver:helper selector:@selector(logOffCallBack) name:PP_CLIENT_LOGOFF_NOTIFICATION object:nil];
	//添加监听关闭Web页面
	[nc addObserver:helper selector:@selector(closeWebViewCallBack:) name:PP_CLIENT_CLOSEWEB_NOTIFICATION object:nil];
	//添加监听补发订单
	[nc addObserver:helper selector:@selector(postBillNoCallBack:) name:PP_CLIENT_POSTBILLNOLIST_NOTIFICATION object:nil];
	
	[[PPAppPlatformKit sharedInstance] setAppId:460 AppKey:@"6416a570eb531690def21829f0d5baec"];
	[[PPAppPlatformKit sharedInstance] setIsNSlogData:NO];
	[[PPAppPlatformKit sharedInstance] setRechargeAmount:@"10"];
	[[PPAppPlatformKit sharedInstance] setIsGetBillNo:NO];
	[[PPAppPlatformKit sharedInstance] setIsLogOutPushLoginView:YES];
	[[PPAppPlatformKit sharedInstance] setIsOpenRecharge:YES];
	
	//[[PPAppPlatformKit sharedInstance] setCloseRechargeAlertMessage:@"关闭充值提示语"];
	
	[PPUIKit sharedInstance];
	
#endif
	
#if GAME_SNS_TYPE==5
	
	[[EFunUC shared] setAppId:1 AppKey:@""];
	
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	//添加监听请求登陆
	[nc addObserver:helper selector:@selector(efunLoginCallBack:) name:EFUN_UC_LOGIN object:nil];
	[nc addObserver:helper selector:@selector(efunLogoutCallBack:) name:EFUN_UC_LOGOUT object:nil];
	
	//[[EfunUserCenter shared] setAppId:1008 AppKey:@"7f2b424e5d9a35db1c20a30723b826e3"];
	
#endif
	
#if GAME_SNS_TYPE==6
	
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	//添加监听请求登陆
	[nc addObserver:helper selector:@selector(efunLoginCallBack:) name:EFUN_USER_CENTER_LOGIN object:nil];
	[nc addObserver:helper selector:@selector(efunLogoutCallBack:) name:EFUN_USER_CENTER_LOGOUT object:nil];
	
	//[[EfunUserCenter shared] setAppId:1018 AppKey:@"d9a35db1c20a30723b826e37f2b424e5"];
	//[[EfunUserCenter shared] autoLogin];
	
#endif
	
#if GAME_SNS_TYPE==7
	
	//是否进入测试站点
	//[idsPP showDebugLog:NO];//TODO
    [idsPP setServerDebug:NO];//TODO
	
	//配置appid appkey umengkey 和 启动参数
	/*
    [[idsPP sharedInstance] setAppID:4023
							  AppKey:@"WwCQ2cl7J53Q6cQj3xTvPQ08rEO58hRL"
							UmengKey:@"51c12a4756240b164b03255c"
					   LaunchOptions:launchOptions];
	*/
	[[idsPP sharedInstance] setAppID:4023
							  AppKey:@"WwCQ2cl7J53Q6cQj3xTvPQ08rEO58hRL"
							UmengKey:@"51c12a4756240b164b03255c"
					  IDSOrientation:IDSInterfaceOrientationLandscape
					   LaunchOptions:launchOptions];
	
	[[idsPP sharedInstance] setIsShowAppIcon:NO];
	[[idsPP sharedInstance] setAppIconPostion:IDSAppIconTopLeft];
	/*
	[[idsPP sharedInstance] setAppIconWithPosition:IDSAppIconTopLeft
									IDSOrientation:IDSInterfaceOrientationLandscape];
	*/
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	//捕获登录消息
    [center addObserver:helper
			   selector:@selector(kIDSLoginNotificationResult:)
				   name:kIDSLoginNotification
				 object:nil];
    
    //捕获登出消息
    [center addObserver:helper
			   selector:@selector(kIDSLogoutNotificationResult:)
				   name:kIDSLogoutNotification
				 object:nil];
	
#endif
	
#if GAME_SNS_TYPE==8
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	
    [center addObserver:helper selector:@selector(onSdkInitFinish:)
				   name:UCG_SDK_MSG_SDK_INIT_FIN
				 object:nil];
	
	[center addObserver:helper selector:@selector(onSdkLoginFinish:)
				   name:UCG_SDK_MSG_LOGIN_FIN
				 object:nil];
	
	[center addObserver:helper selector:@selector(onSdkWithOutLoginFinish:)
				   name:UCG_SDK_MSG_EXIT_WITHOUT_LOGIN
				 object:nil];
	
	[center addObserver:helper selector:@selector(onSdkLogOut:)
				   name:UCG_SDK_MSG_LOGOUT
				 object:nil];
	
	[center addObserver:helper
			   selector:@selector(onPayFin:)
				   name:UCG_SDK_MSG_PAY_FIN
				 object:nil];
	
	/*
	// 添加“用户退出用户中心”以及“用户注销”（如果支持用户账号快速换号的话）的消息的监听
    [center addObserver:helper
			   selector:@selector(userCenterExit:)
				   name:UCG_SDK_MSG_USER_CENTER_EXIT
				 object:nil];
	*/
	
	UCGameSdk *sdk = [UCGameSdk defaultSDK];
	sdk.isDebug = NO;//TODO
	sdk.cpId = 27801;
	sdk.gameId = 516088;
    sdk.serverId = 2057;
	sdk.logLevel = UCLOG_LEVEL_ERR;
    sdk.gameName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    sdk.orientation = UC_LANDSCAPE;
	
	//设置悬浮按钮是否显示,默认不显示
	//sdk.isShowFloatButton = NO;
    //设置悬浮按钮的初始位置，x只能是0或100，0代表左边，100代表右边；y为0~100，0表示最上面，100表示最下面
    //默认是在屏幕右边的中间，如(100,50)
    //sdk.floatButtonPosition = CGPointMake(100, 50);
	
	[sdk initSDK];
	
#endif
	
#if GAME_SNS_TYPE==9
	
	//是否进入测试站点
	//[idsPP showDebugLog:NO];//TODO
    [idsPP setServerDebug:NO];//TODO
	
	//配置appid appkey umengkey 和 启动参数
	/*
    [[idsPP sharedInstance] setAppID:3019
							  AppKey:@"S4O60rrixhMo3Jx5F2IQ028KvIr1u5Vc"
							UmengKey:@"51c12c6256240b1651034fcc"
					   LaunchOptions:launchOptions];
	*/
	[[idsPP sharedInstance] setAppID:3019
							  AppKey:@"S4O60rrixhMo3Jx5F2IQ028KvIr1u5Vc"
							UmengKey:@"51c12c6256240b1651034fcc"
					  IDSOrientation:IDSInterfaceOrientationLandscape
					   LaunchOptions:launchOptions];
	
	[[idsPP sharedInstance] setIsShowAppIcon:NO];
	[[idsPP sharedInstance] setAppIconPostion:IDSAppIconTopLeft];
    /*
	[[idsPP sharedInstance] setAppIconWithPosition:IDSAppIconTopLeft
									IDSOrientation:IDSInterfaceOrientationLandscape];
	*/
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	//捕获登录消息
    [center addObserver:helper
			   selector:@selector(kIDSLoginNotificationResult:)
				   name:kIDSLoginNotification
				 object:nil];
    
    //捕获登出消息
    [center addObserver:helper
			   selector:@selector(kIDSLogoutNotificationResult:)
				   name:kIDSLogoutNotification
				 object:nil];
	 
	//捕获购买结果消息
	[center addObserver:helper
			   selector:@selector(kIDSPayResultNotificationResult:)
				   name:kIDSPayResultNotification
				 object:nil];
	
#endif
	
#if GAME_SNS_TYPE==10
	
	[[NSNotificationCenter defaultCenter] addObserver:helper
                                             selector:@selector(loginResultTB:)
                                                 name:(NSString *)kTBLoginNotification
                                               object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:helper
                                             selector:@selector(leavePlatformTB:)
                                                 name:(NSString *)kTBLeavePlatformNotification
                                               object:nil];
	
	[[TBPlatform defaultPlatform] setAppId:130709];
	[[TBPlatform defaultPlatform] TBSetAutoRotation:YES];
	[[TBPlatform defaultPlatform] TBSetScreenOrientation:UIInterfaceOrientationLandscapeLeft];
	//[[TBPlatform defaultPlatform] TBSetDebugMode:0];//TODO
	
#endif
	
#if GAME_SNS_TYPE==11
	
	NSNotificationCenter * center = [NSNotificationCenter defaultCenter];
	
	[center addObserver:helper selector:@selector(dealDJPlatformLoginResultNotify:)				name:kDJPlatformLoginResultNotification object:nil];
	[center addObserver:helper selector:@selector(dealDJPlatformReadMemberInfoResultNotify:)	name:kDJPlatformReadMemberInfoResultNotification object:nil];
	[center addObserver:helper selector:@selector(dealDJPlatformLogoutResultNotify:)			name:kDJPlatformLogotResultNotification object:nil];
	[center addObserver:helper selector:@selector(dealDJPlatformPaymentResultNotify:)			name:kDJPlatformPaymentResultNotification object:nil];
	[center addObserver:helper selector:@selector(dealDJPlatformPaymentGiveupNotify:)			name:kdjPlatformPaymentGiveupNotification object:nil];
	
	[[DJPlatform defaultDJPlatform] setAppId:@"549"];
	[[DJPlatform defaultDJPlatform] setAppKey:@"Hq6F73J8"];
	[[DJPlatform defaultDJPlatform] setMerchantId:@"344"];
	[[DJPlatform defaultDJPlatform] setServerId:@"1"];
	[[DJPlatform defaultDJPlatform] setTapBackgroundHideView:NO];
	
#endif
	
	
#if GAME_SNS_TYPE==12
	
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	
	//添加监听请求登陆【只成功有效】
	[nc addObserver:helper selector:@selector(loginCallBack:) name:PP_CLIENT_LOGIN_NOTIFICATION object:nil];
	//添加监听关闭客户端页面信息
	[nc addObserver:helper selector:@selector(closePageViewCallBack:) name:PP_CLIENT_CLOSEPAGEVIEW_NOTIFICATION object:nil];
	//添加监听兑换结果返回信息
	[nc addObserver:helper selector:@selector(payResultCallBack:) name:PP_CLIENT_EXCHANGE_NOTIFICATION object:nil];
	//添加监听注销
	[nc addObserver:helper selector:@selector(logOffCallBack) name:PP_CLIENT_LOGOFF_NOTIFICATION object:nil];
	//添加监听关闭Web页面
	[nc addObserver:helper selector:@selector(closeWebViewCallBack:) name:PP_CLIENT_CLOSEWEB_NOTIFICATION object:nil];
	//添加监听补发订单
	[nc addObserver:helper selector:@selector(postBillNoCallBack:) name:PP_CLIENT_POSTBILLNOLIST_NOTIFICATION object:nil];
	
	[[PPAppPlatformKit sharedInstance] setAppId:1055 AppKey:@"67f1172f89109e1ef040f3b13478a3c7"];
	[[PPAppPlatformKit sharedInstance] setIsNSlogData:NO];
	[[PPAppPlatformKit sharedInstance] setRechargeAmount:@"10"];
	[[PPAppPlatformKit sharedInstance] setIsGetBillNo:NO];
	[[PPAppPlatformKit sharedInstance] setIsLogOutPushLoginView:YES];
	[[PPAppPlatformKit sharedInstance] setIsOpenRecharge:YES];
	
	//[[PPAppPlatformKit sharedInstance] setCloseRechargeAlertMessage:@"关闭充值提示语"];
	
	[PPUIKit sharedInstance];
	
#endif
	
	
}

+(void)applicationDidBecomeActive{
#if GAME_SNS_TYPE==7
	/*
    [[idsPP sharedInstance] setAppID:4023
							  AppKey:@"WwCQ2cl7J53Q6cQj3xTvPQ08rEO58hRL"
							UmengKey:@"51c12a4756240b164b03255c"
					   LaunchOptions:nil];
	*/
	[[idsPP sharedInstance] setAppID:4023
							  AppKey:@"WwCQ2cl7J53Q6cQj3xTvPQ08rEO58hRL"
							UmengKey:@"51c12a4756240b164b03255c"
					  IDSOrientation:IDSInterfaceOrientationLandscape
					   LaunchOptions:nil];
#endif
#if GAME_SNS_TYPE==9
	/*
	[[idsPP sharedInstance] setAppID:3019
							  AppKey:@"S4O60rrixhMo3Jx5F2IQ028KvIr1u5Vc"
							UmengKey:@"51c12c6256240b1651034fcc"
					   LaunchOptions:nil];
	*/
	[[idsPP sharedInstance] setAppID:3019
							  AppKey:@"S4O60rrixhMo3Jx5F2IQ028KvIr1u5Vc"
							UmengKey:@"51c12c6256240b1651034fcc"
					  IDSOrientation:IDSInterfaceOrientationLandscape
					   LaunchOptions:nil];
#endif
}
+(void)applicationDidRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken{
#if GAME_SNS_TYPE==7
	[[idsPP sharedInstance]setDeviceToken:deviceToken];
#endif
#if GAME_SNS_TYPE==9
	[[idsPP sharedInstance]setDeviceToken:deviceToken];
#endif
}
+(void)applicationDidReceiveRemoteNotification:(NSDictionary*)userInfo{
#if GAME_SNS_TYPE==7
	[[idsPP sharedInstance] setReceiveRemoteNotificationProcessWithUserInfo:userInfo];
#endif
#if GAME_SNS_TYPE==9
	[[idsPP sharedInstance] setReceiveRemoteNotificationProcessWithUserInfo:userInfo];
#endif
}
+(void)applicationOpenURL:(NSURL*)url application:(UIApplication*)application{
#if GAME_SNS_TYPE==7
	[[idsPP sharedInstance] parseURL:url application:application];
#endif
#if GAME_SNS_TYPE==9
	[[idsPP sharedInstance] parseURL:url application:application];
#endif
}


+(int)getHelperType{
	return GAME_SNS_TYPE;
}

+(BOOL)isMustVerify{
	if(GAME_SNS_TYPE==5 ||
	   GAME_SNS_TYPE==6 ||
	   GAME_SNS_TYPE==7 ||
	   GAME_SNS_TYPE==9 ){
		return YES;
	}
	return NO;
}

#pragma mark -

-(id)init{
	if((self=[super init])!=nil){
		
#if GAME_SNS_TYPE==11
		NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
		if([defaults stringForKey:@"DJ_user_name"]){
			username = [[NSString alloc] initWithString:[defaults stringForKey:@"DJ_user_name"]];
		}
#endif
		
	}
	return self;
}

-(void)start:(id<SNSHelperDelegate>)target{
	delegate = target;
	//[self checkVersion];
}

-(void)checkVersion{
#if GAME_SNS_TYPE==1
	//[[NdComPlatform defaultPlatform] NdAppVersionUpdate:0 delegate:self];
	//[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
#endif
	
#if GAME_SNS_TYPE==2
	[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
#endif
	
#if GAME_SNS_TYPE==3
	[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
#endif
	
#if GAME_SNS_TYPE==4
	[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
#endif
	
#if GAME_SNS_TYPE==5
	[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
#endif
	
#if GAME_SNS_TYPE==6
	[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
#endif
	
#if GAME_SNS_TYPE==7
	[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
#endif
	
#if GAME_SNS_TYPE==8
	//[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
#endif
	
#if GAME_SNS_TYPE==9
	[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
#endif
	
#if GAME_SNS_TYPE==10
	//[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
	[[TBPlatform defaultPlatform] TBAppVersionUpdate:0 delegate:self];
#endif
	
#if GAME_SNS_TYPE==11
	[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
#endif
	
#if GAME_SNS_TYPE==12
	[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
#endif
	
}

-(void)pause{
#if GAME_SNS_TYPE==1
	[[NdComPlatform defaultPlatform] NdPause];
#endif
}

-(NSString*)getUserId{
	if([self isLogined]){
#if GAME_SNS_TYPE==1
		return [[NdComPlatform defaultPlatform] loginUin];
#endif
		
#if GAME_SNS_TYPE==2
		return [NSString stringWithFormat:@"%d",[[DPayPlatform defaultPlatform] getUserId]];
#endif
		
#if GAME_SNS_TYPE==4
		return [NSString stringWithFormat:@"%qu",[[PPAppPlatformKit sharedInstance] currentUserId]];
#endif
		
#if GAME_SNS_TYPE==5
		return [NSString stringWithFormat:@"%d",[[EFunUC shared] userId]];
#endif
		
#if GAME_SNS_TYPE==6
		return [NSString stringWithFormat:@"%d",[[EfunUserCenter shared] userId]];
#endif
		
#if GAME_SNS_TYPE==7
		return [NSString stringWithFormat:@"%@",IDSUser.userid];
#endif
		
#if GAME_SNS_TYPE==8
		return (ucid != nil) ? ucid : @"";
#endif
		
#if GAME_SNS_TYPE==9
		return [NSString stringWithFormat:@"%@",IDSUser.userid];
#endif
		
#if GAME_SNS_TYPE==10
		TBPlatformUserInfo * info = [[TBPlatform defaultPlatform] TBGetMyInfo];
		return [NSString stringWithFormat:@"%@",info.userID];
#endif
		
#if GAME_SNS_TYPE==11
		NSNumber * userId = [[DJPlatform defaultDJPlatform] getCurrentMemberId];
		return [NSString stringWithFormat:@"%d",[userId intValue]];
#endif
		
#if GAME_SNS_TYPE==12
		return [NSString stringWithFormat:@"%qu",[[PPAppPlatformKit sharedInstance] currentUserId]];
#endif
		
	}
	return @"";
}

-(NSDictionary*)getUserInfo{
	
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	[result setObject:[NSNumber numberWithBool:NO] forKey:@"isLogined"];
	[result setObject:[NSNumber numberWithBool:YES] forKey:@"isGuest"];
	[result setObject:[NSNumber numberWithInt:0] forKey:@"SNSID"];
	
	//[result setObject:@"游客" forKey:@"username"];
    [result setObject:NSLocalizedString(@"sns_helper_visitor",nil) forKey:@"username"];
	[result setObject:@"" forKey:@"sid"];
	[result setObject:@"" forKey:@"session"];
	
	if([self isLogined]){
		
		[result setObject:[NSNumber numberWithBool:YES] forKey:@"isLogined"];
		[result setObject:[NSNumber numberWithInt:GAME_SNS_TYPE] forKey:@"SNSID"];
		
#if GAME_SNS_TYPE==1
		ND_LOGIN_STATE state = [[NdComPlatform defaultPlatform] getCurrentLoginState];
		
		if(state==ND_LOGIN_STATE_NORMAL_LOGIN){
			[result setObject:[[NdComPlatform defaultPlatform] nickName] forKey:@"username"];
			[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		}
		
		[result setObject:[[NdComPlatform defaultPlatform] loginUin] forKey:@"sid"];
		[result setObject:[[NdComPlatform defaultPlatform] sessionId] forKey:@"session"];
#endif
		
#if GAME_SNS_TYPE==2
		[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		[result setObject:[self getUserId] forKey:@"sid"];
		[result setObject:[[DPayPlatform defaultPlatform] getSessionId] forKey:@"session"];
		[result setObject:[[DPayPlatform defaultPlatform] getUserName] forKey:@"username"];
#endif
		
#if GAME_SNS_TYPE==3
		
		//[result setObject:[] forKey:@"username"];
		
		NSString * udid = [[[UIDevice currentDevice] uniqueDeviceIdentifier] stringByAppendingString:@""];
		[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		[result setObject:udid forKey:@"sid"];
		[result setObject:udid forKey:@"session"];
		
#endif
		
#if GAME_SNS_TYPE==4
		NSString * session = [NSString stringWithFormat:@"%qu",
							  [[PPAppPlatformKit sharedInstance] currentSessionId]];
		
		[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		[result setObject:[self getUserId] forKey:@"sid"];
		[result setObject:[[PPAppPlatformKit sharedInstance] currentUserName] forKey:@"username"];
		[result setObject:session forKey:@"session"];
#endif
		
#if GAME_SNS_TYPE==5
		
		NSString * session = [[[UIDevice currentDevice] uniqueDeviceIdentifier] stringByAppendingString:@""];
		
		[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		[result setObject:[self getUserId] forKey:@"sid"];
		[result setObject:[[EFunUC shared] userName] forKey:@"username"];
		[result setObject:session forKey:@"session"];
		
#endif
		
#if GAME_SNS_TYPE==6
		
		NSString * session = [[[UIDevice currentDevice] uniqueDeviceIdentifier] stringByAppendingString:@""];
		
		[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		[result setObject:[self getUserId] forKey:@"sid"];
		[result setObject:[[EfunUserCenter shared] userName] forKey:@"username"];
		[result setObject:session forKey:@"session"];
#endif
		
#if GAME_SNS_TYPE==7
		[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		[result setObject:[self getUserId] forKey:@"sid"];
		[result setObject:IDSUser.nickname forKey:@"username"];
		[result setObject:IDSUser.usertoken forKey:@"session"];
#endif
		
		
#if GAME_SNS_TYPE==8
		//TODO
		[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		[result setObject:[UCGameSdk defaultSDK].sid forKey:@"session"];
		[result setObject:ucid forKey:@"sid"];
		[result setObject:ucname forKey:@"username"];
#endif
		
#if GAME_SNS_TYPE==9
		[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		[result setObject:[self getUserId] forKey:@"sid"];
		[result setObject:IDSUser.nickname forKey:@"username"];
		[result setObject:IDSUser.usertoken forKey:@"session"];
#endif
		
#if GAME_SNS_TYPE==10
		
		TBPlatformUserInfo * info = [[TBPlatform defaultPlatform] TBGetMyInfo];
		
		[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		[result setObject:[self getUserId] forKey:@"sid"];
		[result setObject:info.nickName forKey:@"username"];
		[result setObject:info.sessionID forKey:@"session"];
		
#endif
		
#if GAME_SNS_TYPE==11
		DJPlatform * dj = [DJPlatform defaultDJPlatform];
		[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		[result setObject:[self getUserId] forKey:@"sid"];
		[result setObject:username forKey:@"username"];
		[result setObject:[dj getCurrentToken] forKey:@"session"];
#endif
		
#if GAME_SNS_TYPE==12
		NSString * session = [NSString stringWithFormat:@"%qu",
							  [[PPAppPlatformKit sharedInstance] currentSessionId]];
		
		[result setObject:[NSNumber numberWithBool:NO] forKey:@"isGuest"];
		[result setObject:[self getUserId] forKey:@"sid"];
		[result setObject:[[PPAppPlatformKit sharedInstance] currentUserName] forKey:@"username"];
		[result setObject:session forKey:@"session"];
#endif
		
	}
	
	return result;
}

-(BOOL)isLogined{
	
#if GAME_SNS_TYPE==1
	return [[NdComPlatform defaultPlatform] isLogined];
#endif
	
#if GAME_SNS_TYPE==2
	return [[DPayPlatform defaultPlatform] isUserLoggedIn];
#endif
	
#if GAME_SNS_TYPE==3
	return YES;
#endif
	
#if GAME_SNS_TYPE==4
	if([[PPAppPlatformKit sharedInstance] currentUserId]==0){
		return NO;
	}else{
		return YES;
	}
#endif
	
#if GAME_SNS_TYPE==5
	return [[EFunUC shared] isLogin];
#endif
	
#if GAME_SNS_TYPE==6
	return [[EfunUserCenter shared] isLogin];
#endif
	
#if GAME_SNS_TYPE==7
	if([[idsPP sharedInstance] isLogined]){
		if(IDSUser.userid){
			return YES;
		}
	}
#endif
	
#if GAME_SNS_TYPE==8
	return isLoginUC;
#endif
	
#if GAME_SNS_TYPE==9
	if([[idsPP sharedInstance] isLogined]){
		if(IDSUser.userid){
			return YES;
		}
	}
#endif
	
#if GAME_SNS_TYPE==10
	return [[TBPlatform defaultPlatform] isLogined];
#endif
	
#if GAME_SNS_TYPE==11
	if([[DJPlatform defaultDJPlatform] DJIsLogin] && username){
		return YES;
	}
#endif
	
#if GAME_SNS_TYPE==12
	if([[PPAppPlatformKit sharedInstance] currentUserId]==0){
		return NO;
	}else{
		return YES;
	}
#endif
	
	return NO;
}

-(void)login{
	
	[SNSHelper checkOrientation];
	
#if GAME_SNS_TYPE==1
	[[NdComPlatform defaultPlatform] NdLoginEx:0];
#endif
	
#if GAME_SNS_TYPE==2
	[[DPayPlatform defaultPlatform] quickLogin:self];
#endif
	
#if GAME_SNS_TYPE==4
	[[PPLoginView sharedInstance] showLoginViewByRight];
#endif
	
#if GAME_SNS_TYPE==5
	[[EFunUC shared] autoLogin];
#endif
	
#if GAME_SNS_TYPE==6
	[[EfunUserCenter shared] login];
#endif
	
#if GAME_SNS_TYPE==7
	//[[idsPP sharedInstance] showbootLogin];
#endif
		
#if GAME_SNS_TYPE==8
	[[UCGameSdk defaultSDK] login];
#endif
	
#if GAME_SNS_TYPE==9
	//[[idsPP sharedInstance] showbootLogin];
#endif
	
#if GAME_SNS_TYPE==10
	[[TBPlatform defaultPlatform] TBLogin:0];
#endif
	
#if GAME_SNS_TYPE==11
	[[DJPlatform defaultDJPlatform] DJLogin];
#endif
	
#if GAME_SNS_TYPE==12
	[[PPLoginView sharedInstance] showLoginViewByRight];
#endif
	
}

-(void)loginUser{
	
	[SNSHelper checkOrientation];
	
#if GAME_SNS_TYPE==1
	if([self isLogined]){
		[[NdComPlatform defaultPlatform] NdLogout:1];
	}
	[[NdComPlatform defaultPlatform] NdLogin:0];
#endif
	
#if GAME_SNS_TYPE==2
	if(![[DPayPlatform defaultPlatform] isUserLoggedIn]){
		[[DPayPlatform defaultPlatform] login:YES];
	}
#endif
	
#if GAME_SNS_TYPE==4
	[[PPLoginView sharedInstance] showLoginViewByRight];
#endif
	
#if GAME_SNS_TYPE==5
	[[EFunUC shared] login];
#endif
	
#if GAME_SNS_TYPE==6
	[[EfunUserCenter shared] login];
#endif
	
#if GAME_SNS_TYPE==7
	[[idsPP sharedInstance] showbootLogin];
#endif
	
#if GAME_SNS_TYPE==8
	[[UCGameSdk defaultSDK] login];
#endif
	
#if GAME_SNS_TYPE==9
	[[idsPP sharedInstance] showbootLogin];
#endif
	
#if GAME_SNS_TYPE==10
	[[TBPlatform defaultPlatform] TBLogin:0];
#endif
	
#if GAME_SNS_TYPE==11
	[[DJPlatform defaultDJPlatform] DJLogin];
#endif
	
#if GAME_SNS_TYPE==12
	[[PPLoginView sharedInstance] showLoginViewByRight];
#endif
	
}

// 暂时只有云顶有注销功能
-(void)logout
{
#if (GAME_SNS_TYPE==7 || GAME_SNS_TYPE==9)
	[[idsPP sharedInstance] logout];
	//[GameConnection post:@"ConnPost_logout" object:nil];
#endif
}

-(void)guestRegist{
	
#if GAME_SNS_TYPE==1
	[[NdComPlatform defaultPlatform] NdGuestRegist:0];
#endif
	
}

-(void)userFeedback{
#if GAME_SNS_TYPE==1
	[[NdComPlatform defaultPlatform] NdUserFeedBack];
#endif
}

-(void)switchAccount{
	
	[SNSHelper checkOrientation];
	
#if GAME_SNS_TYPE==1
	[[NdComPlatform defaultPlatform] NdSwitchAccount];
#endif
	
#if GAME_SNS_TYPE==2
	[[DPayPlatform defaultPlatform] enterUserCenter];
#endif
	
#if GAME_SNS_TYPE==4
	[[PPCenterView sharedInstance] showCenterViewByRight];
#endif
	
#if GAME_SNS_TYPE==12
	[[PPCenterView sharedInstance] showCenterViewByRight];
#endif
	
}
-(void)enterUserCenter{
	
	[SNSHelper checkOrientation];
	
#if GAME_SNS_TYPE==1
	[[NdComPlatform defaultPlatform] NdEnterPlatform:0];
#endif
	
#if GAME_SNS_TYPE==2
	[[DPayPlatform defaultPlatform] enterUserCenter];
#endif
	
#if GAME_SNS_TYPE==4
	[[PPCenterView sharedInstance] showCenterViewByRight];
#endif
	
#if GAME_SNS_TYPE==5
	[[EFunUC shared] enterUserCenter];
#endif
	
#if GAME_SNS_TYPE==7
	[[idsPP sharedInstance] showMenuWithOrientation:IDSInterfaceOrientationLandscape];
#endif
	
#if GAME_SNS_TYPE==8
	// 设置是否隐藏“充值记录”入口，上App Store的应用因为不会接充值所以请隐藏，默认 不隐藏
	[UCGameSdk defaultSDK].isHidePayHistoryEntrance = NO;
    // 是否允许用户快速换号(即在SDK的个人中心中直接注销当前用户，重新显示登录界面)，如果允许，请监听用户注销消息
    [UCGameSdk defaultSDK].allowChangeAccount = NO;
    // 进入个人中心
    [[UCGameSdk defaultSDK] enterUserCenter];
#endif
	
#if GAME_SNS_TYPE==9
	[[idsPP sharedInstance] showMenuWithOrientation:IDSInterfaceOrientationLandscape];
#endif
	
#if GAME_SNS_TYPE==10
	[[TBPlatform defaultPlatform] TBEnterUserCenter:0];
#endif
	
#if GAME_SNS_TYPE==11
	[[DJPlatform defaultDJPlatform] DJMemberCenter];
#endif
	
#if GAME_SNS_TYPE==12
	[[PPCenterView sharedInstance] showCenterViewByRight];
#endif
	
}
-(void)enterAppCenter{
	
	[SNSHelper checkOrientation];
	
#if GAME_SNS_TYPE==1
	[[NdComPlatform defaultPlatform] NdEnterAppCenter:0];
#endif
	
#if GAME_SNS_TYPE==2
	[[DPayPlatform defaultPlatform] enterUserCenter];
#endif
	
#if GAME_SNS_TYPE==4
	[[PPCenterView sharedInstance] showCenterViewByRight];
#endif
	
#if GAME_SNS_TYPE==10
	[[TBPlatform defaultPlatform] TBEnterAppCenter:0];
#endif
	
#if GAME_SNS_TYPE==12
	[[PPCenterView sharedInstance] showCenterViewByRight];
#endif
	
}

#pragma mark ---------------91 SDK CALLBACK ---------------
#if GAME_SNS_TYPE==1
-(void)loginResult91:(NSNotification*)notify{
	
	NSDictionary * result = [notify userInfo];
	BOOL success = [[result objectForKey:@"result"] boolValue];
	
	if([[NdComPlatform defaultPlatform] isLogined] && success){
		
		//登录成功
		NdGuestAccountStatus * guest = (NdGuestAccountStatus*)[result objectForKey:@"NdGuestAccountStatus"];
		if(guest){
			if([guest isGuestLogined]){
				//游客登录
				
			}else if([guest isGuestRegistered]){
				//游客转正
				
			}
		}else{
			// 普通账号登录成功!
			
		}
	}else{
		//登录失败
		
	}
	
	[delegate didLogin:self];
	
}
-(void)sessionInvalid91:(NSNotification*)notify{
	//TODO
	[delegate didLogout:self];
}
-(void)leavePlatform91:(NSNotification*)notify{
	//[delegate didLogout:self];
	
}
-(void)purchaseResult91:(NSNotification*)notify{
	
	NSDictionary * dic = [notify userInfo];
	
	if([[dic objectForKey:@"result"] boolValue]){
		
		//NSLog(@"购买成功");
		/*
		 NSString * str = @"";
		 NdBuyInfo* buyInfo = (NdBuyInfo*)[dic objectForKey:@"buyInfo"];
		 str = [str stringByAppendingFormat:
		 @"\n\n<productId = %@, productCount = %d, cooOrderSerial = %@>\n\n",
		 buyInfo.productId,
		 buyInfo.productCount,
		 buyInfo.cooOrderSerial];
		 
		 //NSLog(str);
		 */
		
	}else{
		
		int errorCode = [[dic objectForKey:@"error"] intValue];
		
		switch (errorCode){
			case ND_COM_PLATFORM_ERROR_USER_CANCEL:
				//NSLog(@"用户取消");
				break;
			case ND_COM_PLATFORM_ERROR_NETWORK_FAIL:
				//NSLog(@"网络问题");
				break;
			case ND_COM_PLATFORM_ERROR_SERVER_RETURN_ERROR:
				//NSLog(@"服务端处理失败");
				break;
			case ND_COM_PLATFORM_ERROR_VG_MONEY_TYPE_FAILED:
				//NSLog(@"查询商品失败");
				break;
			case ND_COM_PLATFORM_ERROR_ORDER_SERIAL_SUBMITTED:
				//NSLog(@"支付提交");
				break;
			case ND_COM_PLATFORM_ERROR_PARAM:
				//NSLog(@"购买91豆不合法");
			case ND_COM_PLATFORM_ERROR_VG_ORDER_FAILED:
				//NSLog(@"订单失败");
				break;
			case ND_COM_PLATFORM_ERROR_VG_BACK_FROM_RECHARGE:
				//NSLog(@"进入虚拟币充值介面");
				break;
			case ND_COM_PLATFORM_ERROR_PAY_FAILED:
				//NSLog(@"购买虚拟品失败");
				break;
			default:
				//NSLog(@"购买过程错误");
				break;
		}
	}
	
	/*
	 NdVGErrorInfo* vgErrInfo = (NdVGErrorInfo*)[dic objectForKey:@"vgErrorInfo"];
	 if (vgErrInfo) {
	 NSString * str = [str stringByAppendingFormat:@"\n\n%@", vgErrInfo.strErrDesc];
	 NSLog(@"NdBuyCommodityResult: %@", str);
	 }
	 */
	
}

-(void)initResult91:(NSNotification*)notify{
	[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
}

-(void)pauseExit:(NSNotification*)notify{
	[delegate pauseExit];
}

/*
 -(void)appVersionUpdateDidFinish:(ND_APP_UPDATE_RESULT)updateResult{
 
 SNSHELPER_VERSION action = VERSION_NO_NEW_VERSION;
 switch (updateResult) {
 case ND_APP_UPDATE_NO_NEW_VERSION:
 action = VERSION_NO_NEW_VERSION;
 break;
 case ND_APP_UPDATE_FORCE_UPDATE_CANCEL_BY_USER:
 action = VERSION_UPDATE_FORCE_CANCELED;
 break;
 case ND_APP_UPDATE_NORMAL_UPDATE_CANCEL_BY_USER:
 action = VERSION_UPDATE_NORMAL_CANCELED;
 break;
 case ND_APP_UPDATE_NEW_VERSION_DOWNLOAD_FAIL:
 action = VERSION_DOWNLOAD_FAIL;
 break;
 case ND_APP_UPDATE_CHECK_NEW_VERSION_FAIL:
 action = VERSION_CHECK_FAIL;
 break;
 default:
 break;
 }
 
 [delegate didCheckVersion:self action:action];
 
 }
 */

#endif

#pragma mark ---------------DPay SDK CALLBACK ---------------
#if GAME_SNS_TYPE==2

-(void)directLoginDidFinish:(int)errorCode{
	if(errorCode!=0){
		[[DPayPlatform defaultPlatform] login:YES];
	}else{
		[delegate didLogin:self];
	}
}
-(void)loginResult:(NSNotification*)notify{
	[delegate didLogin:self];
}
-(void)loginOut:(NSNotification*)notify{
	[delegate didLogin:self];
}
-(void)loginCancel:(NSNotification*)notify{
	[delegate didLogin:self];
}

-(void)rechargeDidFinish:(NSNotification*)notify{
	
}

#endif


#pragma mark ---------------PP SDK CALLBACK ---------------
#if GAME_SNS_TYPE==4
//登陆成功回调方法
-(void)loginCallBack:(NSNotification *)noti{
	/*
	 MSG_PS_VERIFI2_RESPONSE mpvr = [UnPackage bytePSVerifi2Response:noti.object];
	 MSG_GAME_SERVER mgs = {};
	 mgs.len = 24;
	 mgs.commmand = 0xAA000021;
	 memcpy(mgs.token_key, mpvr.token_key, 16);
	 NSString *requestURLStr = @"http://58.218.147.147:8850/login.php";
	 NSURL *requestUrl = [[NSURL alloc] initWithString:[requestURLStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	 NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
	 
	 NSData *token_keyData = [NSData dataWithBytes:mpvr.token_key length:16];
	 [request setHTTPMethod:@"POST"];
	 [request setTimeoutInterval:10];
	 [request setHTTPBody:token_keyData];
	 [self sendRequest:request];
	 [requestUrl release];
	 
	 [bgGanmeCenterImageView setHidden:NO];
	 [bgloginImageView setHidden:YES];
	 */
	[delegate didLogin:self];
}
//注销回调方法
-(void)logOffCallBack{
	[delegate didLogin:self];
}

/**
 *在充值并且兑换业务服务器不能接受回调。需要客户端发起兑换的厂商需要再此回调获取订单号。将代码设置为[[PPAppPlatformKit sharedInstance] setIsGetBillNo:YES];
 *并且在收到通知做为处理后。请调用-(void)deleteBillNo:(NSString *)paramBillNo将当前订单从队列移除;否则订单一直会在队列象游戏客户端发送通知。
 */
-(void)postBillNoCallBack:(NSNotification *)noti{
	/*
	 //    此时noti.objct为你的订单号
	 //    如果获得处理后。则需要返回给我
	 NSLog(@"获取补发订单回调-%@",noti.object);
	 //这里些你们的业务，请求你们的服务端
	 if (1 == 1) {
	 PPBillNoQueue *ppBillNoQueue = [[PPBillNoQueue alloc] init];
	 [ppBillNoQueue deleteBillNo:noti.object];
	 [ppBillNoQueue release];
	 }
	 */
}

//关闭客户端页面回调方法
-(void)closePageViewCallBack:(NSNotification *)noti{
    
}

//关闭WEB页面回调方法
-(void)closeWebViewCallBack:(NSNotification *)noti{
    
}

//兑换回调接口【只有兑换会执行此回调】
-(void)payResultCallBack:(NSNotification *)noti{
	//回调购买成功。其余都是失败
	//if([[noti object] isEqualToString:@"购买成功"]){
    if([[noti object] isEqualToString:NSLocalizedString(@"sns_helper_buy_ok",nil)]){
		//购买成功发放道具
		
	}else{
		
	}
}
#endif

#pragma mark ---------------Efun SDK CALLBACK ---------------
#if GAME_SNS_TYPE==5
-(void)efunLoginCallBack:(NSNotification*)notification{
	[delegate didLogin:self];
}
-(void)efunLogoutCallBack:(NSNotification*)notification{
	[delegate didLogin:self];
}
#endif

#if GAME_SNS_TYPE==6
-(void)efunLoginCallBack:(NSNotification*)notification{
	[delegate didLogin:self];
}
-(void)efunLogoutCallBack:(NSNotification*)notification{
	[delegate didLogin:self];
}
#endif

#if GAME_SNS_TYPE==7
#pragma mark --------------- 云顶 API CALLBACK ---------------
//捕获登录消息
-(void)kIDSLoginNotificationResult:(NSNotification*)notif{
	
	/*
	 NSDictionary * userinfo = [notif userInfo];
	 bool isSuccess = [[userinfo objectForKey:@"result"] boolValue];
	 if([[idsPP sharedInstance] isLogined] && isSuccess){
	 
	 }else{
	 
	 }
	 */
	
	[delegate didLogin:self];
	
}
-(void)kIDSLogoutNotificationResult:(NSNotification*)notif{
	NSDictionary *userinfo = [notif userInfo];
	bool isSuccess = [[userinfo objectForKey:@"result"] boolValue];
	if(isSuccess){
		[delegate didLogout:self];
		[NSTimer scheduledTimerWithTimeInterval:0.001f target:delegate 
									   selector:@selector(didLogout:) 
									   userInfo:nil repeats:NO];
	}
}
#endif

#if GAME_SNS_TYPE==8
#pragma mark --------------- UC API CALLBACK ---------------

-(void)onSdkInitFinish:(NSNotification*)notification{
	UCResult *result = (UCResult *)notification.object;
	
	//NSLog(@"SDK init res: \ncode=%d, msg=%@",result.statusCode, result.message);
    // 初始化成功时的处理
    if (result.isSuccess)
    {
		if (delegate) {
			[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
		}
    }
	
}

-(void)onSdkLoginFinish:(NSNotification*)notification{
	UCResult * result = notification.object;
	
	//NSLog(result.message);
    if(result.isSuccess){
		[self loadUCdata];
    }
	
}

-(void)loadUCdata{
	
	UCGameSdk *sdk = [UCGameSdk defaultSDK];
	NSString * urlString = @"";
	if(sdk.isDebug){
		urlString = [NSString stringWithFormat:
					 @"http://web1.zl.52yh.com/tools/uccheck/getuserinfotest?sid=%@",
					 [UCGameSdk defaultSDK].sid
					 ];
	}else{
		urlString = [NSString stringWithFormat:
					 @"http://web1.zl.52yh.com/tools/uccheck/getuserinfo?sid=%@",
					 [UCGameSdk defaultSDK].sid
					 ];
	}
	
	NSURL * url = [NSURL URLWithString:urlString];
	ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
	[request setCompletionBlock:^{
		
		NSError * error = nil;
		NSDictionary * json = [[CJSONDeserializer deserializer]
							   deserializeAsDictionary:[request responseData]
							   error:&error];
		if(!error){
			NSDictionary * state = [json objectForKey:@"state"];
			if([[state objectForKey:@"code"] intValue] == 1){
				NSDictionary * data = [json objectForKey:@"data"];
				
				if(ucid){
					[ucid release];
					ucid = nil;
				}
				
				if(ucname){
					[ucname release];
					ucname = nil;
				}
				
				isLoginUC = YES;
				ucid = [[NSString alloc] initWithFormat:@"%d",[[data objectForKey:@"ucid"] intValue]];
				ucname = [[NSString alloc] initWithString:[data objectForKey:@"nickName"]];
				
			}
			[delegate didLogin:self];
		}else{
			[delegate didLogin:self];
		}
		
	}];
	[request setFailedBlock:^{
		[self loadUCdata];
	}];
	[request setRequestMethod:@"GET"];
	[request startAsynchronous];
}

-(void)onSdkWithOutLoginFinish:(NSNotification*)notif{
	//NSLog(@"\n用户未登录下退出");
	isLoginUC = NO;
	[delegate didLogout:self];
}

-(void)onSdkLogOut:(NSNotification*)notif{
	//NSLog(@"\n用户注销登录退出");
	isLoginUC = NO;
	[delegate didLogout:self];
}

-(void)onPayFin:(NSNotification*)notification{
	/*
	UCResult *result = notification.object;
	NSDictionary * data = result.data;
	if(result.isSuccess){
		NSString * orderId = [data objectForKey:@"orderId"];					// 订单号
		float payAmount = [[data objectForKey:@"orderAmount"] floatValue];		// 订单支付金额
		int payWayId = [[data objectForKey:@"payWay"] intValue];				// 支付方式标识
		NSString * payWayName = [data objectForKey:@"payWayName"];				// 支付方式名称
		NSString * msg = [NSString stringWithFormat:@"订单提交成功，订单号为:%@，金额:%.02f元,payWayId:%d, 支付方式:%@",
						   orderId, payAmount, payWayId, payWayName];
	}
	*/
}


#endif

#if GAME_SNS_TYPE==9
#pragma mark --------------- 云顶 JB API CALLBACK ---------------
//捕获登录消息
-(void)kIDSLoginNotificationResult:(NSNotification*)notif{
	
	/*
	 NSDictionary * userinfo = [notif userInfo];
	 bool isSuccess = [[userinfo objectForKey:@"result"] boolValue];
	 if([[idsPP sharedInstance] isLogined] && isSuccess){
	 
	 }else{
	 
	 }
	 */
	
	[delegate didLogin:self];
	
}
-(void)kIDSLogoutNotificationResult:(NSNotification*)notif{
    
	/*
	 NSDictionary *userinfo = [notif userInfo];
	 bool isSuccess = [[userinfo objectForKey:@"result"] boolValue];
	 if(isSuccess){
	 
	 }else{
	 
	 }
	 */
	NSDictionary *userinfo = [notif userInfo];
	bool isSuccess = [[userinfo objectForKey:@"result"] boolValue];
	if(isSuccess){
		[delegate didLogout:self];
		[NSTimer scheduledTimerWithTimeInterval:0.001f target:delegate
									   selector:@selector(didLogout:)
									   userInfo:nil repeats:NO];
	}
}

-(void)kIDSPayResultNotificationResult:(NSNotification*)notif{
	
	if(notif){
		
	}
	
}
#endif

#if GAME_SNS_TYPE==10
#pragma mark --------------- 同步推 API CALLBACK ---------------
-(void)loginResultTB:(NSNotification *)notification{
	[delegate didLogin:self];
}
-(void)leavePlatformTB:(NSNotification *)notification{
	[delegate didLogout:self];
}

-(void)appVersionUpdateDidFinish:(TB_APP_UPDATE_RESULT)updateResult{
    switch (updateResult) {
        case TB_APP_UPDATE_NO_NEW_VERSION:
			//正常进入游戏
			
            break;
        case TB_APP_UPDATE_NEW_VERSION_DOWNLOAD_FAIL:
			//可以正常进入游戏，强制更新可由服务端限制登录
			
            break;
        case TB_APP_UPDATE_CHECK_NEW_VERSION_FAIL:
			//可能是网络问题，那么建议检查下网络，也可以直接进入游戏，
			//这边的风险在于如果是客户端与服务器版本不兼容，容易引起客户端异常
			
            break;
        case TB_APP_UPDATE_UPDATE_CANCEL_BY_USER:
            //进入游戏，需要的话，可以提示进一步提示玩家更新的好处和目的
			
            break;
        default:
            break;
    }
	
	[delegate didCheckVersion:self action:VERSION_NO_NEW_VERSION];
}
#endif

#if GAME_SNS_TYPE==11
#pragma mark --------------- 当乐 API CALLBACK ---------------

-(void)dealDJPlatformLoginResultNotify:(NSNotification*)notify{
	[[DJPlatform defaultDJPlatform] DJReadMemberInfo];
}
-(void)dealDJPlatformLogoutResultNotify:(NSNotification*)notify{
    [delegate didLogout:self];
}

-(void)dealDJPlatformReadMemberInfoResultNotify:(NSNotification*)notify{
	
	DJPlatformMemberInfo *memberInfo = [notify object];
	
	if(username){
		[username release];
		username = nil;
	}
	username = [[NSString alloc] initWithString:memberInfo.userName];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:username forKey:@"DJ_user_name"];
	[defaults synchronize];
	
	[delegate didLogin:self];
	
}

-(void)dealDJPlatformPaymentResultNotify:(NSNotification*)notify{
	
}

-(void)dealDJPlatformPaymentGiveupNotify:(NSNotification*)notify{
    
}
#endif

#pragma mark ---------------PP PGY SDK CALLBACK ---------------
#if GAME_SNS_TYPE==12
//登陆成功回调方法
-(void)loginCallBack:(NSNotification *)noti{
	/*
	 MSG_PS_VERIFI2_RESPONSE mpvr = [UnPackage bytePSVerifi2Response:noti.object];
	 MSG_GAME_SERVER mgs = {};
	 mgs.len = 24;
	 mgs.commmand = 0xAA000021;
	 memcpy(mgs.token_key, mpvr.token_key, 16);
	 NSString *requestURLStr = @"http://58.218.147.147:8850/login.php";
	 NSURL *requestUrl = [[NSURL alloc] initWithString:[requestURLStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	 NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestUrl];
	 
	 NSData *token_keyData = [NSData dataWithBytes:mpvr.token_key length:16];
	 [request setHTTPMethod:@"POST"];
	 [request setTimeoutInterval:10];
	 [request setHTTPBody:token_keyData];
	 [self sendRequest:request];
	 [requestUrl release];
	 
	 [bgGanmeCenterImageView setHidden:NO];
	 [bgloginImageView setHidden:YES];
	 */
	[delegate didLogin:self];
}
//注销回调方法
-(void)logOffCallBack{
	[delegate didLogin:self];
}

/**
 *在充值并且兑换业务服务器不能接受回调。需要客户端发起兑换的厂商需要再此回调获取订单号。将代码设置为[[PPAppPlatformKit sharedInstance] setIsGetBillNo:YES];
 *并且在收到通知做为处理后。请调用-(void)deleteBillNo:(NSString *)paramBillNo将当前订单从队列移除;否则订单一直会在队列象游戏客户端发送通知。
 */
-(void)postBillNoCallBack:(NSNotification *)noti{
	/*
	 //    此时noti.objct为你的订单号
	 //    如果获得处理后。则需要返回给我
	 NSLog(@"获取补发订单回调-%@",noti.object);
	 //这里些你们的业务，请求你们的服务端
	 if (1 == 1) {
	 PPBillNoQueue *ppBillNoQueue = [[PPBillNoQueue alloc] init];
	 [ppBillNoQueue deleteBillNo:noti.object];
	 [ppBillNoQueue release];
	 }
	 */
}

//关闭客户端页面回调方法
-(void)closePageViewCallBack:(NSNotification *)noti{
    
}

//关闭WEB页面回调方法
-(void)closeWebViewCallBack:(NSNotification *)noti{
    
}

//兑换回调接口【只有兑换会执行此回调】
-(void)payResultCallBack:(NSNotification *)noti{
	//回调购买成功。其余都是失败
	//if([[noti object] isEqualToString:@"购买成功"]){
    if([[noti object] isEqualToString:NSLocalizedString(@"sns_helper_buy_ok",nil)]){
		//购买成功发放道具
		
	}else{
		
	}
}
#endif

#pragma mark -

-(void)enterUserInfo:(NSDictionary*)userInfo{
	
#if GAME_SNS_TYPE==9
	if(userInfo){
		[[idsPP sharedInstance] setServId:[userInfo objectForKey:@"serverId"]
								 ServName:[userInfo objectForKey:@"serverName"]
		 ];
		[[idsPP sharedInstance] setRoleId:[userInfo objectForKey:@"playerId"]
								 RoleName:[userInfo objectForKey:@"playerName"]
		 ];
	}
#endif
	
#if GAME_SNS_TYPE==7
	if(userInfo){
		[[idsPP sharedInstance] setServId:[userInfo objectForKey:@"serverId"]
								 ServName:[userInfo objectForKey:@"serverName"]
		 ];
		[[idsPP sharedInstance] setRoleId:[userInfo objectForKey:@"playerId"]
								 RoleName:[userInfo objectForKey:@"playerName"]
		 ];
	}
#endif
	
}

-(void)purchase:(NSDictionary*)info{
	[self purchase:info target:nil call:nil];
}
-(void)purchase:(NSDictionary*)info target:(id)target call:(SEL)call{
	[self purchase:info target:target call:call other:nil];
}

-(void)purchase:(NSDictionary*)info target:(id)target call:(SEL)call other:(NSDictionary*)other{
	
#if GAME_SNS_TYPE==1
	
	NSString * productId = [NSString stringWithFormat:@"%d",[[info objectForKey:@"id"] intValue]];
	
	NdBuyInfo * buyInfo = [[NdBuyInfo new] autorelease];
	buyInfo.cooOrderSerial = [info objectForKey:@"gorder"]; //getGUID();
	buyInfo.productId = productId;
	buyInfo.productName = [info objectForKey:@"name"];
	buyInfo.productPrice = [[info objectForKey:@"price"] floatValue];
	buyInfo.productOrignalPrice = [[info objectForKey:@"oprice"] floatValue];;
	buyInfo.productCount = 1;
	//buyInfo.payDescription = @"";
	
	int res = [[NdComPlatform defaultPlatform] NdUniPayAsyn:buyInfo];
	if (res < 0){
		//NSLog(@"error");
	}
	
#endif
	
#if GAME_SNS_TYPE==2
	
	/*
	DPayRecharge * payRecharge = [[[DPayRecharge alloc] init] autorelease];
	payRecharge.rechargeId = [info objectForKey:@"gorder"];
	payRecharge.rechargeExtra = [info objectForKey:@"gorder"];
	
	[[DPayPlatform defaultPlatform] setClientGenerator:payRecharge];
	
	int price = [[info objectForKey:@"price"] intValue] * 10;
	[[DPayPlatform defaultPlatform] enterRechargeCenter:price];
	*/
	
	
	int price = [[info objectForKey:@"price"] intValue] * 10;
	[[DPayPlatform defaultPlatform] enterRechargeCenterWithCoin:price
												 userRechargeId:[info objectForKey:@"gorder"]
														  extra:[info objectForKey:@"gorder"]
	];
	
	
#endif
	
#if GAME_SNS_TYPE==4
	
	
	PPExchange *exchange = [[PPExchange alloc] init];
	int money = [[NSString stringWithFormat:@"%f",[exchange ppSYPPMoneyRequest]] intValue];
	float price = [[info objectForKey:@"price"] floatValue];
	
	//NSString * billNO = [NSString stringWithFormat:@"%d",[[NSDate date] timeIntervalSince1970]];
	int time = [[NSDate date] timeIntervalSince1970];
	NSString * billNO = [[NSString alloc] initWithFormat:@"%d",time];
	NSString * priceStr = [NSString stringWithFormat:@"%.2lf",price];
	
	if(money>=price){
		
		[exchange ppExchangeToGameRequestWithBillNo:billNO
											 Amount: priceStr
											 RoleId:[info objectForKey:@"gorder"]
											 ZoneId:0];
		
		[billNO release];
		
	}else{
		[[PPWebView sharedInstance] rechargeAndExchangeWebShow:billNO
												   BillNoTitle:[info objectForKey:@"name"]
													  PayMoney:priceStr
														RoleId:[info objectForKey:@"gorder"]
														ZoneId:0];
	}
	
	[exchange release];
	
#endif
	
#if GAME_SNS_TYPE==5
	[[InAppPurchasesHelper shared] purchases:[info objectForKey:@"gid"]
									   order:[info objectForKey:@"gorder"]
									  target:target
										call:call];
#endif
	
#if GAME_SNS_TYPE==6
	[[InAppPurchasesHelper shared] purchases:[info objectForKey:@"gid"]
									   order:[info objectForKey:@"gorder"]
									  target:target
										call:call];
#endif
	
#if GAME_SNS_TYPE==7
	[[InAppPurchasesHelper shared] purchases:[info objectForKey:@"gid"]
									   order:[info objectForKey:@"gorder"]
									  target:target
										call:call];
#endif
	
#if GAME_SNS_TYPE==8
	int price = [[info objectForKey:@"price"] intValue];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithBool:YES],	UCG_SDK_KEY_PAY_ALLOW_CONTINUOUS_PAY,
						  [info objectForKey:@"gorder"],	UCG_SDK_KEY_PAY_CUSTOM_INFO,
						  [NSNumber numberWithInt:price],	UCG_SDK_KEY_PAY_AMOUNT, 
						  nil];
	[[UCGameSdk defaultSDK] payWithPaymentInfo:dict];
#endif

#if GAME_SNS_TYPE==9
	
	if(other){
		[[idsPP sharedInstance] setServId:[other objectForKey:@"serverId"]
								 ServName:[other objectForKey:@"serverName"]
		 ];
		[[idsPP sharedInstance] setRoleId:[other objectForKey:@"playerId"]
								 RoleName:[other objectForKey:@"playerName"]
		 ];
		[[idsPP sharedInstance] showYunDingPayWithGoodsCode:nil];
	}
	
#endif
	
#if GAME_SNS_TYPE==10
	int price = [[info objectForKey:@"price"] intValue];
	/*
	[[TBPlatform defaultPlatform] TBUniPayForCoin:[info objectForKey:@"gorder"]
									   needPayRMB:price 
								   payDescription:[info objectForKey:@"gorder"]
	 ];*/
	
	[[TBPlatform defaultPlatform] TBUniPayForCoin:[info objectForKey:@"gorder"]
									   needPayRMB:price
								   payDescription:[info objectForKey:@"gorder"]
										 delegate:NULL];
#endif
	
#if GAME_SNS_TYPE==11
	
	if(![[DJPlatform defaultDJPlatform] DJIsLogin]){
		UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"提示信息" message:@"请先登录" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
		[alert show];
		[alert release];
	}else{
		int price = [[info objectForKey:@"price"] intValue];
		[[DJPlatform defaultDJPlatform] DJPayment:price
									  productName:[info objectForKey:@"name"]
										  extInfo:[info objectForKey:@"gorder"]
		 ];
	}
	
#endif
	
#if GAME_SNS_TYPE==12
	
	PPExchange *exchange = [[PPExchange alloc] init];
	int money = [[NSString stringWithFormat:@"%f",[exchange ppSYPPMoneyRequest]] intValue];
	float price = [[info objectForKey:@"price"] floatValue];
	
	//NSString * billNO = [NSString stringWithFormat:@"%d",[[NSDate date] timeIntervalSince1970]];
	int time = [[NSDate date] timeIntervalSince1970];
	NSString * billNO = [[NSString alloc] initWithFormat:@"%d",time];
	NSString * priceStr = [NSString stringWithFormat:@"%.2lf",price];
	
	if(money>=price){
		
		[exchange ppExchangeToGameRequestWithBillNo:billNO
											 Amount: priceStr
											 RoleId:[info objectForKey:@"gorder"]
											 ZoneId:0];
		
		[billNO release];
		
	}else{
		[[PPWebView sharedInstance] rechargeAndExchangeWebShow:billNO
												   BillNoTitle:[info objectForKey:@"name"]
													  PayMoney:priceStr
														RoleId:[info objectForKey:@"gorder"]
														ZoneId:0];
	}
	
	[exchange release];
	
#endif
	
}

-(void)purchaseVerify:(BOOL)isPass{
	
#if GAME_SNS_TYPE==5
	[[InAppPurchasesHelper shared] checkVerify:isPass];
#endif
	
#if GAME_SNS_TYPE==6
	[[InAppPurchasesHelper shared] checkVerify:isPass];
#endif
	
#if GAME_SNS_TYPE==7
	[[InAppPurchasesHelper shared] checkVerify:isPass];
#endif
	
}

@end
