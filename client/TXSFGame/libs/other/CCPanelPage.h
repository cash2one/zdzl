//
//  CCPanelPage.h
//  TXSFGame
//
//  Created by efun on 13-3-8.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "CCPanel.h"

// 基于CCPanel
// CCPanel横向翻页

@class ClipPageLayer;

@interface CCPanelPage : CCPanel
{
	ClipPageLayer *pageContent;
}

+(CCPanelPage*)panelWithContent:(CCNode*)_content viewSize:(CGSize)_vSize;
+(CCPanelPage*)panelWithContent:(CCNode*)_content viewPosition:(CGPoint)_vPotion viewSize:(CGSize)_vSize;

-(void)updateContentPosition:(CGPoint)_pt;

@end
