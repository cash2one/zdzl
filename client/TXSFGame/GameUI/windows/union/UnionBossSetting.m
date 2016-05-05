//
//  UnionBossSetting.m
//  TXSFGame
//
//  Created by Max on 13-4-15.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "UnionBossSetting.h"
#import "CCSimpleButton.h"
#import "Config.h"
#import "StretchingImg.h"
#import "UnionPanel.h"
#import "GameConnection.h"


#define WEEKDAYBTN 1000
#define TIMEBTN 2000

@implementation UnionBossSetting


static UnionBossSetting *unionBossSetting = nil;


//NSString *day[7]={@"一",@"二",@"三",@"四",@"五",@"六",@"日"};
static NSString *day[7]={@"union_boss_set_monday",@"union_boss_set_tuesday",@"union_boss_set_wednesday",@"union_boss_set_thursday",@"union_boss_set_friday",@"union_boss_set_saturday",@"union_boss_set_sunday"};
static NSString *timear[6]={@"12:00",@"13:00",@"13:30",@"20:00",@"20:30",@"21:00"};

+(void)show{
	[UnionBossSetting hide];
	if([UnionPanel share]){
		unionBossSetting = [UnionBossSetting node];
		unionBossSetting.position = ccp([UnionPanel share].contentSize.width/2,[UnionPanel share].contentSize.height/2);
		[[UnionPanel share] addChild:unionBossSetting z:10000];
	}
}
+(void)hide{
	if(unionBossSetting){
		int count  = [unionBossSetting retainCount];
		CCLOG(@"%d",count);
		[unionBossSetting removeFromParentAndCleanup:YES];
	}
}

