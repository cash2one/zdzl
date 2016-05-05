//
//  PPWebView.h
//  PPUserUIKit
//
//  Created by seven  mr on 1/24/13.
//  Copyright (c) 2013 张熙文. All rights reserved.
//



#import <UIKit/UIKit.h>
@interface PPWebView : UIView<UIWebViewDelegate>
{

}

/// <summary>
/// 获取单例
/// </summary>
+ (PPWebView *)sharedInstance;



/// <summary>
/// 请求充值并兑换WEB页面
/// </summary>
/// <param name="paramBillNo">请求的订单号</param>
/// <param name="paramBillNo">请求的订单标题</param>
/// <param name="paramBillNo">请求订单的金额</param>
/// <param name="paramBillNo">请求订单购买的角色ID</param>
/// <param name="paramBillNo">请求订单购买的服务器ID</param>
-(void)rechargeAndExchangeWebShow:(NSString *)paramBillNo BillNoTitle:(NSString *)paramBillNoTitle
                         PayMoney:(NSString *)paramPayMoney RoleId:(NSString *)paramRoleId ZoneId:(int)paramZoneId;



@end
