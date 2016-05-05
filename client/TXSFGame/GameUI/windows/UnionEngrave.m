//
//  UnionEngrave.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-30.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "UnionEngrave.h"
#import "Window.h"
#import "CCSimpleButton.h"
#import "UnionManager.h"
#import "CCLabelFX.h"
#import "GameMoney.h"
#import "GameConnection.h"
#import "InfoAlert.h"
#include "MessageBox.h"

@implementation UnionEngrave
//fix chao
//_id is allay_grave table id
-(CCSprite*)getEngraveItemWithID:(int)_id level:(int)level{

    CCSprite *reSpr = nil;
    NSDictionary *dict = [[GameDB shared] getAllyGrave:_id];
    int type = [[dict objectForKey:@"t"] intValue];
    //
    int quality = 0;
    int exp = 0;
    int coin1 = 0; 
    int coin2 = 0;
    int coin3 = 0;

    NSString *name = nil;
    int qualityArr[6] = {1,2,3,1,2,3};
    //NSString *nameArr[6] = {@"普通铭刻",@"灵咒铭刻",@"真言铭刻",@"VIP普通铭刻",@"VIP中级铭刻",@"VIP高级铭刻",};
    NSString *nameArr[6] = {
        NSLocalizedString(@"union_engrave_type1",nil),
        NSLocalizedString(@"union_engrave_type2",nil),
        NSLocalizedString(@"union_engrave_type3",nil),
        NSLocalizedString(@"union_engrave_type4",nil),
        NSLocalizedString(@"union_engrave_type5",nil),
        NSLocalizedString(@"union_engrave_type6",nil),};
    if (dict) {
        if (type>0 && type<7 && level>0 && level<11) {
            
            name = nameArr[type-1];
            quality = qualityArr[type-1];
            exp = [[dict objectForKey:[NSString stringWithFormat:@"lv%darm",level]] intValue];
            coin1 = [[dict objectForKey:@"coin1"] intValue];
            coin2 = [[dict objectForKey:@"coin2"] intValue];
            coin3 = [[dict objectForKey:@"coin3"] intValue];
            ////
            reSpr = [CCSprite spriteWithFile:@"images/ui/union/item-bg.png"];
			if (iPhoneRuningOnGame()) {
				reSpr.scaleY=1.15f;
				reSpr.scaleX=1.2f;
			}
			
            CCSprite * qualitySpr = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/common/quality%d.png",quality]];
            CCSprite * unionQualitySpr = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/union/union_quality%d.png",quality]];
            unionQualitySpr.position = ccp(qualitySpr.contentSize.width/2,qualitySpr.contentSize.height/2);
            [qualitySpr addChild:unionQualitySpr];
			if (iPhoneRuningOnGame()) {
				qualitySpr.position = ccp(50/2.0f,95/2.0f);
			}else{
				qualitySpr.position = ccp(55,95);
			}
            [reSpr addChild:qualitySpr];
            qualitySpr.scale = 0.9;
            //
            CCSimpleButton * btn = [CCSimpleButton spriteWithFile:@"images/ui/button/bts_union_engrave_1.png"
                                                            select:@"images/ui/button/bts_union_engrave_2.png"];
            btn.position = ccp(cFixedScale(110),cFixedScale(25));
            btn.tag = 1000+_id;
            [reSpr addChild:btn];
            btn.target = self;
            btn.call = @selector(doStartEngrave:);
            //
			/*
			CCLabelFX * nameLabel = [CCLabelFX labelWithString:name
													dimensions:CGSizeMake(0,0)
													 alignment:kCCTextAlignmentCenter
													  fontName:GAME_DEF_CHINESE_FONT
													  fontSize:24
												  shadowOffset:CGSizeMake(-1.5, -1.5)
													shadowBlur:2.0f];
			*/ 
			CCSprite *nameLabel=drawString(name, CGSizeMake(100, 30), getCommonFontName(FONT_1), 22, 26, getQualityColorStr(quality));
                       nameLabel.anchorPoint = ccp(0.5, 0.5);
            nameLabel.position = ccp(150,120);
			
			//Kevin added, adjust to iphone//
			if (iPhoneRuningOnGame()) {
				btn.scale=1.2f;
				nameLabel.position = ccp( 137/2.0f, 120/2.0f);
			}
			//-----------------------------//
			
            [reSpr addChild:nameLabel];
            //
//            CCLabelFX * info1 = [CCLabelFX labelWithString:[NSString stringWithFormat:@"炼历:+%d",exp]
//                                                dimensions:CGSizeMake(0,0)
//                                                 alignment:kCCTextAlignmentCenter
//                                                  fontName:GAME_DEF_CHINESE_FONT
//                                                  fontSize:18
//                                              shadowOffset:CGSizeMake(-1.5, -1.5)
//                                                shadowBlur:2.0f];
            CCLabelFX * info1 = [CCLabelFX labelWithString:[NSString stringWithFormat:NSLocalizedString(@"union_engrave_traini",nil),exp]
                                                dimensions:CGSizeMake(0,0)
                                                 alignment:kCCTextAlignmentCenter
                                                  fontName:GAME_DEF_CHINESE_FONT
                                                  fontSize:18
                                              shadowOffset:CGSizeMake(-1.5, -1.5)
                                                shadowBlur:2.0f];
			info1.anchorPoint = ccp(0.5, 0.5);
            info1.position = ccp(150,90);
			
			//Kevin added, adjust to iphone//
			if (iPhoneRuningOnGame()) {
				info1.anchorPoint = ccp( 0, 0.5);
				info1.position = ccp(80/2.0f, 90/2.0f);
			}
			//--------------------------//
			
            [reSpr addChild:info1];
            //
//            CCLabelFX * coinLabel = [CCLabelFX labelWithString:@"消耗:"
//                                                dimensions:CGSizeMake(0,0)
//                                                 alignment:kCCTextAlignmentCenter
//                                                  fontName:GAME_DEF_CHINESE_FONT
//                                                  fontSize:18
//                                              shadowOffset:CGSizeMake(-1.5, -1.5)
//                                                shadowBlur:2.0f];
            CCLabelFX * coinLabel = [CCLabelFX labelWithString:NSLocalizedString(@"union_engrave_expend",nil)
                                                    dimensions:CGSizeMake(0,0)
                                                     alignment:kCCTextAlignmentCenter
                                                      fontName:GAME_DEF_CHINESE_FONT
                                                      fontSize:18
                                                  shadowOffset:CGSizeMake(-1.5, -1.5)
                                                    shadowBlur:2.0f];
            coinLabel.anchorPoint = ccp(0.5, 0.5);
            coinLabel.position = ccp(120,65);
			
			//Kevin added, adjust to iphone//
			if (iPhoneRuningOnGame()) {
				coinLabel.anchorPoint = ccp(0, 0.5);
				coinLabel.position = ccp(80/2.0f, 65/2.0f);
			}
			//--------------------------//
			
            [reSpr addChild:coinLabel];
            //
            int h = cFixedScale(65);
			float dw=0;
			if (iPhoneRuningOnGame()) {
				dw=8;
			}
            if (coin3>0) {
                GameMoney * m1 = [GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_TWO value:coin3];
                m1.anchorPoint = ccp(0,0.5);
                m1.position = ccp(cFixedScale(145-dw),h);
                [reSpr addChild:m1];
            }else if(coin2>0){
                GameMoney * m1 = [GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_ONE value:coin2];
                m1.anchorPoint = ccp(0,0.5);
                m1.position = ccp(cFixedScale(145-dw),h);
                [reSpr addChild:m1];
            }else{
                GameMoney * m1 = [GameMoney gameMoneyWithType:GAMEMONEY_YIBI value:coin1];
                m1.anchorPoint = ccp(0,0.5);
                m1.position = ccp(cFixedScale(145-dw),h);
                [reSpr addChild:m1];
            }
        }
    }
    
    return reSpr;
}

