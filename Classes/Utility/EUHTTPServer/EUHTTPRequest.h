//
//  EUHTTPRequest.h
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EUHTTPRequest;
@protocol EUHTTPRequestDelegate<NSObject>

- (void) httpRequest:(EUHTTPRequest*) request didCompleteWithError:(NSError*) error;

@end


@interface EUHTTPRequest : NSObject<NSStreamDelegate> {
	NSInputStream *inputStream;
	CFHTTPMessageRef message;
	id <EUHTTPRequestDelegate> delegate;
	NSMutableDictionary* arguments;
	NSString* contentType;
	NSInteger contentLength;
	NSString* boundary;
}
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, assign, readonly) CFHTTPMessageRef message;
@property (nonatomic, assign) id <EUHTTPRequestDelegate> delegate;
@property (nonatomic, readonly) NSURL* url;
@property (nonatomic, readonly) NSString* method;
@property (nonatomic, readonly) NSData* body;
@property (nonatomic, readonly) NSDictionary* arguments;
@property (nonatomic, readonly) NSString* contentType;
@property (nonatomic, readonly) NSInteger contentLength;
@property (nonatomic, readonly) NSString* boundary;

- (id)initWithInputStream:(NSInputStream *)readStream 
				 delegate:(id<EUHTTPRequestDelegate>) anObject;

- (void) run;

@end
