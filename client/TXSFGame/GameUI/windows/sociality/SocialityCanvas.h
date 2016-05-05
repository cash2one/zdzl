//
//  SocialityCanvas.h
//  TXSFGame
//
//  Created by efun on 13-3-19.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "SocialHelper.h"

// 玩家项
@interface SocialityItem : CCLayer
{
	NSString *_name;
}

@property (nonatomic) int pid;
@property (nonatomic) int rid;
@property (nonatomic) int level;
@property (nonatomic) int status;
@property (nonatomic) BOOL isSelected;
@property (nonatomic, retain) NSString *name;

@end

@interface SocialityCanvas : CCLayerColor
{
	CCLabelTTF *moreLabel;
	BOOL isLoading;
	CGSize parentSize;
}

@property (nonatomic) int totalCount;
@property (nonatomic) int onlineCount;

-(SocialityItem*)getEventTray:(UITouch*)touch;

-(void)removeSelected;
-(void)updateMembers:(NSDictionary *)dict clear:(BOOL)clear;
-(void)addMember:(NSDictionary *)dict;
-(void)deleteMember:(NSDictionary *)dict;

-(BOOL)checkMore;

@end
