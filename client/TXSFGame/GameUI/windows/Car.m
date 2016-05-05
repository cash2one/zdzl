//
//  Car.m
//  TXSFGame
//
//  Created by Max on 13-3-4.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "Car.h"
#import "CarViewerContent.h"
#import "ItemIconViewerContent.h"
#import "InfoAlert.h"
#import "CarIconViewerContent.h"
#import "CarNameViewContent.h"

#define selfheight self.contentSize.height
#define selfwidth self.contentSize.width
@implementation Car

-(void)onEnter{
	
	[super onEnter];
	
	int rid=[[[[GameConfigure shared]getPlayerInfo]objectForKey:@"rid"]integerValue];
	playerOffset=[[[[GameDB shared]getRoleInfo:rid]objectForKey:@"offset"]integerValue];

	CCSprite *bg1=nil;
	CCSprite *bg2=nil;

	btn_ByCar=[CCSimpleButton spriteWithFile:@"images/ui/car/bycar1.png" select:@"images/ui/car/bycar2.png" invalid:@"images/ui/car/bycar3.png" target:self call:@selector(byAndBuyCarCallBack:)];
	btn_BuyCar=[CCSimpleButton spriteWithFile:@"images/ui/car/buycar1.png" select:@"images/ui/car/buycar2.png" invalid:@"images/ui/car/buycar3.png" target:self call:@selector(byAndBuyCarCallBack:)];
	
	btn_OutCar=[CCSimpleButton spriteWithFile:@"images/ui/car/outcar1.png"  select:@"images/ui/car/outcar2.png" invalid:@"images/ui/car/outcar3.png" target:self call:@selector(byAndBuyCarCallBack:)];
	
	
	if (iPhoneRuningOnGame()) {
		bg1=[CCSprite spriteWithFile:@"images/ui/wback/bg1.jpg"];
		bg2=[CCSprite spriteWithFile:@"images/ui/wback/select_bg.png"];
		bg_payitem=[CCSprite spriteWithFile:@"images/ui/wback/bg_payitem.png"];
	}else{
		bg1=[CCSprite spriteWithFile:@"images/ui/car/bg1.jpg"];
		bg2=[CCSprite spriteWithFile:@"images/ui/car/select_bg.png"];
		bg_payitem=[CCSprite spriteWithFile:@"images/ui/car/bg_payitem.png"];
	}

	CCSprite *payitem24 = [ItemIconViewerContent create:24];
	CCSprite *payitem25 = [ItemIconViewerContent create:25];
	
	[payitem24 setAnchorPoint:CGPointZero];
	[payitem25 setAnchorPoint:CGPointZero];
	
    if (iPhoneRuningOnGame()) {

		btn_BuyCar.scale=1.3f;
		btn_ByCar.scale=1.3f;
		btn_OutCar.scale=1.3f;
		
		[bg1 setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2-16/2)];
		[bg2 setPosition:ccp(self.contentSize.width/2, 200/2)];
		[btn_ByCar setPosition:ccp(200/2+44, 120/2)];
		[btn_OutCar setPosition:ccp(200/2+44,120/2)];
		[btn_BuyCar setPosition:ccp(self.contentSize.width-200/2+44, 120/2)];
		[bg_payitem setPosition:ccp(160/2+44, 40/2+5)];
		[payitem24 setPosition:ccp(-payitem24.contentSize.width/2.0f,-3)];
		[payitem25 setPosition:ccp(100/2.0f, -2)];
		payitem24.scale=1.0f;
		payitem25.scale=payitem24.scale;
    }else{
        [_closeBnt setPosition:ccp(self.contentSize.width-cFixedScale(40),self.contentSize.height-cFixedScale(40))];
        [bg1 setPosition:ccp(self.contentSize.width/2, self.contentSize.height/2-23)];
        [bg2 setPosition:ccp(self.contentSize.width/2, cFixedScale(200))];
        [btn_ByCar setPosition:ccp(cFixedScale(200), cFixedScale(120))];
        [btn_OutCar setPosition:ccp(cFixedScale(200),cFixedScale(120))];
        [btn_BuyCar setPosition:ccp(self.contentSize.width-cFixedScale(200), cFixedScale(120))];
        [bg_payitem setPosition:ccp(cFixedScale(140), cFixedScale(40))];
        [payitem24 setPosition:ccp(0, 0)];
        [payitem25 setPosition:ccp(cFixedScale(100), 0)];
		[payitem24 setScale:0.7];
		[payitem25 setScale:0.7];
	}
	
	[bg_payitem addChild:payitem24];
	
	[bg_payitem addChild:payitem25];
	
	btn_ByCar.tag=1;
	btn_BuyCar.tag=2;
	btn_OutCar.tag=3;
	[self addChild:bg1];
	[self addChild:btn_ByCar];
	[self addChild:btn_BuyCar];
	[self addChild:btn_OutCar];
	[self addChild:bg_payitem];
	[self addChild:bg2];
	
	[self showRole];
	
	[self showPlayerOnCar:NO];
	
	[self countItem2425];
	[self creatCarList];
	[self configTwoButton];
}

