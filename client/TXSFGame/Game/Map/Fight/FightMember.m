//
//  FightMember.m
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-22.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import "FightMember.h"
#import "GameConfigure.h"
#import "FightTeam.h"
#import "FightStatus.h"
#import "FightAction.h"
#import "GameDB.h"

static int getFormatString(NSString*source, NSString*key, int index){
	NSArray * ary = [source componentsSeparatedByString:key];
	if([ary count]>index){
		return [[ary objectAtIndex:index] intValue];
	}
	return 0;
}

/*
static inline float getAttackModeMainPercent(Attack_mode mode){
	//if(mode==Attack_mode_target_single_100) return 1.0f;
	//if(mode==Attack_mode_target_single_120) return 1.2f;
	//if(mode==Attack_mode_target_single_200) return 2.0f;
	return 1.0f;
}

static inline float getAttackOtherPercent(Attack_mode mode){
	if(mode==Attack_mode_target_upright)		return 0.45f;
	if(mode==Attack_mode_target_later)			return 0.20f;
	if(mode==Attack_mode_target_surrounding)	return 0.30f;
	if(mode==Attack_mode_target_sector)			return 0.20f;
	if(mode==Attack_mode_target_aboutRank)		return 0.20f;
	return 1.0f;
}
*/

//普通攻击伤害
static inline float attackTarget(BaseAttribute ba1, int lv, BaseAttribute ba2){
	float cut = ba1.ATK*(1-(ba2.DEF*sqrtf(lv*100)) / (ba2.DEF*lv+lv*lv*180));
	
	//600*(1-(401*sqrtf(lv*100))) / (401*6+6*6*180)
	
	if(cut<0) cut = 0;
	
	if(cut<=0){
		cut = ba1.ATK * 0.05;
	}
	
	return cut;
}
//技能攻击伤害
static inline float skillTarget(BaseAttribute ba1, int lv, BaseAttribute ba2){
	float cut = attackTarget(ba1, lv, ba2) + ba1.INT;// + ba1.STK;
	return cut;
}

//命中
static inline BOOL isHitTarget(BaseAttribute ba1, BaseAttribute ba2){
	float hit = ba1.HIT-ba2.MIS;
	return checkRate(hit);
}

//破甲
static inline BOOL isCheckPEN(BaseAttribute ba){
	return checkRate(ba.PEN);
}
//爆击
static inline BOOL isCheckCRI(BaseAttribute ba){
	return checkRate(ba.CRI);
}

//连击
static inline BOOL isCheckCOB(BaseAttribute ba){
	return checkRate(ba.COB);
}

//挡格
static inline BOOL isCheckBOK(BaseAttribute ba){
	return checkRate(ba.BOK);
}
//反击
static inline BOOL isCheckCOT(BaseAttribute ba){
	return checkRate(ba.COT);
}
//回避
static inline BOOL isCheckMIS(BaseAttribute ba){
	return checkRate(ba.MIS);
}

@implementation FightMember

@synthesize isLoadOtherBuff;

@synthesize index;
@synthesize targetId;
@synthesize level;
@synthesize quality;
@synthesize type;
@synthesize attribute;

@synthesize speed;

@synthesize selfTeam;
@synthesize targetTeam;
@synthesize fightAction;

@synthesize isDie;
@synthesize percentHP;
@synthesize cutPercentHP;

@synthesize currentHP;
@synthesize totalHP;
@synthesize beginHp;

@synthesize currentPower;
@synthesize totalPower;

@synthesize is_far_atk;
@synthesize is_far_skl;

@synthesize isImmunityStatus;

+(FightMember*)memberOfFightData:(NSString*)str{
	if([str length]>0){
		NSArray * a = [str componentsSeparatedByString:@":"];
		if([a count]==2){
			int mid = [[a objectAtIndex:0] intValue];
			int lev = [[a objectAtIndex:1] intValue];
			if(mid>0&&lev>0){
				return [FightMember memberOfMonsterId:mid level:lev];
			}
		}
		if([a count]==3){
			
			int tLevel = [[a objectAtIndex:1] intValue];
			int mid = [[a objectAtIndex:0] intValue];
			int type = [[a objectAtIndex:2] intValue];
			
			int playerLevel = [[GameConfigure shared] getPlayerLevel];
			if(type==2) tLevel = playerLevel + tLevel;
			if(type==3) tLevel = playerLevel - tLevel;
			
			if(tLevel<=0) tLevel = 1;
			
			if(mid>0&&tLevel>0){
				return [FightMember memberOfMonsterId:mid level:tLevel];
			}
			
			return nil;
		}
	}
	return nil;
}

+(FightMember*)memberOfMonsterId:(int)mid level:(int)level{
	FightMember * member = [[FightMember alloc] autorelease];
	member.targetId = mid;
	member.level = level;
	member.type = Fight_member_type_monster;
	[member loadAttribute:nil];
	return member;
}

+(FightMember*)memberOfMonsterDict:(NSDictionary*)mDict{
    if (mDict) {
        FightMember * member = [[FightMember alloc] autorelease];
        member.targetId = [[mDict objectForKey:@"mid"] intValue];
        member.level = [[mDict objectForKey:@"level"] intValue];
        member.type = Fight_member_type_monster;
        //-------------
//        [member loadAttribute:nil];
        [member loadMonsterAttributeWithDict:mDict];
        //-------------
        [member loadBaseValue];
        return member;
    }
    return NULL;
}

+(FightMember*)memberOfRoleId:(int)rid level:(int)level{
	if(rid>0){
		
		FightMember * member = [[FightMember alloc] autorelease];
		member.targetId = rid;
		member.type = Fight_member_type_role;
		member.level = level;
		[member loadAttribute:nil];
		
		return member;
	}
	return nil;
}
+(FightMember*)memberOfSingleRoleId:(int)rid level:(int)level{
	if(rid>0){
		FightMember * member = [[FightMember alloc] autorelease];
		member.targetId = rid;
		member.type = Fight_member_type_single_role;
		member.level = level;
		[member loadAttribute:nil];
		return member;
	}
	return nil;
}

+(FightMember*)memberOfNpc:(int)rid level:(int)level{
	if(rid>0){
		FightMember * member = [[FightMember alloc] autorelease];
		member.targetId = rid;
		member.type = Fight_member_type_npc;
		member.level = level;
		[member loadAttribute:nil];
		return member;
	}
	return nil;
}

+(FightMember*)memberOfRoleId:(int)rid playerData:(NSDictionary*)data{
	if(rid>0){
		FightMember * member = [[FightMember alloc] autorelease];
		member.targetId = rid;
		member.type = Fight_member_type_player;
		[member loadAttribute:data];
		return member;
	}
	return nil;
}

-(NSString*)description{
	//BaseAttribute ba = [self getTotalAttribute];
	//return [NSString stringWithFormat:@"%d : %f %f %d %f",targetId,ba.DEX,ba.SPD,level,self.cutPercentHP];
	//return [NSString stringWithFormat:@"%@ %d -> %d ",[self description],type,targetId];
	
	return [self getMemberInfo];
}

-(void)dealloc{
	
	CCLOG(@"FightMember remove");
	
	if(name){
		[name release];
		name = nil;
	}
	
	if(animation){
		[animation release];
		animation = nil;
	}
	
	if(barOffset){
		[barOffset release];
		barOffset = nil;
	}
	
	
	if(allStatus){
		[allStatus release];
		allStatus = nil;
	}
	
	[super dealloc];
	
}

//==============================================================================
//==============================================================================
#pragma mark -
-(BOOL)isDie{
	return (currentHP<=0);
}
-(float)percentHP{
	if(currentHP<=0) return 0.0f;
	float percent = currentHP/totalHP;
	return percent;
}
-(float)cutPercentHP{
	if(currentHP<=0) return 1.0f;
	float percent = (totalHP-currentHP);
	percent /= totalHP;
	return percent;
}

#pragma mark -

