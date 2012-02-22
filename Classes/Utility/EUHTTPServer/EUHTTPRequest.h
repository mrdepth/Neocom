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
}
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, assign, readonly) CFHTTPMessageRef message;
@property (nonatomic, assign) id <EUHTTPRequestDelegate> delegate;

- (id)initWithInputStream:(NSInputStream *)readStream 
				 delegate:(id<EUHTTPRequestDelegate>) anObject;

- (void) run;

@end
