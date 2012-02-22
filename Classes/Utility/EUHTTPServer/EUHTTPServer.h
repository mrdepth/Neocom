//
//  EUHTTPServer.h
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUHTTPConnection.h"

#define EUHTTPServerErrorDomain @"EUHTTPServerErrorDomain"

#define EUHTTPServerErrorNoSocketsAvailable @"No sockets available"
#define EUHTTPServerErrorCouldNotBindToIPv4Address @"Could not bind to IPv4 address"
#define EUHTTPServerErrorCouldNotBindOrEstablishNetService @"Could not bind or establish Net Service"

typedef enum {
	EUHTTPServerErrorCodeNoSocketsAvailable = 1,
	EUHTTPServerErrorCodeCouldNotBindToIPv4Address,
	EUHTTPServerErrorCodeCouldNotBindOrEstablishNetService
	
} EUHTTPServerErrorCode;

@class EUHTTPServer;
@protocol EUHTTPServerDelegate<NSObject>

- (BOOL) server:(EUHTTPServer*) server didReceiveKeyID:(NSInteger) keyID vCode:(NSString*) vCode error:(NSError**) errorPtr;

@end


@interface EUHTTPServer : NSObject<EUHTTPConnectionDelegate, NSNetServiceDelegate> {
	NSMutableSet * connections;
	NSNetService * netService;
	CFSocketRef ipv4socket;
	id<EUHTTPServerDelegate> delegate;
}

@property (nonatomic, retain) NSNetService * netService;
@property (nonatomic, retain) NSMutableSet * connections;
@property (assign) CFSocketRef ipv4socket;
@property (nonatomic, assign) id<EUHTTPServerDelegate> delegate;

- (id)initWithDelegate:(id<EUHTTPServerDelegate>) anObject;
- (BOOL) setupServer:(NSError **)error;
- (void) run;
- (void) shutdown;
- (void) handleConnection:(NSString *)peerName inputStream:(NSInputStream *)readStream outputStream:(NSOutputStream *)writeStream;

@end