-(void)onEnter{
	[super onEnter];
	
	currenWD=-1;
	wdStr=[[NSMutableString alloc]init];
	tStr =[[NSMutableString alloc]init];
	bg=[CCSprite spriteWithFile:@"images/ui/panel/p3.png"];
	CCSprite *bgbound=[StretchingImg stretchingImg:@"images/ui/union/bounds.png" width:bg.contentSize.width-cFixedScale(40) height:cFixedScale(380) capx:1 capy:1];
	CCSimpleButton *btn_close=[CCSimpleButton spriteWithFile:@"images/ui/button/bt_close.png"];
	CCSprite *title=[CCSprite spriteWithFile:@"images/ui/union/unionbw-title.png"];
	CCSimpleButton *ok=[CCSimpleButton spriteWithFile:@"images/ui/alert/bt_ok_1.png"];
	CCSprite *line=[CCSprite spriteWithFile:@"images/ui/common/line.png"];
	CCSprite *tips=nil;
	if (iPhoneRuningOnGame()) {
		//tips=drawString(@"本周同盟首领战将于                         开启", CGSizeMake(1000,1), getCommonFontName(FONT_1), 20, 24, @"ffffff");
        tips=drawString(NSLocalizedString(@"union_boss_set_open",nil), CGSizeMake(1000,1), getCommonFontName(FONT_1), 20, 24, @"ffffff");
		
	}else{
		//tips=drawString(@"本周同盟首领战将于                    开启", CGSizeMake(1000,1), getCommonFontName(FONT_1), 20, 24, @"ffffff");
        tips=drawString(NSLocalizedString(@"union_boss_set_open",nil), CGSizeMake(1000,1), getCommonFontName(FONT_1), 20, 24, @"ffffff");
	}
    //
    tips.tag = 12346;
    //
    
	//CCSprite *tips1=drawString(@"活动开启前，随时可以更改日期", CGSizeMake(1000,1), getCommonFontName(FONT_1), 20, 24, @"ffffff");
    CCSprite *tips1=drawString(NSLocalizedString(@"union_boss_set_change",nil), CGSizeMake(1000,1), getCommonFontName(FONT_1), 20, 24, @"ffffff");
	CCSprite *datebound=[StretchingImg stretchingImg:@"images/ui/bound.png" width:cFixedScale(130) height:cFixedScale(30) capx:cFixedScale(8) capy:cFixedScale(8)];
	//weekDayStr=drawString(@"周", CGSizeMake(100,1), getCommonFontName(FONT_1), 20, 24, @"ff0000");
    weekDayStr=drawString(NSLocalizedString(@"union_boss_set_week",nil), CGSizeMake(100,1), getCommonFontName(FONT_1), 20, 24, @"ff0000");
	timeStr=drawString(@"01:23",  CGSizeMake(100,1), getCommonFontName(FONT_1), 20, 24, @"ff0000");
	CCSprite *biglogo=[CCSprite spriteWithFile:@"images/ui/union/monster_icon_1006.png"];
	
	
	CCSimpleButton *selecttime_btn=[CCSimpleButton spriteWithSize:datebound.contentSize block:^{
		[self openSelectTime];
	}];
	
	
	btn_close.target=self;
	btn_close.priority=-300;
	btn_close.call=@selector(btnCallBackClose);
	
	ok.priority=-300;
	[ok setTarget:self];
	[ok setCall:@selector(btnOk)];
	
	selecttime_btn.priority=-300;
	
	[btn_close setPosition:ccp(bg.contentSize.width-btn_close.contentSize.width/1.5, bg.contentSize.height-btn_close.contentSize.height/1.5)];
	[title setPosition:ccp(bg.contentSize.width/2, bg.contentSize.height-title.contentSize.height/5)];
	[bgbound setPosition:ccp(bg.contentSize.width/2, cFixedScale(200))];
	if (iPhoneRuningOnGame()) {
		ok.scale=1.3f;
		[ok setPosition:ccp(bg.contentSize.width/2, 45/2.0)];
		[datebound setPosition:ccp(365/2.0f, 133/2.0f)];
        datebound.scaleY = 0.65f;
		[biglogo setPosition:ccp(bg.contentSize.width/2, 330/2.0f)];
	}else{
		[ok setPosition:ccp(bg.contentSize.width/2, 50)];
		[datebound setPosition:ccp(cFixedScale(370), 133)];
		[biglogo setPosition:ccp(bg.contentSize.width/2, 300)];
	}
	[line setPosition:ccp(bg.contentSize.width/2, cFixedScale(80))];
	[tips setPosition:ccp(bg.contentSize.width/2, cFixedScale(130))];
	[tips1 setPosition:ccp(bg.contentSize.width/2, cFixedScale(100))];
	[weekDayStr setPosition:ccp(cFixedScale(310), cFixedScale(133))];
	[timeStr setPosition:ccp(cFixedScale(360), cFixedScale(133))];
	[selecttime_btn setPosition:ccp(datebound.contentSize.width/2, datebound.contentSize.height/2)];
	//showNode(biglogo);
	//	showNode(selecttime_btn);
	
	[weekDayStr setAnchorPoint:ccp(0, 0.5)];
	[timeStr setAnchorPoint:ccp(0, 0.5)];
	
	[line setScaleX:0.6];
	
	[bg addChild:bgbound];
	
	int posx=cFixedScale(70);
	int posy=220;
	int indexpos=0;
	float fontSize=20;
	if (iPhoneRuningOnGame()) {
		posy=245/2.0f;
		fontSize=22;
	}
	for(int i=0;i<7;i++){
		CCSimpleButton *weekday_btn=[CCSimpleButton spriteWithFile:@"images/ui/union/union-noselect.png" select:@"images/ui/union/union-select.png"];
		weekday_btn.priority=-300;
		//CCSprite *weekday_string=drawString([NSString stringWithFormat:@"周%@",day[i]],CGSizeMake(100, 1) , getCommonFontName(FONT_1), fontSize, 24, @"666666");union_boss_set_date
        CCSprite *weekday_string=drawString([NSString stringWithFormat:@"%@%@",NSLocalizedString(@"union_boss_set_week",nil),NSLocalizedString(day[i],nil)],CGSizeMake(100, 1) , getCommonFontName(FONT_1), fontSize, 24, @"666666");
		[weekday_string setPosition:ccp(weekday_btn.contentSize.width/2+weekday_string.contentSize.width, weekday_btn.contentSize.height/2)];
		[weekday_btn addChild:weekday_string z:1 tag:10];
		[weekday_btn setPosition:ccp(posx+indexpos*cFixedScale(140), posy)];
		[weekday_btn setTarget:self];
		[weekday_btn setCall:@selector(weekdayBtnCallBack:)];
		
		indexpos++;
		if(i==3){
			if (iPhoneRuningOnGame()) {
				posy=185/2.0f;
			}else{
				posy=180;
			}
			indexpos=0;
		}
		
		[bg addChild:weekday_btn z:1 tag:WEEKDAYBTN+i];
		
	}
	[datebound addChild:selecttime_btn];
	[bg addChild:title];
	[bg addChild:btn_close];
	[bg addChild:ok];
	[bg addChild:line];
	[bg addChild:tips];
	[bg addChild:tips1];
	[bg addChild:datebound];
	[bg addChild:weekDayStr];
	[bg addChild:timeStr];
	[bg addChild:biglogo];
	[self addChild:bg];
	[GameConnection request:@"allyGetBossTime" format:@"" target:self call:@selector(didRecvallyGetBossTime:)];
	
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:-150 swallowsTouches:YES];
	
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
	return YES;
}

