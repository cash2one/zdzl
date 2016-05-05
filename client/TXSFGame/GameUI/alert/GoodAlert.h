//
//  GoodAlert.h
//  TXSFGame
//
//  Created by Soul on 13-7-30.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameAlert.h"

@interface GoodAlert : GameAlert<CCTouchOneByOneDelegate>{
	NSString *message;
	int goodId;
	int goodType;
	SEL canel;
	BOOL bRecord;
	NSString* recordKey;
	NSString* recordTips;
}
@property(nonatomic,assign)int goodId;
@property(nonatomic,assign)int goodType;
@property(nonatomic,assign)SEL canel;
@property(nonatomic,retain)NSString *message;
@property(nonatomic,retain)NSString *recordKey;
@property(nonatomic,retain)NSString *recordTips;

@end