-(int)speed{
	
	int totalSPD = base_spd * (fightAction.roundIndex + 1);
	
	//add status SPD
	for(FightStatus * status in allStatus){
		if(status.isActive){
			totalSPD += status.attribute.SPD;
		}
	}
	
	//加阵速度眼加成
	//if(fightAction.roundIndex==0){
	//totalSPD += base_spd * pos_center_spd_p;
	//}
	
	return totalSPD;
}

-(void)loadAttribute:(NSDictionary*)other{
	if(type==Fight_member_type_monster){
		[self loadMonsterAttribute];
	}
	if(type==Fight_member_type_role){
		[self loadPlayerRoleAttribute];
	}
	if(type==Fight_member_type_player){
		[self loadTargetPlayerRoleAttribute:other];
	}
	if (type==Fight_member_type_npc) {
		[self loadFightNpcAttribute];
	}
	if(type==Fight_member_type_single_role){
		[self loadFightSingleRoleAttribute];
	}
	[self loadBaseValue];
	
}
-(void)loadMonsterAttributeWithDict:(NSDictionary*)dict{
    attribute = BaseAttributeFromDict(dict);
	
	NSDictionary * monsterInfo = [[GameDB shared] getMonsterInfo:targetId];
	
	//change target type to Boss
	int mt = [[monsterInfo objectForKey:@"type"] intValue];
	if(mt==2){
		type = Fight_member_type_boss;
	}
	
	int sk1 = [[monsterInfo objectForKey:@"sk1"] intValue];
	if(sk1>0){
		//soul
		//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk1];
		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk1];
		id_atk = sk1;
		is_far_atk = [[skill objectForKey:@"far"] boolValue];
		mode_atk = [[skill objectForKey:@"range"] intValue];
		if(mode_atk==0) mode_atk = Attack_mode_target_single;
		
		hart_main_percent_atk	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_atk	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_atk = [[skill objectForKey:@"effect"] intValue];
		eff_atk = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_atk = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_atk = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_atk = [[skill objectForKey:@"effectDIS"] boolValue];
	}
	
	int sk2 = [[monsterInfo objectForKey:@"sk2"] intValue];
	show_skl_id = sk2;
	if(sk2>0){
		//soul
		//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk2];
		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk2];
		id_skl = sk2;
		isShake = [[skill objectForKey:@"shock"] boolValue];
		is_far_skl = [[skill objectForKey:@"far"] boolValue];
		mode_skl = [[skill objectForKey:@"range"] intValue];
		if(mode_skl==0) mode_skl = Attack_mode_target_single;
		
		hart_main_percent_skl	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_skl	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_skl = [[skill objectForKey:@"effect"] intValue];
		eff_skl = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_skl = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_skl = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_skl = [[skill objectForKey:@"effectDIS"] boolValue];
	}
	
	//NSDictionary * monster = [[GameDB shared] getMonsterInfo:targetId];
	
	offset = [[monsterInfo objectForKey:@"offset"] intValue];
	quality = [[monsterInfo objectForKey:@"quality"] intValue];
	body = [[monsterInfo objectForKey:@"body"] floatValue];
	
	animation = @"m1";
	
	if([[monsterInfo objectForKey:@"name"] length]>0){
		name = [monsterInfo objectForKey:@"name"];
		[name retain];
	}
	if([[monsterInfo objectForKey:@"act"] length]>0){
		animation = [monsterInfo objectForKey:@"act"];
		[animation retain];
	}
	if([monsterInfo objectForKey:@"boffset"]){
		if([[monsterInfo objectForKey:@"boffset"] length]>0){
			barOffset = [monsterInfo objectForKey:@"boffset"];
			[barOffset retain];
		}
	}
}
-(void)loadMonsterAttribute{
	//soul
	
	NSDictionary * info = [[GameDB shared] getMonsterLevelInfo:targetId level:level];
    [self loadMonsterAttributeWithDict:info];
	/*
	attribute = BaseAttributeFromDict(info);
	
	NSDictionary * monsterInfo = [[GameDB shared] getMonsterInfo:targetId];
	
	//change target type to Boss
	int mt = [[monsterInfo objectForKey:@"type"] intValue];
	if(mt==2){
		type = Fight_member_type_boss;
	}
	
	int sk1 = [[monsterInfo objectForKey:@"sk1"] intValue];
	if(sk1>0){
		//soul
		//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk1];
		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk1];
		id_atk = sk1;
		is_far_atk = [[skill objectForKey:@"far"] boolValue];
		mode_atk = [[skill objectForKey:@"range"] intValue];
		if(mode_atk==0) mode_atk = Attack_mode_target_single;
		
		hart_main_percent_atk	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_atk	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_atk = [[skill objectForKey:@"effect"] intValue];
		eff_atk = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_atk = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_atk = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_atk = [[skill objectForKey:@"effectDIS"] boolValue];
	}
	
	int sk2 = [[monsterInfo objectForKey:@"sk2"] intValue];
	show_skl_id = sk2;
	if(sk2>0){
		//soul
		//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk2];
		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk2];
		id_skl = sk2;
		isShake = [[skill objectForKey:@"shock"] boolValue];
		is_far_skl = [[skill objectForKey:@"far"] boolValue];
		mode_skl = [[skill objectForKey:@"range"] intValue];
		if(mode_skl==0) mode_skl = Attack_mode_target_single;
		
		hart_main_percent_skl	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_skl	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_skl = [[skill objectForKey:@"effect"] intValue];
		eff_skl = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_skl = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_skl = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_skl = [[skill objectForKey:@"effectDIS"] boolValue];
	}
	
	//NSDictionary * monster = [[GameDB shared] getMonsterInfo:targetId];
	
	offset = [[monsterInfo objectForKey:@"offset"] intValue];
	quality = [[monsterInfo objectForKey:@"quality"] intValue];
	body = [[monsterInfo objectForKey:@"body"] floatValue];
	
	animation = @"m1";
	
	if([[monsterInfo objectForKey:@"name"] length]>0){
		name = [monsterInfo objectForKey:@"name"];
		[name retain];
	}
	if([[monsterInfo objectForKey:@"act"] length]>0){
		animation = [monsterInfo objectForKey:@"act"];
		[animation retain];
	}
	if([monsterInfo objectForKey:@"boffset"]){
		if([[monsterInfo objectForKey:@"boffset"] length]>0){
			barOffset = [monsterInfo objectForKey:@"boffset"];
			[barOffset retain];
		}
	}
	*/
}

