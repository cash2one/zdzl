//
//  UnionPractice.m
//  TXSFGame
//
//  Created by Max on 13-4-28.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionPractice.h"
#import "Window.h"
#import "StretchingImg.h"
#import "CCPanel.h"
#import "AnimationMonster.h"
#import "UnionPracticeConfigTeam.h"
#import "MonsterIconViewerContent.h"
#import "RolePlayer.h"
#import "RoleManager.h"
#import "TaskTalk.h"
#import "FightManager.h"
#import "MapManager.h"




#pragma mark 选择BOSS窗口
@implementation UnionPractice



static UnionPractice *unionPractice;


+(BOOL)checkCanJoinTeam{
	BOOL isYes = YES ;
	[[RoleManager shared].player stopMoveAndTask];
	
	//不愁更加多条件
	if([TaskTalk isTalking])							isYes = NO;
	if([FightManager isFighting])						isYes = NO;
	
	return isYes;
}

+(BOOL)checkCanJoinTeamWithMap{
	BOOL isYes = YES ;
	
	if ([MapManager shared].mapType == Map_Type_WorldBoss ||
		[MapManager shared].mapType == Map_Type_UnionBoss
		) {
		isYes = NO;
	}
	
	return isYes;
}


+(void)statr{
	if(!unionPractice){
		unionPractice =[UnionPractice node];
		[[Window shared]addChild:unionPractice z:10 tag:PANEL_UNION_Practice];
	}
}

-(void)onEnter{
	[super onEnter];
	if (iPhoneRuningOnGame()) {
		bg=[CCSprite spriteWithFile:@"images/ui/wback/fun_bg.jpg"];
	}else{
		bg=[CCSprite spriteWithFile:@"images/ui/panel/p4.png"];
	}
	CCSimpleButton *close_btn=[CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"];
	CCSprite *title=[CCSprite spriteWithFile:@"images/ui/union/practice/titleselect.png"];
	CCSprite *bgbound=nil;
	if (iPhoneRuningOnGame()) {
		bgbound=[StretchingImg stretchingImg:@"images/ui/union/bounds.png" width:480 height:cFixedScale(550) capx:1 capy:1];
		[title setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height- 18)];
		[bgbound setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height/2-cFixedScale(20))];
		[close_btn setPosition:ccp(self.contentSize.width - close_btn.contentSize.width/2+ccpIphone4X(0)-2.0f,
								   self.contentSize.height-close_btn.contentSize.height/2-2.5f)];
		[close_btn setPriority:kCCMenuHandlerPriority];
		close_btn.scale=1.19f;
		
	}else{
		bgbound=[StretchingImg stretchingImg:@"images/ui/union/bounds.png" width:bg.contentSize.width-cFixedScale(40) height:cFixedScale(420) capx:1 capy:1];
		[title setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height- cFixedScale(10))];
		[bgbound setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height/2-cFixedScale(30))];
		[close_btn setPosition:ccp(bg.contentSize.width-close_btn.contentSize.width/1.5, bg.contentSize.height-close_btn.contentSize.height/1.5)];
	}
	
	
	[bg setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2)];
	
	
	[close_btn setTarget:self];
	[close_btn setCall:@selector(closebtnCallBack)];
	[bg addChild:title];
	[bg addChild:bgbound];
	[bg addChild:close_btn];
	[self addChild:bg];
	
	//[self creatCityNameListAndMosterList];
	[GameConnection request:@"allyTTBoxEnter" format:@"" target:self call:@selector(didGameConnection:)];
}


