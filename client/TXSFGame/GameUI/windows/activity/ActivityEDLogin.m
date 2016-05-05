//
//  ActivityEDLogin.m
//  TXSFGame
//
//  Created by Max on 13-5-20.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ActivityEDLogin.h"
#import "CCSimpleButton.h"
#import "GameConnection.h"
#import "ShowItem.h"
#import "GameEffects.h"
#import "InfoAlert.h"
#import "ActivityTab.h"
#import "ActivityPanel.h"
#import "ActivityTabGroup.h"
#import "GameUI.h"

@implementation PockerFace
@synthesize ftpath;
@synthesize isPlayFlipx;

+(PockerFace*)creatPockerFace:(NSString*)path{
	PockerFace *pf=[PockerFace node];
	pf.ftpath=path;
	return pf;
}

#pragma mark 播放反转动画
-(void)playFlip{
	
	CCDelayTime *delayb=[CCDelayTime actionWithDuration:.2];
	CCDelayTime *delayf=[CCDelayTime actionWithDuration:.2];
	
	CCCallBlock *funb=[CCCallBlock actionWithBlock:^{
		backsp.visible=false;
	}];
	CCCallBlock *funf=[CCCallBlock actionWithBlock:^{
		frontsp.visible=true;
	}];
	
	
	CCOrbitCamera *flipXb = [CCOrbitCamera actionWithDuration:0.4 radius:1 deltaRadius:0 angleZ:0 deltaAngleZ:-180 angleX:20 deltaAngleX:0];
	CCOrbitCamera *flipXf = [CCOrbitCamera actionWithDuration:0.4 radius:1 deltaRadius:0 angleZ:0 deltaAngleZ:-180 angleX:20 deltaAngleX:0];
	id seqb=[CCSequence actions:delayb,funb, nil];
	id seqf=[CCSequence actions:delayf,funf, nil];
	
	id swpb=[CCSpawn actions:flipXb,seqb,nil];
	id swpf=[CCSpawn actions:flipXf,seqf,nil];
	
	[backsp runAction:swpb];
	[frontsp runAction:swpf];
	
}


#pragma mark 直接看底牌
-(void)showHand{
	[frontsp setVisible:YES];
	[backsp setVisible:NO];
	self.isPlayFlipx=false;
}

-(void)onEnter{
	[super onEnter];
	backsp=[CCSprite spriteWithFile:@"images/ui/activity/back.png"];
	frontsp=[CCSprite spriteWithFile:@"images/ui/activity/front.png"];
	if (iPhoneRuningOnGame()) {
		backsp.scale=1.12f;
		frontsp.scale=1.12f;
	}
	self.contentSize=frontsp.contentSize;
	[self addChild:frontsp z:1 tag:789];
	[self addChild:backsp z:2];
	self.isPlayFlipx=true;
}



