//
//  AdTrackingDomod.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AdTrackingDomod.h"
#import "DMConversionTracker.h"

#define DOMOD_SDK_APP_ID @"db576a7d"

@implementation AdTrackingDomod

-(void)tracking{
	[super tracking];
	
	[DMConversionTracker startAsynchronousConversionTrackingWithDomobAppId:DOMOD_SDK_APP_ID];
	
	[self over];
}

@end