-(void)creatCityNameListAndMosterList:(NSDictionary*)bids{
	
	CCNode *content=[CCNode node];
	int tw=0;
	int th=0;
	int i=0;
	
	if(bidsData){
		[bidsData release];
	}
	bidsData=[[NSMutableDictionary alloc]initWithDictionary:bids];
	//	CCLOG(@"%@",bids);
	float fontSize=18;
	float lineH=20;
	if (iPhoneRuningOnGame()) {
		fontSize=20;
		lineH=22;
	}
	
	NSArray *sortedArray = [bidsData.allKeys sortedArrayUsingComparator: ^(id obj1, id obj2) {
		
		if ([obj1 integerValue] > [obj2 integerValue]) {
			return (NSComparisonResult)NSOrderedDescending;
		}
		
		if ([obj1 integerValue] < [obj2 integerValue]) {
			return (NSComparisonResult)NSOrderedAscending;
		}
		return (NSComparisonResult)NSOrderedSame;
	}];
	
	NSString *lastkey=@"";
	for(NSString *bidkey in sortedArray){
		int mid=[[[[GameDB shared]getChapterInfo:[bidkey intValue]] objectForKey:@"mid"]intValue];
		NSString *name=[[[GameDB shared]getMapInfo:mid] objectForKey:@"name"];
		CCSimpleButton *btn=[CCSimpleButton spriteWithFile:@"images/ui/union/practice/btncityname.png" select:@"images/ui/union/practice/btncitynamesel.png"];
		[btn setUserObject:bidkey];
		CCSprite *cityname=drawString(name, CGSizeMake(120, 40) , getCommonFontName(FONT_1), fontSize, lineH, @"880000");
		[btn addChild:cityname];
		[btn setAnchorPoint:ccp(0, 0)];
		[btn setTarget:self];
		[btn setCall:@selector(changeCity:)];
		[btn setPosition:ccp(i*(btn.contentSize.width+10), 0)];
		[cityname setPosition:ccp(btn.contentSize.width/2, btn.contentSize.height/2)];
		[content addChild:btn];
		tw+=(btn.contentSize.width+10);
		th=btn.contentSize.height;
		i++;
		lastkey=bidkey;
	}
	
	[content setContentSize:CGSizeMake( tw, th)];
	
	CCPanel *panel=nil;
	if (iPhoneRuningOnGame()) {
		panel=[CCPanel panelWithContent:content viewSize:CGSizeMake(cFixedScale(570),cFixedScale(80))];
		[panel setPosition:ccp((bg.contentSize.width-panel.contentSize.width)/2,bg.contentSize.height-70)];
	}else{
		panel=[CCPanel panelWithContent:content viewSize:CGSizeMake(cFixedScale(550),cFixedScale(80))];
		[panel setPosition:ccp(160,360)];
	}
	[bg addChild:panel z:1 tag:9527];
	//[panel showHorzScrollBar:@"images/ui/common/scroll3.png"];
	if(content.contentSize.width>cFixedScale(550)){
		CCSprite *rlogo=[CCSprite spriteWithFile:@"images/ui/union/practice/rlogo.png"];
		[rlogo setFlipX:YES];
		[bg addChild:rlogo];
		CCSprite *llogo=[CCSprite spriteWithFile:@"images/ui/union/practice/rlogo.png"];
		[bg addChild:llogo];
		if (iPhoneRuningOnGame()) {
			[llogo setPosition:ccp(240/2.0f, 540/2.0f)];
			[rlogo setPosition:ccp(900/2.0f,540/2.0f)];
		}else{
			[llogo setPosition:ccp(100, 400)];
			[rlogo setPosition:ccp(760,400)];		
		}
	}
	
	
	NSArray *bosslist=[NSArray arrayWithArray:[bidsData  objectForKey:lastkey]];
	
	[self creatMonsterList:bosslist];
	
}


-(void)creatMonsterList:(NSArray*)bosslist{
	for(int i=0;i<5;i++){
		[bg removeChildByTag:1000+i];
	}
	float starty=190;
	float startx=105;
	float fontSize=18;
	float lineH=20;
	if (iPhoneRuningOnGame()) {
		starty=150;
		startx=103;
		fontSize=22;
		lineH=22;
	}
	for(int i=0;i<bosslist.count;i++){
		NSDictionary *boss=[[GameDB shared]getTimeBoxInfo:[[bosslist objectAtIndex:i]intValue]];
		NSDictionary *mosterdata=[[GameDB shared]getMonsterInfo:[[boss objectForKey:@"tmid"]intValue]];
		NSDictionary *rewarddata=[[GameDB shared]getRewardInfo:[[boss objectForKey:@"trid"]intValue]];
		NSString *mostername=[mosterdata objectForKey:@"name"];
		NSString *rewardstr=[rewarddata objectForKey:@"info"];
		NSDictionary *colors=getFormatToDict([[[GameDB shared]getGlobalConfig]objectForKey:@"qcolors"]);
		NSString *qastr = [colors objectForKey:[NSString stringWithFormat:@"%i",[[mosterdata objectForKey:@"quality"]intValue]]];
		
		CCLabelTTF *label=[CCLabelTTF labelWithString:mostername fontName:getCommonFontName(FONT_1) fontSize:iPhoneRuningOnGame()?12:18];
		
		CCSprite *rewardinfo=drawString(rewardstr, CGSizeMake(70, 10), getCommonFontName(FONT_1), fontSize,lineH, @"ffffff");
		[label setColor:color3BWithHexString(qastr)];
		
		NSString *mospath=[NSString stringWithFormat:@"images/ui/union/practice/monster/mos%i.jpg",[[boss objectForKey:@"tmid"]intValue]];
		
		CCSimpleButton *bgqa=[CCSimpleButton spriteWithFile:mospath select:mospath];
		if (iPhoneRuningOnGame()) {
			bgqa.scale=1.22f;
		}
		[bgqa setUserObject:[bosslist objectAtIndex:i]];
		[bgqa setTarget:self];
		[bgqa setCall:@selector(openPraConfigTeam:)];
		[bgqa setPosition:ccp(i*(bgqa.contentSize.width+20)+startx,starty)];
		[label setPosition:ccp(bgqa.contentSize.width/2, bgqa.contentSize.height-cFixedScale(15))];
		[rewardinfo setPosition:ccp(bgqa.contentSize.width/2,cFixedScale(40))];
		
		[bgqa addChild:rewardinfo];
		[bgqa addChild:label];
		
		[bg addChild:bgqa z:1 tag:1000+i];
	}
}

