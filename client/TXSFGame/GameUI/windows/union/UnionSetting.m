//
//  UnionSetting.m
//  TXSFGame
//
//  Created by peak on 13-4-18.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionSetting.h"
#import "UnionPanel.h"
#import "UnionMember.h"

#pragma mark UnionSetting onEnter
static UnionSetting * unionSetting;
@implementation UnionSetting
+(void)setStaticUnionSettingNil{
    unionSetting = nil;
}
+(void)show{
	[UnionSetting hide];
    UnionPanel *unionPanel = [UnionPanel getUnionPanel];
	if(unionPanel){
		unionSetting = [UnionSetting node];
		[unionPanel addChild:unionSetting z:9000];
	}
}
+(void)hide{
	if(unionSetting){
		[unionSetting removeFromParentAndCleanup:YES];
		unionSetting = nil;
	}
}

-(id) init
{
	if (self = [super init]) {
		[self setTouchEnabled:YES];
	}
	return self;
}

-(void) registerWithTouchDispatcher
{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority-126 swallowsTouches:YES];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	if(postInput){
		[postInput resignFirstResponder];
	}
	if(infoInput){
		[infoInput resignFirstResponder];
	}
	return YES;
}

-(void)onEnter{
	[super onEnter];
	UnionPanel *unionPanel = [UnionPanel getUnionPanel];
	NSDictionary * ally = unionPanel.info;
	if(!ally){
		[UnionSetting hide];
		return;
	}
	
	self.position = ccpAdd(ccp(0,cFixedScale(-15)),
						   ccp([UnionPanel share].contentSize.width/2,[UnionPanel share].contentSize.height/2));
	
	CCSprite * bg = [CCSprite spriteWithFile:@"images/ui/panel/p2.png"];
	[self addChild:bg];
	
	bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(400) height:cFixedScale(480) capx:cFixedScale(8) capy:cFixedScale(8)];
	bg.anchorPoint = ccp(0.5,0.5);
	bg.position = ccp(0,cFixedScale(-30));
	[self addChild:bg];
	
	CCSimpleButton * btn = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"];
	btn.position = ccp(cFixedScale(170),cFixedScale(240));
	btn.target = self;
	btn.call = @selector(doClose:);
	btn.priority=-300;
	[self addChild:btn];
	
	btn = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_pass_1.png"
								  select:@"images/ui/button/bts_pass_2.png"
								  target:self
									call:@selector(doSave:)
								priority:-255
		   ];
	if (iPhoneRuningOnGame()) {
		btn.scale=1.3f;
	}
	btn.position = ccp(0,cFixedScale(-240));
	[self addChild:btn];
    
	CCSprite * sp = [CCSprite spriteWithFile:@"images/ui/panel/columnTop.png"];
	sp.scaleX = cFixedScale(380)/sp.contentSize.width;
	sp.position = ccp(0,cFixedScale(185));
	[self addChild:sp];
	
	sp = [CCSprite spriteWithFile:@"images/ui/panel/columnTop.png"];
	sp.scaleX = cFixedScale(380)/sp.contentSize.width;
	sp.position = ccp(0,cFixedScale(-20));
	[self addChild:sp];
	
	////////////////////////////////////////////////////////////////////////////
	
	CCLabelFX * label;
//	label = [CCLabelFX labelWithString:@"公告"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_setting_bulletin",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(0,cFixedScale(185));
	[self addChild:label];
	
