//
//  UnionInfo.m
//  TXSFGame
//
//  Created by peak on 13-4-18.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionInfo.h"
#import "UnionConfig.h"
#import "UnionSetting.h"
#import "UnionBossSetting.h"
#import "UnionPanel.h"
#import "UnionManager.h"
#import "RoleManager.h"
#import "RolePlayer.h"
#import "AlertManager.h"

@implementation UnionInfo
-(void)dealloc{
    if (postTextView) {
        [postTextView removeFromSuperview];
		[postTextView release];
		postTextView = nil;
    }
    //
    [super dealloc];
}
-(void)draw
{
    [super draw];
    glLineWidth(1.0f);
    ccDrawColor4F(0.31, 0.22, 0.13, 1);
    ccDrawRect(ccp(0, 0), ccp(self.contentSize.width, self.contentSize.height));
}

-(void)doAllyDismiss{
	[GameConnection request:@"allyDismiss" format:@"" target:self call:@selector(dodDisband:)];
}
-(void)doAllyQuit{
	[GameConnection request:@"allyQuit" format:@"" target:self call:@selector(dodAllyQuit:)];
}

-(void)unionInfoTapped:(id)sender
{
    CCMenuItem *item = sender;
    // 设置
	switch (item.tag) {
        case Tag_Union_Disband:{
			[[AlertManager shared] showMessage:NSLocalizedString(@"ally_dismiss",nil) target:self confirm:@selector(doAllyDismiss) canel:nil];
		}
			break;
		case Tag_Union_Set:{
			[UnionSetting show];
		}
			break;
        case Tag_Union_BossSet:{
			//TODO Max
			[UnionBossSetting show];
		}
			break;
		case Tag_Union_Quit:{
			[[AlertManager shared] showMessage:NSLocalizedString(@"ally_quit",nil) target:self confirm:@selector(doAllyQuit) canel:nil];
		}
			break;
		case Tag_Union_Other:{
            UnionPanel *unionPanel = [UnionPanel getUnionPanel];
			[unionPanel showUnionList];
		}
			break;
		case Tag_Union_Manor:{
			[[Window shared] removeWindow:PANEL_UNION];
			[UnionManager enterUnion];
		}
			break;
		default:
			break;
	}
	//点其它地方时隐藏
	[[UnionPanel share]removeChildByTag:UnionMemberActionMenu];
}
-(void)dodDisband:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		[[GameConfigure shared] removePlayerAlly];
        [[Window shared] removeWindow:PANEL_UNION];
        [UnionManager quitUnion];
        //fix chao
        RolePlayer *player = [RoleManager shared].player;
        if (player) {
            player.allyName=@"";
            [player updateViewer];
        }
        //end
        [ShowItem showItemAct:NSLocalizedString(@"union_info_disband",nil)];
	}else{
		CCLOG(@"Error quit ally");
        [ShowItem showErrorAct:getResponseMessage(response)];
	}
	//点其它地方时隐藏
	[[UnionPanel share]removeChildByTag:UnionMemberActionMenu];
}
-(void)dodAllyQuit:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		[[GameConfigure shared] removePlayerAlly];
        [[Window shared] removeWindow:PANEL_UNION];
        [UnionManager quitUnion];
        //fix chao
        RolePlayer *player = [RoleManager shared].player;
        if (player) {
            player.allyName=@"";
            [player updateViewer];
        }
        //end
	}else{
		CCLOG(@"Error quit ally");
        [ShowItem showErrorAct:getResponseMessage(response)];
	}
	//点其它地方时隐藏
	[[UnionPanel share]removeChildByTag:UnionMemberActionMenu];
}

