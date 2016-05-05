//
//  Config.h
//  TXSFGame
//
//  Created by Soul on 13-5-16.
//  Copyright (c) 2013年 eGame. All rights reserved.
//


#import "GameDB.h"
#import "GameDefine.h"
#import "UIConfig.h"

static inline BOOL isEqualToKey(NSString * a, NSString * b){
	if(!a) return NO;
	if(!b) return NO;
	if([[a uppercaseString] isEqualToString:[b uppercaseString]]){
		return YES;
	}
	return NO;
}

static inline NSString* getFormatTimeWithSeconds(int t)
{
	NSString *hourString = [NSString stringWithFormat:@"%02d",t/3600];
	NSString *minuteString = [NSString stringWithFormat:@"%02d",(t%3600)/60];
	NSString *secondString = [NSString stringWithFormat:@"%02d",t%60];
	return [NSString stringWithFormat:@"%@:%@:%@",hourString, minuteString, secondString];
}

static inline BaseAttribute BaseAttributeZero(){
	BaseAttribute ba;
	
	ba.STR = 0;
	ba.INT = 0;
	ba.VIT = 0;
	ba.DEX = 0;
	
	ba.HP = 0;
	ba.MP = 0;
	ba.ATK = 0;
	ba.STK = 0;
	
	ba.DEF = 0;
	ba.SPD = 0;
	
	ba.MPS = 0;
	ba.MPT = 0;
	
	ba.HIT = 0;
	ba.MIS = 0;
	ba.BOK = 0;
	ba.COT = 0;
	ba.CRI = 0;
	ba.CPR = 0;
	ba.PEN = 0;
	ba.TUF = 0;
	ba.COB = 0;
	
	ba.CBE = 0;
	ba.FAE = 0;
	
	return ba;
}

static inline BaseAttribute BaseAttributeCheck(BaseAttribute ba){
	
	
	ba.STR = (int)ba.STR;
	ba.INT = (int)ba.INT;
	ba.VIT = (int)ba.VIT;
	ba.DEX = (int)ba.DEX;
	
	ba.HP = (int)ba.HP;
	ba.MP = (int)ba.MP;
	ba.ATK = (int)ba.ATK;
	ba.STK = (int)ba.STK;
	
	ba.DEF = (int)ba.DEF;
	ba.SPD = (int)ba.SPD;
	ba.MPS = (int)ba.MPS;
	ba.MPT = (int)ba.MPT;
	
	ba.STK = ba.INT + ba.ATK;
	
	//TODO ???
	ba.CBE = 0;
	ba.FAE = 0;
	
	if(ba.STR<0) ba.STR = 0;
	if(ba.INT<0) ba.INT = 0;
	if(ba.VIT<0) ba.VIT = 0;
	if(ba.DEX<0) ba.DEX = 0;
	
	if(ba.HP<0) ba.HP = 0;
	if(ba.MP<0) ba.MP = 0;
	if(ba.ATK<0) ba.ATK = 0;
	if(ba.STK<0) ba.STK = 0;
	
	if(ba.DEF<0) ba.DEF = 0;
	if(ba.SPD<0) ba.SPD = 0;
	
	if(ba.MPS<0) ba.MPS = 0;
	if(ba.MPT<0) ba.MPT = 0;
	
	if(ba.HIT<0) ba.HIT = 0;
	if(ba.MIS<0) ba.MIS = 0;
	if(ba.BOK<0) ba.BOK = 0;
	if(ba.COT<0) ba.COT = 0;
	if(ba.CRI<0) ba.CRI = 0;
	if(ba.CPR<0) ba.CPR = 0;
	if(ba.PEN<0) ba.PEN = 0;
	if(ba.TUF<0) ba.TUF = 0;
	if(ba.COB<0) ba.COB = 0;
	
	if(ba.CBE<0) ba.CBE = 0;
	if(ba.FAE<0) ba.FAE = 0;
	
	return ba;
}

static inline BaseAttribute BaseAttributeAdd(BaseAttribute ba1, BaseAttribute ba2){
	BaseAttribute ba = BaseAttributeZero();
	
	ba.STR = ba1.STR+ba2.STR;
	ba.INT = ba1.INT+ba2.INT;
	ba.VIT = ba1.VIT+ba2.VIT;
	ba.DEX = ba1.DEX+ba2.DEX;
	
	ba.HP = ba1.HP+ba2.HP;
	ba.MP = ba1.MP+ba2.MP;
	ba.ATK = ba1.ATK+ba2.ATK;
	ba.STK = ba1.STK+ba2.STK;
	
	ba.DEF = ba1.DEF+ba2.DEF;
	ba.SPD = ba1.SPD+ba2.SPD;
	
	ba.MPS = ba1.MPS+ba2.MPS;
	ba.MPT = ba1.MPT+ba2.MPT;
	
	ba.HIT = ba1.HIT+ba2.HIT;
	ba.MIS = ba1.MIS+ba2.MIS;
	ba.BOK = ba1.BOK+ba2.BOK;
	ba.COT = ba1.COT+ba2.COT;
	ba.CRI = ba1.CRI+ba2.CRI;
	ba.CPR = ba1.CPR+ba2.CPR;
	ba.PEN = ba1.PEN+ba2.PEN;
	ba.TUF = ba1.TUF+ba2.TUF;
	ba.COB = ba1.COB+ba2.COB;
	
	return ba;
}

static inline BaseAttribute BaseAttributeConvert(BaseAttribute target){
	BaseAttribute ba = target;
	
	ba.ATK = target.STR * target.ATK; //攻击=勇力*攻击兑换率
	ba.COT = target.STR * target.COT; //反击率=勇力*反击率兑换率
	
	ba.SPD = target.DEX * target.SPD; //速度=迅捷*速度兑换率
	ba.MIS = target.DEX * target.MIS; //闪避率=迅捷*闪避兑换率
	ba.COB = target.DEX * target.COB; //连击率=迅捷*连击率兑换率
	
	ba.HP = target.VIT * target.HP; //生命=体魄*生命兑换率
	ba.DEF = target.VIT * target.DEF; //防御=体魄*体魄兑换率
	
	return ba;
}

static inline BaseAttribute BaseAttributeAddBase(BaseAttribute ba1, BaseAttribute ba2){
	ba1.STR = ba1.STR+ba2.STR;
	ba1.INT = ba1.INT+ba2.INT;
	ba1.VIT = ba1.VIT+ba2.VIT;
	ba1.DEX = ba1.DEX+ba2.DEX;
	return ba1;
}

