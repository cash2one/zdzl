//
//  UnionPracticeConfigTeam.m
//  TXSFGame
//
//  Created by Max on 13-5-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionPracticeConfigTeam.h"
#import "Window.h"
#import "GameUI.h"
#import "StretchingImg.h"
#import "TaskPattern.h"
#import "GameMail.h"
#import "FightPlayer.h"
#import "ChatPanelBase.h"
#import "AnimationMonster.h"
#import "UnionManager.h"
#import "TimeBox.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "PlayerSit.h"
#import "WorldBossTips.h"
#import "DragonTips.h"


@implementation UnionPracticeConfigTeam


static UnionPracticeConfigTeam *unionPracticeConfigTeam;

@synthesize teamId,teamLeader,colId,tbid;



+(void)configWindows{
    //
    [Window stopAll] ;
    //
	[UnionManager hideButton];
	[[GameUI shared] addChild:unionPracticeConfigTeam z:-1];
	//[[Window shared]addChild:unionPracticeConfigTeam z:10 tag:PANEL_UNION_Practice_Team];
	//[[Window shared] setZOrder:1];
//	[[GameUI shared]setZOrder:1];
	[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:NO];//左上
	[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:NO];//右上
	[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:NO];//右上
	
	[[GameUI shared] partialRenewal:GAMEUI_PART_MAIL display:NO];//右上
	[[GameUI shared] closeSpecialSystem];
	
	[WorldBossTips hide];
	[DragonTips hide];
	
	[TaskPattern display];
}
+(bool)isOpen{
	if(unionPracticeConfigTeam){
		return YES;
	}else{
		return NO;
	}
}

+(void)startLeaderWithMosterId:(int)tbid teamId:(int)tid{
	if(!unionPracticeConfigTeam){
		unionPracticeConfigTeam=[UnionPracticeConfigTeam node];
		NSDictionary *timebox=[[GameDB shared]getTimeBoxInfo:tbid];
		//战斗 的角色ID
		unionPracticeConfigTeam.mid=[[timebox objectForKey:@"tmid"]integerValue];
		unionPracticeConfigTeam.rewardid=[[timebox objectForKey:@"trid"]integerValue];
		unionPracticeConfigTeam.fightid=[[timebox objectForKey:@"tfids"]integerValue];
		unionPracticeConfigTeam.teamId=tid;
		unionPracticeConfigTeam.teamLeader=YES;
		unionPracticeConfigTeam.colId=0;
		unionPracticeConfigTeam.tbid=tbid;
		int colConfig[3][3]=cc;
		[unionPracticeConfigTeam creatArrangment:colConfig[0]];
		[UnionPracticeConfigTeam configWindows];
		//[[PlayerSitManager shared] stopSit];
        [PlayerSit hide];
	}
}



+(void)startWithMosterId:(int)tbid teamId:(int)tid{
	if(!unionPracticeConfigTeam){
		
		unionPracticeConfigTeam=[UnionPracticeConfigTeam node];
		NSDictionary *timebox=[[GameDB shared]getTimeBoxInfo:tbid];
		
		unionPracticeConfigTeam.mid=[[timebox objectForKey:@"tmid"]integerValue];
		unionPracticeConfigTeam.rewardid=[[timebox objectForKey:@"trid"]integerValue];
		unionPracticeConfigTeam.fightid=[[timebox objectForKey:@"tfids"]integerValue];
		unionPracticeConfigTeam.teamId=tid;
		unionPracticeConfigTeam.teamLeader=NO;
		unionPracticeConfigTeam.tbid=tbid;
		[UnionPracticeConfigTeam configWindows];
		//[[PlayerSitManager shared] stopSit];
		[PlayerSit hide];
	}
	
}

-(void)dealloc{
	if (stationInfo) {
		[stationInfo release];
		stationInfo = nil;
	}
	[super dealloc];
}