// scrollValue为0~1
-(void)setScroll:(float)scrollValue{
	
    scrollLeft.visible = YES;
    scrollMiddle.visible = YES;
    scrollRight.visible = YES;
    float minWidth = cFixedScale(4);
    float maxWidth = cFixedScale(251);
    //fix chao
    if (iPhoneRuningOnGame()) {
        maxWidth = cFixedScale(300);
    }
    //end
    float realWidth = MAX(MIN(maxWidth * scrollValue, maxWidth), minWidth);
	
    scrollMiddle.scaleX = realWidth / scrollMiddle.contentSize.width;
    scrollRight.position = ccp(scrollMiddle.position.x + realWidth,
                               scrollMiddle.position.y);
}

-(void)updateNotice:(NSString*)note{
	//NSDictionary *notice = [[GameConfigure shared] getGroupPostById:_gid];
	//if(note) noticeLabel.string = note;
    if (note) {
            //
            if (postTextView) {
                postTextView.text = note;
            }
    }
}

-(id)initWithUnionId:(int)uid
{
    int low_height = 30;
    
    float w = 297;
    float h = 491;
    if (iPhoneRuningOnGame() ) {
        w = 348;
        h = 552;
    }
    if (self = [super initWithColor:ccc4(0, 0, 0, 190) width:cFixedScale(w) height:cFixedScale(h)]) {
        // 同盟信息
        CCSprite *infoBg = [CCSprite spriteWithFile:@"images/ui/panel/p11.png"];
        //fix chao
        if (iPhoneRuningOnGame()) {
			infoBg = getSpriteWithSpriteAndNewSize(infoBg, CGSizeMake(cFixedScale(330), cFixedScale(250)));
        }else{
            infoBg = getSpriteWithSpriteAndNewSize(infoBg, CGSizeMake(infoBg.contentSize.width, infoBg.contentSize.height+low_height));
            infoBg.position = ccp(0,-low_height);
        }
        //end
        infoBg.anchorPoint = ccp(0, 0);
        
        CCLayerColor *infoLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0) width:infoBg.contentSize.width height:infoBg.contentSize.height];
        infoLayer.position = ccp(cFixedScale(9), cFixedScale(285));
        [self addChild:infoLayer];
        [infoLayer addChild:infoBg];
        
        //UnionTitle *infoTitle = [[[UnionTitle alloc] initWithWidth:infoBg.contentSize.width title:@"同盟信息"] autorelease];
         UnionTitle *infoTitle = [[[UnionTitle alloc] initWithWidth:infoBg.contentSize.width title:NSLocalizedString(@"union_info_title",nil)] autorelease];
        infoTitle.anchorPoint = ccp(0, 1);
        if (iPhoneRuningOnGame()){
            infoTitle.position = ccp(0, infoBg.contentSize.height);
        }else{
            infoTitle.position = ccp(0, infoBg.contentSize.height-low_height);
        }
        [infoLayer addChild:infoTitle];
        
        // 同盟id
        unionId = uid;
        
		//NSDictionary *group = [[GameConfigure shared] getGroupById:unionId];
        UnionPanel *unionPanel = [UnionPanel getUnionPanel];
		NSDictionary * group = unionPanel.info;
		NSString * groupName = [group objectForKey:@"name"];
		
        int rankNum = [[group objectForKey:@"rank"] intValue];
		int memberNum = [[group objectForKey:@"mCount"] intValue];
        int level = [[group objectForKey:@"level"] intValue];
		
		NSDictionary * allyLevel = [[GameDB shared] getAllyLevel:level];
		int memberMax = [[allyLevel objectForKey:@"maxNum"] intValue];
		
       //NSString *groupInfo = [NSString stringWithFormat:@"同盟名字 : %@\n同盟首领 : \n同盟排名 : %d\n同盟人数 : %d/%d\n同盟等级 : %d", groupName, rankNum, memberNum, memberMax, level];
        NSString *groupInfo = [NSString stringWithFormat:NSLocalizedString(@"union_info_all_info",nil), groupName, rankNum, memberNum, memberMax, level];
        
		//TODO need ally name
        NSString *mainName = [group objectForKey:@"pn"];
		if(!mainName) mainName = @"";
        int infoLabel_w = 250;
        int infoLabel_h = 120;
        int infoLabel_off_h = 0;
        if (iPhoneRuningOnGame()) {
            if (isIphone5()) {
                infoLabel_w = 300;
                infoLabel_off_h = 46;
            }else{
                infoLabel_w = 300;
                infoLabel_off_h = 46;
            }
            
        }
        //CCLabelTTF *infoLabel = [CCLabelTTF labelWithString:groupInfo fontName:getCommonFontName(FONT_1) fontSize:16 dimensions:CGSizeMake(infoLabel_w, infoLabel_h+infoLabel_off_h) hAlignment:kCCTextAlignmentLeft];
        //Kevin added
		int fontSize = 16;
		if (iPhoneRuningOnGame()) {
			fontSize = 18;
		}
		//--------------------//
		
        CCLabelTTF *infoLabel = [CCLabelTTF labelWithString:groupInfo fontName:getCommonFontName(FONT_1) fontSize:fontSize dimensions:CGSizeMake(infoLabel_w, infoLabel_h+infoLabel_off_h) hAlignment:kCCTextAlignmentLeft];
        
        infoLabel.scale=cFixedScale(1);
        
        infoLabel.color = ccc3(236, 228, 208);
        infoLabel.anchorPoint = ccp(0, 1);
        infoLabel.position = ccp(cFixedScale(13), cFixedScale(152+infoLabel_off_h));
        [infoLayer addChild:infoLabel];
        
        CCLabelTTF *infoMainName = [CCLabelTTF labelWithString:mainName fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(16)];
        //        infoMainName.scale=cFixedScale(1);
        infoMainName.color = ccc3(5, 172, 237);
        infoMainName.anchorPoint = ccp(0, 1);
        if (iPhoneRuningOnGame()) {
            //infoMainName.position = ccp(cFixedScale(97-4), cFixedScale(129+infoLabel_off_h)+2);
            infoMainName.fontSize = 10;
            infoMainName.position = ccp(cFixedScale(100), cFixedScale(129+infoLabel_off_h)+2);											//Kevin fixed
        }else{
            infoMainName.position = ccp(97-4, 129);
        }
        [infoLayer addChild:infoMainName];
        
        // 同盟升级进度
        CCSprite *scrollBg = [CCSprite spriteWithFile:@"images/ui/panel/p13.png"];
        if (iPhoneRuningOnGame()) {
			scrollBg = getSpriteWithSpriteAndNewSize(scrollBg, CGSizeMake(cFixedScale(317), cFixedScale(20)));
        }
        scrollBg.anchorPoint = ccp(0, 0);
        if (iPhoneRuningOnGame()) {
            scrollBg.position = ccp(cFixedScale(5), cFixedScale(13));
        }else{
            scrollBg.position = ccp(cFixedScale(5), cFixedScale(13-low_height));
        }
        //scrollBg.position = ccp(cFixedScale(5), cFixedScale(13));
        
        [infoLayer addChild:scrollBg];
        
        scrollLeft = [CCSprite spriteWithFile:@"images/ui/common/progress1.png"];
        scrollLeft.anchorPoint = ccp(0, 0);
        if (iPhoneRuningOnGame()) {
            scrollLeft.position = ccp(cFixedScale(11), cFixedScale(19));
        }else{
            scrollLeft.position = ccp(cFixedScale(11), cFixedScale(19-low_height));
        }
        //scrollLeft.position = ccp(cFixedScale(11), cFixedScale(19));
        scrollMiddle = [CCSprite spriteWithFile:@"images/ui/common/progress2.png"];
        if (iPhoneRuningOnGame()) {
			scrollMiddle = getSpriteWithSpriteAndNewSize(scrollMiddle, CGSizeMake(cFixedScale(312), cFixedScale(8)));
        }
        scrollMiddle.anchorPoint = ccp(0, 0);
        if (iPhoneRuningOnGame()) {
            scrollMiddle.position = ccp(cFixedScale(15), cFixedScale(19));
        }else{
            scrollMiddle.position = ccp(cFixedScale(15), cFixedScale(19-low_height));
        }
        //scrollMiddle.position = ccp(cFixedScale(15), cFixedScale(19));
        
        scrollRight = [CCSprite spriteWithFile:@"images/ui/common/progress3.png"];
        scrollRight.anchorPoint = ccp(0, 0);
        scrollLeft.visible = NO;
        scrollMiddle.visible = NO;
        scrollRight.visible = NO;
        [infoLayer addChild:scrollLeft];
        [infoLayer addChild:scrollMiddle];
        [infoLayer addChild:scrollRight];
        
		NSDictionary * nextLevel = [[GameDB shared] getAllyLevel:(level+1)];
		float exp = [[group objectForKey:@"exp"] floatValue];
		float maxExp = exp;
		if(nextLevel){
			maxExp = [[nextLevel objectForKey:@"exp"] floatValue];
		}else{
            nextLevel = [[GameDB shared] getAllyLevel:(level)];
            if(nextLevel){
                maxExp = [[nextLevel objectForKey:@"exp"] floatValue];
            }
        }
		[self setScroll:exp/maxExp];
		//fix chao
		NSString *str_ = [NSString stringWithFormat:@"%.0f/%.0f",exp,maxExp];
		CCLabelFX *t_Label = [CCLabelFX labelWithString:str_
                                             dimensions:CGSizeMake(0,0)
                                              alignment:kCCTextAlignmentCenter
                                               fontName:GAME_DEF_CHINESE_FONT
                                               fontSize:12
                                           shadowOffset:CGSizeMake(-1.5, -1.5)
                                             shadowBlur:1.0f];
		t_Label.anchorPoint = ccp(1,1);
        //        t_Label.scale=cFixedScale(1);
        if (iPhoneRuningOnGame()) {
            t_Label.position = ccpAdd(scrollBg.position, ccp(scrollBg.contentSize.width,2));
        }else{
            t_Label.position = ccpAdd(scrollBg.position, ccp(scrollBg.contentSize.width,0));
        }
		[infoLayer addChild:t_Label];
		//end
		CCMenu *infomenu = [CCMenu menuWithItems:nil];
		infomenu.position = ccp(0, 0);
		[infoLayer addChild:infomenu];
		
		int duty = [[group objectForKey:@"duty"] intValue];
        //fix chao
        //BOOL isMainUser = (duty==1 || duty==2);
        BOOL isMainUser = NO;
        NSDictionary* duty_dict = [[GameDB shared] readDB:@"ally_right"];
        NSArray *dutyArray = [duty_dict allValues];
        for (NSDictionary *_dict in dutyArray) {
            if (_dict
                && [_dict objectForKey:@"duty"]
                && [[_dict objectForKey:@"duty"] intValue]==duty) {
                isMainUser = [[_dict objectForKey:@"post"] intValue];
                break;
            }
        }
        //end
		int bt_x = 238;
        int bt_y = 57;
        if (iPhoneRuningOnGame()) {
			bt_x += 50 ;
        }else{
            bt_y -=30;
        }
        
        if (UnionDuty_main == duty) {
			NSArray *disbandBtns = getBtnSpriteWithStatus(@"images/ui/button/bt_union_disband");
            CCMenuItem *disbandMenuItem = [CCMenuItemSprite itemWithNormalSprite:[disbandBtns objectAtIndex:0]
															  selectedSprite:[disbandBtns objectAtIndex:1]
																	  target:self
																	selector:@selector(unionInfoTapped:)];
            int t_y=80;
            disbandMenuItem.tag = Tag_Union_Disband;
            //disbandMenuItem.position = ccp(cFixedScale(bt_x), cFixedScale(bt_y+t_y));
            disbandMenuItem.position = ccp(cFixedScale(bt_x-12), cFixedScale(bt_y+t_y));
			if (iPhoneRuningOnGame()) {
				//disbandMenuItem.scale=1.3f;
				//disbandMenuItem.position = ccp(cFixedScale(bt_x)-5, cFixedScale(bt_y+t_y+35));
                disbandMenuItem.position = ccp(cFixedScale(bt_x-210), cFixedScale(bt_y));
			}else{
                disbandMenuItem.position = ccp(cFixedScale(bt_x-180), cFixedScale(bt_y));
                disbandMenuItem.scale=0.8f;
            }
            [infomenu addChild:disbandMenuItem];
        }
        
        if (isMainUser) {
            
            if (duty != UnionDuty_main) {
                NSArray *quitBtns = getBtnSpriteWithStatus(@"images/ui/button/bts_quit");
                CCMenuItem *quitMenuItem = [CCMenuItemSprite itemWithNormalSprite:[quitBtns objectAtIndex:0]
                                                                   selectedSprite:[quitBtns objectAtIndex:1]
                                                                           target:self
                                                                         selector:@selector(unionInfoTapped:)];
                quitMenuItem.tag = Tag_Union_Quit;
                quitMenuItem.position = ccp(cFixedScale(bt_x), cFixedScale(bt_y));
                if (iPhoneRuningOnGame()) {
                    quitMenuItem.scale=1.3f;
                    quitMenuItem.position = ccp(cFixedScale(bt_x)-5, cFixedScale(bt_y)+2);
                }
                
                
                [infomenu addChild:quitMenuItem];
            }
			//fix chao
			NSArray *setBtns = getBtnSpriteWithStatus(@"images/ui/button/bts_set");
			//end
			
            CCMenuItem *setMenuItem = [CCMenuItemSprite itemWithNormalSprite:[setBtns objectAtIndex:0]
															  selectedSprite:[setBtns objectAtIndex:1]
																	  target:self
																	selector:@selector(unionInfoTapped:)];
            setMenuItem.tag = Tag_Union_Set;
            //setMenuItem.position = ccp(cFixedScale(bt_x), cFixedScale(bt_y));
			if (iPhoneRuningOnGame()) {
				setMenuItem.scale=1.3f;
				//setMenuItem.position = ccp(cFixedScale(bt_x)-5, cFixedScale(bt_y)+2);                
			}
            setMenuItem.position = [self getSetPositionWithDuty:duty];
            
            //fix chao 同盟boss 设置
			NSArray *boss_setBtns = getBtnSpriteWithStatus(@"images/ui/button/bts_set");
			CCMenuItem *boss_setMenuItem = [CCMenuItemSprite itemWithNormalSprite:[boss_setBtns objectAtIndex:0]
                                                                   selectedSprite:[boss_setBtns objectAtIndex:1]
                                                                           target:self
                                                                         selector:@selector(unionInfoTapped:)];
            boss_setMenuItem.tag = Tag_Union_BossSet;
			//TODO
            //bt_y += 40;
            //boss_setMenuItem.position = ccp(cFixedScale(bt_x), cFixedScale(bt_y));
			if (iPhoneRuningOnGame()) {
				boss_setMenuItem.scale=1.3f;
				//boss_setMenuItem.position = ccp(cFixedScale(bt_x)-5, cFixedScale(bt_y)+10);
			}
            boss_setMenuItem.position = [self getBossSetPositionWithDuty:duty];
            
            [infomenu addChild:boss_setMenuItem];
            //end
            //
			[infomenu addChild:setMenuItem];

        }else{
			
			NSArray *quitBtns = getBtnSpriteWithStatus(@"images/ui/button/bts_quit");
			CCMenuItem *quitMenuItem = [CCMenuItemSprite itemWithNormalSprite:[quitBtns objectAtIndex:0]
															   selectedSprite:[quitBtns objectAtIndex:1]
																	   target:self
																	 selector:@selector(unionInfoTapped:)];
			quitMenuItem.tag = Tag_Union_Quit;
			quitMenuItem.position = ccp(cFixedScale(bt_x), cFixedScale(bt_y));
			if (iPhoneRuningOnGame()) {
				quitMenuItem.scale=1.3f;
				quitMenuItem.position = ccp(cFixedScale(bt_x)-5, cFixedScale(bt_y)+2);
			}
            
			
			[infomenu addChild:quitMenuItem];
		}
		
        // 同盟公告
        CCSprite *noticeBg = [CCSprite spriteWithFile:@"images/ui/panel/p11.png"];
        //fix chao
        if (iPhoneRuningOnGame()) {
			noticeBg = getSpriteWithSpriteAndNewSize(noticeBg, CGSizeMake(cFixedScale(330), cFixedScale(192+24)));
            noticeBg.position = ccp(0,-8);
        }else{
            noticeBg = getSpriteWithSpriteAndNewSize(noticeBg, CGSizeMake(noticeBg.contentSize.width, noticeBg.contentSize.height));
            noticeBg.position = ccp(0,-25);
        }
        //end
        noticeBg.anchorPoint = ccp(0, 0);
        
        CCLayerColor *noticeLayer = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 0) width:noticeBg.contentSize.width height:noticeBg.contentSize.height];
        noticeLayer.position = ccp(cFixedScale(9), cFixedScale(76));
        [self addChild:noticeLayer];
        [noticeLayer addChild:noticeBg];
        
        //UnionTitle *noticeTitle = [[[UnionTitle alloc] initWithWidth:noticeBg.contentSize.width title:@"同盟公告"] autorelease];
        UnionTitle *noticeTitle = [[[UnionTitle alloc] initWithWidth:noticeBg.contentSize.width title:NSLocalizedString(@"union_info_notice",nil)] autorelease];
        noticeTitle.anchorPoint = ccp(0, 1);
        if (iPhoneRuningOnGame()) {
            noticeTitle.position = ccp(0, noticeBg.contentSize.height-8);
        }else{
            noticeTitle.position = ccp(0, noticeBg.contentSize.height-25);
        }
        //noticeTitle.position = ccp(0, noticeBg.contentSize.height);
        [noticeLayer addChild:noticeTitle];
        //
        if (nil == postTextView) {
            //
            CGSize size_ = [[CCDirector sharedDirector] winSize];
            int noticeLabel_w = 276;
            int noticeLabel_h = 130;
            int noticeLabel_x = size_.width/2;
            int noticeLabel_y = size_.height/2;
            if (iPhoneRuningOnGame()) {
                noticeLabel_w  = 330/2;
                noticeLabel_h  = 130/2+46/2;
                noticeLabel_x -= 465/2;
                noticeLabel_y += 55/2;
            }else{
                noticeLabel_h  += low_height;
                noticeLabel_x -= 405;
                noticeLabel_y += 55;
            }
            int notice_size = 14;
            if (iPhoneRuningOnGame()) {
                notice_size = 16;
            }
             postTextView = [[UITextView alloc] initWithFrame:CGRectMake(noticeLabel_x,noticeLabel_y,noticeLabel_w,noticeLabel_h)];
            postTextView.font = [UIFont fontWithName:getCommonFontName(FONT_1) size:cFixedScale(notice_size)];
            postTextView.backgroundColor = [UIColor clearColor];
            postTextView.textColor = [UIColor whiteColor];
            postTextView.editable = NO;
            UIView * view = (UIView*)[CCDirector sharedDirector].view;
            [view addSubview:postTextView];
        }
