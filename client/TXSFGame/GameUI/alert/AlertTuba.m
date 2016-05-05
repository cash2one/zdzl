//
//  AlertTuba.m
//  TXSFGame
//
//  Created by Max on 13-3-8.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "AlertTuba.h"
#import "TaskTalk.h"

#define LEFTRIGHTMOVEDIS  cFixedScale(280)
#define SPEED cFixedScale(0.5)

static NSMutableArray *allPostList;
static NSMutableArray *allPostList_Tmp;

static CCSprite* getAlertTubaSprite(NSString* content ,
									NSString* fontName,
									NSString* colorStr,
									int fontSize,
									int lineHeight){
	
	lineHeight = cFixedScale(lineHeight);
	
	NSMutableArray* array = [NSMutableArray array];
	if (content != nil) {
		NSArray* tds = [content componentsSeparatedByString:@"|"];
		int skipDisplay = 0;
		for (NSString* iteater in tds) {
			if(skipDisplay<2){
				skipDisplay++;
				continue;
			}
		
			NSArray *parts = [iteater componentsSeparatedByString:@"#"];
			NSString *strContent = nil;
			
			
			int __fontSize = cFixedScale(fontSize) ;
			ccColor3B __color = (colorStr != nil)?color3BWithHexString(colorStr):ccWHITE;
			NSString *strFontName = nil;
			
			if (fontName != nil) {
				strFontName = [NSString stringWithFormat:@"%@",fontName];
			}
			
			if (parts.count > 0) {
				strContent = [NSString stringWithFormat:@"%@",[parts objectAtIndex:0]];
			}
			
			if (parts.count > 1) {
				__color = color3BWithHexString([parts objectAtIndex:1]);
			}
			
			if (parts.count > 2) {
				__fontSize = [[parts objectAtIndex:2] intValue]==0?__fontSize:cFixedScale([[parts objectAtIndex:2] intValue]);
			}
			
			if (parts.count > 3) {
				int findex = [[parts objectAtIndex:3] intValue];
				strFontName = [NSString stringWithFormat:@"%@",getCommonFontName(findex)];
			}
			CCLabelTTF * label = [CCLabelTTF labelWithString:strContent
												   fontName:strFontName
												   fontSize:__fontSize];
			//CCSprite *label= drawString(strContent, CGSizeMake(500, 40), getCommonFontName(0), 18, 20, @"ffffff");
			label.color = __color;
			label.verticalAlignment = kCCVerticalTextAlignmentCenter;
			label.horizontalAlignment = kCCTextAlignmentLeft;
			label.anchorPoint = ccp(0, 0.5);
			
			[array addObject:label];
		}
	}
	CCSprite* sprite = [CCSprite node];
	float startX = cFixedScale(2);
	for (CCLabelTTF* label in array) {
		[sprite addChild:label];
		label.position = ccp(startX, lineHeight/2);
		startX += label.contentSize.width;
		startX += cFixedScale(2) ;
	}
	sprite.contentSize = CGSizeMake(startX+cFixedScale(2), lineHeight);
	return sprite;
}

static AlertTuba *alertTuba;


@implementation TubaContent



-(void)setTarget:(AlertTuba*)_target{
	target=_target;
}

/*
 -(void)setPostList:(NSMutableArray*)list{
 postlist =[[NSMutableArray alloc]initWithArray:list];
 [self creatShowListAndMove];
 }
 */
-(void)onEnter{
	[super onEnter];
	//CCLayerColor *cl=[CCLayerColor layerWithColor:ccc4(20, 100, 255, 255)];
	//[self addChild:cl];
}


