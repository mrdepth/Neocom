//
//  EUHTTPServer.m
//  EVEUniverse
//
//  Created by Shimanski on 8/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EUHTTPServer.h"
#import "UIAlertView+Error.h"
#include <CFNetwork/CFSocketStream.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <arpa/inet.h>

static void httpServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    __weak EUHTTPServer * server = (__bridge EUHTTPServer *)info;
    if (kCFSocketAcceptCallBack == type) {
        // for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
        struct sockaddr_in peerAddress;
        socklen_t peerLen = sizeof(peerAddress);
        NSString * peer = nil;
		
        if (getpeername(nativeSocketHandle, (struct sockaddr *)&peerAddress, (socklen_t *)&peerLen) == 0) {
            peer = [NSString stringWithUTF8String:inet_ntoa(peerAddress.sin_addr)];
		} else {
			peer = @"Generic Peer";
		}
		
        CFReadStreamRef readStream = NULL;
		CFWriteStreamRef writeStream = NULL;
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
		
        if (readStream && writeStream) {
            CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            [server handleConnection:peer inputStream:(__bridge_transfer NSInputStream *)readStream outputStream:(__bridge_transfer NSOutputStream *)writeStream];
        } else {
            // on any failure, need to destroy the CFSocketNativeHandle
            // since we are not going to use it any more
            close(nativeSocketHandle);
        }
    }
}

@implementation EUHTTPServer

- (id)initWithDelegate:(id<EUHTTPServerDelegate>) anObject {
	if (self = [super init]) {
		self.delegate = anObject;
		self.connections = [NSMutableSet set];
	}
	return self;
}

- (void) dealloc {
	[self shutdown];
}

- (void)handleConnection:(NSString *)peerName inputStream:(NSInputStream *)readStream outputStream:(NSOutputStream *)writeStream {
	
	if (peerName != nil && readStream != nil && writeStream != nil) {
		EUHTTPConnection * newPeer = [[EUHTTPConnection alloc] initWithInputStream:readStream 
																outputStream:writeStream 
																		peer:peerName 
																	delegate:self];
		
		if (newPeer) {
			[newPeer run];
			[self.connections addObject:newPeer];
		}
	}
}

- (BOOL) setupServer:(NSError **)error {
	uint16_t chosenPort = 0;
	struct sockaddr_in serverAddress;
	socklen_t nameLen = 0;
	nameLen = sizeof(serverAddress);
	
	if (self.netService && _ipv4socket) {
		return YES;
	} else {
		
		if (!_ipv4socket) {
			CFSocketContext socketCtxt = {0, (__bridge void*) self, NULL, NULL, NULL};
			_ipv4socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&httpServerAcceptCallBack, &socketCtxt);
			
			if (!_ipv4socket) {
				if (error)
					*error = [[NSError alloc] initWithDomain:EUHTTPServerErrorDomain
														 code:EUHTTPServerErrorCodeNoSocketsAvailable
													userInfo:@{NSLocalizedDescriptionKey: EUHTTPServerErrorNoSocketsAvailable}];
				[self shutdown];
				return NO;
			}
			
			int yes = 1;
			setsockopt(CFSocketGetNative(_ipv4socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
			
			// set up the IPv4 endpoint; use port 0, so the kernel will choose an arbitrary port for us, which will be advertised using Bonjour
			memset(&serverAddress, 0, sizeof(serverAddress));
			serverAddress.sin_len = nameLen;
			serverAddress.sin_family = AF_INET;
			serverAddress.sin_port = htons(8080);
			serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
			NSData * address4 = [NSData dataWithBytes:&serverAddress length:nameLen];
			
			if (kCFSocketSuccess != CFSocketSetAddress(_ipv4socket, (__bridge CFDataRef)address4)) {
				if (error)
					*error = [[NSError alloc] initWithDomain:EUHTTPServerErrorDomain
														 code:EUHTTPServerErrorCodeCouldNotBindToIPv4Address
													userInfo:@{NSLocalizedDescriptionKey: EUHTTPServerErrorCouldNotBindToIPv4Address}];
				if (_ipv4socket)
					CFRelease(_ipv4socket);
				_ipv4socket = NULL;
				return NO;
			}
			
			// now that the binding was successful, we get the port number 
			// -- we will need it for the NSNetService
			NSData * addr = (__bridge_transfer NSData *)CFSocketCopyAddress(_ipv4socket);
			memcpy(&serverAddress, [addr bytes], [addr length]);
			chosenPort = ntohs(serverAddress.sin_port);
			
			// set up the run loop sources for the sockets
			CFRunLoopRef cfrl = CFRunLoopGetCurrent();
			CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4socket, 0);
			CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
			CFRelease(source);
		}
		
		if (!self.netService && _ipv4socket) {
			self.netService = [[NSNetService alloc] initWithDomain:@"local" type:@"_http._tcp" name:@"Neocom" port:chosenPort];
			[self.netService setDelegate:self];
		}
		
		if (!self.netService && !_ipv4socket) {
			if (error)
				*error = [[NSError alloc] initWithDomain:EUHTTPServerErrorDomain
													 code:EUHTTPServerErrorCodeCouldNotBindOrEstablishNetService
												userInfo:@{NSLocalizedDescriptionKey: EUHTTPServerErrorCouldNotBindOrEstablishNetService}];
			[self shutdown];
			return NO;
		}
	}
	return YES;
}

- (void)run {
	NSError *error = nil;
	[self setupServer:&error];
	if (error)
		[[UIAlertView alertViewWithError:error] show];
	else {
		[self.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		[self.netService publish];
	}
}

- (void)shutdown {
	if (self.netService) {
		[self.connections removeAllObjects];
		[self.netService stop];
		[self.netService removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
		self.netService = nil;
	}
	if (_ipv4socket) {
		CFSocketInvalidate(_ipv4socket);
		CFRelease(_ipv4socket);
		_ipv4socket = NULL;
	}
}

#pragma mark NSNetServiceDelegate

- (void)netServiceDidPublish:(NSNetService *)sender {
    self.netService = sender;
}

#pragma mark EUHTTPConnectionDelegate

- (void) connectionDidClose:(EUHTTPConnection*) connection {
	[self.connections removeObject:connection];
}

- (void) connection:(EUHTTPConnection*) connection didReceiveRequest:(EUHTTPRequest*) request {
	[self.delegate server:self didReceiveRequest:request connection:connection];
}

@end
