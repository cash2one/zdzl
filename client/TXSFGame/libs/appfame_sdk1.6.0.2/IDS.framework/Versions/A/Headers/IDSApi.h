//
//  idsapi.h
//  Created by 何凌铿 on 13-4-1. qq:2357303
//  Copyright TopClound 2012. All rights reserved.
//  V1.6.0.5(ios6) updated_at 2012-09-21


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
+ (void)showDebugLog:(BOOL)flag;                                    //NO--不显示本地日志(缺省) YES--显示本地日志
+ (void)setServerDebug:(BOOL)flag;                                  //进入调试站点


//效果控制

- (void)setIsShowAppIcon:(BOOL)flag;


//云顶业务

- (void)setAppIconWithPosition:(IDSAppIconPosition)position     //设置云顶 AppIcon初始位置 必须调用
                IDSOrientation:(IDSInterfaceOrientation)idsOrientation;

- (int)setAppID:(NSUInteger)appid                                   //设置AppId 必须调用
         AppKey:(NSString *)appkey                                  //设置AppKey
       UmengKey:(NSString *)umengkey                                //设置UmengKey
  LaunchOptions:(NSDictionary *)launchOptions;                      //设置启动参数，推送相关 


- (void)setRoleId:(NSString*)roleId                     //角色id
         RoleName:(NSString *)roleName;                 //角色名字

- (void)setServId:(NSString *)servId                    //服务器id
         ServName:(NSString *)ServName;                 //服务器名称

- (void)setDeviceToken:(NSData *)deviceToken;                                           //发送推送token
- (void)setReceiveRemoteNotificationProcessWithUserInfo:(NSDictionary *)userInfo;       //推送反映


- (void)showbootLogin;                                                                  //手动显示登录界面

- (void)showMenuWithOrientation:(IDSInterfaceOrientation)orientation;                    //手动显示菜单


- (void)showYunDingPayWithGoodsCode:(NSString *)goodsCode;//手动显示支付界面
- (void)setYunDingPayAxpandData:(NSString *)expandData;   //设置支付额外参数，由云顶服务端回调通知给游戏服务端

- (BOOL)isLogined;                                      //是否登陆
- (void)logout;                                         //登出
- (void)isShowLoginByHandWhenLogouted;                  //当用户手动注销后，是否手动显示登入界面

- (BOOL)isSingleTask;
- (void)parseURL:(NSURL *)url application:(UIApplication *)application;

@end



typedef enum {
    IDS_ERROR_NETWORK,                                 // 客户端网络问题
    IDS_ERROR_SERVER,                                  // 服务器异常
    IDS_ERROR_USER_CANCEL,                             // 用户取消
    IDS_ERROR_ALIWEB_PAY_FAIL_ORDER_FAIL,              // 支付宝web，支付失败，web失败，联系云顶服务端技术支持
    IDS_ERROR_ALIWEB_PAY_SUC_ORDER_FAIL,               // 支付宝   支付成功充值失败
    IDS_ERROR_ALIWEB_PAY_SUC_ORDER_CALLBACKUNKNOWN,    // 支付宝   支付成功充值是否成功未知
    IDS_ERROR_ALIFASTPAY_CHECK_ORDER_FAIL,             // 捷支付最后验签失败
    IDS_ERROR_ALIFASTPAY_FAIL,                         // 快捷支付失败
    
}IDSErrorCode;


typedef enum
{
    IDS_ALIWEB_PAY,  //支付宝web支付
    IDS_ALIFAST_PAY, //支付宝快捷支付
    IDS_PAYPAL_PAY   //paypal支付
}IDSPayType;

