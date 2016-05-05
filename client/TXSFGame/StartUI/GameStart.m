//
//  GameStart.m
//  TXSFGame
//
//  Created by TigerLeung on 12-12-10.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "GameStart.h"
#import "Game.h"
#import "Config.h"
#import "CCLabelFX.h"
#import "GameConnection.h"
#import "GameConfigure.h"
#import "CCScrollLayer.h"
#import "GameDB.h"
#import "GameLoading.h"
#import "CCSimpleButton.h"
#import "ShowItem.h"
#import "SNSHelper.h"
#import "EquipmentIconViewerContent.h"
#import "GameSoundManager.h"
#import "CCPanel.h"
#import "AnimationViewer.h"
#if (GAME_SNS_TYPE==5 || GAME_SNS_TYPE==6)
#import "EFUserAction.h"
#endif

//fix chao 修改位置
#define GAME_START_INPUT_H (380)
//end
//TODO change name
static NSString * role_name[] = {
	//	@"Role 1",
	//	@"Role 2",
	//	@"Role 3",
	//	@"Role 4",
	//	@"Role 5",
	//	@"Role 6",
};

NSString * getRoleName(){
	int total = (sizeof(role_name)/sizeof(role_name[0]));
	return role_name[getRandomInt(0, total-1)];
}

static GameStart * gameStart;
static GameStartRole * selectRole;

//static SEL parentCall;

@implementation CCSimpleContentLayer

-(void)setContentSize:(CGSize)contentSize{
	
	if(self.contentSize.height==0){
		[super setContentSize:contentSize];
		return;
	}
	
	CGSize size = [CCDirector sharedDirector].winSize;
	if(contentSize.height<size.height){
		[super setContentSize:contentSize];
		return;
	}
	
}

@end

@implementation GameStart

-(NSString*)getRoleName{
	
	if(sex==1){
		NSString *name=[randomName1 objectAtIndex:getRandomInt(0, randomName1.count-1)];
		NSString *lastname=[randomLastName1 objectAtIndex:getRandomInt(0, randomLastName1.count-1)];
		NSString *roleName=[NSString stringWithFormat:@"%@%@",lastname,name];
		return roleName;
	}else{
		NSString *name=[randomName0 objectAtIndex:getRandomInt(0, randomName0.count-1)];
		NSString *lastname=[randomLastName0 objectAtIndex:getRandomInt(0, randomLastName0.count-1)];
		NSString *roleName=[NSString stringWithFormat:@"%@%@",lastname,name];
		return roleName;
	}
}

+(BOOL)isOpen{
	if(gameStart){
		return YES;
	}else{
		return NO;
	}
}

+(void)show{
	gameStart = [GameStart node];
	[[Game shared] addChild:gameStart z:INT16_MAX];
	[gameStart showStart];
}

+(void)updateUserInfo{
	if(gameStart){
		[gameStart updateLoginUserInfo];
	}
}

