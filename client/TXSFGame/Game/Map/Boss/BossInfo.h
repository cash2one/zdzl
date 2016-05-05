//
//  BossInfo.h
//  TXSFGame
//
//  Created by Soul on 13-3-28.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum{
	BossInfoType_none = 0 ,
	BossInfoType_world = 1 ,
	BossInfoType_union = 2 ,
}BossInfoType;

@class CCLabelFX;

@interface BossInfo : CCSprite {
	int					_bossId;
	float				_maxHp;
	float				_curHp;
	
	CCLabelFX*			_name;
	CCLabelFX*			_blood;
	CCLabelFX*			_time;
	
	int					_hurt;
	
	float				_iconWidth;
	float				_iconHeight;
	
	BossInfoType		_bossInfoType;
	
}

@property(nonatomic,assign)BossInfoType bossInfoType;
@property(nonatomic,assign)int			bossId;
@property(nonatomic,assign)float		maxHp;
@property(nonatomic,assign)float		curHp;

@property(nonatomic,assign)int			totalHp;
@property(nonatomic,assign)int			nowHp;
@property(nonatomic,assign)int			targetHp;

@property(nonatomic,assign)int			hurt;


+(BossInfo*)create:(BossInfoType)_bossInfoType;

-(void)updateBloodVolume:(float)_value;


@end
