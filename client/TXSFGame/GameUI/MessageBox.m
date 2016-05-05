//
//  MessageBox.m
//  TXSFGame
//
//  Created by shoujun huang on 12-11-28.
//  Copyright 2012 eGame. All rights reserved.
//

#import "MessageBox.h"
#import "Config.h"

#define DEFAULT_SIZE	cFixedScale(16)
#define DEFAULT_LINE	cFixedScale(4)


float line=1.0f;

@implementation MessageBox
@synthesize offset = offset_;
@synthesize isDown = isDown_;
@synthesize boundColor = bcolor_;
@synthesize AdjustWidth = adjust_width;
@synthesize AdjustHeight = adjust_height;
+(MessageBox*)create:(CGPoint)_offset color:(ccColor4B)_cl background:(ccColor4B)_bl
{
	MessageBox *box = [MessageBox layerWithColor:_bl width:0 height:0];
	box.offset = _offset;
	box.boundColor=_cl;
	return box;
}
+(MessageBox*)create:(CGPoint)_offset color:(ccColor4B)_cl
{
	return [MessageBox create:_offset color:_cl background:ccc4(0, 0, 0, 180)];
}
-(void)onEnter
{
	[super onEnter];
	if (iPhoneRuningOnGame()) {
		line=3.3f;
	}
}
-(void)onExit
{
	[super onExit];
}

-(void)draw
{
	[super draw];
	glLineWidth(line);
    ccDrawColor4B(bcolor_.r, bcolor_.g, bcolor_.b, bcolor_.a);
	ccDrawRect(CGPointZero, ccp(self.contentSize.width, self.contentSize.height));
}

-(void)messageWithArray:(NSArray *)_list
{
	if (_list) {
		
		NSString *cmd = @"";
		for (NSString *obj in _list) {
			cmd = [cmd stringByAppendingFormat:@"%@*",obj];
		}
		if (cmd.length > 0) {
			cmd = [cmd substringToIndex:(cmd.length-1)];
			[self message:cmd];
		}
	}
}
-(void)messageWithArgs:(NSString *)_msg, ...
{
	if( _msg ) {
		va_list args;
		va_start(args, _msg);
		NSMutableArray *array = array = [NSMutableArray arrayWithObject:_msg];;
		NSString *i = va_arg(args, NSString*);
		while(i) {
			[array addObject:i];
			i = va_arg(args, NSString*);
		}
		va_end(args);
		[self messageWithArray:array];
	}
	
}
-(void)message:(NSString *)_msg
{
	[self removeAllChildrenWithCleanup:YES];
	if (!_msg) {
		return;
	}
	
	lineH = 0 ;
	
	self.contentSize = [self calculate:_msg];
    if (iPhoneRuningOnGame()) {
        self.contentSize = CGSizeMake(self.contentSize.width-adjust_width/2+offset_.x/2, self.contentSize.height-adjust_height/2+offset_.y/2*2);
        //todo ????
		//        self.contentSize = CGSizeMake(self.contentSize.width/2, self.contentSize.height/2);
        
    }else
		self.contentSize = CGSizeMake(self.contentSize.width-adjust_width+offset_.x*2, self.contentSize.height-adjust_height+offset_.y*2);
	
	CGPoint _pt = ccp(offset_.x, self.contentSize.height - offset_.y);
	NSArray *parts3 = [_msg componentsSeparatedByString:@"*"];
	for ( NSString *str in parts3){
		if (str.length == 0) {
			continue;
		}
		NSArray *parts2 = [str componentsSeparatedByString:@"|"];
		for ( NSString *str2 in parts2){
			_pt = [self drawContent:str2 paint:_pt];
		}
		_pt.x = offset_.x;
		//        if (iPhoneRuningOnGame()) {
		//            _pt.y -= lineH/2;
		//        }else
		_pt.y -= lineH;
	}
}
-(CGSize)calculate:(NSString*)_msg
{
	float _w = 0 ;
	float _h = 0 ;
	NSArray *parts = [_msg componentsSeparatedByString:@"*"];//全部行
	for ( NSString *line in parts) {
		if (line.length == 0) {
			continue;
		}
		NSArray *tr = [line componentsSeparatedByString:@"|"];
		float _x = 0 ;
		float _y = 0 ;
		for (NSString *obj in tr) {
			//-------------------------------------------------------------
			if ([@"^" characterAtIndex:0] == [obj characterAtIndex:0]) {
				//换行
				obj = [obj substringFromIndex:1];
				int _value = [obj intValue];
				if (_value > _y) {
					_y =  _value;//换行的高度
				}
				//continue;
			}
			else {
				NSArray *array = [obj componentsSeparatedByString:@"#"];
				NSString *_info = @"";
				int _size = DEFAULT_SIZE;
				
				int _index = 0 ;
				for ( NSString *str in array){
					if (_index == 0) {
						_info = str;
					}else if (_index == 1) {
					}else if (_index == 2) {
						_size = [str intValue];
					}
					_index++;
				}
				//if ( (_info.length)*_size> _x) {
				_x += (_info.length)*_size ;
				//}
				if (_size > _y) {
					_y = _size;//换行的高度
				}
			}
			//-------------------------------------------------------------
		}
		
		if (_x > _w) {
			_w = _x ;
		}
		_h += (_y+DEFAULT_LINE);
	}
	return CGSizeMake(_w, _h);
}
-(CGPoint)drawContent:(NSString*)_content paint:(CGPoint)_pt
{
	if (!_content) {
		return _pt;
	}
	//空格一段距离
	if ([@"^" characterAtIndex:0] == [_content characterAtIndex:0]) {
		//换行
		_content = [_content substringFromIndex:1];
		int _value = [_content intValue];
		_pt = ccp(_pt.x , _pt.y);
		lineH = _value;
		return _pt;
	}
	
	//绘制要的内容
	NSArray *parts = [_content componentsSeparatedByString:@"#"];
	NSString *_info = @"";
	ccColor3B t_color = ccWHITE;
	int _size = DEFAULT_SIZE;
	int _id = FONT_1;
	
	int _index = 0 ;
	for ( NSString *str in parts){
		if (_index == 0) {
			_info = str;
		}else if (_index == 1) {
			t_color = color3BWithHexString(str);//[self color3BWithHexString:str];
		}else if (_index == 2) {
			_size = [str intValue];
		}else if (_index == 3) {
			_id = [str intValue];
		}
		_index++;
	}
	lineH = _size+DEFAULT_LINE;
	CCLabelTTF *label = [CCLabelTTF labelWithString:_info fontName:getCommonFontName(_id) fontSize:_size];
    if (iPhoneRuningOnGame()) {
		//        label.scale  = 0.5;
		
    }
	label.color = t_color;
	label.dimensions = CGSizeMake(_size*_info.length, _size);
	label.anchorPoint = CGPointZero;//ccp(0, 0.5);
	[label setVerticalAlignment:kCCVerticalTextAlignmentCenter];
	[label setHorizontalAlignment:kCCTextAlignmentLeft];
	[self addChild:label z:0];
    if (iPhoneRuningOnGame()) {
        label.position = ccp(_pt.x, _pt.y - _size/2);
    }else
        label.position = ccp(_pt.x, _pt.y - _size);
	_pt = ccp(_pt.x + _size*(_info.length), _pt.y);
	return _pt;
}