//	label = [CCLabelFX labelWithString:@"介绍"
//							dimensions:CGSizeMake(0,0)
//							 alignment:kCCTextAlignmentCenter
//							  fontName:GAME_DEF_CHINESE_FONT
//							  fontSize:20
//						  shadowOffset:CGSizeMake(-1.5, -1.5)
//							shadowBlur:1.0f];
    label = [CCLabelFX labelWithString:NSLocalizedString(@"union_setting_intro",nil)
							dimensions:CGSizeMake(0,0)
							 alignment:kCCTextAlignmentCenter
							  fontName:GAME_DEF_CHINESE_FONT
							  fontSize:20
						  shadowOffset:CGSizeMake(-1.5, -1.5)
							shadowBlur:1.0f];
	label.anchorPoint = ccp(0.5,0.5);
	label.position = ccp(0,cFixedScale(-20));
	[self addChild:label];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	if (iPhoneRuningOnGame()) {
		postInput = [[UITextView alloc] initWithFrame:CGRectMake(winSize.width/2-cFixedScale(380)/2,winSize.height/2-cFixedScale(135),cFixedScale(380),cFixedScale(160))];
		infoInput = [[UITextView alloc] initWithFrame:CGRectMake(winSize.width/2-cFixedScale(380)/2,winSize.height/2+cFixedScale(70),cFixedScale(380),cFixedScale(160))];
	}else{
		postInput = [[UITextView alloc] initWithFrame:CGRectMake(winSize.width/2-cFixedScale(380)/2,winSize.height/2-cFixedScale(150),cFixedScale(380),cFixedScale(160))];
		infoInput = [[UITextView alloc] initWithFrame:CGRectMake(winSize.width/2-cFixedScale(380)/2,winSize.height/2+cFixedScale(55),cFixedScale(380),cFixedScale(160))];
	}
    //postInput.text=[NSString stringWithFormat: @"公告不能超出 %d 个字符",90*2];
    postInput.text=[NSString stringWithFormat: NSLocalizedString(@"union_setting_bulletin_over",nil),90*2];
	postInput.font = [UIFont fontWithName:getCommonFontName(FONT_1) size:cFixedScale(16)];
	postInput.backgroundColor = [UIColor clearColor];
	postInput.textColor = [UIColor whiteColor];
    //	[postInput setBackgroundColor:[UIColor redColor]];
	postInput.text = [ally objectForKey:@"post"];
	postInput.delegate = self;
	
	infoInput.font = [UIFont fontWithName:getCommonFontName(FONT_1) size:cFixedScale(16)];
	infoInput.backgroundColor = [UIColor clearColor];
	infoInput.textColor = [UIColor whiteColor];
	infoInput.text = [ally objectForKey:@"info"];
	infoInput.delegate = self;
    //	[infoInput setBackgroundColor:[UIColor redColor]];
	
	UIView * view = (UIView*)[CCDirector sharedDirector].view;
	[view addSubview:postInput];
	[view addSubview:infoInput];
	
	//[postInput becomeFirstResponder];
	//[infoInput becomeFirstResponder];
	
}
-(void)onExit{
	
	if(postInput){
		[postInput removeFromSuperview];
		[postInput release];
		postInput = nil;
	}
	if(infoInput){
		[infoInput removeFromSuperview];
		[infoInput release];
		infoInput = nil;
	}
	
	[super onExit];
	
}
-(void)doClose:(id)sender{
	[UnionSetting hide];
}
-(void)doSave:(id)sender{
	if(isChange){
        //fix chao
        NSData *postdata_l=[postInput.text dataUsingEncoding:NSUTF8StringEncoding];
        if(postdata_l.length>90*3){
            //[ShowItem showItemAct:[NSString stringWithFormat: @"公告不能超出 %d 个字符",90*2]];
            [ShowItem showItemAct:[NSString stringWithFormat: NSLocalizedString(@"union_setting_bulletin_over",nil),90*2]];
            return;
        }
        
        NSData *infodata_l=[infoInput.text dataUsingEncoding:NSUTF8StringEncoding];
        if(infodata_l.length>25*3){
            //[ShowItem showItemAct:[NSString stringWithFormat: @"介绍不能超出 %d 个字符",25*2]];
            [ShowItem showItemAct:[NSString stringWithFormat: NSLocalizedString(@"union_setting_intro_over",nil),25*2]];
            return;
        }
        //end
		NSMutableDictionary * d = [NSMutableDictionary dictionary];
		[d setObject:postInput.text forKey:@"ct"];
		[d setObject:infoInput.text forKey:@"inf"];
		
		[GameConnection request:@"allyCPost" data:d target:self call:@selector(didSavePost:)];
	}else{
        [self doClose:sender];
    }
}

