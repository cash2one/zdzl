//
//  PlayerDataHelper.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-1.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "PlayerDataHelper.h"
#import "GameConfigure.h"
#import "GameConnection.h"
#import "GameDB.h"
#import "Config.h"

static PlayerDataHelper * playerDataHelper;

static NSString * getPart(int part){
	return [NSString stringWithFormat:@"eq%d",(part+1)];
}

int sortEquipsByPart(NSDictionary *p1, NSDictionary*p2, void*context){
	
	PlayerDataHelper * helper = context;
	
	int eid1 = [[p1 objectForKey:@"eid"] intValue];
	int eid2 = [[p2 objectForKey:@"eid"] intValue];
	
	NSDictionary * setInfo1 = [helper getEquipSetInfoByEquipId:eid1];
	NSDictionary * setInfo2 = [helper getEquipSetInfoByEquipId:eid2];
	
	int sLv1 = [[setInfo1 objectForKey:@"lv"] intValue];
	int sLv2 = [[setInfo2 objectForKey:@"lv"] intValue];
	int sQu1 = [[setInfo1 objectForKey:@"quality"] intValue];
	int sQu2 = [[setInfo2 objectForKey:@"quality"] intValue];
	
	//check by equip set
	if(sQu1>sQu2) return NSOrderedAscending;
	if(sQu1<sQu2) return NSOrderedDescending;
	if(sLv1>sLv2) return NSOrderedAscending;
	if(sLv1<sLv2) return NSOrderedDescending;
	
	//check by equip level
	int level1 = [[p1 objectForKey:@"level"] intValue];
	int level2 = [[p2 objectForKey:@"level"] intValue];
	
	if(level1>level2) return NSOrderedAscending;
	if(level1<level2) return NSOrderedDescending;
	
	return NSOrderedSame;
}

@implementation NSDictionary (PlayerHelper)
-(id)objectForId:(int)tid{
	NSString * key = [NSString stringWithFormat:@"%d",tid];
	return [self objectForKey:key];
}

-(int)intForKey:(NSString *)_key{
	return [[self objectForKey:_key] intValue];
}
@end

@implementation PlayerDataHelper


@synthesize jewels;
@synthesize equips;
@synthesize fates;
@synthesize items;
@synthesize batchs;
@synthesize isReady;
@synthesize isChecking;
@synthesize totalPower;

+(PlayerDataHelper*)shared{
	return playerDataHelper;
}

+(void)start{
	if(!playerDataHelper){
		playerDataHelper = [[PlayerDataHelper alloc] init];
		[playerDataHelper loadData];
	}
}

+(void)stopAll{
	if(playerDataHelper){
		[playerDataHelper postBattlePower];
		[playerDataHelper writeData];
		[playerDataHelper freeData];
		[playerDataHelper release];
		playerDataHelper = nil;
	}
}

#pragma mark-

-(id)init{
	if((self=[super init])!=nil){
		
	}
	return self;
}

-(void)dealloc{
	[self freeData];
	[super dealloc];
}

-(void)loadData{
	
	[self freeData];

	jewels = [NSMutableArray arrayWithArray:[[GameConfigure shared] getPlayerJewels]];
	[jewels retain];
	
	NSDictionary * gemInfos = [[GameDB shared] getJewelInfoByIds:getArrayListDataByKey(jewels,@"gid")];
	jewelInfos = [NSMutableDictionary dictionaryWithDictionary:gemInfos];
	[jewelInfos retain];
	
	
	roles = [NSMutableArray arrayWithArray:[[GameConfigure shared] getPlayerRoleList]];
	
	NSDictionary * infos = [[GameDB shared] getRoleInfosByIds:getArrayListDataByKey(roles,@"rid")];
	roleInfos = [NSMutableDictionary dictionaryWithDictionary:infos];
	
	[roles retain];
	[roleInfos retain];
	
	NSArray * ueqs = [[GameConfigure shared] getPlayerEquipmentList];
	infos = [[GameDB shared] getEquipmentInfoByIds:getArrayListDataByKey(ueqs,@"eid")];
	
	equips = [NSMutableArray arrayWithArray:ueqs];
	equipInfos = [NSMutableDictionary dictionaryWithDictionary:infos];
	
	[equips retain];
	[equipInfos retain];
	
	infos = [[GameDB shared] getEquipmentSetInfoByIds:getArrayListDataByKey(infos,@"sid")];
	equipSetInfos = [NSMutableDictionary dictionaryWithDictionary:infos];
	[equipSetInfos retain];
	
	NSArray * ufs = [[GameConfigure shared] getPlayerFateList];
	infos = [[GameDB shared] getFateInfoByIds:getArrayListDataByKey(ufs,@"fid")];
	
	fates = [NSMutableArray arrayWithArray:ufs];
	fateInfos = [NSMutableDictionary dictionaryWithDictionary:infos];
	[fates retain];
	[fateInfos retain];
	
	NSArray * uits = [[GameConfigure shared] getPlayerItemList];
	infos = [[GameDB shared] getItemInfoByIds:getArrayListDataByKey(uits,@"iid")];
	
	items = [NSMutableArray arrayWithArray:uits];
	itemInfos = [NSMutableDictionary dictionaryWithDictionary:infos];
	[items retain];
	[itemInfos retain];
	
	
	NSArray * arms = getArrayListDataByKey(roleInfos,@"armId");
	armInfos = [NSMutableDictionary dictionaryWithDictionary:[[GameDB shared] getArmInfoByIds:arms]];
	[armInfos retain];
	
	
	
	NSArray * skills = getArrayListDataByKey(roleInfos,@"sk2");
	skillInfos = [NSMutableDictionary dictionaryWithDictionary:[[GameDB shared] getSkillInfoByIds:skills]];
	[skillInfos retain];
	
	
	powers = [NSMutableDictionary dictionary];
	[powers retain];
	
	equipStrengInfos = [NSMutableDictionary dictionaryWithDictionary:[[GameDB shared] getEquipmentsStrengTable]];
	[equipStrengInfos retain];
	
	
	batchs = [NSMutableDictionary dictionary];
	[batchs retain];
	
	
	attributes = [NSMutableDictionary dictionary];
	[attributes retain];
	
	
	[self loadPart];
	
}

-(void)loadPart{
	
	dispatch_queue_t queue = dispatch_queue_create("PlayerDataHelper.loadPart", NULL);
	dispatch_async(queue, ^{
		
		NSMutableArray * parts = [NSMutableArray array];
		
		for(int i=0;i<6;i++){
			[parts addObject:[NSMutableArray array]];
		}
		
		for(NSDictionary * equip in equips){
			int eid = [[equip objectForKey:@"eid"] intValue];
			NSDictionary * equipInfo = [equipInfos objectForId:eid];
			if(equipInfo){
				int part = [[equipInfo objectForKey:@"part"] intValue];
				NSMutableArray * tAry  = [parts objectAtIndex:(part-1)];
				[tAry addObject:equip];
			}
		}
		
		for(int i=0;i<6;i++){
			[parts[i] sortUsingFunction:sortEquipsByPart 
									 context:self];
		}
		
		NSArray* teams = [self getRoleWithStatus:RoleStatus_in];
		for (NSNumber *number in teams) {
			int _rid = [number intValue];
			NSString* _key = [NSString stringWithFormat:@"%d",_rid];
			[powers setObject:[NSNumber numberWithInt:0] forKey:_key];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			for(int i=0;i<6;i++){
				partEquips[i] = [[NSMutableArray alloc] initWithArray:[parts objectAtIndex:i]];
			}
			isReady = YES;
			
			[self updateAllPower];
			
		});
	});
	
	dispatch_release(queue);
	
}
-(int)getPlayerLevel{
    return [[GameConfigure shared] getPlayerLevel];
}
-(NSDictionary*)getPlayerInfo{
    return [[GameConfigure shared] getPlayerInfo];
}
-(NSString*)getPlayerName{
    return [[GameConfigure shared] getPlayerName];
}
-(void)postBattlePower{
	
	/*
	NSString *str = [NSString stringWithFormat:@"key:CBE|value::%d",totalPower];
	[GameConnection request:@"pAttrSet" format:str target:nil call:nil];
	*/
	[[GameConfigure shared] updateCBE:powers];
	
}

-(void)updateAllPower{
	
	if (isChecking) {
		return ;
	}
		
	dispatch_queue_t queue = dispatch_queue_create("PlayerDataHelper.loadPower", NULL);
	dispatch_async(queue, ^{
		
		CCLOG(@"updateAllPower->begin");
		isChecking = YES;
		
		[playerDataHelper writeData];
		
		
		int tmp_total_power = 0;
		
		NSArray* teams = [self getRoleWithStatus:RoleStatus_in];
		for (NSNumber *number in teams) {
			int _rid = [number intValue];
			
			BaseAttribute att = [[GameConfigure shared] getRoleAttribute:_rid isLoadOtherBuff:YES];
			NSDictionary* eDict = BaseAttributeToDictionary(att);
			int __value = getBattlePower(att);
			NSString* _key = [NSString stringWithFormat:@"%d",_rid];
			
			//------
			[powers setObject:[NSNumber numberWithInt:__value] forKey:_key];
			//------
			[attributes setObject:eDict forKey:_key];
			
			//tmp_total_power += __value;
			
		}
		
		tmp_total_power = [[GameConfigure shared] getPowerResult:powers];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			totalPower = tmp_total_power;
			[GameConnection post:PlayerDataHelper_Event_Update_Power object:nil];
			isChecking = NO;
			CCLOG(@"updateAllPower->end");
		});
		
	});
	dispatch_release(queue);
	
}

-(void)writeData{
	//写入角色数据
	//写入装备数据
	//写入命格数据
	//写入物品数据
	[[GameConfigure shared] updateRoleArray:roles];
	[[GameConfigure shared] updateEquipmentArray:equips];
	[[GameConfigure shared] updateFateArray:fates];
	[[GameConfigure shared] updateItemArray:items];
	[[GameConfigure shared] updateJewelArray:jewels];
}

-(void)freeData{
	
	isReady = NO;
	
	if (jewels) {
		[jewels release];
		jewels = nil;
	}
	
	if (jewelInfos) {
		[jewelInfos release];
		jewelInfos = nil;
	}
	
	if(roles){
		[roles release];
		roles = nil;
	}
	if(roleInfos){
		[roleInfos release];
		roleInfos = nil;
	}
	
	if(equips){
		[equips release];
		equips = nil;
	}
	if(equipInfos){
		[equipInfos release];
		equipInfos = nil;
	}
	if(equipSetInfos){
		[equipSetInfos release];
		equipSetInfos = nil;
	}
	
	if(fates){
		[fates release];
		fates = nil;
	}
	if(fateInfos){
		[fateInfos release];
		fateInfos = nil;
	}
	
	if(items){
		[items release];
		items = nil;
	}
	if(itemInfos){
		[itemInfos release];
		itemInfos = nil;
	}
	
	if (equipStrengInfos) {
		[equipStrengInfos release];
		equipStrengInfos = nil ;
	}
	
	if(armInfos){
		[armInfos release];
		armInfos = nil;
	}
	
	if (skillInfos) {
		[skillInfos release];
		skillInfos = nil;
	}
	
	if (powers) {
		[powers release];
		powers = nil ;
	}
	
	if (batchs) {
		[batchs release];
		batchs = nil;
	}
	
	if (attributes) {
		[attributes release];
		attributes = nil;
	}
	
	for (int i=0; i<6; i++) {
		if(partEquips[i]){
			[partEquips[i] release];
			partEquips[i] = nil;
		}
	}
	
}