-(void)loadFightNpcAttribute{
	attribute = [[GameConfigure shared] getNpcAttribute:targetId level:level];
	
	NSDictionary * role = [[GameDB shared] getRoleInfo:targetId];
	
	offset = [[role objectForKey:@"offset"] intValue];
	quality = [[role objectForKey:@"quality"] intValue];
	body = [[role objectForKey:@"body"] floatValue];
	
	int sk1 = [[role objectForKey:@"sk1"] intValue];
	show_skl_id = [[role objectForKey:@"sk2"] intValue];
	
	if(sk1>0){

		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk1];
		id_atk = sk1;
		is_far_atk = [[skill objectForKey:@"far"] boolValue];
		mode_atk = [[skill objectForKey:@"range"] intValue];
		if(mode_atk==0) mode_atk = Attack_mode_target_single;
		
		hart_main_percent_atk	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_atk	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_atk = [[skill objectForKey:@"effect"] intValue];
		eff_atk = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_atk = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_atk = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_atk = [[skill objectForKey:@"effectDIS"] boolValue];
	}
	
	int sk2 = [[role objectForKey:@"sk2"] intValue];
	if(sk2>0){
		//soul
		//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk2];
		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk2];
		id_skl = sk2;
		isShake = [[skill objectForKey:@"shock"] boolValue];
		is_far_skl = [[skill objectForKey:@"far"] boolValue];
		mode_skl = [[skill objectForKey:@"range"] intValue];
		if(mode_skl==0) mode_skl = Attack_mode_target_single;
		
		hart_main_percent_skl	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_skl	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_skl = [[skill objectForKey:@"effect"] intValue];
		eff_skl = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_skl = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_skl = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_skl = [[skill objectForKey:@"effectDIS"] boolValue];
		
	}
	
	//武器加伤害 , 每回合回复自身hp上限百分之几的hp
	NSDictionary * roleArmInfo  =[[GameDB shared] getRoleInfo:targetId];
	
	int armId = [[roleArmInfo objectForKey:@"armId"] intValue];
	//int level = 2;
	NSDictionary * armLevelInfo = [[GameDB shared] getArmLevelInfo:armId level:2];
	
	arm_hurt_percent = [[armLevelInfo objectForKey:@"hurt_p"] intValue]/100.0f;
	arm_round_add_hp = [[armLevelInfo objectForKey:@"addHp"] intValue];
	arm_round_add_hp_percent = [[armLevelInfo objectForKey:@"addHp_p"] intValue]/100.0f;
	
	NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
	int rid = [[player objectForKey:@"rid"] intValue];
	if(targetId==rid){
		name = [player objectForKey:@"name"];
		[name retain];
	}else{
		name = [role objectForKey:@"name"];
		[name retain];
	}
	
	//TODO load animation name
	animation = [NSString stringWithFormat:@"r%d",targetId];//@"r1";
	[animation retain];
	
	if([role objectForKey:@"boffset"]){
		if([[role objectForKey:@"boffset"] length]>0){
			barOffset = [role objectForKey:@"boffset"];
			[barOffset retain];
		}
	}
	
	
}
-(void)loadPlayerRoleAttribute{
	
	//load user all BA
	attribute = [[GameConfigure shared] getRoleAttribute:targetId isLoadOtherBuff:isLoadOtherBuff];
	
	//load user skill
	NSDictionary * role = [[GameDB shared] getRoleInfo:targetId];
	
	offset = [[role objectForKey:@"offset"] intValue];
	quality = [[role objectForKey:@"quality"] intValue];
	body = [[role objectForKey:@"body"] floatValue];
	
	int sk1 = [[role objectForKey:@"sk1"] intValue];
	show_skl_id = [[role objectForKey:@"sk2"] intValue];
	
	if(sk1>0){
		//soul
		//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk1];
		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk1];
		id_atk = sk1;
		is_far_atk = [[skill objectForKey:@"far"] boolValue];
		mode_atk = [[skill objectForKey:@"range"] intValue];
		if(mode_atk==0) mode_atk = Attack_mode_target_single;
		
		hart_main_percent_atk	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_atk	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_atk = [[skill objectForKey:@"effect"] intValue];
		eff_atk = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_atk = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_atk = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_atk = [[skill objectForKey:@"effectDIS"] boolValue];
		
	}
	
	NSDictionary * roleInfo = [[GameConfigure shared] getUserRoleById:targetId];
	
	int sk = [[roleInfo objectForKey:@"sk"] intValue];
	if(sk>0){
		//soul
		//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk];
		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk];
		id_skl = sk;
		isShake = [[skill objectForKey:@"shock"] boolValue];
		is_far_skl = [[skill objectForKey:@"far"] boolValue];
		mode_skl = [[skill objectForKey:@"range"] intValue];
		if(mode_skl==0) mode_skl = Attack_mode_target_single;
		
		hart_main_percent_skl	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_skl	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_skl = [[skill objectForKey:@"effect"] intValue];
		eff_skl = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_skl = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_skl = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_skl = [[skill objectForKey:@"effectDIS"] boolValue];
		
	}else{
		int sk2 = [[role objectForKey:@"sk2"] intValue];
		if(sk2>0){
			//soul
			//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk2];
			NSDictionary * skill = [[GameDB shared] getSkillInfo:sk2];
			id_skl = sk2;
			isShake = [[skill objectForKey:@"shock"] boolValue];
			is_far_skl = [[skill objectForKey:@"far"] boolValue];
			mode_skl = [[skill objectForKey:@"range"] intValue];
			if(mode_skl==0) mode_skl = Attack_mode_target_single;
			
			hart_main_percent_skl	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
			hart_other_percent_skl	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
			
			//eff_skl = [[skill objectForKey:@"effect"] intValue];
			eff_skl = getFormatString([skill objectForKey:@"effect"],@"@",0);
			eff_offset_skl = getFormatString([skill objectForKey:@"effect"],@"@",1);
			
			eff_rg_skl = [[skill objectForKey:@"effectRG"] intValue];
			eff_dis_skl = [[skill objectForKey:@"effectDIS"] boolValue];
			
		}
	}
	
	//武器加伤害 , 每回合回复自身hp上限百分之几的hp
	NSDictionary * armLevelInfo = [[GameConfigure shared] getUserArmInfoByRoleId:targetId];
	arm_hurt_percent = [[armLevelInfo objectForKey:@"hurt_p"] intValue]/100.0f;
	arm_round_add_hp = [[armLevelInfo objectForKey:@"addHp"] intValue];
	arm_round_add_hp_percent = [[armLevelInfo objectForKey:@"addHp_p"] intValue]/100.0f;
	
	NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
	int rid = [[player objectForKey:@"rid"] intValue];
	if(targetId==rid){
		name = [player objectForKey:@"name"];
		[name retain];
		
		int eq2 = [[roleInfo objectForKey:@"eq2"] intValue];
		if(eq2>0){
			NSDictionary * equip = [[GameConfigure shared] getPlayerEquipInfoById:eq2];
			int eqid = [[equip objectForKey:@"eid"] intValue];
			suit_id = eqid;
		}
		
	}else{
		name = [role objectForKey:@"name"];
		[name retain];
	}
	
	//TODO load animation name
	animation = [NSString stringWithFormat:@"r%d",targetId];//@"r1";
	[animation retain];
	
	if([role objectForKey:@"boffset"]){
		if([[role objectForKey:@"boffset"] length]>0){
			barOffset = [role objectForKey:@"boffset"];
			[barOffset retain];
		}
	}
	
}

-(void)loadFightSingleRoleAttribute{
	
	//load role all BA
	attribute = [[GameConfigure shared] getSingleRoleAttributeById:targetId level:level];
	
	//load user skill
	NSDictionary * role = [[GameDB shared] getRoleInfo:targetId];
	
	offset = [[role objectForKey:@"offset"] intValue];
	quality = [[role objectForKey:@"quality"] intValue];
	body = [[role objectForKey:@"body"] floatValue];
	
	int sk1 = [[role objectForKey:@"sk1"] intValue];
	int sk2 = [[role objectForKey:@"sk2"] intValue];
	show_skl_id = [[role objectForKey:@"sk2"] intValue];
	
	if(sk1>0){
		
		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk1];
		id_atk = sk1;
		is_far_atk = [[skill objectForKey:@"far"] boolValue];
		mode_atk = [[skill objectForKey:@"range"] intValue];
		if(mode_atk==0) mode_atk = Attack_mode_target_single;
		
		hart_main_percent_atk	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_atk	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_atk = [[skill objectForKey:@"effect"] intValue];
		eff_atk = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_atk = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_atk = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_atk = [[skill objectForKey:@"effectDIS"] boolValue];
		
	}
	if(sk2>0){
		//soul
		//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk2];
		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk2];
		id_skl = sk2;
		isShake = [[skill objectForKey:@"shock"] boolValue];
		is_far_skl = [[skill objectForKey:@"far"] boolValue];
		mode_skl = [[skill objectForKey:@"range"] intValue];
		if(mode_skl==0) mode_skl = Attack_mode_target_single;
		
		hart_main_percent_skl	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_skl	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_skl = [[skill objectForKey:@"effect"] intValue];
		eff_skl = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_skl = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_skl = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_skl = [[skill objectForKey:@"effectDIS"] boolValue];
		
	}
	
	//武器加伤害 , 每回合回复自身hp上限百分之几的hp
	int armId = [[role objectForKey:@"armId"] intValue];
	int armLevel = 0;
	
	NSDictionary * armLevelInfo = [[GameDB shared] getArmLevelInfo:armId level:armLevel];
	if(armLevelInfo){
		arm_hurt_percent = [[armLevelInfo objectForKey:@"hurt_p"] intValue]/100.0f;
		arm_round_add_hp = [[armLevelInfo objectForKey:@"addHp"] intValue];
		arm_round_add_hp_percent = [[armLevelInfo objectForKey:@"addHp_p"] intValue]/100.0f;
	}
	
	name = [role objectForKey:@"name"];
	[name retain];
	
	//TODO load animation name
	animation = [NSString stringWithFormat:@"r%d",targetId];//@"r1";
	[animation retain];
	
	if([role objectForKey:@"boffset"]){
		if([[role objectForKey:@"boffset"] length]>0){
			barOffset = [role objectForKey:@"boffset"];
			[barOffset retain];
		}
	}
	
}

