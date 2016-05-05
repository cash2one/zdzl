//
//  AnimationRole.h
//  TXSFGame
//
//  Created by chao chen on 12-10-26.
//  Copyright (c) 2012 eGame. All rights reserved.
//

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Config.h"
#import "AnimationViewer.h"

@class GameLoaderHelper;
@interface AnimationRole:AnimationViewer{
	
	RoleAction roleAction;
	
	RoleDir	roleDir;
	
	//NSString * roleName;
	int roleId;
	int suitId;
	
	int runIndex;
	NSMutableArray * runFrames;
	
	BOOL isHasRole;
	GameLoaderHelper * helper;
	
}
@property(nonatomic,assign) RoleDir roleDir;
@property(nonatomic,assign) RoleAction roleAction;
@property(nonatomic,assign) int roleId;
@property(nonatomic,assign) int suitId;
@property(nonatomic,assign) BOOL OnCar;

-(void)showRole;

-(void)showStand;
-(void)showRuning;

-(void)showSit;
-(void)showSuit:(int)sid;

-(void)removeBase;

@end
