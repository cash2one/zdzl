//
//  WorldMap.h
//  TXSFGame
//
//  Created by huang shoujun on 13-1-19.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
@class AnimationRole;
@class RolePlayer;
@class NpcEffects;

@interface WorldMap : CCLayer {
	BOOL	bBack;
	
	BOOL    bAuto;
	
	float	offset;
	
	int		roleId;
	
	int		nextMap;
	int		_curMapIndex;
	int		_nextMapIndex;
	int		_towardIndex;
	
	AnimationRole* role;
	CCSprite *background;
	
	id target;
	SEL call;
}
@property(nonatomic,assign)id target;
@property(nonatomic,assign)SEL call;
@property(nonatomic,assign)BOOL bAuto;
@property(nonatomic,assign)int nextMap;
@property(nonatomic,assign)BOOL bBack;


+(void)show;
+(void)show:(int)mid target:(id)target call:(SEL)call;
+(void)stopAll;

+(BOOL)checkShowWorldMap:(int)_next now:(int)_now;

+(BOOL)isShow;

+(void)updateChapterMap:(int)_cid map:(int)_mid;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++

@end
