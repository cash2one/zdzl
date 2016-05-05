//
//  ChatPanel.m
//  TXSFGame
//
//  Created by Max on 13-3-19.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ChatPanel.h"
#import "StretchingImg.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "LowerLeftChat.h"
#import "SocialHelper.h"
#import "SocialityManager.h"
#import "MessageManager.h"
#import "SocialityPanel.h"


#define CHATPANEL 1


#define BTN_TAG1 100
#define BTN_TAG2 101
#define BTN_TAG3 102
#define BTN_TAG4 103
#define BTN_TAG5 104

#define SNSMG 1003
#define SNSPANEL 1004
#define BTN_FRIEND 1005
#define PERPANEL 1006
#define CHAT_PANEL_BASE_H (45)

@implementation ChatPanel


static ChatPanel *chatPanel;

+(ChatPanel*)getChatPanel{
	if(chatPanel){
		return chatPanel;
	}else{
		return nil;
	}
}


-(void)creatChatPanel{
	CGSize size=self.contentSize;
	int base_h = CHAT_PANEL_BASE_H;
    if (iPhoneRuningOnGame()) {
        base_h += 20;
    }
	CCSprite *psize = [CCSprite spriteWithFile:@"images/ui/panel/p5.png"];
	
	chatLayer=[CCSprite node];
	
	[chatLayer setContentSize:psize.contentSize];
	
	//CCLOG(@"%f %f",chatLayer.contentSize.width,chatLayer.contentSize.height);
	CCSprite *bgblack=[StretchingImg stretchingImg:@"images/ui/bound.png" width:chatLayer.contentSize.width-40 height:chatLayer.contentSize.height-90 capx:8 capy:8];
	
	CCSprite *typebound = nil;
    if (iPhoneRuningOnGame()) {
        typebound = [CCSprite spriteWithFile:@"images/ui/wback/chatBigInput_bg.png"];
    }else{
        typebound = [CCSprite spriteWithFile:@"images/ui/chat/typeboundbig.png"];
    }
	CCSprite *btn_channel_title=[CCSprite spriteWithFile:@"images/ui/chat/btn_channel_1.png"];
	//CCSimpleButton *btn_close=[CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"];
	
	CCSimpleButton *btn_channel=[CCSimpleButton spriteWithFile:@"images/ui/chat/btn_channel.png"];
	CCSimpleButton *btn_enter=[CCSimpleButton spriteWithFile:@"images/ui/chat/btn_enter.png"];
	CCSimpleButton *btn_emo=[CCSimpleButton spriteWithFile:@"images/ui/chat/btn_openemo.png"];
	
	//CCLabelTTF *typetips=[CCLabelTTF labelWithString:@"请输入文字" fontName:getCommonFontName(FONT_1) fontSize:16];
    CCLabelTTF *typetips=[CCLabelTTF labelWithString:NSLocalizedString(@"chat_input_text",nil) fontName:getCommonFontName(FONT_1) fontSize:16];
	CCSimpleButton *btn_openfriend=[CCSimpleButton spriteWithFile:@"images/ui/chat/btn_openfriend.png"];
    
	CCSimpleButton *btn_openfriend_cli=[CCSimpleButton spriteWithFile:@"images/ui/chat/cri.png"];
    btn_openfriend_cli.scaleX = -1;
    btn_openfriend_cli.priority = -999-1;
    //CCSimpleButton *btn_openfriend_cli=[CCSimpleButton spriteWithFile:@"images/ui/button/bt_cri.png"];
    
	//CCSprite *cli=[CCSprite spriteWithFile:@"images/ui/common/common1.png"];
	
	//[cli setPosition:ccp(btn_openfriend_cli.contentSize.width/2, btn_openfriend_cli.contentSize.height/2)];
	
	//[btn_openfriend_cli addChild:cli];
	
	
    if (iPhoneRuningOnGame()) {
        typebound.scaleX = 1.02f;
        typebound.scaleY = 1.3f;
        //btn_close.scale = 1.3f;
        
        btn_channel.scaleX = 1.7f;
        btn_channel.scaleY = 1.7f;
        
        btn_emo.scaleX = 1.6f;
        btn_emo.scaleY = 1.6f;
        
        btn_enter.scaleX = 1.6f;
        btn_enter.scaleY = 1.6f;
    }
	
	self.textBox =[[UITextField alloc]initWithFrame:CGRectMake(185, self.kbBaseHigth, 630, 30)];
	
	//[self.textBox setBackgroundColor:[UIColor whiteColor]];
    [self.textBox setTextColor:[UIColor whiteColor]];
	//[btn_close setTarget:self];
	[btn_channel setTarget:self];
	[btn_enter setTarget:self];
	[btn_emo setTarget:self];
	[btn_openfriend setTarget:self];
	[btn_openfriend_cli setTarget:self];
	
	[btn_enter setCall:@selector(buttonCallBack:)];
	[btn_channel setCall:@selector(buttonCallBack:)];
	//[btn_close setCall:@selector(callBackClose)];
	[btn_emo setCall:@selector(buttonCallBack:)];
	[btn_openfriend setCall:@selector(buttonCallOpenFriend)];
	[btn_openfriend_cli setCall:@selector(buttonCallOpenFriend:)];
	
	
	[chatLayer setPosition:ccp(size.width/2, size.height/2)];
	
	
	UIView *view=[CCDirector sharedDirector].view;
	[self.textBox setDelegate:self];
	[view addSubview:self.textBox];
	content=[CCLayer node];
    //
    if(iPhoneRuningOnGame()){
        panel=[CCPanel panelWithContent:content viewSize:CGSizeMake(self.ablWidth, self.baseHeight)];
        [panel setPosition:ccp(base_h/2-10, (base_h+25)/2+10)];
    }else{
        panel=[CCPanel panelWithContent:content viewSize:CGSizeMake(self.ablWidth, self.baseHeight)];
        [panel setPosition:ccp((base_h), (base_h+25))];
    }
    //
    [typebound setPosition:ccp(chatLayer.contentSize.width/2, cFixedScale(base_h))];
    [btn_enter setPosition:ccp(chatLayer.contentSize.width/2+typebound.contentSize.width/2 - btn_enter.contentSize.width/2 - cFixedScale(10), cFixedScale(base_h))];
    [btn_emo setPosition:ccp(chatLayer.contentSize.width/2+typebound.contentSize.width/2-btn_emo.contentSize.width/2- btn_enter.contentSize.width - cFixedScale(5), cFixedScale(base_h))];
	[btn_channel setPosition:ccp(chatLayer.contentSize.width/2-typebound.contentSize.width/2+btn_channel.contentSize.width/2+cFixedScale(5), cFixedScale(base_h))];
    //
    //
	if(iPhoneRuningOnGame()){
        typetips=[CCLabelTTF labelWithString:NSLocalizedString(@"chat_input_text",nil) fontName:getCommonFontName(FONT_1) fontSize:16];
		//[typetips setPosition:ccp(210/2, 75/2)];
		bgblack=[StretchingImg stretchingImg:@"images/ui/bound.png" width:(chatLayer.contentSize.width-20) height:(chatLayer.contentSize.height-35) capx:8/2 capy:8/2];
		[bgblack setAnchorPoint:ccp(0.5, 0)];
		[bgblack setPosition:ccp(chatLayer.contentSize.width/2, 3)];
	//	[btn_close setPosition:ccp(chatLayer.contentSize.width-btn_close.contentSize.width/2-10/2, chatLayer.contentSize.height-btn_close.contentSize.height/2-10/2)];
		[typetips setPosition:ccp(155/2+28, base_h/2)];
		//[btn_enter setPosition:ccp(753/2+18, base_h/2)];
		[btn_channel setPosition:ccpAdd(btn_channel.position, ccp(5, 0)) ];
		[btn_channel_title setPosition:ccp(btn_channel.contentSize.width/2, btn_channel.contentSize.height/	2)];
		[btn_emo setPosition:ccpAdd(btn_emo.position, ccp(-15, 0))];
		//[typebound setPosition:ccp(chatLayer.contentSize.width/2+8, base_h/2)];
		CGRect rect= self.textBox.frame;
		[self.textBox setFont:[UIFont boldSystemFontOfSize:12]];
		[self.textBox setFrame:CGRectMake(view.frame.size.width/2-160+8, self.kbBaseHigth, rect.size.width/2-40, rect.size.height/2)];
		[btn_openfriend setPosition:ccp(730/2+30, 150/2+10)];
		[btn_openfriend_cli setPosition:ccp(chatLayer.contentSize.width-btn_openfriend_cli.contentSize.width, chatLayer.contentSize.height/2)];
		
	}else{
		[bgblack setAnchorPoint:ccp(0.5, 0)];
	//	[btn_close setAnchorPoint:ccp(0.5, 0.5)];
		[bgblack setPosition:ccp(chatLayer.contentSize.width/2, 13)];
		[typetips setPosition:ccp(155, base_h)];
		//[btn_enter setPosition:ccp(753, base_h)];
		
		[btn_channel_title setPosition:ccp(btn_channel.contentSize.width/2, btn_channel.contentSize.height/2)];
		[bgblack setPosition:ccp(chatLayer.contentSize.width/2, 13)];
		//[btn_close setPosition:ccp(chatLayer.contentSize.width-btn_close.contentSize.width/2-10, chatLayer.contentSize.height-btn_close.contentSize.height/2-10)];
		
		//[btn_emo setPosition:ccp(715, 75)];
		[btn_openfriend setPosition:ccp(730, 150)];
		[typebound setPosition:ccp(chatLayer.contentSize.width/2, base_h)];
		[btn_openfriend_cli setPosition:ccp(chatLayer.contentSize.width-btn_openfriend_cli.contentSize.width, chatLayer.contentSize.height/2)];
		
	}

	int btn_tagar[5]={CHANNEL_WORLD,CHANNEL_TUBA,CHANNEL_UNION,CHANNEL_PRIVATE,CHANNEL_SYSTEM};
	int btn_l=sizeof(btn_tagar)/sizeof(btn_tagar[0]);
	for(int i=0;i<btn_l;i++){
		CCSimpleButton *btn_tag=[CCSimpleButton spriteWithFile:[NSString stringWithFormat:@"images/ui/chat/btn_tag%i.png",btn_tagar[i]] select:[NSString stringWithFormat:@"images/ui/chat/btn_tag%is.png",btn_tagar[i]]];
        int off_w = 0;
        int off_h = 13;
        if (iPhoneRuningOnGame()) {
            btn_tag.scale = 1.3f;
            off_w = 18;
            off_h -= 10;
        }
		[btn_tag setAnchorPoint:ccp(0, 0)];
		[btn_tag setPosition:ccp(cFixedScale(24)+i*btn_tag.contentSize.width+off_w*i, bgblack.contentSize.height+off_h)];
		[btn_tag setTarget:self];
		[btn_tag setCall:@selector(callBackBtnTag:)];
		[btn_tag setTag:100+i];
		[chatLayer addChild:btn_tag ];
		if(i==0){
			[btn_tag setSelected:YES];
		}
	}
	
	[typetips setColor:ccc3(117, 81, 21)];
	
	
	
	[btn_channel addChild:btn_channel_title z:1 tag:TITLE_CHATCHANNEL];
	//[chatLayer addChild:btn_openfriend z:1 tag:BTN_FRIEND];
	[chatLayer addChild:typetips z:1 tag:TYPETIPS];
	[chatLayer addChild:btn_channel z:1 tag:BTN_CHATCHANNEL];
	[chatLayer addChild:btn_enter z:1 tag:BTN_CHATENTER];
	[chatLayer addChild:btn_emo z:1 tag:BTN_CHATEMO];
//	[chatLayer addChild:btn_close z:9];
	[chatLayer addChild:bgblack];
	[chatLayer addChild:panel];
	[chatLayer addChild:typebound];
	[chatLayer addChild:btn_openfriend_cli z:INT32_MAX];
	panel.stealTouches=NO;
	[self addChild:chatLayer z:-1 tag:CHATPANEL];
}

