//
//  AnimationViewer.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-10-31.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "cocos2d.h"

@interface AnimationHelper : NSObject{
	int tag;
	
	id target;
	SEL result;
	
	int max_count;
	NSMutableArray * frames;
	
	BOOL isComplete;
	
}
@property(nonatomic,assign) int tag;
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL result;

+(AnimationHelper*)loadFileByFileFullPath:(NSString*)filePath name:(NSString*)name target:(id)target result:(SEL)result;
+(AnimationHelper*)loadFileByFileFullPath:(NSString*)filePath target:(id)target result:(SEL)result;

@end

@interface AnimationViewer : CCSprite{
	id target;
	SEL removeCall;
	AnimationHelper * help;
}
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL removeCall;

-(void)remove;

+(BOOL)checkHasAnimation:(NSString*)filePath;
+(NSArray*)loadFileByFileFullPath:(NSString*)filePath name:(NSString*)name;

-(void)showAnimationByPath:(NSString*)filePath;
-(void)showAnimationByPathForever:(NSString*)filePath;
-(void)showAnimationByPathOne:(NSString*)filePath;

-(void)playAnimation:(NSArray*)ary;
-(void)playAnimation:(NSArray*)ary call:(id)call;

-(void)playAnimation:(NSArray*)ary delay:(float)delay;
-(void)playAnimation:(NSArray*)ary delay:(float)delay call:(id)call;
-(void)playAnimationAndClean:(NSArray*)ary;



@end
