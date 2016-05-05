//
//  GameAlert.h
//  TXSFGame
//
//  Created by shoujun huang on 13-1-2.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GameAlert : CCSprite {
	id target;
	id argument;
	SEL call;
	CCNode* _father;//用于二级弹出框,存在father被提前释放的危险
}
@property(nonatomic,assign)id target;
@property(nonatomic,retain)id argument;
@property(nonatomic,assign)SEL call;
@property(nonatomic,assign)CCNode* father;

-(void)show;
-(void)remove;
@end
