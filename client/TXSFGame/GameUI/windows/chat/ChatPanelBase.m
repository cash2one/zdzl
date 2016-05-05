//
//  ChatPanelBase.m
//  TXSFGame
//
//  Created by Max on 13-3-19.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ChatPanelBase.h"
#import "ChatPanel.h"
#import "Config.h"
#import "TaskManager.h"
#import "UnionPractice.h"
#import "MessageManager.h"
#import "DragonReadyData.h"
#import "DragonFightData.h"

#pragma mark 监听聊天接收信息类
@implementation ListenChatData

@synthesize chatSavingHistory;
@synthesize baseAr;



static ListenChatData *listenChatData;



+(ListenChatData*)share{
	if(!listenChatData){
		listenChatData=[[ListenChatData alloc]init];
	}
	return listenChatData;
}


-(id)init{
	if((self=[super init])!=nil){
		baseAr=[[NSMutableArray alloc]init];
		chatSavingHistory=[[NSMutableArray alloc]init];
		[GameConnection addPost:ConnPost_ChatPush target:self call:@selector(receiveChat:)];
	}
	return self;
}


-(void)receiveChat:(NSNotification*)data{
	
	/*
	 NSArray *array=data.object;
	 
	 
	 for(NSArray *ar in  array){
	 
	 NSString *name=[NSString stringWithFormat:@"%@",[ar objectAtIndex:2]];
	 NSString *msg=[NSString stringWithFormat:@"%@",[ar objectAtIndex:1]];
	 int channel=[[ar objectAtIndex:0]integerValue];
	 //MessageData *_temp=[[MessageData alloc]initMessage:name content:msg channelId:channel];
	 [chatSavingHistory addObject:_temp];
	 [_temp release];
	 }
	 
	 
	 
	 
	 for(ChatPanelBase *cpb in baseAr){
	 [cpb.chatHistory addObjectsFromArray:array];
	 }
	 //
	 
	 
	 int len = CHAT_ARRAY_LEN;
	 if (iPhoneRuningOnGame()) {
	 len += 10;
	 }
	 if(chatSavingHistory.count>len){
	 NSRange rang;
	 rang.length=chatSavingHistory.count-len;
	 rang.location=0;
	 [chatSavingHistory removeObjectsInRange:rang];
	 }
	 
	 
	 
	 for(NSArray *msgarray in array){
	 
	 //收到大喇叭立即处理
	 if([[msgarray objectAtIndex:0]integerValue]==CHANNEL_TUBA){
	 BOOL compDev=[Game checkUncompatibleDevice];
	 if(!compDev && [FightManager isFighting]){
	 continue;
	 }
	 NSString *msg=[NSString stringWithFormat:@"%@",[msgarray objectAtIndex:1]];
	 
	 [[AlertTuba share] addPost:msg];
	 }
	 }
	 */
	
}


+(void)stop{
	if(listenChatData){
		[listenChatData release];
		listenChatData=nil;
	}
}


-(void)dealloc{
	[baseAr release];
	[chatSavingHistory release];
	
	
    
	[super dealloc];
}


@end


#pragma mark 聊天UI基类

@implementation ChatPanelBase


@synthesize ablWidth;
@synthesize kbHigth;
@synthesize kbBaseHigth;
@synthesize baseHeight;
@synthesize chatHistory;
@synthesize privateTargetName;
@synthesize privateTargetPid;
@synthesize textBox;


static ChatPanelBase *chatPanelBase;
static int privateMsgcount;

+(int)getPrivateMsgcount{
	return privateMsgcount;
}

+(void)setPrivateMsgcount:(int)n{
	privateMsgcount = n;
}

+(ChatPanelBase*)share{
	return chatPanelBase;
}

