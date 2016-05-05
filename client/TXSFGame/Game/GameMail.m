//
//  GameMail.m
//  TXSFGame
//
//  Created by TigerLeung on 13-1-6.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "GameMail.h"
#import "GameConfigure.h"
#import "GameConnection.h"
#import "GameUI.h"
#import "Config.h"
#import "CCSimpleButton.h"
#import "MailList.h"
#import "AlertManager.h"
#import "RewardPanel.h"
#import "CJSONDeserializer.h"
#import "GameUI.h"
#import "GameConfigure.h"
#import "RoleManager.h"
#import "RolePlayer.h"

@implementation GameMail
@synthesize mails;
@synthesize targetList;

static GameMail * gameMail;

-(void)dealloc{
	
	[NSTimer cancelPreviousPerformRequestsWithTarget:self];
	
	if(mails){
		[mails release];
		mails = nil;
	}
	if(removes){
		[removes release];
		removes = nil;
	}
	if(inRemove){
		[inRemove release];
		inRemove = nil;
	}
	[super dealloc];
	CCLOG(@"GameMail dealloc");
}

-(id)init{
	if(self=[super init]){
		mails = [[NSMutableArray alloc] init];
		removes = [[NSMutableArray alloc] init];
	}
	return self;
}

+(GameMail*)shared{
	if(!gameMail){
		gameMail = [[GameMail alloc] init];
	}
	return gameMail;
}
+(void)stopAll{
	if(gameMail){
		[GameConnection removePostTarget:gameMail];
		[gameMail release];
		gameMail = nil;
	}
}

#pragma mark -

-(int)count{
	return [mails count];
}
-(int)getCountByType:(Mail_type)type{
	int count = 0;
	for(NSDictionary * mail in mails){
		if([[mail objectForKey:@"t"] intValue]==type){
			count += 1;
		}
	}
	return count;
}

-(NSDictionary*)checkRewardTypeByFight{
	NSArray * ms = [self getMailsByType:Mail_type_reward];
	for(NSDictionary * m in ms){
		int t_type = [[m objectForKey:@"content"] intValue];
		if(t_type==1 ||
		   t_type==2 ||
		   t_type==4 ||
		   t_type==6 ){
			return m;
		}
	}
	return nil;
}
-(NSDictionary*)checkRewardTypeByReward{
	NSArray * ms = [self getMailsByType:Mail_type_reward];
	for(NSDictionary * m in ms){
		int t_type = [[m objectForKey:@"content"] intValue];
		if(t_type==3 ||
		   t_type==5 ||
		   t_type==7 ||
		   t_type==8 ||
		   t_type==10 ||
		   t_type==11 ||
		   t_type==12 ||
		   t_type==14 ||
		   t_type==15 ||
		   t_type==16 ){
			return m;
		}
	}
	return nil;
}

-(NSDictionary*)getMailByIndex:(int)index{
	if(index<[mails count]){
		return [mails objectAtIndex:index];
	}
	return nil;
}
-(NSDictionary*)getMailByIndex:(int)index type:(Mail_type)type{
	NSArray * ms = [self getMailsByType:type];
	if(index<[ms count]){
		return [ms objectAtIndex:index];
	}
	return nil;
}
-(NSDictionary*)getMailById:(int)mid{
	for(NSDictionary * mail in mails){
		if([[mail objectForKey:@"id"] intValue]==mid){
			return mail;
		}
	}
	return nil;
}

-(NSArray*)getMailsByType:(Mail_type)type{
	NSMutableArray * result = [NSMutableArray array];
	for(NSDictionary * mail in mails){
		if([[mail objectForKey:@"t"] intValue]==type){
			[result addObject:mail];
		}
	}
	return result;
}

-(void)removeMailById:(int)mid{
	
	NSDictionary * mail = [self getMailById:mid];
	if(mail){
		
		[removes removeAllObjects];
		[removes addObject:mail];
		
		[mails removeObject:mail];
		
		int mid = [[mail objectForKey:@"id"] intValue];
		if(targetList){
			[targetList removeMailAction:mid];
		}
		[self updateUI];
		
		[self checkRemoveMail];
//		[NSTimer scheduledTimerWithTimeInterval:0.1f 
//										 target:self 
//									   selector:@selector(checkRemoveMail) 
//									   userInfo:nil 
//										repeats:NO];
	}
}

