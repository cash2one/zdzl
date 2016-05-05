//
//  AdTrackingAdwords.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AdTrackingAdwords.h"
#import "GoogleConversionPing.h"

@implementation AdTrackingAdwords

-(void)tracking{
	[super tracking];
	
	[GoogleConversionPing pingWithConversionId:@"984943654" label:@"QfIHCJqY_AYQppjU1QM" value:@"0" isRepeatable:NO];
	
	[self over];
}

@end
