//
//  GameMoneyMini.m
//  TXSFGame
//
//  Created by chao chen on 13-3-6.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "GameMoneyMini.h"
#import "GameConfigure.h"
#import "GameMoney.h"

@implementation GameMoneyMini



-(void)onEnter{
	[super onEnter];
	
	CCSprite *_object = (CCSprite*)[self getChildByTag:8111];
	if (!_object) {
		_object = [CCSprite spriteWithFile:@"images/ui/panel/pMining.png"];
		self.contentSize = _object.contentSize;
		[self addChild:_object z:0 tag:8111];
		_object.position = ccp(self.contentSize.width/2,self.contentSize.height/2);
	}
	
	
	NSDictionary *player = [[GameConfigure shared] getPlayerInfo];
	if (player) {
		int coin1 = [[player objectForKey:@"coin1"] intValue];
		int coin2 = [[player objectForKey:@"coin2"] intValue];
		int coin3 = [[player objectForKey:@"coin3"] intValue];
		
		GameMoney *m1 = (GameMoney*)[self getChildByTag:8000];
		GameMoney *m2 = (GameMoney*)[self getChildByTag:8001];
		GameMoney *m3 = (GameMoney*)[self getChildByTag:8002];
		
		if (!m1) {
			m1=[GameMoney gameMoneyWithType:GAMEMONEY_YIBI value:coin1];
			[self addChild:m1 z:1 tag:8000];
			m1.anchorPoint=ccp(0, 0);
		}
		else {
			[m1 setMoneyValue:coin1];
		}
		if (!m2) {
			m2=[GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_ONE value:coin2];
			[self addChild:m2 z:1 tag:8001];
			m2.anchorPoint=ccp(0, 0);
		}
		else {
			[m2 setMoneyValue:coin2];
		}
		if (!m3) {
			m3=[GameMoney gameMoneyWithType:GAMEMONEY_YUANBAO_TWO value:coin3];
			[self addChild:m3 z:1 tag:8002];
			m3.anchorPoint=ccp(0, 0);
		}
		else {
			[m3 setMoneyValue:coin3];
		}
		if (iPhoneRuningOnGame()) {
            m2.position = ccp(20/2, self.contentSize.height - 30/2);
            m3.position = ccp(20/2 + m2.contentSize.width + 4/2, self.contentSize.height - 30/2);
            m1.position = ccp(20/2, self.contentSize.height - 60/2);
        }else{
		m2.position = ccp(20, self.contentSize.height - 30);
		m3.position = ccp(20 + m2.contentSize.width + 4, self.contentSize.height - 30);
		m1.position = ccp(20, self.contentSize.height - 60); 
        }
    }
	[GameConnection addPost:ConnPost_updatePlayerInfo target:self call:@selector(updateAll)];
}
-(void)onExit{
	[GameConnection removePostTarget:self];
	//
	[super onExit];
}
-(void)updateAll{
	NSDictionary *player = [[GameConfigure shared] getPlayerInfo];
	if (player) {
		int coin1 = [[player objectForKey:@"coin1"] intValue];
		int coin2 = [[player objectForKey:@"coin2"] intValue];
		int coin3 = [[player objectForKey:@"coin3"] intValue];
		[self updateMoneyWithCoin1:coin1 coin2:coin2 coin3:coin3];
	}
}
-(void)updateMoneyWithCoin1:(NSInteger)coin1 coin2:(NSInteger)coin2 coin3:(NSInteger)coin3{
	GameMoney* m1 = (GameMoney* )[self getChildByTag:8000];
	[m1 setMoneyValue:coin1];
	GameMoney* m2 = (GameMoney* )[self getChildByTag:8001];
	[m2 setMoneyValue:coin2];
	GameMoney* m3 = (GameMoney* )[self getChildByTag:8002];
	[m3 setMoneyValue:coin3];
	if (m3) {
        if (iPhoneRuningOnGame()) {
            m3.position = ccp(20/2 + m2.contentSize.width + 4/2, self.contentSize.height - 30/2);
        }else
            m3.position = ccp(20 + m2.contentSize.width + 4, self.contentSize.height - 30);
	}
}

-(void)setCoin:(int)type count:(int)c{
	switch (type) {
		case 1:
		{
			GameMoney* m1 = (GameMoney* )[self getChildByTag:8000];
			[m1 setMoneyValue:c];
			
		}
			break;
		case 2:
		{
			GameMoney* m1 = (GameMoney* )[self getChildByTag:8001];
			[m1 setMoneyValue:c];
		}
			break;
		case 3:
		{
			GameMoney* m1 = (GameMoney* )[self getChildByTag:8002];
			[m1 setMoneyValue:c];
		}
			break;
		default:
			break;
	}

}

-(int)getCoin:(int)type{
	switch (type) {
		case 1:
		{
			GameMoney* m1 = (GameMoney* )[self getChildByTag:8000];
			return  [m1 moneyValue];
		}
			break;
		case 2:
		{
			GameMoney* m2 = (GameMoney* )[self getChildByTag:8001];
			return  [m2 moneyValue];
		}
			break;
		case 3:
		{
			GameMoney* m3 = (GameMoney* )[self getChildByTag:8002];
			return  [m3 moneyValue];
		}
			break;
		default:
			break;
	}
	return 0;
	
}
@end
