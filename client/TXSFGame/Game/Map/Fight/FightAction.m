//
//  FightAction.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-22.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "FightAction.h"
#import "GameConfigure.h"
#import "FightTeam.h"
#import "FightMember.h"
#import "FightStatus.h"
#import "Config.h"
#import "FightManager.h"

#import "CJSONDeserializer.h"
#import "CJSONSerializer.h"
#import "GameDB.h"

static int sortMember(FightMember*p1, FightMember*p2, void*context){
	//NSString * methodName = context;
	//SEL methodSelector = NSSelectorFromString(methodName);
	//id value1 = objc_msgSend(p1, methodSelector);
	//id value2 = objc_msgSend(p2, methodSelector);
	
	if(p1.speed < p2.speed) return NSOrderedDescending;
	if(p1.speed > p2.speed) return NSOrderedAscending;
	
	BaseAttribute ba1 = [p1 getTotalAttribute];
	BaseAttribute ba2 = [p2 getTotalAttribute];
	
	if(ba1.DEX < ba2.DEX) return NSOrderedDescending;
	if(ba1.DEX > ba2.DEX) return NSOrderedAscending;
	
	if(p1.level < p2.level) return NSOrderedDescending;
	if(p1.level > p2.level) return NSOrderedAscending;
	
	return NSOrderedSame;
}

@implementation FightAction
@synthesize fightId;
@synthesize roundIndex;

static FightAction * fightAction;

+(void)stopAll{
	if(fightAction){
		[fightAction release];
		fightAction = nil;
	}
}

+(void)startFight:(int)fid{
	if(fightAction==nil){
		fightAction = [[FightAction alloc] init];
		fightAction.fightId = fid;
		[fightAction loadTeamsFromFight];
	}
}

+(void)startFightWorldBoss:(NSDictionary *)data{
	
	if(fightAction==nil){
		fightAction = [[FightAction alloc] init];
		[fightAction loadTeamsFromWorldBoss:data];
	}
	
}

+(void)startFightAbyss:(NSDictionary*)data{
	if(fightAction==nil){
		fightAction = [[FightAction alloc] init];
		[fightAction loadTeamsFromFightAbyss:data];
	}
}

+(void)startCustomizeFight:(NSDictionary *)data{
	if(fightAction==nil){
		fightAction = [[FightAction alloc] init];
		[fightAction loadTeamsFromCustomizeFight:data];
	}
}

+(void)startByPlayer:(NSDictionary*)data{
	if(fightAction==nil){
		fightAction = [[FightAction alloc] init];
		[fightAction loadTeamsFromPlayer:data];
	}
}
+(void)startByTeam:(NSDictionary*)data fight:(int)fid{
	if(fightAction==nil){
		fightAction = [[FightAction alloc] init];
		fightAction.fightId = fid;
		[fightAction loadTeamsFromTeam:data];
	}
}

+(void)startByTeams:(NSDictionary*)data{
	if(fightAction==nil){
		fightAction = [[FightAction alloc] init];
		fightAction.fightId = 0;
		[fightAction loadTeamsFromTeams:data];
	}
}
//chao TODO
//狩龙战NPC战
+(void)startFightDragonByNPC:(NSDictionary*)data fight:(int)fid{
    if(fightAction==nil){
		fightAction = [[FightAction alloc] init];
		fightAction.fightId = fid;
		[fightAction loadDragonByNPCData:data];
	}
}
//chao TODO
//狩龙战影分身
+(void)startFightDragonByPlayer:(NSDictionary*)data{
    if(fightAction==nil){
		fightAction = [[FightAction alloc] init];
		fightAction.fightId = 0;
		[fightAction loadDragonByPlayerData:data];
	}
}

+(void)cleanFight{
	if(fightAction!=nil){
		[fightAction removeAllObjects];
		[fightAction release];
		fightAction = nil;
	}
}

-(void)removeAllObjects{
	if(targetTeam){
		[targetTeam release];
		targetTeam = nil;
	}
	if(userTeam){
		[userTeam release];
		userTeam = nil;
	}
	if(allMember){
		[allMember release];
		allMember = nil;
	}
	if(allTeamInfo){
		[allTeamInfo release];
		allTeamInfo = nil;
	}
	if(allActionInfo){
		[allActionInfo release];
		allActionInfo = nil;
	}
}

-(void)dealloc{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[self removeAllObjects];
	
	[super dealloc];
	
	CCLOG(@"FightAction remove");
}

-(void)initFightData{
	
	allMember = [[NSMutableArray alloc] init];
	targetTeam = [[FightTeam alloc] init];
	userTeam = [[FightTeam alloc] init];
	
	targetTeam.classIndex = 0;
	userTeam.classIndex = 1;
	
	targetTeam.playerId = 0;
	userTeam.playerId = [GameConfigure shared].playerId;
	
	NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
	userTeam.level = [[player objectForKey:@"level"] intValue];
	userTeam.icon = [[player objectForKey:@"rid"] intValue];
	userTeam.icon_type = Fight_team_icon_type_role;
	
	roundIndex = 0;
}

