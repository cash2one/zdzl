//
//  PlayerSit.m
//  TXSFGame
//
//  Created by Max on 13-1-31.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "PlayerSit.h"
#import "Config.h"
#import "GameDB.h"
#import "GameConfigure.h"
#import "GameConnection.h"

#import "MapManager.h"
#import "FightManager.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "TaskTalk.h"
#import "AlertManager.h"
#import "GameLayer.h"
#import "WorldMap.h"
#import "StageTask.h"
#import "UnionPracticeConfigTeam.h"
#import "FishingManager.h"
#import "TaskManager.h"

static float PLAYER_SITTING_TOTAL_TIME; //(24*60*60)
static float PLAYER_SITTING_CHECK_TIME; //10

@implementation PlayerSitManager

@synthesize isInSitting;
@synthesize totalExp;
@synthesize endSitTime;


static PlayerSitManager * playerSitManager;
static BOOL isCanSit;

static void updatePlayerSitConfig(){
	NSDictionary * config = [[GameDB shared] getGlobalConfig];
	
	PLAYER_SITTING_CHECK_TIME = [[config objectForKey:@"sitExpPerTime"] floatValue];
	PLAYER_SITTING_TOTAL_TIME = [[config objectForKey:@"sitTimeMax"] floatValue];
	
}

+(PlayerSitManager*)shared{
	if(playerSitManager==nil){
		updatePlayerSitConfig();
		playerSitManager = [[PlayerSitManager alloc] init];
	}
	return playerSitManager;
}
+(void)stopAll{
	if(playerSitManager){
		[playerSitManager stopTimer];
		[playerSitManager release];
		playerSitManager = nil;
	}
	isCanSit = NO;
	[PlayerSit hide];
}

+(BOOL)isCanSit{
	
	if([[GameConfigure shared] isPlayerOnChapter]){
		return NO;
	}
	
	NSDictionary * systemConfig = [[GameDB shared] getGlobalConfig];
	NSDictionary * playerInfo = [[GameConfigure shared] getPlayerInfo];
	
	int level = [[playerInfo objectForKey:@"level"] intValue];
	int sitLevel = [[systemConfig objectForKey:@"sitBeginLevel"] intValue];
	
	if(level>=sitLevel){
		return YES;
	}
	
	return NO;
}

-(void)dealloc{
    [GameConnection freeRequest:self];
	[super dealloc];
}

-(void)setIsInSitting:(BOOL)_isInSitting{
	isInSitting = _isInSitting;
	if(isInSitting){
		endSitTime = PLAYER_SITTING_TOTAL_TIME;
	}else{
		endSitTime = 0;
	}
}

-(void)stopTimer{
	if(checkTimer){
		[checkTimer invalidate];
		checkTimer = nil;
	}
	[GameConnection removePostTarget:self];
}

-(void)start{
	
	[GameConnection addPost:ConnPost_playerSit target:self call:@selector(onPlayerSitTimerExp:)];
	[GameConnection addPost:ConnPost_updatePlayerUpLevel target:self call:@selector(checkUpLevelCanSit:)];
	
	isCanSit = [PlayerSitManager isCanSit];
	
	[self checkStart];
	
}

-(void)checkStart{
	if(isCanSit && checkTimer==nil){
		
		RolePlayer * player = [RoleManager shared].player;
		if(player.state==Player_state_sit){
			self.isInSitting = YES;
			[self getOnlineSitExp];
		}else{
			self.isInSitting = NO;
		}
		
		checkTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
													  target:self
													selector:@selector(checkSitCount)
													userInfo:nil
													 repeats:YES];
		
	}
}

-(void)startSit{
    //先停止玩家移动
	[[RoleManager shared].player stopMoveAndTask];
	[[TaskManager shared] stopTask];
    
	//todo
	//这里增加检测能不能进行打坐的检测
	
	if(self.isInSitting)return;
	[[RoleManager shared ]stopMovePlayer];
	self.isInSitting = YES;
	
	RolePlayer * player = [RoleManager shared].player;
	player.state = Player_state_sit;
	
	[PlayerSit show];
	//
	[GameConnection request:@"startSit" format:@"" target:nil call:nil];
	
}


