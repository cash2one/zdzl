
//
//  FightCharacter.m
//  TXSFGame
//
//  Created by TigerLeung on 12-12-4.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "FightCharacter.h"
#import "FightGroup.h"
#import "FightAnimation.h"
#import "FightPlayer.h"
#import "CCLabelFX.h"
#import "ActionMove.h"
#import "FightPlayer.h"
#import "GameConfigure.h"

#define MOVE_SPEED cFixedScale([FightPlayer checkSpeed:2000.0f])

#define EFFECT_Z 90001
#define CUT_EFFECT_Z (EFFECT_Z+10)
#define EFFECT_ACTION_Z 90000
#define READY_SKILL_TAG_U 90001
#define READY_SKILL_TAG_D 90002

static int getViewerCutHeight(int tid, Fight_member_type type, int offset){
	if(type==Fight_member_type_monster){
		
		if(iPhoneRuningOnGame()){
			if(tid==42) return 140/2;
			if(tid==43) return 530/4;
			
			if(tid==1004) return 350/2;
			if(tid==1005) return 125/2;
			if(tid==1006) return 120/2;
			
		}
		
		if(tid==42) return 140;
		if(tid==43) return 530/2;
		
		if(tid==1004) return 350;
		if(tid==1005) return 125;
		if(tid==1006) return 120;
		
	}
	return offset;
}

@implementation FightCharacter

@synthesize group;
@synthesize index;
@synthesize isDie;

@synthesize totalHP;
@synthesize currentHP;
@synthesize totalPower;
@synthesize currentPower;

-(void)dealloc{
	if(actionData){
		[actionData release];
		actionData = nil;
	}
	if(name){
		[name release];
		name = nil;
	}
	if(aniName){
		[aniName release];
		aniName = nil;
	}
	if(allStatus){
		[allStatus release];
		allStatus = nil;
	}
	if(effStatus){
		[effStatus release];
		effStatus=nil;
	}
	
	CCLOG(@"FightCharacter dealloc");
	
	[super dealloc];
	
}

-(void)onEnter{
	
	[super onEnter];
	
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:NO];
	
	allStatus = [NSMutableDictionary dictionary];
	[allStatus retain];
	
	effStatus=[[NSMutableArray alloc]init];
	
	self.anchorPoint = ccp(0.5f,0.0f);
	//self.contentSize = CGSizeMake(80, 150);
	
	actionMove = [[ActionMove alloc] init];
	actionMove.viewer = self;
	actionMove.isNotChangeFlipX = YES;
	
	actionMove.speed = MOVE_SPEED;
	
	[self schedule:@selector(checkTimer:) interval:1/60.0f];
	[self checkTimer:0];
	
}

-(void)onExit{
	
	//[self removeAllChildrenWithCleanup:YES];
	
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	
	if(animation){
		[animation removeAllChildrenWithCleanup:YES];
		animation = nil;
	}
	
	if(shadow){
		[shadow removeFromParentAndCleanup:YES];
		shadow = nil;
	}
	
	if(actionMove){
		[actionMove release];
		actionMove = nil;
	}
	//fix chao
    [self hideInfo];
    //end
	[super onExit];
	
}


-(void)checkTimer:(ccTime)time{
	
	if(self.parent){
		int zz = (GAME_MAP_MAX_Y-self.position.y);
		[self.parent reorderChild:self z:zz];
	}
	
	[actionMove update:time];
	//fix chao
    [self updateInfo];
    //end
}