#pragma mark-

-(NSArray*)getRoleWithStatus:(RoleStatus)_status{
	NSMutableArray* array = [NSMutableArray array];
	for (NSDictionary* role in roles) {
		NSNumber* number = [role objectForKey:@"status"];
		if ([number intValue] == _status) {
			[array addObject:[role objectForKey:@"rid"]];
		}
	}
	[array sortUsingSelector:@selector(compare:)];
	return array;
}

-(BOOL)fallOut:(int)_id{
	if (_id <= 0) return NO;
	CCLOG(@"fallOut:%d",_id);
	
	NSMutableDictionary* _temp = [NSMutableDictionary dictionaryWithDictionary:[self getRoleById:_id]];
	[_temp setObject:[NSNumber numberWithInt:RoleStatus_out] forKey:@"status"];
	[self updateRoleByDict:_temp];
	
	return YES ;
}

-(NSDictionary*)getRole:(int)rid{
	for(NSDictionary * role in roles){
		if([[role objectForKey:@"rid"] intValue] == rid){
			return role;
		}
	}
	return nil;
}

-(NSDictionary*)getRoleById:(int)____id{
	for(NSDictionary * role in roles){
		if([role intForKey:@"id"] == ____id){
			return role;
		}
	}
	return nil;
}


-(NSDictionary*)getEquipmentById:(int)____id{
	for(NSDictionary * equip in equips){
		if([equip intForKey:@"id"] == ____id){
			return equip;
		}
	}
	return nil ;
}

-(void)updateEquipmentByDictWithArray:(NSArray *)_array{
	if (_array == nil) return ;
	
	for (NSDictionary* _dict in _array) {
		[self updateEquipmentByDict:_dict];
	}
	
}

-(void)updateEquipmentByDict:(NSDictionary *)_dict{
	if (_dict == nil) return ;
	//
	CCLOG(@"updateEquipmentByDict->begin->%d",equips.count);
	for(NSDictionary * equip in equips){
		if([equip intForKey:@"id"] == [_dict intForKey:@"id"]){
			[equips removeObject:equip];
			break ;
		}
	}
	
	//
	//
	int _eid = [_dict intForKey:@"eid"];
	NSDictionary* ___eDict = [equipInfos objectForId:_eid];
	
	int _part = [___eDict intForKey:@"part"];
	CCLOG(@"updateEquipmentByDict->part:%d",_part);
	
	//-----------------------------------------------------
	BOOL isAdd = NO ;
	for(NSDictionary * equip in partEquips[_part-1]){
		if([equip intForKey:@"id"] == [_dict intForKey:@"id"]){
			isAdd = YES ;
			[partEquips[_part-1] removeObject:equip];
			break ;
		}
	}
	if (isAdd) {
		[partEquips[_part-1] addObject:_dict];
		[partEquips[_part-1] sortUsingFunction:sortEquipsByPart
							context:self];
	}
	//-----------------------------------------------------
	
	CCLOG(@"updateEquipmentByDict->end->%d",equips.count);
	[equips addObject:_dict];
}

-(void)updateRoleByDict:(NSDictionary *)_dict{
	if (_dict == nil) return ;
	//
	CCLOG(@"updateRoleByDict->begin->%d",roles.count);
	for(NSDictionary * role in roles){
		if([role intForKey:@"id"] == [_dict intForKey:@"id"]){
			[roles removeObject:role];
			break ;
		}
	}
	CCLOG(@"updateRoleByDict->end->%d",roles.count);
	[roles addObject:_dict];
}
-(void)updatePackage:(NSDictionary *)dict{
    [[GameConfigure shared] updatePackage:dict];
}
-(NSDictionary*)getItem:(int)iid{
	for(NSDictionary * item in items){
		if([[item objectForKey:@"id"] intValue] == iid){
			return item;
		}
	}
	return nil;
}

-(NSDictionary*)getFate:(int)fid{
	for(NSDictionary * fate in fates){
		if([[fate objectForKey:@"id"] intValue] == fid){
			return fate;
		}
	}
	return nil;
}

-(BOOL)checkEquipmentCanKitUp:(int)_ueid{
	NSDictionary* ___equip = [self getEquipmentById:_ueid];
	if (___equip) {
		int ___id = [___equip intForKey:@"eid"];
		NSDictionary* eDict = [equipInfos objectForId:___id];
		if (eDict) {
			int ___sid = [eDict intForKey:@"sid"];
			int ___limit = [[eDict objectForKey:@"limit"] intValue];
			
			NSDictionary* sDict = [equipSetInfos objectForId:___sid];
			if (sDict) {
				int __cond = [sDict intForKey:@"cond"];
				if (__cond == 0) {
					return YES ;
				}
				if (__cond == 1) {
					NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
					int pLevel = [[playerInfo objectForKey:@"level"] intValue];
					return (pLevel >= ___limit);
				}
			}
		}
	}
	return NO;
}

-(NSDictionary*)getEquipInfoByEquipId:(int)eid{
	return [equipInfos objectForId:eid];
}

-(NSDictionary*)getEquipSetInfoByEquipId:(int)eid{
	NSDictionary * equipInfo = [self getEquipInfoByEquipId:eid];
	int sid = [[equipInfo objectForKey:@"sid"] intValue];
	return [equipSetInfos objectForId:sid];
}

-(NSDictionary*)getEquipForRole:(int)rid part:(int)part{
	if(part<0 || part>5) return nil;
	NSDictionary * role = [self getRole:rid];
	int ueid = [[role objectForKey:getPart(part)] intValue];
	if(ueid>0){
		for(NSDictionary * equip in equips){
			if([[equip objectForKey:@"id"] intValue]==ueid){
				return equip;
			}
		}
	}
	return nil;
}

-(int)getEquipmentMoveCost:(int)_lv1 with:(int)_lv2{
	NSDictionary* d1 = [equipStrengInfos objectForKey:[NSString stringWithFormat:@"%d",_lv1]];
	NSDictionary* d2 = [equipStrengInfos objectForKey:[NSString stringWithFormat:@"%d",_lv2]];
	
	int price = [d1 intForKey:@"mvCoin1"];
	price -= [d2 intForKey:@"mvCoin1"];
	
	return abs(price);
}

-(int)getEquipmentPart:(int)_eid{
	NSDictionary* ___equip = [self getEquipmentById:_eid];
	if (___equip) {
		int ___id = [___equip intForKey:@"eid"];
		NSDictionary* eDict = [equipInfos objectForId:___id];
		if (eDict) {
			return [eDict intForKey:@"part"];
		}
	}
	return 0;
}

-(int)getEquipmentLevel:(int)_eid{
	NSDictionary* ___equip = [self getEquipmentById:_eid];
	if (___equip) {
		return [___equip intForKey:@"level"];
	}
	return 0;
}

-(int)getEquipIdForRole:(int)rid part:(int)part{
	if(part<0 || part>5) return 0;
	NSDictionary * role = [self getRole:rid];
	int ueid = [[role objectForKey:getPart(part)] intValue];
	return ueid;
}

-(NSDictionary*)getNewEquipForRole:(int)rid part:(int)part{
	
	NSMutableDictionary *data = [NSMutableDictionary dictionary];
	
	
	if(part<0 || part>5){
		[data setObject:[NSNumber numberWithInt:Equipment_action_none] forKey:@"action"];
		//return Equipment_action_none;
		return data;
	}
	
	NSArray * parts = partEquips[part];
	
	NSDictionary * uEquip = [self getEquipForRole:rid part:part];
	
	//有装备才去比较
	NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
	int pLevel = [[playerInfo objectForKey:@"level"] intValue];
	
	//没装备 就直接交换了
	if (uEquip == nil) {
		for (NSDictionary* tEquip in parts) {
			int used = [[tEquip objectForKey:@"used"] intValue];
			
			if (used == EquipmentStatus_unused) {
				
				int eid2 = [[tEquip objectForKey:@"eid"] intValue];
				NSDictionary * info = [equipInfos objectForId:eid2];
				
				if(pLevel>=[[info objectForKey:@"limit"] intValue]){
					
					[data setObject:[NSNumber numberWithInt:Equipment_action_swap] forKey:@"action"];
					[data setObject:tEquip forKey:@"data"];
					
					return data;
					
					//return Equipment_action_swap;
				}
			}
		}
		//全部都装不上去
		
		[data setObject:[NSNumber numberWithInt:Equipment_action_none] forKey:@"action"];
		//return Equipment_action_none;
		return data;
	}
	
	int _byEid = [[uEquip objectForKey:@"eid"] intValue];
	NSDictionary *_byEq = [equipInfos objectForId:_byEid];
	int _bySid = [[_byEq objectForKey:@"sid"] intValue];
	NSDictionary* _byEs = [equipSetInfos objectForId:_bySid];
	
	for (NSDictionary* tEquip in parts) {
		
		int used = [[tEquip objectForKey:@"used"] intValue];
		if (used == EquipmentStatus_unused) {
			
			int _beEid = [[tEquip objectForKey:@"eid"] intValue];
			NSDictionary* _beEq = [equipInfos objectForId:_beEid];
			
			int _beSid = [[_beEq objectForKey:@"sid"] intValue];
			int _limit = [[_beEq objectForKey:@"limit"] intValue];
			
			NSDictionary* _beEs = [equipSetInfos objectForId:_beSid];
			
			int __cond = [_beEs intForKey:@"cond"];
			
			if (__cond == 1) {
				//只有设置了锁定的才做判断
				if (pLevel < _limit) {
					//等级不够 算了！！
					continue ;
				}
			}
			
			int byQu = [[_byEs objectForKey:@"quality"] intValue];
			int beQu = [[_beEs objectForKey:@"quality"] intValue];
			
			int byLv = [[_byEs objectForKey:@"lv"] intValue];
			int beLv = [[_beEs objectForKey:@"lv"] intValue];
			
			int byLevel = [[uEquip objectForKey:@"level"] intValue];
			int beLevel = [[tEquip objectForKey:@"level"] intValue];
			
			
			EQUIPMENT_ACTION_TYPE _temp = Equipment_action_none ;
			
			if(byQu<beQu){
				if(byLevel>beLevel) _temp =  Equipment_action_convert;
				if(byLevel<=beLevel) _temp =  Equipment_action_swap;
			} else if (byQu == beQu) {
				if (byLv < beLv) {
					if(byLevel>beLevel) _temp =  Equipment_action_convert;
					if(byLevel<=beLevel) _temp = Equipment_action_swap;

				}else if (byLv == beLv){
					if(byLevel<beLevel) _temp = Equipment_action_swap;
				}
			}
			
			if (_temp != Equipment_action_none) {
				[data setObject:[NSNumber numberWithInt:_temp] forKey:@"action"];
				[data setObject:tEquip forKey:@"data"];
				return data;
			}
		}
	}
	
	[data setObject:[NSNumber numberWithInt:Equipment_action_none] forKey:@"action"];
	return data ;
	
}

