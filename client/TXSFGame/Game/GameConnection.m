//
//  GameConnection.m
//  TXSFGame
//
//  Created by TigerLeung on 12-12-5.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "GameConfigure.h"
#import "GameConnection.h"
#import "DragonReadyData.h"

#import "GCDAsyncSocket.h"
#import "AsyncSocket.h"

#import "NSData+Base64.h"
#import "NSDataAES256.h"
#import "NSString+MD5Addition.h"
#import "UIDevice+IdentifierAddition.h"
#import "CJSONDeserializer.h"
#import "CJSONSerializer.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "NSData+GZIP.h"
#import "NSDataAES256.h"

//TODO GAME_SERVER_TYPE
//1:内部开发服务器组 2:内部测试服务器组(支线测试：用于测试运营的稳定版本)
//3:外网服务器组 4：内部测试服务器组(主线测试：用于测试开发功能的稳定版本)
#define GAME_SERVER_TYPE 3

static NSString * getGameServerInfo(){
	
	//1:内部开发服务器组===============================================================
#if GAME_SERVER_TYPE==1
	return @"http://dev.zl.efun.com:801/config/servers";
#endif
	//1:内部开发服务器组===============================================================
	
	
	//2:内部测试服务器组===============================================================
#if GAME_SERVER_TYPE==2
	
#if GAME_SNS_TYPE==1
	return @"http://dev.zl.efun.com:801/config/test_zl/servers";
#endif
	
#if GAME_SNS_TYPE==2
	return @"http://dev.zl.efun.com:801/config/test_bd/servers";
#endif
	
#if GAME_SNS_TYPE==4
	return @"http://dev.zl.efun.com:801/config/test_zl/servers";
#endif
	
#endif
	//2:内部测试服务器组===============================================================
	
	
	//3:外网服务器组==================================================================
#if GAME_SERVER_TYPE==3
	
#if GAME_SNS_TYPE==1
	return @"http://115.29.5.60:801/config/servers";
#endif
	
#if GAME_SNS_TYPE==2
	return @"http://web1.zl.52yh.com/game/config/bd91/servers";
#endif
	
#if GAME_SNS_TYPE==4
	return @"http://web1.zl.52yh.com/game/config/zl/servers";
#endif
	
#if GAME_SNS_TYPE==5
	return @"http://web1.zl.52yh.com/game/config/app/servers";
#endif
	
#if GAME_SNS_TYPE==6
	return @"http://web1.zl.52yh.com/game/config/apptw/servers";
#endif
	
#if GAME_SNS_TYPE==7
	//return @"http://web1.zl.52yh.com/game/config/appyd/servers";
	return @"http://web1.zl.52yh.com/game/config/ids/servers";
#endif
	
#if GAME_SNS_TYPE==8
	return @"http://web1.zl.52yh.com/game/config/zl/servers";
#endif
	
#if GAME_SNS_TYPE==9
	//return @"http://web1.zl.52yh.com/game/config/appyd/servers";
	return @"http://web1.zl.52yh.com/game/config/ids/servers";
#endif
	
#if GAME_SNS_TYPE==10
	return @"http://web1.zl.52yh.com/game/config/zl/servers";
#endif
	
#if GAME_SNS_TYPE==11
	return @"http://web1.zl.52yh.com/game/config/zl/servers";
#endif
	
#if GAME_SNS_TYPE==12
	return @"http://web1.zl.52yh.com/game/config/zl/servers";
#endif
	
#endif
	
	//3:外网服务器组==================================================================
	
#if GAME_SERVER_TYPE==4
	return @"http://dev.zl.efun.com/config/test_td/servers";
#endif
	
	return @"http://dev.zl.efun.com:801/config/servers";
	
}

#define GAME_CONNECTION_PORT 8002
#define GAME_CONNECTION_POST 0xFFBC
#define GAME_SOCKET_TIMEOUT 8
#define GAME_SOCKET_TIMER 0.05f

static GameConnection * gameConnection;
static NSMutableArray * memoryRequest = nil;
static GameConnectionRequest * currentRequest = nil;

static int GameConnectionRequestTag = 0;
static int MaxTag = 3000;

static inline int getRequestTag(){
	GameConnectionRequestTag++;
	if(GameConnectionRequestTag>=MaxTag){
		GameConnectionRequestTag++;
	}
	return GameConnectionRequestTag;
}

static inline NSData * readDataFromLength(NSData*data,long length){
	
	long l = [data length]-length;
	NSMutableData * result = [NSMutableData dataWithData:data];
	CFDataDeleteBytes((CFMutableDataRef)result, CFRangeMake(length, l));
	
	/*
	const void * b;
	[data getBytes:&b length:sizeof(100)];
	
	[result appendBytes:&b length:sizeof(b)];
	
	const char * bytes = [data bytes];
	for(long i=0; i<length; i++){
		[result appendBytes:&bytes[i] length:1];
	}
	*/
	
	return result;
}

static inline long swapDataToLong(NSData*data){
	long t = 0;
	int l = [data length];
	NSMutableData * result = [NSMutableData data];
	const char * bytes = [data bytes];
	for(int i=(l-1); i>=0; i--){
		[result appendBytes:&bytes[i] length:1];
	}
	
	[result getBytes:&t length:l];
	return (long)t;
}

static inline BaseHead loadHeadFromData(NSData*data){
	BaseHead head;
	
	unsigned char buffer_tag;
	[data getBytes:&buffer_tag range: NSMakeRange(0,2)];
	head.tag = swapDataToLong([NSData dataWithBytes:&buffer_tag length:2]);
	
	unsigned char buffer_len;
	[data getBytes:&buffer_len range: NSMakeRange(2,4)];
	head.length = swapDataToLong([NSData dataWithBytes:&buffer_len length:4]);
	
	return head;
}

