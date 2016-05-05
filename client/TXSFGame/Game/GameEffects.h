//
//  GameEffects.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-8.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"
#import "cocos2d.h"
#import "Task.h"

@interface GameEffects : NSObject{
	id target;
	SEL call;
	EffectsAction targetEffectId;
	id otherMessage;
	BOOL isEndEffects;
	int taskId;
	int taskStep;
}
@property(nonatomic,readonly) EffectsAction targetEffectId;
@property(nonatomic,assign)int taskId;
@property(nonatomic,assign)int taskStep;
@property(nonatomic,assign)id  otherMessage;

+(GameEffects*)share;
+(void)stopAll;

+(BOOL)checkIsEffects;

+(void)remove;
+(void)removeOtherEffect;
+(BOOL)isShowEffect:(int)_tid taskStep:(int)_step;

-(void)showEffects:(EffectsAction)eid target:(id)t call:(SEL)c;
-(void)showEffectsWithDict:(NSDictionary*)dict target:(id)t call:(SEL)c;

-(void)showEffectsWithDict:(NSDictionary*)dict target:(id)t call:(SEL)c taskId:(int)_tid taskStep:(int)_step;


@end

@interface GameEffectsBlockTouck : CCLayer{
	id  target;
	SEL call;
}

@property(nonatomic,assign)id target;
@property(nonatomic,assign)SEL call;

+(void)lockScreen;
+(void)unlockScreen;

+(void)lockScreen:(id)_target call:(SEL)_call;

@end
//
//@interface CCTransitionEffects: CCRenderTexture
//+(void)lockScreen;
//+(void)unlockScreen;
//@end
