//
//  HammerPanel.h
//  TXSFGame
//
//  Created by shoujun huang on 12-12-1.
//  Copyright 2012年 chao chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCLayerList.h"
#import "Config.h"
#import "WindowComponent.h"

@interface EquipmentIcon : CCSprite{
	int quality;
	int ueid;
	int eid;
	int level;
	CGPoint target;
	BOOL isSelect;
	BOOL isMoving;
}
@property(nonatomic,assign)BOOL isMoving;
@property(nonatomic,assign)BOOL isSelect;
@property(nonatomic,assign)int quality;
@property(nonatomic,assign)int eid;
@property(nonatomic,assign)int level;
@property(nonatomic,assign)CGPoint target;
@property(nonatomic,assign)int ueid;
-(void)updateLevel:(int)_level;
-(void)updateEquipment:(int)_eid;
-(void)showLevelSetting:(BOOL)_bool;
-(CGRect)rect;
@end

@interface HammerPanel : WindowComponent<CCListDelegate>{
	CCMenu *windowMenu;
	
	BOOL isDisplayEffect;
	BOOL isMove;
    BOOL isSende;
}
@end