+(void)hide{
	
	if(gameStart){
		[gameStart removeFromParentAndCleanup:YES];
	}
	gameStart = nil;
	
	[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
	[CCLabelBMFont purgeCachedData];
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	[[CCFileUtils sharedFileUtils] purgeCachedEntries];
	
}

+(void)create{
	if(!gameStart){
		gameStart = [GameStart node];
		[[Game shared] addChild:gameStart z:INT16_MAX];
	}
	[gameStart showCreate];
}

+(void)list{
	if(!gameStart){
		gameStart = [GameStart node];
		[[Game shared] addChild:gameStart z:INT16_MAX];
	}
	//[gameStart showList];
	[gameStart showServer];
}

/*
 +(BOOL)isShowServerList{
 if(gameStart){
 return [gameStart isShowServer];
 }
 return NO;
 }
 
 +(void)showPlayerList{
 if([GameStart isShowServerList]){
 [gameStart showPlayers];
 }
 }
 */

#pragma mark -
/*
 -(BOOL)isShowServer{
 if(layer_server){
 return YES;
 }
 return NO;
 }
 */

// 如果是EF用户中心，确保数据返回后才可点击
-(BOOL)checkSNSValid
{
#if (GAME_SNS_TYPE==5 || GAME_SNS_TYPE==6)
	return ![EFUserAction isSend];
#endif
	return YES;
}

-(void)dealloc{
	[randomLastName1 release];
	[randomName1 release];
	[randomLastName0 release];
	[randomName0 release];
	[super dealloc];
	CCLOG(@"GameStart dealloc");
}

-(void)onEnter{
	
	[super onEnter];
	randomLastName1 =[[NSMutableArray alloc]init];
	randomName1=[[NSMutableArray alloc]init];
	
	randomLastName0=[[NSMutableArray alloc]init];
	randomName0=[[NSMutableArray alloc]init];
	sex=1;
	
	NSArray *names=[[GameDB shared] getNames];
	for(NSDictionary *dict in names){
		//CCLOG(@"%i",[[dict objectForKey:@"sex"]integerValue]);
		if([[dict objectForKey:@"sex"]integerValue]==1 && [[dict objectForKey:@"t"]integerValue]==1){
			[randomLastName1 addObject:[dict objectForKey:@"n"]];
		}
		if([[dict objectForKey:@"sex"]integerValue]==1 && [[dict objectForKey:@"t"]integerValue]==2){
			[randomName1 addObject:[dict objectForKey:@"n"]];
		}
		if([[dict objectForKey:@"sex"]integerValue]==2 && [[dict objectForKey:@"t"]integerValue]==1){
			[randomLastName0 addObject:[dict objectForKey:@"n"]];
		}
		if([[dict objectForKey:@"sex"]integerValue]==2 && [[dict objectForKey:@"t"]integerValue]==2){
			[randomName0 addObject:[dict objectForKey:@"n"]];
		}
		if([[dict objectForKey:@"sex"]integerValue]==0){
			[randomLastName0 addObject:[dict objectForKey:@"n"]];
			[randomLastName1 addObject:[dict objectForKey:@"n"]];
		}
		
	}
	/*
	[randomLastName1 addObject:@"比尔"];
	[randomName1 addObject:@"盖茨"];
	
	[randomLastName1 addObject:@"约翰"];
	[randomName1 addObject:@"艾维"];
	
	[randomLastName1 addObject:@"蒂姆"];
	[randomName1 addObject:@"库克"];
	
	[randomLastName1 addObject:@"张"];
	[randomName1 addObject:@"无忌"];
	
	[randomLastName1 addObject:@"郭"];
	[randomName1 addObject:@"靖"];
	
	[randomLastName0 addObject:@"赵"];
	[randomName0 addObject:@"敏"];
	
	[randomLastName0 addObject:@"黄"];
	[randomName0 addObject:@"蓉"];
	
	[randomLastName0 addObject:@"周"];
	[randomName0 addObject:@"芷若"];
	
	[randomLastName0 addObject:@"李"];
	[randomName0 addObject:@"秋水"];
     */
    //
    [randomLastName1 addObject:NSLocalizedString(@"start_last_name_1",nil)];
	[randomName1 addObject:NSLocalizedString(@"start_name_1",nil)];
	
    [randomLastName1 addObject:NSLocalizedString(@"start_last_name_2",nil)];
	[randomName1 addObject:NSLocalizedString(@"start_name_2",nil)];
	
    [randomLastName1 addObject:NSLocalizedString(@"start_last_name_3",nil)];
	[randomName1 addObject:NSLocalizedString(@"start_name_3",nil)];
	
    [randomLastName1 addObject:NSLocalizedString(@"start_last_name_4",nil)];
	[randomName1 addObject:NSLocalizedString(@"start_name_4",nil)];
	
    [randomLastName1 addObject:NSLocalizedString(@"start_last_name_5",nil)];
	[randomName1 addObject:NSLocalizedString(@"start_name_5",nil)];
	
    [randomLastName1 addObject:NSLocalizedString(@"start_last_name_6",nil)];
	[randomName1 addObject:NSLocalizedString(@"start_name_6",nil)];
	
    [randomLastName1 addObject:NSLocalizedString(@"start_last_name_7",nil)];
	[randomName1 addObject:NSLocalizedString(@"start_name_7",nil)];
	
    [randomLastName1 addObject:NSLocalizedString(@"start_last_name_8",nil)];
	[randomName1 addObject:NSLocalizedString(@"start_name_8",nil)];
	
    [randomLastName1 addObject:NSLocalizedString(@"start_last_name_9",nil)];
	[randomName1 addObject:NSLocalizedString(@"start_name_9",nil)];
	
	[[[CCDirector sharedDirector]touchDispatcher]addTargetedDelegate:self priority:-100 swallowsTouches:YES];
	
	currenRoleIndex=0;
	
	[GameConnection addPost:@"ConnPost_doStartDirect" target:self call:@selector(doStartDirect)];
	
	//fix chao
	//[GameConnection addPost:ConnPost_repeatName target:self call:@selector(showRepeatName)];
	//end
	//[GameConnection addPost:ConnPost_disconnect target:self call:@selector(listenDis)];
}

/*
 -(void)showRepeatName{
 [ShowItem showItemAct:@"名字重复！请重新输入"];
 }
 */

-(void)onExit{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[GameConnection removePostTarget:self];
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	if(input_role_name){
		[input_role_name release];
		input_role_name = nil;
	}
	[self cleanAll];
	[super onExit];
}

-(void)cleanAll{
	
	if(menu){ [menu removeFromParentAndCleanup:YES]; menu = nil;}
	if(content){ [content removeFromParentAndCleanup:YES]; content = nil;}
	if(scrollLayer){ [scrollLayer removeFromParentAndCleanup:YES]; scrollLayer = nil;}
	
	server1 = nil;
	server2 = nil;
	selectTarget = nil;
	listPlayer = nil;
	isLoadPlayerList=NO;
	isShowPlayerList = NO;
	isHidePlayerList = NO;
	selectServerId = -1;
	
	if(serverPlayrs){
		[serverPlayrs release];
		serverPlayrs = nil;
	}
	
	if(layer_start){	[layer_start removeFromParentAndCleanup:YES];	layer_start = nil;}
	if(layer_server){	[layer_server removeFromParentAndCleanup:YES];	layer_server = nil;}
	if(layer_create){	[layer_create removeFromParentAndCleanup:YES];	layer_create = nil;}
	if(layer_list){		[layer_list removeFromParentAndCleanup:YES];	layer_list = nil;}
	
	if(name_label){ name_label = nil; }
	
	[self hideVersion];
	[self removeInputField];
	
	selectRole = nil;
	
	[self removeChildByTag:123 cleanup:YES];
	[self removeChildByTag:-3435888 cleanup:YES];
	
	[[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
	[[CCTextureCache sharedTextureCache] removeUnusedTextures];
	
}

-(void)loadStartBackground{
	[self removeChildByTag:123 cleanup:YES];
	
	CCLayer * sbg = [CCLayer node];
	sbg.anchorPoint = ccp(0,0);
	[self addChild:sbg z:-100 tag:123];
	
	CGPoint center = ccp(sbg.contentSize.width/2,sbg.contentSize.height/2);
	
	CCSprite * bg1 = [CCSprite spriteWithFile:@"images/start/start-bg/bg1.jpg"];
	CCSprite * bg2 = [CCSprite spriteWithFile:@"images/start/start-bg/bg2.png"];
	bg1.position = center;
	bg2.position = center;
	[sbg addChild:bg1 z:1];
	[sbg addChild:bg2 z:10];
	
	CCSprite * ship = [CCSprite spriteWithFile:@"images/start/start-bg/ship.png"];
	ship.position = center;
	[sbg addChild:ship z:2];
	
	CCMoveTo * move1 = [CCMoveTo actionWithDuration:2.25f position:ccpAdd(center, ccp(0,cFixedScale(6)))];
	CCMoveTo * move2 = [CCMoveTo actionWithDuration:2.25f position:ccpAdd(center, ccp(0,0))];
	id sequence = [CCSequence actions:move1,move2,nil];
	id forever = [CCRepeatForever actionWithAction:sequence];
	[ship runAction:forever];
	
	AnimationViewer * cloud = [AnimationViewer node];
	[sbg addChild:cloud z:3];
	cloud.anchorPoint=ccp(0,0);
	
	AnimationViewer * role1 = [AnimationViewer node];
	[sbg addChild:role1 z:13];
	role1.anchorPoint=ccp(0.5,0);
	
	AnimationViewer * role2 = [AnimationViewer node];
	[sbg addChild:role2 z:11];
	role2.anchorPoint=ccp(0.5,0);
    
    AnimationViewer * role3 = [AnimationViewer node];
	[sbg addChild:role3 z:12];
	role3.anchorPoint=ccp(0.5,0);
	
	[cloud playAnimation:[AnimationViewer loadFileByFileFullPath:@"images/start/start-bg/cloud/" 
															name:@"%d.png"]];
	
	[role1 playAnimation:[AnimationViewer loadFileByFileFullPath:@"images/start/start-bg/p1/" 
															name:@"%d.png"]];
	
	[role2 playAnimation:[AnimationViewer loadFileByFileFullPath:@"images/start/start-bg/p2/" 
															name:@"%d.png"]];
	
    [role3 playAnimation:[AnimationViewer loadFileByFileFullPath:@"images/start/start-bg/p3/"
															name:@"%d.png"]];
    
	role1.position = ccpAdd(center, ccp(cFixedScale(244),cFixedScale(-318)));
	role2.position = ccpAdd(center, ccp(cFixedScale(350),cFixedScale(-198)));
    role3.position = ccpAdd(center, ccp(cFixedScale(400),cFixedScale(-290)));
	
}

-(void)loadBackground{
	
	NSString * bg_file = @"images/start/start-bg.jpg";
	
	if(layer_create){
		//背景图
		if (iPhoneRuningOnGame()) {
			bg_file = @"images/ui/wback/bg-create.jpg";
		}else{
			bg_file = @"images/start/create/bg-create.jpg";
		}
		[self removeChildByTag:123 cleanup:YES];
	}
	if(layer_list){
		bg_file = @"images/start/list/bg-list.jpg";
		[self removeChildByTag:123 cleanup:YES];
	}
	
	
	if(![self getChildByTag:123]){
		
		CGSize size = [CCDirector sharedDirector].winSize;
		
		CCSprite * bg = [CCSprite spriteWithFile:bg_file];
		bg.anchorPoint = ccp(0,0);
		
		bg.position = ccp(
						  (size.width-bg.contentSize.width)/2,
						  (size.height-bg.contentSize.height)/2 );
		
		//bg.opacity = 128;
		//bg.scale = (size.width/bg.contentSize.width);
		
		[self addChild:bg z:-100 tag:123];
		
		//		NSString* path_ = [NSString stringWithFormat:@"images/start/logo.png"];
		//#if GAME_SNS_TYPE == 2
		//		path_ = [NSString stringWithFormat:@"images/start/bd-logo.png"];
		//#endif
		//		if (path_) {
		//			CCSprite * logo = [CCSprite spriteWithFile:path_];
		//			if (iPhoneRuningOnGame()) {
		//				logo.position = ccp(bg.contentSize.width/2,bg.contentSize.height/2+80/2.0f);
		//			}else{
		//				logo.position = ccp(bg.contentSize.width/2,bg.contentSize.height/2+50);
		//			}
		//			[bg addChild:logo];
		//		}
	}
	
}

-(void)loadMenu:(CCNode*)target{
	menu = [CCMenu menuWithItems:nil];
	[target addChild:menu];
}

-(void)showContent{
	content = [CCLayer node];
	[self addChild:content z:-99];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	CCSprite * title_bg = [CCSprite spriteWithFile:@"images/start/title.png"];
	[content addChild:title_bg];
	
	CCSprite * bar1 = [CCSprite spriteWithFile:@"images/start/content/bar-1.png"];
	[content addChild:bar1 z:-100];
	
	CCSprite * bar2 = [CCSprite spriteWithFile:@"images/start/content/bar-2.png"];
	[content addChild:bar2 z:-100];
	
	CCSprite * bar3 = [CCSprite spriteWithFile:@"images/start/content/bar-3.png"];
	[content addChild:bar3 z:-100];
	
	CCSprite * index = [CCSprite spriteWithFile:@"images/start/content/page-index.png"];
	[content addChild:index z:-100];
	
	CCSprite * bar_bg = [CCSprite spriteWithFile:@"images/start/content/bg.png"];
	bar_bg.anchorPoint = ccp(0.5,1);
	[content addChild:bar_bg z:-101];
	
	if(iPhoneRuningOnGame()){
		title_bg.position = ccp(winSize.width/2,winSize.height/2+270/2);
		bar1.position = ccp(winSize.width/2,winSize.height/2+(270-5)/2);
		bar2.position = ccp(winSize.width/2,215);
		bar3.position = ccp(winSize.width/2,0);
		index.position = ccp(winSize.width/2,15);
		bar_bg.position = ccp(winSize.width/2,winSize.height/2+(270-7)/2);
		bar_bg.scaleY = 580;
	}else{
		title_bg.position = ccp(winSize.width/2,winSize.height/2+270);
		bar1.position = ccp(winSize.width/2,winSize.height/2+270-5);
		bar2.position = ccp(winSize.width/2,500);
		bar3.position = ccp(winSize.width/2,70);
		index.position = ccp(winSize.width/2,95);
		bar_bg.position = ccp(winSize.width/2,winSize.height/2+270-7);
		bar_bg.scaleY = 580;
	}
	
}

-(void)showCloseBtn:(CCNode*)target{
	if(menu){
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		NSArray * btns = getBtnSprite(@"images/ui/button/bt_close.png");
		CCMenuItemImage * item;
		
		item = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
									  selectedSprite:[btns objectAtIndex:1]
											  target:self
											selector:@selector(doCloseBtn)];
		
		if(iPhoneRuningOnGame()){
			item.position = ccp(winSize.width/2-16,winSize.height/2-14);
		}else{
			item.position = ccp(winSize.width/2-32,winSize.height/2-28);
		}
		
		[menu addChild:item];
		//parentCall = nil;
	}
}

-(void)doCloseBtn{
	if([Game shared].isInGameing){
		[self closeWindow];
	}else{
		[self showStart];
	}
}

-(void)closeWindow{
	[GameStart hide];
	[[Game shared] showAll];
}

-(void)showScorllLayer:(NSArray*)layers{
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	scrollLayer = [CCScrollLayer nodeWithLayers:layers widthOffset:0];
	//buyLayer.marginOffset = 50;
	//scrollLayer.delegate = self;
	scrollLayer.pagesIndicatorNormalColor = ccc4(255, 255, 255, 255);
	scrollLayer.pagesIndicatorSelectedColor = ccc4(178, 67, 0, 255);
	
	if(iPhoneRuningOnGame()){
		scrollLayer.pagesIndicatorSize = 3.0f;
		scrollLayer.pagesIndicatorPosition = ccp(winSize.width/2, 15);
	}
	
	scrollLayer.contentSize = winSize;
	//scrollLayer.isInContent = YES;
	[scrollLayer updatePages];
	
	[layer_server addChild:scrollLayer z:10];
	
}

-(CCMenuItem*)getServerBtn:(NSDictionary*)dict{
	//fix chao
	//NSArray * btns = getBtnSprite(@"images/start/server/btn-bg.png");
	NSArray * btns = getBtnSpriteWithStatus(@"images/start/server/btn-bg");
	//end
	CCLabelFX * label1 = [CCLabelFX labelWithString:[dict objectForKey:@"name"]
										 dimensions:CGSizeMake(0,0)
										  alignment:kCCTextAlignmentCenter
										   fontName:GAME_DEF_CHINESE_FONT
										   fontSize:20
									   shadowOffset:CGSizeMake(-1.5, -1.5)
										 shadowBlur:2.0f];
	CCLabelFX * label2 = [CCLabelFX labelWithString:[dict objectForKey:@"name"]
										 dimensions:CGSizeMake(0,0)
										  alignment:kCCTextAlignmentCenter
										   fontName:GAME_DEF_CHINESE_FONT
										   fontSize:20
									   shadowOffset:CGSizeMake(-1.5, -1.5)
										 shadowBlur:2.0f];
	label1.anchorPoint = ccp(0.5,0.5);
	label2.anchorPoint = ccp(0.5,0.5);
	
	CCSprite * btn1 = [btns objectAtIndex:0];
	CCSprite * btn2 = [btns objectAtIndex:1];
	[btn1 addChild:label1];
	[btn2 addChild:label2];
	
	label1.position = ccp(btn1.contentSize.width/2 - cFixedScale(20),btn1.contentSize.height/2);
	label2.position = ccp(btn2.contentSize.width/2 - cFixedScale(20),btn2.contentSize.height/2);
	
	CCMenuItemImage * item = [CCMenuItemImage itemWithNormalSprite:btn1
													selectedSprite:btn2
															target:self
														  selector:@selector(doSelectServer:)];
	item.tag = [[dict objectForKey:@"id"] intValue];
	
	//TODO don't delete
	int status = [[dict objectForKey:@"status"] intValue];
	CCSprite * s1 = nil;
	if(status==1) s1 = [CCSprite spriteWithFile:@"images/start/server/status-1.png"];
	if(status==2) s1 = [CCSprite spriteWithFile:@"images/start/server/status-2.png"];
	if(status==3) s1 = [CCSprite spriteWithFile:@"images/start/server/status-3.png"];
	if(s1){
		s1.anchorPoint = ccp(1,0.5);
		s1.position = ccp(btn1.contentSize.width-cFixedScale(30),btn1.contentSize.height/2);
		[btn1 addChild:s1];
	}
	CCSprite * s2 = nil;
	if(status==1) s2 = [CCSprite spriteWithFile:@"images/start/server/status-1.png"];
	if(status==2) s2 = [CCSprite spriteWithFile:@"images/start/server/status-2.png"];
	if(status==3) s2 = [CCSprite spriteWithFile:@"images/start/server/status-3.png"];
	if(s2){
		s2.anchorPoint = ccp(1,0.5);
		s2.position = ccp(btn2.contentSize.width-cFixedScale(30),btn2.contentSize.height/2);
		[btn2 addChild:s2];
	}
	
	return item;
}

#pragma mark -
-(void)updateLoginUserInfo{
	if(layer_start){
		
		[menu removeChildByTag:701];
		[menu removeChildByTag:702];
		[layer_start removeChildByTag:21301];
		
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		
		NSArray * btns = nil;
		CCMenuItemImage * item = nil;
		
		NSDictionary * info = [[SNSHelper shared] getUserInfo];
		
		CCSprite *spr = [CCSprite spriteWithFile:@"images/start/btn-link-back.png"];
		item = [CCMenuItemImage itemWithNormalSprite:spr
									  selectedSprite:nil
											  target:self
											selector:@selector(linkButtonBackCall:)];
		item.tag = 701;
		item.anchorPoint = ccp(0,1);
		item.position = ccp(-winSize.width/2+cFixedScale(10),winSize.height/2);
		[menu addChild:item];
		
		if([[info objectForKey:@"isGuest"] boolValue] && [[info objectForKey:@"isLogined"] boolValue]){
			btns = getBtnSpriteWithStatus(@"images/start/btn-start-bind");
			CCMenuItemImage * bt_item = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
															   selectedSprite:[btns objectAtIndex:1]
																	   target:self
																	 selector:@selector(linkButtonBackCall:)];
			bt_item.tag = 702;
			bt_item.anchorPoint = ccp(0.5,0.5);
			bt_item.scale = 1.2f;
			if(iPhoneRuningOnGame()){
				bt_item.position = ccp(-winSize.width/2+150,winSize.height/2-35/2);
			}else{
				bt_item.position = ccp(-winSize.width/2+300,winSize.height/2-35);
			}
			[menu addChild:bt_item];
		}
		
		//NSString *nameStr = @"游客";
		//NSString * nameStr = [NSString stringWithFormat:@"欢迎你！%@!",[info objectForKey:@"username"]];
        NSString * nameStr = [NSString stringWithFormat:NSLocalizedString(@"start_welcome",nil),[info objectForKey:@"username"]];
		if(![[info objectForKey:@"isLogined"] boolValue]){
			//nameStr = @"   未登录";
            nameStr = NSLocalizedString(@"start_no_logon",nil);
		}
		
		CCLabelFX * label = [CCLabelFX labelWithString:nameStr
											dimensions:CGSizeMake(0,0)
											 alignment:kCCVerticalTextAlignmentCenter
											  fontName:getCommonFontName(FONT_1)
											  fontSize:22
										  shadowOffset:CGSizeMake(0, 0)
											shadowBlur:0.0f
										   shadowColor:ccc4(0, 0, 0, 255)
											 fillColor:ccc4(250,190,60, 255)
							 ];
		label.anchorPoint = ccp(0,0.5);
		
		if(iPhoneRuningOnGame()){
			label.scale = 0.8;
			label.position = ccp(40+cFixedScale(10),winSize.height-35/2);
		}else{
			label.position = ccp(80+cFixedScale(10),winSize.height-35);
		}
		
		[layer_start addChild:label z:10 tag:21301];
		
	}
}

-(void)showVersion{
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	
	NSString * version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
	#ifdef GAME_SNS_TYPE
	version=[NSString stringWithFormat:@"%@_%i",version,GAME_SNS_TYPE];
	#endif
	CCLabelFX * label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"v%@",version]
										dimensions:CGSizeMake(0,0)
										 alignment:kCCVerticalTextAlignmentCenter
										  fontName:getCommonFontName(FONT_1)
										  fontSize:18
									  shadowOffset:CGSizeMake(0, 0)
										shadowBlur:0.0f
									   shadowColor:ccc4(0, 0, 0, 255)
										 fillColor:ccc4(250,190,60, 255)
						 ];
	label.anchorPoint = ccp(1,0);
	label.position = ccp(winSize.width-cFixedScale(18),cFixedScale(8));
	
	[self addChild:label z:100 tag:8888];
	
}
-(void)hideVersion{
	[self removeChildByTag:8888 cleanup:YES];
}

