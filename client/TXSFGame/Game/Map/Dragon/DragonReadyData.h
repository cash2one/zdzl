//
//  DragonReadyData.h
//  TXSFGame
//
//  Created by efun on 13-9-7.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "GameDefine.h"
#import "DragonDefine.h"

/*
 *	狩龙提前通知时间
 */

@interface DragonCountdown : NSObject
{
	int _countdown;
	DragonType _dragonType;
	
	NSTimer *_countDownTimer;
}
@property (nonatomic, assign) int countdown;
@property (nonatomic, assign) DragonType dragonType;

+(void)acceptPush:(NSDictionary*)dict;
+(int)getCountdown;
+(DragonType)getDragonType;

@end

/*
 *	狩龙准备界面数据
 */

@interface DragonReadyData : NSObject
{
	BOOL _isStart;				// 是否已经点击开始
	
	int _roomNum;				// 房间号
	int _countdown;				// 倒计时
	int _playerCount;			// 玩家数
	int _glory;					// 同盟建设值
	NSString *_captainName;		// 队长名字
	NSDictionary *_skyBookDict;	// 天书
	
	// 通过活动配置表获得
	int _mapId;					// 地图id
	int _playerMaxCount;		// 房间最大人数
	DragonType _dragonType;		// 地图类型
	
	NSTimer *countDownTimer;
}

@property (nonatomic, assign) BOOL isStart;
@property (nonatomic, assign) int roomNum;
@property (nonatomic, assign) int countdown;
@property (nonatomic, assign) int playerCount;
@property (nonatomic, assign) int glory;
@property (nonatomic, assign) NSString *captainName;
@property (nonatomic, assign) NSDictionary *skyBookDict;

@property (nonatomic, assign) int mapId;
@property (nonatomic, assign) int playerMaxCount;
@property (nonatomic, assign) DragonType dragonType;

+(DragonReadyData*)shared;
+(void)startAll;
+(void)stopAll;
+(void)remove;

+(BOOL)checkIsReady;	// 是否有准备数据
+(BOOL)checkIsStart;	// 是否已经点击了开始
+(void)setIsStart:(BOOL)__isStart;
+(BOOL)checkCanNet;		// 是否能请求连接
+(void)setCanNet:(BOOL)_isCanNet;

+(void)beginWithData:(id)sender;

-(BOOL)checkIsCaption;	// 是否为队长
-(int)getBookCount:(int)__bookId;

@end
