//
//  AnimationViewer.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-10-31.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "AnimationViewer.h"
#import "Config.h"
#import "NSString+MD5Addition.h"

#define animation_frame_delay 1/8.0f

static int helper_tag = 0;
static int getHelperTag(){
	helper_tag += 1;
	if(helper_tag>INT16_MAX){
		helper_tag = 1;
	}
	return helper_tag;
}

static NSMutableArray * helpers;

static void removeHelp(AnimationHelper * help){
	if(!helpers) return;
	[helpers removeObject:help];
}
static void removeHelpByTarget(id target){
	if(!helpers) return;
	for(AnimationHelper * help in helpers){
		if(help.target==target){
			help.target = nil;
			break;
		}
	}
}

@implementation AnimationHelper
@synthesize tag;
@synthesize target;
@synthesize result;

+(AnimationHelper*)loadFileByFileFullPath:(NSString*)filePath name:(NSString*)name target:(id)target result:(SEL)result{
	NSString * path = [NSString stringWithFormat:@"%@%@",filePath,name];
	return [AnimationHelper loadFileByFileFullPath:path target:target result:result];
}
+(AnimationHelper*)loadFileByFileFullPath:(NSString*)filePath target:(id)target result:(SEL)result{
	AnimationHelper * helper = [[[AnimationHelper alloc] init] autorelease];
	helper.tag = getHelperTag();
	helper.target = target;
	helper.result = result;
	[helper loadFileByFileFullPath:filePath];
	
	if(!helpers){
		helpers = [[NSMutableArray alloc] init];
	}
	[helpers addObject:helper];
	
	return helper;
}

-(void)setTarget:(id)_target{
	if(target) [target release];
	target = _target;
	if(target) [target retain];
}

-(void)loadFileByFileFullPath:(NSString*)filePath{
	
	[self removeFrames];
	
	frames = [NSMutableArray array];
	[frames retain];
	
	for(int i=0;i<INT16_MAX;i++){
		
		NSString * tPath = [NSString stringWithFormat:filePath,i];
		//NSString * cache = [tPath stringFromMD5];
		NSString * cache = tPath;
		
		CCSpriteFrame * frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:cache];
		if(frame){
			[frames addObject:frame];
			continue;
		}else{
			
			if(checkHasFile([[CCFileUtils sharedFileUtils] fullPathFromRelativePath:tPath])){
				[[CCTextureCache sharedTextureCache] addImageAsync:tPath withBlock:^(CCTexture2D*texture){
					
					CCSpriteFrame * frame = [CCSpriteFrame frameWithTexture:texture rect:
											 CGRectMake(0,0,texture.contentSize.width,texture.contentSize.height)];
					
					[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:cache];
					
					[frames addObject:frame];
					
					[self checkComplete];
					
				}];
			}else{
				max_count = i;
				[self checkComplete];
				if(isComplete) return;
				break;
			}
			
		}
		
	}
}

-(void)checkComplete{
	if([frames count]==max_count){
		isComplete = YES;
		if(target!=nil && result!=nil){
			[target performSelector:result withObject:[NSArray arrayWithArray:frames]];
			[target release];
			target = nil;
			result = nil;
		}
		[self removeFrames];
		removeHelp(self);
	}
}

-(void)removeFrames{
	if(frames){
		[frames removeAllObjects];
		[frames release];
		frames = nil;
	}
}

-(void)dealloc{
	//CCLOG(@"AnimationHelper tag->%d dealloc",tag);
	[self removeFrames];
	[super dealloc];
}

@end

#pragma mark -

@implementation AnimationViewer

@synthesize target;
@synthesize removeCall;

-(void)onExit{
	[self checkRemoveHelp];
	[super onExit];
}
-(void)dealloc{
	
	[self checkRemoveHelp];
	
	[super dealloc];
	
	//TODO
	//[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
	//[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	
}

-(void)checkRemoveHelp{
	if(help){
		removeHelpByTarget(self);
		help = nil;
	}
}

-(void)remove{
	
	[self checkRemoveHelp];
	
	if(target!=nil&&removeCall!=nil){
		[target performSelector:removeCall withObject:self];
	}
	[self removeFromParentAndCleanup:YES];
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

+(BOOL)checkHasAnimation:(NSString*)filePath{
	for(int i=0;i<1;i++){
		NSString * tPath = [NSString stringWithFormat:filePath,i];
		//NSString * cache = [tPath stringFromMD5];
		NSString * cache = tPath;
		
		CCSpriteFrame * frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:cache];
		if(frame) return YES;
		
		if(checkHasFile([[CCFileUtils sharedFileUtils] fullPathFromRelativePath:tPath])){
			return YES;
		}else{
			return NO;
		}
	}
	return NO;
}