-(void)onEnter{
	[super onEnter];
	chatHistory=[[NSMutableArray alloc]init];
	
	if(ablWidth==0){
		ablWidth=330;
	}
	if(kbHigth==0){
		kbHigth=400;
	}
	currenChannel = CHANNEL_WORLD;
	currenReadChannel = CHANNEL_ALL;
	chatInterval = 150;
	baseHeight = 95;
	pointEmo = ccp(430, 0);
	
	
	[[MessageManager share]addDispatcherPool:self :@selector(MessageCallBack:)];
	chatcolor=getFormatToDict([[[GameDB shared]getGlobalConfig]objectForKey:@"qcolors"]);
	[chatcolor retain];
    //
	[self regPRAjoin];
	[self regDRAjoin];	// 狩龙邀请
}

-(void)regPRAjoin{
	[GameConnection addPost:@"PRA" target:self call:@selector(listenUnionTeamJoin:)];
}

-(void)regDRAjoin{
	[GameConnection addPost:@"DRA" target:self call:@selector(listenDragonTeamJoin:)];
}

-(void)MessageCallBack:(MessageData*)m{
	[self stopAddHistory];
	[chatHistory addObject:m];
	[self startAddHistroy];
}


-(void)listenUnionTeamJoin:(NSNotification*)nof{
	if(panel.isTouchValid){
		NSArray *var=[[nof object]componentsSeparatedByString:@")"];
        if ([var count]>1) {
            int tid=[[var objectAtIndex:0]intValue];
            int tbid=[[var objectAtIndex:1]intValue];
            [UnionPracticeCreatJoin joinTeam:tid tbid:tbid];
        }else{
            CCLOG(@"union fight data error...");
        }
	}
}

-(void)listenDragonTeamJoin:(NSNotification*)nof{
	if(panel.isTouchValid){
		// 确保没有准备房间和战场的数据
		if (![DragonReadyData checkIsReady] && ![DragonFightData checkIsFight]) {
			int num = [[nof object] intValue];
			if (num > 0) {
				NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:num] forKey:@"rnum"];
				[GameConnection request:@"awarEnterRoom" data:dict target:[DragonReadyData class] call:@selector(beginWithData:)];
			}
		}
	}
}

-(void)showInputTextField{
	[textBox setHidden:YES];
}
-(void)hideInputTextField{
	[textBox setHidden:NO];
}





-(void)loadBrow{
	CCSpriteFrame * frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"face1_1.png"];
	if(!frame){
		NSString *imgpath=[NSString stringWithFormat:@"%@texture.plist",BASEPATH];
		[[CCSpriteFrameCache sharedSpriteFrameCache]addSpriteFramesWithFile:imgpath];
	}
}




