//
//  MessageLabel.m
//  TXSFGame
//
//  Created by Soul on 13-7-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "MessageLabel.h"
#import "Config.h"
#import "CCNode+AddHelper.h"
#import "MessageManager.h"

@implementation MessageLabel

@synthesize message;
@synthesize messageWidth;
@synthesize messageHeight;


+(MessageLabel*)create:(MessageHelper *)_helper dimension:(CGSize)_size{
	if (_helper) {
		MessageLabel* label = [MessageLabel node];
		//[label setTag:_helper.serialNumber];
		//[label setMessage:_helper.messageInfo];
		[label setMessageHeight:_size.height];
		[label setMessageWidth:_size.width];
		[label showContent];
		return label ;
	}
	return nil ;
}

-(void)draw{
	[super draw];
	ccDrawColor4B(255, 0, 0, 200);
	ccDrawRect(CGPointZero, ccp(self.contentSize.width, self.contentSize.height));
}

-(void)dealloc{
	[super dealloc];
}

-(void)onExit{
	if (message) {
		[message release];
		message = nil ;
	}
	[super onExit];
}

-(void)onEnter{
	[super onEnter];
}

-(void)showContent{
	if (message && message.count == 3) {
		NSString *name=[NSString stringWithFormat:@"%@",[message objectAtIndex:2]];
		NSString *msg=[NSString stringWithFormat:@"%@",[message objectAtIndex:1]];
		NSString* channelName = [self getChannelName:[[message objectAtIndex:0] intValue]];
		//
		//todo show message
		//
		NSString* result = nil ;
		if ([@"" isEqualToString:name]) {
			result = [NSString stringWithFormat:@"[%@] %@",channelName,msg];
		}else{
			result = [NSString stringWithFormat:@"[%@] %@: %@",channelName,name,msg];
		}
		
		if (result) {
			CCSprite* spr = drawString(result, CGSizeMake(messageWidth,messageHeight), getCommonFontName(FONT_1),18,20, @"FFFFFF");
			self.contentSize = spr.contentSize;
			[self Category_AddChildToCenter:spr z:0];
		}
	}
}

-(NSString*)getChannelName:(int)_cid{
	switch (_cid) {
		case 1:
			return NSLocalizedString(@"chat_send_world",nil) ;
		case 6:
			return NSLocalizedString(@"chat_send_system",nil) ;
		case 3:
			return NSLocalizedString(@"chat_send_reproducer",nil) ;
		case 4:
			return NSLocalizedString(@"chat_send_union",nil) ;
		case 5:
			return NSLocalizedString(@"chat_send_private",nil) ;
	}
	return @"";
}

@end
