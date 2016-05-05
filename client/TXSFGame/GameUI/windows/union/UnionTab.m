//
//  UnionTab.m
//  TXSFGame
//
//  Created by peak on 13-4-18.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionTab.h"
#import "UnionPanel.h"

static CCPanel *s_auditPanel=nil;

@implementation UnionAuditItem
@synthesize delegate;
-(id)initWithUserId:(int)userId name:(NSString *)name level:(int)level rank:(int)rank
{
    if (self = [super init]) {
        float w_ = 502;
        float h_ = 35;
        float off_x = 0;
        if (iPhoneRuningOnGame()) {
			w_ += 50;
			h_+=10;
        }
        self.contentSize = CGSizeMake(cFixedScale(w_), cFixedScale(h_));
        self.anchorPoint = ccp(0, 0);
        CGPoint halfPoint = ccp(self.contentSize.width / 2, self.contentSize.height / 2);
        
        CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/p14.png"];
        bg.scaleX = self.contentSize.width / bg.contentSize.width;
        bg.scaleY = self.contentSize.height / bg.contentSize.height;
        bg.position = halfPoint;
        [self addChild:bg];
        
        float nameX = cFixedScale(61+off_x+20);
        float levelX = cFixedScale(170+off_x);
        float rankX = cFixedScale(266+off_x);
        float approveX= cFixedScale(380+off_x);
        float refuseX = cFixedScale(456+off_x);
		
        float fontSize = cFixedScale(16);
        NSString *fontName = getCommonFontName(FONT_1);
        ccColor3B nameColor = ccc3(4, 175, 238);
        ccColor3B normalColor = ccc3(236, 226, 210);
        
        CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:name fontName:fontName fontSize:fontSize];
        nameLabel.color = nameColor;
        nameLabel.position = ccp(nameX, halfPoint.y);
        [self addChild:nameLabel];
        
        CCLabelTTF *levelLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", level] fontName:fontName fontSize:fontSize];
        levelLabel.color = normalColor;
        levelLabel.position = ccp(levelX, halfPoint.y);
        [self addChild:levelLabel];
		
        CCLabelTTF *rankLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", rank] fontName:fontName fontSize:fontSize];
        rankLabel.color = normalColor;
        rankLabel.position = ccp(rankX, halfPoint.y);
        [self addChild:rankLabel];
        //fix chao
		//        NSArray *approveBtns = getLabelSprites(@"images/ui/button/bt_background2.png",
		//                                               @"images/ui/button/bt_background2.png",
		//                                               @"批 准",
		//                                               14,
		//                                               ccc4(65,197,186,255),
		//                                               ccc4(65,197,186,255) );
		NSArray *approveBtns = getBtnSpriteWithStatus(@"images/ui/button/bts_approve");
		
		//end
        CCMenuItemSprite *approveMenuItem = [CCMenuItemSprite itemWithNormalSprite:[approveBtns objectAtIndex:0]
                                                                    selectedSprite:[approveBtns objectAtIndex:1]
                                                                            target:self
                                                                          selector:@selector(approveTapped:)];
        approveMenuItem.tag = userId;
        approveMenuItem.position = ccp(approveX, halfPoint.y);
		if (iPhoneRuningOnGame()) {
			approveMenuItem.scale=1.2f;
		}
        //fix chao
		//        NSArray *refuseBtns = getLabelSprites(@"images/ui/button/bt_background2.png",
		//                                              @"images/ui/button/bt_background2.png",
		//                                              @"拒 绝",
		//                                              14,
		//                                              ccc4(65,197,186,255),
		//                                              ccc4(65,197,186,255) );
		NSArray *refuseBtns = getBtnSpriteWithStatus(@"images/ui/button/bts_refuse");
		//end
		
        CCMenuItemSprite *refuseMenuItem = [CCMenuItemSprite itemWithNormalSprite:[refuseBtns objectAtIndex:0]
                                                                   selectedSprite:[refuseBtns objectAtIndex:1]
                                                                           target:self
                                                                         selector:@selector(refuseTapped:)];
        refuseMenuItem.tag = userId;
        refuseMenuItem.position = ccp(refuseX, halfPoint.y);
		if (iPhoneRuningOnGame()) {
			refuseMenuItem.scale=1.2f;
			refuseMenuItem.position = ccp(refuseX+10, halfPoint.y);
		}
        
        CCMenu *menu = [CCMenu menuWithItems:approveMenuItem, refuseMenuItem, nil];
        menu.position = ccp(0, 0);
        [self addChild:menu];
    }
    return self;
}