-(void)showPlayerOnCar:(bool)isOnCar{
	//[player stopAllActions];
	if(isOnCar){
		id move=[CCMoveTo actionWithDuration:0.3 position:ccp(self.contentSize.width/2,cFixedScale(330)-cFixedScale(playerOffset))];
		[player runAction:move];
	}else{
		id move=[CCMoveTo actionWithDuration:0.3 position:ccp(self.contentSize.width/2,cFixedScale(300)-cFixedScale(playerOffset))];
		[player runAction:move];
	}
}

-(void)showRole{
	
	player = [AnimationRole node];
	[player setPosition:ccp(self.contentSize.width/2,cFixedScale(300)-cFixedScale(playerOffset))];
	player.anchorPoint = ccp(0.5,0);
	[self addChild:player z:10];
	
	player.roleId = [RoleManager shared].player.role_id;
	player.suitId = [RoleManager shared].player.suit_id;
	player.roleDir = RoleDir_down;
	player.roleAction = RoleAction_stand;
	[player showRole];
	
}

#pragma mark 创建坐骑列表
-(void)creatCarList{
	NSArray *_tempcarlist=[[[GameDB shared]readDB:@"car"] allValues];
	NSSortDescriptor *sorter=[[[NSSortDescriptor alloc]initWithKey:@"id" ascending:YES] autorelease];
	NSArray *sortDescriptors = [[[NSArray alloc] initWithObjects:&sorter count:1] autorelease];
	carlist = [_tempcarlist sortedArrayUsingDescriptors:sortDescriptors];
	
	int myCurCarCid=[[[[GameConfigure shared]getPlayerInfo]objectForKey:@"car"]integerValue];
	[carlist retain];
	//[sortDescriptors release];
	int width=0;
	
	CCLayerColor *contentlist=[CCLayerColor layerWithColor:ccc4(0, 0, 0, 0)];
	for(int i=0;i<carlist.count;i++){
		int qua=[[[carlist objectAtIndex:i]objectForKey:@"quality"]integerValue];
		int carid=[[[carlist objectAtIndex:i]objectForKey:@"id"]integerValue];
		if(carid==myCurCarCid){
			currenSelectCar=[carlist objectAtIndex:i];
			[self showCar];
		}
		NSString *quaPath=[NSString stringWithFormat:@"images/ui/common/quality%i.png",qua];
		CCSprite *btn_bg=[CCSprite spriteWithFile:quaPath];
		
		//NSString *btn_selectcar_str=[NSString stringWithFormat:@"images/ui/car/car%i.png",carid];
		//CCSimpleButton *btn_selectcar=[CCSimpleButton spriteWithFile:btn_selectcar_str];
		
		CarIconViewerContent * carIcon = [CarIconViewerContent create:carid];
		carIcon.position = ccp(cFixedScale(63)/2, cFixedScale(63)/2);
		
		CCSimpleButton * btn_selectcar= [CCSimpleButton node];
		btn_selectcar.contentSize = CGSizeMake(cFixedScale(63), cFixedScale(63));
		[btn_selectcar addChild:carIcon];
		
		[btn_selectcar setTarget:self];
		[btn_selectcar setCall:@selector(selectCarCallBack:)];
		btn_selectcar.tag=i;
		[btn_bg setAnchorPoint:ccp(0, 0)];
		[btn_bg setPosition:ccp(cFixedScale(i*100), 0)];
		
		addTargetToCenter(btn_selectcar,btn_bg, carid);
		[contentlist addChild:btn_bg];
		width+=100;
	}
//    if (iPhoneRuningOnGame()) {
//        [contentlist setContentSize:CGSizeMake(cFixedScale(width), cFixedScale(84))];        
//    }else{
        [contentlist setContentSize:CGSizeMake(cFixedScale(width), cFixedScale(84))];
//    }
	 CCPanel *panel=[CCPanel panelWithContent:contentlist viewSize:CGSizeMake(cFixedScale(300), cFixedScale(84))];
    if (iPhoneRuningOnGame()) {
        if (isIphone5()) {
			[panel setPosition:ccp(436/2, 160/2)];
        }else{
           [panel setPosition:ccp(436/2, 160/2)];
        }
    }else{
        [panel setPosition:ccp(150, 160)];
    }
	[self addChild:panel];
	[panel showHorzScrollBar:@"images/ui/common/scroll3.png"];
}

