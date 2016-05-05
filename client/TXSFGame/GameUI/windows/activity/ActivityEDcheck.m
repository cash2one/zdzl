//
//  ActivityEDcheck.m
//  TXSFGame
//
//  Created by Max on 13-5-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ActivityEDcheck.h"
#import "CCPanel.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "CJSONDeserializer.h"
#import "Window.h"
#import "Game.h"
#import "RoleViewerContent.h"
#import "InfoAlert.h"
#import "ActivityEDLogin.h"

@implementation RoleInfo

@synthesize rid;

+(void)showRoleInfo:(int)rid{
	RoleInfo *roleinfo=[RoleInfo node];
	roleinfo.rid=rid;
	[[Game shared] addChild:roleinfo z:INT32_MAX];
}


-(void)onEnter{
	[super onEnter];
	NSDictionary *roledict=[[GameDB shared]getRoleInfo:rid];
	NSString *name=[roledict objectForKey:@"name"];
	NSString *job=[roledict objectForKey:@"job"];
	int *skillid=[[roledict objectForKey:@"sk2"]intValue];
	NSString *skill=[[[GameDB shared]getSkillInfo:skillid]objectForKey:@"name"];
	NSString *desc=[roledict objectForKey:@"info"];
	
	[[[CCDirector sharedDirector]touchDispatcher ]addTargetedDelegate:self priority:INT32_MIN+2 swallowsTouches:YES];
	CCSprite *bg=[CCSprite spriteWithFile:@"images/ui/activity/bgrole.png"];
	CCLabelTTF *labelName=[CCLabelTTF labelWithString:name fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18)];
	CCLabelTTF *labelJob=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"职阶 : %@",job] fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(16)];
	CCLabelTTF *labelSkill=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"绝技 : %@",skill] fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(16)];
	CCLabelTTF *labelDesc=[CCLabelTTF labelWithString:desc fontName:getCommonFontName(FONT_1) fontSize:cFixedScale(18) dimensions:CGSizeMake(cFixedScale(270), cFixedScale(200)) hAlignment:kCCTextAlignmentLeft];
	CCSprite *bp=[CCSprite spriteWithFile:@"images/ui/panel/phalanx22.png"];
	rvc=[RoleViewerContent node];
	[rvc loadTargetRole:rid];
	CCSimpleButton *showskillbtn=[CCSimpleButton node];

	[showskillbtn setContentSize:CGSizeMake(cFixedScale(100), cFixedScale(200))];
	[showskillbtn setTarget:self];
	[showskillbtn setCall:@selector(btnCallBack)];
	[showskillbtn setPriority:INT32_MIN+1];
	

	[rvc setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height-cFixedScale(230))];

	[showskillbtn setPosition:rvc.position];
	[bp setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height-cFixedScale(230))];
	[labelName setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height-cFixedScale(15))];
	[labelJob setPosition:ccp(cFixedScale(50), bg.contentSize.height-cFixedScale(50))];
	[labelSkill setPosition:ccp(cFixedScale(235), bg.contentSize.height-cFixedScale(50))];
	[labelDesc setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height-cFixedScale(375))];
	
	[labelName setColor:ccc3(255, 234, 0)];
	[labelJob setColor:ccc3(255, 200, 0)];
	[labelSkill setColor:ccc3(255, 200, 0)];
	[labelDesc setColor:ccc3(255, 255, 220)];
	
	
	[bg addChild:showskillbtn];
	[bg addChild:bp];
	[bg addChild:labelName];
	[bg addChild:labelJob];
	[bg addChild:labelSkill];
	[bg addChild:labelDesc];
	[bg addChild:rvc];
	addTargetToCenter(bg, self, 1);
}


-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	[self removeFromParentAndCleanup:true];
	return YES;
}

-(void)onExit{
	[super onExit];
	[[[CCDirector sharedDirector]touchDispatcher]removeDelegate:self];
}

-(void)btnCallBack{
	[rvc showSkill];
}


@end



@implementation ActivityEDcheckCell

@synthesize day,status,lastDay,selector,target;

+(ActivityEDcheckCell*)Cell:(int)day  status:(Cellst)st{
	ActivityEDcheckCell *cell=[ActivityEDcheckCell node];
	cell.day=day;
	
	cell.status=st;
	cell.contentSize=CGSizeMake(cFixedScale(309), cFixedScale(60));
	return cell;
}