-(void)loadTargetPlayerRoleAttribute:(NSDictionary*)data{
	
	NSDictionary * player = [data objectForKey:@"player"];
	NSDictionary * position = [data objectForKey:@"choosePosition"];
	
	NSArray * roles = [data objectForKey:@"roles"];
	
	NSDictionary * ilist = [data objectForKey:@"ilist"];
	NSArray * equips = [ilist objectForKey:@"equip"];
	NSArray * fates = [ilist objectForKey:@"fate"];
	
	NSDictionary * userRole = nil;
	for(NSDictionary * r in roles){
		if([[r objectForKey:@"rid"] intValue]==targetId){
			userRole = r;
			break;
		}
	}
	
	level = [[player objectForKey:@"level"] intValue];
	
	NSMutableDictionary * tmp = [NSMutableDictionary dictionary];
	[tmp setObject:userRole forKey:@"userRole"];
	if(position) [tmp setObject:position forKey:@"position"];
	[tmp setObject:equips forKey:@"equips"];
	[tmp setObject:fates forKey:@"fates"];
	[tmp setObject:[NSNumber numberWithInt:level] forKey:@"level"];
	
	attribute = [[GameConfigure shared] getRoleAttributeByData:tmp isLoadOtherBuff:NO];
	
	////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////
	
	//load user skill
	NSDictionary * role = [[GameDB shared] getRoleInfo:targetId];
	
	offset = [[role objectForKey:@"offset"] intValue];
	//quality = [[role objectForKey:@"quality"] intValue];
    //
    quality = [[userRole objectForKey:@"q"] intValue];
    //
	body = [[role objectForKey:@"body"] floatValue];
	
	int userRoleId = [[player objectForKey:@"rid"] intValue];
	if(userRoleId==targetId){
		int eq2Id = [[userRole objectForKey:@"eq2"] intValue];
		if(eq2Id>0){
			for(NSDictionary * equip in equips){
				int userEquipId = [[equip objectForKey:@"id"] intValue];
				if(userEquipId==eq2Id){
					int eid = [[equip objectForKey:@"eid"] intValue];
					suit_id = eid;
				}
			}
		}
	}
	
	int sk1 = [[role objectForKey:@"sk1"] intValue];
	
	if(sk1>0){
		//soul
		//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk1];
		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk1];
		id_atk = sk1;
		is_far_atk = [[skill objectForKey:@"far"] boolValue];
		mode_atk = [[skill objectForKey:@"range"] intValue];
		if(mode_atk==0) mode_atk = Attack_mode_target_single;
		
		hart_main_percent_atk	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_atk	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_atk = [[skill objectForKey:@"effect"] intValue];
		eff_atk = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_atk = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_atk = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_atk = [[skill objectForKey:@"effectDIS"] boolValue];
	}
	
	//NSDictionary * roleInfo = [[GameConfigure shared] getUserRoleById:targetId];
	NSDictionary * roleInfo = userRole;
	int sk = [[roleInfo objectForKey:@"sk"] intValue];
	if(sk>0){
		//soul
		//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk];
		NSDictionary * skill = [[GameDB shared] getSkillInfo:sk];
		id_skl = sk;
		isShake = [[skill objectForKey:@"shock"] boolValue];
		is_far_skl = [[skill objectForKey:@"far"] boolValue];
		mode_skl = [[skill objectForKey:@"range"] intValue];
		if(mode_skl==0) mode_skl = Attack_mode_target_single;
		
		hart_main_percent_skl	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
		hart_other_percent_skl	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
		
		//eff_skl = [[skill objectForKey:@"effect"] intValue];
		eff_skl = getFormatString([skill objectForKey:@"effect"],@"@",0);
		eff_offset_skl = getFormatString([skill objectForKey:@"effect"],@"@",1);
		
		eff_rg_skl = [[skill objectForKey:@"effectRG"] intValue];
		eff_dis_skl = [[skill objectForKey:@"effectDIS"] boolValue];
		
	}else{
		int sk2 = [[role objectForKey:@"sk2"] intValue];
		if(sk2>0){
			//soul
			//NSDictionary * skill = [[GameConfigure shared] getSkillInfoById:sk2];
			NSDictionary * skill = [[GameDB shared] getSkillInfo:sk2];
			id_skl = sk2;
			isShake = [[skill objectForKey:@"shock"] boolValue];
			is_far_skl = [[skill objectForKey:@"far"] boolValue];
			mode_skl = [[skill objectForKey:@"range"] intValue];
			if(mode_skl==0) mode_skl = Attack_mode_target_single;
			
			hart_main_percent_skl	= [[skill objectForKey:@"rHurt1"] intValue]/100.0f;
			hart_other_percent_skl	= [[skill objectForKey:@"rHurt2"] intValue]/100.0f;
			
			//eff_skl = [[skill objectForKey:@"effect"] intValue];
			eff_skl = getFormatString([skill objectForKey:@"effect"],@"@",0);
			eff_offset_skl = getFormatString([skill objectForKey:@"effect"],@"@",1);
			
			eff_rg_skl = [[skill objectForKey:@"effectRG"] intValue];
			eff_dis_skl = [[skill objectForKey:@"effectDIS"] boolValue];
			
		}
	}
	
	//武器加伤害 , 每回合回复自身hp上限百分之几的hp
	//NSDictionary * armLevelInfo = [[GameConfigure shared] getUserArmInfoByRoleId:targetId];
	
	int armId = [[role objectForKey:@"armId"] intValue];
	int armLevel = [[roleInfo objectForKey:@"armLevel"] intValue];
	NSDictionary * armLevelInfo = [[GameDB shared] getArmLevelInfo:armId level:armLevel];
	
	arm_hurt_percent = [[armLevelInfo objectForKey:@"hurt_p"] intValue]/100.0f;
	arm_round_add_hp = [[armLevelInfo objectForKey:@"addHp"] intValue];
	arm_round_add_hp_percent = [[armLevelInfo objectForKey:@"addHp_p"] intValue]/100.0f;
	
	//NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
	int rid = [[player objectForKey:@"rid"] intValue];
	if(targetId==rid){
		name = [player objectForKey:@"name"];
		[name retain];
	}else{
		name = [role objectForKey:@"name"];
		[name retain];
	}
	
	//TODO load animation name
	animation = [NSString stringWithFormat:@"r%d",targetId];//@"r1";
	[animation retain];
	
	if([role objectForKey:@"boffset"]){
		if([[role objectForKey:@"boffset"] length]>0){
			barOffset = [role objectForKey:@"boffset"];
			[barOffset retain];
		}
	}
	
}

-(void)loadBaseValue{
	
	currentHP = attribute.HP;
	totalHP = attribute.HP;
	beginHp = attribute.HP;
	
	currentPower = attribute.MPS;
	totalPower = attribute.MP;
	
	base_spd = attribute.SPD;
	
}

//位置加成
-(void)addPosition:(NSString*)pos{
	
	//阵型 位置伤害回复
	pos_add_hurt_hp_percent = valueFromFormat(pos,@"ADD_HURT_HP_P",1) / 100.0f;
	pos_add_hurt_hp_rate = valueFromFormat(pos,@"ADD_HURT_HP_P",2);
	
	//阵型 阵眼速度加成
	//pos_center_spd_p = valueFromFormat(pos,@"CENTER_SPD_P",1) / 100.0f;
	
	//添加阵型加成
	//BaseAttribute posBuff = BaseAttributeFromFormat(attribute, pos);
	//[self addBuff:posBuff];
	
}

