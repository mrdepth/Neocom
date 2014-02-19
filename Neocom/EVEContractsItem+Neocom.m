//
//  EVEContractsItem+Neocom.m
//  Neocom
//
//  Created by Shimanski Artem on 19.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "EVEContractsItem+Neocom.h"
#import <objc/runtime.h>

@implementation EVEContractsItem (Neocom)

- (NCLocationsManagerItem*) startStation {
	return objc_getAssociatedObject(self, @"startStation");
}

- (NCLocationsManagerItem*) endStation {
	return objc_getAssociatedObject(self, @"endStation");
}

- (NSString*) issuerName {
	return objc_getAssociatedObject(self, @"issuerName");
}

- (NSString*) issuerCorpName {
	return objc_getAssociatedObject(self, @"issuerCorpName");
}

- (NSString*) assigneeName {
	return objc_getAssociatedObject(self, @"assigneeName");
}

- (NSString*) acceptorName {
	return objc_getAssociatedObject(self, @"acceptorName");
}

- (NSString*) forCorpName {
	return objc_getAssociatedObject(self, @"forCorpName");
}

- (void) setStartStation:(NCLocationsManagerItem *)startStation {
	return objc_setAssociatedObject(self, @"startStation", startStation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setEndStation:(NCLocationsManagerItem *)endStation {
	return objc_setAssociatedObject(self, @"endStation", endStation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setIssuerName:(NSString *)issuerName {
	return objc_setAssociatedObject(self, @"issuerName", issuerName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setIssuerCorpName:(NSString *)issuerCorpName {
	return objc_setAssociatedObject(self, @"issuerCorpName", issuerCorpName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setAssigneeName:(NSString *)assigneeName {
	return objc_setAssociatedObject(self, @"assigneeName", assigneeName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setAcceptorName:(NSString *)acceptorName {
	return objc_setAssociatedObject(self, @"acceptorName", acceptorName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setForCorpName:(NSString *)forCorpName {
	return objc_setAssociatedObject(self, @"forCorpName", forCorpName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
