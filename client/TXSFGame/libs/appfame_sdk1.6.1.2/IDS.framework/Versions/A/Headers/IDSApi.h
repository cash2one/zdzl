//
//  idsapi.h
//  Created by 何凌铿 on 13-4-1. qq:2357303
//  Copyright TopClound 2012. All rights reserved.
//  V1.6.1.2  updated_at 2012-09-21


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum
{
    IDSInterfaceOrientationPortrait         =     5,    //--支持竖版转向，通常使用
    IDSInterfaceOrientationLandscape        =     6     //--支持横版转向，通常使用
}
IDSInterfaceOrientation;


typedef enum
{
    //以下方位是手机竖直情况下的位置
    
    IDSAppIconTopRight          =   1,      //云顶标志初始位置 上右
    IDSAppIconTopLeft           =   2,      //云顶标志初始位置 上左
    IDSAppIconBottomRight       =   3,      //云顶标志初始位置 下右
    IDSAppIconBottomLeft        =   4       //云顶标志初始位置 下左
}
IDSAppIconPosition;



@interface idsPP : NSObject


+ (idsPP *)sharedInstance;                                          //使用单例持久
+ (void)releaseInstance;                                            //释放持久单例

//调试信息

+ (NSString *)version;                                              //SDK版本信息
+ (void)setServerDebug:(BOOL)flag;                                  //进入调试站点

//效果控制

- (void)setIsShowAppIcon:(BOOL)flag;
- (void)setAppIconPostion:(IDSAppIconPosition)posttion;             //设置浮动图标的初始化位置
- (void)hiddenChangeAccountFun;                                     //在我的账号中心隐藏切换账号功能


//云顶业务
- (int)setAppID:(NSUInteger)appid                                   //设置AppId
         AppKey:(NSString *)appkey                                  //设置AppKey
       UmengKey:(NSString *)umengkey                                //设置UmengKey
 IDSOrientation:(IDSInterfaceOrientation)idsOrientation             //设置SDK的方向
  LaunchOptions:(NSDictionary *)launchOptions;                      //设置启动参数，推送相关


//setServId 必须在SetRoleId 之前调用
- (void)setServId:(NSString *)servId                    //服务器id 必须调用
         ServName:(NSString *)ServName;                 //服务器名称


- (void)setRoleId:(NSString*)roleId                     //角色id 必需调用
         RoleName:(NSString *)roleName;                 //角色名字


- (void)setDeviceToken:(NSData *)deviceToken;                                           //发送推送token
- (void)setReceiveRemoteNotificationProcessWithUserInfo:(NSDictionary *)userInfo;       //推送反映


/*
 *账号中心界面
 */
- (void)showMenuWithOrientation:(IDSInterfaceOrientation)orientation;          //手动显示账号中心，菜单中提供了用户系统和支付系统。


- (void)showYunDingPayWithGoodsCode:(NSString *)goodsCode;                      //越狱版本中，手动显示支付界面
- (void)setYunDingPayAxpandData:(NSString *)expandData;                         //设置支付额外参数，由云顶服务端回调通知给游戏服务端

- (BOOL)isLogined;                                                              //是否登陆
- (void)logout;                                                                 //登出


- (void)parseURL:(NSURL *)url application:(UIApplication *)application;         //越狱版本中，快捷支付跳转回游戏时候的配置，具体可以查看demo


/*
 *以下两个方法是为特殊的游戏准备的，不要使用。
 *方法showbootLogin与setShowLoginByHandWhenLogouted必须配合使用
 *只有在AppDelegate的启动函数中调用setShowLoginByHandWhenLogouted，调用showbootLogin
 *才有效果
 */
- (void)showbootLogin;                                                           //特殊游戏使用
- (void)setShowLoginByHandWhenLogouted;                                          //当用户手动注销后，启动游戏，是否手动显示登入界面
- (void)setNoShowLoginWhenLogouted;                                              //注销后不会出现登录界面

@end



typedef enum {
    IDS_ERROR_NETWORK,                                 // 客户端网络问题
    IDS_ERROR_SERVER,                                  // 服务器异常
    IDS_ERROR_USER_CANCEL,                             // 用户取消
    IDS_ERROR_ALIWEB_PAY_FAIL_ORDER_FAIL,              // 支付宝web，支付失败，web失败，联系云顶服务端技术支持
    IDS_ERROR_ALIWEB_PAY_SUC_ORDER_FAIL,               // 支付宝   支付成功充值失败
    IDS_ERROR_ALIWEB_PAY_SUC_ORDER_CALLBACKUNKNOWN,    // 支付宝   支付成功充值是否成功未知
    IDS_ERROR_ALIFASTPAY_CHECK_ORDER_FAIL,             // 快捷支付最后验签失败
    IDS_ERROR_ALIFASTPAY_FAIL,                         // 快捷支付失败
    
}IDSErrorCode;


typedef enum
{
    IDS_ALIWEB_PAY,  //支付宝web支付
    IDS_ALIFAST_PAY, //支付宝快捷支付
    IDS_PAYPAL_PAY   //paypal支付
}IDSPayType;