static inline NSData * convertHeadToData(BaseHead head){
	
	uint32_t tTag = CFSwapInt32HostToBig(head.tag);
	uint32_t tLen = CFSwapInt32HostToBig(head.length);
	
	NSMutableData * dTag = [NSMutableData dataWithBytes:&tTag length:4];
	NSMutableData * dLen = [NSMutableData dataWithBytes:&tLen length:4];
	
	CFDataDeleteBytes((CFMutableDataRef)dTag, CFRangeMake(0, 2));
	//CFDataDeleteBytes((CFMutableDataRef)dLen, CFRangeMake(0, 2));
	
	NSMutableData * result = [NSMutableData data];
	[result appendData:dTag];
	[result appendData:dLen];
	
	return result;
}

static inline NSData * convertHeadData(int tag, long length){
	BaseHead tHead;
	tHead.tag = tag;
	tHead.length = length;
	return convertHeadToData(tHead);
}

static NSString * getXXX(){
	return @"4fcc09d3ceb79129";
}

@implementation GameConnection

@synthesize server_time;

@synthesize recommendServerId;
@synthesize currentServerId;
@synthesize currentPlayerId;

@synthesize serverInfo;

+(GameConnection*)share{
	if(!gameConnection){
		gameConnection = [[[GameConnection alloc] init] autorelease];
		//[gameConnection start];
	}
	return gameConnection;
}

+(void)stopAll{
	
	if(memoryRequest){
		id target = memoryRequest;
		memoryRequest = nil;
		[target removeAllObjects];
		[target release];
	}
	GameConnectionRequestTag = 0;
	
	if(gameConnection){
		[NSTimer cancelPreviousPerformRequestsWithTarget:gameConnection];
		[gameConnection stop];
	}
	
}

+(void)freeRequest:(id)target{
	[GameConnectionRequest freeRequest:target];
}

+(void)request:(NSString*)action data:(NSDictionary*)data target:(id)target call:(SEL)call{
	GameConnectionRequest * request = [GameConnectionRequest request];
	
	request.target = target;
	request.call = call;
	
	[request setRequestAction:action];
	[request setRequestFromDict:data];
	
	[request action];
}
+(void)request:(NSString*)action format:(NSString*)format target:(id)target call:(SEL)call{
	GameConnectionRequest * request = [GameConnectionRequest request];
	
	request.target = target;
	request.call = call;
	
	[request setRequestAction:action];
	[request setRequestFromFormat:format];
	
	[request action];
}
+(void)request:(NSString *)action data:(NSDictionary *)data target:(id)target call:(SEL)call arg:(NSDictionary *)_arg
{
	GameConnectionRequest * request = [GameConnectionRequest request];
	
	request.target = target;
	request.call = call;
	
	//----
	request.args = _arg;
	
	[request setRequestAction:action];
	[request setRequestFromDict:data];
	
	[request action];
}
//add soul
+(void)request:(NSString *)action format:(NSString *)format target:(id)target call:(SEL)call arg:(NSDictionary *)_arg
{
	GameConnectionRequest * request = [GameConnectionRequest request];
	
	request.target = target;
	request.call = call;
	//----
	request.args = _arg;
	
	[request setRequestAction:action];
	[request setRequestFromFormat:format];
	
	[request action];
}

+(void)post:(NSString*)post object:(id)object{
	NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName:post object:object];
}

+(void)addPost:(NSString*)post target:(id)target call:(SEL)call{
	[[NSNotificationCenter defaultCenter] addObserver:target 
											 selector:call
												 name:post 
											   object:nil];
}
+(void)removePostTarget:(id)target{
	[[NSNotificationCenter defaultCenter] removeObserver:target];
}

#pragma mark-

-(void)stop{
	
	currentPlayerId = 0;
	action_type = SOCKET_ACTION_TYPE_NONE;
	server_time = 0;
	
	if(userInfo){
		[userInfo release];
		userInfo = nil;
	}
	if(loginInfo){
		[loginInfo release];
		loginInfo = nil;
	}
	if(newInfo){
		[newInfo release];
		newInfo = nil;
	}
	
	if(receiveData){
		[receiveData release];
		receiveData = nil;
	}
	
	if(cRequest){
		[cRequest release];
		cRequest = nil;
	}
	
	if(asyncSocket){
		
		asyncSocket.delegate = nil;
		if(asyncSocket.isConnected){
			[asyncSocket disconnect];
		}
		
	}
	
}

-(void)setServer_time:(long long)_server_time{
	server_time = _server_time;
	[GameConfigure shared].time = server_time;
}

-(void)initObjects{
	action_type = SOCKET_ACTION_TYPE_NONE;
	server_time = 0;
	/*
	if(!asyncSocket){
		dispatch_queue_t mainQueue = dispatch_get_main_queue();
		asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:mainQueue];
	}
	*/
	asyncSocket = [[AsyncSocket alloc] initWithDelegate:self];
	
	if(!cRequest){
		cRequest = [[GameConnectionRequest alloc] initWithTag:GAME_CONNECTION_POST];
		[GameConnectionRequest addToMemory:cRequest];
	}
	if(!receiveData){
		receiveData = [[NSMutableData alloc] init];
	}
	
	asyncSocket.delegate = self;
	cRequest.target = self;
	cRequest.call = @selector(didReceivePush:);
	
}

-(void)loadServersInfo{
	if(serverInfo){
		[GameConnection post:ConnPost_getServersInfo object:nil];
		return;
	}
	[self doLoadServersInfo:YES];
}

