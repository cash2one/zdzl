//
//  MessageAlert.h
//  TXSFGame
//
//  Created by huang shoujun on 13-1-7.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameAlert.h"

typedef enum{
	MessageAlert_none=10,
	MessageAlert_ok,
	MessageAlert_no,
	MessageAlert_all,
	MessageAlert_setting,
	MessageAlert_error,
}MessageAlert_type;

@interface MessageAlert : GameAlert<CCTouchOneByOneDelegate> {
    SEL canel_;
	NSString *message;
	float delay_;
	MessageAlert_type type;
	
	BOOL bRecord;
	NSString* recordKey;
	NSString* recordTips;
	
	BOOL	_isUrgent;
}
@property(nonatomic,assign)BOOL	 isUrgent;
@property(nonatomic,assign)float delay;
@property(nonatomic,assign)SEL canel;
@property(nonatomic,retain)NSString *message;
@property(nonatomic,assign)MessageAlert_type type;
@property(nonatomic,retain)NSString *recordKey;
@property(nonatomic,retain)NSString *recordTips;
@end
