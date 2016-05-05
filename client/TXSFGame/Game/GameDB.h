//
//  GameDB.h
//  TXSFGame
//
//  Created by shoujun huang on 12-12-8.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BaseDataBuff : NSObject{
	int				_time;
	NSDictionary*	_data;
	NSString*		_name;
}
@property(nonatomic,retain)NSString*						name;
@property(nonatomic,retain,getter = getData)NSDictionary*	data;

-(void)updataTime;
-(void)resetTime;

@end

@interface GameDB : NSObject
{
	NSString *_filePath;
	int version;
}
@property(nonatomic,retain)NSString *FilePath;

+(void)cleanCache;

+(GameDB*)shared;
+(void)remove;
+(void)stopAll;
+(void)freeMemory;

//---------------------------------------
-(void)reload;
//-(void)reload:(NSString*)_path;//"resoure/game_db"
-(BOOL)checkOutVersion:(int)_ver;

//------------操作表------------------
-(NSDictionary*)getInfo:(NSString*)_table;

-(NSDictionary*)getRoleList;

-(NSDictionary*)getRoleInfo:(int)_id;
-(NSDictionary*)getRoleInfosByIds:(NSArray*)ids;

-(NSDictionary*)getRoleByIndex:(int)_index;

-(NSDictionary*)getArmInfo:(int)_id;
-(NSDictionary*)getArmInfoByIds:(NSArray*)ids;

-(NSDictionary*)getCarInfo:(int)_id;

-(NSDictionary*)getEquipmentSetInfo:(int)_id;
-(NSDictionary*)getEquipmentSetInfoByIds:(NSArray*)ids;

-(NSDictionary*)getEquipmentInfo:(int)_id;
-(NSDictionary*)getEquipmentInfoByIds:(NSArray*)ids;

-(NSDictionary*)getFateInfo:(int)_id;
-(NSDictionary*)getFateInfoByIds:(NSArray*)ids;

-(NSDictionary*)getFateCostInfo:(int)_id;
-(NSDictionary*)getFateRateInfo:(int)_id;

-(NSDictionary*)getItemInfo:(int)_id;
-(NSDictionary*)getItemInfoByIds:(NSArray*)ids;

-(NSDictionary*)getMonsterInfo:(int)_id;
-(NSDictionary*)getNpcInfo:(int)_id;
-(NSDictionary*)getRewardInfo:(int)_id;

-(NSDictionary*)getSkillInfo:(int)_id;
-(NSDictionary*)getSkillInfoByIds:(NSArray*)ids;

-(NSDictionary*)getJewelShopInfo:(int)_id;
-(NSDictionary*)getJewelInfo:(int)_id;
-(NSDictionary*)getJewelInfoByIds:(NSArray*)ids;
-(NSDictionary*)getJewelLevelInfoWithLevel:(int)_gid level:(int)_level;
-(NSDictionary*)getJewelLevelInfoWithLevels:(int)_gid level:(NSArray*)_level;


-(NSDictionary*)getSkillStateInfo:(int)_id;

-(NSDictionary*)getPositionList;
-(NSDictionary*)getPositionInfo:(int)_id;


-(NSDictionary*)getStateInfo:(int)_id;
-(NSDictionary*)getMapInfo:(int)_id;
-(NSDictionary*)getStageInfo:(int)_id;
-(NSDictionary*)getFightInfo:(int)_id;
-(NSDictionary*)getFusionInfo:(int)_id;
-(NSDictionary*)getRoleLevelInfo:(int)_rid level:(int)_level;
-(NSDictionary*)getMonsterLevelInfo:(int)_mid;//怪物ID查找怪物等级表格 得到属性
-(NSDictionary*)getMonsterLevelInfo:(int)_mid level:(int)_level;//怪物ID查找怪物等级表格 得到属性
-(NSDictionary*)getArmLevelInfo:(int)_aid level:(int)_level;
-(NSDictionary*)getEquipmentLevelInfo:(int)_part level:(int)_level;//部位
-(NSDictionary*)getRoleExpInfo:(int)_level;
-(NSDictionary*)getArmExpInfo:(int)_level;
-(NSDictionary*)getGrouplevelInfo:(int)_level;
-(NSDictionary*)getEquipmentsStrengInfo:(int)_level;
-(NSDictionary*)getEquipmentsMoveInfo:(int)_level;


