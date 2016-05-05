//
//  UIConfig.h
//  TXSFGame
//
//  Created by Soul on 13-5-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//

#import "cocos2d.h"
#import "CCLabelFX.h"
#import "GameDB.h"
#import "GameConnection.h"
//#import "EventLayer.h"
//#import "BrowLayer.h"
#import "StringSprite.h"

#import "EquipmentIconViewerContent.h"
#import "FateIconViewerContent.h"
#import "ItemIconViewerContent.h"
#import "RoleIconViewerContent.h"

#import "GameDefine.h"

static inline NSString* getRoleUpStringWithQuality(int quality){
    NSString *str_ = @"";
    switch (quality) {
        case IQ_GREEN:
            str_ = @"role_cultivate_quality_green";
            break;
        case IQ_BLUE:
            str_ = @"role_cultivate_quality_blue";
            break;
        case IQ_PURPLE:
            str_ = @"role_cultivate_quality_purple";
            break;
        case IQ_ORANGE:
            str_ = @"role_cultivate_quality_orange";
            break;
        case IQ_RED:
            break;
        default:
            break;
    }
    return  str_;
}
static inline NSString* getPartName(EquipmentPart _part)
{
	if (_part == EquipmentPart_head) {
		//return @"头盔";
        return  NSLocalizedString(@"config_equipment_part_head",nil);
		
	}
	else if ( _part == EquipmentPart_body) {
		//return @"盔甲";
        return  NSLocalizedString(@"config_equipment_part_body",nil);
	}
	else if ( _part == EquipmentPart_foot) {
		//return @"战靴";
        return  NSLocalizedString(@"config_equipment_part_foot",nil);
	}
	else if ( _part == EquipmentPart_necklace) {
		//return @"项链";
        return  NSLocalizedString(@"config_equipment_part_necklace",nil);
	}
	else if ( _part == EquipmentPart_sash) {
		//return @"腰带";
        return  NSLocalizedString(@"config_equipment_part_sash",nil);
	}
	else if ( _part == EquipmentPart_ring) {
		//return @"戒指";
        return  NSLocalizedString(@"config_equipment_part_ring",nil);
	}
	return nil;
}

static inline NSString* getPartKey(EquipmentPart _part)
{
	if (_part == EquipmentPart_head) {
		return @"eq1";
	}
	else if ( _part == EquipmentPart_body) {
		return @"eq2";
	}
	else if ( _part == EquipmentPart_foot) {
		return @"eq3";
	}
	else if ( _part == EquipmentPart_necklace) {
		return @"eq4";
	}
	else if ( _part == EquipmentPart_sash) {
		return @"eq5";
	}
	else if ( _part == EquipmentPart_ring) {
		return @"eq6";
	}
	return nil;
}

static inline NSArray * getBtnSpriteForScale(NSString * name, float scale){
	
	CCSprite * pass1 = [CCSprite spriteWithFile:name];
	CCSprite * pass2 = [CCSprite spriteWithFile:name];
	pass2.scale = scale;
	
	CCSprite * passBtn1 = [CCSprite node];
	[passBtn1 addChild:pass1];
	
	pass1.anchorPoint = ccp(0,0);
	pass1.position = ccp(pass1.contentSize.width*((scale-1)/2),pass1.contentSize.height*((scale-1)/2));
	passBtn1.contentSize = CGSizeMake(pass2.contentSize.width*scale, pass2.contentSize.height*scale);
	
	return [NSArray arrayWithObjects:passBtn1,pass2,nil];
}

static inline NSArray * getBtnSprite(NSString * name){
	return getBtnSpriteForScale(name, 1.2);
}

static inline NSArray * getBtnSpriteWithStatus(NSString * name)
{
	if (!name) {
		CCLOG(@"name is null!");
		return nil;
	}
	NSString *path1 = [name stringByAppendingFormat:@"_1.png"];
	NSString *path2 = [name stringByAppendingFormat:@"_2.png"];
	
	CCSprite *spr1 = [CCSprite spriteWithFile:path1];
	CCSprite *spr2 = [CCSprite spriteWithFile:path2];
	
	NSMutableArray *array = [NSMutableArray array];
	[array addObject:spr1];
	[array addObject:spr2];
	return array;
}
static inline NSArray * getDisableBtnSpritesArrayWithStatus(NSString * name)
{
	if (!name) {
		CCLOG(@"name is null!");
		return nil;
	}
	NSString *path1 = [name stringByAppendingFormat:@"_1.png"];
	NSString *path2 = [name stringByAppendingFormat:@"_2.png"];
	NSString *path3 = [name stringByAppendingFormat:@"_3.png"];
	
	CCSprite *spr1 = [CCSprite spriteWithFile:path1];
	CCSprite *spr2 = [CCSprite spriteWithFile:path2];
	CCSprite *spr3 = [CCSprite spriteWithFile:path3];
	NSMutableArray *array = [NSMutableArray array];
	[array addObject:spr1];
	[array addObject:spr2];
	[array addObject:spr3];
	
	return array;
}


static inline NSArray * getDisableBtnSpriteWithStatus(NSString * name)
{
	if (!name) {
		CCLOG(@"name is null!");
		return nil;
	}
	NSString *path1 = [name stringByAppendingFormat:@"_3.png"];
	NSString *path2 = [name stringByAppendingFormat:@"_3.png"];
	
	CCSprite *spr1 = [CCSprite spriteWithFile:path1];
	CCSprite *spr2 = [CCSprite spriteWithFile:path2];
	
	NSMutableArray *array = [NSMutableArray array];
	[array addObject:spr1];
	[array addObject:spr2];
	return array;
}
static inline NSString* getCommonFontName(FONT_TYPE _type){
	switch (_type) {
		case FONT_1:{return @"Verdana-Bold";}
		case FONT_2:{return @"Marker Felt";}
		case FONT_3:{return GAME_DEF_CHINESE_FONT;}
			
		default:break;
	}
	return nil;
}

static inline float cFixedScale(float v){
	if((UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone)){
		return v/2;
	}
    return v;
}



