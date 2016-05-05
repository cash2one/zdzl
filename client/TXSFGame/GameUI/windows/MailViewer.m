//
//  MailViewer.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-7.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "MailViewer.h"
#import "Window.h"
#import "StretchingImg.h"
#import "CCSimpleButton.h"
#import "CCLabelFX.h"
#import "GameMail.h"
#import "CCPanel.h"

static int targetMailId;

@implementation MailViewer

+(void)show:(int)mailId{
	targetMailId = mailId;
	[[Window shared] showWindow:PANEL_MAIL];
}

-(void)onExit{
	targetMailId = 0;
	[super onExit];
}

-(void)onEnter{
	[super onEnter];
	
	NSDictionary * mail = [[GameMail shared] getMailById:targetMailId];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	CCSprite * bg = [CCSprite spriteWithFile:@"images/ui/panel/p3.png"];
	bg.position = ccp(winSize.width/2,winSize.height*0.55);
	[self addChild:bg];
	
	CCSprite * title = [CCSprite spriteWithFile:@"images/ui/mail/title-1.png"];
	title.position = ccp(bg.contentSize.width/2,bg.contentSize.height-10);
	[bg addChild:title];
	
	CCSprite * background=[StretchingImg stretchingImg:@"images/ui/bound.png"
										  width:bg.contentSize.width-cFixedScale(55)
										 height:bg.contentSize.height-cFixedScale(65)
										   capx:cFixedScale(8) capy:cFixedScale(8)];
	background.anchorPoint = ccp(0.5,1);
	
	background.position = ccp(bg.contentSize.width/2,bg.contentSize.height-cFixedScale(48));
	[bg addChild:background];
	
	CCSprite * f = [CCSprite spriteWithFile:@"images/ui/panel/p18.png"];
	f.anchorPoint = ccp(0.5,0.5);
	f.scaleX = 0.6;
	f.position = ccp(bg.contentSize.width/2,iPhoneRuningOnGame()?43:70);
	[bg addChild:f];
	
	CCSimpleButton * btn = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_ok_1.png" 
												   select:@"images/ui/button/bt_ok_2.png"];
	btn.position = ccp(bg.contentSize.width/2,42);
	if (iPhoneRuningOnGame()) {
		btn.position = ccp(bg.contentSize.width/2,26);
		btn.scale = 1.3;
	}
	btn.target = self;
	btn.call = @selector(doPass:);
	[bg addChild:btn];
	
	CCLabelFX * label = [CCLabelFX labelWithString:[mail objectForKey:@"title"]
										dimensions:CGSizeMake(0,0)
										 alignment:kCCTextAlignmentCenter
										  fontName:GAME_DEF_CHINESE_FONT 
										  fontSize:28
									  shadowOffset:CGSizeMake(-1.5, -1.5) 
										shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,1.0);
	if (iPhoneRuningOnGame()) {
		label.position = ccp(bg.contentSize.width/2,bg.contentSize.height-cFixedScale(60));
	}else{
		label.position = ccp(bg.contentSize.width/2,bg.contentSize.height-60);
	}
	[bg addChild:label];
	
	NSString * msg = [mail objectForKey:@"content"];
	
	int t_w = bg.contentSize.width-cFixedScale(70);
	int t_h = bg.contentSize.height-cFixedScale(180);
	if (iPhoneRuningOnGame()) {
		t_w *= 2;
		t_h = bg.contentSize.height-97;
	}
	CCSprite * content = drawString(msg, 
							  CGSizeMake(t_w,0), 
							  GAME_DEF_CHINESE_FONT, 24, 26, 
							  getHexStringWithColor3B(ccWHITE));
	content.anchorPoint = ccp(0,1);
	
	int c_h = (content.contentSize.height>t_h?content.contentSize.height:t_h);
	CCLayerColor * layer = [CCLayerColor layerWithColor:ccc4(0,0,0,0)
												  width:t_w 
												 height:c_h];
	[layer addChild:content];
	content.position = ccp(0,c_h);
	
	CCPanel * panle = [CCPanel panelWithContent:layer 
								   viewPosition:ccp(0,0) 
									   viewSize:CGSizeMake( t_w, t_h)];
	panle.anchorPoint = ccp(0.5,1);
	if (iPhoneRuningOnGame()) {
		panle.position = ccp(winSize.width/2-(t_w/4),winSize.height*0.30f+15);
	}else{
		panle.position = ccp(winSize.width/2-(t_w/2),winSize.height*0.35+10);
	}
	[self addChild:panle];
	[panle updateContentToTop];
	
}

-(void)doPass:(CCNode*)sender{
    CCNode *temp = sender;
    for (;; ) {
        if (temp == NULL) {
            break;
        }
        if ([temp isKindOfClass:[CCPanel class]]) {
            CCPanel *temp_ = (CCPanel *)temp;
            if(!temp_.isTouchValid){
                return;
            }
            break;
        }
        temp = temp.parent;
    }
    //
	[[GameMail shared] removeMailById:targetMailId];
	[[Window shared] removeWindow:PANEL_MAIL];
}

@end
