//
//  EFSimpleAbout.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-26.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFSimpleAbout.h"

@implementation EFSimpleAbout

-(void)show{
	
	[super showBackground:@"ef_resources/bg_login.jpg"];
	[super showCloseBtn];
	[super showReturnBtn];
	
	[super showTitle:@"联系客服"];
	
	[super showContent:0];
	
}

@end
