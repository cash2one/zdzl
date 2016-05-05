//
//  FightGroup.m
//  TXSFGame
//
//  Created by TigerLeung on 12-12-3.
//  Copyright (c) 2012年 eGame. All rights reserved.
//

#import "FightGroup.h"
#import "Config.h"
#import "FightPlayer.h"
#import "FightCharacter.h"
#import "GameConfigure.h"
#import "FightAnimation.h"
#import "CCLabelFX.h"
#import "CCSimpleButton.h"
#import "CJSONDeserializer.h"
#import "StretchingImg.h"

#import "TaskIconViewerContent.h"
#import "MonsterIconViewerContent.h"


#define START_LEVEL					50

@implementation FightGroup

@synthesize groupId;
@synthesize playerId;
@synthesize player;
@synthesize targetGroup;

@synthesize isCurrentUser;

-(void)dealloc{
	
	CCLOG(@"FightGroup dealloc");
	
	if(groups){
		for(FightCharacter * c in groups){
			[c removeFromParentAndCleanup:YES];
		}
		[groups release];
		groups = nil;
	}
	if(buffs){
		[buffs release];
		buffs = nil;
	}
	if(playerIds){
		[playerIds release];
		playerIds = nil;
	}
	[super dealloc];
}

-(BOOL)checkPlayerInGroup{
	int localPlayerId = [GameConfigure shared].playerId;
	return [self checkPlayerInGroup:localPlayerId];
}

-(BOOL)checkPlayerInGroup:(int)pid{
	if(playerId==pid) return YES;
	for(NSString * tid in playerIds){
		if([tid intValue]==pid){
			return YES;
		}
	}
	return NO;
}

-(BOOL)isCurrentUser{
	
	//两队不在同一个队伍里面,按gid返回
	if(![self checkPlayerInGroup] && ![targetGroup checkPlayerInGroup]){
		if(groupId==0){
			return NO;
		}
		return YES;
	}
	
	if([self checkPlayerInGroup]){
		return YES;
	}
	if([targetGroup checkPlayerInGroup]){
		return NO;
	}
	
	if(groupId==0){
		return YES;
	}
	if(groupId==1){
		return NO;
	}
	
	return NO;
}

#pragma mark-

-(void)setGroupInfo:(NSString*)info{
	NSArray * ary = [info componentsSeparatedByString:@"="];
	if([ary count]>=2){
		
		[self loadIndex:[ary objectAtIndex:0] buffs:[ary objectAtIndex:2]];
		//[self loadTeam:[ary objectAtIndex:1]];
		
	}
}
-(void)setGroupTeam:(NSString*)info{
	NSArray * ary = [info componentsSeparatedByString:@"="];
	
	[self showTeamIcon:[ary objectAtIndex:0] buffs:[ary objectAtIndex:2]];
	[self loadTeam:[ary objectAtIndex:1]];
}

-(void)loadIndex:(NSString*)str buffs:(NSString*)buffString{
	
	groupId = [valueFromSort(str,0) intValue];
	playerId = [valueFromSort(str,1) intValue];
	
	playerIds = [valueFromSort(str,5) componentsSeparatedByString:@"|"];
	[playerIds retain];
	
}