-(void)onEnter{
	self.windowType=PANEL_CHAT_BIG;
	[super onEnter];
	
	
	if(iPhoneRuningOnGame()){
		self.ablWidth=cFixedScale(645);
    }else{
        self.ablWidth=680;
    }
	self.baseHeight=cFixedScale(360-(CHAT_PANEL_BASE_H-75));
	self.kbHigth=300;
    CGSize size_ = [[CCDirector sharedDirector] winSize];
	if(iPhoneRuningOnGame()){
		self.kbBaseHigth=size_.height-CHAT_PANEL_BASE_H-10;
        self.baseHeight -= 10;
	}else{
		self.kbBaseHigth=size_.height-110-CHAT_PANEL_BASE_H;
        self.baseHeight += 20;
		self.kbHigth=280;
	}
	
	currenReadChannel = CHANNEL_WORLD;
	pointEmo=ccp(500, 90);
	
	
	isChatOpen=true;
	chatPanel=self;
	[self creatChatPanel];
	[[LowerLeftChat share]EventCloseChat:nil];
	
	[[[CCDirector sharedDirector]touchDispatcher ]addTargetedDelegate:self priority:-997 swallowsTouches:NO];
	[self addAllHistroy];
	[GameConnection addPost:@"PER" target:self call:@selector(listenPersonInfo:)];
	cuUserName = [[NSMutableString alloc]init];
	[GameConnection addPost:ConnPost_updateChannel target:self call:@selector(listenChannel:)];
}