-(void)loadTeamsFromFight{
	
	[self initFightData];
	
	if(fightId==3){
		[self getCustomFightData];
		return;
	}
	
	if(fightId>0){
		
		int level = 1;
		
		NSDictionary * info = [[GameDB shared] getFightInfo:fightId];
		for(int i=0;i<15;i++){
			NSString * key = [NSString stringWithFormat:@"s%d",(i+1)];
			FightMember * member = [FightMember memberOfFightData:[info objectForKey:key]];
			if(member){
				member.index = i;
				
				member.targetTeam = userTeam;
				member.selfTeam = targetTeam;
				member.fightAction = self;
				
				[targetTeam addMember:member];
				[allMember addObject:member];
				
				if(member.level>level) level = member.level;
				
			}
		}
		
		targetTeam.level = level;
		targetTeam.icon = [[info objectForKey:@"icon"] intValue];
		targetTeam.icon_type = Fight_team_icon_type_momster;
		
		[self loadPlayerTeam:nil isLoadOtherBuff:YES];
		[self logTeamInfo:[info objectForKey:@"BG"]];
		[self fightRound];
		
	}
	
}

-(void)loadTeamsFromWorldBoss:(NSDictionary*)data{
	[self initFightData];
	//todo 创建世界BOSS
	if (data != nil) {
		
		int monsterId = [[data objectForKey:@"mid"] intValue];
		int level = [[data objectForKey:@"level"] intValue];
		int curBlood = [[data objectForKey:@"curHp"] intValue];
		NSString* _bg = [data objectForKey:@"bg"];
		
		FightMember* member = [FightMember memberOfMonsterId:monsterId level:level];
		
		if(member){
			//写死
			member.index = 4;
			
			member.targetTeam = userTeam;
			member.selfTeam = targetTeam;
			member.fightAction = self;
			
			//免疫全部技能
			member.isImmunityStatus = YES;
			
			//设定当前血量
			if (curBlood < member.currentHP) {
				member.currentHP = curBlood;
			}
			
			member.beginHp = member.currentHP ;
			
			[targetTeam addMember:member];
			[allMember addObject:member];
			
		}
		
		targetTeam.level = level;
		targetTeam.icon = monsterId;//icon ;
		targetTeam.icon_type = Fight_team_icon_type_momster;
		
		NSDictionary* buffDict = [data objectForKey:@"buff"];
		if (buffDict) {
			[userTeam logTeamBuff:buffDict type:Fight_Buff_Type_worldBoss];
		}
		
		[self loadPlayerTeam:buffDict isLoadOtherBuff:YES];
		[self logTeamInfo:_bg];
		[self fightRound];
		
	}
}

-(void)loadTeamsFromCustomizeFight:(NSDictionary*)data{
	[self initFightData];
	
	int fid = [[data objectForKey:@"fid"] intValue];
	
	if(fid>0){
		
		int level = 1;
		
		NSDictionary * info = [[GameDB shared] getFightInfo:fid];
		for(int i=0;i<15;i++){
			NSString * key = [NSString stringWithFormat:@"s%d",(i+1)];
			FightMember * member = [FightMember memberOfFightData:[info objectForKey:key]];
			if(member){
				member.index = i;
				
				member.targetTeam = userTeam;
				member.selfTeam = targetTeam;
				member.fightAction = self;
				
				[targetTeam addMember:member];
				[allMember addObject:member];
				
				if(member.level>level) level = member.level;
				
			}
		}
		
		targetTeam.level = level;
		targetTeam.icon = [[info objectForKey:@"icon"] intValue];
		targetTeam.icon_type = Fight_team_icon_type_momster;
		
		int pid = [[data objectForKey:@"posId"] intValue];
		int plevel = [[data objectForKey:@"posLevel"] intValue];
		
		NSArray* array = [data objectForKey:@"roles"];
		
		[self loadNpcTeam:pid posLevel:plevel role:array];
		
		[self logTeamInfo:[info objectForKey:@"BG"]];
		[self fightRound];
		
	}
}

-(void)loadTeamsFromPlayer:(NSDictionary*)data{
	[self initFightData];
	
	NSDictionary * player = [data objectForKey:@"player"];
	NSDictionary * pos = [data objectForKey:@"position"];
	
	NSDictionary * position = nil;
	int posId = [[player objectForKey:@"posId"] intValue];
	
	targetTeam.playerId = [[player objectForKey:@"id"] intValue];
	targetTeam.level = [[player objectForKey:@"level"] intValue];
	targetTeam.icon = [[player objectForKey:@"rid"] intValue];
	targetTeam.icon_type = Fight_team_icon_type_role;
	
	for(NSDictionary * p in pos){
		if([[p objectForKey:@"id"] intValue]==posId){
			position = p;
			break;
		}
	}
	
	//todo 数据错误跳出战斗
	
	if(position){
		
		NSArray * roles = [data objectForKey:@"roles"];
		
		for(int i=0;i<15;i++){
			NSString * key = [NSString stringWithFormat:@"s%d",(i+1)];
			int rid = [[position objectForKey:key] intValue];
			
			BOOL isHasRole = NO;
			for(NSDictionary * rr in roles){
				int rid_ = [[rr objectForKey:@"rid"] intValue];
				if(rid_==rid){
					isHasRole = YES;
					break;
				}
			}
			if(!isHasRole) continue;
			
			NSMutableDictionary * tmp = [NSMutableDictionary dictionaryWithDictionary:data];
			[tmp setObject:position forKey:@"choosePosition"];
			
			FightMember * member = [FightMember memberOfRoleId:rid playerData:tmp];
			if(member){
				member.index = i;
				
				member.targetTeam = userTeam;
				member.selfTeam = targetTeam;
				member.fightAction = self;
				
				[targetTeam addMember:member];
				[allMember addObject:member];
				
			}
		}
		
		[self loadPlayerTeam:nil isLoadOtherBuff:NO];
		[self logTeamInfo:@"fsyspvp"];
		[self fightRound];
		
	}else{
		CCLOG(@"Error");
	}
	
}