-(void)approveTapped:(id)sender
{
	if(![s_auditPanel isTouchValid]){
		return;
	}
    CCMenuItemSprite *approveMenuItem = sender;
    
	CCLOG(@"接受了Id为%d用户的请求", approveMenuItem.tag);
    
    if (delegate && [delegate respondsToSelector:@selector(auditActionWithTarget: accept:)]) {
        [delegate auditActionWithTarget:self accept:YES];
    }
}

-(void)refuseTapped:(id)sender
{
	if(![s_auditPanel isTouchValid]){
		return;
	}
    CCMenuItemSprite *refuseMenuItem = sender;
    
	CCLOG(@"拒绝了Id为%d用户的请求", refuseMenuItem.tag);
    
    if (delegate && [delegate respondsToSelector:@selector(auditActionWithTarget: accept:)]) {
        [delegate auditActionWithTarget:self accept:NO];
    }
}

@end

@implementation UnionAudit
@synthesize auditPanel;
//@synthesize auditArray;
-(id)initWithUnionId:(int)uid
{
    int w_ = 502;
    int h_ = 469;
    if (iPhoneRuningOnGame()) {
		w_ += 50;
		h_ += 20;
    }
    if (self = [super initWithColor:ccc4(0, 0, 0, 0) width:cFixedScale(w_) height:cFixedScale(h_)]) {
        unionId = uid;
        float off_x = 0;
        float nameX = cFixedScale(61+off_x+20);
        float levelX = cFixedScale(170+off_x);
        float rankX = cFixedScale(266+off_x);
        float actionX= cFixedScale(417+off_x);
        
        // 标题
        UnionTitle *title = [[[UnionTitle alloc] initWithWidth:self.contentSize.width] autorelease];
        title.anchorPoint = ccp(0, 1);
        title.position = ccp(0, self.contentSize.height);
        [self addChild:title];

        //CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:@"申请人" fontName:title.fontName fontSize:title.fontSize];
        CCLabelTTF *nameLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_tab_apply",nil) fontName:title.fontName fontSize:title.fontSize];
        nameLabel.color = title.fontColor;
        nameLabel.position = ccp(nameX, title.contentSize.height / 2);
        [title addChild:nameLabel];
        //CCLabelTTF *levelLabel = [CCLabelTTF labelWithString:@"等级" fontName:title.fontName fontSize:title.fontSize];
        CCLabelTTF *levelLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_tab_level",nil) fontName:title.fontName fontSize:title.fontSize];
        levelLabel.color = title.fontColor;
        levelLabel.position = ccp(levelX, title.contentSize.height / 2);
        [title addChild:levelLabel];
        //CCLabelTTF *rankLabel = [CCLabelTTF labelWithString:@"竞技场排名" fontName:title.fontName fontSize:title.fontSize];
        CCLabelTTF *rankLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_tab_arena_rank",nil) fontName:title.fontName fontSize:title.fontSize];
        rankLabel.color = title.fontColor;
        rankLabel.position = ccp(rankX, title.contentSize.height / 2);
        [title addChild:rankLabel];
        //CCLabelTTF *actionLabel = [CCLabelTTF labelWithString:@"操作" fontName:title.fontName fontSize:title.fontSize];
        CCLabelTTF *actionLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_tab_operate",nil) fontName:title.fontName fontSize:title.fontSize];
        actionLabel.color = title.fontColor;
        actionLabel.position = ccp(actionX, title.contentSize.height / 2);
        [title addChild:actionLabel];
        
		[GameConnection request:@"allyApplicants" format:@"" target:self call:@selector(didGetAllyApplicants:)];
		
        self.touchEnabled = YES;
		
    }
    return self;
}

-(void)onExit{
	s_auditPanel = nil;
	if(auditArray){
		[auditArray release];
		auditArray = nil;
	}
	[super onExit];
}