-(void)show:(NSString*)info{
	
	NSArray * ary = [info componentsSeparatedByString:@":"];
	if ([ary count]<15) {
        CCLOG(@"fight character error....");
        return;
    }
	index = [[ary objectAtIndex:0] intValue];
	
	aniName = [NSString stringWithString:[ary objectAtIndex:1]];
	[aniName retain];
	
	totalHP = [[ary objectAtIndex:2] intValue];
	if (ary.count > 18) {
		int _temp = [[ary objectAtIndex:18] intValue];
		if (_temp > 0) {
			currentHP = _temp;
		}else{
			currentHP = totalHP;
		}
	}else{
		currentHP = totalHP;
	}
	
	//currentHP = totalHP;
	
	id_atk = [[ary objectAtIndex:3] intValue];
	id_skl = [[ary objectAtIndex:4] intValue];
	
	name = [NSString stringWithString:[ary objectAtIndex:5]];
	[name retain];
	
	currentPower = [[ary objectAtIndex:6] intValue];
	totalPower = [[ary objectAtIndex:7] intValue];
	
	targetId = [[ary objectAtIndex:8] intValue];
	type = [[ary objectAtIndex:9] intValue];
	
	int offset = [[ary objectAtIndex:10] intValue];
	animation = [FightAnimation node];
	animation.target = self;
	animation.anchorPoint = ccp(0.5,0);
	
	if(iPhoneRuningOnGame()){
		offset /= 2;
	}
	animation.position = ccp(0,-getViewerCutHeight(targetId,type,offset));
	
	if(group.isCurrentUser){
		animation.dir = FightAnimation_DIR_D;
	}else{
		animation.dir = FightAnimation_DIR_U;
	}
	[self addChild:animation];
	
	self.position = [self getStandPosition];
	
	show_skl_id = [[ary objectAtIndex:12] intValue];
	quality = [[ary objectAtIndex:13] intValue];
	isShake = [[ary objectAtIndex:14] boolValue];
	suit_id = [[ary objectAtIndex:15] intValue];
	
	if(suit_id>0){
		if([animation chkeckHasAnimation:aniName bySuit:suit_id]){
			//aniName
			NSString * cname = [NSString stringWithFormat:@"%@_%d",aniName,suit_id];
			if(aniName) [aniName release];
			aniName = [NSString stringWithString:cname];
			[aniName retain];
		}
	}
	
	[self showStand];
	
	animationSize = animation.contentSize;
	/*
	if(targetId==43 || targetId == 1004 || targetId == 1005 || targetId == 1006 ){
		animation.scale = 2;
		animationSize.width *= 2;
		animationSize.height *= 2;
	}
	 */
	
	if (type == Fight_member_type_boss) {
		float scale = getAniScale(targetId);
		animation.scale = scale;
		animationSize.width *= scale;
		animationSize.height *= scale;
	}
	
	animationSize.height = animationSize.height-getViewerCutHeight(targetId,type,offset);
	if(animationSize.height<0) animationSize.height = 0;
	
	tScale = [[ary objectAtIndex:11] floatValue];
	if(tScale<=0) tScale = 1;
	
	shadow = [CCSprite spriteWithFile:@"images/shadow.png"];
	shadow.position = self.position;
	shadow.scale = tScale;
	
	[self.parent addChild:shadow z:0];
	
	if(tScale>=2) tScale = 1.5f;
	
	NSString * barOffsetStr = @"";
	if([ary count]>=20){
		if([[ary objectAtIndex:19] length]>0){
			barOffsetStr = [NSString stringWithFormat:@"{%@}",[ary objectAtIndex:19]];
		}
	}
	barOffset = CGPointFromString(barOffsetStr);
	
	[self showName];
	[self showHP];
	[self updateHP];
	
	if(currentPower>=totalPower){
		[self readySkill];
	}
	
}

-(BOOL)checkScale{
	if (targetId==43) {
		return YES ;
	}
	if (targetId >= 1004 && targetId <= 1006) {
		return YES;
	}
	return NO;
}
-(void)setPosition:(CGPoint)position{
	[super setPosition:position];
	if(shadow){
		shadow.position = position;
	}
}

-(void)showName{
	
	CCNode * node = nil;
	node = [self getChildByTag:99];
	if(node){
		node.visible = YES;
		node = [self getChildByTag:98];
		if(node) node.visible = YES;
		return;
	}
	
	CCLabelTTF * label = [CCLabelTTF labelWithString:name
											fontName:getCommonFontName(FONT_1) 
											fontSize:20];
	label.anchorPoint = ccp(0.5,0);
	label.color = ccYELLOW;
	
	//NSArray *m=[GameDB shared]get
	//CCLOG(@"%@",[[[GameDB shared]getGlobalConfig ]objectForKey:@"qcolors"]);
	
	NSDictionary *qa=getFormatToDict([[[GameDB shared]getGlobalConfig ]objectForKey:@"qcolors"]);
	
	label.color=color3BWithHexString([qa objectForKey:[NSString stringWithFormat:@"%i",quality]]);
	
	label.position = ccp(0,animationSize.height+20);
	if(barOffset.x!=0 || barOffset.y!=0){
		label.position = ccp(barOffset.x,barOffset.y+20);
	}
	
	CCRenderTexture * stroke = createStroke(label, 2, ccBLACK);
	stroke.sprite.opacity = 192;
	
	[self addChild:label z:99 tag:99];
	[self addChild:stroke z:98 tag:98];
	
	if(iPhoneRuningOnGame()){
		label.scale = 0.5f;
		stroke.scale = 0.5f;
		
		label.position = ccp(0,animationSize.height+10);
		stroke.position = ccp(0,animationSize.height+16);
		
		if(barOffset.x!=0 || barOffset.y!=0){
			label.position = ccp(cFixedScale(barOffset.x),cFixedScale(barOffset.y)+10);
			stroke.position = ccp(label.position.x,label.position.y+6);
		}
		
	}
	
}

-(void)hideName{
	CCNode * node = nil;
	node = [self getChildByTag:99];
	if(node) node.visible = NO;
	
	node = [self getChildByTag:98];
	if(node) node.visible = NO;
}

-(void)removeName{
	CCNode * node = nil;
	node = [self getChildByTag:99];
	if(node) [node removeFromParentAndCleanup:YES];
	
	node = [self getChildByTag:98];
	if(node) [node removeFromParentAndCleanup:YES];
}