-(void)loadTeamsFromTeam:(NSDictionary*)data{
	
	if(fightId<1) return;
	
	[self initFightData];
	
	int level = 1;
	NSDictionary * info = [[GameDB shared] getFightInfo:fightId];
	for(int i=0;i<15;i++){
		NSString * key = [NSString stringWithFormat:@"s%d",(i+1)];
		FightMember * member = [FightMember memberOfFightData:[info objectForKey:key]];
		if(member){
			member.index = i;
			
			member.targetTeam = userTeam;
			member.selfTeam = targetTeam;
			member.fightAction = self;
			
			[targetTeam addMember:member];
			[allMember addObject:member];
			
			if(member.level>level) level = member.level;
		}
	}
	
	targetTeam.level = level;
	targetTeam.icon = [[info objectForKey:@"icon"] intValue];
	targetTeam.icon_type = Fight_team_icon_type_momster;
	
	[self loadPlayersByTeamData:data];
	[self logTeamInfo:[info objectForKey:@"BG"]];
	
	[self fightRound];
	
}

-(void)loadTeamsFromTeams:(NSDictionary*)data{
	
	[self initFightData];
	
	[self loadTargetsByTeamData:[data objectForKey:@"team2"]];
	[self loadPlayersByTeamData:[data objectForKey:@"team1"]];
	
	[self logTeamInfo:@"fsyspvp"];
	
	[self fightRound];
	
}

-(void)loadTeamsFromFightAbyss:(NSDictionary*)data{
	
	[self initFightData];
	
	NSDictionary * globalConfig = [[GameDB shared] getGlobalConfig];
	float deepGuard1Rate = [[globalConfig objectForKey:@"deepGuard1Rate"] floatValue];
	float deep10Rate = [[globalConfig objectForKey:@"deep10Rate"] floatValue];
	int floorIndex = [[data objectForKey:@"floorIndex"] intValue];
	int targetId = [[data objectForKey:@"targetId"] intValue];
	int deepBossStart = [[globalConfig objectForKey:@"deepBossStart"] intValue];
	float deepBossRate = [[globalConfig objectForKey:@"deepBossRate"] floatValue];
	
	deep10Rate = deep10Rate * (floorIndex/10);
	deepBossRate = deepBossRate * MAX(0, floorIndex-deepBossStart);
	
	//load other buff in teams
	NSDictionary * ubuff = [data objectForKey:@"buff"];
	NSDictionary * gbuff = [data objectForKey:@"gbuff"];
	
	[targetTeam logTeamBuff:gbuff type:Fight_Buff_Type_abyss];
	[userTeam logTeamBuff:ubuff type:Fight_Buff_Type_abyss];
	
	int level = [[data objectForKey:@"level"] intValue];
	int pid = [[data objectForKey:@"pid"] intValue];
	
	Abyss_Target_Type type = [[data objectForKey:@"type"] intValue];
	targetTeam.level = level;
	targetTeam.icon = targetId;
	if(type==Abyss_Target_Type_role){
		targetTeam.icon_type = Fight_team_icon_type_npc;
	}else{
		targetTeam.icon_type = Fight_team_icon_type_momster;
	}
	
	if(type==Abyss_Target_Type_monster || type==Abyss_Target_Type_role){
		
		NSDictionary * position = [[GameDB shared] getPositionLevelInfo:pid level:1];
		NSMutableArray * roles = [NSMutableArray arrayWithArray:[data objectForKey:@"rids"]];
		
		for(int i=0;i<15;i++){
			NSString * key = [NSString stringWithFormat:@"s%d",(i+1)];
			
			NSString * t = [position objectForKey:key];
			if(![t isEqualToString:@"0"] && [t length]>0){
				
				if([roles count]>0){
					
					int tid = [[roles objectAtIndex:0] intValue];
					[roles removeObjectAtIndex:0];
					
					FightMember * member;
					if(type==Abyss_Target_Type_role){
						
						member = [FightMember memberOfSingleRoleId:tid level:level];
						[member setFightRate:deepGuard1Rate];
						[member addFightRate:deep10Rate];
						
						
					}else if(type==Abyss_Target_Type_monster){
						
						member = [FightMember memberOfMonsterId:tid level:level];
						[member addFightRate:deep10Rate];
						
					}
					
					if(member){
						member.index = i;
						
						member.targetTeam = userTeam;
						member.selfTeam = targetTeam;
						member.fightAction = self;
						
						//TODO add position buff ?
						//[member addBuffByString:t];
//						[member addBuffByDict:gbuff];
						
						[targetTeam addMember:member];
						[allMember addObject:member];
					}
					
				}
			}
		}
	}else if(type==Abyss_Target_Type_boss){
		
		int bid = [[data objectForKey:@"bid"] intValue];
		FightMember * member = [FightMember memberOfMonsterId:bid level:level];
		member.index = 4; //center point
		member.targetTeam = userTeam;
		member.selfTeam = targetTeam;
		member.fightAction = self;
		
		//TODO
		//没有用
//		[member addBuffByDict:gbuff];
		
		[member addFightAbyssBossRate:deepBossRate];
		
		[targetTeam addMember:member];
		[allMember addObject:member];
		
		targetTeam.icon_type = Fight_team_icon_type_momster;
		targetTeam.icon = bid;
//		targetTeam.icon = 90003;
		
	}
	
	[self loadPlayerTeam:ubuff isLoadOtherBuff:YES];
	[self logTeamInfo:[data objectForKey:@"BG"]];
	[self fightRound];
	
}

