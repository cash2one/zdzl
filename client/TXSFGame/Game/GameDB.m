//
//  GameDB.m
//  TXSFGame
//
//  Created by shoujun huang on 12-12-8.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "GameDB.h"
#import "Config.h"
#import "CJSONDeserializer.h"
#import "CJSONSerializer.h"

#import "SSKeychain.h"
#import "NSData+Base64.h"
#import "NSDataAES256.h"
#import "NSString+MD5Addition.h"
#import "UIDevice+IdentifierAddition.h"

#import "GameConnection.h"
#import "ASIHTTPRequest.h"
#import "NSData+GZIP.h"

@class GameDatabaseCache;
static GameDatabaseCache * downloadCache = nil;

@interface GameDatabaseCache:NSObject{
	long long contentLength;
	long long loadLength;
	NSMutableData * cacheData;
}
@property(nonatomic,assign) long long contentLength;
@property(nonatomic,assign) long long loadLength;
-(NSData*)cache;
-(float)getCompletePercent;
@end

@implementation GameDatabaseCache
@synthesize contentLength;
@synthesize loadLength;
-(id)init{
	if(self=[super init]){
		contentLength = 0;
		loadLength = 0;
		cacheData = [[NSMutableData alloc] init];
	}
	return self;
}
-(void)appendData:(NSData*)data{
	[cacheData appendData:data];
	loadLength += data.length;
}
-(NSData*)cache{
	return [NSData dataWithData:cacheData];
}
-(float)getCompletePercent{
	if(contentLength==0){
		return 0;
	}
	return (loadLength/contentLength);
}
-(void)dealloc{
	[cacheData release];
	[super dealloc];
	downloadCache = nil;
}
@end

#define CONFIG_ROLE_LEVELE @"role_level"
#define CONFIG_ROLE_EXP @"role_exp"
#define CONFIG_ROLE @"role"
#define CONFIG_FATE @"fate"
#define CONFIG_FATE_RATE @"fate_rate"
#define CONFIG_FATE_COST @"fate_cost"
#define CONFIG_FATE_LEVEL @"fate_level"
#define CONFIG_ARM @"arm"
#define CONFIG_ARM_EXP @"arm_exp"
#define CONFIG_ARM_LEVEL @"arm_level"
#define CONFIG_SKILL @"skill"
#define CONFIG_SKILL_STATE @"sk_state"
#define CONFIG_STATE @"state"
#define CONFIG_EQUIP @"equip"
#define CONFIG_EQUIP_LEVEL @"eq_level"
#define CONFIG_EQUIP_SET @"eq_set"
#define CONFIG_EQUIP_STRENG @"str_eq"
#define CONFIG_EQUIP_MOVE @"str_move"
#define CONFIG_ITEM @"item"
#define CONFIG_FUSION @"fusion"
#define CONFIG_REWARD @"reward"
#define CONFIG_MONSTER @"monster"
#define CONFIG_MONSTER_LEVEL @"monster_level"
#define CONFIG_NPC @"npc"
#define CONFIG_CAR @"car"
//#define CONFIG_GROUP_LEVEL @"group_level"
#define CONFIG_MAP @"map"
#define CONFIG_STAGE @"stage"
#define CONFIG_FIGHT @"fight"
#define CONFIG_POSITION @"position"
#define CONFIG_POS_LEVEL @"pos_level"
#define CONFIG_TASK @"task"
#define CONFIG_DAILY @"daily"
#define CONFIG_SHOP	@"shop"
#define CONFIG_Dire_SHOP @"direct_shop"
#define CONFIG_RULE @"rule"

//add
#define CONFIG_IRON_RATE @"mine_rate"
#define CONFIG_BF_TASK @"bf_task"
#define CONFIG_CHAPTER @"chapter"
#define CONFIG_FETE_RATE @"fete_rate"


#define CONFIG_TIME_BOX @"tbox"
#define CONFIG_DEEP_BOX @"deep_box"
#define CONFIG_DEEP_POSITION @"deep_pos"
#define CONFIG_DEEP_GUARD @"deep_guard"
#define CONFIG_BUFF @"buff"

#define CONFIG_ALLY_LEVEL @"ally_level"//同盟等级表
#define CONFIG_ALLY_RIGHT @"ally_right"//职务权限表
#define CONFIG_ALLY_GRAVE @"ally_grave"//同盟铭刻表

//seting
#define CONFIG_SETTING @"setting"
#define CONFIG_NAMES @"names"

//intro
#define CONFIG_INTRO @"intro"
#define CONFIG_ERROR @"error"
//#define CONFIG_BANWORD @"ban_word"

#define CONFIG_BOSS_LEVEL @"boss_level"
//-----
#define CONFIG_GAME_TIPS @"tips"
//-----


#define CONFIG_ACHI_DAY @"achi_day"
#define CONFIG_ACHI_ETERNAL @"achi_eternal"


#define CONFIG_FUNCS @"funcs"

#define CONFIG_gem @"gem"
#define CONFIG_gem_level @"gem_level"
#define CONFIG_gem_up_rate @"gem_up_rate"
#define CONFIG_gem_shop @"gem_shop"

#define CONFIG_roleup @"roleup"
#define CONFIG_roleup_type @"roleup_type"

// 狩龙相关
#define CONFIG_ALLY_BOAT_EXCHANGE		@"ally_boat_exchange"		// 天舟兑换物品
#define CONFIG_ALLY_BOAT_LEVEL			@"ally_boat_level"			// 天舟等级
#define CONFIG_AWAR_BOOK				@"awar_book"				// 天书
#define CONFIG_AWAR_NPC_CONFIG			@"awar_npc_config"			// 战斗npc配置表
#define CONFIG_AWAR_PER_CONFIG			@"awar_per_config"			// 每场战斗配置表
#define CONFIG_AWAR_START_CONFIG		@"awar_start_config"		// 战斗开始配置表
#define CONFIG_AWAR_STRONG_MAP			@"awar_strong_map"			// 魔龙降世势力地图表

enum{
	GameTipsType_fight = 1 ,
	GameTipsType_loading = 2 ,
};

static NSString * db_TableName[] = {
	CONFIG_ROLE,
	CONFIG_ROLE_LEVELE,
	CONFIG_ROLE_EXP,
	CONFIG_FATE,
	CONFIG_FATE_RATE,
	CONFIG_FATE_COST,
	CONFIG_FATE_LEVEL,
	CONFIG_ARM,
	CONFIG_ARM_EXP,
	CONFIG_ARM_LEVEL,
	CONFIG_SKILL,
	CONFIG_SKILL_STATE,
	CONFIG_STATE,
	CONFIG_EQUIP,
	CONFIG_EQUIP_LEVEL,
	CONFIG_EQUIP_SET,
	CONFIG_EQUIP_STRENG,
	CONFIG_EQUIP_MOVE,
	CONFIG_ITEM,
	CONFIG_FUSION,
	CONFIG_REWARD,
	CONFIG_MONSTER,
	CONFIG_MONSTER_LEVEL,
	CONFIG_NPC,
	CONFIG_CAR,
	//	CONFIG_GROUP_LEVEL,
	CONFIG_MAP,
	CONFIG_STAGE,
	CONFIG_FIGHT,
	CONFIG_POSITION,
	CONFIG_POS_LEVEL,
	CONFIG_TASK,
	CONFIG_DAILY,
	CONFIG_SHOP,
	CONFIG_Dire_SHOP,
	CONFIG_RULE,
	CONFIG_IRON_RATE,
	CONFIG_BF_TASK,
	CONFIG_CHAPTER,
	CONFIG_FETE_RATE,
	CONFIG_SETTING,
	CONFIG_TIME_BOX,
	CONFIG_DEEP_BOX,
	CONFIG_DEEP_POSITION,
	CONFIG_DEEP_GUARD,
	CONFIG_BUFF,
	CONFIG_ALLY_LEVEL,
	CONFIG_ALLY_RIGHT,
	CONFIG_NAMES,
	CONFIG_INTRO,
	CONFIG_ERROR,
	CONFIG_BOSS_LEVEL,
    CONFIG_ALLY_GRAVE,
	//CONFIG_BANWORD,
	//
	CONFIG_GAME_TIPS,
	//
	
	CONFIG_ACHI_DAY,
	CONFIG_ACHI_ETERNAL,
	
	CONFIG_FUNCS,
	
	CONFIG_gem,
	CONFIG_gem_level,
	CONFIG_gem_up_rate,
	CONFIG_gem_shop,
	
	
	CONFIG_roleup,
	CONFIG_roleup_type,
	
	CONFIG_ALLY_BOAT_EXCHANGE,
	CONFIG_ALLY_BOAT_LEVEL,
	CONFIG_AWAR_BOOK,
	CONFIG_AWAR_NPC_CONFIG,
	CONFIG_AWAR_PER_CONFIG,
	CONFIG_AWAR_START_CONFIG,
	CONFIG_AWAR_STRONG_MAP,
	
};
static int db_table_name_index = -1;
int getTotalTableName(){
	return (sizeof(db_TableName)/sizeof(db_TableName[0]));
};
NSString * getTableNameByIndex(int index){
	int total = getTotalTableName();
	if(index>=total) return nil;
	return db_TableName[index];
};

void postLoadData(){
	dispatch_async(dispatch_get_main_queue(), ^{
		int total = getTotalTableName();
		if(db_table_name_index>=total){
			return;
		}
		db_table_name_index++;
		
		NSMutableDictionary * progress = [NSMutableDictionary dictionary];
		[progress setObject:[NSNumber numberWithInt:db_table_name_index] forKey:@"index"];
		[progress setObject:[NSNumber numberWithInt:total] forKey:@"total"];
		[GameConnection post:ConnPost_getUpdateReload object:progress];
	});
}

#define CONFIGURATION_KEYCHAIN_DB_SERVICE @"com.service.game_db"
#define CONFIGURATION_KEYCHAIN_DB_FILE @"file_"
#define CONFIGURATION_KEYCHAIN_DB_PASSWORD @"password_"

#define CONFIGURATION_GAME_INFO @"game_info"

//debug 数据
#define GAMEDB_DEBUG____________ YES

#define MAX_KEEP 3

static NSMutableDictionary* db_buff  = nil;
static NSMutableArray*		del_buff = nil;

static inline BaseDataBuff * getBaseDataBuff(NSString*_n){
	BaseDataBuff* _buff = [db_buff objectForKey:_n];
	if (_buff == nil) {
		CCLOG(@"(%@)BaseDataHelper create",_n);
		NSDictionary* dict = [[GameDB shared] readDBFromFile:_n];
		if (dict) {
			_buff = [[[BaseDataBuff alloc] init] autorelease];
			_buff.data = dict;
			_buff.name = _n;
			[db_buff setObject:_buff forKey:_n];
		}
	}
	return _buff;
}

@implementation BaseDataBuff

@synthesize name = _name;
@synthesize data = _data;

-(id)init{
	if ((self = [super init]) != nil) {
		[self resetTime];
	}
	return self;
}

-(void)dealloc{
	
	if (_name) {
		CCLOG(@"(%@)BaseDataHelper dealloc",self.name);
	}
	
	if (_name) {
		[_name release];
		_name = nil;
	}
	
	if (_data) {
		[_data release];
		_data = nil;
	}
	
	[super dealloc];
}

-(NSDictionary*)getData{
	[self resetTime];
	return _data;
}

-(void)resetTime{
	_time = MAX_KEEP;
}

-(void)updataTime{
	_time--;
	if (_time <= 0) {
		//准备删除它
		if (del_buff != nil) {
			if (![del_buff containsObject:self.name]) {
				[del_buff addObject:self.name];
			}
		}
	}
}

@end

static GameDB	*m_instance  = nil;
static NSTimer	*s_DBTimer = nil;

@implementation GameDB

@synthesize FilePath = _filePath;

#pragma mark -

+(void)stopTimer{
	if(s_DBTimer){
		[s_DBTimer invalidate];
		s_DBTimer = nil;
	}
}

+(void)startTimer{
	[GameDB stopTimer];
	s_DBTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
												 target:[GameDB class]
											   selector:@selector(updataTime)
											   userInfo:nil repeats:YES];
}

+(void)updataTime{
	if (db_buff != nil) {
	
		[db_buff enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			BaseDataBuff* _buff = (BaseDataBuff*)obj;
			[_buff updataTime];
		}];
		
		if (del_buff != nil) {
			//删除那些倒计时结束的
			[db_buff removeObjectsForKeys:del_buff];
			//清空
			[del_buff removeAllObjects];
		}
		
	}
}

+(void)cleanCache{
	NSString * path = getLibraryPath();
	NSString * db_dir = [NSString stringWithFormat:@"%@/%@/",path,GAME_DB_DIR];
	NSString * cache_dir = [NSString stringWithFormat:@"%@/%@/",path,GAME_DB_Cache_DIR];
	deleteFile(db_dir);
	deleteFile(cache_dir);
}

+(GameDB*)shared
{
	if (!m_instance) {
		m_instance = [[GameDB alloc] init];
		[GameDB startTimer];
	}
	return m_instance;
}

+(void)stopAll{
	[GameDB remove];
}

+(void)remove
{
	[GameDB stopTimer];
	[GameDB freeMemory];
	
	if (m_instance) {
		[m_instance release];
		m_instance=nil;
	}
}

