//
//  LowerLeftChat.m
//  TXSFGame
//
//  Created by max on 12-11-18.
//  Copyright 2012 eGame. All rights reserved.
//

#import "LowerLeftChat.h"

#import "ChatPanel.h"

@interface ChatPanelBase (CPBPrivate)
-(void)buttonCallBack:(id)sender;
@end

#pragma mark 左下角聊天类
@implementation LowerLeftChat


static LowerLeftChat *Leftchat;



+(LowerLeftChat*)share{
	if(Leftchat){
		return Leftchat;
	}
	return nil;
}

+(void)clearText{
   	if( Leftchat && !iPhoneRuningOnGame() ){
		[Leftchat.textBox setText:@""];
        [Leftchat setPrivateTargetName:@""];
		[Leftchat setPrivateTargetPid:0];
	}
}

-(void)updatePrivateMsgCount{
	
	if([ChatPanelBase getPrivateMsgcount]>0){
		if(pmc!=0 && pmc == [ChatPanelBase getPrivateMsgcount]){
			return;
		}
		msgCbg.visible=YES;
		[msgCbg removeAllChildren];
		CCLabelTTF *l=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i",[ChatPanelBase getPrivateMsgcount]] fontName:getCommonFontName(0) fontSize:10];
		addTargetToCenter(l, msgCbg, 999);
		pmc=[ChatPanelBase getPrivateMsgcount];
	}else{
		pmc=0;
		msgCbg.visible=NO;
		
	}
	
}

-(void)onEnter{
	currenChannel=1;
	self.windowType = PANEL_CHAT;
	[super onEnter];
	[self creatChatBg];
	NSString *imgpath=[NSString stringWithFormat:@"%@btn_openchat.png",BASEPATH];
	CCSimpleButton *openmenu=[CCSimpleButton spriteWithFile:imgpath];
	[openmenu setTarget:self];
	[openmenu setCall:@selector(EventOpenChat:)];
	
	if(iPhoneRuningOnGame()){
        openmenu.scale = 1.3f;
		[openmenu setPosition:ccp(openmenu.contentSize.width/2,30)];
	}else{
		[openmenu setPosition:ccp(openmenu.contentSize.width/2,70)];
	}
	
	[self addChild:openmenu z:-1 tag:BTN_CHATOPEN];
	Leftchat=self;
	chatInterval=500;
	chatPosY=CHAT_LAYERY;
	[self schedule:@selector(updatePrivateMsgCount) interval:0.1f];
	
	
}

-(void)onExit{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] removeDelegate:self];
	[self EventCloseChat:nil];
	
	Leftchat = nil;
	[GameConnection removePostTarget:self];
	NSString *imgpath=[NSString stringWithFormat:@"%@texture.plist",BASEPATH];
	[[CCSpriteFrameCache sharedSpriteFrameCache]removeSpriteFramesFromFile:imgpath];
	
	[super onExit];
}



-(void)EventOpenChat:(id)sender{
	if(![GameUI shared].isShowUI){
		return;
	}
	
	if(isChatOpen){
		return;
	}
	if([ChatPanel getChatPanel]){
		return;
	}
	
	[self loadBrow];
	if (!iPhoneRuningOnGame()) {
		[self.textBox setEnabled:YES];
	}
	[[self getChildByTag:BTN_CHATOPEN]setVisible:NO];
	
	[chatLayer setPosition:ccp(chatLayer.contentSize.width/2*-1, chatPosY)];
	
	id act=[CCMoveTo actionWithDuration:0.3 position:ccp(20, chatPosY)];
	
	id act1=[CCMoveTo actionWithDuration:0.3 position:ccp(0, chatPosY)];
	CCCallFuncN *fun=[CCCallFuncN actionWithTarget:self selector:@selector(showTextBox:)];
	id squ=[CCSequence actions:act,act1,fun,nil];
	[chatLayer stopAllActions];
	[chatLayer runAction:squ];
	[[GameUI shared] closeMainMenu];
	isChatOpen=true;
	[self addNewHistroy];

	
}

