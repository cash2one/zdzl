//
//  IDSNotifications.h
//  ids
//
//  Created by 何凌铿 on 13-4-1. qq:2357303
//  Copyright (c) 2013年 hlk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString * const kIDSLoginNotification;                  // <登录各种>  默认登录，云顶登录，第三方登录，注册登录；发出该消息
extern NSString * const kIDSLogoutNotification;                 // <登出>     注销；发出消息
extern NSString * const kIDSPayResultNotification;              // <支付结果>  支付结果；发出消息
extern NSString * const kIDSWinADCloseNotification;             // <橱窗广告关闭> 橱窗广告关闭发出消息
extern NSString * const kIDSBannerADCloseNotification;          // <广告条关闭>  广告条光比发布消息
extern NSString * const kIDSMenuCloseNotification;              // <菜单关闭>
extern NSString * const kIDSViewCloseNotification;              // <内容页关闭>  点击内容页“菜单”按钮 ，退会到菜单界面
extern NSString * const kIDSViewReturnNotification;             // <内容页返回游戏> 点击内容页“返回游戏”按钮，直接返回游戏
extern NSString * const kIDSIconTouchNotification;              // <图标点击>
extern NSString * const kIDSMenuChooseNotification;

