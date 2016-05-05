//
//  GameStart.h
//  TXSFGame
//
//  Created by TigerLeung on 12-12-10.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "intro.h"
//#import "Nd91Manager.h"

@class CCScrollLayer;
@class CCLabelFX;
@class CCPanel;
@interface CCSimpleContentLayer : CCLayerColor{
	
}

@end

@interface GameStart : CCLayer <UITextFieldDelegate>{
	
	CCMenu * menu;
	CCLayer * content;
	CCScrollLayer * scrollLayer;
	
	CCLayer * layer_start;
	CCLayer * layer_server;
	CCLayer * layer_create;
	CCLayer * layer_list;
	
	int select_role_id;
	int currenRoleIndex;
	NSString * select_role_name;
	NSString * input_role_name;
	CCLabelFX * name_label;
	NSMutableArray *randomName1;
	NSMutableArray *randomLastName1;
	
	NSMutableArray *randomName0;
	NSMutableArray *randomLastName0;
	int sex;
	UITextField * nameInput;
	//int touchDis;
	
	BOOL isLoadPlayerList;
	int selectServerId;
	
	CCNode * server1;
	CCNode * server2;
	CCNode * selectTarget;
	CCSprite * listPlayer;
	
	BOOL isShowPlayerList;
	BOOL isHidePlayerList;
	//CCSprite * note_bg;
	CCPanel *panel;
	
	NSArray * serverPlayrs;
}

+(void)show;
+(void)hide;

+(void)create;
+(void)list;

+(BOOL)isOpen;

+(void)updateUserInfo;

/*
+(BOOL)isShowServerList;
+(void)showPlayerList;
*/

+(GameStart*)share;

@end

@interface GameStartRole : CCSprite<CCTouchOneByOneDelegate>{
	
	id target;
	SEL call;
	
	NSDictionary * info;
//	int touchDis;
}
@property(nonatomic,assign) NSDictionary * info;
@property(nonatomic,assign) BOOL select;
@property(nonatomic,assign) id target;
@property(nonatomic,assign) SEL call;

-(void)loadViewer;
-(void)moveTo:(CGPoint)tp isMove:(BOOL)isMove;

@end
