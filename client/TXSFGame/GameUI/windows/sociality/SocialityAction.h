//
//  SocialityAction.h
//  TXSFGame
//
//  Created by Soul on 13-3-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

#define SocialityActionTop			cFixedScale(5)
#define SocialityActionBottom	           	cFixedScale(5)
#define SocialityActionSize		CGSizeMake(iPhoneRuningOnGame()?52:94, iPhoneRuningOnGame()?20:33)

typedef enum{
	Sociality_no			= 0 ,
	Sociality_speak			= 1 ,
	Sociality_add_friend	= 2 ,
	Sociality_copy_name		= 3 ,
	Sociality_check_info	= 4 ,
	Sociality_black_list	= 5 ,
	Sociality_delete_friend = 6 ,
	Sociality_delete_blacklist	= 7,
}Sociality_action;

static inline NSString* actionToString(Sociality_action _act){
//	if (_act == Sociality_speak) {
//		return [NSString stringWithFormat:@"私聊"];
//	}else if (_act == Sociality_add_friend){
//		return [NSString stringWithFormat:@"加为好友"];
//	}else if (_act == Sociality_copy_name){
//		return [NSString stringWithFormat:@"复制名称"];
//	}else if (_act == Sociality_check_info){
//		return [NSString stringWithFormat:@"查看信息"];
//	}else if (_act == Sociality_black_list){
//		return [NSString stringWithFormat:@"移至黑名单"];
//	}else if (_act == Sociality_delete_friend){
//		return [NSString stringWithFormat:@"删除好友"];
//	}else if (_act == Sociality_delete_blacklist){
//		return [NSString stringWithFormat:@"删除黑名单"];
//	}
    if (_act == Sociality_speak) {
		return [NSString stringWithFormat:NSLocalizedString(@"sociality_action_private",nil)];
	}else if (_act == Sociality_add_friend){
		return [NSString stringWithFormat:NSLocalizedString(@"sociality_action_add_friend",nil)];
	}else if (_act == Sociality_copy_name){
		return [NSString stringWithFormat:NSLocalizedString(@"sociality_action_copy_name",nil)];
	}else if (_act == Sociality_check_info){
		return [NSString stringWithFormat:NSLocalizedString(@"sociality_action_check_info",nil)];
	}else if (_act == Sociality_black_list){
		return [NSString stringWithFormat:NSLocalizedString(@"sociality_action_black_list",nil)];
	}else if (_act == Sociality_delete_friend){
		return [NSString stringWithFormat:NSLocalizedString(@"sociality_action_del_friend",nil)];
	}else if (_act == Sociality_delete_blacklist){
		return [NSString stringWithFormat:NSLocalizedString(@"sociality_action_del_blacklist",nil)];
	}
	return nil;
}

@interface SocialityAction : CCLayer
{
	SocialityType _type;
}

@property (nonatomic) SocialityType type;
@property (nonatomic) int pid;
@property (nonatomic, retain) NSString *name;

@end