-(void)didEngraveBaseInfo:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		NSDictionary * data = getResponseData(response);
		
//        CGSize winSize = [[CCDirector sharedDirector] winSize];
        //NSDictionary *dict = [[GameConfigure shared] getPlayerInfo];
        //NSNumber *vip= [dict objectForKey:@"vip"];
        
        int level = [[[data objectForKey:@"ally"] objectForKey:@"level"] intValue];
        
        for (int i=1; i<4;i++) {
            [self removeChildByTag:1000+i cleanup:YES];
            CCSprite *it = [self getEngraveItemWithID:i level:level];
            if (it) {
                it.anchorPoint = ccp(0,1);
				if (iPhoneRuningOnGame()) {
//					if (isIphone5()) {
//						it.position = ccp(568/2.0f-cFixedScale(548)+44,self.contentSize.height/2+cFixedScale(250)-(i-1)*cFixedScale(178));
//					}else{
//						it.position = ccp(568/2.0f-cFixedScale(548),self.contentSize.height/2+cFixedScale(250)-(i-1)*cFixedScale(178));
//					}
                    it.position = ccp(568/2.0f-cFixedScale(548)+44,self.contentSize.height/2+cFixedScale(250)-(i-1)*cFixedScale(178));
				}else{
					it.position = ccp(self.contentSize.width/2-400,self.contentSize.height/2+220-(i-1)*170);
				}
                [self addChild:it z:1 tag:1000+i];
            }
            
        }
        
    }
}
-(void)resetEngraveItem{
    [GameConnection request:@"allyOwn" format:@"" target:self call:@selector(didEngraveBaseInfo:)];
    } 
