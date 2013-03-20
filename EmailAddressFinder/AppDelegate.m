//
//  AppDelegate.m
//  EmailAddressFinder
//
//  Created by David Hoerl on 3/20/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//

#import "AppDelegate.h"
#import "TheWindowController.h"

@implementation AppDelegate
{
	TheWindowController *wc;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	wc = [[TheWindowController alloc] initWithWindowNibName:@"TheWindowController"];
	assert(wc);
	assert(wc.window);
	[wc.window makeKeyAndOrderFront:self];
}

@end
