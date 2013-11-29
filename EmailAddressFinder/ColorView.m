//
//  ColorView.m
//  EmailAddressFinder
//
//  Created by David Hoerl on 7/30/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//

#import "ColorView.h"

@implementation ColorView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];

	[self.backgroundColor set];
	
    NSRectFill(dirtyRect);
}

@end