-(void)addBuffByString:(NSString*)buff{
	//add buff string format
	BaseAttribute ba = BaseAttributeFromFormat(attribute, buff);
	[self addBuff:ba];
}
-(void)addBuffByDict:(NSDictionary*)dict{
	if([[dict allKeys] count]>0){
		BaseAttribute ba = BaseAttributeAllFromDict(attribute, dict);
		[self addBuff:ba];
	}
}

-(void)addBuff:(BaseAttribute)buff{
	attribute = BaseAttributeAddBuff(attribute, buff);
	[self loadBaseValue];
}
-(void)setFightRate:(float)rate{
	
	attribute.ATK = attribute.ATK*rate;
	attribute.HP = attribute.HP*rate;
	
	[self loadBaseValue];
	
}
-(void)addFightRate:(float)rate{
	
	attribute.ATK += attribute.ATK*rate;
	attribute.HP += attribute.HP*rate;
	
	[self loadBaseValue];
	
}

-(void)addFightAbyssBossRate:(float)rate{
	
	attribute.ATK += attribute.ATK*rate;
	attribute.HP += attribute.HP*rate;
	attribute.DEF += attribute.DEF*rate;
	
	[self loadBaseValue];
	
}

-(BaseAttribute)getTotalAttribute{
	
	//add some status...
	BaseAttribute result = BaseAttributeZero();
	result = BaseAttributeAdd(result, attribute);
	
	for(FightStatus * status in allStatus){
		if(status.isActive){
			result = BaseAttributeAdd(result, status.attribute);
		}
	}
	
	result = BaseAttributeCheck(result);
	return result;
}

//伤害加成 百分比
-(float)getAddHPPercent{
	
	//武器伤害加成 + 状态伤害加成
	
	float hurt_percent = 0.0f;
	hurt_percent += arm_hurt_percent;
	
	for(FightStatus * status in allStatus){
		if(status.isActive){
			hurt_percent += status.add_hurt_hp_percent;
		}
	}
	
	return hurt_percent;
}

//伤害减免 百份比
-(float)getCutHPPercent{
	
	//状态伤害减免百分比
	
	float cut_percent = 0.0f;
	for(FightStatus * status in allStatus){
		if(status.isActive){
			cut_percent += status.cut_hurt_hp_percent;
		}
	}
	
	return cut_percent;
}

//==============================================================================
#pragma mark -
//==============================================================================

-(void)fight{
	
	if([self isDie]) return;
	
	if([self statusIsCannotAtk]){
		[self checkAllStatusActionByAttackBefore];
		if([self isDie]){
			//TODO Log 死亡
			[fightAction logActionDie:self];
			return;
		}	
		return;
	}
	
	[self checkAllStatusActionByAttackBefore];
	if([self isDie]){
		//TODO Log 死亡
		[fightAction logActionDie:self];
		return;
	}
	
	//if([self statusIsCannotAtk])return;
	
	if([self isUseSkill]){
		[self skill];
	}else{
		[self attack];
	}
	
	if(![self isDie]){
		[self checkAllStatusActionByAttackAfter];
	}
	
}

-(void)checkHP{
	if(currentHP<0) currentHP = 0;
	if(currentHP>=totalHP) currentHP = totalHP;
}

//受伤
-(void)cutHP:(int)cut isBok:(BOOL)isBok isCpr:(BOOL)isCpr isPen:(BOOL)isPen{
	
	[self checkAllStatusAction:Fight_Action_Type_gethurt];
	
	if(cut<0) cut = 0;
	if(cut<1 && cut>0) cut=1;
	
	currentHP -= cut;
	[self checkHP];
	
	//TODO LOG 伤害
	[fightAction logActionChangeHP:self hp:-cut isBok:isBok isCpr:isCpr isPen:isPen];
	
	if(currentHP>0){
		
		//状态加HP
		if(checkRate(pos_add_hurt_hp_rate) && cut>0){
			
			int addHP = cut * pos_add_hurt_hp_percent;
			currentHP += addHP;
			[self checkHP];
			
			//TODO Log 受攻击后回伤害的百分比HP
			[fightAction logActionChangeHP:self hp:addHP isBok:NO isCpr:NO isPen:NO];
			
		}
		
	}
	
}

-(void)addActionMP:(int)mp{
	
	if([self isDie]) return;
	
	if(currentPower>=totalPower&&mp>0) return;
	
	currentPower += mp;
	if(currentPower<0) currentPower = 0;
	if(currentPower>totalPower) currentPower = totalPower;
	
	[fightAction logActionChangePower:self power:currentPower];
	
	if(currentPower>=totalPower){
		if(!isShowSkill){
			[fightAction logActionReadySkill:self];
		}
		isShowSkill = YES;
	}else{
		if(isShowSkill && mp<0){
			[fightAction logActionRemoveSkill:self];
			isShowSkill = NO;
		}
	}
	
}

-(void)addPercentHP:(float)hp_p PercentMP:(float)mp_p{
	[self addPercentHP:hp_p PercentMP:mp_p HP:0 MP:0];
}
-(void)addPercentHP:(float)hp_p PercentMP:(float)mp_p HP:(float)t_hp MP:(float)t_mp{
	//加血
	[self addHP:(currentHP * hp_p + t_hp)];
	//加气
	[self addActionMP:(currentPower * mp_p + t_mp)];
}

-(void)addHP:(int)hp{
	
	if(hp==0) return;
	
	currentHP += hp;
	[self checkHP];
	
	if(currentHP<=0){
		
		//TODO Log 死亡
		[fightAction logActionDie:self];
		
	}else{
		
		//TODO LOG 加减HP
		[fightAction logActionChangeHP:self hp:hp isBok:NO isCpr:NO isPen:NO];
		
	}
	
}

//TODO 回合结束 
-(void)roundEnd{
	
	if([self isDie]) return;
	
	//武器加血
	float addHP = arm_round_add_hp;
	addHP += arm_round_add_hp_percent * totalHP;
	if(addHP>0){
		
		currentHP += addHP;
		[self checkHP];
		
		//TODO Log 回合结束, 武器加自身HP
		[fightAction logActionChangeHP:self hp:addHP isBok:NO isCpr:NO isPen:NO];
		
	}
	
	[self checkAllStatusAction:Fight_Action_Type_endround];
	
	[self cleanStatus];
	
}

//==============================================================================
#pragma mark -
//==============================================================================

-(void)addPower{
	BaseAttribute ba = [self getTotalAttribute];
	//currentPower += ba.MPT;
	//[fightAction logActionChangePower:self power:currentPower];
	[self addActionMP:ba.MPT];
}

-(BOOL)isUseSkill{
	
	if(id_skl<=0) return NO;
	
	if(currentPower>=totalPower){
		currentPower -= totalPower;
		isShowSkill = NO;
		[fightAction logActionChangePower:self power:currentPower];
		return YES;
	}
	return NO;
}

