//
//  ItemSizer.h
//  TXSFGame
//
//  Created by Soul on 13-3-9.
//  Copyright 2013年 eGame. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"


@interface CSizer : CCSprite<CCTouchOneByOneDelegate>

@end

@interface SizerMumber :  CSizer{
	int			_type;
	CCSprite*	_background;
	CCLabelTTF* _text;
	id			_target;
	SEL			_call;
}
@property(nonatomic,assign)int type;
@property(nonatomic,assign)id  target;
@property(nonatomic,assign)SEL call;

@end

@interface ItemSizer : CSizer {
    int			_selectIndex;
	CCLabelTTF* _text;
	BOOL		_isDelay;
	
	id			_target;
	SEL			_call;
	
}
@property(nonatomic,assign)id  target;
@property(nonatomic,assign)SEL call;

@property(nonatomic,assign)int selectIndex;

@end