-(void)onEnter{
	[super onEnter];

	NSString *descStr=[[[GameDB shared]getGlobalConfig] objectForKey:@"daySignDay2Rid"];
	NSDictionary *descDict=getFormatToDict(descStr);
	int rewardId=[[descDict objectForKey:[NSString stringWithFormat:@"%i",day+1]]intValue];
	NSDictionary *rewardDict=[[GameDB shared]getRewardInfo:rewardId];
	NSString *rewardinfostr=[rewardDict objectForKey:@"info"];
	NSString *rewardstr=[rewardDict objectForKey:@"reward"];
	NSError *err=nil;
	
	NSArray *gif=[[CJSONDeserializer deserializer]deserializeAsArray:[rewardstr dataUsingEncoding:NSUTF8StringEncoding] error:&err];
	
	CCSprite *cell=[CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/activity/cell%i.png",(day+1)%3?0:1]];
	
	if(day==14){
		cell=[CCSprite spriteWithFile:@"images/ui/activity/cell2.png"];
	}
	
	CCSimpleButton *b=[CCSimpleButton spriteWithFile:@"images/ui/button/bts_get_1.png" select:@"images/ui/button/bts_get_1.png" invalid:@"images/ui/activity/getbtn0.png" target:self call:@selector(CallBackEDcheckCell:)];
	
	NSString* path = [NSString stringWithFormat:@"images/ui/num/num-2.png"];
	CCSprite* daytime = getImageNumber(path, 15, 25, day+1);
	[cell setAnchorPoint:CGPointZero];
	CCSprite *desc=drawString(rewardinfostr, CGSizeMake(300, 22), getCommonFontName(FONT_1), 18, 22, @"ffffff");
	
	CCSprite *itemLogo=nil;
	
	for(NSDictionary *d in gif){
		int iid=[[d objectForKey:@"i"] intValue];
		if([[d objectForKey:@"t"]isEqualToString:@"i"]){
			itemLogo=getItemIcon(iid);
		}
		if([[d objectForKey:@"t"]isEqualToString:@"e"]){
			itemLogo=getEquipmentIcon(iid);
		}
		if([[d objectForKey:@"t"]isEqualToString:@"f"]){
			int qa=[[d objectForKey:@"q"]intValue];
			itemLogo=getFateIconWithQa(iid,qa);
		}
		if([[d objectForKey:@"t"]isEqualToString:@"c"]){
			itemLogo=getCarIcon(iid);
		}
		if([[d objectForKey:@"t"]isEqualToString:@"r"]){
			itemLogo=getTMemberIcon(iid);
		}
	}
	
	float w=self.contentSize.width*self.scaleX;
	[b setPosition:ccp(w-cFixedScale(10), cFixedScale(30))];
	[desc setPosition:ccp(cFixedScale(170), cFixedScale(30))];
	[daytime setPosition:ccp(cFixedScale(40), cFixedScale(31))];
	

	[cell setContentSize:self.contentSize];
	[cell addChild:daytime];
	[cell addChild:desc];
	[cell addChild:b];
	b.anchorPoint=ccp(1.0,0.5);

	
	[self addChild:cell];
	
	if(itemLogo){
		[itemLogo setScale:0.6];
		[itemLogo setPosition:ccp(cFixedScale(100), cFixedScale(30))];
		[self addChild:itemLogo];
	}
	switch (status) {
		case Geted:{
			b.visible=NO;
			CCSprite *getsp=[CCSprite spriteWithFile:@"images/ui/activity/geted.png"];
			[getsp setPosition:ccp(cFixedScale(260), cFixedScale(30))];
			[self addChild:getsp];
		}
			break;
			
		case CanGet:{
			
		}
			break;
		case CanNotGet:{
			[b setInvalid:YES];
		}
			break;
		default:
			break;
	}
	
	
}

-(void)CallBackEDcheckCell:(CCSimpleButton*)b{
	if (![self checkTouchValid]) {
		return;
	} 
	[target performSelector:selector withObject:b];
}

-(BOOL)checkTouchValid{
	for( CCNode *c = self.parent; c != nil; c = c.parent ){
		if( [c isKindOfClass:[CCPanel class]]){
			CCPanel* temp = (CCPanel*)c;
			return temp.isTouchValid;
		}
	}
	return YES;
}


@end




@implementation ActivityEDcheck

-(void)onEnter{
	[super onEnter];
	CCSprite *bg=[CCSprite spriteWithFile:@"images/ui/activity/bgde.png"];
	CCSimpleButton *btn=[CCSimpleButton spriteWithFile:@"images/ui/activity/descbtn.png"];
	[btn setPosition:ccp(cFixedScale(480), cFixedScale(48))];
	[btn setTarget:self];
	[btn setCall:@selector(openRoleinfo)];
	
	[bg setAnchorPoint:CGPointZero];
	
	[self addChild:bg];
	[self addChild:btn];
    //fix chao
    RuleButton *ruleButton = [RuleButton node];
    if (iPhoneRuningOnGame()) {
		bg.scale=1.12f;
        ruleButton.scale = 1.19;
    }
    ruleButton.type = RuleType_sign;
    ruleButton.priority = -129;
    [self addChild:ruleButton z:100];
    CGPoint pos = ccp(bg.contentSize.width*bg.scaleX+ruleButton.contentSize.width, bg.contentSize.height*bg.scaleY-ruleButton.contentSize.height);
    ruleButton.position = ccp(pos.x-cFixedScale(WINDOW_RULE_OFF_X)* ruleButton.scale, pos.y-cFixedScale(WINDOW_RULE_OFF_Y)* ruleButton.scale);
    //end
	[GameConnection request:@"daySignDid" format:@"" target:self call:@selector(didRequest:)];
	[GameConnection addPost:ConnPost_updatePackageLuck target:self call:@selector(showUpdatePackage:)];
	

}

-(void)showUpdatePackage:(NSNotification*)nof{
	NSArray *updateData = [[GameConfigure shared] getPackageAddData:nof.object type:PackageItem_all];
	[[AlertManager shared] showReceiveItemWithArray:updateData];
}

-(void)openRoleinfo{
	[RoleInfo showRoleInfo:20003];
}


-(void)didRequest:(NSDictionary*)dict{
	if(checkResponseStatus(dict)){
		int day=[[getResponseData(dict) objectForKey:@"finish"]intValue];
		bool sigh=[[getResponseData(dict) objectForKey:@"sign"]intValue];
		[self creatCheckList:day todaysigh:sigh];
		Cellst st=CanNotGet;
		if(day<14){
			st=CanNotGet;
		}
		if(day==14 && !sigh){
			st=CanGet;
		}
		if(day>14 && sigh){
			st=Geted;
		}
		
		ActivityEDcheckCell *cell=[ActivityEDcheckCell Cell:14  status:st];
		[cell setPosition:ccp(cFixedScale(25), cFixedScale(13))];
		[cell setTarget:self];
		[cell setSelector:@selector(bigCellCallBack)];
		[self addChild:cell];
	}
	
}







-(void)creatCheckList:(int)c todaysigh:(bool)sigh{
	[self removeChildByTag:1111 cleanup:YES];
	CCLayer *content=[CCLayer node];
	for(int i=0;i<14;i++){
		Cellst st=CanNotGet;
		if(i>c){
			st=CanNotGet;
		}
		if(i<c){
			st=Geted;
		}
		if(i==c && !sigh){
			
			st=CanGet;
		}
		ActivityEDcheckCell *cell=[ActivityEDcheckCell Cell:i  status:st];
		[cell setTarget:self];
		[cell setSelector:@selector(cellCallBack:)];
		[content addChild:cell];
	}
	[CCPanel makeNodeQueue:content vertical:YES ascending:YES gep:7];
	CCPanel *panel=[CCPanel panelWithContent:content viewSize:CGSizeMake(content.contentSize.width, cFixedScale(400))];
	[panel showScrollBar:@"images/ui/common/scroll3.png"];
	if(c<8){
		[panel updateContentToTop:67*c];
	}else{
		[panel updateContentToBottom];
	}
	[panel setPosition:ccp(cFixedScale(25),cFixedScale(80))];
	[self addChild:panel z:1 tag:1111];
	
}

-(void)onExit{
	[super onExit];
	[GameConnection removePostTarget:self];
}

-(void)bigCellCallBack{
	[[Window shared]removeWindow:PANEL_ACTIVITY];
	[GameConnection request:@"daySign" format:@"" target:nil call:nil];
}


-(void)cellCallBack:(CCSimpleButton*)b{
	[GameConnection request:@"daySign" format:@"" target:self call:@selector(didRequest:)];
}

@end
