//
//  ConfigTeamBase.m
//  TXSFGame
//
//  Created by Max on 13-5-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "ConfigTeamBase.h"
#import "AnimationMonster.h"
#import "CCSimpleButton.h"
#import "GameConfigure.h"

@implementation ConfigTeamBase

@synthesize mid;
@synthesize rewardid;
@synthesize fightid;
@synthesize colId;
@synthesize upRoleDataFun;


-(void)onEnter{
	[super onEnter];
	
	roleAr=[[NSMutableDictionary alloc]init];
	roleArMe=[[NSMutableDictionary alloc]init];
	NSString *onRstr=[NSString stringWithFormat:NSLocalizedString(@"union_par_teamcount", nil),0];
	onRLabel=[CCLabelTTF labelWithString:onRstr fontName:getCommonFontName(FONT_1) fontSize:iPhoneRuningOnGame()?10:18];
	
	if (iPhoneRuningOnGame()) {
		[onRLabel setPosition:ccp(960/2.0f-40,[CCDirector sharedDirector].winSize.height-35)];
	}else{
		[onRLabel setPosition:ccp(960, 680)];
	}
	[self addChild:onRLabel z:1];
	
	[self creatRoleList];
}



-(void)onExit{
	[super onExit];
	[roleAr release];
}


#pragma mark 创建阵标识(圆圈)
-(void)creatArrangment:(int[3])n{
	
	int srcx=cFixedScale(400);
	int srcy=cFixedScale(250);
	if (iPhoneRuningOnGame()) {
		srcx=280/2.0f;
	}
	for (int i=0; i<9;i++ ) {
		CCSprite *role_ar_bg=nil;
		bool colb=NO;
		
		for(int j=0;j<3;j++){
			if(i==n[j]){
				colb=YES;
			}
		}
		if(colb){
			role_ar_bg=[CCSprite spriteWithFile:@"images/ui/panel/phalanx22.png"];
		}else{
			role_ar_bg=[CCSprite spriteWithFile:@"images/ui/panel/phalanx11.png"];
		}
		
		if(i%3==0){
			srcx+=cFixedScale(100);
			srcy-=cFixedScale(70);
		}
		[role_ar_bg setPosition:ccp(srcx+i%3*cFixedScale(110), srcy+i%3*cFixedScale(60))];
		[self addChild:role_ar_bg z:1 tag:ROLEARBASE+i];
	}
	
}


#pragma mark 创建角色列表
-(void)creatRoleList{
	
	roleList = [CCNode node];
	[self addChild:roleList z:101];
	
	NSArray *roles = [[GameConfigure shared] getPlayerRoleList];
	int i=0;
	CGSize winSize=[CCDirector sharedDirector].winSize;
	for (NSDictionary *roledata in roles) {
		if([[roledata objectForKey:@"status"] intValue]==1){
			CCSprite *characterIconBg = [CCSprite spriteWithFile:@"images/ui/panel/phalanx_character_bg.png"];
			int rid=[[roledata objectForKey:@"rid"]integerValue];
			CCSprite *characterface=getCharacterIcon(rid, ICON_PLAYER_NORMAL);
			[characterIconBg setUserObject:[roledata objectForKey:@"rid"]];
			[characterface setPosition:ccp(characterIconBg.contentSize.width/2, characterIconBg.contentSize.height/2)];
			if (iPhoneRuningOnGame()) {
				characterIconBg.scale=0.92f;
				characterface.scale=0.92f;
				[characterIconBg setPosition:ccp(960/2.0f-characterface.contentSize.width/2-5, winSize.height-65-i*34)];
			}else{
				[characterIconBg setPosition:ccp(970, 600-i*80)];
			}
			[characterIconBg addChild:characterface];
			
			//[self addChild:characterIconBg z:101 tag:CHARACTERARBASE+i];
			[roleList addChild:characterIconBg z:101 tag:CHARACTERARBASE+i];
			
			i++;
		}
	}
}

-(void)showRoleList{
	//[roleList setVisible:YES];
	[roleList stopAllActions];
	[roleList runAction:[CCMoveTo actionWithDuration:0.25f position:ccp(0,0)]];
}
-(void)hideRoleList{
	//[roleList setVisible:NO];
	[roleList stopAllActions];
	[roleList runAction:[CCMoveTo actionWithDuration:0.25f position:ccp(cFixedScale(200),0)]];
}