#pragma mark 发送聊天
-(void)sendChatEvent:(NSString*)str{
	
	if(chatInterval<5){
		
        [ShowItem showItemAct:NSLocalizedString(@"chat_send_much",nil)];
		return;
	}
	
	if([[GameConfigure shared]isPlayerOnChapter]){
		return ;
	}
	
	NSString *format = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
	if([format length]==0){
		return;
	}
	
	if([str length]==0){
		CCLOG(@"message == '' ");
		return;
	}
	
	chatInterval=0;
	
#ifdef COCOS2D_DEBUG
#if COCOS2D_DEBUG == 1
	if (str != nil && str.length > 0) {
		NSString* _inputStr = [str lowercaseString];
		if ([_inputStr hasPrefix:@"gmc:"]) {
			NSString* cmd = [str substringFromIndex:4];
			NSArray* ary = [cmd componentsSeparatedByString:@":"];
			
			if (ary != nil && ary.count >= 2) {
				
				NSString* _handle = [ary objectAtIndex:0];
				NSString* _value = [ary objectAtIndex:1];
				if ([@"fid" isEqualToString:_handle]) {
					int fid = [_value intValue];
					[[FightManager shared]startFightById:fid target:nil call:nil];
					[textBox resignFirstResponder];
					return;
				}
				
				if ([@"task" isEqualToString:_handle]) {
					int st = [_value intValue];
					[TaskManager taskManagerRobot:(st == 1)];
					[textBox resignFirstResponder];
					return;
				}
				
				if ([@"team" isEqualToString:_handle]) {
					
					[[FightManager shared] startFightById:[[ary objectAtIndex:1] intValue]
													 team:[[ary objectAtIndex:2] intValue]
												   target:nil
													 call:nil
													 sele:nil];
					
					return;
				}
				
				if ([@"teams" isEqualToString:_handle]) {
					[[FightManager shared] startFightTeam:1000001
												   byTeam:1000002
												   target:nil
													 call:nil
													 sele:nil];
					return;
				}
				
			}
		}
	}
	
#endif
#endif
	/*
	 if([str length]>5){
	 NSString *head=[str substringToIndex:4];
	 if([head isEqualToString:@"GMC:"]){
	 NSString *cmd=[NSString stringWithFormat:@"cmd:%@",[str substringFromIndex:4]];
	 [GameConnection request:@"gm" format:cmd target:self call:@selector(receiveGmRS:)];
	 return;
	 }
	 }
	 */
	
	if([str length]>150){
		str=[str substringToIndex:150];
	}
	
	str=[str stringByReplacingOccurrencesOfString:@"|" withString:@""];
	str=[str stringByReplacingOccurrencesOfString:@"*" withString:@""];
	str=[str stringByReplacingOccurrencesOfString:@"#" withString:@""];
	str=[str stringByReplacingOccurrencesOfString:@":" withString:@""];
	
	NSString *reqstr=[NSString stringWithFormat:@"t::%i|m:%@",currenChannel,str];
	if(currenChannel==CHANNEL_PRIVATE && [privateTargetName length]<1){
		[ShowItem showErrorAct:@"-1"];
		return;
	}
	if(currenChannel==CHANNEL_UNION && [[[[GameConfigure shared]getPlayerAlly]objectForKey:@"n"] length]<1){
		[ShowItem showErrorAct:@"-2"];
		return;
	}
	if(currenChannel==CHANNEL_TUBA){
		BOOL hasTuba=false;
		NSArray *itemdata=[[GameConfigure shared]getPlayerItemByType:Item_material];
		for(NSDictionary *data in itemdata){
			if([[data objectForKey:@"iid"]integerValue]==10002){
				hasTuba=true;
			}
		}
		if(!hasTuba){
			[ShowItem showErrorAct:@"-3"];
			return;
		}
	}
	
	if([privateTargetName length]>0){
		
		//TODO
		
		int fontsize=16;
		if(iPhoneRuningOnGame()){
			fontsize=20;
		}
		
		
		str=[str substringFromIndex:[privateTargetName length]];
		
		if(privateTargetPid!=0){
			reqstr=[NSString stringWithFormat:@"t::5|m:%@|id::%i",str ,privateTargetPid];
		} else {
			reqstr=[NSString stringWithFormat:@"t::5|m:%@|name:%@",str ,privateTargetName];
		}
		NSString *msg=str;
		
		
		textBox.text=[NSString stringWithFormat:@"%@:",privateTargetName];
		str =[NSString stringWithFormat:NSLocalizedString(@"chat_send_private_msgformat", nil),privateTargetName,fontsize,privateTargetName];
		str =[NSString stringWithFormat:@"%@:%@#ff63e0",str,msg];
		NSArray *c=[NSArray arrayWithObjects:[NSNumber numberWithInt:5],str,privateTargetName,nil];
		NSArray *cc=[NSArray arrayWithObjects:c, nil];
		NSNotification *nof=[NSNotification notificationWithName:@"chatMsg" object:cc];
		[[MessageManager share] receive:nof];
		[GameConnection request:@"chatSend" format:reqstr target:self call:@selector(didSendChat:)];
	}else{
		textBox.text=@"";
		[GameConnection request:@"chatSend" format:reqstr target:self call:@selector(didSendChat:)];
	}
	
}

+(void)sendInviteUnionTeam:(NSString*)content{
	content=[NSString stringWithFormat:@"t::4|m:%@",content];
	[GameConnection request:@"chatSend" format:content target:[chatPanelBase class] call:@selector(didSendChat:)];
}


+(void)didsendInviteUnionTeam:(NSDictionary*)n{
	CCLOG(@"%@",n);
}

