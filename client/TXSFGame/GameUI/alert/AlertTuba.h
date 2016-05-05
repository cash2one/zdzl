//
//  AlertTuba.h
//  TXSFGame
//
//  Created by Max on 13-3-8.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Config.h"
#import "Game.h"

@class AlertTuba;



@interface TubaContent : CCLayer{
	AlertTuba *target;
	
}

@end


@interface AlertTuba : CCLayer {
	CCSprite *left;
	CCSprite *rigth;
	CCLayerColor *bg;
	TubaContent *tc;
	bool isOpen;
}


@property(nonatomic,assign)CGSize screenSize;

+(AlertTuba*)share;
-(void)closeTuBa;
-(void)addPost:(NSString*)string;




@end
