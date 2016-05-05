//
//  FightTeam.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-22.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "FightTeam.h"
#import "FightMember.h"
#import "Config.h"
#import "CJSONSerializer.h"

static int sortMemberDownHP(FightMember*p1, FightMember*p2, void*context){
	if(p1.cutPercentHP < p2.cutPercentHP) return NSOrderedDescending;
	if(p1.cutPercentHP > p2.cutPercentHP) return NSOrderedAscending;
	return NSOrderedSame;
}

static int sortMemberDownMP(FightMember*p1, FightMember*p2, void*context){
	if(p1.currentPower > p2.currentPower) return NSOrderedDescending;
	if(p1.currentPower < p2.currentPower) return NSOrderedAscending;
	return NSOrderedSame;
}

static int row_count = 3;

@implementation FightTeam
@synthesize classIndex;
@synthesize playerId;
@synthesize level;
@synthesize icon;
@synthesize icon_type;
@synthesize members;
@synthesize damages;

-(id)init{
	if((self=[super init])){
		[self start];
	}
	return self;
}

-(void)dealloc{
	if(members){
		[members release];
		members = nil;
	}
	if(buffs){
		[buffs release];
		buffs = nil;
	}
	if(playerIds){
		[playerIds release];
		playerIds = nil;
	}
	if (damages) {
		[damages release];
		damages = nil;
	}
	[super dealloc];
	CCLOG(@"FightTeam remove");
}

-(void)setPlayerId:(int)pid{
	playerId = pid;
	[self addPlayer:playerId];
}

-(FightMember*)getMebmerByIndex:(int)index{
	for(FightMember * member in members){
		if(member.index==index){
			if(!member.isDie) return member;
		}
	}
	return nil;
}

-(NSArray*)getMembersByRow:(int)row{
	NSMutableArray * result = [NSMutableArray array];
	for(int i=0;i<row_count;i++){
		int index = i+row*row_count;
		FightMember * member = [self getMebmerByIndex:index];
		if(member){
			if(!member.isDie){
				[result addObject:member];
			}
		}
	}
	return result;
}

//==============================================================================
//==============================================================================

-(void)start{
	members = [[NSMutableArray alloc] init];
	buffs = [[NSMutableArray alloc] init];
	playerIds = [[NSMutableArray alloc] init];
}

-(BOOL)isEmpty{
	if(members){
		return ([members count]==0);
	}
	return YES;
}
-(BOOL)isKillAll{
	if(![self isEmpty]){
		for(FightMember * member in members){
			if(!member.isDie){
				return NO;
			}
		}
	}
	return YES;
}
-(int)getDieLeftkindCount{
	int count = 0;
	if(![self isEmpty]){
		for(FightMember * member in members){
			if(!member.isDie){
				count++;
			}
		}
	}
	return count;
}

-(void)addMember:(FightMember*)member{
	[members addObject:member];
}
-(void)removeMember:(FightMember*)member{
	[members removeObject:member];
}

-(void)addPlayer:(int)pid{
	if(pid>0){
		for(NSString * inTeam in playerIds){
			if([inTeam intValue]==pid){
				return;
			}
		}
		[playerIds addObject:[NSString stringWithFormat:@"%d",pid]];
	}
}

-(int)getTeamTopType{
	int mt = 0;
	for(FightMember*member in members){
		if(member.type>mt){
			mt = member.type;
		}
	}
	return mt;
}

-(NSArray*)checkMembers:(NSArray*)targets{
	NSMutableArray * result = [NSMutableArray array];
	for(FightMember * member in targets){
		if(!member.isDie){
			[result addObject:member];
		}
	}
	return result;
}

