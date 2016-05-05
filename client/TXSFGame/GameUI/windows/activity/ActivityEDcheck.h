//
//  ActivityEDcheck.h
//  TXSFGame
//
//  Created by Max on 13-5-22.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


typedef  enum {
	Geted,
	CanGet,
	CanNotGet,
}Cellst;

@class RoleViewerContent;
@interface RoleInfo : CCLayer{
	RoleViewerContent *rvc;
}

@property (nonatomic,assign)int rid;

@end

@interface ActivityEDcheckCell : CCLayer{
	
}


+(ActivityEDcheckCell*)Cell:(int)day status:(Cellst)st;

@property (nonatomic,assign) int day;
@property (nonatomic,assign) Cellst status;
@property (nonatomic,assign) bool lastDay;
@property (nonatomic,assign) SEL selector;
@property (nonatomic,assign) id target;
@end


@interface ActivityEDcheck : CCLayer {
    
}

@end
