//
//  ActivityEDLogin.h
//  TXSFGame
//
//  Created by Max on 13-5-20.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface PockerFace : CCNode{
	CCSprite *backsp;
	CCSprite *frontsp;
	
	
};


@property (nonatomic,retain) NSString *ftpath;
@property (nonatomic,assign) bool isPlayFlipx;
+(PockerFace*)creatPockerFace:(NSString*)path;
-(void)setItemInfo:(NSDictionary*)dict FlipX:(bool)f mask:(bool)m count:(int)c;
-(void)playFlip ;
-(void)showHand;

@end



@interface ActivityEDLogin : CCLayer {
    int maxLuckDrawTime;
	int hasLuckDrawTime;
	bool drawLuckCoolDown;
	int coolDownTouch;
    //
    BOOL isEDLoginSend;
    //
}

+(void)checkMaxhasLuckTime;


@end