//取品质字体颜色
static inline ccColor3B getColorByQuality(ItemQuality quality){
	ccColor3B color;
	switch (quality) {
		case IQ_WHITE:color = ccc3(238, 228, 208);break;
			//		case IQ_WHITE:color = ccc3(254, 236, 130);break;	// 合成物品有用到
		case IQ_GREEN:color = ccc3(49, 182, 82);break;
		case IQ_BLUE:color = ccc3(6, 148, 216);break;
		case IQ_PURPLE:color = ccc3(239, 4, 222);break;
		case IQ_ORANGE:color = ccc3(247, 73, 0);break;
		case IQ_RED:color = ccc3(247, 0, 0);break;
		default:color = ccc3(254, 236, 130);break;
	}
	return color;
}
//十进制转十六进制
static inline NSString* getHexStringWithInt(int tmpid)	{
	NSString *endtmp=@"";
	NSString *nLetterValue;
	NSString *nStrat;
	int ttmpig=tmpid%16;
	int tmp=tmpid/16;
	switch (ttmpig)	{
		case 10:nLetterValue =@"A";break;
		case 11:nLetterValue =@"B";break;
		case 12:nLetterValue =@"C";break;
		case 13:nLetterValue =@"D";break;
		case 14:nLetterValue =@"E";break;
		case 15:nLetterValue =@"F";break;
		default:nLetterValue= [NSString stringWithFormat:@"%i",ttmpig];// [[NSString alloc]initWithFormat:@"%i",ttmpig];
	}
	switch (tmp){
		case 10:nStrat =@"A";break;
		case 11:nStrat =@"B";break;
		case 12:nStrat =@"C";break;
		case 13:nStrat =@"D";break;
		case 14:nStrat =@"E";break;
		case 15:nStrat =@"F";break;
		default:nStrat= [NSString stringWithFormat:@"%i",tmp];//[[NSString alloc]initWithFormat:@"%i",tmp];
	}
	endtmp= [NSString stringWithFormat:@"%@%@",nStrat,nLetterValue];//[[NSString alloc]initWithFormat:@"%@%@",nStrat,nLetterValue];
	return endtmp;
}
//转string
static inline NSString* getHexStringWithColor3B(ccColor3B color3B){
	NSString *r = [NSString stringWithFormat:@"%@",getHexStringWithInt(color3B.r)];
    NSString *g = [NSString stringWithFormat:@"%@",getHexStringWithInt(color3B.g)];
    NSString *b = [NSString stringWithFormat:@"%@",getHexStringWithInt(color3B.b)];
    return [NSString stringWithFormat:@"#%@%@%@",r,g,b];
}
//品质获得十六进制颜色
static inline NSString* getHexColorByQuality(ItemQuality quality)
{
	ccColor3B color = getColorByQuality(quality);
	return getHexStringWithColor3B(color);
}
static inline ccColor3B color3BWithHexString(NSString* _color)
{
	NSString *cString = [[_color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
	if ([cString length] < 6)
		return ccWHITE;
	
	if ([cString hasPrefix:@"0X"])
		cString = [cString substringFromIndex:2];
	else if ([cString hasPrefix:@"#"])
		cString = [cString substringFromIndex:1];
	
	if ([cString length] != 6)
		return ccWHITE;
	
	NSRange range;
	range.location = 0;
	range.length = 2;
	NSString *rString = [cString substringWithRange:range];
	
	range.location = 2;
	NSString *gString = [cString substringWithRange:range];
	
	range.location = 4;
	NSString *bString = [cString substringWithRange:range];
	
	unsigned int r, g, b;
	[[NSScanner scannerWithString:rString] scanHexInt:&r];
	[[NSScanner scannerWithString:gString] scanHexInt:&g];
	[[NSScanner scannerWithString:bString] scanHexInt:&b];
	
	return ccc3(r, g, b);
}

//------------------------------------------------------------------------------

/*
static inline NSArray* getLineHight(NSString* content ,
									 NSString* font,
									 NSString* color,
									 CGSize viewSize,
									 int fontSize,
									 int rowH){
	
	CCLabelTTF *pen = [CCLabelTTF labelWithString:@"" fontName:font fontSize:fontSize];
	pen.verticalAlignment = kCCVerticalTextAlignmentCenter;
	pen.horizontalAlignment = kCCTextAlignmentLeft;
	pen.anchorPoint = ccp(0, 0.5);
	
	NSDictionary* css = getParseSetting(0);
	NSArray* tds = [content componentsSeparatedByString:[css objectForKey:@"td"]];
	
	//-----------------------------------------------------------------------
	//shit! begin to rated altitude
	//-----------------------------------------------------------------------
	int drawHeight = 0 ;
	int drawX = 0;
	
	NSMutableArray* heights = [NSMutableArray array];
	
	for (NSString* td in tds){
		NSArray* objs = [td componentsSeparatedByString:[css objectForKey:@"cell"]];
		NSString* pContent = getPaintContent(objs);
		pen.fontName = getPaintFontName(objs, font);
		pen.fontSize = getPaintFontSize(objs, fontSize);
		pen.color = getPaintFontColor(objs, color);
		
		if (pContent != nil) {
			int length = pContent.length;
			for (int i = 0 ; i < length ; i++){
				NSString* iconStr = checkDrawImage(pContent, i);
				if (iconStr != nil) {
					i = i + iconStr.length - 1;
					
					float tWidth = getDrawImageRect(0).width;
					float tHeight = getDrawImageRect(0).height > rowH ? getDrawImageRect(0).height :rowH;
					
					if ((drawX + tWidth) > viewSize.width) {
						[heights addObject:[NSNumber numberWithInt:drawHeight]];
						drawX = 0 ;
						drawHeight = 0;
					}
					
					if (tHeight > drawHeight) {
						drawHeight = tHeight;
					}
					
					drawX += tWidth;
					continue;
				}
				
				NSRange rang;
				rang.location = i;
				rang.length = 1;
				NSString *chars = [pContent substringWithRange:rang];
				pen.string = chars;
				
				float tWidth = pen.contentSize.width;
				float tHeight = pen.contentSize.height > rowH ? pen.contentSize.height : rowH;
				
				if ((drawX + tWidth) > viewSize.width) {
					[heights addObject:[NSNumber numberWithInt:drawHeight]];
					drawX = 0 ;
					drawHeight = 0;
				}
				
				if (tHeight > drawHeight) {
					drawHeight = tHeight;
				}
				
				drawX += tWidth;
			}
		}
	}
	
	[heights addObject:[NSNumber numberWithInt:drawHeight]];
	
	return heights;
	
}
*/
static inline CCSprite* stringSprite(NSString* content ,
									 NSString* font,
									 NSString* color,
									 CGSize viewSize,
									 int fontSize,
									 int rowH,
									 BOOL isDouble){
	
	/*
	CGSize defaultSize = [CCDirector sharedDirector].winSize;
	CCRenderTexture* result = [CCRenderTexture renderTextureWithWidth:defaultSize.width height:defaultSize.height];
	CCLabelTTF *pen = [CCLabelTTF labelWithString:@"" fontName:font fontSize:fontSize];
	pen.verticalAlignment = kCCVerticalTextAlignmentCenter;
	pen.horizontalAlignment = kCCTextAlignmentLeft;
	pen.anchorPoint = ccp(0, 0);
	
	float paintX = 0;
	float paintY = defaultSize.height - cFixedScale(2);
	
	NSMutableArray *emopos=[NSMutableArray array];
	NSMutableDictionary* eventDict = [NSMutableDictionary dictionary];
	
	[result begin];
	
	NSDictionary* css = getParseSetting(0);
	NSArray* lines = [content componentsSeparatedByString:[css objectForKey:@"tr"]];
	for (NSString *lineContent in lines) {
		if ([lineContent hasPrefix:[css objectForKey:@"bl"]]) {
			if (lineContent.length > 1) {
				NSString *strValue = [lineContent substringFromIndex:1];
				int iValue = [strValue intValue];
				paintX = 0 ;
				paintY -= iValue;
			}else{
				paintX = 0 ;
				paintY -= rowH;
			}
			continue ;
		}
		
		NSMutableArray* heights = [NSMutableArray arrayWithArray:getLineHight(lineContent, font, color, viewSize, fontSize, rowH)];
		NSArray* tds = [lineContent componentsSeparatedByString:[css objectForKey:@"td"]];
		int drawHeight = rowH;
		if (heights != nil && heights.count > 0) {
			NSNumber* number = [heights objectAtIndex:0];
			drawHeight = [number intValue];
			[heights removeObjectAtIndex:0];
		}
		
		paintX = 0 ;
		paintY -= drawHeight;
		
		for (NSString* td in tds) {
			NSArray* objs = [td componentsSeparatedByString:[css objectForKey:@"cell"]];
			NSString* pEvent = getPaintEventContent(objs);
			NSString* pContent = getPaintContent(objs);
			pen.fontName = getPaintFontName(objs, font);
			pen.fontSize = getPaintFontSize(objs, fontSize);
			pen.color = getPaintFontColor(objs, color);
			
			float eventX = paintX ;
			float eventY = paintY ;
			
			float eventWidth = 0;
			float eventHeight = 0;
			
			NSMutableArray* eventRects = [NSMutableArray array];
			
			if (pContent != nil) {
				int length = pContent.length;
				for (int i = 0 ; i < length ; i++){
					NSString* iconStr = checkDrawImage(pContent, i);
					if (iconStr != nil) {
						i = i + iconStr.length - 1;
						int amiIndex = getDrawImageId(iconStr);
						float tWidth = getDrawImageRect(amiIndex).width;
						
						if ((paintX + tWidth) > viewSize.width) {
							
							paintX = 0 ;
							
							if (pEvent != nil) {
								NSValue* value = [NSValue valueWithCGRect:CGRectMake(eventX, eventY, eventWidth, eventHeight)];
								[eventRects addObject:value];
							}
							
							
							if (heights != nil && heights.count > 0) {
								NSNumber* number = [heights objectAtIndex:0];
								drawHeight = [number intValue];
								[heights removeObjectAtIndex:0];
							}else{
								drawHeight = rowH ;
							}
							
							paintY -= drawHeight;
							
							if (pEvent != nil) {
								eventX = paintX;
								eventY = paintY;
								eventWidth = 0;
								eventHeight = drawHeight;
							}
						}
						
						NSMutableDictionary *dict=[NSMutableDictionary dictionary];
						[dict setObject:[NSNumber numberWithFloat:(paintX + tWidth/2)] forKey:@"XX"];
						[dict setObject:[NSNumber numberWithFloat:(paintY)] forKey:@"YY"];
						[dict setObject:[NSNumber numberWithFloat:amiIndex] forKey:@"amiid"];
						[emopos addObject:dict];
						paintX += tWidth;
						
						if (pEvent != nil) {
							eventWidth += tWidth;
							eventHeight = drawHeight;
						}
						
						continue;
					}
					
					NSRange rang;
					rang.location = i;
					rang.length = 1;
					NSString *chars = [pContent substringWithRange:rang];
					pen.string = chars;
					
					float tWidth = pen.contentSize.width;
					
					if ((paintX + tWidth) > viewSize.width) {
						paintX = 0 ;
						
						if (pEvent != nil) {
							NSValue* value = [NSValue valueWithCGRect:CGRectMake(eventX, eventY, eventWidth, eventHeight)];
							[eventRects addObject:value];
						}
						
						if (heights != nil && heights.count > 0) {
							NSNumber* number = [heights objectAtIndex:0];
							drawHeight = [number intValue];
							[heights removeObjectAtIndex:0];
						}else{
							drawHeight = rowH ;
						}
						paintY -= drawHeight;
						
						if (pEvent != nil) {
							eventX = paintX;
							eventY = paintY;
							eventWidth = 0;
							eventHeight = drawHeight;
						}
					}
					
					pen.position = ccp(paintX, paintY + cFixedScale(2));
					paintX += tWidth;
					
					if (pEvent != nil) {
						eventWidth += tWidth;
						eventHeight = drawHeight;
					}
					
					[pen visit];
				}
			}
			
			if (pEvent != nil) {
				NSValue* value = [NSValue valueWithCGRect:CGRectMake(eventX, eventY, eventWidth, eventHeight)];
				[eventRects addObject:value];
			}
			
			if (pEvent != nil) {
				//颜色并上事件的字符串
				NSString* colorStr = getHexStringWithColor3B(pen.color);
				NSString* key = [NSString stringWithFormat:@"%@:::%@",pEvent,colorStr];
				[eventDict setObject:eventRects forKey:key];
			}
		}
	}
	[result end];
	
	CGRect rect = CGRectMake(0, paintY, viewSize.width, defaultSize.height - paintY);
	CCSprite *spr=[CCSprite spriteWithTexture:result.sprite.texture rect:rect];
	[spr setFlipY:YES];
	
	BrowLayer* browLayer = [BrowLayer create:spr.contentSize array:emopos clip:paintY];
	if (browLayer != nil) {
		[spr addChild:browLayer];
	}
	
	EventLayer* layer = [EventLayer create:spr.contentSize clip:paintY];
	if (layer != nil) {
		[layer addMemuItem:eventDict];
		[spr addChild:layer];
	}
	
	return spr;

	*/
	
	StringSprite* spr = [StringSprite create:content
									fontName:font
									   color:color
										size:viewSize
									fontSize:fontSize
										 row:rowH
									wrapping:isDouble];
	return spr;
}

//------------------------------------------------------------------------------

static inline CCSprite* drawStringForEvent(NSString *message ,CGSize size ,NSString *font , int fontSize , int lineH,NSString *_color){
	int maxHigth=512;
	float linehigth=0;
	bool isMoreLine=false;
	int lineCount=1;
	lineH=cFixedScale(lineH);
	
	int posxy[4][2]={{0,1},{1,0},{-1,0},{0,-1}};
	
	if(message.length>1000){
		message=[message substringToIndex:1000];
	}
	
	NSMutableArray *emopos=[NSMutableArray array];
    NSMutableArray *underline=[NSMutableArray array];
	size=CGSizeMake(cFixedScale(size.width), maxHigth);
	CCRenderTexture *target = [CCRenderTexture renderTextureWithWidth:size.width height:size.height];
	
	target.position=ccp(size.width/2, size.height/2);
	
	
	CCLabelTTF *label = [CCLabelTTF labelWithString:@"" fontName:font fontSize:fontSize];
	label.anchorPoint =ccp(0, 0);
	
	int _x = 0 ;
	int _y = size.height - lineH;
	int _w = 0;
	[target begin];
	
	NSArray *partArray = [message componentsSeparatedByString:@"*"];
	for (NSString *partContent in partArray) {
		
		if (partContent.length > 0) {
			NSString *finder = [NSString stringWithFormat:@"^"];
			NSRange strHead;
			strHead.length = 1;
			strHead.location = 0;
			NSString *firstStr = [partContent substringWithRange:strHead];
			if ([finder isEqualToString:firstStr]) {
				if (partContent.length == 1) {
					_x = 0 ;
					_y -= lineH;
					linehigth+=lineH;
				}
				else {
					NSString *strValue = [partContent substringFromIndex:1];
					int iValue = [strValue intValue];
					_x = 0 ;
					_y -= (lineH+iValue);
					linehigth+=(lineH+iValue);
				}
			}
			else {
				NSArray *strArray = [partContent componentsSeparatedByString:@"|"];
				for (NSString *iteater in strArray) {
					NSArray *parts = [iteater componentsSeparatedByString:@"#"];
					NSString *strContent = nil;
					NSString *strColor = nil;
					NSString *strFontName = nil;
					NSString *strFontSize = nil;
					NSString *eventVar=nil;
					switch (parts.count) {
						case 1:{
							strContent = [NSString stringWithFormat:@"%@",[parts objectAtIndex:0]];
						}
							break;
						case 2:{
							strContent = [NSString stringWithFormat:@"%@",[parts objectAtIndex:0]];
							strColor = [NSString stringWithFormat:@"%@",[parts objectAtIndex:1]];
						}
							break;
						case 3:{
							strContent = [NSString stringWithFormat:@"%@",[parts objectAtIndex:0]];
							strColor = [NSString stringWithFormat:@"%@",[parts objectAtIndex:1]];
							strFontSize =[NSString stringWithFormat:@"%@",[parts objectAtIndex:2]];
						}
							break;
						case 4:{
							strContent = [NSString stringWithFormat:@"%@",[parts objectAtIndex:0]];
							strColor = [NSString stringWithFormat:@"%@",[parts objectAtIndex:1]];
							strFontSize = [NSString stringWithFormat:@"%@",[parts objectAtIndex:2]];
							strFontName = [NSString stringWithFormat:@"%@",[parts objectAtIndex:3]];
						}
							break;
						case 5:{
							strContent = [NSString stringWithFormat:@"%@",[parts objectAtIndex:0]];
							strColor = [NSString stringWithFormat:@"%@",[parts objectAtIndex:1]];
							strFontSize = [NSString stringWithFormat:@"%@",[parts objectAtIndex:2]];
							strFontName = [NSString stringWithFormat:@"%@",[parts objectAtIndex:3]];
							eventVar=[NSString stringWithFormat:@"%@",[parts objectAtIndex:4]];
						}
						default:
							break;
					}
					
					if (strContent) {
						if (!strColor) {
							if (!_color) {
								_color=[NSString stringWithFormat:@"ffffff"];
							}
							strColor=[NSString stringWithFormat:@"%@",_color];
						}
						if (!strFontName) {
							strFontName=[NSString stringWithFormat:@"%@",font];
						}
						else {
							strFontName=getCommonFontName([strFontName intValue]);
						}
						if (!strFontSize) {
							strFontSize=[NSString stringWithFormat:@"%d",fontSize];
						}
						label.fontName=strFontName;
						
						label.color = color3BWithHexString(strColor);
						
						
						label.fontSize=cFixedScale([strFontSize intValue]);
						
						
						int count = [strContent length];
						
						for (int i = 0; i < count; i++) {
							NSRange rang;
							rang.location = i;
							rang.length = 1;
							NSString *chars = [strContent substringWithRange:rang];
							
							if([chars isEqualToString:@"{"] && (i+4)<count){
								rang.length=5;
								NSString *emo = [strContent substringWithRange:rang];
								NSString *head=[emo substringToIndex:2];
								NSString *end=[emo substringFromIndex:4];
								
								if([head isEqualToString:@"{!"] && [end isEqualToString:@"}"]){
									NSRange indexValue;
									indexValue.location=2;
									indexValue.length=2;
									int amiIndex=[[emo substringWithRange:indexValue]integerValue];
									//CCLOG(@"%@ head:%@ end:%@ ami:%i",emo,head,end,amiIndex);
									if(amiIndex!=0){
										_w=_x;
										if(_x+cFixedScale(22)>size.width){
											_x = 0 ;
											_y -= label.contentSize.height;
											linehigth+=label.contentSize.height;
											isMoreLine=true;
											lineCount++;
										}
										NSMutableDictionary *dict=[NSMutableDictionary dictionary];
										[dict setObject:[NSNumber numberWithFloat:_x] forKey:@"XX"];
										[dict setObject:[NSNumber numberWithFloat:lineCount] forKey:@"YY"];
										[dict setObject:[NSNumber numberWithFloat:amiIndex] forKey:@"amiid"];
										[emopos addObject:dict];
										_x+=cFixedScale(22);
										_w+=cFixedScale(22);
										i+=4;
										continue;
									}
								}
							}
							
							
							label.string=chars;
							
							if(linehigth==0){
								linehigth=label.contentSize.height;
							}
							if ((_x + label.fontSize) > size.width) {
								_x = 0 ;
								_y -= label.contentSize.height;
								linehigth+=label.contentSize.height;
								isMoreLine=true;
								lineCount++;
							}
                            if(![eventVar isEqual:nil] &&  [eventVar length]>3){
								NSString *NofName= [eventVar substringToIndex:3];
                                NSString *Nofcontent=[eventVar substringFromIndex:3];
                                CCLayerColor *line=[CCLayerColor layerWithColor:ccc4(label.color.r, label.color.g, label.color.b, 255) width:label.contentSize.width height:1];
								CCMenu *m=[CCMenu menuWithArray:nil];
								CCMenuItem *ccmi=[CCMenuItem itemWithBlock:^(id sender){
									[GameConnection post:NofName object:Nofcontent];
								}];
								[ccmi setAnchorPoint:ccp(0,0)];
								[ccmi setContentSize:CGSizeMake(label.contentSize.width, label.contentSize.height)];
								[m addChild:ccmi];
								[m setPosition:ccp(0, 0)];
								[line addChild:m];
                                NSMutableDictionary *dict=[NSMutableDictionary dictionary];
                                [dict setObject:[NSNumber numberWithFloat:_x] forKey:@"XX"];
                                [dict setObject:[NSNumber numberWithFloat:_y] forKey:@"YY"];
                                [dict setObject:line forKey:@"line"];
                                [underline addObject:dict];
							}
							
							for(int i=0;i<4;i++){
								label.position=ccp(_x+posxy[i][0],_y+posxy[i][1]);
								[label setColor:ccc3(0, 0, 0)];
								[label visit];
							}
							label.position=ccp(_x, _y);
							label.color = color3BWithHexString(strColor);
							[label visit];
							
							_x += label.contentSize.width;
							if (_w < size.width) {
								_w += label.contentSize.width;
							}
							
						}
					}
				}
				_x = 0 ;
				_y -= lineH;
				linehigth+=lineH;
			}
		}
	}
	
	[target end];
	if (_w > size.width) {
		_w = size.width;
	}
	linehigth-=lineH;
	linehigth=linehigth>maxHigth?maxHigth:linehigth;
	
	int outputWidth=isMoreLine?size.width:_w;
	int outputlinehigth=linehigth;
	int outCropHight=maxHigth-linehigth;
	
	
	
	CCSprite *spr=[CCSprite spriteWithTexture:target.sprite.texture rect:CGRectMake(0, outCropHight, outputWidth, outputlinehigth)];
	[spr setFlipY:YES];
	
	//输出表情
	for(NSDictionary *dict in emopos){
		int X=[[dict objectForKey:@"XX"]integerValue];
		int Y=[[dict objectForKey:@"YY"]integerValue];
		int amiId=[[dict objectForKey:@"amiid"]integerValue];
		CCSprite *emo=[CCSprite spriteWithSpriteFrameName:[NSString stringWithFormat:@"face%i_1.png",amiId]];
		NSMutableArray *amiarry=[NSMutableArray array];
		for(int d=0;d<INT16_MAX;d++){
			CCSpriteFrame *f1=[[CCSpriteFrameCache sharedSpriteFrameCache]spriteFrameByName:[NSString stringWithFormat:@"face%i_%i.png",amiId,d+1]];
			if(!f1){
				break;
			}else{
				[amiarry addObject:f1];
			}
		}
		CCAnimation *c1=[CCAnimation animationWithSpriteFrames:amiarry delay:0.1];
		CCAnimate* animate = [CCAnimate actionWithAnimation:c1];
		CCSequence *seq = [CCSequence actions:animate,nil];
        CCRepeatForever* repeat = [CCRepeatForever actionWithAction:seq];
        [emo runAction:repeat];
		[emo setAnchorPoint:ccp(0, 0)];
		Y=(abs(Y-lineCount))*cFixedScale(23);
		[emo setPosition:ccp(X, Y+cFixedScale(5))];
		[spr addChild:emo];
	}
	
	//输出事件
    for(NSDictionary *dict in underline){
        int X=[[dict objectForKey:@"XX"]integerValue];
		int Y=[[dict objectForKey:@"YY"]integerValue];
        CCLayerColor *uline=[dict objectForKey:@"line"];
		
		if(iPhoneRuningOnGame()){
			[uline setPosition:ccp(X, Y-(outputlinehigth+outCropHight)+(512-outCropHight)-2)];
		}else{
			[uline setPosition:ccp(X, Y-(outputlinehigth+outCropHight)+(512-outCropHight))];
		}
        [spr addChild:uline];
    }
	return spr;
}


/*
 * message 结构字符串 (|标记特殊处理字符 *分段处理 ^空行处理)
 * size 大小
 * font 默认字体名
 * fontSize 默认字体大小
 * lineH 默认行距
 */
static inline CCSprite* drawString(NSString *message ,CGSize size ,NSString *font , int fontSize , int lineH,NSString *_color)
{
	//CCSprite *spr=drawStringForEvent(message, size, font, fontSize, lineH, _color);
	CCSprite *spr= stringSprite(message, font, _color, size, fontSize, lineH, YES);
	return spr;
}

#pragma mark begin
#pragma mark 通过ID获得图像
//-----------------------------------------------------------------------------------
//游戏的通用Icon 读取方法
//对应 装备 武器 物品 角色头像等等.....
//
//-----------------------------------------------------------------------------------

static inline CCSprite* getCharacterIcon(int roleID , ICON_HEAD_TYPE type){
	return [RoleIconViewerContent create:roleID type:type];
}

static inline CCSprite* getItemIcon(int itemID){
	if (itemID <= 0) {
		CCLOG(@"getItemIcon->%d",itemID);
		return [CCSprite node];
	}
	
	return [ItemIconViewerContent create:itemID];
	
	/*
	 if (itemID <= 0) {
	 return nil;
	 }
	 NSString *path = [NSString stringWithFormat:@"images/ui/item/item%d.png",itemID];
	 CCSprite *spr = [CCSprite spriteWithFile:path];
	 return spr;
	 */
}

static inline CCSprite* getFateIconWithQa(int fateID,int qa){
	return [FateIconViewerContent create:fateID quality:qa];
	//CCSprite *spr = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/fate/soul%d.png",fateID]];
	//return spr;
}


static inline CCSprite* getFateIcon(int fateID){
	return [FateIconViewerContent create:fateID];
	//CCSprite *spr = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/fate/soul%d.png",fateID]];
	//return spr;
}

static inline CCSprite* getTMemberIcon(int wid)
{
	if (wid == 0) {
		CCLOG(@"getEquipmentIcon is null by id=%d",wid);
		return nil;
	}
	if (wid >= 1 && wid <= 25000) {
		//[CCFileUtils sharedFileUtils]
		//if(cc)
		CCSprite *spr=nil;
		NSString *path=[NSString stringWithFormat:@"images/ui/panel/t%i.png",wid];
		path=[[CCFileUtils sharedFileUtils]fullPathFromRelativePath:path];
		if([[NSFileManager defaultManager] fileExistsAtPath:path]){
			spr = [CCSprite spriteWithFile:path];
		}else{
			spr = [CCSprite spriteWithFile:@"images/ui/panel/t31.png"];
		}
#ifdef GAME_DEBUGGER
		CCLabelTTF *label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"id=%d",wid] fontName:@"Verdana-Bold" fontSize:22];
		label.color = ccc3(255, 0, 0);
		[label setVerticalAlignment:kCCVerticalTextAlignmentCenter];
		[label setHorizontalAlignment:kCCTextAlignmentCenter];
		label.position=ccp(spr.contentSize.width/2, spr.contentSize.height/2);
		[spr addChild:label];
#endif
		return spr;
	}
	return nil;
}