-(void)showTeamIcon:(NSString*)str buffs:(NSString*)buffString{
	if(player){
		
		int level = [valueFromSort(str,2) intValue];
		Fight_team_icon_type iconType = [valueFromSort(str,3) intValue];
		int iconId = [valueFromSort(str,4) intValue];
		
		CCSprite * team = [CCSprite node];
		team.anchorPoint = ccp(0.5,0);
		
		CCSprite * levelBar = [CCSprite spriteWithFile:@"images/ui/button/bt_levelbar.png"];
		[team addChild:levelBar z:1];
		
		CCLabelTTF * label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Lv%d",level] 
												fontName:getCommonFontName(FONT_1) 
												fontSize:14];
		label.anchorPoint = ccp(0.5,0.5);
		label.color = ccBLACK;
		[team addChild:label z:2];
		if(iPhoneRuningOnGame()){
			label.scale = 0.5f;
		}
		
		//世界BOSS的时候改变一下，显示转数
		if (groupId == 0) {//上面的
			if ([FightManager getFightType] == Fight_Type_bossFight) {
				//世界BOSS
				int _temp = level - START_LEVEL ;
				//NSString* _des = [NSString stringWithFormat:@"%d 转",_temp];
                NSString* _des = [NSString stringWithFormat:NSLocalizedString(@"fight_metempsychosis",nil),_temp];
				label.string = _des;
			}
		}
		
		CCSprite* background = [CCSprite spriteWithFile:@"images/ui/characterIcon/big.png"];
		background.anchorPoint = ccp(0.5,0.0);
		[team addChild:background];
		
		CCSprite * icon = nil;
		//NSString * iconPath = nil;
		if(iconType==Fight_team_icon_type_role){
			icon = getCharacterIcon(iconId, ICON_PLAYER_BIG);
		}else if(iconType==Fight_team_icon_type_npc){
			icon = [TaskIconViewerContent create:[NSString stringWithFormat:@"%d",iconId]];
		}else if(iconType==Fight_team_icon_type_momster){
			icon = [MonsterIconViewerContent create:iconId];
		}
		
		if(icon){
			icon.anchorPoint = ccp(0.5,0.0);
			icon.position = ccp(background.contentSize.width/2,0);
			
			if(iconType == Fight_team_icon_type_role){
				if ([self isCurrentUser]) {
					icon.position = ccp(background.contentSize.width,0);
				}else{
					icon.position = ccp(0,0);
				}
			}
			
			[background addChild:icon];
		}
		
		NSData * data = [buffString dataUsingEncoding:NSUTF8StringEncoding];
		CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];	
		buffs = [deserializer deserializeAsArray:data error:nil];
		if(buffs){
			
			[buffs retain];
			int count = 0;
			
			for(int i=0;i<[buffs count];i++){
				NSDictionary * buff = [buffs objectAtIndex:i];
				Fight_Buff_Type type = [[buff objectForKey:@"type"] intValue];
				
				CCSimpleButton * btn = nil;
				if(type==Fight_Buff_Type_abyss){
					if([self isCurrentUser]){
						btn = [CCSimpleButton spriteWithFile:@"images/fight/buff_icon/3.png"];
					}
					count++;
				}
				if(type==Fight_Buff_Type_worldBoss){
					if([self isCurrentUser]){
						btn = [CCSimpleButton spriteWithFile:@"images/fight/buff_icon/3.png"];
					}
					count++;
				}
				if(type==Fight_Buff_Type_foot){
					btn = [CCSimpleButton spriteWithFile:@"images/fight/buff_icon/2.png"];
					count++;
				}
				if(btn){
					btn.target = self;
					btn.call = @selector(doShowBuff:);
					if([self isCurrentUser]){
						if(iPhoneRuningOnGame()){
							btn.position = ccp(-(25*count+20),7);
						}else{
							btn.position = ccp(-(50*count+40),15);
						}
					}else{
						if(iPhoneRuningOnGame()){
							btn.position = ccp(25*count+20,50);
						}else{
							btn.position = ccp(50*count+40,100);
						}
					}
					[team addChild:btn z:3 tag:i];
				}
				
			}
		}
		
		if(![self isCurrentUser]){
			icon.scaleX = -1;
		}
		
		isShowHeadIcon = YES;
		team.position = [self getIconPosition];
        //fix chao 回放时 先删旧的
        [player removeChildByTag:groupId+9000 cleanup:YES];
        //end
		[player addChild:team z:INT32_MAX-2 tag:groupId+9000];
		
	}
}

-(CGPoint)getIconPosition{
	CGPoint position = CGPointZero;
	CGSize winSize = [[CCDirector sharedDirector] winSize];
	if([self isCurrentUser]){
		position = ccp(winSize.width-cFixedScale(70),cFixedScale(15));
	}else{
		position = ccp(cFixedScale(70),winSize.height-cFixedScale(130));
	}
	return position;
}

-(void)doShowBuff:(CCNode*)node{
	NSDictionary * buff = [buffs objectAtIndex:node.tag];
	[self showBuff:[buff objectForKey:@"d"] index:node.tag];
}

