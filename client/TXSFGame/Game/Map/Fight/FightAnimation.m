//
//  FightAnimation.m
//  TXSFGame
//
//  Created by TigerLeung on 12-12-4.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "FightAnimation.h"
#import "CCLabelFX.h"
#import "FightPlayer.h"

#define FIGHT_ANIMATION_TIME ([FightPlayer checkTime:(1/12.0f)])
#define FIGHT_ANIMATION_DELAY ([FightPlayer checkTime:(0.5f)])

//static NSMutableArray * fightAnimationMemory;
//static void addFightAnimationDataToMemory(id target){
//	if(!fightAnimationMemory){
//		fightAnimationMemory = [[NSMutableArray alloc] init];
//	}
//	[fightAnimationMemory addObject:target];
//}
//
//static void removeFightAnimationDataFromMemory(id target){
//	if(fightAnimationMemory!=nil && target!=nil){
//		[fightAnimationMemory removeObject:target];
//	}
//}

@implementation FightAnimation

@synthesize dir;
@synthesize isShowStand;

//+(void)checkMemoryUnshowStand{
//	if(fightAnimationMemory){
//		for(FightAnimation * fa in fightAnimationMemory){
//			[fa unshowAnimationStand];
//		}
//	}
//}

-(void)dealloc{
	
	/*
	if(standAction){
		[standAction release];
		standAction = nil;
	}
	*/
	
	if(isEffect){
		CCLOG(@"FightAnimation dealloc %d ",self.retainCount);
	}
	
	[super dealloc];
	
}

-(void)onEnter{
	//addFightAnimationDataToMemory(self);
	[super onEnter];
	
	[self schedule:@selector(updateStand) interval:FIGHT_ANIMATION_TIME];
}
-(void)onExit{
	
	//removeFightAnimationDataFromMemory(self);
	[self removeCallEnd];
	[self stopAllActions];
	
	/*
	if(standAction){
		[standAction release];
		standAction = nil;
	}
	*/
	
	if(standFrames){
		[standFrames release];
		standFrames = nil;
	}
	
	if(isEffect){
		CCLOG(@"FightAnimation onExit %d ",self.retainCount);
	}
	
	[super onExit];
	
}

-(void)remove{
	[self removeCallEnd];
	[super remove];
}

-(void)addCall:(id)call end:(id)end{
	if(call){
		targetCall = call;
		[targetCall retain];
	}
	if(end){
		targetEnd = end;
		[targetEnd retain];
	}
}
-(void)removeCallEnd{
	if(targetCall){
		[targetCall release];
		targetCall = nil;
	}
	if(targetEnd){
		[targetEnd release];
		targetEnd = nil;
	}
}

////////////////////////////////////////////////////////////////////////////////

-(BOOL)chkeckHasAnimation:(NSString*)name bySuit:(int)suit{
	
	if(suit<=0) return NO;
	
	NSString * path = [NSString stringWithFormat:@"images/fight/ani/%@_%d/%d/battle-stand/%@",name,suit,dir,@"%d.png"];
	if([AnimationViewer checkHasAnimation:path]){
		return YES;
	}
	return NO;
}

-(void)updateStand{
	if(isShowStand && standFrames){
		if([standFrames count]>0){
			[self setDisplayFrame:[standFrames objectAtIndex:standFrameIndex]];
			standFrameIndex++;
			if(standFrameIndex>=[standFrames count]){
				standFrameIndex = 0;
			}
		}
	}
}

-(void)unshowAnimationStand{
	
	//if(isShowStand) return;
	isShowStand = NO;
	//[self stopAllActions];
	
	/*
	if(standAction){
		
		[self stopAction:standAction];
		[standAction release];
		standAction = nil;
		
		//[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
		//[[CCTextureCache sharedTextureCache] removeUnusedTextures];
		
	}
	*/
	
	if(standFrames){
		[standFrames release];
		standFrames = nil;
	}
	
}