-(void)showHP{
	if(!bar_hp){
		
		bar_hp = [CCSprite spriteWithFile:@"images/fight/p/p-bg.png"];
		bar_hp.anchorPoint = ccp(0.5,0.5);
		
		bar_hp.position = ccp(0,animationSize.height+10);
		if(barOffset.x!=0 || barOffset.y!=0){
			bar_hp.position = ccp(barOffset.x,barOffset.y+10);
		}
		
		[self addChild:bar_hp z:100 tag:100];
		
		CCSprite * p1 = [CCSprite spriteWithFile:@"images/fight/p/p-1.png"];
		CCSprite * p2 = [CCSprite spriteWithFile:@"images/fight/p/p-2.png"];
		CCSprite * p3 = [CCSprite spriteWithFile:@"images/fight/p/p-3.png"];
		
		p1.anchorPoint = ccp(0,0.5);
		p2.anchorPoint = ccp(0,0.5);
		p3.anchorPoint = ccp(0,0.5);
		
		[bar_hp addChild:p1 z:1 tag:101];
		[bar_hp addChild:p2 z:2 tag:102];
		[bar_hp addChild:p3 z:3 tag:103];
		
		p1.position = ccp(1,3);
		p2.position = ccp(p1.position.x+p1.contentSize.width,3);
		
		if(iPhoneRuningOnGame()){
			
			bar_hp.position = ccp(0,animationSize.height+5);
			
			if(barOffset.x!=0 || barOffset.y!=0){
				bar_hp.position = ccp(cFixedScale(barOffset.x),cFixedScale(barOffset.y)+5);
			}
			
			p1.position = ccp(0.5,1.5);
			p2.position = ccp(p1.position.x+p1.contentSize.width,1.5);
		}
		
	}else{
		bar_hp.visible = YES;
	}
	
}
-(void)showEff{
	for(NSNumber *effi in effStatus){
		[self getChildByTag:effi.intValue].visible=YES;
	}
}
-(void)hideHP{
	if(bar_hp) bar_hp.visible = NO;
}
-(void)removeHP{
	if(bar_hp){
		[bar_hp removeFromParentAndCleanup:YES];
		bar_hp = nil;
	}
}
-(void)hideEff{
	for(NSNumber *effi in effStatus){
		[self getChildByTag:effi.intValue].visible=NO;
	}

}

-(void)updateHP{
	
	if(!bar_hp) return;
	
	CCNode * p1 = [bar_hp getChildByTag:101];
	CCNode * p2 = [bar_hp getChildByTag:102];
	CCNode * p3 = [bar_hp getChildByTag:103];
	
	if(currentHP<=0){
		p1.visible = NO;
		p2.visible = NO;
		p3.visible = NO;
	}else{
		float scale = currentHP/floor(totalHP);
		if(scale>1) scale = 1.0f;
		p2.scaleX = scale;
		if(iPhoneRuningOnGame()){
			p3.position = ccp(p2.position.x+p2.contentSize.width*scale,1.5);
		}else{
			p3.position = ccp(p2.position.x+p2.contentSize.width*scale,3);
		}
	}
	
}

-(CGPoint)getStandPosition{
	
	CGSize size = [[CCDirector sharedDirector] winSize];
	CGPoint sp = ccp(size.width/2,size.height/2);
	CGPoint p = ccp(-1000,-1000);
	
	if(group.isCurrentUser){
		
		int t_x = 145;
		int t_y = 90;
		int n_x = 85;
		int n_y = 52;
		
		if(iPhoneRuningOnGame()){
			t_x /= 2;
			t_y /= 2;
			n_x /= 2;
			n_y /= 2;
			
			sp = ccpAdd(sp, ccp(68/2,-93/2));
		}else{
			sp = ccpAdd(sp, ccp(68,-93));
		}
		
		int c = index%3;
		if(c==0) p = ccpAdd(sp, ccp(-t_x,-t_y));
		if(c==1) p = ccpAdd(sp, ccp(0,0));
		if(c==2) p = ccpAdd(sp, ccp(t_x,t_y));
		
		int t = index/3;
		p = ccpAdd(p,ccp(n_x*t,-n_y*t));
		
		//return p;
		
	}else{
		
		int t_x = 120;
		int t_y = 75;
		int n_x = 84;
		int n_y = 51;
		
		if(iPhoneRuningOnGame()){
			t_x /= 2;
			t_y /= 2;
			n_x /= 2;
			n_y /= 2;
			sp = ccpAdd(sp, ccp(-87/2,17/2));
		}else{
			sp = ccpAdd(sp, ccp(-87,17));
		}
		
		int c = index%3;
		if(c==0) p = ccpAdd(sp, ccp(t_x,t_y));
		if(c==1) p = ccpAdd(sp, ccp(0,0));
		if(c==2) p = ccpAdd(sp, ccp(-t_x,-t_y));
		
		int t = index/3;
		p = ccpAdd(p,ccp(-n_x*t,n_y*t));
		
		//return p;
		
	}
	
	return p;
}

-(void)showStand{
	if(isDie) return;
	[animation showAnimationStandByName:aniName];
}

#pragma mark -

-(void)action:(NSString*)data{
	
	if(isDie) return;
	
	if(!isAction){
		[self actionStart:data];
	}else{
		actionData = [NSString stringWithString:data];
		[actionData retain];
	}
}

