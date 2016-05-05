//
//  ShowItem.m
//  TXSFGame
//
//  Created by Max on 13-1-12.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ShowItem.h"
#import "Game.h"
#import "TaskTalk.h"
#import "GameLoading.h"

@implementation ShowItem

//@synthesize itemTips;
static int alertBase=0;
static int alertBaseTemp=0;
static int isRealy=true;

static NSMutableArray *tipslist;
//static bool listActisOpen=false;
static int pos[6]={130,110,90,70,50};

static NSTimer * showTimer;

+(void)stopAll{
	
	alertBase = 0;
	alertBaseTemp = 0;
	isRealy = YES;
	
	if(showTimer){
		[showTimer invalidate];
		showTimer = nil;
	}
	
	
}

+(void)showErrorAct:(id)key{
	int errorid =[key integerValue];
	[ShowItem showItemAct:[[GameDB shared]getErrorMsg:errorid]];
}

+(void)showItemAct:(NSString*)itemTipsString{
	if([itemTipsString length]<1){
		return;
	}
	
	/*
	if(!listActisOpen){
		[NSTimer scheduledTimerWithTimeInterval:0.5 target:[ShowItem class] 
									   selector:@selector(PlayAct) 
									   userInfo:nil repeats:YES];
		tipslist =[[NSMutableArray alloc]init];
		listActisOpen=true;
	}
	*/
	
	if(tipslist == nil){
		tipslist =[[NSMutableArray alloc]init];
		
	}
	[tipslist addObject:itemTipsString];
	
	[self PlayAct];
	
}

+(void)PlayAct{
	
	showTimer = nil;
	
	if(tipslist.count==0){
		return;
	}
	
	if(!isRealy){
		[self checkNext];
		return;
	}
	
	//屏幕上有5个不显示
	if(alertBase>5){
		[self checkNext];
		return;
	}
	
	//战斗中不显示
	if([FightManager isFighting]){
		return;
	}
	if([TaskTalk isTalking]){
		return;
	}
	if([GameLoading isShowing]){
		return;
	}
	alertBase++;
	alertBaseTemp++;
	if(alertBase>5){
		isRealy=false;
		[self checkNext];
		return;
	}
	
	NSString *tipstr=[tipslist objectAtIndex:0];
	CGSize p=[[CCDirector sharedDirector] winSize];
	CCSprite *ci=nil;
	//
	if(iPhoneRuningOnGame()){
		ci=drawString(tipstr, CGSizeMake(500, 20), getCommonFontName(FONT_1), 24, 28, @"ffff00");
		[ci setPosition:ccp(p.width/2.0f, p.height/2.0f+50)];
	}else{
		ci=drawString(tipstr, CGSizeMake(500, 10), getCommonFontName(FONT_1), 20, 22, @"ffff00");
		[ci setPosition:ccp(p.width/2.0f, p.height/2.0f+100)];
	}
	
	float ty = pos[alertBase-1];
	if(iPhoneRuningOnGame()){
		ty = ty/2-10;
	}
	id act=[CCMoveBy actionWithDuration:1 position:ccp(0, ty)];
	
	id acteast=[CCEaseIn actionWithAction:act rate:0.3];
	id actdaley=[CCDelayTime actionWithDuration:3];
	id actap=[CCFadeTo actionWithDuration:1 opacity:0];
	
	id actright=nil;
	if(iPhoneRuningOnGame()){
		actright=[CCMoveBy actionWithDuration:1 position:ccp(alertBase%2==0?10:-10, 0)];
	}else{
		actright=[CCMoveBy actionWithDuration:1 position:ccp(alertBase%2==0?20:-20, 0)];
	}
	id actapandactright=[CCSpawn actions:actap,actright, nil];
	
	CCCallFuncND *fun=[CCCallFuncND actionWithTarget:[ShowItem class] selector:@selector(tipsFinlish:data:) data:ci];
	id seq=[CCSequence actions:acteast,actdaley,actapandactright,fun,nil];
	[ci runAction:seq];
	
	[[Game shared] addChild:ci z:INT32_MAX-10];
	[tipslist removeObjectAtIndex:0];
	
	[self checkNext];
	
}

+(void)removeAllTips{
	[tipslist removeAllObjects];
	[tipslist release];
	tipslist = nil;
}

+(void)tipsFinlish:(id)fun data:(id)_data{
	CCNode *data=(CCNode*)_data;
	[data removeFromParentAndCleanup:true];
	alertBaseTemp--;
	if(alertBaseTemp<=1){
		alertBase=0;
		alertBaseTemp=0;
		isRealy=true;
	}
	//CCLOG(@"纪录：%i",alertBaseTemp);
}


+(void)checkNext{
	if(showTimer){
		[showTimer invalidate];
		showTimer = nil;
	}
	showTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:[ShowItem class] 
											   selector:@selector(PlayAct) 
											   userInfo:nil repeats:NO];
}


@end