#pragma mark 将语句加入聊天框
-(void)AddChatContent:(NSString*)str color:(NSString*)_color{
	[self loadBrow];
	CCSprite *line=nil;
	float fontSize=16;
	float lineHeight=22;
	float rectHeight=30;
	if (iPhoneRuningOnGame()) {
		fontSize=20;
		lineHeight=25;
		rectHeight=30;
	}
    int w_ = ablWidth;
    if (iPhoneRuningOnGame()) {
        w_ += w_;
    }
	line=drawString(str, CGSizeMake(w_,rectHeight), getCommonFontName(FONT_1),fontSize,lineHeight, _color);
	
	[line setAnchorPoint:ccp(0, 0)];
    if (iPhoneRuningOnGame()) {
        [line setPosition:ccp(0,0)];
    }else{
        [line setPosition:ccp(0,0)];
    }
	int lasthight=line.contentSize.height;
	
	for(CCSprite *sprite in content.children){
		[sprite setPosition:ccp(0, sprite.position.y+line.contentSize.height)];
		lasthight+=sprite.contentSize.height;
	}
	for(CCSprite *sprite in content.children){
		if(sprite.position.y>512){
			[sprite removeFromParentAndCleanup:true];
		}
	}
	[content addChild:line];
	
	lasthight = lasthight < baseHeight?baseHeight:lasthight;
	[content setContentSize:CGSizeMake(ablWidth,lasthight)];
	
}


-(void)AddChatContent:(NSString*)str  {
	[self AddChatContent:str color:@"ffffff"];
}


-(void)addAllHistroy {
	[self stopAddHistory];
	[chatHistory addObjectsFromArray:[[MessageManager share]messageList]];
	int recodeCount=[chatHistory count];
	for(int i=0;i<recodeCount;i++){
		[self addHistroy];
	}
	[self startAddHistroy];
}

-(void)addNewHistroy{
	[self stopAddHistory];
	int recodeCount=[chatHistory count];
	for(int i=0;i<recodeCount;i++){
		[self addHistroy];
	}
	[self startAddHistroy];
}


