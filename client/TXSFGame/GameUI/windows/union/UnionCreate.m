//
//  UnionCreate.m
//  TXSFGame
//
//  Created by Max on 13-3-14.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionCreate.h"
#import "GameFilter.h"
//
@interface UnionCreateWin : CCLayer<UITextFieldDelegate> {
    //CCLayer * content;
	CCLayer * subContent;
    
    UITextField * inputField;
    id tager;
    SEL call;
}
@property (nonatomic, assign) id tager;
@property (nonatomic, assign) SEL call;
@end
@implementation UnionCreateWin
@synthesize tager;
@synthesize call;
-(void)onEnter{
    [super onEnter];
    inputField = nil;
    subContent = [CCLayer node];
    [self addChild:subContent];
    //
    [self doCreate];
    [[[CCDirector sharedDirector]touchDispatcher]addTargetedDelegate:self priority:-255 swallowsTouches:YES];
}
-(void)onExit{
    [[[CCDirector sharedDirector]touchDispatcher]removeDelegate:self];
    if(inputField){
		[inputField removeFromSuperview];
		[inputField release];
		inputField = nil;
	}
    [super onExit];
}
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	//    if (unionMember && unionMember.visible) {
	//        [unionMember ccTouchBegan:touch withEvent:event];
	//    }
    return YES;
}
-(BOOL)textFieldShouldBeginEditing:(UITextField*)textField{
    
	[subContent stopAllActions];
	[subContent runAction:[CCMoveTo actionWithDuration:0.25 position:ccp(0,cFixedScale(150))]];
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.25];
	inputField.frame = CGRectMake(winSize.width/2-cFixedScale(105),winSize.height/2-cFixedScale(60+150),cFixedScale(210),cFixedScale(25));
	[UIView commitAnimations];
	
	return YES;
}
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
	if(isEmo(string)){
		return NO;
	}
	
	return YES;
}
- (BOOL)textFieldShouldEndEditing:(UITextField*)textField{
    
    [subContent stopAllActions];
	[subContent runAction:[CCMoveTo actionWithDuration:0.25 position:ccp(0,0)]];
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.25];
    
	inputField.frame = CGRectMake(winSize.width/2-cFixedScale(105),winSize.height/2-cFixedScale(60),cFixedScale(210),cFixedScale(25));
	[UIView commitAnimations];
	[inputField resignFirstResponder];
	return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [subContent stopAllActions];
	[subContent runAction:[CCMoveTo actionWithDuration:0.25 position:ccp(0,0)]];
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.25];
	inputField.frame = CGRectMake(winSize.width/2-cFixedScale(105),winSize.height/2-cFixedScale(60),cFixedScale(210),cFixedScale(25));
	[UIView commitAnimations];
	
	[inputField resignFirstResponder];
	
	return YES;
}

