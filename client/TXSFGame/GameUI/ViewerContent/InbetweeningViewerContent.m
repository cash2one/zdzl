//
//  InbetweeningViewerContent.m
//  TXSFGame
//
//  Created by Soul on 13-5-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "InbetweeningViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"
#import "cocos2d.h"


@implementation InbetweeningViewerContent

+(InbetweeningViewerContent*)create:(NSDictionary *)data{
	InbetweeningViewerContent* __node = [InbetweeningViewerContent node];
	[__node loadData:data];
	return __node;
}

-(void)loadData:(NSDictionary*)dict{
	self.contentSize = [CCDirector sharedDirector].winSize;
	
	if(iKonInfo) {
		[iKonInfo release];
		iKonInfo = nil;
	}
	
	iKonInfo = dict;
	if(iKonInfo){
		[iKonInfo retain];
		[self showInbetweeningViewer];
	}
}

-(void)showInbetweeningViewer{
	if(helper){
		BOOL isError = helper.isError;
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [iKonInfo objectForKey:@"path"];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_inbetweening target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_inbetweening;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		[self showLoaderInContentCenter];
		return;
	}
	
	CCSprite* sprite = [CCSprite spriteWithFile:path];
	if(sprite){
		[self addChild:sprite];
		sprite.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
	}
	
}

-(void)onExit{
	if (iKonInfo != nil) {
		[iKonInfo release];
		iKonInfo = nil;
	}
	[super onExit];
}

@end