-(BOOL)checkCanNewEquipForRole:(int)rid part:(int)part{
	NSDictionary * upEquip = [self getNewEquipForRole:rid part:part];
	if(upEquip){
		return YES;
	}
	return NO;
}

-(int)getUserRoleId:(int)_rid{
	NSDictionary* dict = [self getRole:_rid];
	int ___id = [[dict objectForKey:@"id"] intValue];
	return ___id;
}

-(int)getFateExperience:(int)_rid{
	NSDictionary* _role = [self getRole:_rid];
	if (_role == nil) return 0 ;
	
	int _total = 0 ;
	
	for (int i = 1 ; i <= 6; i++) {
		NSString* _key = [NSString stringWithFormat:@"fate%d",i];
		int _fid = [[_role objectForKey:_key] intValue];
		
		if (_fid <= 0) continue ;
		
		NSDictionary* fDict = [self getFate:_fid];
		
		int _exp = [[fDict objectForKey:@"exp"] intValue];
		_total += _exp ;
		
	}
	
	return _total/5 ;
}

-(int)getWeaponLevel:(int)_rid{
	if (_rid <= 0) return nil ;
	NSDictionary* _urole = [self getRole:_rid];
	int _armLv = [[_urole objectForKey:@"armLevel"] intValue];
	return _armLv;
}

-(int)getEquipmentQuality:(int)_eid{
	NSDictionary* e1 = [equipInfos objectForId:_eid];
	int _sid = [[e1 objectForKey:@"sid"] intValue];
	NSDictionary* e2 = [equipSetInfos objectForId:_sid];
	return [e2 intForKey:@"quality"];
}

-(NSDictionary*)getJewelInfoBy:(int)_jid
{
	return [jewelInfos objectForId:_jid];
}

-(int)getJewelQuality:(int)_gid{
	NSDictionary* g1 = [jewelInfos objectForId:_gid];
	return [g1 intForKey:@"quality"];
}

-(int)getFateQuality:(int)_fid{
	NSDictionary* e1 = [fateInfos objectForId:_fid];
	return [e1 intForKey:@"quality"];
}

-(int)getItemQuality:(int)_iid{
	NSDictionary* e1 = [itemInfos objectForId:_iid];
	return [e1 intForKey:@"quality"];
}

-(NSArray*)getItemArrayWithType:(int)_tType{
	//获取消耗品或者材料
	
	NSMutableArray* array = [NSMutableArray array];
	
	for (NSDictionary* _item in  items) {
		int __iid = [_item intForKey:@"iid"];
		NSDictionary* _iDict = [itemInfos objectForId:__iid];
		if (_iDict != nil) {
			int __type = [_iDict intForKey:@"type"];
			BOOL isAdd = NO ;
			
			if (_tType == 1) { //材料
				if (__type == Item_material ||
					__type == Item_stone) {
					isAdd = YES ;
				}
			}else if (_tType == 2){//消耗品
				if (__type == Item_expendable ||
					__type == Item_fish_item ||
					__type == Item_fish_food ||
					__type == Item_gift_bag ) {
					isAdd = YES ;
				}
			}else if (_tType == 3){//装备碎片
				if (__type == Item_splinter) {
					isAdd = YES ;
				}
			}
			
			if (isAdd) {
				[array addObject:_item];
			}
		}
	}
	
	return array ;
}

-(int)getTotalPower{
	/*
	NSArray* a2 = [self getRoleWithStatus:RoleStatus_in];
	int _total = 0 ;
	for (NSNumber *number in a2) {
		int _temp = [[powers objectForId:[number intValue]] intValue];
		_total += _temp;
	}
	return _total;
	*/
	
	return totalPower;
}

-(int)getItemCountById:(int)_id
{
	NSDictionary* iDict = [self getItem:_id];
	int iid = [iDict intForKey:@"iid"];
    int count = 0;
	NSArray* _array = [NSArray arrayWithArray:items];
    for (NSDictionary *item in _array) {
        if ([item intForKey:@"iid"] == iid) {
            count += [item intForKey:@"count"];
        }
    }
    return count;
}

-(NSString*)getWeaponName:(int)_rid{
	if (_rid <= 0) return nil ;
	
	NSDictionary* _role = [roleInfos objectForId:_rid];
	
	if (_role == nil) return nil ;
	
	int _aid = [[_role objectForKey:@"armId"] intValue];
	if (_aid <= 0) return nil ;
	
	NSDictionary* _arm = [armInfos objectForId:_aid];
	
	NSString* name = [_arm objectForKey:@"name"];
	
	return name ;
}


-(NSArray*)getRoleCaption:(int)_rid{
	
	NSDictionary* playerDict = [[GameConfigure shared] getPlayerInfo];
	NSDictionary* roleDict = [roleInfos objectForId:_rid];
	
	NSString* s0 = nil ;
	if (_rid < 10)
		s0 = [playerDict objectForKey:@"name"] ;
	else
		s0 = [roleDict objectForKey:@"name"];
	
	NSString* s1 = [NSString stringWithFormat:@"%d",[[playerDict objectForKey:@"level"] intValue]];
	
	int _skill = [[roleDict objectForKey:@"sk2"] intValue];
	NSString* s2 = [[skillInfos objectForId:_skill] objectForKey:@"name"];
	
	int zhanli = [[powers objectForId:_rid] intValue];
	NSString* s3 = [NSString stringWithFormat:@"%d",zhanli] ;
	
	NSString* s4 = [roleDict objectForKey:@"job"];
	NSString* s5 = [roleDict objectForKey:@"office"];
	
	return [NSArray arrayWithObjects:s0,s1,s2,s3,s4,s5,nil];
}

/*
 * _rid 用户表角色ID
 * _ueid 脱下的装备ID
 * _ieid 穿上的装备ID
 */

-(void)doEquipmentAction:(int)_rid off:(int)_ueid input:(int)_ieid{
	
	if (_rid <= 0) return ;
	
	NSMutableDictionary* _role = [NSMutableDictionary dictionaryWithDictionary:[self getRoleById:_rid]];
	
	//处理脱下装备
	if (_ueid > 0) {
		NSMutableDictionary* _equip = [NSMutableDictionary dictionaryWithDictionary:[self getEquipmentById:_ueid]];
		int ___eid  = [_equip intForKey:@"eid"];
		NSDictionary* dbEq = [equipInfos objectForId:___eid];
		
		int ___part = [dbEq intForKey:@"part"];
		NSString* _key = [NSString stringWithFormat:@"eq%d",___part];
		
		[_role setObject:[NSNumber numberWithInt:0] forKey:_key];
		[_equip setObject:[NSNumber numberWithInt:EquipmentStatus_unused] forKey:@"used"];
		[self updateEquipmentByDict:_equip];
		
	}
	
	//处理穿上装备
	if (_ieid > 0) {
		NSMutableDictionary* _equip = [NSMutableDictionary dictionaryWithDictionary:[self getEquipmentById:_ieid]];
		
		int ___eid  = [_equip intForKey:@"eid"];
		NSDictionary* dbEq = [equipInfos objectForId:___eid];
		
		int ___part = [dbEq intForKey:@"part"];
		NSString* _key = [NSString stringWithFormat:@"eq%d",___part];
		
		[_role setObject:[NSNumber numberWithInt:_ieid] forKey:_key];
		[_equip setObject:[NSNumber numberWithInt:EquipmentStatus_used] forKey:@"used"];
		[self updateEquipmentByDict:_equip];
		
	}
	
	[self updateRoleByDict:_role];
}

/*
 * _eid1 - 强化等级 ->  _eid2 - 强化等级
 */
-(void)doEquipmentMoveLevel:(int)_eid1 with:(int)_eid2{
	NSMutableDictionary* e1 = [NSMutableDictionary dictionaryWithDictionary:[self getEquipmentById:_eid1]];
	NSMutableDictionary* e2 = [NSMutableDictionary dictionaryWithDictionary:[self getEquipmentById:_eid2]];
	
	int level1 = [e1 intForKey:@"level"];
	int level2 = [e2 intForKey:@"level"];
	
	//对调等级
	[e1 setObject:[NSNumber numberWithInt:level2] forKey:@"level"];
	[e2 setObject:[NSNumber numberWithInt:level1] forKey:@"level"];
	
	[self updateEquipmentByDict:e1];
	[self updateEquipmentByDict:e2];
	
}

-(int)getTotalPackageAmount{
	int _maxCount = 5 ;
	
	NSDictionary *playerDict = [[GameConfigure shared] getPlayerInfo];
	int playerVip = [[playerDict objectForKey:@"vip"] intValue];
	_maxCount += playerVip;
	
	return _maxCount*12;
}


