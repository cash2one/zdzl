//
//  MailList.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-6.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "MailList.h"
#import "CCSimpleButton.h"
#import "GameMail.h"
#import "CCPanel.h"
#import "MailViewer.h"
#import "Config.h"
#import "Window.h"
#import "MainMenu.h"
#import "Arena.h"
#import "GameConfigure.h"
#import "PlayerSit.h"

static MailList * mailList = nil;
static BOOL isFirstShow = YES;

@implementation MailList

+(MailList*)shared{
	return mailList;
}

+(void)moveTop{
	
	return;
	if(mailList){
		
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		
		int th = 160;
		if(iPhoneRuningOnGame()){
			th /= 2;
		}
		/*
		id move = [CCMoveTo actionWithDuration:0.8f position:ccp(winSize.width/2,th)];
		id ease = [CCEaseElasticOut actionWithAction:move period:0.8f];
		[mailList runAction:ease];
		*/
		
		mailList.position = ccp(winSize.width/2,th);
		
	}
}

+(void)moveDown{
	
	return;
	
	if(mailList){
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		id move = nil;
		if(iPhoneRuningOnGame()){
			move = [CCMoveTo actionWithDuration:0.8f position:ccp(winSize.width/2,5)];
		}else{
			move = [CCMoveTo actionWithDuration:0.8f position:ccp(winSize.width/2,10)];
		}
		id ease = [CCEaseElasticOut actionWithAction:move period:0.8f];
		[mailList runAction:ease];
	}
}

-(void)onEnter{
	[super onEnter];
	
	mailList = self;
	
	btns = [[NSMutableArray alloc] init];
	[GameMail shared].targetList = self;
	
	if(iPhoneRuningOnGame()){
		content = [CCLayerColor layerWithColor:ccc4(0,0,0,0) width:90 height:30];
	}else{
		content = [CCLayerColor layerWithColor:ccc4(0,0,0,0) width:180 height:60];
	}
	if (iPhoneRuningOnGame()) {
		content.position = ccp(-content.contentSize.width/2,-15);
	}else{
		content.position = ccp(-content.contentSize.width/2,0);
	}
	[self addChild:content];
	
	
	//[self showMailList];
	
}

-(void)onExit{
	
	mailList = nil;
	
	if(btns){
		[btns release];
		btns = nil;
	}
	
	[GameMail shared].targetList = nil;
	[super onExit];
}

-(void)showMailList{
	
	if([[GameConfigure shared] isPlayerOnChapter]){
		return;
	}
	
	int total = 0;
	int count = 3;
	NSDictionary * fightMail = [[GameMail shared] checkRewardTypeByFight];
	NSDictionary * rewardMail = [[GameMail shared] checkRewardTypeByReward];
	if(fightMail!=nil){
		count--;
		int mid = [[fightMail objectForKey:@"id"] intValue];
		if(![self checkHasMailInList:mid]){
			CCSimpleButton * btn = [CCSimpleButton spriteWithFile:@"images/ui/mail/btn-2.png"];
			btn.tag = mid;
			btn.anchorPoint = ccp(0.5,0.5);
			btn.target = self;
			btn.call = @selector(doSelect:);
			[btns addObject:btn];
		}
		total++;
	}
	if(rewardMail!=nil){
		count--;
		int mid = [[rewardMail objectForKey:@"id"] intValue];
		if(![self checkHasMailInList:mid]){
			CCSimpleButton * btn = [CCSimpleButton spriteWithFile:@"images/ui/mail/btn-3.png"];
			btn.tag = mid;
			btn.anchorPoint = ccp(0.5,0.5);
			btn.target = self;
			btn.call = @selector(doSelect:);
			[btns addObject:btn];
		}
		total++;
	}
	
	count = min(count, [[GameMail shared] getCountByType:Mail_type_message]);
	
	for(int i=0; i<count; i++){
		
		NSDictionary * mail = [[GameMail shared] getMailByIndex:i type:Mail_type_message];
		int mid = [[mail objectForKey:@"id"] intValue];
		
		if(![self checkHasMailInList:mid]){
			
			CCSimpleButton * btn = [CCSimpleButton spriteWithFile:@"images/ui/mail/btn-1.png"];
			
			btn.tag = mid;
			btn.anchorPoint = ccp(0.5,0.5);
			btn.target = self;
			btn.call = @selector(doSelect:);
			
			[btns addObject:btn];
		}
		total++;
	}
	
	if(total>0){
		
		int tw = 60;
        int off_h = 0;
		if(iPhoneRuningOnGame()){
            tw *= 1.3f;
			tw /= 2;
            //off_h += 6;
		}
		
		int w = (content.contentSize.width-(tw*total))/2;
		
		for(int i=0; i<[btns count]; i++){
			CCSimpleButton * btn = [btns objectAtIndex:i];
			if(!btn.parent){
                if (iPhoneRuningOnGame()) {
                    btn.scale = 1.3f;
                }
				[content addChild:btn];
				btn.position = ccp(content.contentSize.width+tw,tw/2+off_h);
			}
			
			if(isFirstShow){
				btn.position = ccpAdd(ccp(w+(tw)*i,0),ccp(tw/2,tw/2+off_h));
                CCLOG(@"is first ----");
			}else{
                [btn stopAllActions];
				CCMoveTo * move = [CCMoveTo actionWithDuration:0.25 position:ccpAdd(ccp(w+(tw)*i,0),ccp(tw/2,tw/2+off_h))];
				[btn runAction:move];
                CCLOG(@"is no first ----");
			}
			
		}
	}
	
	isFirstShow = NO;
}

-(BOOL)checkHasMailInList:(int)mid{
	for(CCNode * node in btns){
		if(node.tag==mid){
			return YES;
		}
	}
	return NO;
}

-(void)removeMailAction:(int)mid{
	CCNode * target = nil;
	for(CCNode * node in btns){
		if(node.tag==mid){
			target = node;
			break;
		}
	}
	if(target){
		[btns removeObject:target];
		[target removeFromParentAndCleanup:YES];
	}
}

-(void)doSelect:(CCNode*)node{
	
	if ([[Window shared] isHasWindow]) {
		return ;
	}
	
	if ([Arena arenaIsOpen]) {
		return ;
	}
    
	if (iPhoneRuningOnGame() && [PlayerSit isPlayerShowSit]) {
        return;
    }
    
	[[Window shared] removeAllWindows];
	
	//[btns removeObject:node];
	//[node removeFromParentAndCleanup:YES];
	//[[GameMail shared] removeMailById:node.tag];
	
	NSDictionary * mail = [[GameMail shared] getMailById:node.tag];
	
	if([[mail objectForKey:@"t"] intValue]==Mail_type_message){
		[MailViewer show:node.tag];
	}
	if([[mail objectForKey:@"t"] intValue]==Mail_type_reward){
		[[Window shared] showWindow:PANEL_REWARD];
	}
	/*
	if([[mail objectForKey:@"t"] intValue]==Mail_type_fight){
		[MailViewer show:node.tag];
	}
	*/
	
}

@end