-(void)showTextBox:(CCCallFuncN*)n{
	if (!iPhoneRuningOnGame()) {
		[self.textBox setHidden:NO];
		//CGRect rect=self.textBox.frame;
		//[self.textBox setFrame:CGRectMake(rect.origin.x, rect.origin.y,rect.size.width, rect.size.height)];
		[self.textBox setEnabled:YES];
	}
}

-(void)EventCloseChat:(id)sender{
	
	CCSprite *bg_chat=(CCSprite*)[self getChildByTag:BG_CHAT];
    [bg_chat removeChildByTag:BG_EMO cleanup:true];
	
	id act=[CCMoveTo actionWithDuration:0.15 position:ccp(bg_chat.contentSize.width/2*-1+10, bg_chat.position.y)];
	id call = [CCCallBlock actionWithBlock:^(void){
		CCNode * node = [self getChildByTag:BG_CHAT];
		node.position = ccp(node.position.x,2);
		
		CCSimpleButton *btn= (CCSimpleButton*)[self getChildByTag:BTN_CHATOPEN];
		[btn setVisible:YES];
	}];
	[bg_chat stopAllActions];
	[bg_chat runAction:[CCSequence actions:act, call, nil]];
	
	[self closeTextBox];
	
	
	isChatOpen=false;
	[self stopAddHistory];
}



#pragma mark 创建聊天窗
-(void)creatChatBg{
	int off_h = 12;
    
	self.ablWidth=cFixedScale(346);

	if(iPhoneRuningOnGame()){
		content=[CCLayerColor layerWithColor:ccc4(0, 0, 0, 0) width:self.ablWidth height:BASECONTENTHIGHT+off_h];
	}else{
		content=[CCLayerColor layerWithColor:ccc4(0, 0, 0, 0) width:self.ablWidth height:BASECONTENTHIGHT];
	}
	
	chatLayer=[CCLayer node];
	NSString *imgpath=[NSString stringWithFormat:@"%@bg.png",BASEPATH];
	
	CCSprite *bg=[CCSprite spriteWithFile:imgpath];
	imgpath=[NSString stringWithFormat:@"%@btn_closechat.png",BASEPATH];
	CCSimpleButton *btn_closechat=[CCSimpleButton spriteWithFile:imgpath];
	imgpath=[NSString stringWithFormat:@"%@btn_openbigchat.png",BASEPATH];
	//CCSimpleButton *btn_openbigchat=[CCSimpleButton spriteWithFile:imgpath];
    if (iPhoneRuningOnGame()) {
        //btn_openbigchat.scale = 2.0f;
		btn_closechat.visible=NO;
    }
	CCSimpleButton *btn_abopenbigchar=[CCSimpleButton spriteWithFile:[NSString stringWithFormat:@"%@chatpop1.png",BASEPATH] select:[NSString stringWithFormat:@"%@chatpop2.png",BASEPATH]];
	
	
//	if(iPhoneRuningOnGame()){
//		panel=[CCPanel panelWithContent:content viewSize:CGSizeMake(346/2.0f, BASECONTENTHIGHT+off_h)];
//	}else{
//		panel=[CCPanel panelWithContent:content viewSize:CGSizeMake(345, BASECONTENTHIGHT)];
//	}
    if(iPhoneRuningOnGame()){
		panel=[CCPanel panelWithContent:content viewSize:CGSizeMake(self.ablWidth, BASECONTENTHIGHT+off_h)];
	}else{
		panel=[CCPanel panelWithContent:content viewSize:CGSizeMake(self.ablWidth, BASECONTENTHIGHT)];
	}
    
	CCLabelTTF *typetips=nil;
	
	
	
	[bg setAnchorPoint:ccp(0, 0)];
	
	
	//[btn_openbigchat setTarget:self];
	
	//[btn_openbigchat setCall:@selector(buttonCallBack:)];
	
	
	[btn_abopenbigchar setTarget:self];
	
	[btn_abopenbigchar setCall:@selector(buttonCallBack:)];
	msgCbg = [CCSprite spriteWithFile:@"images/ui/timebox/freetime_bg.png"];

	if(iPhoneRuningOnGame()){
        int h_ = 3;
		[btn_closechat setPosition:ccp(410/2, 90/2)];
		[panel setPosition:ccp(65/2, 0/2.0f)];
		[bg setPosition:ccp(0, 0/2.0f)];
		bg.scaleY=1.04f;
		[chatLayer setPosition:ccp((chatLayer.contentSize.width/2*-1)/2, chatPosY/2)];
		typetips.scale = 1.0f;
		
		[typetips setPosition:ccp(60+15, 23/2+h_)];
		//[btn_openbigchat setPosition:ccp(410/2-5,87/2.0f)];
		[btn_abopenbigchar setPosition:ccp(34/2, 25)];
		btn_abopenbigchar.scale=1.04f;
		[self.textBox setFrame:CGRectMake(65/2, 295, 260/2, 30/2)];
		//chen add hide code
		typetips.visible=NO;
		//		showNode(bg);
	}else{
        bg.scaleY = 0.82;
		[btn_closechat setPosition:ccp(410, 40)];
		[panel setPosition:ccp(65, 0)];
		[bg setPosition:ccp(0, 0)];
		[chatLayer setPosition:ccp(chatLayer.contentSize.width/2*-1, chatPosY)];
		[typetips setPosition:ccp(110, 23)];
		//[btn_openbigchat setPosition:ccp(410,76)];
		[btn_abopenbigchar setPosition:ccp(34, 40)];
		
	}
	CGPoint p = ccp(btn_abopenbigchar.contentSize.width-cFixedScale(10), btn_abopenbigchar.contentSize.height-cFixedScale(10));

	[msgCbg setPosition:p];
	[btn_abopenbigchar addChild:msgCbg z:INT16_MAX];

	
	[chatLayer addChild:bg];
	[chatLayer addChild:btn_abopenbigchar z:1 tag:BTN_BIGCHAT];
	[chatLayer addChild:panel];
	[chatLayer addChild:btn_closechat z:-1 tag:BTN_CHATCLOSE];
	
	[self addChild:chatLayer z:-1 tag:BG_CHAT];
	
	//[chatLayer addChild:btn_openbigchat z:10 tag:BTN_BIGCHAT];
	panel.stealTouches=NO;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
	if ([[Window shared] isHasWindow]) {
        return NO;
    }
    return [super textFieldShouldBeginEditing:textField];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
	if(iPhoneRuningOnGame()){
		//[[Window shared]showWindow:PANEL_CHAT];
	}
	else
	{
		[super textFieldDidBeginEditing:textField];
	}
}


