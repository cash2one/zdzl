//
//  UnionMember.m
//  TXSFGame
//
//  Created by Max on 13-3-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionMember.h"
#import "UnionPanel.h"
#import "AlertManager.h"
#import "Config.h"
#import "LowerLeftChat.h"
#import "SocialHelper.h"
#import "UnionSetting.h"

/*
typedef enum {
	UnionDuty_main		= 1, //盟主
	UnionDuty_vice			= 2,//副盟主
	UnionDuty_elder		= 3,//长老
    UnionDuty_bodyGuard		= 4,//护法
	UnionDuty_diaphysis		= 5,//精英
    UnionDuty_member		= 6,//盟友
}UnionDuty;
*/
#pragma mark 盟友一行显示
@implementation UnionMemberItem
@synthesize isSelected;
@synthesize isMainUser;
@synthesize duty;
static UnionMember *unionMember;

-(id)initWithName:(NSString *)name level:(int)level job:(NSString *)job rank:(int)rank contrib:(int)contrib status:(NSString *)status pid:(int)_pid
{
    int w_ = 502;
    int h_ = 35.5;
    if (iPhoneRuningOnGame()) {
		w_=554;
    }
    if (self = [super init]) {
		pid=_pid;
		
        self.contentSize = CGSizeMake(cFixedScale(w_), cFixedScale(h_));
        self.anchorPoint = ccp(0, 0);
        CGPoint halfPoint = ccp(self.contentSize.width / 2, self.contentSize.height / 2);
        
        CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/p14.png"];
        bg.scaleX = self.contentSize.width / bg.contentSize.width;
        bg.scaleY = self.contentSize.height / bg.contentSize.height;
        bg.position = halfPoint;
        [self addChild:bg];
        float off_x = 20;
		
        float nameX = cFixedScale(41+off_x);
        float levelX = cFixedScale(122+off_x);
        float jobX = cFixedScale(188);
        float rankX = cFixedScale(275);
        float contribX= cFixedScale(372);
        float statusX = cFixedScale(454);
        
		
		if (iPhoneRuningOnGame()) {
			off_x=30;
			nameX = cFixedScale(41+off_x);
			levelX = cFixedScale(122+off_x+20);
			jobX = cFixedScale(188+30);
			rankX = cFixedScale(275+25);
			contribX= cFixedScale(372+27);
			statusX = cFixedScale(454+30);
			
		}
        float fontSize = cFixedScale(16);
        NSString *fontName = getCommonFontName(FONT_1);
        normalColor = ccc3(169, 156, 126);
        selectedColor = ccc3(236, 226, 210);
		
		
		
        nameLabel = [CCLabelTTF labelWithString:name fontName:fontName fontSize:fontSize];
        nameLabel.color = normalColor;
        nameLabel.position = ccp(nameX, halfPoint.y);
        [self addChild:nameLabel];
        levelLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", level] fontName:fontName fontSize:fontSize];
        levelLabel.color = normalColor;
        levelLabel.position = ccp(levelX, halfPoint.y);
        [self addChild:levelLabel];
        jobLabel = [CCLabelTTF labelWithString:job fontName:fontName fontSize:fontSize];
        jobLabel.color = normalColor;
        jobLabel.position = ccp(jobX, halfPoint.y);
        [self addChild:jobLabel];
        rankLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", rank] fontName:fontName fontSize:fontSize];
        rankLabel.color = normalColor;
        rankLabel.position = ccp(rankX, halfPoint.y);
        [self addChild:rankLabel];
        contribLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", contrib] fontName:fontName fontSize:fontSize];
        contribLabel.color = normalColor;
        contribLabel.position = ccp(contribX, halfPoint.y);
        [self addChild:contribLabel];
        statusLabel = [CCLabelTTF labelWithString:status fontName:fontName fontSize:fontSize];
        statusLabel.color = normalColor;
        statusLabel.position = ccp(statusX, halfPoint.y);
        [self addChild:statusLabel];
        isSelected = NO;
    }
	CCSimpleButton *openActBtn=[CCSimpleButton spriteWithSize:CGSizeMake(cFixedScale(w_-2),cFixedScale(h_+3))  block:^(){
		if([unionMember getCCPanel].isTouchValid){
			[[UnionPanel share]removeChildByTag:UnionMemberActionMenu];
			UnionMemberAction *uma=[UnionMemberAction memberAction:name pid:pid];
            uma.duty = duty;
			//[uma setPosition:ccp([[UnionPanel share]touchPoint].x-cFixedScale(500-2), [[UnionPanel share]touchPoint].y-cFixedScale(500-2))];
            CGPoint pos = [[UnionPanel share] convertToNodeSpace:[[UnionPanel share]touchPoint]];
			pos=ccp(pos.x,pos.y-cFixedScale(35));
            [uma setPosition:pos];
            [[UnionPanel share]addChild:uma z:999 tag:UnionMemberActionMenu];
		}
	}];
	[openActBtn setSwallows:NO];
	[openActBtn setAnchorPoint:ccp(0, 0)];
	[self addChild:openActBtn];
    if (iPhoneRuningOnGame()) {
		openActBtn.priority = -100;
    }
    return self;
}