-(void)loadNpcTeam:(int)_posid posLevel:(int)_posLevel role:(NSArray*)roles{
	NSDictionary * positionLevel = [[GameDB shared] getPositionLevelInfo:_posid level:_posLevel];
	for (NSDictionary* dict in roles) {
		int _rid = [[dict objectForKey:@"rid"] intValue];
		int _level = [[dict objectForKey:@"rlevel"] intValue];
		BOOL isCap = [[dict objectForKey:@"isCap"] boolValue];
		NSString *pos = [dict objectForKey:@"s"];
		NSString *index = [pos substringFromIndex:1];
		
		FightMember * member = [FightMember memberOfNpc:_rid level:_level];
		if (member) {
			
			NSString * posAdd = [positionLevel objectForKey:pos];
			[member addPosition:posAdd];
			
			int _index = [index intValue] - 1 ;
			_index = _index < 0 ? 0 : _index ;
			member.index = _index;//
			
			member.targetTeam = targetTeam;
			member.selfTeam = userTeam;
			member.fightAction = self;
			
			[userTeam addMember:member];
			[allMember addObject:member];
			
			//todo

			if (isCap) {
				userTeam.icon=_rid;
				userTeam.level=_level;
			}
		}
	}
}

-(void)loadPlayerTeam:(id)buff isLoadOtherBuff:(BOOL)isLoad{
	
	//load other buff in userTeam
	NSDictionary * footBuff = [[GameConfigure shared] getPlayerBuffByType:Buff_Type_foot];
	if(footBuff){
		NSDictionary * bd = getFormatToDict([footBuff objectForKey:@"buff"]);
		[userTeam logTeamBuff:bd type:Fight_Buff_Type_foot];
	}
	
	NSDictionary * userPosition = [[GameConfigure shared] getUserChoosePosition];
	
	//position level buffs
	int posid = [[userPosition objectForKey:@"posId"] intValue];
	int posLevel = [[userPosition objectForKey:@"level"] intValue];
	
	//soul
	//NSDictionary * positionLevel = [[GameConfigure shared] getPosition:posid level:posLevel];
	NSDictionary * positionLevel = [[GameDB shared] getPositionLevelInfo:posid level:posLevel];
	
	//Player level
	int level = [[GameConfigure shared] getPlayerLevel];
	for(int i=0;i<15;i++){
		NSString * key = [NSString stringWithFormat:@"s%d",(i+1)];
		int rid = [[userPosition objectForKey:key] intValue];
		NSDictionary *role = [[GameConfigure shared] getPlayerRoleFromListById:rid];
		if (role) {
			int status = [[role objectForKey:@"status"] intValue];
			if (RoleStatus_in == status) {
				FightMember * member = [FightMember memberOfRoleId:rid level:level];
				if(member){
					
					member.isLoadOtherBuff = isLoad;
					
					NSString * posAdd = [positionLevel objectForKey:key];
					[member addPosition:posAdd];
					
					member.index = i;
					member.targetTeam = targetTeam;
					member.selfTeam = userTeam;
					member.fightAction = self;
					//
                    member.quality = [[role objectForKey:@"q"] intValue];
                    //
					if(buff!=nil){
						if([buff isKindOfClass:[NSDictionary class]]) [member addBuffByDict:buff];
						if([buff isKindOfClass:[NSString class]]) [member addBuffByString:buff];
					}
					
					[userTeam addMember:member];
					[allMember addObject:member];
					
				}
			}
		}
	}
}

