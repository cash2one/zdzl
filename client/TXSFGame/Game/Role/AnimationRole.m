//
//  AnimationRole.m
//  TXSFGame
//
//  Created by chao chen on 12-10-26.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "AnimationRole.h"
#import "AnimationViewer.h"

#import "GameResourceLoader.h"
#import "GameFileUtils.h"

static float frames_delay = 1/12.0f;

@implementation AnimationRole

@synthesize roleDir;
@synthesize roleAction;
@synthesize roleId;
@synthesize suitId;
@synthesize OnCar;

-(void)setScaleX:(float)scaleX{
	if(scaleX<0) [super setScaleX:-1];
	if(scaleX>=0) [super setScaleX:1];
}

-(void)onEnter{
	
	[super onEnter];
	
	roleAction = RoleAction_stand;
	roleDir = RoleDir_down;
	
	self.anchorPoint = ccp(0.5,0);
	
	runIndex = 0;
	runFrames = [[NSMutableArray alloc] init];
	
	[self schedule:@selector(checkRuning:) interval:frames_delay];
	
}

-(void)onExit{
	
	if(helper){
		[helper free];
		helper = nil;
	}
	
	if(runFrames){
		[runFrames release];
		runFrames = nil;
	}
	
	[super onExit];	
}

-(void)checkRuning:(ccTime)time{
	
	if(!isHasRole) return;
	
	if(roleAction==RoleAction_runing && [runFrames count]>0){
		
		if(runIndex>=[runFrames count]) runIndex = 0;
		[self setDisplayFrame:[runFrames objectAtIndex:runIndex]];
		runIndex++;
		
	}
}

-(void)showRole{
	
	if(roleId==0){
		[self showBase];
		return;
	}
	
	if(helper){
		BOOL isError = helper.isError;
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"r%d",roleId];
	if(suitId>0){
		name = [NSString stringWithFormat:@"r%d_%d",roleId,suitId];
	}
	
	NSString * path = [GameResourceLoader getFilePathByType:PathType_role target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		path = [NSString stringWithFormat:@"%@.%@",path,GAME_RESOURCE_DAT];
		helper = [GameLoaderHelper create:path isUnzip:YES];
		helper.type = PathType_role;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		
		[self showBase];
		[self updateParent];
		return;
	}
	
	[self removeBase];
	[self loadActionFrames];
	[self updateParent];
	
}

-(void)setRoleDir:(RoleDir)dir{
	if(dir==RoleDir_none) return;
	if(roleDir!=dir){
		roleDir = dir;
		[self loadActionFrames];
	}
}

-(void)showSuit:(int)sid{
	
	if(suitId==sid) return;
	suitId=sid;
	[self showRole];
	
}

#pragma mark 站立表现
-(void)showStand{
	if(roleAction==RoleAction_stand) return;
	CCLOG(@"showStand");
	roleAction = RoleAction_stand;
	[self stopAllActions];
	[self loadActionFrames];
}

#pragma mark 跑步表现
-(void)showRuning{
	if(roleAction==RoleAction_runing) return;
	CCLOG(@"showRuning");
	roleAction = RoleAction_runing;
	[self stopAllActions];
	runIndex = 0;
	[self loadActionFrames];
	
}  

#pragma mark 打坐表现

-(void)showSit{
	if(roleAction==RoleAction_siting) return;
	CCLOG(@"showSit");
	roleAction=RoleAction_siting;
	[self stopAllActions];
	runIndex=0;
	[self loadActionFrames];
}

#pragma mark 执行序列帧

-(void)loadActionFrames{
	
	if(!isHasRole) return;
	
	NSString * path = @"";
	NSString * suit = @"";
	//角色//（套装）//动作//方向
	if(suitId!=0){
		 suit=[NSString stringWithFormat:@"_%i",suitId];
	}
	
	RoleAction action = roleAction;
	if(OnCar==YES && roleAction!=RoleAction_siting){
		action = RoleAction_stand;
	}
	
	path = [NSString stringWithFormat:@"images/animations/role/r%d%@/%d/%d/",roleId,suit,action,roleDir];
	if(action==RoleAction_siting){
		//角色//（套装）//动作
		path = [NSString stringWithFormat:@"images/animations/role/r%d%@/%d/",roleId,suit,action];
	}
	
	NSArray * frames = [AnimationViewer loadFileByFileFullPath:path name:@"%d.png"];
	[self playAnimation:frames];
	
}

-(void)playAnimation:(NSArray*)ary{
	
	//[super playAnimation:ary];
	if([ary count]>0){
		
		[runFrames removeAllObjects];
		
		if(roleAction==RoleAction_stand){
			[self playAnimation:ary delay:frames_delay];
		}
		if(roleAction==RoleAction_siting){
			[self playAnimation:ary delay:frames_delay];
		}
		if(roleAction==RoleAction_runing){
			
			CCSpriteFrame * frame = [ary objectAtIndex:0];
			self.contentSize = frame.rect.size;
			
			[runFrames addObjectsFromArray:ary];
		}
	}
	
	//[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	
}

-(void)dealloc{
	if(helper){
		[helper free];
		helper = nil;
	}
	[super dealloc];
}

-(void)showBase{
	
	CCSprite * def = [CCSprite spriteWithFile:@"images/defaultViewer.png"];
	def.tag = 123;
	def.anchorPoint = ccp(0.5,0);
	def.position = ccp(0,-self.position.y);
	[self addChild:def];
	
	if(runFrames){
		[runFrames removeAllObjects];
	}
	[self stopAllActions];
	[self setDisplayFrame:nil];
	
	isHasRole = NO;
}

-(void)removeBase{
	[self removeChildByTag:123 cleanup:YES];
	isHasRole = YES;
}

-(void)updateParent{
	SEL updateViewer = @selector(updateViewer);
	if([self.parent respondsToSelector:updateViewer]){
		[self.parent performSelector:updateViewer];
	}
}

-(CGSize)contentSize{
	CCNode * def = [self getChildByTag:123];
	if(def){
		return CGSizeMake(def.contentSize.width, def.contentSize.height+cFixedScale(10)+abs(def.position.y));
	}
	return super.contentSize;
}

@end
