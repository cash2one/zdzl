//
//  WeaponViewerContent.m
//  TXSFGame
//
//  Created by TigerLeung on 13-3-21.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "WeaponViewerContent.h"
#import "GameResourceLoader.h"
#import "GameFileUtils.h"
#import "Config.h"

@implementation WeaponViewerContent

+(WeaponViewerContent*)create:(int)wid type:(int)type{
	WeaponViewerContent * node = [WeaponViewerContent node];
	[node loadWeapon:wid type:type];
	return node;
}

-(void)loadWeapon:(int)wid type:(int)_type{
	weapon_id = wid;
	type = _type;
	[self showWeapon];
}

-(void)showWeapon{
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			if(type<=0){
				return;
			}else{
				type = 0;
			}
		}
	}
	
	NSString * name = [NSString stringWithFormat:@"%d.png",weapon_id];
    
	if(type>0){
		name = [NSString stringWithFormat:@"%d_%d.png",weapon_id,type];
	}else if(type==-1){
        if (weapon_id>=1&&weapon_id<=6) {
            name = [NSString stringWithFormat:@"%d_%d.png",weapon_id,1];
        }
    }
     
    /*
     if (_sid == -1) {
        if (_aid>=1&&_aid<=6) {
            weapon = getHostWeaponImage(_aid, 1);
        }else{
            weapon = getWeaponImage(_aid);
        }
     } else {
        weapon = getHostWeaponImage(_aid, _sid);
     }
     */
    
	NSString * path = [GameResourceLoader getFilePathByType:PathType_weapon target:name];
	if(![CCFileUtils hasFilePathByTarget:path]){
		
		helper = [GameLoaderHelper create:path];
		helper.type = PathType_weapon;
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		
		[self showLoaderInContentCenter];
		
		return;
	}
	
	viewer = [CCSprite spriteWithFile:path];
	if(viewer){
		//viewer.anchorPoint = self.anchorPoint;
		[self addChild:viewer];
	}
	
	[self hideLoader];
	
}

-(void)setAnchorPoint:(CGPoint)anchorPoint{
	[super setAnchorPoint:anchorPoint];
	if(viewer){
		//viewer.anchorPoint = anchorPoint;
	}
}

@end
