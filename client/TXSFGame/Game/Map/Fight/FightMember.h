//
//  FightMember.h
//  TXSFGame
//
//  Created by Tiger Leung on 12-11-22.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"

@class FightAction;
@class FightTeam;
@class FightStatus;

@interface FightMember : NSObject{
	
	BOOL isLoadOtherBuff;
	
	int index;
	int targetId;
	int level;
	int suit_id;
	
	int offset;
	float body;
	int quality;
	
	NSString * name;
	NSString * animation;
	NSString * barOffset;
	
	Fight_member_type type;
	BaseAttribute attribute;
	
	FightTeam * selfTeam;
	FightTeam * targetTeam;
	FightAction * fightAction;
	
	//武器 伤害加成与回合结束回HP
	float arm_hurt_percent;
	float arm_round_add_hp;
	float arm_round_add_hp_percent;
	
	//阵型 回复自身伤害值
	float pos_add_hurt_hp_percent;
	float pos_add_hurt_hp_rate;
	
	//阵型 阵眼速度加成
	//float pos_center_spd_p;
	
	int base_spd;
	
	int currentHP;
	int totalHP;
	
	//add by soul
	int beginHp;//开始的时候是多少血
	
	int currentPower;
	int totalPower;
	
	int id_atk;
	Attack_mode mode_atk;
	BOOL is_far_atk;
	float hart_main_percent_atk;
	float hart_other_percent_atk;
	int eff_atk;
	int eff_offset_atk;
	int eff_rg_atk;
	BOOL eff_dis_atk;
	
	int id_skl;
	Attack_mode mode_skl;
	BOOL is_far_skl;
	float hart_main_percent_skl;
	float hart_other_percent_skl;
	int eff_skl;
	int eff_offset_skl;
	int eff_rg_skl;
	BOOL eff_dis_skl;
	
	BOOL isShake;
	
	int show_skl_id;
	
	NSMutableArray * allStatus;
	
	BOOL isShowSkill;
	
	BOOL isImmunityStatus;
	
}
@property(nonatomic,assign) BOOL isLoadOtherBuff;

@property(nonatomic,assign) int index;
@property(nonatomic,assign) int targetId;
@property(nonatomic,assign) int level;
@property(nonatomic,assign) int quality;

@property(nonatomic,assign) int speed;

@property(nonatomic,assign) Fight_member_type type;
@property(nonatomic,assign) BaseAttribute attribute;

@property(nonatomic,assign) FightTeam * selfTeam;
@property(nonatomic,assign) FightTeam * targetTeam;
@property(nonatomic,assign) FightAction * fightAction;

@property(nonatomic,assign) BOOL isDie;
@property(nonatomic,assign) float percentHP;
@property(nonatomic,assign) float cutPercentHP;

@property(nonatomic,assign) int beginHp;
@property(nonatomic,assign) int currentHP;
@property(nonatomic,assign) int totalHP;
@property(nonatomic,assign) int currentPower;
@property(nonatomic,assign) int totalPower;

@property(nonatomic,assign) BOOL is_far_atk;
@property(nonatomic,assign) BOOL is_far_skl;

@property(nonatomic,assign) BOOL isImmunityStatus;

+(FightMember*)memberOfFightData:(NSString*)str;

+(FightMember*)memberOfMonsterId:(int)mid level:(int)level;

+(FightMember*)memberOfMonsterDict:(NSDictionary*)mDict;

+(FightMember*)memberOfRoleId:(int)rid level:(int)level;
+(FightMember*)memberOfSingleRoleId:(int)rid level:(int)level;

+(FightMember*)memberOfRoleId:(int)rid playerData:(NSDictionary*)data;
+(FightMember*)memberOfNpc:(int)rid level:(int)level;

//-(void)loadAttribute;

-(void)addPosition:(NSString*)pos;

-(void)addBuffByString:(NSString*)buff;
-(void)addBuffByDict:(NSDictionary*)dict;
-(void)addBuff:(BaseAttribute)buff;

-(void)setFightRate:(float)rate;
-(void)addFightRate:(float)rate;
-(void)addFightAbyssBossRate:(float)rate;

-(BaseAttribute)getTotalAttribute;

-(void)fight;

-(void)cutHP:(int)cut isBok:(BOOL)isBok isCpr:(BOOL)isCpr isPen:(BOOL)isPen;
-(void)addActionMP:(int)mp;
-(void)addPercentHP:(float)hp_p PercentMP:(float)mp_p;
-(void)addPercentHP:(float)hp_p PercentMP:(float)mp_p HP:(float)t_hp MP:(float)t_mp;
-(void)addHP:(int)hp;

-(float)getAddHPPercent;
-(float)getCutHPPercent;

-(void)roundEnd;

//==============================================================================
//==============================================================================
-(void)addStatus:(FightStatus*)status;
-(void)updateStatus:(FightStatus*)status;
-(void)removeStatus:(FightStatus*)status;

-(BOOL)statusIsCannotAtk;
-(BOOL)statusIsCannotMis;
-(BOOL)statusIsCannotBok;
-(BOOL)statusIsCannotCot;

//==============================================================================
//==============================================================================
//-(void)checkLogTargetEffectByAtk:(FightMember*)target hit:(BOOL)hit;
//-(void)checkLogTargetEffectBySkl:(FightMember*)target hit:(BOOL)hit;

-(NSString*)getMemberInfo;
-(NSString*)getPosition;

//==============================================================================
//==============================================================================
-(int)getTotalHurt;

@end
