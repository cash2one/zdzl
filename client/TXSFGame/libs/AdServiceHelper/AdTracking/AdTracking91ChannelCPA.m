//
//  AdTracking91ChannelCPA.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AdTracking91ChannelCPA.h"
#import <NdChannelLib/NdChannelLib.h>

@implementation AdTracking91ChannelCPA

-(void)tracking{
	[super tracking];
	[NdChannelLib NdUploadChannelId:1090 delegate:self];
}

-(void)NdUploadChannelIdDidFinished:(int)resultCode  sessionId:(NSString*)session errorDescription:(NSString*)description{
	if(resultCode!=0){
		NSLog(@"Error : %@",description);
	}
	[self over];
}

@end
