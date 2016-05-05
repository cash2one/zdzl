//
//  NSData+GZIP.m
//
//  Version 1.0
//
//  Created by Nick Lockwood on 03/06/2012.
//  Copyright (C) 2012 Charcoal Design
//
//  Distributed under the permissive zlib License
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/Gzip
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//


#import "NSData+GZIP.h"
#import <zlib.h>


#define CHUNK_SIZE 16384


@implementation NSData (GZIP)

+(NSData*) gzipData: (NSData*)pUncompressedData  
{  
    /* 
     Special thanks to Robbie Hanson of Deusty Designs for sharing sample code 
     showing how deflateInit2() can be used to make zlib generate a compressed 
     file with gzip headers: 
	 
	 http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html 
	 
     */  
	
    if (!pUncompressedData || [pUncompressedData length] == 0)  
    {  
        //NSLog(@"%s: Error: Can't compress an empty or null NSData object.", __func__);  
        return nil;  
    }  
	
    /* Before we can begin compressing (aka "deflating") data using the zlib 
     functions, we must initialize zlib. Normally this is done by calling the 
     deflateInit() function; in this case, however, we'll use deflateInit2() so 
     that the compressed data will have gzip headers. This will make it easy to 
     decompress the data later using a tool like gunzip, WinZip, etc. 
	 
     deflateInit2() accepts many parameters, the first of which is a C struct of 
     type "z_stream" defined in zlib.h. The properties of this struct are used to 
     control how the compression algorithms work. z_stream is also used to 
     maintain pointers to the "input" and "output" byte buffers (next_in/out) as 
     well as information about how many bytes have been processed, how many are 
     left to process, etc. */  
    z_stream zlibStreamStruct;  
    zlibStreamStruct.zalloc    = Z_NULL; // Set zalloc, zfree, and opaque to Z_NULL so  
    zlibStreamStruct.zfree     = Z_NULL; // that when we call deflateInit2 they will be  
    zlibStreamStruct.opaque    = Z_NULL; // updated to use default allocation functions.  
    zlibStreamStruct.total_out = 0; // Total number of output bytes produced so far  
    zlibStreamStruct.next_in   = (Bytef*)[pUncompressedData bytes]; // Pointer to input bytes  
    zlibStreamStruct.avail_in  = [pUncompressedData length]; // Number of input bytes left to process  
	
    /* Initialize the zlib deflation (i.e. compression) internals with deflateInit2(). 
     The parameters are as follows: 
	 
     z_streamp strm - Pointer to a zstream struct 
     int level      - Compression level. Must be Z_DEFAULT_COMPRESSION, or between 
	 0 and 9: 1 gives best speed, 9 gives best compression, 0 gives 
	 no compression. 
     int method     - Compression method. Only method supported is "Z_DEFLATED". 
     int windowBits - Base two logarithm of the maximum window size (the size of 
	 the history buffer). It should be in the range 8..15. Add  
	 16 to windowBits to write a simple gzip header and trailer  
	 around the compressed data instead of a zlib wrapper. The  
	 gzip header will have no file name, no extra data, no comment,  
	 no modification time (set to zero), no header crc, and the  
	 operating system will be set to 255 (unknown).  
     int memLevel   - Amount of memory allocated for internal compression state. 
	 1 uses minimum memory but is slow and reduces compression 
	 ratio; 9 uses maximum memory for optimal speed. Default value 
	 is 8. 
     int strategy   - Used to tune the compression algorithm. Use the value 
	 Z_DEFAULT_STRATEGY for normal data, Z_FILTERED for data 
	 produced by a filter (or predictor), or Z_HUFFMAN_ONLY to 
	 force Huffman encoding only (no string match) */  
    
	//int initError = deflateInit2(&zlibStreamStruct, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);  
	int initError = deflateInit(&zlibStreamStruct, Z_DEFAULT_COMPRESSION);
	
    if (initError != Z_OK)  
    {  
        NSString *errorMsg = nil;  
        switch (initError)  
        {  
            case Z_STREAM_ERROR:  
                errorMsg = @"Invalid parameter passed in to function.";  
                break;  
            case Z_MEM_ERROR:  
                errorMsg = @"Insufficient memory.";  
                break;  
            case Z_VERSION_ERROR:  
                errorMsg = @"The version of zlib.h and the version of the library linked do not match.";  
                break;  
            default:  
                errorMsg = @"Unknown error code.";  
                break;  
        }  
        //NSLog(@"%s: deflateInit2() Error: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg);  
        [errorMsg release];  
        return nil;  
    }  
	
    // Create output memory buffer for compressed data. The zlib documentation states that  
    // destination buffer size must be at least 0.1% larger than avail_in plus 12 bytes.  
    NSMutableData *compressedData = [NSMutableData dataWithLength:[pUncompressedData length] * 1.01 + 12];  
	
    int deflateStatus;  
    do  
    {  
        // Store location where next byte should be put in next_out  
        zlibStreamStruct.next_out = [compressedData mutableBytes] + zlibStreamStruct.total_out;  
		
        // Calculate the amount of remaining free space in the output buffer  
        // by subtracting the number of bytes that have been written so far  
        // from the buffer's total capacity  
        zlibStreamStruct.avail_out = [compressedData length] - zlibStreamStruct.total_out;  
		
        /* deflate() compresses as much data as possible, and stops/returns when 
         the input buffer becomes empty or the output buffer becomes full. If 
         deflate() returns Z_OK, it means that there are more bytes left to 
         compress in the input buffer but the output buffer is full; the output 
         buffer should be expanded and deflate should be called again (i.e., the 
         loop should continue to rune). If deflate() returns Z_STREAM_END, the 
         end of the input stream was reached (i.e.g, all of the data has been 
         compressed) and the loop should stop. */  
        deflateStatus = deflate(&zlibStreamStruct, Z_FINISH);  
		
    } while ( deflateStatus == Z_OK );        
	
    // Check for zlib error and convert code to usable error message if appropriate  
    if (deflateStatus != Z_STREAM_END)  
    {  
        NSString *errorMsg = nil;  
        switch (deflateStatus)  
        {  
            case Z_ERRNO:  
                errorMsg = @"Error occured while reading file.";  
                break;  
            case Z_STREAM_ERROR:  
                errorMsg = @"The stream state was inconsistent (e.g., next_in or next_out was NULL).";  
                break;  
            case Z_DATA_ERROR:  
                errorMsg = @"The deflate data was invalid or incomplete.";  
                break;  
            case Z_MEM_ERROR:  
                errorMsg = @"Memory could not be allocated for processing.";  
                break;  
            case Z_BUF_ERROR:  
                errorMsg = @"Ran out of output buffer for writing compressed bytes.";  
                break;  
            case Z_VERSION_ERROR:  
                errorMsg = @"The version of zlib.h and the version of the library linked do not match.";  
                break;  
            default:  
                errorMsg = @"Unknown error code.";  
                break;  
        }  
        //NSLog(@"%s: zlib error while attempting compression: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg);  
        [errorMsg release];  
		
        // Free data structures that were dynamically created for the stream.  
        deflateEnd(&zlibStreamStruct);  
		
        return nil;  
    }  
    // Free data structures that were dynamically created for the stream.  
    deflateEnd(&zlibStreamStruct);  
    [compressedData setLength: zlibStreamStruct.total_out];  
    //NSLog(@"%s: Compressed file from %d KB to %d KB", __func__, [pUncompressedData length]/1024, [compressedData length]/1024);  
	
    return compressedData;  
}  