+(void)freeMemory{
	//TODO 清空
	if (db_buff != nil) {
		[db_buff removeAllObjects];
	}
	if (del_buff != nil) {
		[del_buff removeAllObjects];
	}
}

-(id)init{
	
	if ((self = [super init]) != nil) {
		db_buff  = [[NSMutableDictionary alloc] init];
		del_buff = [[NSMutableArray alloc] init];
 	}
	
	return self;
}

-(void)dealloc
{
	[_filePath release];
	
	if (db_buff != nil) {
		[db_buff release];
		db_buff = nil;
	}
	
	if (del_buff != nil) {
		[del_buff release];
		del_buff = nil;
	}
	
	[super dealloc];
	CCLOG(@"GameDB dealloc");
}

-(NSData*)getDecryptData:(NSData*)data{
	data = [data AES128DecryptWithKey:@"xf3R0xdcmx8bxc0J"];
	data = [data gunzippedData];
	return data;
}

-(void)reload{
	
	//检测 加载大表 分离大表
	//武器表
	[self process_common:CONFIG_ARM key:@"id"];
	
	//武器经验
	[self process_common:CONFIG_ARM_EXP key:@"level"];
	//武器等级
	[self process_condition:CONFIG_ARM_LEVEL key:@"level"];
	//坐骑表
	[self process_common:CONFIG_CAR key:@"id"];
	//装备表
	[self process_common:CONFIG_EQUIP key:@"id"];
	//套装表
	[self process_common:CONFIG_EQUIP_SET key:@"id"];
	//套装等级
	[self process_condition:CONFIG_EQUIP_LEVEL key:@"level"];
	//猎命
	[self process_common:CONFIG_FATE key:@"id"];
	//猎命等级
	[self process_condition:CONFIG_FATE_LEVEL key:@"level"];
	//
	[self process_common:CONFIG_FATE_RATE key:@"id"];
	//
	[self process_common:CONFIG_FIGHT key:@"id"];
	//
	[self process_common:CONFIG_FUSION key:@"id"];
	
	[self process_common:CONFIG_FATE_COST key:@"id"];
	//
	//[self process_common:CONFIG_GROUP_LEVEL key:@"level"];
	//地图
	[self process_common:CONFIG_MAP key:@"id"];
	//物品
	[self process_common:CONFIG_ITEM key:@"id"];
	//怪物
	[self process_common:CONFIG_MONSTER key:@"id"];
	//怪物等级
	[self process_condition:CONFIG_MONSTER_LEVEL key:@"level"];
	//[self process_common:CONFIG_MONSTER_LEVEL key:@"mid"];
	//NPC
	[self process_common:CONFIG_NPC key:@"id"];
	//坐骑
	//[self process_common:CONFIG_CAR key:@"id"];
	
	[self process_condition:CONFIG_POS_LEVEL key:@"level"];
	//NPC
	[self process_common:CONFIG_POSITION key:@"id"];
	//奖励
	[self process_common:CONFIG_REWARD key:@"id"];
	//角色
	[self process_common:CONFIG_ROLE key:@"id"];
	//角色经验
	[self process_common:CONFIG_ROLE_EXP key:@"level"];
	//角色等级
	[self process_condition:CONFIG_ROLE_LEVELE key:@"level"];
	//技能
	[self process_common:CONFIG_SKILL key:@"id"];
	//技能状态
	[self process_common:CONFIG_SKILL_STATE key:@"id"];
	//副本
	[self process_common:CONFIG_STAGE key:@"id"];
	//状态
	[self process_common:CONFIG_STATE key:@"id"];
    
	[self process_common:CONFIG_ALLY_GRAVE key:@"id"];
    
	//装备强化
	[self process_common:CONFIG_EQUIP_STRENG key:@"level"];
	//装备等级转移
	[self process_common:CONFIG_EQUIP_MOVE key:@"level"];
	//任务
	[self process_condition:CONFIG_TASK key:@"id"];
	// 日常
	[self process_condition:CONFIG_DAILY key:@"id"];
	// 商店
	[self process_common:CONFIG_SHOP key:@"id"];
	[self process_common:CONFIG_Dire_SHOP key:@"iid"];
	//-add
	[self process_common:CONFIG_RULE key:@"id"];
	
	[self process_common:CONFIG_IRON_RATE key:@"id"];//玄铁概率表
	
	[self process_common:CONFIG_CHAPTER key:@"id"];//章节
	
	[self process_common:CONFIG_BF_TASK key:@"id"];//兵符
	
	[self process_common:CONFIG_FETE_RATE key:@"id"];//兵符
	
	[self process_common:CONFIG_TIME_BOX key:@"id"];//时光盒
	
	[self process_common:CONFIG_DEEP_BOX key:@"id"];//深渊宝箱
	
	[self process_common:CONFIG_DEEP_POSITION key:@"id"];//深渊阵型
	
	[self process_common:CONFIG_DEEP_GUARD key:@"id"];//深渊精英
	
	[self process_common:CONFIG_BUFF key:@"id"];//buff
	
	[self process_common:CONFIG_ALLY_LEVEL key:@"id"];//同盟等级表
	
	[self process_common:CONFIG_ALLY_RIGHT key:@"id"];//同盟权限表
	
	[self process_setting:CONFIG_SETTING];
	
	[self process_common:CONFIG_NAMES key:@"id"];
	
	[self process_common:CONFIG_INTRO key:@"id"];
	
	//[self process_common:CONFIG_BANWORD key:@"id"];
	[self process_common:CONFIG_ERROR key:@"id"];
	
	[self process_common:CONFIG_BOSS_LEVEL key:@"id"];
	
	//---
	[self process_condition:CONFIG_GAME_TIPS key:@"stype"];
	//--[self process_common:CONFIG_FIGHT_TIPS key:@"id"];
	//
	
	//每日成就
	[self process_common:CONFIG_ACHI_DAY key:@"id"];
	//永久成就
	[self process_common:CONFIG_ACHI_ETERNAL key:@"id"];
	
	
	[self process_common:CONFIG_FUNCS key:@"id"];
	
	[self process_common:CONFIG_gem key:@"id"];
	
	//[self process_common:CONFIG_gem_up_rate key:@"id"];
	
	[self process_common:CONFIG_gem_shop key:@"id"];
	
	[self process_condition:CONFIG_gem_level key:@"level"];
	
	//一个角色ID 对应一个升级的类型
	[self process_common:CONFIG_roleup_type key:@"rid"];
	[self process_conditions:CONFIG_roleup
						 key:[NSArray arrayWithObjects:@"type",@"quality",@"grade",nil]
					 findKey:@"check"];
	
	[self process_conditions:CONFIG_gem_up_rate
						 key:[NSArray arrayWithObjects:@"fq",@"flv",@"tq",nil]
					 findKey:@"tlv"];
	
	[self process_common:CONFIG_ALLY_BOAT_EXCHANGE key:@"id"];
	[self process_common:CONFIG_ALLY_BOAT_LEVEL key:@"id"];
	[self process_common:CONFIG_AWAR_BOOK key:@"id"];
	[self process_common:CONFIG_AWAR_NPC_CONFIG key:@"id"];
	[self process_common:CONFIG_AWAR_PER_CONFIG key:@"id"];
	[self process_common:CONFIG_AWAR_START_CONFIG key:@"id"];
	[self process_common:CONFIG_AWAR_STRONG_MAP key:@"id"];
	
	[self setOutVersion:version];
	
}

-(void)setOutVersion:(int)_ver{
	NSMutableDictionary *_info = [NSMutableDictionary dictionary];
	[_info setObject:[NSNumber numberWithInt:_ver] forKey:@"version"];
	[self writeDB:_info key:CONFIGURATION_GAME_INFO];
}

-(BOOL)checkOutVersion:(int)_ver
{
	version = _ver;
	
	NSDictionary *_dict = [self readDB:CONFIGURATION_GAME_INFO];
	BOOL isLoad = YES;
	if(_dict){
		//判断是不是需要去加载
		if([[_dict objectForKey:@"version"] intValue] == version){
			isLoad = NO;
		}
	}
	
	//TODO
	//version = 9999;
	//isLoad = YES;
	
	if(isLoad){
		[GameConnection post:ConnPost_getUpdateDatabaseStart object:nil];
		[self downloadDB];
	}else{
		[GameConnection post:ConnPost_getUpdateDatabaseOver object:nil];
	}
	return isLoad;
}

-(void)downloadDB{
	
	db_table_name_index += 1;
	
	NSString * tableName = getTableNameByIndex(db_table_name_index);
	if(tableName){
		
		NSString * path = [[GameConnection share] getDBPath];
		
		//__block long long contentLength = 0;
		//__block long long loadLength = 0;
		//NSMutableData * result = [[NSMutableData alloc] init];
		
		downloadCache = [[GameDatabaseCache alloc] init];
		
		NSURL * url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",path,tableName]];
		
		ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:url];
		[request setTimeOutSeconds:15*60];
		[request setCompletionBlock:^{
			
			NSData * data = [downloadCache cache];
			[downloadCache release];
			
			[self getCompletionData:data];
		}];
		[request setFailedBlock:^{
			[downloadCache release];
			[self getCompletionData:nil];
		}];
		
		[request setHeadersReceivedBlock:^(NSDictionary*headers){
			
			downloadCache.contentLength = [[headers objectForKey:@"Content-Length"] longLongValue];
			
			NSMutableDictionary * progress = [NSMutableDictionary dictionary];
			[progress setObject:[NSNumber numberWithInt:db_table_name_index] forKey:@"index"];
			[progress setObject:[NSNumber numberWithInt:getTotalTableName()] forKey:@"total"];
			[progress setObject:[NSNumber numberWithInt:0] forKey:@"percent"];
			
			[GameConnection post:ConnPost_getUpdateProgress object:progress];
			
		}];
		
		[request setDataReceivedBlock:^(NSData * data){
			
			[downloadCache appendData:data];
			
			NSMutableDictionary * progress = [NSMutableDictionary dictionary];
			[progress setObject:[NSNumber numberWithInt:db_table_name_index] forKey:@"index"];
			[progress setObject:[NSNumber numberWithInt:getTotalTableName()] forKey:@"total"];
			//[progress setObject:[NSNumber numberWithFloat:((float)loadLength/contentLength)] forKey:@"percent"];
			[progress setObject:[NSNumber numberWithFloat:[downloadCache getCompletePercent]] forKey:@"percent"];
			
			[GameConnection post:ConnPost_getUpdateProgress object:progress];
			
		}];
		
		[request startAsynchronous];
		
	}else{
		
		db_table_name_index = -1;
		
		//[GameConnection post:ConnPost_getUpdateReload object:nil];
		postLoadData();
		
		dispatch_queue_t reload_queue = dispatch_queue_create("com.game.reload", NULL);
		dispatch_async(reload_queue, ^{
			
			NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
			[self reload];
			[pool release];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[GameConnection post:ConnPost_getUpdateDatabaseOver object:nil];
			});
			
		});
		dispatch_release(reload_queue);
		
	}
	
}

-(void)getCompletionData:(NSData*)data{
	
	NSString * name = getTableNameByIndex(db_table_name_index);
	
	CCLOG(@"getCompletionData %@ ",name);
	
	if(data){
		if([data length]>0){
			
			NSString * file = getLibraryCachePathByName(name);
			[data writeToFile:file atomically:YES];
			
			[NSTimer scheduledTimerWithTimeInterval:0.05f
											 target:self
										   selector:@selector(downloadDB)
										   userInfo:nil
											repeats:NO];
			return;
		}
	}
	
	//TODO show alert down error
	
	CCLOG(@"Download error : %@ \n",name);
	
	
}

#pragma mark -
#pragma mark io

-(NSDictionary*)readDBFromFile:(NSString *)_key{
	if(![self checkHasRecord:_key]) return nil;
	
	NSString * gameRecordPassword = [self getRandomPassword:_key];
	NSString * filePath = getLibraryFilePathByName([self getRandomFileName:_key]);
	
	NSString * str = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
	NSData * data = [NSData dataFromBase64String:str];
	NSData * decodeData = [data AES256DecryptWithKey:gameRecordPassword];
	
	NSString *error;
	NSPropertyListFormat format;
	NSDictionary * dict = (NSDictionary*)[NSPropertyListSerialization propertyListFromData:decodeData
																		  mutabilityOption:NSPropertyListImmutable
																					format:&format
																		  errorDescription:&error];
	
	return dict;
}

-(NSDictionary*)readDB:(NSString*)_key
{
	BaseDataBuff* _buff = getBaseDataBuff(_key);
	
	if (_buff) {
		return [_buff getData];
	}
	
	return nil;
}
-(void)writeDB:(NSDictionary*)target key:(NSString*)_key
{
	
	//-----------------------------------------------------------------
	NSString * gameRecordPassword = [self getRandomPassword:_key];
	
	NSDictionary * dict = [NSDictionary dictionaryWithDictionary:target];
	NSString * filePath = getLibraryFilePathByName([self getRandomFileName:_key]);
	NSString * error;
	NSData * data = [NSPropertyListSerialization dataFromPropertyList:dict
															   format:NSPropertyListBinaryFormat_v1_0
													 errorDescription:&error];
	NSData * encodeData = [data AES256EncryptWithKey:gameRecordPassword];
	NSString * str = [encodeData base64EncodedString];
	
	[NSKeyedArchiver archiveRootObject:str toFile:filePath];
	//-----------------------------------------------------------------
	
}
-(BOOL)checkHasRecord:(NSString*)key{
	NSString * filePath = getLibraryFilePathByName([self getRandomFileName:key]);
	if(checkHasFile(filePath)){
		return YES;
	}
	return NO;
}

