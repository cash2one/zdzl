//
//  InAppBrowser.m
//  TXSFGame
//
//  Created by TigerLeung on 13-4-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "InAppBrowser.h"
#import "ASDepthModalViewController.h"
#import <QuartzCore/QuartzCore.h>

#define BROWSER_SCALE 1.0f
#define BROWSER_BAR_HEIGHT 30.0f

@implementation InAppBrowser

+(void)show:(NSString*)url{
	[InAppBrowser show:url title:@""];
}

+(void)show:(NSString*)url title:(NSString*)title{
	CGRect screen = [[UIScreen mainScreen] bounds];
	CGRect rect = CGRectMake(0, 0, 
							 MAX(screen.size.width,screen.size.height)*BROWSER_SCALE, 
							 MIN(screen.size.width,screen.size.height)*BROWSER_SCALE);
	
	InAppBrowser * subView = [[[InAppBrowser alloc] initWithFrame:rect] autorelease];
	
	[subView setTitle:title];
	[subView setUrl:url];
	
	[ASDepthModalViewController presentView:subView];
	
}
+(void)hide{
	[ASDepthModalViewController dismiss];
}

-(id)initWithFrame:(CGRect)frame{
	if((self=[super initWithFrame:frame])!=nil){
		
		CGRect rect = CGRectMake(0, 0, frame.size.width, BROWSER_BAR_HEIGHT);
		
		UINavigationBar * navigationBar = [[[UINavigationBar alloc] initWithFrame:rect] autorelease];
		navigationBar.barStyle = UIBarStyleBlackTranslucent;
		
//		UIBarButtonItem *rightButton = [[[UIBarButtonItem alloc] 
//										 initWithTitle:@"关闭" 
//										 style:UIBarButtonItemStyleDone 
//										 target:[InAppBrowser class] 
//										 action:@selector(hide)] autorelease];
        UIBarButtonItem *rightButton = [[[UIBarButtonItem alloc]
										 initWithTitle:NSLocalizedString(@"browser_close",nil)
										 style:UIBarButtonItemStyleDone
										 target:[InAppBrowser class]
										 action:@selector(hide)] autorelease];
		
		navigationItem = [[[UINavigationItem alloc] initWithTitle:@""] autorelease];
		navigationItem.rightBarButtonItem = rightButton;
		navigationItem.hidesBackButton = YES;
		[navigationBar pushNavigationItem:navigationItem animated:NO];
		
		rect = CGRectMake(0, BROWSER_BAR_HEIGHT, frame.size.width, frame.size.height);
		
		background = [[[UIView alloc] initWithFrame:rect] autorelease];
		background.backgroundColor = [UIColor whiteColor];
		
		rect = CGRectMake(0, 0, frame.size.width, frame.size.height);
		
		webView = [[[UIWebView alloc] initWithFrame:rect] autorelease];
		webView.backgroundColor = [UIColor clearColor];
		//webView.opaque = NO;
		webView.scrollView.contentInset = UIEdgeInsetsMake(BROWSER_BAR_HEIGHT, 0.0, 0.0, 0.0);
		webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(BROWSER_BAR_HEIGHT, 0.0, 0.0, 0.0);
		webView.delegate = self;
		
		[self addSubview:background];
		[self addSubview:webView];
		[self addSubview:navigationBar];
		
		/*
		self.layer.cornerRadius = 6;
		self.layer.shouldRasterize = YES;
		self.layer.masksToBounds = YES;
		*/
		
	}
	return self;
}

-(void)setTitle:(NSString*)title{
	if(!title) title = @"";
	navigationItem.title = title;
}

-(void)setUrl:(NSString*)url{
	if(!url) return;
	if([url length]==0) return;
	if([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]){
		
	}else{
		url = [NSString stringWithFormat:@"http://%@",url];
	}
	
	[background setHidden:NO];
	
	NSURL * path = [NSURL URLWithString:url];
	[webView loadRequest:[NSURLRequest requestWithURL:path]];
	
}

#pragma mark UIWebViewDelegate
- (void)webViewDidStartLoad:(UIWebView *)webView{
	[background setHidden:NO];
}
-(void)webViewDidFinishLoad:(UIWebView*)webView{
	[background setHidden:YES];
}
-(void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error{
	[background setHidden:YES];
}

@end