-(void)showStart{
	
	if(layer_server){
		if([[GameConnection share] isConnection]){
			[[GameConnection share] logout];
		}
	}
	if(layer_list){
		[[GameConnection share] logout];
		[self cleanAll];
		return;
	}
	if(layer_create){
		[[GameConnection share] logout];
	}
	
	[self cleanAll];
	layer_start = [CCLayer node];
	[self addChild:layer_start];
	[self loadMenu:layer_start];
	
	//[self loadBackground];
	[self loadStartBackground];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	NSString* path_ = [NSString stringWithFormat:@"logo.png"];
	
	if (path_ != nil) {
		CCSprite * logo = [CCSprite spriteWithFile:path_];
		if (iPhoneRuningOnGame()) {
			logo.position = ccp(winSize.width/2,winSize.height/2+80/2.0f);
		}else{
			logo.position = ccp(winSize.width/2,winSize.height/2+50);
		}
		//			logo.position = ccp(winSize.width/2,winSize.height/2+cFixedScale(50));
		[layer_start addChild:logo z:-99];
	}
	
	//fix chao
	//NSArray * btns = getBtnSprite(@"images/start/btn-start.png");
	NSArray *btns = getBtnSpriteWithStatus(@"images/start/btn-start");
	//end
	CCMenuItemImage * item = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
													selectedSprite:[btns objectAtIndex:1]
															target:self
														  selector:@selector(doStart:)];
	item.tag = 101;
	item.scale = 1.4;
	
	if(iPhoneRuningOnGame()){
		item.position = ccp(0,winSize.height);
	}else{
		item.position = ccp(0,-(winSize.height/2-295)-55);
	}
	
	[menu addChild:item];
	
	//fix chao
	//btns = getBtnSprite(@"images/start/btn-select-server.png");
	btns = getBtnSpriteWithStatus(@"images/start/btn-select-server");
	item = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
								  selectedSprite:[btns objectAtIndex:1]
										  target:self
										selector:@selector(showServer)];
	item.tag = 102;
	//item.position = ccp(0,-300);
	
	if(iPhoneRuningOnGame()){
		item.position = ccp(0,(winSize.height/2));
	}else{
		item.position = ccp(0,-(winSize.height/2-140)-55);
	}
	
	/*
	 CCSprite *str91=drawString(@"91用户登陆", CGSizeMake(150,10), getCommonFontName(FONT_3), 20, 20, @"ffffff");
	 CCMenuItem *btn91=[CCMenuItem itemWithBlock:^(id n){
	 [Nd91Manager openLogin91:self call:@selector(didlogin91:)];
	 }];
	 [str91 setAnchorPoint:ccp(0, 0)];
	 [str91 setPosition:ccp(0, 0)];
	 [btn91 setContentSize:str91.contentSize];
	 [btn91 addChild:str91];
	 [btn91 setPosition:ccp(0, -(winSize.height/2-40))];
	 [menu addChild:btn91];
	 */
	
	[menu addChild:item];
	//end
	
	BOOL isHasLast = YES;
	int serverId = [GameConfigure shared].serverId;
	if(serverId==0){
		serverId = [GameConnection share].currentServerId;
		isHasLast = NO;
	}
	
	NSDictionary * server = [[GameConnection share] getServerInfoById:serverId];
	
	if(server){
		
		//NSString * msg = [NSString stringWithFormat:@"%@ %@",(isHasLast?@"最近玩过 :":@"进入 :"),[server objectForKey:@"name"]];
		NSString * msg = [NSString stringWithFormat:@"%@ %@",(isHasLast?NSLocalizedString(@"start_near_in",nil):NSLocalizedString(@"start_in",nil)),[server objectForKey:@"name"]];
        
		int status = [[server objectForKey:@"status"] intValue];
		if(status==0){
			//msg = @"服务器关闭了！";
            msg = NSLocalizedString(@"start_close",nil);
		}
		if(status==3){
			//msg = @"服务器维护中！";
            msg = NSLocalizedString(@"start_maintenance",nil);
		}
		if(status==4){
			//msg = @"内测已结束，下次开放测试时间请密切留意论坛信息！";
            msg = NSLocalizedString(@"start_close_info",nil);
		}
		
		//fix chao
		CCLabelTTF *label = [CCLabelTTF labelWithString:msg fontName:getCommonFontName(FONT_1) fontSize:22];
		//		CCLabelFX * label = [CCLabelFX labelWithString:msg
		//											dimensions:CGSizeMake(0,0)
		//											 alignment:kCCVerticalTextAlignmentCenter
		//											  fontName:getCommonFontName(FONT_1)
		//											  fontSize:22
		//										  shadowOffset:CGSizeMake(0, 0)
		//											shadowBlur:0.0f
		//										   shadowColor:ccc4(0, 0, 0, 255)
		//											 fillColor:ccc4(255,255,255, 255)
		//							 ];
		
		label.anchorPoint = ccp(0.5,0);
		
		if(iPhoneRuningOnGame()){
			label.scale = 0.7;
			label.position = ccp(winSize.width/2,50);
		}else{
			label.position = ccp(winSize.width/2,170-45);
		}
		
		CCRenderTexture * stroke = createStroke(label, 1.0,ccBLACK);
		[layer_start addChild:stroke];
		[layer_start addChild:label];
	}
	/*
	NSDictionary * serverInfo = [GameConnection share].serverInfo;
	NSString * note= [serverInfo objectForKey:@"notice"];
	if(note && [note length]>1){
		int fontSize=18;
		if(iPhoneRuningOnGame()){
			fontSize=28;
		}else{
			fontSize=18;
		}
		
		NSArray *noteAr=[note componentsSeparatedByString:@"|"];
		NSString *drawcontent=@"";
		for(NSString *c in noteAr){
			NSArray *dc=[c componentsSeparatedByString:@"#"];
			if(dc.count>1){
				drawcontent =[drawcontent stringByAppendingFormat:@"%@#38d3ff#%i#0#URL%@|",[dc objectAtIndex:0],fontSize,[dc objectAtIndex:1]];
			}else{
				drawcontent=[drawcontent stringByAppendingFormat:@"%@#ffffff#%i#0|",[dc objectAtIndex:0],fontSize];
			}
		}
		
		note_bg = [CCSprite spriteWithFile:@"images/start/note.png"];
		
		CCSprite *cccbg=[CCSprite node];
		CCSprite *cccontent=nil;
		
		
		if(iPhoneRuningOnGame())
		{
			cccontent=drawString(drawcontent, CGSizeMake(note_bg.contentSize.width*2-40, 1*2), getCommonFontName(FONT_1), fontSize, fontSize+2, @"ffffff");
		}else{
			cccontent=drawString(drawcontent, CGSizeMake(note_bg.contentSize.width-40, 1), getCommonFontName(FONT_1), fontSize, fontSize+2, @"ffffff");
		}
		if(cccontent.contentSize.height<note_bg.contentSize.height-cFixedScale(65)){
			cccbg.contentSize=CGSizeMake(cccontent.contentSize.width, note_bg.contentSize.height-cFixedScale(65));
		}else{
			cccbg.contentSize=CGSizeMake(cccontent.contentSize.width, cccontent.contentSize.height);
		}
		CGSize showsize=CGSizeMake(note_bg.contentSize.width-cFixedScale(40), note_bg.contentSize.height-cFixedScale(80));
		panel=[CCPanel panelWithContent:cccbg viewSize:showsize];
		
		
		[cccontent setPosition:ccp(0, cccbg.contentSize.height-cccontent.contentSize.height)];
		[panel setPosition:ccp(cFixedScale(20), cFixedScale(20))];
		[panel showScrollBar:@"images/ui/common/scroll3.png"];
		[panel updateContentToTop];
		[note_bg setAnchorPoint:ccp(0, 0)];
		[cccontent setAnchorPoint:ccp(0, 0)];
		[cccbg setAnchorPoint:ccp(0, 0)];
		
		[cccbg addChild:cccontent];
		[note_bg addChild:panel];
		[layer_start addChild:note_bg];
		
		
		
		[GameConnection addPost:@"URL" target:self call:@selector(openURL:)];
		
		[self showVersion];
	}
	*/
    [GameConnection addPost:@"URL" target:self call:@selector(openURL:)];
    
    [self showVersion];
    //
	[self updateLoginUserInfo];
}


-(void)openURL:(NSNotification*)url{
	CCLOG(@"URL:%@",url.object);
	NSURL *urls=[NSURL URLWithString:[NSString stringWithFormat:@"http://%@",url.object]];
	[[UIApplication sharedApplication]openURL:urls];
}
/*
 #pragma mark 91成功登陆返回
 -(void)didlogin91:(NSNotification *)n{
 CCLOG(@"%@",n);
 }
 */

//fix chao
-(void)linkButtonBackCall:(CCNode*)sender{
	if (![self checkSNSValid]) return;
	
	//TODO chao 加入绑定功能
	CCLOG(@"linkButtonBackCall");
	
	if(sender.tag==701){
		if([[SNSHelper shared] isLogined]){
			[[SNSHelper shared] enterUserCenter];
		}else{
			[[SNSHelper shared] loginUser];
		}
	}
	
	if(sender.tag==702){
		[[SNSHelper shared] guestRegist];
	}
	
}
//end

-(void)doStart:(CCMenuItem*)sender{
	if (![self checkSNSValid]) return;
	
	[[GameSoundManager shared] click];
	if(![[GameConnection share] checkCurrentServerCanEnter]){
		return;
	}
	[GameConnection post:ConnPost_passStart object:nil];
}