-(void)listenChannel:(NSNotification*)nof{
	
	for(int i=0;i<5;i++){
		CCSimpleButton	*tmpb=(CCSimpleButton*)[chatLayer getChildByTag:i+100];
		[tmpb setSelected:NO];
	}
	int tag=0;
	switch ([nof.object intValue]) {
		case 1:{
			tag = BTN_TAG1;
			currenReadChannel = CHANNEL_WORLD;
		}
			break;
		case 3:{
			tag = BTN_TAG2;
			currenReadChannel = CHANNEL_TUBA;
		}
			break;
		case 4:{
			tag = BTN_TAG3;
			currenReadChannel = CHANNEL_UNION;
		}
			break;
		case 5:{
			tag = BTN_TAG4;
			currenReadChannel = CHANNEL_PRIVATE;
		}
			break;
			
		default:
			break;
	}
	CCSimpleButton *b=(CCSimpleButton*)[chatLayer getChildByTag:tag];
	b.selected=YES;
	[content removeAllChildren];
	[self.chatHistory removeAllObjects];
	[self addAllHistroy];
}


-(void)listenPersonInfo:(NSNotification*)nof{
	if(panel.isTouchValid){
		[cuUserName setString:nof.object];
        int w_ = 100;
        int h_ = 100;
        int f_ = 16;
        if (iPhoneRuningOnGame()) {
            w_ += 100;
            h_ += 100;
            f_ += 16;
        }
		CCSprite *bound=[StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(w_) height:cFixedScale(h_) capx:cFixedScale(8) capy:cFixedScale(8)];
		CCLabelTTF *label1 = [CCLabelTTF labelWithString:NSLocalizedString(@"chat_private",nil) fontName:getCommonFontName(0) fontSize:cFixedScale(f_)];
		CCLabelTTF *label2 = [CCLabelTTF labelWithString:NSLocalizedString(@"chat_add_friend",nil) fontName:getCommonFontName(0) fontSize:cFixedScale(f_)];
		CCLabelTTF *label3 = [CCLabelTTF labelWithString:NSLocalizedString(@"chat_look_data",nil) fontName:getCommonFontName(0) fontSize:cFixedScale(f_)];
		CCSimpleButton *b1=[CCSimpleButton spriteWithNode:label1];
		CCSimpleButton *b2=[CCSimpleButton spriteWithNode:label2];
		CCSimpleButton *b3=[CCSimpleButton spriteWithNode:label3];
		
		[bound setPosition:ccpAdd(cupoint, ccp(0,bound.contentSize.height/2))];
		
		[b1 setPriority:-999];
		[b2 setPriority:-999];
		[b3 setPriority:-999];
		
		[b1 setPosition:ccp(bound.contentSize.width/2,bound.contentSize.height/1.2 )];
		[b2 setPosition:ccp(bound.contentSize.width/2,bound.contentSize.height/2)];
		[b3 setPosition:ccp(bound.contentSize.width/2,bound.contentSize.height/5)];
		
		[b1 setTarget:self];
		[b2 setTarget:self];
		[b3 setTarget:self];
		[b1 setCall:@selector(PerPanelCallBack:)];
		[b2 setCall:@selector(PerPanelCallBack:)];
		[b3 setCall:@selector(PerPanelCallBack:)];
		
		[bound addChild:b1 z:1 tag:1];
		[bound addChild:b2 z:1 tag:2];
		[bound addChild:b3 z:1 tag:3];
		
		[[self textBox]setHidden:YES];
		[chatLayer addChild:bound z:INT32_MAX tag:PERPANEL];
	}
}