-(void)attack{
	
	if([targetTeam isKillAll]) return;
	
	//攻击主要目标
	FightMember * target = [targetTeam getTargetByIndex:index];
	//攻击其它目标
	NSArray * members = [targetTeam getMembersByMode:mode_atk index:target.index];
	
	//TODO Log 移动到目标面前
	if(!is_far_atk) [fightAction logActionMove:self target:target];
	//TODO Log A攻击 动画
	//[fightAction logActionAttack:self];
	//[self checkLogTargetEffectByAtk:nil hit:NO];
	
	/*
	BOOL isAttackTarget = [self checkIsAttackTarget:target];
	BOOL isAttackTargets[20];
	for(int i=0;i<[members count];i++){
		isAttackTargets[i] = [self checkIsAttackTarget:[members objectAtIndex:i]];
	}
	*/
	
	int total_mp_self = 0;
	NSMutableArray * results = [NSMutableArray array];
	
	BOOL isHitMainTarget = NO;
	//添加状态伤害加成
	float percent = hart_main_percent_atk + [self getAddHPPercent] - [target getCutHPPercent];
	//cut = [self attackTarget:target percent:percent];
	
	NSDictionary * result = [self attackTarget:target percent:percent];
	if(result){
		[results addObject:result];
		
		isHitMainTarget = [[result objectForKey:@"isHit"] boolValue];
		BOOL isTargetPen = [[result objectForKey:@"isTargetPen"] boolValue];
		
		//load main target add mPower
		int mp_self = [[result objectForKey:@"mp_self"] intValue];
		total_mp_self += mp_self;
		
		if(isHitMainTarget && isTargetPen){
			[fightAction logActionEffectPen:self];
		}
	}
	
	[fightAction logActionAttack:self];
	[self checkLogTargetEffectByAtk:nil hit:NO];
	
	if(result){
		BOOL isTargetCpr = [[result objectForKey:@"isTargetCpr"] boolValue];
		if(isHitMainTarget && isTargetCpr){
			[fightAction logActionEffectCpr:self];
		}
	}
	
	//添加状态伤害加成
	percent = hart_other_percent_atk + [self getAddHPPercent];
	
	for(int i=0;i<[members count];i++){
		FightMember * member = [members objectAtIndex:i];
		//[self attackTarget:member percent:(percent-[member getCutHPPercent])];
		result = [self attackTarget:member percent:(percent-[member getCutHPPercent])];
		if(result){
			[results addObject:result];
		}
	}
	
	for(int i=0;i<[results count];i++){
		result = [results objectAtIndex:i];
		FightMember * member = [result objectForKey:@"target"];
		BOOL isHit = [[result objectForKey:@"isHit"] boolValue];
		[self checkLogTargetEffectByAtk:member hit:isHit];
	}
	
	for(int i=0;i<[results count];i++){
		
		result = [results objectAtIndex:i];
		
		FightMember * member = [result objectForKey:@"target"];
		
		BOOL isHit = [[result objectForKey:@"isHit"] boolValue];
		BOOL isTargetCpr = [[result objectForKey:@"isTargetCpr"] boolValue];
		BOOL isTargetBok = [[result objectForKey:@"isTargetBok"] boolValue];
		BOOL isTargetPen = [[result objectForKey:@"isTargetPen"] boolValue];
		
		int cutHp = [[result objectForKey:@"cut"] intValue];
		
		if(isHit){
			[member cutHP:cutHp isBok:isTargetBok isCpr:isTargetCpr isPen:isTargetPen];
			//if(isTargetCpr) [fightAction logActionEffectCpr:target];
			//if(isTargetBok) [fightAction logActionEffectBok:target];
		}else{
			[fightAction logActionEffectMis:member];
		}
	}
	
	
	for(int i=0;i<[results count];i++){
		result = [results objectAtIndex:i];
		FightMember * member = [result objectForKey:@"target"];
		if(member.isDie){
			[fightAction logActionDie:member];
		}else{
			//int mp_self = [[result objectForKey:@"mp_self"] intValue];
			int mp_targ = [[result objectForKey:@"mp_targ"] intValue];
			
			//total_mp_self += mp_self;
			
			//CCLOG(@"target add mp %d",mp_targ);
			[member addActionMP:mp_targ];
		}
	}
	
	//CCLOG(@"self add mp %d",total_mp_self);
	[self addActionMP:total_mp_self];
	
	//B反击A
	[self targetCounterAttack:target];
	
	if(!self.isDie){
		
		//TODO Log 移动到原位
		if(!is_far_atk){
			[fightAction logActionBack:self];
		}else{
			[fightAction logActionDelay:0.3f];
		}
		
		//[self addPower];
		BaseAttribute ba = [self getTotalAttribute];
		//CCLOG(@"self add mpt %d",ba.MPT);
		[self addActionMP:ba.MPT];
		
		if(isHitMainTarget){
			//连击
			[self attackContinueTarget:target];
		}
		
	}
	
	CCLOG(@"\n\n\n");
	
}

-(void)skill{
	
	if([targetTeam isKillAll]) return;
	
	//攻击主要目标
	FightMember * target = [targetTeam getTargetByIndex:index];
	
	//TODO Log 移动到目标面前
	if(!is_far_skl) [fightAction logActionMove:self target:target];
	
	NSMutableArray * results = [NSMutableArray array];
	
	//添加状态伤害加成
	//float percent = getAttackModeMainPercent(mode_atk) + [self getAddHPPercent] - [target getCutHPPercent];
	float percent = hart_main_percent_skl + [self getAddHPPercent] - [target getCutHPPercent];
	BOOL isHitMainTarget = NO;
	int cut = 0;
	
	NSDictionary * result = [self skillTarget:target percent:percent];
	
	if(result){
		[results addObject:result];
		
		isHitMainTarget = [[result objectForKey:@"isHit"] boolValue];
		BOOL isTargetPen = [[result objectForKey:@"isTargetPen"] boolValue];
		cut = [[result objectForKey:@"cut"] intValue];
		
		if(isHitMainTarget && isTargetPen){
			[fightAction logActionEffectPen:self];
		}
		
	}
	
	//TODO Log A攻击 动画
	[fightAction logActionSkill:self];
	[self checkLogTargetEffectBySkl:nil hit:NO];
	
	if(result){
		BOOL isTargetCpr = [[result objectForKey:@"isTargetCpr"] boolValue];
		if(isHitMainTarget && isTargetCpr){
			[fightAction logActionEffectCpr:self];
		}
	}
	
	//攻击其它目标
	NSArray * members = [targetTeam getMembersByMode:mode_skl index:target.index];
	
	percent = hart_other_percent_skl + [self getAddHPPercent];
	for(FightMember * member in members){
		
		//添加状态伤害加成
		result = [self skillTarget:member percent:(percent - [member getCutHPPercent])];
		if(result){
			[results addObject:result];
		}
		
	}
	
	for(int i=0;i<[results count];i++){
		result = [results objectAtIndex:i];
		FightMember * member = [result objectForKey:@"target"];
		BOOL isHit = [[result objectForKey:@"isHit"] boolValue];
		[self checkLogTargetEffectBySkl:member hit:isHit];
	}
	
	for(int i=0;i<[results count];i++){
		
		result = [results objectAtIndex:i];
		
		FightMember * member = [result objectForKey:@"target"];
		
		BOOL isHit = [[result objectForKey:@"isHit"] boolValue];
		BOOL isTargetCpr = [[result objectForKey:@"isTargetCpr"] boolValue];
		BOOL isTargetBok = [[result objectForKey:@"isTargetBok"] boolValue];
		BOOL isTargetPen = [[result objectForKey:@"isTargetPen"] boolValue];
		
		int cutHp = [[result objectForKey:@"cut"] intValue];
		
		if(isHit){
			[member cutHP:cutHp isBok:isTargetBok isCpr:isTargetCpr isPen:isTargetPen];
			//if(isTargetCpr) [fightAction logActionEffectCpr:target];
			//if(isTargetBok) [fightAction logActionEffectBok:target];
		}else{
			[fightAction logActionEffectMis:member];
		}
	}
	
	for(int i=0;i<[results count];i++){
		result = [results objectAtIndex:i];
		FightMember * member = [result objectForKey:@"target"];
		if(member.isDie){
			[fightAction logActionDie:member];
		}
	}
	
	//添加状态
	NSMutableArray * targets = [NSMutableArray array];
	//[targets addObjectsFromArray:members];
	for(int i=0;i<[results count];i++){
		result = [results objectAtIndex:i];
		FightMember * member = [result objectForKey:@"target"];
		BOOL isHit = [[result objectForKey:@"isHit"] boolValue];
		if(isHit && !member.isDie){
			[targets addObject:member];
		}
	}
	
	NSArray * skillStatus = [[GameDB shared] getSkillStautsIds:id_skl];
	for(NSDictionary * ss in skillStatus){
		int stid = [[ss objectForKey:@"stid"] intValue];
		[FightStatus member:self addStatus:stid to:target other:targets cut:cut hit:isHitMainTarget];
	}
	
	//TODO Log 移动到原位
	if(!is_far_skl){
		[fightAction logActionBack:self];
	}else{
		[fightAction logActionDelay:0.3f];
	}
	
}