-(void)didGetAllyApplicants:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		NSArray * members = getResponseData(response);
		
		if([members count]==0){
			return;
		}
		
		// 成员框
		int w = cFixedScale(506);
		int h = cFixedScale(429);
        if (iPhoneRuningOnGame() ) {
            if (isIphone5()) {
                //                w += cFixedScale(100);
                //                h += cFixedScale(30);
                w += cFixedScale(50);
                h += cFixedScale(30);
            }else{
                w += cFixedScale(50);
                h += cFixedScale(30);
            }
            
        }
		/*
         auditPanel = [ScrollPanel create:self direction:ScrollPanelDirVertical size:CGSizeMake(506, 429) priority:ScrollPanelPriorityNormal];
         auditPanel.position = ccp(0, 3);
         [self addChild:auditPanel];
         */
        listLayer = [[[CCLayerColor alloc] initWithColor:ccc4(0, 0, 0, 0)] autorelease];
        
        float perHeight = cFixedScale(39);
		if (iPhoneRuningOnGame()) {
			perHeight = cFixedScale(52);
		}
        int count = [members count];
        //int pageCount = ceil((float)count/11);
        //listLayer.contentSize = CGSizeMake(auditPanel.contentSize.width, auditPanel.contentSize.height * pageCount);
        float contentHeight=count*perHeight<h?h:count*perHeight;
        //listLayer.contentSize = CGSizeMake(w, h * pageCount);
        listLayer.contentSize = CGSizeMake(w, contentHeight);
		auditArray = [NSMutableArray array];
		[auditArray retain];
		
        for (int i = 0; i < count; i++) {
			
			NSDictionary * member = [members objectAtIndex:i];
			
			int pid = [[member objectForKey:@"pid"] intValue];
			int level = [[member objectForKey:@"lv"] intValue];
			int rank = [[member objectForKey:@"pvp"]isKindOfClass:[NSNull class]]?0:[[member objectForKey:@"pvp"]integerValue];
			NSString * name = [member objectForKey:@"name"];
			
            // playerId获取玩家表
            UnionAuditItem *unionAuditItem = [[[UnionAuditItem alloc] initWithUserId:pid
																				name:name
																			   level:level
																				rank:rank
											   ] autorelease];
            
            unionAuditItem.position = ccp(0, listLayer.contentSize.height - perHeight * (i+1));
            unionAuditItem.tag = pid;  // 用户id
            unionAuditItem.delegate = self;
			
            [listLayer addChild:unionAuditItem];
            [auditArray addObject:unionAuditItem];
        }
        //fix chao
        auditPanel = [CCPanel panelWithContent:listLayer viewSize:CGSizeMake(w, h)];
		auditPanel.position = ccp(0, cFixedScale(3));
		[auditPanel showScrollBar:@"images/ui/common/scroll3.png"];
		[self addChild:auditPanel];
		[auditPanel updateContentToTop];
		//auditPanel.contentLayer = listLayer;
		s_auditPanel = auditPanel;
		//end
		
		
	}else{
		CCLOG(@"Error load ally applicants");
	}
}

-(void)resetAuditItemPosition
{
    float perHeight = cFixedScale(39);
    int count = auditArray.count;
    int pageCount = ceil((float)count/11);
    listLayer.contentSize = CGSizeMake(auditPanel.contentSize.width, auditPanel.contentSize.height * pageCount);
	//[auditPanel resetScroll];
    for (int i = 0; i < count; i++) {
        UnionAuditItem *unionAuditItem = [auditArray objectAtIndex:i];
        unionAuditItem.position = ccp(0, listLayer.contentSize.height - perHeight * (i+1));
    }
}