-(void)actionStart:(NSString*)str{
	if(isDie) return;
	
	isAction = YES;
	
	Fight_Action_Log_Type parentAction = [valueFromSort(str,0) intValue];
	
	if(parentAction==Fight_Action_Log_Type_hp){
		int cut = [valueFromSort(str,2) intValue];
		int chp = [valueFromSort(str,3) intValue];
		BOOL isBok = [valueFromSort(str,4) boolValue];
		BOOL isCpr = [valueFromSort(str,5) boolValue];
		BOOL isPen = [valueFromSort(str,6) boolValue];
		
		[self cutHP:cut currentHP:chp isBok:isBok isCpr:isCpr isPen:isPen];
		
		
	}else if(parentAction==Fight_Action_Log_Type_power){
		int pwoer = [valueFromSort(str,2) intValue];
		[self showPower:pwoer];
	}else if(parentAction==Fight_Action_Log_Type_die){
		[self showDie];
	}else if(parentAction==Fight_Action_Log_Type_ready_skill){
		[self showReadySkill];
	}else if(parentAction==Fight_Action_Log_Type_remove_skill){
		[self showRemoveReadySkill];
	}
	
	if(parentAction==Fight_Action_Log_Type_move){
		FightCharacter * target = [group.player getTargetCharacter:valueFromSort(str,2)];
		[self moveTo:target];
		
	}else if(parentAction==Fight_Action_Log_Type_back){
		[self goBack];
	}
	
	if(parentAction==Fight_Action_Log_Type_atk){
		[self showAttack];
	}else if(parentAction==Fight_Action_Log_Type_skl){
		[self showSkill];
	}
	
	if(parentAction==Fight_Action_Log_Type_add) [self showEffectAdd];
	if(parentAction==Fight_Action_Log_Type_bok) [self showEffectBok];
	if(parentAction==Fight_Action_Log_Type_cob) [self showEffectCob];
	if(parentAction==Fight_Action_Log_Type_cot) [self showEffectCot];
	if(parentAction==Fight_Action_Log_Type_cpr) [self showEffectCpr];
	if(parentAction==Fight_Action_Log_Type_mis) [self showEffectMis];
	if(parentAction==Fight_Action_Log_Type_pen) [self showEffectPen];
	
	if(parentAction==Fight_Action_Log_Type_addStatus){
		[self addStatus:[valueFromSort(str,2) intValue] 
				  index:[valueFromSort(str,3) intValue]
				 effect:valueFromSort(str,4)
		 ];
	}else if(parentAction==Fight_Action_Log_Type_updateStatus){
		[self updateStatus:[valueFromSort(str,2) intValue] 
					 index:[valueFromSort(str,3) intValue]];
	}else if(parentAction==Fight_Action_Log_Type_removeStatus){
		[self removeStatus:[valueFromSort(str,2) intValue] 
					 index:[valueFromSort(str,3) intValue]];
	}
	
	if(parentAction==Fight_Action_Log_Type_effect_single){
		[self showEffect:[valueFromSort(str,2) intValue] 
				  offset:[valueFromSort(str,3) intValue]
		 ];
	}
	
}

-(void)actionOver{
	if(isDie) return;
	if(actionData){
		[self scheduleOnce:@selector(actionNext) delay:0.001f];
	}else{
		isAction = NO;
	}
}

-(void)actionNext{
	if(isDie) return;
	NSString * str = [NSString stringWithString:actionData];
	[actionData release];
	actionData = nil;
	[self actionStart:str];
}

#pragma mark -

-(void)cutHP:(int)cut currentHP:(int)chp isBok:(BOOL)isBok isCpr:(BOOL)isCpr isPen:(BOOL)isPen{
	
	currentHP = chp;
	[self updateHP];
	
	if(cut!=0){
		
		FightAnimation * m = [FightAnimation node];
		m.anchorPoint = ccp(0.5f,0.5f);
		m.position = ccp(0,animationSize.height+cFixedScale(50));
		if(barOffset.x!=0 || barOffset.y!=0){
			m.position = ccp(cFixedScale(barOffset.x),cFixedScale(barOffset.y+50));
		}
		
		[self addChild:m z:CUT_EFFECT_Z];
		
		[m showCut:cut delay:0.0f];
		
		/*
		int ttag = 0;
		for(int i=0;i<10;i++){
			if([self getChildByTag:(3000+ttag)]){
				ttag++;
			}else{
				break;
			}
		}
		m.tag = (3000+ttag);
		
		if(isBok || isCpr || isPen){
			[m showCut:cut delay:[FightPlayer checkTime:0.35f+(ttag*0.25f)]];
		}else{
			[m showCut:cut delay:[FightPlayer checkTime:(ttag*0.25f)]];
		}
		*/
		
	}
	
	if(cut<0){
		
		CGPoint pos = ccp(0,cFixedScale(-50));
		
		id end = [CCCallFunc actionWithTarget:self selector:@selector(cutHpOver)];
		
		if(isBok){
			[self showActionEffect:Fight_Action_Log_Type_bok isCheckAction:NO];
			[animation showAnimationBokByName:aniName call:nil end:end];
		}else{
			[animation showAnimationHurtByName:aniName call:nil end:end];
		}
		
		if(isCpr || isPen){
			
			if(isCpr){
				FightAnimation * f = [FightAnimation node];
				f.anchorPoint = ccp(0.5,0.0);
				f.position = pos;
				[self addChild:f z:CUT_EFFECT_Z];
				[f showEffect:@"images/fight/eff/cpr/%d.png"];
			}
			if(isPen){
				FightAnimation * f = [FightAnimation node];
				f.anchorPoint = ccp(0.5,0.0);
				f.position = pos;
				[self addChild:f z:CUT_EFFECT_Z];
				[f showEffect:@"images/fight/eff/wreck/%d.png"];
			}
			
		}else{
			
			FightAnimation * f = [FightAnimation node];
			f.anchorPoint = ccp(0.5,0.0);
			f.position = pos;
			[self addChild:f z:CUT_EFFECT_Z];
			[f showEffect:@"images/fight/eff/hit/%d.png"];
			
		}
		
	}
	
	//[self scheduleOnce:@selector(actionOver) delay:0.6f];
	[self actionOver];
	
	[group.player actionFight];
	
}
-(void)cutHpOver{
	[self showStand];
	if(isDie && animation.opacity>0){
		[self viewDie];
	}
}

