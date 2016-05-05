//
//  DPayPlatformProtocol.h
//  DPay
//
//  Created by lory qing on 10/12/12.
//  Copyright (c) 2012 Bodong NetDragon. All rights reserved.
//

@class DPayUserAccountInfo;
@class DPayPurchasedGoodsDetailInfo;
@class DPayOrderInfo;

@protocol DPayPlatformProtocol <NSObject>

@optional

#pragma mark - 用户

/**
 @brief 开发者登陆
 @param errorCode 错误码， 0表示请求成功， 其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)quickLoginDidFinish:(int)errorCode;

/**
 @brief 实时获取用户账户信息 回调
 @param userBalance 用户账户信息对象
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)getAccountDetailDidFinish:(DPayUserAccountInfo *)accountInfo
                        errorCode:(int)errorCode;

#pragma mark - 充值

/**
 @brief 查询充值状态 (充值漏单处理) 回调
 @param rechargeStatus 充值状态 详细说明请参考DPayStructDefine.h
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)getRechargeStatusDidFinish:(DPAY_RECHARGE_STATUS)rechargeStatus
                             extra:(NSString *)extra
                         errorCode:(int)errorCode;

#pragma mark - 商城

/**
 @brief 获取商品分类列表 回调
 @param records 商品分类(DPayGoodsCategory)列表.
 @param totalCount 分类总条数
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)getGoodsCategoryListDidFinish:(NSArray *)goodCategoryRecords
                           totalCount:(int)totalCount
                            errorCode:(int)errorCode;

/**
 @brief 获取某个分类商品列表或多个分类的商品列表 回调
 @param records 商品信息(DPayGoodsInfo)列表.
 @param totalCount 商品总条数
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)getGoodsListDidFinish:(NSArray *)goodInfoRecords
                   totalCount:(int)totalCount
                    errorCode:(int)errorCode;

/**
 @brief 获取商品详细信息 回调
 @param records 商品信息对象(DPayGoodsDetailInfo)列表.
 @param totalCount 商品总条数
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)getGoodsDetailInfoDidFinish:(NSArray *)goodDetailInfoRecords
                         totalCount:(int)totalCount
                          errorCode:(int)errorCode;

/**
 @brief 获取用户已经购买商品列表 回调
 @param records 商品信息(DPayPurchasedGoodsInfo)列表.
 @param totalCount 商品总条数
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)getPurchasedGoodsListDidFinish:(NSArray *)purchasedGoodsInfoRecords
                            totalCount:(int)totalCount
                             errorCode:(int)errorCode;

/**
 @brief 查询已购商品信息 回调
 @param goodsInfo 已购买的商品信息对象
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)getGoodsPurchasedInfoDidFinish:(DPayPurchasedGoodsDetailInfo *)purchasedGoodInfo
                             errorCode:(int)errorCode;

/**
 @brief 消耗商品 回调
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)consumeGoodsDidFinish:(int)errorCode;

/**
 @brief 购买商品 回调
 @param orderId 订单ID
 @param goodsItems 用户购买的商品(DPayPurchasingItem)列表
 @param errorGoodsIDs 不可购买的商品ID,多个ID以逗号隔开
 @param usedAmount 订单总额
 @param extra 自定义的额外信息
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)purchaseGoodsDidFinish:(NSString *)orderId
                    goodsItems:(NSArray *)goodsItems
                  errorGoodIDs:(NSString *)errorGoodsIDs
                    usedAmount:(float)usedAmount
                         extra:(NSString *)extra
                     errorCode:(int)errorCode;


/**
 @brief 购买商品(扩展) 回调
 @param orderId 订单ID
 @param extra 自定义的额外信息
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)purchaseCustomGoodsDidFinish:(NSString *)orderId
                               extra:(NSString *)extra
                           errorCode:(int)errorCode;

/**
 @brief 查询购买订单状态 (购买商品漏单处理) 回调
 @param orderInfo 订单信息对象
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)getGoodsOrderStatusDidFinish:(DPayOrderInfo *)orderInfo
                           errorCode:(int)errorCode;

#pragma mark - 其他

/**
 @brief 提交反馈信息 回调
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)feedbackDidFinish:(int)errorCode;

/**
 @brief 获取应用信息 回调
 @param records 应用消息类型(DPayApplicationMessage)数组
 @param totalCount 应用消息总数
 @param errorCode 错误码， 0表示请求成功，其他错误码信息请参考DPayPlatformError.h文件
 */
- (void)getMessageDidFinish:(NSArray *)messageRecords
                 totalCount:(int)totalCount
                  errorCode:(int)errorCode;

@end