-(void)auditActionWithTarget:(id)target accept:(BOOL)isAccept{
	
    if ([target isKindOfClass:[UnionAuditItem class]] && [auditArray containsObject:target]) {
		
		UnionAuditItem * node = (UnionAuditItem*)target;
		int pid = node.tag;
		int state = (isAccept?1:0);
		
		[auditArray removeObject:target];
        [target removeFromParentAndCleanup:YES];
        [self resetAuditItemPosition];
		
		NSString * fm = [NSString stringWithFormat:@"pid::%d|state::%d",pid,state];
        SEL call_ = nil;
        if(isAccept){
            call_ = @selector(didAccept:);
        }else{
            call_ = @selector(didNoAccept:);
        }
		[GameConnection request:@"allyHDApply" format:fm target:self call:call_];
		//[GameConnection request:@"allyHDApply" format:fm target:nil call:nil];
		
    }
}
-(void)didNoAccept:(NSDictionary*)response{
	if(checkResponseStatus(response)){
        //[ShowItem showItemAct:[NSString stringWithFormat:@"已拒绝加入!"]];
        [ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_tab_refuse_ok",nil)]];
        [[UnionPanel share] updateBaseInfo];
	}else{
        //[ShowItem showItemAct:[NSString stringWithFormat:@"拒绝失败!"]];
        [ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_tab_refuse_fail",nil)]];
		CCLOG(@"error ally accept");
	}
}
-(void)didAccept:(NSDictionary*)response{
	if(checkResponseStatus(response)){
        //[ShowItem showItemAct:[NSString stringWithFormat:@"成功加入!"]];
        [ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_tab_enter_ok",nil)]];
        [[UnionPanel share] updateBaseInfo];
	}else{
        //[ShowItem showItemAct:[NSString stringWithFormat:@"加入失败!"]];
        [ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_tab_enter_fail",nil)]];
		CCLOG(@"error ally accept");
	}
}

@end

@interface UnionTrendsItem : CCSprite
{
    CCLabelTTF *nameLabel;
    CCLabelTTF *trendsLabel;
    CCLabelTTF *timeLabel;
    
    ccColor3B mainUseColor;
    ccColor3B normalColor;
}
@property (nonatomic) BOOL isMainUser;
-(id)initWithName:(NSString *)name trends:(NSString *)trends time:(int)time;

@end

@implementation UnionTrendsItem
@synthesize isMainUser;
-(id)initWithName:(NSString *)name trends:(NSString *)trends time:(int)time
{
    if (self = [super init]) {
        float w_ = 493;
        float h_ = 35.5;
        if (iPhoneRuningOnGame()) {
            //            if(isIphone5()){
            ////                w_ += 100;
            //                w_ += 50;
            //            }else{																//Kevin modified
            w_ += 50;
			h_ = 65.5;																//Kevin added
            //            }
            
        }
        self.contentSize = CGSizeMake(cFixedScale(w_), cFixedScale(h_));
        self.anchorPoint = ccp(0, 0);
        CGPoint halfPoint = ccp(self.contentSize.width / 2, self.contentSize.height / 2);
        
        CCSprite *bg = [CCSprite spriteWithFile:@"images/ui/panel/p14.png"];
        bg.scaleX = self.contentSize.width / bg.contentSize.width;
        bg.scaleY = self.contentSize.height / bg.contentSize.height;
        bg.position = halfPoint;
        [self addChild:bg];
        //float off_x = 20;
        float nameX = cFixedScale(9+10);
        float trendsX = cFixedScale(75+80);
        float timeX = cFixedScale(397);
        
        float fontSize = cFixedScale(14);
        //Kevin added
		if (iPhoneRuningOnGame()) {
			fontSize = 10;
		}
		//--------------------//
		
        NSString *fontName = getCommonFontName(FONT_1);
        normalColor = ccc3(236, 226, 210);
        mainUseColor = ccc3(4, 174, 237);
        
        nameLabel = [CCLabelTTF labelWithString:name fontName:fontName fontSize:fontSize];
        nameLabel.color = mainUseColor;
        nameLabel.anchorPoint = ccp(0, 0.5);
        nameLabel.position = ccp(nameX, halfPoint.y);
        [self addChild:nameLabel];
        
        trendsLabel = [CCLabelTTF labelWithString:trends fontName:fontName fontSize:fontSize];
        trendsLabel.color = normalColor;
        trendsLabel.anchorPoint = ccp(0, 0.5);
        trendsLabel.position = ccp(trendsX, halfPoint.y);
        [self addChild:trendsLabel];
		
		NSString * timeString = getTime(time);
        
        timeLabel = [CCLabelTTF labelWithString:timeString fontName:fontName fontSize:fontSize];
        timeLabel.color = normalColor;
        timeLabel.anchorPoint = ccp(0, 0.5);
        timeLabel.position = ccp(timeX, halfPoint.y);
        [self addChild:timeLabel];
		
    }
    return self;
}

-(void)setIsMainUser:(BOOL)_isMainUser
{
    isMainUser = _isMainUser;
    nameLabel.color = mainUseColor;
}

@end

@implementation UnionTrends
@synthesize trendsPanel;
@synthesize trendsArray;
-(id)initWithUnionId:(int)uid
{
    int w_ = 502;
    int h_ = 469;
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            //            w_ += 100;
            //            h_ += 30;
            w_ += 50;
            h_ += 30;
        }else{
            w_ += 50;
            h_ += 30;
        }
        
    }
    if (self = [super initWithColor:ccc4(0, 0, 0, 0) width:cFixedScale(w_) height:cFixedScale(h_)]) {
        unionId = uid;
        
        // 获取盟主Id
        //int mainId = 1;
		
        float menuItemY = cFixedScale(h_-17);

        // 人事
        //CCLabelTTF *personnelLabel = [CCLabelTTF labelWithString:@"人事" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(16)];
        CCLabelTTF *personnelLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_tab_personnel",nil) fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(16)];
        personnelLabel.color = ccc3(237, 226, 205);
        [self addChild:personnelLabel];
		personnelLabel.position = ccp(70, menuItemY);
        
        CCSprite *personnelNormal = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle01.png"];
        CCSprite *personnelSelected = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle01.png"];
        CCMenuItemSprite *personnelMenuItem = [CCMenuItemSprite itemWithNormalSprite:personnelNormal selectedSprite:personnelSelected target:self selector:@selector(selectType:)];
        personnelMenuItem.tag = Tag_Union_Trends_Personnel;
		personnelMenuItem.position = ccp(38, menuItemY);
		if (iPhoneRuningOnGame()) {
			personnelMenuItem.scale=1.2f;
			personnelMenuItem.position = ccp(38/2.0f, menuItemY-5);
			personnelLabel.position = ccp(70/2.0f, menuItemY-5);
		}
        
        personnelSelectedDone = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle02.png"];
        personnelSelectedDone.position = personnelMenuItem.position;
		if (iPhoneRuningOnGame()) {
			personnelSelectedDone.scale=1.2f;
		}
        
        [self addChild:personnelSelectedDone z:10];
        
        // 贡献
        //CCLabelTTF *contribLabel = [CCLabelTTF labelWithString:@"贡献" fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(16)];
        CCLabelTTF *contribLabel = [CCLabelTTF labelWithString:NSLocalizedString(@"union_tab_proffer",nil) fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(16)];
        contribLabel.color = ccc3(237, 226, 205);
        contribLabel.position = ccp(185, menuItemY);
        [self addChild:contribLabel];
        
        CCSprite *contribNormal = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle01.png"];
        CCSprite *contribSelected = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle01.png"];
        CCMenuItemSprite *contribMenuItem = [CCMenuItemSprite itemWithNormalSprite:contribNormal selectedSprite:contribSelected target:self selector:@selector(selectType:)];
        contribMenuItem.tag = Tag_Union_Trends_Contrib;
        contribMenuItem.position = ccp(153, menuItemY);
		if (iPhoneRuningOnGame()) {
			contribMenuItem.position = ccp(153/2.0f, menuItemY-5);
			contribLabel.position = ccp(185/2.0f, menuItemY-5);
            
			contribMenuItem.scale=1.3f;
		}
        
        contribSelectedDone = [CCSprite spriteWithFile:@"images/ui/button/bt_toggle02.png"];
        contribSelectedDone.position = contribMenuItem.position;
		if (iPhoneRuningOnGame()) {
			contribSelectedDone.scale=1.3f;
		}
        
        [self addChild:contribSelectedDone z:10];
        
        CCMenu *menu = [CCMenu menuWithItems:personnelMenuItem, contribMenuItem, nil];
        menu.position = ccp(0, 0);
        [self addChild:menu];
        
		[GameConnection request:@"allyLog" format:@"" target:self call:@selector(didAllyLog:)];
		
    }
    return self;
}
-(void)didAllyLog:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		NSArray * logs = getResponseData(response);
		
        personnelCount = 0;
        contribCount = 0;
        
        // 动态框
		//fix chao
		/*
		 trendsPanel = [ScrollPanel create:self direction:ScrollPanelDirVertical size:CGSizeMake(self.contentSize.width, 429) priority:ScrollPanelPriorityNormal];
		 trendsPanel.position = ccp(5, 3);
		 [self addChild:trendsPanel];
		 */
        //end
        float perHeight = cFixedScale(39);
        int count = logs.count;
        //int pageCount = ceil((float)count/11);
        
        listLayer = [[[CCLayerColor alloc] initWithColor:ccc4(0, 0, 0, 0)] autorelease];
        //listLayer.contentSize = CGSizeMake(trendsPanel.contentSize.width, trendsPanel.contentSize.height * pageCount);
        float h_ = cFixedScale(429);
        if (iPhoneRuningOnGame()) {
            perHeight = cFixedScale(69);
			h_ += cFixedScale(20);
        }
        float contentHeight=count*perHeight<h_?h_:count*perHeight;
        //listLayer.contentSize = CGSizeMake(self.contentSize.width, PanelLayer_Width * pageCount);
        listLayer.contentSize = CGSizeMake(self.contentSize.width, contentHeight);
        self.trendsArray = [NSMutableArray array];
		
        for (int i = 0; i < logs.count; i++) {
            NSDictionary * log = [logs objectAtIndex:i];
			
			int time = [[log objectForKey:@"ct"] intValue];
			int type = [[log objectForKey:@"t"] intValue];
			
			Tag_Union_Trends_Type t_type = Tag_Union_Trends_Personnel;
			if(type==1 || type==2 || type==6 || type==7){
				t_type = Tag_Union_Trends_Personnel;
			}
			if(type==3){
				t_type = Tag_Union_Trends_Contrib;
			}

			NSString * n1 = [log objectForKey:@"n1"];
			NSString * n2 = [log objectForKey:@"n2"];
			NSString * info = @"";
			//if(type==1) info = [NSString stringWithFormat:@"加入了同盟"];
            if(type==1) info = [NSString stringWithFormat:NSLocalizedString(@"union_tab_enter_union",nil)];
			//if(type==2) info = [NSString stringWithFormat:@"退出了同盟"];
            if(type==2) info = [NSString stringWithFormat:NSLocalizedString(@"union_tab_exit_union",nil)];
			if(type==3){
				int v1 = [[log objectForKey:@"v1"] intValue];
				//info = [NSString stringWithFormat:@"为同盟贡献了%d经验",v1];
                info = [NSString stringWithFormat:NSLocalizedString(@"union_tab_exit_union",nil),v1];
			}
			//if(type==6) info = [NSString stringWithFormat:@"任职[%@] ??? ",n2];
            if(type==6){
                int v1 = [[log objectForKey:@"v1"] intValue];
                info = [NSString stringWithFormat:NSLocalizedString(@"union_tab_duty",nil),n2,getJobName(v1)];
            }
			//if(type==7) info = [NSString stringWithFormat:@"踢走[%@]",n2];
            if(type==7) info = [NSString stringWithFormat:NSLocalizedString(@"union_tab_kick",nil),n2];
			
            UnionTrendsItem *unionTrendsItem = [[[UnionTrendsItem alloc] initWithName:n1
																			   trends:info
																				 time:time
												 ] autorelease];
			
			unionTrendsItem.tag = t_type;
            unionTrendsItem.position = ccp(0, listLayer.contentSize.height - perHeight * (i+1));
            [listLayer addChild:unionTrendsItem];
            [trendsArray addObject:unionTrendsItem];
            
            if (unionTrendsItem.tag == Tag_Union_Trends_Personnel) {
                personnelCount++;
            } else if (unionTrendsItem.tag == Tag_Union_Trends_Contrib) {
                contribCount++;
            }
        }
		//fix chao
        trendsPanel = [CCPanel panelWithContent:listLayer viewSize:CGSizeMake(self.contentSize.width, h_)];
		//trendsPanel.tag = 10;
		trendsPanel.position = ccp(cFixedScale(5), cFixedScale(3));
		[trendsPanel showScrollBar:@"images/ui/common/scroll3.png"];
		[self addChild:trendsPanel];
		[trendsPanel updateContentToTop];
		//trendsPanel.contentLayer = listLayer;
		//end
        isSelectedPersonnel = YES;
        isSelectedContrib = YES;
		
		
		
	}else{
		CCLOG(@"error load ally log");
	}
}

