//
//  MainMenu.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-16.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameConfigure.h"
#import "Config.h"
#import "Game.h"
#import "intro.h"
#import "CCSimpleButton.h"



@interface MainMenu : CCLayer
{
    bool                        m_bOpenMenu;
//    CCMenu*                     m_Menu;//右下方的菜单项
//	//fix chao
//	CCMenu*                     m_controlMenu;//右下方的菜单项
	//end
    //----------------------------
    NSMutableArray              *m_HImageItems; //存放右下方菜单项X方向的TAG
    NSMutableArray              *m_VImageItems;//存放右下方菜单项Y方向的TAG
	//fix chao
    NSMutableArray              *m_HIphoneImageItems;//存放iphone右下方菜单项X方向的TAG
    NSMutableArray              *m_VIphoneImageItems;//存放iphone右下方菜单项Y方向的TAG
    //end
	CCSimpleButton	*controlButton;
	CCLayer	*buttonLayer;
    
    //
    CCLabelFX *exeSprite;
}

@property(nonatomic,assign)bool OpenMenu;
+(MainMenu*)share;
+(id) getInstance;
+(int)totalButtons;

-(int)buttonCount;

-(NSString*)getImage:(MENU_TAG)tag;
-(void) menuCallbackBack: (id) sender;//菜单功能的回调函数
-(void) loadMenuItemList;
-(void) initAllButton;
//-(CCMenuItem*)getMenuItem:(MENU_TAG)tag;
-(CCSimpleButton *)getButtonWithTag:(MENU_TAG)tag;
-(void) addMenuItem:(int)tag Dir:(int)dir;
-(void) removeMenuItem:(int)tag Dir:(int)dir;
-(void) removeAllMenuItem;
//fix chao
-(void)closeMenu;
-(void)unfoldMenu;
-(void)updateExp;
//end
-(void)showFireEffectWithTag:(int)tag;
-(void)hideFireEffectWithTag:(int)tag;
@end