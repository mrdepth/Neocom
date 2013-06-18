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

#define EUHTTPServerErrorNoSocketsAvailable NSLocalizedString(@"No sockets available", nil)
#define EUHTTPServerErrorCouldNotBindToIPv4Address NSLocalizedString(@"Could not bind to IPv4 address", nil)
#define EUHTTPServerErrorCouldNotBindOrEstablishNetService NSLocalizedString(@"Could not bind or establish Net Service", nil)

typedef enum {
	EUHTTPServerErrorCodeNoSocketsAvailable = 1,
	EUHTTPServerErrorCodeCouldNotBindToIPv4Address,
	EUHTTPServerErrorCodeCouldNotBindOrEstablishNetService
	
} EUHTTPServerErrorCode;

@class EUHTTPServer;
@protocol EUHTTPServerDelegate<NSObject>

- (void) server:(EUHTTPServer*) server didReceiveRequest:(EUHTTPRequest*) request connection:(EUHTTPConnection*) connection;

@end


@interface EUHTTPServer : NSObject<EUHTTPConnectionDelegate, NSNetServiceDelegate>

@property (nonatomic, strong) NSNetService * netService;
@property (nonatomic, strong) NSMutableSet * connections;
@property (assign) CFSocketRef ipv4socket;
@property (nonatomic, assign) id<EUHTTPServerDelegate> delegate;

- (id)initWithDelegate:(id<EUHTTPServerDelegate>) anObject;
- (BOOL) setupServer:(NSError **)error;
- (void) run;
- (void) shutdown;
- (void) handleConnection:(NSString *)peerName inputStream:(NSInputStream *)readStream outputStream:(NSOutputStream *)writeStream;

@end