-(void)addHistroy{
	chatInterval++;
	if(isChatOpen && chatHistory.count>0){

		MessageData *chatmsg=[chatHistory objectAtIndex:0];
		//NSString *name=[chatmsg name];
		NSString *msg=[chatmsg content];
		int channel=[chatmsg channelId];
		
		int fontsize=16;
		if (iPhoneRuningOnGame()) {
			fontsize=20;
		}
		if(currenReadChannel == CHANNEL_ALL || channel == currenReadChannel){
			if(channel == CHANNEL_PRIVATE){
				privateMsgcount++;
			}
			[self AddChatContent:msg];
			/*
			 switch (channel) {
			 case CHANNEL_WORLD:{
			 //[self AddChatContent:[NSString stringWithFormat:@"[世界]#%@#%i#0|%@ : #%@#%i#0|%@",chatW,fontsize,name,chatW,fontsize,msg]];
			 
			 [self AddChatContent:[NSString stringWithFormat:@"[%@]#%@#%i#0|%@#%@#%i#0#PER%@| : |%@#%@",NSLocalizedString(@"chat_send_world",nil),chatW,fontsize,name,nameC,fontsize,name,msg,chatW]];
			 
			 [self AddChatContent:msg];
			 }
			 break;
			 case CHANNEL_SYSTEM:{
			 [self AddChatContent:[NSString stringWithFormat:@"[%@]#fffc00#%i#0|%@",NSLocalizedString(@"chat_send_system",nil),fontsize,msg]];
			 }
			 break;
			 case CHANNEL_TUBA:{
			 //	CCLOG(@"%i ,%@",[name length],chatH);
			 if([name length]>1){
			 //桂思凯 :#38d3ff| Helloa adfadfkadfkafda$$d
			 //[self AddChatContent:[NSString stringWithFormat:@"[喇叭]#%@#%i#0|%@",chatP,fontsize,msg] color:chatP];
			 [self AddChatContent:[NSString stringWithFormat:@"[%@]#%@#%i#0|%@",NSLocalizedString(@"chat_send_reproducer",nil),chatP,fontsize,msg] color:chatP];
			 }else{
			 [self AddChatContent:[NSString stringWithFormat:@"[%@]#%@#%i#0|%@",NSLocalizedString(@"chat_send_reproducer",nil),chatH,fontsize,msg] color:chatH];
			 }
			 }
			 break;
			 case CHANNEL_UNION:{
			 if([name length]>1){
			 //[self AddChatContent:[NSString stringWithFormat:@"[工会]#%@#%i#0|%@ : #%@#%i#0|%@#%@",chatA,fontsize,name,chatA,fontsize,msg,chatA]];
			 //                        [self AddChatContent:[NSString stringWithFormat:@"[%@]#%@#%i#0|%@ : #%@#%i#0|%@#%@",NSLocalizedString(@"chat_send_union",nil),chatA,fontsize,name,chatA,fontsize,msg,chatA]];
			 [self AddChatContent:[NSString stringWithFormat:@"[%@]#%@#%i#0|%@ : #%@#%i#0|%@",NSLocalizedString(@"chat_send_union",nil),chatA,fontsize,name,chatA,fontsize,msg]];
			 }else{
			 //[self AddChatContent:[NSString stringWithFormat:@"[工会]#%@#%i#0|%@#%@",chatA,fontsize,msg,chatA]];
			 [self AddChatContent:[NSString stringWithFormat:@"[%@]#%@#%i#0|%@#%@",NSLocalizedString(@"chat_send_union",nil),chatA,fontsize,msg,chatA]];
			 }
			 }
			 break;
			 case CHANNEL_PRIVATE:{
			 //[self AddChatContent:[NSString stringWithFormat:@"[密]#%@#%i#0|%@ : #%@#%i#0|%@#%@#%i#0",chatT,fontsize,name,chatT,fontsize,msg,chatT,fontsize]];
			 NSString *pname = [NSString stringWithFormat:NSLocalizedString(@"chat_send_private_msgformat",nil),name,fontsize,name];
			 
			 
			 [self AddChatContent:[NSString stringWithFormat:@"[%@]#%@#%i#0|%@ : #%@#%i#0|%@#%@#%i#0",NSLocalizedString(@"chat_send_private",nil),chatT,fontsize,pname,chatT,fontsize,msg,chatT,fontsize]];
			 }
			 break;
			 
			 default:
			 break;
			 }
			 */
		}
		[chatHistory removeObjectAtIndex:0];
	}
}


#pragma mark 发送聊天返回
-(void)didSendChat:(NSDictionary*)data{
	if(checkResponseStatus(data)){
		
	}else{
		[ShowItem showErrorAct:getResponseMessage(data)];
	}
}

#pragma mark 打开表情面板
-(void)openEmo{
	[self loadBrow];
	[chatLayer removeChildByTag:BG_EMO cleanup:true];
	NSString *imgpath=[NSString stringWithFormat:@"%@emobg.png",BASEPATH];
	
	CCSprite * emobg=nil;
    float iphoneScale = 0.85f;
	if(iPhoneRuningOnGame()){
		emobg= [StretchingImg stretchingImg:imgpath width:250*iphoneScale*2 height:250*iphoneScale/2 capx:5 capy:5];
	}else{
		emobg= [StretchingImg stretchingImg:imgpath width:250 height:250 capx:5 capy:5];
	}
	
	[emobg setAnchorPoint:ccp(0, 0)];
	imgpath=[NSString stringWithFormat:@"%@texture.plist",BASEPATH];
	[[CCSpriteFrameCache sharedSpriteFrameCache]addSpriteFramesWithFile:imgpath];
	int index=1;
    int x_ = 6;
    int y_ = 6;
    if (iPhoneRuningOnGame()) {
        x_ = 12;
        y_ = 3;
    }
	for(int i=0;i<x_;i++){
		for (int iy=0; iy<y_; iy++) {
			CCSimpleButton *face=[CCSimpleButton spriteWithSpriteFrameName:[NSString stringWithFormat:@"face%i_1.png",index]];
            face.priority = -1000;
			if(iPhoneRuningOnGame()){
                face.scale = 2.0f;
				[face setPosition:ccp(i*40*iphoneScale+20*iphoneScale, iy*40*iphoneScale+20*iphoneScale)];
			}else{
				[face setPosition:ccp(i*40+20, iy*40+20)];
			}
			[face setTarget:self];
			[face setCall:@selector(eventEMOCallBack:)];
			[emobg addChild:face z:1 tag:BTN_EMOBASE+index];
			index++;
		}
	}
	if(iPhoneRuningOnGame()){
		[emobg setPosition:ccp(pointEmo.x/2-emobg.contentSize.width/2-20,pointEmo.y/2+10)];
	}else{
		[emobg setPosition:ccp(pointEmo.x, pointEmo.y)];
	}
	[chatLayer addChild:emobg z:INT32_MAX tag:BG_EMO];
}