//==============================================================================
//==============================================================================
#pragma mark -
-(BOOL)checkTargetActive:(FightMember*)target{
	if(target){
		if(target.isDie){
			CCLOG(@"shit!!! ERROR #1...");
			return NO;
		}
	}else{
		CCLOG(@"shit!!! ERROR #2...");
		return NO;
	}
	return YES;
}

//普通攻击主目标
-(NSDictionary*)attackTarget:(FightMember*)target percent:(float)percent{
	
	if(![self checkTargetActive:target]) return nil;
	
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	int mp_self = 0;
	int mp_targ = 0;
	
	BaseAttribute ba1 = [self getTotalAttribute];
	
	BaseAttribute ba2 = [target getTotalAttribute];
	
	//A命中B
	BOOL isTargetHit = (isHitTarget(ba1, ba2) || [target statusIsCannotMis]);
	mp_self += 30;
	
	BOOL isTargetCpr = NO;
	BOOL isTargetBok = NO;
	BOOL isTargetPen = NO;
	
	float cut = 0;
	
	//[self checkLogTargetEffectByAtk:target hit:isHit];
	
	if(isTargetHit){
		
		cut = attackTarget(ba1, level, ba2);
		
		//A破甲
		if(isCheckPEN(ba1)){
			
			isTargetPen = YES;
			//[fightAction logActionEffectPen:self];
			
			//破甲伤害
			//cut = cut+ba2.DEF/3;
			cut = cut+ba2.DEF*level*3.14/270;
			
			//扣减免伤
			cut = cut * ((100.0f-ba2.TUF)/100.0f);
			
			//[self addActionMP:20];//20
			mp_self += 20;
			
		}else{
			
			//A爆击B
			if(isCheckCRI(ba1)){
				
				isTargetCpr = YES;
				
				//爆伤
				cut = cut * ((150.0f+ba1.CPR)/100.0f);
				
				//TODO LOG 爆伤 动画
				//[fightAction logActionEffectCpr:target];
				
				//[self addActionMP:20];//20
				mp_self += 20;
				
			}
			
			//B挡格A
			if(isCheckBOK(ba2) && ![target statusIsCannotBok]){
				
				isTargetBok = YES;
				
				//挡格减伤
				cut = cut * ((100-30-sqrtf(4*target.level))/100.0f);
				
				//TODO LOG B格挡 动画
				//[fightAction logActionEffectBok:target];
				
				//[target addActionMP:20];//20
				mp_targ += 20;
				
			}else{
				//扣减免伤
				cut = cut * ((100-ba2.TUF)/100.0f);
			}
		}
		
		//[target addActionMP:20];//20
		mp_targ += 20;
		
		cut = (cut*percent);
		if(cut<0) cut = 0;
		
		/*
		[target cutHP:cut isBok:isTargetBok isCpr:isTargetCpr];
		
		[self addActionMP:mp_self];
		[target addActionMP:mp_targ];
		
		//TODO LOG 破甲 动画
		if(isTargetPen && isMain){
			[fightAction logActionEffectPen:self];
		}
		
		if(isTargetCpr){
			//TODO LOG 爆伤 动画
			[fightAction logActionEffectCpr:target];
		}
		if(isTargetBok){
			//TODO LOG B格挡 动画
			[fightAction logActionEffectBok:target];
		}
		*/
		
	}else{
		
		//[target addActionMP:20];//20
		mp_targ += 20;
		[target checkAllStatusAction:Fight_Action_Type_gethurt];
		
		//[self addActionMP:mp_self];
		//[target addActionMP:mp_targ];
		
		//TODO Log B闪避 动画
		//[fightAction logActionEffectMis:target];
		
	}
	
	[result setObject:[NSNumber numberWithBool:isTargetHit] forKey:@"isHit"];
	[result setObject:[NSNumber numberWithBool:isTargetCpr] forKey:@"isTargetCpr"];
	[result setObject:[NSNumber numberWithBool:isTargetBok] forKey:@"isTargetBok"];
	[result setObject:[NSNumber numberWithBool:isTargetPen] forKey:@"isTargetPen"];
	
	[result setObject:[NSNumber numberWithFloat:cut] forKey:@"cut"];
	
	[result setObject:[NSNumber numberWithInt:mp_self] forKey:@"mp_self"];
	[result setObject:[NSNumber numberWithInt:mp_targ] forKey:@"mp_targ"];
	
	[result setObject:target forKey:@"target"];
	
	return result;
}

//反击
-(void)targetCounterAttack:(FightMember*)target{
	
	if(![self checkTargetActive:target]) return;
	if(![self checkTargetActive:self]) return;
	
	if([target statusIsCannotCot]) return;
	
	BaseAttribute ba1 = [self getTotalAttribute];
	BaseAttribute ba2 = [target getTotalAttribute];
	
	float cut = 0;
	
	//B反击A
	if(isCheckCOT(ba2)){
		
		[fightAction logActionEffectCot:target];
		
		//TODO Log B攻击 动画
		if(!target.is_far_atk) [fightAction logActionMove:target target:self];
		[fightAction logActionAttack:target];
		
		//B命中A
		if(isHitTarget(ba2, ba1)){
			
			CCLOG(@"B反击A");
			cut = attackTarget(ba2, target.level, ba1) * 0.35f;
			if(cut<0) cut = 0;
			
			[self cutHP:cut isBok:NO isCpr:NO isPen:NO];
			if([self isDie]){
				[fightAction logActionDie:self];
			}
			
		}else{
			
			//TODO Log A闪避 动画
			[fightAction logActionEffectMis:self];
			[self checkAllStatusAction:Fight_Action_Type_gethurt];
		}
		
		if(!target.is_far_atk){
			[fightAction logActionBack:target];
		}else{
			[fightAction logActionDelay:0.3f];
		}
		
	}
	
}

//连击
-(void)attackContinueTarget:(FightMember*)target{
	
	if(![self checkTargetActive:target]) return;
	if(![self checkTargetActive:self]) return;
	
	int mp_self = 0;
	int mp_targ = 0;
	
	BaseAttribute ba1 = [self getTotalAttribute];
	BaseAttribute ba2 = [target getTotalAttribute];
	
	//A连击B
	if(isCheckCOB(ba1)){
		
		CCLOG(@"连击");
		
		//[self addActionMP:40];//40
		mp_self += 40;
		
		[fightAction logActionEffectCob:self];
		
		BOOL isTargetBok = NO;
		
		//TODO Log 移动到目标前
		if(!is_far_atk){
			[fightAction logActionMove:self target:target];
		}
		
		//TODO Log A攻击 动画
		[fightAction logActionAttack:self];
		
		if(isCheckMIS(ba2)){
			
			//TODO Log B回避A 动画
			[fightAction logActionEffectMis:target];
			
			//[target addActionMP:40];//40
			mp_targ += 40;
			
		}else{
			
			float cut = attackTarget(ba1, level, ba2) * 0.5f;
			
			//格挡
			if(isCheckBOK(ba2)){
				
				isTargetBok = YES;
				
				cut *= 0.5f;
				
				//TODO LOG B格挡 动画
				[fightAction logActionEffectBok:target];
				
			}
			
			//[target addActionMP:40];//40
			mp_targ += 40;
			
			if(cut<0) cut = 0;
			
			[target cutHP:cut isBok:isTargetBok isCpr:NO isPen:NO];
			if([target isDie]){
				[fightAction logActionDie:target];
			}
			
		}
		
		[self addActionMP:mp_self];
		[target addActionMP:mp_targ];
		
		//反击
		[self targetCounterAttack:target];
		
		if(!self.isDie){
			//TODO Log 移动到原位
			if(!is_far_atk){
				[fightAction logActionBack:self];
			}else{
				[fightAction logActionDelay:0.3f];
			}
		}
		
	}
	
}

