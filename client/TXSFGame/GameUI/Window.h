//
//  Window.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-15.
//  Copyright 2012 Soul. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"
#import "MainMenu.h"


@interface Window : CCLayer {
	
}

+(Window*)shared;
+(void)stopAll;
+(BOOL)checkPlayerCanRun;
+(void)cleanMemory;
+(void)destroy;

-(int)showWindow:(WINDOW_TYPE)_type;
-(int)showWindow:(WINDOW_TYPE)_type only:(BOOL)_only;
-(int)showWindow:(WINDOW_TYPE)_type dictionary:(NSDictionary*)_dict;

-(void)removeWindow:(WINDOW_TYPE) _type;
-(void)removeAllWindows;
-(int)showWindowByUnlock:(Unlock_object)_unlock;

-(BOOL)isHasWindowByType:(WINDOW_TYPE)type;
-(BOOL)isHasWindow;

-(BOOL)checkCanRunTask;
-(BOOL)checkCanTouchNpc;


@end