-(void)setIsMainUser:(BOOL)_isMainUser
{
    isMainUser = _isMainUser;
    nameLabel.color = ccc3(5, 174, 240);
}

-(void)setIsSelected:(BOOL)_isSelected
{
    if (isSelected == _isSelected) {
        return;
    }
    
    isSelected = _isSelected;
    if (isSelected) {
        if (!isMainUser) {
            nameLabel.color = selectedColor;
        }
        levelLabel.color = selectedColor;
        jobLabel.color = selectedColor;
        rankLabel.color = selectedColor;
        contribLabel.color = selectedColor;
        statusLabel.color = selectedColor;
    } else {
        if (!isMainUser) {
            nameLabel.color = normalColor;
        }
        levelLabel.color = normalColor;
        jobLabel.color = normalColor;
        rankLabel.color = normalColor;
        contribLabel.color = normalColor;
        statusLabel.color = normalColor;
    }
}

@end



BOOL isCreateAction=NO;

#pragma mark 盟友操作
@implementation UnionMemberAction
@synthesize userId;


@synthesize playerId;
@synthesize playerName;
@synthesize duty;

+(UnionMemberAction*)memberAction:(NSString*)_name pid:(int)_pid{
	UnionMemberAction *uma=[UnionMemberAction node];
	[uma setPlayerName:_name];
	[uma setPlayerId:_pid];
	return uma;
}

-(void)draw
{
    [super draw];
    glLineWidth(1.0f);
    ccDrawColor4B(165, 125, 61, 1);
    ccDrawRect(ccp(0, 0), ccp(self.contentSize.width, self.contentSize.height));
}