#pragma mark 表情按钮回调
-(void)eventEMOCallBack:(id)sender{
	CCSimpleButton *b=(CCSimpleButton*)sender;
	CCLOG(@"text tc:%@",textBox);
	if([textBox.text  length]>0){
		textBox.text=[NSString stringWithFormat:@"%@%@",textBox.text,[NSString stringWithFormat:@"{!%02i}",b.tag-BTN_EMOBASE]];
	}else{
		textBox.text=[NSString stringWithFormat:@"%@",[NSString stringWithFormat:@"{!%02i}",b.tag-BTN_EMOBASE]];
	}
	
	[chatLayer removeChildByTag:BG_EMO cleanup:true];
	[chatLayer removeChildByTag:TYPETIPS cleanup:true];
}

#pragma mark 按钮回调事件
-(void)buttonCallBack:(id)sender{
	CCNode *node=(CCNode*)sender;
	
	switch (node.tag) {
		case BTN_CHATENTER:{
			[self sendChatEvent:textBox.text];
		}
			break;
		case BTN_CHATCHANNEL:{
			
			CCNode *nodebg=chatLayer;
			CCSimpleButton *tb=sender;
			if([chatLayer getChildByTag:BG_CHATCHANNEL]){
				[[chatLayer getChildByTag:BG_CHATCHANNEL] removeFromParentAndCleanup:true];
				return;
			}
			
			
			if(![chatLayer getChildByTag:BG_CHATCHANNEL]){
				CCSprite *channelbg=[CCSprite spriteWithFile:[NSString stringWithFormat:@"%@channelbg.png",BASEPATH]];
				[channelbg setAnchorPoint:ccp(0.5, 0)];
				
				if(iPhoneRuningOnGame()){
                    channelbg.scaleX = 2.0f;
					[channelbg setPosition:ccp(tb.position.x, tb.position.y+20)];
				}else{
					[channelbg setPosition:ccp(tb.position.x, tb.position.y+20)];
				}
				
				[channelbg setTag:BG_CHATCHANNEL];
				[nodebg addChild:channelbg];
				
				int Channelar[4]={CHANNEL_WORLD,CHANNEL_TUBA,CHANNEL_UNION,CHANNEL_PRIVATE};
				
				for (int i=0; i<4; i++) {
					NSString *imgpath=[NSString stringWithFormat:@"%@btn_channel_s%i.png",BASEPATH,Channelar[i]];
					if(currenChannel==Channelar[i]){
						imgpath=[NSString stringWithFormat:@"%@btn_channel_ss%i.png",BASEPATH,Channelar[i]];
					}
					CCSimpleButton *b=[CCSimpleButton spriteWithFile:imgpath];
					[b setTarget:self];
					[b setCall:@selector(buttonChannelCallBack:)];
					
					if(iPhoneRuningOnGame()){
                        b.scaleX = 1.2f;
                        b.scaleY = 1.5f;
						[b setPosition:ccp(channelbg.contentSize.width/2, channelbg.contentSize.height-i*25-20)];
					}else{
						[b setPosition:ccp(channelbg.contentSize.width/2, channelbg.contentSize.height-i*50-40)];
					}
					[channelbg addChild:b z:100 tag:BTN_CHATCHANNELBASE+Channelar[i]];
				}
				
			}
			
		}
			break;
		case BTN_CHATEMO:{
			if ([chatLayer getChildByTag:BG_EMO]) {//如果已经打开就关闭
				[chatLayer removeChildByTag:BG_EMO cleanup:true];
				[chatLayer removeChildByTag:TYPETIPS cleanup:true];
			}else{//否则就打开
				[self openEmo];
			}
		}
			break;
		case BTN_BIGCHAT:{
			[[Window shared]showWindow:PANEL_CHAT_BIG];
		}
		default:
			break;
	}
}




