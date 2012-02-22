//
//  URLImageView.m
//  URLImageView
//
//  Created by Artem Shimanski on 11/1/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "URLImageView.h"


@implementation URLImageView
@synthesize delegate = _delegate;
@synthesize url = _url;
@synthesize isLoading = _isLoading;
@synthesize activityIndicatorView = _activityIndicatorView;

- (void) setImageWithContentsOfURL: (NSURL*) url {
	[self setImageWithContentsOfURL:url scale:1];
}

- (void) setImageWithContentsOfURL: (NSURL*) url scale: (float) scale {
	URLImageViewManager *manager = [URLImageViewManager sharedManager];
	if (self.isLoading && self.url) {
		[_delegate release];
		[manager cancelPreviousRequestWithURL:self.url delegate:self];
	}
	else
		self.isLoading = YES;
	self.url = url;
	if (!url) {
		self.isLoading = NO;
		return;
	}
	[_delegate retain];
	_scale = scale;
	[manager requestImageWithContentsOfURL:url delegate:self];
}

- (void) dealloc {
	[_url release];
	[_activityIndicatorView release];
	[super dealloc];
}

- (UIActivityIndicatorView*) activityIndicatorView {
	if (!_activityIndicatorView) {
		_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		_activityIndicatorView.hidesWhenStopped = YES;
		_activityIndicatorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
		[self addSubview:_activityIndicatorView];
	}
	return _activityIndicatorView;
}

- (void) setIsLoading:(BOOL)value {
	_isLoading = value;
	if (_isLoading)
		[self.activityIndicatorView startAnimating];
	else
		[self.activityIndicatorView stopAnimating];
}

- (void) layoutSubviews {
	[super layoutSubviews];
	_activityIndicatorView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

#pragma mark URLImageViewManagerDelegate

- (void) imageViewManager: (URLImageViewManager*) manager didReceiveImage: (UIImage*) image {
	self.image = [UIImage imageWithCGImage:[image CGImage] scale:_scale orientation:image.imageOrientation];
	self.isLoading = NO;
	[_delegate imageView:self didReceiveImage:image];
	[_delegate release];
}

- (void) imageViewManager: (URLImageViewManager*) manager didFailWithError: (NSError*) error {
	self.isLoading = NO;
	[_delegate imageView:self didFailWithError:error];
	[_delegate release];
}

@end