//        noticeLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:notice_size dimensions:CGSizeMake(noticeLabel_w, noticeLabel_h) hAlignment:kCCTextAlignmentLeft];
//       
//        //noticeLabel = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:16 dimensions:CGSizeMake(noticeLabel_w, noticeLabel_h) hAlignment:kCCTextAlignmentLeft];
//        noticeLabel.color = ccc3(236, 228, 208);
//        noticeLabel.scale=cFixedScale(1);
//        noticeLabel.anchorPoint = ccp(0, 1);
//        if (iPhoneRuningOnGame()) {
//            noticeLabel.position = ccp(cFixedScale(13), cFixedScale(152+14));
//        }else{
//            noticeLabel.position = ccp(cFixedScale(13), cFixedScale(152-25));
//        }
//        //noticeLabel.position = ccp(cFixedScale(13), cFixedScale(152));
//        [noticeLayer addChild:noticeLabel];
//        
        [self updateNotice:[group objectForKey:@"post"]];
        
        // 其他同盟按钮
		//fix chao
		NSArray *otherBtns = getBtnSpriteWithStatus(@"images/ui/button/bt_other_union");
		//end
        CCMenuItem *otherMenuItem = [CCMenuItemSprite itemWithNormalSprite:[otherBtns objectAtIndex:0]
                                                            selectedSprite:[otherBtns objectAtIndex:1]
                                                                    target:self
                                                                  selector:@selector(unionInfoTapped:)];
        otherMenuItem.tag = Tag_Union_Other;
        if (iPhoneRuningOnGame()) {
			otherMenuItem.scale=1.2f;
			otherMenuItem.position = ccp(cFixedScale(76+15), cFixedScale(30));
        }else{
            otherMenuItem.position = ccp(cFixedScale(76), cFixedScale(25));
        }
        
		NSArray *manorBtns = getBtnSpriteWithStatus(@"images/ui/button/bt_union_demesne");
		//end
        CCMenuItem *manorMenuItem = [CCMenuItemSprite itemWithNormalSprite:[manorBtns objectAtIndex:0]
                                                            selectedSprite:[manorBtns objectAtIndex:1]
                                                                    target:self
                                                                  selector:@selector(unionInfoTapped:)];
        manorMenuItem.tag = Tag_Union_Manor;
        if (iPhoneRuningOnGame()) {
			manorMenuItem.scale=1.2f;
			manorMenuItem.position = ccp(cFixedScale(220+37), cFixedScale(30));
        }else{
            manorMenuItem.position = ccp(cFixedScale(220), cFixedScale(25));
        }
        
        CCMenu *unionMenu = [CCMenu menuWithItems:otherMenuItem, manorMenuItem, nil];
        unionMenu.position = ccp(0, 0);
        [self addChild:unionMenu];
    }
    return self;
}
-(CGPoint)getBossSetPositionWithDuty:(UnionDuty)duty{
    CGPoint pos;
    int bt_x = 238;
    int bt_y = 57;
    if (iPhoneRuningOnGame()) {
        bt_x += 40 ;
        bt_y += 40;
    }
    bt_y += 80;
    if (duty==UnionDuty_main) {
        bt_y -= 40;
        if (iPhoneRuningOnGame()) {
            bt_y -= 20;
        }else{
            bt_y -= 20;
        }
    }else{
        if (iPhoneRuningOnGame()) {
            bt_x = 55;
            bt_y = 60;
        }else{
            bt_y -=22;
        }
    }
    pos = ccp(cFixedScale(bt_x), cFixedScale(bt_y));
    return pos;
    return pos;
}
-(CGPoint)getSetPositionWithDuty:(UnionDuty)duty{
    CGPoint pos;
    int bt_x = 238;
    int bt_y = 57;
    if (iPhoneRuningOnGame()) {
        bt_x += 40 ;
    }        
//
    bt_y += 40;
    if (duty==UnionDuty_main) {
        //bt_y -= 40;
        if (iPhoneRuningOnGame()) {
            bt_y -= 40;
        }else{
            bt_y -= 70;
        }
    }else{
        if (iPhoneRuningOnGame()) {
            bt_y += 20;
        }else{
            bt_y -=25;
        }
    }
    pos = ccp(cFixedScale(bt_x), cFixedScale(bt_y));
    return pos;
}
@end