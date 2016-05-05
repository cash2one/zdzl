//
//  JewelHelper.h
//  TXSFGame
//
//  Created by Soul on 13-7-15.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Config.h"

@interface NSDictionary (JewelHelper)
-(id)objectForId:(int)tid;
-(int)intForKey:(NSString*)_key;
@end

@interface JewelHelper : NSObject{
	NSMutableArray * roles;
	NSMutableArray * equips;
	NSMutableArray * items;
	NSMutableArray * jewels;
	NSMutableDictionary * roleInfos;
	NSMutableDictionary * equipInfos;
	NSMutableDictionary * equipSetInfos;
	NSMutableDictionary * itemInfos;
	NSMutableDictionary * jewelInfos;
}

@property(nonatomic,assign)NSMutableArray * jewels;

+(JewelHelper*)shared;
+(void)stop;

-(NSString*)getDescribetion:(int)_iid type:(ItemTray_type)_type;

-(NSArray*)getStones;

-(NSDictionary*)getEquipSetInfoBy:(int)eid;
-(NSDictionary*)getEquipInfoBy:(int)eid;
-(NSDictionary*)getJewelInfoBy:(int)jid;
-(NSDictionary*)getItemInfoBy:(int)iid;

-(int)getEquipmentQuality:(int)_eid;
-(int)getItemQuality:(int)_iid;
-(int)getJewelQuality:(int)_gid;
-(NSDictionary*)getJewelBy:(int)_ujid;
-(NSString*)getJewelAdditionBy:(int)_rid;

-(NSDictionary*)getEquipmentBy:(int)ueid;
-(NSDictionary*)getEquipmentForRole:(int)rid part:(int)part;
-(NSDictionary*)getItemBy:(int)uiid;

-(NSArray*)getRoleWithStatus:(RoleStatus)_status;
-(NSArray*)getEquipmentsEach:(int)_rid;

-(NSDictionary*)checkJewelCanInlay:(int)_ujid ueid:(int)_ueid index:(int)_index;	// key为result,info
-(void)doInlayJewel:(int)_ujid ueid:(int)_ueid index:(int)_index;
-(void)doTakeOffJewel:(int)_ueid index:(int)_index;

-(void)setJewelStatus:(int)_ujid status:(JewelStatus)_st;
-(void)addJewelWithData:(NSDictionary*)_dict;
-(void)updateJewel:(int)_ujid :(NSDictionary*)dict;

-(void)removeItemsWithArray:(NSArray*)_array;
-(void)removeJewelsWithArray:(NSArray*)_array;

-(void)addItems:(NSArray*)_array;

-(int)getTotalPackageAmount;
-(int)getPackageAmount:(ItemManager_show_type)_type;
-(int)getJewelPackageAmountWith:(EquipmentPart)_part;

@end