-(id)init
{
	float width=95;
	float height=140;
	float itemW=92;
	float itemH=35;
	float fontSize=14;
	if (iPhoneRuningOnGame()) {
		width=120.0f/2;
		height=165.0f/2;
		itemW=116/2.0f;
		itemH=40/2.0f;
		fontSize=10;
	}
	
	
    if (self = [super initWithColor:ccc4(0, 0, 0, 190) width:width height:height]) {
        
        CGSize menuItemSize = CGSizeMake(itemW,itemH);
        CGPoint halfPoint = ccp(menuItemSize.width / 2.0f, menuItemSize.height / 2.0f);
        ccColor3B normalColor = ccc3(237, 229, 207);
        ccColor3B selectedColor = ccc3(235, 180, 69);
    	
		NSMutableArray *memberActButton=[NSMutableArray array];
		NSDictionary *uniondata=[UnionPanel share].info;
		CCLOG(@"%@",uniondata);
		NSArray *memberActLabel=nil;
		NSArray *posy;
		int len=0;
		
		if ([[uniondata objectForKey:@"duty"]integerValue]==1) {
			len=4;
			
			/*
			memberActLabel=[NSArray arrayWithObjects:NSLocalizedString(@"union_member_private", nil),
												   NSLocalizedString(@"union_member_add_friend",nil),
												   NSLocalizedString(@"union_member_check_info",nil),
												   NSLocalizedString(@"union_member_kick",nil), nil];
			*/
			
			if (iPhoneRuningOnGame()) {
				posy=[NSArray arrayWithObjects:@"120",@"80",@"40",@"0", nil];
			}else{
				posy=[NSArray arrayWithObjects:@"105",@"70",@"35",@"0", nil];
			}
			[self setContentSize:CGSizeMake(width, height)];
		}else{
			len=3;
			
			/*
			memberActLabel=[NSArray arrayWithObjects:NSLocalizedString(@"union_member_private", nil),
													NSLocalizedString(@"union_member_add_friend",nil),
													NSLocalizedString(@"union_member_check_info",nil), nil];
			*/
			
			if (iPhoneRuningOnGame()) {
				posy=[NSArray arrayWithObjects:@"80",@"40",@"0", nil];
			}else{
				posy=[NSArray arrayWithObjects:@"70",@"35",@"0", nil];
			}
			[self setContentSize:CGSizeMake(width, height-itemH)];
		}
		
        //fix chao
        memberActLabel = [self getStringArrayWithDuty:[[uniondata objectForKey:@"duty"]integerValue]];
        if (memberActLabel) {
            len = [memberActLabel count];
            height += itemH*(len-4);
            posy = [self getPosArrayWithLength:len];
            [self setContentSize:CGSizeMake(width, height)];
        }
		//end

		
		
		
		for(int i=0;i<len;i++){
			CCSprite *spNormal = [CCSprite node];
			CCSprite *spSelected = [CCSprite node];
			spNormal.contentSize = menuItemSize;
			spSelected.contentSize = menuItemSize;
			CCLabelTTF *labelNormal = [CCLabelTTF labelWithString:[memberActLabel objectAtIndex:i] fontName:getCommonFontName(FONT_1) fontSize:fontSize];
			CCLabelTTF *labelSelected = [CCLabelTTF labelWithString:[memberActLabel objectAtIndex:i] fontName:getCommonFontName(FONT_1) fontSize:fontSize];
			labelNormal.color = normalColor;
			labelSelected.color = selectedColor;
			labelNormal.position = halfPoint;
			labelSelected.position = halfPoint;
			CCSprite *SelectedBg = [CCSprite spriteWithFile:@"images/ui/panel/p15.png"];
			SelectedBg.scaleX = menuItemSize.width / SelectedBg.contentSize.width;
			SelectedBg.scaleY = menuItemSize.height / SelectedBg.contentSize.height;
			SelectedBg.position = halfPoint;
			[spNormal addChild:labelNormal];
			[spSelected addChild:SelectedBg];
			[spSelected addChild:labelSelected];
			
			
			CCMenuItemSprite *MenuItem = [CCMenuItemSprite itemWithNormalSprite:spNormal selectedSprite:spSelected target:self selector:@selector(memberActionTapped:)];
            //fix chao
            int tag_temp = [self getUnionMemberTagWithString:[memberActLabel objectAtIndex:i]];
            if (tag_temp>=Tag_Union_Member_Talk && tag_temp <= Tag_Union_Member_kick ) {
                MenuItem.tag = tag_temp;
            }
			//MenuItem.tag = Tag_Union_Member_Talk+i;
            //end
			MenuItem.position = ccpAdd(halfPoint, ccp(0, cFixedScale([[posy objectAtIndex:i]integerValue])));
			[memberActButton addObject:MenuItem];
			//			[self setTouchPriority:-190];
		}
		menu = [CCMenu menuWithArray:memberActButton];
        menu.position = ccp(1, 1);
        [self addChild:menu];
		[menu setTouchPriority:-128];
    }
	//	showNode(self);
    return self;
}
-(NSArray*)getStringArrayWithDuty:(int)duty_{
    NSMutableArray *_mutArray = nil;
    //
    NSDictionary* duty_dict = [[GameDB shared] readDB:@"ally_right"];
    NSArray *dutyArray = [duty_dict allValues];
    for (NSDictionary *_dict in dutyArray) {
        if (_dict
            && [_dict objectForKey:@"duty"]
            && [[_dict objectForKey:@"duty"] intValue]==duty_) {
            ////
            //_mutArray = [NSMutableArray arrayWithObjects:@"私聊",@"加为好友",@"查看信息", nil];
            _mutArray = [NSMutableArray arrayWithObjects:
                         NSLocalizedString(@"union_member_private",nil),
                         NSLocalizedString(@"union_member_add_friend",nil),
                         NSLocalizedString(@"union_member_check_info",nil), nil];
            if ([[_dict objectForKey:@"change"] intValue]) {
                //[_mutArray addObject:@"改变职责"];
                [_mutArray addObject:NSLocalizedString(@"union_member_change_duty",nil)];
            }
            if ([[_dict objectForKey:@"kick"] intValue]) {
                //[_mutArray addObject:@"踢掉"];
                [_mutArray addObject:NSLocalizedString(@"union_member_kick",nil)];
            }
            break;
        }
    }
    
    return _mutArray;
}
-(NSArray*)getPosArrayWithLength:(int)len{
    NSMutableArray *_mutArray = [NSMutableArray array];
    //
    int val_ = 0;
    int step_ = 0;
    if (iPhoneRuningOnGame()) {
        step_ = 40;
    }else{
        step_ = 35;
    }
    val_ = len*step_-step_;
    for (int i=0; i<len; i++) {
        [_mutArray addObject:[NSString stringWithFormat:@"%d",val_-i*step_]];
    }
    return _mutArray;
}
//fix chao
-(int)getUnionMemberTagWithString:(NSString*)tagName{
    int tag = 0;
//    if ([tagName isEqualToString:@"私聊"]) {
//        tag = Tag_Union_Member_Talk;
//    }else if([tagName isEqualToString:@"加为好友"]) {
//        tag = Tag_Union_Member_Add;
//    }else if([tagName isEqualToString:@"查看信息"]) {
//        tag = Tag_Union_Member_Look;
//    }else if([tagName isEqualToString:@"改变职责"]) {
//        tag = Tag_Union_Member_changeDuty;
//    }else if([tagName isEqualToString:@"踢掉"]) {
//        tag = Tag_Union_Member_kick;
//    }
    if ([tagName isEqualToString:NSLocalizedString(@"union_member_private",nil)]) {
        tag = Tag_Union_Member_Talk;
    }else if([tagName isEqualToString:NSLocalizedString(@"union_member_add_friend",nil)]) {
        tag = Tag_Union_Member_Add;
    }else if([tagName isEqualToString:NSLocalizedString(@"union_member_check_info",nil)]) {
        tag = Tag_Union_Member_Look;
    }else if([tagName isEqualToString:NSLocalizedString(@"union_member_change_duty",nil)]) {
        tag = Tag_Union_Member_changeDuty;
    }else if([tagName isEqualToString:NSLocalizedString(@"union_member_kick",nil)]) {
        tag = Tag_Union_Member_kick;
    }
    return tag;
}
//end
-(void) onEnter
{
	[super onEnter];
	//开启触摸
	[self setTouchEnabled:YES];
	//	[self setTouchMode:kCCTouchesAllAtOnce];
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-127 swallowsTouches:YES];
	int selfId=[[[[GameConfigure shared] getPlayerInfo] objectForKey:@"id"]intValue];
	
	if(selfId==playerId){
		CCMenuItemSprite *MenuItem=(CCMenuItemSprite*)[menu getChildByTag:Tag_Union_Member_Talk];
		MenuItem.isEnabled=NO;
		MenuItem=(CCMenuItemSprite*)[menu getChildByTag:Tag_Union_Member_Add];
		MenuItem.isEnabled=NO;
		MenuItem=(CCMenuItemSprite*)[menu getChildByTag:Tag_Union_Member_kick];
		MenuItem.isEnabled=NO;
	}
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	//	CGPoint touchPoint=[touch locationInView:touch.view];
	//	touchPoint=[self convertToNodeSpace:touchPoint];
	//	//点其它地方时隐藏
	[[UnionPanel share]removeChildByTag:UnionMemberActionMenu];
	return NO;
}


