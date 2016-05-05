//
//  JewelPanel.h
//  TXSFGame
//
//  Created by Soul on 13-5-13.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "WindowComponent.h"

@interface JewelPanel : WindowComponent
{
	int roleId;
	int maxCount;
	
	NSMutableArray *countArray;
	NSMutableDictionary *jewelHole;
}

@end