-(void)iphoneButtonCallBack{
	[[Window shared]showWindow:PANEL_CHAT_BIG];
}

-(void)buttonCallBack:(id)sender{
    if ([[Window shared] isHasWindow]) {
        return ;
    }
    [super buttonCallBack:sender];
}



#pragma mark 处理触摸事件
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchDis=touchLocation.x;
	CGPoint gltouch=[[CCDirector sharedDirector]convertToGL:touchLocation];
	
	
	if(iPhoneRuningOnGame()){
		if(CGRectContainsPoint(CGRectMake(0, 0, 450/2, 155/2), gltouch)){
			return YES;
		}
	}else{
		if(keyBoradOpen){
			[self.textBox resignFirstResponder];
		}
		if(CGRectContainsPoint(CGRectMake(0, 0, 450, 140), gltouch)){
			return YES;
		}
	}
	
	return NO;
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint touchLocation = [touch locationInView:touch.view];
	touchDis=touchLocation.x-touchDis;
	
	if(touchDis>0 && touchDis>50){
		if(!keyBoradOpen){
			if (!iPhoneRuningOnGame()) {
				[self EventOpenChat:[self getChildByTag:BTN_CHATOPEN]];
			}
		}
	}else if(touchDis<0 && touchDis<-50){
		//[self EventCloseChat:nil];
	}
	
}


#pragma mark 析构
-(void)dealloc{
	//if(self.textBox) [self.textBox release];
	[super dealloc];
}


@end