-(void)countItem2425{
	
	NSArray *item=[[GameConfigure shared]getPlayerItemByType:Item_material];
	
	//CCLOG(@"%@",item);
	
	int item24count=0;
	int item25count=0;
	
	for(NSDictionary *data in item){
		if([[data objectForKey:@"iid"]integerValue]==24){
			item24count+=[[data objectForKey:@"count"]integerValue];
		}
		if([[data objectForKey:@"iid"]integerValue]==25){
			item25count+=[[data objectForKey:@"count"]integerValue];
		}
	}
	
	if(label24){
		[label24 removeFromParentAndCleanup:true];
	}
	if(label25)
	{
		[label25 removeFromParentAndCleanup:true];
	}
	float fontSize=14;
	float lineHeight=15;
	float rectHeight=10;
	
	if (iPhoneRuningOnGame()) {
		fontSize=16;
		lineHeight=20;
		rectHeight=20;
	}
	label24=drawString([NSString stringWithFormat:@"x %i",item24count], CGSizeMake(500, rectHeight), getCommonFontName(FONT_1), fontSize, lineHeight, @"ffeb7b");
	label25=drawString([NSString stringWithFormat:@"x %i",item25count], CGSizeMake(500, rectHeight), getCommonFontName(FONT_1), fontSize, lineHeight, @"ffeb7b");
	[label24 setAnchorPoint:ccp(0, 0)];
	[label25 setAnchorPoint:ccp(0, 0)];
	if (iPhoneRuningOnGame()) {
		[label24 setPosition:ccp(30/2.0f, 5/2.0f)];
		[label25 setPosition:ccp(155/2.0f, 5/2.0f)];
	}else{
		[label24 setPosition:ccp(40, 5)];
		[label25 setPosition:ccp(140, 5)];
	}
	[bg_payitem addChild:label24];
	[bg_payitem addChild:label25];
}
-(BOOL)checkIsInLayer:(CCSimpleButton*)b{
    if (b) {
        CCNode* super_node = b.parent.parent.parent;
        CGPoint pos = [b convertToWorldSpace:b.position];
        pos = [super_node convertToNodeSpace:pos];
        if (pos.x>cFixedScale(0) &&
            pos.x<cFixedScale(300) &&
            pos.y>cFixedScale(0) &&
            pos.y<cFixedScale(84)) {
            return YES;
        }
    }
    return NO;
}

