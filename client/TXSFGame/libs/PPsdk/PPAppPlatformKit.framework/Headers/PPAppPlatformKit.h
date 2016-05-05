//
//  PPAppPlatform.h
//  PPAppPlatformKit
//
//  Created by 张熙文 on 1/11/13.
//  Copyright (c) 2013 张熙文. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <PPAppPlatformKit/PPAppPlatformKitConfig.h>
#import <PPAppPlatformKit/PPExchange.h>
#import <PPAppPlatformKit/PPUIKit.h>
#import <PPAppPlatformKit/PPWebView.h>
#import <PPAppPlatformKit/PPLoginView.h>
#import <PPAppPlatformKit/PPServerDataDefine.h>
#import <PPAppPlatformKit/UnPackage.h>
#import <PPAppPlatformKit/PPCenterView.h>
#import <PPAppPlatformKit/PPBillNoQueue.h>



@interface PPAppPlatformKit : NSObject
{

}
-(void)setCurrentAddress:(NSString *)paramCurrentAddress;

-(NSString *)currentAddress;

/// <summary>
/// 初始化SDK信息配置。
/// </summary>
/// <returns>返回PPAppPlatformKit单例</returns>
+ (PPAppPlatformKit *)sharedInstance;

/// <summary>
/// 设置是否需要客户端补发充值兑换订单，PS：默认开启。充值并且兑换业务服务器不能接受回调。需要客户端发起兑换的厂商需要再此回调获取订单号时启用
/// </summary>
/// <param name="IsGetBillNo">BOOL</param>
/// <returns>无返回</returns>
-(void)setIsGetBillNo:(BOOL)paramIsGetBillNo;

/// <summary>
/// 设置充值页面默认金额
/// </summary>
/// <param name="Amount">金额</param>
/// <returns>无返回</returns>
-(void)setRechargeAmount:(NSString *)paramAmount;


/// <summary>
/// 设置关闭充值提示语
/// </summary>
/// <returns>无返回</returns>
-(void)setCloseRechargeAlertMessahe:(NSString *)paramCloseRechargeAlertMessahe;

/// <summary>
/// 设置是否允许充值 【默认为YES】
/// </summary>
/// <returns>无返回</returns>
-(void)setIsOpenRecharge:(BOOL)paramIsOpenRecharge;


/// <summary>
/// 获取当前用户currentUserName
/// </summary>
/// <returns>返回currentUserName</returns>
-(NSString *)currentUserName;

/// <summary>
/// 获取当前用户currentUserId
/// </summary>
/// <returns>返回currentUserId</returns>
-(uint64_t)currentUserId;

/// <summary>
/// 获取当前用户currentSessionId
/// </summary>
/// <returns>返回currentSessionId</returns>
-(uint64_t)currentSessionId;

/// <summary>
/// 获取SDK是否允许打印日志到控制台
/// </summary>
/// <returns>返回BOOL</returns>
-(BOOL)isNSlogData;

/// <summary>
/// 设置SDK是否允许打印日志到控制台 PS：默认开启
/// </summary>
/// <param name="IsNSlogDatad">是否允许SDK打印日志到控制台</param>
/// <returns>无返回</returns>
-(void)setIsNSlogData:(BOOL)paramIsNSlogDatad;

/// <summary>
/// 设置该游戏的AppKey和AppId。从开发者中心游戏列表获取
/// </summary>
/// <param name="AppId">游戏Id</param>
/// <param name="AppKey">游戏Id</param>
/// <returns>无返回</returns>
- (void)setAppId:(int)paramAppId AppKey:(NSString *)paramAppKey;

/// <summary>
/// 设置SDK用户注销后是否自动push出登陆
/// </summary>
/// <param name="IsLogOutPushLoginView">是否允许</param>
/// <returns>无返回</returns>
- (void)setIsLogOutPushLoginView:(BOOL)paramIsLogOutPushLoginView;


@end