static inline CCSprite* getCarIcon(int wid)
{
	if (wid == 0) {
		CCLOG(@"getEquipmentIcon is null by id=%d",wid);
		return nil;
	}
	if (wid >= 1 && wid <= 100) {
		CCSprite *spr = [CCSprite spriteWithFile:@"images/ui/panel/t31.png"];
#ifdef GAME_DEBUGGER
		CCLabelTTF *label = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"id=%d",wid] fontName:@"Verdana-Bold" fontSize:22];
		label.color = ccc3(255, 0, 0);
		[label setVerticalAlignment:kCCVerticalTextAlignmentCenter];
		[label setHorizontalAlignment:kCCTextAlignmentCenter];
		label.position=ccp(spr.contentSize.width/2, spr.contentSize.height/2);
		[spr addChild:label];
#endif
		return spr;
	}
	return nil;
}

static inline CCSprite* getEquipmentIcon(int wid){
	return [EquipmentIconViewerContent create:wid];
	/*
	 if (wid == 0) {
	 CCLOG(@"getEquipmentIcon is null by id=%d",wid);
	 return nil;
	 }else{
	 NSString *path = [NSString stringWithFormat:@"images/ui/equipment/equip%d.png",wid];
	 CCSprite *spr = [CCSprite spriteWithFile:path];
	 return spr;
	 }
	 return nil;
	 */
}