-(void)setTrendsPositionWithPersonnel:(BOOL)personnel contrib:(BOOL)contrib
{
    float perHeight = cFixedScale(39);
    
    //Kevin added
	if (iPhoneRuningOnGame()) {
		perHeight = cFixedScale(69);
	}
	//------------------//
    
    int count = (personnel ? personnelCount : 0) + (contrib ? contribCount : 0);
    int pageCount = ceil((float)count/11);
    listLayer.contentSize = CGSizeMake(trendsPanel.contentSize.width, trendsPanel.contentSize.height * pageCount);
	// [trendsPanel resetScroll];
    int j = 0;
    for (int i = 0; i < trendsArray.count; i++) {
        UnionTrendsItem *trendsItem = [trendsArray objectAtIndex:i];
        BOOL isVisible = NO;
        if (trendsItem.tag == Tag_Union_Trends_Personnel && personnel) {
            isVisible = YES;
        }
        if (trendsItem.tag == Tag_Union_Trends_Contrib && contrib) {
            isVisible = YES;
        }
        if (isVisible) {
            j++;
            trendsItem.position = ccp(0, listLayer.contentSize.height - perHeight * j);
            trendsItem.visible = YES;
        } else {
            trendsItem.visible = NO;
        }
    }
	[trendsPanel updateContentToTop];
	
}

