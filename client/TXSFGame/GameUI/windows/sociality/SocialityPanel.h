//
//  SocialityPanel.h
//  TXSFGame
//
//  Created by Soul on 13-3-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCPanel.h"
#import "Config.h"
#import "SocialityAction.h"
#import "SocialityCanvas.h"
#import "SocialityManager.h"
#import "WindowComponent.h"

@interface SocialityPanel : WindowComponent <UITextFieldDelegate> {
	
	SocialityType currentType;	// 当前tab对应的类型
	
	SocialityAction *_friendAction;
	SocialityAction *_onlineAction;
	SocialityAction *_blacklistAction;
	SocialityAction *_currentAction;
	
	SocialityManager *manager;
	
	UITextField *keyInput;
	SocialityType justShowBoxType;
}

@property (nonatomic,assign)SocialityType justShowBoxType;

//-(void)update:(NSArray *)array;
//-(void)removeWithTag:(int)tag;
//-(void)insert:(NSDictionary *)dict atIndex:(int)index;

+(SocialityPanel *)shared;
-(void)setAction:(CGPoint)point playerId:(int)pid name:(NSString *)name;
+(void)openAddTypeBox:(SocialityType)var :(CCNode*)par;

// 判断是否点击中action
-(BOOL)checkTouchAction:(CGPoint)point;
// 隐藏action
-(void)hideAction;

@end