-(id)init{
	if(self=[super init]){
		[GameConnection addPost:@"ConnPost_AllyParTeamInfo" target:self call:@selector(listenTeamInfo:)];
		[GameConnection addPost:@"ConnPost_AllyParTeamDisband" target:self call:@selector(listenTeamDisband:)];
		[GameConnection addPost:@"ConnPost_AllyParTeamFigthInfo" target:self call:@selector(listenTeamFight:)];
	}
	return  self;
}

#pragma mark 处理队伍开始战斗
-(void)listenTeamFight:(NSNotification*)nof{
	CCLOG(@"%@",nof.object);
	isWaitting = YES ;
	NSDictionary *figthDict=nof.object;
	int refid=[[figthDict objectForKey:@"fp_id"]intValue];
	[[FightManager shared]playFightRecord:refid target:[UnionPracticeConfigTeam class] call:@selector(figthCallBack:)];
	isStartFight=YES;
    //
    [[PlayerSitManager shared] stopSit];
}

#pragma mark 处理队伍解散
-(void)listenTeamDisband:(NSNotification*)nof{
	if (unionPracticeConfigTeam) {
		[unionPracticeConfigTeam removeFromParentAndCleanup:true];
		unionPracticeConfigTeam = nil ;
	}
	//[[Window shared]removeWindow:PANEL_UNION_Practice_Team];
	[ShowItem showItemAct:NSLocalizedString(@"union_par_teamdisband", nil)];
}

#pragma mark 处理阵变换
-(void)listenTeamInfo:(NSNotification*)nof{
	
	if (stationInfo) {
		[stationInfo release];
		stationInfo = nil ;
	}
	
	stationInfo = [NSDictionary dictionaryWithDictionary:nof.object];
	[stationInfo retain];
	
	[self showStationInfo];
	
}

-(void)showStationInfo{
	
	if (stationInfo == nil) {
		CCLOG(@"showStationInfo->error->stationInfo == nil");
		return ;
	}
	
	NSDictionary *team=[stationInfo objectForKey:@"mb"];
	
	for(int i=0;i<9;i++){
		[[self getChildByTag:ROLEVIEWBASE+i] removeFromParentAndCleanup:true];
		[roleAr setValue:nil forKey:[NSString stringWithFormat:@"%i",i]];
	}
	int colConfig[3][3]=cc;
	
	NSMutableDictionary *collist=[NSMutableDictionary dictionary];
	for(NSString *teamkey in [team allKeys]){
		
		int pos =[teamkey intValue];
		
		
		for(int xi=0;xi<9;xi++){
			if (colConfig[xi/3][xi%3]==pos) {
				[collist setValue:@"" forKey:[NSString stringWithFormat:@"%i",xi/3]];
			}
		}
		
		
		int rid=[[[team objectForKey:teamkey]objectForKey:@"rid"]intValue];
		int pid=[[[team objectForKey:teamkey]objectForKey:@"pid"]intValue];
		int mepid=[GameConfigure shared].playerId;
		
		RoleViewerContent *rvc=[RoleViewerContent node];
		rvc.dir=2;
		if(pid!=mepid && rid<10){
			int eid=[[[team objectForKey:teamkey]objectForKey:@"eid"]intValue];
			[rvc loadTargetOtherRole:rid eid:eid];
		}else{
			[rvc loadTargetRole:rid];
		}
		[rvc setPosition:[self getChildByTag:ROLEARBASE+pos].position];
		[self addChild:rvc z:1 tag:ROLEVIEWBASE+pos];
		[roleAr setValue:[[team objectForKey:teamkey]objectForKey:@"rid"] forKey:teamkey];
	}
	[popleCountLabel setString:[NSString stringWithFormat:@"%i/3",collist.allKeys.count]];
	
	
	if(isRunFirstConfig){
		self.colId=0;
		colId=0;
		for(int i=0;i<3;i++){
			if([collist valueForKey:[NSString stringWithFormat:@"%i",i]]==nil){
				super.colId=i;
				colId=i;
				break;
			}
		}
		[self firstConfig];
	}
	
}

