//
//  TipsBox.h
//  TXSFGame
//
//  Created by efun on 12-12-3.
//  Copyright (c) 2012年 chao chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"
#import "StretchingImg.h"
#import "Window.h"

@interface TipsBox : CCLayerColor

@property (nonatomic, retain) CCLabelTTF *tipsLabel;

//-(id)initWithString:(NSString *)string width:(float)width height:(float)height;

+(void)showMessage:(NSString *)message;
+(void)showMessage:(NSString *)message position:(CGPoint)pos;
//+(void)createWithString:(NSString *)string;
//+(void)createWithString:(NSString *)string width:(float)width height:(float)height;

@end