//end
-(void)onEnter{
	[super onEnter];
	
//	CGSize winSize = [[CCDirector sharedDirector] winSize];
	
	MessageBox* right=[MessageBox create:CGPointZero color:ccc4(74, 51, 21,255)];
	if (iPhoneRuningOnGame()) {
		[self addChild:right];
		right.contentSize=CGSizeMake(651/2.0f, 549/2.0f);
//		if (isIphone5()) {
//			right.position=ccp(299/2.0f+44,32/2.0f);
//		}else{
//			right.position=ccp(299/2.0f,32/2.0f);
//		}
        right.position=ccp(299/2.0f+44,32/2.0f);
	}
	
	CCSprite * image = [CCSprite spriteWithFile:@"images/ui/union/image.jpg"];
	image.anchorPoint = ccp(0,1);
	if (iPhoneRuningOnGame()) {
		[right addChild:image];
		image.scale=1.107f;
		image.position = ccp(2.25f,right.contentSize.height-1.75f);
	}else{
		image.position = ccp(self.contentSize.width/2-170,self.contentSize.height/2+220);
		[self addChild:image];
	}
    
	float w=230,h=492;
	if (iPhoneRuningOnGame()) {
		w=284;
		h=548;
	}
	
    CCSprite *bound=[StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(w) height:cFixedScale(h) capx:cFixedScale(8) capy:cFixedScale(8)];
	if (iPhoneRuningOnGame()) {
//		if (isIphone5()) {
//			[bound setPosition:ccp(bound.contentSize.width/2.0f+4+44,self.contentSize.height/2.0f-7)];
//		}else{
//			[bound setPosition:ccp(bound.contentSize.width/2.0f+4,self.contentSize.height/2.0f-7)];
//		}
        [bound setPosition:ccp(bound.contentSize.width/2.0f+4+44,self.contentSize.height/2.0f-7)];
	}else{
		[bound setPosition:ccpAdd(image.position, ccp(-bound.contentSize.width/2-7, -bound.contentSize.height/2) )];
	}
	[self addChild:bound];
    
    [self resetEngraveItem];
}
-(void)doStartEngrave:(CCNode*)sender{
	
	CCSimpleButton * btn1 = (CCSimpleButton*)[[self getChildByTag:1001] getChildByTag:1001];
	CCSimpleButton * btn2 = (CCSimpleButton*)[[self getChildByTag:1002] getChildByTag:1002];
	CCSimpleButton * btn3 = (CCSimpleButton*)[[self getChildByTag:1003] getChildByTag:1003];
	btn1.target = nil;
	btn2.target = nil;
	btn3.target = nil;
	
	NSString * fm = [NSString stringWithFormat:@"type::%d",(sender.tag-1000)];
	[GameConnection request:@"allyGrave" format:fm target:self call:@selector(didAllyGrave:)];
}

-(void)didAllyGrave:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		
		NSDictionary * data = getResponseData(response);
		if(data){
			//NSString *mstr[4]={@"银币",@"元宝",@"绑元宝",@"炼历"};
            NSString *mstr[4]={
                NSLocalizedString(@"union_engrave_coin1",nil),
                NSLocalizedString(@"union_engrave_coin2",nil),
                NSLocalizedString(@"union_engrave_coin3",nil),
                NSLocalizedString(@"union_engrave_train",nil)};
			NSString *mkey[4]={@"coin1",@"coin2",@"coin3",@"train"};
			for(int i=0;i<4;i++){
				int coin=[[data objectForKey:mkey[i+1]]integerValue];
				int mecoin=[[[[GameConfigure shared]getPlayerInfo] objectForKey:mkey[i+1]]integerValue];
				if((coin-mecoin)>1){
					//[ShowItem showItemAct:[NSString stringWithFormat:@"获得%@ X %i",mstr[i+1],coin-mecoin]];
                    [ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_engrave_get",nil),mstr[i+1],coin-mecoin]];
				}
			}
			[[GameConfigure shared] updatePackage:data];
			[[AlertManager shared]showReceiveItem:data];
			
		}
		
		[[Window shared] removeAllWindows];
		
	}else{
		CCLOG(@"error allyGrave");
		
		CCSimpleButton * btn1 = (CCSimpleButton*)[[self getChildByTag:1001] getChildByTag:1001];
		CCSimpleButton * btn2 = (CCSimpleButton*)[[self getChildByTag:1002] getChildByTag:1002];
		CCSimpleButton * btn3 = (CCSimpleButton*)[[self getChildByTag:1003] getChildByTag:1003];
		btn1.target = self;
		btn2.target = self;
		btn3.target = self;
		[ShowItem showErrorAct:getResponseMessage(response)];
	}
}

-(void)onExit{
	[UnionManager endCurrentAction];
	[super onExit];
}

-(void)dealloc{
	[super dealloc];
	CCLOG(@"UnionEngrave dealloc");
}

@end