-(void)selectType:(id)sender
{
    CCMenuItemSprite *menuItem = sender;
    if (menuItem.tag == Tag_Union_Trends_Personnel) {
        
        isSelectedPersonnel = !isSelectedPersonnel;
        personnelSelectedDone.visible = isSelectedPersonnel;
        
    } else if (menuItem.tag == Tag_Union_Trends_Contrib) {
        
        isSelectedContrib = !isSelectedContrib;
        contribSelectedDone.visible = isSelectedContrib;
        
    }
    
    [self setTrendsPositionWithPersonnel:isSelectedPersonnel contrib:isSelectedContrib];
}

@end

@interface UnionTabItem : CCSprite
{
    ccColor3B normalColor;
    ccColor3B selectedColor;
    CCLabelTTF *label;
    CCSprite *normalSprite;
    CCSprite *selectedSprite;
}
@property (nonatomic) BOOL isSelected;
@end

@implementation UnionTabItem
@synthesize isSelected;
-(id)initWithType:(Tag_Union_Tab_Type)type
{
    if (self = [super init]) {
        normalColor = ccc3(169, 156, 126);
        selectedColor = ccc3(227, 229, 227);
        
        float width = 76.0;
        
		if (iPhoneRuningOnGame()) {
			width=100.0/2.0f;
		}
        normalSprite = [CCSprite spriteWithFile:@"images/ui/panel/t25.png"];
        selectedSprite = [CCSprite spriteWithFile:@"images/ui/panel/t24.png"];
        normalSprite.scale= width / normalSprite.contentSize.width;
        selectedSprite.scale = width / normalSprite.contentSize.width;
        
        selectedSprite.visible = NO;
        
        self.anchorPoint = ccp(0, 0);
        if (iPhoneRuningOnGame()) {
            self.contentSize = CGSizeMake(width, normalSprite.contentSize.height+20);
        }else{
            self.contentSize = CGSizeMake(width, normalSprite.contentSize.height);
        }
        //self.contentSize = CGSizeMake(width, normalSprite.contentSize.height);
        CGPoint halfPoint = ccp(self.contentSize.width / 2,
                                self.contentSize.height / 2);
        if (iPhoneRuningOnGame()) {
            halfPoint.y -= 15/2;
        }
        normalSprite.position = halfPoint;
        selectedSprite.position = halfPoint;
        [self addChild:normalSprite];
        [self addChild:selectedSprite];
        
        label = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:16];
        label.scale=cFixedScale(1);
        label.color = normalColor;
        label.position = halfPoint;
        [self addChild:label];
        
        switch (type) {
            case Tag_Union_Tab_Activity:
                //label.string = @"活 动";
                label.string = NSLocalizedString(@"union_tab_activity",nil);
                self.tag = Tag_Union_Tab_Activity;
                break;
            case Tag_Union_Tab_Member:
                //label.string = @"成 员";
                label.string = NSLocalizedString(@"union_tab_member",nil);
                self.tag = Tag_Union_Tab_Member;
                break;
            case Tag_Union_Tab_Audit:
                //label.string = @"审 核";
                label.string = NSLocalizedString(@"union_tab_audit",nil);
                self.tag = Tag_Union_Tab_Audit;
                break;
            case Tag_Union_Tab_Trends:
                //label.string = @"动 态";
                label.string = NSLocalizedString(@"union_tab_trends",nil);
                self.tag = Tag_Union_Tab_Trends;
                break;
                
            default:
                break;
        }
        
        self.isSelected = NO;
    }
    return self;
}
-(void)setIsSelected:(BOOL)_isSelected
{
    if (isSelected == _isSelected) {
        return;
    }
    
    isSelected = _isSelected;
    if (isSelected) {
        label.color = selectedColor;
        normalSprite.visible = NO;
        selectedSprite.visible = YES;
    } else {
        label.color = normalColor;
        normalSprite.visible = YES;
        selectedSprite.visible = NO;
    }
}

