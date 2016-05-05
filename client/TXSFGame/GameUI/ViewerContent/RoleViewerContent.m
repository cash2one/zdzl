//
//  RoleViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-20.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "RoleViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "AnimationViewer.h"
#import "GameDB.h"
#import "Config.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "GameConfigure.h"

#define role_frame_delay 0.09f

@implementation RoleViewerContent

@synthesize dir;


-(void)loadTargetOtherRole:(int)rid eid:(int)eid{
	if(dir!=1 && dir!=2) dir = 1;
	
	roleAnima = [AnimationViewer node];
	[self addChild:roleAnima];
	NSDictionary *roleInfo = [[GameDB shared] getRoleInfo:rid];
	if (roleInfo) {
		roleId = rid;
		float offset = [[roleInfo objectForKey:@"offset"] intValue];
		offset = cFixedScale(offset);
		roleAnima.anchorPoint = ccp(0.5,0);
		roleAnima.position = ccp(0,-offset);
		equipId=eid;
		[self showRole];
	}
	

}

-(void)loadTargetRole:(int)rid{
	
	if(dir!=1 && dir!=2) dir = 1;
	
	roleAnima = [AnimationViewer node];
	[self addChild:roleAnima];
	
	NSDictionary *roleInfo = [[GameDB shared] getRoleInfo:rid];
	if (roleInfo) {
		
		roleId = rid;
		
		float offset = [[roleInfo objectForKey:@"offset"] intValue];
		offset = cFixedScale(offset);
		
		//NSString *fullPath = nil;
		
		// 主角
		if (rid == [RoleManager shared].player.role_id) {
			
			int eqid = 0;
			int eq2 = 0;
			
			NSDictionary* playerRole = [[GameConfigure shared] getPlayerRoleFromListById:rid];
			if (playerRole) {
				eq2 = [[playerRole objectForKey:@"eq2"] intValue];
				NSDictionary* playerEquip = [[GameConfigure shared] getPlayerEquipInfoById:eq2];
				if (playerEquip) {
					eqid = [[playerEquip objectForKey:@"eid"] intValue];
				}
			}
			
			if (eqid == 0) {
				//fullPath = [NSString stringWithFormat:@"images/fight/ani/r%d/2/battle-stand/", rid];
			} else {
				equipId = eqid;
				//fullPath = [NSString stringWithFormat:@"images/fight/ani/r%d_%d/2/battle-stand/", rid, eqid];
			}
		}else{
			//fullPath = [NSString stringWithFormat:@"images/fight/ani/r%d/2/battle-stand/", rid];
		}
		
		//roleAnima.anchorPoint = ccp(0.5, offset / roleAnima.contentSize.height);
		roleAnima.anchorPoint = ccp(0.5,0);
		roleAnima.position = ccp(0,-offset);
		
		[self showRole];
		
	}
	
}

-(void)showRole{
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			if(equipId==0){
				return;
			}else{
				equipId = 0;
			}
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"r%d",roleId];
	if(equipId>0){
		name = [NSString stringWithFormat:@"%@_%d",name,equipId];
	}
	
	NSString * path = [GameResourceLoader getFilePathByType:PathType_fight_role target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		path = [NSString stringWithFormat:@"%@.%@",path,GAME_RESOURCE_DAT];
		
		helper = [GameLoaderHelper create:path isUnzip:YES];
		helper.type = PathType_fight_role;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		
		CCSprite * def = [CCSprite spriteWithFile:@"images/defaultViewer.png"];
		def.tag = 123;
		def.anchorPoint = ccp(0.5,0);
		[self addChild:def];
		
		return;
	}
	
	[self showStand];
	
}

-(void)showStand{
	
	[self removeChildByTag:123 cleanup:YES];
	
	NSString * fullPath = [self getActionString:@"battle-stand"];
	if(fullPath && roleAnima){
		NSArray * roleFrames = [AnimationViewer loadFileByFileFullPath:fullPath name:@"%d.png"];
		[roleAnima playAnimation:roleFrames delay:role_frame_delay];
	}
	
	isLoaded = YES;
}

-(void)showSkill{
	if(!isLoaded) return;
	[self showSkillByEndCall:nil];
}

-(void)showSkillByEndCall:(CCAction*)action{
	NSString * fullPath = [self getActionString:@"battle-attackex"];
	
	if(fullPath && roleAnima){
		NSArray * roleFrames = [AnimationViewer loadFileByFileFullPath:fullPath name:@"%d.png"];
		
		id call = [CCCallFunc actionWithTarget:self selector:@selector(showStand)];
		CCSequence * seq = nil;
		if(action){
			seq = [CCSequence actions:call,action,nil];
		}else{
			seq = [CCSequence actions:call,nil];
		}
		[roleAnima playAnimation:roleFrames delay:role_frame_delay call:seq];
	}
}

-(NSString*)getActionString:(NSString*)action{
	NSString * fullPath = nil;
	//if(roleId == [RoleManager shared].player.role_id){
		if(equipId==0){
			fullPath = [NSString stringWithFormat:@"images/fight/ani/r%d/%d/%@/",roleId,dir,action];
		}else{
			fullPath = [NSString stringWithFormat:@"images/fight/ani/r%d_%d/%d/%@/",roleId,equipId,dir,action];
		}
	//}else{
		//fullPath = [NSString stringWithFormat:@"images/fight/ani/r%d/%d/%@/",roleId,dir,action];
//	}
	return fullPath;
}

@end