-(void)hideBuff{
	int tag = 19000+groupId;
	CCNode * node = [player getChildByTag:tag];
	if(node){
		[node removeFromParentAndCleanup:YES];
	}
}

-(void)showBuff:(NSDictionary*)buff index:(int)index{
	
	int tag = 19000+groupId;
	CCNode * node = [player getChildByTag:tag];
	if(node){
		[node removeFromParentAndCleanup:YES];
		if(selectIndex==index){
			return;
		}
	}
	
	if([buff allKeys]>0){
		
		selectIndex = index;
		
		int fontSize = 16;
		int fontHeight = 20;
		
		int count = 0;
		CCSprite * content = [CCSprite node];
		//fix chao
//		CCLabelTTF * label = [CCLabelTTF labelWithString:@"遇强越强"
//												fontName:getCommonFontName(FONT_1)
//												fontSize:fontSize];
        CCLabelTTF * label = [CCLabelTTF labelWithString:NSLocalizedString(@"fight_strong",nil)
												fontName:getCommonFontName(FONT_1)
												fontSize:fontSize];
		label.anchorPoint = ccp(0.0,0.0);
		label.color = ccWHITE;
		label.position = ccp(0,-count*fontHeight);
		[content addChild:label];
		count++;
		//end
		for(NSString * key in buff){
			NSString * t = getPropertyName(key);
			if(t){
				int c = [[buff objectForKey:key] intValue];
				CCLabelTTF * label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@ :",t] 
														fontName:getCommonFontName(FONT_1) 
														fontSize:fontSize];
				label.anchorPoint = ccp(0.0,0.0);
				label.color = ccWHITE;
				label.position = ccp(0,-count*fontHeight);
				[content addChild:label];
				
				CCLabelTTF * valueLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"+%d",c]
															 fontName:getCommonFontName(FONT_1)
															 fontSize:fontSize];
				valueLabel.anchorPoint = ccp(0, 0);
				valueLabel.color = ccc3(0, 255, 0);
				valueLabel.position = ccp(label.position.x + label.contentSize.width + 5,
										  label.position.y);
				[content addChild:valueLabel];
				
				count++;
			}
		}
		for(NSString * key in buff){
			NSString * t = getPropertyName(fixBaseAttributeKey(key));
			if(t){
				int c = [[buff objectForKey:key] intValue];
				CCLabelTTF * label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%@ :",t] 
														fontName:getCommonFontName(FONT_1) 
														fontSize:fontSize];
				label.anchorPoint = ccp(0.0,0.0);
				label.color = ccWHITE;
				label.position = ccp(0,-count*fontHeight);
				[content addChild:label];
				
				CCLabelTTF * valueLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"+%d%@",c,@"%"]
															 fontName:getCommonFontName(FONT_1)
															 fontSize:fontSize];
				valueLabel.anchorPoint = ccp(0, 0);
				valueLabel.color = ccc3(0, 255, 0);
				valueLabel.position = ccp(label.position.x + label.contentSize.width + 5,
										  label.position.y);
				[content addChild:valueLabel];
				
				count++;
			}
		}

		if (iPhoneRuningOnGame()) {
			content.position = ccp(12/2.0f,(count*fontHeight-8)/2.0f);
		}else{
			content.position = ccp(12,count*fontHeight-8);
		}
		CCSprite * background =nil;
		
		if (iPhoneRuningOnGame()) {
			content.scale=0.5f;
			background = [StretchingImg stretchingImg:@"images/ui/bound.png"
												width:170/2.0f
											   height:(count*fontHeight+16+8)/2.0f
												 capx:8/2.0f capy:8/2.0f];
		}else{
			background = [StretchingImg stretchingImg:@"images/ui/bound.png"
												width:170
											   height:count*fontHeight+16+8
												 capx:8 capy:8];
		}
		[background addChild:content];
		
		CGSize winSize = [[CCDirector sharedDirector] winSize];
		if([self isCurrentUser]){
			background.anchorPoint = ccp(0.5,0);
            background.position = ccp(winSize.width-cFixedScale(200),cFixedScale(100));
        }else{
			background.anchorPoint = ccp(0.5,1);
			background.position = ccp(cFixedScale(200),winSize.height-cFixedScale(100));
		}
		[player addChild:background z:INT32_MAX-1 tag:tag];
		
	}
}