-(void)didSavePost:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
	}else{
		CCLOG(@"Error allyCPost");
	}
    UnionPanel *unionPanel = [UnionPanel getUnionPanel];
	[unionPanel updatePost:postInput.text info:infoInput.text];
	[UnionSetting hide];
}

-(void)textViewDidChange:(UITextView*)textView{
	isChange = YES;
}

-(void)textViewDidBeginEditing:(UITextView*)textView{
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	if(textView==postInput){
		
		CGPoint pt = ccpAdd(ccp(0,cFixedScale(100)), ccp([UnionPanel share].contentSize.width/2,[UnionPanel share].contentSize.height/2));
        [self stopAllActions];
		[self runAction:[CCMoveTo actionWithDuration:0.25 position:pt]];
		
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.25];
		postInput.frame = CGRectMake(winSize.width/2-cFixedScale(380)/2,winSize.height/2-cFixedScale(150+115),cFixedScale(380),cFixedScale(160));
		infoInput.frame = CGRectMake(winSize.width/2-cFixedScale(380)/2,winSize.height/2+cFixedScale(55-115),cFixedScale(380),cFixedScale(160));
		[UIView commitAnimations];
		
	}
	if(textView==infoInput){
		CGPoint pt;
        [self stopAllActions];
		if (iPhoneRuningOnGame()) {
			pt = ccpAdd(ccp(0,cFixedScale(210)), ccp([UnionPanel share].contentSize.width/2,[UnionPanel share].contentSize.height/2));
			[self runAction:[CCMoveTo actionWithDuration:0.25 position:pt]];
		}else{
			pt = ccpAdd(ccp(0,cFixedScale(250)), ccp([UnionPanel share].contentSize.width/2,[UnionPanel share].contentSize.height/2));
			[self runAction:[CCMoveTo actionWithDuration:0.25 position:pt]];
		}
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.25];
		if (iPhoneRuningOnGame()) {
			postInput.frame = CGRectMake(winSize.width/2-cFixedScale(380)/2,winSize.height/2-cFixedScale(160+217),cFixedScale(380),cFixedScale(160));
			infoInput.frame =CGRectMake(winSize.width/2-cFixedScale(380)/2,postInput.frame.origin.y+80+47/2.0f,cFixedScale(380),cFixedScale(160));
		}else{
			postInput.frame = CGRectMake(winSize.width/2-cFixedScale(380)/2,winSize.height/2-cFixedScale(150+265),cFixedScale(380),cFixedScale(160));
			infoInput.frame = CGRectMake(winSize.width/2-cFixedScale(380)/2,winSize.height/2+cFixedScale(55-265),cFixedScale(380),cFixedScale(160));
		}
		[UIView commitAnimations];
	}
	
}
-(void)textViewDidEndEditing:(UITextView*)textView{
	
	CGPoint pt = ccpAdd(ccp(0,cFixedScale(-15)), ccp([UnionPanel share].contentSize.width/2,[UnionPanel share].contentSize.height/2));
    [self stopAllActions];
	[self runAction:[CCMoveTo actionWithDuration:0.25 position:pt]];
	
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.25];
	postInput.frame = CGRectMake(winSize.width/2-cFixedScale(380)/2,winSize.height/2-cFixedScale(150),cFixedScale(380),cFixedScale(160));
	infoInput.frame = CGRectMake(winSize.width/2-cFixedScale(380)/2,winSize.height/2+cFixedScale(55),cFixedScale(380),cFixedScale(160));
	[UIView commitAnimations];
	
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
	if (text.length<=0) {
		return YES;
	}
	if (iPhoneRuningOnGame()) {
	if (textView==infoInput) {
		NSData *infodata_l=[textView.text dataUsingEncoding:NSUTF8StringEncoding];
		if(infodata_l.length>25*3){
			//				[ShowItem showItemAct:[NSString stringWithFormat: @"介绍不能超出 %d 个字符",25*2]];
			return NO;
		}
	}
	}
	if(isEmo(text)){
		return NO;
	}
	return YES;
}

