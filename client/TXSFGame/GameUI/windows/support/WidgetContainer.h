//
//  WidgetContainer.h
//  TXSFGame
//
//  Created by Soul on 13-5-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Widget.h"

@interface WidgetContainer : Widget{
	CGPoint layoutPt;
}

-(Widget*)touchWidget:(UITouch*)touch;


-(void)alignWidgets;
-(void)alignWidgetsVertically;
-(void)alignWidgetsVerticallyWithPadding:(float)padding;

-(void)alignWidgetsHorizontally;
-(void)alignWidgetsHorizontallyWithPadding:(float)padding;

-(void)adjustPosition:(CGPoint)pt;
-(void)slidToPosition:(CGPoint)pt;
-(void)returning;

-(BOOL)checkHorizontally;
-(BOOL)checkVertically;

@end
