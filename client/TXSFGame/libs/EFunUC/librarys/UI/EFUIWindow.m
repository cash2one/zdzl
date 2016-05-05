//
//  EFUIWindow.m
//  TXSFGame
//
//  Created by TigerLeung on 13-7-17.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "EFUIWindow.h"
#import "ASDepthModalViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SVProgressHUD.h"
#import "EFBaseWindow.h"
//
static BOOL s_isAnimate = NO;
static EFUIWindow * sharedView;
//static UIWindow * overlayWindow;

@implementation EFUIWindow

-(id)initWithFrame:(CGRect)frame{
	if((self = [super initWithFrame:frame])){
		self.backgroundColor = [UIColor clearColor];
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
		logWindows = [[NSMutableArray alloc] init];
		s_isAnimate = NO;
	}
    return self;
}

-(void)drawRect:(CGRect)rect{
    
    //CGContextRef context = UIGraphicsGetCurrentContext();
    
	//[[UIColor colorWithWhite:0 alpha:0.5] set];
	//CGContextFillRect(context, self.bounds);
	
	/*
	size_t locationsCount = 2;
	CGFloat locations[2] = {0.0f, 1.0f};
	CGFloat colors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.75f}; 
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
	CGColorSpaceRelease(colorSpace);
	
	CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
	float radius = MIN(self.bounds.size.width , self.bounds.size.height) ;
	CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
	CGGradientRelease(gradient);
	*/
	
}

-(void)dealloc{
	[logWindows release];
    s_isAnimate = NO;
	[super dealloc];
}

-(void)addSubview:(UIView*)target effect:(int)effect{
	
	[super addSubview:target];
	
	if(currentView){
		
		id actionFinish = ^(BOOL finished){
			[currentView removeFromSuperview];
			currentView = target;
			[logWindows insertObject:NSStringFromClass([currentView class]) atIndex:0];
            //
            s_isAnimate = NO;
		};
		
		if(effect==1){
			CGRect tFrame = target.frame;
			tFrame.origin.x = [EFUIWindow getWindowRect].size.width;
			target.frame = tFrame;
			[UIView animateWithDuration:0.25
								  delay:0
								options:UIViewAnimationCurveEaseOut
							 animations:^{	
								 target.frame = currentView.frame;
								 CGRect cFrame = currentView.frame;
								 cFrame.origin.x = -cFrame.size.width;
								 currentView.frame = cFrame;
							 }
							 completion:actionFinish
			 ];
            //
            s_isAnimate = YES;
		}
		
		if(effect==2){
			CGRect tFrame = target.frame;
			tFrame.origin.x = -tFrame.size.width;
			target.frame = tFrame;
			[UIView animateWithDuration:0.25
								  delay:0
								options:UIViewAnimationCurveEaseOut
							 animations:^{	
								 target.frame = currentView.frame;
								 CGRect cFrame = currentView.frame;
								 cFrame.origin.x = [EFUIWindow getWindowRect].size.width;
								 currentView.frame = cFrame;
							 }
							 completion:actionFinish
			 ];
            s_isAnimate = YES;
		}
		
	}else{
		currentView = target;
		[logWindows insertObject:NSStringFromClass([currentView class]) atIndex:0];
	}
	
}

-(void)returnParentWindow{
	if([logWindows count]>1){
		NSString * window = [logWindows objectAtIndex:1];
		[logWindows removeObjectsInRange:NSMakeRange(0,2)];
		[EFUIWindow showWindowByName:window effect:2];
	}
	if([logWindows count]==1){
		NSString * window = [logWindows objectAtIndex:0];
		[EFUIWindow showWindowByName:window effect:2];
	}
}

#pragma mark -

+(BOOL)isRunOniPhone{
	return (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone);
}

+(CGRect)getWindowRect{
	CGRect screen = [[UIScreen mainScreen] bounds];
	CGRect rect = CGRectMake(0, 0, 
							 MAX(screen.size.width,screen.size.height), 
							 MIN(screen.size.width,screen.size.height));
	return rect;
}
+(void)makeWindows{
	if(sharedView==nil){
		sharedView = [[EFUIWindow alloc] initWithFrame:[self getWindowRect]];
		[ASDepthModalViewController presentView:sharedView];
	}
}

+(void)closeWindows{
	[self closeWindowsWithDelay:0.0];
}
+(void)closeWindowsWithDelay:(float)delay{
	if(delay==0){
		[self doCloseWindows];
		return;
	}
	[NSTimer scheduledTimerWithTimeInterval:delay target:self selector:@selector(doCloseWindows) userInfo:nil repeats:NO];
}
+(void)doCloseWindows{
	[ASDepthModalViewController dismiss];
	if(sharedView){
		[sharedView release];
		sharedView = nil;
	}
}

+(void)returnWindow{
	if(sharedView){
		[sharedView returnParentWindow];
	}
}
+(BOOL)isRunAnimate{
    return s_isAnimate;
}
+(void)showWindowByName:(NSString*)name{
	[self showWindowByName:name effect:1];
}

+(void)showWindowByName:(NSString*)name effect:(int)effect{
	EFBaseWindow * window = [EFBaseWindow getWindow:name];
	if(window){
		[self makeWindows];
		[sharedView addSubview:window effect:effect];
	}
	[self moveContentToOrigin:0.38];
}

+(void)showLogin{
	[self showWindowByName:@"EFWindowLogin"];
}
+(void)showUserRegister{
	[self showWindowByName:@"EFRegister"];
}
+(void)showUserCenter{
	[self showWindowByName:@"EFGeneralInfo"];
}
+(void)showModifyInfo{
	[self showWindowByName:@"EFModifyInfo"];
}
+(void)showAbout{
	[self showWindowByName:@"EFAbout"];
}
+(void)showSimpleAbout{
	[self showWindowByName:@"EFSimpleAbout"];
}
+(void)showForget{
	[self showWindowByName:@"EFForget"];
}

+(void)moveContentToY:(float)ty{
	if(sharedView){
		[UIView animateWithDuration:0.25
							  delay:0
							options:UIViewAnimationCurveEaseOut
						 animations:^{
							 CGRect frame = sharedView.frame;
							 frame.origin.y = ty;
							 sharedView.frame = frame;
						 }
						 completion:nil
		 ];
	}
}

+(void)moveContentToOrigin{
	[self moveContentToOrigin:0];
}
+(void)moveContentToOrigin:(float)delay{
	if(sharedView){
		[UIView animateWithDuration:0.25
							  delay:delay
							options:UIViewAnimationCurveEaseOut
						 animations:^{
							 sharedView.frame = [self getWindowRect];
						 }
						 completion:nil
		 ];
	}
}

+(void)showLoading{
	[SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeGradient];
}
+(void)hideLoading{
	//[SVProgressHUD dismissWithAfterDelay:0.15f];
	[SVProgressHUD dismiss];
}

@end