-(void)checkSitCount{
	
	if(self.isInSitting){
		endSitTime--;
		[PlayerSit update];
		return;
	}
	
	if(![self checkCanSitOnGame]) return;
	if([TaskTalk isTalking] || [StageTask isTalking]){
		timerCount=0;
		return;
	}
	if([UnionPracticeConfigTeam isOpen]){
		timerCount=0;
		return;
	}
	
	
	CCLOG(@"打坐倒计时:%i",timerCount);
	
	if(timerCount>PLAYER_SITTING_CHECK_TIME){
		[self startSit];
		/*
		 self.isInSitting = YES;
		 
		 RolePlayer * player = [RoleManager shared].player;
		 player.state = Player_state_sit;
		 
		 [PlayerSit show];
		 
		 [GameConnection request:@"startSit" format:@"" target:nil call:nil];
		 */
		
	}else{
		timerCount++;
	}
	
}

-(BOOL)checkCanSitOnGame{
	
	BOOL isCanSitOnGame = YES;
	
	if(self.isInSitting)			isCanSitOnGame = NO;
	if([TaskTalk isTalking])		isCanSitOnGame = NO;
	if([FightManager isFighting])	isCanSitOnGame = NO;
	if([AlertManager hasAlert])		isCanSitOnGame = NO;
	if([WorldMap isShow])			isCanSitOnGame = NO;
	if([FishingManager checkIsFishing])			isCanSitOnGame = NO;
	//TODO all map type can sit???
	if(
       //[MapManager shared].mapType==Map_Type_Fish		||
	   //[MapManager shared].mapType==Map_Type_WorldBoss	||
	   //[MapManager shared].mapType==Map_Type_UnionBoss	||
	   //[MapManager shared].mapType==Map_Type_Abyss		||
	   //[MapManager shared].mapType==Map_Type_Mining	||
	   //[MapManager shared].mapType==Map_Type_TimeBox	||
	   NO){
		isCanSitOnGame = NO;
	}
	
	RolePlayer * player = [RoleManager shared].player;
	if(player==nil){
		isCanSitOnGame = NO;
	}else{
		if([player isRunning]) isCanSitOnGame = NO;
		if(player.state!=Player_state_normal) isCanSitOnGame = NO;
	}
	
	if(isCanSitOnGame==NO){
		timerCount = 0;
	}
	
	return isCanSitOnGame;
}

-(void)stopSit{
	
	if(!isCanSit) return;
	
	//RolePlayer * player = [RoleManager shared].player;
	//if(player.state==Player_state_sit){
	if(self.isInSitting){
		
		self.isInSitting = NO;
		
		RolePlayer * player = [RoleManager shared].player;
		player.state = Player_state_normal;
		[GameConnection request:@"stopSit" format:@"" target:nil call:nil];
		
		[PlayerSit hide];
		
		
		//TODO save player exp???
		
	}
	timerCount = 0;
	totalExp = 0;
}

-(void)getOnlineSitExp{
	[GameConnection request:@"onlineSitExp" format:@"" target:self call:@selector(didGetOnlineSitExp:)];
}

-(void)didGetOnlineSitExp:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSDictionary * dict = getResponseData(response);
		if(dict){
			totalExp = [[dict objectForKey:@"addExp"] intValue];
			endSitTime = [[dict objectForKey:@"canSitTime"] intValue];
			int meExp=[[dict objectForKey:@"exp"] intValue];
			[[GameConfigure shared]setPlayerExp:meExp];
			if(endSitTime==0){
				self.isInSitting=YES;
				[self stopSit];
				[[MainMenu share]updateExp];
				RolePlayer * player = [RoleManager shared].player;
				[player setState:Player_state_normal];
				[player stopMove];
				return;
			}
			[PlayerSit show];
		}
	}
}

-(void)onPlayerSitTimerExp:(NSNotification*)notification{
	NSDictionary *data = notification.object;
	if(data){
		int lastExp=[[data objectForKey:@"exp"] intValue]-totalExp;
		totalExp =[[data objectForKey:@"exp"] intValue];
		int srcExp=[[GameConfigure shared]getPlayerExp]+lastExp;
		[[GameConfigure shared]setPlayerExp:srcExp];
		[[MainMenu share]updateExp];
	}
}

-(void)checkUpLevelCanSit:(NSNotification*)notification{
	if(!isCanSit){
		isCanSit = [PlayerSitManager isCanSit];
		[self checkStart];
	}
}

@end


@implementation PlayerSit

static PlayerSit * playerSit;