static inline BaseAttribute BaseAttributeAddOther(BaseAttribute ba1, BaseAttribute ba2){
	BaseAttribute ba = ba1;
	
	ba.HP = ba1.HP+ba2.HP;
	ba.MP = ba1.MP+ba2.MP;
	ba.ATK = ba1.ATK+ba2.ATK;
	ba.STK = ba1.STK+ba2.STK;
	
	ba.DEF = ba1.DEF+ba2.DEF;
	ba.SPD = ba1.SPD+ba2.SPD;
	
	ba.MPS = ba1.MPS+ba2.MPS;
	ba.MPT = ba1.MPT+ba2.MPT;
	
	ba.HIT = ba1.HIT+ba2.HIT;
	ba.MIS = ba1.MIS+ba2.MIS;
	ba.BOK = ba1.BOK+ba2.BOK;
	ba.COT = ba1.COT+ba2.COT;
	ba.CRI = ba1.CRI+ba2.CRI;
	ba.CPR = ba1.CPR+ba2.CPR;
	ba.PEN = ba1.PEN+ba2.PEN;
	ba.TUF = ba1.TUF+ba2.TUF;
	ba.COB = ba1.COB+ba2.COB;
	
	return ba;
}

static inline BaseAttribute BaseAttributeAddBuff(BaseAttribute ba1, BaseAttribute ba2){
	
	BaseAttribute ba = BaseAttributeZero();
	
	ba = BaseAttributeAddBase(ba, ba1);
	ba = BaseAttributeAddBase(ba, ba2);
	
	ba = BaseAttributeConvert(ba);
	
	ba = BaseAttributeAddOther(ba, ba1);
	ba = BaseAttributeAddOther(ba, ba2);
	
	return BaseAttributeCheck(ba);
}

static inline BaseAttribute BaseAttributeFromDict(NSDictionary*dict){
	BaseAttribute ba = BaseAttributeZero();
	if(!dict) return ba;
	
	ba.STR = [[dict objectForKey:@"STR"] floatValue];
	ba.INT = [[dict objectForKey:@"INT"] floatValue];
	ba.VIT = [[dict objectForKey:@"VIT"] floatValue];
	ba.DEX = [[dict objectForKey:@"DEX"] floatValue];
	
	ba.HP = [[dict objectForKey:@"HP"] floatValue];
	ba.MP = [[dict objectForKey:@"MP"] floatValue];
	ba.ATK = [[dict objectForKey:@"ATK"] floatValue];
	ba.STK = [[dict objectForKey:@"STK"] floatValue];
	
	ba.DEF = [[dict objectForKey:@"DEF"] floatValue];
	ba.SPD = [[dict objectForKey:@"SPD"] floatValue];
	
	ba.MPS = [[dict objectForKey:@"MPS"] floatValue];
	ba.MPT = [[dict objectForKey:@"MPT"] floatValue];
	
	ba.HIT = [[dict objectForKey:@"HIT"] floatValue];
	ba.MIS = [[dict objectForKey:@"MIS"] floatValue];
	ba.BOK = [[dict objectForKey:@"BOK"] floatValue];
	ba.COT = [[dict objectForKey:@"COT"] floatValue];
	ba.CRI = [[dict objectForKey:@"CRI"] floatValue];
	ba.CPR = [[dict objectForKey:@"CPR"] floatValue];
	ba.PEN = [[dict objectForKey:@"PEN"] floatValue];
	ba.TUF = [[dict objectForKey:@"TUF"] floatValue];
	ba.COB = [[dict objectForKey:@"COB"] floatValue];
	
	return ba;
}
static inline BaseAttribute BaseAttributePercentFromDict(NSDictionary*dict){
	BaseAttribute ba = BaseAttributeZero();
	if(!dict) return ba;
	
	ba.STR = [[dict objectForKey:@"STR_P"] floatValue];
	ba.INT = [[dict objectForKey:@"INT_P"] floatValue];
	ba.VIT = [[dict objectForKey:@"VIT_P"] floatValue];
	ba.DEX = [[dict objectForKey:@"DEX_P"] floatValue];
	
	ba.HP = [[dict objectForKey:@"HP_P"] floatValue];
	ba.MP = [[dict objectForKey:@"MP_P"] floatValue];
	ba.ATK = [[dict objectForKey:@"ATK_P"] floatValue];
	ba.STK = [[dict objectForKey:@"STK_P"] floatValue];
	
	ba.DEF = [[dict objectForKey:@"DEF_P"] floatValue];
	ba.SPD = [[dict objectForKey:@"SPD_P"] floatValue];
	
	ba.MPS = [[dict objectForKey:@"MPS_P"] floatValue];
	ba.MPT = [[dict objectForKey:@"MPT_P"] floatValue];
	
	ba.HIT = [[dict objectForKey:@"HIT_P"] floatValue];
	ba.MIS = [[dict objectForKey:@"MIS_P"] floatValue];
	ba.BOK = [[dict objectForKey:@"BOK_P"] floatValue];
	ba.COT = [[dict objectForKey:@"COT_P"] floatValue];
	ba.CRI = [[dict objectForKey:@"CRI_P"] floatValue];
	ba.CPR = [[dict objectForKey:@"CPR_P"] floatValue];
	ba.PEN = [[dict objectForKey:@"PEN_P"] floatValue];
	ba.TUF = [[dict objectForKey:@"TUF_P"] floatValue];
	ba.COB = [[dict objectForKey:@"COB_P"] floatValue];
	
	return ba;
}