-(void)checkHasPersonInfo{
	
	if(![[Window shared]isHasWindowByType:PANEL_OTHER_PLAYER_INFO]){
		[GameConnection addPost:@"PER" target:self call:@selector(listenPersonInfo:)];
		[self regPRAjoin];
		[self unschedule:@selector(checkHasPersonInfo)];
	}
}

-(void)PerPanelCallBack:(CCSimpleButton*)b{
	CCLOG(@"%@",cuUserName);
	switch (b.tag) {
		case 1:{
			[ChatPanelBase sendPrivateChannle:cuUserName pid:0];
		}
			break;
		case 2:{
			[[SocialHelper shared] socialActionWithName:cuUserName action:SocialHelper_addFriend];
		}
			break;
		case 3:{
			[[SocialHelper shared] socialGetInfo:cuUserName isOver:YES];
			[self schedule:@selector(checkHasPersonInfo) interval:0.1];
			[GameConnection removePostTarget:self];
		}
			break;
		default:
			break;
	}
	[chatLayer removeChildByTag:PERPANEL];
    if (b.tag == 3) {
        [textBox setHidden:YES];
        textBox.text=@"";
    }else{
        [textBox setHidden:NO];
    }
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	cupoint= [chatLayer convertToNodeSpace:getGLpoint(touch)];
	[[self textBox]setHidden:NO];
	
	[chatLayer removeChildByTag:PERPANEL];
	return NO;
}