#define BG @"images/ui/sit/sitBg.png"
#define YELLOWCOLOR ccc3(235,179,59)
#define WHITECOLOR ccc3(238,227,205)
#define GREENCOLOR ccc3(13,177,75)

//@synthesize get_have_time;
+(BOOL)isPlayerShowSit{
    if (playerSit) {
        return YES;
    }
    return NO;
}
+(void)show{
	
	[PlayerSit hide];
	
	//TODO WTF???
	/*
	 NSArray *frame1=[AnimationViewer loadFileByFileFullPath:@"images/animations/1/" name:@"%i.png"];
	 NSArray *frame2=[AnimationViewer loadFileByFileFullPath:@"images/animations/1/" name:@"%i.png"];
	 AnimationViewer *pv=[AnimationViewer node];
	 */
	
	RolePlayer * player = [RoleManager shared].player;
	if(player.state==Player_state_sit){
		playerSit = [PlayerSit node];
        //fix chao
        if (iPhoneRuningOnGame()) {
            playerSit.position = ccp(0,-20);
            [[Game shared] addChild:playerSit z:11];
            //[[GameLayer shared] addChild:playerSit z:INT32_MAX-128];
        }else{
            [[GameLayer shared] addChild:playerSit z:INT32_MAX-128];
        }
        //end
		//[[GameLayer shared] addChild:playerSit z:INT32_MAX-128];
	}
	
}

+(void)hide{
	if(playerSit){
		[playerSit removeFromParentAndCleanup:YES];
		playerSit = nil;
	}
}

+(void)update{
	if(playerSit){
		[playerSit updateContent];
	}
}

/*
 static int EXP=0;
 static int sitTime = 0;
 
 +(int)getSitTime{
 return sitTime;
 }
 
 +(void)setSitTime:(int)i{
 sitTime=i;
 }
 
 +(void)setExp:(int)i{
 EXP=i;
 }
 
 +(int)getExp{
 return EXP;
 }
 
 +(PlayerSit*)share{
 if(!playerSit){
 playerSit=[PlayerSit node];
 }
 return playerSit;
 }
 
 -(void)cancelSit{
 [GameConnection request:@"stopSit" format:@"" target:self call:@selector(requestConnection:)];
 }
 */

-(void)onEnter{
	[super onEnter];
	
	/*
	 get_have_time=sitTime;
	 sitTime=-999;
	 exp=EXP;
	 */
	
	CCSprite *bg=[CCSprite spriteWithFile:BG];
	
//	CCLabelTTF *title=[CCLabelTTF labelWithString:@"修炼中(可离线)" fontName:getCommonFontName(FONT_3)  fontSize:20];
//	labelexp=[CCLabelTTF labelWithString:@"累计经验:" fontName:getCommonFontName(FONT_3)  fontSize:20];
//	labeltime=[CCLabelTTF labelWithString:@"修炼时间:" fontName:getCommonFontName(FONT_3) fontSize:20];
    CCLabelTTF *title=[CCLabelTTF labelWithString:NSLocalizedString(@"player_sit_repose",nil) fontName:getCommonFontName(FONT_3)  fontSize:20];
	labelexp=[CCLabelTTF labelWithString:NSLocalizedString(@"player_sit_count_exp",nil) fontName:getCommonFontName(FONT_3)  fontSize:20];
	labeltime=[CCLabelTTF labelWithString:NSLocalizedString(@"player_sit_repose_time",nil) fontName:getCommonFontName(FONT_3) fontSize:20];
	labelspeed=[CCLabelTTF labelWithString:[self getSitPercent] fontName:getCommonFontName(FONT_3)  fontSize:20];
	
	[labelexp setAnchorPoint:ccp(0, 0)];
	[labelspeed setAnchorPoint:ccp(0, 0)];
	[labeltime setAnchorPoint:ccp(0, 0)];
	
	[title setColor:YELLOWCOLOR];
	[labelspeed setColor:GREENCOLOR];
	[labelexp setColor:WHITECOLOR];
	[labeltime setColor:WHITECOLOR];
	
	if(iPhoneRuningOnGame()){
		
		title.scale = 0.5f;
		labelexp.scale = 0.5f;
		labelspeed.scale = 0.5f;
		labeltime.scale = 0.5f;
		
		[title setPosition:ccp(bg.contentSize.width/2+33/2, bg.contentSize.height-30/2)];
		[bg setPosition:ccp(self.contentSize.width/2, self.contentSize.height/4+88/2)];
		[labelexp setPosition:ccp(190/2,80/2)];
		[labelspeed setPosition:ccp(190/2,50/2)];
		[labeltime setPosition:ccp(190/2,20/2)];
	}else{
		[title setPosition:ccp(bg.contentSize.width/2+33, bg.contentSize.height-30)];
		[bg setPosition:ccp(self.contentSize.width/2, self.contentSize.height/4+88)];
		[labelexp setPosition:ccp(190,80)];
		[labelspeed setPosition:ccp(190,50)];
		[labeltime setPosition:ccp(190,20)];
	}
	
	[bg addChild:title];
	[bg addChild:labelexp];
	[bg addChild:labelspeed];
	[bg addChild:labeltime];
	[self addChild:bg];
	
	/*
	 if(EXP!=0){
	 [self schedule:@selector(reflash) interval:1];
	 }else{
	 [GameConnection request:@"startSit" format:@"" target:self call:@selector(requestConnection:)];
	 }
	 [GameConnection addPost:@"ConnPost_playerSit" target:self call:@selector(requestPost:)];
	 */
	
}