-(NSString*)getRandomPassword:(NSString*)key{
	NSString * password = [NSString stringWithFormat:@"%@_%@",CONFIGURATION_KEYCHAIN_DB_PASSWORD,key];
	password = [password stringFromMD5];
	NSString * string = [SSKeychain passwordForService:CONFIGURATION_KEYCHAIN_DB_SERVICE
											   account:password];
	if(string==nil){
		[SSKeychain setPassword:randomLetter(16)
					 forService:CONFIGURATION_KEYCHAIN_DB_SERVICE
						account:password];
		string = [SSKeychain passwordForService:CONFIGURATION_KEYCHAIN_DB_SERVICE
										account:password];
	}
	return string;
}

-(NSString*)getRandomFileName:(NSString*)key{
	NSString * filename = [NSString stringWithFormat:@"%@_%@",CONFIGURATION_KEYCHAIN_DB_FILE,key];
	filename = [filename stringFromMD5];
	NSString * string = [SSKeychain passwordForService:CONFIGURATION_KEYCHAIN_DB_SERVICE account:filename];
	if(string==nil){
		[SSKeychain setPassword:randomLetter(16)
					 forService:CONFIGURATION_KEYCHAIN_DB_SERVICE
						account:filename];
		string = [SSKeychain passwordForService:CONFIGURATION_KEYCHAIN_DB_SERVICE
										account:filename];
	}
	return [NSString stringWithFormat:@"_%@_",string];
}

#pragma mark -
#pragma mark process table

-(NSDictionary*)process_setting:(NSString*)_table
{
	NSString * file = getLibraryCachePathByName(_table);
	NSData * data = [[NSFileManager defaultManager] contentsAtPath:file];
	//data = [data gunzippedData];
	data = [self getDecryptData:data];
	
	CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];
	NSMutableDictionary *set_dict = [NSMutableDictionary dictionary];
	NSError *error = nil;
	NSArray *array = [deserializer deserializeAsArray:data error:&error];
	if (error) {
		CCLOG(@"getInfo role_level! erro:%@",[error description]);
		return set_dict;
	}
	for (NSDictionary *ite in array) {
		[set_dict setObject:[ite objectForKey:@"value"] forKey:[ite objectForKey:@"key"]];
	}
	[self writeDB:set_dict key:_table];
	
	//删除tmp file文件
	deleteFile(file);
	postLoadData();
	
	return set_dict;
}
-(void)process_condition:(NSString*)_table key:(NSString*)_handle
{
	NSString * file = getLibraryCachePathByName(_table);
	NSData * data = [[NSFileManager defaultManager] contentsAtPath:file];
	//data = [data gunzippedData];
	data = [self getDecryptData:data];
	
	CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];
	NSError *error = nil;
	NSDictionary *dict = [deserializer deserializeAsDictionary:data error:&error];
	if (error) {
		CCLOG(@"getInfo %@! erro:%@",_table,[error description]);
		return ;
	}
	NSArray *keys = [dict allKeys];
	for (NSString *_key in keys) {
		//CCLOG(_key);
		NSArray *_list = [dict objectForKey:_key];
		NSMutableDictionary *targetDict = [NSMutableDictionary dictionary];
		for (NSDictionary *_dict_ in _list) {
			int _value = [[_dict_ objectForKey:_handle] intValue];
			[targetDict setObject:_dict_ forKey:[NSString stringWithFormat:@"%d",_value]];
		}
		NSString *_newKey = [NSString stringWithFormat:@"%@_%@",_table,_key];
		[self writeDB:targetDict key:_newKey];
	}
	
	//删除tmp file文件
	deleteFile(file);
	postLoadData();
	
}

-(void)process_conditions:(NSString*)_table key:(NSArray*)keyfilters findKey:(NSString*)_fKey
{
	NSString * file = getLibraryCachePathByName(_table);
	NSData * data = [[NSFileManager defaultManager] contentsAtPath:file];
	data = [self getDecryptData:data];
	
	CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];
	NSError *error = nil;
	NSArray *array = [deserializer deserializeAsArray:data error:&error];
	if (error) {
		CCLOG(@"getInfo faild! erro:%@",[error description]);
		return ;
	}
	
	NSMutableArray *key1 = [NSMutableArray arrayWithArray:keyfilters];
	NSString* lastKey = [key1 lastObject];
	[key1 removeLastObject];
	
	NSMutableDictionary* resultDict = [NSMutableDictionary dictionary];
	for (NSDictionary* dict in array) {
		NSString* key = [NSString stringWithFormat:@""];
		for (NSString* tempKey in key1) {
			key = [key stringByAppendingFormat:@"_%d",[[dict objectForKey:tempKey] intValue]];
		}
		NSMutableArray* rArray = [NSMutableArray arrayWithArray:[resultDict objectForKey:key]];
		[rArray addObject:dict];
		[resultDict setObject:rArray forKey:key];
	}
	
	NSArray* resultKeys = [resultDict allKeys];
	for (NSString* resultKey in resultKeys) {
		NSArray* resultValues = [resultDict objectForKey:resultKey];
		NSMutableDictionary *target = [NSMutableDictionary dictionary];
		for (NSDictionary *_dict in resultValues) {
			int _tid = [[_dict objectForKey:lastKey] intValue ];
			int _id = [[_dict objectForKey:_fKey] intValue ];
			NSMutableDictionary* tempDict = [NSMutableDictionary dictionaryWithDictionary:[target objectForKey:[NSString stringWithFormat:@"%d",_tid]]];
			[tempDict setObject:_dict forKey:[NSString stringWithFormat:@"%d",_id]];
			[target setObject:tempDict forKey:[NSString stringWithFormat:@"%d",_tid]];
		}
		[self writeDB:target key:[_table stringByAppendingFormat:@"%@",resultKey]];
	}
	
	//删除tmp file文件
	deleteFile(file);
	postLoadData();
	
	return ;
	
}
/*
 *快捷使用 标记着等级的复合查找
 */
-(void)parse:(NSString*)_table
{
	[self process_condition:_table key:@"level"];
}
/*
 *复合类型 解析
 *_table 表名
 *_handle 条件
 */

-(NSDictionary*)process_common:(NSString*)_table key:(NSString*)_handle{
	
	NSString * file = getLibraryCachePathByName(_table);
	NSData * data = [[NSFileManager defaultManager] contentsAtPath:file];
	data = [self getDecryptData:data];
	
	CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];
	NSError *error = nil;
	NSArray *array = [deserializer deserializeAsArray:data error:&error];
	if (error) {
		CCLOG(@"getInfo faild! erro:%@",[error description]);
		return nil;
	}
	NSMutableDictionary *target = [NSMutableDictionary dictionary];
	for (NSDictionary *_dict in array) {
		int _id = [[_dict objectForKey:_handle] intValue ];
		[target setObject:_dict forKey:[NSString stringWithFormat:@"%d",_id]];
	}
	[self writeDB:target key:_table];
	
	//删除tmp file文件
	deleteFile(file);
	postLoadData();
	
	return target;
}

/*
 -(NSDictionary*)process_common:(NSString*)file_path table:(NSString*)_table key:(NSString*)_handle
 {
 if (!file_path || !_table || !_handle) {
 CCLOG(@"process_common parameter is null = %@",_table);
 return nil;
 }
 NSString *path = [NSString stringWithFormat:@"%@/%@",file_path,_table];
 path = [[NSBundle mainBundle] pathForResource:path ofType:@""];
 
 NSData * data = [[NSFileManager defaultManager] contentsAtPath:path];
 
 
 
 CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];
 NSError *error = nil;
 NSArray *array = [deserializer deserializeAsArray:data error:&error];
 if (error) {
 CCLOG(@"getInfo faild! erro:%@",[error description]);
 return nil;
 }
 NSMutableDictionary *target = [NSMutableDictionary dictionary];
 for (NSDictionary *_dict in array) {
 //---
 int _id = [[_dict objectForKey:_handle] intValue ];
 [target setObject:_dict forKey:[NSString stringWithFormat:@"%d",_id]];
 }
 [self writeDB:target key:_table];
 
 
 
 return target;
 }
 */

/*
 *注意
 *默认是操作ID，
 */
-(NSDictionary*)getInfo:(NSString*)_table{
	NSDictionary *dict = [self readDB:_table];
	if (!dict) {
		dict = [self process_common:_table key:@"id"];
	}
	return dict;
}
-(NSDictionary*)getInfo:(NSString*)_table :(int)_id
{
	NSDictionary *dict = [self readDB:_table];
	if (!dict) {
		dict = [self process_common:_table key:@"id"];
	}
	NSString *_key = [NSString stringWithFormat:@"%d",_id];
	return [dict objectForKey:_key];
}
#pragma mark -
#pragma mark get data
-(NSDictionary*)getRoleInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_ROLE :_id];
	
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary * userRole = [NSMutableDictionary dictionary];
		
		[userRole setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		
		[userRole setObject:@"name" forKey:@"name"];
		[userRole setObject:@"info" forKey:@"info"];
		[userRole setObject:@"act1" forKey:@"act"];
		
		[userRole setObject:@"job1" forKey:@"job"];
		[userRole setObject:@"office1" forKey:@"office"]; //位阶
		
		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"sex"];
		[userRole setObject:[NSNumber numberWithInt:_id] forKey:@"armId"];
		
		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"quality"];
		
		[userRole setObject:[NSNumber numberWithInt:3] forKey:@"sk1"];//普通攻击
		[userRole setObject:[NSNumber numberWithInt:4] forKey:@"sk2"];//绝杀攻击
		
		[userRole setObject:[NSNumber numberWithInt:_id] forKey:@"index"];
		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"disLV"];
		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"invLV"];
		[userRole setObject:@"" forKey:@"invs"];
		[userRole setObject:[NSNumber numberWithInt:1] forKey:@"useId"];
		[userRole setObject:[NSNumber numberWithInt:5] forKey:@"useNum"];
		
		if (_id == 7) {
			[userRole setObject:[NSNumber numberWithInt:7] forKey:@"index"];
			[userRole setObject:@"tid:1|rid:4|rid:5|max:10|vip:5" forKey:@"invs"];
		}
		else if (_id == 9) {
			[userRole setObject:[NSNumber numberWithInt:30] forKey:@"invLV"];
		}
		else if (_id == 14) {
			[userRole setObject:@"tid:1|rid:4|max:30|vip:20" forKey:@"invs"];
		}
		
		return userRole;
	}
#endif
	return dict;
}

-(NSDictionary*)getRoleList{
	NSDictionary * dict = [self readDB:CONFIG_ROLE];
	return dict;
}

-(NSDictionary*)getRoleInfosByIds:(NSArray*)ids{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	NSDictionary * dict = [self readDB:CONFIG_ROLE];
	if(dict){
		for(id _id in ids){
			NSString * _key = [NSString stringWithFormat:@"%d",[_id intValue]];
			//[result addObject:[dict objectForKey:_key]];
			[result setObject:[dict objectForKey:_key] forKey:_key];
		}
	}
	return result;
}

-(NSDictionary*)getRoleByIndex:(int)_index
{
	NSDictionary *dict = [self readDB:CONFIG_ROLE];
	for (NSString *key in [dict allKeys]) {
		NSDictionary *temp = [dict objectForKey:key];
		if ([[temp objectForKey:@"index"] intValue] == _index) {
			return temp;
		}
	}
	return nil;
}
-(NSDictionary*)getArmInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_ARM :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		
		NSMutableDictionary *armInfo = [NSMutableDictionary dictionary];
		[armInfo setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[armInfo setObject:@"name" forKey:@"name"];
		[armInfo setObject:@"info" forKey:@"info"];
		[armInfo setObject:@"act" forKey:@"act"];
		//test
		[armInfo setObject:[NSNumber numberWithInt:_id*2+1] forKey:@"sk1"];
		[armInfo setObject:[NSNumber numberWithInt:_id*2+2] forKey:@"sk2"];
		
		return armInfo;
	}
#endif
	return dict;
}

-(NSDictionary*)getArmInfoByIds:(NSArray *)ids{
	
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	NSDictionary * dict = [self readDB:CONFIG_ARM];
	if(dict){
		for(id _id in ids){
			NSString * _key = [NSString stringWithFormat:@"%d",[_id intValue]];
			[result setObject:[dict objectForKey:_key] forKey:_key];
		}
	}
	return result;
}

