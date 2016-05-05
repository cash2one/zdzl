//
//  UnionCat.m
//  TXSFGame
//
//  Created by Max on 13-3-27.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionCat.h"
#import "CCSimpleButton.h"
#import "Window.h"
#import "ClickAnimation.h"

@implementation UnionCat

-(void)onEnter{
	[super onEnter];

	CCSprite *img=[CCSprite spriteWithFile:@"images/ui/union/imagecat.jpg"];
	btn_doMoney=[CCSimpleButton spriteWithFile:@"images/ui/union/btn_domoney.png"];
	if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
			img.scaleY=1.12f;
			img.scaleX=1.16f;
			btn_doMoney.scale=1.3f;
			[img setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2-cFixedScale(15))];
			[btn_doMoney setPosition:ccp(cFixedScale(770)+44, cFixedScale(100))];
        }else{
			img.scaleY=1.12f;
			img.scaleX=1.16f;
			btn_doMoney.scale=1.3f;
			[img setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2-cFixedScale(15))];
			[btn_doMoney setPosition:ccp(cFixedScale(770)+44, cFixedScale(100))];
        }
    }else{
		[img setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2-cFixedScale(20))];
		[btn_doMoney setPosition:ccp(cFixedScale(670), cFixedScale(100))];
	}
	
	[btn_doMoney setTarget:self];
	
	[btn_doMoney setCall:@selector(callBackdoMoney)];
	
	[self addChild:img];
	[self addChild:btn_doMoney z:1];
	
	[GameConnection request:@"actiInfo" format:@"allyOnly::1" target:self call:@selector(didGetAllyEvent:)];
}


-(void)didGetAllyEvent:(NSDictionary*)dict{
	CCLOG(@"%@",dict);
	if(checkResponseStatus(dict)){
		dict=getResponseData(dict);
		int catcount=[[dict objectForKey:@"cat"]integerValue];
		
		NSString *tips=@"";
		if(catcount>0){
			//tips=[NSString stringWithFormat:@"今天剩余招财次数：%i次",catcount];
            tips=[NSString stringWithFormat:NSLocalizedString(@"union_cat_count",nil),catcount];
		}else{
			//tips=[NSString stringWithFormat:@"今日的招财进宝次数已经用完"];
            tips=[NSString stringWithFormat:NSLocalizedString(@"union_cat_count_over",nil)];
			[btn_doMoney setVisible:NO];
		}
		if(moneystr){
			[moneystr removeFromParentAndCleanup:true];
			moneystr=nil;
		}
		float fontSize=16;
		float lineHeight=18;
		float rectH=30;
		NSString* color=@"ffffff";
		if (iPhoneRuningOnGame()) {
			rectH=40;
			fontSize=22;
			lineHeight=28;
		}
		moneystr=drawString(tips, CGSizeMake(400, rectH), getCommonFontName(FONT_1), fontSize, lineHeight,color);
		if (iPhoneRuningOnGame()) {
			[moneystr setPosition:ccp(770/2.0f+44, 165/2.0f)];
		}else{
			[moneystr setPosition:ccp(670, 150)];
		}
		[self addChild:moneystr z:1];
	}
}

-(void)onExit{
	[super onExit];
}

-(void)callBackdoMoney{
	[GameConnection request:@"allyCat" format:@"" target:self call:@selector(didAllyCat:)];
}

-(void)didAllyCat:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		NSDictionary * data = getResponseData(response);
		if(data){
			//NSString *mstr[3]={@"银币",@"元宝",@"绑元宝"};
            NSString *mstr[3]={NSLocalizedString(@"union_cat_coin1",nil),NSLocalizedString(@"union_cat_coin2",nil),NSLocalizedString(@"union_cat_coin3",nil)};
			for(int i=0;i<3;i++){
				int coin=[[data objectForKey:[NSString stringWithFormat:@"coin%i",(i+1)]]integerValue];
				int mecoin=[[[[GameConfigure shared]getPlayerInfo] objectForKey:[NSString stringWithFormat:@"coin%i",(i+1)]]integerValue];
				if((coin-mecoin)>1){
					//[ShowItem showItemAct:[NSString stringWithFormat:@"获得 %@ X %i",mstr[i],coin-mecoin]];
                    [ShowItem showItemAct:[NSString stringWithFormat:NSLocalizedString(@"union_cat_get",nil),mstr[i],coin-mecoin]];
				}
			}
			[[GameConfigure shared] updatePackage:data];
			[GameConnection request:@"actiInfo" format:@"allyOnly::1" target:self call:@selector(didGetAllyEvent:)];
            CGPoint pos = ccp(self.contentSize.width/2, self.contentSize.height/2);
            float scale_x = 1.0f;
            float scale_y = 1.0f;
            if (iPhoneRuningOnGame()) {
                scale_x = 1.16f;
                scale_y = 1.12f;
                pos.y -= 15/2;
            }else{
                pos.y -= 15;
            }
            [ClickAnimation showInLayer:self z:0 tag:555 call:nil point:pos scaleX:scale_x scaleY:scale_y path:@"images/animations/catEffects/" loop:NO];
		}
	}else{
		CCLOG(@"error allyCat");
	}
}

@end