-(void)memberActionTapped:(id)sender
{
	CCMenuItemSprite *menuItem = sender;
	switch (menuItem.tag) {
		case Tag_Union_Member_Talk:{
			CCLOG(@"聊天");
			[ChatPanelBase sendPrivateChannle:playerName pid:playerId];
			[[Window shared] removeWindow:PANEL_UNION];
			
		}
			break;
		case Tag_Union_Member_Add:{
			[[SocialHelper shared] socialAction:playerId action:SocialHelper_addFriend];
			CCLOG(@"加为好友");
		}
			break;
		case Tag_Union_Member_Look:{
            [[SocialHelper shared] socialGetInfo:playerId name:playerName];
			CCLOG(@"查看");
		}
			break;
            //
            /*
        case Tag_Union_Member_setMain:{
            CCLOG(@"%i",self.playerId);
			[[AlertManager shared]showMessage:[NSString stringWithFormat:@"是否确定任职 %@ 为盟主",playerName] target:self confirm:@selector(confirmSetMain) canel:nil];
			CCLOG(@"任职盟主");
		}
			break;
        case Tag_Union_Member_setVice:{
            CCLOG(@"%i",self.playerId);
			[[AlertManager shared]showMessage:[NSString stringWithFormat:@"是否确定任职 %@ 为副盟主",playerName] target:self confirm:@selector(confirmSetVice) canel:nil];
			CCLOG(@"任职副盟主");
		}
			break;
        case Tag_Union_Member_setElder:{
            CCLOG(@"%i",self.playerId);
			[[AlertManager shared]showMessage:[NSString stringWithFormat:@"是否确定任职 %@ 为长老",playerName] target:self confirm:@selector(confirmSetElder) canel:nil];
			CCLOG(@"任职长老");
		}
			break;
        case Tag_Union_Member_setBodyGuard:{
            CCLOG(@"%i",self.playerId);
			[[AlertManager shared]showMessage:[NSString stringWithFormat:@"是否确定任职 %@ 为护法",playerName] target:self confirm:@selector(confirmSetElder) canel:nil];
			CCLOG(@"任职护法");
		}
			break;
        case Tag_Union_Member_setDiaphysis:{
            CCLOG(@"%i",self.playerId);
			[[AlertManager shared]showMessage:[NSString stringWithFormat:@"是否确定任职 %@ 为精英",playerName] target:self confirm:@selector(confirmSetDiaphysis) canel:nil];
            CCLOG(@"任职精英");
		}
			break;
        case Tag_Union_Member_setMember:{
            CCLOG(@"%i",self.playerId);
			[[AlertManager shared]showMessage:[NSString stringWithFormat:@"是否确定任职 %@ 为盟友",playerName] target:self confirm:@selector(confirmSetMember) canel:nil];
            CCLOG(@"任职盟友");
		}
			break;
             */
            //
        case Tag_Union_Member_changeDuty:{
			CCLOG(@"%i",self.playerId);
            //TODO chao change duty UI 
			//[[AlertManager shared]showMessage:[NSString stringWithFormat:@"是否确定更改 %@ 职责",playerName] target:self confirm:nil canel:nil];
            //[[AlertManager shared]showMessage:[NSString stringWithFormat:NSLocalizedString(@"union_member_sure_change_duty",nil),playerName] target:self confirm:@selector(changeDuty) canel:nil];
            [self changeDuty];
		}
			break;
		case Tag_Union_Member_kick:{
			CCLOG(@"%i",self.playerId);
			//[[AlertManager shared]showMessage:[NSString stringWithFormat:@"是否确定踢除 %@",playerName] target:self confirm:@selector(confirmDelMember) canel:nil];
            [[AlertManager shared]showMessage:[NSString stringWithFormat:NSLocalizedString(@"union_member_sure_kick",nil),playerName] target:self confirm:@selector(confirmDelMember) canel:nil];
		}
			break;
		default:
			break;
	}
	self.visible = NO;
}
//
-(void)changeDuty{
    //[UnionDisbandSetting show];
    UnionPanel *unionPanel = [UnionPanel getUnionPanel];
    NSDictionary * group = nil;
    if (unionPanel) {
        group = unionPanel.info;
    }
    int role_duty = [[group objectForKey:@"duty"] intValue];
    if (role_duty>=UnionDuty_main && role_duty<=UnionDuty_member) {
        if (role_duty<=duty) {
           [UnionDisbandSetting showWithID:playerId name:playerName duty:duty]; 
        }else{
            [ShowItem showItemAct:NSLocalizedString(@"union_member_no_power",nil)];
        }
    
    }else{
        CCLOG(@"role duty error");
    }

}
/*
//设为盟主
-(void)confirmSetMain{
    [self confirmSetWithDuty:UnionDuty_main];
}
//设为副盟主
-(void)confirmSetVice{
    [self confirmSetWithDuty:UnionDuty_vice];
}
//设为长老
-(void)confirmSetElder{
    [self confirmSetWithDuty:UnionDuty_elder];
}
//设为护法
-(void)confirmSetBodyGuard{
    [self confirmSetWithDuty:UnionDuty_bodyGuard];
}
//设为精英
-(void)confirmSetDiaphysis{
    [self confirmSetWithDuty:UnionDuty_diaphysis];
}
//设为盟友
-(void)confirmSetMember{
    [self confirmSetWithDuty:UnionDuty_member];
}
 
//设置
-(void)confirmSetWithDuty:(int)duty_{
    [GameConnection request:@"allyCDuty" format:[NSString stringWithFormat:@"pid::%i|duty::%i",playerId,duty_] target:self call:@selector(didconfirmSetMember:)];
}
//任职回调
-(void)didconfirmSetMember:(NSDictionary*)data{
	if(checkResponseStatus(data)){
		[GameConnection request:@"allyMembers" format:@"" target:unionMember  call:@selector(didGetAllyMambers:)];
	}else{
        [ShowItem showErrorAct:getResponseMessage(data)];
    }
}
 */
