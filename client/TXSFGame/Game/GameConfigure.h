//
//  GameConfigure.h
//  TXSFGame
//
//  Created by chao chen on 12-10-12.
//  Copyright (c) 2012 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseGameConfig.h"
#import "Config.h"
#import "AlertManager.h"

@interface GameConfigure : BaseGameConfig{
	
	//NSMutableDictionary * game_db;
	
	//NSMutableDictionary * testTaskList;
	//NSMutableDictionary * userFunction;
	//NSMutableArray		* userRoleList;//玩家角色
	//NSMutableArray		* userEquipList;//玩家装备
	
	int time;
	
	BOOL isCanSendMove;
	
}
@property(nonatomic,assign) int time;
@property(nonatomic,assign) BOOL isCanSendMove;

////取配置文件对象指针
+(GameConfigure*)shared;
+(void)stopAll;

-(int)getLastLoginPlayerId;
-(int)getPlayerCount;

-(void)loadData;
-(NSArray*)getDataByTableName:(NSString*)_table;

//==============================================================================
//User map and NPC =============================================================
//==============================================================================

-(NSDictionary*)getChooseChapter;
-(BOOL)isPlayerOnChapter;
-(BOOL)isPlayerOnOneOrChapter;
-(int)getPlayerLevel;
-(NSDictionary*)getPlayerById:(int)_id;

-(void)setPlayerLocation:(CGPoint)point mapId:(int)mid;
-(NSDictionary*)getUserMapInfo;

-(NSDictionary*)getUserMapByMapId:(int)mapId;
-(NSArray*)getUserMapNPCByMapId:(int)mapId;
-(int)getTotalPowerResult;


-(void)removeUserMapNPCWith:(int)mapId;
-(void)updateMapNPCData:(NSString*)data map:(int)mapId target:(id)_t call:(SEL)_c;
-(void)removeUserMapNPC:(int)npcId map:(int)mapId target:(id)_t call:(SEL)_c;
-(BOOL)addUserMapNPC:(int)npcId map:(int)mapId point:(CGPoint)point direction:(int)direction target:(id)_t call:(SEL)_c;

//-(void)updateMapNPCData:(NSString*)data map:(int)mapId;
//-(BOOL)addUserMapNPC:(int)npcId map:(int)mapId point:(CGPoint)point direction:(int)direction;
//-(void)removeUserMapNPC:(int)npcId map:(int)mapId;

//==============================================================================
//==============================================================================
//-(NSDictionary*)getMapInfoById:(int)mid;
//-(NSDictionary*)getNPCInfoById:(int)nid;

//==============================================================================
-(NSArray*)getUserTaskList;
-(void)removeUserTaskList;
-(void)startUserTask:(int)userTaskId;
-(void)updateUserTask:(int)userTaskId step:(int)step;
-(void)completeUserTask:(int)userTaskId target:(id)target call:(SEL)call;
-(NSArray*)getCompleteUserTaskList;
-(void)addNewUserTasks:(NSArray*)tasks;
-(void)removeUserTasksById:(int)tid;
-(NSDictionary*)getTaskInfoById:(int)tid;

/*
-(void)initTestTsakList;
-(NSDictionary*)getTestTaskInfoById:(int)tid;
-(NSDictionary*)getTestTaskInfoById:(int)tid type:(int)type;
-(NSMutableDictionary*)getProcess:(int)action;
*/

-(void)setUserStage:(int)sid kill:(int)count;
-(NSString*)getUserStage;
-(NSString*)getUserStageByStageId:(int)sid;
-(NSArray*)removeUserStage:(int)sid;

//??? type
//-(NSDictionary*)getMonsterInfoById:(int)mid;

//-(NSDictionary*)getSkillInfoById:(int)sid;
//-(NSArray*)getSkillStautsIds:(int)sid;
//-(NSDictionary*)getStatusInfoById:(int)sid;

//-(NSDictionary*)getFightInfoById:(int)fid;
//-(NSDictionary*)getMonster:(int)mid level:(int)level;

-(NSArray*)getUserChoosePositionMember;
-(NSDictionary*)getUserChoosePosition;
//-(NSDictionary*)getPosition:(int)posId level:(int)posLevel;

-(NSDictionary*)getUserRoleById:(int)rid;
//-(NSDictionary*)getRoleInfoById:(int)rid;