-(void)didRecvallyGetBossTime:(NSDictionary*)n{
	if(checkResponseStatus(n)){
		CCLOG(@"%@",getResponseData(n));
		
		NSArray *data=[[getResponseData(n) objectForKey:@"t"]componentsSeparatedByString:@"-"];
		int weekday=[[data objectAtIndex:0]integerValue]==0?1:[[data objectAtIndex:0]integerValue];
		[self weekdayBtnCallBack:(CCSimpleButton*)[bg getChildByTag:(WEEKDAYBTN+(weekday-1))]];
		
		NSString *time=[NSString stringWithFormat:@"%@:%@",[data objectAtIndex:1],[data objectAtIndex:2]];
		[self setWeekTimeDay:time target:timeStr wt:1];
		[wdStr setString:[NSString stringWithFormat:@"%i",weekday-1]];
		[tStr setString:time];
		int isf= [[getResponseData(n) objectForKey:@"isfight"]integerValue];
		if(!isf){

			currenWD=[[getResponseData(n) objectForKey:@"w"]integerValue];
			for(int i=0;i<currenWD;i++){
				[bg getChildByTag:WEEKDAYBTN+i].visible=NO;
			}

		}else{
            //
            CCSprite *tips = (CCSprite *)[bg getChildByTag:12346];
            if (tips) {
                CGPoint pos = tips.position;
                [bg removeChildByTag:12346 cleanup:YES];
                CCSprite *tips = nil;
                if (iPhoneRuningOnGame()) {;
                    tips=drawString(NSLocalizedString(@"union_boss_next_set_open",nil), CGSizeMake(1000,1), getCommonFontName(FONT_1), 20, 24, @"ffffff");
                    
                }else{
                    tips=drawString(NSLocalizedString(@"union_boss_next_set_open",nil), CGSizeMake(1000,1), getCommonFontName(FONT_1), 20, 24, @"ffffff");
                }
                //
                tips.tag = 12346;
                tips.position = pos;
                [bg addChild:tips];
                //
            }
            //
        }
	}
}

-(void)didRecvallySetBossTime:(NSDictionary*)n{
	if(checkResponseStatus(n)){
		//[ShowItem showItemAct:@"设置成功"];
        [ShowItem showItemAct:NSLocalizedString(@"union_boss_set_ok",nil)];
	}else{
		//[ShowItem showItemAct:@"设置失败"];
        [ShowItem showItemAct:NSLocalizedString(@"union_boss_set_fail",nil)];
	}
}

-(void)btnOk{
	NSString *str=[NSString stringWithFormat:@"t:%i-%@",wdStr.integerValue+1,[tStr stringByReplacingOccurrencesOfString:@":" withString:@"-"]];
	[GameConnection request:@"allySetBossTime" format:str target:self call:@selector(didRecvallySetBossTime:)];
}



-(void)btnCallBackClose{
	
	//[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	//[self removeFromParentAndCleanup:true];
	[UnionBossSetting hide];
}

