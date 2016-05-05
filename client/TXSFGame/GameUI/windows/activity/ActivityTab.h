//
//  ActivityTab.h
//  TXSFGame
//
//  Created by Soul on 13-4-16.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"

@interface ActivityTab : CCSprite {
	CCSprite* spriteNormal;
	CCSprite* spriteSelect;
	
	NSString* name;
	NSString* tips;
	
	BOOL	isSelected;
	
	int		_activityId;
	Activity_Type _type;
	
	id		target;
	SEL		call;
}

@property(nonatomic,assign)Activity_Type type;
@property(nonatomic,assign)int activityId;

@property(nonatomic,assign)id  target;
@property(nonatomic,assign)SEL call;
@property(nonatomic,assign)BOOL	isSelected;


-(void)setName:(NSString*)_name;
-(void)setTips:(NSString*)_tips;

-(BOOL)checkTouch:(UITouch*)touch;

@end

