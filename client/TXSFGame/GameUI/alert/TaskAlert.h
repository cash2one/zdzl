//
//  TaskAlert.h
//  TXSFGame
//
//  Created by shoujun huang on 13-1-2.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameAlert.h"

@class Task;
@interface TaskAlert : GameAlert<CCTouchOneByOneDelegate> {
	Task *task;
	//fix chao
	BOOL isMenuTouch;
	//end
	BOOL bNeedInfo;
	BOOL bTouchDelay;
}
@property(nonatomic,assign)Task *task;
@property(nonatomic,assign)BOOL bNeedInfo;
@end
