//
//  ActivityViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-4-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "ActivityViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "InAppBrowser.h"
#import "ActivityKey.h"
#import "Window.h"

@implementation ActivityViewerContent

@synthesize target;
@synthesize call;

+(ActivityViewerContent*)create:(NSDictionary*)data{
	ActivityViewerContent * node = [ActivityViewerContent node];
	[node loadData:data];
	return node;
}

+(NSString*)getFunctionType:(NSDictionary*)dict{
	if(dict!=nil){
		NSString * cmd = [dict objectForKey:@"cmd"];
		if(cmd){
			NSArray * cmds = [cmd componentsSeparatedByString:@"::"];
			if([cmds count]>1){
				return (NSString*)[cmds objectAtIndex:0];
			}else{
				if ([cmd length] > 0) {
					return cmd;
				}
			}
		}
	}
	return @"";
}

+(id)getFunctionAction:(NSDictionary*)dict{
	if(dict!=nil){
		NSString * cmd = [dict objectForKey:@"cmd"];
		if(cmd){
			NSArray * cmds = [cmd componentsSeparatedByString:@"::"];
			if([cmds count]>1){
				return [cmds objectAtIndex:1];
			}
		}
	}
	return @"";
}

-(void)dealloc{
	if(activity){
		[activity release];
		activity = nil;
	}
	[super dealloc];
}

-(void)onExit{
	[super onExit];
}

-(void)loadData:(NSDictionary*)data{
	
	self.contentSize = CGSizeMake(cFixedScale(565), cFixedScale(474));
	
	if(activity) [activity release];
	
	activity = data;
	if(activity){
		[activity retain];
		[self showActivity];
	}
}

-(int)getActivityId{
	if (activity) {
		return [[activity objectForKey:@"id"] intValue];
	}
	return 0;
}

-(void)showActivity{
	
	if(helper){
		BOOL isError = helper.isError;
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * name = [activity objectForKey:@"bg"];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_activity target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_activity;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		[self showLoaderInContentCenter];
		return;
	}
	
	CCSimpleButton * viewer = [CCSimpleButton spriteWithFile:path];
	if(viewer){
		viewer.anchorPoint = ccp(0,0);
		viewer.target = self;
		viewer.call = @selector(onPress:);
		viewer.touchScale = 1.0f;
		viewer.priority = INT32_MIN+15;
		[self addChild:viewer];
	}
	
	[self hideLoader];
	[self checkCommand];
	
}

+(void) hideKeyboard:(ActivityViewerContent*) keywin
{
	ActivityKey* key=(ActivityKey*)[keywin getChildByTag:7865];
	if (key) {
		[ActivityKey hideKeyboard:key];		
	}
}

-(void)checkCommand{
	
	NSString * cmd = [ActivityViewerContent getFunctionType:activity];
	
	if(isEqualToKey(cmd, FUNC_input)){
		
		if([self getChildByTag:7865]) return;
		
		ActivityKey * content = [ActivityKey node];
		[content loadData:activity];
		content.position = ccp(0,0);
		[self addChild:content z:10 tag:7865];
		
	}
}

-(void)onPress:(id)sender{
	
	if (!self.visible) {
		return ;
	}
	
	if(activity!=nil){
		
		NSString * cmd = [ActivityViewerContent getFunctionType:activity];
		id action = [ActivityViewerContent getFunctionAction:activity];
		
		if(isEqualToKey(cmd, FUNC_url)){
			[InAppBrowser show:action title:[activity objectForKey:@"name"]];
			[self doParentCall];
			
			return ;
		}
		
		if(isEqualToKey(cmd, FUNC_win)){
			//TODO soul
			int panelId = [action intValue];
			[self doParentCall];
			[[Window shared] showWindow:panelId];
			return ;
		}
		
		if(isEqualToKey(cmd, FUNC_input)){
			//add chenjunming
			//hide keyboard
			ActivityKey* key=nil;
			if ((key=(ActivityKey*)[self getChildByTag:7865])) {
				[ActivityKey hideKeyboard:key];
			}
			
			return ;
		}
		
		
		[self doParentCall];
		
	}
	
}

-(void)doParentCall{
	if(target!=nil && call!=nil){
		[target performSelector:call];
	}
}

@end