-(void)doLoadServersInfo:(BOOL)isDecrypt{
	
	NSString * serverUrl = getGameServerInfo();
	NSString * version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	
#if (GAME_SERVER_TYPE==1 || GAME_SERVER_TYPE == 2)
	version = @"1.0.6";
#endif
	
	NSString * path = [NSString stringWithFormat:@"%@.%@%@",serverUrl,version,(isDecrypt?@".dat":@"")];
	
	ASIHTTPRequest * http = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:path]];
	[http setTimeOutSeconds:3*60];
	[http setCompletionBlock:^{
		
		NSData * responseData = [NSData dataWithData:[http responseData]];
		if(isDecrypt){
			responseData = [responseData AES128DecryptWithKey:getXXX()];
		}
		
		NSError * error = nil;
		NSDictionary * json = [[CJSONDeserializer deserializer] 
							   deserializeAsDictionary:responseData
							   error:&error];
		if(!error){
			serverInfo = [[NSDictionary alloc] initWithDictionary:json];
			
			currentServerId = [[serverInfo objectForKey:@"current"] intValue];
			
			//拿到推荐的服务器ID
			recommendServerId = [[serverInfo objectForKey:@"current"] intValue];
			
			[GameConnection post:ConnPost_getServersInfo object:nil];
		}else{
			if(isDecrypt){
				[self doLoadServersInfo:NO];
			}else{
				[GameConnection post:ConnPost_getServersInfoError object:nil];
			}
		}
		
	}];
	[http setFailedBlock:^{
		[GameConnection post:ConnPost_getServersInfoError object:nil];
	}];
	
	[http startAsynchronous];
	//[http startSynchronous];
	
}

-(void)reloadServersInfo{
	[NSTimer scheduledTimerWithTimeInterval:GAME_SOCKET_TIMER 
									 target:self 
								   selector:@selector(loadServersInfo) 
								   userInfo:nil 
									repeats:NO];
}

-(BOOL)checkCurrentServerCanEnter{
	return [self checkServerCanEnter:currentServerId];
}

-(BOOL)checkServerCanEnter:(int)sid{
	NSDictionary * server = [[GameConnection share] getServerInfoById:sid];
	int status = [[server objectForKey:@"status"] intValue];
	if(status==0 || status==3 || status==4){
		return NO;
	}
	return YES;
}
-(NSDictionary*)getServerInfoById:(int)sid{
	if(serverInfo){
		NSArray * servers = [serverInfo objectForKey:@"servers"];
		for(NSDictionary * server in servers){
			if([[server objectForKey:@"id"] intValue]==sid){
				return server;
			}
		}
	}
	return nil;
}

-(NSString*)getServerHost:(int)sid{
	NSDictionary * server = [self getServerInfoById:sid];
	if(server){
		return [server objectForKey:@"host"];
	}
	return nil;
}

-(int)getServerPort:(int)sid{
	int port = GAME_CONNECTION_PORT;
	NSDictionary * server = [self getServerInfoById:sid];
	if(server){
		if([[server objectForKey:@"port"] intValue]>0){
			port = [[server objectForKey:@"port"] intValue];
		}
	}
	return port;
}
-(NSArray*)getAllActivity{
	if(serverInfo){
		NSArray* array = [NSArray arrayWithArray:[serverInfo objectForKey:@"activity"]];
		NSMutableArray* result = [NSMutableArray array];
		for (NSDictionary* iterator in array) {
			NSString* inc = [iterator objectForKey:@"inc"];
			NSString* exc = [iterator objectForKey:@"exc"];
			
			if (inc.length == 0 && exc.length == 0) {
				//不设定任何条件，那么直接选择
				[result addObject:iterator];
				continue ;
			}
			
			bool isExc = NO ;
			//检测不包含
			if (exc.length > 0) {
				NSArray* temp = [exc componentsSeparatedByString:@","];
				for (NSString* str in temp) {
					int exid = [str intValue];
					if (exid == currentServerId) {
						isExc = YES ;
						break ;
					}
				}
			}
			
			if (isExc) {
				//当前的不包含
				continue ;
			}
			
			if (inc.length > 0) {
				NSArray* temp = [inc componentsSeparatedByString:@","];
				for (NSString* str in temp) {
					int sid = [str intValue];
					if (sid == currentServerId) {
						[result addObject:iterator];
						break ;
					}
				}
			}
		}
		return result;
	}
	return [NSArray array];
}
-(NSArray*)getAllServer{
	if(serverInfo){
		return [serverInfo objectForKey:@"servers"];
	}
	return nil;
}

-(NSString*)getDBPath{
	if(serverInfo){
		NSString * vers = [serverInfo objectForKey:@"db_ver"];
		NSString * path = [serverInfo objectForKey:@"db_path"];
		return [NSString stringWithFormat:@"%@/%@",path,vers];
	}
	return nil;
}
-(NSString*)getGameApiPath:(int)sid{
	if(serverInfo){
		NSString * host = [self getServerHost:sid];
		int port = [self getServerPort:sid];
		if(host!=nil&&port>0){
			port += 1;
			return [NSString stringWithFormat:@"http://%@:%d/api/game",host,port];
		}
	}
	return nil;
}

-(void)getServerPlayers:(NSDictionary*)data server:(int)ser target:(id)target call:(SEL)call{
	
	NSString * path = [NSString stringWithFormat:@"%@/userPlayers?sns=%@&sid=%@",
					   [self getGameApiPath:ser],
					   [data objectForKey:@"SNSID"],
					   [data objectForKey:@"sid"]];
	
	ASIHTTPRequest * http = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:path]];
	[http setTimeOutSeconds:60];
	[http setCompletionBlock:^{
		
		NSData * responseData = [http responseData];
		responseData = [responseData AES128DecryptWithKey:getXXX()];
		
		NSError * error = nil;
		NSArray * json = [[CJSONDeserializer deserializer] 
							   deserializeAsArray:responseData
							   error:&error];
		if(!error){
			if(target!=nil && call!=nil){
				[target performSelector:call withObject:json];
			}
		}else{
			if(target!=nil && call!=nil){
				[target performSelector:call withObject:nil];
			}
		}
		
	}];
	[http setFailedBlock:^{
		if(target!=nil && call!=nil){
			[target performSelector:call withObject:nil];
		}
	}];
	//[http startAsynchronous];
	[http startSynchronous];
	
}

