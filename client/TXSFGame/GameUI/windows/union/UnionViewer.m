//
//  UnionViewer.m
//  TXSFGame
//
//  Created by Max on 13-3-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionViewer.h"



@implementation UnionViewer

static UnionViewer * unionViewer;

+(void)show:(NSDictionary*)info{
	if([UnionPanel share]){
		unionViewer = [UnionViewer node];		
		[[UnionPanel share] addChild:unionViewer z:900];
		[unionViewer setData:info];
	}
}


+(void)hide{
	if(unionViewer){
		[unionViewer removeFromParentAndCleanup:true];
		
	}
}

-(void)setData:(NSDictionary*)info{
	int level = [[info objectForKey:@"lv"] intValue];
	NSDictionary * allyLevel = [[GameDB shared] getAllyLevel:level];
	int memberMax = [[allyLevel objectForKey:@"maxNum"] intValue];
	CCLabelFX * label = [CCLabelFX labelWithString:[info objectForKey:@"n"]
										dimensions:CGSizeMake(0,0)
										 alignment:kCCTextAlignmentCenter
										  fontName:GAME_DEF_CHINESE_FONT
										  fontSize:20
									  shadowOffset:CGSizeMake(-1.5, -1.5)
										shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(0,cFixedScale(185));
	[self addChild:label];
	
	NSString *pnstr=[NSString stringWithFormat:@"%@",[info objectForKey:@"pn"]];
	
	label = [CCLabelFX labelWithString:pnstr
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentLeft
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0,0.5);
	label.position = ccp(cFixedScale(-135),cFixedScale(150));
	[self addChild:label];
	
	label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d",level]
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentLeft
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0,0.5);
	label.position = ccp(cFixedScale(-135),cFixedScale(120));
	[self addChild:label];
	
	///
	
	label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d/%d",[[info objectForKey:@"c"] intValue],memberMax]
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentLeft
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0,0.5);
	label.position = ccp(cFixedScale(80),cFixedScale(150));
	[self addChild:label];
	
	label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d",[[info objectForKey:@"rank"] intValue]]
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentLeft
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0,0.5);
	label.position = ccp(cFixedScale(80),cFixedScale(120));
	[self addChild:label];
	
	NSString * msg = [info objectForKey:@"info"];
	if(!msg) msg = @"";
    //msg = [NSString stringWithFormat:@"同盟介绍: %@",msg];
    msg = [NSString stringWithFormat:NSLocalizedString(@"union_viewer_intro",nil),msg];
	float fontSize=16;
	float lineHeight=18;
    if (iPhoneRuningOnGame()) {
		fontSize=18;
		lineHeight=22;
    }
	
    CCSprite *labelSpr=drawString(msg,CGSizeMake(380,0),getCommonFontName(FONT_1),fontSize,lineHeight,@"ffffff");
    labelSpr.anchorPoint = ccp(0,1);
	labelSpr.position = ccp(cFixedScale(-160-20),cFixedScale(90+20/2));
	[self addChild:labelSpr];
    /*
	label = [CCLabelFX labelWithString:msg
							dimensions:CGSizeMake(380,70)
							 alignment:kCCTextAlignmentLeft
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:16
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
     
	label.anchorPoint = ccp(0,1);
	label.position = ccp(-160-20,90+20/2);
	[self addChild:label];
    */
	
	int aid = [[info objectForKey:@"aid"] intValue];
	NSString * fm = [NSString stringWithFormat:@"aid::%d",aid];
	CCLOG(@"%i",unionViewer.retainCount);
	[GameConnection request:@"allyOtherMembers" format:fm target:self call:@selector(didLoadMembers:)];
	CCLOG(@"%i",unionViewer.retainCount);
	
}

-(void)didLoadMembers:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		[self showMemberList:getResponseData(response)];
	}else{
		CCLOG(@"Error load members");
	}
}