-(NSDictionary*)getUserArmInfoByRoleId:(int)rid;

-(BOOL)checkStopChapterTask:(int)_tid;
-(void)reloadPlayerAllData;

-(void)forSkipChapterReload;

-(NSMutableArray*)getUserMenuList;
-(void)updateUserMenuList:(int)_tag;
-(BOOL)checkPlayerFunction:(Unlock_object)_id;


-(NSDictionary*)getErrorMessage;
-(NSString*)getErrorMessage:(NSString*)key;

/*
-(void)updateChapterMap:(NSString*)_data;
-(NSDictionary*)getPlayerChapterMap;
-(NSDictionary*)getPlayerExternalMap;
*/

-(NSDictionary*)getUserWorldMap;

-(NSString*)getDefaultChapterMapInfo:(int)_cid;
-(void)addUserWorldMap:(int)_cid;
-(void)addUserWorldMapWith:(NSString*)_data;
-(void)updateUserWorldMap:(int)_tag map:(int)_mid;
-(void)addUserWorldMap:(int)_tag map:(int)_mid;
-(NSString*)getUserWorldMapForString:(int)_tag map:(int)_mid;
-(void)setUserWorldMap:(NSString*)_info;

//-(void)sendRolePower;

-(int)getPowerResult:(NSDictionary*)powers;
-(void)updateCBE:(NSDictionary*)powers;

#pragma mark 装备列表
-(NSArray*)getPlayerEquipmentList;
-(NSDictionary*)getPlayerEquipInfoById:(int)_id;
-(NSDictionary*)getPlayerEquipInfoWithBaseId:(int)_id;
-(void)moveLevelPlayerEquipmentEid1:(int)eid1 eid2:(int)eid2;//装备等级转移（2转到1）， 转移之后不穿戴 
-(void)movePlayerEquipment:(int)eid1 :(int)eid2 :(int)upid :(int)_part;//装备转移,转移之后穿戴
-(NSDictionary*)compareEqiutForShift:(NSDictionary*)_dict;//比较更换装备
-(void)tackOffEquipmentWithID:(int)eid rid:(int)_rid;//脱装备
-(void)tackOffEquipment:(NSString*)_part rid:(int)_rid;//脱装备
-(void)upgradePlayerEquipment:(int)_id;//装备升级
-(void)updateEquipment:(int)_ueid type:(int)_type;
-(void)removeEquipment:(int)_ueid;
#pragma maek

#pragma mark 角色表
-(NSArray*)getPlayerJewels;//获得玩家珠宝
-(NSDictionary*)getPlayerJewelInfoById:(int)_id;
-(NSArray*)getPlayerRoleList;//玩家角色列表
-(NSDictionary*)getPlayerRoleFromListById:(int)rid;
-(void)wearEquipment:(int)_id part:(int)_part target:(int)_ueid;//穿戴装备
-(void)wearEquipment:(int)_id target:(int)_ueid;//穿戴装备
-(void)updateArmLevel:(int)_urid level:(int)_level;//等级
-(NSArray*)getFightTeamMember;//参战成员
-(NSArray*)getTeamMember;
-(void)removeTeamMember:(int)_rid;

-(BaseAttribute)getNpcAttribute:(int)_rid level:(int)_level;
-(BaseAttribute)getRoleAttribute:(int)_rid isLoadOtherBuff:(BOOL)isLoad;
-(BaseAttribute)getRoleAttributeByData:(NSDictionary*)data isLoadOtherBuff:(BOOL)isLoad;
-(BaseAttribute)getSingleRoleAttributeById:(int)rid level:(int)level;

-(void)activePlayerRoleSkillWithType:(int)_urid type:(int)_type;
-(void)activePlayerRoleSkillWithId:(int)_urid sid:(int)_sid;
-(NSArray *)addPlayerRole:(NSDictionary*)_dict;
-(void)updatePlayerRoleWithId:(int)_id status:(int)_status;
#pragma mark


-(void)updateRoleArray:(NSArray*)_array;
-(void)updateEquipmentArray:(NSArray*)_array;
-(void)updateFateArray:(NSArray*)_array;
-(void)updateItemArray:(NSArray*)_array;
-(void)updateJewelArray:(NSArray *)_array;