@end

#pragma mark- UnionDisbandSetting
#define select_start_tag (12345)
#define UDS_text_size (22)
//
@interface UnionDisbandMenu:CCMenu
-(void) registerWithTouchDispatcher;
@end
@implementation UnionDisbandMenu
-(void) registerWithTouchDispatcher{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:-300 swallowsTouches:YES];
}
@end
@interface UnionArrayNode:CCNode{
    CCMenuItemToggle *btt_toggle;
    NSString *dutyName;
}
@property (nonatomic,retain)CCMenuItemToggle *btt_toggle;
@property (nonatomic,retain)NSString *dutyName;
@end
@implementation UnionArrayNode
@synthesize btt_toggle;
@synthesize dutyName;
@end
//
@implementation UnionDisbandSetting
static UnionDisbandSetting *s_unionDisbandSetting=nil;
@synthesize select_index;
@synthesize memberID;
@synthesize playerDuty;
@synthesize playerName;
/*
+(void)show{
	[UnionSetting hide];
    //
    UnionPanel *unionPanel = [UnionPanel getUnionPanel];
	if(unionPanel){
        if (s_unionDisbandSetting) {
            [UnionDisbandSetting hide];
        }
		s_unionDisbandSetting = [UnionDisbandSetting node];
		[unionPanel addChild:s_unionDisbandSetting z:9000];
	}
}
 */
