//
//  DragonMapNameInfo.h
//  TXSFGame
//
//  Created by efun on 13-10-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "GameDefine.h"

/*
 *	地图名字，返回
 */

@interface DragonMapNameInfo : CCSprite
{
	DragonType _dragonType;
	DragonTime _dragonTime;
}
@property (nonatomic, assign) DragonType dragonType;
@property (nonatomic, assign) DragonTime dragonTime;

+(DragonMapNameInfo*)create:(DragonType)_type time:(DragonTime)_time;

@end
