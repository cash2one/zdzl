//
//  ActivityPanel.h
//  TXSFGame
//
//  Created by efun on 13-3-11.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "WindowComponent.h"

typedef enum {
	ActivityType_key=1,		// 激活码兑换
	ActivityType_topup2=2,	// 充值2
	ActivityType_topup3=3,	// 充值3
	ActivityType_topup4=4,	// 充值4
	ActivityType_topup5=5,	// 充值5
} ActivityType;

@interface Frame : CCLayerColor{
	ccColor4B	boundColor;
}
@property(nonatomic,assign)ccColor4B boundColor;
@end


@class ButtonGroup;
@class ActivityTabGroup;

@interface ActivityPanel : WindowComponent
{
	NSMutableArray* activityArray;
	ActivityTabGroup *tabsManager;
	int selectRecord ;
}

@property(nonatomic,retain)ActivityTabGroup *tabsManager;

+(ActivityPanel*)shared;

-(void)moveTop:(BOOL)isTop;
-(void)doSelectMenu:(id)sender;

@end
