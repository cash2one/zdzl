//
//  SacrificePanel.m
//  TXSFGame
//
//  Created by efun on 12-12-5.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "SacrificePanel.h"

@implementation SacrificePanel

-(void)onEnter
{
    [super onEnter];
	
	self.touchEnabled = YES;
	self.touchPriority = -1;
       
    // 祭天背景
    CCSprite *sealBg = nil;
    if (iPhoneRuningOnGame()) {
            sealBg = [CCSprite spriteWithFile:@"images/ui/wback/p9_iphone.jpg"];
            sealBg.position = ccp(self.contentSize.width/2, self.contentSize.height/2 - 8);
    }else{
        sealBg = [CCSprite spriteWithFile:@"images/ui/panel/p9.jpg"];
        sealBg.position = ccp(self.contentSize.width/2, self.contentSize.height/2-23);
    }

    [self addChild:sealBg];
    if (iPhoneRuningOnGame()) {
        sealPoint = ccp(self.contentSize.width/2+4.5f, self.contentSize.height/2 +4.78/2.0f);
    }else{
		sealPoint = ccp(self.contentSize.width/2+8, self.contentSize.height/2-14);
    }
    costCoin = [[[[GameDB shared] getGlobalConfig] objectForKey:@"feteCoin2Num"] intValue];

    // 虎纹，龙纹帅印
	//int tigerId = [[GameConfigure shared] getItemIdByName:@"虎纹帅印"];
    int tigerId = [[GameConfigure shared] getItemIdByName:NSLocalizedString(@"sacrifice_tiger_stamp",nil)];
	CCSprite *tigerSeal = getItemIcon(tigerId);
    tigerSeal.position = ccp(self.contentSize.width/2-357, self.contentSize.height/2+140);
    [self addChild:tigerSeal z:1];
    
	//int dragonId = [[GameConfigure shared] getItemIdByName:@"龙纹帅印"];
    int dragonId = [[GameConfigure shared] getItemIdByName:NSLocalizedString(@"sacrifice_dragon_stamp",nil)];
	CCSprite *dragonSeal = getItemIcon(dragonId);
    dragonSeal.position = ccp(self.contentSize.width/2-357, self.contentSize.height/2+37);
    [self addChild:dragonSeal z:1];
    
//    NSString *tigerName = @"虎纹帅印";
//    NSString *dragonName = @"龙纹帅印";
//    int tigerId = -1;
//    int dragonId = -1;
//    
//    NSDictionary *itemsDict = [[GameDB shared] readDB:@"item"];
//    for (NSString *key in [itemsDict allKeys])
//    {
//        NSDictionary *dict = [itemsDict objectForKey:key];
//        NSString *name = [dict objectForKey:@"name"];
//        if ([name isEqualToString:tigerName]) {
//            tigerId = [[dict objectForKey:@"id"] intValue];
//        } else if ([name isEqualToString:dragonName]) {
//            dragonId = [[dict objectForKey:@"id"] intValue];
//        }
//        
//        if (tigerId != -1 && dragonId != -1) {
//            break;
//        }
//    }
    
    int tigerSealCount = [[GameConfigure shared] getPlayerItemCountByIid:tigerId];
    int dragonSealCount = [[GameConfigure shared] getPlayerItemCountByIid:dragonId];
    
    tigerLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", tigerSealCount] fontName:getCommonFontName(FONT_1) fontSize:16];
    tigerLabel.anchorPoint = ccp(0, 0.5);
    tigerLabel.position = ccp(self.contentSize.width/2-310, self.contentSize.height/2+143);
    tigerLabel.color = ccc3(235, 180, 70);
    [self addChild:tigerLabel z:1];
    
    dragonLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", dragonSealCount] fontName:getCommonFontName(FONT_1) fontSize:16];
    dragonLabel.anchorPoint = ccp(0, 0.5);
    dragonLabel.position = ccp(self.contentSize.width/2-310, self.contentSize.height/2+40);
    dragonLabel.color = ccc3(235, 180, 70);
    [self addChild:dragonLabel z: 1];
    if (iPhoneRuningOnGame()) {
        CCSprite * pic1 = [CCSprite spriteWithFile:@"images/ui/wback/pic_iphone.png"];
        [self addChild:pic1];
        
        CCSprite * pic2 = [CCSprite spriteWithFile:@"images/ui/wback/pic_iphone.png"];
		[self addChild:pic2];
		
		if (isIphone5()) {
			pic1.position = ccp(100/2.0f+44, self.contentSize.height-60/2.0f-pic1.contentSize.height/2.0f);
		}else{
			pic1.position = ccp(100/2.0f+88, self.contentSize.height-60/2.0f-pic1.contentSize.height/2.0f);
		}
		pic2.position = ccp(pic1.position.x,pic1.position.y-pic1.contentSize.height/2-pic2.contentSize.height/2-10);
        
        tigerSeal.position = ccp(pic1.position.x-pic1.contentSize.width/2.0f+10+tigerSeal.contentSize.width/2, pic1.position.y);
        dragonSeal.position = ccp(pic2.position.x-pic2.contentSize.width/2.0f+10+dragonSeal.contentSize.width/2, pic2.position.y);
        tigerLabel.position = ccp(pic1.position.x-pic1.contentSize.width/2.0f+90/2.0f+5, pic1.position.y+5/2.0f);
        tigerLabel.scale = 0.7;
        dragonLabel.position = ccp(pic2.position.x-pic2.contentSize.width/2.0f+90/2.0f+5,pic2.position.y+5/2.0f);
        dragonLabel.scale = 0.7;
    }
    
	NSArray *freeBtns = getBtnSpriteWithStatus(@"images/ui/button/bt_pray");
	//end
	freeItem = [CCMenuItemSprite itemWithNormalSprite:[freeBtns objectAtIndex:0]
                                       selectedSprite:[freeBtns objectAtIndex:1]
                                               target:self
                                             selector:@selector(getSealTapped:)];
    freeItem.tag = Sacrifice_Button_Free;
    if (iPhoneRuningOnGame()) {
		freeItem.scale=1.5f;
        freeItem.position = ccp(self.contentSize.width/2+8/2, 37/2.0f);
    }else{
        freeItem.position = ccp(self.contentSize.width/2+8, self.contentSize.height/2-180);
    }
	freeItem.visible = NO;
    
	NSArray *goldBtns = getBtnSpriteWithStatus(@"images/ui/button/bt_gold_pray");
	//end
	goldItem = [CCMenuItemSprite itemWithNormalSprite:[goldBtns objectAtIndex:0]
                                       selectedSprite:[goldBtns objectAtIndex:1]
                                               target:self
                                             selector:@selector(getSealTapped:)];
    goldItem.tag = Sacrifice_Button_Gold;
    if (iPhoneRuningOnGame()) {
		goldItem.position=freeItem.position;
		goldItem.scale=freeItem.scale;
//        goldItem.position = ccp(self.contentSize.width/2+8/2, self.contentSize.height/2-220/2);
    }else{
        goldItem.position = ccp(self.contentSize.width/2+8, self.contentSize.height/2-180);
    }
	goldItem.visible = NO;
    
    // 祭天按钮说明
    buttonInfo = [CCLabelTTF labelWithString:@"" fontName:getCommonFontName(FONT_1) fontSize:14];
    buttonInfo.color = ccc3(254, 236, 130);
    if (iPhoneRuningOnGame()) {
        buttonInfo.position = ccp(self.contentSize.width/2+200/2 + 30, self.contentSize.height/2-216/2);
        buttonInfo.scale = 0.7;
    }else{
        buttonInfo.position = ccp(self.contentSize.width/2+200, self.contentSize.height/2-180);
//    ruleButton.position = ccp(self.contentSize.width-cFixedScale(130), self.contentSize.height- cFixedScale(40));
	}
	
    [self addChild:buttonInfo];
    
    CCMenu *menu = [CCMenu menuWithItems:freeItem, goldItem, nil];
    menu.position = ccp(0, 0);
    [self addChild:menu];
    
	CCSimpleButton *toRecruit = [CCSimpleButton spriteWithFile:@"images/ui/button/bt_torecruit_1.png"
														select:@"images/ui/button/bt_torecruit_2.png"
														target:self
														  call:@selector(doToRecruit)];
    if (iPhoneRuningOnGame()) {
		toRecruit.scale=1.5f;
		if (isIphone5()) {
			toRecruit.position = ccp(60, 37/2.0f);
		}else{
			toRecruit.position = ccp(60+44, 37/2.0f);
		}
    }else{
	toRecruit.position = ccp(104, 71);
	}
	[self addChild:toRecruit];
    
    // 获取祭天剩余次数
    [GameConnection request:@"enterFete" data:[NSDictionary dictionary] target:self call:@selector(didEnterFete:)];
}