#pragma mark 生成卡牌的样子(并选择反转)
-(void)setItemInfo:(NSDictionary*)dict FlipX:(bool)f mask:(bool)m count:(int)c{
	int itemid=[[dict objectForKey:@"i"]intValue];
	NSString *type=[NSString stringWithFormat:@"%@",[dict objectForKey:@"t"]];
	NSString *itemname=@"";
	CCSprite *itemsp=nil;
	if([type isEqualToString:@"i"]){
		itemsp=getItemIcon(itemid);
		itemname=[[[GameDB shared]getItemInfo:itemid]objectForKey:@"name"];
		
	}
	if([type isEqualToString:@"e"]){
		itemsp=getEquipmentIcon(itemid);
		itemname=[[[GameDB shared]getEquipmentInfo:itemid]objectForKey:@"name"];
		
	}
	if([type isEqualToString:@"f"]){
		itemname=[[[GameDB shared]getFateInfo:itemid]objectForKey:@"name"];
		int qa=[[[[GameDB shared]getFateInfo:itemid]objectForKey:@"quality"]intValue];
		itemsp=getFateIconWithQa(itemid, qa);
	}
	if([type isEqualToString:@"c"]){
		itemsp=getCarIcon(itemid);
		itemname=[[[GameDB shared]getCarInfo:itemid]objectForKey:@"name"];
		
	}
	if([type isEqualToString:@"r"]){
		itemsp=getTMemberIcon(itemid);
		itemname=[[[GameDB shared]getRoleInfo:itemid]objectForKey:@"name"];
	}
	if(itemsp){
		CCNode *node=[self getChildByTag:789];
		CCLabelTTF *namelabel=[CCLabelTTF labelWithString:itemname fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
		[namelabel setColor:ccc3(67, 39, 5)];
		[itemsp setPosition:ccp(node.contentSize.width/2, cFixedScale(80))];
		[namelabel setPosition:ccp(node.contentSize.width/2, cFixedScale(23))];
		[namelabel setFlipX:f];
		if(f){
			[itemsp setScaleX:-1];
		}
		
		if(c>0){
			NSString *countstr=[NSString stringWithFormat:@"X%i",c];
			CCLabelFX *countLabel=[CCLabelFX labelWithString:countstr fontName:getCommonFontName(FONT_1) fontSize:14 shadowOffset:CGSizeMake(1, 1) shadowBlur:0];
			[countLabel setAnchorPoint:ccp(1, 0.5)];
			[countLabel setColor:ccGREEN];
			[countLabel setPosition:ccp(node.contentSize.width-cFixedScale(10), cFixedScale(45))];
			if(f){
				[countLabel setAnchorPoint:ccp(0, 0.5)];
				[countLabel setPosition:ccp(cFixedScale(10), cFixedScale(45))];
				[countLabel setFlipX:YES];
			}
			[node addChild:countLabel];
		}
		[node addChild:namelabel];
		[node addChild:itemsp];
		if(m){
			CCLayerColor *grayface=[CCLayerColor layerWithColor:ccc4(10, 10, 10, 150) width:self.contentSize.width-cFixedScale(10) height:self.contentSize.height-cFixedScale(10)];
			[grayface setIgnoreAnchorPointForPosition:NO];
			[grayface setAnchorPoint:ccp(0.5, 0.5)];
			addTargetToCenter(grayface, node, 1);
		}
	}
	
}



@end


@implementation ActivityEDLogin

#define POCKERBASE 50

+(void)sdidrequest:(NSDictionary*)data{
	int hasTime=[[getResponseData(data) objectForKey:@"mdraws"] intValue]-[[getResponseData(data) objectForKey:@"draws"]intValue];
	if(hasTime>0){
        //
        [[GameUI shared] showButtonFireEffectWithTag:BT_ACT_TAG];
        /*
		ActivityPanel *activity = [ActivityPanel node];
		//activity.windowType = PANEL_ACTIVITY;
		if([[Window shared]isHasWindow]){
			[Intro stopAll];
			[[Window shared] removeAllWindows];
			
		}
		activity.windowType = PANEL_ACTIVITY;
		[[Window shared] addChild:activity z:10 tag:PANEL_ACTIVITY];
		
		for (ActivityTab *at in activity.tabsManager.menuUIData){
			if(at.activityId==10001){
				at.isSelected=YES;
			}else{
				at.isSelected=NO;
			}
		}
         */
	}else{
        [[GameUI shared] hideButtonFireEffectWithTag:BT_ACT_TAG];
    }
	
}

+(void)checkMaxhasLuckTime{
	[GameConnection request:@"dayLuckEnter" format:@"" target:[ActivityEDLogin class] call:@selector(sdidrequest:)];
}


-(void)onEnter{
	[super onEnter];
    isEDLoginSend = NO;
    
	maxLuckDrawTime=0;
	CCSprite *bg=[CCSprite spriteWithFile:@"images/ui/activity/bg.jpg"];
	[bg setAnchorPoint:ccp(0, 0)];
	
	[self addChild:bg];
	for(int i=0;i<9;i++){
		PockerFace *p=[PockerFace creatPockerFace:@"images/ui/activity/front.png"];
		CCSimpleButton *b=[CCSimpleButton node];
		
		[b setPriority:INT32_MIN+1];
		
		if (iPhoneRuningOnGame()) {
			p.scale=1.02f;
			b.scale=1.02f;
		}
		
		[b setTarget:self];
		[b setCall:@selector(PockerFaceBtnCallBack:)];
		
		//[b setPosition:ccp(65+(i%3*115), 360-(i/3*135))];
		//[p setPosition:ccp(65+(i%3*115), 360-(i/3*135))];
		
		if(iPhoneRuningOnGame()){
			[b setPosition:ccp(cFixedScale(65*b.scaleX)+(i%3*cFixedScale(137)), cFixedScale(400*b.scaleY)-(i/3*cFixedScale(160)))];
			[p setPosition:ccp(cFixedScale(65*p.scaleX)+(i%3*cFixedScale(137)), cFixedScale(400*p.scaleY)-(i/3*cFixedScale(160)))];
		}else{
			[b setPosition:ccp(65+(i%3*125), 370-(i/3*140))];
			[p setPosition:ccp(65+(i%3*125), 370-(i/3*140))];
		}
		
		p.tag=POCKERBASE+i;
		b.tag=POCKERBASE+i;
		[self addChild:p];
		b.contentSize=CGSizeMake(p.contentSize.width, p.contentSize.height);
		[self addChild:b];
	}
    //fix chao
    RuleButton *ruleButton = [RuleButton node];
    if (iPhoneRuningOnGame()) {
		bg.scale=1.12f;
        ruleButton.scale = 1.19;
    }
    ruleButton.type = RuleType_EDLogin;
    ruleButton.priority = INT32_MIN+1;
    [self addChild:ruleButton z:100];
    CGPoint pos = ccp(bg.contentSize.width*bg.scaleX+ruleButton.contentSize.width, bg.contentSize.height*bg.scaleY-ruleButton.contentSize.height);
    ruleButton.position = ccp(pos.x-cFixedScale(WINDOW_RULE_OFF_X)* ruleButton.scale, pos.y-cFixedScale(WINDOW_RULE_OFF_Y)* ruleButton.scale);
	
    //end
	[GameConnection request:@"dayLuckEnter" format:@"" target:self call:@selector(didrequest:)];
    isEDLoginSend = YES;
    
	drawLuckCoolDown=true;
    //TODO 闪烁
	//[[[CCDirector sharedDirector]touchDispatcher ]addTargetedDelegate:self priority:INT32_MIN+2 swallowsTouches:YES];
    //
    [[GameUI shared] hideButtonFireEffectWithTag:BT_ACT_TAG];
	
}

-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	if(coolDownTouch==0){
		[self scheduleOnce:@selector(SetcoolDownTouch) delay:5];
		coolDownTouch=1;
		[ShowItem showItemAct:NSLocalizedString(@"activity_perday_logintips", nil)];
	}
	
	return YES;
}

