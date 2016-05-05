//
//  intro.m
//  TXSFGame
//
//  Created by Max on 13-1-26.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "intro.h"
#import "GameUI.h"
#import "GameLoading.h"







@implementation Intro


#define BG1 @"images/ui/intro/talkBg_l.png"
#define BG2 @"images/ui/intro/talkBg_u.png"
#define BG3 @"images/ui/intro/talkBg_d.png"
#define BG4 @"images/ui/intro/notalkBg.png"
#define FIRESELECT @"images/ui/intro/select.png"
#define CURRENTIPS 0xabc
#define COLORSTR ccc3(49 ,18 ,7)





static Intro *intro;
static int currenStep=-2;
static bool isOpenMMission=false;




+(Intro*)share{
	if(!intro){
		intro =[Intro node];
		intro.visible=NO;
	}
	return intro;
}


+(BOOL)isIntroOpen{
	return [Intro share].visible;
}

+(void)stopAll{
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	if(intro){
		[intro removeFromParentAndCleanup:YES];
		intro = nil;
	}
}



-(void)onEnter{
	[super onEnter];
	//isOnEnter=YES;
	if(isForce){
		[[[CCDirector sharedDirector]touchDispatcher]addTargetedDelegate:self priority:INT16_MIN swallowsTouches:YES];
		
	}
}





-(void)showCurrenTips{
	if(self.visible) return;
	
	if([GameLoading isShowing]){
		[self scheduleOnce:@selector(doShowTips) delay:1.5f];
	}else{
		[self scheduleOnce:@selector(doShowTips) delay:0.69f];
	}
	
}

-(void)doShowTips{
	if(isLogo && [[GameUI shared] isOpenMainMenu]){
		[self setVisible:YES];
	}else if(!isLogo && [[Window shared]isHasWindow] && !isIntoNode){
		[self setVisible:YES];
	}
	if(isIntoNode){
		[self setVisible:YES];
	}
}

-(void)hideCurrenTips{
	if(![[GameConfigure shared]isPlayerOnChapter]){
		[self setVisible:NO];
		[self unschedule:@selector(doShowTips)];
	}
}



+(IntroStep)getCurrenStep{
	return currenStep;
}

+(void)resetCurrenStep{
	currenStep=-2;
}


-(void)runIntroTask:(IntroStep)_step{
	
	switch (_step) {
		case INTRO_NOTHING:
		{
			//[self runIntroTagerPoint:INTRO_START_Move];
		}
			break;
		case INTRO_OPEN_MMission:
		{
			isOpenMMission=true;
			[self runIntroTagerPoint:INTRO_OPEN_MMission];
		}
			break;
		default:
			break;
	}
	
}


-(void)runIntroUnLockTask:(Unlock_object)uno{
	if(uno==Unlock_mine){
		[NSTimer scheduledTimerWithTimeInterval:1.0f target:self
									   selector:@selector(delayShowUnLockMenuBtnTip:)
									   userInfo:[NSNumber numberWithInt:BT_HAMMER_TAG]
										repeats:NO];
	}
}

-(void)delayShowUnLockMenuBtnTip:(NSTimer*)tag{
	CCSimpleButton *b=[[MainMenu share]getButtonWithTag:[[tag userInfo] integerValue]];
	[self runIntroTager:b step:INTRO_ENTER_Mining];
}

#pragma mark 在世界范围生成tips
-(void)runIntroTagerPoint:(int)_step{
	if(currenStep==-2){
		currenStep=[[[GameConfigure shared]getPlayerCliAttr:@"introstep"]integerValue];
		currenStep=currenStep<=0?1:currenStep;
	}
	if(currenStep>_step){
		return;
	}
	if(currenStep==_step && self.visible){
		return;
	}
	[self setPosition:ccp(0, 0)];
	currenStep=_step;
    [[GameConfigure shared] setPlayerCliAttr:@"introstep" value:[NSNumber numberWithInt:currenStep]];
    //-//
	NSDictionary *db=[[GameDB shared]getIntro:currenStep];
	dir=[[db objectForKey:@"dir"]integerValue];
	type=[[db objectForKey:@"type"]integerValue];
	isForce=[[db objectForKey:@"force"]integerValue];
	
	isLogo=[[db objectForKey:@"islogo"]integerValue];
	content=[db objectForKey:@"content"];
	
	
	[[Game shared] addChild:self z:INT32_MAX];
	size=CGSizeMake(121, 121);
	point=ccp(940, 630);
	[self makeTips];
	
}



