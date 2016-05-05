//
//  FightAnimation.h
//  TXSFGame
//
//  Created by TigerLeung on 12-12-4.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AnimationViewer.h"
#import "Config.h"

@interface FightAnimation : AnimationViewer{
	FightAnimation_DIR dir;
	
	BOOL isShowStand;
	
	//CCRepeatForever * standAction;
	NSArray * standFrames;
	int standFrameIndex;
	
	id targetCall;
	id targetEnd;
	
	BOOL isEffect;
	
}
@property(nonatomic,assign) FightAnimation_DIR dir;
@property(nonatomic,assign) BOOL isShowStand;

//+(void)checkMemoryUnshowStand;

-(BOOL)chkeckHasAnimation:(NSString*)name bySuit:(int)suit;

-(void)showAnimationStandByName:(NSString*)name;

-(void)showAnimationFightByName:(NSString*)name call:(id)call end:(id)end;
-(void)showAnimationSkillByName:(NSString*)name call:(id)call end:(id)end;
-(void)showAnimationBokByName:(NSString*)name call:(id)call end:(id)end;
-(void)showAnimationHurtByName:(NSString*)name call:(id)call end:(id)end;

-(void)showCut:(int)cut delay:(float)delay;

-(void)showActionEffect:(NSString*)path end:(id)end;
-(void)showActionEffect:(NSString*)path;

-(void)showEffect:(NSString*)path;
-(void)showEffect:(NSString*)path call:(id)call;
-(void)showEffectForever:(NSString*)path;


-(void)updateSpeed;

@end