-(void)connection{
	
	CCLOG(@"GameConnection connection ... ");
	
	[self initObjects];
	
	action_type = SOCKET_ACTION_TYPE_LOGIN;
	
	NSString * host = [self getServerHost:currentServerId];
	int port = [self getServerPort:currentServerId];
	
	if(host!=nil&&port>0){
		NSError * error = nil;
		if(![asyncSocket connectToHost:host onPort:port withTimeout:GAME_SOCKET_TIMEOUT error:&error]){
			[self postTimeout];
		}
	}else{
		[self postTimeout];
	}
	
}

-(void)disconnect{
	[asyncSocket disconnect];
}
-(BOOL)isConnection{
	return asyncSocket.isConnected;
}

-(BOOL)isDidEnterServer{
	if(action_type>SOCKET_ACTION_TYPE_ENTER_SERVER){
		return YES;
	}
	return NO;
}

-(void)readData{
	
	//[asyncSocket readDataWithTimeout:-1 tag:0];
	//[asyncSocket readDataToLength:0 withTimeout:-1 tag:0];
	
	[asyncSocket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:32 tag:0];
	
}

-(void)sendRequest:(GameConnectionRequest*)request{
	[asyncSocket writeData:request.requestData withTimeout:-1 tag:request.tag];
	[self readData];
}