-(int)getPackageAmount:(int)_type{
	int packageCapacity=0;
	
	ItemManager_show_type _temp = ItemManager_show_type_all;
	
	if (_type == 1) _temp = ItemManager_show_type_all;
	if (_type == 2) _temp = ItemManager_show_type_equipment;
	if (_type == 3) _temp = ItemManager_show_type_expendable;
	if (_type == 4) _temp = ItemManager_show_type_fate;
	if (_type == 5) _temp = ItemManager_show_type_fodder;
	if (_type == 6) _temp = ItemManager_show_type_jewel;
	
	if (_temp == ItemManager_show_type_all) {
		return [self getPackageAmount];
	}
	
	if (_temp == ItemManager_show_type_equipment) {
		NSArray* _array = [NSArray arrayWithArray:equips];
		for (NSDictionary* dict in _array) {
			if ([dict intForKey:@"used"] == EquipmentStatus_unused) {
				packageCapacity++;
			}
		}
		//装备碎片
		NSArray * splinters = [NSArray arrayWithArray:items];
		for(NSDictionary * item in splinters){
			int iid = [[item objectForKey:@"iid"] intValue];
			NSDictionary * itemInfo = [itemInfos objectForId:iid];
			int itemType = [[itemInfo objectForKey:@"type"] intValue];
			if(itemType==Item_splinter){
				packageCapacity += 1;
			}
		}
		return packageCapacity;
	}
	
	if (_temp == ItemManager_show_type_expendable) {
		int totalCount = 0;
		NSArray * _array = [NSArray arrayWithArray:items];
		for(NSDictionary * item in _array){
			int iid = [[item objectForKey:@"iid"] intValue];
			NSDictionary * itemInfo = [itemInfos objectForId:iid];
			int itemType = [[itemInfo objectForKey:@"type"] intValue];
			if(itemType==Item_expendable || 
			   itemType==Item_fish_item || 
			   itemType==Item_fish_food ||
			   itemType==Item_gift_bag){
				totalCount += 1;
			}
		}
		return totalCount;
	}
	
	
	if (_temp == ItemManager_show_type_fate) {
		NSArray* _array = [NSArray arrayWithArray:fates];
		
		for (NSDictionary* dict in _array) {
			if ([dict intForKey:@"used"] == FateStatus_unused) {
				packageCapacity++;
			}
		}
		
		return packageCapacity;
	}
	
	if(_temp == ItemManager_show_type_fodder){
		int totalCount = 0;
		NSArray * _array = [NSArray arrayWithArray:items];
		for(NSDictionary * item in _array){
			int iid = [[item objectForKey:@"iid"] intValue];
			NSDictionary * itemInfo = [itemInfos objectForId:iid];
			int itemType = [[itemInfo objectForKey:@"type"] intValue];
			if(itemType==Item_material ||
			   itemType==Item_symbol ||
			   itemType==Item_stone
			   ){
				totalCount += 1;
			}
		}
		return totalCount;
	}

	if(_temp == ItemManager_show_type_jewel){
		NSArray* _array = [NSArray arrayWithArray:jewels];
		
		for (NSDictionary* dict in _array) {
			if ([dict intForKey:@"used"] == JewelStatus_unused) {
				packageCapacity++;
			}
		}
		
		return packageCapacity;
	}
	
	return packageCapacity;
}

-(int)getPackageAmount{
	
	
	int packageCapacity=0;
	
	NSArray* _array1 = [NSArray arrayWithArray:equips];
	for (NSDictionary* dict in _array1) {
		if ([dict intForKey:@"used"] == EquipmentStatus_unused) {
			packageCapacity++;
		}
	}
	
	NSArray* _array2 = [NSArray arrayWithArray:fates];
	for (NSDictionary* dict in _array2) {
		if ([dict intForKey:@"used"] == FateStatus_unused) {
			packageCapacity++;
		}
	}
	
	NSArray* _array3 = [NSArray arrayWithArray:jewels];
	for (NSDictionary* dict in _array3) {
		if ([dict intForKey:@"used"] == JewelStatus_unused) {
			packageCapacity++;
		}
	}
	
	packageCapacity += items.count;
	
	return packageCapacity;
	
}

-(void)updateDataByBatchEnd{
	NSArray *_buff1 = [batchs objectForKey:@"equip"];
	NSArray *_buff2 = [batchs objectForKey:@"fate"];
	NSArray *_buff3 = [batchs objectForKey:@"item"];
	NSArray *_buff4 = [batchs objectForKey:@"gem"];
    
	if (_buff1 != nil) {
		for (NSNumber *_number in _buff1) {
			NSDictionary* _edict = [self getEquipmentById:[_number intValue]];
			if (_edict != nil) {
				[equips removeObject:_edict];
			
			}
		}
	}
	
	if (_buff2 != nil) {
		for (NSNumber *_number in _buff2) {
			NSDictionary* _edict = [self getFate:[_number intValue]];
			if (_edict != nil) {
				[fates removeObject:_edict];
			}
		}
	}
	
	if (_buff3 != nil) {
		for (NSNumber *_number in _buff3) {
			NSDictionary* _edict = [self getItem:[_number intValue]];
			if (_edict != nil) {
				[items removeObject:_edict];
			}
		}
	}
    if (_buff4 != nil) {
		for (NSNumber *_number in _buff4) {
			NSDictionary* _edict = [self getJewelBy:[_number intValue]];
			if (_edict != nil) {
				[jewels removeObject:_edict];
			}
		}
	}
	[batchs removeAllObjects];
}

-(int)checkBatchSell{
	
	NSArray *_buff1 = [batchs objectForKey:@"equip"];
	NSArray *_buff2 = [batchs objectForKey:@"fate"];
	NSArray *_buff3 = [batchs objectForKey:@"item"];
	NSArray *_buff4 = [batchs objectForKey:@"gem"];

	int _total = 0 ;
	
	if (_buff1 != nil && _buff1.count > 0) {
		_total += _buff1.count;
	}
	
	if (_buff2 != nil && _buff2.count > 0) {
		_total += _buff2.count;
	}
	
	if (_buff3 != nil && _buff3.count > 0) {
		_total += _buff3.count;
	}
    
    if (_buff4 != nil && _buff4.count > 0) {
		_total += _buff4.count;
	}
    
	return _total;
}

-(void)cleanupBatchData{
	if (batchs != nil) {
		[batchs removeAllObjects];
	}
}

-(void)addBatchItem:(int)_id type:(int)_bType{
	if (_bType == ItemTray_armor) {
		//装备
		NSArray *_buff = [batchs objectForKey:@"equip"];
		if (_buff == nil) {
			_buff = [NSArray array];
		}
		
		NSMutableArray* array = [NSMutableArray arrayWithArray:_buff];
		
		NSNumber *_number = [NSNumber numberWithInt:_id];
		
		if (![array containsObject:_number]) {
			[array addObject:_number];
		}else{
			CCLOG(@"addBatchItem error!!!! %d -> type=%d",_id,_bType);
		}
		
		[batchs setObject:array forKey:@"equip"];
		
	}
	
	if (_bType == ItemTray_fate) {
		//命格
		NSArray *_buff = [batchs objectForKey:@"fate"];
		if (_buff == nil) {
			_buff = [NSArray array];
		}
		
		NSMutableArray* array = [NSMutableArray arrayWithArray:_buff];
		
		NSNumber *_number = [NSNumber numberWithInt:_id];
		
		if (![array containsObject:_number]) {
			[array addObject:_number];
		}else{
			CCLOG(@"addBatchItem error!!!! %d -> type=%d",_id,_bType);
		}
		
		[batchs setObject:array forKey:@"fate"];
		
	}
	
	if (_bType == ItemTray_item ||
        _bType == ItemTray_item_armor ||
        _bType == ItemTray_item_stone) {
		//物品 (消耗品和材料)
		NSArray *_buff = [batchs objectForKey:@"item"];
		if (_buff == nil) {
			_buff = [NSArray array];
		}
		
		NSMutableArray* array = [NSMutableArray arrayWithArray:_buff];
		
		NSNumber *_number = [NSNumber numberWithInt:_id];
		
		if (![array containsObject:_number]) {
			[array addObject:_number];
		}else{
			CCLOG(@"addBatchItem error!!!! %d -> type=%d",_id,_bType);
		}
		
		[batchs setObject:array forKey:@"item"];
		
	}
	if (_bType == ItemTray_item_jewel) {
        //珠宝
		NSArray *_buff = [batchs objectForKey:@"gem"];
		if (_buff == nil) {
			_buff = [NSArray array];
		}
		
		NSMutableArray* array = [NSMutableArray arrayWithArray:_buff];
		
		NSNumber *_number = [NSNumber numberWithInt:_id];
		
		if (![array containsObject:_number]) {
			[array addObject:_number];
		}else{
			CCLOG(@"addBatchItem error!!!! %d -> type=%d",_id,_bType);
		}
		
		[batchs setObject:array forKey:@"gem"];
    }
}

-(void)deleteBatchItem:(int)_id type:(int)_bType{
	if (_id <= 0 || _bType <= 0) {
		CCLOG(@"deleteBatchItem error!!");
		return ;
	}
	
	if (_bType == ItemTray_armor) {
		//装备
		NSArray *_buff = [batchs objectForKey:@"equip"];
		if (_buff == nil) {
			_buff = [NSArray array];
		}
		
		NSMutableArray* array = [NSMutableArray arrayWithArray:_buff];
		
		NSNumber *_number = [NSNumber numberWithInt:_id];
		
		[array removeObject:_number];
		
		[batchs setObject:array forKey:@"equip"];
		
	}
	
	if (_bType == ItemTray_fate) {
		//命格
		NSArray *_buff = [batchs objectForKey:@"fate"];
		if (_buff == nil) {
			_buff = [NSArray array];
		}
		
		NSMutableArray* array = [NSMutableArray arrayWithArray:_buff];
		
		NSNumber *_number = [NSNumber numberWithInt:_id];
		
		[array removeObject:_number];
		
		[batchs setObject:array forKey:@"fate"];
		
	}
	
	if (_bType == ItemTray_item ||
        _bType == ItemTray_item_armor ||
        _bType == ItemTray_item_stone) {
		
		NSArray *_buff = [batchs objectForKey:@"item"];
		if (_buff == nil) {
			_buff = [NSArray array];
		}
		
		NSMutableArray* array = [NSMutableArray arrayWithArray:_buff];
		
		NSNumber *_number = [NSNumber numberWithInt:_id];
		
		[array removeObject:_number];
		
		[batchs setObject:array forKey:@"item"];
	}
    
	if (_bType == ItemTray_item_jewel) {
		
		NSArray *_buff = [batchs objectForKey:@"gem"];
		if (_buff == nil) {
			_buff = [NSArray array];
		}
		
		NSMutableArray* array = [NSMutableArray arrayWithArray:_buff];
		
		NSNumber *_number = [NSNumber numberWithInt:_id];
		
		[array removeObject:_number];
		
		[batchs setObject:array forKey:@"gem"];
	}
}

-(NSDictionary*)getDBEquipment:(int)_id{
	NSDictionary* eDict = [equipInfos objectForId:_id];
	if (eDict == nil) {
		eDict = [[GameDB shared] getEquipmentInfo:_id];
		[equipInfos setObject:eDict forKey:[NSString stringWithFormat:@"%d",_id]];
	}
	return eDict ;
}

-(void)addEquipmentWithData:(NSDictionary *)_dict{
	if (_dict == nil) {
		return ;
	}
	
	NSDictionary* dict = [NSDictionary dictionaryWithDictionary:_dict];
	[equips addObject:dict];
	int eid = [dict intForKey:@"eid"];
	
	NSDictionary* eDict = [[GameDB shared] getEquipmentInfo:eid];
	NSString* _key = [NSString stringWithFormat:@"%d",eid];
	[equipInfos setObject:eDict forKey:_key];
	
	int sid = [eDict intForKey:@"sid"];
	
	NSDictionary* sDict = [[GameDB shared] getEquipmentSetInfo:sid];
	_key = [NSString stringWithFormat:@"%d",sid];
	[equipSetInfos setObject:sDict forKey:_key];
	
}

