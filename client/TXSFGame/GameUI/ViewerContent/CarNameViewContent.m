//
//  CarNameViewContent.m
//  TXSFGame
//
//  Created by Max on 13-5-31.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "CarNameViewContent.h"
#import "Config.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"

@implementation CarNameViewContent

+(CarNameViewContent*)create:(int)nid{
	CarNameViewContent * node = [CarNameViewContent node];
	[node loadCarName:nid];
	return node;
}

-(void)loadCarName:(int)nid{
	name_id = nid;
	self.contentSize = CGSizeMake(cFixedScale(63), cFixedScale(63));
	[self showCarName];
}

-(void)showCarName{
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			return;
		}
	}
	NSString * name = [NSString stringWithFormat:@"carname%d.png",name_id];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_car target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_icon_car;
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


-(void)onEnter{
	[super onEnter];
}

-(void)onExit{
	[super onExit];
}

@end