//ATK:100|DEF:50 实数
static inline BaseAttribute BaseAttributeFromKV(NSString*string){
	BaseAttribute ba = BaseAttributeZero();
	
	NSArray * ary1 = [string componentsSeparatedByString:@"|"];
	for(NSString * str in ary1){
		if([str length]>0){
			NSArray * ary2 = [str componentsSeparatedByString:@":"];
			if([ary2 count]==2){
				
				NSString * key = [ary2 objectAtIndex:0];
				
				if(isEqualToKey(key,@"STR")) ba.STR += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"INT")) ba.INT += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"VIT")) ba.VIT += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"DEX")) ba.DEX += [[ary2 objectAtIndex:1] floatValue];
				
				if(isEqualToKey(key,@"HP")) ba.HP += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"MP")) ba.MP += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"ATK")) ba.ATK += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"STK")) ba.STK += [[ary2 objectAtIndex:1] floatValue];
				
				if(isEqualToKey(key,@"DEF")) ba.DEF += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"SPD")) ba.SPD += [[ary2 objectAtIndex:1] floatValue];
				
				if(isEqualToKey(key,@"MPS")) ba.MPS += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"MPT")) ba.MPT += [[ary2 objectAtIndex:1] floatValue];
				
				if(isEqualToKey(key,@"HIT")) ba.HIT += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"MIS")) ba.MIS += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"BOK")) ba.BOK += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"COT")) ba.COT += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"CRI")) ba.CRI += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"CPR")) ba.CPR += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"PEN")) ba.PEN += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"TUF")) ba.TUF += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"COB")) ba.COB += [[ary2 objectAtIndex:1] floatValue];
				
			}
		}
	}
	
	return ba;
}

static inline NSDictionary* BaseAttributeToDictionary(BaseAttribute ba){
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	
	[dict setObject:[NSNumber numberWithFloat:ba.STR] forKey:@"STR"];
	[dict setObject:[NSNumber numberWithFloat:ba.INT] forKey:@"INT"];
	[dict setObject:[NSNumber numberWithFloat:ba.VIT] forKey:@"VIT"];
	[dict setObject:[NSNumber numberWithFloat:ba.DEX] forKey:@"DEX"];
	
	[dict setObject:[NSNumber numberWithFloat:ba.HP] forKey:@"HP"];
	[dict setObject:[NSNumber numberWithFloat:ba.MP] forKey:@"MP"];
	[dict setObject:[NSNumber numberWithFloat:ba.ATK] forKey:@"ATK"];
	[dict setObject:[NSNumber numberWithFloat:ba.STK] forKey:@"STK"];
	
	[dict setObject:[NSNumber numberWithFloat:ba.DEF] forKey:@"DEF"];
	[dict setObject:[NSNumber numberWithFloat:ba.SPD] forKey:@"SPD"];
	[dict setObject:[NSNumber numberWithFloat:ba.MPS] forKey:@"MPS"];
	[dict setObject:[NSNumber numberWithFloat:ba.MPT] forKey:@"MPT"];
	
	[dict setObject:[NSNumber numberWithFloat:ba.HIT] forKey:@"HIT"];
	[dict setObject:[NSNumber numberWithFloat:ba.MIS] forKey:@"MIS"];
	[dict setObject:[NSNumber numberWithFloat:ba.BOK] forKey:@"BOK"];
	[dict setObject:[NSNumber numberWithFloat:ba.COT] forKey:@"COT"];
	[dict setObject:[NSNumber numberWithFloat:ba.CRI] forKey:@"CRI"];
	[dict setObject:[NSNumber numberWithFloat:ba.CPR] forKey:@"CPR"];
	[dict setObject:[NSNumber numberWithFloat:ba.PEN] forKey:@"PEN"];
	[dict setObject:[NSNumber numberWithFloat:ba.TUF] forKey:@"TUF"];
	[dict setObject:[NSNumber numberWithFloat:ba.COB] forKey:@"COB"];
	
	return dict;
}

static inline NSDictionary* BaseAttributePercentToDictionary(BaseAttribute ba){
	NSMutableDictionary* dict = [NSMutableDictionary dictionary];
	
	[dict setObject:[NSNumber numberWithFloat:ba.STR] forKey:@"STR_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.INT] forKey:@"INT_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.VIT] forKey:@"VIT_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.DEX] forKey:@"DEX_P"];
	
	[dict setObject:[NSNumber numberWithFloat:ba.HP] forKey:@"HP_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.MP] forKey:@"MP_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.ATK] forKey:@"ATK_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.STK] forKey:@"STK_P"];
	
	[dict setObject:[NSNumber numberWithFloat:ba.DEF] forKey:@"DEF_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.SPD] forKey:@"SPD_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.MPS] forKey:@"MPS_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.MPT] forKey:@"MPT_P"];
	
	[dict setObject:[NSNumber numberWithFloat:ba.HIT] forKey:@"HIT_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.MIS] forKey:@"MIS_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.BOK] forKey:@"BOK_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.COT] forKey:@"COT_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.CRI] forKey:@"CRI_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.CPR] forKey:@"CPR_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.PEN] forKey:@"PEN_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.TUF] forKey:@"TUF_P"];
	[dict setObject:[NSNumber numberWithFloat:ba.COB] forKey:@"COB_P"];
	
	return dict;
}

//ATK_P:100|DEF_P:50 百分比
static inline BaseAttribute BaseAttributePercentFromKV(NSString*string){
	BaseAttribute ba = BaseAttributeZero();
	
	NSArray * ary1 = [string componentsSeparatedByString:@"|"];
	for(NSString * str in ary1){
		if([str length]>0){
			NSArray * ary2 = [str componentsSeparatedByString:@":"];
			if([ary2 count]==2){
				
				NSString * key = [ary2 objectAtIndex:0];
				
				if(isEqualToKey(key,@"STR_P")) ba.STR += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"INT_P")) ba.INT += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"VIT_P")) ba.VIT += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"DEX_P")) ba.DEX += [[ary2 objectAtIndex:1] floatValue];
				
				if(isEqualToKey(key,@"HP_P")) ba.HP += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"MP_P")) ba.MP += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"ATK_P")) ba.ATK += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"STK_P")) ba.STK += [[ary2 objectAtIndex:1] floatValue];
				
				if(isEqualToKey(key,@"DEF_P")) ba.DEF += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"SPD_P")) ba.SPD += [[ary2 objectAtIndex:1] floatValue];
				
				if(isEqualToKey(key,@"MPS_P")) ba.MPS += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"MPT_P")) ba.MPT += [[ary2 objectAtIndex:1] floatValue];
				
				if(isEqualToKey(key,@"HIT_P")) ba.HIT += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"MIS_P")) ba.MIS += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"BOK_P")) ba.BOK += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"COT_P")) ba.COT += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"CRI_P")) ba.CRI += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"CPR_P")) ba.CPR += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"PEN_P")) ba.PEN += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"TUF_P")) ba.TUF += [[ary2 objectAtIndex:1] floatValue];
				if(isEqualToKey(key,@"COB_P")) ba.COB += [[ary2 objectAtIndex:1] floatValue];
				
			}
		}
	}
	
	return ba;
}