/*
 * 获得角色头像
 */
static inline CCSprite* getCharacterMixIcon(int iconID,bool big)
{
	CCSprite* background ;
	if (big) {
		background = [CCSprite spriteWithFile:@"images/ui/characterIcon/big.png"];
	}
	else {
		background = [CCSprite spriteWithFile:@"images/ui/characterIcon/small.png"];
	}
	//NSString *str = findCharacterIcon(iconID);
	//if (str) {
	CCSprite* icon = getCharacterIcon(iconID, ICON_PLAYER_BIG); //[CCSprite spriteWithFile:str];
	if (icon) {
		icon.anchorPoint = ccp(0.5f,0);
		[background addChild:icon];
		icon.position = ccp(background.contentSize.width/2, 0);
	}
	else {
		CCLOG(@"can't create character icon");
	}
	//	}
	//	else {
	//		CCLOG(@"can't find character icon in getCharacterMixIcon");
	//	}
	
	return background;
}


/*
 * 获得头像的按钮组
 */
static inline NSArray * getCharacterIconBtns(int iconID,bool big){
	
	CCSprite * pass1 = getCharacterMixIcon(iconID,big);
	CCSprite * pass2 = getCharacterMixIcon(iconID,big);
	float scale = 1.1f;
	pass2.scale = scale;
	
	CCSprite * passBtn1 = [CCSprite node];
	[passBtn1 addChild:pass1];
	
	pass1.anchorPoint = ccp(0,0);
	pass1.position = ccp(pass1.contentSize.width*((scale-1)/2),pass1.contentSize.height*((scale-1)/2));
	passBtn1.contentSize = CGSizeMake(pass2.contentSize.width*scale, pass2.contentSize.height*scale);
	
	return [NSArray arrayWithObjects:passBtn1,pass2,nil];
}

