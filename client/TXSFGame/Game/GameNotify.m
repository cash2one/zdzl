//
//  GameNotify.m
//  TXSFGame
//
//  Created by Soul on 13-3-22.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "GameNotify.h"
#import "GameConnection.h"

static GameNotify* s_GameNotify = nil;

@implementation GameNotify

@synthesize notifys = _notifys;

+(GameNotify*)shared{
	if (s_GameNotify == nil) {
		s_GameNotify = [[GameNotify alloc] init];
	}
	return s_GameNotify;
}

+(void)stopAll{
	if(s_GameNotify){
		[GameConnection removePostTarget:s_GameNotify];
		[s_GameNotify release];
		s_GameNotify = nil;
	}
}

-(id)init{
	if ((self = [super init])) {
		_notifys = [[NSMutableArray alloc] init];
	}
	return self;
}

-(void)dealloc{
	if (_notifys != nil) {
		[_notifys removeAllObjects];
		[_notifys release];
		_notifys = nil ;
	}
	[super dealloc];
}

-(void)start{
	
}

-(void)checkNotify{
	
}

@end