#pragma mark 设定阵型数据
-(void)setRoleAndMeValue:(id)value keyname:(NSString*)key{
	[roleArMe setValue:value forKey:key];
	[roleAr setValue:value forKey:key];
	
	for(int i=0;i<10;i++){
		CCSprite *characterIconBg=(CCSprite*)[roleList getChildByTag:CHARACTERARBASE+i];
		[characterIconBg removeChildByTag:1000 cleanup:true];
		
	}
	int onRcount=0;
	for(NSString *key in roleArMe.allKeys){
		for (int i=0; i<10; i++) {
			CCSprite *characterIconBg=(CCSprite*)[roleList getChildByTag:CHARACTERARBASE+i];
			int rid=[characterIconBg.userObject intValue];
			if(rid==[[roleArMe objectForKey:key] intValue]){
				CCSprite *infight=[CCSprite spriteWithFile:@"images/ui/common/fight.png"];
				[infight setPosition:ccp(characterIconBg.contentSize.width-infight.contentSize.width/2, characterIconBg.contentSize.height-infight.contentSize.height/2)];
				
				[characterIconBg addChild:infight z:1 tag:1000];
				onRcount++;
			}
		}
	}
	NSString *onRstr=[NSString stringWithFormat:NSLocalizedString(@"union_par_teamcount", nil),onRcount];
	[onRLabel setString:onRstr];
}



#pragma mark 拖动布阵处理
-(BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event{
	if(isTouched){
		return NO;
	}
	CGPoint point=getGLpoint(touch);
	
	for(int i=0;i<10;i++){
		CCSprite *sprite=(CCSprite*)[roleList getChildByTag:CHARACTERARBASE+i];
		
		CGRect rect=CGRectMake(sprite.position.x- sprite.contentSize.width/2, sprite.position.y-sprite.contentSize.height/2, sprite.contentSize.width, sprite.contentSize.height);

		if(CGRectContainsPoint(rect, point)){
			CCLOG(@"%@",sprite.userObject);
			RoleViewerContent *rvc=[RoleViewerContent node];
			int rid=[sprite.userObject intValue];
			rvc.dir=2;
			[rvc loadTargetRole:rid];
			[rvc setPosition:point];
			currenDropObj=rvc;
			[currenDropObj setUserObject:sprite.userObject];
			[self addChild:rvc z:102];
			isTouched=true;
			
			[self hideRoleList];
			
			return YES;
		}
		CCSprite *spriteAr=(CCSprite*)[self getChildByTag:ROLEARBASE+i];
		CGRect rectAr=CGRectMake(spriteAr.position.x- spriteAr.contentSize.width/2, spriteAr.position.y-spriteAr.contentSize.height/2, spriteAr.contentSize.width, spriteAr.contentSize.height);
        //
        if(![self checkOnCol:i]){
            continue;
        }
        //
		if(CGRectContainsPoint(rectAr,point)){
			
			int rid=[[roleArMe valueForKey:[NSString stringWithFormat:@"%i",i]] intValue];
            //
            if (rid == 0) {
                continue;
            }
            //
			roleArId=i;
			RoleViewerContent *rvc=[RoleViewerContent node];
			rvc.dir=2;
			[rvc loadTargetRole:rid];
			[rvc setPosition:point];
			currenDropObj=rvc;
			[currenDropObj setUserObject:[roleArMe valueForKey:[NSString stringWithFormat:@"%i",i]]];
			[self addChild:rvc z:102];
			isTouched=true;
			
			[self hideRoleList];
			
			return YES;
		}
	}
	return NO;
}

-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	if(currenDropObj){
		[currenDropObj setPosition:getGLpoint(touch)];
		for(int i=0;i<10;i++){
			CCSprite *sprite=(CCSprite*)[self getChildByTag:ROLEARBASE+i];
			[sprite removeAllChildrenWithCleanup:true];
			CGRect rect=CGRectMake(sprite.position.x- sprite.contentSize.width/2, sprite.position.y-sprite.contentSize.height/2, sprite.contentSize.width, sprite.contentSize.height);
			if([self checkOnCol:i]){
				if(CGRectContainsPoint(rect, currenDropObj.position)){
					CCSprite *hitsp=[CCSprite spriteWithFile:@"images/ui/panel/phalanx22.png"];
					addTargetToCenter(hitsp,sprite,0);
				}
			}
		}
	}
}

-(void)ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event{
	if(currenDropObj){
		[currenDropObj removeFromParentAndCleanup:true];
		currenDropObj=nil;
		isTouched=false;
	}
	
	[self showRoleList];
}