/*
 *CCLabelFX在垂直对齐的时候有些小问题
 *待修改，这里提供一个过度函数开发使用
 *Soul
 */
static inline void spriteChangScale(CCSprite* spr,float scale)
{
	if (!spr) {
		return;
	}
	spr.scale = scale;
	spr.position = ccp( -spr.contentSize.width*((scale-1)/2),-spr.contentSize.height*((scale-1)/2) );
	spr.contentSize = CGSizeMake(spr.contentSize.width*scale, spr.contentSize.height*scale);
	
}

static inline void setCCLabelFXPositionAdjust(CCLabelTTF *label,CGPoint pt)
{
	//CGSize lSize = [label dimensions];
	float fSize = [label fontSize];
	//float gapY = (lSize.height - fSize)/2;
	label.position = ccp(pt.x, pt.y - fSize/4) ;
	//[label setPosition:ccp(pt.x, pt.y - fSize/4)];
}

static inline NSArray * getLabelSpritesWith(NSString* path1,NSString *path2, NSString* label, NSString *fontName,float fontSize ,ccColor4B c1,ccColor4B c2)
{
	CCSprite *spr1 = [CCSprite spriteWithFile:path1]; //正常状态
	CCSprite *spr2 = [CCSprite spriteWithFile:path2]; //点击状态
	
	CCLabelTTF *label1 = [CCLabelTTF labelWithString:label fontName:fontName fontSize:fontSize];
	[label1 setColor:ccc3(c1.r, c1.g, c1.b)];
	CCLabelTTF *label2 = [CCLabelTTF labelWithString:label fontName:fontName fontSize:fontSize];
	[label2 setColor:ccc3(c2.r, c2.g, c2.b)];
	
	CGSize size = spr1.contentSize;
	
	label1.position = ccp(size.width/2, size.height/2);
	label2.position = ccp(size.width/2, size.height/2);
	
	
	[spr1 addChild:label1];
	[spr2 addChild:label2];
	spriteChangScale(spr2,1.1f);
	return [NSArray arrayWithObjects:spr1,spr2,nil];
}