#pragma mark 在世界范围生成tips
-(void)runIntroTager:(CCNode*)node step:(int)_step{
	if(currenStep==-2){
		currenStep=[[[GameConfigure shared]getPlayerCliAttr:@"introstep"]integerValue];
		currenStep=currenStep<=0?1:currenStep;
	}
	if(_step>currenStep){
		self.visible=NO;
		[self removeAllChildrenWithCleanup:true];
	}
	
	if(self.visible || currenStep>_step){
		return;
	}
	if(currenStep==_step && self.visible){
		return;
	}
	[self removeAllChildrenWithCleanup:true];
	currenStep=_step;
    [[GameConfigure shared] setPlayerCliAttr:@"introstep" value:[NSNumber numberWithInt:currenStep]];
    //-//
	currenTager=node;
	isIntoNode=false;
	[self setPosition:ccp(0, 0)];
	NSDictionary *db=[[GameDB shared]getIntro:currenStep];
	dir=[[db objectForKey:@"dir"]integerValue];
	type=[[db objectForKey:@"type"]integerValue];
	isForce=[[db objectForKey:@"force"]integerValue];
	
	isLogo=[[db objectForKey:@"islogo"]integerValue];
	content=[db objectForKey:@"content"];
	if([db objectForKey:@"dropPosition"]!=nil && ![[db objectForKey:@"dropPosition"] isEqualToString:@""]){
		NSString *poskey=iPhoneRuningOnGame()?@"dropPositionIP":@"dropPosition";
		
		
		
		int x=[[[[db objectForKey:poskey] componentsSeparatedByString:@":"]objectAtIndex:0]intValue];
        //
        if (isIphone5() ) {
            if (INTRO_Hammer_Step_1 == currenStep ||
                INTRO_GuangXing_Step_1 == currenStep ||
                INTRO_Phalanx_Step_1 == currenStep) {
                x += 80;
            }
        
        }
        
        
		int y=[[[[db objectForKey:poskey] componentsSeparatedByString:@":"]objectAtIndex:1]intValue];
		CGPoint _point=ccp(cFixedScale(x),cFixedScale(y));
		dropPos=[NSValue valueWithCGPoint:_point];
		[dropPos retain];
	}
	
	
	[self setPosition:CGPointZero];
	[[Game shared] addChild:self z:INT32_MAX];
	
	point=[currenTager.parent convertToWorldSpace:currenTager.position];
	anpoint=currenTager.anchorPoint;
	size=currenTager.contentSize;
	self.visible=NO;
	[self makeTips];
}

#pragma mark 在某个CCNODE生成tips
-(void)runIntroInTager:(CCNode*)node step:(int)_step{
	currenTager=nil;
	if(currenStep==-2){
		currenStep=[[[GameConfigure shared]getPlayerCliAttr:@"introstep"]integerValue];
		currenStep=currenStep<=0?1:currenStep;
	}
	
	if(currenStep>_step){
		return;
	}
	
	if(!tips){
		if(currenStep==_step && tips.visible){
			return;
		}
	}
	currenStep=_step;
    [[GameConfigure shared] setPlayerCliAttr:@"introstep" value:[NSNumber numberWithInt:currenStep]];
    //-//
	currenTager=node;
	NSDictionary *db=[[GameDB shared]getIntro:currenStep];
	dir=[[db objectForKey:@"dir"]integerValue];
	type=[[db objectForKey:@"type"]integerValue];
	isForce=[[db objectForKey:@"force"]integerValue];
	isLogo=[[db objectForKey:@"islogo"]integerValue];
	content=[db objectForKey:@"content"];
	if([content isEqual:nil]){
		content=@"";
	}
	
	
	isInto=true;
	isIntoNode=true;
	self.visible=NO;
	//[self retain];
	[self makeTips];
}

-(void)runBackIntro{
    if(currenStep==-2){
		currenStep=[[[GameConfigure shared]getPlayerCliAttr:@"introstep"]integerValue];
		currenStep=currenStep<=0?1:currenStep;
	}
    //
	currenStep-=1;
    [[GameConfigure shared] setPlayerCliAttr:@"introstep" value:[NSNumber numberWithInt:currenStep]];
    //-//
	NSString *var=[NSString stringWithFormat:@"key:introstep|value:%i",currenStep];
	[GameConnection request:@"cliAttrSet" format:var target:nil call:nil];
	[self removeFromParentAndCleanup:true];
}


