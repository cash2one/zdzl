//
//  TBPlatformAPIResponse.h
//  TBPlatform
//
//  Created by OXH on 13-4-23.
//
//

#import <Foundation/Foundation.h>

/**
 *	@brief	登录状态
 */
typedef enum _TB_LOGIN_STATE
 {
	TB_LOGIN_STATE_NOT_LOGIN = 0,  	//未登录		
	TB_LOGIN_STATE_NORMAL_LOGIN,     //普通帐号登陆
}TB_LOGIN_STATE;



#pragma mark - TBPlatformUserInfo

/**
 *	@brief	我的基础信息
 */
@interface TBPlatformUserInfo : NSObject
@property (nonatomic, copy) NSString *sessionID;						// 登录会话id,用于登录验证
@property (nonatomic, copy) NSString *userID;                           // 用户id
@property (nonatomic, copy) NSString *nickName;                         // 用户昵称
@end


