//
//  UnionCreate.h
//  TXSFGame
//
//  Created by Max on 13-3-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "StretchingImg.h"
#import "CCLabelFX.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "GameConfigure.h"
#import "CCPanel.h"
#import "UnionViewer.h"

@interface UnionCreate : CCLayer<UITextFieldDelegate> {
	CCLayer * content;
	
	int tmp_page;
	int tmp_count;
	
	
	NSMutableArray * alls;

}

@end
