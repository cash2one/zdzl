//
//  EFUIWindow.h
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AvailabilityMacros.h>

@interface EFUIWindow : UIView{
	UIView * currentView;
	NSMutableArray * logWindows;
}
+(BOOL)isRunOniPhone;
+(CGRect)getWindowRect;

+(void)closeWindows;
+(void)closeWindowsWithDelay:(float)delay;
+(void)returnWindow;


+(void)showLogin;
+(void)showUserRegister;
+(void)showUserCenter;
+(void)showModifyInfo;
+(void)showAbout;
+(void)showSimpleAbout;
+(void)showForget;

+(void)showLoading;
+(void)hideLoading;

+(void)moveContentToY:(float)ty;
+(void)moveContentToOrigin;
//
+(BOOL)isRunAnimate;
@end