// 用户中心点击游戏试玩，如果当前是游客试玩状态，相当于点击了开始按钮
-(void)doStartDirect
{
	if(![[GameConnection share] checkCurrentServerCanEnter]){
		return;
	}
	[GameConnection post:ConnPost_passStart object:nil];
}

-(void)showServer{
	
	if (![self checkSNSValid]) return;
	
	[[GameSoundManager shared] click];
	
	[self cleanAll];
	layer_server = [CCLayer node];
	[self addChild:layer_server];
	[self loadMenu:layer_server];
	[self showCloseBtn:layer_server];
	[self loadBackground];
	
	[self showContent];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	CCSprite * title = [CCSprite spriteWithFile:@"images/start/server/select-server.png"];
	[layer_server addChild:title];
	
	CCSprite * msg1 = [CCSprite spriteWithFile:@"images/start/server/msg-last.png"];
	[layer_server addChild:msg1];
	
	CCSprite * msg2 = [CCSprite spriteWithFile:@"images/start/server/msg-offer.png"];
	[layer_server addChild:msg2];
	
	if(iPhoneRuningOnGame()){
		title.position = ccp(winSize.width/2,winSize.height/2+270/2);
		msg1.position = ccp(winSize.width/2-150/2,winSize.height/2+220/2);
		msg2.position = ccp(winSize.width/2+150/2,winSize.height/2+220/2);
	}else{
		title.position = ccp(winSize.width/2,winSize.height/2+270);
		msg1.position = ccp(winSize.width/2-150,winSize.height/2+220);
		msg2.position = ccp(winSize.width/2+150,winSize.height/2+220);
	}
	
	int serverId = [GameConfigure shared].serverId;
	if(serverId==0){
		serverId = [GameConnection share].currentServerId;
	}
	
	NSDictionary * server;
	CCMenuItem * btn;
	
	server = [[GameConnection share] getServerInfoById:serverId];
	btn = [self getServerBtn:server];
	if(iPhoneRuningOnGame()){
		btn.position = ccp(-150/2,160/2);
	}else{
		btn.position = ccp(-150,160);
	}
	server1 = btn;
	[menu addChild:btn];
	
	
	int recommendServerId = [GameConnection share].recommendServerId ;
	if (recommendServerId == 0) {
		recommendServerId = [GameConnection share].currentServerId;
	}
	
	server = [[GameConnection share] getServerInfoById:recommendServerId];
	btn = [self getServerBtn:server];
	if(iPhoneRuningOnGame()){
		btn.position = ccp(150/2,160/2);
	}else{
		btn.position = ccp(150,160);
	}
	server2 = btn;
	[menu addChild:btn];
	
	NSMutableArray * layers = [NSMutableArray array];
	NSMutableArray * servers = [NSMutableArray array];
	[servers addObjectsFromArray:[[GameConnection share] getAllServer]];
	
	//int page = [servers count]%8-1;
	int page = [servers count]/8+1;
	
	for(int i=0;i<page;i++){
		
		CCLayer * layer = [CCLayer node];
		CCMenu * sub = [CCMenu menuWithItems:nil];
		[layer addChild:sub z:0 tag:123];
		[layers addObject:layer];
		
		for(int y=0;y<8;y++){
			int t_i = (i*8+y);
			if(t_i<[servers count]){
				NSDictionary * server = [servers objectAtIndex:t_i];
				if(server){
					CCMenuItem * btn = [self getServerBtn:server];
					int t_x = (y%2==0)?-150:150;
					int t_y = 60+(y/2)*-90;
					
					if(iPhoneRuningOnGame()){
						t_x /= 2;
						t_y /= 2;
					}
					
					btn.position = ccp(t_x,t_y);
					[sub addChild:btn];
				}
			}
		}
		
	}
	
	[self showScorllLayer:layers];
	[self showVersion];
	
}
//点击服务器时显示的角色列表
-(void)showPlayers{
	
	isShowPlayerList = YES;
	
	if(isHidePlayerList){
		return;
	}
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	int t_y = 0;
	int t_h = 0;
	
	if(selectTarget==server1 || selectTarget==server2){
		for(CCLayer * layer in scrollLayer.pages){
			CCNode * target = [layer getChildByTag:123];
			int index = 0;
			for(CCNode * node in target.children){
				int r = 4-(index/2+1);
				
				t_y = r*-30;
				if(iPhoneRuningOnGame()){
					t_y = r*-15 - 10;
				}
				
				id move = [CCMoveTo actionWithDuration:0.15f
											  position:ccpAdd(node.position, ccp(0,t_y))];
				[node runAction:move];
				index++;
			}
		}
	}else{
		
		int sr = 0;
		int index = 0;
		for(CCNode * node in selectTarget.parent.children){
			int r = index/2+1;
			if(node==selectTarget) sr = r;
			index++;
		}
		
		index = 0;
		for(CCNode * node in selectTarget.parent.children){
			int r = index/2+1;
			if(r<=sr){
				t_y = r*30-10;
				if(iPhoneRuningOnGame()){
					t_y = r*15-8;
				}
				id move = [CCMoveTo actionWithDuration:0.15f
											  position:ccpAdd(node.position, ccp(0,t_y))];
				[node runAction:move];
				
				if(node==selectTarget) t_h = t_y;
				
			}else{
				t_y = (4-r)*-30-30;
				if(iPhoneRuningOnGame()){
					t_y = (4-r)*-15-18;
				}
				id move = [CCMoveTo actionWithDuration:0.15f
											  position:ccpAdd(node.position, ccp(0,t_y))];
				[node runAction:move];
			}
			index++;
		}
	}
	
	listPlayer = [CCSprite spriteWithFile:@"images/start/server/player-list-bg.png"];
	listPlayer.anchorPoint = ccp(0.5,0.5);
	listPlayer.scaleX = 1.0f;
	listPlayer.scaleY = 0.0f;
	[selectTarget.parent.parent addChild:listPlayer z:100 tag:1333];
	
	if(selectTarget==server1 || selectTarget==server2){
		if(iPhoneRuningOnGame()){
			listPlayer.position = ccp(winSize.width/2,winSize.height/2+25);
		}else{
			listPlayer.position = ccp(winSize.width/2,winSize.height/2+60);
		}
	}else{
		int ty = winSize.height/2+selectTarget.position.y-94+t_h;
		if(iPhoneRuningOnGame()){
			ty = winSize.height/2+selectTarget.position.y-94/2+t_h;
		}
		listPlayer.position = ccp(winSize.width/2,ty);
	}
	
	id scale = [CCScaleTo actionWithDuration:0.15f scaleX:1.0f scaleY:1.0f];
	id call = [CCCallBlock actionWithBlock:^(void){
		isShowPlayerList = NO;
	}];
	[listPlayer runAction:[CCSequence actions:scale,call,nil]];
	
	/*
	 NSMutableArray * players = [NSMutableArray array];
	 GameConfigure * config = [GameConfigure shared];
	 if([config.userInfo objectForKey:@"players"]){
	 [players addObjectsFromArray:[config.userInfo objectForKey:@"players"]];
	 }
	 */
	
	for(int i=0;i<3;i++){
		
		CCSimpleButton * p = nil;
		if(i<[serverPlayrs count]){
			
			NSDictionary * player = [serverPlayrs objectAtIndex:i];
			
			int pid = [[player objectForKey:@"id"] intValue];
			int rid = [[player objectForKey:@"rid"] intValue];
			int level = [[player objectForKey:@"level"] intValue];
			
			p = [CCSimpleButton spriteWithFile:@"images/start/server/p1.png"
										select:@"images/start/server/p2.png" ];
			
			CCLabelFX * label1 = [CCLabelFX labelWithString:[player objectForKey:@"name"]
												 dimensions:CGSizeMake(0,0)
												  alignment:kCCTextAlignmentLeft
												   fontName:GAME_DEF_CHINESE_FONT
												   fontSize:22
											   shadowOffset:CGSizeMake(-1.5, -1.5)
												 shadowBlur:2.0f];
			
//			CCLabelFX * label2 = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d级",level]
//												 dimensions:CGSizeMake(0,0)
//												  alignment:kCCTextAlignmentLeft
//												   fontName:GAME_DEF_CHINESE_FONT
//												   fontSize:20
//											   shadowOffset:CGSizeMake(-1.5, -1.5)
//												 shadowBlur:2.0f];
            CCLabelFX * label2 = [CCLabelFX labelWithString:[NSString stringWithFormat:NSLocalizedString(@"start_level",nil),level]
												 dimensions:CGSizeMake(0,0)
												  alignment:kCCTextAlignmentLeft
												   fontName:GAME_DEF_CHINESE_FONT
												   fontSize:20
											   shadowOffset:CGSizeMake(-1.5, -1.5)
												 shadowBlur:2.0f];
			
			CCSprite * icon = getCharacterIcon(rid,ICON_PLAYER_NORMAL);
			icon.position = ccp(p.contentSize.width/2,p.contentSize.height/2);
			[p addChild:icon];
			
			label1.color = ccc3(232,178,72);
			label2.color = ccc3(222,207,168);
			label1.anchorPoint = ccp(0,1);
			label2.anchorPoint = ccp(0,0);
			
			if(iPhoneRuningOnGame()){
				label1.position = ccp(p.contentSize.width-6,p.contentSize.height-5);
				label2.position = ccp(p.contentSize.width-6,5);
			}else{
				label1.position = ccp(p.contentSize.width-12,p.contentSize.height-10);
				label2.position = ccp(p.contentSize.width-12,10);
			}
			
			[p addChild:label1];
			[p addChild:label2];
			
			p.tag = pid;
			
		}else{
			p = [CCSimpleButton spriteWithFile:@"images/start/server/p3.png"];
			p.touchScale = 1.1f;
			
//			CCLabelFX * label1 = [CCLabelFX labelWithString:@"创建"
//												 dimensions:CGSizeMake(0,0)
//												  alignment:kCCTextAlignmentLeft
//												   fontName:GAME_DEF_CHINESE_FONT
//												   fontSize:24
//											   shadowOffset:CGSizeMake(-1.5, -1.5)
//												 shadowBlur:2.0f];
            CCLabelFX * label1 = [CCLabelFX labelWithString:NSLocalizedString(@"start_create",nil)
												 dimensions:CGSizeMake(0,0)
												  alignment:kCCTextAlignmentLeft
												   fontName:GAME_DEF_CHINESE_FONT
												   fontSize:24
											   shadowOffset:CGSizeMake(-1.5, -1.5)
												 shadowBlur:2.0f];
			
//			CCLabelFX * label2 = [CCLabelFX labelWithString:@"角色"
//												 dimensions:CGSizeMake(0,0)
//												  alignment:kCCTextAlignmentLeft
//												   fontName:GAME_DEF_CHINESE_FONT
//												   fontSize:24
//											   shadowOffset:CGSizeMake(-1.5, -1.5)
//												 shadowBlur:2.0f];
            CCLabelFX * label2 = [CCLabelFX labelWithString:NSLocalizedString(@"start_role",nil)
												 dimensions:CGSizeMake(0,0)
												  alignment:kCCTextAlignmentLeft
												   fontName:GAME_DEF_CHINESE_FONT
												   fontSize:24
											   shadowOffset:CGSizeMake(-1.5, -1.5)
												 shadowBlur:2.0f];
			
			label1.anchorPoint = ccp(0,1);
			label2.anchorPoint = ccp(0,0);
			
			if(iPhoneRuningOnGame()){
				label1.position = ccp(p.contentSize.width-6,p.contentSize.height-5);
				label2.position = ccp(p.contentSize.width-6,5);
			}else{
				label1.position = ccp(p.contentSize.width-12,p.contentSize.height-10);
				label2.position = ccp(p.contentSize.width-12,10);
			}
			
			[p addChild:label1];
			[p addChild:label2];
			
			p.tag = 0;
			
		}
		
		p.priority = -255;
		p.isEnabled = YES;
		p.target = self;
		p.call = @selector(selectPlayer:);
		
		if(iPhoneRuningOnGame()){
			if(i==0) p.position = ccp(winSize.width/2-130,listPlayer.contentSize.height/2);
			if(i==2) p.position = ccp(winSize.width/2+130,listPlayer.contentSize.height/2);
		}else{
			if(i==0) p.position = ccp(winSize.width/2-260,listPlayer.contentSize.height/2);
			if(i==2) p.position = ccp(winSize.width/2+260,listPlayer.contentSize.height/2);
		}
		if(i==1) p.position = ccp(winSize.width/2,listPlayer.contentSize.height/2);
		
		[listPlayer addChild:p];
		
	}
	
}