-(void)onEnter{
	[super onEnter];
	isRunFirstConfig=true;
	isWaitting = NO;
	bg=[CCSprite spriteWithFile:@"images/ui/union/timesbox.png"];
	CCSimpleButton *startfight_btn=[CCSimpleButton spriteWithFile:@"images/ui/union/practice/startfightbtn.png"];
	CCSprite *mcbg=[CCSprite spriteWithFile:@"images/ui/union/practice/teammembercountbg.png"];
	close_btn=[CCSimpleButton spriteWithFile:@"images/ui/button/bt_back.png"];
	
	invitebtn=[CCSimpleButton spriteWithFile:@"images/ui/union/practice/invitebtn.png"];
	CGSize winSize=[CCDirector sharedDirector].winSize;

	[bg setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2)];
	
	popleCountLabel=[CCLabelTTF labelWithString:@"1/3" fontName:getCommonFontName(FONT_1) fontSize:iPhoneRuningOnGame()?14:18];
	
	[startfight_btn setTarget:self];
	[startfight_btn setCall:@selector(startfightbtnCallBack)];
	
	if (iPhoneRuningOnGame()) {
		close_btn.scale=1.2f;
	}
	
	[close_btn setTarget:self];
	[close_btn setCall:@selector(closebtnCallBack)];
	

	[invitebtn setTarget:self];
	[invitebtn setCall:@selector(invitebtnCallBack)];
	
	[self creatBossViewer];
	[[[CCDirector sharedDirector]touchDispatcher]addTargetedDelegate:self priority:-128 swallowsTouches:NO];
	if(teamLeader){
		[self addChild:startfight_btn z:1];
		[self addChild:invitebtn z:1];
	}
	
	[self addChild:close_btn z:1];
	[self addChild:mcbg z:1];
	[self addChild:popleCountLabel z:1];
	[self addChild:bg];
	roleArId=-1;
	isRunFirstConfig=true;
	if(teamLeader){
		[self firstConfig];
	}
	if (iPhoneRuningOnGame()) {
		bg.scaleX=winSize.width/bg.contentSize.width;
		[startfight_btn setPosition:ccp(self.contentSize.width/2, self.contentSize.height-startfight_btn.contentSize.height/2-10)];
		[popleCountLabel setPosition:ccp(self.contentSize.width/2, startfight_btn.position.y-startfight_btn.contentSize.height/2-10)];
		[invitebtn setPosition:ccp(self.contentSize.width/2, popleCountLabel.position.y-popleCountLabel.contentSize.height/2-5-invitebtn.contentSize.height/2)];
		[mcbg setPosition:ccp(self.contentSize.width/2, startfight_btn.position.y-startfight_btn.contentSize.height/2-10)];

	}else{
		[startfight_btn setPosition:ccp(self.contentSize.width/2, cFixedScale(700))];
		[popleCountLabel setPosition:ccp(self.contentSize.width/2, 600)];
		[invitebtn setPosition:ccp(self.contentSize.width/2, 550)];
		[mcbg setPosition:ccp(self.contentSize.width/2, 600)];
	}
	[close_btn setPosition:ccp(winSize.width-close_btn.contentSize.width, self.contentSize.height-close_btn.contentSize.height)];
	[self setUpRoleDataFun:@selector(updataRoleAr)];

	
}


-(void)invitebtnCallBack{
    if ([[Window shared] isHasWindow]) {
        return ;
    }
	NSString *var=[NSString stringWithFormat:@"msg:PRA%i)%i",teamId,tbid];
	//[ChatPanelBase sendInviteUnionTeam:var];
	
	[GameConnection request:@"allyTTBoxInvitePub" format:var target:nil call:nil];
	[invitebtn setVisible:NO];
	//[self schedule:@selector(showInvitebtn) interval:5];
	[self scheduleOnce:@selector(showInvitebtn) delay:5];
}

