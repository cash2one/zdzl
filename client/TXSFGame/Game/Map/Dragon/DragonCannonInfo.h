//
//  DragonCannonInfo.h
//  TXSFGame
//
//  Created by efun on 13-9-9.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "GameDefine.h"

/*
 *	狩龙炮弹信息
 */

@interface DragonCannonInfo : CCSprite
{
	DragonType _dragonType;
	DragonTime _dragonTime;
	
	int exitTime;
	int maxCount;
	float fontSize;
	
	CGPoint fightPoint;
	CGPoint cannonPoint;
	CGPoint captainPoint;
	
	// 天舟相关耐久度
	CCLabelTTF *boatHpLabel;
	CCSprite *boatHpSprite;
	CCSprite *boatHpBg;
	CCSprite *boatScrollBg;
	CCSprite *boatScrollBg1;
	CCSprite *boatScrollBg2;
	CCSprite *boatScrollBg3;
}
@property (nonatomic, assign) DragonType dragonType;
@property (nonatomic, assign) DragonTime dragonTime;

+(DragonCannonInfo*)create:(DragonType)_type time:(DragonTime)_time;

@end
