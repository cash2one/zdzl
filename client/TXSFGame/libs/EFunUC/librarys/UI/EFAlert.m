//
//  EFAlert.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFAlert.h"

@implementation EFAlert

+(void)alert:(NSString*)message{
	[self alert:message delay:0.38f];
}

+(void)alert:(NSString*)message delay:(float)delay{
	if(delay<=0){
		[self doShowAlert:message];
		return;
	}
	[NSTimer scheduledTimerWithTimeInterval:delay 
									 target:self selector:@selector(showAlert:) 
								   userInfo:message repeats:NO];
}

+(void)showAlert:(NSTimer*)timer{
	[self doShowAlert:timer.userInfo];
}

+(void)doShowAlert:(NSString*)message{
	UIAlertView * Alert = [[UIAlertView alloc]initWithTitle:@"提示" 
													message:message
												   delegate:nil 
										  cancelButtonTitle:@"确定" 
										  otherButtonTitles:nil];
	[Alert show];
	[Alert release];
}

@end