//
-(void)confirmDelMember{
	[GameConnection request:@"allyKick" format:[NSString stringWithFormat:@"pid::%i",playerId] target:self call:@selector(didconfirmDelMember:)];
}

-(void)didconfirmDelMember:(NSDictionary*)data{
	if(checkResponseStatus(data)){
		[GameConnection request:@"allyMembers" format:@"" target:unionMember  call:@selector(didGetAllyMambers:)];
	}else{
        [ShowItem showErrorAct:getResponseMessage(data)];
    }
}
@end




#define UNIONMEMBER_W (502)
#define UNIONMEMBER_H (469)
#pragma mark 盟友list
@implementation UnionMember


+(UnionMember*)getUnionMember{
    return unionMember;
}
-(UnionMember*)share{
	return unionMember;
}

-(CCPanel*)getCCPanel{
	return memberListPanel;
}

-(id)initWithUnionId:(int)uid
{
    int w_ = UNIONMEMBER_W;
    int h_ = UNIONMEMBER_H;
    int off_x = 0;
    if (iPhoneRuningOnGame()) {
		h_ += 20;
		w_=554;
		off_x=30;
    }
    if (self = [super initWithColor:ccc4(0, 0, 0, 0) width:cFixedScale(self.contentSize.width) height:cFixedScale(h_)]) {
        unionId = uid;
        
        float nameX = cFixedScale(41+off_x);
        float levelX = cFixedScale(122+off_x);
        float jobX = cFixedScale(188+off_x);
        float rankX = cFixedScale(275+off_x);
        float contribX= cFixedScale(372+off_x);
        float statusX = cFixedScale(454+off_x);
		if (iPhoneRuningOnGame()) {
			nameX = cFixedScale(41+off_x);
			levelX = cFixedScale(122+off_x+20);
			jobX = cFixedScale(188+off_x);
			rankX = cFixedScale(275+off_x);
			contribX= cFixedScale(372+off_x);
			statusX = cFixedScale(454+off_x);
		}
        unionMember=self;
        memberAction = [[[UnionMemberAction alloc] init] autorelease];
		//  memberAction.delegate = (UnionPanel *)[[Window shared] getChildByTag:PANEL_UNION];
        memberAction.visible = NO;
        [self addChild:memberAction z:1000];
        
        // 标题
        UnionTitle *title = [[[UnionTitle alloc] initWithWidth:cFixedScale(w_)] autorelease];
        title.anchorPoint = ccp(0, 1);
        title.position = ccp(0, self.contentSize.height);
        [self addChild:title];

        //CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:@"同盟列表" fontName:title.fontName fontSize:title.fontSize];
        CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_member_list",nil) fontName:title.fontName fontSize:title.fontSize];
        nameLabel.color = title.fontColor;
        nameLabel.position = ccp(nameX, title.contentSize.height / 2);
        [title addChild:nameLabel];
        //CCLabelTTF *levelLabel = [CCLabelTTF labelWithString:@"等级" fontName:title.fontName fontSize:title.fontSize];
        CCLabelTTF *levelLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_member_level",nil) fontName:title.fontName fontSize:title.fontSize];
        levelLabel.color = title.fontColor;
        levelLabel.position = ccp(levelX, title.contentSize.height / 2);
        [title addChild:levelLabel];
        //CCLabelTTF *jobLabel = [CCLabelTTF labelWithString:@"职务" fontName:title.fontName fontSize:title.fontSize];
        CCLabelTTF *jobLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_member_duty",nil) fontName:title.fontName fontSize:title.fontSize];
        jobLabel.color = title.fontColor;
        jobLabel.position = ccp(jobX, title.contentSize.height / 2);
        [title addChild:jobLabel];
        //CCLabelTTF *rankLabel = [CCLabelTTF labelWithString:@"竞技场排名" fontName:title.fontName fontSize:title.fontSize];
        CCLabelTTF *rankLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_member_arena_rank",nil) fontName:title.fontName fontSize:title.fontSize];
        rankLabel.color = title.fontColor;
        rankLabel.position = ccp(rankX, title.contentSize.height / 2);
        [title addChild:rankLabel];
        //CCLabelTTF *contribLabel = [CCLabelTTF labelWithString:@"总贡献" fontName:title.fontName fontSize:title.fontSize];
        CCLabelTTF *contribLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_member_proffer_count",nil) fontName:title.fontName fontSize:title.fontSize];
        contribLabel.color = title.fontColor;
        contribLabel.position = ccp(contribX, title.contentSize.height / 2);
        [title addChild:contribLabel];
        //CCLabelTTF *statusLabel = [CCLabelTTF labelWithString:@"状态" fontName:title.fontName fontSize:title.fontSize];
        CCLabelTTF *statusLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_member_state",nil) fontName:title.fontName fontSize:title.fontSize];
        statusLabel.color = title.fontColor;
        statusLabel.position = ccp(statusX, title.contentSize.height / 2);
        [title addChild:statusLabel];
        
		[GameConnection request:@"allyMembers" format:@"" target:self call:@selector(didGetAllyMambers:)];
		
        self.touchEnabled = YES;
    }
    return self;
}