-(void)SetcoolDownTouch{
	coolDownTouch=0;
}




-(void)didrequest:(NSDictionary*)data{
	if(!checkResponseStatus(data)){
		[ShowItem showErrorAct:getResponseMessage(data)];
		return;
	}
	
	if([getResponseFunc(data) isEqualToString:@"dayLuckEnter"]){
        
		//bool isVip=[[[[GameConfigure shared]getPlayerInfo]objectForKey:@"vip"]intValue]>=1?true:false;
        bool isVip = false;
        if ([getResponseData(data) objectForKey:@"state"]) {
            isVip = [[getResponseData(data) objectForKey:@"state"] intValue]==0?false:true;
        }
		hasLuckDrawTime=[[getResponseData(data) objectForKey:@"mdraws"] intValue]-[[getResponseData(data) objectForKey:@"draws"]intValue];
		if(hasLuckDrawTime<1){
			[[[CCDirector sharedDirector]touchDispatcher]removeDelegate:self];
		}
		maxLuckDrawTime = [[getResponseData(data) objectForKey:@"mdraws"] intValue];
		[self creatMaxLuckDLabel:hasLuckDrawTime];
		for(int i=0;i<4;i++){
			CCSprite *p=nil;
			if(i<=maxLuckDrawTime-(isVip?2:1) || (i==3 && isVip)){
                p=[CCSprite spriteWithFile:@"images/ui/activity/clogoselect.png"];
            }else{
				p=[CCSprite spriteWithFile:@"images/ui/activity/clogo.png"];
			}
			if(p){
				if (iPhoneRuningOnGame()) {
					[p setPosition:ccp(cFixedScale(454+i*52), cFixedScale(43))];
				}else{
					[p setPosition:ccp((392+i*52), (43))];
				}
				[self addChild:p];
			}
		}
		[self openPocker:[getResponseData(data) objectForKey:@"items"] delay:0];
		
	}
	
	if([getResponseFunc(data) isEqualToString:@"dayLuckDraw"]){
		CCLOG(@"%@",data);
		hasLuckDrawTime=[[getResponseData(data) objectForKey:@"mdraws"] intValue]-[[getResponseData(data) objectForKey:@"draws"] intValue];
		[self creatMaxLuckDLabel:hasLuckDrawTime];
		NSDictionary *item=getResponseData(data);
		NSArray *updateData = [[GameConfigure shared] getPackageAddData:[item objectForKey:@"update"]];
		for(NSDictionary *d in updateData){
			if([[d objectForKey:@"rid"]intValue]>0){
				
				NSMutableDictionary* dict = [NSMutableDictionary dictionary];
				[dict setObject:[NSNumber numberWithInt:EffectsAction_joinPartner] forKey:@"eid"];
				[dict setObject:[d objectForKey:@"rid"] forKey:@"other"];
				[[GameEffects share] showEffectsWithDict:dict target:nil call:nil];
				
			}
		}
		if([item objectForKey:@"update"]==nil){
			[ShowItem showErrorAct:@"-5"];
		}else{
			[[AlertManager shared] showReceiveItemWithArray:updateData];
			[[GameConfigure shared]updatePackage:[item objectForKey:@"update"]];
		}
		[self openPocker:[getResponseData(data) objectForKey:@"items"] delay:2];
	}
    //
	isEDLoginSend = NO;
}