-(void)updateContent{
	
    unsigned int exp = ABS([PlayerSitManager shared].totalExp);
	unsigned int time = ABS(PLAYER_SITTING_TOTAL_TIME-[PlayerSitManager shared].endSitTime);
	//float percent = (time/PLAYER_SITTING_TOTAL_TIME)*100;

//	labelexp.string = [NSString stringWithFormat:@"累计经验 : %d",exp];
//	labeltime.string = [NSString stringWithFormat:@"修炼时间 : %@",getTimeFormat(time)];
    labelexp.string = [NSString stringWithFormat:@"%@ %d",NSLocalizedString(@"player_sit_count_exp",nil),exp];
	labeltime.string = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"player_sit_repose_time",nil),getTimeFormat(time)];
	//labelspeed.string = [NSString stringWithFormat:@"打坐进度 : %.0f%@",percent,@"%"];
	
}

/*
 -(void)requestPost:(NSNotification*)data{
 CCLOG(@"%@",data);
 
 exp=[[[data object]objectForKey:@"exp"]integerValue];
 
 }
 
 -(void)requestConnection:(NSDictionary*)data{
 
 if([[data objectForKey:@"s"]integerValue]==1 && [[data objectForKey:@"f"]isEqualToString:@"stopSit"]){
 [self removeFromParentAndCleanup:true];
 }
 if([[data objectForKey:@"s"]integerValue]==1 && [[data objectForKey:@"f"]isEqualToString:@"startSit"]){
 [self schedule:@selector(reflash) interval:1];
 }
 
 }
 
 -(void)dealloc{
 playerSit=nil;
 sitTime=0;
 EXP=0;
 [GameConnection removePostTarget:self];
 [super dealloc];
 }
 
 -(void)reflash{
 if(get_have_time==0){
 [self removeFromParentAndCleanup:true];
 }
 get_have_time--;
 NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:get_have_time];
 CCLOG(@"%@", [confromTimesp.description stringByReplacingOccurrencesOfString:@"1970-01-01 " withString:@""]);
 NSString *timestr= [confromTimesp.description stringByReplacingOccurrencesOfString:@"1970-01-01 " withString:@""];
 timestr=[timestr stringByReplacingOccurrencesOfString:@" +0000" withString:@""];
 timestr=[NSString stringWithFormat:@"修炼时间：%@",timestr];
 NSString *expstr=[NSString stringWithFormat:@"累计经验：%i",exp];
 labeltime.string=timestr;
 labelexp.string=expstr;
 }
 */

-(NSString*)getSitPercent{
	NSDictionary * config = [[GameDB shared] getGlobalConfig];
	NSDictionary * vipLevSit = getFormatToDict([config objectForKey:@"vipLevSit"]);
	NSDictionary * player = [[GameConfigure shared] getPlayerInfo];
	int vip = [[player objectForKey:@"vip"] intValue];
	int percent = 100;
	for(NSNumber * per in vipLevSit){
		if(vip>=[per intValue]){
			percent += [[vipLevSit objectForKey:per] intValue];
		}
	}
	//return [NSString stringWithFormat:@"打坐速度: %d%@",percent,@"%"];
    return [NSString stringWithFormat:NSLocalizedString(@"player_sit_speed",nil),percent,@"%"];
}

@end
