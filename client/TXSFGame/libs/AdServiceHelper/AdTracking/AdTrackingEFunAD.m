//
//  AdTrackingEFunAD.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "AdTrackingEFunAD.h"
#import "EfunAD.h"

@implementation AdTrackingEFunAD

-(void)tracking{
	
	[super tracking];
	
	[EfunAD setEfunAD];
	
	[self over];
	
}

@end