#pragma mark 玩家信息
-(NSDictionary*)getPlayerInfo;
-(int)getPlayerPackageItemCount;//获得角色背包物品数
-(int)getPlayerPackageMaxCapacity;//获得角色最大背包数
-(int)getPlayerId;//获得玩家ID
-(int)getPlayerRole;//获得玩家角色ID
-(NSString*)getPlayerName;//获得玩家名字
-(int)getPlayerTrain;//获得玩家炼历
-(int)getPlayerMoney;//获得玩家钱币
-(int)getPlayerCoin2;//获得玩家元宝
-(int)getPlayerCoin3;//获得玩家绑元宝
-(int)getPlayerExp;//获得玩家经验
-(int)getPlayerLevel;//获得等级
-(int)getPlayerIngot;
-(int)getPlayerLastMapId;
-(int)getRoleQualityWithRid:(int)_rid;
-(void)updatePlayerIngotEx:(int)_value;//绑定元宝
-(void)updatePlayerIngot:(int)_value;//元宝
-(void)updatePlayerState:(int)state;//更新玩家的状态
-(void)updatePlayerMoney:(int)_num;//更新玩家的钱
-(void)updatePlayerLastMapId:(int)_id;//更新上一次玩家地图
-(void)updatePlayerPosId:(int)_pid;//更新玩家激活阵形
-(void)updatePlayerTrain:(int)_train;//更新玩家的钱
-(void)updatePlayerInfo:(NSDictionary*)info;
-(void)updatePlayerChapter;
-(void)updatePlayerFuncs:(unsigned int)_func;
-(void)updatePlayerFuncs:(unsigned int)_func target:(id)_target call:(SEL)_call;
#pragma mark 

#pragma mark 物品列表
-(NSArray*)getPlayerItemList;//玩家物品列表
-(NSDictionary*)getPlayerItemInfoById:(int)_id;
-(int)getPlayerItemCountByIid:(int)iid;//获取物品数量
-(void)removeItem:(int)_uiid;//删除物品
-(int)getItemIdByName:(NSString *)name;
-(NSArray*)getPlayerItemListByIid:(int)_iid;//返回玩家物品数组
-(NSArray*)getPlayerItemByType:(Item_type)_type;//通过类型
#pragma mark

#pragma mark 命格列表
-(NSArray*)getPlayerFateList;//玩家命格列表
-(NSDictionary*)getPlayerFateInfoById:(int)_id;
-(void)removeFate:(int)_ufid;//删除命格
-(void)addFate:(NSDictionary*)dict;//加一个命格
-(void)wearFate:(int)_ufid part:(int)_part target:(int)_urid;//穿戴命格
-(void)tackOffFate:(int)_ufid part:(int)_part target:(int)_urid;//脱命格
-(void)tackOffFate:(int)_ufid target:(int)_urid;//脱命格
#pragma mark


#pragma mark 收取
-(NSArray*)getPlayerWaitItemList;//玩家待收取物品表
-(NSArray*)getPlayerWaitItemListByType:(int)_type;
-(void)addPlayerWaitItem:(NSArray*)_idArray;//加玩家待收取猎命
-(void)removePlayerWaitItem:(NSArray*)_idDictArray;//删玩家待收取猎命
#pragma mark --

#pragma mark 背包操作
-(void)markPlayerProperty;
-(NSArray*)getPackageAddDataWithServer:(NSArray*)array;
-(void)updatePackage:(NSDictionary*)dict;
-(NSDictionary*)handleItemsInfo:(NSArray*)array;
#pragma mark

#pragma mark 背包更新数据
// isAdd 为YES，消耗的银币，元宝不提示；为NO，弹出消耗的银币，元宝
-(NSArray*)getPackageAddData:(NSDictionary*)dict;// isAdd为NO
-(NSArray*)getPackageAddData:(NSDictionary*)dict type:(PackageItemType)type;// isAdd为NO
-(NSArray*)getPackageAddData:(NSDictionary*)dict isAdd:(BOOL)isAdd;
-(NSArray*)getPackageAddData:(NSDictionary*)dict type:(PackageItemType)type isAdd:(BOOL)isAdd;
#pragma mark

// 返回NSDictionary key为iid value为数值（可负）
-(NSDictionary*)getItemUpdateData:(NSDictionary*)dict;

#pragma mark function
-(void)recordPlayerSetting:(NSString*)_key value:(id)_value;
-(NSDictionary*)getPlayerRecord;
-(id)getPlayerRecord:(NSString*)_key;
#pragma mark


