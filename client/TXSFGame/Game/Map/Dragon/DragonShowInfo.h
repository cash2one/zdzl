//
//  DragonShowInfo.h
//  TXSFGame
//
//  Created by efun on 13-9-23.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"

/*
 *	狩龙信息显示，比如xx炮击了xx
 */

@interface DragonShowInfo : CCLayer
{
	BOOL _isShowNow;
	NSMutableArray *_infoArray;
}

@end
