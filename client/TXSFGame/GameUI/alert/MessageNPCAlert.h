//
//  MessageNPCAlert.h
//  TXSFGame
//
//  Created by TigerLeung on 13-2-1.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameAlert.h"

@interface MessageNPCAlert : GameAlert<CCTouchOneByOneDelegate> {
	
	SEL canel;
	NSString *message;
	
	int npcId;
	BOOL isHasNpcFunc;
	
}
@property(nonatomic,assign)SEL canel;
@property(nonatomic,retain)NSString *message;
@property(nonatomic,assign)int npcId;

@end