- (NSData *)gzippedDataWithCompressionLevel:(float)level
{
    if ([self length])
    {
        z_stream stream;
        stream.zalloc = Z_NULL;
        stream.zfree = Z_NULL;
        stream.opaque = Z_NULL;
        stream.avail_in = (uint)[self length];
        stream.next_in = (Bytef *)[self bytes];
        stream.total_out = 0;
        stream.avail_out = 0;
        
        int compression = (level < 0.0f)? Z_DEFAULT_COMPRESSION: (int)roundf(level * 9);
        if (deflateInit2(&stream, compression, Z_DEFLATED, 31, 8, Z_DEFAULT_STRATEGY) == Z_OK)
        {
            NSMutableData *data = [NSMutableData dataWithLength:CHUNK_SIZE];
            while (stream.avail_out == 0)
            {
                if (stream.total_out >= [data length])
                {
                    data.length += CHUNK_SIZE;
                }
                stream.next_out = [data mutableBytes] + stream.total_out;
                stream.avail_out = (uint)([data length] - stream.total_out);
                deflate(&stream, Z_FINISH);
            }
            deflateEnd(&stream);
            data.length = stream.total_out;
            return data;
        }
    }
    return nil;
}

- (NSData *)gzippedData
{
    return [self gzippedDataWithCompressionLevel:-1.0f];
}

- (NSData *)gunzippedData
{
    if ([self length])
    {
        z_stream stream;
        stream.zalloc = Z_NULL;
        stream.zfree = Z_NULL;
        stream.avail_in = (uint)[self length];
        stream.next_in = (Bytef *)[self bytes];
        stream.total_out = 0;
        stream.avail_out = 0;
        
        NSMutableData *data = [NSMutableData dataWithLength: [self length] * 1.5];
        if (inflateInit2(&stream, 47) == Z_OK)
        {
            int status = Z_OK;
            while (status == Z_OK)
            {
                if (stream.total_out >= [data length])
                {
                    data.length += [self length] * 0.5;
                }
                stream.next_out = [data mutableBytes] + stream.total_out;
                stream.avail_out = (uint)([data length] - stream.total_out);
                status = inflate (&stream, Z_SYNC_FLUSH);
            }
            if (inflateEnd(&stream) == Z_OK)
            {
                if (status == Z_STREAM_END)
                {
                    data.length = stream.total_out;
                    return data;
                }
            }
        }
    }
    return nil;
}

@end