-(void)onExit{
	[super onExit];
	unionPractice=nil;
	[bidsData release];
}

-(void)changeCity:(CCSimpleButton*)b{
	CCPanel *panel= (CCPanel*)[bg getChildByTag:9527];
	if(panel.isTouchValid){
		NSString *keybd=b.userObject;
		[self creatMonsterList:[bidsData objectForKey:keybd]];
	}
}

-(void)closebtnCallBack{
	[[Window shared]removeChildByTag:PANEL_UNION_Practice cleanup:true];
}

-(void)didGameConnection:(NSDictionary*)n{
	
	NSDictionary *bids=[getResponseData(n) objectForKey:@"bids"];
	
	[self creatCityNameListAndMosterList:bids];
}


-(void)openPraConfigTeam:(CCSimpleButton*)b{
	int mid=[b.userObject integerValue];
	midArg=mid;
	[GameConnection request:@"allyTTBoxNew" format:[NSString stringWithFormat:@"tbid::%i",mid] target:self call:@selector(didRequest:)];
}


-(void)didRequest:(NSDictionary*)data{
	if(!checkResponseStatus(data)){
		[ShowItem showErrorAct:getResponseMessage(data)];
		
	}
	if(checkResponseStatus(data)){
		CCLOG(@"%@",data);
		[self closebtnCallBack];
        int tid=[[getResponseData(data) objectForKey:@"tid"]intValue];
		[UnionPracticeConfigTeam startLeaderWithMosterId:midArg teamId:tid];
	}
}

@end




#pragma mark 组队与加入
@implementation UnionPracticeCreatJoin

static UnionPracticeCreatJoin *unionPracticeCreatJoin;

+(void)statr{
	if(!unionPracticeCreatJoin){
		unionPracticeCreatJoin =[UnionPracticeCreatJoin node];
		[[Window shared]addChild:unionPracticeCreatJoin z:10 tag:PANEL_UNION_Practice];
	}
}

-(void)onEnter{
	[super onEnter];
	bg=[CCSprite spriteWithFile:@"images/ui/panel/p1.png"];
	CCSimpleButton *close_btn=[CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"];
	CCSimpleButton *creat_btn=[CCSimpleButton spriteWithFile:@"images/ui/union/practice/creatteambtn.png"];
	CCSprite *title=[CCSprite spriteWithFile:@"images/ui/union/practice/title.png"];
	CCSprite *bgbound=[StretchingImg stretchingImg:@"images/ui/union/bounds.png" width:bg.contentSize.width-cFixedScale(40) height:cFixedScale(490) capx:1 capy:1];
	
	[close_btn setTarget:self];
	[close_btn setCall:@selector(closebtnCallBack)];
	[creat_btn setTarget:self];
	[creat_btn setCall:@selector(creatbtnCallBack)];
	[creat_btn setPriority:-999];
	
	[title setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height- cFixedScale(10))];
	[bg setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2)];
	[bgbound setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height/2-cFixedScale(30))];
	[close_btn setPosition:ccp(bg.contentSize.width-close_btn.contentSize.width/1.5, bg.contentSize.height-close_btn.contentSize.height/1.5)];
	[creat_btn setPosition:ccp(bg.contentSize.width/2, cFixedScale(40))];
	
	
	[self addChild:bg];
	[bg addChild:close_btn];
	[bg addChild:title];
	[bg addChild:bgbound];
	[bg addChild:creat_btn];
	
	[GameConnection request:@"allyTTBoxList" format:@"" target:self call:@selector(didRequest:)];
}


