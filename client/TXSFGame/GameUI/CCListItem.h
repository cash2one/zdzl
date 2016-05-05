//
//  CCListItem.h
//  TXSFGame
//
//  Created by shoujun huang on 12-11-26.
//  Copyright 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface CCListItem : CCNode{
	BOOL isEnabled_;
	BOOL isSelected_;
}
@property(nonatomic,assign)BOOL isSelect;
-(BOOL) isEnabled;
-(CGRect)rect; 
@end