-(void)showPower:(int)power{
	currentPower = power;
	
	if(currentPower<totalPower){
		[self removeReady];
	}
	
	[self actionOver];
	[group.player actionFight];
	
}

-(void)moveTo:(FightCharacter*)target{
	
	[self hideName];
	[self hideHP];
	
	CGPoint tp = target.position;
	if(group.isCurrentUser){
		if(iPhoneRuningOnGame()){
			tp = ccpAdd(tp, ccp(50,-25));
		}else{
			tp = ccpAdd(tp, ccp(100,-50));
		}
	}else{
		if(iPhoneRuningOnGame()){
			tp = ccpAdd(tp, ccp(-50,25));
		}else{
			tp = ccpAdd(tp, ccp(-100,50));
		}
	}
	
	actionMove.speed = MOVE_SPEED;
	
	actionMove.call = @selector(moveEnd);
	[actionMove moveTo:[NSArray arrayWithObject:NSStringFromCGPoint(tp)]];
	
}
-(void)moveEnd{
	[self actionOver];
	[group.player actionFight];
}

-(void)goBack{
	
	//[self doGoBack];
	[self scheduleOnce:@selector(doGoBack) delay:[FightPlayer checkTime:0.25f]];
	
}
-(void)doGoBack{
	CGPoint tp = [self getStandPosition];
	actionMove.speed = MOVE_SPEED;
	actionMove.call = @selector(backEnd);
	[actionMove moveTo:[NSArray arrayWithObject:NSStringFromCGPoint(tp)]];
}

-(void)backEnd{
	[self showName];
	[self showHP];
	[self showEff];
	[self actionOver];
	[group.player actionFight];
}

-(void)showAttack{
	
	[self hideName];
	[self hideHP];
	[self hideEff];
	//TODO target id_atk ???
	id call = [CCCallFunc actionWithTarget:self selector:@selector(attackTarget)];
	id end = [CCCallFunc actionWithTarget:self selector:@selector(attackOver)];
	[animation showAnimationFightByName:aniName call:call end:end];
	
}
-(void)attackTarget{
	[group.player actionFight];
}
-(void)attackOver{
	[self showName];
	[self showHP];
	[self showStand];
	
	[self actionOver];
}

-(void)showSkill{
	
	//target id_skl ???
	
	[self hideName];
	[self hideHP];
	[self removeReady];
	
	BOOL isShow = NO;
	if(show_skl_id>0){
		NSString * s = [NSString stringWithFormat:@"images/fight/sname/skilltxt%d.png",show_skl_id];
		CCSprite * sn = [CCSprite spriteWithFile:s];
		if(sn){
			sn.anchorPoint = ccp(0.5,0);
			sn.position = ccp(0,animationSize.height+cFixedScale(10));
			if(barOffset.x!=0 || barOffset.y!=0){
				sn.position = ccp(cFixedScale(barOffset.x),cFixedScale(barOffset.y+10));
			}
			
			[self addChild:sn z:INT16_MAX tag:9003];
			
			CGPoint pos = ccp(0,30);
			if(iPhoneRuningOnGame()){
				pos = ccp(0,15);
			}
			
			id m = [CCMoveTo actionWithDuration:[FightPlayer checkTime:0.8f] position:ccpAdd(sn.position,pos)];
			id c = [CCCallFunc actionWithTarget:self selector:@selector(skillStart)];
			[sn runAction:[CCSequence actions:m,c,nil]];
			isShow = YES;
		}
	}
	
	if(!isShow){
		id call = [CCCallFunc actionWithTarget:self selector:@selector(skillTarget)];
		id end = [CCCallFunc actionWithTarget:self selector:@selector(skillOver)];
		[animation showAnimationSkillByName:aniName call:call end:end];
	}
	
}

-(void)skillStart{
	[self hideEff];
	[self removeChildByTag:9003 cleanup:YES];
	id call = [CCCallFunc actionWithTarget:self selector:@selector(skillTarget)];
	id end = [CCCallFunc actionWithTarget:self selector:@selector(skillOver)];
	[animation showAnimationSkillByName:aniName call:call end:end];
}

-(void)skillTarget{
	if(isShake){
		[group.player shake];
	}
	[group.player actionFight];
}
-(void)skillOver{
	[self showName];
	[self showHP];
	[self showStand];
	[self showEff];
	[self actionOver];
}

-(void)endShow{
	[self showStand];
	[group.player actionFight];
}