-(void)didRequest:(NSDictionary*)data{
	//CCLOG(@"%@",data);
	if(checkResponseStatus(data) && [getResponseFunc(data) isEqualToString:@"allyTTBoxList"]){
		
		NSArray *teamsData=getResponseData(data);
		CCLayer *content=[CCLayer node];
		int contenth=0;
		int topy=0;
		if (iPhoneRuningOnGame()) {
			topy=teamsData.count>2?teamsData.count*cFixedScale(210):cFixedScale(410);
		}
		else{
			topy=teamsData.count>2?teamsData.count*210:415;
		}
		for(int i=0;i<teamsData.count;i++){
			
			CCSprite *teambg=[CCSprite spriteWithFile:@"images/ui/union/practice/teamlistbg.png"];
			[teambg setAnchorPoint:ccp(0, 1)];
			[teambg setPosition:ccp(0, topy-i*cFixedScale(215))];
			[content addChild:teambg];
			contenth+=cFixedScale(215);
			NSDictionary *teaminfo=[teamsData objectAtIndex:i];
			for(int j=0;j<3;j++){
				@try {
					NSDictionary *teamMember=[[teaminfo objectForKey:@"mb"] objectAtIndex:j];
					int rid=[[teamMember objectForKey:@"rid"] intValue];
					NSString *namestr=[teamMember objectForKey:@"n"];
					if(j==0){
						namestr=[NSString stringWithFormat:@"%@ : |%@#%@",NSLocalizedString(@"union_par_teamleader", nil),namestr,getQualityColorStr(2)];
					}else{
						namestr=[NSString stringWithFormat:@"%@ : |%@#%@",NSLocalizedString(@"union_par_teamember", nil),namestr,getQualityColorStr(2)];
					}
					
					NSString *levelstr=[NSString stringWithFormat:@"%@ : %@",NSLocalizedString(@"union_par_teamlevel", nil),[teamMember objectForKey:@"lv"]];
					
					
					CCSprite *face=getCharacterIcon(rid, ICON_PLAYER_NORMAL);
					CCSprite *name=drawString(namestr, CGSizeMake(200, 20), getCommonFontName(FONT_1), 18, 22, @"ffffff");
					CCSprite *level=drawString(levelstr, CGSizeMake(130,20), getCommonFontName(FONT_1),18, 22, @"ffffff");
					
					[name setAnchorPoint:ccp(0, 0.5)];
					[level setAnchorPoint:ccp(0, 0.5)];
					
					
					int offset=cFixedScale(67);
					[face setPosition:ccp(cFixedScale(310), cFixedScale(169)-offset*j)];
					[name setPosition:ccp(cFixedScale(360), cFixedScale(180)-offset*j)];
					[level setPosition:ccp(cFixedScale(360), cFixedScale(155)-offset*j)];
					[teambg addChild:name];
					[teambg addChild:face];
					[teambg addChild:level];
				}
				@catch (NSException *exception) {
					CCLabelTTF *label=[CCLabelTTF labelWithString:NSLocalizedString(@"union_par_teamjoin", nil) fontName:getCommonFontName(FONT_1) fontSize:iPhoneRuningOnGame()?11:18];
					CCSimpleButton *joinBtn=[CCSimpleButton spriteWithNode:label];
					NSMutableDictionary *dict=[NSMutableDictionary dictionary];
					
					[dict setObject:[teaminfo objectForKey:@"tid"] forKey:@"tid"];
					[dict setObject:[teaminfo objectForKey:@"tbid"] forKey:@"tbid"];
					
					[joinBtn setUserObject:dict];
					[joinBtn setTarget:self];
					[joinBtn setCall:@selector(joinbtnCallBack:)];
					[joinBtn setPosition:ccp(cFixedScale(430), cFixedScale(163)- cFixedScale(60)*j)];
					[teambg addChild:joinBtn];
				}
			}
			int tbid=[[teaminfo objectForKey:@"tbid"] intValue];
			NSDictionary *timebox=[[GameDB shared]getTimeBoxInfo:tbid];
			NSDictionary *mosterdata=[[GameDB shared]getMonsterInfo:[[timebox objectForKey:@"tmid"]intValue]];
			NSDictionary *rewarddata=[[GameDB shared]getRewardInfo:[[timebox objectForKey:@"trid"]intValue]];
			int mosid=[[timebox objectForKey:@"tmid"] intValue];
			int qa=[[mosterdata objectForKey:@"quality"] intValue];
			NSString *monsterName=[NSString stringWithFormat:@"%@#%@",[mosterdata objectForKey:@"name"],getQualityColorStr(qa)];
			NSString *monsterReward=[rewarddata objectForKey:@"info"];
			
			CCSprite *mname=drawString(monsterName, CGSizeMake(100, 10), getCommonFontName(FONT_1), 18, 22, @"ffffff");
			CCSprite *mreward=drawString(monsterReward, CGSizeMake(400, 10), getCommonFontName(FONT_1), 18, 22, @"ffffff");
			MonsterIconViewerContent *monsterFace=[MonsterIconViewerContent create:mosid];
			
			[monsterFace setPosition:ccp(cFixedScale(116),cFixedScale(156))];
			[mname setPosition:ccp(cFixedScale(116), cFixedScale(50))];
			[mreward setPosition:ccp(cFixedScale(116),cFixedScale(30))];
			
			[teambg addChild:mreward];
			[teambg addChild:mname];
			[teambg addChild:monsterFace];
		}
		contenth=contenth<cFixedScale(415)?cFixedScale(415):contenth;
		[content setContentSize:CGSizeMake(cFixedScale(512), contenth)];
		panel=[CCPanel panelWithContent:content viewSize:CGSizeMake(cFixedScale(512), contenth)];
		[panel updateContentToTop];
		[panel setPosition:ccp(cFixedScale(40), cFixedScale(80))];
		[bg addChild:panel];
	}
	if(checkResponseStatus(data) && [getResponseFunc(data) isEqualToString:@"allyTTBoxAdd"]){
		[UnionPracticeConfigTeam startWithMosterId:currenTbid teamId:currenTid];
		[self closebtnCallBack];
	}
	
	
}