-(FightMember*)getTargetByIndex:(int)index{
	
	int tIndex = index%row_count;
	if(index%row_count==0){
		tIndex += 2;
	}else if(index%row_count==2){
		tIndex -= 2;
	}
	
	for(int row=0;row<5;row++){
		int targetIndex = row*row_count+tIndex;
		FightMember * member = [self getMebmerByIndex:targetIndex];
		if(member){
			return member;
		}else{
			NSArray * rows = [self getMembersByRow:row];
			if([rows count]>0){
				int o = getRandomInt(0,[rows count]-1);
				return [rows objectAtIndex:o];
			}
		}
	}
	
	return nil;
}


-(NSArray*)getMembersByMode:(Attack_mode)mode index:(int)index{
	
	//load other member from Attack_mode by not has mainTarget
	NSMutableArray * result = [NSMutableArray array];
	if(mode==0||mode==Attack_mode_target_single){
		return result;
	}
	
	FightMember * member = nil;
	
	if(mode==Attack_mode_target_upright){ //目标及后面
		member = [self getMebmerByIndex:(index+row_count)];
		if(member) [result addObject:member];
	}else if(mode==Attack_mode_target_later){ //目标及身后一竖
		for(int i=1;i<5;i++){
			member = [self getMebmerByIndex:(index+row_count*i)];
			if(member){
				[result addObject:member];
			}else{
				//TODO
				//break;
			}
		}
	}else if(mode==Attack_mode_target_surrounding){ //目标及周围
		
		if(index%row_count==0){
			//右
			member = [self getMebmerByIndex:(index+1)];
			if(member) [result addObject:member];
		}else if(index%row_count==1){
			//左
			member = [self getMebmerByIndex:(index+1)];
			if(member) [result addObject:member];
			
			//右
			member = [self getMebmerByIndex:(index-1)];
			if(member) [result addObject:member];
		}else if(index%row_count==2){
			//右
			member = [self getMebmerByIndex:(index-1)];
			if(member) [result addObject:member];
		}
		
		//后
		member = [self getMebmerByIndex:(index+row_count)];
		if(member) [result addObject:member];
		
	}else if(mode==Attack_mode_target_sector){ //目标及扇形
		
		if(index%row_count==0){
			//后左
			member = [self getMebmerByIndex:(index+1+row_count)];
			if(member) [result addObject:member];
		}else if(index%row_count==1){
			
			//后左
			member = [self getMebmerByIndex:(index+1+row_count)];
			if(member) [result addObject:member];
			
			//后右
			member = [self getMebmerByIndex:(index-1+row_count)];
			if(member) [result addObject:member];
			
		}else if(index%row_count==2){
			//后右
			member = [self getMebmerByIndex:(index-1+row_count)];
			if(member) [result addObject:member];
		}
		
		//后两位
		member = [self getMebmerByIndex:(index+row_count)];
		if(member) [result addObject:member];
		member = [self getMebmerByIndex:(index+row_count*2)];
		if(member) [result addObject:member];
		
	}else if(mode==Attack_mode_target_aboutRank){ //目标及左右两列
		
		int i = 0;
		int t = index;
		
		if(index%row_count==0){
			//右
			t = index + 1;
			for(i=1;i<5;i++){
				member = [self getMebmerByIndex:(t+row_count*i)];
				if(member){
					[result addObject:member];
				}else{
					break;
				}
			}
		}else if(index%row_count==1){
			//左
			t = index - 1;
			for(i=1;i<5;i++){
				member = [self getMebmerByIndex:(t+row_count*i)];
				if(member){
					[result addObject:member];
				}else{
					break;
				}
			}
			//右
			t = index + 1;
			for(i=1;i<5;i++){
				member = [self getMebmerByIndex:(t+row_count*i)];
				if(member){
					[result addObject:member];
				}else{
					//TODO
					//break;
				}
			}
		}else if(index%row_count==2){
			//左
			t = index - 1;
			for(i=1;i<5;i++){
				member = [self getMebmerByIndex:(t+row_count*i)];
				if(member){
					[result addObject:member];
				}else{
					break;
				}
			}
		}
	}
	
	//全体攻击
	if(mode==Attack_mode_Attack_mode_full){ //敌全体
		for(member in members){
			if(member.index!=index){
				[result addObject:member];
			}
		}
	}else if(mode==Attack_mode_across){ //一横
		for(int i=0;i<5;i++){
			NSArray * ary = [self getMembersByRow:i];
			if([ary count]>0){
				for(member in ary){
					if(member.index!=index){
						[result addObject:member];
					}
				}
				break;
			}
		}
	}
	
	return [self checkMembers:result];
}