-(NSDictionary*)getCarInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_CAR :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *carInfo = [NSMutableDictionary dictionary];
		[carInfo setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[carInfo setObject:@"name" forKey:@"name"];
		[carInfo setObject:@"info" forKey:@"info"];
		[carInfo setObject:@"act" forKey:@"act"];
		[carInfo setObject:[NSNumber numberWithInt:1] forKey:@"quality"];
		[carInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"speed"];
		[carInfo setObject:[NSNumber numberWithInt:1] forKey:@"useId"];
		[carInfo setObject:[NSNumber numberWithInt:1] forKey:@"count"];
		[carInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint1"];
		[carInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint2"];
		[carInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint3"];
		return carInfo;
	}
#endif
	return dict ;
}
-(NSDictionary*)getEquipmentInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_EQUIP :_id] ;
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *equipInfo = [NSMutableDictionary dictionary];
		[equipInfo setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[equipInfo setObject:@"name" forKey:@"name"];
		[equipInfo setObject:@"info" forKey:@"info"];
		[equipInfo setObject:@"act" forKey:@"act"];
		
		[equipInfo setObject:[NSNumber numberWithInt:_id] forKey:@"sid"];
		int part = _id%6;
		part += 1;
		[equipInfo setObject:[NSNumber numberWithInt:part] forKey:@"part"];
		[equipInfo setObject:[NSNumber numberWithInt:1] forKey:@"limit"];
		[equipInfo setObject:[NSNumber numberWithInt:1] forKey:@"price"];
		
		//add
		[equipInfo setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
		[equipInfo setObject:[NSNumber numberWithInt:30] forKey:@"DEX"];
		[equipInfo setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
		[equipInfo setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
		
		[equipInfo setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
		[equipInfo setObject:[NSNumber numberWithInt:1000] forKey:@"MP"];
		[equipInfo setObject:[NSNumber numberWithInt:60] forKey:@"ATK"];
		[equipInfo setObject:[NSNumber numberWithInt:60] forKey:@"STK"];
		
		[equipInfo setObject:[NSNumber numberWithInt:10] forKey:@"DEF"];
		[equipInfo setObject:[NSNumber numberWithInt:5] forKey:@"SPD"];
		
		[equipInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPS"];
		[equipInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPR"];
		
		[equipInfo setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
		[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
		[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
		[equipInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
		[equipInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
		[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
		[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
		[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
		[equipInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
		
		return equipInfo;
	}
#endif
	return dict;
}

-(NSDictionary*)getEquipmentInfoByIds:(NSArray*)ids{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	NSDictionary * dict = [self readDB:CONFIG_EQUIP];
	if(dict){
		for(id _id in ids){
			NSString * _key = [NSString stringWithFormat:@"%d",[_id intValue]];
			//[result addObject:[dict objectForKey:_key]];
			[result setObject:[dict objectForKey:_key] forKey:_key];
		}
	}
	return result;
}

-(NSDictionary*)getEquipmentSetInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_EQUIP_SET :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *equipSetInfo = [NSMutableDictionary dictionary];
		[equipSetInfo setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[equipSetInfo setObject:@"name" forKey:@"name"];
		[equipSetInfo setObject:@"info" forKey:@"info"];
		[equipSetInfo setObject:@"effect2" forKey:@"effect2"];
		[equipSetInfo setObject:@"effect4" forKey:@"effect4"];
		[equipSetInfo setObject:@"effect6" forKey:@"effect6"];
		
		[equipSetInfo setObject:[NSNumber numberWithInt:1] forKey:@"quality"];
		[equipSetInfo setObject:[NSNumber numberWithInt:_id*2] forKey:@"lv"];//装备本身等级
		return equipSetInfo;
	}
#endif
	return dict;
}

-(NSDictionary*)getEquipmentSetInfoByIds:(NSArray*)ids{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	NSDictionary * dict = [self readDB:CONFIG_EQUIP_SET];
	if(dict){
		for(id _id in ids){
			NSString * _key = [NSString stringWithFormat:@"%d",[_id intValue]];
			//[result addObject:[dict objectForKey:_key]];
			[result setObject:[dict objectForKey:_key] forKey:_key];
		}
	}
	return result;
}

-(NSDictionary*)getFateInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_FATE :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *fateInfo = [NSMutableDictionary dictionary];
		[fateInfo setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[fateInfo setObject:@"name" forKey:@"name"];
		[fateInfo setObject:@"info" forKey:@"info"];
		[fateInfo setObject:@"act" forKey:@"act"];
		[fateInfo setObject:[NSNumber numberWithInt:1] forKey:@"quality"];
		[fateInfo setObject:[NSNumber numberWithInt:0] forKey:@"beginExp"];
		[fateInfo setObject:[NSNumber numberWithFloat:50.0f] forKey:@"rate"];
		[fateInfo setObject:[NSNumber numberWithInt:1] forKey:@"price"];
		
		return fateInfo;
	}
#endif
	return dict;
}

-(NSDictionary*)getFateInfoByIds:(NSArray*)ids{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	NSDictionary * dict = [self readDB:CONFIG_FATE];
	if(dict){
		for(id _id in ids){
			NSString * _key = [NSString stringWithFormat:@"%d",[_id intValue]];
			//[result addObject:[dict objectForKey:_key]];
			[result setObject:[dict objectForKey:_key] forKey:_key];
		}
	}
	return result;
}

-(NSDictionary*)getFateRateInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_FATE_RATE :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *fateRateInfo = [NSMutableDictionary dictionary];
		[fateRateInfo setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[fateRateInfo setObject:@"1" forKey:@"type"];
		[fateRateInfo setObject:@"1" forKey:@"mid"];
		[fateRateInfo setObject:[NSNumber numberWithFloat:50.0f] forKey:@"rate"];
		[fateRateInfo setObject:[NSNumber numberWithInt:1] forKey:@"rid"];
		
		return fateRateInfo;
	}
#endif
	return dict ;
}
-(NSDictionary*)getFateCostInfo:(int)_id
{
	//TODO 缺少表
	NSDictionary *dict = [self getInfo:CONFIG_FATE_COST :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *_info = [NSMutableDictionary dictionary];
		[_info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[_info setObject:[NSNumber numberWithInt:2] forKey:@"num"];
		[_info setObject:[NSNumber numberWithInt:20] forKey:@"coin1"];
		[_info setObject:[NSNumber numberWithInt:30] forKey:@"coin2"];
		[_info setObject:[NSNumber numberWithInt:40] forKey:@"coin3"];
		return _info;
	}
#endif
	return dict;
}
-(NSDictionary*)getItemInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_ITEM :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *itemInfo = [NSMutableDictionary dictionary];
		[itemInfo setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[itemInfo setObject:@"name" forKey:@"name"];
		[itemInfo setObject:@"info" forKey:@"info"];
		[itemInfo setObject:@"act" forKey:@"act"];
		[itemInfo setObject:[NSNumber numberWithInt:1] forKey:@"quality"];
		
		[itemInfo setObject:[NSNumber numberWithInt:Item_material] forKey:@"type"];
		
		[itemInfo setObject:[NSNumber numberWithInt:1] forKey:@"price"];
		[itemInfo setObject:[NSNumber numberWithInt:99] forKey:@"stack"];
		
		[itemInfo setObject:[NSNumber numberWithInt:2] forKey:@"rid"];
		
		return itemInfo;
	}
#endif
	return dict ;
}
-(NSDictionary*)getItemInfoByIds:(NSArray*)ids{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	NSDictionary * dict = [self readDB:CONFIG_ITEM];
	if(dict){
		for(id _id in ids){
			NSString * _key = [NSString stringWithFormat:@"%d",[_id intValue]];
			//[result addObject:[dict objectForKey:_key]];
			[result setObject:[dict objectForKey:_key] forKey:_key];
		}
	}
	return result;
}

-(NSDictionary*)getMonsterInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_MONSTER :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary * info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		
		[info setObject:[NSNumber numberWithInt:MONSTER_TYPE_MONSTER] forKey:@"type"];
		
		if(_id==3){
			[info setObject:[NSNumber numberWithInt:MONSTER_TYPE_BOSS] forKey:@"type"];
		}
		
		[info setObject:@"monster" forKey:@"name"];
		[info setObject:@"monster info" forKey:@"info"];
		[info setObject:@"monster_1" forKey:@"act"];
		
		[info setObject:[NSNumber numberWithInt:2] forKey:@"sex"];
		
		//TODO skill ???
		[info setObject:[NSNumber numberWithInt:1] forKey:@"sk1"];
		[info setObject:[NSNumber numberWithInt:2] forKey:@"sk2"];
		
		return info;
	}
#endif
	return dict;
}
//
-(NSDictionary*)getMonsterLevelInfo:(int)_mid
{
	NSDictionary *dict = [self readDB:CONFIG_MONSTER_LEVEL];
	if (!dict) {
		dict = [self process_common:CONFIG_MONSTER_LEVEL key:@"mid"];//怪物等级表 mid
	}
	NSString *_key = [NSString stringWithFormat:@"%d",_mid];
	NSDictionary *monster = [dict objectForKey:_key];
	return monster;
}
-(NSDictionary*)getMonsterLevelInfo:(int)_mid level:(int)_level
{
	
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_MONSTER_LEVEL,_mid];
	NSDictionary *table = [self readDB:path];
	NSDictionary *dict = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
#ifdef GAMEDB_DEBUG
	if (!dict){
		
		NSMutableDictionary * info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_mid] forKey:@"id"];
		[info setObject:[NSNumber numberWithInt:_mid] forKey:@"mid"];
		[info setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
		
		[info setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
		[info setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
		[info setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
		[info setObject:[NSNumber numberWithInt:100] forKey:@"DEX"];
		
		[info setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
		[info setObject:[NSNumber numberWithInt:100] forKey:@"MP"];
		[info setObject:[NSNumber numberWithInt:100] forKey:@"ATK"];
		[info setObject:[NSNumber numberWithInt:100] forKey:@"STK"];
		
		[info setObject:[NSNumber numberWithInt:10] forKey:@"DEF"];
		[info setObject:[NSNumber numberWithInt:10] forKey:@"SPD"];
		
		[info setObject:[NSNumber numberWithInt:50] forKey:@"MPS"];
		[info setObject:[NSNumber numberWithInt:10] forKey:@"MPT"];    // @"MPR" ?
		
		[info setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
		[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
		[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
		[info setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
		[info setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
		[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
		[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
		[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
		[info setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
		
		return info;
	}
#endif
	return dict;
}
//
-(NSDictionary*)getNpcInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_NPC :_id];
	//
	//#ifdef GAMEDB_DEBUG
	//	if (!dict || YES) {
	//		NSMutableDictionary * info = [NSMutableDictionary dictionary];
	//		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
	//		[info setObject:[NSString stringWithFormat:@"npc_%d",_id] forKey:@"name"];
	//
	//		//TODO test
	//		[info setObject:@"fuck!|fuck 2!|fuck 3!" forKey:@"msg"];
	//		[info setObject:@"" forKey:@"func"];
	//		[info setObject:[NSNumber numberWithBool:YES] forKey:@"isShowName"];
	//
	//		if(_id==1){
	//			[info setObject:@"1:2" forKey:@"func"];//NPC_FUNC_MAP to map id : 2
	//		}
	//		if(_id==2){
	//			[info setObject:@"3:1" forKey:@"func"];//NPC_FUNC_STAGE to stage id : 1
	//			[info setObject:[NSNumber numberWithBool:NO] forKey:@"isShowName"];
	//		}
	//		if(_id==3){
	//			[info setObject:@"4:2" forKey:@"func"];//NPC_FUNC_FIGHT to fight id : 2
	//		}
	//		return info;
	//	}
	//#endif
	return dict ;
}
-(NSDictionary*)getRewardInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_REWARD :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *rewardInfo = [NSMutableDictionary dictionary];
		[rewardInfo setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[rewardInfo setObject:@"name" forKey:@"name"];
		[rewardInfo setObject:@"info" forKey:@"info"];
		[rewardInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint1"];
		[rewardInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint2"];
		[rewardInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint3"];
		[rewardInfo setObject:[NSNumber numberWithInt:1] forKey:@"exp"];
		[rewardInfo setObject:[NSNumber numberWithInt:1] forKey:@"train"];
		[rewardInfo setObject:@"item" forKey:@"item"];
		[rewardInfo setObject:@"equip" forKey:@"equip"];
		[rewardInfo setObject:@"fate" forKey:@"fate"];
		[rewardInfo setObject:@"reward" forKey:@"reward"];
		
		return rewardInfo;
	}
#endif
	return dict ;
}

-(NSDictionary*)getSkillInfoByIds:(NSArray *)ids{
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	NSDictionary * dict = [self readDB:CONFIG_SKILL];
	if(dict){
		for(id _id in ids){
			NSString * _key = [NSString stringWithFormat:@"%d",[_id intValue]];
			[result setObject:[dict objectForKey:_key] forKey:_key];
		}
	}
	return result;
}

-(NSDictionary*)getJewelShopInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_gem_shop :_id];
	if (dict == nil) {
		CCLOG(@"getJewelShopInfo->dict is nil");
	}
	return dict;
}

-(NSDictionary*)getJewelInfo:(int)_id{
	NSDictionary *dict = [self getInfo:CONFIG_gem :_id];
	if (dict == nil) {
		CCLOG(@"getJewelInfo->dict is nil");
	}
	return dict;
}

-(NSDictionary*)getJewelInfoByIds:(NSArray *)ids{
	CCLOG(@"getJewelInfoByIds");
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	NSDictionary * dict = [self readDB:CONFIG_gem];
	if(dict){
		for(id _id in ids){
			NSString * _key = [NSString stringWithFormat:@"%d",[_id intValue]];
			[result setObject:[dict objectForKey:_key] forKey:_key];
		}
	}
	return result;
}

-(NSDictionary*)getSkillInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_SKILL :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary * info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		
		[info setObject:@"skill" forKey:@"name"];
		[info setObject:@"skill" forKey:@"info"];
		[info setObject:@"skill" forKey:@"act"];
		
		[info setObject:[NSNumber numberWithInt:Attack_mode_target_single] forKey:@"range"];
		[info setObject:[NSNumber numberWithInt:100] forKey:@"rHurt1"];
		[info setObject:[NSNumber numberWithInt:80] forKey:@"rHurt2"];
		[info setObject:[NSNumber numberWithInt:0] forKey:@"far"];
		
		if(_id==1){
			[info setObject:[NSNumber numberWithInt:Attack_mode_target_single] forKey:@"range"];
		}
		if(_id==2){
			[info setObject:[NSNumber numberWithInt:Attack_mode_target_upright] forKey:@"range"];
		}
		
		if(_id==3){
			[info setObject:[NSNumber numberWithInt:Attack_mode_target_single] forKey:@"range"];
		}
		if(_id==4){
			[info setObject:[NSNumber numberWithInt:Attack_mode_target_upright] forKey:@"range"];
		}
		
		return info;
	}
#endif
	return dict;
}
-(NSDictionary*)getSkillStateInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_SKILL_STATE :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary * skillStatus = nil;
		
		skillStatus = [NSMutableDictionary dictionary];
		[skillStatus setObject:[NSNumber numberWithInt:1] forKey:@"id"];
		[skillStatus setObject:[NSNumber numberWithInt:_id] forKey:@"skid"];
		[skillStatus setObject:[NSNumber numberWithInt:1] forKey:@"stid"];
		return skillStatus;
	}
#endif
	return dict;
}

-(NSDictionary*)getPositionList{
	NSDictionary *dict = [self readDB:CONFIG_POSITION];
	return dict;
}
-(NSDictionary*)getPositionInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_POSITION :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *positionInfo = [NSMutableDictionary dictionary];
		[positionInfo setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[positionInfo setObject:@"name" forKey:@"name"];
		[positionInfo setObject:@"info" forKey:@"info"];
		[positionInfo setObject:@"act" forKey:@"act"];
		[positionInfo setObject:[NSNumber numberWithInt:2] forKey:@"eye"];
		return positionInfo;
	}
#endif
	return dict;
}
-(NSDictionary*)getBFTaskInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_BF_TASK :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[info setObject:[NSNumber numberWithInt:1] forKey:@"type"];
		[info setObject:[NSNumber numberWithInt:20] forKey:@"bid"];
		[info setObject:[NSNumber numberWithInt:2] forKey:@"rid"];
		[info setObject:[NSNumber numberWithInt:2] forKey:@"tid"];
		return info;
	}
#endif
	return dict;
}
-(NSDictionary*)getBFTaskInfo:(int)_tid q:(int)_q
{
	NSDictionary *dict = [self readDB:CONFIG_BF_TASK];
	if (dict) {
		NSArray *keys = [dict allKeys];
		for (int i = 0; i < keys.count; i++) {
			NSDictionary *bfTask = [dict objectForKey:[keys objectAtIndex:i]];
			int tid = [[bfTask objectForKey:@"tid"] intValue];
			int q = [[bfTask objectForKey:@"quality"] intValue];
			if (tid == _tid && q == _q) {
				return bfTask;
			}
		}
	}
	return dict;
}
-(NSDictionary*)getStateInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_STATE :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary * info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[info setObject:@"fight" forKey:@"name"];
		[info setObject:@"" forKey:@"info"];
		
		//1:普通加成 2:中毒 3:队友或自己HP 4:直加HP(盾牌作用)
		[info setObject:[NSNumber numberWithInt:Fight_Status_Type_general] forKey:@"type"];
		
		[info setObject:[NSNumber numberWithInt:100] forKey:@"rate"];
		
		//1=敌方目标; 2=自己; 3自己全体;  (4-5要搜索sort与num)
		[info setObject:[NSNumber numberWithInt:2] forKey:@"target"];
		
		//target==3时起作用
		[info setObject:[NSNumber numberWithInt:3] forKey:@"num"];
		
		//1:攻击时 2:受伤时 3:回合结束时
		[info setObject:[NSNumber numberWithInt:Fight_Action_Type_attack] forKey:@"action"];
		//作用的次数
		[info setObject:[NSNumber numberWithInt:2] forKey:@"count"];
		
		//--------------------------------------------------------------------------
		
		[info setObject:[NSNumber numberWithInt:100] forKey:@"ahp"];
		[info setObject:[NSNumber numberWithInt:80] forKey:@"bhp"];
		
		[info setObject:[NSNumber numberWithBool:NO] forKey:@"noatk"];
		[info setObject:[NSNumber numberWithBool:NO] forKey:@"nomis"];
		[info setObject:[NSNumber numberWithBool:NO] forKey:@"nobok"];
		[info setObject:[NSNumber numberWithBool:NO] forKey:@"nocot"];
		
		/*
		 //数值加成 -> HIT:100|CRI:100
		 [info setObject:@"HIT:100|CRI:100" forKey:@"value_r"];
		 //数值成分比加成 -> HIT:100|CRI:100
		 [info setObject:@"HIT:50|CRI:30|DEX:100" forKey:@"value_p"];
		 */
		
		[info setObject:@"HIT_P:50|CRI_P:30|DEX_P:100|HIT:100|CRI:100" forKey:@"value"];
		
		//添加实数
		[info setObject:[NSNumber numberWithInt:100] forKey:@"mp"];
		[info setObject:[NSNumber numberWithInt:1000] forKey:@"hp"];
		
		//添加百分比
		[info setObject:[NSNumber numberWithInt:50] forKey:@"mp_p"];
		[info setObject:[NSNumber numberWithInt:50] forKey:@"hp_p"];
		
		return info;
	}
#endif
	return dict ;
}
-(NSDictionary*)getMapInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_MAP :_id];
	
#ifdef GAMEDB_DEBUG
	/*
	 if (!dict || YES) {
	 if(_id==1){
	 NSMutableDictionary * info = [NSMutableDictionary dictionary];
	 [info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
	 [info setObject:[NSNumber numberWithInt:1] forKey:@"type"];
	 [info setObject:[NSNumber numberWithInt:0] forKey:@"pmid"];
	 [info setObject:@"test map" forKey:@"name"];
	 [info setObject:@"test map" forKey:@"info"];
	 [info setObject:@"start.tmx" forKey:@"tiledFile"];
	 [info setObject:[NSNumber numberWithBool:YES] forKey:@"multi"];
	 return info;
	 }
	 if(_id==2){
	 NSMutableDictionary * info = [NSMutableDictionary dictionary];
	 [info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
	 [info setObject:[NSNumber numberWithInt:2] forKey:@"type"];
	 [info setObject:[NSNumber numberWithInt:1] forKey:@"pmid"];
	 [info setObject:@"test map" forKey:@"name"];
	 [info setObject:@"test map" forKey:@"info"];
	 [info setObject:@"stage1.tmx" forKey:@"tiledFile"];
	 [info setObject:[NSNumber numberWithBool:NO] forKey:@"multi"];
	 return info;
	 }
	 if(_id==3){
	 NSMutableDictionary * info = [NSMutableDictionary dictionary];
	 [info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
	 [info setObject:[NSNumber numberWithInt:2] forKey:@"type"];
	 [info setObject:[NSNumber numberWithInt:1] forKey:@"pmid"];
	 [info setObject:@"test map" forKey:@"name"];
	 [info setObject:@"test map" forKey:@"info"];
	 [info setObject:@"stage1.tmx" forKey:@"tiledFile"];
	 [info setObject:[NSNumber numberWithBool:NO] forKey:@"multi"];
	 return info;
	 }
	 
	 NSMutableDictionary * info = [NSMutableDictionary dictionary];
	 [info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
	 [info setObject:[NSNumber numberWithInt:1] forKey:@"type"];
	 [info setObject:@"test map" forKey:@"name"];
	 [info setObject:@"test map" forKey:@"info"];
	 [info setObject:@"start.tmx" forKey:@"tiledFile"];
	 [info setObject:[NSNumber numberWithBool:YES] forKey:@"multi"];
	 
	 return info;
	 }
	 */
#endif
	return dict ;
}
-(NSDictionary*)getStageInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_STAGE :_id];
	return dict ;
}
-(NSDictionary*)getChapterInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_CHAPTER :_id];
	//#ifdef GAMEDB_DEBUG
	//	if (!dict) {
	//		NSMutableDictionary * info = [NSMutableDictionary dictionary];
	//		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
	//		[info setObject:[NSString stringWithFormat:@"Chapter%d",_id] forKey:@"name"];
	//		[info setObject:[NSNumber numberWithInt:0] forKey:@"start"];//是否初章
	//		[info setObject:[NSNumber numberWithInt:1] forKey:@"startTid"];//开始该章任务ID
	//		[info setObject:[NSNumber numberWithInt:2] forKey:@"endTid"];//完成该章任务ID
	//		return info;
	//	}
	//#endif
	return dict ;
}
-(NSDictionary*)getIronRateInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_IRON_RATE :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary * info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[info setObject:[NSNumber numberWithInt:1] forKey:@"type"];//类型 1=普通 2=高级
		[info setObject:[NSNumber numberWithInt:1] forKey:@"level1"];//起始等级
		[info setObject:[NSNumber numberWithInt:2] forKey:@"level2"];//终止等级
		[info setObject:[NSNumber numberWithInt:2] forKey:@"rid"];//奖励
		[info setObject:[NSNumber numberWithInt:2] forKey:@"coin1"];
		[info setObject:[NSNumber numberWithInt:2] forKey:@"coin2"];
		[info setObject:[NSNumber numberWithInt:2] forKey:@"coin3"];
		return info;
	}
#endif
	return dict ;
}
-(NSDictionary*)getFeteRateInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_FETE_RATE :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary * info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[info setObject:@"" forKey:@"info"];//说明
		[info setObject:@"" forKey:@"act"];//动画
		[info setObject:[NSNumber numberWithInt:1] forKey:@"type"];//类型 1免费 2 元宝
		[info setObject:[NSNumber numberWithInt:2] forKey:@"rate"];//概率
		[info setObject:[NSNumber numberWithInt:2] forKey:@"rid"];
		return info;
	}
#endif
	return dict ;
}
-(NSDictionary*)getFightInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_FIGHT :_id];
	
	//#ifdef GAMEDB_DEBUG
	//	//???
	//	if (!dict || YES) {
	//		NSMutableDictionary * info = [NSMutableDictionary dictionary];
	//		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
	//		[info setObject:@"fight" forKey:@"name"];
	//
	//		[info setObject:@"fstage03" forKey:@"BG"];
	//
	//		//TODO 怪物站位与数据->1:1 (怪物ID:怪物Level)
	//		[info setObject:@"1:0" forKey:@"s1"];
	//		[info setObject:@"1:1" forKey:@"s2"];
	//		[info setObject:@"1:0" forKey:@"s3"];
	//
	//		[info setObject:@"0:0" forKey:@"s4"];
	//		[info setObject:@"0:0" forKey:@"s5"];
	//		[info setObject:@"0:0" forKey:@"s6"];
	//
	//		[info setObject:@"0:0" forKey:@"s7"];
	//		[info setObject:@"0:0" forKey:@"s8"];
	//		[info setObject:@"0:0" forKey:@"s9"];
	//
	//		[info setObject:@"0:0" forKey:@"s10"];
	//		[info setObject:@"0:0" forKey:@"s11"];
	//		[info setObject:@"0:0" forKey:@"s12"];
	//
	//		[info setObject:@"0:0" forKey:@"s13"];
	//		[info setObject:@"0:0" forKey:@"s14"];
	//		[info setObject:@"0:0" forKey:@"s15"];
	//
	//		return info;
	//	}
	//#endif
	
	return dict ;
}
-(NSDictionary*)getTimeBoxInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_TIME_BOX :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[info setObject:[NSNumber numberWithInt:1] forKey:@"mid"];
		[info setObject:[NSNumber numberWithInt:2] forKey:@"chapter"];
		[info setObject:[NSNumber numberWithInt:1] forKey:@"rid"];
		[info setObject:[NSNumber numberWithInt:1] forKey:@"place"];
		return info;
	}