-(void)makeTips{
	[self showCurrenTips];
	AnimationViewer *fire_logo = nil;
	
	int moveh=0;
	int movev=0;
	int movehsrc=0;
	int movevsrc=0;
	if(isLogo){
		if(![[GameUI shared] isOpenMainMenu]){
			[self hideCurrenTips];
			return;
		}
		if(![[GameUI shared] isShowUI]){
			[self hideCurrenTips];
			return;
		}
		
		NSArray *frame=[AnimationViewer loadFileByFileFullPath:@"images/ui/intro/fire/" name:@"%d.png"];
		fire_logo=[AnimationViewer node];
		[fire_logo playAnimation:frame];
		[fire_logo setPosition:ccp(point.x, point.y)];
		[self addChild:fire_logo];
	}
	
	switch (dir) {
		case 1:{
			if(type==1){
				tips=[CCSprite spriteWithFile:BG2];
				CCLabelTTF *label=[CCLabelTTF labelWithString:content fontName:getCommonFontName(FONT_3) fontSize:18];
				[label setPosition:ccp(tips.contentSize.width/2, tips.contentSize.height/2-label.contentSize.height/2)];
				[label setColor:COLORSTR];
				[tips addChild:label];
				[tips setPosition:ccp(point.x,point.y-size.height-30)];
				movev=20;
				movevsrc=-20;
				
				if(iPhoneRuningOnGame()){
					label.scale = 0.6;
					movev=-10;
					movevsrc=10;
					[tips setPosition:ccp(point.x,point.y-size.height-15)];
				}
			}
		}
			break;
		case 2:{
			if(type==1){
				tips=[CCSprite spriteWithFile:BG3];
				CCLabelTTF *label=[CCLabelTTF labelWithString:content fontName:getCommonFontName(FONT_3) fontSize:18];
				[label setPosition:ccp(tips.contentSize.width/2, tips.contentSize.height/2+10)];
				[tips addChild:label];
				[label setColor:COLORSTR];
				
				[tips setPosition:ccp(point.x-30, point.y+size.height)];
				
				movev=-20;
				movevsrc=20;
				
				if(iPhoneRuningOnGame()){
					label.scale = 0.6;
					[label setPosition:ccp(tips.contentSize.width/2, tips.contentSize.height/2+5)];
					[tips setPosition:ccp(point.x-15, point.y+size.height)];
					movev=-10;
					movevsrc=10;
				}
			}
		}
			break;
		case 3:{
			if(type==1){
				tips=[CCSprite spriteWithFile:BG1];
				[tips setFlipX:YES];
				CCLabelTTF *label=[CCLabelTTF labelWithString:content fontName:getCommonFontName(FONT_3) fontSize:18];
				[label setPosition:ccp(tips.contentSize.width/2+10, tips.contentSize.height/2)];
				[tips setPosition:ccp(point.x+size.width/2+tips.contentSize.width/2, point.y)];
				[tips addChild:label];
				[label setColor:COLORSTR];
				moveh=20;
				movehsrc=-20;
				
				if(iPhoneRuningOnGame()){
					label.scale = 0.6;
					[label setPosition:ccp(tips.contentSize.width/2+5, tips.contentSize.height/2)];
					[tips setPosition:ccp(point.x+tips.contentSize.width/2+20, point.y)];
					moveh=10;
					movehsrc=-10;
				}
			}
		}
			break;
		case 4:{
			if(type==1){
				tips=[CCSprite spriteWithFile:BG1];
				CCLabelTTF *label=[CCLabelTTF labelWithString:content fontName:getCommonFontName(FONT_3) fontSize:18];
				[label setPosition:ccp(tips.contentSize.width/2-10, tips.contentSize.height/2)];
				[label setColor:COLORSTR];
				[tips addChild:label];
				[tips setPosition:ccp(point.x-size.width/2-tips.contentSize.width/2, point.y)];
				moveh=-20;
				movehsrc=20;
				
				if(iPhoneRuningOnGame()){
					label.scale = 0.6;
					[label setPosition:ccp(tips.contentSize.width/2-5, tips.contentSize.height/2)];
					[tips setPosition:ccp(point.x-size.width/2-tips.contentSize.width/2, point.y)];
					moveh=10;
					movehsrc=-10;
				}
			}
		}
			break;
		default:
			break;
	}
	id act=[CCMoveBy actionWithDuration:0.5 position:ccp(moveh, movev)];
	id act1=[CCMoveBy actionWithDuration:0.5 position:ccp(movehsrc, movevsrc)];
	id seq=[CCSequence actions:act,act1,nil];
	id loop=[CCRepeatForever actionWithAction:seq];
	
	
	//生成手指
	if(dropPos){
		tips.visible=false;
		CCSprite *fg=[CCSprite spriteWithFile:@"images/ui/intro/fg.png"];
		[fg setScale:0.5];
		[fg setAnchorPoint:ccp(0, 1)];
		[fg setPosition:point];
		[self addChild:fg];
		id def=[CCDelayTime actionWithDuration:1];
		id fact=[CCMoveTo actionWithDuration:1 position:dropPos.CGPointValue];
		
		id call=[CCCallBlock actionWithBlock:^{
			[fg setPosition:point];
		}];
		id dee=[CCDelayTime actionWithDuration:1];
		id sq=[CCSequence actions:def,fact,dee,call,nil];
		id ff=[CCRepeatForever actionWithAction:sq];
		[fg runAction:ff];
		
		[dropPos release];
	}
	
	if(tips){
		[tips runAction:loop];
		if(isInto){
			[currenTager addChild:tips z:INT_MAX];
		}else{
			[self addChild:tips];
		}
	}
	
	
}