-(void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
	
	[self showRoleList];
	
	isTouched=false;
	if(currenDropObj){
		[currenDropObj setPosition:getGLpoint(touch)];
		for(int i=0;i<10;i++){
			CCSprite *sprite=(CCSprite*)[self getChildByTag:ROLEARBASE+i];
			[sprite removeAllChildrenWithCleanup:true];
			CGRect rect=CGRectMake(sprite.position.x- sprite.contentSize.width/2, sprite.position.y-sprite.contentSize.height/2, sprite.contentSize.width, sprite.contentSize.height);
			if(CGRectContainsPoint(rect, currenDropObj.position)){
				if(![self checkOnCol:i]){
					break;
				}
				int rid_me=[currenDropObj.userObject intValue];
				
				NSString *key=[NSString stringWithFormat:@"%i",i];
				
				if(![roleArMe valueForKey:key]){
					for(NSString *keyobj in roleArMe.allKeys){
						//遇到相同的武将回收
						if([[roleArMe valueForKey:keyobj] intValue] == rid_me){
							[self setRoleAndMeValue:nil keyname:keyobj];
							[[self getChildByTag:ROLEVIEWBASE+keyobj.intValue]removeFromParentAndCleanup:true];
						}
						//遇到多一位其他配将回收
						if(rid_me>10 && [[roleArMe valueForKey:keyobj] intValue]>10){
							[self setRoleAndMeValue:nil keyname:keyobj];
							[[self getChildByTag:ROLEVIEWBASE+keyobj.intValue]removeFromParentAndCleanup:true];
						}
					}
					[self setRoleAndMeValue:currenDropObj.userObject keyname:key];
					
					[currenDropObj removeFromParentAndCleanup:true];
					currenDropObj=nil;
					
					[self performSelector:upRoleDataFun];
                    //
                    roleArId=-1;
					return;
				}else{
                    //位置有人
                    //[ShowItem showErrorAct:@"54"];
                    int ar_id = [self checkInPoint:rid_me];
                    if (roleArId == i || ar_id == i) {
                        roleArId=-1;
                    }else if(-1 == roleArId){
                        if (-1 == ar_id) {
                            int rid=[[roleArMe objectForKey:[NSString stringWithFormat:@"%i",i]] intValue];
                            if (rid<10) {
                                if ( rid>0 && rid<10 ) {
                                    [ShowItem showItemAct:NSLocalizedString(@"union_par_tips_1",nil)];
                                }else{
                                    [ShowItem showErrorAct:@"1"];
                                }
                            }else{
                                [self setRoleAndMeValue:currenDropObj.userObject keyname:key];
                                [self performSelector:upRoleDataFun];
                            }
                        }else{
                            //交换
                            int rid=[[roleArMe objectForKey:[NSString stringWithFormat:@"%i",i]] intValue];
                            if (rid>0) {
                                [self setRoleAndMeValue:currenDropObj.userObject keyname:key];
                                [self setRoleAndMeValue:[NSNumber numberWithInt:rid] keyname:[NSString stringWithFormat:@"%i",ar_id]];
                                [self performSelector:upRoleDataFun];
                            }else{
                                [ShowItem showErrorAct:@"1"];
                            }
                            
                        }
                    }else{
                        //在位置的两名个角色交换位置
                        //交换
                        int rid=[[roleArMe objectForKey:[NSString stringWithFormat:@"%i",i]] intValue];
                        [self setRoleAndMeValue:currenDropObj.userObject keyname:key];
                        [self setRoleAndMeValue:[NSNumber numberWithInt:rid] keyname:[NSString stringWithFormat:@"%i",ar_id]];
                        [self performSelector:upRoleDataFun];
                        //
                        roleArId=-1;
                    }
                    
                    [currenDropObj removeFromParentAndCleanup:true];
                    currenDropObj=nil;
                    return;
                    
                }
                //
                
			}
		}
		//拉出阵中
		if(roleArId!=-1){
			if([roleArMe objectForKey:[NSString stringWithFormat:@"%i",roleArId]]){
				int rid=[[roleArMe objectForKey:[NSString stringWithFormat:@"%i",roleArId]] intValue];
				if(rid<10){
					[ShowItem showItemAct:NSLocalizedString(@"union_par_tips_1",nil)];
                    roleArId=-1;
				}else{
					NSString *key=[NSString stringWithFormat:@"%i",roleArId];
					[self setRoleAndMeValue:[NSNumber numberWithInt:-1] keyname:key];
					[[self getChildByTag:ROLEVIEWBASE+roleArId]removeFromParentAndCleanup:true];
					roleArId=-1;
					[self performSelector:upRoleDataFun];
				}
			}
		}
		[currenDropObj removeFromParentAndCleanup:true];
		currenDropObj=nil;
	}
	
}

//fix chao
-(int)checkInPoint:(int)rid{
    if(roleArMe){
        for(NSString *keyobj in roleArMe.allKeys){
            if([[roleArMe valueForKey:keyobj] intValue] == rid){
                return [keyobj intValue];
            }
        }
    }
    return -1;
}
//end

#pragma mark 监测能否使用该列
-(bool)checkOnCol:(int)raId{
	int colConfig[3][3]=cc;
	for(int i=0;i<3;i++){
		if(raId==colConfig[colId][i]){
			return YES;
		}
	}
	return NO;
}


@end
