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


@interface EUHTTPRequest : NSObject<NSStreamDelegate>
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, assign, readonly) CFHTTPMessageRef message;
@property (nonatomic, weak) id <EUHTTPRequestDelegate> delegate;
@property (nonatomic, readonly) NSURL* url;
@property (nonatomic, readonly) NSString* method;
@property (nonatomic, readonly) NSData* body;
@property (nonatomic, strong) NSMutableDictionary* arguments;
@property (nonatomic, strong) NSString* contentType;
@property (nonatomic, assign) NSInteger contentLength;
@property (nonatomic, strong) NSString* boundary;

- (id)initWithInputStream:(NSInputStream *)readStream 
				 delegate:(id<EUHTTPRequestDelegate>) anObject;

- (void) run;

@end
