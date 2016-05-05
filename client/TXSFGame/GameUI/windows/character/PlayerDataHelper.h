//
//  PlayerDataHelper.h
//  TXSFGame
//
//  Created by TigerLeung on 13-3-1.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSDictionary.h>
#import "Config.h"

#define PlayerDataHelper_Event_Update_Power @"PlayerDataHelper_Event_Update_Power"
#define PlayerDataHelper_Take_Off_Jewel		@"PlayerDataHelper_Take_Off_Jewel"

@interface NSDictionary (PlayerHelper)
-(id)objectForId:(int)tid;
-(int)intForKey:(NSString*)_key;
@end

@interface PlayerDataHelper : NSObject{
	
	BOOL isReady;
	
	NSMutableArray * roles;
	NSMutableArray * equips;
	NSMutableArray * fates;
	NSMutableArray * items;
	
	NSMutableArray * jewels;
	
	NSMutableDictionary * roleInfos;
	NSMutableDictionary * equipInfos;
	NSMutableDictionary * equipSetInfos;
	NSMutableDictionary * fateInfos;
	NSMutableDictionary * itemInfos;
	
	NSMutableDictionary * jewelInfos;
	
	
	NSMutableDictionary * equipStrengInfos;
	NSMutableDictionary * armInfos;
	NSMutableDictionary * skillInfos;
	
	NSMutableArray * partEquips[6];
	
	int totalPower;
	
	NSMutableDictionary* powers;
	NSMutableDictionary* attributes;
	
	NSMutableDictionary* batchs;
	
	BOOL			isChecking;
	
}
@property(nonatomic,assign)BOOL isReady;
@property(nonatomic,assign)BOOL isChecking;
@property(nonatomic,assign)int	totalPower;


@property(nonatomic,assign)NSMutableArray * jewels;
@property(nonatomic,assign)NSMutableArray * equips;
@property(nonatomic,assign)NSMutableArray * fates;
@property(nonatomic,assign)NSMutableArray * items;
@property(nonatomic,assign)NSMutableDictionary *batchs;



+(PlayerDataHelper*)shared;
+(void)start;
+(void)stopAll;

#pragma mark -

-(NSArray*)getRoleWithStatus:(RoleStatus)_status;

-(NSDictionary*)getRoleById:(int)____id;
-(void)updateRoleByDict:(NSDictionary*)_dict;
-(void)updatePackage:(NSDictionary *)dict;

-(NSDictionary*)getEquipmentById:(int)____id;
-(void)updateEquipmentByDict:(NSDictionary*)_dict;
-(void)updateEquipmentByDictWithArray:(NSArray*)_array;

-(NSDictionary*)getRole:(int)rid;
-(NSDictionary*)getFate:(int)fid;
-(BOOL)fallOut:(int)_id;

-(BOOL)checkEquipmentCanKitUp:(int)_ueid;

-(NSDictionary*)getEquipInfoByEquipId:(int)eid;
-(NSDictionary*)getEquipSetInfoByEquipId:(int)eid;

-(int)getEquipmentMoveCost:(int)_lv1 with:(int)_lv2;
-(int)getEquipmentLevel:(int)_eid;
-(int)getEquipmentPart:(int)_eid;
-(int)getEquipIdForRole:(int)rid part:(int)part;
-(NSDictionary*)getEquipForRole:(int)rid part:(int)part;
-(NSDictionary*)getNewEquipForRole:(int)rid part:(int)part;

-(BOOL)checkCanNewEquipForRole:(int)rid part:(int)part;
-(int)getUserRoleId:(int)_rid;

-(int)getFateExperience:(int)_rid;
-(int)getEquipmentQuality:(int)_eid;
-(NSString*)getWeaponName:(int)_rid;

-(int)getWeaponLevel:(int)_rid;
-(int)getTotalPower;

-(int)getFateQuality:(int)_fid;
-(int)getItemQuality:(int)_iid;


-(NSArray*)getItemArrayWithType:(int)_type;

-(int)getPackageAmount:(int)_type;
-(int)getPackageAmount;
-(int)getTotalPackageAmount;

-(NSArray*)getRoleCaption:(int)_rid;
//穿戴和脱装备
-(void)doEquipmentAction:(int)_rid off:(int)_ueid input:(int)_ieid;
//交换两件装备的等级
-(void)doEquipmentMoveLevel:(int)_eid1 with:(int)_eid2;

//______________________________________________
-(NSDictionary*)getRoleSuit:(int)_rid;
-(NSString*)getEquipDescribe:(int)_id role:(int)_rid;
-(NSString*)getItemDescribe:(int)_iid;
-(NSString*)getFateDescribe:(int)_fid;

-(NSString*)getDescribetion:(int)_iid type:(ItemTray_type)_type;



-(int)checkBatchSell;
-(void)updateDataByBatchEnd;
-(void)cleanupBatchData;//清楚批量数据
-(void)addBatchItem:(int)_id	type:(int)_bType; //添加一个数据到批量出售
-(void)deleteBatchItem:(int)_id	type:(int)_bType; //添加一个批量到批量出售

-(int)getItemCountById:(int)_id;

-(void)addEquipmentWithData:(NSDictionary*)_dict;
-(void)removeItemsWithArray:(NSArray*)_array;
-(void)updateItemsWithArray:(NSArray*)_array;

-(int)getItemUseLevel:(int)_id;
-(BOOL)checkCanUseItem:(int)_id;
-(int)getItemType:(int)_id;
-(void)updateALL:(NSDictionary*)_dict;
-(void)updateAllPower;
-(NSDictionary*)getRoleDescribetion:(int)_rid;

-(NSString*)getPlayerName;
-(int)getPlayerLevel;
-(NSDictionary*)getPlayerInfo;
-(void)postBattlePower;

-(void)addEquipments:(NSArray*)_array;
-(void)addFates:(NSArray*)_array;
-(void)addItems:(NSArray*)_array;

-(NSDictionary*)getJewelInfoBy:(int)_jid;
-(int)getJewelQuality:(int)_gid;
-(NSArray*)getEquipmentsEach:(int)_rid;

-(NSDictionary*)getEquipmentGemById:(int)ueid;
-(void)updateEquipmentJewel:(int)ueid :(NSDictionary*)dict;

-(BOOL)removeJewelBy:(int)_id;
-(NSDictionary*)getJewelBy:(int)_id;
-(void)setJewelStatus:(int)gid status:(JewelStatus)_st;
-(void)gemInlay:(int)ueid :(int)gid :(int)index;
-(void)gemRemove:(int)ueid :(int)index;

#pragma mark -

@end