-(void)didReceivePush:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		NSString * func = getResponseFunc(response);
		id data = getResponseData(response);
		//CCLOG(@"%@ -> \n%@",func,data);
		//TODO 广播数据 多种
		if(isEqualToKey(func,@"init")){
			[[GameConfigure shared] initPlayerData:data];
			[GameConnection post:ConnPost_init object:data];
			return;
		}
		if(isEqualToKey(func, @"taskPush")){
			[[GameConfigure shared] addNewUserTasks:data];
			[GameConnection post:ConnPost_taskPush object:data];
			return;
		}
		if(isEqualToKey(func, @"mapChange")){
			[GameConnection post:ConnPost_MapPush object:data];
			return;
		}
		if(isEqualToKey(func, @"mailPush")){
			//todo 重新处理右键的结构
			// data{
			//MAIL:[]
			//WAIT:[]
			//}
			
			[GameConnection post:ConnPost_MailPush object:data];
			return;
		}
		if(isEqualToKey(func, @"addSitExp")){
			//TODO 打坐 每分钟返回经验
			[GameConnection post:ConnPost_playerSit object:data];
			
		}
		if(isEqualToKey(func, @"upLevel")){
			[[GameConfigure shared] updatePlayerInfo:[data objectForKey:@"player"]];
			[GameConnection post:ConnPost_updatePlayerInfo object:nil];
			[GameConnection post:ConnPost_updatePlayerUpLevel object:nil];
		}
		if(isEqualToKey(func, @"chatMsg"))
		{
			[GameConnection post:ConnPost_ChatPush object:data];
		}
		if(isEqualToKey(func, @"update")){
			[GameConnection post:ConnPost_updatePackageLuck object:data];
			[[GameConfigure shared] updatePackage:data];
		}
		if(isEqualToKey(func, @"goodsGive")){
			
			int coin = [[GameConfigure shared] getPlayerCoin2];
			
			NSDictionary * result = [NSDictionary dictionaryWithDictionary:data];
			int getCoin = [[[result objectForKey:@"data"] objectForKey:@"coin2"] intValue] - coin;
			
			NSMutableDictionary *coinDict = [NSMutableDictionary dictionary];
			[coinDict setObject:[NSNumber numberWithInt:getCoin] forKey:@"getCoin"];
			
			[GameConnection post:ConnPost_goodsGive object:coinDict];
			
			[[GameConfigure shared] updatePackage:[result objectForKey:@"data"]];
			[[GameConfigure shared] updatePlayerInfo:[result objectForKey:@"player"]];
			[[GameConfigure shared] updateVipConfig:[result objectForKey:@"vipData"]];
			
		}
		
		if(isEqualToKey(func, @"bossNotice")){
			[GameConnection post:ConnPost_WorldBoss_Start object:data];
		}
		if(isEqualToKey(func, @"bossHp")){
			[GameConnection post:ConnPost_WorldBoss_Hurts object:data];
		}
		if(isEqualToKey(func, @"bossRank")){
			[GameConnection post:ConnPost_WorldBoss_Rank object:data];
		}
		
		// 狩龙
		if (isEqualToKey(func, @"awarNotice")) {
			[DragonCountdown acceptPush:data];
		}
		if (isEqualToKey(func, @"awarEnterRoomB")) {
			[GameConnection post:ConnPost_Dragon_enterRoom object:data];
		}
		if (isEqualToKey(func, @"awarExitRoomB")) {
			[GameConnection post:ConnPost_Dragon_exitRoom object:data];
		}
		if (isEqualToKey(func, @"awarStartB")) {
			[GameConnection post:ConnPost_Dragon_startFight object:data];
		}
		if (isEqualToKey(func, @"awarMosterStartB")) {
			[GameConnection post:ConnPost_Dragon_killMonsterStart object:data];
		}
		if (isEqualToKey(func, @"awarMosterEndB")) {
			[GameConnection post:ConnPost_Dragon_killMonsterEnd object:data];
		}
		if (isEqualToKey(func, @"awarFireB")) {
			[GameConnection post:ConnPost_Dragon_fire object:data];
		}
		if (isEqualToKey(func, @"awarBossHp")) {
			[GameConnection post:ConnPost_Dragon_bossHp object:data];
		}
		if (isEqualToKey(func, @"awarHardB")) {
			[GameConnection post:ConnPost_Dragon_hard object:data];
		}
		if (isEqualToKey(func, @"awarWorldMapB")) {
			[GameConnection post:ConnPost_Dragon_worldMap object:data];
		}
		if (isEqualToKey(func, @"awarWorldChooseB")) {
			[GameConnection post:ConnPost_Dragon_warChoose object:data];
		}
		if (isEqualToKey(func, @"awarRs")) {
			[GameConnection post:ConnPost_Dragon_result object:data];
		}
		// end
		
		//同盟BOSS
		if(isEqualToKey(func, @"allyBossNotice")){
			[GameConnection post:ConnPost_allyBossRank_Start object:data];
		}
		
		if(isEqualToKey(func, @"allyBossHp")){
			[GameConnection post:ConnPost_allyBossRank_Hurts object:data];
		}
		
		if(isEqualToKey(func, @"allyBossRank")){
			[GameConnection post:ConnPost_allyBossRank_Rank object:data];
		}
		
		if (isEqualToKey(func, @"achiUpdate")) {
			[GameConnection post:ConnPost_achiUpdate object:data];
		}
		if(isEqualToKey(func, @"TeamInfo")){
			[GameConnection post:ConnPost_AllyParTeamInfo object:data];
		}
		if(isEqualToKey(func, @"TeamDisband")){
			[GameConnection post:ConnPost_AllyParTeamDisband object:data];
			
		}
		if(isEqualToKey(func, @"allyTTBoxEnd")){
			[GameConnection post:ConnPost_AllyParTeamFigthInfo object:data];
		}
		
		
		//TODO 接受同盟更新的信息，并且POST 出去
		if (isEqualToKey(func, @"allyUpdate")) {
            NSDictionary* _dict =nil;
            _dict =[data objectForKey:@"apply"];
            if (_dict) {
                //加入
                NSDictionary* _info = [_dict objectForKey:@"ally"];
                if(_info){
                    [[GameConfigure shared] setPlayerAlly:_info];
                    [GameConnection post:ConnPost_AllyApply_success object:nil];
                }
                return ;
            }
            
            _dict =nil;
            _dict =[data objectForKey:@"kick"];
            if(_dict){
                //踢出
                [[GameConfigure shared] removePlayerAlly];
                [GameConnection post:ConnPost_KickApply_success object:nil];
            }
            
		}
		
	}else{
        [GameConnection post:ConnPost_response_error object:response];
        //
		NSString * m = getResponseMessage(response);
		if(m) CCLOG(m);
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark-
////////////////////////////////////////////////////////////////////////////////

//用户登录
/*
-(void)login:(NSString*)name password:(NSString*)pass{
	
	if(username) [username release];
	if(password) [password release];
	
	username = name;
	password = pass;
	
	[username retain];
	[password retain];
	
	[self connection];
}
*/

-(void)loginSNSUser:(NSDictionary*)data{
	login_type = LOGIN_TYPE_SNS;
	
	if(userInfo) [userInfo release];
	userInfo = [NSDictionary dictionaryWithDictionary:data];
	[userInfo retain];
	
	[self connection];
}

-(void)loginLocalUser{
	login_type = LOGIN_TYPE_LOCAL;
	//[self login:@"" password:@""];
	[self connection];
}

-(void)didLogin:(NSDictionary*)response{
	
	if(checkResponseStatus(response)){
		
		if(loginInfo){
			[loginInfo release];
			loginInfo = nil;
		}
		
		loginInfo = [[NSDictionary alloc] initWithDictionary:getResponseData(response)];
		server_time = [[loginInfo objectForKey:@"time"] longLongValue];
		
		GameConfigure * config = [GameConfigure shared];
		config.userId = [[loginInfo objectForKey:@"uid"] intValue];
		config.serverId = currentServerId;
		
		action_type = SOCKET_ACTION_TYPE_LOGIN_ED;
		
	}else{
		[self postTimeout];
	}
	
	[self disconnect];
	
}

//用户退出
-(void)logout{
	CCLOG(@"Game logout");
	[GameConnection stopAll];
	[GameConnection request:@"logout" format:nil target:nil call:nil];
}

//进入服务器
-(void)loginServer{
	action_type = SOCKET_ACTION_TYPE_ENTER_SERVER;
	NSError * error = nil;
	
	NSString * server_adds = [loginInfo objectForKey:@"ip"];
	int server_port = [[loginInfo objectForKey:@"port"] intValue];
	
	if(![asyncSocket connectToHost:server_adds onPort:server_port 
					   withTimeout:GAME_SOCKET_TIMEOUT error:&error]
	   ){
		[self postTimeout];
	}
	
}

-(void)didLoginServer:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		action_type = SOCKET_ACTION_TYPE_ENTER_SERVER_ED;
		[GameConnection post:ConnPost_login object:nil];
		
		//[self getPlayers];
		
	}else{
		[self disconnect];
	}
}

-(void)getPlayers{
	[GameConnection request:@"players" format:nil target:self call:@selector(didLoadPlayers:)];
}

-(void)didLoadPlayers:(NSDictionary*)response{
	
	if(checkResponseStatus(response)){
		NSArray * pList = getResponseData(response);
		
		GameConfigure * config = [GameConfigure shared];
		[config savePlayerList:pList];
		
		[GameConnection post:ConnPost_playerList object:pList];
		
		
	}else{
		[self disconnect];
	}
}

-(void)newPlayer:(NSString*)name rid:(int)rid{
	
	if(action_type==SOCKET_ACTION_TYPE_ENTER_GAME){
		
		newInfo = [NSDictionary dictionaryWithObjectsAndKeys:
				   [NSNumber numberWithInt:rid],@"rid",
				   name, @"name", 
				   nil];
		[newInfo retain];
		
		[GameConnection post:ConnPost_InGame_New object:nil];
		[GameConnection request:@"leave" format:nil target:self call:@selector(didLeavePlayerInGame:)];
		
	}else{
		
		NSString * str = [NSString stringWithFormat:@"name:%@|rid::%d",name,rid];
		[GameConnection request:@"new" format:str target:self call:@selector(didNewPlayer:)];
		
	}
	
}

