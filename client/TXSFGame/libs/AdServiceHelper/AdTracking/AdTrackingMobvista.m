//
//  AdTrackingMobvista.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AdTrackingMobvista.h"
#import "ASIFormDataRequest.h"
#import "UIDevice+IdentifierAddition.h"

@implementation AdTrackingMobvista

-(void)tracking{
	
	[super tracking];
	
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults]; 
	NSString * key = [NSString stringWithFormat:@"%@_mobvistaInstall",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"]]; 
	
	if([defaults boolForKey:key]==NO){
		
		NSString * mac = [[UIDevice currentDevice] macaddress];
		
		NSString * url = [NSString stringWithFormat:@"http://ad.52yh.com/ads_installStatistics.shtml"];
		url = [NSString stringWithFormat:@"%@?gameCode=zdzlios&flage=iSNew_20130130&advertiser=mobvista&mobvistaSDK=mobvistaSDK",url];
		url = [NSString stringWithFormat:@"%@&mac=%@",url,mac];
		
		ASIFormDataRequest * request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:url]];
		
		[request setCompletionBlock:^{
			[defaults setBool:YES forKey:key];
			[defaults synchronize];
			[self over];
		}];
		
		[request setFailedBlock:^{
			[self over];
		}];
		
		[request setRequestMethod:@"GET"];
		[request startAsynchronous];
		
	}else{
		[self over];
	}
	
}

@end