-(void)doToRecruit
{
    if (isBusy) return;
    
	[[Window shared] showWindow:PANEL_RECRUIT];
}

-(void)updatePanel
{
    //buttonInfo.string = (freeCount > 0) ? [NSString stringWithFormat:@"今日免费祭天次数：%d", freeCount] : [NSString stringWithFormat:@"今日元宝祭天剩余次数：%d\n元宝祭天可大幅提高龙纹帅印出现概率", goldCount];
    buttonInfo.string = (freeCount > 0) ? [NSString stringWithFormat:NSLocalizedString(@"sacrifice_free_count",nil), freeCount] : [NSString stringWithFormat:NSLocalizedString(@"sacrifice_yuanbao_count",nil), goldCount];
    freeItem.visible = (freeCount > 0);
    goldItem.visible = !(freeCount > 0) && (goldCount > 0);
	
//	int tigerId = [[GameConfigure shared] getItemIdByName:@"虎纹帅印"];
//	int dragonId = [[GameConfigure shared] getItemIdByName:@"龙纹帅印"];
    int tigerId = [[GameConfigure shared] getItemIdByName:NSLocalizedString(@"sacrifice_tiger_stamp",nil)];
	int dragonId = [[GameConfigure shared] getItemIdByName:NSLocalizedString(@"sacrifice_dragon_stamp",nil)];
	int tigerSealCount = [[GameConfigure shared] getPlayerItemCountByIid:tigerId];
    int dragonSealCount = [[GameConfigure shared] getPlayerItemCountByIid:dragonId];
    tigerLabel.string = [NSString stringWithFormat:@"%d", tigerSealCount];
	dragonLabel.string = [NSString stringWithFormat:@"%d", dragonSealCount];
}

