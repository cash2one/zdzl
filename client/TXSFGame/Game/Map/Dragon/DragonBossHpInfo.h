//
//  DragonBossHpInfo.h
//  TXSFGame
//
//  Created by efun on 13-9-9.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "GameDefine.h"

/*
 *	狩龙Boss血条信息
 */

@interface DragonBossHpInfo : CCSprite
{
	CGPoint bossHpPoint;
	
	// 天舟相关耐久度
	CCSprite *bossScrollBg;
	CCSprite *bossScrollBg1;
	CCSprite *bossScrollBg2;
	CCSprite *bossScrollBg3;
}

@end