-(NSArray*)getMembersDamages{
	CCLOG(@"getMembersDamage-----");
	NSMutableArray * result = [NSMutableArray array];
	
	for(FightMember * member in members){
		NSString* _info = [NSString stringWithFormat:@"%d",member.targetId];
		int _value = [member getTotalHurt];
		_info = [_info stringByAppendingFormat:@"|%d",_value];;
		[result addObject:_info];
	}
	
	return result ;
}

-(NSArray*)getMembersSortDownHP:(int)count{
	
	NSMutableArray * result = [NSMutableArray array];
	
	NSMutableArray * targets = [NSMutableArray arrayWithArray:[self checkMembers:members]];
	[targets sortUsingFunction:sortMemberDownHP context:nil];
	count = min([targets count], count);
	
	for(int i=0;i<count;i++){
		FightMember * member = [targets objectAtIndex:i];
		[result addObject:member];
	}
	return result;
}

-(NSArray*)getMembersSortDownMP:(int)count{
	NSMutableArray * result = [NSMutableArray array];
	
	NSMutableArray * targets = [NSMutableArray arrayWithArray:[self checkMembers:members]];
	[targets sortUsingFunction:sortMemberDownMP context:nil];
	count = min([targets count], count);
	
	for(int i=0;i<count;i++){
		FightMember * member = [targets objectAtIndex:i];
		[result addObject:member];
	}
	return result;
}

-(void)logTeamBuff:(NSDictionary*)buff type:(Fight_Buff_Type)type{
	if(buff){
		if([[buff allKeys] count]>0){
			NSMutableDictionary * data = [NSMutableDictionary dictionary];
			[data setObject:[NSNumber numberWithInt:type] forKey:@"type"];
			[data setObject:buff forKey:@"d"];
			[buffs addObject:data];
		}
	}
}

//==============================================================================
#pragma mark -
//==============================================================================
-(NSDictionary*)getTeamInfo{
	NSMutableDictionary * info = [NSMutableDictionary dictionary];
	
	[info setObject:[NSNumber numberWithInt:classIndex] forKey:@"ci"];
	[info setObject:[NSNumber numberWithInt:playerId] forKey:@"ui"];
	
	NSMutableArray * mem = [NSMutableArray array];
	for(FightMember * member in members){
		[mem addObject:[member getMemberInfo]];
	}
	[info setObject:mem forKey:@"tm"];
	[info setObject:buffs forKey:@"buffs"];
	return info;
}

-(NSString*)getTeamInfoSting{
	
	NSMutableArray * mem = [NSMutableArray array];
	for(FightMember * member in members){
		[mem addObject:[member getMemberInfo]];
	}
	
	NSData * data = [[CJSONSerializer serializer] serializeObject:buffs error:nil];
	NSString * json = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	
	NSString * info = [NSString stringWithFormat:@"%d:%d:%d:%d:%d:%@=%@=%@",
					   classIndex,
					   playerId,
					   (level>99?99:level),
					   icon_type,
					   icon,
					   [playerIds componentsJoinedByString:@"|"],
					   [mem componentsJoinedByString:@"|"],
					   json];
	
	return info;
}

-(void)logMemberDamages{
	if (damages == nil) {
		damages = [NSMutableDictionary dictionary];
		[damages retain];
	}
	for(FightMember* member in members){
		NSString* key = [NSString stringWithFormat:@"%d",member.targetId];
		NSString* value = [NSString stringWithFormat:@"%d",[member getTotalHurt]];
		[damages setObject:value forKey:key];
	}
}

@end
