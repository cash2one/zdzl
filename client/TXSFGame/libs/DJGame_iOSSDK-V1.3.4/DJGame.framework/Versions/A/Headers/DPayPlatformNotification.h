//
//  DPayPlatformNotification.h
//  DPay
//
//  Created by lory qing on 11/8/12.
//  Copyright (c) 2012 Bodong NetDragon. All rights reserved.
//

#ifndef DPay_DPayPlatformNotification_h
#define DPay_DPayPlatformNotification_h

/*SDK通知消息*/

//平台离开时的通知
#define DPay_kNotificationLeavePlatform     @"kNotificationLeavePlatform"

//用户取消登录时的通知
#define DPay_kNotificationUserCancelLogin   @"kNotificationUserCancelLogin"

//登录成功时的通知
#define DPay_kNotificationUserLoginSuccess  @"kNotificationUserLoginSuccess"

//用户注销时的通知
#define DPay_kNotificationUserLoginOut      @"kNotificationUserLoginOut"

//用户下单通知
#define DPay_kNotificationRechargeDidSubmit @"kNotificationRechargeDidSubmit"

//用户充值结束通知，开发这可在接收到这个通知后，查询订单状态（注：用户有可能未充值，就结束）
#define DPay_kNotificationRechargeDidFinish @"kNotificationRechargeDidFinish"

#endif