-(void)joinbtnCallBack:(CCSimpleButton*)b{
	int tid=[[[b userObject] objectForKey:@"tid"] intValue];
	currenTid=tid;
	currenTbid=[[[b userObject] objectForKey:@"tbid"] intValue];
	[GameConnection request:@"allyTTBoxAdd" format:[NSString stringWithFormat:@"tid::%i",tid] target:self call:@selector(didRequest:)];
}

+(void)joinTeam:(int)tid tbid:(int)tbid{
	if (![UnionPractice checkCanJoinTeam]) {
		return ;
	}
	
	if (![UnionPractice checkCanJoinTeamWithMap]) {
		[ShowItem showItemAct:NSLocalizedString(@"error_map_type_",nil)];
		return ;
	}
	
	if(![UnionPracticeConfigTeam isOpen]){
		NSDictionary *var=[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i",tbid],@"tbid",[NSString stringWithFormat:@"%i",tid],@"tid", nil];
		[GameConnection request:@"allyTTBoxAdd" format:[NSString stringWithFormat:@"tid::%i",tid] target:[UnionPracticeCreatJoin class] call:@selector(joinTeamCallBack::) arg:var];
	}
}


+(void)joinTeamCallBack:(NSDictionary*)data :(NSDictionary*)data1{
	if(checkResponseStatus(data)){
		
		CCLOG(@"%@",data1);
		int tid=[[data1 objectForKey:@"tid"]intValue];
		int tbid=[[data1 objectForKey:@"tbid"]intValue];
		[UnionPracticeConfigTeam startWithMosterId:tbid teamId:tid];
		
	}else{
		[ShowItem showErrorAct:getResponseMessage(data)];
	}
}



-(void)closebtnCallBack{
	[[Window shared]removeChildByTag:PANEL_UNION_Practice cleanup:true];
}


-(void)creatbtnCallBack{
	[self closebtnCallBack];
	[UnionPractice statr];
}

-(void)onExit{
	[super onExit];
	unionPracticeCreatJoin=nil;
}



@end
