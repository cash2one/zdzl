//
//  FishGear.h
//  TXSFGame
//
//  Created by efun on 13-2-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "AnimationViewer.h"

@interface FishGearViewer : AnimationViewer
{
	id fishTarget;
	SEL fishCall;
}
@property (nonatomic, retain) id fishTarget;
@property (nonatomic) SEL fishCall;

-(void)run:(NSArray *)frames;
-(void)runForever:(NSArray *)frames;

@end

@interface FishGear : CCLayer
{
	id target;
	SEL call;
	
	BOOL fishStart;
	
	NSArray *loopFrames;
	NSArray *gearFrames;
	NSMutableArray *reverseGearFrames;
	
	NSMutableArray *fishGears;
	
	FishGearViewer *currentViewer;
}
@property (nonatomic, retain) id target;
@property (nonatomic) SEL call;
@property (nonatomic, retain) NSMutableArray *points;

-(void)showStart:(int)index;
-(void)showStop:(int)index;

-(void)fishCallback;

-(void)removeAll;

@end