-(void)selectPlayer:(CCNode*)sender{
	
	int pid = (sender.tag>0?sender.tag:-1);
	
	if([Game shared].isInGameing){
		if([GameConnection share].currentPlayerId==pid &&
		   [GameConnection share].currentServerId==selectServerId){
			[self doCloseBtn];
			return;
		}
	}
	[Intro resetCurrenStep];
	NSMutableDictionary * data = [NSMutableDictionary dictionary];
	[data setObject:[NSNumber numberWithInt:selectServerId] forKey:@"sid"];
	[data setObject:[NSNumber numberWithInt:pid] forKey:@"pid"];
	
	[GameConnection post:ConnPost_selectServerPlayer object:data];
	
	return;
	
	/*
	 if(pid<=0){
	 [NSTimer scheduledTimerWithTimeInterval:0.001f
	 target:self
	 selector:@selector(showCreate)
	 userInfo:nil
	 repeats:NO];
	 }else{
	 [[GameConnection share] enterPlayer:pid];
	 
	 }
	 */
	
}

-(void)hidePlayerList{
	
	int t_y = 0;
	
	if(listPlayer){
		isHidePlayerList = YES;
		listPlayer.scaleX = 1.0f;
		listPlayer.scaleY = 1.0f;
		
		CCSprite * target = listPlayer;
		
		id scale = [CCScaleTo actionWithDuration:0.15f scaleX:1.0f scaleY:0.0f];
		id call = [CCCallBlock actionWithBlock:^(void){
			
			[target removeAllChildrenWithCleanup:YES];
			[target removeFromParentAndCleanup:YES];
			
			isHidePlayerList = NO;
			if(isShowPlayerList){
				[NSTimer scheduledTimerWithTimeInterval:0.001f
												 target:self
											   selector:@selector(showPlayers)
											   userInfo:nil
												repeats:NO];
			}
			
		}];
		[listPlayer runAction:[CCSequence actions:scale,call,nil]];
		
		if(selectTarget==server1 || selectTarget==server2){
			for(CCLayer * layer in scrollLayer.pages){
				CCNode * target = [layer getChildByTag:123];
				int index = 0;
				for(CCNode * node in target.children){
					int r = 4-(index/2+1);
					t_y = r*30;
					if(iPhoneRuningOnGame()){
						t_y = r*15 + 10;
					}
					id move = [CCMoveTo actionWithDuration:0.15f
												  position:ccpAdd(node.position, ccp(0,t_y))];
					[node runAction:move];
					index++;
				}
			}
		}else{
			
			int sr = 0;
			int index = 0;
			for(CCNode * node in selectTarget.parent.children){
				int r = index/2+1;
				if(node==selectTarget) sr = r;
				index++;
			}
			
			index = 0;
			for(CCNode * node in selectTarget.parent.children){
				int r = index/2+1;
				if(r<=sr){
					t_y = r*-30+10;
					if(iPhoneRuningOnGame()){
						t_y = r*-15+8;
					}
					id move = [CCMoveTo actionWithDuration:0.15f
												  position:ccpAdd(node.position, ccp(0,t_y))];
					[node runAction:move];
					
				}else{
					t_y = (4-r)*30+30;
					if(iPhoneRuningOnGame()){
						t_y = (4-r)*15+18;
					}
					id move = [CCMoveTo actionWithDuration:0.15f
												  position:ccpAdd(node.position, ccp(0,t_y))];
					[node runAction:move];
				}
				index++;
			}
			
		}
		
	}else{
		isHidePlayerList = NO;
	}
	listPlayer = nil;
	
}

+(GameStart*)share{
	if(!gameStart){
		gameStart=[GameStart node];
	}
	return gameStart;
}

-(void)doSelectServer:(CCNode*)sender{
	
	if(isLoadPlayerList || isShowPlayerList || isHidePlayerList){
		return;
	}
	if(![[GameConnection share] checkServerCanEnter:sender.tag]){
		return;
	}
	
	NSDictionary * server = [[GameConnection share] getServerInfoById:sender.tag];
	if([[server objectForKey:@"status"] intValue]==3){
		return;
	}
	
	if(![[SNSHelper shared] isLogined]){
		[[SNSHelper shared] login];
		return;
	}
	
	[[GameSoundManager shared] click];
	
	[self hidePlayerList];
	if(sender.tag==selectServerId){
		selectServerId = -1;
		return;
	}
	
	selectTarget = sender;
	isLoadPlayerList = YES;
	selectServerId = sender.tag;
	isShowPlayerList = NO;
	
	//[GameConfigure shared].serverId = sender.tag;
	//[GameConnection share].currentServerId = sender.tag;
	
	//[[GameConnection share] loginSNSUser:[[SNSHelper shared] getUserInfo]];
	[[GameConnection share] getServerPlayers:[[SNSHelper shared] getUserInfo]
									  server:selectServerId
									  target:self
										call:@selector(didLoadPlayers:)];
	
}

-(void)didLoadPlayers:(NSArray*)data{
	isLoadPlayerList = NO;
	if(serverPlayrs){
		[serverPlayrs release];
		serverPlayrs = nil;
	}
	
	if(data){
		serverPlayrs = [NSArray arrayWithArray:data];
	}
	
	if(serverPlayrs==nil){
		serverPlayrs = [NSArray array];
	}
	[serverPlayrs retain];
	
	[self showPlayers];
}