-(void)showMemberList:(NSArray*)members{
	int w = cFixedScale(380);
	int h = cFixedScale(270);
	float posY=-260;
	if (iPhoneRuningOnGame()) {
		posY=-260;
	}
	CCLayerColor * content = [CCLayerColor layerWithColor:ccc4(255,0,0,0) width:w height:h];
	
	int count = [members count];	
	content.contentSize = CGSizeMake(cFixedScale(380), cFixedScale(26)*count);

	if(content.contentSize.height<h){
		content.contentSize = CGSizeMake(w,h);
	}
	
	CCPanel * cp = [CCPanel panelWithContent:content viewSize:CGSizeMake(w, h)];
	cp.tag = 101;	
	cp.position = ccp(cFixedScale(-190),cFixedScale(posY));
	[cp showScrollBar:@"images/ui/common/scroll3.png"];
	[self addChild:cp z:100];
	
	for(int i=0;i<count;i++){
		
		CCSprite * t = [CCSprite node];
		t.anchorPoint = ccp(0,0);
		t.position = ccp(0,content.contentSize.height-cFixedScale(26)*i-cFixedScale(26));
		[content addChild:t];
		
		CCSprite * m = [CCSprite spriteWithFile:@"images/ui/panel/pageBack.png"];
		m.anchorPoint = ccp(0,0);
		m.scaleX = cFixedScale(380)/m.contentSize.width;
		
		[t addChild:m];
		
		NSDictionary * member = [members objectAtIndex:i];
		
		CCLabelFX * label;
		label = [CCLabelFX labelWithString:[member objectForKey:@"n"]
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:GAME_DEF_CHINESE_FONT
								  fontSize:20
							  shadowOffset:CGSizeMake(-1.5, -1.5)
								shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(cFixedScale(60),cFixedScale(10));
		[t addChild:label];
		
		label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d",[[member objectForKey:@"lv"] intValue]]
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:GAME_DEF_CHINESE_FONT
								  fontSize:20
							  shadowOffset:CGSizeMake(-1.5, -1.5)
								shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(cFixedScale(130+30),cFixedScale(10));
		[t addChild:label];
		
		label = [CCLabelFX labelWithString:getJobName([[member objectForKey:@"duty"] intValue])
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:GAME_DEF_CHINESE_FONT
								  fontSize:20
							  shadowOffset:CGSizeMake(-1.5, -1.5)
								shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(cFixedScale(200+20),cFixedScale(10));
		[t addChild:label];
		
		label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d",[[member objectForKey:@"pvp"] intValue]]
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:GAME_DEF_CHINESE_FONT
								  fontSize:20
							  shadowOffset:CGSizeMake(-1.5, -1.5)
								shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(cFixedScale(310),cFixedScale(10));
		[t addChild:label];
		
		
	}
	[cp updateContentToTop];	
}

#pragma mark UnionViewer onEnter
-(void)onEnter{
	[super onEnter];
	
	self.position = ccpAdd(ccp(0,cFixedScale(-15)),
						   ccp([UnionPanel share].contentSize.width/2,[UnionPanel share].contentSize.height/2));
	
	[[[CCDirector sharedDirector]touchDispatcher]addTargetedDelegate:self priority:-255 swallowsTouches:YES];
	
	CCSprite * bg = [CCSprite spriteWithFile:@"images/ui/panel/p2.png"];
	[self addChild:bg];
	
	bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(400) height:cFixedScale(480) capx:cFixedScale(8) capy:cFixedScale(8)];
	bg.anchorPoint = ccp(0.5,0.5);
	bg.position = ccp(0,cFixedScale(-30));
	[self addChild:bg];
	
	CCSimpleButton * btn = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"];
	btn.position = ccp(cFixedScale(170),cFixedScale(240));
	if (iPhoneRuningOnGame()) {
		btn.scale=1.19f;
		btn.position = ccp(cFixedScale(170),cFixedScale(240));
	}
	btn.target = self;
	btn.call = @selector(doClose:);
	btn.priority=-501;
	[self addChild:btn];
	
	btn = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_close_1.png"
								  select:@"images/ui/button/bts_close_2.png"];
	btn.position = ccp(0,cFixedScale(-240));
	btn.target = self;
	btn.call = @selector(doClose:);
	btn.priority=-501;
//	[self addChild:btn];
	
	CCSprite * sp = [CCSprite spriteWithFile:@"images/ui/panel/columnTop.png"];
	sp.scaleX = cFixedScale(380)/sp.contentSize.width;
	sp.position = ccp(0,cFixedScale(185));
	[self addChild:sp];
	
	sp = [CCSprite spriteWithFile:@"images/ui/panel/columnTop.png"];
	sp.scaleX = cFixedScale(380)/sp.contentSize.width;
	sp.position = ccp(0,cFixedScale(30));
	[self addChild:sp];

//	CCLabelFX * label = [CCLabelFX labelWithString:@"盟主:"
//										dimensions:CGSizeMake(0,0)
//										 alignment:kCCTextAlignmentLeft
//										  fontName:GAME_DEF_CHINESE_FONT
//										  fontSize:20
//									  shadowOffset:CGSizeMake(-1.5, -1.5)
//										shadowBlur:1.0f];
    CCLabelFX * label = [CCLabelFX labelWithString:NSLocalizedString(@"union_viewer_main",nil)
										dimensions:CGSizeMake(0,0)
										 alignment:kCCTextAlignmentLeft
										  fontName:GAME_DEF_CHINESE_FONT
										  fontSize:20
									  shadowOffset:CGSizeMake(-1.5, -1.5)
										shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(cFixedScale(-160),cFixedScale(150));
	[self addChild:label];
	
//	label = [CCLabelFX labelWithString:@"等级:"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentLeft
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_viewer_level",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentLeft
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(cFixedScale(-160),cFixedScale(120));
	[self addChild:label];
	
//	label = [CCLabelFX labelWithString:@"成员:"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentLeft
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_viewer_member",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentLeft
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(cFixedScale(60),cFixedScale(150));
	[self addChild:label];
	
//	label = [CCLabelFX labelWithString:@"排名:"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentLeft
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_viewer_rank",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentLeft
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(cFixedScale(60),cFixedScale(120));
	[self addChild:label];
    
	////////////////////////////////////////////////////////////////////////////
	
//	label = [CCLabelFX labelWithString:@"成员"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_viewer_member_text",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(cFixedScale(-130),sp.position.y);
	[self addChild:label];
	
//	label = [CCLabelFX labelWithString:@"等级"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_viewer_level_text",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(cFixedScale(-60+30),sp.position.y);
	[self addChild:label];
	
//	label = [CCLabelFX labelWithString:@"职务"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_viewer_duty",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(cFixedScale(10+20),sp.position.y);
	[self addChild:label];
	
//	label = [CCLabelFX labelWithString:@"竞技场排名"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_viewer_arena_rank",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(cFixedScale(120),sp.position.y);
	[self addChild:label];
	
}
-(void)doClose:(id)sender{
	[UnionViewer hide];
}
-(void)onExit{
	[[[CCDirector sharedDirector]touchDispatcher]removeDelegate:self];
	[super onExit];
}

-(void)dealloc{
	unionViewer = nil;
	[super dealloc];

}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	//    if (unionMember && unionMember.visible) {
	//        [unionMember ccTouchBegan:touch withEvent:event];
	//    }
    return YES;
}



@end
