//
//  MailList.h
//  TXSFGame
//
//  Created by TigerLeung on 13-1-6.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface MailList : CCLayerColor{
	NSMutableArray * btns;
	CCLayerColor * content;
}

+(MailList*)shared;
+(void)moveTop;
+(void)moveDown;

-(void)showMailList;
-(void)removeMailAction:(int)mid;

@end
