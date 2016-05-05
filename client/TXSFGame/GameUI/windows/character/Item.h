//
//  Item.h
//  TXSFGame
//
//  Created by Soul on 13-3-8.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

@class GameLoaderHelper;

@interface Item : CCSprite {
	int				_level;
	int				_count;
	ItemQuality		_quality;
	
	Item_type		_iType;
	
	GameLoaderHelper * helper;
	NSString * targetPath;
}

@property(nonatomic,assign)Item_type iType;
@property(nonatomic,assign)int level;
@property(nonatomic,assign)int count;
@property(nonatomic,assign)ItemQuality quality;


+(Item*)create:(NSString*)_path quality:(int)_qua count:(int)_cut level:(int)_lv;
+(Item*)createByIcon:(CCSprite*)icon quality:(int)_qua count:(int)_cut level:(int)_lv;

-(void)showOther:(BOOL)_isShow;


@end
