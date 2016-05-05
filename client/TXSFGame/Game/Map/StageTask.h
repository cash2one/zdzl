//
//  StageTask.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-21.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StageTask : NSObject{
	id target;
	SEL call;
	
	int step;
	NSArray * data;
	
}

@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL call;
@property(nonatomic,assign) NSArray * data;

+(void)stopAll;
+(void)show:(NSArray*)data target:(id)target call:(SEL)call;
+(void)remove;
+(BOOL)isTalking;

@end
