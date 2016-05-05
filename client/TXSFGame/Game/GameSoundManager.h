//
//  GameSoundManager.h
//  TXSFGame
//
//  Created by TigerLeung on 13-2-14.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimpleAudioEngine.h"
#import "MapManager.h"

@interface GameSoundManager : NSObject{
	SimpleAudioEngine * sae;
	BOOL isPlaying;
	
	int bgIndex;
	
	BOOL isPlayBackgroundMusic;
	BOOL isPlayEffectMusic;
}

@property(nonatomic,assign) BOOL isPlayBackgroundMusic;
@property(nonatomic,assign) BOOL isPlayEffectMusic;

+(GameSoundManager*)shared;
+(void)stopAll;

-(void)playWelcome;

-(void)pauseBackgroundMusic;
-(void)stopBackgroundMusic;

-(void)playBackgroundMusic;
-(void)playBackgroundMusicByType:(Map_Type)type mid:(int)mid;

-(void)playFightBackgroundMusic;
-(void)playFightBossBackgroundMusic;

-(void)playWiner;

-(void)click;

@end
