//
//  ActivityPanel.m
//  TXSFGame
//
//  Created by efun on 13-3-11.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "ActivityPanel.h"
#import "Config.h"
#import "CCPanelPage.h"
#import "ButtonGroup.h"
#import "CCSimpleButton.h"

@interface ActivityItem : CCSprite
{
	CCSprite *bg;
	CCSprite *selectedIcon;
}

@property (nonatomic) BOOL isSelected;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *tips;

@end

@implementation ActivityItem

@end

@implementation ActivityPanel

@end
