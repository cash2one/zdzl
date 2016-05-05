//
//  PageConsole.h
//  TXSFGame
//
//  Created by Max on 12-12-30.
//  Copyright 2012年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface PageConsole : CCLayer {
	int pageCount;
	int currenPage;
	CCSpriteFrame *sf1;
	CCSpriteFrame *sf2;
}


-(id)initPageCount:(int)pagecount;

-(void)changPage:(int)pagenum;

@property (nonatomic,assign) NSInteger currenPage;
@end