#pragma mark 选择坐骑回调
-(void)selectCarCallBack:(CCSimpleButton*)b{
    if (![self checkIsInLayer:b]) {
        return;
    };
	if(carTitleName){
		[carTitleName removeFromParentAndCleanup:true];
	}
	currenSelectCar=[carlist objectAtIndex:b.tag-1];
	NSString *infostr=[currenSelectCar objectForKey:@"info"];
	float fontSize=14;
	float lineHeight=20;
	float rectHeight=20;
	if (iPhoneRuningOnGame()) {
		
		//Kevin added
		infostr = [infostr stringByReplacingOccurrencesOfString:@"#16#" withString:@"#20#"];
		//----------------------------------------/
	}
	CCSprite *info=drawString(infostr, CGSizeMake(200, rectHeight), getCommonFontName(FONT_1), fontSize, lineHeight, @"ffffff");

	int carnameid=[[currenSelectCar objectForKey:@"id"]integerValue];
	carTitleName =[CarNameViewContent create:carnameid];
	[info setAnchorPoint:ccp(0, 0)];
	[carTitleName setAnchorPoint:ccp(0, 0)];
	if (iPhoneRuningOnGame()) {
//        if (isIphone5()) {
//			[carTitleName setPosition:ccp(40/2+44, bg.contentSize.height-150/2)];
//			[info setPosition:ccp(0, -info.contentSize.height/2-carTitleName.contentSize.height-8)];
//        }else{
        [carTitleName setPosition:ccp(80, self.contentSize.height-150/2)];
        [info setPosition:ccp(0, -info.contentSize.height/2-carTitleName.contentSize.height-12)];					//Kevin modified. before height-8
//        }
    }else{
        [carTitleName setPosition:ccp(80, self.contentSize.height-150)];
        [info setPosition:ccp(0, -info.contentSize.height-10)];
    }
//	showNode(info);
	[carTitleName addChild:info];
	[self addChild:carTitleName];
	[self configTwoButton];
	[self showCar];
}

-(void)showCar{
	
	if(cvc){
		[cvc removeFromParentAndCleanup:true];
	}
	
	int carid = [[currenSelectCar objectForKey:@"id"] integerValue];
	
	cvc = [CarViewerContent node];
	[cvc loadTargetCar:carid dir:5 scaleX:1];
	cvc.position = ccp(self.contentSize.width/2, cFixedScale(330)-cFixedScale(cvc.inSkyHigh));
	
	[self addChild:cvc z:9];
	[self showPlayerOnCar:YES];
}


#pragma mark 选者装载，卸载，兑换
-(void)byAndBuyCarCallBack:(CCSimpleButton*)b{
	if(currenSelectCar && b.tag==1){
		int cid=[[currenSelectCar objectForKey:@"id"]integerValue];
		pcid=cid;
		cid=[self getMyCarPackageId:cid];
		NSString *post=[NSString stringWithFormat:@"cid::%i",cid];
		[GameConnection request:@"carDo" format:post target:self call:@selector(didRequest:)];
	}
	if(currenSelectCar && b.tag==2){
		int coin1=[[currenSelectCar objectForKey:@"coin1"]integerValue];
		int coin2=[[currenSelectCar objectForKey:@"coin2"]integerValue];
		int coin3=[[currenSelectCar objectForKey:@"coin3"]integerValue];
		int useid=[[currenSelectCar objectForKey:@"useId"]integerValue];
		int usecout=[[currenSelectCar objectForKey:@"count"]integerValue];
		NSString *paystr=@"";
		if(coin1>0){
			//paystr=[paystr stringByAppendingFormat:@"花费银币:%i ",coin1];
            paystr=[paystr stringByAppendingFormat:NSLocalizedString(@"car_spend_coin1",nil),coin1];
		}
		if(coin2>0){
			//paystr=[paystr stringByAppendingFormat:@"花费元宝:%i ",coin2];
            paystr=[paystr stringByAppendingFormat:NSLocalizedString(@"car_spend_coin2",nil),coin2];
		}
		if(coin3>0){
			//paystr=[paystr stringByAppendingFormat:@"花费绑元宝:%i ",coin3];
            paystr=[paystr stringByAppendingFormat:NSLocalizedString(@"car_spend_coin3",nil),coin3];
		}
		if(usecout>0){
			//paystr=[paystr stringByAppendingFormat:@"花费 %@: %i ",getAllItemName(useid, @"i"),usecout];
            paystr=[paystr stringByAppendingFormat:NSLocalizedString(@"car_spend",nil),getAllItemName(useid, @"i"),usecout];
		}
		//paystr =[NSString stringWithFormat:@"是否确定 %@ 兑换 %@",paystr,[currenSelectCar objectForKey:@"name"]];
        paystr =[NSString stringWithFormat:NSLocalizedString(@"car_change",nil),paystr,[currenSelectCar objectForKey:@"name"]];
		[[AlertManager shared]showMessage:paystr target:self confirm:@selector(makeSureCallBack) canel:nil];
	}
	if(currenSelectCar && b.tag==3){
		[GameConnection request:@"carDo" format:@"cid::0" target:self call:@selector(didRequest:)];
		pcid=0;
	}
}

