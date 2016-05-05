//
//  DragonTips.h
//  TXSFGame
//
//  Created by efun on 13-9-13.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"

@interface DragonTips : CCLayer
{
	BOOL isStart;
}
@property (nonatomic, assign) BOOL isStart;
@property (nonatomic, retain) CCLabelTTF *labelTime;

+(void)hide;
+(void)show:(BOOL)_isShow;
+(void)resetThisTimeClose;
+(void)updateStatus;

+(void)checkStatus;

@end