static inline BaseAttribute BaseAttributeFromPercent(BaseAttribute a, BaseAttribute p){
	
	BaseAttribute r = BaseAttributeZero();
	
	//百分比不能添加4个基础
	/*
	 if(p.STR>0) r.STR = a.STR * (p.STR/100.0f);
	 if(p.INT>0) r.INT = a.INT * (p.INT/100.0f);
	 if(p.VIT>0) r.VIT = a.VIT * (p.VIT/100.0f);
	 if(p.DEX>0) r.DEX = a.DEX * (p.DEX/100.0f);
	 */
	
	if(fabsf(p.HP)>0) r.HP = a.HP * (p.HP/100.0f);
	if(fabsf(p.MP)>0) r.MP = a.MP * (p.MP/100.0f);
	if(fabsf(p.ATK)>0) r.ATK = a.ATK * (p.ATK/100.0f);
	if(fabsf(p.STK)>0) r.STK = a.STK * (p.STK/100.0f);
	
	if(fabsf(p.DEF)>0) r.DEF = a.DEF * (p.DEF/100.0f);
	if(fabsf(p.SPD)>0) r.SPD = a.SPD * (p.SPD/100.0f);
	if(fabsf(p.MPS)>0) r.MPS = a.MPS * (p.MPS/100.0f);
	if(fabsf(p.MPT)>0) r.MPT = a.MPT * (p.MPT/100.0f);
	
	if(fabsf(p.HIT)>0) r.HIT = a.HIT * (p.HIT/100.0f);
	if(fabsf(p.MIS)>0) r.MIS = a.MIS * (p.MIS/100.0f);
	if(fabsf(p.BOK)>0) r.BOK = a.BOK * (p.BOK/100.0f);
	if(fabsf(p.COT)>0) r.COT = a.COT * (p.COT/100.0f);
	if(fabsf(p.CRI)>0) r.CRI = a.CRI * (p.CRI/100.0f);
	if(fabsf(p.CPR)>0) r.CPR = a.CPR * (p.CPR/100.0f);
	if(fabsf(p.PEN)>0) r.PEN = a.PEN * (p.PEN/100.0f);
	if(fabsf(p.TUF)>0) r.TUF = a.TUF * (p.TUF/100.0f);
	if(fabsf(p.COB)>0) r.COB = a.COB * (p.COB/100.0f);
	
	return r;
}

//按实数与百分比添加 百分比按member的BaseAttribute添加 -> NSString format
static inline BaseAttribute BaseAttributeFromFormat(BaseAttribute ba, NSString*value){
	BaseAttribute r1 = BaseAttributeFromKV(value);
	BaseAttribute r2 = BaseAttributePercentFromKV(value);
	r2 = BaseAttributeFromPercent(ba, r2);
	BaseAttribute result = BaseAttributeAdd(r1, r2);
	return result;
}
//按实数与百分比添加 百分比按member的BaseAttribute添加 -> NSDictionary
static inline BaseAttribute BaseAttributeAllFromDict(BaseAttribute ba, NSDictionary*dict){
	if([[dict allKeys] count]==0){
		return BaseAttributeZero();
	}
	BaseAttribute r1 = BaseAttributeFromDict(dict);
	BaseAttribute r2 = BaseAttributePercentFromDict(dict);
	r2 = BaseAttributeFromPercent(ba, r2);
	BaseAttribute result = BaseAttributeAdd(r1, r2);
	return result;
}

/**
 * <BaseAttribute ba> 用于统计的属性
 */
static inline NSString* BaseAttributeToDisplayString(BaseAttribute ba){
	NSString* setting = [[GameDB shared] getGlobalSetting:@"display_now"];
	NSMutableArray* result = [NSMutableArray array];
	if (setting != nil) {
		NSDictionary* attribute = BaseAttributeToDictionary(ba);
		NSArray* keys = [setting componentsSeparatedByString:@"|"];
		for (NSString* temp in keys) {
			NSArray* keys2 = [temp componentsSeparatedByString:@":"];
			if (keys2.count > 1) {
				NSString* v1 = [keys2 objectAtIndex:0];
				NSString* v2 = [keys2 objectAtIndex:1];
				float v3  = [[attribute objectForKey:v1] floatValue];
				if (keys2.count == 3) {
					NSString *str1 = [NSString stringWithFormat:@"%@:%.1f%@",v2,v3,@"%"];
					[result addObject:str1];
				}else{
					NSString *str1  = [NSString stringWithFormat:@"%@:%.f",v2,v3];
					[result addObject:str1];
				}
			}
		}
	}
	return [result componentsJoinedByString:@"|"];
}

static inline NSString* BaseAttributeToDisplayStringWithFilter(BaseAttribute ba,NSString* filter){
	NSString* setting = [[GameDB shared] getGlobalSetting:@"display_now"];
	NSMutableArray* result = [NSMutableArray array];
	if (setting != nil && filter != nil) {
		NSDictionary* attribute = BaseAttributeToDictionary(ba);
		NSArray* keys = [setting componentsSeparatedByString:@"|"];
		NSArray* filters = [filter componentsSeparatedByString:@"|"];
		for (NSString* temp in keys) {
			NSArray* keys2 = [temp componentsSeparatedByString:@":"];
			if (keys2.count > 1) {
				NSString* v1 = [keys2 objectAtIndex:0];
				NSString* v2 = [keys2 objectAtIndex:1];
				float v3  = [[attribute objectForKey:v1] floatValue];
				if ([filters containsObject:v1]) {
					if (keys2.count == 3) {
						NSString *str1 = [NSString stringWithFormat:@"%@:%.1f%@",v2,v3,@"%"];
						[result addObject:str1];
					}else{
						NSString *str1  = [NSString stringWithFormat:@"%@:%.f",v2,v3];
						[result addObject:str1];
					}
				}
			}
		}
	}
	return [result componentsJoinedByString:@"|"];
}

