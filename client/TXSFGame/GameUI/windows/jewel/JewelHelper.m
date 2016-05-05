//
//  JewelHelper.m
//  TXSFGame
//
//  Created by Soul on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "JewelHelper.h"
#import "GameDB.h"
#import "GameConfigure.h"

#define SAVE_RELEASE(value) \
if(value)					\
{							\
	[value release];		\
	value = nil;			\
}


@implementation NSDictionary (JewelHelper)
-(id)objectForId:(int)tid{
	NSString * key = [NSString stringWithFormat:@"%d",tid];
	return [self objectForKey:key];
}

-(int)intForKey:(NSString *)_key{
	return [[self objectForKey:_key] intValue];
}
@end

static JewelHelper* s_JewelHelper = nil ;
@implementation JewelHelper

@synthesize jewels;

+(JewelHelper*)shared{
	if (s_JewelHelper == nil) {
		s_JewelHelper = [[JewelHelper alloc] init];
		[s_JewelHelper loadData];
	}
	return s_JewelHelper;
}

+(void)stop{
	if (s_JewelHelper) {
		[s_JewelHelper writeData];
		[s_JewelHelper freeData];
		[s_JewelHelper release];
		s_JewelHelper = nil ;
	}
}

-(void)dealloc{
	[self freeData];
	[super dealloc];
}

-(void)loadData{
	jewels = [NSMutableArray arrayWithArray:[[GameConfigure shared] getPlayerJewels]];
	NSDictionary * gemInfos = [[GameDB shared] getJewelInfoByIds:getArrayListDataByKey(jewels,@"gid")];
	jewelInfos = [NSMutableDictionary dictionaryWithDictionary:gemInfos];
	
	[jewels retain];
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
	
	NSArray * uits = [[GameConfigure shared] getPlayerItemList];
	infos = [[GameDB shared] getItemInfoByIds:getArrayListDataByKey(uits,@"iid")];
	
	items = [NSMutableArray arrayWithArray:uits];
	itemInfos = [NSMutableDictionary dictionaryWithDictionary:infos];
	
	[items retain];
	[itemInfos retain];
}

-(void)writeData
{
	[[GameConfigure shared] updateRoleArray:roles];
	[[GameConfigure shared] updateEquipmentArray:equips];
	[[GameConfigure shared] updateItemArray:items];
	[[GameConfigure shared] updateJewelArray:jewels];
}

-(void)freeData{
	SAVE_RELEASE(jewels);
	SAVE_RELEASE(jewelInfos);
	SAVE_RELEASE(roles);
	SAVE_RELEASE(roleInfos);
	SAVE_RELEASE(equips);
	SAVE_RELEASE(equipInfos);
	SAVE_RELEASE(equipSetInfos);
	SAVE_RELEASE(items);
	SAVE_RELEASE(itemInfos);
}


#pragma mark -