//fix chao
//角色的文字介绍
-(CCSprite *)getRoleLabelSprite:(NSInteger)rid width:(NSInteger)width height:(NSInteger)height{
	CCSprite *spr = nil;
	
	NSString *nameStr = nil;
	NSString *infoStr = nil;
	//NSString *powerStr = nil;
	NSString *jobStr = nil;
	NSString *skillStr = nil;
	NSString *officeStr = nil;
	
	float padx=138.0f;
	float pady=4.0f;
	NSDictionary *roleDict = [[GameDB shared]getRoleInfo:rid];
	if (!roleDict) {
		CCLOG(@"error:rid is error");
		return [CCSprite node];
	}
	
	nameStr = [roleDict objectForKey:@"office"];
	infoStr = [roleDict objectForKey:@"info"];
//	jobStr = [NSString stringWithFormat:@"职阶：%@",[roleDict objectForKey:@"job"]];
//	skillStr = [NSString stringWithFormat:@"技能：%@",[[[GameDB shared] getSkillInfo:[[roleDict objectForKey:@"sk2"] intValue]] objectForKey:@"name"]];
//	officeStr = [NSString stringWithFormat:@"位阶：%@",[roleDict objectForKey:@"office"]];
	
    jobStr = [NSString stringWithFormat:NSLocalizedString(@"start_job",nil),[roleDict objectForKey:@"job"]];
	skillStr = [NSString stringWithFormat:NSLocalizedString(@"start_skill",nil),[[[GameDB shared] getSkillInfo:[[roleDict objectForKey:@"sk2"] intValue]] objectForKey:@"name"]];
	officeStr = [NSString stringWithFormat:NSLocalizedString(@"start_office",nil),[roleDict objectForKey:@"office"]];
	// 获得战力
	
	/*
	 BaseAttribute att = [[GameConfigure shared] getRoleAttribute:rid isLoadOtherBuff:YES];
	 int zhanli = getBattlePower(att);
	 //if (zhanli>=0)
	 //{
	 powerStr = [NSString stringWithFormat:@"战力：%d",zhanli];
	 //}
	 */
	if ((!nameStr) || (!infoStr) /*|| (!powerStr)*/ || (!jobStr) || (!skillStr) || (!officeStr)) {
		CCLOG(@"error:message is error");
		return nil;
	}
	spr = [CCSprite node];
	spr.contentSize = CGSizeMake(width, height);
	float fontSize=22;
	if (iPhoneRuningOnGame()) {
		fontSize=24;
	}
	////name
	CCLabelFX *label =[CCLabelFX labelWithString:nameStr
									  dimensions:CGSizeMake(0,0)
									   alignment:kCCVerticalTextAlignmentCenter
										fontName:getCommonFontName(FONT_1)
										fontSize:fontSize
									shadowOffset:CGSizeMake(0, 0)
									  shadowBlur:0.0f
									 shadowColor:ccc4(0, 0, 0, 255)
									   fillColor:ccc4(255,255,255, 255)];
	
	[spr addChild:label];
	
	if(iPhoneRuningOnGame()){
		label.position = ccp((padx+label.contentSize.width/2.0f)/2.0f,height-20/2.0f);
	}else{
		label.position = ccp(spr.contentSize.width/2,108);
	}
	fontSize=15;
	if (iPhoneRuningOnGame()) {
		fontSize=19;
	}
	
	CCLabelFX* last=label;
	
	////info
	label =[CCLabelFX labelWithString:infoStr
						   dimensions:CGSizeMake(0,0)
							alignment:kCCVerticalTextAlignmentCenter
							 fontName:getCommonFontName(FONT_1)
							 fontSize:fontSize
						 shadowOffset:CGSizeMake(0, 0)
						   shadowBlur:0.0f
						  shadowColor:ccc4(0, 0, 0, 255)
							fillColor:ccc4(150,150,150, 255)];
	
	[spr addChild:label];
	
	label.anchorPoint = ccp(0,0.5);
	if(iPhoneRuningOnGame()){
		label.position = ccp(last.position.x-last.contentSize.width/2.0f,last.position.y-last.contentSize.height-pady/2.0f);
	}else{
		label.position = ccp(20,80);
	}
	
	////
	CGPoint pos[] = {{20,50},{135,50},{20,25},{135,25}};
	//NSArray *strArr = [NSArray arrayWithObjects:powerStr,jobStr,skillStr,officeStr, nil];
	NSArray *strArr = [NSArray arrayWithObjects:jobStr,skillStr,officeStr, nil];
	for (int i=0; i<3; i++) {
		fontSize=15;
		if (iPhoneRuningOnGame()) {
			fontSize=19;
		}
		NSString *t_str = nil;
		t_str = [strArr objectAtIndex:i];
		
		last=label;
		
		label =[CCLabelFX labelWithString:t_str
							   dimensions:CGSizeMake(0,0)
								alignment:kCCVerticalTextAlignmentCenter
								 fontName:getCommonFontName(FONT_1)
								 fontSize:fontSize
							 shadowOffset:CGSizeMake(0, 0)
							   shadowBlur:0.0f
							  shadowColor:ccc4(0, 0, 0, 255)
								fillColor:ccc4(240, 150, 28, 255)];
		[spr addChild:label];
		label.anchorPoint = ccp(0,0.5);
		
		if(iPhoneRuningOnGame()){
			label.position = ccp(last.position.x,last.position.y-last.contentSize.height-pady/2.0f);
		}else{
			label.position = pos[i];
		}
		
	}
	return spr;
}
//end
-(void)showCreate{
	
	[self cleanAll];
	layer_create = [CCLayer node];
	
	//fix chao 加入提示
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	//TODO me
	int rbs_w = 36;
	int rbs_h = 36;
	//人物选择背景的大小
	CGSize ts = CGSizeMake(250, 228);
	if(iPhoneRuningOnGame()){
		rbs_w /= 2;
		rbs_h /= 2;
		
		ts.width = 432/2.0f;
		ts.height = 200/2.0f;
	}
	float padx=0;
	if (iPhoneRuningOnGame()) {
		if (isIphone5()) {
			padx=44;
		}
	}
	//角色介绍文字的背景
	CCSprite *role_backSpr1 = getSpriteWithSpriteAndNewSize([CCSprite spriteWithFile:@"images/start/create/role_button_bg.png"],ts);
	CCSprite *role_backSpr2 = getSpriteWithSpriteAndNewSize([CCSprite spriteWithFile:@"images/start/create/role_button_bg.png"],ts);
	CCSprite *role_backSpr3 = getSpriteWithSpriteAndNewSize([CCSprite spriteWithFile:@"images/start/create/role_button_bg.png"],ts);
	
	CCSprite *role_backSpr4 = getSpriteWithSpriteAndNewSize([CCSprite spriteWithFile:@"images/start/create/role_button_bg.png"],ts);
	
	if(iPhoneRuningOnGame()){
		role_backSpr1.position = ccp(role_backSpr1.contentSize.width/2.0f+padx,winSize.height-role_backSpr1.contentSize.height/2.0f-10/2.0f);
		role_backSpr2.position = ccp(role_backSpr1.position.x,role_backSpr1.position.y-role_backSpr1.contentSize.height-10.5f/2.0f);
		role_backSpr3.position = ccp(role_backSpr1.position.x,role_backSpr2.position.y-role_backSpr2.contentSize.height-10.5f/2.0f);
		role_backSpr4.position = ccp(role_backSpr1.position.x,role_backSpr2.position.y-role_backSpr2.contentSize.height-10.5f/2.0f);
	}else{
		role_backSpr1.position = ccp(rbs_w + role_backSpr1.contentSize.width/2,winSize.height-rbs_h - role_backSpr1.contentSize.height/2);
		role_backSpr2.position = ccp(rbs_w + role_backSpr1.contentSize.width/2,winSize.height/2);
		role_backSpr3.position = ccp(rbs_w + role_backSpr1.contentSize.width/2,rbs_h + role_backSpr1.contentSize.height/2);
	}
	//
	[layer_create addChild:role_backSpr1];
	[layer_create addChild:role_backSpr2];
	[layer_create addChild:role_backSpr3];
	//角色介绍文字
	
	CCSprite *roleLabelSpr1 = [self getRoleLabelSprite:1 width:role_backSpr1.contentSize.width height:role_backSpr1.contentSize.height];
	CCSprite *roleLabelSpr2 = [self getRoleLabelSprite:3 width:role_backSpr2.contentSize.width height:role_backSpr2.contentSize.height];
	CCSprite *roleLabelSpr3 = [self getRoleLabelSprite:5 width:role_backSpr2.contentSize.width height:role_backSpr2.contentSize.height];
	
	roleLabelSpr1.position = role_backSpr1.position;
	roleLabelSpr2.position = role_backSpr2.position;
	roleLabelSpr3.position = role_backSpr3.position;
	
	//end
	
	[self addChild:layer_create];
	[self loadMenu:layer_create];
	
	//if([Game checkIsInGameing]){
	[self showCloseBtn:layer_create];
	//}
	
	[self loadBackground];
	
	NSArray * btns;
	CCMenuItemImage * item;
	
	NSString * pt[] = {
		@"{-420,290}",
		@"{-280,290}",
		@"{-420,60}",
		@"{-280,60}",
		@"{-420,-175}",
		@"{-280,-175}",
		//end
	};
	
	if(iPhoneRuningOnGame()){
		pt[0] = @"{-210,125}";
		pt[1] = @"{-56,86}";
		pt[2] = @"{-210,20}";
		pt[3] = @"{-56,-19}";
		pt[4] = @"{-210,-86}";
		pt[5] = @"{-56,-124}";
	}
	//角色按钮
	for (int i = 1 ; i<= 6; i++) {
		
		CCSprite *spr3 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/start/create/bt_c1.png"]] ;
		CCSprite *spr4 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/start/create/bt_c2.png"]] ;
		
		CCSprite * spr1 = getCharacterIcon(i, ICON_PLAYER_BIG);
		spr1.scale = 0.68;
		
		CCMenuItemSprite *bt_spr01 = [CCMenuItemSprite itemWithNormalSprite:spr3 selectedSprite:nil];
		CCMenuItemSprite *bt_spr02 = [CCMenuItemSprite itemWithNormalSprite:spr4 selectedSprite:nil];
		CCMenuItemToggle *item = [CCMenuItemToggle itemWithTarget:self selector:@selector(doSelectRole:) items:bt_spr01,bt_spr02, nil];
		
		item.tag = i;
		
		CGPoint p = CGPointFromString(pt[i-1]);
		
		spr1.anchorPoint = ccp(0.5,0);
		if (iPhoneRuningOnGame()) {
			item.position = p;
			item.scale=1.15f;
			spr1.scale=0.78f;
			spr1.position = ccp(item.position.x+self.contentSize.width/2 + spr3.contentSize.width*item.scale/2,
								item.position.y-spr3.contentSize.height*item.scale/2 + self.contentSize.height/2);
		}else{
			item.position = p;
			spr1.position = ccp(item.position.x+self.contentSize.width/2 + spr3.contentSize.width/2,
								item.position.y-spr3.contentSize.height/2 + self.contentSize.height/2);
			
		}
		[menu addChild:item];
		[layer_create addChild:spr1];
		//end
		
	}
	//end
	
	//使介绍文字在角色头像之上
	[layer_create addChild:roleLabelSpr1];
	[layer_create addChild:roleLabelSpr2];
	[layer_create addChild:roleLabelSpr3];
	
	//fix chao
	//btns = getBtnSprite(@"images/start/btn-start.png");
	if (iPhoneRuningOnGame()) {
		btns = getBtnSpriteWithStatus(@"images/ui/wback/btn-start");
	}else{
		btns = getBtnSpriteWithStatus(@"images/start/btn-start");
	}
	item = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
								  selectedSprite:[btns objectAtIndex:1]
										  target:self
										selector:@selector(doCreate:)];
	item.tag = 101;
	if(iPhoneRuningOnGame()){
		item.scale=0.9f;
		item.position = ccp(110,-137.5);
	}else{
		item.position = ccp(110,-310);
	}
	
	//item.scale = 0.7;
	//end
	[menu addChild:item];
	//输入框背景图
	CCSprite * input =nil;
	if (iPhoneRuningOnGame()) {
		input = [CCSprite spriteWithFile:@"images/ui/wback/bg-input.png"];
	}else{
		input = [CCSprite spriteWithFile:@"images/start/create/bg-input.png"];
	}
	if(iPhoneRuningOnGame()){
		input.position = ccp(winSize.width/2+110,164/2.0f);
	}else{
		input.position = ccp(620,176);
	}
	//	input.opacity=90;
	[layer_create addChild:input z:12 tag:789];
	//文本框中的名字
	name_label = [CCLabelFX labelWithString:@""
								 dimensions:CGSizeMake(0,0)
								  alignment:kCCTextAlignmentCenter
								   fontName:GAME_DEF_CHINESE_FONT
								   fontSize:18
							   shadowOffset:CGSizeMake(-1.5, -1.5)
								 shadowBlur:2.0f];
	name_label.anchorPoint = ccp(0,0.5);
	
	if(iPhoneRuningOnGame()){
		name_label.position = ccp(5/2,input.contentSize.height/2-1);
	}else{
		name_label.position = ccp(5,input.contentSize.height/2-2);
	}
	
	[input addChild:name_label];
	
	//fix chao
	NSArray *arr = getBtnSpriteWithStatus(@"images/start/create/btn_random");
	//CCSprite * tmp = getSpriteWithSpriteAndNewSize([CCSprite spriteWithFile:@"images/btn-tmp.png"],CGSizeMake(56, 32));
	//CCSprite * tmp = [CCSprite spriteWithFile:@"images/btn-tmp.png"];
	//	item = [CCMenuItemImage itemWithNormalSprite:tmp
	//								  selectedSprite:nil
	//										  target:self
	//										selector:@selector(doGetRoleName)];
	item = [CCMenuItemImage itemWithNormalSprite:[arr objectAtIndex:0]
								  selectedSprite:[arr objectAtIndex:1]
										  target:self
										selector:@selector(doGetRoleName)];
	//item.position = ccp(210,-223);
	//item.scaleX = 0.7;
	//item.scaleY = 0.5;
	//item.opacity = 128;
	//fix chao
	//[menu addChild:item];
	
	if(iPhoneRuningOnGame()){
		item.scale=1.4f;
		item.position = ccp(185.5f,-90.5f+12.0f);
	}else{
		item.position = ccp(210-5,-223+16);
	}
	
	CCMenu *newMenu = [CCMenu node];
	[layer_create addChild:newMenu z:999];
	newMenu.position = ccp(winSize.width/2,winSize.height/2);
	[newMenu addChild:item];
	//end
	
	//CCSprite *tmp = getSpriteWithSpriteAndNewSize([CCSprite spriteWithFile:@"images/btn-tmp.png"],CGSizeMake(188, 32));
	//tmp.opacity = 0;
	//输入框后面
	CCSprite *tmp = [CCSprite spriteWithFile:@"images/btn-tmp.png"];
	item = [CCMenuItemImage itemWithNormalSprite:tmp
								  selectedSprite:nil
										  target:self
										selector:@selector(doShowInput)];
	if(iPhoneRuningOnGame()){
		item.position = ccp(92.0f,-90.5+12.0f);
		item.scaleX = 15.0f;
		item.scaleY = 2.5f;
	}else{
		item.position = ccp(78,-223+16);
		item.scaleX = 10.0f;
		item.scaleY = 2.0f;
	}
	
	item.opacity = 0;
	[menu addChild:item];
	//	showNode(item);
	//end
	//TODO show role info
	
	select_role_id = 1;
	[self showSelectRole];
	[self doGetRoleName];
	//fix chao
	CCMenuItemToggle *roleTag = (CCMenuItemToggle *)[menu getChildByTag:select_role_id];
	[roleTag setSelectedIndex:1];
	//end
	
	//[[GameFilter share] loadKeyword];
	
}

