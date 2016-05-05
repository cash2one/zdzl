//
//  MessageContainer.m
//  TXSFGame
//
//  Created by Soul on 13-7-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "MessageContainer.h"
#import "MessageManager.h"
#import "MessageLabel.h"
#import "GameConnection.h"


@implementation MessageContainer

@synthesize defaultWidth;
@synthesize channelId;
@synthesize space;

/*
 @discussion 创建一个指定频道的MessageContainer
 @result MessageContainer
 */
+(MessageContainer*)create:(Channel_type)_channelId{
	MessageContainer* container = [MessageContainer node];
	container.channelId = _channelId;
	return container;
}

-(id)init{
	if ((self = [super init]) != nil) {
		space = cFixedScale(4);
	}
	return self ;
}

-(void)onEnter{
	[super onEnter];
//	NSArray* array = [[MessageManager shared] getChatsWithChanel:channelId];
//	for (MessageHelper* helper in array) {
//		[self pushLabel:helper];
//	}
	[GameConnection addPost:MessageHelper_add target:self call:@selector(addMessage:)];
	[GameConnection addPost:MessageHelper_delete target:self call:@selector(removeMessage:)];
}

-(void)addMessage:(NSNotification*)data{
	MessageHelper* _messageHelper = data.object;
	if (_messageHelper) {
		[self insertLabel:_messageHelper];
	}
}

-(void)removeMessage:(NSNotification*)data{
	NSNumber* __number = data.object;
	if (__number) {
		[self removeChildByTag:[__number intValue] cleanup:YES];
	}
}
-(void)onExit{
	[GameConnection removePostTarget:self];
	[super onExit];
}
/*
 @param MessageLabel
 @discussion 在MessageContainer中的最下面插入一个 MessageHelper
 @result
 */
-(void)insertLabel:(MessageHelper *)_helper{
	
	if (_helper == nil) {
		return ;
	}
	/*
	if (channelId != CHANNEL_ALL) {
		if ([_helper getChannel] != channelId) {
			return ;
		}
	}
	if ([self getChildByTag:_helper.serialNumber]) {
		//重复添加了
		return ;
	}
	 */
	MessageLabel* label = [MessageLabel create:_helper dimension:CGSizeMake(400, 40)];
	[self insert:label];
}
/*
 @param MessageLabel
 @discussion 在MessageContainer中的最后面压入一个 MessageHelper
 @result
 */
-(void)pushLabel:(MessageHelper *)_helper{
	if (_helper == nil) {
		return ;
	}
	/*
	if (channelId != CHANNEL_ALL) {
		if ([_helper getChannel] != channelId) {
			return ;
		}
	}
	if ([self getChildByTag:_helper.serialNumber]) {
		//重复添加了
		return ;
	}
	MessageLabel* label = [MessageLabel create:_helper dimension:CGSizeMake(400, 40)];
	[self push:label];
	*/
	CCLOG(@"paintY=%d",[self getPaintHeight]);
}
/*
 @param MessageLabel
 @discussion 在MessageContainer中的最后面压入一个 MessageLabel
 @result
 */
-(void)push:(MessageLabel *)label{
	float pointY = [self getPaintHeight];
	label.anchorPoint = CGPointZero;
	label.position = ccp(0, pointY);
	[self addChild:label z:0];
}
/*
 @param MessageLabel
 @discussion 在MessageContainer中的最下面插入一个 MessageLabel
 @result
 */
-(void)insert:(MessageLabel *)label{
	CGPoint gap = ccp(0, label.contentSize.height + space);
	CCNode * _iterator = nil;
	CCARRAY_FOREACH(_children, _iterator) {
		CGPoint pt = _iterator.position;
		_iterator.position = ccpAdd(pt, gap);
	}
	label.anchorPoint = CGPointZero;
	label.position = CGPointZero;
	[self addChild:label z:0];
	CCLOG(@"paintY=%d",[self getPaintHeight]);
}
/*
 @discussion 返回整个MessageContainer中最后那个MessageLabel的序列号
 @result 序列号，如果返回的是-1 代表失败
 */
-(int)peekSerialNumber{
	int serial = -1;
	CCNode * _iterator = nil;
	CCARRAY_FOREACH(_children, _iterator) {
		serial = _iterator.tag;
	}
	return serial;
}
/*
 @discussion 返回整个MessageContainer的实际绘制高度是多少
 @result 绘制高度
 */
-(int)getPaintHeight{
	CCNode * _iterator = nil;
	float pointY = 0 ;
	CCARRAY_FOREACH(_children, _iterator) {
		pointY += _iterator.contentSize.height ;
		pointY += space;
	}
	return pointY;
}
@end