-(void)removeItemsWithArray:(NSArray *)_array{
	if (_array == nil) {
		return ;
	}
	
	for (NSNumber *_number in _array) {
		NSDictionary* _edict = [self getItem:[_number intValue]];
		if (_edict != nil) {
			[items removeObject:_edict];
		}
	}
}

-(BOOL)checkCanUseItem:(int)_id{
	int l1 = [[GameConfigure shared] getPlayerLevel];
	int l2 = [self getItemUseLevel:_id];
	
	return (l1 >= l2);
}

-(int)getItemType:(int)_id{
	NSDictionary* dict = [self getItem:_id];
	if (dict != nil) {
		int iid = [dict intForKey:@"iid"];
		if (iid > 0) {
			NSDictionary* iDict = [itemInfos objectForId:iid];
			int type = [iDict intForKey:@"type"];
			return type;
		}
	}
	return 0;
}

-(int)getItemUseLevel:(int)_id{
	NSDictionary* dict = [self getItem:_id];
	if (dict != nil) {
		int iid = [dict intForKey:@"iid"];
		if (iid > 0) {
			NSDictionary* iDict = [itemInfos objectForId:iid];
			int _level = [iDict intForKey:@"lv"];
			return _level;
		}
	}
	return 0;
}

-(void)updateItemsWithArray:(NSArray *)_array
{
	if (_array == nil) {
		return;
	}
	for (NSDictionary *dict in _array) {
		int _id = [dict intForKey:@"id"];
		NSDictionary *_dict = [self getItem:_id];
		if (_dict != nil) {
			int index = [items indexOfObject:_dict];
			NSDictionary *newDict = [NSDictionary dictionaryWithDictionary:dict];
			[items replaceObjectAtIndex:index withObject:newDict];
		}
	}
}

-(NSDictionary*)getRoleSuit:(int)_rid{
	NSMutableDictionary* rDict = [NSMutableDictionary dictionary];
	if (_rid <= 0) return rDict;
	
	
	NSDictionary *userRole = [self getRole:_rid];
	
	for (int i = 1; i <= 6; i++) {
		
		NSString *_key = [NSString stringWithFormat:@"eq%d",i];
		
		int reid = [userRole intForKey:_key];
		
		NSDictionary *req = [self getEquipmentById:reid];
		
		int eid = [req intForKey:@"eid"];
		
		NSDictionary *eq = [equipInfos objectForId:eid];
		
		int sid = [eq intForKey:@"sid"];
		
		int num = [rDict intForKey:[NSString stringWithFormat:@"%d",sid]];
		
		if (num <= 0) {
			[rDict setObject:[NSNumber numberWithInt:1] forKey:[NSString stringWithFormat:@"%d",sid]];
		}else{
			num += 1;
			[rDict setObject:[NSNumber numberWithInt:num] forKey:[NSString stringWithFormat:@"%d",sid]];
		}
		
	}
	
	return rDict;
}

-(NSString*)getInfoWithString:(NSString*)_string
{
	if (!_string) return @"";
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	NSArray *_array = [_string componentsSeparatedByString:@"|"];
	for (NSString *__string in _array) {
		NSArray *__array = [__string componentsSeparatedByString:@":"];
		if (__array.count >= 2) {
			NSString *__key = [__array objectAtIndex:0];
			NSString *__value = [__array objectAtIndex:1];
			
			[dict setObject:__value forKey:__key];
		}
	}
	
	BaseAttribute attr = BaseAttributeFromDict(dict);
	NSString *string = BaseAttributeToDisplayStringWithOutZero(attr);
	
	string = [string stringByReplacingOccurrencesOfString:@"|" withString:@" "];
	string = [string stringByReplacingOccurrencesOfString:@":" withString:@"+"];
	
	return string;
}

-(NSString*)getEquipDescribe:(int)_id role:(int)_rid{
	if (_id <= 0 ) {
		return nil;
	}
	
	NSDictionary *_dict = [self getEquipmentById:_id];
	
	int eid = [_dict intForKey:@"eid"];
	
	int e_level = [_dict intForKey:@"level"];
	
	NSDictionary *equip = [equipInfos objectForId:eid];
	
	int e_sid = [equip intForKey:@"sid"];
	
	NSDictionary *eset = [equipSetInfos objectForId:e_sid];
	
	int qa=[eset intForKey:@"quality"];
	
	NSString *name = [equip objectForKey:@"name"];
	
	name = [NSString stringWithFormat:@"^1*%@",name];
	
	NSString *cmd = [name stringByAppendingFormat:@"#%@#20#0*",getQualityColorStr(qa)];
	
	//cmd = [NSString stringWithFormat:@"^2*%@",cmd];
	
	cmd = [cmd stringByAppendingFormat:@"^4*"];
	
	int trade_value = [[_dict objectForKey:@"isTrade"] intValue];
	
	if (trade_value == TradeStatus_yes) {
		//cmd = [cmd stringByAppendingFormat:@"可以交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"player_data_helper_trade",nil)];
	}
	else {
		//cmd = [cmd stringByAppendingFormat:@"不可交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"player_data_helper_no_trade",nil)];
	}
	
	int limit = [[equip objectForKey:@"limit"] intValue];
	//NSString *str_limit = [NSString stringWithFormat:@"使用等级: %d",limit];
    NSString *str_limit = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_use_level",nil),limit];
	cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",str_limit];
	cmd = [cmd stringByAppendingFormat:@"^4*"];
	
	int _part = [[equip objectForKey:@"part"] intValue];
	
	//NSString *str_part = [NSString stringWithFormat:@"装备类型: %@",getPartName(_part)];
	NSString *str_part = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_equip_type",nil),getPartName(_part)];
    
	cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",str_part];
	//---------------------------------------------------------------
	if (equip) {
		cmd = [cmd stringByAppendingString:getAttrDescribetionWithDict(equip)];
	}
	
	//-------------------------------
	/*
	for (int i = 0; i < 21; i++) {
		//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
        NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
		float _value = [[equip objectForKey:[args objectAtIndex:0]] floatValue];
		if (_value > 0 ) {
			NSString *str_temp = [NSString stringWithFormat:@"%@ #eeeeee#16#0",[args objectAtIndex:1]];
			if (args.count == 3) {
				str_temp = [str_temp stringByAppendingFormat:@"|+%.1f%@#00ee00#16#0*",_value,@"%"];
			}
			else {
				str_temp = [str_temp stringByAppendingFormat:@"|+%.0f#00ee00#16#0*",_value];
			}
			cmd = [cmd stringByAppendingFormat:@"%@",str_temp];
		}
	}
	 */
	
	//--------------------------------
	
	if (e_level > 0	) {
		//这里暂时先读 IO
		NSDictionary *dict_lv = [[GameDB shared] getEquipmentLevelInfo:_part level:e_level];
		if (dict_lv) {
			BaseAttribute attr = BaseAttributeFromDict(dict_lv);
			NSString *string = BaseAttributeToDisplayStringWithOutZero(attr);
			
			NSArray *array = [string componentsSeparatedByString:@"|"];
			for (NSString *_string in array) {
				NSArray *_array = [_string componentsSeparatedByString:@":"];
				if (_array.count >= 2) {
					NSString *_name = [_array objectAtIndex:0];
					NSString *_addValue = [_array objectAtIndex:1];
					
					NSString *str_temp = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_upgrade_2",nil),e_level,_name,_addValue];
					cmd = [cmd stringByAppendingFormat:@"%@",str_temp];
				}
			}
		}
		
		/*
		for (int i = 0; i < 21; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			float _value = [[dict_lv objectForKey:[args objectAtIndex:0]] floatValue];
			CCLOG(@"%@ | %.1f",[args objectAtIndex:1],_value);
			if (_value > 0 ) {
				//NSString *str_temp = [NSString stringWithFormat:@"%d级强化:%@ +%.0f#00ff00#16#0*",e_level,[args objectAtIndex:1],_value];
                NSString *str_temp = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_upgrade",nil),e_level,[args objectAtIndex:1],_value];
				cmd = [cmd stringByAppendingFormat:@"%@",str_temp];
			}
		}*/
	}
	
	NSDictionary *gem = [_dict objectForKey:@"gem"];
	if (gem) {
		BaseAttribute attribute = BaseAttributeZero();
		NSArray* jewelIds = [gem allValues];
		for (NSNumber* number in jewelIds){
			NSDictionary* jewel = [self getJewelBy:[number intValue]];
			if (jewel) {
				int gid = [jewel intForKey:@"gid"];
				int level = [jewel intForKey:@"level"];
				NSDictionary* dict = [[GameDB shared] getJewelLevelInfoWithLevel:gid level:level];
				BaseAttribute r1 = BaseAttributeFromDict(dict);
				BaseAttribute r2 = BaseAttributePercentFromDict(dict);
				r2 = BaseAttributeFromPercent(attribute, r2);
				r2 = BaseAttributeAdd(r1, r2);
				attribute = BaseAttributeAdd(attribute, r2);
			}
		}
		NSString *jewelString = BaseAttributeToDisplayStringWithOutZero(attribute);
		if (![jewelString isEqualToString:@""]) {
			cmd = [cmd stringByAppendingFormat:@"^10*"];
			cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",NSLocalizedString(@"player_data_helper_jewel",nil)];
			
			NSArray *_array = [jewelString componentsSeparatedByString:@"|"];
			for (int i = 0; i < _array.count; ) {
				NSString *_s1 = [_array objectAtIndex:i];
				NSArray *_a1 = [_s1 componentsSeparatedByString:@":"];
				if ((i+1)<_array.count) {
					NSString *_s2 = [_array objectAtIndex:i+1];
					NSArray *_a2 = [_s2 componentsSeparatedByString:@":"];
					
					if (_a1.count >= 2 && _a2.count >= 2) {
						cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0|+%@#00ee00#16#0| |%@#eeeeee#16#0|+%@#00ee00#16#0*",
							   [_a1 objectAtIndex:0],
							   [_a1 objectAtIndex:1],
							   [_a2 objectAtIndex:0],
							   [_a2 objectAtIndex:1]];
					}
					i += 2;
				} else {
					if (_a1.count >=2) {
						cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0|+%@#00ee00#16#0*", [_a1 objectAtIndex:0], [_a1 objectAtIndex:1]];
					}
					break;
				}
			}
		}
	}
	
	if (_rid > 0) {
		//---------------------------------
		cmd = [cmd stringByAppendingFormat:@"^10*"];
		//空
		
		NSString *_info2 = [eset objectForKey:@"effect2"];
		_info2 = [self getInfoWithString:_info2];
		/*
		_info2 = [_info2 stringByReplacingOccurrencesOfString:@"|" withString:@" "];
		_info2 = [_info2 stringByReplacingOccurrencesOfString:@":" withString:@"+"];
		for (int i = 0; i < 21; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			_info2 = [_info2 stringByReplacingOccurrencesOfString:[args objectAtIndex:0] withString:[args objectAtIndex:1]];
		}
		 */
		NSString *_info4 = [eset objectForKey:@"effect4"];
		_info4 = [self getInfoWithString:_info4];
		/*
		_info4 = [_info4 stringByReplacingOccurrencesOfString:@"|" withString:@" "];
		_info4 = [_info4 stringByReplacingOccurrencesOfString:@":" withString:@"+"];
		for (int i = 0; i < 21; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			_info4 = [_info4 stringByReplacingOccurrencesOfString:[args objectAtIndex:0] withString:[args objectAtIndex:1]];
		}
		 */
		NSString *_info6 = [eset objectForKey:@"effect6"];
		_info6 = [self getInfoWithString:_info6];
		/*
		_info6 = [_info6 stringByReplacingOccurrencesOfString:@"|" withString:@" "];
		_info6 = [_info6 stringByReplacingOccurrencesOfString:@":" withString:@"+"];
		for (int i = 0; i < 21; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			_info6 = [_info6 stringByReplacingOccurrencesOfString:[args objectAtIndex:0] withString:[args objectAtIndex:1]];
		}
		*/
		NSDictionary *setInfo = [self getRoleSuit:_rid];
		
		int num = [[setInfo objectForKey:[NSString stringWithFormat:@"%d",e_sid]] intValue];
		
		//NSString *str_setInfo = [NSString stringWithFormat:@"套装属性(%d/6)#888888#14#0*",num];
        NSString *str_setInfo = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_set_info_1",nil),num];
		
		if (num >= 2) {
			str_setInfo = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_set_info_2",nil),num];
		}
		cmd = [cmd stringByAppendingFormat:@"%@",str_setInfo];
		
		if (num >= 6) {
//			_info2 = [NSString stringWithFormat:@"2件:%@#ffffff#14#0*",_info2];
//			_info4 = [NSString stringWithFormat:@"4件:%@#ffffff#14#0*",_info4];
//			_info6 = [NSString stringWithFormat:@"6件:%@#ffffff#14#0*",_info6];
            _info2 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"player_data_helper_two_set",nil),_info2];
			_info4 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"player_data_helper_four_set",nil),_info4];
			_info6 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"player_data_helper_six_set",nil),_info6];
		}else if(num >= 4){
//			_info2 = [NSString stringWithFormat:@"2件:%@#ffffff#14#0*",_info2];
//			_info4 = [NSString stringWithFormat:@"4件:%@#ffffff#14#0*",_info4];
//			_info6 = [NSString stringWithFormat:@"6件:%@#888888#14#0*",_info6];
            _info2 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"player_data_helper_two_set",nil),_info2];
			_info4 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"player_data_helper_four_set",nil),_info4];
			_info6 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"player_data_helper_six_set",nil),_info6];
		}else if(num >= 2){
//			_info2 = [NSString stringWithFormat:@"2件:%@#ffffff#14#0*",_info2];
//			_info4 = [NSString stringWithFormat:@"4件:%@#888888#14#0*",_info4];
//			_info6 = [NSString stringWithFormat:@"6件:%@#888888#14#0*",_info6];
            _info2 = [NSString stringWithFormat:@"%@%@#ffffff#14#0*",NSLocalizedString(@"player_data_helper_two_set",nil),_info2];
			_info4 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"player_data_helper_four_set",nil),_info4];
			_info6 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"player_data_helper_six_set",nil),_info6];
		}else {
//			_info2 = [NSString stringWithFormat:@"2件:%@#888888#14#0*",_info2];
//			_info4 = [NSString stringWithFormat:@"4件:%@#888888#14#0*",_info4];
//			_info6 = [NSString stringWithFormat:@"6件:%@#888888#14#0*",_info6];
            _info2 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"player_data_helper_two_set",nil),_info2];
			_info4 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"player_data_helper_four_set",nil),_info4];
			_info6 = [NSString stringWithFormat:@"%@%@#888888#14#0*",NSLocalizedString(@"player_data_helper_six_set",nil),_info6];
		}
		
		cmd = [cmd stringByAppendingFormat:@"%@",_info2];
		cmd = [cmd stringByAppendingFormat:@"%@",_info4];
		cmd = [cmd stringByAppendingFormat:@"%@",_info6];

	}
		
	int price = [[equip objectForKey:@"price"] intValue];
	//NSString *str_price = [NSString stringWithFormat:@"可出售: %d#ffff00#16#0*",price];
    NSString *str_price = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_can_sale",nil),price];
	cmd = [cmd stringByAppendingFormat:@"^4*"];
	
	cmd = [cmd stringByAppendingFormat:@"%@",str_price];
	cmd = [cmd stringByAppendingFormat:@"^4*"];
	//---------------------------------------------------------------\
    
    