#pragma mark 频道回调事件
-(void)buttonChannelCallBack:(id)sender{
	CCSimpleButton *b=(CCSimpleButton*)sender;
	currenChannel=b.tag-BTN_CHATCHANNELBASE;
	if(currenChannel!=CHANNEL_PRIVATE){
		privateTargetName=@"";
		privateTargetPid=0;
		textBox.text=@"";
	}
	NSNumber *num=[NSNumber numberWithInt:currenChannel];
	[GameConnection post:ConnPost_updateChannel object:num];
	[chatLayer removeChildByTag:BG_CHATCHANNEL cleanup:true];
	CCNode *btn=[chatLayer getChildByTag:BTN_CHATCHANNEL];
	[btn removeChildByTag:TITLE_CHATCHANNEL cleanup:true];
	CCSprite *title=[CCSprite spriteWithFile:[NSString stringWithFormat:@"%@btn_channel_%i.png",BASEPATH,currenChannel]];
    if (iPhoneRuningOnGame()) {
        title.scale = 1.3f;
    }
	addTargetToCenter(title, btn, TITLE_CHATCHANNEL);
}

#pragma mark 监测物理键盘是否打开
-(void)keyBoardIsOpen{
	bool open=true;
	UIWindow* tempWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:1];
    UIView* keyboard;
    for(int i=0; i<[tempWindow.subviews count]; i++) {
        keyboard = [tempWindow.subviews objectAtIndex:i];
		CCLOG(@"%@",keyboard);
        if(([[keyboard description] hasPrefix:@"<UIPeripheralHostView"] == YES)){
			if([[keyboard description] rangeOfString:@"CABasicAnimation"].length<=0){
				open=false;
				[chatLayer removeChildByTag:TYPETIPS cleanup:true];
			}
		}
		
    }
	if(open){
		keyBoradOpen=YES;
		CCMoveTo * move = [CCMoveBy actionWithDuration:0.15 position:ccp(0, cFixedScale(self.kbHigth))];
		CCCallBlock * call = [CCCallBlock actionWithBlock:^(void){
			CGRect rect=textBox.frame;
			[textBox setFrame:CGRectMake(rect.origin.x, kbBaseHigth-cFixedScale(kbHigth), rect.size.width, rect.size.height)];
			[chatLayer removeChildByTag:TYPETIPS cleanup:true];
		}];
		[self runAction:[CCSequence actions:move, call, nil]];
	}
}



#pragma mark 键盘托管事件
- (void)textFieldDidBeginEditing:(UITextField *)textField{
	[self performSelector:@selector(keyBoardIsOpen) withObject:nil afterDelay:0.1];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
	if(isEmo(string)){
		return NO;
	}
	if([privateTargetName length]>1){
		NSString * textString = [textField.text stringByReplacingCharactersInRange:range withString:string];
		NSRange name_range = [textString rangeOfString:[NSString stringWithFormat:@"%@:",privateTargetName]];
		if(name_range.location==0 && name_range.length==[privateTargetName length]+1){
			return YES;
		}else{
			return NO;
		}
	}
	
	/*
	 if([privateTargetName length]>1 && [textString length]+[string length]<([privateTargetName length]+2)){
	 return NO;
	 }else{
	 return YES;
	 }
	 */
	
	return YES;
}


-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
	if([[GameConfigure shared]isPlayerOnChapter]){
		return NO;
	}
	return YES;
}