-(void)showDie{
	//fix chao
	//[[FightPlayer shared] unboundCharacter:self];
    [self hideInfo];
	//end
	isDie = YES;
	
	if(animation.isShowStand){
		[self viewDie];
	}
	[group.player actionFight];
	
}
//fix chao
-(void)hideInfo{
    if (characterInfo) {
        [characterInfo stopAllActions];
        [characterInfo removeFromParentAndCleanup:YES];
        characterInfo = nil;
    }
}
-(void)showInfo{
    if( (!characterInfo) &&
       (!isDie) &&
       [FightPlayer shared] &&
       ([[FightPlayer shared] isEndPlay]==NO)
       ){
		characterInfo = [CCSprite spriteWithFile:@"images/fight/info/bg.png"];
        characterInfo = getSpriteWithSpriteAndNewSize(characterInfo, CGSizeMake(cFixedScale(150), cFixedScale(50)));
		characterInfo.anchorPoint = ccp(0.5,1);
		[self.parent addChild:characterInfo z:INT32_MAX];
		
		CCSprite * c1 = [CCSprite spriteWithFile:@"images/fight/info/c1.png"];
		CCSprite * c2 = [CCSprite spriteWithFile:@"images/fight/info/c2.png"];
		
        c1 = getSpriteWithSpriteAndNewSize(c1, CGSizeMake(cFixedScale(50), cFixedScale(20)));
        c2 = getSpriteWithSpriteAndNewSize(c2, CGSizeMake(cFixedScale(50), cFixedScale(20)));
        
		c1.anchorPoint = ccp(0,0);
		c2.anchorPoint = ccp(0,0);
		
		c1.position = ccp(cFixedScale(0), cFixedScale(28));
		c2.position = ccp(cFixedScale(0), cFixedScale(4));
		
		[characterInfo addChild:c1 z:1];
		[characterInfo addChild:c2 z:1];
		[characterInfo runAction:([CCSequence actions:[CCDelayTime actionWithDuration:5],[CCCallFuncN actionWithTarget:self selector:@selector(hideInfo)], nil ])];
	}else{
        [self hideInfo];
    }
}
-(void)updateInfo{
	if(characterInfo ){
		
		[characterInfo removeChildByTag:1001 cleanup:YES];
		[characterInfo removeChildByTag:1002 cleanup:YES];
		
		characterInfo.position = self.position;
		
		float cut_y = (characterInfo.position.y-characterInfo.contentSize.height);
		if(cut_y<0){
			characterInfo.position = ccp(characterInfo.position.x, characterInfo.position.y-cut_y);
		}
		
		float cut_x = (characterInfo.position.x-characterInfo.contentSize.width/2);
		if(cut_x<0){
			characterInfo.position = ccp(characterInfo.position.x-cut_x, characterInfo.position.y);
		}
		
		CGSize winSize = [CCDirector sharedDirector].winSize;
		cut_x = (characterInfo.position.x+characterInfo.contentSize.width/2);
		if(cut_x>winSize.width){
			characterInfo.position = ccp(characterInfo.position.x-(cut_x-winSize.width), characterInfo.position.y);
		}
		
		NSString * s1 = [NSString stringWithFormat:@"%d/%d",self.currentHP,self.totalHP];
		NSString * s2 = [NSString stringWithFormat:@"%d/%d",self.currentPower,self.totalPower];
        
		CCSprite * d1 = drawBoundString(s1, 15, GAME_DEF_CHINESE_FONT, 15, ccc3(0, 255, 0), ccBLACK);
		CCSprite * d2 = drawBoundString(s2, 15, GAME_DEF_CHINESE_FONT, 15, ccc3(0, 200, 200), ccBLACK);
		
		d1.position = ccp(cFixedScale(55+d1.contentSize.width/2), cFixedScale(28+15));
		d2.position = ccp(cFixedScale(55+d2.contentSize.width/2), cFixedScale(4+15));
		
		[characterInfo addChild:d1 z:2 tag:1001];
		[characterInfo addChild:d2 z:2 tag:1002];
		
	}
}
//end
-(void)viewDie{
	
	[self removeReady];
	[self removeName];
	[self removeHP];
	
	id a = [CCFadeOut actionWithDuration:[FightPlayer checkTime:1.0f]];
	id k = [CCCallFunc actionWithTarget:self selector:@selector(viewDieOver)];
	
	[animation stopAllActions];
	[animation runAction:[CCSequence actions: a, k, nil]];
	
	//[animation runAction:[CCFadeOut actionWithDuration:1.0f]];
	[shadow runAction:[CCFadeOut actionWithDuration:[FightPlayer checkTime:1.0f]]];
	
	FightAnimation * d = [FightAnimation node];
	d.anchorPoint = ccp(0.5,0.5);
	d.scale = tScale;
	d.position = self.position;
	[d showEffect:@"images/fight/eff/die_d/%d.png"];
	[self.parent addChild:d z:1];
	
	FightAnimation * u = [FightAnimation node];
	u.anchorPoint = ccp(0.5,0);
	u.scale = tScale;
	if(iPhoneRuningOnGame()){
		u.position = ccp(0,-25);
	}else{
		u.position = ccp(0,-50);
	}
	
	[u showEffect:@"images/fight/eff/die_u/%d.png"];
	[self addChild:u z:10000];
	
}

-(void)viewDieOver{
	if(shadow){
		[shadow stopAllActions];
		[shadow removeFromParentAndCleanup:YES];
		shadow = nil;
	}
	if(animation){
		[animation removeFromParentAndCleanup:YES];
		animation = nil;
	}
	[self removeAllChildrenWithCleanup:YES];
}

