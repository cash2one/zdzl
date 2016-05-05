//
//  FightStatus.m
//  TXSFGame
//
//  Created by TigerLeung on 12-11-27.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "FightStatus.h"
#import "FightMember.h"
#import "FightTeam.h"
#import "GameConfigure.h"
#import "GameDB.h"

static int statusCountIndex = 0;

@implementation FightStatus

@synthesize statusId;
@synthesize statusIndex;
@synthesize isActive;
@synthesize member;
@synthesize parentCutHP;
@synthesize attribute;
@synthesize count;

@synthesize add_hurt_hp_percent;
@synthesize cut_hurt_hp_percent;

@synthesize isNoAtk;
@synthesize isNoMis;
@synthesize isNoBok;
@synthesize isNoCot;

@synthesize effect;

+(void)member:(FightMember*)member addStatus:(int)sid to:(FightMember*)main other:(NSArray*)targets cut:(int)cut hit:(BOOL)hit{
	
	CCLOG(@"add status %d",sid);
	
	NSMutableArray * adds = [NSMutableArray array];
	
	//soul
	//NSDictionary * info = [[GameConfigure shared] getStatusInfoById:sid];
	NSDictionary * info = [[GameDB shared] getStateInfo:sid];
	
	BOOL isCheckImmunityStatus = NO;
	
	int target = [[info objectForKey:@"target"] intValue];
	if(target==1){
		//敌方目标
		if(hit) [adds addObject:main];
		[adds addObjectsFromArray:targets];
		isCheckImmunityStatus = YES;
	}else if(target==2){
		//自己
		[adds addObject:member];
	}else if (target==3){
		//全部队友
		int num = [[info objectForKey:@"num"] intValue];
		NSArray * teams = [member.selfTeam getMembersSortDownHP:num];
		[adds addObjectsFromArray:teams];
	}else if (target==4){
		//敌方首要目标
		if(hit) [adds addObject:main];
		isCheckImmunityStatus = YES;
	}else if (target==5){
		//敌方次要目标
		[adds addObjectsFromArray:targets];
		isCheckImmunityStatus = YES;
	}else if (target==6){
		//全部队友,按mp 排列
		int num = [[info objectForKey:@"num"] intValue];
		NSArray * teams = [member.selfTeam getMembersSortDownMP:num];
		[adds addObjectsFromArray:teams];
	}
	
	NSMutableArray * cuts = [NSMutableArray arrayWithArray:adds];
	[adds removeAllObjects];
	for(id t in cuts){
		if(![adds containsObject:t]){
			[adds addObject:t];
		}
	}
	
	//has target
	if([adds count]>0){
		int rate = [[info objectForKey:@"rate"] intValue];
		for(FightMember * add in adds){
			
			//免疫其他技能
			if(isCheckImmunityStatus){
				if(add.isImmunityStatus){
					continue;
				}
			}
			
			if(checkRate(rate)){
				FightStatus * status = [FightStatus getStatusbyInfo:info member:add cut:cut];
				status.statusId = sid;
				[add addStatus:status];
			}
			
		}
	}
	
}

+(FightStatus*)getStatusbyInfo:(NSDictionary*)info member:(FightMember*)member cut:(int)cut{
	FightStatus * status = [[[FightStatus alloc] init] autorelease];
	status.statusId = [[info objectForKey:@"id"] intValue];
	status.member = member;
	status.parentCutHP = cut;
	[status initInfo:info];
	return status;
}

-(void)dealloc{
	
	if(effect){
		[effect release];
		effect = nil;
	}
	
	[super dealloc];
	
	CCLOG(@"status remove");
	
}

//==============================================================================
//==============================================================================

-(void)initInfo:(NSDictionary*)info{
	
	statusCountIndex++;
	statusIndex = statusCountIndex;
	
	isActive = YES;
	
	type = [[info objectForKey:@"type"] intValue];
	
	action = [[info objectForKey:@"action"] intValue];
	count = [[info objectForKey:@"round"] intValue];
	
	ahp = [[info objectForKey:@"ahp"] intValue] / 100.0f;
	bhp = [[info objectForKey:@"bhp"] intValue] / 100.0f;
	
	isNoAtk = [[info objectForKey:@"noatk"] boolValue];
	isNoMis = [[info objectForKey:@"nomis"] boolValue];
	isNoBok = [[info objectForKey:@"nobok"] boolValue];
	isNoCot = [[info objectForKey:@"nocot"] boolValue];
	
	//load all add BaseAttribute
	
	BaseAttribute tAttribute = member.attribute;
	
	attribute = BaseAttributeFromFormat(tAttribute, [info objectForKey:@"value"]);
	//不可能出现在状态加成里面
	attribute.HP = 0;
	attribute.MP = 0;
	attribute.MPS = 0;
	attribute.MPT = 0;
	attribute.CBE = 0;
	attribute.FAE = 0;
	
	//add mp or hp
	t_hp = [[info objectForKey:@"hp"] floatValue];
	t_mp = [[info objectForKey:@"mp"] floatValue];
	hp_p = [[info objectForKey:@"hp_p"] floatValue]/100.0f;
	mp_p = [[info objectForKey:@"mp_p"] floatValue]/100.0f;
	
	[self checkStatusType:Fight_Action_Type_atonce];
	
	if([[info objectForKey:@"eff"] length]>0){
		effect = [info objectForKey:@"eff"];
		[effect retain];
	}
	
}

//update by action an cut count...
-(void)checkStatusType:(Fight_Action_Type)at{
	
	if(action==at){
		
		//action this status other
		if(type==Fight_Status_Type_general){
			//nothing
		}else if(type==Fight_Status_Type_harm){
			[member addHP:-(parentCutHP * bhp)];
		}else if(type==Fight_Status_Type_cure){
			[member addHP:(parentCutHP * ahp)];
		}else if(type==Fight_Status_Type_add){
			[member addPercentHP:hp_p PercentMP:mp_p HP:t_hp MP:t_mp];
		}
		
		[self checkCleanStatus];
		
	}
}

-(void)checkStatusByAttackBefore{
	if(action==Fight_Action_Type_attack){
		if(type==Fight_Status_Type_harm){
			[member addHP:-(parentCutHP * bhp)];
		}else if(type==Fight_Status_Type_cure){
			[member addHP:(parentCutHP * ahp)];
		}else if(type==Fight_Status_Type_add){
			[member addPercentHP:hp_p PercentMP:mp_p HP:t_hp MP:t_mp];
		}
		[self checkCleanStatus];
	}
}
-(void)checkStatusByAttackAfter{
	if(action==Fight_Action_Type_attack){
		if(type==Fight_Status_Type_general){
			[self checkCleanStatus];
		}
	}
}

-(void)checkCleanStatus{
	count--;
	if(count<=0){
		[member removeStatus:self];
		[self clean];
	}else{
		[member updateStatus:self];
	}
}

-(void)clean{
	
	isActive = NO;
	
	ahp = 0;
	bhp = 0;
	
	isNoAtk = NO;
	isNoMis = NO;
	isNoBok = NO;
	isNoCot = NO;
	
	attribute = BaseAttributeZero();
	
	mp_p = 0;
	hp_p = 0;
	
}

-(float)add_hurt_hp_percent{
	if(type==Fight_Status_Type_general && isActive){
		return ahp;
	}
	return 0.0f;
}
-(float)cut_hurt_hp_percent{
	if(type==Fight_Status_Type_general && isActive){
		return bhp;
	}
	return 0.0f;
}

-(NSString*)description{
	return [NSString stringWithFormat:@"%@ %d: (%d %d) %d",[super description],statusId,type,action,count];
}


@end
