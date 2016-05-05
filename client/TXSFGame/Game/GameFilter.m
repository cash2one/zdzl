//
//  GameFilter.m
//  TXSFGame
//
//  Created by Max on 13-2-20.
//  Copyright 2013年 eGame. All rights reserved.
//

#import "GameFilter.h"
#import "Config.h"


@implementation GameFilter


@synthesize filterKeyWord;

static GameFilter *gameFilter;
static int filterLenght=0;

+(GameFilter*)share{
	if(!gameFilter){
		gameFilter=[[GameFilter alloc]init];
	}
	return gameFilter;
}

+(void)stopAll{
	if(gameFilter){
		[gameFilter release];
		gameFilter = nil;
	}
}

+(BOOL)validContract:(NSString*)str{
	if (str == nil && str.length == 0) {
		return NO;
	}
	
	NSDictionary* dict = getParseSetting(0);
	NSArray* array = [dict allValues];
	if (array && array.count > 0) {
		for (NSString *value in array) {
			NSRange rang = [str rangeOfString:value];
			if (rang.length > 0) {
				return NO;
			}
		}
	}
	
	NSArray* specials = getSpecialCharacter();
	if (specials && specials.count > 0) {
		for (NSString *value in specials) {
			NSRange rang = [str rangeOfString:value];
			if (rang.length > 0) {
				return NO;
			}
		}
	}
	
	return YES;
}

-(void)loadKeyword{
	
	if(filterKeyWord!=nil){
		return;
	}
	
	dispatch_queue_t reload_queue = dispatch_queue_create("com.game.loadKeyword", NULL);
	dispatch_async(reload_queue, ^{
		
		int maxFilterLenght = 0;
		
		NSDictionary *_db=[[GameDB shared] getBanWord];
		NSMutableDictionary *tempkeyword = [NSMutableDictionary dictionary];
		
		for(NSDictionary *keyword in _db.allValues){
			NSString *ftstr=@"";
			NSString *keywordstr=[NSString stringWithFormat:@"%@",[keyword objectForKey:@"banword"]];
			for(int f=0;f<[keywordstr length];f++){
				ftstr=[ftstr stringByAppendingString:@"$"];
			}
			[tempkeyword setValue:ftstr forKey:keywordstr];
			if(maxFilterLenght<keywordstr.length){
				maxFilterLenght=keywordstr.length;
			}
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[gameFilter setFilterKeyWord:tempkeyword];
			filterLenght = maxFilterLenght;
		});
		
	});
	dispatch_release(reload_queue);
	
}
-(void)freeKeyword{
	if(filterKeyWord){
		[filterKeyWord release];
		filterKeyWord = nil;
	}
}

-(NSString*)chatFilter:(NSString*)str{
	for(int i=filterLenght;i>0;i--){
		for(int l=0;l<str.length;l++){
			NSRange range;
			range.length=1+i;
			range.location=l;
			if((range.length+range.location)>str.length){
				continue;
			}
			NSString *keyword=[str substringWithRange:range];
			NSString *content=[filterKeyWord objectForKey:[keyword lowercaseString]];
			if(content.length>0){
				str=[str stringByReplacingCharactersInRange:range withString:content];
			}
		}
	}
	return  str;
}

-(bool)nameFilter:(NSString*)str{
	str=[str lowercaseString];
	for(int i=filterLenght;i>0;i--){
		for(int l=0;l<str.length;l++){
			NSRange range;
			range.length=1+i;
			range.location=l;
			if((range.length+range.location)>str.length){
				continue;
			}
			NSString *keyword=[str substringWithRange:range];
			NSString *content=[filterKeyWord objectForKey:keyword];
			if(content.length>0){
				return YES;
			}
		}
	}
	return  NO;
}


-(void)dealloc{
	[self freeKeyword];
	gameFilter=nil;
	[super dealloc];
}


@end
