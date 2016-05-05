//
//  AnimationMonster.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-20.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Config.h"
#import "AnimationViewer.h"

@class GameLoaderHelper;
@interface AnimationMonster : AnimationViewer{
	int targetId;
	MONSTER_TYPE targetType;
	RoleDir monster_dir;
	
	NSArray * f1;
	NSArray * f2;
	
	NSString* aniName;
	
	GameLoaderHelper * helper;
	
}
@property(nonatomic,retain) NSString* aniName;
@property(nonatomic,assign) RoleDir monster_dir;

-(void)showAnimationByMonsterId:(int)monsterId type:(MONSTER_TYPE)type;
-(void)loadMonsterAnimation;

@end