+(void)showWithID:(int)member_id name:(NSString*)name duty:(int)duty{
    [UnionSetting hide];
    //
    UnionPanel *unionPanel = [UnionPanel getUnionPanel];
	if(unionPanel){
        if (s_unionDisbandSetting) {
            [UnionDisbandSetting hide];
        }
		s_unionDisbandSetting = [UnionDisbandSetting node];
        s_unionDisbandSetting.memberID = member_id;
        [s_unionDisbandSetting setPlayerName:name];
        s_unionDisbandSetting.playerDuty = duty;
		[unionPanel addChild:s_unionDisbandSetting z:9000];
	}
}
+(void)hide{
	if(s_unionDisbandSetting){
		[s_unionDisbandSetting removeFromParentAndCleanup:YES];
		s_unionDisbandSetting = nil;
	}
}
-(id)init{
    if ((self = [super init])!=nil) {
        menu = nil;
        select_index = 0;
        memberID = 0;
        playerDuty = 0;
        playerName = nil;
        select_array = nil;
    }
    return self;
}
-(void)onEnter{
	[super onEnter];

    //
    menu = [UnionDisbandMenu menuWithItems:nil];
	menu.ignoreAnchorPointForPosition = YES;
    menu.position = CGPointZero;
	[self addChild:menu z:3];
    //
	self.position = ccpAdd(ccp(0,cFixedScale(-15)),
						   ccp([UnionPanel share].contentSize.width/2,[UnionPanel share].contentSize.height/2));
	
	CCSprite * bg = [CCSprite spriteWithFile:@"images/ui/panel/p2.png"];
    self.contentSize = bg.contentSize;
	[self addChild:bg];
	
	bg = [StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(400) height:cFixedScale(480) capx:cFixedScale(8) capy:cFixedScale(8)];
	bg.anchorPoint = ccp(0.5,0.5);
	bg.position = ccp(0,cFixedScale(-30));
	[self addChild:bg];
    CCSimpleButton * btn = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"];
	btn.position = ccp(cFixedScale(170),cFixedScale(240));
	btn.target = self;
	btn.call = @selector(doClose:);
	btn.priority=-300;
	[self addChild:btn];
    //
    select_array = [NSMutableArray array];
    [select_array retain];
    //
    UnionPanel *unionPanel = [UnionPanel getUnionPanel];
     NSDictionary * group = nil;
    if (unionPanel) {
        group = unionPanel.info;
    }
    
    int duty = [[group objectForKey:@"duty"] intValue];
    NSArray *str_arr = [self getStringArrayWithDuty:duty];
    int x = cFixedScale(10);
    int y = 0;
    int tag = 0;
    NSArray *spr_arr = nil;
    for (NSString *str in str_arr) {
        if (str) {
            spr_arr = [self getSpriteWithString:str];
            tag = [self getTagWithString:str];
            if (tag>=select_start_tag) {

                CCMenuItemSprite *bt_spr01 = [CCMenuItemSprite itemWithNormalSprite:[spr_arr objectAtIndex:0] selectedSprite:nil];
                CCMenuItemSprite *bt_spr02 = [CCMenuItemSprite itemWithNormalSprite:[spr_arr objectAtIndex:1] selectedSprite:nil];
                CCMenuItemToggle *btt_toggle = [CCMenuItemToggle itemWithTarget:self selector:@selector(menuCallbackBack:) items:bt_spr01,bt_spr02, nil];
                [menu addChild:btt_toggle z:0 tag:tag];
                btt_toggle.position = ccp(x,y);
                //
                UnionArrayNode *arrNode = [UnionArrayNode node];
                arrNode.btt_toggle = btt_toggle;
                arrNode.dutyName = str;
                [select_array addObject:arrNode];
                //[select_array addObject:btt_toggle];
                y += cFixedScale(UDS_text_size+UDS_text_size/2);
            }
        }
    }
    //
    select_index = [self getIndexWithDuty:playerDuty];
    [self selectWithIndex:select_index];
    //
    if (playerName) {
        CCLabelTTF *label = [CCLabelTTF labelWithString:playerName fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(20) ];
        if (label) {
            [self addChild:label];
            label.position = ccp(cFixedScale(-100),cFixedScale(-100));
            label.color = ccYELLOW;
        }
    }

    //
    NSArray *sprArrYes = getBtnSpriteWithStatus(@"images/ui/button/bt_ok");
    CCMenuItemSprite *bt_yes = [CCMenuItemSprite itemWithNormalSprite:[sprArrYes objectAtIndex:0] selectedSprite:[sprArrYes objectAtIndex:1] target:self selector:@selector(menuCallbackForYes:)];
    [menu addChild:bt_yes];
    bt_yes.position = ccp(-(self.contentSize.width/4),-self.contentSize.height/2+bt_yes.contentSize.height);
    //
    NSArray *sprArrNo = getBtnSpriteWithStatus(@"images/ui/button/bt_cancel");
    CCMenuItemSprite *bt_no = [CCMenuItemSprite itemWithNormalSprite:[sprArrNo objectAtIndex:0] selectedSprite:[sprArrNo objectAtIndex:1] target:self selector:@selector(doClose:)];
    [menu addChild:bt_no];
    bt_no.position = ccp((self.contentSize.width/4),-self.contentSize.height/2+bt_no.contentSize.height);
    //
    [self setTouchEnabled:YES];
}
-(void)menuCallbackForYes:(id)sender{
    if (playerName) {
        [[AlertManager shared]showMessage:[NSString stringWithFormat:NSLocalizedString(@"union_setting_sure_change_duty",nil),playerName,getJobName([self getDutyWithIndex:select_index])] target:self confirm:@selector(changeDuty) canel:nil];
    }else{
        CCLOG(@"player name is nil");
    }

}
-(int)getDutyWithIndex:(int)index{
    if ( index>=0 && index<[select_array count]) {
        //CCMenuItem *btt_toggle = [select_array objectAtIndex:index];
        CCMenuItem *btt_toggle = [[select_array objectAtIndex:index] btt_toggle];
        if (btt_toggle) {
            int tag = btt_toggle.tag-select_start_tag;
            switch (tag) {
                case UnionDuty_main:{return  UnionDuty_main;} break;
                case UnionDuty_vice:{return  UnionDuty_vice;} break;
                case UnionDuty_elder:{return  UnionDuty_elder;} break;
                case UnionDuty_bodyGuard:{return  UnionDuty_bodyGuard;} break;
                case UnionDuty_diaphysis:{return  UnionDuty_diaphysis;} break;
                case UnionDuty_member:{return  UnionDuty_member;} break;
            }
        }
    }
    return 0;
}