//==============================================================================
//技能攻击目标
-(NSDictionary*)skillTarget:(FightMember*)target percent:(float)percent{
	
	if(![self checkTargetActive:target]) return nil;
	
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	BaseAttribute ba1 = [self getTotalAttribute];
	BaseAttribute ba2 = [target getTotalAttribute];
	
	//A命中B
	
	BOOL checkHit = isHitTarget(ba1, ba2);
	BOOL cannotMis = [target statusIsCannotMis];
	
	BOOL isTargetHit = (checkHit || cannotMis);
	
	//isTargetHit = YES;
	
	BOOL isTargetBok = NO;
	BOOL isTargetCpr = NO;
	BOOL isTargetPen = NO;
	
	float cut = 0;
	
	//[self checkLogTargetEffectBySkl:target hit:isHit];
	
	if(isTargetHit){
		
		cut = skillTarget(ba1, level, ba2);
		
		//A破甲
		if(isCheckPEN(ba1)){
			
			isTargetPen = YES;
			
			//破甲伤害
			//cut = cut + ba1.INT + ba2.DEF / 3;
			cut = cut+ba2.DEF*level*3.14/270;
			
			//扣减免伤
			cut = cut * ((100-ba2.TUF)/100.0f);
			
		}else{
			
			//A爆击B
			isTargetCpr = isCheckCRI(ba1);
			if(isTargetCpr){
				
				cut = (cut + ba1.INT)*((150+ba1.CPR)/100.0f);
				
				//TODO Log B爆伤 动画
				//[fightAction logActionEffectCpr:target];
				
			}
			
			//B挡格A
			if(isCheckBOK(ba2) && ![target statusIsCannotBok]){
				//挡格减伤
				
				isTargetBok = YES;
				
				//TODO Log B格挡 动画
				//[fightAction logActionEffectBok:target];
				
				//cut = cut * ((100-30-ba2.BOK)/100.0f);
				cut = cut * ((100-30-sqrtf(4*target.level))/100.0f);
				
			}else{
				
				//扣减免伤
				cut = cut * ((100-ba2.TUF)/100.0f);
				
			}
		}
		
		cut = (cut*percent);
		if(cut<0) cut = 0;
		
		//[target cutHP:cut isBok:isTargetBok isCpr:isTargetCpr];
		
	}else{
		
		CCLOG(@"B闪避A");
		
		//TODO Log B回避 动画
		//[fightAction logActionEffectMis:target];
		
		[target checkAllStatusAction:Fight_Action_Type_gethurt];
		
	}
	
	[result setObject:[NSNumber numberWithBool:isTargetHit] forKey:@"isHit"];
	[result setObject:[NSNumber numberWithBool:isTargetCpr] forKey:@"isTargetCpr"];
	[result setObject:[NSNumber numberWithBool:isTargetBok] forKey:@"isTargetBok"];
	[result setObject:[NSNumber numberWithBool:isTargetPen] forKey:@"isTargetPen"];
	[result setObject:[NSNumber numberWithFloat:cut] forKey:@"cut"];
	[result setObject:target forKey:@"target"];
	
	return result;
}

//==============================================================================
//==============================================================================
#pragma mark -

-(void)addStatus:(FightStatus*)status{
	
	if(self.isDie) return;
	
	CCLOG(@"name:%@ add status : %d",name,status.statusId);
	
	if(!allStatus){
		allStatus = [[NSMutableArray alloc] init];
	}
	
	if(status.count>0){
		[allStatus addObject:status];
		//TODO Log 角色添加状态
		[fightAction logActionAddStatus:self status:status];
	}
}
-(void)updateStatus:(FightStatus*)status{
	
	if(self.isDie) return;
	
	//TODO Log 角色状态更新
	[fightAction logActionUpdateStatus:self status:status];
}

-(void)removeStatus:(FightStatus*)status{
	
	if(self.isDie) return;
	
	//TODO Log 角色删除状态
	[fightAction logActionRemoveStatus:self status:status];
	//[allStatus removeObject:status];
}

-(void)cleanStatus{
	
	if(self.isDie) return;
	
	NSMutableArray * noAction = [NSMutableArray array];
	for(FightStatus * status in allStatus){
		if(!status.isActive){
			[noAction addObject:status];
		}
	}
	
	for(FightStatus * status in noAction){
		[allStatus removeObject:status];
	}
	
}

-(void)checkAllStatusAction:(Fight_Action_Type)at{
	if(self.isDie) return;
	for(FightStatus * status in allStatus){
		[status checkStatusType:at];
	}
}

-(void)checkAllStatusActionByAttackBefore{
	if(self.isDie) return;
	for(FightStatus * status in allStatus){
		[status checkStatusByAttackBefore];
	}
}
-(void)checkAllStatusActionByAttackAfter{
	if(self.isDie) return;
	for(FightStatus * status in allStatus){
		[status checkStatusByAttackAfter];
	}
}

-(BOOL)statusIsCannotAtk{
	
	if(self.isDie) return NO;
	
	for(FightStatus * status in allStatus){
		if(status.isNoAtk && status.isActive){
			return YES;
		}
	}
	return NO;
}
-(BOOL)statusIsCannotMis{
	
	if(self.isDie) return NO;
	
	for(FightStatus * status in allStatus){
		if(status.isNoMis && status.isActive){
			return YES;
		}
	}
	return NO;
}
-(BOOL)statusIsCannotBok{
	
	if(self.isDie) return NO;
	
	for(FightStatus * status in allStatus){
		if(status.isNoBok && status.isActive){
			return YES;
		}
	}
	return NO;
}
-(BOOL)statusIsCannotCot{
	
	if(self.isDie) return NO;
	
	for(FightStatus * status in allStatus){
		if(status.isNoCot && status.isActive){
			return YES;
		}
	}
	return NO;
}

//==============================================================================
#pragma mark -
//==============================================================================

-(void)checkLogTargetEffectByAtk:(FightMember*)target hit:(BOOL)hit{
	
	if(eff_atk==0) return;
	
	if(eff_rg_atk==1 && target!=nil){ //单格
		if(eff_dis_atk){
			if(hit){
				//单体效果动画
				[fightAction logActionEffectSingle:target effect:eff_atk offset:eff_offset_atk];
			}
		}else{
			//单体效果动画
			[fightAction logActionEffectSingle:target effect:eff_atk offset:eff_offset_atk];
		}
	}
	if(eff_rg_atk==2 && target==nil){ //全阵
		//全体效果动画
		[fightAction logActionEffectAll:self.targetTeam effect:eff_atk offset:eff_offset_atk];
	}
}
-(void)checkLogTargetEffectBySkl:(FightMember*)target hit:(BOOL)hit{
	
	if(eff_skl==0) return;
	
	if(eff_rg_skl==1 && target!=nil){ //单格
		if(eff_dis_skl){
			if(hit){
				//单全体效果动画
				[fightAction logActionEffectSingle:target effect:eff_skl offset:eff_offset_skl];
			}
		}else{
			//全体效果动画
			[fightAction logActionEffectSingle:target effect:eff_skl offset:eff_offset_skl];
		}
	}
	if(eff_rg_skl==2 && target==nil){ //全阵
		//全体效果动画
		[fightAction logActionEffectAll:self.targetTeam effect:eff_skl offset:eff_offset_skl];
	}
	
}

-(NSString*)getMemberInfo{
	
	NSString * result = [NSString stringWithFormat:
						 @"%d:%@:%d:%d:%d:%@:%d:%d:%d:%d:%d:%f:%d:%d:%d:%d:%d:%d:%d:%@",
						 index,animation,totalHP,id_atk,id_skl,name,
						 currentPower,
						 totalPower,targetId,type,offset,body,show_skl_id,
						 quality,
						 (isShake?1:0),
						 suit_id,
						 eff_atk,
						 eff_skl,
						 currentHP,
						 (barOffset?barOffset:@"")
						 ];
	
	return result;
}

-(NSString*)getPosition{
	return [NSString stringWithFormat:@"%d.%d",selfTeam.classIndex,index];
}

-(int)getTotalHurt{
	//return (totalHP - currentHP);
	//return currentHP;
	return beginHp - currentHP;
}

@end
