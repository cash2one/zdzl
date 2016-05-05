//
//  Item.m
//  TXSFGame
//
//  Created by Soul on 13-3-8.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "Item.h"
#import "CCNode+AddHelper.h"

#import "GameFileUtils.h"
#import "GameResourceLoader.h"

#define Item_default_width cFixedScale(86)
#define Item_default_height	cFixedScale(86)
#define POS_num_2_Y cFixedScale(10)
#define POS_num_X   cFixedScale(15)

@implementation Item

@synthesize level = _level;
@synthesize count = _count;
@synthesize quality = _quality;
@synthesize iType	= _iType;


+(Item*)create:(NSString *)_path quality:(int)_qua count:(int)_cut level:(int)_lv{
	
	if (_path == nil) return nil;
	
	Item* _item = [Item node];
	_item.level = _lv ;
	_item.count = _cut;
	_item.quality = _qua;
	[_item showItem:_path];
	
	return _item ;
}

+(Item*)createByIcon:(CCSprite*)icon quality:(int)_qua count:(int)_cut level:(int)_lv{
	
	Item* _item = [Item node];
	
	_item.level = _lv ;
	_item.count = _cut;
	_item.quality = _qua;
	[_item showIcon:icon];
	
	return _item ;
}

-(id)init{
	if ((self = [super init])) {
		self.contentSize=CGSizeMake(Item_default_width, Item_default_height);
	}
	return self;
}

-(void)dealloc{
	CCLOG(@"Item->dealloc!");
	[super dealloc];
}

-(void)onEnter{
	[super onEnter];
	//[self showItem];
}
-(void)onExit{
	
	if(helper){
		[helper free];
		helper = nil;
	}
	if(targetPath){
		[targetPath release];
		targetPath = nil;
	}
	
	[super onExit];
}

-(void)showIcon:(CCNode*)icon{
	[self Category_AddChildToCenter:icon z:2];
}

-(void)showItem:(NSString*)_path{
	if(targetPath) [targetPath release];
	targetPath = [NSString stringWithString:_path];
	[targetPath retain];
	[self showItem];
}

-(void)showItem{
	
	if(!targetPath) return;
	
	if(helper){
		BOOL isError = helper.isError;
		[helper free];
		helper = nil;
		if(isError){
			return;
		}
	}
	
	if(![CCFileUtils hasFilePathByTarget:targetPath]){
		helper = [GameLoaderHelper create:targetPath];
		helper.target = self;
		helper.call = _cmd;
		[[GameResourceLoader shared] downloadHelper:helper];
		return;
	}
	
	CCSprite* __sprite = [CCSprite spriteWithFile:targetPath];
	if (__sprite == nil) {
		CCLOG(@"Fuck! have no image!!!");
	}
	[self Category_AddChildToCenter:__sprite z:2];
}

-(void)setCount:(int)count{
	_count = count;
	
	[self removeChildByTag:2012 cleanup:YES];
	
	if (_count <= 1) return ;

	CCSprite *num_2 = getImageNumber(@"images/ui/num/num-3.png", 15, 20, _count);
	
	[self addChild:num_2 z:5];
	
	num_2.tag = 2012 ;
	
	num_2.position=ccp(self.contentSize.width/2, POS_num_2_Y);
	

}

-(void)setLevel:(int)level{
	_level = level;
	
	[self removeChildByTag:2009 cleanup:YES];
	[self removeChildByTag:2010 cleanup:YES];
	
	if (_level <= 0) return ;
	
	CGRect rect = CGRectMake(15*10, 0, 15, 25) ;
	CCSprite *num_1 = [CCSprite spriteWithFile:@"images/ui/num/num-1.png" rect:rect];
	
	CCSprite *num_2 = getImageNumber(@"images/ui/num/num-1.png", 15, 20, _level);
	
	[self addChild:num_1 z:5];
	[self addChild:num_2 z:5];
	
	num_1.anchorPoint = num_2.anchorPoint = ccp(0, 1.0);
	
	num_1.tag = 2009 ;
	num_2.tag = 2010 ;


	num_1.position=ccp(0, self.contentSize.height);
	num_2.position=ccp(POS_num_X, self.contentSize.height);
	
}

-(void)setQuality:(ItemQuality)quality{
	_quality = quality;
	
	[self removeChildByTag:2007 cleanup:YES];
	[self removeChildByTag:2008 cleanup:YES];
	
	if (quality < IQ_WHITE) return ;
	
	NSString* path = [NSString stringWithFormat:@"images/ui/common/quality%d.png",quality];
	CCSprite* __sprite = [CCSprite spriteWithFile:path];
	__sprite.tag = 2007 ;
	__sprite.visible= YES;
	[self Category_AddChildToCenter:__sprite];
	
	NSString* path2 = [NSString stringWithFormat:@"images/ui/common/quality%dSelect.png",quality];
	CCSprite* __sprite2 = [CCSprite spriteWithFile:path2];
	__sprite2.tag = 2008;
	__sprite2.visible= NO;
	[self Category_AddChildToCenter:__sprite2];
	
}

-(void)showOther:(BOOL)_isShow{
	
	CCNode* n1 = [self getChildByTag:2007];
	CCNode* n2 = [self getChildByTag:2008];
	
	CCNode* n3 = [self getChildByTag:2009];
	CCNode* n4 = [self getChildByTag:2010];
	
	CCNode* n5 = [self getChildByTag:2012];
	
	if (n1)		n1.visible = _isShow;
	if (n2)		n2.visible = NO;
	if (n3)		n3.visible = _isShow;
	if (n4)		n4.visible = _isShow;
	if (n5)		n5.visible = _isShow;
	
}

@end

