-(int)getIndexWithDuty:(int)duty{
    int index = 0;
    NSString *nameStr = nil;
    //
    if ( duty>=UnionDuty_main && duty<=UnionDuty_member) {
        nameStr = [self getStringWithDuty:duty];
        if (nameStr) {
            for (UnionArrayNode *arrNode in select_array) {
                if ([arrNode dutyName] && [nameStr isEqualToString:[arrNode dutyName]]) {
                    return index;
                }
                index++;
            }
        }
    }
    return -1;
}
-(void)changeDuty{
    int duty = [self getDutyWithIndex:select_index];
    if (duty>=UnionDuty_main && duty<=UnionDuty_member) {
        if (memberID>0) {
            [self confirmSetWithDuty:duty playerID:memberID];
        }else{
            CCLOG(@"player id is error");
        }
    }else{
        CCLOG(@"duty is error");
    }
}
//设置
-(void)confirmSetWithDuty:(int)duty_ playerID:(int)player_id{
    [GameConnection request:@"allyCDuty" format:[NSString stringWithFormat:@"pid::%i|duty::%i",player_id,duty_] target:self call:@selector(didconfirmSetMember:)];
}
//任职回调
-(void)didconfirmSetMember:(NSDictionary*)data{
	if(checkResponseStatus(data)){
        UnionMember *unionMember = [UnionMember getUnionMember];
        if (unionMember) {
            [GameConnection request:@"allyMembers" format:@"" target:unionMember  call:@selector(didGetAllyMambers:)];
        }
		[ShowItem showItemAct:NSLocalizedString(@"union_setting_ok",nil)];
        //
        [UnionDisbandSetting hide];
	}else{
        [ShowItem showErrorAct:getResponseMessage(data)];
    }
}
//
-(int)getIndexWithTag:(int)tag{
    int index = 0;
    //for (CCMenuItem *btt_toggle in select_array) {
    for (UnionArrayNode *arrNode in select_array) {
        CCMenuItem *btt_toggle = [arrNode btt_toggle];
        if (btt_toggle.tag == tag) {
            return index;
        }
        index++;
    }
    return -1;
}
-(void)menuCallbackBack:(id)sender{
    CCNode *node = sender;
    [self selectWithIndex:[self getIndexWithTag:[node tag]]];

}
-(int)getTagWithString:(NSString*)str{
    int tag=0;
    if (str) {
        if ([str isEqualToString:NSLocalizedString(@"union_config_main",nil)]) {
            tag = select_start_tag + UnionDuty_main;
        }else if ([str isEqualToString:NSLocalizedString(@"union_config_vice",nil)]) {
            tag = select_start_tag + UnionDuty_vice;
        }else if ([str isEqualToString:NSLocalizedString(@"union_config_elder",nil)]) {
            tag = select_start_tag + UnionDuty_elder;
        }else if ([str isEqualToString:NSLocalizedString(@"union_config_body_guard",nil)]) {
            tag = select_start_tag + UnionDuty_bodyGuard;
        }else if ([str isEqualToString:NSLocalizedString(@"union_config_diaphysis",nil)]) {
            tag = select_start_tag + UnionDuty_diaphysis;
        }else if ([str isEqualToString:NSLocalizedString(@"union_config_member",nil)]) {
            tag = select_start_tag + UnionDuty_member;
        }
    }
    return tag;
}
-(NSString*)getStringWithDuty:(UnionDuty)duty_{
    NSString *str = nil;
    str = getJobName(duty_);
    if ([str length]>0) {
        return str;
    }
    return nil;
}
-(NSString*)getStringWithAllayLevelDict:(NSDictionary*)allayLevelDict_ duty:(UnionDuty)duty_{
    if (allayLevelDict_) {
        if ([allayLevelDict_ objectForKey:[NSString stringWithFormat:@"dt%dNum",duty_]]&&
            [[allayLevelDict_ objectForKey:[NSString stringWithFormat:@"dt%dNum",duty_]] intValue]>0) {
            return [self getStringWithDuty:duty_];
        }
    }
    return nil;
}
-(NSArray*)getStringArrayWithDuty:(int)duty{
    NSMutableArray *array=[NSMutableArray array];
    UnionPanel *unionPanel = [UnionPanel getUnionPanel];
    NSDictionary * group = unionPanel.info;
    if (group && [group objectForKey:@"level"]) {
        int level = [[group objectForKey:@"level"] intValue];
        NSDictionary *allayLevelDict = [[GameDB shared] getAllyLevel:level];
        if (allayLevelDict) {
            if (duty == UnionDuty_main || duty == UnionDuty_vice) {
                NSString *dutyStr = nil;
                //
                if (duty == UnionDuty_main) {
                    dutyStr = [self getStringWithAllayLevelDict:allayLevelDict duty:UnionDuty_main];
                    if (dutyStr) {
                        [array addObject:dutyStr];
                    }
                }
                //
                dutyStr = [self getStringWithAllayLevelDict:allayLevelDict duty:UnionDuty_vice];
                if (dutyStr) {
                    [array addObject:dutyStr];
                }
                //
                dutyStr = [self getStringWithAllayLevelDict:allayLevelDict duty:UnionDuty_elder];
                if (dutyStr) {
                    [array addObject:dutyStr];
                }
                //
                dutyStr = [self getStringWithAllayLevelDict:allayLevelDict duty:UnionDuty_bodyGuard];
                if (dutyStr) {
                    [array addObject:dutyStr];
                }
                //
                dutyStr = [self getStringWithAllayLevelDict:allayLevelDict duty:UnionDuty_diaphysis];
                if (dutyStr) {
                    [array addObject:dutyStr];
                }
                //
                dutyStr = [self getStringWithAllayLevelDict:allayLevelDict duty:UnionDuty_member];
                if (dutyStr) {
                    [array addObject:dutyStr];
                }
            }
        }
    }
    return array;
}
-(NSArray*)getSpriteWithString:(NSString*)name{
    NSMutableArray *array=nil;
    if (name) {
        array = [NSMutableArray array];
        int size = UDS_text_size;
        CCLabelTTF *labelNormal = [CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(size) ];
        if (labelNormal) {
            [array addObject:labelNormal];
        }
         CCLabelTTF *labelSelect = [CCLabelTTF labelWithString:[NSString stringWithFormat:@".%@",name] fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(size)];
        if (labelSelect) {
            [array addObject:labelSelect];
        }
    }
    return array;
}
-(void)selectWithIndex:(int)index{
    
        
    
    if (select_index>=0 && [select_array count]>select_index) {
        //CCMenuItemToggle *toggle = [select_array objectAtIndex:select_index];
        UnionArrayNode *arrNode = [select_array objectAtIndex:select_index];
        if (arrNode) {
            CCMenuItemToggle *toggle = [arrNode btt_toggle];
            [toggle setSelectedIndex:0];
        }
        
        //
        /*
        select_index = index;
        toggle = [select_array objectAtIndex:select_index];
        [toggle setSelectedIndex:1];
         */
    }
    //
    if (index>=0 && [select_array count]>index) {
        select_index = index;
        if (select_index>=0 && [select_array count]>select_index) {
            //CCMenuItemToggle *toggle = [select_array objectAtIndex:select_index];
             UnionArrayNode *arrNode = [select_array objectAtIndex:select_index];
            if (arrNode) {
                CCMenuItemToggle *toggle = [arrNode btt_toggle];
                [toggle setSelectedIndex:1];
            }
        }
    }
}
-(void)doClose:(id)sender{
	[UnionDisbandSetting hide];
}
-(void)onExit{
    [select_array release];
    [super onExit];
}
-(void) registerWithTouchDispatcher
{
	CCDirector *director = [CCDirector sharedDirector];
	[[director touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority-126 swallowsTouches:YES];
}
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return YES;
}
@end 