static inline NSString* BaseAttributeToDisplayStringWithOutZero(BaseAttribute ba){
	NSString* setting = [[GameDB shared] getGlobalSetting:@"display_now"];
	NSMutableArray* result = [NSMutableArray array];
	if (setting != nil) {
		NSDictionary* attribute = BaseAttributeToDictionary(ba);
		NSArray* keys = [setting componentsSeparatedByString:@"|"];
		for (NSString* temp in keys) {
			NSArray* keys2 = [temp componentsSeparatedByString:@":"];
			if (keys2.count > 1) {
				NSString* v1 = [keys2 objectAtIndex:0];
				NSString* v2 = [keys2 objectAtIndex:1];
				float v3  = [[attribute objectForKey:v1] floatValue];
				if (v3 > 0) {
					if (keys2.count == 3) {
						NSString *str1 = [NSString stringWithFormat:@"%@:%.1f%@",v2,v3,@"%"];
						[result addObject:str1];
					}else{
						NSString *str1  = [NSString stringWithFormat:@"%@:%.f",v2,v3];
						[result addObject:str1];
					}
				}
			}
		}
	}
	return [result componentsJoinedByString:@"|"];
}

static inline NSString* getAttrDescribetion(NSDictionary *dict, NSString *str){
	if (dict == nil) return @"";
	
	NSString *attrString = @"";
	BaseAttribute attr = BaseAttributeFromDict(dict);
	NSString *string = BaseAttributeToDisplayStringWithOutZero(attr);
	
	NSArray *array = [string componentsSeparatedByString:@"|"];
	for (NSString *_string in array) {
		NSArray *_array = [_string componentsSeparatedByString:@":"];
		if (_array.count >= 2) {
			NSString *_name = [_array objectAtIndex:0];
			NSString *_addValue = [_array objectAtIndex:1];
			
			attrString = [attrString stringByAppendingFormat:str, _name, _addValue];
		}
	}
	
	return attrString;
}

static inline NSString* getAttrDescribetionWithDict(NSDictionary *dict){
	return getAttrDescribetion(dict, @"%@ #eeeeee#16#0|+%@#00ee00#16#0*");
}

static inline float valueFromFormat(NSString*value, NSString*tkey, int index){
	NSArray * ary1 = [value componentsSeparatedByString:@"|"];
	for(NSString * str in ary1){
		if([str length]>0){
			NSArray * ary2 = [str componentsSeparatedByString:@":"];
			if([ary2 count]>index){
				NSString * key = [ary2 objectAtIndex:0];
				if(isEqualToKey(key,tkey)){
					return [[ary2 objectAtIndex:index] floatValue];
				}
			}
		}
	}
	return 0.0f;
}
static inline id valueFromSort(NSString*value, int index){
	NSArray * ary = [value componentsSeparatedByString:@":"];
	if([ary count]>index){
		return [ary objectAtIndex:index];
	}
	return @"";
}

static inline int getBattlePower(BaseAttribute att){
	
	return att.STR*0.8 + att.DEX*2 + att.VIT*2 + att.INT*0.7 + att.ATK*0.5 + att.DEF*2 + att.SPD*2 + att.HP/5 + (att.HIT-95) + att.MIS*2 + att.BOK*2 + att.COT*2 + att.CRI/2 + att.CPR/2 + att.PEN/2 + att.TUF + att.COB;
}

static inline BossData BossDataZero(){
	BossData boss;
	
	boss.bossHP = 0 ;
	boss.bossTotalHP = 0 ;
	boss.bossId = 0 ;
	boss.bossLevel = 0;
	
	return boss;
}

static inline CombatCool CombatCoolZero(){
	CombatCool comc;
	
	comc._remain = 0 ;
	comc._total = 0;
	
	return comc;
}

static inline SystemStatusInfo SystemStatusInfoZero(){
	SystemStatusInfo sys;
	
	sys.isCheckStart = NO;
	sys.isCheckStop = NO;
	sys.isCheckStop = NO;
	
	sys.startTime = INT32_MAX;
	sys.stopTime = INT32_MAX;
	sys.combatCool = CombatCoolZero();
	
	return sys;
}

////////////////////////////////////////////////////////////////////////////////
//------------------------------------------------------------------------------


static inline NSArray * getNPCListByData(NSString*data){
	NSMutableArray * result = [NSMutableArray array];
	if([data length]>0){
		NSArray * ary1 = [data componentsSeparatedByString:@"|"];
		for(NSString * str in ary1){
			if([str length]>0){
				NSArray * ary2 = [str componentsSeparatedByString:@":"];
				if([ary2 count] > 2){
					NSMutableDictionary * d = [NSMutableDictionary dictionary];
					[d setObject:[ary2 objectAtIndex:0] forKey:@"nid"];
					[d setObject:[ary2 objectAtIndex:1] forKey:@"point"];
					[d setObject:[ary2 objectAtIndex:2] forKey:@"direction"];
					if ([ary2 count]==4) {
						[d setObject:[ary2 objectAtIndex:3] forKey:@"count"];
					}
					[result addObject:d];
				}
			}
		}
	}
	return result;
}

static inline NSString * getNPCDataByList(NSArray*ary){
	if([ary count]==0){
		return @"";
	}
	
	NSMutableArray * source = [NSMutableArray array];
	
	//增加计算管理
	for(NSDictionary * data in ary){
		NSString * nid = [data objectForKey:@"nid"];
		NSString * point = [data objectForKey:@"point"];
		NSString * direction = [data objectForKey:@"direction"];
		NSString * count = [data objectForKey:@"count"];
		
		[source addObject:[NSString stringWithFormat:@"%@:%@:%@:%@",nid,point,direction,count]];
	}
	
	NSString * result = [NSString string];
	result = [result stringByAppendingString:[source objectAtIndex:0]];
	
	for(int i=1;i<[source count];i++){
		result = [result stringByAppendingString:@"|"];
		result = [result stringByAppendingString:[source objectAtIndex:i]];
	}
	
	return result;
}


////////////////////////////////////////////////////////////////////////////////
//------------------------------------------------------------------------------

static inline RoleDir getDirByPoints(CGPoint startPoint, CGPoint targetPoint){
	
	RoleDir targetDir = RoleDir_none;
	
	CGPoint diff = ccpSub(targetPoint,startPoint);
	float angle = (atan2f(diff.y,diff.x))*180/M_PI;
	if(diff.y<0) angle += 360;
	int ang = 25;
	
	if(angle>(90-ang)&&angle<(90+ang))		targetDir = RoleDir_up;
	if(angle>(270-ang)&&angle<(270+ang))	targetDir = RoleDir_down;
	
	if(angle>(360-ang)||angle<(ang))		targetDir = RoleDir_flat;
	if(angle>(180-ang)&&angle<(180+ang))	targetDir = RoleDir_flat;
	
	if(angle>ang&&angle<(90-ang))			targetDir = RoleDir_up_flat;
	if(angle>(90+ang)&&angle<(180-ang))		targetDir = RoleDir_up_flat;
	
	if(angle>(180+ang)&&angle<(270-ang))	targetDir = RoleDir_down_flat;
	if(angle>(270+ang)&&angle<(360-ang))	targetDir = RoleDir_down_flat;
	
	return targetDir;
}