static inline NSArray * getLabelSprites(NSString* path1,NSString *path2, NSString* label,float fontSize ,ccColor4B c1,ccColor4B c2)
{
	return getLabelSpritesWith(path1, path2, label, @"Verdana-Bold", fontSize, c1, c2);
}

static inline NSArray * getToggleSpritesWith(NSString* path1,NSString *path2, NSString* label, NSString *fontName,float fontSize ,ccColor4B c1,ccColor4B c2)
{
	CCSprite *spr1 = [CCSprite spriteWithFile:path1]; //正常状态
	CCSprite *spr2 = [CCSprite spriteWithFile:path1]; //点击状态
	CCSprite *spr3 = [CCSprite spriteWithFile:path2]; //点击状态
	[spr2 addChild:spr3];
	
	CCLabelTTF *label1 = [CCLabelTTF labelWithString:label fontName:fontName fontSize:fontSize];
	[label1 setColor:ccc3(c1.r, c1.g, c1.b)];
	CCLabelTTF *label2 = [CCLabelTTF labelWithString:label fontName:fontName fontSize:fontSize];
	[label2 setColor:ccc3(c2.r, c2.g, c2.b)];
	
	CGSize size = spr1.contentSize;
	spr3.position = ccp(size.width/2, size.height/2);
	label1.position = ccp(size.width+label1.contentSize.width/2, size.height/2);
	label2.position = ccp(size.width+label2.contentSize.width/2, size.height/2);
	[spr1 addChild:label1];
	[spr2 addChild:label2];
	size.width = spr1.contentSize.width+label1.contentSize.width;
	size.height = spr1.contentSize.height>label1.contentSize.height?spr1.contentSize.height:label1.contentSize.height;
	
	
	spr1.contentSize = size;
	spr2.contentSize = size;
	return [NSArray arrayWithObjects:spr1,spr2,nil];
}

static inline NSArray * getToggleSprites(NSString* path1,NSString *path2, NSString* label,float fontSize ,ccColor4B c1,ccColor4B c2)
{
	
	return getToggleSpritesWith(path1, path2, label, @"Verdana-Bold", fontSize, c1, c2);
}
static inline NSArray * getToggleButton(NSString* path1,NSString *path2, NSString* label,float fontSize ,ccColor4B c1,ccColor4B c2)
{
	NSArray *sprArr = getLabelSprites(path1,path2,label,fontSize,c1,c2 );
	CCMenuItemSprite *spr01 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:0] selectedSprite:nil];
	CCMenuItemSprite *spr02 = [CCMenuItemSprite itemWithNormalSprite:[sprArr objectAtIndex:1] selectedSprite:nil];
	return [NSArray arrayWithObjects:spr01,spr02,nil];
}
static inline CCLabelTTF* getButtonLabel(BUTTON_LABEL_TYPE _type)
{
	CCLabelTTF *label = nil;
	switch (_type) {
		case BUTTON_LABEL_1:{
			label = [CCLabelTTF labelWithString:@"" fontName: @"Verdana-Bold" fontSize:16];
			label.color = ccc3(65,197,186);
		}break;
		case BUTTON_LABEL_2:{
			
		}break;
		case BUTTON_LABEL_3:{
			
		}break;
		default:
			break;
	}
	return label;
}

static inline CCSprite* getSpriteWithPathArray(NSArray *pathArray)
{
	CCSprite *spr = [CCSprite node];
	CCSprite *t_spr;
	CGSize size;
	NSMutableArray *sprArray = nil;
	sprArray = [NSMutableArray array];
	for (NSString *fileName in pathArray) {
		t_spr = [CCSprite spriteWithFile:fileName];
		[sprArray addObject:t_spr];
		if (size.width<t_spr.contentSize.width) {
			size.width = t_spr.contentSize.width;
		}
		if (size.height<t_spr.contentSize.height) {
			size.height = t_spr.contentSize.height;
		}
	}
	if (sprArray) {
		spr.contentSize = size;
		for (CCSprite* addSpr in sprArray) {
			[spr addChild:addSpr];
			addSpr.position = ccp(spr.contentSize.width/2,spr.contentSize.height/2);
		}
		return spr;
	}
	
	return nil;
}
static inline CCSprite* getSpriteWithSpriteAndNewSize(CCSprite* spr,CGSize newSize){
	if (!spr) {
		return nil;
	}
	float scale_x = newSize.width/spr.contentSize.width;
	float scale_y = newSize.height/spr.contentSize.height;
	spr.scaleX = scale_x;
	spr.scaleY = scale_y;
	CCSprite *newSpr = [CCSprite node];
	newSpr.contentSize = newSize;
	[newSpr addChild:spr];
	spr.position = ccp(newSize.width/2,newSize.height/2);
	return newSpr;
}
static inline CCSprite* getSpriteWithFiles(NSString* path,...)
{
	va_list args;
	va_start(args, path);
	NSMutableArray *pathArray = nil;
	if (path) {
		pathArray = [NSMutableArray arrayWithObject:path];
		NSString *str = va_arg(args, NSString*);
		while (str) {
			[pathArray addObject:str];
			str = va_arg(args, NSString*);
		}
	}
	va_end(args);
	return getSpriteWithPathArray(pathArray);
}

static inline ccColor3B getColorByLevel(int level)
{
	return ccc3(0, 255, 0);
}

static inline CCMenuItemImage *makeMenuItemImageBtn(NSString* imgPath,float scale,id target,SEL select){
	NSArray * btns = getBtnSpriteForScale(imgPath,1.1f);
	CCMenuItemImage *re_btn = [CCMenuItemImage itemWithNormalSprite:[btns objectAtIndex:0]
													 selectedSprite:[btns objectAtIndex:1]
													 disabledSprite:nil
															 target:target
														   selector:select];
	return re_btn;
}

