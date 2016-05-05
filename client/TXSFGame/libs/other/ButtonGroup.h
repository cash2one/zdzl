//
//  ButtonGroup.h
//  TXSFGame
//
//  Created by Soul on 13-2-1.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

/*
 * 用于创建互斥的菜单事件
 * 使用例子:
 CCMenuItem *menuItem1 = [CCMenuItemImage itemWithNormalImage:@"images/ui/button/bt_all_get_1.png"
 selectedImage:@"images/ui/button/bt_all_get_3.png"
 block:^(id sender) {
 CCLOG(@"1");
 }];
 CCMenuItem *menuItem2 = [CCMenuItemImage itemWithNormalImage:@"images/ui/button/bt_all_synthesize_1.png"
 selectedImage:@"images/ui/button/bt_all_synthesize_3.png"
 block:^(id sender) {
 CCLOG(@"2");
 }];
 
 CCMenuItem *menuItem3 = [CCMenuItemImage itemWithNormalImage:@"images/ui/button/bt_allpurple_1.png"
 selectedImage:@"images/ui/button/bt_allpurple_3.png"
 block:^(id sender) {
 CCLOG(@"3");
 }];
 ButtonGroup *groups =[ButtonGroup menuWithItems:menuItem1, menuItem2, menuItem3, nil];
 groups.position = ccp(500, 400);
 [groups alignItemsVerticallyWithPadding:10];
 [groups setSelectedItem:menuItem1];
 [groups setTouchPriority:-101];
 [self addChild:groups];
 */

@interface ButtonGroup : CCMenu {
    CCMenuItem *m_Item;
}

-(void)setSelectedItem:(CCMenuItem*)_item;

@end
