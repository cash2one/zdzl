//
//  CarViewerContent.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-20.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "RolePlayer.h"
#import "BaseLoaderViewerContent.h"

@class GameLoaderHelper;
@class AnimationViewer;
@interface CarViewerContent : BaseLoaderViewerContent{
	
	int car_id;
	RoleDir roleDir;
	int scaleX;
	AnimationViewer * car;
	int isDir;
}

@property (nonatomic,assign)int carOffset;
@property (nonatomic,assign)int shadowSize;
@property (nonatomic,assign)int inSkyHigh;

-(void)loadTargetCar:(int)cid dir:(RoleDir)_dir scaleX:(int)_scaleX;

-(void)updateDir:(RoleDir)_dir scaleX:(int)_scaleX;

@end
