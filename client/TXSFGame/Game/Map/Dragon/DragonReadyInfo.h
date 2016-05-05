//
//  DragonReadyInfo.h
//  TXSFGame
//
//  Created by efun on 13-10-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "GameDefine.h"

/*
 *	准备房间信息
 */

@class CCSimpleButton;

@interface DragonReadyInfo : CCSprite
{
	float fontSize;
	DragonType _dragonType;
	
	CCSimpleButton *_inviteButton;
}
@property (nonatomic, assign) DragonType dragonType;

+(DragonReadyInfo*)create:(DragonType)_type;

@end