// became first responder
//-(BOOL)textFieldShouldEndEditing:(UITextField *)textField{
//
//
//}

- (void)textFieldDidEndEditing:(UITextField *)textField{
	if(isChatOpen){
		//[textBox setHidden:YES];
		CCMoveTo * move = [CCMoveBy actionWithDuration:0.05 position:ccp(0, cFixedScale(-self.kbHigth))];
		CCCallBlock * call = [CCCallBlock actionWithBlock:^(void){
			if(keyBoradOpen){
				keyBoradOpen=false;
				CGRect rect = textBox.frame;
				[textBox setFrame:CGRectMake(rect.origin.x, kbBaseHigth,rect.size.width, rect.size.height)];
			}
		}];
		[self runAction:[CCSequence actions:move, call, nil]];
	}
}
-(void)loadTextBox{
	if(textBox==nil){
		textBox = [[UITextField alloc]init];
	}
}

-(void)closeTextBox{
	[textBox setHidden:YES];
	[textBox setEnabled:NO];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
	[self sendChatEvent:textField.text];
	if(iPhoneRuningOnGame()){
		[textBox resignFirstResponder];
	}
	return YES;
}





-(void)removeTipsChangeButton{
	CCNode *btn=[chatLayer getChildByTag:BTN_CHATCHANNEL];
	[btn removeChildByTag:TITLE_CHATCHANNEL];
	[chatLayer removeChildByTag:TYPETIPS];
	currenChannel=CHANNEL_PRIVATE;
	CCSprite *title=[CCSprite spriteWithFile:[NSString stringWithFormat:@"%@btn_channel_%i.png",BASEPATH,currenChannel]];
	addTargetToCenter(title, btn, TITLE_CHATCHANNEL);
}

#pragma mark 接收外部调用的私聊方法
+(void)sendPrivateChannle:(NSString*)targetName pid:(int)_pid{
	if(iPhoneRuningOnGame()){
		if(![ChatPanel getChatPanel]){
			[[Window shared]showWindow:PANEL_CHAT];
		}
		[ChatPanel getChatPanel].privateTargetName=targetName;
		[ChatPanel getChatPanel].privateTargetPid=_pid;
		[[ChatPanel getChatPanel].textBox setText:[NSString stringWithFormat:@"%@:",targetName]];
		[[ChatPanel getChatPanel] removeTipsChangeButton];
		NSNumber *num=[NSNumber numberWithInt:CHANNEL_PRIVATE];
		[GameConnection post:ConnPost_updateChannel object:num];
	}else{
		if([ChatPanel getChatPanel]){
			[ChatPanel getChatPanel].privateTargetName=targetName;
			[ChatPanel getChatPanel].privateTargetPid=_pid;
			[[ChatPanel getChatPanel].textBox setText:[NSString stringWithFormat:@"%@:",targetName]];
			[[ChatPanel getChatPanel] removeTipsChangeButton];
			NSNumber *num=[NSNumber numberWithInt:CHANNEL_PRIVATE];
			[GameConnection post:ConnPost_updateChannel object:num];
			
		}else{
			[[LowerLeftChat share]EventOpenChat:nil];
			[LowerLeftChat share].privateTargetPid=_pid;
			[LowerLeftChat share].privateTargetName=targetName;
			[[LowerLeftChat share].textBox setText:[NSString stringWithFormat:@"%@:",targetName]];
			[[LowerLeftChat share] removeTipsChangeButton];
		}
	}
}

-(void)startAddHistroy{
	[self schedule:@selector(addHistroy) interval:0.1];
}

-(void)stopAddHistory{
	[self unschedule:@selector(addHistroy)];
}

-(void)onExit{
	
	[self stopAddHistory];
	[textBox removeFromSuperview];
	[chatHistory release];
	[chatcolor release];
	
	[[MessageManager share]removeDispatcherPool:self];
	
    [GameConnection freeRequest:self];
	[GameConnection removePostTarget:self];
	
	[super onExit];
	
}

-(void)dealloc{
	if(textBox){
		[textBox release];
		textBox = nil;
	}
	[super dealloc];
}
@end