-(void)doCreate{
	
	CCSprite * con = [StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(400) height:cFixedScale(300) capx:cFixedScale(8) capy:cFixedScale(8)];
	[subContent addChild:con z:1];
	
	CCSprite * input = [CCSprite spriteWithFile:@"images/ui/panel/input.png"];
	input.position = ccp(0,cFixedScale(50));
	[subContent addChild:input z:100];
	
	CCSprite * sp = [CCSprite spriteWithFile:@"images/ui/panel/p18.png"];
	sp.scaleX = 0.4;
	sp.position = ccp(0,cFixedScale(-60));
	[subContent addChild:sp z:100];
	
	CCSimpleButton * btn1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_create_1.png"
													select:@"images/ui/button/bts_create_2.png"];
	btn1.position = ccp(cFixedScale(-100),cFixedScale(-100));
	if (iPhoneRuningOnGame()) {
		btn1.scale=1.3f;
	}
    
	btn1.target = self;
    btn1.priority = -256;
	btn1.call = @selector(doCreateAction:);
	[subContent addChild:btn1 z:100];
	
	CCSimpleButton * btn2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_cancel_1.png"
													select:@"images/ui/button/bt_cancel_2.png"];
	btn2.position = ccp(cFixedScale(100),cFixedScale(-100));
	btn2.target = self;
    btn2.priority = -256;
	if (iPhoneRuningOnGame()) {
		btn2.scale=1.3f;
	}
    
	btn2.call = @selector(doCreateCancel:);
	[subContent addChild:btn2 z:100];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	inputField = [[UITextField alloc] initWithFrame:CGRectMake(winSize.width/2-cFixedScale(105),winSize.height/2-cFixedScale(60),cFixedScale(210),cFixedScale(25))];
	[inputField setBorderStyle:UITextBorderStyleNone];
	[inputField setFont:[UIFont fontWithName:getCommonFontName(FONT_1) size:cFixedScale(16)]];
	[inputField setText:@""];
	
	inputField.textColor = [UIColor whiteColor];
	inputField.delegate = self;
	
	UIView * view = (UIView*)[CCDirector sharedDirector].view;
	[view addSubview:inputField];
	[inputField becomeFirstResponder];
	
}
-(void)doCreateAction:(CCNode*)sender{
	
	NSString * name = inputField.text;
	//fix chao
	name=[name stringByReplacingOccurrencesOfString:@" " withString:@""];
	NSData *data_l=[name dataUsingEncoding:NSUTF8StringEncoding];
	if(name.length<=0){
		//[ShowItem showItemAct:@"请填入同盟名字"];
        [ShowItem showItemAct:NSLocalizedString(@"union_create_input_name",nil)];
		return;
	}
	if(data_l.length>5*3){
		//[ShowItem showItemAct:[NSString stringWithFormat:@"名字超出%d个字符",5*2]];
		[ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_create_name_over",nil)]];
        //[ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_create_name_over",nil),5*2]];
		return;
	}
	CGSize fontsize=[name sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]];
	if(fontsize.width>90){
		//[ShowItem showItemAct:[NSString stringWithFormat:@"名字禁止使用",5*2]];
		[ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_create_name_no_use",nil)]];
        //[ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_create_name_no_use",nil),5*2]];
		return;
	}
	
	if (![GameFilter validContract:name]) {
		[ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_create_name_no_use",nil)]];
		//[ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_create_name_no_use",nil),5*2]];
		return;
	}
	//end
	if([name length]>0){
		NSString * fm = [NSString stringWithFormat:@"name:%@",name];
        if (tager && call) {
            [GameConnection request:@"allyCreate" format:fm target:tager call:call];
        }else{
            [ShowItem showErrorAct:@"1"];
        }
        [self removeFromParentAndCleanup:YES];
	}
    //
}
-(void)doCreateCancel:(CCNode*)sender{
    [self removeFromParentAndCleanup:YES];
}
@end
//
@implementation UnionCreate

-(void)showUnionList{
	
	[content removeAllChildren];
	
	
	CCSprite *bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(826) height:cFixedScale(480) capx:cFixedScale(8) capy:cFixedScale(8)];
	bg.anchorPoint = ccp(0.5,0.5);
	if(iPhoneRuningOnGame()){
		bg.position = ccp(0, cFixedScale(-40));
	}else{
		bg.position = ccp(0, cFixedScale(-30));
	}
	[content addChild:bg z:-100];
	
	CCSprite * ct = [CCSprite spriteWithFile:@"images/ui/panel/columnTop-1.png"];
	ct.anchorPoint = ccp(0.5,0.5);
	if(iPhoneRuningOnGame()){
		bg.position = ccp(0, cFixedScale(-40));
		ct.position = ccp(0,cFixedScale(180));
	}else{
		bg.position = ccp(0, cFixedScale(-30));
		ct.position = ccp(0,cFixedScale(185));
	}
	ct.scaleX = 1.55;
	[content addChild:ct];
	
//	CCLabelFX * label = [CCLabelFX labelWithString:@"排名"
//										dimensions:CGSizeMake(0,0)
//										 alignment:kCCTextAlignmentCenter
//										  fontName:GAME_DEF_CHINESE_FONT
//										  fontSize:20
//									  shadowOffset:CGSizeMake(-1.5, -1.5)
//										shadowBlur:1.0f];
    CCLabelFX * label = [CCLabelFX labelWithString:NSLocalizedString(@"union_create_rank",nil)
										dimensions:CGSizeMake(0,0)
										 alignment:kCCTextAlignmentCenter
										  fontName:GAME_DEF_CHINESE_FONT
										  fontSize:20
									  shadowOffset:CGSizeMake(-1.5, -1.5)
										shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	if(iPhoneRuningOnGame()){
		label.position = ccp(cFixedScale(-350),cFixedScale(180));
	}else{
		label.position = ccp(cFixedScale(-350),cFixedScale(185));
	}
	[content addChild:label];
	
//	label = [CCLabelFX labelWithString:@"同盟"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_create_union",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	if(iPhoneRuningOnGame()){
		label.position = ccp(cFixedScale(-250),cFixedScale(180));
	}else{
		label.position = ccp(cFixedScale(-250),cFixedScale(185));
	}
	[content addChild:label];
	
//	label = [CCLabelFX labelWithString:@"盟主"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_create_main",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	if(iPhoneRuningOnGame()){
		label.position = ccp(cFixedScale(-120),cFixedScale(180));
	}else{
		label.position = ccp(cFixedScale(-120),cFixedScale(185));
	}
	[content addChild:label];
	
//	label = [CCLabelFX labelWithString:@"同盟等级"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_create_union_level",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	if(iPhoneRuningOnGame()){
		label.position = ccp(cFixedScale(50),cFixedScale(180));
	}else{
		label.position = ccp(cFixedScale(50),cFixedScale(185));
	}
	[content addChild:label];
	