-(void)weekdayBtnCallBack:(CCSimpleButton*)_b{
	float fontSize=20;
	if (iPhoneRuningOnGame()) {
		fontSize=22;
	}

	for(int i=0;i<7;i++){
		CCSimpleButton *b=(CCSimpleButton*)[bg getChildByTag:WEEKDAYBTN+i];
		[b removeChildByTag:10];
		[b setSelected:NO];
		//CCSprite *weekday_string=drawString([NSString stringWithFormat:@"周%@",day[b.tag-WEEKDAYBTN]],CGSizeMake(100, 1) , getCommonFontName(FONT_1), fontSize, 24, @"666666");
        CCSprite *weekday_string=drawString([NSString stringWithFormat:@"%@%@",NSLocalizedString(@"union_boss_set_week",nil),NSLocalizedString(day[b.tag-WEEKDAYBTN],nil)],CGSizeMake(100, 1) , getCommonFontName(FONT_1), fontSize, 24, @"666666");
		[weekday_string setPosition:ccp(b.contentSize.width/2+weekday_string.contentSize.width, b.contentSize.height/2)];
		[b addChild:weekday_string];
	}
	CCSimpleButton *weekday_btn=(CCSimpleButton*)_b;
	[weekday_btn setSelected:YES];
	[weekday_btn removeChildByTag:10];
	//CCSprite *weekday_string=drawString([NSString stringWithFormat:@"周%@",day[weekday_btn.tag-WEEKDAYBTN]],CGSizeMake(100, 1) , getCommonFontName(FONT_1), fontSize, 24, @"ffff00");
    CCSprite *weekday_string=drawString([NSString stringWithFormat:@"%@%@",NSLocalizedString(@"union_boss_set_week",nil),NSLocalizedString(day[weekday_btn.tag-WEEKDAYBTN],nil)],CGSizeMake(100, 1) , getCommonFontName(FONT_1), fontSize, 24, @"ffff00");
	[weekday_string setPosition:ccp(weekday_btn.contentSize.width/2+weekday_string.contentSize.width, weekday_btn.contentSize.height/2)];
	[weekday_btn addChild:weekday_string];
	//[self setWeekTimeDay:[NSString stringWithFormat:@"周%@",day[weekday_btn.tag-WEEKDAYBTN]] target:weekDayStr wt:0];
    [self setWeekTimeDay:[NSString stringWithFormat:@"%@%@",NSLocalizedString(@"union_boss_set_week",nil),NSLocalizedString(day[weekday_btn.tag-WEEKDAYBTN],nil)] target:weekDayStr wt:0];
	[wdStr setString:[NSString stringWithFormat:@"%i",weekday_btn.tag-WEEKDAYBTN]];
}

-(void)setWeekTimeDay:(NSString*)day target:(CCNode*)tar wt:(int)_wt{
	if(tar){
		CGPoint p=tar.position;
		[tar removeFromParentAndCleanup:true];
		tar=nil;
		tar =drawString(day, CGSizeMake(100,1), getCommonFontName(FONT_1), 20, 24, @"ff0000");
		[tar setAnchorPoint:ccp(0, 0.5)];
		[tar setPosition:p];
		[bg addChild:tar];
		if(_wt==0){
			weekDayStr=(CCSprite*)tar;
		}else{
			timeStr=(CCSprite*)tar;
		}
	}
}



-(void)openSelectTime{
	if(timeBtnBg){
		[timeBtnBg removeFromParentAndCleanup:true];
		timeBtnBg=nil;
	}
	if (iPhoneRuningOnGame()) {
		timeBtnBg=[StretchingImg stretchingImg:@"images/ui/union/bounds.png" width:95/2.0f height:189/2.0f capx:1 capy:1];
	}else{
		timeBtnBg=[StretchingImg stretchingImg:@"images/ui/union/bounds.png" width:80 height:130 capx:1 capy:1];
	}
	for(int i=0;i<6;i++){
		float fontSize=18;
		float lineH=22;
		if (iPhoneRuningOnGame()) {
			fontSize=26;
			lineH=28;
		}
		CCSprite *timestr=drawString(timear[i], CGSizeMake(100, 1), getCommonFontName(FONT_1), fontSize,lineH, @"ffffff");
		
		CCSimpleButton *b=[CCSimpleButton spriteWithNode:timestr];
		b.priority=-300;
		[b setTarget:self];
		[b setCall:@selector(timebtnCallBack:)];
		[b setTag:TIMEBTN+i];
		[b setAnchorPoint:ccp(0, 0)];
		if (iPhoneRuningOnGame()) {
			[b setPosition:ccp(2.5f, i*30/2.0f)];
		}else{
			[b setPosition:ccp(5, i*20)];
		}
		[timeBtnBg addChild:b];
	}
	[timeBtnBg setPosition:ccp(cFixedScale(500),cFixedScale(100))];
	timeBtnBg.tag=12341;
	[bg addChild:timeBtnBg];
	
}


-(void)timebtnCallBack:(CCSimpleButton*)n
{
	if(timeBtnBg){
		[tStr setString:timear[n.tag-TIMEBTN]];
		[self setWeekTimeDay:tStr target:timeStr wt:1];
		[timeBtnBg removeFromParentAndCleanup:true];
		timeBtnBg=nil;
	}

}

-(id)retain{
	CCLOG(@"");
	return [super retain];
}

-(oneway void)release{
	[super release];
}

-(void)onExit{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	
	[tStr release];
	[wdStr release];
	
	unionBossSetting = nil ;
	
	if (bg) {
		[bg removeFromParentAndCleanup:YES];
		bg = nil ;
	}
	
	[super onExit];
}

-(void)dealloc{
	CCLOG(@"UnionBossSetting->dealloc");
	[super dealloc];
}




@end
