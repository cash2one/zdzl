//
//  DJPlatform.h
//  DownjoySDK20
//
//  Created by tech on 13-2-28.
//  Copyright (c) 2013年 downjoy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface DJPlatform : UIViewController

-(void) setMerchantId : (NSString *) merchantId;
-(void) setAppId : (NSString *) appId;
-(void) setAppKey : (NSString *) appKey;
-(void) setServerId : (NSString *) serverId;
-(void) setTapBackgroundHideView : (BOOL) hidden;
-(void) setProChannelId : (NSString *) channelId;
//登陆
-(void) DJLogin;
//获取用户Mid
-(NSNumber *) getCurrentMemberId;
//获取用户Token
-(NSString *) getCurrentToken;
//获取用户信息
-(void) DJReadMemberInfo;
//注销
-(void) DJLogout;
//用户中心
-(void) DJMemberCenter;
//下订单
-(void) DJPayment : (float) money productName : (NSString *) productName extInfo : (NSString *) extInfo;
// 判断是否登陆状态
-(BOOL) DJIsLogin;
+(DJPlatform *) defaultDJPlatform;

@end