-(void)makeSureCallBack{
	int cid=[[currenSelectCar objectForKey:@"id"]integerValue];
	NSString *str=[NSString stringWithFormat:@"cid::%i",cid];
	[GameConnection request:@"carExchange" format:str target:self call:@selector(didRequest:)];
}


#pragma mark 网络回调
-(void)didRequest:(NSDictionary*)data{
	if(!checkResponseStatus(data)){
		[ShowItem showErrorAct:getResponseMessage(data)];
	}
	if(checkResponseStatus(data) && [getResponseFunc(data) isEqualToString:@"carExchange"]){
		[[GameConfigure shared]updatePackage:getResponseData(data)];
		[self countItem2425];
		[self configTwoButton];
	}
	if(checkResponseStatus(data) && [getResponseFunc(data) isEqualToString:@"carDo"]){
		if(pcid==0){
			[cvc removeFromParentAndCleanup:true];
			cvc=nil;
			currenSelectCar =nil;
			[self showPlayerOnCar:NO];
			//[ShowItem showItemAct:@"卸下成功"];
            [ShowItem showItemAct:NSLocalizedString(@"car_demount",nil)];
		}else{
			[self showPlayerOnCar:YES];
			//[ShowItem showItemAct:@"乘骑成功"];
            [ShowItem showItemAct:NSLocalizedString(@"car_sit",nil)];
		}
		NSNumber *num=[NSNumber numberWithInt:pcid];
		[[GameConfigure shared]setPlayerCar:num];
		[self configTwoButton];
		[[RoleManager shared].player updateCar:pcid];
	}
}


//-(void)closeCarWindow:(CCSimpleButton*)b{
//	[[Window shared]removeWindow:PANEL_CAR];
//}


#pragma mark 配置按钮状态
-(void)configTwoButton{
	
	[btn_ByCar setPosition:ccp(self.contentSize.width/2, cFixedScale(120))];
	[btn_OutCar setPosition:ccp(self.contentSize.width/2, cFixedScale(120))];
	[btn_BuyCar setPosition:ccp(self.contentSize.width/2, cFixedScale(120))];
	
	int cid=[[currenSelectCar objectForKey:@"id"]integerValue];
	int onTheCar=-1;
	bool isHasCar=NO;
	bool isExchange=NO;
	
	isHasCar=[self getMyCarPackageId:cid]==-1?NO:YES;
	onTheCar=[Car getMyPackageCarId];
	if([[currenSelectCar objectForKey:@"isExchange"]integerValue]==0){
		isExchange=NO;
	}else{
		isExchange=YES;
	}
	
	if(isHasCar && onTheCar!=cid){
		btn_ByCar.visible=YES;
		btn_OutCar.visible=NO;
		btn_BuyCar.visible=NO;
		[btn_ByCar setInvalid:NO];
		[btn_BuyCar setInvalid:YES];
	}
	
	if(isHasCar&& onTheCar==cid){
		btn_ByCar.visible=NO;
		btn_OutCar.visible=YES;
		[btn_BuyCar setInvalid:YES];
	}
	
	if(!isHasCar){
		btn_ByCar.visible=NO;
		[btn_ByCar setInvalid:YES];
		btn_OutCar.visible=NO;
		[btn_BuyCar setInvalid:NO];
		btn_BuyCar.visible=YES;
	}
	
	if(!isExchange){
		[btn_BuyCar setInvalid:YES];
	}
	
}


+(int)getMyPackageCarId{
	int ppcid=[[[[GameConfigure shared]getPlayerInfo]objectForKey:@"car"]integerValue];
	
	if(ppcid>0){
		return  ppcid;
	}
	return  -1;
	
}

-(int)getMyCarPackageId:(int)cid{
	NSArray *mycarlist=[[GameConfigure shared]getPlayerCarList];
	for(NSDictionary *dict in mycarlist){
		if([[dict objectForKey:@"cid"]integerValue]==cid){
			return [[dict objectForKey:@"id"]integerValue];
		}
	}
	return  -1;
}

-(void)dealloc{
	if(carlist)[carlist release];
	[super dealloc];
}

-(void)onExit
{
	[GameConnection freeRequest:self];
	
	[super onExit];
}

@end