-(void)loadPlayersByTeamData:(NSDictionary*)data{
	[self loadTeamInfoByData:data team:userTeam target:targetTeam];
}
-(void)loadTargetsByTeamData:(NSDictionary*)data{
	[self loadTeamInfoByData:data team:targetTeam target:userTeam];
}

-(void)loadTeamInfoByData:(NSDictionary*)data team:(FightTeam*)team target:(FightTeam*)target{
	NSArray * players = [data objectForKey:@"players"];
	NSDictionary * position = [data objectForKey:@"mb"];
	
	NSDictionary * playerInfo = [self getPlayerInfoBy:players 
											   target:[[data objectForKey:@"lid"] intValue]];
	team.icon = [[playerInfo objectForKey:@"rid"] intValue];
	team.level = [[playerInfo objectForKey:@"level"] intValue];
	team.icon_type = Fight_team_icon_type_role;
	
	for(NSString * pkey in position){
		
		NSDictionary * teamInfo = [position objectForKey:pkey];
		int pid = [[teamInfo objectForKey:@"pid"] intValue];
		int rid = [[teamInfo objectForKey:@"rid"] intValue];
		NSDictionary * playerData = [self getPlayerDataBy:players target:pid];
		
		FightMember * member = [FightMember memberOfRoleId:rid playerData:playerData];
		if(member){
			
			member.index = [pkey intValue];
			member.targetTeam = target;
			member.selfTeam = team;
			member.fightAction = self;
			
			[team addMember:member];
			[team addPlayer:pid];
			
			[allMember addObject:member];
		}
	}
}
//chao TODO
//狩龙战NPC战
-(void)loadDragonByNPCData:(NSDictionary*)data{
    //chao TODO
    if (data) {
        [self initFightData];
        
        int level = 1;
        NSDictionary *attrs_dict = [data objectForKey:@"attrs"];
        NSDictionary *anc_info_dict = [[GameDB shared] getAwarNpcConfig:fightId];
        NSDictionary * info = [[GameDB shared] getFightInfo:[[anc_info_dict objectForKey:@"fid"] intValue]];
        for(int i=0;i<15;i++){
            NSString * key = [NSString stringWithFormat:@"s%d",(i+1)];
            key = [info objectForKey:key];
            if([key length]>0){
                NSArray * a = [key componentsSeparatedByString:@":"];
                
                if ([a count]>0) {
                    NSDictionary *t_dict = [attrs_dict objectForKey:[a objectAtIndex:0]];
                    if (t_dict) {
                    //FightMember * member = [FightMember memberOfMonsterId:[[t_dict objectForKey:@"mid"] intValue] level:[[t_dict objectForKey:@"level"] intValue]];
                        FightMember * member = [FightMember memberOfMonsterDict:t_dict];
                        if(member){
                            member.index = i;
                            
                            member.targetTeam = userTeam;
                            member.selfTeam = targetTeam;
                            member.fightAction = self;
                            
                            [targetTeam addMember:member];
                            [allMember addObject:member];
                            
                            if(member.level>level) level = member.level;
                        }
                    }
                }
            }
        }
        
        targetTeam.level = level;
        targetTeam.icon = [[info objectForKey:@"icon"] intValue];
        targetTeam.icon_type = Fight_team_icon_type_momster;
		NSDictionary *buff_dict = [data objectForKey:@"pbuff"];
		[self loadPlayerTeam:buff_dict isLoadOtherBuff:YES];
        
//        targetTeam.icon_type = Fight_team_icon_type_momster;
//        
//        [self loadPlayersByTeamData:data];
        [self logTeamInfo:[info objectForKey:@"BG"]];
        
        [self fightRound];

    }else{
        CCLOG(@"-------data:is null");
    }
}
//chao TODO
//狩龙战影分身
-(void)loadDragonByPlayerData:(NSDictionary*)data{
    //chao TODO
    if (data) {
        [self initFightData];
        
        NSDictionary * player = [data objectForKey:@"player"];
        NSDictionary * pos = [data objectForKey:@"position"];
        
        NSDictionary * position = nil;
        int posId = [[player objectForKey:@"posId"] intValue];
        
        targetTeam.playerId = [[player objectForKey:@"id"] intValue];
        targetTeam.level = [[player objectForKey:@"level"] intValue];
        targetTeam.icon = [[player objectForKey:@"rid"] intValue];
        targetTeam.icon_type = Fight_team_icon_type_role;
        
        for(NSDictionary * p in pos){
            if([[p objectForKey:@"id"] intValue]==posId){
                position = p;
                break;
            }
        }
        
        //todo 数据错误跳出战斗
        
        if(position){
            
            NSArray * roles = [data objectForKey:@"roles"];
            
            for(int i=0;i<15;i++){
                NSString * key = [NSString stringWithFormat:@"s%d",(i+1)];
                int rid = [[position objectForKey:key] intValue];
                
                BOOL isHasRole = NO;
                for(NSDictionary * rr in roles){
                    int rid_ = [[rr objectForKey:@"rid"] intValue];
                    if(rid_==rid){
                        isHasRole = YES;
                        break;
                    }
                }
                if(!isHasRole) continue;
                
                NSMutableDictionary * tmp = [NSMutableDictionary dictionaryWithDictionary:data];
                [tmp setObject:position forKey:@"choosePosition"];
                
                FightMember * member = [FightMember memberOfRoleId:rid playerData:tmp];
                if(member){
                    member.index = i;
                    
                    member.targetTeam = userTeam;
                    member.selfTeam = targetTeam;
                    member.fightAction = self;
                    
                    [targetTeam addMember:member];
                    [allMember addObject:member];
                    
                }
            }
            NSDictionary *buff_dict = [data objectForKey:@"pbuff"];
            [self loadPlayerTeam:buff_dict isLoadOtherBuff:YES];
            [self logTeamInfo:@"fsyspvp"];
            [self fightRound];
            
        }else{
            CCLOG(@"Error");
        }
    }else{
        CCLOG(@"-------data:is null");
    }
}
-(NSDictionary*)getPlayerDataBy:(NSArray*)players target:(int)pid{
	for(NSDictionary * player in players){
		NSDictionary * info = [player objectForKey:@"player"];
		if([[info objectForKey:@"id"] intValue]==pid){
			return player;
		}
	}
	return nil;
}