-(void)loadTeam:(NSString*)str{
	
	groups = [[NSMutableArray alloc] init];
	
	NSArray * ary = [str componentsSeparatedByString:@"|"];
	for(NSString * v in ary){
		FightCharacter * character = [FightCharacter node];
		[groups addObject:character];
		[player addChild:character];
		
		character.group = self;
		[character show:v];
		
	}
}

-(FightCharacter*)getCharacterByIndex:(int)i{
	for(FightCharacter * character in groups){
		if(character.index==i){
			return character;
		}
	}
	return nil;
}
//fix chao
-(void)hideInfo{
    for(FightCharacter * character in groups){
        if (character) {
            [character hideInfo];
        }
	}
}
//end
-(void)showEffect:(int)eid offset:(int)offset{
	
	CGPoint p_min = ccp(10000,10000);
	CGPoint p_max = ccp(-1000,-1000);
	for(FightCharacter * c in groups){
		if(c.position.x<p_min.x) p_min.x = c.position.x;
		if(c.position.y<p_min.y) p_min.y = c.position.y;
		if(c.position.x>p_max.x) p_max.x = c.position.x;
		if(c.position.y>p_max.y) p_max.y = c.position.y;
	}
	
	CGPoint center = ccp(p_min.x+(p_max.x-p_min.x)/2,p_min.y+(p_max.y-p_min.y)/2);
	if(offset==0){
		center = ccpAdd(center, ccp(0,-50));
	}else{
		center = ccpAdd(center, ccp(0,-offset));
	}
	
	NSString * uPath = [NSString stringWithFormat:@"images/fight/eff/effects/%d/u/%@",eid,@"%d.png"];
	
	FightAnimation * u = [FightAnimation node];
	u.anchorPoint = ccp(0.5,0.0);
	u.position = center;
	[u showEffect:uPath];
	[player addChild:u z:(GAME_MAP_MAX_Y-center.y)];
	
	NSString * dPath = [NSString stringWithFormat:@"images/fight/eff/effects/%d/d/%@",eid,@"%d.png"];
	
	FightAnimation * d = [FightAnimation node];
	d.anchorPoint = ccp(0.5,0.5);
	d.position = center;
	[d showEffect:dPath];
	[player addChild:d z:-1];
	
	[player actionFight];
}

-(int)getLiveCount{
	int count = 0;
	for(FightCharacter * c in groups){
		if(!c.isDie){
			count+=1;
		}
	}
	
	return count;
}

-(void)openHeadIcon{
	if(isShowHeadIcon==NO){
		CCNode * node = [player getChildByTag:groupId+9000];
		if(node){
			node.visible = YES;
			[node stopAllActions];
			CGPoint point = [self getIconPosition];
			id move = [CCMoveTo actionWithDuration:0.5f position:point];
			[node runAction:move];
		}
	}
	isShowHeadIcon = YES;
}
-(void)closeHeadIcon{
	if(isShowHeadIcon==YES){
		[self hideBuff];
		CCNode * node = [player getChildByTag:groupId+9000];
		if(node){
			[node stopAllActions];
			CGPoint point = [self getIconPosition];
			if([self isCurrentUser]){
				point = ccpAdd(point, ccp(cFixedScale(200),cFixedScale(-200)));
			}else{
				point = ccpAdd(point, ccp(cFixedScale(-200),cFixedScale(200)));
			}
			id move = [CCMoveTo actionWithDuration:0.5f position:point];
			id hide = [CCCallBlock actionWithBlock:^{
				node.visible = NO;
			}];
			[node runAction:[CCSequence actions:move, hide, nil]];
		}
	}
	isShowHeadIcon = NO;
}

-(void)updateSpeed{
	for(FightCharacter * character in groups){
		[character updateSpeed];
	}
}

@end