-(void)removeInCurrenTipsAndNextStep:(int)step{
    if(currenStep==-2){
		currenStep=[[[GameConfigure shared]getPlayerCliAttr:@"introstep"]integerValue];
		currenStep=currenStep<=0?1:currenStep;
	}
    //
	if(!currenTager){
		return;
	}
	if(step>=currenStep){
		if(!currenTager){
			return;
		}
		CCLOG(@"%@ ,%@",tips,currenTager);
		currenStep=step+1;
        [[GameConfigure shared] setPlayerCliAttr:@"introstep" value:[NSNumber numberWithInt:currenStep]];
        //-//
		NSString *var=[NSString stringWithFormat:@"key:introstep|value:%i",currenStep];
		[GameConnection request:@"cliAttrSet" format:var target:nil call:nil];
		[tips removeFromParentAndCleanup:true];
	}
}
//
-(void)removeCurrenTipsAndNextStep:(int)step{
    if(currenStep==-2){
		currenStep=[[[GameConfigure shared]getPlayerCliAttr:@"introstep"]integerValue];
		currenStep=currenStep<=0?1:currenStep;
	}
    //
	if(step==INTRO_OPEN_MMission && currenStep!=INTRO_OPEN_MMission)
	{
		return;
	}
	
	if(step==INTRO_MMission_Step_1 && currenStep<INTRO_OPEN_MMission){
		return;
	}
	
	if(step==INTRO_OPEN_MMission && currenStep==INTRO_OPEN_MMission){
		if(isOpenMMission){
			currenStep=INTRO_MMission_Step_1;
            [[GameConfigure shared] setPlayerCliAttr:@"introstep" value:[NSNumber numberWithInt:currenStep]];
            //-//
			NSString *var=[NSString stringWithFormat:@"key:introstep|value:%i",currenStep];
			[GameConnection request:@"cliAttrSet" format:var target:nil call:nil];
			[self removeAllChildrenWithCleanup:true];
			[self removeFromParentAndCleanup:true];
		}
		return;
	}
	if(step>=currenStep){
		currenStep=step+1;
        [[GameConfigure shared] setPlayerCliAttr:@"introstep" value:[NSNumber numberWithInt:currenStep]];
        //-//
		NSString *var=[NSString stringWithFormat:@"key:introstep|value:%i",currenStep];
		[GameConnection request:@"cliAttrSet" format:var target:nil call:nil];
		[self removeFromParentAndCleanup:true];
		
	}
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	CGPoint tpoint=getGLpoint(touch);
	CGRect rect=CGRectMake(point.x-size.width/2, point.y-size.height/2, size.width, size.height);
	
	if(CGRectContainsPoint(rect, tpoint)){
		return NO;
	}
	return YES;
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	[ShowItem showItemAct:content];
}


-(void)onExit{
	[super onExit];
	intro = nil;
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	if(isForce){
		[[[CCDirector sharedDirector]touchDispatcher]removeDelegate:self];
	}
}


-(void)dealloc{
	if(intro.retainCount==1){
		intro=nil;
	}
	[super dealloc];
	
}


@end