-(NSDictionary*)getPlayerCarInfoById:(int)_id;

// 同盟
//-(NSDictionary*)getGroupById:(int)_id;
//-(NSDictionary*)getGroupPlayerById:(int)_gid;
//-(NSDictionary *)getGroupPostById:(int)_gid;
//-(NSMutableArray *)getGroupList;
//-(NSMutableArray *)getGroupPlayerList;
//-(NSMutableArray *)getGroupPostList;

//===============
//end
//===============

//===============
//常用方法，基于以上数据
//===============

//-(void)shiftRoleEquipmenf:(int)_rid part:(int)_part src:(int)_id1 des:(int)_id2;//角色换装备
//------



//-(NSMutableDictionary*)getWeaponPanelCharacterInfo:(int)_rid;
//

//------------


#pragma mark - 
#pragma mark - 阵型
// 玩家阵形表
-(NSArray *)getPlayerPhalanxList;                           // 获取玩家阵形列表
-(NSArray *)addPlayerPhalanx:(NSDictionary*)_dict;          // 学习阵形
-(void)updatePlayerPhalanxWithId:(int)_pid level:(int)_level;   // 更新玩家阵形等级
-(void)updatePlayerPhalanx:(NSDictionary*)dict;                 // 更新玩家阵形
-(NSDictionary *)getPlayerPhalanxByPhalanxId:(int)pid;      // 获取玩家阵形数据(通过阵形id)
-(NSDictionary *)getPlayerPhalanxById:(int)_id;             // 获取玩家阵形数据

//-(NSMutableDictionary*)getWeaponInfo:(int)_rid;

//-------------------------------------------------
//
////***************************
////左上角UI 数据
////***************************
//-(NSDictionary*)getLeftUpUIInfo;
//-(void)updateLeftUpUIInfo:(NSDictionary*)dict;
//***************************

//***************************
//背包 数据
//***************************
//-(NSArray*)getPackageItemIDInfo;
//-(void)salePackageItemWithID:(NSInteger)itmeID count:(NSInteger)value;
//-(BOOL)addPackageItemWithID:(NSInteger)itmeID count:(NSInteger)value;
//-(void)removePackageItemWithID:(NSInteger)itmeID count:(NSInteger)value;
//-(NSDictionary *)getItemInfoWithID:(NSInteger)itemID;
//***************************

//***************************
//观星 数据
//***************************
-(NSArray*)getFateArrayWithRoldID:(NSInteger)roleID;
//***************************


//==============================================================================
//Player =======================================================================
//==============================================================================

-(NSArray*)getPlayerMails;

-(void)setPlayerBuff:(NSDictionary*)dict type:(Buff_Type)type;
-(NSDictionary*)getPlayerBuffByType:(Buff_Type)type;

-(NSDictionary*)getPlayerAlly;
-(void)removePlayerAlly;
-(void)setPlayerAlly:(NSDictionary*)info;
//取自定义cliAttr数据
-(NSString*)getPlayerCliAttr:(NSString*)key;
-(void)setPlayerCliAttr:(NSString*)key value:(id)_value;
//取拥有坐骑列表
-(NSArray*)getPlayerCarList;
-(void)setPlayerCar:(id)pcid;
//设置玩家经验
-(void)setPlayerExp:(int)Exp;
-(void)updateRoleByDict:(NSDictionary *)_dict;
//______________________________________________________________________________
//______________________________________________________________________________
//______________________________________________________________________________

-(void)doEquipmentAction:(int)_rid off:(int)_ueid input:(int)_ieid;
-(void)doEquipmentMoveLevel:(int)_eid1 with:(int)_eid2;
//______________________________________________________________________________
//______________________________________________________________________________


-(int)getPlayerVipLevel;
-(NSArray*)getRoleWithStatus:(RoleStatus)_status;
-(NSDictionary*)getVipConfig;
-(void)updateVipConfig:(NSDictionary*)dict;



//-----------------------------------------------------------------------------
//
//-----------------------------------------------------------------------------
-(BOOL)checkPlayerIsFirstRecharge;
-(void)closePlayerFirstRecharge;


-(NSDictionary*)getPlayerCBE;
-(void)updatePlayerCBE:(NSDictionary*)dict;


@end
