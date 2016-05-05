//
//  RoleViewerContent.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-20.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "BaseLoaderViewerContent.h"

@class GameLoaderHelper;
@class AnimationViewer;
@interface RoleViewerContent:BaseLoaderViewerContent{
	int roleId;
	int equipId;
	AnimationViewer * roleAnima;
	int dir;
	BOOL isLoaded;
}
@property(nonatomic,assign) int dir;

-(void)loadTargetRole:(int)rid;
-(void)loadTargetOtherRole:(int)rid eid:(int)eid;

-(void)showStand;
-(void)showSkill;
-(void)showSkillByEndCall:(CCAction*)action;
@end