#pragma mark 翻开抽过的牌
-(void)openPocker:(NSArray*)ar delay:(int)d{
	NSMutableArray *index=[NSMutableArray array];
	for(NSDictionary *dict in ar){
		if([[dict objectForKey:@"index"]intValue]>0){
			int c=[[dict objectForKey:@"c"]intValue];
			PockerFace *pf=(PockerFace*)[self getChildByTag:[[dict objectForKey:@"index"]intValue]+POCKERBASE-1];
			if(d==0){
				[pf setItemInfo:dict FlipX:NO mask:NO count:c];
				[pf showHand];
			}else{
				if (pf.isPlayFlipx) {
					pf.isPlayFlipx=false;
					[pf setItemInfo:dict FlipX:YES mask:NO count:c];
					[pf playFlip];
					
				}
			}
			[index addObject:[NSNumber numberWithInt:[[dict objectForKey:@"index"]intValue]]];
		}
	}
	if(ar.count==9){
		NSArray *var=[NSArray arrayWithObjects:index,ar,[NSNumber numberWithInt:d],nil];
		[self setUserObject:var];
		[self scheduleOnce:@selector(openOtherPocker) delay:d];
	}
}


#pragma mark 翻开未抽过的牌
-(void)openOtherPocker{
	NSMutableArray *index=[[self userObject] objectAtIndex:0];
	
	
	NSArray *ar=[[self userObject] objectAtIndex:1];
	NSSortDescriptor *sorter=[[[NSSortDescriptor alloc]initWithKey:@"index" ascending:YES] autorelease];
	NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:&sorter count:1] autorelease];
	ar = [ar sortedArrayUsingDescriptors:sortDescriptors];
	//[sortDescriptors release];
	int delay=[[[self userObject] objectAtIndex:2]intValue];
	int idx=0;
	for(int i=0;i<ar.count;i++){
		bool b=[index containsObject:[NSNumber numberWithInt:i+1]];
		if(b){
			continue;
		}
		NSDictionary *dict=[ar objectAtIndex:idx];
		int didx=[[dict objectForKey:@"index"]intValue];
		if(didx<=0){
			PockerFace *pf=(PockerFace*)[self getChildByTag:i+POCKERBASE];
			if(delay==0){
				[pf setItemInfo:dict FlipX:NO mask:YES count:0];
				[pf showHand];
			}else{
				[pf setItemInfo:dict FlipX:YES mask:YES count:0];
				[pf playFlip];
			}
			idx++;
		}
	}
	
	if(delay!=0){
		[self scheduleOnce:@selector(openEDcheck) delay:2];
	}
	
}

-(void)creatMaxLuckDLabel:(int)count{
	[self removeChildByTag:567 cleanup:YES];
	CCSprite *maxLuckDrawTimesp=drawString([NSString stringWithFormat:@"%i",count], CGSizeMake(200, 18), getCommonFontName(FONT_1), 18, 22, @"ffdf08");
	if(iPhoneRuningOnGame()){
		[maxLuckDrawTimesp setPosition:ccp(cFixedScale(545),cFixedScale(80))];
	}else{
		[maxLuckDrawTimesp setPosition:ccp((485),(75))];
	}
	[self addChild:maxLuckDrawTimesp z:1 tag:567];
}

-(void)openEDcheck{
	[[Window shared]removeWindow:PANEL_ACTIVITY];
}


-(void)onExit{
	[super onExit];
	[self unscheduleAllSelectors];
	[GameConnection removePostTarget:self];
    //TODO 闪烁
	//[[[CCDirector sharedDirector]touchDispatcher]removeDelegate:self];
    //
    isEDLoginSend = NO;
    //
    [ActivityEDLogin checkMaxhasLuckTime];
}


-(void)PockerFaceBtnCallBack:(CCSimpleButton*)b{
	if(drawLuckCoolDown){
		drawLuckCoolDown=false;
		[self scheduleOnce:@selector(coolDownok) delay:0.1];
	}else{
		return;
	}
	
	if(maxLuckDrawTime==0){
		return;
	}
    //
    if (isEDLoginSend) {
        return;
    }
    isEDLoginSend = YES;
    //
	int posPockerFace=b.tag-POCKERBASE;
	[b removeFromParentAndCleanup:true];
	[GameConnection request:@"dayLuckDraw" format:[NSString stringWithFormat:@"index::%i",posPockerFace+1] target:self call:@selector(didrequest:)];
	maxLuckDrawTime--;
}


-(void)coolDownok{
	drawLuckCoolDown=true;
}

@end