-(void)showInvitebtn{
	[invitebtn setVisible:YES];
}

-(void)closebtnCallBack{
    if ([[Window shared] isHasWindow]) {
        return ;
    }
	if (!isWaitting) {
		if (unionPracticeConfigTeam) {
			[unionPracticeConfigTeam removeFromParentAndCleanup:true];
			unionPracticeConfigTeam = nil ;
            //
            [PlayerSit show];
		}
		//[unionPracticeConfigTeam removeFromParentAndCleanup:true];
		//[[Window shared] removeWindow:PANEL_UNION_Practice_Team];
		[[TaskPattern shared] checkStatus];//重新检查打开 任务按钮
	}else{
		[self scheduleOnce:@selector(openClosing) delay:3.0f];
	}
}

-(void)openClosing{
	if (isWaitting) {
		isWaitting = NO ;
	}
}

-(void)showReward{
    if ([[Window shared] isHasWindow]) {
        return ;
    }
	if(rewardbg){
		[rewardbg removeFromParentAndCleanup:true];
		rewardbg=nil;
	}
	float fontSize=16;
	float lineH=18;
	if (iPhoneRuningOnGame()) {
		fontSize=18;
		lineH=22;
	}
	NSString *name=[[[GameDB shared]getMonsterInfo:self.mid]objectForKey:@"name"];
	
	NSString *rewardstr=[NSString stringWithFormat:NSLocalizedString(@"union_team_drop",nil),[[[GameDB shared]getRewardInfo:self.rewardid]objectForKey:@"info"]];
    
	int qa=[[[[GameDB shared]getMonsterInfo:self.mid]objectForKey:@"quality"]integerValue];
	rewardbg=[StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(350) height:cFixedScale(70) capx:cFixedScale(8) capy:cFixedScale(8)];
	CCSprite *namesp=drawString(name, CGSizeMake(100, 22), getCommonFontName(FONT_1), fontSize, lineH, getQualityColorStr(qa));
	CCSprite *rewardsp=drawString(rewardstr, CGSizeMake(370, 22), getCommonFontName(FONT_1), fontSize, lineH, @"ffffff");
	
	
	[namesp setPosition:ccp(cFixedScale(10), cFixedScale(30))];
	[rewardsp setPosition:ccp(cFixedScale(10), cFixedScale(10))];
	
	[namesp setAnchorPoint:ccp(0, 0)];
	[rewardsp setAnchorPoint:ccp(0, 0)];
	[rewardbg setPosition:ccp(cFixedScale(200), cFixedScale(400))];
	[rewardbg addChild:namesp];
	[rewardbg addChild:rewardsp];
	[self addChild:rewardbg];
	
}

-(void)startfightbtnCallBack{
    if ([[Window shared] isHasWindow]) {
        return ;
    }
	isStartFight=YES;
	NSDictionary *timebox=[[GameDB shared]getTimeBoxInfo:tbid];
	int fid=[[timebox objectForKey:@"tfids"] intValue];
	[[FightManager shared]startFightById:fid team:teamId target:[UnionPracticeConfigTeam class] call:@selector(figthCallBack:) sele:@selector(fightseleCallBack)];
    //
    [[PlayerSitManager shared] stopSit];
}

+(void)figthCallBack:(NSDictionary*)dict{
	[TimeBox quitTimeBox];
}


+(void)fightseleCallBack{
	int isWin=[FightManager isWinFight]==true?1:0;
	NSString *figthSub=[[FightManager shared]getFigthSub];
	NSString *var=[NSString stringWithFormat:@"isOK::%i|fp:%@",isWin,figthSub];
	[GameConnection request:@"allyTTBoxEnd" format:var target:self call:nil];
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
    if ([[Window shared] isHasWindow]) {
        return NO;
    }
	if(rewardbg){
		[rewardbg removeFromParentAndCleanup:true];
		rewardbg=nil;
	}
	return  [super ccTouchBegan:touch withEvent:event];
}