-(void)showAnimationStandByName:(NSString*)name{
	
	isShowStand = YES;
	
	if(standFrames==nil){
		NSString * path = [NSString stringWithFormat:@"images/fight/ani/%@/%d/battle-stand/",name,dir];
		standFrames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
		[standFrames retain];
		if([standFrames count]>0){
			[self setDisplayFrame:[standFrames objectAtIndex:0]];
		}
	}
	
	/*
	if(!standAction){
		
		NSString * path = [NSString stringWithFormat:@"images/fight/ani/%@/%d/battle-stand/",name,dir];
		standFrames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
		[standFrames retain];
		if([standFrames count]>0){
			[self setDisplayFrame:[standFrames objectAtIndex:0]];
		}
		
		CCAnimation * animation = [CCAnimation animationWithSpriteFrames:standFrames delay:FIGHT_ANIMATION_TIME];
		CCAnimate * animate = [CCAnimate actionWithAnimation:animation];
		
		standAction = [CCRepeatForever actionWithAction:animate];
		[standAction retain];
		
	}
	*/
	
	//[self stopAllActions];
	//[self runAction:standAction];
	
}

-(void)showAnimationFightByName:(NSString*)name call:(id)call end:(id)end{
	
	isShowStand = NO;
	//[self unshowAnimationStand];
	
	NSString * path = [NSString stringWithFormat:@"images/fight/ani/%@/%d/battle-attack/%@",name,dir,@"%d.png"];
	[self addCall:call end:end];
	[self showAnimationByPath:path];
	
}

-(void)showAnimationSkillByName:(NSString*)name call:(id)call end:(id)end{
	
	isShowStand = NO;
	//[self unshowAnimationStand];
	
	NSString * path = [NSString stringWithFormat:@"images/fight/ani/%@/%d/battle-attackex/%@",name,dir,@"%d.png"];
	
	if(![AnimationViewer checkHasAnimation:path]){
		path = [NSString stringWithFormat:@"images/fight/ani/%@/%d/battle-attack/%@",name,dir,@"%d.png"];
	}
	
	[self addCall:call end:end];
	[self showAnimationByPath:path];
	
}

-(void)showAnimationBokByName:(NSString*)name call:(id)call end:(id)end{
	
	isShowStand = NO;
	//[self unshowAnimationStand];
	
	NSString * path = [NSString stringWithFormat:@"images/fight/ani/%@/%d/battle-block/%@",name,dir,@"%d.png"];
	[self addCall:call end:end];
	[self showAnimationByPath:path];
	
}
-(void)showAnimationHurtByName:(NSString*)name call:(id)call end:(id)end{
	
	isShowStand = NO;
	//[self unshowAnimationStand];
	
	NSString * path = [NSString stringWithFormat:@"images/fight/ani/%@/%d/battle-gethit/%@",name,dir,@"%d.png"];
	[self addCall:call end:end];
	[self showAnimationByPath:path];
	
}

-(void)playAnimation:(NSArray*)ary{
	
	if(!ary) return;
	if([ary count]<=1){
		
		if([ary count]>0){
			[self setDisplayFrame:[ary objectAtIndex:0]];
		}
		
		NSMutableArray * actions = [NSMutableArray array];
		[actions addObject:[CCDelayTime actionWithDuration:FIGHT_ANIMATION_DELAY]];
		if(targetCall) [actions addObject:targetCall];
		if(targetEnd) [actions addObject:targetEnd];
		
		[self stopAllActions];
		[self runAction:[CCSequence actionWithArray:actions]];
		
		[self removeCallEnd];
		
		return;
	}
	
	NSMutableArray * actions = [NSMutableArray array];
	
	int count = [ary count];
	int center = count/2;
	if(center<=0) center = 1;
	
	NSRange r1 = NSMakeRange(0,center);
	NSRange r2 = NSMakeRange(center,count-center);
	
	NSArray * ary1 = [ary objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:r1]];
	NSArray * ary2 = [ary objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:r2]];
	
	CCAnimation * animation1 = [CCAnimation animationWithSpriteFrames:ary1 delay:FIGHT_ANIMATION_TIME];
	CCAnimate * animate1 = [CCAnimate actionWithAnimation:animation1];
	CCAnimation * animation2 = [CCAnimation animationWithSpriteFrames:ary2 delay:FIGHT_ANIMATION_TIME];
	CCAnimate * animate2 = [CCAnimate actionWithAnimation:animation2];
	
	[actions addObject:animate1];
	if(targetCall) [actions addObject:targetCall];
	[actions addObject:animate2];
	if(targetEnd) [actions addObject:targetEnd];
	
	[self stopAllActions];
	[self runAction:[CCSequence actionWithArray:actions]];
	
	[self removeCallEnd];
}

//==============================================================================
#pragma mark-
//==============================================================================