//描边字
static inline CCRenderTexture* createStroke(CCLabelTTF* label,float size ,ccColor3B cor){
	CCRenderTexture* rt = [CCRenderTexture renderTextureWithWidth:label.contentSize.width+size*2  height:label.contentSize.height+size*2];
	CGPoint originalPos = [label position];
	ccColor3B originalColor = [label color];
	BOOL originalVisibility = [label visible];
	[label setColor:cor];
	[label setVisible:YES];
	ccBlendFunc originalBlend = [label blendFunc];
	[label setBlendFunc:(ccBlendFunc) { GL_SRC_ALPHA, GL_ONE }];
	CGPoint bottomLeft = ccp(label.contentSize.width * label.anchorPoint.x + size, label.contentSize.height * label.anchorPoint.y + size);
	CGPoint positionOffset = ccp(label.contentSize.width * label.anchorPoint.x - label.contentSize.width/2,label.contentSize.height * label.anchorPoint.y - label.contentSize.height/2);
	CGPoint position = ccpSub(originalPos, positionOffset);
	[rt begin];
	for (int i=0; i<360; i+=15) // you should optimize that for your needs
	{
		[label setPosition:ccp(bottomLeft.x + sin(CC_DEGREES_TO_RADIANS(i))*size, bottomLeft.y + cos(CC_DEGREES_TO_RADIANS(i))*size)];
		[label visit];
	}
	[rt end];
	[label setPosition:originalPos];
	[label setColor:originalColor];
	[label setBlendFunc:originalBlend];
	[label setVisible:originalVisibility];
	[rt setPosition:position];
	return rt;
}

static inline void addTargetToCenter(CCNode *target ,CCNode *obj,int tag){
	[target setPosition:ccp(obj.contentSize.width/2,obj.contentSize.height/2)];
	if(tag){
		[target setTag:tag];
	}
	[obj addChild:target];
}
//=============================================================
// 背景
static inline NSArray *getRecruitBackground(int qid)
{
    if (qid >= 2 && qid <= 4) {
        CCSprite *bg1 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/panel/recruit_itembg_%d_1.png", qid]];
        CCSprite *bg2 = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/panel/recruit_itembg_%d_2.png", qid]];
        return [NSArray arrayWithObjects:bg1, bg2, nil];
    }
    CCSprite *bg1 = [CCSprite spriteWithFile:@"images/ui/panel/recruit_itembg_1_1.png"];
    CCSprite *bg2 = [CCSprite spriteWithFile:@"images/ui/panel/recruit_itembg_1_2.png"];
    return [NSArray arrayWithObjects:bg1, bg2, nil];
}

// 头像
/*
 static inline CCSprite* getRecruitIcon(int roleID){
 // roleId为0时为隐藏图片
 CCSprite *icon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/characterIcon/recruit_icon/player_dj_%d.png", roleID]];
 if (!icon) {
 icon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/characterIcon/recruit_icon/player_dj_%d.png", 0]];
 }
 return icon;
 }
 static inline CCSprite* getRecruitHideIcon(int roleID)
 {
 // roleId为0时为隐藏图片
 CCSprite *icon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/characterIcon/recruit_icon/player_dj_%d_1.png", roleID]];
 if (!icon) {
 icon = [CCSprite spriteWithFile:[NSString stringWithFormat:@"images/ui/characterIcon/recruit_icon/player_dj_%d.png", 0]];
 }
 return icon;
 }
 */

// 职业
static inline CCSprite *getOfficeIcon(NSString *office)
{
    CCSprite *icon = nil;
    /*
	 if ([office isEqualToString:@"修罗"]) {
	 icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job1.png"];
	 } else if ([office isEqualToString:@"夜叉"]) {
	 icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job2.png"];
	 } else if ([office isEqualToString:@"迦楼罗"]) {
	 icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job3.png"];
	 } else if ([office isEqualToString:@"摩呼罗迦"]) {
	 icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job4.png"];
	 } else if ([office isEqualToString:@"乾闼婆"]) {
	 icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job5.png"];
	 } else if ([office isEqualToString:@"龙众"]) {
	 icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job6.png"];
	 } else if ([office isEqualToString:@"紧那罗"]) {
	 icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job7.png"];
	 } else if ([office isEqualToString:@"天众"]) {
	 icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job8.png"];
	 }
     */
    if ([office isEqualToString:NSLocalizedString(@"config_job_1",nil)]) {
        icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job1.png"];
    } else if ([office isEqualToString:NSLocalizedString(@"config_job_2",nil)]) {
        icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job2.png"];
    } else if ([office isEqualToString:NSLocalizedString(@"config_job_3",nil)]) {
        icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job3.png"];
    } else if ([office isEqualToString:NSLocalizedString(@"config_job_4",nil)]) {
        icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job4.png"];
    } else if ([office isEqualToString:NSLocalizedString(@"config_job_5",nil)]) {
        icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job5.png"];
    } else if ([office isEqualToString:NSLocalizedString(@"config_job_6",nil)]) {
        icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job6.png"];
    } else if ([office isEqualToString:NSLocalizedString(@"config_job_7",nil)]) {
        icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job7.png"];
    } else if ([office isEqualToString:NSLocalizedString(@"config_job_8",nil)]) {
        icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job8.png"];
    }
    
    if (Nil == icon) {
        CCLOG(@"getOfficeIcon %@ is nil", office);
        icon = [CCSprite spriteWithFile:@"images/ui/panel/recruit_job1.png"];
    }
    return icon;
}

static inline NSDictionary * getFormatToDict(NSString*value){
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	NSArray * ary1 = [value componentsSeparatedByString:@"|"];
	for(NSString * str in ary1){
		NSArray * ary2 = [str componentsSeparatedByString:@":"];
		if([ary2 count]>1){
			[result setObject:[ary2 objectAtIndex:1] forKey:[ary2 objectAtIndex:0]];
		}
	}
	return result;
}

//获取品质颜色
static inline NSString *getQualityColorStr(int qa){
	NSDictionary *colors=getFormatToDict([[[GameDB shared]getGlobalConfig]objectForKey:@"qcolors"]);
	return [colors objectForKey:[NSString stringWithFormat:@"%i",qa]];
}
//fix chao 防跳动描边字
#define DBS_SIDE_W (1.2)
static inline CCSprite* drawBoundString( NSString *_string,int _side ,NSString *_fName ,int _size ,ccColor3B _c1 ,ccColor3B _bgc2){
	if (_string) {
		CCLabelTTF *label = [CCLabelTTF labelWithString:_string fontName:_fName fontSize:_size];
		float _w = label.contentSize.width;
		float _h = label.contentSize.height;
		_w = _w/2;
		_w = _w*2;
		_h = _h/2;
		_h = _h*2;
		
		if(_w==0 || _h==0){
			return [CCSprite node];
		}
		
		CCRenderTexture *render = [CCRenderTexture renderTextureWithWidth:_w height:_h];
		float _x = label.contentSize.width/2;
		float _y = label.contentSize.height/2;
		
		CGPoint pt[] = {{DBS_SIDE_W,0},{0,-DBS_SIDE_W},{-DBS_SIDE_W,0},{0,DBS_SIDE_W},{DBS_SIDE_W,DBS_SIDE_W},{-DBS_SIDE_W,DBS_SIDE_W},{-DBS_SIDE_W,-DBS_SIDE_W},{DBS_SIDE_W,-DBS_SIDE_W}};
		[render begin];
		if (_side>sizeof(pt)/sizeof(pt[0])) {
			_side = sizeof(pt)/sizeof(pt[0]);
		}
		for (int i = 0; i< _side; i++) {
			CGPoint temp = pt[i];
			label.color = _bgc2;
			label.position=ccpAdd(ccp(_x, _y), temp);
			[label visit];
		}
		label.color = _c1;
		label.position=ccp(_x, _y);
		[label visit];
		[render end];
		
		CCSprite *spr = [CCSprite node];
		[spr addChild:render];
		render.position = ccp(label.contentSize.width/2,label.contentSize.height/2);
		spr.contentSize = label.contentSize;
		
		if(iPhoneRuningOnGame()){
			spr.scale = 0.5f;
		}
		
		return spr;
		//
	}
	
	return nil;
}
////下划线字
static inline CCSprite* getUnderlineSprite( NSString *_string ,NSString *_fName ,int _fSize ,ccColor4B _c1 ){
	CCLabelTTF *label = [CCLabelTTF labelWithString:_string fontName:_fName fontSize:_fSize];
	if(label){
		label.color = ccc3(_c1.r, _c1.g, _c1.b);
		CCRenderTexture *render = [CCRenderTexture renderTextureWithWidth:label.contentSize.width+_fSize*2  height:label.contentSize.height+_fSize*2];
		if (render) {
			CCSprite *spr = [CCSprite node];
			[render begin];
			ccDrawColor4B(_c1.r,_c1.g,_c1.b,_c1.a);
			ccDrawLine(ccp(_fSize, _fSize), ccp(label.contentSize.width+_fSize,_fSize));
			[render end];
			spr.contentSize = label.contentSize;
			[spr addChild:render];
			[spr addChild:label];
			render.position = ccp(spr.contentSize.width/2,spr.contentSize.height/2);
			label.position = render.position;
			label.opacity = _c1.a;
			render.sprite.opacity = _c1.a;
			return spr;
		}
	}
	return nil;
}


