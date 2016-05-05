//
//  GameSoundManager.m
//  TXSFGame
//
//  Created by TigerLeung on 13-2-14.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "GameSoundManager.h"
#import "GameConfigure.h"

@implementation GameSoundManager

@synthesize isPlayBackgroundMusic;
@synthesize isPlayEffectMusic;

static NSString * backgroundMusic[] = {
	
	@"sounds/stage.mp3",
	@"sounds/union.mp3",
	@"sounds/chapter_1.mp3",
	@"sounds/fight1.mp3",
	@"sounds/fight2.mp3",
	@"sounds/winer.mp3",
	@"sounds/buttonClick.mp3",
	@"",
	@"",
	@"",
	@"",
	
	@"sounds/map_1.mp3",
	@"sounds/map_2.mp3",
	@"sounds/map_5.mp3",
	@"sounds/map_7.mp3",
	
};

//#define MUSIC_SETTING_PLAY_BG @"MUSIC_SETTING_PLAY_BG"
//#define MUSIC_SETTING_PLAY_EF @"MUSIC_SETTING_PLAY_EF"

#define MUSIC_SETTING_PLAY_VOL @"zl_music_vol_value"
#define MUSIC_SETTING_PLAY_BG @"zl_music_bg"
#define MUSIC_SETTING_PLAY_EF @"zl_music_ef"

static GameSoundManager * gameSoundManager;

+(GameSoundManager*)shared{
	if(gameSoundManager==nil){
		gameSoundManager = [[GameSoundManager alloc] init];
	}
	return gameSoundManager;
}

+(void)stopAll{
	if(gameSoundManager){
		[gameSoundManager release];
		gameSoundManager = nil;
	}
}

-(id)init{
	if((self=[super init])!=nil){
		
		NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
		//float setting_vol = [defaults floatForKey:MUSIC_SETTING_PLAY_VOL];
		float setting_vol = 0.6f;
		
		sae = [SimpleAudioEngine sharedEngine];
		sae.backgroundMusicVolume = 1.0 * setting_vol;
		//sae.backgroundMusicVolume = 0.6;
		
		//load isPlayBackgroundMusic & isPlayEffectMusic
		//isPlayBackgroundMusic	= [defaults boolForKey:MUSIC_SETTING_PLAY_BG];
		//isPlayEffectMusic		= [defaults boolForKey:MUSIC_SETTING_PLAY_EF];
		
		bgIndex = -1;
		
	}
	return self;
}

-(void)dealloc{
	
	[SimpleAudioEngine end];
	gameSoundManager = nil;
	sae = nil;
	
	[super dealloc];
}

-(void)saveSettings{
	NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:isPlayBackgroundMusic forKey:MUSIC_SETTING_PLAY_BG];
	[defaults setBool:isPlayEffectMusic forKey:MUSIC_SETTING_PLAY_EF];
	[defaults synchronize];
}

-(void)setIsPlayBackgroundMusic:(BOOL)_isPlayBackgroundMusic{
	isPlayBackgroundMusic = _isPlayBackgroundMusic;
	[self saveSettings];
	
	if(isPlayBackgroundMusic){
		[self playBackgroundMusic];
	}else{
		[self stopBackgroundMusic];
	}
}
-(void)setIsPlayEffectMusic:(BOOL)_isPlayEffectMusic{
	isPlayEffectMusic = _isPlayEffectMusic;
	[self saveSettings];
}

-(void)playWelcome{
	
	if(!isPlayBackgroundMusic) return;
	
	[sae playBackgroundMusic:backgroundMusic[2]];
	
	isPlaying = YES;
	
}

-(void)pauseBackgroundMusic{
	[sae pauseBackgroundMusic];
}

-(void)stopBackgroundMusic{
	isPlaying = NO;
	[sae stopBackgroundMusic];
}

-(void)playBackgroundMusic{
	
	if(!isPlayBackgroundMusic) return;
	
	[self playBackgroundMusicByType:[MapManager shared].mapType 
								mid:[MapManager shared].mapId];
	
	isPlaying = YES;
	
}

-(void)playBackgroundMusicByType:(Map_Type)type mid:(int)mid{
	
	if([[GameConfigure shared] isPlayerOnChapter]){
		if(isPlaying){
			[sae resumeBackgroundMusic];
		}else{
			[sae playBackgroundMusic:backgroundMusic[2]];
		}
		return;
	}
	
	int index = -1;
	
	if(type==Map_Type_Standard){
		if(mid==1){
			index = 11;
		}else if(mid==2 || mid==3 || mid==4){
			index = 12;
		}else if(mid==5){
			index = 13;
		}else if(mid==6){
			index = 0;
		}else if(mid==7 || mid==8 || mid==27 || mid==28 || mid==29 || mid==35 || mid==36){
			index = 14;
		}
	}else if(type==Map_Type_Stage){
		index = 0;
	}else if(type==Map_Type_Fish){
		index = 11;
	}else if(type==Map_Type_Mining){
		index = 11;
	}else if(type==Map_Type_TimeBox){
		index = 0;
	}else if(type==Map_Type_Abyss){
		index = 0;
	}else if(type==Map_Type_WorldBoss){
		index = 0;
	}else if(type==Map_Type_UnionBoss){
		index = 0;
	}else if(type==Map_Type_Union){
		index = 1;
	}else if(type==Map_Type_SysPvp){
		index = 12;
	}else if(type==Map_Type_dragonReady){
		index = 0;
	}else if(type==Map_Type_dragonFight){
		index = 0;
	}
	
	int totalMusic = (sizeof(backgroundMusic)/sizeof(backgroundMusic[0]));
	if(index>=0 && index<totalMusic){
		if(bgIndex==index && isPlaying){
			[sae resumeBackgroundMusic];
			return;
		}
		[sae playBackgroundMusic:backgroundMusic[index]];
		bgIndex = index;
	}
	
}

-(void)playFightBackgroundMusic{
	if(!isPlayBackgroundMusic) return;
	[self stopBackgroundMusic];
	[sae playBackgroundMusic:backgroundMusic[3]];
}

-(void)playFightBossBackgroundMusic{
	if(!isPlayBackgroundMusic) return;
	[self stopBackgroundMusic];
	[sae playBackgroundMusic:backgroundMusic[4]];
}

-(void)playWiner{
	if(!isPlayEffectMusic) return;
	[sae playEffect:backgroundMusic[5]];
}

-(void)playEffect:(NSString*)_file{
	if(!isPlayEffectMusic) return;
	if(!_file) return ;
	[sae playEffect:_file];
}

-(void)click{
	if(!isPlayEffectMusic) return;
	[sae playEffect:backgroundMusic[6]];
}

@end