-(NSDictionary*)getPlayerInfoBy:(NSArray*)players target:(int)pid{
	NSDictionary * player = [self getPlayerDataBy:players target:pid];
	if(player){
		return [player objectForKey:@"player"];
	}
	return nil;
}



-(void)fightRound{
	
	[allMember sortUsingFunction:sortMember context:nil];
	
	//start fight
	for(FightMember * member in allMember){
		[member fight];
		CCLOG(@"\n\n");
	}
	
	
	//记录伤害
	[targetTeam logMemberDamages];
	[userTeam logMemberDamages];
	
	//remove die member
	NSMutableArray * dies = [NSMutableArray array];
	for(FightMember * member in allMember){
		if([member isDie]){
			[dies addObject:member];
		}
	}
	
	for(FightMember * member in dies){
		[allMember removeObject:member];
		[targetTeam removeMember:member];
		[userTeam removeMember:member];
	}
	
	CCLOG(@"\n\n");
	CCLOG(@"=========================");
	CCLOG(@"=======End Round=========");
	CCLOG(@"=========================");
	CCLOG(@"\n\n");
	
	if([targetTeam isKillAll]){
		
		CCLOG(@"roundIndex->%d",roundIndex);
		
		[FightManager shared].dieLeftkindCount = [userTeam getDieLeftkindCount];
		
		[FightManager shared].targetDamages = targetTeam.damages;
		[FightManager shared].userDamages = userTeam.damages;
		
		//this end all fight
		[self logActionEnd:userTeam];
		[self resultAllFightLog:YES];
		
		return;
	}
	if([userTeam isKillAll]){
		
		CCLOG(@"roundIndex->%d",roundIndex);
		
		[FightManager shared].dieLeftkindCount = [targetTeam getDieLeftkindCount];
		
		[FightManager shared].targetDamages = targetTeam.damages;
		[FightManager shared].userDamages = userTeam.damages;
		
		//this end all fight
		[self logActionEnd:targetTeam];
		[self resultAllFightLog:NO];
		return;
	}
	
	//end round
	for(FightMember * member in allMember){
		[member roundEnd];
	}
	[self logAction:[NSString stringWithFormat:@"%d",Fight_Action_Log_Type_round]];
	
	//next Round
	roundIndex++;
	//[self fightRound];
	
	[NSTimer scheduledTimerWithTimeInterval:(getRandomInt(1,5)/1000.0f)
									 target:self 
								   selector:@selector(fightRound) 
								   userInfo:nil
									repeats:NO];
	
}

//==============================================================================
#pragma mark -
//==============================================================================

-(void)getCustomFightData{
	
	//记录两队人的数据
	allTeamInfo = [NSMutableDictionary dictionary];
	[allTeamInfo retain];
	
	if(fightId==3){
		
		targetTeam.level = 99;
		targetTeam.icon_type = Fight_team_icon_type_momster;
		targetTeam.icon = 43;
		
		FightMember * boss = [FightMember memberOfFightData:@"43:130"];
		if(boss){
			
			
			if(iPhoneRuningOnGame()){
				boss.index = 1;
			}else{
				boss.index = 4;
			}
			
			boss.targetTeam = userTeam;
			boss.selfTeam = targetTeam;
			boss.fightAction = self;
			
			[targetTeam addMember:boss];
			[allMember addObject:boss];
		}
		
		int level = [[GameConfigure shared] getPlayerLevel];
		FightMember * member = [FightMember memberOfRoleId:35 level:level];
		if(member){
			member.index = 7;
			member.targetTeam = targetTeam;
			member.selfTeam = userTeam;
			member.fightAction = self;
			
			[userTeam addMember:member];
			[allMember addObject:member];
			
		}
		
		NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
		int rid = [[playerInfo objectForKey:@"rid"] intValue];
		
		userTeam.level = 99;
		userTeam.icon_type = Fight_team_icon_type_role;
		userTeam.icon = rid;
		
		FightMember * playerRole = [FightMember memberOfRoleId:rid level:level];
		if(playerRole){
			
			playerRole.index = 10;
			playerRole.targetTeam = targetTeam;
			playerRole.selfTeam = userTeam;
			playerRole.fightAction = self;
			
			[userTeam addMember:playerRole];
			[allMember addObject:playerRole];
		}
		
		[self logTeamInfo:@"fstage03"];
		
		[self logActionDelay:0.1];
		[self logActionAttack:boss];
		[self logActionEffectBok:member];
		[self logAction:[NSString stringWithFormat:
						 @"%d:%@:%d:%d:%d",
						 Fight_Action_Log_Type_hp,
						 [member getPosition],
						 -99999,
						 0,1]];
		
		[self logActionDelay:1.5];
		[self logActionDie:member];
		[self logActionDelay:1];
		
		[self logAction:[NSString stringWithFormat:
						 @"%d:%d:0",
						 Fight_Action_Log_Type_end,
						 targetTeam.classIndex
						 ]];
	}
	
	//TODO play
	[self resultAllFightLog:YES];
	
}

