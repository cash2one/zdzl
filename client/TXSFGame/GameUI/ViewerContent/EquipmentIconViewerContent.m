//
//  EquipmentIconViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-20.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EquipmentIconViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"
#import "IconLoadingViewer.h"

@implementation EquipmentIconViewerContent

+(EquipmentIconViewerContent*)create:(int)eid{
	EquipmentIconViewerContent * node = [EquipmentIconViewerContent node];
	[node loadTargetEquipIcon:eid];
	return node;
}

-(void)onEnter{
	[super onEnter];
	[self showEquipIcon];
}

-(void)loadTargetEquipIcon:(int)eid{
	equip_id = eid;
	self.contentSize = CGSizeMake(cFixedScale(84), cFixedScale(84));
	[self showEquipIcon];
}

-(void)showEquipIcon{
	
	if(equip_id==0) return;
	if(!self.parent) return;
	
	[self removeChildByTag:123 cleanup:YES];
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"equip%d.png",equip_id];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_equip target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_icon_equip;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		
		[self showLoaderInContentCenter];
		
		return;
	}
	
	CCSprite * icon = [CCSprite spriteWithFile:path];
	if(icon){
		icon.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
		[self addChild:icon];
	}
	
	[self hideLoader];
	
}

@end
