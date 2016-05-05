//
//  BaseGameConfig.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-3.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaseGameConfig : NSObject{
	
	int userId;
	int serverId;
	NSMutableDictionary * userInfo;
	
	int playerId;
	NSMutableDictionary * gameRecord;
	
}
@property(nonatomic,assign) int userId;
@property(nonatomic,assign) int serverId;
@property(nonatomic,readonly) NSMutableDictionary * userInfo;

@property(nonatomic,assign) int playerId;

-(void)start;

-(void)save:(NSString*)username password:(NSString*)password;
-(void)savePlayerList:(NSArray*)players;
-(void)addPlayerToList:(NSDictionary*)player;

-(NSArray*)getPlayerList;

-(void)initPlayerData:(NSDictionary*)data;
-(void)resetPlayerData:(NSDictionary*)data;

-(void)addData:(id)data key:(NSString*)key;
-(id)getDataBykey:(NSString*)key;

-(void)addLocalData:(id)data key:(NSString*)key;
-(NSDictionary*)getLocalData;
//-(id)getLocalDataBykey:(NSString*)key;

@end