-(void)doSelectRole:(CCNode*)sender{
	
	[[GameSoundManager shared] click];
	
	//fix chao
	CCMenuItemToggle *roleTag = (CCMenuItemToggle *)[menu getChildByTag:select_role_id];
	[roleTag setSelectedIndex:0];
	//end
	select_role_id = sender.tag;
	[self showSelectRole];
	sex=sender.tag%2;
	//fix chao
	roleTag = (CCMenuItemToggle *)[menu getChildByTag:select_role_id];
	[roleTag setSelectedIndex:1];
	
	[self doGetRoleName];
	//end
}
-(void)showSelectRole{
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	//TODO show select role viewer by select_role_id
	//----------------------------------------------
	CCSprite *spr = (CCSprite*)[self getChildByTag:-3435888];
	if (spr) {
		[spr stopAllActions];
		[spr removeFromParentAndCleanup:YES];
		spr = nil;
	}
	
	NSString *path = [NSString stringWithFormat:@"images/start/role/player_sbig_%d.png",select_role_id];
	spr = [CCSprite spriteWithFile:path];
	
	if (spr) {
		spr.anchorPoint=ccp(0.5, 0);
		if(iPhoneRuningOnGame()){
			//右边角色
			spr.scale=0.82f;
			spr.position=ccp(winSize.width/2+105, 80);
		}else{
			spr.position=ccp(630, 200);
		}
		[self addChild:spr z:-1 tag:-3435888];
	}
	
}
-(void)doCreate:(CCMenuItem*)sender{
	
	[[GameSoundManager shared] click];
	
	//fix chao 提取文字
	//sender.isEnabled = NO;
	NSString * name =@"";
	if (nameInput) {
		select_role_name = nameInput.text;
		[name_label setString:select_role_name];
        if(input_role_name){
            [input_role_name release];
            input_role_name=select_role_name;
            [input_role_name retain];
        }
	}
	//end
	name = select_role_name;
	
	if(input_role_name){
		name = input_role_name;
	}
	
	//NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	name=[name stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSData *data_l=[name dataUsingEncoding:NSUTF8StringEncoding];
	//[data_l b]
//	char lv[100];
//	[data_l getBytes:lv];
//	CCLOG(@"%c",lv);
	if(data_l.length<4){
		//[ShowItem showItemAct:@"名字禁止使用"];
        [ShowItem showItemAct:NSLocalizedString(@"start_not_use",nil)];
		return;
	}
	if(name.length<=0){
		//[ShowItem showItemAct:@"请填入角色名字"];
        [ShowItem showItemAct:NSLocalizedString(@"start_input_name",nil)];
		return;
	}
	if(data_l.length>15){
		//[ShowItem showItemAct:@"名字超出15个字符"];
        [ShowItem showItemAct:NSLocalizedString(@"start_name_long",nil)];
		return;
	}
	
	/*
	if([[GameFilter share] nameFilter:name]){
		[[Window shared]setVisible:YES];
		//[ShowItem showItemAct:@"名字禁止使用"];
        [ShowItem showItemAct:NSLocalizedString(@"start_not_use",nil)];
		return;
	}
	*/
	
	if (![GameFilter validContract:name]) {
		[[Window shared]setVisible:YES];
		[ShowItem showItemAct:NSLocalizedString(@"start_not_use",nil)];
		return;
	}
	
    CGSize size=[name sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
	
	CCLOG(@"%f",size.width);
	if (size.width>75) {
		//[ShowItem showItemAct:@"名字禁止使用"];
        [ShowItem showItemAct:NSLocalizedString(@"start_not_use",nil)];
		return;
	}
	[Intro resetCurrenStep];
	[GameLoading showMessage:@"" loading:YES];
	//TODO tiger 在游戏中创建角色，重名提示
	[[GameConnection share] newPlayer:name rid:select_role_id];
	
	
}
-(void)doShowInput{
	
	/////
	if (nameInput) {
		return;
	}
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	
	if(iPhoneRuningOnGame()){
		if (isIphone5()) {
			nameInput = [[UITextField alloc] initWithFrame:CGRectMake(601.5/2.0f,160/2.0f-12.0f,300.5/2.0f,42/2.0f)];
		}else{
			nameInput = [[UITextField alloc] initWithFrame:CGRectMake(513.5/2.0f,160/2.0f-12.0f,300.5/2.0f,42/2.0f)];
		}
		[nameInput setFont:[UIFont fontWithName:getCommonFontName(FONT_1) size:11]];
		//		[nameInput setBackgroundColor:[UIColor whiteColor]];
	}else{
		nameInput = [[UITextField alloc] initWithFrame:CGRectMake(495,size.height-GAME_START_INPUT_H-188-16+28/2,190,28)];
		[nameInput setFont:[UIFont fontWithName:getCommonFontName(FONT_1) size:16]];
	}
	
	[nameInput setHidden:YES];
	[nameInput setBorderStyle:UITextBorderStyleRoundedRect];
	
	
	if(input_role_name){
		[nameInput setText:input_role_name];
	}else{
		[nameInput setText:select_role_name];
	}
	nameInput.delegate = self;
	UIView * view = (UIView*)[CCDirector sharedDirector].view;
	[view addSubview:nameInput];
	[nameInput setReturnKeyType:UIReturnKeyDone];
	[nameInput setKeyboardType:UIKeyboardTypeDefault];
	[nameInput becomeFirstResponder];
	
	
	if(iPhoneRuningOnGame()){
		//[CCMoveTo actionWithDuration:0.2 position:ccp(0,281.5/2.0f)],
		[layer_create runAction:[CCSequence actions:
								 [CCMoveTo actionWithDuration:0.2 position:ccp(0,320/2.0f)],
								 [CCCallFunc actionWithTarget:self selector:@selector(showInputField)],
								 
								 nil]
		 ];
		
	}else{
		[layer_create runAction:[CCSequence actions:
								 [CCMoveTo actionWithDuration:0.2 position:ccp(0,GAME_START_INPUT_H)],
								 [CCCallFunc actionWithTarget:self selector:@selector(showInputField)],
								 nil]
		 ];
	}
	
	
	//end 修改显示方式
	
}

-(void)showInputField{
	[nameInput setHidden:NO];
}
-(void)removeInputField{
	if(nameInput){
		[nameInput resignFirstResponder];
		[nameInput removeFromSuperview];
		nameInput = nil;
	}
}



-(void)doGetRoleName{
	select_role_name = [self getRoleName];
	[name_label setString:select_role_name];
	if(nameInput) [nameInput setText:select_role_name];
	
	if(input_role_name){
		[input_role_name release];
		input_role_name = nil;
	}
	
}

-(void)editRoleNameEnd:(UITextField*)textField{
	//fix chao 修改显示方式
	/*
	 CCNode * target = [layer_create getChildByTag:789];
	 id action;
	 if(target){
	 action = [CCMoveTo actionWithDuration:0.2 position:ccp(620,160)];
	 [target runAction:action];
	 }
	 
	 //fix chao
	 CCNode *bt_target = [menu getChildByTag:101];
	 if (bt_target) {
	 [bt_target runAction:[CCMoveTo actionWithDuration:0.2 position:ccp(bt_target.position.x,bt_target.position.y-(GAME_START_INPUT_H-160)) ]];
	 }
	 //end
	 target = [menu getChildByTag:3];
	 if(target){
	 action = [CCMoveTo actionWithDuration:0.2 position:ccp(-420,75)];
	 [target runAction:action];
	 }
	 if(target){
	 target = [menu getChildByTag:4];
	 action = [CCMoveTo actionWithDuration:0.2 position:ccp(-270,75)];
	 [target runAction:action];
	 }
	 if(target){
	 target = [menu getChildByTag:5];
	 action = [CCMoveTo actionWithDuration:0.2 position:ccp(-420,-150)];
	 [target runAction:action];
	 }
	 if(target){
	 target = [menu getChildByTag:6];
	 action = [CCMoveTo actionWithDuration:0.2 position:ccp(-270,-150)];
	 [target runAction:action];
	 }
	 */
	
	[layer_create stopAllActions];
	[layer_create runAction:[CCSequence actions: [CCMoveTo actionWithDuration:0.2 position:ccp(0,0)], [CCCallFunc actionWithTarget:self selector:@selector(showInputField)], nil]];
	//end 修改显示方式
	[self removeInputField];
	float lineWidth=175;
	if (iPhoneRuningOnGame()) {
		lineWidth=275;
	}
	if(name_label){
		NSString* strtemp=textField.text;
		int len=0;
		float width=0.0f;
		for (int i=0; i<strtemp.length; i++) {
			NSString* strOneInTemp=[strtemp substringWithRange:NSMakeRange(i,1)];
			CGSize size=[strOneInTemp sizeWithFont:[UIFont systemFontOfSize:name_label.fontSize]];
			width+=size.width;
			if (width<=lineWidth) {
				len++;
			}else{
				break;
			}
		}
		strtemp=[strtemp substringWithRange:NSMakeRange(0, len)];
		
		if(input_role_name) [input_role_name release];
		input_role_name = strtemp;
		[input_role_name retain];
		[name_label setString:input_role_name];
		name_label.visible = YES;
	}
	
}
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	//	if (string.length<=0) {
	//		return YES;
	//	}
	//	NSString* name=textField.text;
	//	NSData *data_l=[name dataUsingEncoding:NSUTF8StringEncoding];
	//	if (data_l.length>60) {
	//		return NO;
	//	}
    return !isEmo(string);
}

-(BOOL)textFieldShouldReturn:(UITextField*)textField{
	[self editRoleNameEnd:textField];
	return YES;
}
-(void)textFieldDidEndEditing:(UITextField*)textField{
	[self editRoleNameEnd:textField];
}
- (BOOL)textFieldShouldEndEditing:(UITextField*)textField{
	
	//TODO check textField.text
	
	return YES;
}

/*
 -(void)showList{
 
 CGSize winSize = [[CCDirector sharedDirector] winSize];
 
 [[Game shared] hideOther:self];
 
 [self cleanAll];
 layer_list = [CCLayer node];
 [self addChild:layer_list];
 [self loadMenu:layer_list];
 [self showCloseBtn:layer_list];
 [self loadBackground];
 
 NSArray * btns;
 CCMenuItemImage * item;
 //fix chao
 //btns = getBtnSprite(@"images/start/btn-start.png");
 btns = getBtnSpriteWithStatus(@"images/start/btn-start");
 item = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
 selectedSprite:[btns objectAtIndex:1]
 target:self
 selector:@selector(doEnter:)];
 
 if(iPhoneRuningOnGame()){
 item.position = ccp(0,-winSize.height/2+23);
 }else{
 item.position = ccp(0,-winSize.height/2+85);
 }
 
 //item.position = ccp(0,-320);
 //item.scale = 0.7;
 //end
 
 [menu addChild:item];
 ////
 ccColor4B textColor = ccc4(240, 150, 28, 255);
 float textSize = 16.0f;
 float textH = 175;
 CCLabelFX * label = [CCLabelFX labelWithString:@""
 dimensions:CGSizeMake(0,0)
 alignment:kCCTextAlignmentCenter
 fontName:getCommonFontName(FONT_1)
 fontSize:26
 shadowOffset:CGSizeMake(0, 0)
 shadowBlur:0.0f];
 label.anchorPoint = ccp(0.5,0.5);
 if(iPhoneRuningOnGame()){
 label.position = ccp(winSize.width/2-10/2,70);
 }else{
 label.position = ccp(winSize.width/2-10,210);
 }
 
 [layer_list addChild:label z:100 tag:300];
 
 label = [CCLabelFX labelWithString:@""
 dimensions:CGSizeMake(0,0)
 alignment:kCCTextAlignmentCenter
 fontName:getCommonFontName(FONT_1)
 fontSize:textSize
 shadowOffset:CGSizeMake(0, 0)
 shadowBlur:0.0f
 shadowColor:ccc4(255,255,255, 128)
 fillColor:textColor];
 label.anchorPoint = ccp(0.0,0.5);
 
 if(iPhoneRuningOnGame()){
 label.position = ccp(winSize.width/2-160/2,55);
 }else{
 label.position = ccp(winSize.width/2-160,textH);
 }
 
 [layer_list addChild:label z:100 tag:301];
 
 label = [CCLabelFX labelWithString:@""
 dimensions:CGSizeMake(0,0)
 alignment:kCCTextAlignmentCenter
 fontName:getCommonFontName(FONT_1)
 fontSize:textSize
 shadowOffset:CGSizeMake(0, 0)
 shadowBlur:0.0f
 shadowColor:ccc4(255,255,255, 128)
 fillColor:textColor];
 label.anchorPoint = ccp(0.0,0.5);
 
 if(iPhoneRuningOnGame()){
 label.position = ccp(winSize.width/2-60/2,55);
 }else{
 label.position = ccp(winSize.width/2-60,textH);
 }
 
 [layer_list addChild:label z:100 tag:306];
 
 label = [CCLabelFX labelWithString:@""
 dimensions:CGSizeMake(0,0)
 alignment:kCCTextAlignmentCenter
 fontName:getCommonFontName(FONT_1)
 fontSize:textSize
 shadowOffset:CGSizeMake(0, 0)
 shadowBlur:0.0f
 shadowColor:ccc4(255,255,255, 128)
 fillColor:textColor];
 label.anchorPoint = ccp(0.0,0.5);
 if(iPhoneRuningOnGame()){
 label.position = ccp(winSize.width/2+50/2,55);
 }else{
 label.position = ccp(winSize.width/2+50,textH);
 }
 [layer_list addChild:label z:100 tag:304];
 
 //end
 GameConfigure * config = [GameConfigure shared];
 NSArray * players = [config getPlayerList];
 
 for(int i=0;i<3;i++){
 GameStartRole * gameRole = [GameStartRole node];
 if(i<[players count]){
 //fix chao 更新玩家数据
 NSDictionary *t_dict = [[GameConfigure shared] getPlayerInfo];
 if ([[[players objectAtIndex:i] objectForKey:@"id"] intValue] == [[t_dict objectForKey:@"id"] intValue]) {
 gameRole.info = t_dict;
 }else{
 gameRole.info = [players objectAtIndex:i];
 }
 //gameRole.info = [players objectAtIndex:i];
 //end
 
 }
 [gameRole loadViewer];
 gameRole.target = self;
 gameRole.call = @selector(showPlayerInfo:);
 gameRole.select = NO;
 gameRole.tag = (601+i);
 [layer_list addChild:gameRole];
 
 }
 
 if([players count]>0){
 [self showPlayerInfo:(GameStartRole*)[layer_list getChildByTag:601] move:NO];
 }
 
 }
 */