//	label = [CCLabelFX labelWithString:@"人数"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_create_people",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	if(iPhoneRuningOnGame()){
		label.position = ccp(cFixedScale(180),cFixedScale(180));
	}else{
		label.position = ccp(cFixedScale(180),cFixedScale(185));
	}
	[content addChild:label];
	
//	label = [CCLabelFX labelWithString:@"操作"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_create_operate",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	if(iPhoneRuningOnGame()){
		label.position = ccp(cFixedScale(305),cFixedScale(180));
	}else{
		label.position = ccp(cFixedScale(305),cFixedScale(185));
	}
	[content addChild:label];
	
	NSDictionary * ally = [[GameConfigure shared] getPlayerAlly];
	if(ally==NULL){
		CCSimpleButton * create = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_create_1.png"
														  select:@"images/ui/button/bts_create_2.png"];
		create.position = ccp(cFixedScale(-340),cFixedScale(240));
		create.target = self;
		create.call = @selector(doCreate:);
		if (iPhoneRuningOnGame()) {
			create.scale=1.2f;
			create.position = ccp(cFixedScale(-340),cFixedScale(230));
		}
		[content addChild:create];
	}else{
		CCSimpleButton * create = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_return_1.png"
														  select:@"images/ui/button/bt_return_2.png"];
		create.position = ccp(cFixedScale(-340),cFixedScale(240));
		create.target = self;
		if (iPhoneRuningOnGame()) {
			create.scale=1.2f;
			create.position = ccp(cFixedScale(-340),cFixedScale(230));
		}

		create.call = @selector(doReturn:);
		[content addChild:create];
	}
	tmp_page = 1;
	tmp_count = 0;
	[self getUnionList];
}
//
-(void)doCreate:(CCNode*)sender{
    int win_tag = 1101;
    UnionCreateWin *unionCreateWin = (UnionCreateWin *)[self getChildByTag:win_tag];
    if (unionCreateWin) {
        [self removeChildByTag:win_tag cleanup:YES];
        unionCreateWin = nil;
    }
    unionCreateWin = [UnionCreateWin node];
    unionCreateWin.tager = self;
    unionCreateWin.call = @selector(didCreate:);
    [self addChild:unionCreateWin z:200 tag:win_tag];
}

//
#pragma mark 获取
-(void)getUnionList{
	NSString * fm = [NSString stringWithFormat:@"page::%d",tmp_page];
	[GameConnection request:@"allyAllyList" format:fm target:self call:@selector(didGetUnionList:)];
}

-(void)didGetUnionList:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSArray * list = getResponseData(response);
		[self showUnionList:list];
	}else{
		
	}
}

