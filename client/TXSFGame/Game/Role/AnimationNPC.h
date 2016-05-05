//
//  AnimationNPC.h
//  TXSFGame
//
//  Created by chao chen on 12-11-6.
//  Copyright 2012 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "Config.h"
#import "AnimationViewer.h"

@class AnimationViewer;
@class GameLoaderHelper;
@interface AnimationNPC : AnimationViewer{
	int npc_id;
	GameLoaderHelper * helper;
    //
    int npc_suitId;
    int npc_dir;
}

-(void)showAnimationByNPCId:(int)npcId;
-(void)showAnimationByROLEId:(int)roleId suitId:(int)suitId dir:(int)dir;
@end
