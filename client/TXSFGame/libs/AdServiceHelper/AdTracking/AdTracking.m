//
//  AdTracking.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AdTracking.h"

static NSMutableArray * memoryCache = nil;

static void addTrackingToMemory(id target){
	if(!memoryCache){
		memoryCache  =[[NSMutableArray alloc] init];
		[memoryCache addObject:target];
	}
}

static void delTrackingToMemory(id target){
	if(memoryCache){
		[memoryCache removeObject:target];
		if([memoryCache count]==0){
			[memoryCache release];
			memoryCache = nil;
		}
	}
}

@implementation AdTracking

-(void)dealloc{
	//TODO test
	//NSLog(@"AdTracking dealloc");
	[super dealloc];
}

-(void)tracking{
	addTrackingToMemory(self);
}

-(void)over{
	delTrackingToMemory(self);
}

@end
