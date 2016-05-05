//
//  DragonFightData.h
//  TXSFGame
//
//  Created by efun on 13-9-7.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "GameDefine.h"
#import "DragonDefine.h"

/*
 *	狩龙战斗界面数据
 */

@interface DragonFightData : NSObject
{
	DragonResultType resultType;	// 狩龙战结果
	BOOL isCanMove;					// 能否移动
	BOOL isFinalOver;				// 最终结束了
	BOOL isShowStartTitle;			// 是否显示开始信息了
	BOOL isShowResultTitle;			// 是否显示结果信息
	
	NSArray *shadowData;			// 影分身数据
	
	// 天舟
	int continueTime;				// 续航时长
	int installTime;				// 装炮时间
	int boatHard;					// 天舟耐久度
	int boatTotalHard;				// 天舟最大耐久度
	int cannon;						// 炮弹数目
	NSMutableDictionary *cannonUseData;		// 炮弹的使用情况
	
	// 玩家数据
	int cdTime;								// 玩家死亡CD
	int maxCDTime;							// 玩家最大死亡CD
	int glory;								// 同盟建设值
	NSMutableDictionary *booksData;			// 天书数目
	NSMutableDictionary *booksCD;			// 天书CD
	NSMutableDictionary *booksExchange;		// 天书剩余兑换次数
	
	// 战斗数据
	int bossHp;								// boss血量
	int bossTotalHp;						// boss最大血量
	NSMutableArray *aliveNpcs;				// 存在的npcids
	NSMutableDictionary *currentFightData;	// 战斗中的玩家和npc
	
	// 战场数据
	NSString *captainName;	// 队长名
	NSString *startInfo;	// 开始信息
	int playerCount;		// 玩家数
	int playerMaxCount;		// 最大人数
	int normalTime;			// 普通剩余时间
	int ascId;				// 活动开启配置表
	
	// 每场战斗配置表获得
	int mapId;
	BOOL isCanHitBoss;
	DragonType dragonType;
	
	NSTimer *fightTimer;		// 战斗剩余时间
	NSTimer *cannonTimer;		// 打炮剩余时间
	NSTimer *bookTimer;			// 天书剩余时间
	NSTimer *cdTimer;			// 玩家cd剩余时间
}
@property (nonatomic, assign) DragonResultType resultType;
@property (nonatomic, assign) BOOL isCanMove;
@property (nonatomic, assign) BOOL isFinalOver;
@property (nonatomic, assign) BOOL isShowStartTitle;
@property (nonatomic, assign) BOOL isShowResultTitle;
@property (nonatomic, assign) NSArray *shadowData;

@property (nonatomic, assign) int continueTime;
@property (nonatomic, assign) int installTime;
@property (nonatomic, assign) int boatHard;
@property (nonatomic, assign) int boatTotalHard;
@property (nonatomic, assign) int cannon;
@property (nonatomic, assign) NSMutableDictionary *cannonUseData;

@property (nonatomic, assign) int cdTime;
@property (nonatomic, assign) int glory;
@property (nonatomic, assign) NSMutableDictionary *booksData;
@property (nonatomic, assign) NSMutableDictionary *booksCD;
@property (nonatomic, assign) NSMutableDictionary *booksExchange;

@property (nonatomic, assign) int bossHp;
@property (nonatomic, assign) int bossTotalHp;
@property (nonatomic, assign) NSMutableArray *aliveNpcs;
@property (nonatomic, assign) NSMutableDictionary *currentFightData;

@property (nonatomic, assign) NSString *captainName;
@property (nonatomic, assign) NSString *startInfo;
@property (nonatomic, assign) int playerCount;
@property (nonatomic, assign) int playerMaxCount;
@property (nonatomic, assign) int normalTime;
@property (nonatomic, assign) int ascId;

@property (nonatomic, assign) int mapId;
@property (nonatomic, assign) BOOL isCanHitBoss;
@property (nonatomic, assign) DragonType dragonType;

+(DragonFightData*)shared;
+(void)startAll;
+(void)stopAll;
+(void)remove;

+(BOOL)checkIsFight;		// 是否有开战数据
+(BOOL)checkIsCaptain;		// 是否为队长
+(BOOL)checkIsCD;			// 是否死亡cd时间
+(BOOL)checkExistCannon;	// 是否还有炮弹
+(BOOL)checkIsBoatHarm;		// 天舟是否损害

+(BOOL)checkCanNet;			// 是否能请求连接
+(void)setCanNet:(BOOL)_isCanNet;
+(BOOL)checkCanBookRequest;
+(void)setCanBookRequest:(BOOL)_isCan;

+(BOOL)checkIsWin;				// 赢了，返回NO代表还没结束
+(BOOL)checkIsLose;				// 输了，返回NO代表还没结束
+(BOOL)checkIsOver;				// 是否结束了，返回NO代表还没结束
+(BOOL)checkIsFinalOver;		// 是否已经完全结束了，捡了宝箱，也可能时Gm指令重新开了一场
+(BOOL)checkIsShowStartTitle;	// 是否显示了开始信息，YES=已经显示过了，NO=还没显示
+(BOOL)checkIsShowResultTitle;	// 是否显示了结果信息，同上

+(int)getSelectMonsterId;
+(void)setSelectMonsterId:(int)monsterId;

+(void)beginWithData:(id)sender;

// 请求回调
+(void)didUseBook:(id)sender arg:(id)arg;
+(void)doFightEnd;
+(void)didFightEnd:(id)sender;
+(void)didAssess:(id)sender;	// 请求评价界面
+(void)didGetBox:(id)sender;	// 开宝箱返回

// 返回0-100
-(float)getFirePercent:(int)index;

// 获取影分身显示数据
-(NSDictionary*)getShadow:(int)__ancId;

// 清除CD
-(void)removeCD;

// 天书
-(float)getBookCD:(int)__bookId;
-(int)getBookCount:(int)__bookId;
-(int)getExchangeBookCount:(int)__bookId;
-(BOOL)checkUseNormalBook:(int)__bookId;
-(BOOL)checkUseExchangeBook:(int)__bookId;
-(void)useNormalBook:(int)__bookId;
-(void)useExchangeBook:(int)__bookId;

@end