-(void)removeAllMailByType:(Mail_type)type{
	NSArray * result = [self getMailsByType:type];
	for(NSDictionary * mail in result){
		int mid = [[mail objectForKey:@"id"] intValue];
		[targetList removeMailAction:mid];
		[mails removeObject:mail];
	}
	
	[self updateUI];
	
	[removes removeAllObjects];
	[removes addObjectsFromArray:result];
	
	[self checkRemoveMail];
}

-(void)checkRemoveMail{
	
	if(inRemove) return;
	if([removes count]==0) return;
	
	inRemove = [removes objectAtIndex:0];
	[inRemove retain];
	
	[removes removeObjectAtIndex:0];
	
	[self doRemoveMailById];
	
}

-(void)doRemoveMailById{
    
    [[GameConfigure shared] markPlayerProperty];
    
	int mid = [[inRemove objectForKey:@"id"] intValue];
	NSString * fm = [NSString stringWithFormat:@"id::%d",mid];
	[GameConnection request:@"mailReceive" format:fm target:self call:@selector(didMailReceive:)];
	
}
-(void)didMailReceive:(NSDictionary*)response{
	
	if(checkResponseStatus(response)){
		
		NSDictionary * data = getResponseData(response);
		if(data){
			
			NSArray *updateData = [[GameConfigure shared] getPackageAddData:data];
			[[AlertManager shared] showReceiveItemWithArray:updateData];
			
			[[GameConfigure shared] updatePackage:data];
			/*
            //fix chao
            RolePlayer *player = [RoleManager shared].player;
            if (player) {
                NSDictionary *playerAlly=[[GameConfigure shared]getPlayerAlly];
                player.allyName=[playerAlly objectForKey:@"n"];
                [player updateViewer];
            }
            //end
			 */
		}
		
	}else{
		
		CCLOG(@"Error");
		
//        [[AlertManager shared] showMessage:NSLocalizedString(@"mail_get_error",nil)
//									target:nil
//								   confirm:nil
//									 canel:nil];
		[ShowItem showErrorAct:getResponseMessage(response)];
		
		//cancel remove mails
		if(inRemove){
			[mails addObject:inRemove];
			[inRemove release];
			inRemove = nil;
		}
		[mails addObjectsFromArray:removes];
		
		[self updateUI];
		
		[[RewardPanel shared] showList];
		
		return;
	}
	
	if(inRemove){
		[inRemove release];
		inRemove = nil;
	}
	
	[self checkRemoveMail];
	
}

-(void)start{
	
	[GameConnection addPost:ConnPost_MailPush target:self call:@selector(onPushMails:)];
	
	NSArray * ary = [[GameConfigure shared] getPlayerMails];
	if(!ary){
		[GameConnection request:@"mail" format:@"" target:self call:@selector(didLoadMails:)];
	}else{
		[self receiveMails:ary];
	}
	
}
-(void)didLoadMails:(NSDictionary*)response{
	if(checkResponseStatus(response)){
		[self receiveMails:getResponseData(response)];
	}
}

-(void)receiveMails:(NSArray*)array{
	if (array == nil) {
		return;
	}
	
	NSArray *waits = [[GameConfigure shared] getPlayerWaitItemListByType:PlayerWaitItemType_4];
	NSArray *formatMails = [self formatMail:array waitArray:waits];
	
	[mails addObjectsFromArray:formatMails];
	
	[self updateUI];
	
}

-(void)onPushMails:(NSNotification*)notification{
	
	NSDictionary * object = notification.object;
	
	NSArray *waitArray = nil;
	if([object objectForKey:@"wait"]){
		CCLOG(@"get wait");
		waitArray = [object objectForKey:@"wait"];
	}
	
	NSMutableArray *mailArray = [NSMutableArray arrayWithArray:[object objectForKey:@"mail"]];
	if (mailArray) {
		NSArray *formatMails = [self formatMail:mailArray waitArray:waitArray];
		[mails addObjectsFromArray:formatMails];
	}
	
	[self updateUI];
	
}