#endif
	return dict ;
}
-(NSDictionary*)getDeepBoxInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_DEEP_BOX :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[info setObject:[NSNumber numberWithInt:1] forKey:@"fr1"];
		[info setObject:[NSNumber numberWithInt:2] forKey:@"fr2"];
		[info setObject:@"45:51" forKey:@"rd"];
		return info;
	}
#endif
	return dict ;
}
-(NSDictionary*)getDeepPositionInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_DEEP_POSITION :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[info setObject:[NSNumber numberWithInt:1] forKey:@"lv1"];
		[info setObject:[NSNumber numberWithInt:2] forKey:@"lv2"];
		[info setObject:@"1:25|2:25|3:25|4:25" forKey:@"pos"];
		return info;
	}
#endif
	return dict ;
}
-(NSDictionary*)getDeepGuardInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_DEEP_GUARD :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[info setObject:[NSNumber numberWithInt:1] forKey:@"lv1"];
		[info setObject:[NSNumber numberWithInt:2] forKey:@"lv2"];
		[info setObject:@"21:100|23:100|24:100|25:100|26:100" forKey:@"guard"];
		[info setObject:@"HP:10|ATK:10" forKey:@"up"];
		return info;
	}
#endif
	return dict ;
}
-(NSArray*)getFootBuffs{
	NSMutableArray * result = [NSMutableArray array];
	NSDictionary * dict = [self readDB:CONFIG_BUFF];
	for(NSString * key in dict){
		[result addObject:[dict objectForKey:key]];
	}
	return result;
}
-(NSDictionary*)getFootBuffInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_BUFF :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[info setObject:@"buff1" forKey:@"name"];
		[info setObject:@"will die" forKey:@"info"];
		[info setObject:@"" forKey:@"act"];
		[info setObject:[NSNumber numberWithInt:1] forKey:@"type"];
		[info setObject:[NSNumber numberWithInt:1] forKey:@"stype"];
		[info setObject:@"ATK|HP|CRI" forKey:@"buff"];
		[info setObject:@"3|3|3" forKey:@"plan1"];
		[info setObject:@"2|3|4" forKey:@"plan2"];
		[info setObject:[NSNumber numberWithInt:10] forKey:@"coin2"];
		[info setObject:[NSNumber numberWithInt:25] forKey:@"coin3"];
		return info;
	}
