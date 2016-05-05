//
//  Widget.h
//  TXSFGame
//
//  Created by Soul on 13-5-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface Widget : CCNode {
	BOOL	_touchEvent;
	id		_target;
	SEL		_call;
	id		_arg;
}

@property(nonatomic,assign)BOOL		touchEvent;
@property(nonatomic,assign)id		target;
@property(nonatomic,assign)SEL		call;
@property(nonatomic,retain)id		arg;


-(void)doEvent;
-(void)freeEvent;
-(void)resetStatus;

-(BOOL)focusWidget:(Widget*)widget;

-(BOOL)checkEvent:(UITouch*)touch;
-(BOOL)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event;
-(void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event;
-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event;
-(void)touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event;

@end
