//
//  DPayPlatform.h
//  DPay
//
//  Created by lory qing on 10/12/12.
//  Copyright (c) 2012 Bodong NetDragon. All rights reserved.
//

#import "DPayStructDefine.h"

@protocol DPayPlatformProtocol;

@class DPayRechargeGenerator;
@class DPayAppInfo;

@interface DPayPlatform : NSObject

/**
 @brief 获取DPayPlatform的实例对象
 */
+ (DPayPlatform *)defaultPlatform;
 
#pragma mark - 平台配置

/**
 @brief 设置应用Id及设置应用密钥
 @param appId 应用程序id，需要向用户中心申请，合法的id大于 0
 @param appKey 第三方应用程序密钥，appKey未系统分配给第三方的应用程序密钥，第三方需要向平台提供方申请，并设置到平台上
 @result 设置是否成功
 */
- (BOOL)setAppId:(int)appId andAppKey:(NSString *)appKey;

/**
 @brief 设置渠道Id, 必须在setAppId:(int)appId andAppKey:(NSString *)appKey 之前调用 （可选）
 */
- (void)setChannelId:(int)channelId;

/**
 @brief 设定View方向
 @note	设定方向之前必须关闭自动旋转(即调用setOfferViewAutoRotate，参数为NO)，否则设定无效
 */
- (void)setViewOrientation:(UIInterfaceOrientation)orientation;

/**
 @brief 设定View是否自动旋转，默认为自动旋转
 */
- (void)setViewAutoRotate:(BOOL)isAutoRotate;

/**
 @brief 设置导航条菜单是否可见（导航条菜单用于不同页面间的切换，如：用户中心，商城等）
 @note 默认可见
 */
- (void)setNavigationItemVisible:(BOOL)isVisible;

/**
 @brief 获取应用详细信息
 @result 返回应用信息的对象DPayApplicationInfo，具体查看API文档
 */
- (DPayAppInfo *)getAppInfo;

/**
 @brief 获取会话ID
 */
- (NSString *)getSessionId;

#pragma mark - 用户

/**
 @brief  进入用户登录页面
 @param	 isOnlyForLogin 是否仅仅只需调用SDK的登录页面，然后返回开发者应用界面；默认为NO
 @note	 在某些应用中如果开发者只需SDK的登录页面，则调用此方法，并设置参数为YES
 @result 无
 */
- (void)login:(BOOL)isOnlyForLogin;

/**
 @brief 快速登陆
 @param delegate 回调对象
 @result 返回结果请实现对应的回调函数 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)quickLogin:(id<DPayPlatformProtocol>)delegate;

/**
 @brief 个人中心页面
 */
- (void)enterUserCenter;

/**
 @brief 用户是否登录
 */
- (BOOL)isUserLoggedIn;

/**
 @brief 获取用户ID
 @result 若用户没登录，则返回0
 */
- (long long)getUserId;

/**
 @brief 获取用户名
 @result 若用户没登录，则返回nil
 */
- (NSString *)getUserName;

/**
 @brief 获取用户当前余额
 @result 若用户没登录，则返回0
 */
- (float)getUserBalance;

/**
 @brief 获取用户当前账号信息
 */
- (void)getAccountDetail:(id<DPayPlatformProtocol>)delegate;

/**
 @brief 用户注销
 */
- (void)logout;

#pragma mark - 充值

/**
 @brief 进入充值中心页面
 @param userRechargeId 开发者自定义的流水号。虚拟货币或代币模式下，参数可传入空。代币模式下，必须传入非空的参数
 @param extra 自定义额外信息
 */
- (void)enterRechargeCenterWithUserRechargeId:(NSString *)userRechargeId
                                        extra:(NSString *)extra;

/**
 @brief 直接传入金额，进入充值页面
 @param userRechargeId 开发者自定义的流水号。虚拟货币或代币模式下，参数可传入空。代币模式下，必须传入非空的参数
 @param extra 自定义额外信息
 @note 充值最大金额1-999999。如果传入小于1的数，会被默认设为1；如果传入比999999大的数，会被默认设为999999
 */
- (void)enterRechargeCenterWithCoin:(int)gameCoin
                     userRechargeId:(NSString *)userRechargeId
                              extra:(NSString *)extra;

/**
 @brief 查询充值状态 (充值漏单处理)
 @param rechareId 充值的流水号，由SDK生成的
 @param userRechargeId 开发者身定义的流水号，开发者自行控制，可选项，若没有定义，请传入空字符串
 @param delegate 回调对象
 @result 返回结果请实现对应的回调函数 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)getRechargeStatus:(NSString *)rechargeId
           userRechargeId:(NSString *)userRechargeId
                 delegate:(id<DPayPlatformProtocol>)delegate;

#pragma mark - 商城

/**
 @brief 商城页面
 */
- (void)enterShoppingMall;