-(void)callBackBtnTag:(CCSimpleButton*)b{
	if([b selected]){
		return;
	}
	for(int i=0;i<5;i++){
		CCSimpleButton	*tmpb=(CCSimpleButton*)[chatLayer getChildByTag:i+100];
		[tmpb setSelected:NO];
	}
	
	
	switch (b.tag) {
		case BTN_TAG1:{
			currenReadChannel=CHANNEL_WORLD;
			CCSimpleButton *tempb=[CCSimpleButton node];
			tempb.tag = currenReadChannel+BTN_CHATCHANNELBASE;
			[self buttonChannelCallBack:tempb];
    	}
			break;
		case BTN_TAG2:{
			currenReadChannel=CHANNEL_TUBA;
			CCSimpleButton *tempb=[CCSimpleButton node];
			tempb.tag=currenReadChannel+BTN_CHATCHANNELBASE;
			[self buttonChannelCallBack:tempb];
    	}
			break;
		case BTN_TAG3:{
			currenReadChannel=CHANNEL_UNION;
			CCSimpleButton *tempb=[CCSimpleButton node];
			tempb.tag=currenReadChannel+BTN_CHATCHANNELBASE;
			[self buttonChannelCallBack:tempb];
		}
			break;
		case BTN_TAG4:{
			currenReadChannel=CHANNEL_PRIVATE;
			CCSimpleButton *tempb=[CCSimpleButton node];
			tempb.tag=currenReadChannel+BTN_CHATCHANNELBASE;
			[self buttonChannelCallBack:tempb];
		}
			break;
		case BTN_TAG5:{
			currenReadChannel = CHANNEL_SYSTEM;
		}
		default:
			break;
	}
	[b setSelected:YES];

	[content removeAllChildren];
	[self.chatHistory removeAllObjects];
	[self addAllHistroy];
}

