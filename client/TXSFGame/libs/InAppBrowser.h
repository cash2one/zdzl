//
//  InAppBrowser.h
//  TXSFGame
//
//  Created by TigerLeung on 13-4-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface InAppBrowser : UIView<UIWebViewDelegate>{
	UIView * background;
	UINavigationItem * navigationItem;
	UIWebView * webView;
}

+(void)show:(NSString*)url;
+(void)show:(NSString*)url title:(NSString*)title;
+(void)hide;

@end