-(void)didLeavePlayerInGame:(NSDictionary*)response{
	
	if(checkResponseStatus(response)){
		
		action_type = SOCKET_ACTION_TYPE_ENTER_SERVER_ED;
		
		if(newInfo){
			[self newPlayer:[newInfo objectForKey:@"name"] 
						rid:[[newInfo objectForKey:@"rid"] intValue]];
			[newInfo release];
			newInfo = nil;
		}
		
	}
	
}

-(void)didNewPlayer:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		NSDictionary * role = getResponseData(response);
		GameConfigure * config = [GameConfigure shared];
		[config addPlayerToList:role];
		
		int pid = [[role objectForKey:@"id"] intValue];
		[self enterPlayer:pid];
		
	}else{
		
		[GameConnection post:ConnPost_CreateRoleError object:response];
	}
}

-(void)enterCurrentPlayer{
	[GameConnection post:ConnPost_start object:[NSNumber numberWithInt:currentPlayerId]];
	NSString * str = [NSString stringWithFormat:@"id::%d",currentPlayerId];
	[GameConnection request:@"enter" format:str target:self call:@selector(didEnterPlayer:)];
}

-(void)enterPlayer:(int)pid{
	
	currentPlayerId = pid;
	
	if(action_type==SOCKET_ACTION_TYPE_ENTER_GAME){
		did_pid = pid;
		//[GameConnection post:ConnPost_InGame_Change object:nil];
		[GameConnection request:@"leave" format:nil target:self call:@selector(didLeavePlayerChange:)];
	}else{
		[self enterCurrentPlayer];
	}
	
}

-(void)didLeavePlayerChange:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		action_type = SOCKET_ACTION_TYPE_ENTER_SERVER_ED;
		
		[GameConnection post:ConnPost_start object:[NSNumber numberWithInt:did_pid]];
		
		NSString * str = [NSString stringWithFormat:@"id::%d",did_pid];
		[GameConnection request:@"enter" format:str target:self call:@selector(didEnterPlayer:)];
		
	}
}