#endif
	return dict ;
}

-(NSDictionary*)getAllyLevel:(int)_id{
	NSDictionary *dict = [self getInfo:CONFIG_ALLY_LEVEL :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		return info;
	}
#endif
	return dict ;
}
-(NSDictionary*)getAllyRight:(int)_id{
	NSDictionary *dict = [self getInfo:CONFIG_ALLY_RIGHT :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		return info;
	}
#endif
	return dict ;
}
-(NSDictionary*)getAllyGrave:(int)_id{
    NSDictionary *dict = [self getInfo:CONFIG_ALLY_GRAVE :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		return info;
	}
#endif
	return dict ;
}
-(NSDictionary*)getFusionInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_FUSION :_id];
#ifdef GAMEDB_DEBUG
	if (!dict) {
		NSMutableDictionary *fusionInfo = [NSMutableDictionary dictionary];
		[fusionInfo setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
		[fusionInfo setObject:@"name" forKey:@"name"];
		[fusionInfo setObject:@"info" forKey:@"info"];
		[fusionInfo setObject:[NSNumber numberWithInt:2] forKey:@"desId"];
		[fusionInfo setObject:[NSNumber numberWithInt:1] forKey:@"srcId"];
		[fusionInfo setObject:[NSNumber numberWithInt:1] forKey:@"count"];
		[fusionInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint1"];
		[fusionInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint2"];
		[fusionInfo setObject:[NSNumber numberWithInt:1] forKey:@"coint3"];
		
		return fusionInfo;
	}
#endif
	return dict ;
}
-(NSDictionary*)getRoleLevelInfo:(int)_rid level:(int)_level
{
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_ROLE_LEVELE,_rid];
	NSDictionary *table = [self readDB:path];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
#ifdef GAMEDB_DEBUG
	if (!_info) {
		NSMutableDictionary *roleLevelInfo = [NSMutableDictionary dictionary];
		[roleLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
		[roleLevelInfo setObject:[NSNumber numberWithInt:_rid] forKey:@"rid"];
		[roleLevelInfo setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
		
		[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
		[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"DEX"];
		[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
		[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
		
		[roleLevelInfo setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
		[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"MP"];
		[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"ATK"];
		[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"STK"];
		
		[roleLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"DEF"];
		[roleLevelInfo setObject:[NSNumber numberWithInt:50] forKey:@"SPD"];
		
		[roleLevelInfo setObject:[NSNumber numberWithInt:50] forKey:@"MPS"];
		[roleLevelInfo setObject:[NSNumber numberWithInt:10] forKey:@"MPR"];
		
		[roleLevelInfo setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
		[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
		[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
		[roleLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
		[roleLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
		[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
		[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
		[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
		[roleLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
		
		return roleLevelInfo;
	}
#endif
	return _info;
}
-(NSDictionary*)getArmLevelInfo:(int)_aid level:(int)_level
{
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_ARM_LEVEL,_aid];
	NSDictionary *table = [self readDB:path];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
#ifdef GAMEDB_DEBUG_
	if (!_info) {
		NSMutableDictionary *armInfo = [NSMutableDictionary dictionary];
		[armInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
		[armInfo setObject:[NSNumber numberWithInt:_aid] forKey:@"aid"];
		[armInfo setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
		
		[armInfo setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
		[armInfo setObject:[NSNumber numberWithInt:30] forKey:@"DEX"];
		[armInfo setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
		[armInfo setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
		
		[armInfo setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
		[armInfo setObject:[NSNumber numberWithInt:1000] forKey:@"MP"];
		[armInfo setObject:[NSNumber numberWithInt:60] forKey:@"ATK"];
		[armInfo setObject:[NSNumber numberWithInt:60] forKey:@"STK"];
		
		[armInfo setObject:[NSNumber numberWithInt:10] forKey:@"DEF"];
		[armInfo setObject:[NSNumber numberWithInt:5] forKey:@"SPD"];
		
		[armInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPS"];
		[armInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPR"];
		
		[armInfo setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
		[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
		[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
		[armInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
		[armInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
		[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
		[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
		[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
		[armInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
		
		return armInfo;
	}
#endif
	return _info;
}
-(NSDictionary*)getRoleExpInfo:(int)_level
{
	NSDictionary *table = [self readDB:CONFIG_ROLE_EXP];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
#ifdef GAMEDB_DEBUG
	if (!_info) {
		NSMutableDictionary *roleExpInfo = [NSMutableDictionary dictionary];
		[roleExpInfo setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
		[roleExpInfo setObject:[NSNumber numberWithInt:_level*10000] forKey:@"exp"];
		[roleExpInfo setObject:[NSNumber numberWithInt:1] forKey:@"siteExp"];
		return roleExpInfo;
	}
#endif
	return _info;
}

-(NSDictionary*)getArmExpInfo:(int)_level
{
	NSDictionary *table = [self readDB:CONFIG_ARM_EXP];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
#ifdef GAMEDB_DEBUG
	if (!_info) {
		NSMutableDictionary *armExpInfo = [NSMutableDictionary dictionary];
		[armExpInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
		[armExpInfo setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
		[armExpInfo setObject:[NSNumber numberWithInt:_level*1000] forKey:@"exp"];
		
		return armExpInfo;
	}
#endif
	return _info;
}

-(NSDictionary*)getEquipmentLevelInfo:(int)_part level:(int)_level
{
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_EQUIP_LEVEL,_part];
	NSDictionary *table = [self readDB:path];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
#ifdef GAMEDB_DEBUG
	if (!_info) {
		/*
		 NSMutableDictionary *equipLevelInfo = [NSMutableDictionary dictionary];
		 [equipLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
		 [equipLevelInfo setObject:[NSNumber numberWithInt:_part] forKey:@"part"];
		 [equipLevelInfo setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
		 
		 [equipLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
		 [equipLevelInfo setObject:[NSNumber numberWithInt:30] forKey:@"DEX"];
		 [equipLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
		 [equipLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
		 
		 [equipLevelInfo setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
		 [equipLevelInfo setObject:[NSNumber numberWithInt:1000] forKey:@"MP"];
		 [equipLevelInfo setObject:[NSNumber numberWithInt:60] forKey:@"ATK"];
		 [equipLevelInfo setObject:[NSNumber numberWithInt:60] forKey:@"STK"];
		 
		 [equipLevelInfo setObject:[NSNumber numberWithInt:10] forKey:@"DEF"];
		 [equipLevelInfo setObject:[NSNumber numberWithInt:5] forKey:@"SPD"];
		 
		 [equipLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPS"];
		 [equipLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPR"];
		 
		 [equipLevelInfo setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
		 [equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
		 [equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
		 [equipLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
		 [equipLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
		 [equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
		 [equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
		 [equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
		 [equipLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
		 
		 return equipLevelInfo;
		 */
	}
#endif
	return _info;
}
-(NSDictionary*)getEquipmentsStrengInfo:(int)_level
{
	NSDictionary *table = [self readDB:CONFIG_EQUIP_STRENG];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
#ifdef GAMEDB_DEBUG
	if (!_info) {
		/*
		 NSMutableDictionary *strEquipInfo = [NSMutableDictionary dictionary];
		 [strEquipInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
		 [strEquipInfo setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
		 [strEquipInfo setObject:[NSNumber numberWithInt:1] forKey:@"useId"];
		 [strEquipInfo setObject:[NSNumber numberWithInt:1] forKey:@"count"];
		 [strEquipInfo setObject:[NSNumber numberWithInt:1] forKey:@"mvCoin1"];
		 return strEquipInfo;
		 */
	}
#endif
	return _info;
}

-(NSDictionary*)getEquipmentsStrengTable{
	return [self readDB:CONFIG_EQUIP_STRENG];
}

-(NSDictionary*)getEquipmentsMoveInfo:(int)_level
{
	
	NSDictionary *table = [self readDB:CONFIG_EQUIP_MOVE];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
#ifdef GAMEDB_DEBUG
	if(!_info) {
		NSMutableDictionary *strMoveInfo = [NSMutableDictionary dictionary];
		[strMoveInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
		[strMoveInfo setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
		[strMoveInfo setObject:[NSNumber numberWithInt:1] forKey:@"coin1"];
		[strMoveInfo setObject:[NSNumber numberWithInt:1] forKey:@"coin2"];
		[strMoveInfo setObject:[NSNumber numberWithInt:1] forKey:@"coin3"];
		return strMoveInfo;
	}
#endif
	return _info;
}
-(NSDictionary*)getGrouplevelInfo:(int)_level
{
	return nil;
	/*
	 NSDictionary *table = [self readDB:CONFIG_GROUP_LEVEL];
	 NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
	 #ifdef GAMEDB_DEBUG
	 if (!_info) {
	 NSMutableDictionary *groupLevelInfo = [NSMutableDictionary dictionary];
	 [groupLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
	 [groupLevelInfo setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
	 [groupLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"contrib"];
	 
	 return groupLevelInfo;
	 }
	 #endif
	 return _info;
	 */
	
}

-(NSDictionary*)getJewelLevelInfoWithLevels:(int)_gid level:(NSArray *)_level{
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_gem_level,_gid];
	NSDictionary *table = [self readDB:path];
	NSMutableDictionary* _result = [NSMutableDictionary dictionary];
	
	for (NSNumber *_number in _level) {
		int _num = [_number intValue];
		NSString* _key = [NSString stringWithFormat:@"%d",_num];
		NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_num]];
		if (_info) {
            [_result setObject:_info forKey:_key];
        }
	}
	return _result;
}

-(NSDictionary*)getJewelLevelInfoWithLevel:(int)_gid level:(int)_level{
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_gem_level,_gid];
	NSDictionary *table = [self readDB:path];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
	return _info;
}

-(NSDictionary*)getFateLevelInfoWithLevels:(int)_fid level:(NSArray *)_level{
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_FATE_LEVEL,_fid];
	NSDictionary *table = [self readDB:path];
	NSMutableDictionary* _result = [NSMutableDictionary dictionary];
	
	for (NSNumber *_number in _level) {
		int _num = [_number intValue];
		NSString* _key = [NSString stringWithFormat:@"%d",_num];
		NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_num]];
		if (_info) {
            [_result setObject:_info forKey:_key];
        }
		
	}
	
	return _result;
	
}

-(NSDictionary*)getFateLevelInfo:(int)_fid level:(int)_level
{
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_FATE_LEVEL,_fid];
	NSDictionary *table = [self readDB:path];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
#ifdef GAMEDB_DEBUG
	if (!_info) {
		/*
		 NSMutableDictionary *fateLevelInfo = [NSMutableDictionary dictionary];
		 
		 [fateLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
		 [fateLevelInfo setObject:[NSNumber numberWithInt:_fid] forKey:@"fid"];
		 [fateLevelInfo setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
		 [fateLevelInfo setObject:[NSNumber numberWithInt:1] forKey:@"exp"];
		 
		 [fateLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"STR"];
		 [fateLevelInfo setObject:[NSNumber numberWithInt:30] forKey:@"DEX"];
		 [fateLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"VIT"];
		 [fateLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"INT"];
		 
		 [fateLevelInfo setObject:[NSNumber numberWithInt:1000] forKey:@"HP"];
		 [fateLevelInfo setObject:[NSNumber numberWithInt:1000] forKey:@"MP"];
		 [fateLevelInfo setObject:[NSNumber numberWithInt:60] forKey:@"ATK"];
		 [fateLevelInfo setObject:[NSNumber numberWithInt:60] forKey:@"STK"];
		 
		 [fateLevelInfo setObject:[NSNumber numberWithInt:10] forKey:@"DEF"];
		 [fateLevelInfo setObject:[NSNumber numberWithInt:5] forKey:@"SPD"];
		 
		 [fateLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPS"];
		 [fateLevelInfo setObject:[NSNumber numberWithInt:100] forKey:@"MPR"];
		 
		 [fateLevelInfo setObject:[NSNumber numberWithFloat:80.0f] forKey:@"HIT"];
		 [fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"MIS"];
		 [fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"BOK"];
		 [fateLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"COT"];
		 [fateLevelInfo setObject:[NSNumber numberWithFloat:20.0f] forKey:@"CRI"];
		 [fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"CPR"];
		 [fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"PEN"];
		 [fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"TUF"];
		 [fateLevelInfo setObject:[NSNumber numberWithFloat:10.0f] forKey:@"COB"];
		 
		 return fateLevelInfo;
		 */
	}
#endif
	return _info;
}
-(NSDictionary*)getPositionLevelInfo:(int)_pid level:(int)_level
{
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_POS_LEVEL,_pid];
	NSDictionary *table = [self readDB:path];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_level]];
	//#ifdef GAMEDB_DEBUG
	//	if (!_info) {
	//
	//		NSMutableDictionary * levelInfo = [NSMutableDictionary dictionary];
	//		[levelInfo setObject:[NSNumber numberWithInt:1] forKey:@"id"];
	//
	//		[levelInfo setObject:[NSNumber numberWithInt:_pid] forKey:@"posId"];   // @"pid" ?
	//		[levelInfo setObject:[NSNumber numberWithInt:_level] forKey:@"level"];
	//
	//		[levelInfo setObject:[NSNumber numberWithInt:10] forKey:@"unlock"];
	//		[levelInfo setObject:[NSNumber numberWithInt:100] forKey:@"coin1"];
	//
	//		//阵型增加 ：(特别)自身50%机率回复自身伤害值的10% ADD_HURT_HP_P:10:50
	//		[levelInfo setObject:@"ATK:1|DEF:1|ADD_HURT_HP_P:10:50" forKey:@"s1"];
	//		[levelInfo setObject:@"ATK:1|DEF:1" forKey:@"s2"];
	//		[levelInfo setObject:@"ATK:1|DEF:1" forKey:@"s3"];
	//		[levelInfo setObject:@"" forKey:@"s4"];
	//		[levelInfo setObject:@"CENTER_SPD_P:25" forKey:@"s5"];
	//		[levelInfo setObject:@"" forKey:@"s6"];
	//		[levelInfo setObject:@"" forKey:@"s7"];
	//		[levelInfo setObject:@"" forKey:@"s8"];
	//		[levelInfo setObject:@"" forKey:@"s9"];
	//		[levelInfo setObject:@"" forKey:@"s10"];
	//		[levelInfo setObject:@"" forKey:@"s11"];
	//		[levelInfo setObject:@"" forKey:@"s12"];
	//		[levelInfo setObject:@"" forKey:@"s13"];
	//		[levelInfo setObject:@"" forKey:@"s14"];
	//		[levelInfo setObject:@"" forKey:@"s15"];
	//		return levelInfo;
	//	}
	//#endif
	return _info;
}
-(NSArray*)getDailyByType:(int)_type
{
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_DAILY,_type];
	NSDictionary *table = [self readDB:path];
	return [table allValues];
}
-(NSDictionary*)getShopInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_SHOP :_id];
	return dict ;
}
-(NSDictionary*)getDireShopInfo:(int)_iid
{
	NSDictionary *dict = [self readDB:CONFIG_Dire_SHOP];
	NSString *_key = [NSString stringWithFormat:@"%d",_iid];
	NSDictionary *dShop = [dict objectForKey:_key];
	return dShop;
}
-(NSDictionary*)getRuleInfo:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_RULE :_id];
	return dict;
}
-(NSDictionary*)getTaskInfo:(int)_type taskId:(int)_id
{
	
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_TASK,_type];
	NSDictionary *table = [self readDB:path];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_id]];
	
#ifdef GAMEDB_DEBUG
	//	if (!_info) {
	//		NSMutableDictionary * info = [NSMutableDictionary dictionary];
	//
	//		[info setObject:[NSNumber numberWithInt:_id] forKey:@"id"];
	//		[info setObject:[NSNumber numberWithInt:_type] forKey:@"type"];//主线任务
	//
	//		[info setObject:[NSString stringWithFormat:@"task_%d",_id] forKey:@"name"];
	//		[info setObject:[NSString stringWithFormat:@"icon_task_%d",_id] forKey:@"icon"];
	//		[info setObject:[NSString stringWithFormat:@"info task %d",_id] forKey:@"info"];
	//
	//		//TODO 结构 task:1|level:1|role:7|obj:1:3|equ:5
	//		//一般主线任务是没有unlock
	//		//task:1 任务id为1已完成 可以多个 task:1|task:2|task:3 用于多完成多个支线任务才达到条件
	//		//level:1 玩家级数到达1
	//		//role:1 玩家角色里有的角色id 可以多个->role:1|role:2|role:3
	//		//obj:1:3 玩家背包里有的物品obj id为1的数量是3  可以多个->obj:1:3|obj:2:2|obj:3:1
	//		//equ:5 玩家有装备equ id为5的装备 可以多个->equ:5|equ:6|equ:7|equ:8 多个装备可以用于收藏整个套装后激活技定的任务
	//		[info setObject:@"" forKey:@"unlock"];
	//
	//		[info setObject:[NSNumber numberWithInt:(_id+1)] forKey:@"nextId"];//用于多个任务关连
	//		[info setObject:[NSNumber numberWithInt:1] forKey:@"rid"];//奖励ID，调用奖励接口
	//
	//		[info setObject:@"" forKey:@"step"];//非常复杂
	//
	//		if(_type==1){
	//
	//			//完成上一级任务
	//			[info setObject:[NSString stringWithFormat:@"task:%d",(_id-1)] forKey:@"unlock"];
	//
	//			[info setObject:[NSNumber numberWithInt:(_id+1)] forKey:@"nextId"];
	//			//TODO add task step data
	//
	//
	//			NSMutableArray * processList = [NSMutableArray array];
	//
	//			NSMutableDictionary * process;
	//			NSMutableDictionary * data;
	//
	//
	//			//move to npc 1
	//			process = [self getProcess:Task_Action_moveToNPC];
	//			data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
	//			[data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
	//			[data setObject:[NSNumber numberWithInt:1] forKey:@"npcId"];
	//			[process setObject:data forKey:@"data"];
	//			[processList addObject:process];
	//
	//			//fight 1
	//
	//			process = [self getProcess:Task_Action_fight];
	//			data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
	//			[data setObject:[NSNumber numberWithInt:1] forKey:@"fid"];
	//			[process setObject:data forKey:@"data"];
	//			[processList addObject:process];
	//
	//			//talk 1
	//			process = [self getProcess:Task_Action_talk];
	//			[processList addObject:process];
	//
	//			//move to npc 2
	//			process = [self getProcess:Task_Action_moveToNPC];
	//			data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
	//			[data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
	//			[data setObject:[NSNumber numberWithInt:2] forKey:@"npcId"];
	//			[process setObject:data forKey:@"data"];
	//			[processList addObject:process];
	//
	//			// stage 1
	//			process = [self getProcess:Task_Action_stage];
	//			data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
	//			[data setObject:[NSNumber numberWithInt:100] forKey:@"sid"];
	//
	//			NSMutableArray * p = [NSMutableArray array];
	//			NSMutableArray * a1 = [NSMutableArray array];
	//
	//			NSMutableDictionary * e1 = [self getProcess:Task_Action_addNpc];
	//			NSMutableDictionary * d1 = [NSMutableDictionary dictionaryWithDictionary:[e1 objectForKey:@"data"]];
	//			[d1 setObject:[NSNumber numberWithInt:3] forKey:@"npcId"];
	//			[d1 setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
	//			[d1 setObject:NSStringFromCGPoint(ccp(50,70)) forKey:@"point"];
	//			[e1 setObject:d1 forKey:@"data"];
	//			[a1 addObject:e1];
	//
	//			e1 = [self getProcess:Task_Action_talk];
	//			[a1 addObject:e1];
	//
	//			e1 = [self getProcess:Task_Action_effects];
	//			d1 = [NSMutableDictionary dictionaryWithDictionary:[e1 objectForKey:@"data"]];
	//			[d1 setObject:[NSNumber numberWithInt:EffectsAction_loshing] forKey:@"eid"];
	//			[e1 setObject:d1 forKey:@"data"];
	//			[a1 addObject:e1];
	//
	//			e1 = [self getProcess:Task_Action_removeNpc];
	//			d1 = [NSMutableDictionary dictionaryWithDictionary:[e1 objectForKey:@"data"]];
	//			[d1 setObject:[NSNumber numberWithInt:3] forKey:@"npcId"];
	//			[d1 setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
	//			[e1 setObject:d1 forKey:@"data"];
	//			[a1 addObject:e1];
	//
	//			NSMutableDictionary * p1 = [NSMutableDictionary dictionary];
	//			[p1 setObject:a1 forKey:@"before"];
	//			[p1 setObject:a1 forKey:@"behind"];
	//
	//			p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
	//			[p1 setObject:[NSNumber numberWithInt:0] forKey:@"index"];
	//			[p addObject:p1];
	//
	//			p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
	//			[p1 setObject:[NSNumber numberWithInt:1] forKey:@"index"];
	//			[p addObject:p1];
	//
	//			p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
	//			[p1 setObject:[NSNumber numberWithInt:2] forKey:@"index"];
	//			[p addObject:p1];
	//
	//			p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
	//			[p1 setObject:[NSNumber numberWithInt:3] forKey:@"index"];
	//			[p addObject:p1];
	//
	//			p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
	//			[p1 setObject:[NSNumber numberWithInt:4] forKey:@"index"];
	//			[p addObject:p1];
	//
	//			p1 = [NSMutableDictionary dictionaryWithDictionary:p1];
	//			[p1 setObject:[NSNumber numberWithInt:5] forKey:@"index"];
	//			[p addObject:p1];
	//
	//			[data setObject:p forKey:@"process"];
	//
	//			[process setObject:data forKey:@"data"];
	//			[processList addObject:process];
	//
	//			//move to npc 1
	//			process = [self getProcess:Task_Action_moveToNPC];
	//			data = [NSMutableDictionary dictionaryWithDictionary:[process objectForKey:@"data"]];
	//			[data setObject:[NSNumber numberWithInt:1] forKey:@"mapId"];
	//			[data setObject:[NSNumber numberWithInt:1] forKey:@"npcId"];
	//			[process setObject:data forKey:@"data"];
	//			[processList addObject:process];
	//
	//			//talk 1
	//			process = [self getProcess:Task_Action_talk];
	//			[processList addObject:process];
	//
	//
	//			NSMutableDictionary * stepData = [NSMutableDictionary dictionary];
	//			[stepData setObject:[NSNumber numberWithInt:[processList count]] forKey:@"count"];
	//			[stepData setObject:processList forKey:@"step"];
	//
	//			// turn data to json string
	//			NSData * jsonData = [[CJSONSerializer serializer] serializeObject:stepData error:nil];
	//			NSString * step = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	//
	//			step = @"{\"count\":3,\"step\":[{\"action\":\"3\",\"data\":{\"mapId\":\"1\",\"npcId\":\"1\"}},{\"action\":\"9\",\"data\":{\"sid\":\"1\",\"process\":[{\"index\":\"0\",\"before\":[{\"action\":\"1\",\"data\":[{\"rid\":\"0\",\"dir\":\"1\",\"msg\":\"1111\"},{\"rid\":\"1\",\"dir\":\"2\",\"msg\":\"2222\"},{\"rid\":\"0\",\"dir\":\"1\",\"msg\":\"11111\"},{\"rid\":\"1\",\"dir\":\"2\",\"msg\":\"22222\"}]}]}]}},{\"action\":\"1\",\"data\":[{\"rid\":\"0\",\"dir\":\"1\",\"msg\":\"1\"},{\"rid\":\"1\",\"dir\":\"2\",\"msg\":\"2\"},{\"rid\":\"0\",\"dir\":\"1\",\"msg\":\"3\"},{\"rid\":\"1\",\"dir\":\"2\",\"msg\":\"4\"},{\"rid\":\"0\",\"dir\":\"1\",\"msg\":\"5\"},{\"rid\":\"1\",\"dir\":\"2\",\"msg\":\"6\"}]}]}";
	//
	//			[info setObject:step forKey:@"step"];//非常复杂
	//
	//		}
	//		if(_type==2){
	//
	//			[info setObject:[NSString stringWithFormat:@"task:%d",(_id-100)] forKey:@"unlock"];
	//
	//			[info setObject:[NSNumber numberWithInt:(_id+1)] forKey:@"nextId"];
	//			//TODO add task step data
	//			NSString * step = @"";
	//			[info setObject:step forKey:@"step"];//非常复杂
	//
	//		}
	//		if(_type==3){
	//
	//			//TODO add task step data
	//			NSString * step = @"";
	//			[info setObject:step forKey:@"step"];//非常复杂
	//
	//		}
	//		if(_type==3){
	//
	//			[info setObject:@"task:100000|level:20" forKey:@"unlock"];
	//
	//			//TODO add task step data
	//			NSString * step = @"";
	//			[info setObject:step forKey:@"step"];//非常复杂
	//
	//		}
	//		return info;
	//	}
#endif
	return _info;
}
-(NSDictionary*)getFusionTable
{
	NSDictionary *dict = [self readDB:CONFIG_FUSION];
	if (!dict) {
		dict = [self process_common:CONFIG_FUSION key:@"id"];
	}
	return dict;
}

-(NSDictionary*)getGlobalConfig
{
	NSDictionary *dict = [self readDB:CONFIG_SETTING];
	if (!dict) {
		CCLOG(@"have no setting!");
		dict = [self process_setting:CONFIG_SETTING];
	}
	return dict;
}

-(id)getGlobalSetting:(NSString *)key{
	NSDictionary *dict = [self readDB:CONFIG_SETTING];
	if (dict) {
		return [dict objectForKey:key];
	}
	return nil;
}

-(int)mapRolesMax{
	NSDictionary * config = [self getGlobalConfig];
	int max = [[config objectForKey:@"mapRolesMax"] intValue];
	if(max==0){
		return 50;
	}
	return max;
}

-(NSArray*)getSkillStautsIds:(int)sid{
	//加载表
	NSDictionary *dict = [self readDB:CONFIG_SKILL_STATE];
	//获得全部元素
	NSArray *array = [dict allValues];
	NSMutableArray * result = [NSMutableArray array];
	for (NSDictionary *_temp in array) {
		int skill = [[_temp objectForKey:@"skid"] intValue];
		if (skill == sid) {//技能ID 相同的 丢出去
			[result addObject:_temp];
		}
	}
	
#ifdef GAMEDB_DEBUG
	//	if ([result count] == 0) {
	//		NSMutableDictionary * skillStatus = nil;
	//
	//		skillStatus = [NSMutableDictionary dictionary];
	//		[skillStatus setObject:[NSNumber numberWithInt:1] forKey:@"id"];
	//		[skillStatus setObject:[NSNumber numberWithInt:sid] forKey:@"skid"];
	//		[skillStatus setObject:[NSNumber numberWithInt:1] forKey:@"stid"];
	//
	//		[result addObject:skillStatus];
	//
	//		skillStatus = [NSMutableDictionary dictionary];
	//		[skillStatus setObject:[NSNumber numberWithInt:1] forKey:@"id"];
	//		[skillStatus setObject:[NSNumber numberWithInt:sid] forKey:@"skid"];
	//		[skillStatus setObject:[NSNumber numberWithInt:2] forKey:@"stid"];
	//
	//		[result addObject:skillStatus];
	//	}
#endif
	return result;
	
}




#ifdef GAMEDB_DEBUG
-(NSMutableDictionary*)getProcess:(int)action{
	NSMutableDictionary * process = [NSMutableDictionary dictionary];
	[process setObject:[NSNumber numberWithInt:action] forKey:@"action"];
	
	if(action==Task_Action_talk){
		NSMutableArray * data = [NSMutableArray array];
		[data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck1",@"msg",@"1",@"rid",@"1",@"dir",nil]];
		[data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck2",@"msg",@"2",@"rid",@"2",@"dir",nil]];
		[data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck3",@"msg",@"1",@"rid",@"1",@"dir",nil]];
		[data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck4",@"msg",@"2",@"rid",@"2",@"dir",nil]];
		[data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck5",@"msg",@"1",@"rid",@"1",@"dir",nil]];
		[data addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"fuck6",@"msg",@"2",@"rid",@"2",@"dir",nil]];
		[process setObject:data forKey:@"data"];
	}
	if(action==Task_Action_move){
		NSMutableDictionary * data = [NSMutableDictionary dictionary];
		[data setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
		[data setObject:NSStringFromCGPoint(ccp(50,60)) forKey:@"point"];
		
		[process setObject:data forKey:@"data"];
	}
	if(action==Task_Action_moveToNPC){
		NSMutableDictionary * data = [NSMutableDictionary dictionary];
		[data setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
		[data setObject:[NSNumber numberWithInt:0] forKey:@"npcId"];
		
		[process setObject:data forKey:@"data"];
	}
	
	////////////////////////////////////////////////////////////////////////////
	
	if(action==Task_Action_addNpc){
		NSMutableDictionary * data = [NSMutableDictionary dictionary];
		
		[data setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
		[data setObject:[NSNumber numberWithInt:0] forKey:@"npcId"];
		[data setObject:NSStringFromCGPoint(ccp(50,60)) forKey:@"point"];
		
		[process setObject:data forKey:@"data"];
	}
	if(action==Task_Action_moveNpc){
		NSMutableDictionary * data = [NSMutableDictionary dictionary];
		
		[data setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
		[data setObject:[NSNumber numberWithInt:0] forKey:@"npcId"];
		[data setObject:NSStringFromCGPoint(ccp(50,60)) forKey:@"point"];
		
		[process setObject:data forKey:@"data"];
	}
	if(action==Task_Action_removeNpc){
		NSMutableDictionary * data = [NSMutableDictionary dictionary];
		
		[data setObject:[NSNumber numberWithInt:0] forKey:@"mapId"];
		[data setObject:[NSNumber numberWithInt:0] forKey:@"npcId"];
		
		[process setObject:data forKey:@"data"];
	}
	
	////////////////////////////////////////////////////////////////////////////
	
	if(action==Task_Action_effects){
		NSMutableDictionary * data = [NSMutableDictionary dictionary];
		[data setObject:[NSNumber numberWithInt:0] forKey:@"eid"];
		[data setObject:@"" forKey:@"other"];
		[process setObject:data forKey:@"data"];
	}
	
	if(action==Task_Action_unlock){
		NSMutableDictionary * data = [NSMutableDictionary dictionary];
		[data setObject:[NSNumber numberWithInt:0] forKey:@"unlockID"];
		[process setObject:data forKey:@"data"];
	}
	
	////////////////////////////////////////////////////////////////////////////
	
	if(action==Task_Action_stage){
		NSMutableDictionary * data = [NSMutableDictionary dictionary];
		[data setObject:[NSNumber numberWithInt:0] forKey:@"sid"];
		[data setObject:@"" forKey:@"process"];
		[process setObject:data forKey:@"data"];
	}
	
	if(action==Task_Action_fight){
		NSMutableDictionary * data = [NSMutableDictionary dictionary];
		[data setObject:[NSNumber numberWithInt:1] forKey:@"fid"];
		[process setObject:data forKey:@"data"];
	}
	
	return process;
}

#endif

-(NSArray*)getNames{
	NSDictionary *dict=[self readDB:CONFIG_NAMES];
	NSArray *re=dict.allValues;
	return re;
}

-(NSDictionary*)getIntro:(int)step{
	NSDictionary *db=[self readDB:CONFIG_INTRO];
	return 	[db objectForKey:[NSString stringWithFormat:@"%i",step]];
}


-(NSDictionary*)getBanWord{
	NSDictionary *dict= [NSDictionary dictionary];//[self readDB:CONFIG_BANWORD];
	return dict;
}


//todo maxleung 等错误表录入完测试
-(NSString*)getErrorMsg:(int)errorid{
	NSDictionary *db=[self readDB:CONFIG_ERROR];
	NSDictionary *dict = [db objectForKey:[NSString stringWithFormat:@"%d",errorid]];
	if (dict) {
		return [dict objectForKey:@"info"];
	}
	
	return @"";
	//	return [db objectForKey:[NSString stringWithFormat:@"%d",errorid]];
}

-(NSDictionary*)getBossLevelInfoBydId:(int)_id{
	NSDictionary *db=[self readDB:CONFIG_BOSS_LEVEL];
	NSDictionary *dict = [db objectForKey:[NSString stringWithFormat:@"%d",_id]];
	if (dict) {
		return dict;
	}
	return nil;
}

-(NSDictionary*)getFightTips:(int)_type{
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_GAME_TIPS,GameTipsType_fight];
	NSDictionary *table = [self readDB:path];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_type]];
	return _info;
}

-(NSDictionary*)getLoadingTips:(int)_type{
	NSString *path = [NSString stringWithFormat:@"%@_%d",CONFIG_GAME_TIPS,GameTipsType_loading];
	NSDictionary *table = [self readDB:path];
	NSDictionary *_info = [table objectForKey:[NSString stringWithFormat:@"%d",_type]];
	return _info;
}

-(NSDictionary*)getDaySuccessInfo:(int)_id{
	NSDictionary *db=[self readDB:CONFIG_ACHI_DAY];
	NSDictionary *dict = [db objectForKey:[NSString stringWithFormat:@"%d",_id]];
	if (dict) {
		return dict;
	}
	return nil;
}


-(NSDictionary*)getfuncsInfo:(int)_id{
	NSDictionary *db=[self readDB:CONFIG_FUNCS];
	NSDictionary *dict = [db objectForKey:[NSString stringWithFormat:@"%d",_id]];
	if (dict) {
		return dict;
	}
	return nil;
}

-(NSDictionary*)getEverSuccessInfo:(int)_id{
	NSDictionary *db=[self readDB:CONFIG_ACHI_ETERNAL];
	NSDictionary *dict = [db objectForKey:[NSString stringWithFormat:@"%d",_id]];
	if (dict) {
		return dict;
	}
	return nil;
}

-(NSDictionary*)getRoleupQualityInfo:(int)_type quality:(int)_quality{
	NSString* fileName = [NSString stringWithFormat:@"%@_%d_%d",CONFIG_roleup,_type,_quality];
	NSDictionary *db=[self readDB:fileName];
	return db;
}

-(NSDictionary*)getRoleupInfo:(int)_type quality:(int)_quality grade:(int)_grade check:(int)_check{
	NSDictionary* dict = [self getRoleupQualityInfo:_type quality:_quality];
	if (dict) {
		NSDictionary* gDict = [dict objectForKey:[NSString stringWithFormat:@"%d",_grade]];
		if (gDict) {
			NSDictionary* cDict = [gDict objectForKey:[NSString stringWithFormat:@"%d",_check]];
			return cDict ;
		}
	}
	return nil;
}

-(NSDictionary*)getRoleupTypeInfo:(int)_rid{
	NSDictionary *db=[self readDB:CONFIG_roleup_type];
	NSDictionary *dict = [db objectForKey:[NSString stringWithFormat:@"%d",_rid]];
	return dict;
}

-(NSDictionary*)getGemUpRate:(int)_s1 startLevel:(int)_sl to:(int)_t1 toLevel:(int)_tl{
	NSString* fileName = [NSString stringWithFormat:@"%@_%d_%d",CONFIG_gem_up_rate,_s1,_sl];
	NSDictionary *dict=[self readDB:fileName];
	if (dict) {
		NSDictionary* gDict = [dict objectForKey:[NSString stringWithFormat:@"%d",_t1]];
		if (gDict) {
			NSDictionary* cDict = [gDict objectForKey:[NSString stringWithFormat:@"%d",_tl]];
			return cDict ;
		}
	}
	return nil;
}

-(NSDictionary*)getAllBoatExchange:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_ALLY_BOAT_EXCHANGE :_id];
	return dict ;
}
// 天舟兑换物品表
-(NSDictionary*)getAllBoatExchange{
    NSDictionary *dict = [self readDB:CONFIG_ALLY_BOAT_EXCHANGE];
	if (!dict) {
		dict = [self process_common:CONFIG_ALLY_BOAT_EXCHANGE key:@"id"];
	}
    return dict;
}

-(NSDictionary*)getAllBoatLevel:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_ALLY_BOAT_LEVEL :_id];
	return dict ;
}
// 天舟等级(类型，等级)
-(NSDictionary*)getAllBoatLevelWithType:(int)_type level:(int)_level{
    NSDictionary *dict = [self readDB:CONFIG_ALLY_BOAT_LEVEL];
	if (!dict) {
		dict = [self process_common:CONFIG_ALLY_BOAT_LEVEL key:@"id"];
	}
    NSArray *allkey = [dict allKeys];
    for (id key in allkey) {
        NSDictionary *t_dict = [dict objectForKey:key];
        if ([[t_dict objectForKey:@"t"] intValue] == _type && [[t_dict objectForKey:@"lv"] intValue] == _level) {
            return t_dict;
        }
    }
	return NULL;
}

-(NSDictionary*)getAwarBook:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_AWAR_BOOK :_id];
	return dict ;
}

-(NSDictionary*)getAwarNpcConfig:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_AWAR_NPC_CONFIG :_id];
	return dict ;
}

-(NSDictionary*)getAwarPerConfig:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_AWAR_PER_CONFIG :_id];
	return dict ;
}

-(NSDictionary*)getAwarStartConfig:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_AWAR_START_CONFIG :_id];
	return dict ;
}

-(NSDictionary*)getAwarStrongMap:(int)_id
{
	NSDictionary *dict = [self getInfo:CONFIG_AWAR_STRONG_MAP :_id];
	return dict ;
}
-(NSDictionary*)getAwarStrongMap{
    NSDictionary *dict = [self readDB:CONFIG_AWAR_STRONG_MAP];
	if (!dict) {
		dict = [self process_common:CONFIG_AWAR_STRONG_MAP key:@"id"];
	}
    return dict ;
}
@end
