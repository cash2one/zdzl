//
//  ArenaTeamDataNET.m
//  TXSFGame
//
//  Created by Max on 13-5-24.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "ArenaTeamDataNET.h"
#import "GameConnection.h"



@implementation ArenaTeamDataNET

@synthesize selector;
@synthesize target;

static ArenaTeamDataNET* arenaTeamDataNET;
+(ArenaTeamDataNET*)share{
	if(!arenaTeamDataNET){
		arenaTeamDataNET=[[ArenaTeamDataNET alloc]init];
	}
	return arenaTeamDataNET;
}

-(id)init{
	if(self=[super init]){
		selector=nil;
		target=nil;
	}
	return self;
}

-(void)request:(NSString*)command arg:(NSString*)arg{
	[GameConnection request:command format:arg target:self call:@selector(didRequest:)];
}


-(void)didRequest:(NSDictionary*)data{
	[self performSelector:selector withObject:data];
}


-(void)dealloc{
	[super dealloc];
}

@end
