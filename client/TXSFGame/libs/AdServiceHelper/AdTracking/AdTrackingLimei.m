//
//  AdTrackingLimei.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AdTrackingLimei.h"
#import "ASIFormDataRequest.h"
#import "UIDevice+IdentifierAddition.h"

@implementation AdTrackingLimei

-(void)tracking{
	[super tracking];
	
	NSString * appKey = [[NSBundle mainBundle] bundleIdentifier];
	NSString * udid = [[UIDevice currentDevice] uniqueDeviceIdentifier];
	
    NSString * urlString = [NSString stringWithFormat:@"http://api.lmmob.com/capCallbackApi/1/?appId=%@&udid=%@&returnFormat=1", appKey,udid];
	NSURL * url = [NSURL URLWithString:urlString];
	ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:url];
	[request setCompletionBlock:^{
		//NSString * responseString = [request responseString];
		[self over];
	}];
	
	[request setFailedBlock:^{
		[self over];
	}];
	
	[request setRequestMethod:@"GET"];
	[request startAsynchronous];
	
}

@end
