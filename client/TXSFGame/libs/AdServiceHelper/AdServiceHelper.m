//
//  AdServiceHelper.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AdServiceHelper.h"
#import "AdTracking.h"

static NSString * adTrackingClass[] = {
	
#ifdef GAME_SNS_TYPE

#if GAME_SNS_TYPE==1
	//@"AdTrackingAdwo",
	//@"AdTrackingEFun",
	//@"AdTrackingDomod",
#endif
	
#if GAME_SNS_TYPE==2
	//@"AdTracking91ChannelCPA",
	//@"AdTrackingDomod",
	//@"AdTrackingUmtrack",
	//@"AdTrackingEFun",
	
	@"AdTrackingMobvista",
	
#endif
	
#if GAME_SNS_TYPE==3
	//@"AdTrackingEFun",
	//@"AdTrackingDomod",
	//@"AdTrackingUmtrack",
	//@"AdTrackingAdwords",
	@"AdTrackingDomod",
	@"AdTrackingUmtrack",
	@"AdTrackingEFun",
#endif
	
#if GAME_SNS_TYPE==4
	@"AdTrackingUmtrack",
	@"AdTrackingEFun",
#endif
	
#if GAME_SNS_TYPE==5
	//@"AdTrackingEFunAD",
	//@"AdTrackingLimei",
	@"AdTrackingEFun",
#endif
	
#if GAME_SNS_TYPE==6
	//@"AdTrackingEFunAD",
	@"AdTrackingEFun",
#endif
	
#if GAME_SNS_TYPE==7
	@"AdTrackingYdUmtrack",
#endif
	
#if GAME_SNS_TYPE==9
	//@"AdTrackingYdUmtrack",
#endif
	
#if GAME_SNS_TYPE==10
	
#endif
	
#endif
	
};

static Class getTrackingClass(int index){
	return NSClassFromString(adTrackingClass[index]);
}

static AdServiceHelper * adServiceHelper;

@implementation AdServiceHelper

+(AdServiceHelper*)shared{
	if(adServiceHelper==nil){
		adServiceHelper = [[AdServiceHelper alloc] init];
	}
	return adServiceHelper;
}

+(void)stopAll{
	if(adServiceHelper){
		[adServiceHelper release];
		adServiceHelper = nil;
	}
}

-(void)sendTracking{
	
	//TODO
	[self doSendTracking];
	
}

-(void)doSendTracking{
	int total = sizeof(adTrackingClass)/sizeof(adTrackingClass[0]);
	for(int i=0;i<total;i++){
		Class target = getTrackingClass(i);
		if(target){
			AdTracking * tracking = [[target alloc] init];
			[tracking tracking];
			[tracking release];
		}
	}
}

@end