@end

@implementation UnionTab
@synthesize unionActivity;
@synthesize unionMember;
@synthesize unionTrends;
@synthesize unionAudit;
-(void)draw
{
    [super draw];
    glLineWidth(1.0f);
    ccDrawColor4F(0.31, 0.22, 0.13, 1);
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
            ccDrawRect(ccp(0, 0), ccp(cFixedScale(576), cFixedScale(552)));
        }else{
            ccDrawRect(ccp(0, 0), ccp(cFixedScale(576), cFixedScale(552)));
        }
        
    }else{
        ccDrawRect(ccp(0, 0), ccp(cFixedScale(518), cFixedScale(491)));
    }
}

-(void)addItems:(NSArray *)items
{
    CGPoint orginPoint = ccp(0, cFixedScale(492));
    float offsetX = cFixedScale(82);
    int i = 0;
    int off_y = 0;
    if (iPhoneRuningOnGame()) {
		orginPoint = ccp(4, cFixedScale(492));
		offsetX = cFixedScale(110);
		off_y += cFixedScale(20);
    }
    for (UnionTabItem *tabItem in items) {
        tabItem.position = ccp(orginPoint.x + offsetX * i, orginPoint.y + off_y);
        [self addChild:tabItem];
        i++;
    }
}

-(void)changeTab:(Tag_Union_Tab_Type)type
{
    if (tabType == type) {
        return;
    }
    
    tabType = type;
    for (UnionTabItem *tabItem in tabItems) {
        if (tabItem.tag == type) {
            tabItem.isSelected = YES;
        } else {
            tabItem.isSelected = NO;
        }
    }
    
    if (unionMember && unionMember.parent) {
        [unionMember removeFromParentAndCleanup:NO];
		unionMember = nil;
    }
    if (unionActivity && unionActivity.parent) {
        [unionActivity removeFromParentAndCleanup:NO];
		unionActivity = nil;
    }
    if (unionAudit && unionAudit.parent) {
        [unionAudit removeFromParentAndCleanup:NO];
		unionAudit = nil;
    }
    if (unionTrends && unionTrends.parent) {
        [unionTrends removeFromParentAndCleanup:NO];
		unionTrends = nil;
    }
    
    switch (type) {
        case Tag_Union_Tab_Activity:
        {
            if (!unionActivity) {
                self.unionActivity = [[[UnionActivity alloc] initWithUnionId:unionId] autorelease];
                unionActivity.position = ccp(cFixedScale(8), cFixedScale(10));
            }
            [self addChild:unionActivity];
        }
            break;
        case Tag_Union_Tab_Member:
        {
            if (!unionMember) {
                self.unionMember = [[[UnionMember alloc] initWithUnionId:unionId] autorelease];
                unionMember.position = ccp(cFixedScale(8), cFixedScale(12));
            }
            [self addChild:unionMember];
        }
            break;
        case Tag_Union_Tab_Audit:
        {
            if (!unionAudit) {
                self.unionAudit = [[[UnionAudit alloc] initWithUnionId:unionId] autorelease];
                unionAudit.position = ccp(cFixedScale(8), cFixedScale(12));
            }
            [self addChild:unionAudit];
        }
            break;
        case Tag_Union_Tab_Trends:
        {
            if (!unionTrends) {
                self.unionTrends = [[[UnionTrends alloc] initWithUnionId:unionId] autorelease];
                unionTrends.position = ccp(cFixedScale(8), cFixedScale(10));
            }
            [self addChild:unionTrends];
        }
            break;
			
        default:
            break;
    }
}

