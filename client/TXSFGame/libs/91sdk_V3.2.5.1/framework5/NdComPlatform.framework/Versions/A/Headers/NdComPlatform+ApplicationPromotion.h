//
//  NdComPlatform+ApplicationPromotion.h
//  NdComPlatform_SNS
//
//  Created by xujianye on 12-5-24.
//  Copyright 2012 NetDragon WebSoft Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NdComPlatformBase.h"
#import "NdComPlatformAPIResponse+ApplicationPromotion.h"


@interface NdComPlatform(ApplicationPromotion)

#pragma mark -
#pragma mark Data

/*!
 获取推广的软件信息列表
 @param maxDisplay 最多获取几个，如果 <= 0，则获取全部列表
 @param delegate 回调对象
 @result 请求成功返回正数，失败返回错误码
 */
- (int)NdGetAppPromotionList:(int)maxDisplay  delegate:(id)delegate;

/*!
 用户点击了推广列表中的某个软件
 @param appId 点击的那个软件
 @param delegate 回调对象
 @result 请求成功返回正数，失败返回错误码
 */
- (int)NdStartAppPromotion:(NSString*)appId  delegate:(id)delegate;

/*!
 获取在推广列表中得到的奖励信息
 @param delegate 回调对象
 @result 请求成功返回正数，失败返回错误码
 */
- (int)NdQueryAppPromotionAwardList:(id)delegate;

/*!
 在被推广的软件中激活了奖励
 @param delegate 回调对象
 @result 请求成功返回正数，失败返回错误码
 */
- (int)NdReachAppPromotionAwardCondition:(id)delegate;




#pragma mark -
#pragma mark UI

/*!
 进入推广墙列表
 @param nFlag 默认为0
 @result 请求成功返回正数，失败返回错误码
 */
- (int)NdEnterAppPromotionList:(int)nFlag;




typedef	enum  _NDCP_AP_BANNER_ALIGN {
	NDCP_AP_BANNER_ALIGN_TOP	= 2,
	NDCP_AP_BANNER_ALIGN_BOTTOM = 3,
}	NDCP_AP_BANNER_ALIGN;
/*!
 使用Banner方式展示推广应用
 @param nFlag 默认为0
 @param align Banner停靠位置
 @result 请求成功返回正数，失败返回错误码
 */
- (int)NdShowAppPromotionBanner:(int)nFlag  bannerAlign:(NDCP_AP_BANNER_ALIGN)align;


/*!
 使用Banner方式展示推广应用
 @param nFlag 默认为0
 @param anchorPoint Banner的锚点：{0,0}代表左上角，{1,1}代表右下角，{0.5,0.5}代表Banner中心位置，以此类推。
 @param position	指定Banner锚点所在的屏幕（去除StatusBar后的区域）位置。position也可以作为该屏幕的锚点用，如{0,0}代表屏幕左上角，{1,1}代表屏幕右下角。
 @result 请求成功返回正数，失败返回错误码
 */
- (int)NdShowAppPromotionBanner:(int)nFlag  anchorPoint:(CGPoint)anchorPoint  position:(CGPoint)position;




typedef	enum  _NDCP_AP_SLIDER_ALIGN {
	NDCP_AP_SLIDER_ALIGN_LEFT	= 0,
	NDCP_AP_SLIDER_ALIGN_RIGHT	= 1,
	NDCP_AP_SLIDER_ALIGN_TOP	= 2,
	NDCP_AP_SLIDER_ALIGN_BOTTOM = 3,
}	NDCP_AP_SLIDER_ALIGN;
/*!
 使用Slider方式展示推广应用
 @param nFlag 默认为0
 @param align 
 @result 请求成功返回正数，失败返回错误码
 */
- (int)NdShowAppPromotionSlider:(int)nFlag  sliderAlign:(NDCP_AP_SLIDER_ALIGN)align;


/*!
 隐藏推广应用（调用NdShowAppPromotion⋯⋯所显示的推广应用）
 @param nFlag 默认为0。
 @result 请求成功返回正数，失败返回错误码
 */
- (int)NdHideAppPromotion:(int)nFlag;

@end




#pragma mark -
#pragma mark -

@protocol NdComPlatformUIProtocol_ApplicationPromotion

/*!
 NdGetAppPromotionList的回调
 @param error		错误码
 @param totalCount	推广软件总数
 @param promotingApps	推广的软件列表（存放NdAppPromotion*）
 */
- (void)NdGetAppPromotionListDidFinish:(NSError*)error  totalCount:(int)totalCount promotingApps:(NSArray*)promotingApps;


/*!
 NdStartAppPromotion的回调
 @param error		错误码
 */
- (void)NdStartAppPromotionDidFinish:(NSError*)error;


/*!
 NdQueryAppPromotionAwardList的回调
 @param error		错误码
 @param awards		奖励信息（存放NdAppPromotionAward*）
 */
- (void)NdQueryAppPromotionAwardListDidFinish:(NSError *)error  awards:(NSArray*)awards;


/*!
 NdReachAppPromotionAwardCondition的回调
 @param error		错误码
 */
- (void)NdReachAppPromotionAwardConditionDidFinish:(NSError*)error;

@end