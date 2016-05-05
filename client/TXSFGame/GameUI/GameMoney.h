//
//  GameMoney.h
//  TXSFGame
//
//  Created by chao chen on 12-11-16.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCLabelFX.h"

typedef enum{
	GAMEMONEY_YIBI			= 1,//银币
	GAMEMONEY_YUANBAO_ONE	= 2,//元宝1
	GAMEMONEY_YUANBAO_TWO	= 3,//绑元宝2
	GAMEMONEY_EXP			= 4,//经验
	GAMEMONEY_SIT_EXP		= 5,//打坐经验
	GAMEMONEY_TRAIN			= 6,//练历
}GameMoneyType;

static NSString * getImagePath(GameMoneyType type){
	if(type==GAMEMONEY_YIBI)		return @"images/ui/object-icon/1.png";
	if(type==GAMEMONEY_YUANBAO_ONE)	return @"images/ui/object-icon/2.png";
	if(type==GAMEMONEY_YUANBAO_TWO)	return @"images/ui/object-icon/3.png";
	if(type==GAMEMONEY_EXP)			return @"images/ui/object-icon/4.png";
	if(type==GAMEMONEY_SIT_EXP)		return @"images/ui/object-icon/5.png";
	if(type==GAMEMONEY_TRAIN)		return @"images/ui/object-icon/6.png";
	return @"images/ui/object-icon/1.png";
}

@interface GameMoney : CCSprite
{
  	GameMoneyType type;//种类
	CCSprite *sprite;//
	CCLabelFX *txt;//
	NSInteger moneyValue;//
}
@property (nonatomic,assign)GameMoneyType type;
@property (nonatomic,assign)NSInteger moneyValue;
+(GameMoney*)gameMoneyWithType:(GameMoneyType)_type value:(NSInteger)value;
+(GameMoney*)gameStringWithType:(GameMoneyType)_type value:(NSInteger)value;
-(void)setMoneyValue:(NSInteger)value;
-(void)setMoneyValue:(GameMoneyType)_type :(NSInteger)value;
@end
