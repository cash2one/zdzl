//
//  GameUIRoleHead.h
//  TXSFGame
//
//  Created by chao chen on 12-11-13.
//  Copyright 2012 eGame. All rights reserved.
//

#import <GameKit/GameKit.h>
#import "cocos2d.h"
#import "CCMenuEx.h"
#import "GameConnection.h"
#import "Config.h"
#import "MapManager.h"

////======================


@interface TransparentSprite : CCSprite

@end

@interface GameUIRoleHead : CCLayerColor{
	NSInteger bt_uncoiledDir;////展开按钮方向	
	CCMenu *roleHeadUIMenu;////头像区菜单z:1
	CCMenu *peiJiangMenu;////配将菜单z:1
	//
	BOOL isRoleHeadUIMenu;
	BOOL isPeiJiangMenu;
	BOOL bOpen;
}

////更新头像区
-(void)updateAll;

-(void)updateStatus:(Map_Type)_type;

-(void)updateMoneyWithYuanBao01:(NSInteger)value01 yuanBao02:(NSInteger)value02 yinBi:(NSInteger)value03;
-(void)updateTeamMember:(NSArray*)array;///
-(void)updateLevel:(NSInteger)level;
-(void)updateRoleName:(NSString*)name;
-(void)updateVIP:(NSInteger)vip;
-(void)updateRoleHead:(NSInteger)headID;

@end