-(void)showReadySkill{
	[self readySkill];
	[group.player actionFight];
	[self actionOver];
}

-(void)showRemoveReadySkill{
	[self removeReady];
	[group.player actionFight];
	[self actionOver];
}

-(void)readySkill{
	
	if(id_skl<=0) return;
	if([[GameConfigure shared] isPlayerOnChapter]){
		if(type==Fight_member_type_monster || type==Fight_member_type_boss){
			if(targetId==40) return;
			if(targetId==41) return;
			if(targetId==42) return;
			if(targetId==43) return;
		}
	}
	
	if(![self getChildByTag:READY_SKILL_TAG_U]){
		FightAnimation * rSkillu = [FightAnimation node];
		rSkillu.anchorPoint = ccp(0.5,0.0);
		rSkillu.position = ccp(0,cFixedScale(-50));
		[self addChild:rSkillu z:10000 tag:READY_SKILL_TAG_U];
		[rSkillu showEffectForever:@"images/fight/eff/skill_u/%d.png"];
	}
	
	if(![self getChildByTag:READY_SKILL_TAG_D]){
		FightAnimation * rSkilld = [FightAnimation node];
		rSkilld.anchorPoint = ccp(0.5,0.5);
		rSkilld.position = ccp(0,0);
		[self addChild:rSkilld z:-10 tag:READY_SKILL_TAG_D];
		[rSkilld showEffectForever:@"images/fight/eff/skill_d/%d.png"];
	}
	
}

-(void)removeReady{
	CCNode * node = nil;
	node = [self getChildByTag:READY_SKILL_TAG_U];
	if(node) [node removeFromParentAndCleanup:YES];
	node = [self getChildByTag:READY_SKILL_TAG_D];
	if(node) [node removeFromParentAndCleanup:YES];
}

-(void)showStatusTips:(int)sin{
	NSString * skey = [NSString stringWithFormat:@"index-%d",sin];
	NSDictionary * status = [allStatus objectForKey:skey];
	NSString * effect = [status objectForKey:@"effect"];
	
	if([effect length]>0){
		
		id end = [CCCallFunc actionWithTarget:self selector:@selector(actionOver)];
		
		NSString * path = [NSString stringWithFormat:@"images/fight/eff/%@.png",effect];
		
		FightAnimation * f = [FightAnimation node];
		f.anchorPoint = ccp(0.5,0.0);
		f.position = ccp(0,animationSize.height+cFixedScale(20));
		
		[f showActionEffect:path end:end];
		[self addChild:f z:EFFECT_ACTION_Z];
		
	}else{
		[self actionOver];
	}
}

-(void)showStatusEffect:(int)sin{
	NSString * skey = [NSString stringWithFormat:@"index-%d",sin];
	NSDictionary * status = [allStatus objectForKey:skey];
	NSString * effect = [status objectForKey:@"effect"];
	
	if([effect length]>0){
		
		NSString * path = [NSString stringWithFormat:@"images/fight/eff/status/%@/%@.png",effect,@"%d"];
		
		FightAnimation * f = [FightAnimation node];
		f.anchorPoint = ccp(0.5,0.0);
		f.position = ccp(0,cFixedScale(-50));
		[f showEffectForever:path];
		
		[self addChild:f z:EFFECT_ACTION_Z tag:(8500+sin)];
		NSNumber *effi=[NSNumber numberWithInt:8500+sin];
		[effStatus addObject:effi];
	}
	
}
-(void)removeStatusEffect:(int)sin{
	[self removeChildByTag:(8500+sin) cleanup:YES];
	NSNumber *effi=[NSNumber numberWithInt:8500+sin];
	[effStatus removeObject:effi];
}

-(void)addStatus:(int)sid index:(int)sin effect:(NSString*)effect{
	
	NSMutableDictionary * status = [NSMutableDictionary dictionary];
	[status setObject:[NSNumber numberWithInt:sid] forKey:@"statusId"];
	[status setObject:[NSNumber numberWithInt:sin] forKey:@"index"];
	[status setObject:effect forKey:@"effect"];
	
	NSString * skey = [NSString stringWithFormat:@"index-%d",sin];
	[allStatus setObject:status forKey:skey];
	
	[self showStatusTips:sin];
	[self showStatusEffect:sin];
	
	[group.player actionFight];
	
	
}
-(void)updateStatus:(int)sid index:(int)sin{
	[self showStatusTips:sin];
	[group.player actionFight];
}

-(void)removeStatus:(int)sid index:(int)sin{
	
	[self removeStatusEffect:sin];
	
	NSString * skey = [NSString stringWithFormat:@"index-%d",sin];
	[allStatus removeObjectForKey:skey];
	[self actionOver];
	[group.player actionFight];
	
}