-(NSString*)getItemDescribe:(int)_iid{
	NSDictionary *_dict = [self getItemBy:_iid];
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

-(NSString*)getDescribetion:(int)_iid type:(ItemTray_type)_type
{
	NSString* _msg = nil ;
	if (_type == ItemTray_item_stone) {
		_msg = [self getItemDescribe:_iid];
	}
	if (_type == ItemTray_item_jewel) {
		_msg = [self getJewelDescribe:_iid];
	}
	
	return _msg ;
}

-(NSArray*)getStones
{
	NSMutableArray *array = [NSMutableArray array];
	
	for (NSDictionary* _item in  items) {
		int __iid = [_item intForKey:@"iid"];
		NSDictionary* _iDict = [itemInfos objectForId:__iid];
		if (_iDict != nil) {
			
			int __type = [_iDict intForKey:@"type"];
			BOOL isAdd = NO ;
			if (__type == Item_stone) {
				isAdd = YES;
			}
			
			if (isAdd) {
				[array addObject:_item];
			}
		}
	}
	
	return array;
}

-(NSString*)getJewelAdditionBy:(int)_rid{
	NSMutableArray* array = [NSMutableArray array];
	for (int i = EquipmentPart_head ; i <= EquipmentPart_ring; i++) {
		NSDictionary* dict = [self getEquipmentForRole:_rid part:i-1];
		if (dict) {
			[array addObject:dict];
		}
	}
	
	NSDictionary * globalConfig = [[GameDB shared] getGlobalConfig];
	NSString* jewelInfo = [globalConfig objectForKey:@"gem_gather"];
	
	BaseAttribute attribute = BaseAttributeZero();
	for (NSDictionary* equip in array){
		NSDictionary* gem = [equip objectForKey:@"gem"];
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
	}
	
	return BaseAttributeToDisplayStringWithFilter(attribute, jewelInfo);
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

-(BOOL)removeEquipmentBy:(int)_id{
	for (NSDictionary *dict in equips) {
		if ([dict intForKey:@"id"] == _id) {
			[equips removeObject:dict];
			return YES;
		}
	}
	return NO;
}

-(int)getEquipmentQuality:(int)_eid
{
	NSDictionary *equip = [equipInfos objectForId:_eid];
	if (equip) {
		int sid = [[equip objectForKey:@"sid"] intValue];
		NSDictionary *s = [equipSetInfos objectForId:sid];
		if (s) {
			return [[s objectForKey:@"quality"] intValue];
		}
	}
	return IQ_WHITE;
}

-(int)getJewelQuality:(int)_gid{
	NSDictionary* g1 = [jewelInfos objectForId:_gid];
	return [g1 intForKey:@"quality"];
}

-(int)getItemQuality:(int)_iid{
	NSDictionary* e1 = [itemInfos objectForId:_iid];
	return [e1 intForKey:@"quality"];
}

-(NSDictionary*)getJewelBy:(int)_ujid{
	for (NSDictionary* jewel in jewels) {
		if ([jewel intForKey:@"id"] == _ujid) {
			return jewel;
		}
	}
	return nil;
}

-(NSDictionary*)getRoleBy:(int)_rid{
	for (NSDictionary* role in roles) {
		if ([role intForKey:@"rid"] == _rid) {
			return role;
		}
	}
	return nil;
}

-(NSDictionary*)getEquipmentBy:(int)ueid{
	for (NSDictionary* equip in equips) {
		if ([equip intForKey:@"id"] == ueid) {
			return equip;
		}
	}
	return nil;
}

-(NSDictionary*)getItemBy:(int)uiid{
	for(NSDictionary * item in items){
		if([[item objectForKey:@"id"] intValue] == uiid){
			return item;
		}
	}
	return nil;
}

-(NSDictionary*)getEquipSetInfoBy:(int)eid
{
	NSDictionary *equipInfo = [self getEquipInfoBy:eid];
	if (equipInfo) {
		int sid = [equipInfo intForKey:@"sid"];
		return [equipSetInfos objectForId:sid];;
	}
	return nil;
}

-(NSDictionary*)getEquipInfoBy:(int)eid
{
	NSDictionary *equipInfo = [equipInfos objectForId:eid];
	return equipInfo;
}

-(NSDictionary*)getJewelInfoBy:(int)jid
{
	NSDictionary *jewelInfo = [jewelInfos objectForId:jid];
	return jewelInfo;
}

-(NSDictionary*)getItemInfoBy:(int)iid
{
	NSDictionary *itemInfo = [itemInfos objectForKey:iid];
	return itemInfo;
}

-(NSString*)getPath:(int)_part{
	return [NSString stringWithFormat:@"eq%d",(_part+1)];
}

-(NSDictionary*)getEquipmentForRole:(int)rid part:(int)part{
	if(part<0 || part>5) return nil;
	NSDictionary * role = [self getRoleBy:rid];
	int ueid = [[role objectForKey:[self getPath:part]] intValue];
	if(ueid>0){
		return [self getEquipmentBy:ueid];
	}
	return nil;
}

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

-(NSArray*)getEquipmentsEach:(int)_rid{
	
	NSMutableArray* array = [NSMutableArray array];
	for (int i = EquipmentPart_head ; i <= EquipmentPart_ring; i++) {
		NSDictionary* dict = [[JewelHelper shared] getEquipmentForRole:_rid part:i-1];
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
				int seqLevel = [seqInfo intForKey:@"lv"];
				
				NSMutableDictionary* eDict = [NSMutableDictionary dictionary];
				[eDict setObject:[NSNumber numberWithInt:ueid] forKey:@"ueid"];
				[eDict setObject:[NSNumber numberWithInt:eid] forKey:@"eid"];
				[eDict setObject:[NSNumber numberWithInt:quality] forKey:@"quality"];
				[eDict setObject:[NSNumber numberWithInt:level] forKey:@"level"];
				[eDict setObject:[NSNumber numberWithInt:part] forKey:@"part"];
				[eDict setObject:[NSNumber numberWithInt:seqLevel] forKey:@"seqLevel"];	// 套装等级
				[result addObject:eDict];
				
			}
		}
	}
	return result;
}