/*
 -(void)doEnter:(CCMenuItem*)item{
 
 if(selectRole.info){
 
 int pid = [[selectRole.info objectForKey:@"id"] intValue];
 
 if(pid==[GameConfigure shared].playerId){
 [self closeWindow];
 return;
 }
 
 [[GameConnection share] enterPlayer:pid];
 item.isEnabled = NO;
 
 }else{
 //parentCall = @selector(showList);
 [self showCreate];
 }
 }
 */
/*
 static NSString * rolePoint[] = {
 @"{0,-60}",
 @"{320,10}",
 @"{-320,10}",
 };
 */
/*
 -(void)showPlayerInfo:(GameStartRole*)role move:(BOOL)move{
 if(selectRole==role) return;
 if(selectRole) selectRole.select = NO;
 
 selectRole = role;
 selectRole.select = YES;
 
 int index = selectRole.tag;
 for(int i=0;i<3;i++){
 GameStartRole * node = (GameStartRole*)[layer_list getChildByTag:index];
 
 CGPoint p = CGPointFromString(rolePoint[i]);
 if(iPhoneRuningOnGame()){
 node.scale=0.7f;
 p.x /= 2;
 p.y /= 2;
 }
 
 [node moveTo:p isMove:move];
 index++;
 if(index>603) index = 601;
 }
 
 //TODO show player text info
 //fix chao
 CCLabelFX * label1 = (CCLabelFX*)[layer_list getChildByTag:300];
 CCLabelFX * label2 = (CCLabelFX*)[layer_list getChildByTag:301];
 //CCLabelFX * label3 = (CCLabelFX*)[layer_list getChildByTag:302];
 //CCLabelFX * label4 = (CCLabelFX*)[layer_list getChildByTag:303];
 CCLabelFX * label5 = (CCLabelFX*)[layer_list getChildByTag:304];
 //CCLabelFX * label6 = (CCLabelFX*)[layer_list getChildByTag:305];
 CCLabelFX * label7 = (CCLabelFX*)[layer_list getChildByTag:306];
 
 if(role.info){
 [label1 setString:[role.info objectForKey:@"name"]];
 
 
 int rid = [[role.info objectForKey:@"rid"] intValue];
 NSDictionary *dict =  [[GameDB shared] getRoleInfo:rid];
 //int sk = [[dict objectForKey:@"sk2"] intValue];
 //NSDictionary *sDict = [[GameDB shared] getSkillInfo:sk];
 //fix chao
 int level = [[role.info objectForKey:@"level"] intValue];
 //end
 
 if (level > 99) {
 level = 99 ;
 }
 [label2 setString:[NSString stringWithFormat:@"等级 : %@",[NSString stringWithFormat:@"%d",level]]];
 //[label3 setString:[NSString stringWithFormat:@"种族 : %@",@"XXX"]];
 //[label4 setString:[NSString stringWithFormat:@"战力 : %d",getBattlePower([[GameConfigure shared] getRoleAttribute:rid])]];
 
 [label5 setString:[NSString stringWithFormat:@"职阶 : %@",[dict objectForKey:@"job"]]];
 //[label6 setString:[NSString stringWithFormat:@"技能 : %@",[sDict objectForKey:@"name"]]];
 [label7 setString:[NSString stringWithFormat:@"位阶 : %@",[dict objectForKey:@"office"]]];
 
 }else{
 [label1 setString:@""];
 [label2 setString:@""];
 //[label3 setString:@""];
 //[label4 setString:@""];
 [label5 setString:@""];
 //[label6 setString:@""];
 [label7 setString:@""];
 }
 //end
 
 }
 */
/*
 -(void)showPlayerInfo:(GameStartRole*)role{
 [self showPlayerInfo:role move:YES];
 }
 */
//fix chao 去掉

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	//touchDis=[touch locationInView:touch.view].x;
	/*
	 if (CGRectContainsPoint(CGRectMake(note_bg.position.x, note_bg.position.y, note_bg.contentSize.width, note_bg.contentSize.height), getGLpoint(touch)))
	 {
	 dropNote_bg=true;
	 }
	 */
	if(nameInput){
		[self editRoleNameEnd:nameInput];
	}
	return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	//CCLOG(@"%@",touch);
	/*
	 if(dropNote_bg){
	 CGPoint point=getGLpoint(touch);
	 if(point.y+note_bg.contentSize.height>self.contentSize.height){
	 return;
	 }
	 [note_bg setPosition:ccp(0, point.y)];
	 }
	 */
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	/*
	 touchDis-=[touch locationInView:touch.view].x;
	 if(abs(touchDis)>200){
	 if(touchDis>0){
	 currenRoleIndex+=1;
	 currenRoleIndex=currenRoleIndex>2?0:currenRoleIndex;
	 }
	 if(touchDis<0){
	 currenRoleIndex-=1;
	 currenRoleIndex=currenRoleIndex<0?2:currenRoleIndex;
	 }
	 GameStartRole * node = (GameStartRole*)[layer_list getChildByTag:601+currenRoleIndex];
	 [self showPlayerInfo:node move:YES];
	 }
	 */
	
}

//end

@end

@implementation GameStartRole
@synthesize info;
@synthesize select;
@synthesize target, call;

-(void)moveTo:(CGPoint)tp isMove:(BOOL)isMove{
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	tp = ccpAdd(ccp(winSize.width/2,winSize.height/2), tp);
	if(isMove){
		
		CGPoint pt = self.position;
		
		id action;
		if(self.position.y==tp.y){
			
			if(iPhoneRuningOnGame()){
				action = [CCJumpTo actionWithDuration:0.5 position:tp height:25 jumps:1];
			}else{
				action = [CCJumpTo actionWithDuration:0.5 position:tp height:50 jumps:1];
			}
			
		}else{
			if (tp.x == winSize.width/2) {
				//向中间
				action = [CCJumpTo actionWithDuration:0.5 position:tp height:-abs(self.position.y-tp.y)/2 jumps:1];
				id act2 = [CCScaleTo actionWithDuration:0.5 scale:1];
				CCNode *_obj = [self getChildByTag:503];
				if (_obj) {
					[_obj runAction:act2];
				}
			}
			else {
				if (pt.x == winSize.width/2) {
					action = [CCJumpTo actionWithDuration:0.5 position:tp height:-abs(self.position.y-tp.y)/2 jumps:1];
					id act2 = [CCScaleTo actionWithDuration:0.5 scale:0.5];
					
					CCNode *_obj = [self getChildByTag:503];
					if (_obj) {
						[_obj runAction:act2];
					}
				}
				else {
					action = [CCJumpTo actionWithDuration:0.5 position:tp height:-abs(self.position.y-tp.y)/2 jumps:1];
				}
			}
		}
		
		[self runAction:action];
	}else{
		self.position = tp;
		if (tp.x != winSize.width/2) {
			CCNode *_obj = [self getChildByTag:503];
			if (_obj) {
				_obj.scale = 0.5;
			}
			//fix chao
			//end
		}
	}
}

-(void)dealloc{
	if(info){
		[info release];
		info = nil;
	}
	
	[super dealloc];
	
}

-(void)setInfo:(NSDictionary *)_info{
	info = _info;
	[info retain];
}

-(void)loadViewer{
	
	CCSprite * fire1 = [CCSprite spriteWithFile:@"images/start/list/bg-fire-1.png"];
	if(iPhoneRuningOnGame()){
		fire1.position = ccp(0,30/2);
	}else{
		fire1.position = ccp(0,30);
	}
	[self addChild:fire1 z:1 tag:501];
	
	CCSprite * fire2 = [CCSprite spriteWithFile:@"images/start/list/bg-fire-2.png"];
	if(iPhoneRuningOnGame()){
		fire2.position = ccp(0,15/2);
	}else{
		fire2.position = ccp(0,15);
	}
	[self addChild:fire2 z:1 tag:502];
	
	if(info){
		
		//TODO show role view
		int _rid = [[info objectForKey:@"rid"] intValue];
		if (_rid > 0 ) {
			
			NSString *path = [NSString stringWithFormat:@"images/start/role/player_sbig_%d.png",_rid];
			CCSprite * role = [CCSprite spriteWithFile:path];
			if (role) {
				role.anchorPoint = ccp(0.5,0);
				if(iPhoneRuningOnGame()){
					role.position=ccp(0, -50/2);
				}else{
					role.position=ccp(0, -50);
				}
				[self addChild:role z:100 tag:503];
			}
			else {
				CCLOG(@"texture is null!");
			}
		}
		else {
			CCLOG(@"error rid loadViewer!");
		}
	}
	//fix chao
	else{
		CCSprite *role = [CCSprite spriteWithFile:@"images/start/list/bg-fire-3.png"];
		if (role) {
			role.anchorPoint = ccp(0.5,0);
			if(iPhoneRuningOnGame()){
				role.position=ccp(0, -50/2);
			}else{
				role.position=ccp(0, -50);
			}
			[self addChild:role z:100 tag:503];
		}
	}
	//end
	
}

-(void)setSelect:(BOOL)isSelect{
	if(isSelect){
		[self getChildByTag:501].visible = YES;
		[self getChildByTag:502].visible = NO;
	}else{
		[self getChildByTag:501].visible = NO;
		[self getChildByTag:502].visible = YES;
	}
}

-(void)onEnter{
	[super onEnter];
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-200 swallowsTouches:YES];
	[self schedule:@selector(checkTimer:) interval:10.f/30];
	//touchDis=-9999;
}

-(void)checkTimer:(ccTime)time{
	if(self.parent){
		int zz = (GAME_MAP_MAX_Y-self.position.y);
		[self.parent reorderChild:self z:zz];
	}
}

-(void)onExit{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}

-(BOOL)isTouchInSite:(UITouch*)touch{
	
	CGSize size = CGSizeMake(200, 400);
	
	if(iPhoneRuningOnGame()){
		size.width /= 2;
		size.height /= 2;
	}
	
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	if(p.x<-size.width/2) return NO;
	if(p.x>size.width/2) return NO;
	
	if(iPhoneRuningOnGame()){
		if(p.y<-25) return NO;
	}else{
		if(p.y<-50) return NO;
	}
	
	if(p.y>size.height) return NO;
	return YES;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	bool isTouch=[self isTouchInSite:touch];
	if (isTouch) {
		//touchDis=[self convertTouchToNodeSpaceAR:touch].x;
		return YES;
	}else{
		return NO;
	}
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if([self isTouchInSite:touch]){
		if(target!=nil && call!=nil){
			[target performSelector:call withObject:self];
		}
	}
	
	/*
	 if(touchDis!=-9999){
	 if([self convertTouchToNodeSpaceAR:touch].x>0){
	 CCLOG(@"向右");
	 [target performSelector:call withObject:self];
	 }
	 if([self convertTouchToNodeSpaceAR:touch].x<0){
	 CCLOG(@"向左");
	 [target performSelector:call withObject:self];
	 }
	 //touchDis=[self convertTouchToNodeSpaceAR:touch].x;
	 }
	 */
}

@end