/**
 @brief 获取商品分类列表
 @param currentPage 第几页
 @param limit 每页请求的商品个数，0表示一次性获取完
 @param delegate 回调对象
 @result 返回结果请实现对应的回调函数 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)getGoodsCategoryList:(int)currentPage
                       limit:(int)limit
                    delegate:(id<DPayPlatformProtocol>)delegate;

/**
 @brief 获取某个分类商品列表或多个分类的商品列表
 @param consumeType 消费类型,详细说明请参考DPayStructDefine.h
 @param categoryID 分类ID（0表示不过滤分类)
 @param currentPage 第几页
 @param limit 每页请求的商品个数，0表示一次性获取完
 @param delegate 回调对象
 @result 返回结果请实现对应的回调函数 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)getGoodsList:(DPAY_TYPE_OF_CONSUME)consumeType
          categoryID:(int)categoryID
         currentPage:(int)currentPage
               limit:(int)limit
            delegate:(id<DPayPlatformProtocol>)delegate;

/**
 @brief 获取商品详细信息
 @param goodsID 虚拟商品id,支持一次查询多个,商品ID用逗号隔开
 @param delegate 回调对象
 @result 返回结果请实现对应的回调函数 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)getGoodsDetailInfo:(NSString *)goodsID
                  delegate:(id<DPayPlatformProtocol>)delegate;

/**
 @brief 购买商品
 @param goodsArray 所需购买的商品数组，数组元素为DPayPurchasingItem对象
 eg:
 DPayPurchasingItem *item = [[DPayPurchasingItem alloc] init];
 item.goodsId = 50;
 item.goodsPurcharsedNum = 1;
 NSArray *arr = [NSArray arrayWithObject:item];
 [item release];
 
 @param delegate 回调对象
 @result 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)purchaseGoods:(NSArray *)goods
                extra:(NSString *)extra
             delegate:(id<DPayPlatformProtocol>)delegate;

/**
 @brief 购买商品（扩展）
 @param goodsArray 所需购买的商品数组，数组元素为DPayPurchasingCustomItem对象
 eg:
 DPayPurchasingCustomItem *item = [[DPayPurchasingCustomItem alloc] init];
 item.goodsId = 50;
 item.goodsPurcharsedNum = 1;
 NSArray *arr = [NSArray arrayWithObject:item];
 [item release];
 
 @param orderID 订单ID
 @param productAmount 订单金额
 @param extra 开发者定义额外字符串
 @param delegate 回调对象
 @result 开发者可以获取购买的状态， 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)purchaseCustomGoods:(NSArray *)goods
               productAmout:(float)productAmout
                      extra:(NSString *)extra
                   delegate:(id<DPayPlatformProtocol>)delegate;

/**
 @brief 查询订单状态 (购买商品漏单处理)
 @param orderID 购买商品订单id
 @param delegate 回调对象
 @result 返回结果请实现对应的回调函数 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)getGoodsOrderStatus:(NSString *)orderID
                   delegate:(id<DPayPlatformProtocol>)delegate;

/**
 @brief 获取用户已购买商品列表
 @param consumeType 消费类型,详细说明请参考DPayStructDefine.h
 @param categoryID 分类ID（0表示不过滤分类)
 @param currentPage 第几页
 @param limit 每页请求的商品个数，0表示一次性获取完
 @param delegate 回调对象
 @result 返回结果请实现对应的回调函数 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)getPurchasedGoodsList:(DPAY_TYPE_OF_CONSUME)consumeType
                   categoryID:(int)categoryID
                  currentPage:(int)currentPage
                        limit:(int)limit
                     delegate:(id<DPayPlatformProtocol>)delegate;

/**
 @brief 查询已购商品信息
 @param goodsID 虚拟商品id
 @param userID 用户id
 @param delegate 回调对象
 @result 返回结果请实现对应的回调函数 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)getGoodsPurchasedInfo:(int)goodsID
                     delegate:(id<DPayPlatformProtocol>)delegate;

/**
 @brief 消耗商品
 @param goodsID 虚拟商品id
 @param usingCount 消耗商品个数
 @param delegate 回调对象
 @result 返回结果请实现对应的回调函数 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)consumeGoods:(int)goodsID
          usingCount:(int)usingCount
            delegate:(id<DPayPlatformProtocol>)delegate;

#pragma mark - 其他

/**
 @brief 提交反馈信息
 @param message 反馈详细内容
 @param contact 用户反馈的联系方式
 @param delegate 回调对象
 @result 返回结果请实现对应的回调函数 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)feedback:(NSString *)message
         contact:(NSString *)contact
        delegate:(id<DPayPlatformProtocol>)delegate;

/**
 @brief 获取应用消息
 @param delegate 回调对象
 @result 返回结果请实现对应的回调函数 详细说明请查看DPayPlatformProtocol.h文件
 */
- (void)getMessage:(id<DPayPlatformProtocol>)delegate;

@end