-(void)didEnterFete:(id)sender
{
    if (checkResponseStatus(sender)) {
        NSDictionary *dict = getResponseData(sender);
        if (dict) {
            freeCount = [[dict objectForKey:@"num1"] intValue];
            goldCount = [[dict objectForKey:@"num2"] intValue];
            
            // 更新界面
            [self updatePanel];
        }
    } else {
        CCLOG(@"获取祭天数据失败");
    }
}

-(void)showSealAnimation:(BOOL)isFree
{
    CCNode *child = [self getChildByTag:Tag_Seal];
    if (child) {
        [child removeFromParentAndCleanup:YES];
    }
    
    AnimationViewer *sealAnima = [AnimationViewer node];
    if (iPhoneRuningOnGame()) {
        sealAnima.scale = 1.37f;
    }
    sealAnima.tag = Tag_Seal;
    sealAnima.position = sealPoint;
    [self addChild:sealAnima];
    
	// 播放获得前动画
    NSString *fullPath = [NSString stringWithFormat:@"images/animations/seal/%d/", 10];
    NSArray *sealFrames = [AnimationViewer loadFileByFileFullPath:fullPath name:@"%d.png"];
    id call = [CCCallFunc actionWithTarget:self selector:@selector(getSeal)];
    [sealAnima playAnimation:sealFrames delay:0.08 call:call];
    
    if (isFree) {
        freeCount--;
        if (freeCount < 0) {
            freeCount = 0;
        }
    } else {
        goldCount--;
        if (goldCount < 0) {
            goldCount = 0;
        }
    }
	
	if (freeCount <= 0 && goldCount <= 0) {
        freeItem.visible = NO;
		goldItem.visible = NO;
    }
}

-(void)showMessageWithName:(NSString*)name count:(int)count
{
	int iid = [[GameConfigure shared] getItemIdByName:name];
	NSDictionary *dict = [[GameDB shared] getItemInfo:iid];
	if (dict) {
		ItemQuality quality = [[dict objectForKey:@"quality"] intValue];
		//[ShowItem showItemAct:[NSString stringWithFormat:@"获得|%@%@|x%d", name, getHexColorByQuality(quality), count]];
        [ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"sacrifice_get",nil), name, getHexColorByQuality(quality), count]];
	}
}

// 获取帅印
-(void)getSeal
{
	// 显示当前获得图腾
	CCNode *child = [self getChildByTag:Tag_Seal];
    if (child) {
        [child removeFromParentAndCleanup:YES];
    }
    
    AnimationViewer *sealAnima = [AnimationViewer node];
    sealAnima.tag = Tag_Seal;
    if (iPhoneRuningOnGame()) {
        sealAnima.scale = 1.37f;
    }
    sealAnima.position = sealPoint;
    [self addChild:sealAnima];
    
    NSString *fullPath = [NSString stringWithFormat:@"images/animations/seal/%d/", currentSealType];
    NSArray *sealFrames = [AnimationViewer loadFileByFileFullPath:fullPath name:@"%d.png"];
    [sealAnima playAnimation:sealFrames delay:0.08];
	
    switch (currentSealType) {
        case Seal_Tiger:
        {
			//[self showMessageWithName:@"虎纹帅印" count:currentSealCount];
            [self showMessageWithName:NSLocalizedString(@"sacrifice_tiger_stamp",nil) count:currentSealCount];
        }
            break;
        case Seal_Dragon:
        {
			//[self showMessageWithName:@"龙纹帅印" count:currentSealCount];
            [self showMessageWithName:NSLocalizedString(@"sacrifice_dragon_stamp",nil) count:currentSealCount];
        }
            break;
        case Seal_Deer:
        {
			//[ShowItem showItemAct:@"呃……本次祭天一无所获"];
            [ShowItem showItemAct:NSLocalizedString(@"sacrifice_nothing",nil)];
        }
            break;
        case Seal_Phoenix:
        {
			//[ShowItem showItemAct:@"下个祭天效果翻倍（可累计）"];
            [ShowItem showItemAct:NSLocalizedString(@"sacrifice_multiple",nil)];
        }
            break;
        default:
            break;
    }
    [self updatePanel];
}

