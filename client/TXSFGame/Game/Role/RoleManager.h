//
//  RoleManager.h
//  TXSFGame
//
//  Created by chao chen on 12-10-24.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

@class RolePlayer;
@class AnimationViewer;

@interface RoleManager : NSObject{
	NSMutableArray * players;
	BOOL otherVisible;
	
	int maxPlayerCount;
}

@property(nonatomic,assign) RolePlayer * player;
@property(nonatomic,assign) int maxPlayerCount;

+(RoleManager*)shared;
+(void)stopAll;
+(void)reloadPlayers;

-(void)loadPlayer;

-(void)movePlayerToStartPoint;
-(void)movePlayerTo:(CGPoint)point;
-(void)movePlayerTo:(CGPoint)point target:(id)target call:(SEL)call;
-(void)stopMovePlayer;

-(BOOL)playerIsOnPoint:(CGPoint)point;

-(void)clearAllPlayer;


-(BOOL)isOtherPlayerVisible;
-(void)loadOtherPlayers;
-(void)otherPlayerVisible:(BOOL)visible;

-(CGPoint)getFreePoint:(NSArray*)array;

-(float)getPointDistanceWithPlayer:(CGPoint)_pt;
////////////////////////////////////////////////////////////////////////////////
-(void)playerSit;
-(AnimationViewer*)getMyImages:(bool)ShowCar;
@end