-(void)creatShowListAndMove:(NSMutableArray*)postlist{
	int length=0;
	CCNode *parent=[CCNode node];
	float fontSize=16;
	float lineHight=18;
	if (iPhoneRuningOnGame()) {
		fontSize=30;
		lineHight=36;
	}
	for(NSString *str in postlist){
		//CCSprite *label= drawStringForEvent(str, CGSizeMake(3000, 30), getCommonFontName(FONT_1), fontSize, lineHight, @"ffff00");
		
		//todo 缺少包边字
		//....
		CCSprite *label= getAlertTubaSprite(str,
											getCommonFontName(FONT_1),
											@"ffff00",
											fontSize,
											lineHight);
		
		if(iPhoneRuningOnGame()){
			[label setPosition:ccp(length, -1)];
		}else{
			[label setPosition:ccp(length, 3)];
		}
		
		[label setAnchorPoint:ccp(0, 0)];
		
		if(iPhoneRuningOnGame()){
			length+=label.contentSize.width+40;
		}else{
			length+=label.contentSize.width+80;
		}
		
		[parent addChild:label];
	}
	[parent setIgnoreAnchorPointForPosition:NO];
	[parent setAnchorPoint:ccp(0, 0)];
	if(iPhoneRuningOnGame()){
		[parent setContentSize:CGSizeMake(length, 15)];
		[parent setPosition:ccp(785/2, target.screenSize.height*0.77)];
	}else{
		[parent setContentSize:CGSizeMake(length, 30)];
		[parent setPosition:ccp(785, target.screenSize.height*0.78)];
	}
	
	
	int needmovelengh=(length+cFixedScale(520));
	
	id move=[CCMoveBy actionWithDuration:needmovelengh/50 position:ccp(needmovelengh*-1, 0)];
	id bfun=[CCCallBlock actionWithBlock:^{
		if(allPostList_Tmp){
			[self creatShowListAndMove:allPostList_Tmp];
			[allPostList_Tmp removeAllObjects];
			[allPostList_Tmp release];
			allPostList_Tmp=nil;
		}else{
			[target closeTuBa];
			[self removeFromParentAndCleanup:true];
		}
	}];
	id seq=[CCSequence actions:move,bfun, nil];
	[parent runAction:seq];
	[self addChild:parent];
}


-(void)onExit{
	[super onExit];
}

-(void)dealloc{
	[super dealloc];
}

-(void)visit{
	float cutSizeW=target.contentSize.width;
	float cutSizeWShow=520;
	float cutSiztHShow=0;
	if(target.contentSize.width==568){
		cutSizeW=1136;
	}
	if(target.contentSize.width==480){
		cutSizeW=960;
	}
	glScissor(cutSizeW/2-cutSizeWShow/2, cutSiztHShow, cutSizeWShow, 1000);
	glEnable(GL_SCISSOR_TEST);
    [super visit];
	glDisable(GL_SCISSOR_TEST);
}


@end



@implementation AlertTuba

@synthesize screenSize;


+(AlertTuba*)share{
	if(!alertTuba){
		alertTuba=[AlertTuba node];
		Game *root=[Game shared];
		[root addChild:alertTuba z:INT32_MAX];
	}
	return alertTuba;
}

-(void)onEnter{
	[super onEnter];
	//[NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(showTuBa) userInfo:nil repeats:YES];
	[self schedule:@selector(showTuBa) interval:3.0f];
}

-(void)addPost:(NSString*)string{
	
	if(!isOpen){
		if(allPostList==nil ){
			allPostList=[[NSMutableArray alloc]init];
			[allPostList addObject:string];
		}else{
			[allPostList addObject:string];
		}
	}else{
		if(allPostList_Tmp==nil ){
			allPostList_Tmp=[[NSMutableArray alloc]init];
			[allPostList_Tmp addObject:string];
		}else{
			[allPostList_Tmp addObject:string];
		}
	}
}