-(void)getSealEventByType:(BOOL)isFree
{
    NSString *type = [NSString stringWithFormat:@"type::%d", (isFree ? 1 : 2)];
    NSMutableDictionary *t_dict = [NSMutableDictionary dictionary];
    [t_dict setObject:(isFree ? @"YES" : @"NO") forKey:@"isFree"];
    [GameConnection request:@"fete" format:type target:self call:@selector(didGetSeal::) arg:t_dict];
}

-(void)didGetSeal:(id)sender :(NSDictionary *)data
{
    if (checkResponseStatus(sender)) {
        NSDictionary *dict = getResponseData(sender);
        if (dict) {
            // 类型
            int frid = [[dict objectForKey:@"frid"] intValue];
            NSDictionary *feteDict = [[GameDB shared] getFeteRateInfo:frid];
            if (feteDict) {
                int act = [[feteDict objectForKey:@"act"] intValue];
                switch (act) {
                    case 1:
                        currentSealType = Seal_Tiger;
                        break;
                    case 2:
                        currentSealType = Seal_Dragon;
                        break;
                    case 3:
                        currentSealType = Seal_Deer;
                        break;
                    case 4:
                        currentSealType = Seal_Phoenix;
                        break;
                    
                    default:
                        break;
                }
            } else {
                CCLOG(@"祭天数据不存在");
            }
			
			NSDictionary *itemUpdateData = [[GameConfigure shared] getItemUpdateData:dict];
			NSString *key = [[itemUpdateData allKeys] lastObject];
			currentSealCount = [[itemUpdateData objectForKey:key] intValue];
            
            BOOL isFree = [[data objectForKey:@"isFree"] boolValue];
            
            // 更新背包数据
            [[GameConfigure shared] updatePackage:dict];
            
            // 播放获取动画
            [self showSealAnimation:isFree];
        }
    } else {
		[ShowItem showErrorAct:getResponseMessage(sender)];
    }
}

-(void)setButtonBusy
{
	isBusy = NO;
}

-(void)getSealTapped:(id)sender
{
	if (isBusy) {
//		[ShowItem showItemAct:@"祭天过于频繁"];
		return;
	} else {
		isBusy = YES;
		//[self schedule:@selector(setButtonBusy) interval:1.5];
		[self scheduleOnce:@selector(setButtonBusy) delay:1.5f];
	}
	
    if (freeCount <= 0 && goldCount <= 0) {
		//[ShowItem showItemAct:@"今天祭天次数已满"];
        [ShowItem showItemAct:NSLocalizedString(@"sacrifice_full",nil)];
        return;
    }
    
    CCMenuItemSprite *item = (CCMenuItemSprite *)sender;
    if (item.tag == Sacrifice_Button_Free) {
        
        // 免费获取帅印
        CCLOG(@"免费获取帅印");
        [self getSealEventByType:YES];
        
    } else if (item.tag == Sacrifice_Button_Gold) {
        
        NSDictionary *playerInfo = [[GameConfigure shared] getPlayerInfo];
        int coin2 = [[playerInfo objectForKey:@"coin2"] intValue];
        int coin3 = [[playerInfo objectForKey:@"coin3"] intValue];
        
        // 需消耗元宝
        if (coin3 + coin2 >= costCoin) {
			BOOL isRecordSacrifice = [[[GameConfigure shared] getPlayerRecord:NO_REMIND_SACRIFICE] boolValue];
			if (isRecordSacrifice) {
				[self confirmUseGold];
			} else {
				//NSString *message = [NSString stringWithFormat:@"是否花费|%d#ff0000|元宝进行祭天",costCoin];
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"sacrifice_spend",nil),costCoin];
				[[AlertManager shared] showMessageWithSettingFormFather:message target:self confirm:@selector(confirmUseGold) key:NO_REMIND_SACRIFICE father:self];
			}
        }
        // 元宝不够
        else {
			//[ShowItem showItemAct:@"元宝不足"];
            [ShowItem showItemAct:NSLocalizedString(@"sacrifice_no_yuanbao",nil)];
        }
    }
}

// 确认用元宝购买
-(void)confirmUseGold
{
    [self getSealEventByType:NO];
}

-(void)onExit
{
	[GameConnection freeRequest:self];
	
	[super onExit];
}

@end
