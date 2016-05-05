//
//  Alert.h
//  TXSFGame
//
//  Created by shoujun huang on 13-1-2.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface Alert : CCSprite {
	id target;
	id argument;
	SEL call;
}
@property(nonatomic,assign)id target;
@property(nonatomic,retain)id argument;
@property(nonatomic,assign)SEL call;

-(void)show;
-(void)remove;
@end
