//
//  ActionMove.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-10-31.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface ActionMove : NSObject{
	
	NSMutableArray * targetPoints;
	
	BOOL isMove;
	CCNode * viewer;
	float speed;
	CGPoint startPoint;
	CGPoint targetPoint;
	
	float aTime;
	float fTime;
	
	CGPoint delta;
	
	SEL call;
	
	int distance;
	BOOL isNotChangeFlipX;
	int step;
	
}
@property(nonatomic,assign) BOOL isMove;
@property(nonatomic,assign) CCNode * viewer;
@property(nonatomic,assign) float speed;
@property(nonatomic,assign) SEL call;
@property(nonatomic,assign) int distance;
@property(nonatomic,assign) BOOL isNotChangeFlipX;

-(void)start;
-(void)moveTo:(NSArray*)points;

-(void)stop;
-(void)moveEnd;
-(void)update:(ccTime)time;
-(BOOL)isPrepareMoveEnd;

@end
