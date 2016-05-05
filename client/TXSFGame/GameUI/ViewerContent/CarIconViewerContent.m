//
//  CarIconViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-25.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "CarIconViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"

@implementation CarIconViewerContent

+(CarIconViewerContent*)create:(int)cid{
	CarIconViewerContent * node = [CarIconViewerContent node];
	[node loadCarIcon:cid];
	return node;
}

-(void)loadCarIcon:(int)cid{
	car_id = cid;
	self.contentSize = CGSizeMake(cFixedScale(63), cFixedScale(63));
	[self showCarIcon];
}

-(void)showCarIcon{
	
	//[self showLoaderInContentCenter];
	//return;
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"car%d.png",car_id];
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

@end
