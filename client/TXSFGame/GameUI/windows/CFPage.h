//
//  CFPage.h
//  TXSFGame
//
//  Created by shoujun huang on 12-12-20.
//  Copyright 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCLayerList.h"
#import "Config.h"
#import "MessageBox.h"

#define PageDot_Tag		88

typedef enum {
	IST_EQUIP = 88,//装备
	IST_ITEM,//物品
	IST_FATE,//元神
}ItemSystemType;

#pragma mark -
#pragma mark - PageDot
////页面
@interface PageDot:CCSprite{
	NSUInteger dotCount;
    int m_index;
}
@property (nonatomic,assign) NSUInteger dotCount;
-(void)setIndex:(NSUInteger)index;
-(int)index;
-(void)setSize:(CGSize)size;
-(void)setSizeWithScale:(CGSize)scaleSize;
@end

#pragma mark -
#pragma mark - Card
@interface Card:  CCListItem{
	ItemSystemType cardType;//物品类型
	NSInteger	cardItemID;//物品ID(小于1为没有物品)
	NSInteger	cardBaseID;//基础表ID
	////
	NSInteger	isTrade;//可否交易
	NSInteger	itemExp;//经验
	NSInteger	itemLevel;//物品等级
	ItemQuality	itemQuality;//物品品质
	////
	NSInteger	itemCount;//物品数量
	BOOL		itemSelected;//标志选中
	BOOL		itemUsed;//使用标志
	BOOL		itemClose;//关闭状态
}
////
@property (nonatomic,assign) NSInteger isTrade;
@property (nonatomic,assign) NSInteger itemExp;
@property (nonatomic,assign) NSInteger itemLevel;
@property (nonatomic,assign) ItemQuality itemQuality;
///////
@property (nonatomic,assign) NSInteger itemCount;
@property (nonatomic,assign) BOOL itemSelected;
@property (nonatomic,assign) BOOL itemUsed;
@property (nonatomic,assign) BOOL itemClose;
/////
-(void)changeItemWithOther:(Card*)other;
-(void)changeItemWithDict:(NSDictionary*)dict;//改变物品
-(void)removeItem;//删除物品
-(void)setItemIsNull;//设置物品为空
-(void)setItemVisible:(BOOL)visibled;//物品显示和隐藏
-(NSInteger)getItemID;//取物品ID
-(NSDictionary*)getCardDict;//取物品dict
-(NSInteger)getBaseID;//基础表ID
-(ItemSystemType)getItemType;//类型
-(BOOL)isOwnItem;//是否有物品
////
-(void)removeItemWithValue:(NSInteger)value;//删除物品(数量)
-(void)addItemWithValue:(NSUInteger)value;//增加物品(数量)
//显示选择操作
-(void)showItemSelected;
//不显示选择操作
-(void)hideItemSelected;
//
-(CCSprite*)getIconWithType:(NSInteger)type bID:(NSInteger)bid;

-(void)showItem;
-(void)hideItem;
@end

#pragma mark -
#pragma mark text Box
@interface TextBox:CCLayerColor{
	MessageBox* messageBox;
	CCMenu *menu;
	NSInteger cardItemID;
	ItemSystemType cardItemSysType;
	NSInteger cardCount;
	BOOL isMenuTouch;
	BOOL isShowButton;
}
@property (nonatomic,assign) BOOL isShowButton;
-(void)addMenuItem:(CCMenuItem*)menuItem z:(NSInteger)z tag:(NSInteger)tag;
-(void)setMessageBoxWith:(ItemSystemType)type itemID:(NSInteger)itemID count:(NSInteger)count;
-(void)setMessageBoxWith:(NSString*)str;
@end

#pragma mark -
#pragma mark - CardLayer
#define CL_DITHERING_LEN (20.0f) //抖动的范围
#define CL_SHOW_CARD_TIME (50.0f)//显示弹出介绍时间
#define CL_MOVE_PACKAGE_TIME (60.0f)//移动背包的时间
#define CL_MOVE_ITEM_TIME (100.0f)//移动物品的时间

@interface CardLayer : CCLayerColor<CCListDelegate>{
	CCLayerList				*cards;
	////
	NSInteger row;//行
	NSInteger column;//列
	///
	NSInteger capacity;
	NSInteger capacityMax;
	CGRect cutRect;
	///
	NSInteger pagesCount;
	//
	CGPoint startMovePos;
	//
	CGPoint pageStartMovePos;
	//
	NSInteger pageIndex;
	//
	BOOL isMovePage;
	//
	id target;
	
	////	
	CGFloat touchStartTime;//开始触碰时间
	UITouch *startTouch;//开始的触点
	BOOL isMoveItem;//移动物品
	BOOL isMovePackage;//移动背包
	BOOL isMoveTouch;//移动手指	
}
@property (nonatomic,assign) id target;
@property (nonatomic,assign) NSInteger row;
@property (nonatomic,assign) NSInteger column;
@property (nonatomic,assign) NSInteger capacity;
@property (nonatomic,assign) NSInteger capacityMax;
@property (nonatomic,assign) CGRect cutRect;
@property (nonatomic,assign) NSInteger pageIndex;
+(CardLayer*)create;
-(void)reload;
////增加物品(ID,value)
-(void)initPageWithCount:(NSInteger)count;
-(NSInteger)getPagesCount;
-(void)startPageIndex:(int)page;
-(BOOL)addItemWithDict:(NSDictionary*)dict;
-(void)removeItemWithID:(NSInteger)itemID;
-(void)removeAllItem;
-(NSArray*)getLayerItemArray;
-(BOOL)checkPosIsInNowPage:(CGPoint)pos;
-(BOOL)checkIsInNowPage:(Card*)card;
-(void)setBatSale:(BOOL)isSale;

-(void)showNeighPage;
-(void)hideOtherPage;
//fix chao
-(void)setCardsIsNil;
-(void)updatePageWithMovePos:(CGPoint)pos;
//end
@end