+(CCNode*)create:(NSString*)str target:(id)tar sel:(SEL)call{
	CCNode *node=[CCNode node];
	NSArray *parts=[str componentsSeparatedByString:@"|"];
	int linehight=0;
	int posx=0;
	for(NSString *words in parts){
		NSString *info=@"";
		ccColor3B color=ccWHITE;
		int size=DEFAULT_LINE;
		int font=FONT_1;
		int index=0;
		NSString *var=@"";
		
		//int sp=0;
		
		NSArray *word = [words componentsSeparatedByString:@"#"];
		for(NSString *str in word){
			switch (index) {
				case 0:{
					info=str;
					//var=str;
				}
					break;
				case 1:{
					color=color3BWithHexString(str);
				}
					break;
				case 2:{
					size=[str integerValue];
				}
					break;
				case 3:{
					font=[str integerValue];
				}
					break;
				case 4:{
					var=str;
				}
					break;
				case 5:{
					//sp=[str integerValue];
				}
					break;
				default:
					break;
			}
			index++;
			
		}
		CCLabelTTF *lab=[CCLabelTTF labelWithString:info fontName:getCommonFontName(font) fontSize:size];
		[lab setColor:color];
		[lab setPosition:ccp(posx, 0)];
		if(![var isEqual:@""]){
			CCLayerColor *layerline=[CCLayerColor layerWithColor:ccc4(color.r, color.g, color.b ,100)];
			[layerline setContentSize:CGSizeMake(lab.contentSize.width, 2)];
			[layerline setPosition:ccp(0, -2)];
			CCMenu *menu=[CCMenu menuWithArray:nil];
			CCMenuItem *menuitem=[CCMenuItem itemWithTarget:tar selector:call];
			[menuitem setUserObject:var];
			[menuitem setContentSize:CGSizeMake(lab.contentSize.width, lab.contentSize.height)];
			[menu setPosition:ccp(0,0)];
			[menuitem setPosition:ccp(lab.contentSize.width/2, lab.contentSize.height/2)];
			[menu addChild:menuitem];
			[lab addChild:menu];
			[lab addChild:layerline];
		}
		[node addChild:lab];
		posx+=lab.contentSize.width+cFixedScale(5);
		linehight=lab.contentSize.height;
	}
	[node setContentSize:CGSizeMake(posx, linehight)];
	return node;
}


//-(ccColor3B)color3BWithHexString:(NSString *)_color
//{
//	if (!_color) {
//		return ccWHITE;
//	}
//
//	NSString *cString = [[_color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
//	if ([cString length] < 6)
//		return ccWHITE;
//
//	if ([cString hasPrefix:@"0X"])
//		cString = [cString substringFromIndex:2];
//	else if ([cString hasPrefix:@"#"])
//		cString = [cString substringFromIndex:1];
//
//	if ([cString length] != 6)
//		return ccWHITE;
//
//	NSRange range;
//	range.location = 0;
//	range.length = 2;
//	NSString *rString = [cString substringWithRange:range];
//
//	range.location = 2;
//	NSString *gString = [cString substringWithRange:range];
//
//	range.location = 4;
//	NSString *bString = [cString substringWithRange:range];
//
//	unsigned int r, g, b;
//	[[NSScanner scannerWithString:rString] scanHexInt:&r];
//	[[NSScanner scannerWithString:gString] scanHexInt:&g];
//	[[NSScanner scannerWithString:bString] scanHexInt:&b];
//
//	return ccc3(r, g, b);
//}
@end
