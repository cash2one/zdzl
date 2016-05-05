//
//  CarViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-20.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "CarViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "AnimationViewer.h"
#import "GameDB.h"
#import "Config.h"

@implementation CarViewerContent

@synthesize carOffset,inSkyHigh,shadowSize;

-(void)loadTargetCar:(int)cid dir:(RoleDir)_dir scaleX:(int)__scaleX{
	car_id = cid;
	roleDir=_dir;
	scaleX=__scaleX;
	
	NSDictionary * carInfo = [[GameDB shared] getCarInfo:car_id];
	carOffset=[[carInfo objectForKey:@"offset"]integerValue];
	shadowSize=[[carInfo objectForKey:@"isshadow"]integerValue];
	inSkyHigh=[[carInfo objectForKey:@"high"]integerValue];
	isDir = [[carInfo objectForKey:@"isDir"] integerValue];
	
	[self showCar];
}

-(void)showCar{
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			return;
		}
	}
	
	NSString * path = [self getPath];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		path = [NSString stringWithFormat:@"%@.%@",path,GAME_RESOURCE_DAT];
		
		helper = [GameLoaderHelper create:path isUnzip:YES];
		helper.type = PathType_fight_role;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		
		CCSprite * def = [CCSprite spriteWithFile:@"images/defaultCar.png"];
		def.tag = 123;
		def.anchorPoint = ccp(0.5,1.0);
		[self addChild:def];
		
		return;
	}
	
	[self removeChildByTag:123 cleanup:YES];
	
	car = [AnimationViewer node];
	[car setAnchorPoint:ccp(0.5, 0)];

	[car setPosition:ccp(0,-cFixedScale(carOffset)+ cFixedScale(inSkyHigh))];
	[self addChild:car];
	
	if(isDir==0){
		path = [NSString stringWithFormat:@"%@/%@",path,@"%d.png"];
		[car showAnimationByPathForever:path];
	}else{
		[self updateViewer];
	}
}

-(void)updateDir:(RoleDir)_dir scaleX:(int)__scaleX{
	if(roleDir==_dir) return;
	roleDir = _dir;
	scaleX=__scaleX;
	[self updateViewer];
}

-(void)updateViewer{
	if(!car) return;
	if(isDir == 1){
		NSString * path = [self getPath];
		path = [NSString stringWithFormat:@"%@/%d/%@",path,roleDir,@"%d.png"];
		[car showAnimationByPathForever:path];
		
	}
}

-(NSString*)getPath{
	NSString * name = [NSString stringWithFormat:@"car%d",car_id];
	NSString * path = [GameResourceLoader getFilePathByType:PathType_car target:name];
	return path;
}

@end