//==============================================================================
#pragma mark -
//==============================================================================

-(void)resultAllFightLog:(BOOL)isUserWin{
	
	NSMutableDictionary * result = [NSMutableDictionary dictionaryWithDictionary:allTeamInfo];
	NSString * f = [allActionInfo componentsJoinedByString:@"|"];
	if(f==nil) f = @"";
	[result setObject:f forKey:@"f"];
	
	[[FightManager shared] seleFightResult:result isUserWin:isUserWin];
	[[FightManager shared] playFightResult];
	
	//[[FightManager shared] playFight:result];
	
}

-(void)logTeamInfo:(NSString*)bg{
	
	//记录两队人的数据
	allTeamInfo = [NSMutableDictionary dictionary];
	[allTeamInfo retain];
	
	NSString * t1 = [targetTeam getTeamInfoSting];
	NSString * t2 = [userTeam getTeamInfoSting];
	
	[allTeamInfo setObject:bg forKey:@"a"];
	[allTeamInfo setObject:[NSNumber numberWithInt:fightId] forKey:@"b"];
	
	if(fightId>0){
		
		NSDictionary * fightData = [[GameDB shared] getFightInfo:fightId];
		if(fightData){
			
			id par = [fightData objectForKey:@"par"];
			if(par){
				[allTeamInfo setObject:par forKey:@"p"];
			}
			
			/*
			if(![[fightData objectForKey:@"par"]isKindOfClass:[NSNull class]]){
				[allTeamInfo setObject:[fightData objectForKey:@"par"] forKey:@"p"];
			}
			*/
			
		}
	}
	
	int mt = [targetTeam getTeamTopType];
	[allTeamInfo setObject:[NSNumber numberWithInt:mt] forKey:@"c"];
	
	[allTeamInfo setObject:t1 forKey:@"1"];
	[allTeamInfo setObject:t2 forKey:@"2"];
	
}

-(void)logAction:(NSString*)action{
	if(!allActionInfo){
		allActionInfo = [NSMutableArray array];
		[allActionInfo retain];
	}
	[allActionInfo addObject:action];
}

-(void)logActionChangeHP:(FightMember*)member hp:(int)hp 
				   isBok:(BOOL)isBok 
				   isCpr:(BOOL)isCpr 
				   isPen:(BOOL)isPen{
	
	CCLOG(@"logActionChangeHP %@ %d/%d",[member getPosition],hp,member.currentHP);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@:%d:%d:%d:%d:%d",
					 Fight_Action_Log_Type_hp,
					 [member getPosition],
					 hp,
					 member.currentHP,
					 (isBok?1:0),
					 (isCpr?1:0),
					 (isPen?1:0)
					 ]];
	
}
-(void)logActionChangePower:(FightMember*)member power:(int)power{
	
	CCLOG(@"logActionChangePower %@ %d",[member getPosition],power);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@:%d",
					 Fight_Action_Log_Type_power,
					 [member getPosition],
					 power
					 ]];
	
}

-(void)logActionDie:(FightMember*)member{
	CCLOG(@"logActionDie %@",[member getPosition]);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@",
					 Fight_Action_Log_Type_die,
					 [member getPosition]
					 ]];
	
}

-(void)logActionReadySkill:(FightMember*)member{
	CCLOG(@"logActionReadySkill %@ ",[member getPosition]);
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@",
					 Fight_Action_Log_Type_ready_skill,
					 [member getPosition]
					 ]];
}

-(void)logActionRemoveSkill:(FightMember*)member{
	CCLOG(@"logActionRemoveSkill %@ ",[member getPosition]);
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@",
					 Fight_Action_Log_Type_remove_skill,
					 [member getPosition]
					 ]];
}

-(void)logActionMove:(FightMember*)member target:(FightMember*)target{
	CCLOG(@"logActionMove %@ -> %@",[member getPosition],[target getPosition]);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@:%@",
					 Fight_Action_Log_Type_move,
					 [member getPosition],
					 [target getPosition]
					 ]];
	
}
-(void)logActionBack:(FightMember*)member{
	CCLOG(@"logActionBack %@",[member getPosition]);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@",
					 Fight_Action_Log_Type_back,
					 [member getPosition]
					 ]];
	
}