-(void)buttonCallOpenFriend:(CCSimpleButton*)b{
	
	if([[b userObject]isEqual:@"A"]){
		[chatLayer removeChildByTag:SNSPANEL];
		[b setPosition:ccp(chatLayer.contentSize.width-b.contentSize.width, chatLayer.contentSize.height/2)];
		[b setUserObject:@"B"];
		[b setScaleX:-1];
		return;
	}
	
	float fontSize = 18;
	
	//CCLabelTTF *snstitle=[CCLabelTTF labelWithString:@"好友列表" fontName:getCommonFontName(FONT_1) fontSize:fontSize];
    CCLabelTTF *snstitle=[CCLabelTTF labelWithString:NSLocalizedString(@"chat_friend_list",nil) fontName:getCommonFontName(FONT_1) fontSize:fontSize];
	[snstitle setColor:ccORANGE];
	//to do friend list
	// 代码
	float snsHeight = 140;
	if (iPhoneRuningOnGame()) {
		snsHeight = 100;
		snstitle.fontSize = 14;
		
	}
	CCSimpleButton *btn_friendtype=[CCSimpleButton spriteWithFile:@"images/ui/chat/btn_friendtype2.png" select:@"images/ui/chat/btn_friendtype1.png"];
	CCSimpleButton *btn_blacktype=[CCSimpleButton spriteWithFile:@"images/ui/chat/btn_blacklisttype2.png" select:@"images/ui/chat/btn_blacklisttype1.png"];
	
	CCSimpleButton *btn_addFriend=[CCSimpleButton spriteWithFile:@"images/ui/button/bt_add_1.png" select:@"images/ui/button/bt_add_2.png"];
	CCSimpleButton *btn_addBlacklist=[CCSimpleButton spriteWithFile:@"images/ui/chat/btn_addblacklist1.png" select:@"images/ui/chat/btn_addblacklist2.png"];
	
	[btn_addBlacklist setVisible:NO];
	[btn_addFriend setVisible:YES];
	
	[btn_friendtype setTag:1];
	[btn_blacktype setTag:2];
	
	[btn_addFriend setTag:3];
	[btn_addBlacklist setTag:4];
	
	[btn_blacktype setPriority:-999];
	[btn_friendtype setPriority:-999];
	
	[btn_friendtype setSelected:YES];
	
	[btn_friendtype setTarget:self];
	[btn_blacktype setTarget:self];
	
	[btn_friendtype setCall:@selector(btn_typeCallBack:)];
	[btn_blacktype setCall:@selector(btn_typeCallBack:)];
	
	[btn_addBlacklist setTarget:self];
	[btn_addFriend setTarget:self];
	
	[btn_addFriend setCall:@selector(btn_addBoxCallBack:)];
	[btn_addBlacklist setCall:@selector(btn_addBoxCallBack:)];
	if(iPhoneRuningOnGame()){
		[btn_friendtype setScale:1.2];
		[btn_blacktype setScale:1.2];
		[btn_addFriend setScale:1.2];
		[btn_addBlacklist setScale:1.2];
		
	}
	
	CCSprite *snsbg=[StretchingImg stretchingImg:@"images/ui/chat/friendlistbg.png" width:cFixedScale(309) height:cFixedScale(400) capx:cFixedScale(14) capy:cFixedScale(14)];
	[snsbg setAnchorPoint:ccp(0, 0.5)];
	float managerHeight = 115;
	if (iPhoneRuningOnGame()) {
		managerHeight = 80;
	}
	SocialityManager *manager = [[[SocialityManager alloc] initWithSize:CGSizeMake(cFixedScale(400), cFixedScale(300))] autorelease];
	manager.isFriendList = YES;
	if (iPhoneRuningOnGame()) {
		manager.position = ccp(snsbg.contentSize.width/2, snsbg.contentSize.height-cFixedScale(23));
	}
	manager.position=ccp(0,snsbg.contentSize.height-manager.contentSize.height-cFixedScale(50));
	[snsbg setPosition:ccp(chatLayer.contentSize.width,chatLayer.contentSize.height/2+10)];
	
	float offsetY = 30;
	if (iPhoneRuningOnGame()) {
		offsetY = 25;
	}
	
	[btn_friendtype setPosition:ccp(0+btn_friendtype.contentSize.width/2+cFixedScale(12) , snsbg.contentSize.height-cFixedScale(80))];
	[btn_blacktype setPosition:ccp(0+btn_blacktype.contentSize.width/2+cFixedScale(12), btn_friendtype.position.y-btn_blacktype.contentSize.height)];
	
	id move1=[CCMoveBy actionWithDuration:0.2 position:ccp(-snsbg.contentSize.width-cFixedScale(30), 0)];
	id og=[CCFadeIn actionWithDuration:0.3];
	id ogg=[CCEaseIn actionWithAction:og rate:5];
	id swq=[CCSpawn actions:move1,ogg, nil];
	
	[snsbg runAction:swq];
	
	[b setPosition:ccp(chatLayer.contentSize.width-snsbg.contentSize.width, chatLayer.contentSize.height/2)];
	
	[b setUserObject:@"A"];
	[b setScaleX:1];
	[snstitle setPosition:ccp(snsbg.contentSize.width/2, snsbg.contentSize.height-offsetY)];
	
	[btn_addBlacklist setPosition:ccp(snsbg.contentSize.width/2, cFixedScale(50))];
	[btn_addFriend setPosition:ccp(snsbg.contentSize.width/2, cFixedScale(50))];
	
	[snsbg addChild:snstitle z:1];
	

	
	[snsbg addChild:manager z:1 tag:SNSMG];
	[snsbg addChild:btn_friendtype];
	[snsbg addChild:btn_blacktype];
	[snsbg addChild:btn_addFriend];
	[snsbg addChild:btn_addBlacklist];
	
	
	[chatLayer addChild:snsbg z:1 tag:SNSPANEL];
	[[SocialityManager shared] setCanvasWithType:Sociality_friend];
	[[SocialHelper shared] socialRelationmembers:SocialHelper_relation_friend];
	
}


