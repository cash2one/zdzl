//
//  BossAction.h
//  TXSFGame
//
//  Created by Soul on 13-3-28.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef enum{
	
	BossAction_none			= 0 ,
	BossAction_wait			= 1 ,
	BossAction_fight		= 2 ,
	BossAction_fightCd		= 3 ,
	
}BossAction_type;

#define BossAction_start_fight	@"BossAction_start_fight"
#define BossAction_start_over_cd	@"BossAction_start_over_cd"

@interface BossAction : CCSprite {
    BossAction_type		_type;
	int					_stopTime;
}

@property(nonatomic,assign)BossAction_type	type;
@property(nonatomic,assign)int				stopTime;

@end