-(void)didGetAllyMambers:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		int w_ = 500;
        int h_ = 440;
        if (iPhoneRuningOnGame()) {
			h_ += 20;
			w_=554;
        }
		NSArray * members = getResponseData(response);
		
		if([members count]==0){
			return;
		}
		if(memberListPanel.parent){
			[memberListPanel removeFromParentAndCleanup:true];
		}
		// 成员框
		listLayer = [[[CCLayerColor alloc] initWithColor:ccc4(0, 0, 0, 0)] autorelease];
        float perHeight = cFixedScale(39);
        if (iPhoneRuningOnGame()) {
            if (isIphone5()) {
                perHeight += cFixedScale(5);
            }else{
                perHeight += cFixedScale(5);
            }
            
        }
	    int count = [members count];
		
		float contentHeight=count*perHeight<cFixedScale(h_)?cFixedScale(h_):count*perHeight;
		
		[listLayer setContentSize:CGSizeMake(cFixedScale(w_), contentHeight)];
        for (int i = 0; i < count; i++) {
            // playerId获取玩家表
			contentHeight-=perHeight;
			NSDictionary * member = [members objectAtIndex:i];
			NSString * name = [member objectForKey:@"n"];
			NSString * job = getJobName([[member objectForKey:@"duty"] intValue]);
			int duty = [[member objectForKey:@"duty"] intValue];
			int level = [[member objectForKey:@"lv"] intValue];
			int rank = [[member objectForKey:@"pvp"] intValue];
			int contrib = [[member objectForKey:@"exp"] intValue];
			int time = [[member objectForKey:@"dt"] intValue];
			int pid = [[member objectForKey:@"pid"] intValue];
			
			//NSString * status = @"在线";
            NSString * status = NSLocalizedString(@"union_member_online",nil);
			if(time>0){
				status = getTime(time);
			}
            UnionMemberItem *unionMemberItem = [[[UnionMemberItem alloc] initWithName:name
																				level:level
																				  job:job
																				 rank:rank
																			  contrib:contrib
																			   status:status pid:pid
												 ] autorelease];
            unionMemberItem.position = ccp(0, contentHeight);
            unionMemberItem.tag = pid; // 用户id
			
            if(duty==1){
				unionMemberItem.isMainUser = YES;
            }
            unionMemberItem.duty = duty;
            [listLayer addChild:unionMemberItem];
        }
		
		memberListPanel=[CCPanel panelWithContent:listLayer viewSize:CGSizeMake(cFixedScale(w_), cFixedScale(h_))];
		memberListPanel.position = ccp(0, 0);
		[memberListPanel showScrollBar:@"images/ui/common/scroll3.png"];
		[memberListPanel updateContentToTop];
		[self addChild:memberListPanel];
        //fix chao
        [[UnionPanel share] updateBaseInfo];
        //end
	}else{
		CCLOG(@"error load ally members");
	}
}

@end