-(void)showTuBa{
	if(allPostList==nil || allPostList.count<1)return;
	if(isOpen){
		return;
	}
	if ([TaskTalk isTalking])return;
	screenSize=[CCDirector sharedDirector].winSize;
	
	isOpen=true;
	tc=[TubaContent node];
	[tc setVisible:NO];
	[tc setTarget:self];
	left=[CCSprite spriteWithFile:@"images/ui/chat/left-s.png"];
	rigth=[CCSprite spriteWithFile:@"images/ui/chat/left-s.png"];
	if (iPhoneRuningOnGame()) {
		left.scale=1.25f;
		rigth.scale=1.25f;
	}
	float height=33;
	if (iPhoneRuningOnGame()) {
		height=20;
	}
	bg =[CCLayerColor layerWithColor:ccc4(50, 50, 50, 200) width:1 height:height];
	[bg setIgnoreAnchorPointForPosition:NO];
	[bg setAnchorPoint:ccp(0.5, 0.5)];
	
	[bg setPosition:ccp(screenSize.width/2, screenSize.height*0.8)];
	[left setPosition:ccp(screenSize.width/2, screenSize.height*0.8)];
	[rigth setPosition:ccp(screenSize.width/2, screenSize.height*0.8)];
	
	[left setOpacity:0];
	[rigth setOpacity:0];
	
	
	id ap1=[CCFadeIn actionWithDuration:SPEED];
	id ap2=[CCFadeIn actionWithDuration:SPEED];
	id delay=[CCDelayTime actionWithDuration:SPEED];
	
	
	
	id movetoleft=[CCMoveBy actionWithDuration:SPEED position:ccp(LEFTRIGHTMOVEDIS*-1, 0)];
	id movetoright=[CCMoveBy actionWithDuration:SPEED position:ccp(LEFTRIGHTMOVEDIS, 0)];
	id scaletox=[CCScaleBy actionWithDuration:SPEED scaleX:cFixedScale(552) scaleY:1];
	
	id bfun=[CCCallBlock actionWithBlock:^{
		[tc setVisible:YES];
		
		[tc creatShowListAndMove:allPostList];
		[allPostList release];
		allPostList=nil;
	}];
	
	id seq1=[CCSequence actions:ap1,movetoleft, nil];
	id seq2=[CCSequence actions:ap2,movetoright, nil];
	id seq3=[CCSequence actions:delay,scaletox,bfun,nil];
	
	
	[left runAction:seq1];
	[rigth runAction:seq2];
	[bg runAction:seq3];
	[rigth setScaleX:-1];
	[self addChild:bg];
	[self addChild:left];
	[self addChild:rigth];
	[self addChild:tc];
	Game *root=[Game shared];
	[root addChild:self z:INT32_MAX];
}

-(void)closeTuBa{
	
	id ap1=[CCFadeOut actionWithDuration:SPEED];
	id ap2=[CCFadeOut actionWithDuration:SPEED];
	
	id bfun=[CCCallBlock actionWithBlock:^{
		[self removeFromParentAndCleanup:true];
		isOpen=false;
	}];
	
	id bfun2=[CCCallBlock actionWithBlock:^{
		[bg removeFromParentAndCleanup:true];
		
	}];
	
	id movetoleft=nil;
	id movetoright=nil;
	
	if(iPhoneRuningOnGame()){
		movetoleft=[CCMoveBy actionWithDuration:SPEED position:ccp(LEFTRIGHTMOVEDIS, 0)];
		movetoright=[CCMoveBy actionWithDuration:SPEED position:ccp(LEFTRIGHTMOVEDIS*-1, 0)];
	}else{
		movetoleft=[CCMoveBy actionWithDuration:SPEED position:ccp(LEFTRIGHTMOVEDIS, 0)];
		movetoright=[CCMoveBy actionWithDuration:SPEED position:ccp(LEFTRIGHTMOVEDIS*-1, 0)];
	}
	
	id scaletox=[CCScaleTo actionWithDuration:SPEED scaleX:1 scaleY:1];
	id seq1=[CCSequence actions:movetoleft,ap1, nil];
	id seq2=[CCSequence actions:movetoright,ap2,bfun, nil];
	id seq3=[CCSequence actions:scaletox,bfun2,nil];
	
	[left runAction:seq1];
	[rigth runAction:seq2];
	[bg runAction:seq3];
	
}

-(void)onExit{
	//[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	[super onExit];
	
}


-(void)dealloc{
	if(allPostList){
		[allPostList release];
		allPostList=nil;
	}
	/*
	 if(allPostList_Tmp){
	 allPostList =[[NSMutableArray alloc]initWithArray:allPostList_Tmp];
	 [allPostList_Tmp release];
	 allPostList_Tmp=nil;
	 }
	 */
	
	
	[alertTuba release];
	alertTuba=nil;
	[super dealloc];
}

@end