////    //todo
    if (iPhoneRuningOnGame()) {
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#14#" withString:@"#16#"];
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#16#" withString:@"#18#"];
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#20#" withString:@"#22#"];

    }
    return cmd;
	
}

-(NSString*)getJewelDescribe:(int)_gid{
	NSDictionary *_dict = [self getJewelBy:_gid];
	if (!_dict) {
		return nil;
	}
	
	int gid = [[_dict objectForKey:@"gid"] intValue];
	int g_level = [[_dict objectForKey:@"level"] intValue] ;
	
	if (gid <= 0 || g_level > 10) {
		return nil;
	}
	
	NSDictionary *jewelDict = [jewelInfos objectForId:gid];
	
	if (!jewelDict) {
		return nil;
	}
	
	int qu = [[jewelDict objectForKey:@"quality"] intValue];
	
    NSString *name = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_level",nil),
					  [jewelDict objectForKey:@"name"],g_level];
	
	NSString *cmd = [name stringByAppendingFormat:@"#%@#20#0*",getQualityColorStr(qu)];
	cmd = [cmd stringByAppendingFormat:@"^4*"];
	
	int trade_value = [[_dict objectForKey:@"isTrade"] intValue];
	if (trade_value == TradeStatus_yes) {
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"player_data_helper_trade",nil)];
	}
	else {
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"player_data_helper_no_trade",nil)];
	}
	
	cmd = [cmd stringByAppendingFormat:@"%@*",NSLocalizedString(@"player_data_helper_parts",nil)];
	
	NSString* partInfo = [jewelDict objectForKey:@"parts"];
	if (partInfo) {
		NSArray* partAry = [partInfo componentsSeparatedByString:@"|"];
		NSString* partResult = [NSString stringWithFormat:@""];
		for (NSNumber *number in partAry) {
			int pInt = [number intValue];
			NSString* _strTemp = getPartName(pInt);
			if (_strTemp) {
				partResult = [partResult stringByAppendingFormat:@"%@,",_strTemp];
			}
		}
		
		if (partResult.length > 0) {
			partResult = [partResult substringToIndex:[partResult length] - 1];
			cmd = [cmd stringByAppendingFormat:@"%@*",partResult];
		}
	}
	
	float upSucc = [[_dict objectForKey:@"upSucc"] floatValue];
	if (upSucc > 0) {
		cmd = [cmd stringByAppendingFormat:@"^4*"];
		cmd = [cmd stringByAppendingFormat:@"%@%.0f%%#00ee00#16#0*",[NSString stringWithFormat:NSLocalizedString(@"player_data_helper_success",nil)], upSucc];
	}
				
	NSString *t_str = nil;
				
	NSArray* _farray = [NSArray arrayWithObjects:[NSNumber numberWithInt:g_level],
						[NSNumber numberWithInt:g_level+1],nil];
	
	NSDictionary* _fDict = [[GameDB shared] getJewelLevelInfoWithLevels:gid level:_farray];
	
	NSDictionary *nowJewelLevelDict = [_fDict objectForKey:[NSString stringWithFormat:@"%d",g_level]];
	t_str = getAttrDescribetionWithDict(nowJewelLevelDict);
	
	if (t_str.length > 0) {
		cmd = [cmd stringByAppendingFormat:@"^4*"];
		cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:NSLocalizedString(@"player_data_helper_effect",nil)]];
		cmd = [cmd stringByAppendingFormat:@"%@",t_str];
	}
	
//	t_str = [NSString stringWithFormat:@""];
	
	NSDictionary *nextJewelLevelDict = [_fDict objectForKey:[NSString stringWithFormat:@"%d",g_level+1]];
	t_str = getAttrDescribetionWithDict(nextJewelLevelDict);
	
	if (t_str.length > 0) {
		cmd = [cmd stringByAppendingFormat:@"^5*"];
        cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",
			   [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_next_effect",nil)]];
		cmd = [cmd stringByAppendingFormat:@"%@",t_str];
	}
	
	int price = [[jewelDict objectForKey:@"price"] intValue];
    NSString *str_price = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_can_sale",nil),price];
	cmd = [cmd stringByAppendingFormat:@"^8*"];
	cmd = [cmd stringByAppendingFormat:@"%@",str_price];
	
	//---------------------------------------------------------------
	cmd = [cmd stringByAppendingFormat:@"^4*"];
	
    if (iPhoneRuningOnGame()) {
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#14#" withString:@"#16#"];
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#16#" withString:@"#18#"];
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#20#" withString:@"#22#"];
    }
	return cmd;
}

-(NSString*)getItemDescribe:(int)_iid{
	NSDictionary *_dict = [self getItem:_iid];
	if (!_dict) {
		CCLOG(@"message box item dict is nil");
		return nil;
	}
	
	int iid = [[_dict objectForKey:@"iid"] intValue];
	
	NSDictionary *itemDict = [itemInfos objectForId:iid];
	
	if (!itemDict) {
		CCLOG(@"message box itemDict dict is nil");
		return nil;
	}
	
	int qu=[[itemDict objectForKey:@"quality"] intValue];
	
	NSString *name = [NSString stringWithFormat:@"^2*%@",[itemDict objectForKey:@"name"]];
	
	NSString *cmd = [name stringByAppendingFormat:@"#%@#20#0*",getQualityColorStr(qu)];
	
	cmd = [cmd stringByAppendingFormat:@"^8*"];
	
	int trade_value = [[_dict objectForKey:@"isTrade"] intValue];
	
    if (trade_value == TradeStatus_yes) {
		//cmd = [cmd stringByAppendingFormat:@"可以交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"player_data_helper_trade",nil)];
	}
	else {
		//cmd = [cmd stringByAppendingFormat:@"不可交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"player_data_helper_no_trade",nil)];
	}
	////
	cmd = [cmd stringByAppendingFormat:@"^5*"];
	//cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:@"效果:"]];
    cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:NSLocalizedString(@"player_data_helper_effect",nil)]];
	cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[itemDict objectForKey:@"info"] ];
	////
	cmd = [cmd stringByAppendingFormat:@"^5*"];
	int price = [[itemDict objectForKey:@"price"] intValue];
	
	if (price > 0) {
		//NSString *str_price = [NSString stringWithFormat:@"可出售: %d银币#ffff00#16#0*",price];
        NSString *str_price = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_can_sale",nil),price];
		cmd = [cmd stringByAppendingFormat:@"^5*"];
		cmd = [cmd stringByAppendingFormat:@"%@",str_price];
		//---------------------------------------------------------------
		
		cmd = [cmd stringByAppendingFormat:@"^5*"];
	}
    
    if (iPhoneRuningOnGame()) {
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#14#" withString:@"#16#"];
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#16#" withString:@"#18#"];
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#20#" withString:@"#22#"];
    }
	return cmd;
}