-(void)logActionAttack:(FightMember*)member{
	CCLOG(@"logActionAttack %@",[member getPosition]);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@",
					 Fight_Action_Log_Type_atk,
					 [member getPosition]
					 ]];
	
}
-(void)logActionSkill:(FightMember*)member{ 
	CCLOG(@"logActionSkill %@",[member getPosition]);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@",
					 Fight_Action_Log_Type_skl,
					 [member getPosition]
					 ]];
}

-(void)logActionAddStatus:(FightMember*)member status:(FightStatus*)status{
	CCLOG(@"logActionAddStatus %@ %d %d %@",[member getPosition],
		  status.statusId,status.statusIndex,(status.effect!=nil?status.effect:@"*")
		  );
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@:%d:%d:%@",
					 Fight_Action_Log_Type_addStatus,
					 [member getPosition],
					 status.statusId,
					 status.statusIndex,
					 (status.effect!=nil?status.effect:@"")
					 ]];
}
-(void)logActionUpdateStatus:(FightMember*)member status:(FightStatus*)status{
	CCLOG(@"logActionRemoveStatus %@ %d %d",[member getPosition],status.statusId,status.statusIndex);
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@:%d:%d",
					 Fight_Action_Log_Type_updateStatus,
					 [member getPosition],
					 status.statusId,
					 status.statusIndex
					 ]];
}
-(void)logActionRemoveStatus:(FightMember*)member status:(FightStatus*)status{
	CCLOG(@"logActionRemoveStatus %@ %d %d",[member getPosition],status.statusId,status.statusIndex);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@:%d:%d",
					 Fight_Action_Log_Type_removeStatus,
					 [member getPosition],
					 status.statusId,
					 status.statusIndex
					 ]];
}

-(void)logActionDelay:(float)time{
	CCLOG(@"logActionDelay %.1f",time);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%.1f",
					 Fight_Action_Log_Type_delay,
					 time
					 ]];
	
}

-(void)logActionEnd:(FightTeam*)team{
	CCLOG(@"logActionEnd %d",team.classIndex);
	[self logAction:[NSString stringWithFormat:
					 @"%d:%d:1",
					 Fight_Action_Log_Type_end,
					 team.classIndex
					 ]];
}

-(void)logActionEffectSingle:(FightMember *)member effect:(int)eid offset:(int)offset{
	
	CCLOG(@"logActionEffectSingle %d %d",eid,offset);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@:%d:%d",
					 Fight_Action_Log_Type_effect_single,
					 [member getPosition],
					 eid,
					 offset
					 ]];
	
}
-(void)logActionEffectAll:(FightTeam*)team effect:(int)eid offset:(int)offset{
	
	CCLOG(@"logActionEffectAll %d %d",eid,offset);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%d:%d:%d",
					 Fight_Action_Log_Type_effect_all,
					 team.classIndex,
					 eid,
					 offset
					 ]];
}
//------------------------------------------------------------------------------

-(void)logActionEffectAdd:(FightMember*)member{
	[self logAction:[NSString stringWithFormat:@"%d:%@",Fight_Action_Log_Type_add,[member getPosition]]];
}
-(void)logActionEffectBok:(FightMember*)member{
	[self logAction:[NSString stringWithFormat:@"%d:%@",Fight_Action_Log_Type_bok,[member getPosition]]];
}
-(void)logActionEffectCob:(FightMember*)member{
	[self logAction:[NSString stringWithFormat:@"%d:%@",Fight_Action_Log_Type_cob,[member getPosition]]];
}
-(void)logActionEffectCot:(FightMember*)member{
	[self logAction:[NSString stringWithFormat:@"%d:%@",Fight_Action_Log_Type_cot,[member getPosition]]];
}
-(void)logActionEffectCpr:(FightMember*)member{
	[self logAction:[NSString stringWithFormat:@"%d:%@",Fight_Action_Log_Type_cpr,[member getPosition]]];
}
-(void)logActionEffectMis:(FightMember*)member{
	[self logAction:[NSString stringWithFormat:@"%d:%@",Fight_Action_Log_Type_mis,[member getPosition]]];
}
-(void)logActionEffectPen:(FightMember*)member{
	[self logAction:[NSString stringWithFormat:@"%d:%@",Fight_Action_Log_Type_pen,[member getPosition]]];
}

/*
-(void)logActionBok:(FightMember*)member{
	CCLOG(@"logActionBok %@",[member getPosition]);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@",
					 Fight_Action_Log_Type_bok,
					 [member getPosition]
					 ]];
}
-(void)logActionMis:(FightMember*)member{
	CCLOG(@"logActionMis %@",[member getPosition]);
	
	[self logAction:[NSString stringWithFormat:
					 @"%d:%@",
					 Fight_Action_Log_Type_mis,
					 [member getPosition]
					 ]];
}
*/

@end
