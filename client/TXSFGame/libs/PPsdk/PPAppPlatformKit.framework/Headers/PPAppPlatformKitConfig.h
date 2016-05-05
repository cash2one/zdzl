//
//  PPAppPlatformKitConfig.h
//  PPAppPlatformKit
//
//  Created by 张熙文 on 1/11/13.
//  Copyright (c) 2013 张熙文. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark ------------------------ 常用请求接口参数 -----------------------------

#define PP_ISNSLOG                                                                      [[PPAppPlatformKit sharedInstance] isNSlogData]


#pragma mark ------------------------ SDK发送给游戏客户端通知 ------------------------------
/**
 *SDK发给游戏客户端通知
 */

//SDK注销用户时返回的通知
#define PP_CLIENT_LOGOFF_NOTIFICATION                                                    @"PP_CLIENT_LOGOFF_NOTIFICATION"
//登陆成功时返回通知
#define PP_CLIENT_LOGIN_NOTIFICATION                                                     @"PP_CLIENT_LOGIN_NOTIFICATION"
//关闭SDK的WEB页面时返回通知
#define PP_CLIENT_CLOSEWEB_NOTIFICATION                                                  @"PP_CLIENT_CLOSEWEB_NOTIFICATION"
//关闭SDK窗口界面是返回通知
#define PP_CLIENT_CLOSEPAGEVIEW_NOTIFICATION                                             @"PP_CLIENT_CLOSEPAGEVIEW_NOTIFICATION"
//补发订单到游戏客户端返回通知
#define PP_CLIENT_POSTBILLNOLIST_NOTIFICATION                                            @"PP_CLIENT_POSTBILLNOLIST_NOTIFICATION"
//兑换后返回通知
#define PP_CLIENT_EXCHANGE_NOTIFICATION                                                  @"PP_CLIENT_EXCHANGE_NOTIFICATION"