-(void)showCut:(int)cut delay:(float)delay{
	
	NSString * str = [NSString stringWithFormat:@"%@%d",(cut>=0?@"/":@"."),abs(cut)];
	NSString * png = (cut>=0?@"images/fonts/number_add.png":@"images/fonts/number_cut.png");
	
	CCLabelAtlas * label = [CCLabelAtlas labelWithString:str
											   charMapFile:png
												 itemWidth:cFixedScale(32)
												itemHeight:cFixedScale(49)
											  startCharMap:'.'];
	label.anchorPoint = ccp(0.5f,0.0f);
	label.visible = NO;
	
	self.scale = 0;
	
	if(iPhoneRuningOnGame()){
		label.scale = 0.75;
	}
	[self addChild:label z:0 tag:123];
	
	if(delay>0){
		[self scheduleOnce:@selector(doShowCut) delay:delay];
	}else{
		[self doShowCut];
	}
	
}

-(void)doShowCut{
	
	CCNode * node = [self getChildByTag:123];
	if(node){
		
		node.visible = YES;
		
		/*
		CGPoint pos = ccp(0,50);
		if(iPhoneRuningOnGame()){
			pos = ccp(0,25);
		}
		id move = [CCMoveTo actionWithDuration:0.2f position:ccpAdd(self.position,pos)];
		id time = [CCDelayTime actionWithDuration:0.3f];
		id call = [CCCallFunc actionWithTarget:self selector:@selector(remove)];
		[self runAction:[CCSequence actions: move, time, call, nil]];
		
		id time1 = [CCDelayTime actionWithDuration:0.2f];
		id fade = [CCFadeTo actionWithDuration:0.3 opacity:0];
		[node runAction:[CCSequence actions: time1, fade, nil]];
		*/
		
		id scale = [CCScaleTo actionWithDuration:[FightPlayer checkTime:0.2f] scale:1.0f];
		id time = [CCDelayTime actionWithDuration:[FightPlayer checkTime:0.3f]];
		id call = [CCCallFunc actionWithTarget:self selector:@selector(remove)];
		[self runAction:[CCSequence actions: scale, time, call, nil]];
		
		id time1 = [CCDelayTime actionWithDuration:[FightPlayer checkTime:0.2f]];
		id fade = [CCFadeTo actionWithDuration:[FightPlayer checkTime:0.3f] opacity:0];
		[node runAction:[CCSequence actions: time1, fade, nil]];
		
	}
	
}

-(void)showActionEffect:(NSString*)path end:(id)end{
	
	CCSprite * image = [CCSprite spriteWithFile:path];
	image.anchorPoint = ccp(0.5,0.0);
	[self addChild:image];
	
	CGPoint pos = ccp(0,50);
	if(iPhoneRuningOnGame()){
		pos = ccp(0,25);
	}
	
	id move = [CCMoveTo actionWithDuration:[FightPlayer checkTime:0.2f] position:ccpAdd(self.position,pos)];
	id time = [CCDelayTime actionWithDuration:[FightPlayer checkTime:0.3f]];
	id call = [CCCallFunc actionWithTarget:self selector:@selector(remove)];
	
	if(end){
		[self runAction:[CCSequence actions: move, time, call, end, nil]];
	}else{
		[self runAction:[CCSequence actions: move, time, call, nil]];
	}
	
	id time1 = [CCDelayTime actionWithDuration:[FightPlayer checkTime:0.2f]];
	id fade = [CCFadeTo actionWithDuration:[FightPlayer checkTime:0.3f] opacity:0.0f];
	[image runAction:[CCSequence actions: time1, fade, nil]];
	
}

-(void)showActionEffect:(NSString*)path{
	[self showActionEffect:path end:nil];
}

-(void)showEffect:(NSString*)path{
	
	isEffect = YES;
	
	id end = [CCCallFunc actionWithTarget:self selector:@selector(remove)];
	[self addCall:nil end:end];
	[self showAnimationByPath:path];
	
}

-(void)showEffect:(NSString*)path call:(id)call{
	id end = [CCCallFunc actionWithTarget:self selector:@selector(remove)];
	[self addCall:call end:end];
	[self showAnimationByPath:path];
}

-(void)showEffectForever:(NSString*)path{
	[super showAnimationByPathForever:path];
}

-(void)updateSpeed{
	
	if(isShowStand){
		
		//[self stopAction:standAction];
		[self unschedule:@selector(updateStand)];
		[self schedule:@selector(updateStand) interval:FIGHT_ANIMATION_TIME];
		
	}
	
}

@end
