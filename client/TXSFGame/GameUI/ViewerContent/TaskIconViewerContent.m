//
//  TaskIconViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "TaskIconViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"

@implementation TaskIconViewerContent

+(TaskIconViewerContent*)create:(NSString*)task{
	TaskIconViewerContent * node = [TaskIconViewerContent node];
	[node showTask:task];
	return node;
}

-(void)onExit{
	if(task){
		[task release];
		task = nil;
	}
	[super onExit];
}

-(void)dealloc{
	if(task){
		[task release];
		task = nil;
	}
	[super dealloc];
}

-(void)showTask:(NSString*)_task{
	if(task){
		[task release];
		task = nil;
	}
	
	task = [NSString stringWithString:_task];
	if(task){
		[task retain];
		[self showTask];
	}
	
}

-(void)showTask{
	
	[self removeChildByTag:123 cleanup:YES];
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"task_icon_%@.png",task];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_icon_task target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_icon_task;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		
		return;
	}
	
	icon = [CCSprite spriteWithFile:path];
	if(icon){
		icon.anchorPoint = self.anchorPoint;
		[self addChild:icon];
	}
}

-(void)setAnchorPoint:(CGPoint)anchorPoint{
	[super setAnchorPoint:anchorPoint];
	if(icon){
		icon.anchorPoint = anchorPoint;
	}
}

@end
