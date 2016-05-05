//
//  AnimationMonster.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-20.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "AnimationMonster.h"
#import "GameFileUtils.h"
#import "GameResourceLoader.h"

@implementation AnimationMonster

@synthesize monster_dir;
@synthesize aniName;

-(void)onEnter{
	[super onEnter];
	
	monster_dir = RoleDir_down;
	
	self.anchorPoint = ccp(0.5,0);
}

-(void)onExit{
	
	if(helper){
		[helper free];
		helper = nil;
	}
	
	if(f1){
		[f1 release];
		f1 = nil;
	}
	if(f2){
		[f2 release];
		f2 = nil;
	}
	
	if (aniName) {
		[aniName release];
		aniName = nil;
	}
	
	[super onExit];
}

-(void)setMonster_dir:(RoleDir)dir{
	if(monster_dir==dir) return;
	monster_dir = dir;
	[self loadMonsterAnimation];
}

-(void)showAnimationByMonsterId:(int)monsterId type:(MONSTER_TYPE)type{
	
	targetId = monsterId;
	targetType = type;
	
	CCSprite * def = [CCSprite spriteWithFile:@"images/defaultViewer.png"];
	def.tag = 123;
	def.anchorPoint = ccp(0.5,0);
	def.position = ccp(0,-self.position.y);
	[self addChild:def];
	
	[self checkLoadMonster];
	
}

-(void)checkLoadMonster{
	
	if(helper){
		BOOL isError = helper.isError;
		helper = nil;
		if(isError){
			//return;
		}
	}
	
	NSString * name = nil;
	if (aniName) {
		name = [NSString stringWithFormat:@"%@",aniName];
	}else{
		name = [NSString stringWithFormat:@"m%d",targetId];
	}
	//[NSString stringWithFormat:@"m%d",targetId];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_map_monster target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		path = [NSString stringWithFormat:@"%@.%@",path,GAME_RESOURCE_DAT];
		
		helper = [GameLoaderHelper create:path isUnzip:YES];
		helper.type = PathType_map_monster;
		helper.target = self;
		helper.call = _cmd;
		
		[[GameResourceLoader shared] downloadHelper:helper];
		return;
	}
	
	[self removeChildByTag:123 cleanup:YES];
	
	if(targetType==MONSTER_TYPE_MONSTER){
		path = [NSString stringWithFormat:@"images/monsters/m%d/1/%@",targetId,@"%d.png"];
		[AnimationHelper loadFileByFileFullPath:path target:self result:@selector(didLoadAnimation1:)];
		
		path = [NSString stringWithFormat:@"images/monsters/m%d/2/%@",targetId,@"%d.png"];
		[AnimationHelper loadFileByFileFullPath:path target:self result:@selector(didLoadAnimation2:)];
	}else{
		
		path = [NSString stringWithFormat:@"images/monsters/m%d/3/%@",targetId,@"%d.png"];
		[AnimationHelper loadFileByFileFullPath:path target:self result:@selector(didLoadAnimation1:)];
		
	}
	
}

-(void)didLoadAnimation1:(NSArray*)ary{
	f1 = ary;
	[f1 retain];
	
	[self loadMonsterAnimation];
}
-(void)didLoadAnimation2:(NSArray*)ary{
	f2 = ary;
	[f2 retain];
	
	[self loadMonsterAnimation];
}

-(void)loadMonsterAnimation{
	
	if(targetType==MONSTER_TYPE_BOSS && f1){
		[self playAnimation:f1];
		return;
	}
	
	if(monster_dir==RoleDir_down && f1){
		[self stopAllActions];
		[self playAnimation:f1];
		return;
	}
	
	if(monster_dir==RoleDir_up && f2){
		[self stopAllActions];
		[self playAnimation:f2];
		return;
	}
	
}


@end