-(NSDictionary*)checkJewelCanInlay:(int)_ujid ueid:(int)_ueid index:(int)_index
{
	NSMutableDictionary *_dict = [NSMutableDictionary dictionary];
	
	if (_ujid < 0 || _ueid < 0) {
		[_dict setObject:NSLocalizedString(@"jewel_cannot_inlay_type",nil) forKey:@"info"];
		[_dict setObject:[NSNumber numberWithBool:NO] forKey:@"result"];
		return _dict;
	}
	
	NSDictionary *equipment = [self getEquipmentBy:_ueid];
	if (equipment) {
		
		NSDictionary *jewel = [self getJewelBy:_ujid];
		if (jewel) {
			int gid = [jewel intForKey:@"gid"];
			NSDictionary *jewelInfo = [self getJewelInfoBy:gid];
			if (jewelInfo) {
				NSString *parts = [jewelInfo objectForKey:@"parts"];
				NSArray *partArray = [parts componentsSeparatedByString:@"|"];
				
				int eid = [equipment intForKey:@"eid"];
				NSDictionary *equipInfo = [self getEquipInfoBy:eid];
				if (equipInfo) {
					int part = [equipInfo intForKey:@"part"];
					NSString *partKey = [NSString stringWithFormat:@"%d", part];
					// 当前装备可以镶嵌该珠宝
					if ([partArray containsObject:partKey]) {
						
						NSDictionary *gem = [equipment objectForKey:@"gem"];
						NSArray *gemKeys = [gem allKeys];
						NSString *_key = [NSString stringWithFormat:@"%d", _index];
						// 装备上没有珠宝
						if (gemKeys.count <= 0) {
							[_dict setObject:[NSNumber numberWithBool:YES] forKey:@"result"];
							return _dict;
						}
						// 当前孔没有珠宝
						if (![gemKeys containsObject:_key]) {
							int type = [jewelInfo intForKey:@"type"];
							
							// 当前装备没有同类型珠宝
							for (NSString *key in gemKeys) {
								int _id = [gem intForKey:key];
								NSDictionary *_info = [self getJewelBy:_id];
								if (_info) {
									int _gid = [_info intForKey:@"gid"];
									NSDictionary *___info = [self getJewelInfoBy:_gid];
									if (___info) {
										int _type = [___info intForKey:@"type"];
										if (_type == type) {
											[_dict setObject:NSLocalizedString(@"jewel_had_same_type",nil) forKey:@"info"];
											[_dict setObject:[NSNumber numberWithBool:NO] forKey:@"result"];
											return _dict;
										}
									}
								}
							}
							
							[_dict setObject:[NSNumber numberWithBool:YES] forKey:@"result"];
							return _dict;
						} else {
							[_dict setObject:NSLocalizedString(@"jewel_had_other",nil) forKey:@"info"];
							[_dict setObject:[NSNumber numberWithBool:NO] forKey:@"result"];
							return _dict;
						}
					} else {
						[_dict setObject:NSLocalizedString(@"jewel_cannot_inlay_type",nil) forKey:@"info"];
						[_dict setObject:[NSNumber numberWithBool:NO] forKey:@"result"];
						return _dict;
					}
				}
			}
		}
	}
	
	[_dict setObject:NSLocalizedString(@"jewel_cannot_inlay",nil) forKey:@"info"];
	[_dict setObject:[NSNumber numberWithBool:NO] forKey:@"result"];
	return _dict;
}

-(void)doInlayJewel:(int)_ujid ueid:(int)_ueid index:(int)_index
{
	if (_ujid < 0 || _ueid < 0) return;
	
	NSMutableDictionary *equipment = [NSMutableDictionary dictionaryWithDictionary:[self getEquipmentBy:_ueid]];
	if (equipment) {
		
		NSMutableDictionary *gem = [NSMutableDictionary dictionaryWithDictionary:[equipment objectForKey:@"gem"]];
		NSString *key = [NSString stringWithFormat:@"%d", _index];
		NSString *value = [NSString stringWithFormat:@"%d", _ujid];
		[gem setObject:value forKey:key];
		
		[equipment setObject:gem forKey:@"gem"];
		[self removeEquipmentBy:_ueid];
		[equips addObject:equipment];
	}
}

