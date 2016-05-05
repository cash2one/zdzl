//
//  RolePlayer.h
//  TXSFGame
//
//  Created by chao chen on 12-10-16.
//  Copyright (c) 2012 eGame. All rights reserved.
//

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Config.h"
#import "Car.h"

@class MapManager;
@class ActionMove;
@class AnimationRole;
@class AnimationViewer;
@class CarViewerContent;

@interface RolePlayer : CCSprite<CCTouchOneByOneDelegate>{
	
	int player_id;
	int role_id;
	int suit_id;
	int car_id;
	int level;
	int offset;
    int quality;
	int inskyhigh;
	
	BOOL isShow;
	
	Player_state state;
	NSString * name;
	CCSprite * nameLabel;
	
	AnimationRole * viewer;
	ActionMove * actionMove;
	
	CCSprite * shadowSpr;
	CCSprite * loading;
	
	AnimationViewer * sitEffect1;
	AnimationViewer * sitEffect2;
	
	CarViewerContent *cvc;
	
	id target;
	SEL moveEndCall;
	
	CGPoint targetPoint;
	
	BOOL		_isSelected;
	
	CCNode * followTarget;
	CCSprite * mapPointer;
	
}
@property(nonatomic,assign) int quality;
@property(nonatomic,assign) int player_id;
@property(nonatomic,assign) int role_id;
@property(nonatomic,assign) int suit_id;
@property(nonatomic,assign) int car_id;
@property(nonatomic,assign) int level;
@property(nonatomic,assign) Player_state state;
@property(nonatomic,retain) NSString * name;
@property(nonatomic,retain) NSString * allyName;

@property(nonatomic,assign) ActionMove * actionMove;
@property(nonatomic,assign) RoleDir roleDir;

@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL moveEndCall;

@property(nonatomic,assign) CGPoint targetPoint;

@property(nonatomic,assign) BOOL isShow;

@property(nonatomic,assign) BOOL isSelected;

@property(nonatomic,assign) CCNode * followTarget;

+(void)reset;

-(void)start;
-(void)startDelay:(float)time;

-(void)showPlayer;
-(void)hidePlayer;

//-(void)updateDir:(int)dir;
-(void)updateViewer;
-(void)updateSuit:(int)suitId;
-(void)updateCar:(int)carId;

////移动到
//-(void)moveToStartPoint;
-(void)moveTo:(CGPoint)pos;
-(void)moveTo:(CGPoint)pos target:(id)t call:(SEL)c;

-(void)stopMove;
-(void)stopMoveAndTask;
-(void)moveEnd;

-(void)updateDir:(CGPoint)_target;
-(CGSize)getRolePlayerSize;

//更新套装
-(void)updateSuit;
-(void)updateCar:(int)carId;

-(BOOL)isCanRun;
-(BOOL)isRunning;

-(void)showTaskStatus:(BOOL)isStart;
//-------------------------------------
-(void)startLoading:(NSString*)_string;
-(void)closeLoading;
//-------------------------------------
-(void)showUplevel;
//-------------------------------------
-(void)showEffect:(int)_eid target:(id)_target call:(SEL)_call;

-(void)checkFollowTarget:(CCNode*)followed;

/*
 * 因为移动结束一般都带有回调
 * 所以做一个判断是不是准备移动结束的方法，阻止移动回调的错误
 */
-(BOOL)isPrepareMoveEnd;

@end
