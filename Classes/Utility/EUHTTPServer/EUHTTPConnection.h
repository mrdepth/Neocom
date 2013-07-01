//
//  EUHTTPRequest.h
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EUHTTPRequest.h"
#import "EUHTTPResponse.h"

@class EUHTTPConnection;
@protocol EUHTTPConnectionDelegate

- (void) connectionDidClose:(EUHTTPConnection*) connection;
- (void) connection:(EUHTTPConnection*) connection didReceiveRequest:(EUHTTPRequest*) request;

@end


@interface EUHTTPConnection: NSObject<EUHTTPRequestDelegate, EUHTTPResponseDelegate>
@property (nonatomic, strong) NSString *peerName;
@property (nonatomic, weak) id <EUHTTPConnectionDelegate> delegate;
@property (nonatomic, strong) EUHTTPRequest *request;
@property (nonatomic, strong) EUHTTPResponse *response;

- (id)initWithInputStream:(NSInputStream *)readStream 
			 outputStream:(NSOutputStream *) writeStream 
					 peer:(NSString *) peerAddress 
				 delegate:(id<EUHTTPConnectionDelegate>) anObject;

- (void) run;

@end
