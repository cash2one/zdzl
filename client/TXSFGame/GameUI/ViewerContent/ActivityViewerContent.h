//
//  ActivityViewerContent.h
//  TXSFGame
//
//  Created by TigerLeung on 13-4-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseLoaderViewerContent.h"

@class GameLoaderHelper;
@class AnimationViewer;


#define FUNC_url	@"url"
#define FUNC_win	@"win"
#define FUNC_input	@"input"

@interface ActivityViewerContent : BaseLoaderViewerContent{
	NSDictionary * activity;
	
	id target;
	SEL call;
}
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL call;

+(ActivityViewerContent*)create:(NSDictionary*)data;
+(NSString*)getFunctionType:(NSDictionary*)dict;
+(id)getFunctionAction:(NSDictionary*)dict;
//hide keyboard
+(void) hideKeyboard:(ActivityViewerContent*) keywin;

-(int)getActivityId;
@end