static NSString *letter[] = {
	@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",
	@"a",@"b",@"c",@"d",@"e",@"f",@"g",@"h",@"i",@"j",
	@"k",@"l",@"m",@"n",@"o",@"p",@"q",@"r",@"s",@"t",
	@"u",@"v",@"w",@"x",@"y",@"z",
};

// static file functions

static inline int getRandomInt(int x, int y){
	
	if(x<0) x = 0;
	if(y<0) y = 0;
	
	BOOL isCut = NO;
	if(x==y) return x;
	if(x==0){
		x = 1;
		y = y + 1;
		isCut = YES;
	}
	x *= 100;
	y *= 100;
	
	float rand = (x+arc4random()%(y-x))/100.0f+0.5f;
	if(isCut) rand-=1;
	return rand;
}

static inline BOOL checkRate(float x){
	if(x>100) return YES;
	int t = x * 100;
	int i = getRandomInt(0,100*100);
	if(i<=t) return YES;
	return NO;
}


//Library
static inline NSString* getLibraryPath(){
	//NSArray * paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString * path = [paths objectAtIndex:0];
	return path;
}

static inline NSString* getDocumentPath(){
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * path = [paths objectAtIndex:0];
	return path;
}

static inline BOOL checkHasFile(NSString* filePath){
	if(![[NSFileManager defaultManager] fileExistsAtPath:filePath]){
		return NO;
	}
	return YES;
}

static inline void deleteFile(NSString*file){
	NSFileManager *fileMgr = [NSFileManager defaultManager];
	[fileMgr removeItemAtPath:file error:nil];
}

