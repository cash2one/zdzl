//
//  AnimationNPC.m
//  TXSFGame
//
//  Created by chao chen on 12-11-6.
//  Copyright 2012 eGame. All rights reserved.
//

#import "AnimationNPC.h"
#import "GameFileUtils.h"
#import "GameResourceLoader.h"

@implementation AnimationNPC

-(void)onEnter{
	[super onEnter];
	self.anchorPoint = ccp(0.5,0);
}

-(void)onExit{
	if(helper){
		[helper free];
		helper = nil;
	}
	[super onExit];
}
-(void)showAnimationByNPCId:(int)npcId{
	npc_id = npcId;
	
	CCSprite * def = [CCSprite spriteWithFile:@"images/defaultViewer.png"];
	def.tag = 123;
	def.anchorPoint = ccp(0.5,0);
	def.position = ccp(0,-self.position.y);
	[self addChild:def];
	self.contentSize = CGSizeMake(0, (def.contentSize.height+cFixedScale(10))+abs(self.position.y));
	
	[self showNpcAnimation];
	
}
//chao
-(void)showAnimationByROLEId:(int)roleId suitId:(int)suitId dir:(int)dir{
    npc_id = roleId;
	npc_suitId = suitId;
    npc_dir = dir;
    
	CCSprite * def = [CCSprite spriteWithFile:@"images/defaultViewer.png"];
	def.tag = 123;
	def.anchorPoint = ccp(0.5,0);
	def.position = ccp(0,-self.position.y);
	[self addChild:def];
	self.contentSize = CGSizeMake(0, (def.contentSize.height+cFixedScale(10))+abs(self.position.y));
	
	[self showRoleAnimation];
}
-(void)showNpcAnimation{
	
	if(helper){
		BOOL isError = helper.isError;
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"npc_%d",npc_id];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_map_npc target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		path = [NSString stringWithFormat:@"%@.%@",path,GAME_RESOURCE_DAT];
		
		helper = [GameLoaderHelper create:path isUnzip:YES];
		helper.type = PathType_map_npc;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		return;
	}
	
	path = [NSString stringWithFormat:@"%@/%@.png",path,@"%d"];
	[self showAnimationByPath:path];
	
}
//chao
-(void)showRoleAnimation{
    if(helper){
		BOOL isError = helper.isError;
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"r%d",npc_id];
    if(npc_suitId>0){
		name = [NSString stringWithFormat:@"r%d_%d",npc_id,npc_suitId];
	}
	NSString * path = [GameResourceLoader getFilePathByType:PathType_role target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		path = [NSString stringWithFormat:@"%@.%@",path,GAME_RESOURCE_DAT];
		
		helper = [GameLoaderHelper create:path isUnzip:YES];
		helper.type = PathType_role;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
        //
        [self removeChildByTag:123 cleanup:YES];
        CCSprite * def = [CCSprite spriteWithFile:@"images/defaultViewer.png"];
        def.tag = 123;
        def.anchorPoint = ccp(0.5,0);
        def.position = ccp(0,-self.position.y);
        [self addChild:def];
        //
        [self stopAllActions];
        [self setDisplayFrame:nil];
		return;
	}
    NSString * suit = @"";
    if(npc_suitId!=0){
        suit=[NSString stringWithFormat:@"_%i",npc_suitId];
	}
	path = [NSString stringWithFormat:@"images/animations/role/r%d%@/%d/%d/",npc_id,suit,RoleAction_stand,npc_dir];
    path = [NSString stringWithFormat:@"%@%@",path,@"%d.png"];
	[self showAnimationByPath:path];
    /////
}

-(void)playAnimation:(NSArray*)frames{
	
	[self removeChildByTag:123 cleanup:YES];
	
	//todo save use array
	//todo Tiger
	if(frames && [frames count]>0){
		CCSpriteFrame * frame = [frames objectAtIndex:0];
		self.contentSize = frame.rect.size;
		[self updateParent];
	}
	[super playAnimation:frames];
}

-(void)updateParent{
	SEL updateBaseSize = @selector(updateBaseSize);
	if([self.parent respondsToSelector:updateBaseSize]){
		[self.parent performSelector:updateBaseSize];
	}
}

@end