////下划线字 array
static inline NSArray * getUnderlineSpriteArray( NSString *_string ,NSString *_fName ,int _fSize ,ccColor4B _c1 ){
	CCSprite *spr1 = getUnderlineSprite(_string, _fName, _fSize, _c1); //正常状态
	CCLabelTTF *label1 = [CCLabelTTF labelWithString:_string fontName:_fName fontSize:_fSize];
	[label1 setColor:ccc3(_c1.r, _c1.g, _c1.b)];
	label1.opacity = _c1.a;
	return [NSArray arrayWithObjects:spr1,label1,nil];
}
//发光字体
static inline CCSprite* getStrokeSprite( NSString *_string ,NSString *_fName ,int _fSize ,float side,ccColor4B _c1 ,ccColor4B _bgc2){
	CCLabelTTF *label = [CCLabelTTF labelWithString:_string fontName:_fName fontSize:_fSize];
	if(label){
		label.color = ccc3(_c1.r, _c1.g, _c1.b);
		
		CCRenderTexture *render = createStroke(label, side,  ccc3(_bgc2.r, _bgc2.g, _bgc2.b));
		if (render) {
			CCSprite *spr = [CCSprite node];
			spr.contentSize = label.contentSize;
			[spr addChild:render];
			[spr addChild:label];
            float h_off = 0;
            float h_scale = (20 - _fSize)/1.5;
            if (h_scale<0) {
                h_scale = 0;
            }
            h_off = 2.5-side;
            if (h_off<0) {
                h_off = 0;
            }
			render.position = ccp(spr.contentSize.width/2,spr.contentSize.height/2+h_off+h_scale);
            label.position = ccp(spr.contentSize.width/2,spr.contentSize.height/2);
			//label.position = render.position;
			label.opacity = _c1.a;
			render.sprite.opacity = _bgc2.a;
			return spr;
		}
	}
	return nil;
}

static inline NSString * getTimeFormat(unsigned int time){
	int s = time%60;
	int m = time/60%60;
	int h = time/(60*60);
	//	NSString * string = [NSString stringWithFormat:@"%@%@%@",
	//						 (h>0?[NSString stringWithFormat:@"%d小时",h]:@""),
	//						 ((h>0||m>0)?[NSString stringWithFormat:@"%d分",m]:@""),
	//						 [NSString stringWithFormat:@"%@秒",
	//						  (s<10?[NSString stringWithFormat:@"0%d",s]:
	//						   [NSString stringWithFormat:@"%d",s])]];
    NSString * string = [NSString stringWithFormat:@"%@%@%@",
						 (h>0?[NSString stringWithFormat:NSLocalizedString(@"config_hour",nil),h]:@""),
						 ((h>0||m>0)?[NSString stringWithFormat:NSLocalizedString(@"config_minute",nil),m]:@""),
						 [NSString stringWithFormat:NSLocalizedString(@"config_second",nil),
						  (s<10?[NSString stringWithFormat:@"0%d",s]:
						   [NSString stringWithFormat:@"%d",s])]];
	return string;
}

///////////////////////////////////////////////////////////
static inline CCSprite* getImageNumber(NSString* path , float width , float height , int num){
	CCSprite* ___sprite = [CCSprite node];
	CCSprite* ___result = [CCSprite node];
	float _x = 0 ;
	float _y = 0 ;
	int _total = 0 ;
	
    /*
	 if (iPhoneRuningOnGame()) {
	 width /= 2;
	 height /= 2;
	 }
	 */
	
	width = cFixedScale(width);
	height = cFixedScale(height);
    
	do {
		int d1 = num%10;
		num = num/10;
		CCSprite* temp = [CCSprite spriteWithFile:path rect:CGRectMake(width*d1, 0, width, height)];
		[___sprite addChild:temp z:0];
		temp.anchorPoint=ccp(1.0f, 0.5);
		temp.position=ccp(_x, _y);
		_x -= width ;
		_total++;
	} while (num > 0);
	
	
	___result.contentSize =CGSizeMake(_total*width, height);
	[___result addChild:___sprite z:1];
	___sprite.position=ccp(___result.contentSize.width, height/2);
	
	return ___result;
}

static inline void showNode(CCNode* nd){
    CCLayerColor * ndShow = [CCLayerColor layerWithColor:ccc4(255,0,0,100) width:nd.contentSize.width height:nd.contentSize.height];
    [ndShow setIgnoreAnchorPointForPosition:YES];
    ndShow.position =ccp(0,0);
    ndShow.anchorPoint = ccp(0,0);
    [nd addChild:ndShow z:999];
}

static inline CCLayer *getSideLayerWithAll(CCNode *node, float sideWidth, ccColor3B color)
{
	if (node == nil) return nil;
	CCLayerColor *layer = [CCLayerColor layerWithColor:ccc4(color.r, color.g, color.b, 255)
												 width:node.contentSize.width+sideWidth*2
												height:node.contentSize.height+sideWidth*2];
	node.anchorPoint = CGPointZero;
	node.position = ccp(sideWidth, sideWidth);
	[layer addChild:node];
	return layer;
}
static inline CCLayer *getSideLayer(CCNode *node, float sideWidth)
{
	return getSideLayerWithAll(node, sideWidth, ccc3(81, 53, 22));
}

static inline NSString* getTextWithQuality(int quality){
	NSString *str_ = @"";
	switch (quality) {
		case IQ_GREEN:
			str_ = @"game_quality_green";
			break;
		case IQ_BLUE:
			str_ = @"game_quality_blue";
			break;
		case IQ_PURPLE:
			str_ = @"game_quality_purple";
			break;
		case IQ_ORANGE:
			str_ = @"game_quality_orange";
			break;
		case IQ_RED:
            str_ = @"game_quality_red";
			break;
		default:
			break;
	}
	return  str_;
}