#pragma mark 将-1数据转为空值用于删除人物
-(void)cleanupRoleAr{
	for(NSString *key in roleArMe.allKeys){
		if([[roleArMe valueForKey:key] intValue]==-1){
			[self setRoleAndMeValue:nil keyname:key];
		}
	}
}



#pragma mark 默认将主角放在阵中
-(void)firstConfig{
	
	isRunFirstConfig=false;
	int colConfig[3][3]=cc;
	[self creatArrangment:colConfig[colId]];
	NSArray *roleList2 = [[GameConfigure shared] getPlayerRoleList];
	for (NSDictionary *roleData in roleList2) {
		if([[roleData objectForKey:@"rid"] intValue]<10){
			int pos=colConfig[colId][0];
			RoleViewerContent *rvc=[RoleViewerContent node];
			rvc.dir=2;
			[rvc loadTargetRole:[[roleData objectForKey:@"rid"] intValue]];
			[self setRoleAndMeValue:[roleData objectForKey:@"rid"] keyname:[NSString stringWithFormat:@"%i",pos]];
			[rvc setPosition:[self getChildByTag:ROLEARBASE+pos].position];
			[self addChild:rvc z:1 tag:ROLEVIEWBASE+pos];
			[self updataRoleAr];
			return;
		}
	}
}




-(void)onExit{
	if(!isStartFight){
		[GameConnection request:@"allyTTBoxDel" format:@"" target:nil call:nil];
	}
	close_btn = nil ;
	[super onExit];
	[UnionManager showButton];
	//[[Window shared] setZOrder:INT32_MAX - 10];
	[[GameUI shared] partialRenewal:GAMEUI_PART_LU display:YES];//左上
	[[GameUI shared] partialRenewal:GAMEUI_PART_RU display:YES];//右上
	[[GameUI shared] partialRenewal:GAMEUI_PART_RD display:YES];//右上
	[[GameUI shared] partialRenewal:GAMEUI_PART_MAIL display:YES];//右上
	[[[CCDirector sharedDirector]touchDispatcher]removeDelegate:self];
	[[GameUI shared] openSpecialSystem];
	unionPracticeConfigTeam=nil;
	[GameConnection removePostTarget:self];
}


-(void)updataRoleAr{
	NSMutableDictionary *var=[NSMutableDictionary dictionary];
	[var setValue:roleArMe forKey:@"pos"];
	
	[GameConnection request:@"allyTTBoxMove" data:var target:self call:@selector(endUpdataRoleAr:)];
	[self cleanupRoleAr];
}

-(void)endUpdataRoleAr:(NSDictionary*)sender{
	if (!checkResponseStatus(sender)) {
		isRunFirstConfig = YES ;
		[roleArMe removeAllObjects];
		[roleAr removeAllObjects];
		[self showStationInfo];
	}
}

-(void)creatBossViewer{
	int mid=self.mid;
	NSDictionary *monsterData=[[GameDB shared]getMonsterInfo:mid];
	AnimationMonster *monster=[AnimationMonster node];
	int offset=[[monsterData objectForKey:@"offset"]integerValue];
	[monster showAnimationByMonsterId:mid type:MONSTER_TYPE_BOSS];
	monster.scale=getAniScale(mid);
	
	CCSimpleButton *boss_btn =[CCSimpleButton node];
	[boss_btn setContentSize:CGSizeMake(cFixedScale(200), cFixedScale(200))];
	[boss_btn setTarget:self];
	[boss_btn setCall:@selector(showReward)];
	[monster setPosition:ccp(cFixedScale(200), cFixedScale(500)-cFixedScale(offset))];
	[boss_btn setPosition:ccp(cFixedScale(200), cFixedScale(500))];
	
	[self addChild:monster z:1];
	[self addChild:boss_btn z:1];
}


@end
