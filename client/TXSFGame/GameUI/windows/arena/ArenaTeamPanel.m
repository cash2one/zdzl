//
//  ArenaTeamPanel.m
//  TXSFGame
//
//  Created by Max on 13-5-24.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ArenaTeamPanel.h"
#import "ArenaTeamDataNET.h"


@implementation ArenaTeamPanel

static ArenaTeamPanel *arenaTeamPanel;

+(ArenaTeamPanel*)start{
	arenaTeamPanel=[ArenaTeamPanel node];
	return arenaTeamPanel;
}


-(void)onEnter{
	[super onEnter];
	
	atp=[ArenaTeamDataNET share];
	atp.selector=@selector(didNetCallBack:);
	atp.target=self;
	
}

-(void)onExit{
	[atp release];
	[super onExit];
}

-(void)didNetCallBack:(NSDictionary*)data{
	
}

@end
