//
//  ArenaTeamPanel.h
//  TXSFGame
//
//  Created by Max on 13-5-24.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
//#import "ArenaTeamDataNET.h"

@class ArenaTeamDataNET;

@interface ArenaTeamPanel : CCLayer {
    ArenaTeamDataNET *atp;
}

+(ArenaTeamPanel*)start;

@end