// 邮件内容添加奖品信息
-(NSArray *)formatMail:(NSArray *)mailArray waitArray:(NSArray *)waitArray
{
	if (mailArray == nil && mailArray.count == 0) {
		return nil;
	}
	
	NSMutableArray *_mailArray = [NSMutableArray array];
	
	for (NSMutableDictionary *mail in mailArray) {
		
		//TODO
		int type = [[mail objectForKey:@"t"] intValue];
		if(type==Mail_type_fight){
			continue;
		}
		
		
		NSMutableDictionary *finalyMail = [NSMutableDictionary dictionaryWithDictionary:mail];
		
		int wid = [[mail objectForKey:@"wid"] intValue];
		
		NSArray *items = nil;
		for (NSDictionary *wait in waitArray) {
			int _id = [[wait objectForKey:@"id"] intValue];
			if (_id == wid) {
				NSString* str = [wait objectForKey:@"items"];
				NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
				CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];
				items = [deserializer deserializeAsArray:data error:nil];
				break;
			}
		}
		
		if (items) {
			// 包括物品，装备，命格，坐骑，配将
			NSMutableArray *itemInfos = [NSMutableArray array];
			for (NSDictionary *item in items) {
				int iid = [[item objectForKey:@"i"] intValue];
				int count = [[item objectForKey:@"c"] intValue];
				NSString *type = [item objectForKey:@"t"];
				
				NSDictionary *itemInfo = nil;
				BOOL isEquip = NO;
				
				// 物品
				if ([type isEqualToString:@"i"]) {
					// 打坐经验转为经验显示
					int _iid = iid;
					if (iid == 5) {
						_iid = 4;
						
						int level = [[GameConfigure shared] getPlayerLevel];
						NSDictionary* levelInfo = [[GameDB shared] getRoleExpInfo:level];
						int siteExp = [[levelInfo objectForKey:@"siteExp"] intValue];
						count *= siteExp;
					}
					itemInfo = [[GameDB shared] getItemInfo:_iid];
				}
				// 装备
				else if ([type isEqualToString:@"e"]) {
					itemInfo = [[GameDB shared] getEquipmentInfo:iid];
					isEquip = YES;
				}
				// 命格
				else if ([type isEqualToString:@"f"]) {
					itemInfo = [[GameDB shared] getFateInfo:iid];
				}
				// 坐骑
				else if ([type isEqualToString:@"c"]) {
					itemInfo = [[GameDB shared] getCarInfo:iid];
				}
				// 配将
				else if ([type isEqualToString:@"r"]) {
					itemInfo = [[GameDB shared] getRoleInfo:iid];
				}
				
				if (itemInfo) {
					NSString *name = [itemInfo objectForKey:@"name"];
					ItemQuality quality = IQ_WHITE;
					if (isEquip) {
						// 读套装表品质
						int sid = [[itemInfo objectForKey:@"sid"] intValue];
						NSDictionary *eqSet = [[GameDB shared] getEquipmentSetInfo:sid];
						if (eqSet) {
							quality = [[eqSet objectForKey:@"quality"] intValue];
						}
					} else {
						quality = [[itemInfo objectForKey:@"quality"] intValue];
					}
					
					NSString *colorStr = getHexColorByQuality(quality);
					[itemInfos addObject:[NSString stringWithFormat:@"|%@x%d%@|", name, count, colorStr]];
				}
			}
			if (itemInfos.count > 0) {
				NSString *allInfo = [itemInfos componentsJoinedByString:@" "];
				
				// 改变mail内容
				NSString *param = [NSString stringWithFormat:@"%@%@", [mail objectForKey:@"param"], allInfo];
				
				[finalyMail setObject:param forKey:@"param"];
			}
		}
		
		[_mailArray addObject:finalyMail];
	}
	
	return _mailArray;
}

-(void)updateUI{
	if(targetList){
		[targetList showMailList];
	}
	if([GameUI isHasGameUI]){
		[[GameUI shared] updateMailCount];
	}
}

@end