-(void)showEffect:(int)eid offset:(int)offset{
	
	NSString * uPath = [NSString stringWithFormat:@"images/fight/eff/effects/%d/u/%@",eid,@"%d.png"];
	
	id call = [CCCallFunc actionWithTarget:self selector:@selector(actionOver)];
	FightAnimation * u = [FightAnimation node];
	u.anchorPoint = ccp(0.5,0.0);
	if(offset==0){
		if(iPhoneRuningOnGame()){
			u.position = ccp(0,-25);
		}else{
			u.position = ccp(0,-50);
		}
	}else{
		if(iPhoneRuningOnGame()){
			u.position = ccp(0,-offset/2);
		}else{
			u.position = ccp(0,-offset);
		}
	}
	
	[self addChild:u z:EFFECT_Z+9];
	[u showEffect:uPath call:call];
	
	/*
	NSString * dPath = [NSString stringWithFormat:@"images/fight/eff/effects/%d/d/%@",eid,@"%d.png"];
	FightAnimation * d = [FightAnimation node];
	d.anchorPoint = ccp(0.5,0.5);
	d.position = self.position;
	[self.parent addChild:d z:-1];
	[d showEffect:dPath call:nil];
	*/
	
	[group.player actionFight];
	
}

//------------------------------------------------------------------------------

-(void)showActionEffect:(Fight_Action_Log_Type)log_type{
	[self showActionEffect:log_type isCheckAction:YES];
}

-(void)showActionEffect:(Fight_Action_Log_Type)log_type isCheckAction:(BOOL)isCheck{
	
	NSString * path = nil;
	if(log_type==Fight_Action_Log_Type_add) path = @"images/fight/eff/ADD.png";
	if(log_type==Fight_Action_Log_Type_bok) path = @"images/fight/eff/BOK.png";
	if(log_type==Fight_Action_Log_Type_cob) path = @"images/fight/eff/COB.png";
	if(log_type==Fight_Action_Log_Type_cot) path = @"images/fight/eff/COT.png";
	if(log_type==Fight_Action_Log_Type_cpr) path = @"images/fight/eff/CPR.png";
	if(log_type==Fight_Action_Log_Type_pen) path = @"images/fight/eff/PEN.png";
	if(log_type==Fight_Action_Log_Type_mis) path = @"images/fight/eff/MIS.png";
	
	if(path){
		
		FightAnimation * f = [FightAnimation node];
		f.anchorPoint = ccp(0.5,0.0);
		f.position = ccp(0,animationSize.height+cFixedScale(20));
		
		if(isCheck){
			id end = [CCCallFunc actionWithTarget:self selector:@selector(actionOver)];
			[f showActionEffect:path end:end];
		}else{
			[f showActionEffect:path];
		}
		
		[self addChild:f z:EFFECT_ACTION_Z];
		
	}else{
		if(isCheck){
			[self actionOver];
		}
	}
	
}

-(void)showEffectAdd{
	//TODO
	[self showActionEffect:Fight_Action_Log_Type_add];
	[group.player actionFight];
	
}

-(void)showEffectBok{
	
	[self showActionEffect:Fight_Action_Log_Type_bok];
	id end = [CCCallFunc actionWithTarget:self selector:@selector(endShow)];
	[animation showAnimationBokByName:aniName call:nil end:end];
	
	//[group.player actionFight];
	
}
-(void)showEffectCob{
	[self showActionEffect:Fight_Action_Log_Type_cob];
	[group.player actionFight];
}

#pragma mark 反击
-(void)showEffectCot{
	[self showActionEffect:Fight_Action_Log_Type_cot];
	[group.player actionFight];
}
-(void)showEffectCpr{
	[self showActionEffect:Fight_Action_Log_Type_cpr];
	[group.player shake];
	[group.player actionFight];
}
-(void)showEffectPen{
	[self showActionEffect:Fight_Action_Log_Type_pen];
	[group.player actionFight];
}

#pragma mark 闪躲
-(void)showEffectMis{
	
	[self showActionEffect:Fight_Action_Log_Type_mis];
	
	CGPoint op = self.position;
	CGPoint tp = ccpAdd(op, ccp(50,-20));
	if(iPhoneRuningOnGame()){
		tp = ccpAdd(op, ccp(25,-10));
	}
	if(!group.isCurrentUser){
		if(iPhoneRuningOnGame()){
			tp = ccpAdd(op, ccp(-25,10));
		}else{
			tp = ccpAdd(op, ccp(-50,20));
		}
	}
	
	//actionMove.speed = cFixedScale([FightPlayer checkSpeed:500.0f]);
	actionMove.speed = MOVE_SPEED/2;
	
	actionMove.call = @selector(misEnd);
	[actionMove moveTo:[NSArray arrayWithObjects:NSStringFromCGPoint(tp),NSStringFromCGPoint(op),nil]];
	
	//[group.player actionFight];
	
}
-(void)misEnd{
	[group.player actionFight];
}

-(void)updateSpeed{
	if(isDie) return;
	
	if(animation){
		[animation updateSpeed];
	}
	
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////

-(BOOL)isTouchInSite:(UITouch*)touch{
	
	CGSize size = animationSize;
	
	CGPoint p = [self convertTouchToNodeSpaceAR:touch];
	if(p.x<-size.width/2) return NO;
	if(p.x>size.width/2) return NO;
	if(p.y<0) return NO;
	if(p.y>size.height) return NO;
	return YES;
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	return [self isTouchInSite:touch];
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	if([self isTouchInSite:touch]){
		//[FightPlayer showInfo:self];
		[[FightPlayer shared] showInfo:self];
	}
}


@end