-(void)didEnterPlayer:(NSDictionary*)response{
	
	if(checkResponseStatus(response)){
		
		action_type = SOCKET_ACTION_TYPE_ENTER_GAME;
		
		NSDictionary * data = getResponseData(response);
		[GameConnection post:ConnPost_enter object:data];
		
	}else{
		//TODO reCall ???
		
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Socket Delegate
////////////////////////////////////////////////////////////////////////////////
-(void)onSocket:(AsyncSocket*)sock didConnectToHost:(NSString*)host port:(UInt16)port{
	[self socket:nil didConnectToHost:host port:port];
}
-(void)onSocket:(AsyncSocket*)sock didWriteDataWithTag:(long)tag{
	[self readData];
	[GameConnectionRequest didSendDataWithTag:tag];
}
-(void)onSocket:(AsyncSocket*)sock didReadData:(NSData*)data withTag:(long)tag{
	[self socket:nil didReadData:data withTag:tag];
}
-(void)onSocketDidDisconnect:(AsyncSocket*)sock{
	[self socketDidDisconnect:nil withError:nil];
}
-(void)onSocket:(AsyncSocket*)sock willDisconnectWithError:(NSError*)err{
	[self socketDidDisconnect:nil withError:err];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Socket Delegate GCD
////////////////////////////////////////////////////////////////////////////////
-(void)socket:(GCDAsyncSocket*)sock didConnectToHost:(NSString*)host port:(UInt16)port{
	
	CCLOG(@"GameConnection connection success ... ");
	
	[self readData];
	
	if(action_type==SOCKET_ACTION_TYPE_LOGIN){
		
		NSString * udid = [[UIDevice currentDevice] uniqueDeviceIdentifier];
		NSString * dt = [[UIDevice currentDevice] deviceToken];
		NSString * mac = [[UIDevice currentDevice] macaddress];
		NSString * dev = getDeviceName();
		NSString * ver = [[UIDevice currentDevice] systemVersion];
		
		if(login_type==LOGIN_TYPE_LOCAL){
			/*
			NSString * str = [NSString stringWithFormat:@"user:|pwd:|UDID:%@|DT:%@|MAC:%@|DEV:%@|VER:%@",udid,dt,mac,dev,ver];
			[GameConnection request:@"login" format:str target:self call:@selector(didLogin:)];
			*/
		}
		
		if(login_type==LOGIN_TYPE_SNS){
			
			int type = [[userInfo objectForKey:@"SNSID"] intValue];
			NSString * sid = [userInfo objectForKey:@"sid"];
			NSString * session = [userInfo objectForKey:@"session"];
			
			NSMutableDictionary * data = [NSMutableDictionary dictionary];
			
			[data setObject:[NSNumber numberWithInt:type] forKey:@"t"];
			[data setObject:sid forKey:@"sid"];
			[data setObject:session forKey:@"session"];
			
			[data setObject:udid forKey:@"UDID"];
			[data setObject:dt forKey:@"DT"];
			[data setObject:mac forKey:@"MAC"];
			[data setObject:dev forKey:@"DEV"];
			[data setObject:ver forKey:@"VER"];
			
			[GameConnection request:@"loginSNS" data:data target:self call:@selector(didLogin:)];
			
			/*
			NSString * str = [NSString stringWithFormat:
							  @"t::%d|sid:%@|session:%@|UDID:%@|DT:%@|MAC:%@|DEV:%@|VER:%@",
							  type,sid,session,udid,dt,mac,dev,ver];
			[GameConnection request:@"loginSNS" format:str target:self call:@selector(didLogin:)];
			*/
			
		}
		
		return;
	}
	
	if(action_type==SOCKET_ACTION_TYPE_ENTER_SERVER){
		
		int userId = [[loginInfo objectForKey:@"uid"] intValue];
		NSString * server_keys = [loginInfo objectForKey:@"key"];
		NSString * str = [NSString stringWithFormat:@"user::%d|key:%@",userId,server_keys];
		[GameConnection request:@"login1" format:str target:self call:@selector(didLoginServer:)];
		
	}
	
}
-(void)socket:(GCDAsyncSocket*)sock didWriteDataWithTag:(long)tag{
	[self readData];
	[GameConnectionRequest didSendDataWithTag:tag];
}
-(void)socket:(GCDAsyncSocket*)sock didReadData:(NSData*)data withTag:(long)tag{
	
	[self readData];
	
	//CCLOG(@"\n didReadData \n");
	//CCLOG(@"data length : %d",[data length]);
	//CCLOG(@"%@",[data description]);
	
	if([data isEqualToData:[GameConnectionRequest BlockPing]]){
		CCLOG(@"block ping");
		return;
	}
	
	[receiveData appendData:data];
	
	long length = [self loadReceiveLength];
	
	while(YES){
		if([receiveData length]>=length && [receiveData length]>0 && length>0){
			NSData * result = readDataFromLength(receiveData, length);
			
			//CCLOG(@"\n\n%@\n\n",[result description]);
			
			CFDataDeleteBytes((CFMutableDataRef)receiveData, CFRangeMake(0,length));
			
			[GameConnectionRequest didReceiveData:result];
			
			length = [self loadReceiveLength];
		}else{
			break;
		}
	}
	
}
-(void)socketDidDisconnect:(GCDAsyncSocket*)sock withError:(NSError*)err{
	
	CCLOG(@"socketDidDisconnect");
	
	if(action_type==SOCKET_ACTION_TYPE_LOGIN){
		[self postTimeout];
		return;
	}
	
	if(action_type==SOCKET_ACTION_TYPE_LOGIN_ED){
		[self loginServer];
		return;
	}
	
	if(action_type==SOCKET_ACTION_TYPE_ENTER_SERVER){
		[self postTimeout];
		return;
	}
	if(action_type==SOCKET_ACTION_TYPE_ENTER_SERVER_ED){
		[self postDisconnect];
		return;
	}
	if(action_type==SOCKET_ACTION_TYPE_ENTER_GAME){
		[self postDisconnect];
		return;
	}
	
}

#pragma mark-

-(void)postDisconnect{
	action_type = SOCKET_ACTION_TYPE_NONE;
	[GameConnection post:ConnPost_disconnect object:nil];
}

-(void)postTimeout{
	action_type = SOCKET_ACTION_TYPE_NONE;
	[GameConnection post:ConnPost_connect_timeout object:nil];
}

//平叔叔说在这里要处理一下心跳包 MaxLeung
-(long)loadReceiveLength{
	if([receiveData length]>4){
		char buff[4];
		[receiveData getBytes:buff length:4];
		NSMutableData *nsbuff=[[[NSMutableData alloc]initWithBytes:buff length:4] autorelease];
		if([nsbuff isEqualToData:[GameConnectionRequest BlockPing]]){
			CFDataDeleteBytes((CFMutableDataRef)receiveData, CFRangeMake(0,4));
		}
		//[nsbuff release];
	}
	if([receiveData length]>6){
		BaseHead head = loadHeadFromData(receiveData);
		return head.length + 6;
	}
	return 0;
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark GameConnectionRequest
////////////////////////////////////////////////////////////////////////////////

@implementation GameConnectionRequest
@synthesize tag;
@synthesize target;
@synthesize call;
@synthesize requestData;
//add soul
@synthesize args=argument;

+(NSData*)BlockPing{
	return [NSData dataWithBytes:"\x00\x00\x00\x04" length:4];
}

+(GameConnectionRequest*)request{
	GameConnectionRequest * request = [[[GameConnectionRequest alloc] init] autorelease];
	[GameConnectionRequest addToMemory:request];
	return request;
}

+(void)addToMemory:(id)target{
	if(!memoryRequest){
		memoryRequest = [[NSMutableArray alloc] init];
	}
	[memoryRequest addObject:target];
}
+(void)removeMemory:(id)target{
	if(memoryRequest){
		[memoryRequest removeObject:target];
	}
}

+(void)didSendDataWithTag:(int)tag{
	NSArray * targets = [NSArray arrayWithArray:memoryRequest];
	for(GameConnectionRequest * request in targets){
		if(request.tag==tag){
			[request cleantRequestData];
		}
	}
}

+(void)freeRequest:(id)target{
	if(memoryRequest){
		NSArray * targets = [NSArray arrayWithArray:memoryRequest];
		for(GameConnectionRequest * request in targets){
			if(request.target==target){
				[request free];
			}
		}
	}
}

+(void)didReceiveData:(NSData*)data{
	if(currentRequest==nil){
		BaseHead head = loadHeadFromData(data);
		for(GameConnectionRequest * request in memoryRequest){
			if(request.tag==head.tag){
				currentRequest = request;
				[currentRequest receiveData:data];
				return;
			}
		}
	}
	[currentRequest receiveData:data];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

-(id)initWithTag:(int)_tag{
	if((self = [super init])){
		tag = _tag;
		requestDict = [[NSMutableDictionary alloc] init];
	}
    return self;
}

-(id)init{
	if((self = [super init])){
		tag = getRequestTag();
		requestDict = [[NSMutableDictionary alloc] init];
	}
    return self;
}

-(void)dealloc{
	
	CCLOG(@"GameConnectionRequest dealloc %d",tag);
	//add soul
	if (argument) {
		[argument release];;
		argument = nil;
	}
	[self cleantRequestDict];
	[self cleantRequestData];
	[self cleanResponseData];
	
	[super dealloc];
}

-(void)setTarget:(id)_target{
	if(_target){
		target = _target;
		if(target!=gameConnection){
			[target retain];
		}
	}
}

-(void)free{
	target = nil;
	//call = nil;
}

#pragma mark-

-(void)cleantRequestDict{
	if(requestDict){
		[requestDict release];
		requestDict = nil;
	}
}
-(void)cleantRequestData{
	if(requestData){
		[requestData release];
		requestData = nil;
	}
	if(target==nil && call==nil){
		[GameConnectionRequest removeMemory:self];
	}
}
-(void)cleanResponseData{
	if(responseData){
		[responseData release];
		responseData = nil;
	}
}

-(void)getRequestData{
	
	if(!requestDict) return;
	
	NSError * error = nil;
	NSData * json = [[CJSONSerializer serializer] serializeObject:requestDict error:&error];
	if(error){
		CCLOG(@"#ERROR");
		return;
	}
	
	//json = [json gzippedData];
	json = [NSData gzipData:json];
	
	//NSData * s = [json gunzippedData];
	//NSDictionary * jsondata = [[CJSONDeserializer deserializer] deserializeAsDictionary:s error:nil];
	
	long length = [json length];
	
	requestData = [NSMutableData dataWithData:convertHeadData(tag,length)];
	[requestData appendData:json];
	[requestData retain];
	
	[self cleantRequestDict];
	
}

-(void)action{
	[self getRequestData];
	if(!requestData) return;
	[[GameConnection share] sendRequest:self];
}

#pragma mark-

-(void)setRequestAction:(NSString*)action{
	[requestDict setObject:action forKey:@"f"];
}
-(void)setRequestFromDict:(NSDictionary*)dict{
	if(!dict) return;
	if([dict count]!=0){
		[requestDict setObject:dict forKey:@"d"];
	}
}

-(void)setRequestFromFormat:(NSString*)format{
	if(!format) return;
	NSMutableDictionary * dict = [NSMutableDictionary dictionary];
	NSArray * ary1 = [format componentsSeparatedByString:@"|"];
	for(NSString * v in ary1){
		NSArray * ary2 = [v componentsSeparatedByString:@":"];
		//string
		if([ary2 count]==2){
			[dict setObject:[ary2 objectAtIndex:1] forKey:[ary2 objectAtIndex:0]];
		}
		//int
		if([ary2 count]==3){
			NSNumber * num = [NSNumber numberWithInt:[[ary2 objectAtIndex:2] intValue]];
			[dict setObject:num forKey:[ary2 objectAtIndex:0]];
		}
		
	}
	[self setRequestFromDict:dict];
}

/*
-(void)receiveData:(NSData*)data length:(long)length{
	responseLength = length;
	if(!responseData){
		responseData = [[NSMutableData alloc] init];
	}
	
	[responseData appendData:data];
	CFDataDeleteBytes((CFMutableDataRef)responseData, CFRangeMake(0,6));
	
	[self checkCompleteReceiveData];
}
*/

-(void)receiveData:(NSData*)data{
	if(!responseData){
		responseData = [[NSMutableData alloc] init];
		BaseHead head = loadHeadFromData(data);
		responseLength = head.length;
	}
	[responseData appendData:data];
	[self checkCompleteReceiveData];
	
	//tag = -1;
	
}

-(void)checkCompleteReceiveData{
	
	//CCLOG(@"checkCompleteReceiveData : %i / %lu ",[responseData length], (responseLength+6));
	
	if([responseData length]>=(responseLength+6)){
		
		currentRequest = nil;
		
		CFDataDeleteBytes((CFMutableDataRef)responseData, CFRangeMake(0,6));
		
		NSData * data = [NSData dataWithData:responseData];
		data = [data AES128DecryptWithKey:getXXX()];
		data = [data gunzippedData];
		//CCLOG(@"%d / %d",[data length], [responseData length]);
		
		NSError * error = nil;
		NSDictionary * json = [[CJSONDeserializer deserializer] 
							   deserializeAsDictionary:data error:&error];
		if(!error){
			if(!checkResponseStatus(json)){
				//CCLOG(@"#ERROR : %@",getResponseMessage(json));
				CCLOG(@"#ERROR");
			}
		}else{
			json = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"0",@"#ERROR 1", nil]
											   forKeys:[NSArray arrayWithObjects:@"s",@"m", nil] 
					];
		}
		
		CCLOG(@"\n\n %@ \n\n",[json description]);
		
		[self cleanResponseData];
		
//		@try {
			if(target!=nil&&call!=nil){
				if (argument) {
					[target performSelector:call withObject:json withObject:argument];
				}else{
					[target performSelector:call withObject:json];
				}
				
				if(target!=gameConnection){
					[target release];
					target = nil;
				}
				
			}else if (target == nil && call != nil) {
				//todo 保护回调数据
				CCLOG(@"#Warning！save data to client!");
				NSMutableDictionary* netData = [NSMutableDictionary dictionary];
				[netData setObject:json forKey:@"json"];
				if (argument != nil) {
					[netData setObject:[NSDictionary dictionaryWithDictionary:argument] forKey:@"arg"];
				}else{
					[netData setObject:[NSDictionary dictionary] forKey:@"arg"];
				}
				[GameConnection post:ConnPost_writeDataSecurity object:netData];
			}
//		}
//		@catch (NSException *exception) {
//			CCLOG(@" [receive error!!!] ");
//		}
//		@finally {
//			
//		}
		
		if(tag!=GAME_CONNECTION_POST){
			//[memoryRequest removeObject:self];
			[GameConnectionRequest removeMemory:self];
		}else{
			//CCLOG(@"server pots data to client");
			
		}
		
	}
}

@end