static inline NSString* getLibraryCachePathByName(NSString* fileName){
	NSString * path = getLibraryPath();
	NSString *dir = [NSString stringWithFormat:@"%@/%@/",path,GAME_DB_Cache_DIR];
	BOOL isDir = NO;
	NSFileManager *fileMgr = [NSFileManager defaultManager];
	BOOL exited = [fileMgr fileExistsAtPath:dir isDirectory:&isDir];
	if (!(isDir == YES && exited == YES)) {
		[fileMgr createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
	}
 	NSString * file = [dir stringByAppendingPathComponent:fileName];
	return file;
}

//Library
static inline NSString* getLibraryFilePathByName(NSString* fileName){
	NSString * path = getLibraryPath();
	NSString *dir = [NSString stringWithFormat:@"%@/%@/",path,GAME_DB_DIR];
	BOOL isDir = NO;
	NSFileManager *fileMgr = [NSFileManager defaultManager];
	BOOL exited = [fileMgr fileExistsAtPath:dir isDirectory:&isDir];
	if (!(isDir == YES && exited == YES)) {
		[fileMgr createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
	}
 	NSString * file = [dir stringByAppendingPathComponent:fileName];
	return file;
}
static inline NSString* getFilePathByName(NSString* fileName){
	NSString * path = getDocumentPath();
	NSString * file = [path stringByAppendingPathComponent:fileName];
	return file;
}

static inline NSString * randomLetter(int length){
	NSString * result = [NSString string];
	int total = (sizeof(letter)/sizeof(letter[0]));
	for(int i=0;i<length;i++){
		int index = arc4random()%total;
		result = [result stringByAppendingString:letter[index]];
	}
	return result;
}

static inline NSData * getDataFromString(NSString * string){
	return [string dataUsingEncoding:NSUTF8StringEncoding];
}
static inline NSString * getStringFromData(NSData * data){
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

//获取全类型物品质量
static inline int getAllItemQuality(int itemid,NSString *type){
	if([type isEqualToString:@"i"]){
		int qa=[[[[GameDB shared]getItemInfo:itemid]objectForKey:@"quality"]integerValue];
		return qa;
	}
	if([type isEqualToString:@"e"]){
		int sid=[[[[GameDB shared]getEquipmentInfo:itemid]objectForKey:@"sid"]integerValue];
		int qa=[[[[GameDB shared]getEquipmentSetInfo:sid]objectForKey:@"quality"]integerValue];
		return qa;
	}
	if([type isEqualToString:@"c"]){
		int qa=[[[[GameDB shared]getCarInfo:itemid]objectForKey:@"quality"]integerValue];
		return qa;
	}
	if([type isEqualToString:@"c"]){
		int qa=[[[[GameDB shared]getFateInfo:itemid]objectForKey:@"qulity"]integerValue];
		return qa;
	}
	return 0;
}


//获取全类型物品名字
static inline NSString* getAllItemName(int itemid,NSString *type){
	NSString *itemname=@"";
	if([type isEqualToString:@"i"]){
		return  [[[GameDB shared]getItemInfo:itemid]objectForKey:@"name"];
	}
	if([type isEqualToString:@"e"]){
		return [[[GameDB shared]getEquipmentInfo:itemid]objectForKey:@"name"];
		
	}
	if([type isEqualToString:@"c"]){
		return [[[GameDB shared]getCarInfo:itemid]objectForKey:@"name"];
	}
	if([type isEqualToString:@"f"]){
		return [[[GameDB shared]getFateInfo:itemid]objectForKey:@"name"];
	}
	return itemname;
}
//-----------------------------------------------------------------------------------
#pragma mark end

static inline NSString * getStringForInt(int i){
	
	if(i<10) return [NSString stringWithFormat:@"000%d",i];
	if(i<100) return [NSString stringWithFormat:@"00%d",i];
	if(i<1000) return [NSString stringWithFormat:@"0%d",i];
	if(i<10000) return [NSString stringWithFormat:@"%d",i];
	
	return [NSString stringWithFormat:@"%d",i];
}


static inline bool checkCollide(CGPoint _pt , CGPoint _target ,float  _r)
{
	float r = (_target.x - _pt.x)*(_target.x - _pt.x) + (_target.y-_pt.y)*(_target.y-_pt.y);
	if (r < _r*_r) {
		return true;
	}
	return false;
}

static inline CGPoint getTiledRectCenterPoint(CGRect rect){
	CGPoint point = ccpAdd(rect.origin, ccp(rect.size.width/2,rect.size.height/2));
    if (iPhoneRuningOnGame()) {
        point = ccp(point.x/2, point.y/2);
    }
	return point;
}
static inline bool isOpenFunction(unsigned int value , int index){
	//	unsigned int temp = (value & (1L << index));
	//	CCLOG(@"isOpenFunction temp = %u index = %d",temp,index);
    return (value & (1L << index)) != 0;
}
static inline unsigned int updateFunction(unsigned int value , int index){
    return (value | (1L << index));
}

static inline NSString * getAttributeName(NSString*key){
	if(!key) return nil;
	int total = (sizeof(attribute_map)/sizeof(attribute_map[0]));
	for(int i=0;i<total;i++){
		//NSArray * ary = [attribute_map[i] componentsSeparatedByString:@"|"];
        NSString *aryStr = NSLocalizedString(attribute_map[i],nil);
        if (aryStr) {
            NSArray * ary = [aryStr componentsSeparatedByString:@"|"];
            if([ary count]>1){
                if(isEqualToKey([ary objectAtIndex:0], key)){
                    return [ary objectAtIndex:1];
                }
            }
        }
	}
	return nil;
}

static inline NSString * getPropertyName(NSString*key){
	if (!key) return nil;
	
	NSString* setting = [[GameDB shared] getGlobalSetting:@"display_now"];
	if (setting != nil) {
		NSArray* keys = [setting componentsSeparatedByString:@"|"];
		for (NSString* temp in keys) {
			NSArray* keys2 = [temp componentsSeparatedByString:@":"];
			if (keys2.count > 1) {
				NSString* v1 = [keys2 objectAtIndex:0];
				if ([v1 isEqualToString:key]) {
					return [keys2 objectAtIndex:1];
				}
			}
		}
	}
	return nil;
	/*
	if(!key) return nil;
	int total = (sizeof(property_map)/sizeof(property_map[0]));
	for(int i=0;i<total;i++){
		//NSArray * ary = [property_map[i] componentsSeparatedByString:@"|"];
        NSArray * ary = [NSLocalizedString(property_map[i],nil) componentsSeparatedByString:@"|"];
		if([ary count]>1){
			if(isEqualToKey([ary objectAtIndex:0], key)){
				return [ary objectAtIndex:1];
			}
		}
	}
	return nil;
	 */
}
static inline NSString * fixBaseAttributeKey(NSString*key){
	key = [key uppercaseString];
	NSArray * ary = [key componentsSeparatedByString:@"_P"];
	if([ary count]>1){
		return [ary objectAtIndex:0];
	}
	return nil;
}



//获取触摸GL点
static inline CGPoint getGLpoint(UITouch *touch){
	CGPoint touchLocation = [touch locationInView: [touch view]];
	touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
	return  touchLocation;
}

//yyyymmdd HHMMSS
//时间戳转换真实时间
static inline NSString *timestmpToTime(NSString *stmp,NSString *format){
	NSDate *confromTimesp = [NSDate dateWithTimeIntervalSince1970:[stmp integerValue]];
	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	[formatter setDateStyle:NSDateFormatterMediumStyle];
	[formatter setTimeStyle:NSDateFormatterShortStyle];
	[formatter setDateFormat:format];
	NSString *restr=[formatter stringFromDate:confromTimesp];
	[formatter release];
	return restr;
}

static inline int filterMenuTag(Unlock_object unlockId){
	if(unlockId == Unlock_phalanx) return BT_PHALANX_TAG;
	if(unlockId == Unlock_recruit) return BT_RECRUIT_TAG;
	if(unlockId == Unlock_hammer) return BT_HAMMER_TAG;
	if(unlockId == Unlock_weapon) return BT_WEAPON_TAG;
	if(unlockId == Unlock_star) return BT_GUANXING_TAG;
	if(unlockId == Unlock_timebox) return BT_TIMEBOX_TAG;
	if(unlockId == Unlock_friend) return BT_FRIEND_TAG;
	if(unlockId == Unlock_zazen) return BT_ZAZEN_TAG;
	if(unlockId == Unlock_union) return BT_UNION_TAG;
	if(unlockId == Unlock_arena) return BT_ARENA_TAG;
	return -1;
}
static inline int filterWindowTag(Unlock_object unlockId){
	if(unlockId == Unlock_phalanx) return PANEL_PHALANX;
	if(unlockId == Unlock_recruit) return PANEL_RECRUIT;
	if(unlockId == Unlock_hammer) return PANEL_HAMMER;
	if(unlockId == Unlock_weapon) return PANEL_WEAPON;
	if(unlockId == Unlock_star) return PANEL_FATE;
	if(unlockId == Unlock_daily) return PANEL_DAILY;
	if(unlockId == Unlock_union) return PANEL_UNION;
	return -1;
}
static inline int checkTutorial(Unlock_object unlockId){
	if(unlockId == Unlock_phalanx) return YES;
	if(unlockId == Unlock_recruit) return YES;
	if(unlockId == Unlock_hammer) return YES;
	if(unlockId == Unlock_weapon) return YES;
	if(unlockId == Unlock_star) return YES;
	if(unlockId == Unlock_timebox) return YES;
	return NO;
}
//end



#pragma mark iphone相关方法 勿删
//转换坐标
static inline CGPoint ccpIphone(CGPoint pt)
{
	//    if (!iPhoneRuningOnGame()) {
	//        return pt;
	//    }else{
	CGSize scr_size=[[UIScreen mainScreen] bounds].size;
	if (scr_size.height!=568) {
		return ccp(pt.x + 44 ,pt.y);
	}else{                         //Iphone5
		return ccp(pt.x + 44,pt.y);
	}
	//    }
}

static inline float ccpIphone4X(float f)
{
	CGSize scr_size=[[UIScreen mainScreen] bounds].size;
	if (scr_size.height!=568) {
		return f + 44;
	}else{           //Iphone5
		return f;
	}
}


static inline BOOL isIphone5()
{
    CGSize scr_size=[[UIScreen mainScreen] bounds].size;
    if (scr_size.height==568) {//Iphone5
        return YES;
    }else{
        return NO;
    }
}

static inline CGPoint ccpHalf(CGPoint pt)
{
    return ccp(pt.x/2,pt.y/2);
}

/////////////////////////////////////////////////////////
#define CCP_SCALE   getscale()
static inline float getscale(){
    if (iPhoneRuningOnGame()) {
        return 0.5;
    }else
        return 1;
}



static inline float getDistanceByTouchs(NSSet*touches){
	if([touches count]<2) return 0;
	NSArray * ts = [touches allObjects];
	UITouch * touch1 = [ts objectAtIndex:0];
	UITouch * touch2 = [ts objectAtIndex:1];
	CGPoint tp1 = [touch1 locationInView:[touch1 view]];
	CGPoint tp2 = [touch2 locationInView:[touch2 view]];
	return ccpDistance(tp1, tp2);
}

static inline bool isEmo(NSString *d){
	NSData *data=[d dataUsingEncoding:NSUTF8StringEncoding];
	if(data.length>10){
		return false;
	}
	char tempstr[4];
	[data getBytes:tempstr];
	
	int sx=tempstr[1];
	int fx=tempstr[0];
	CCLOG(@"%x %x",(int)tempstr[0],(int)tempstr[1]);
	if(tempstr[0]=='\xe2' && sx>=0xffffff80 && sx<0xffffff9f){
		return true;
	}
	if(tempstr[0]=='\xf0' && sx>=0xffffff80 && sx<=0xffffff9f){
		return true;
	}
	if(fx>=49 && fx<=58 && tempstr[1]=='\xe2'){
		return true;
	}
	return false;
}

static inline float getAniScale(int _tid){
	
	if (_tid == 43)	return 2.0f;
	
	if (_tid == 28) return 2.0f;
	if (_tid == 29) return 2.0f;
	
	//todo 好多ID 要处理
	if (_tid == 38) return 2.0f;
	if (_tid == 45) return 2.0f;
	//------------------
	if (_tid == 39) return 2.0f;
	if (_tid == 46) return 2.0f;
	//------------------
	if (_tid == 1001) return 2.0f;
	if (_tid == 1004) return 2.0f;
	if (_tid == 1005) return 2.0f;
	if (_tid == 1006) return 2.0f;
	
	return 1.0f;
}

#import "sys/utsname.h"
static NSString * getDeviceName(){
	struct utsname systemInfo;
	uname(&systemInfo);
	NSString * machine = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
	NSArray * machines = [machine componentsSeparatedByString:@","];
	return [machines objectAtIndex:0];
}


static inline float getCombatCool(int _hurt){
	if (_hurt < 1) return 0.0f;
	
	if (_hurt < 10*10000) {
		return 20;
	}else if (_hurt < 20*10000){
		return 35;
	}else if (_hurt < 30*10000){
		return 50;
	}else if (_hurt < 40*10000){
		return 75;
	}
	return (75 + (_hurt - 40*10000)*0.0001);
}

static inline NSDictionary* getParseSetting(int type){
	
	NSMutableDictionary* setting = [NSMutableDictionary dictionary];
	[setting setObject:@"*" forKey:@"tr"];
	[setting setObject:@"|" forKey:@"td"];
	[setting setObject:@"#" forKey:@"cell"]; //
	[setting setObject:@"^" forKey:@"bl"]; //blank line
	[setting setObject:@"{!" forKey:@"brewLeft"];
	[setting setObject:@"}" forKey:@"brewRight"];
	return setting;
	
}

static inline id getArrayListDataByKey(id target, NSString*key){
	NSMutableDictionary * result = [NSMutableDictionary dictionary];
	
	if([target isKindOfClass:[NSArray class]]){
		for(NSDictionary * dict in target){
			[result setObject:[dict objectForKey:key]
					   forKey:[dict objectForKey:key]];
		}
	}
	
	if([target isKindOfClass:[NSDictionary class]]){
		for(NSString * tmp in target){
			NSDictionary * dict = [(NSDictionary*)target objectForKey:tmp];
			[result setObject:[dict objectForKey:key]
					   forKey:[dict objectForKey:key]];
		}
	}
	
	return [result allValues];
}

static inline float getAngle(CGPoint pt1, CGPoint pt2){
	float dx1 = pt2.x - pt1.x;
    float dy1 = pt2.y - pt1.y;
	
    float r1 = sqrt(dx1 * dx1 + dy1 * dy1);
    float a1 = asinf(dy1/r1);
	float angle = CC_RADIANS_TO_DEGREES(a1);
	
	if (a1 >= 0) {
		if (dx1 < 0) {
			angle = 180 - fabsf(angle);
		}
	}
	
	if (a1 < 0) {
		if (dx1 <= 0) {
			angle = 180 + fabsf(angle);
		}else{
			angle = 360 - fabsf(angle);
		}
	}
	
	return angle;
}
static inline NSArray* getSpecialCharacter(){
	NSMutableArray* setting = [NSMutableArray array];
	[setting addObject:@"~"];
	[setting addObject:@"!"];
	[setting addObject:@"@"];
	[setting addObject:@"#"];
	[setting addObject:@"$"];
	[setting addObject:@"%"];
	[setting addObject:@"^"];
	[setting addObject:@"&"];
	[setting addObject:@"*"];
	[setting addObject:@"("];
	[setting addObject:@")"];
	[setting addObject:@"+"];
	[setting addObject:@"_"];
	[setting addObject:@"-"];
	[setting addObject:@"="];
	[setting addObject:@"<"];
	[setting addObject:@">"];
	[setting addObject:@"?"];
	[setting addObject:@":"];
	return setting;
}

static inline NSArray* getOtherProperty(){
	NSMutableArray* propertys = [NSMutableArray array];
	[propertys addObject:@"hurt_p"];
	[propertys addObject:@"addHp"];
	[propertys addObject:@"addHp_p"];
	return propertys;
}

static inline CGPoint getFinalPosition(CCNode *node){
	if (node == nil) return CGPointZero;
		
	CGSize winSize = [CCDirector sharedDirector].winSize;
	CGRect rect = node.boundingBox;
	float offsetX = 0;
	float offsetY = 0;
	
	float leftX = rect.origin.x;
	float rightX = rect.origin.x+rect.size.width;
	float bottomY = rect.origin.y;
	float topY = rect.origin.y+rect.size.height;
	
	if (leftX < 0) {
		offsetX = -leftX;
	}
	if (rightX>winSize.width) {
		offsetX = -(rightX-winSize.width);
	}
	if (bottomY < 0) {
		offsetY = -bottomY;
	}
	if (topY>winSize.height) {
		offsetY = -(topY-winSize.height);
	}
	return ccpAdd(node.position, ccp(offsetX, offsetY));
}