-(void)updateALL:(NSDictionary *)_dict{
	if (_dict) {
		
		NSArray *keys = [_dict allKeys];
		
		if (YES) {
			NSMutableDictionary *eDicts = [NSMutableDictionary dictionary];
			
			for (NSDictionary *iterate in equips) {
				
				int _id = [iterate intForKey:@"id"];
				NSString *_key = [NSString stringWithFormat:@"%d",_id];
				[eDicts setObject:iterate forKey:_key];
				
			}
			
			NSMutableDictionary *iDicts = [NSMutableDictionary dictionary];
			
			for (NSDictionary *iterate in items) {
				int _id = [iterate intForKey:@"id"];
				NSString *_key = [NSString stringWithFormat:@"%d",_id];
				[iDicts setObject:iterate forKey:_key];
			}
			
			NSMutableDictionary *fDicts = [NSMutableDictionary dictionary];
			
			for (NSDictionary *iterate in fates) {
				int _id = [iterate intForKey:@"id"];
				NSString *_key = [NSString stringWithFormat:@"%d",_id];
				[fDicts setObject:iterate forKey:_key];
			}
            //
            NSMutableDictionary *gDicts = [NSMutableDictionary dictionary];
			
			for (NSDictionary *iterate in jewels) {
				int _id = [iterate intForKey:@"id"];
				NSString *_key = [NSString stringWithFormat:@"%d",_id];
				[gDicts setObject:iterate forKey:_key];
			}
			
			if ([keys containsObject:@"equip"]) {
				NSArray *array = [_dict objectForKey:@"equip"];
				for (NSDictionary *iterate in array) {
					int _id = [iterate intForKey:@"id"];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[eDicts setObject:iterate forKey:_key];
				}
			}
			
			if ([keys containsObject:@"item"]) {
				NSArray *array = [_dict objectForKey:@"item"];
				for (NSDictionary *iterate in array) {
					int _id = [iterate intForKey:@"id"];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[iDicts setObject:iterate forKey:_key];
				}
			}
			
			if ([keys containsObject:@"fate"]) {
				NSArray *array = [_dict objectForKey:@"fate"];
				for (NSDictionary *iterate in array) {
					int _id = [iterate intForKey:@"id"];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[fDicts setObject:iterate forKey:_key];
				}
			}
            //
			if ([keys containsObject:@"gem"]) {
				NSArray *array = [_dict objectForKey:@"gem"];
				for (NSDictionary *iterate in array) {
					int _id = [iterate intForKey:@"id"];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[gDicts setObject:iterate forKey:_key];
				}
			}
            
			if ([keys containsObject:@"delIids"]) {
				
				NSArray *array = [_dict objectForKey:@"delIids"];
				for (NSNumber *number in array) {
					int _id = [number intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[iDicts removeObjectForKey:_key];
				}
				
			}
			
			if ([keys containsObject:@"delEids"]) {
				
				NSArray *array = [_dict objectForKey:@"delEids"];
				for (NSNumber *number in array) {
					int _id = [number intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[eDicts removeObjectForKey:_key];
				}
				
			}
			
			if ([keys containsObject:@"delFids"]) {
				
				NSArray *array = [_dict objectForKey:@"delFids"];
				for (NSNumber *number in array) {
					int _id = [number intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[fDicts removeObjectForKey:_key];
				}
				
			}
			//
            if ([keys containsObject:@"delGids"]) {
				
				NSArray *array = [_dict objectForKey:@"delGids"];
				for (NSNumber *number in array) {
					int _id = [number intValue];
					NSString *_key = [NSString stringWithFormat:@"%d",_id];
					[gDicts removeObjectForKey:_key];
				}
				
			}
            
			[items removeAllObjects];
			[items addObjectsFromArray:[iDicts allValues]];
			
			[fates removeAllObjects];
			[fates addObjectsFromArray:[fDicts allValues]];
			
			[equips removeAllObjects];
			[equips addObjectsFromArray:[eDicts allValues]];
            //
            [jewels removeAllObjects];
			[jewels addObjectsFromArray:[eDicts allValues]];
			
			NSArray *iArray = [_dict objectForKey:@"item"];
			if (iArray != nil && iArray.count > 0) {
				NSDictionary* idict = [[GameDB shared] getItemInfoByIds:getArrayListDataByKey(iArray,@"iid")];
				NSArray* keys = [idict allKeys];
				for (NSString *key in keys) {
					NSDictionary* temp = [NSDictionary dictionaryWithDictionary:[idict objectForKey:key]];
					[itemInfos setObject:temp forKey:key];
				}
			}
			
			NSArray *eArray = [_dict objectForKey:@"equip"];
			if (eArray != nil && eArray.count > 0) {
				NSDictionary* edict = [[GameDB shared] getEquipmentInfoByIds:getArrayListDataByKey(eArray,@"eid")];
				NSArray* ekeys = [edict allKeys];
				
				for (NSString *key in ekeys) {
					NSDictionary* temp = [NSDictionary dictionaryWithDictionary:[edict objectForKey:key]];
					[equipInfos setObject:temp forKey:key];
				}
				
				NSDictionary* sdict = [[GameDB shared] getEquipmentSetInfoByIds:getArrayListDataByKey(edict,@"sid")];
				
				NSArray* skeys = [sdict allKeys];
				for (NSString *key in skeys) {
					NSDictionary* temp = [NSDictionary dictionaryWithDictionary:[sdict objectForKey:key]];
					[equipSetInfos setObject:temp forKey:key];
				}
			}
			
			NSArray *fArray = [_dict objectForKey:@"fate"];
			if (fArray != nil && fArray.count > 0) {
				NSDictionary* fdict = [[GameDB shared] getFateInfoByIds:getArrayListDataByKey(fArray,@"fid")];
				
				NSArray* fkeys = [fdict allKeys];
				
				for (NSString *key in fkeys) {
					NSDictionary* temp = [NSDictionary dictionaryWithDictionary:[fdict objectForKey:key]];
					[fateInfos setObject:temp forKey:key];
				}
			}
            //
			NSArray *gArray = [_dict objectForKey:@"gem"];
			if (gArray != nil && gArray.count > 0) {
				NSDictionary* gdict = [[GameDB shared] getJewelInfoByIds:getArrayListDataByKey(gArray,@"gid")];
				
				NSArray* fkeys = [gdict allKeys];
				
				for (NSString *key in fkeys) {
					NSDictionary* temp = [NSDictionary dictionaryWithDictionary:[gdict objectForKey:key]];
					[jewelInfos setObject:temp forKey:key];
				}
			}
		}
	}
}

-(void)addItems:(NSArray *)_array{
	if (_array == nil) return ;
	if (_array.count == 0) return ;
	
	NSArray* iArray = [NSArray arrayWithArray:_array];
	[items addObjectsFromArray:iArray];
	
	NSDictionary* idict = [[GameDB shared] getItemInfoByIds:getArrayListDataByKey(iArray,@"iid")];
	
	NSArray* keys = [idict allKeys];
	
	for (NSString *key in keys) {
		NSDictionary* temp = [NSDictionary dictionaryWithDictionary:[idict objectForKey:key]];
		[itemInfos setObject:temp forKey:key];
	}
	
}

-(void)addEquipments:(NSArray *)_array{
	if (_array == nil) return ;
	if (_array.count == 0) return ;
	
	NSArray* eArray = [NSArray arrayWithArray:_array];
	[equips addObjectsFromArray:eArray];
	
	NSDictionary* edict = [[GameDB shared] getEquipmentInfoByIds:getArrayListDataByKey(eArray,@"eid")];
	
	NSArray* ekeys = [edict allKeys];
	
	for (NSString *key in ekeys) {
		NSDictionary* temp = [NSDictionary dictionaryWithDictionary:[edict objectForKey:key]];
		[equipInfos setObject:temp forKey:key];
	}
	
	NSDictionary* sdict = [[GameDB shared] getEquipmentSetInfoByIds:getArrayListDataByKey(edict,@"sid")];
	
	NSArray* skeys = [sdict allKeys];
	for (NSString *key in skeys) {
		NSDictionary* temp = [NSDictionary dictionaryWithDictionary:[sdict objectForKey:key]];
		[equipSetInfos setObject:temp forKey:key];
	}
	
}

-(void)addFates:(NSArray *)_array{
	if (_array == nil) return ;
	if (_array.count == 0) return ;
	
	NSArray* fArray = [NSArray arrayWithArray:_array];
	
	[fates addObjectsFromArray:fArray];
	
	NSDictionary* fdict = [[GameDB shared] getFateInfoByIds:getArrayListDataByKey(fArray,@"fid")];
	
	NSArray* fkeys = [fdict allKeys];
	
	for (NSString *key in fkeys) {
		NSDictionary* temp = [NSDictionary dictionaryWithDictionary:[fdict objectForKey:key]];
		[fateInfos setObject:temp forKey:key];
	}
	
}

-(NSString*)getDescribetion:(int)_iid type:(ItemTray_type)_type{
	NSString* _msg = nil ;
	if (_type == ItemTray_armor) {
		_msg = [self getEquipDescribe:_iid role:0];
	}
	
	if (_type == ItemTray_fate) {
		_msg = [self getFateDescribe:_iid];
	}
	
	if (_type == ItemTray_item ||
		_type == ItemTray_item_armor) {
		_msg = [self getItemDescribe:_iid];
	}
	
	if (_type == ItemTray_item_jewel) {
		_msg = [self getJewelDescribe:_iid];
	}
	
	return _msg ;
}

-(NSDictionary*)getRoleDescribetion:(int)_rid{
	if (_rid < 0) return nil;
	NSString* _key = [NSString stringWithFormat:@"%d",_rid];
	NSDictionary* dict = [NSDictionary dictionaryWithDictionary:[attributes objectForKey:_key]];
	return dict;
}

-(NSString*)getFateDescribe:(int)_fid{
	NSDictionary *_dict = [self getFate:_fid];
	if (!_dict) {
		CCLOG(@"message box fate dict is nil");
		return nil;
	}
	
	int fid = [[_dict objectForKey:@"fid"] intValue];
	int f_level = [[_dict objectForKey:@"level"] intValue] ;
	
	if (f_level <= 0 || f_level > 10) {
		CCLOG(@" getFateMessageWithItemID f_level = 0");
		return nil;
	}
	
	NSDictionary *fateDict = [fateInfos objectForId:fid];
	
	if (!fateDict) {
		CCLOG(@"message box fateDict dict is nil");
		return nil;
	}
	
	int qu=[[fateDict objectForKey:@"quality"]integerValue];
	
	//NSString *name = [NSString stringWithFormat:@"^2*%@ %d级",[fateDict objectForKey:@"name"],f_level];
    NSString *name = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_level",nil),[fateDict objectForKey:@"name"],f_level];
	
	NSString *cmd = [name stringByAppendingFormat:@"#%@#20#0*",getQualityColorStr(qu)];
	cmd = [cmd stringByAppendingFormat:@"^5*"];
	
	int trade_value = [[_dict objectForKey:@"isTrade"] intValue];
	if (trade_value == TradeStatus_yes) {
		//cmd = [cmd stringByAppendingFormat:@"可以交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"player_data_helper_trade",nil)];
	}
	else {
		//cmd = [cmd stringByAppendingFormat:@"不可交易#eeeeee#16#0*"];
        cmd = [cmd stringByAppendingFormat:NSLocalizedString(@"player_data_helper_no_trade",nil)];
	}
	//TODO  获得命格等级数据
	
	NSArray* _farray = [NSArray arrayWithObjects:[NSNumber numberWithInt:f_level],
												 [NSNumber numberWithInt:f_level+1],nil];
	
	NSDictionary* _fDict = [[GameDB shared] getFateLevelInfoWithLevels:fid level:_farray];
	
	NSDictionary *nowFateLevelDict = [_fDict objectForKey:[NSString stringWithFormat:@"%d",f_level]];

	NSString *t_str = [NSString stringWithFormat:@""];
	
	if (nowFateLevelDict != nil) {
		/*
		for (int i = 0; i<24; i++) {
			//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
            NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
			float _value =[[nowFateLevelDict objectForKey:[args objectAtIndex:0]] floatValue];
			if (_value >0 ) {
				if (args.count == 3) {
					NSString *str_temp_1 = [NSString stringWithFormat:@"%@ #eeeeee#16#0",[args objectAtIndex:1]];
					NSString *str_temp_2 = [NSString stringWithFormat:@"+%.1f%@#00ee00#16#0",_value,@"%"];
					t_str = [t_str stringByAppendingFormat:@"%@|%@*",str_temp_1,str_temp_2];
				}else{
					NSString *str_temp_1 = [NSString stringWithFormat:@"%@ #eeeeee#16#0",[args objectAtIndex:1]];
					NSString *str_temp_2 = [NSString stringWithFormat:@"+%.0f#00ee00#16#0",_value];
					t_str = [t_str stringByAppendingFormat:@"%@|%@*",str_temp_1,str_temp_2];
				}
			}
		}
		 */
		t_str = [t_str stringByAppendingString:getAttrDescribetionWithDict(nowFateLevelDict)];
	}
	
	//
	NSDictionary *nextFateLevelDict = [_fDict objectForKey:[NSString stringWithFormat:@"%d",f_level+1]];
	
	if (nextFateLevelDict) {
		//NSString *str_exp = [NSString stringWithFormat:@"经验: %d/%d",[[_dict objectForKey:@"exp"] intValue],[[nextFateLevelDict objectForKey:@"exp"] intValue] ] ;
        NSString *str_exp = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_exp",nil),[[_dict objectForKey:@"exp"] intValue],[[nextFateLevelDict objectForKey:@"exp"] intValue] ] ;
		cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",str_exp];
	}

	if (t_str.length > 0) {
		cmd = [cmd stringByAppendingFormat:@"^5*"];
		cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:NSLocalizedString(@"player_data_helper_effect",nil)]];
		cmd = [cmd stringByAppendingFormat:@"%@",t_str];
	}
	
	////next level
	t_str = [NSString stringWithFormat:@""];
	if (nextFateLevelDict != nil) {
		t_str = [t_str stringByAppendingString:getAttrDescribetionWithDict(nextFateLevelDict)];
	}
	/*
	for (int i = 0; i<24; i++) {
		//NSArray *args = [property_map[i] componentsSeparatedByString:@"|"];
        NSArray *args = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
		float _value =[[nextFateLevelDict objectForKey:[args objectAtIndex:0]] floatValue];
		if (_value >0 ) {
			if (args.count == 3) {
				NSString *str_temp_1 = [NSString stringWithFormat:@"%@ #eeeeee#16#0",[args objectAtIndex:1]];
				NSString *str_temp_2 = [NSString stringWithFormat:@"+%.1f%@#00ee00#16#0",_value,@"%"];
				t_str = [t_str stringByAppendingFormat:@"%@|%@*",str_temp_1,str_temp_2];
			}else{
				NSString *str_temp_1 = [NSString stringWithFormat:@"%@ #eeeeee#16#0",[args objectAtIndex:1]];
				NSString *str_temp_2 = [NSString stringWithFormat:@"+%.0f#00ee00#16#0",_value];
				t_str = [t_str stringByAppendingFormat:@"%@|%@*",str_temp_1,str_temp_2];
			}
		}
	}
	 */
	////
	if (t_str.length > 0) {
		cmd = [cmd stringByAppendingFormat:@"^5*"];
		//cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:@"下一级效果:"]];
        cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:NSLocalizedString(@"player_data_helper_next_effect",nil)]];
		cmd = [cmd stringByAppendingFormat:@"%@",t_str];
	}
	//fix chao
	if (fid==37) {
		cmd = [cmd stringByAppendingFormat:@"^5*"];
		//cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:@"描述:"]];
        cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[NSString stringWithFormat:NSLocalizedString(@"player_data_helper_dec",nil)]];
		cmd = [cmd stringByAppendingFormat:@"%@#eeeeee#16#0*",[fateDict objectForKey:@"info"] ];
	}
	//end
	int price = [[fateDict objectForKey:@"price"] intValue];
	//NSString *str_price = [NSString stringWithFormat:@"可出售: %d银币#ffff00#16#0*",price];
    NSString *str_price = [NSString stringWithFormat:NSLocalizedString(@"player_data_helper_can_sale",nil),price];
	cmd = [cmd stringByAppendingFormat:@"^10*"];
	cmd = [cmd stringByAppendingFormat:@"%@",str_price];
	
	//---------------------------------------------------------------
	cmd = [cmd stringByAppendingFormat:@"^5*"];
	
    
    if (iPhoneRuningOnGame()) {
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#14#" withString:@"#16#"];
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#16#" withString:@"#18#"];
        cmd = [cmd stringByReplacingOccurrencesOfString:@"#20#" withString:@"#22#"];
    }
	return cmd;
}

