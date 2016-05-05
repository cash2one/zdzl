//
//  MessageContainer.h
//  TXSFGame
//
//  Created by Soul on 13-7-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "CCLayer.h"
#import "Config.h"

@class MessageHelper;

@interface MessageContainer : CCLayer{
	Channel_type	channelId;
	int				space;
	int				defaultWidth;
}
@property(nonatomic,assign)Channel_type channelId;
@property(nonatomic,assign)int defaultWidth;
@property(nonatomic,assign)int space;

+(MessageContainer*)create:(Channel_type)_channelId;
-(void)insertLabel:(MessageHelper*)_helper;
-(void)pushLabel:(MessageHelper*)_helper;
-(int)peekSerialNumber;
-(int)getPaintHeight;

@end