+(NSArray*)loadFileByFileFullPath:(NSString*)filePath name:(NSString*)name{
	
	NSString * path = [NSString stringWithFormat:@"%@",filePath];
	NSMutableArray * result = [NSMutableArray array];
	
	for(int i=0;i<INT16_MAX;i++){
		
		NSString * _name = [NSString stringWithFormat:name,i];
		NSString * tPath = [NSString stringWithFormat:@"%@%@",path,_name];
		//NSString * cache = [tPath stringFromMD5];
		NSString * cache = tPath;
		
		CCSpriteFrame * frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:cache];
		
		if(frame){
			[result addObject:frame];
		}else{
			if(checkHasFile([[CCFileUtils sharedFileUtils] fullPathFromRelativePath:tPath])){
				CCTexture2D * texture = [[CCTextureCache sharedTextureCache] addImage:tPath];
				frame = [CCSpriteFrame frameWithTexture:texture rect:
						 CGRectMake(0,0,texture.contentSize.width,texture.contentSize.height)];
				[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFrame:frame name:cache];
				[result addObject:frame];
			}else{
				break;
			}
		}
	}
	
	return result;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void)showAnimationByPath:(NSString*)filePath{
	[self checkRemoveHelp];
	help = [AnimationHelper loadFileByFileFullPath:filePath target:self result:@selector(didLoadAnimation:)];
}
-(void)didLoadAnimation:(NSArray*)frames{
	help = nil;
	[self playAnimation:frames];
}

-(void)showAnimationByPathForever:(NSString*)filePath{
	[self checkRemoveHelp];
	help = [AnimationHelper loadFileByFileFullPath:filePath target:self result:@selector(didLoadAnimationForever:)];
}
-(void)didLoadAnimationForever:(NSArray*)frames{
	help = nil;
	if([frames count]>0){
		[self playAnimation:frames delay:animation_frame_delay];
	}
}


-(void)showAnimationByPathOne:(NSString*)filePath{
	[self checkRemoveHelp];
	help = [AnimationHelper loadFileByFileFullPath:filePath target:self result:@selector(didLoadAnimationOne:)];
}
-(void)didLoadAnimationOne:(NSArray*)frames{
	help = nil;
	if([frames count]>0){
		[self playAnimationAndClean:frames];
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void)playAnimation:(NSArray*)ary{
	if([ary count]>0){
		[self playAnimation:ary delay:animation_frame_delay];
	}
}
-(void)playAnimation:(NSArray*)ary call:(id)call{
	if([ary count]>0){
		[self playAnimation:ary delay:animation_frame_delay call:call];
	}
}

-(void)playAnimation:(NSArray*)ary delay:(float)delay{
	
	if(!ary) return;
	if([ary count]==0) return;
	
	[self stopAllActions];
	[self setDisplayFrame:[ary objectAtIndex:0]];
	if([ary count]>1){
		CCAnimation * animation = [CCAnimation animationWithSpriteFrames:ary delay:delay];
		CCAnimate * animate = [CCAnimate actionWithAnimation:animation];
		CCSequence * seq = [CCSequence actions:animate, nil];
		[self runAction:[CCRepeatForever actionWithAction:seq]];
	}
	
}

-(void)playAnimation:(NSArray*)ary delay:(float)delay call:(id)call{
	if(!ary) return;
	if([ary count]==0) return;
	
	[self setDisplayFrame:[ary objectAtIndex:0]];
	
	[self stopAllActions];
	if([ary count]>1){
		CCAnimation * animation = [CCAnimation animationWithSpriteFrames:ary delay:delay];
		CCAnimate * animate = [CCAnimate actionWithAnimation:animation];
		CCSequence * seq;
		if(call){
			seq = [CCSequence actions:animate, call, nil];
		}else{
			seq = [CCSequence actions:animate, nil];
		}
		[self runAction:seq];
	}
	
}

-(void)playAnimationAndClean:(NSArray*)ary{
    if(!ary) return;
	if([ary count]==0) return;
	
	[self setDisplayFrame:[ary objectAtIndex:0]];
	
	[self stopAllActions];
	if([ary count]>1){
		CCAnimation * animation = [CCAnimation animationWithSpriteFrames:ary delay:0.08];
		CCAnimate * animate = [CCAnimate actionWithAnimation:animation];
        CCCallBlock *bfun=[CCCallBlock actionWithBlock:^{
            [self removeFromParentAndCleanup:true];
        }];
       CCSequence * seq = [CCSequence actions:animate, bfun, nil];
		
		[self runAction:seq];
	}
}



@end