-(NSArray*)getEquipmentsEach:(int)_rid{
	
	NSMutableArray* array = [NSMutableArray array];
	for (int i = EquipmentPart_head ; i <= EquipmentPart_ring; i++) {
		NSDictionary* dict = [[PlayerDataHelper shared] getEquipForRole:_rid part:i-1];
		if (dict) {
			[array addObject:dict];
		}
	}
	NSMutableArray* result = [NSMutableArray array];
	for (NSDictionary* dict in array) {
		int ueid = [dict intForKey:@"id"];
		int eid = [dict intForKey:@"eid"];
		int level = [dict intForKey:@"level"];
		NSDictionary* eqInfo = [equipInfos objectForId:eid];
		if (eqInfo != nil) {
			int part = [eqInfo intForKey:@"part"];
			int sid = [eqInfo intForKey:@"sid"];
			NSDictionary* seqInfo = [equipSetInfos objectForId:sid];
			if (seqInfo != nil) {
				int quality = [seqInfo intForKey:@"quality"];
				
				NSMutableDictionary* eDict = [NSMutableDictionary dictionary];
				[eDict setObject:[NSNumber numberWithInt:ueid] forKey:@"ueid"];
				[eDict setObject:[NSNumber numberWithInt:eid] forKey:@"eid"];
				[eDict setObject:[NSNumber numberWithInt:quality] forKey:@"quality"];
				[eDict setObject:[NSNumber numberWithInt:level] forKey:@"level"];
				[eDict setObject:[NSNumber numberWithInt:part] forKey:@"part"];
				[result addObject:eDict];
				
			}
		}
	}
	return result;
}

-(NSDictionary*)getEquipmentGemById:(int)ueid{
	NSDictionary* equipment = [self getEquipmentById:ueid];
	if (equipment != nil) {
		NSDictionary* result = [NSDictionary dictionaryWithDictionary:[equipment objectForKey:@"gem"]];
		return result;
	}
	return nil;
}

-(void)updateEquipmentJewel:(int)ueid :(NSDictionary *)dict{
	NSDictionary* equipment = [self getEquipmentById:ueid];
	if (equipment != nil) {
		NSMutableDictionary* result = [NSMutableDictionary dictionaryWithDictionary:equipment];
		[result setObject:dict forKey:@"gem"];
		
		for (NSDictionary* rm in equips) {
			if ([rm intForKey:@"id"] == ueid) {
				[equips removeObject:rm];
				break ;
			}
		}
		
		[equips addObject:result];
	}
}

-(BOOL)removeJewelBy:(int)_id{
	for (NSDictionary* dict in jewels) {
		if ([dict intForKey:@"id"] == _id) {
			[jewels removeObject:dict];
			return YES;
		}
	}
	return NO;
}

-(NSDictionary*)getJewelBy:(int)_id{
	for (NSDictionary* dict in jewels) {
		if ([dict intForKey:@"id"] == _id) {
			return [NSDictionary dictionaryWithDictionary:dict];
		}
	}
	return nil;
}

-(void)setJewelStatus:(int)gid status:(JewelStatus)_st{
	NSMutableDictionary* result = [NSMutableDictionary dictionaryWithDictionary:[self getJewelBy:gid]];
	[result setObject:[NSNumber numberWithInt:_st] forKey:@"used"];
	[self removeJewelBy:gid];
	[jewels addObject:result];
}

-(void)gemInlay:(int)ueid :(int)gid :(int)index{
	NSMutableDictionary* gemDict = [NSMutableDictionary dictionaryWithDictionary:[self getEquipmentGemById:ueid]];
	[gemDict setObject:[NSNumber numberWithInt:gid] forKey:[NSString stringWithFormat:@"%d",index]];
	[self updateEquipmentJewel:ueid :gemDict];
}

-(void)gemRemove:(int)ueid :(int)index{
	NSMutableDictionary* gemDict = [NSMutableDictionary dictionaryWithDictionary:[self getEquipmentGemById:ueid]];
	[gemDict removeObjectForKey:[NSString stringWithFormat:@"%d",index]];
	[self updateEquipmentJewel:ueid :gemDict];
}

@end