-(void)showUnionList:(NSArray*)ary{
	
	//[unionPanel hideLoading];
	
	int count = [ary count];
	if(count==0) return;
	if(count<6){
		tmp_page = -1;
	}
	
	[alls addObjectsFromArray:ary];
	
	CCLayerColor * cc;
	CCLayerColor * li;
	CCPanel * cp = (CCPanel*)[content getChildByTag:101];
	if(!cp){
		cc = [CCLayerColor layerWithColor:ccc4(255,0,0,0) width:cFixedScale(820) height:cFixedScale(430)];
		li = [CCLayerColor layerWithColor:ccc4(0,0,0,0) width:cFixedScale(100) height:0];
		li.anchorPoint = ccp(0,1);
		li.tag = 103;
		[cc addChild:li];
		
		cp = [CCPanel panelWithContent:cc viewSize:CGSizeMake(cFixedScale(820),cFixedScale(430))];
		cp.tag = 101;
		cp.position = ccp(cFixedScale(-410),cFixedScale(-265));
		[content addChild:cp z:100];
		
	}else{
		cc = (CCLayerColor*)[cp getContent];
		li = (CCLayerColor*)[cc getChildByTag:103];
	}
	
	cc.contentSize = CGSizeMake(cFixedScale(820), cFixedScale(60)*(count+tmp_count+(tmp_page>=0?1:0)));
	if(cc.contentSize.height<cFixedScale(430)){
		cc.contentSize = CGSizeMake(cFixedScale(820), cFixedScale(430));
	}
	li.position = ccp(0,cc.contentSize.height);
	
	NSDictionary * ally = [[GameConfigure shared] getPlayerAlly];
	int hight=0;
	for(int i=0;i<count;i++){
		CCSprite * m = [CCSprite spriteWithFile:@"images/ui/panel/p14-1.png"];
		m.anchorPoint = ccp(0,1);
		if (iPhoneRuningOnGame()) {
			m.position = ccp(cFixedScale(4),(cFixedScale(-60)*tmp_count)-cFixedScale(60)*i-cFixedScale(6));
		}else{
			m.position = ccp(cFixedScale(4),(cFixedScale(-60)*tmp_count)-cFixedScale(60)*i-cFixedScale(3));
		}
		[li addChild:m];
		
		NSDictionary * info = [ary objectAtIndex:i];
		bool isPin=[[info objectForKey:@"pin"]integerValue];
		CCLabelFX * label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d",[[info objectForKey:@"rank"] intValue]]
											dimensions:CGSizeMake(0,0)
											 alignment:kCCTextAlignmentCenter
											  fontName:GAME_DEF_CHINESE_FONT
											  fontSize:20
										  shadowOffset:CGSizeMake(-1.5, -1.5)
											shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(cFixedScale(55),cFixedScale(25));
		[m addChild:label];
		
		label = [CCLabelFX labelWithString:[info objectForKey:@"n"]
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:GAME_DEF_CHINESE_FONT
								  fontSize:20
							  shadowOffset:CGSizeMake(-1.5, -1.5)
								shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(cFixedScale(155),cFixedScale(25));
		[m addChild:label];
		
		NSString *pnstr=[NSString stringWithFormat:@"%@",[info objectForKey:@"pn"]];
		label = [CCLabelFX labelWithString:pnstr
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:GAME_DEF_CHINESE_FONT
								  fontSize:20
							  shadowOffset:CGSizeMake(-1.5, -1.5)
								shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(cFixedScale(285),cFixedScale(25));
		[m addChild:label];
		
		label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d",[[info objectForKey:@"lv"] intValue]]
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:GAME_DEF_CHINESE_FONT
								  fontSize:20
							  shadowOffset:CGSizeMake(-1.5, -1.5)
								shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(cFixedScale(460),cFixedScale(25));
		[m addChild:label];
		
		label = [CCLabelFX labelWithString:[NSString stringWithFormat:@"%d",[[info objectForKey:@"c"] intValue]]
								dimensions:CGSizeMake(0,0)
								 alignment:kCCTextAlignmentCenter
								  fontName:GAME_DEF_CHINESE_FONT
								  fontSize:20
							  shadowOffset:CGSizeMake(-1.5, -1.5)
								shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(cFixedScale(585),cFixedScale(25));
		[m addChild:label];
		
		if(ally==nil && !isPin){
			
			CCSimpleButton * b1 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_add_1.png"
														  select:@"images/ui/button/bts_add_2.png"];
			b1.tag = [[info objectForKey:@"aid"] intValue];
			b1.position = ccp(cFixedScale(670),cFixedScale(25));
			b1.target = self;
			if (iPhoneRuningOnGame()) {
				b1.scale=1.2f;
			}

			b1.call = @selector(doAdd:);
			[m addChild:b1];
			
		}
		
		CCSimpleButton * b2 = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_view_1.png"
													  select:@"images/ui/button/bts_view_2.png"];
		b2.tag = [[info objectForKey:@"aid"] intValue];
		if (iPhoneRuningOnGame()) {
			b2.scale=1.2f;
		}

		if(ally || isPin){
			b2.position = ccp(cFixedScale(710),cFixedScale(25));
		}else{
			b2.position = ccp(cFixedScale(760),cFixedScale(25));
		}
		
		b2.target = self;
		b2.call = @selector(doView:);
		[m addChild:b2];
		hight=i;
	}
	
	if(tmp_page>=0){
		CCSimpleButton * next = [CCSimpleButton spriteWithFile:@"images/ui/panel/p14-1.png"];
		next.anchorPoint = ccp(0,1);
		next.position = ccp(4,(cFixedScale(-60)*tmp_count)-cFixedScale(60)*(hight+1)-cFixedScale(3));
		next.target = self;
		next.call = @selector(doNext:);
		[li addChild:next];
//		CCLabelFX * label = [CCLabelFX labelWithString:@"查看更多..."
//											dimensions:CGSizeMake(0,0)
//											 alignment:kCCTextAlignmentCenter
//											  fontName:GAME_DEF_CHINESE_FONT
//											  fontSize:20
//										  shadowOffset:CGSizeMake(-1.5, -1.5)
//											shadowBlur:1.0f];
        CCLabelFX * label = [CCLabelFX labelWithString:NSLocalizedString(@"union_create_more",nil)
											dimensions:CGSizeMake(0,0)
											 alignment:kCCTextAlignmentCenter
											  fontName:GAME_DEF_CHINESE_FONT
											  fontSize:20
										  shadowOffset:CGSizeMake(-1.5, -1.5)
											shadowBlur:1.0f];
		label.anchorPoint = ccp(0.5,0.5);
		label.position = ccp(cFixedScale(400),cFixedScale(25));
		[next addChild:label];
	}
	if(tmp_count==0) [cp updateContentToTop];
	tmp_count += count;
	[cp showScrollBar:@"images/ui/common/scroll3.png"];
}

-(void)doReturn:(id)sender{
	[[UnionPanel share]getUnionInfo];
}

-(void)didCreate:(NSDictionary*)response{
	if(checkResponseStatus(response)){
        NSDictionary *dict = getResponseData(response);
        [[GameConfigure shared] updatePackage:dict];
		[[UnionPanel share] getUnionInfo];
	}else{
		CCLOG(@"Create error");
        [ShowItem showErrorAct:getResponseMessage(response)];
        //[ShowItem showItemAct:@"创建同盟失败!"];
        [ShowItem showItemAct:NSLocalizedString(@"union_create_fail",nil)];
	}
}


-(void)doAdd:(CCNode*)sender{
	if(sender.tag>0){
		CCLOG(@"view %d", sender.tag);
		
		NSString * fm = [NSString stringWithFormat:@"aid::%d",sender.tag];
		//[GameConnection request:@"allyApply" format:fm target:self call:@selector(didAdd:)];
		[GameConnection request:@"allyApply" format:fm target:nil call:nil];
        //[ShowItem showItemAct:@"已申请，请等待审核通过"];
        [ShowItem showItemAct:NSLocalizedString(@"union_create_wait_check",nil)];
	}
}
-(void)didAdd:(NSDictionary*)response{
	CCPanel * cp = (CCPanel*)[content getChildByTag:101];
	if(!cp.isTouchValid)return;
	if(checkResponseStatus(response)){
		if([getResponseFunc(response) isEqualToString:@"allyApply"]){
			//[ShowItem showItemAct:@"申请成功，请待审核通过"];
            [ShowItem showItemAct:NSLocalizedString(@"union_create_wait_check_2",nil)];
		}
	}else{
		[ShowItem showErrorAct:getResponseMessage(response)];
		CCLOG(@"Error add");
	}
}
//查看
-(void)doView:(CCNode*)sender{
	CCPanel * cp = (CCPanel*)[content getChildByTag:101];
	if(!cp.isTouchValid)return;
	if(sender.tag>0){
		CCLOG(@"view %d", sender.tag);
		
		for(NSDictionary * n in alls){
			if([[n objectForKey:@"aid"] intValue]==sender.tag){
				[UnionViewer show:n];
				return;
			}
		}
		
	}
}
-(void)doNext:(CCNode*)sender{
	CCPanel * cp = (CCPanel*)[content getChildByTag:101];
	if(!cp.isTouchValid)return;
	if(sender) [sender removeFromParentAndCleanup:YES];
	
	if(tmp_page>=0){
		tmp_page++;
		[self getUnionList];
	}
	
}

#pragma mark UnionCreate onEnter
-(void)onEnter{
	[super onEnter];
	
	alls = [[NSMutableArray alloc] init];
	
	content = [CCLayer node];
	[self addChild:content z:100];
	
	
	[self showUnionList];
	
}
-(void)onExit{
	
	if(alls){
		[alls release];
		alls = nil;
	}
	
	
	[super onExit];
	
}



@end