-(NSDictionary*)getFateLevelInfo:(int)_fid level:(int)_level;
-(NSDictionary*)getFateLevelInfoWithLevels:(int)_fid level:(NSArray*)_level;

-(NSDictionary*)getPositionLevelInfo:(int)_pid level:(int)_level;
-(NSDictionary*)getTaskInfo:(int)_type taskId:(int)_id;
-(NSDictionary*)getTimeBoxInfo:(int)_id;
-(NSDictionary*)getDeepBoxInfo:(int)_id;
-(NSDictionary*)getDeepPositionInfo:(int)_id;
-(NSDictionary*)getDeepGuardInfo:(int)_id;

-(NSArray*)getFootBuffs;//TODO buff only for foot
-(NSDictionary*)getFootBuffInfo:(int)_id;//TODO buff only for foot

-(NSDictionary*)getAllyLevel:(int)_id;
-(NSDictionary*)getAllyRight:(int)_id;
-(NSDictionary*)getAllyGrave:(int)_id;
-(NSArray*)getDailyByType:(int)_type;
-(NSDictionary*)getShopInfo:(int)_id;
-(NSDictionary*)getDireShopInfo:(int)_iid;
-(NSDictionary*)getRuleInfo:(int)_id;

-(NSDictionary*)getDaySuccessInfo:(int)_id;
-(NSDictionary*)getEverSuccessInfo:(int)_id;

//-----------------------
//add
//-----------------------
-(NSDictionary*)getBFTaskInfo:(int)_id;
-(NSDictionary*)getBFTaskInfo:(int)_tid q:(int)_q;	// 任务id，品质;q数值对应QualityItem
-(NSDictionary*)getChapterInfo:(int)_id;
-(NSDictionary*)getIronRateInfo:(int)_id;
-(NSDictionary*)getFeteRateInfo:(int)_id;
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------------------------------------------------------------
//---------------获得表-------------------------------------
-(NSDictionary*)getFusionTable;
-(NSDictionary*)readDB:(NSString*)_table;
-(NSDictionary*)readDBFromFile:(NSString*)_table;
-(NSArray*)getSkillStautsIds:(int)sid;
-(NSDictionary*)getGlobalConfig;
-(id)getGlobalSetting:(NSString*)key;
-(NSArray*)getNames;

-(NSDictionary*)getBanWord;
-(NSMutableDictionary*)getIntro:(int)step;
-(NSString*)getErrorMsg:(int)errorid;
-(int)mapRolesMax;

-(NSDictionary*)getEquipmentsStrengTable;

-(NSDictionary*)getBossLevelInfoBydId:(int)_id;
-(NSDictionary*)getFightTips:(int)_type;
-(NSDictionary*)getLoadingTips:(int)_type;

-(NSDictionary*)getfuncsInfo:(int)_id;

//武将升级
-(NSDictionary*)getRoleupQualityInfo:(int)_type quality:(int)_quality;
-(NSDictionary*)getRoleupInfo:(int)_type quality:(int)_quality grade:(int)_grade check:(int)_check;
-(NSDictionary*)getRoleupTypeInfo:(int)_rid;

-(NSDictionary*)getGemUpRate:(int)_s1 startLevel:(int)_sl to:(int)_t1 toLevel:(int)_tl;

// 狩龙相关
-(NSDictionary*)getAllBoatExchange:(int)_id;	// 天舟兑换物品
-(NSDictionary*)getAllBoatExchange;	// 天舟兑换物品表
-(NSDictionary*)getAllBoatLevel:(int)_id;		// 天舟等级
-(NSDictionary*)getAllBoatLevelWithType:(int)_type level:(int)_level;		// 天舟等级(类型，等级)
-(NSDictionary*)getAwarBook:(int)_id;			// 天书
-(NSDictionary*)getAwarNpcConfig:(int)_id;		// 战斗npc配置表
-(NSDictionary*)getAwarPerConfig:(int)_id;		// 每场战斗配置表
-(NSDictionary*)getAwarStartConfig:(int)_id;	// 战斗开始配置表
-(NSDictionary*)getAwarStrongMap:(int)_id;		// 魔龙降世势力地图表
-(NSDictionary*)getAwarStrongMap;// 魔龙降世势力地图表
@end


