//
//  RoleIconViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "RoleIconViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"

@implementation RoleIconViewerContent

+(RoleIconViewerContent*)create:(int)rid type:(int)type{
	RoleIconViewerContent * node = [RoleIconViewerContent node];
	[node loadRoleIcon:rid type:type];
	return node;
}

-(void)loadRoleIcon:(int)rid type:(int)_type{
	
	role_id = rid;
	type = _type;
	
	[self showRoleIcon];
	
}

-(void)showRoleIcon{
	
	if(role_id==0) return;
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = @"";
	PathType pathType = PathType_icon_role;
	
	if(type==ICON_PLAYER_BIG){
		pathType = PathType_icon_role;
		name = [NSString stringWithFormat:@"player_icon_%d.png",role_id];
		self.contentSize = CGSizeMake(cFixedScale(121), cFixedScale(121));
	}else if(type==ICON_PLAYER_NORMAL){
		pathType = PathType_icon_member;
		name = [NSString stringWithFormat:@"player_team_%d.png",role_id];
		self.contentSize = CGSizeMake(cFixedScale(90), cFixedScale(58));
	}else if(type==ICON_PLAYER_SMALL){
		pathType = PathType_icon_team;
		name = [NSString stringWithFormat:@"player_steam_%d.png",role_id];
		self.contentSize = CGSizeMake(cFixedScale(59), cFixedScale(59));
	}else{
		return;
	}
	
	NSString * path = [GameResourceLoader getFilePathByType:pathType target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		helper = [GameLoaderHelper create:path];
		helper.type = pathType;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		
		return;
	}
	
	icon = [CCSprite spriteWithFile:path];
	if(icon){
		if(type==ICON_PLAYER_BIG){
			icon.anchorPoint = ccp(0.5,0);
		}else if(type==ICON_PLAYER_NORMAL){
			icon.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
		}else if(type==ICON_PLAYER_SMALL){
			icon.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
		}else{
			return;
		}
		[self addChild:icon];
	}
	
}

-(void)setAnchorPoint:(CGPoint)anchorPoint{
	[super setAnchorPoint:anchorPoint];
	if(icon){
		//icon.anchorPoint = anchorPoint;
	}
}

@end
