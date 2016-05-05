//
//  DragonBookInfo.h
//  TXSFGame
//
//  Created by efun on 13-9-9.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "GameDefine.h"

/*
 *	狩龙天书信息
 */

@interface DragonBookInfo : CCSprite
{
	DragonTime _dragonTime;
	NSMutableArray *_bookArray;
}
@property (nonatomic, assign) DragonTime dragonTime;

+(DragonBookInfo*)create:(DragonTime*)_time;

@end