-(void)doTakeOffJewel:(int)_ueid index:(int)_index
{
	if (_ueid < 0) return;
	
	NSMutableDictionary *equipment = [NSMutableDictionary dictionaryWithDictionary:[self getEquipmentBy:_ueid]];
	if (equipment) {
		
		NSMutableDictionary *gem = [NSMutableDictionary dictionaryWithDictionary:[equipment objectForKey:@"gem"]];
		NSString *key = [NSString stringWithFormat:@"%d", _index];
		[gem removeObjectForKey:key];
		
		[equipment setObject:gem forKey:@"gem"];
		[self removeEquipmentBy:_ueid];
		[equips addObject:equipment];
	}
}

-(void)setJewelStatus:(int)_ujid status:(JewelStatus)_st{
	NSMutableDictionary* result = [NSMutableDictionary dictionaryWithDictionary:[self getJewelBy:_ujid]];
	[result setObject:[NSNumber numberWithInt:_st] forKey:@"used"];
	[self removeJewelBy:_ujid];
	[jewels addObject:result];
}

-(void)addJewelWithData:(NSDictionary *)_dict
{
	if (_dict == nil) {
		return ;
	}
	
	NSDictionary* dict = [NSDictionary dictionaryWithDictionary:_dict];
	[jewels addObject:dict];
	int gid = [dict intForKey:@"gid"];
	
	NSDictionary* jDict = [[GameDB shared] getJewelInfo:gid];
	NSString* _key = [NSString stringWithFormat:@"%d",gid];
	[jewelInfos setObject:jDict forKey:_key];
}

-(void)updateJewel:(int)_ujid :(NSDictionary *)dict
{
	[self removeJewelBy:_ujid];
	[jewels addObject:dict];
}

-(void)removeItemsWithArray:(NSArray *)_array
{
	if (_array == nil) {
		return ;
	}
	
	for (NSNumber *_number in _array) {
		NSDictionary* _edict = [self getItemBy:[_number intValue]];
		if (_edict != nil) {
			[items removeObject:_edict];
		}
	}
}

-(void)removeJewelsWithArray:(NSArray*)_array
{
	if (_array == nil) {
		return ;
	}
	
	for (NSNumber *_number in _array) {
		NSDictionary* _jdict = [self getJewelBy:[_number intValue]];
		if (_jdict != nil) {
			[jewels removeObject:_jdict];
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

-(int)getTotalPackageAmount{
	int _maxCount = 5 ;
	
	NSDictionary *playerDict = [[GameConfigure shared] getPlayerInfo];
	int playerVip = [[playerDict objectForKey:@"vip"] intValue];
	_maxCount += playerVip;
	
	return _maxCount*12;
}

-(int)getPackageAmount:(ItemManager_show_type)_type
{
	if (_type == ItemManager_show_type_jewel) {
		int totalCount = 0;
		NSArray* _array = [NSArray arrayWithArray:jewels];
		
		for (NSDictionary* dict in _array) {
			if ([dict intForKey:@"used"] == JewelStatus_unused) {
				totalCount++;
			}
		}
		
		return totalCount;
	}
	
	if (_type == ItemManager_show_type_stone){
		int totalCount = 0;
		NSArray * _array = [NSArray arrayWithArray:items];
		for(NSDictionary * item in _array){
			int iid = [[item objectForKey:@"iid"] intValue];
			NSDictionary * itemInfo = [itemInfos objectForId:iid];
			int itemType = [[itemInfo objectForKey:@"type"] intValue];
			if(itemType==Item_stone
			   ){
				totalCount += 1;
			}
		}
		return totalCount;
	}
	
	return 0;
}

-(int)getJewelPackageAmountWith:(EquipmentPart)_part
{
	int totalCount = 0;
	NSArray* _array = [NSArray arrayWithArray:jewels];
	
	for (NSDictionary* dict in _array) {
		if ([dict intForKey:@"used"] == JewelStatus_unused) {
			if (_part == 0) {
				totalCount++;
				continue;
			}
			
			int gid = [dict intForKey:@"gid"];
			NSDictionary *jewelInfo = [self getJewelInfoBy:gid];
			if (jewelInfo) {
				NSString *_parts = [jewelInfo objectForKey:@"parts"];
				NSArray *_partArray = [_parts componentsSeparatedByString:@"|"];
				NSString *partString = [NSString stringWithFormat:@"%d", _part];
				if ([_partArray containsObject:partString]) {
					totalCount++;
				}
			}
		}
	}
	
	return totalCount;
}

@end
