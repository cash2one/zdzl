#import <Foundation/NSData.h>
@class NSString;
@interface NSData (AES256) 
-(NSData*)AES256EncryptWithKey:(NSString*)key;
-(NSData*)AES256DecryptWithKey:(NSString*)key;

-(NSData*)AES128EncryptWithKey:(NSString*)key;
-(NSData*)AES128DecryptWithKey:(NSString*)key;

@end
