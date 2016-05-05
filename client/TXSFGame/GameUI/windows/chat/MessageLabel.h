//
//  MessageLabel.h
//  TXSFGame
//
//  Created by Soul on 13-7-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"

@class MessageHelper;

@interface MessageLabel : CCSprite{
	NSArray*		message;
	int				messageWidth;
	int				messageHeight;
}
@property(nonatomic,retain)NSArray* message ;
@property(nonatomic,assign)int messageWidth;
@property(nonatomic,assign)int messageHeight;

+(MessageLabel*)create:(MessageHelper*)_helper dimension:(CGSize)_size;

@end