-(void)btn_addBoxCallBack:(CCSimpleButton*)b{
	switch (b.tag) {
		case 3:{
			[SocialityPanel openAddTypeBox:Sociality_friend :self];
		}
			break;
		case 4:{
			[SocialityPanel openAddTypeBox:Sociality_blacklist :self];
		}
			break;
		default:
			break;
	}
}


-(void)btn_typeCallBack:(CCSimpleButton*)b{
	CCSimpleButton *b1=(CCSimpleButton*)[[chatLayer getChildByTag:SNSPANEL]getChildByTag:1];
	CCSimpleButton *b2=(CCSimpleButton*)[[chatLayer getChildByTag:SNSPANEL]getChildByTag:2];
	CCSimpleButton *b3=(CCSimpleButton*)[[chatLayer getChildByTag:SNSPANEL]getChildByTag:3];
	CCSimpleButton *b4=(CCSimpleButton*)[[chatLayer getChildByTag:SNSPANEL]getChildByTag:4];
	
	switch (b.tag) {
		case 1:{
			[b1 setSelected:YES];
			[b2 setSelected:NO];
			[[SocialityManager shared] setCanvasWithType:Sociality_friend];
			[[SocialHelper shared] socialRelationmembers:SocialHelper_relation_friend];
			[b3 setVisible:YES];
			[b4 setVisible:NO];
		}
			break;
		case 2:{
			[b1 setSelected:NO];
			[b2 setSelected:YES];
			[[SocialityManager shared] setCanvasWithType:Sociality_blacklist];
			[[SocialHelper shared] socialRelationmembers:SocialHelper_relation_enemy];
			[b3 setVisible:NO];
			[b4 setVisible:YES];
		}
			break;
		default:
			break;
	}
}

-(void)removeTipsChangeButton{
	[super removeTipsChangeButton];
}

-(void)callBackClose{
	
	[[Window shared]removeWindow:PANEL_CHAT];
}

-(void)onExit{
	[ChatPanelBase setPrivateMsgcount:0];
	[[[CCDirector sharedDirector]touchDispatcher ]removeDelegate:self];
	[cuUserName release];
	chatPanel=nil;
	[super onExit];
}

@end