-(id)initWithUnionId:(int)uid
{
    float w = 518;
    float h = 516;
    if (iPhoneRuningOnGame()) {
		w = 488;
		h = 578;
    }
    if (self = [super initWithColor:ccc4(0, 0, 0, 0) width:cFixedScale(w) height:cFixedScale(h)]) {
        
        unionId = uid;
		UnionPanel *unionPanel = [UnionPanel getUnionPanel];
		NSDictionary * allyInfo = unionPanel.info;
		int duty = [[allyInfo objectForKey:@"duty"] intValue];
        float w_ = 517;
        float h_ = 490;
        if (iPhoneRuningOnGame()) {
			w_ = 574;
			h_ = 550;
        }
        CCLayerColor *contentLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 190) width:cFixedScale(w_) height:cFixedScale(h_)];
        contentLayer.position = ccp(1, 1);
        [self addChild:contentLayer];
        
        tabItems = [NSMutableArray array];
		[tabItems retain];
		
        // 活动
        UnionTabItem *activityTabItem = [[[UnionTabItem alloc] initWithType:Tag_Union_Tab_Activity] autorelease];
        [tabItems addObject:activityTabItem];
        // 成员
        UnionTabItem *memberTabItem = [[[UnionTabItem alloc] initWithType:Tag_Union_Tab_Member] autorelease];
        [tabItems addObject:memberTabItem];
		
        // 是否盟主
        //fix chao
        BOOL isCheck = NO;
        NSDictionary* duty_dict = [[GameDB shared] readDB:@"ally_right"];
        NSArray *dutyArray = [duty_dict allValues];
        for (NSDictionary *_dict in dutyArray) {
            if (_dict
                && [_dict objectForKey:@"duty"]
                && [[_dict objectForKey:@"duty"] intValue]==duty) {
                isCheck = [[_dict objectForKey:@"check"] intValue];
                break;
            }
        }
        if (isCheck) {
            UnionTabItem *auditTabItem = [[[UnionTabItem alloc] initWithType:Tag_Union_Tab_Audit] autorelease];
            [tabItems addObject:auditTabItem];
        }
        /*
		if (duty==1 || duty==2) {
            // 审核
            UnionTabItem *auditTabItem = [[[UnionTabItem alloc] initWithType:Tag_Union_Tab_Audit] autorelease];
            [tabItems addObject:auditTabItem];
        }
         */
		//end
        
        // 动态
        UnionTabItem *trendsTabItem = [[[UnionTabItem alloc] initWithType:Tag_Union_Tab_Trends] autorelease];
        [tabItems addObject:trendsTabItem];
        
        [self addItems:tabItems];
        
        // 默认选中选项卡
        [self changeTab:Tag_Union_Tab_Activity];
        
        self.touchEnabled = YES;
    }
    return self;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	//    if (unionMember && unionMember.visible) {
	//        [unionMember ccTouchBegan:touch withEvent:event];
	//    }
    return YES;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
	//    if (unionMember && unionMember.visible) {
	//        [unionMember ccTouchMoved:touch withEvent:event];
	//    }
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInView:touch.view];
    touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    touchLocation = [self convertToNodeSpace:touchLocation];
    
    for (UnionTabItem *tabItem in tabItems) {
        if (CGRectContainsPoint(tabItem.boundingBox, touchLocation)) {
            [self changeTab:tabItem.tag];
			[[UnionPanel share]removeChildByTag:UnionMemberActionMenu];
        }
    }
}

-(void)dealloc
{
	[tabItems release];
    [super dealloc];
}

@end

