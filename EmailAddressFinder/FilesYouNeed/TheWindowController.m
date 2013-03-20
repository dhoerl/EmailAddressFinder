//
//  TheWindowController.m
//  EmailAddressFinder
//
//  Created by David Hoerl on 3/20/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//

#import "TheWindowController.h"
#import "EmailSearcher.h"

@interface TheWindowController ()
@end

@implementation TheWindowController
{
	IBOutlet NSTextView *testString;
	IBOutlet NSTextView *resultsList;
	
	EmailSearcher *es;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	es = [EmailSearcher new];
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)windowWillClose:(NSNotification *)notification
{
	dispatch_async(dispatch_get_main_queue(), ^
		{
			[[NSApplication sharedApplication] terminate:self];
		} );
}

- (IBAction)testAction:(id)sender
{
	NSString *str = [testString string];
	if(![str length]) {
		NSBeep();
	} else {
		[resultsList setString:@""];
	
		NSArray *a = [es findMatchesInString:str];
		NSMutableString *str = [NSMutableString stringWithCapacity:256];
		NSString *entry;
		
		for(id foo in a) {
			if(es.wantMailboxSpecifiers) {
				NSDictionary *dict = (NSDictionary *)foo;
				entry = [NSString stringWithFormat:@"Name: %@ Address: %@  Mailbox: %@", dict[@"name"], dict[@"address"], dict[@"mailbox"]];
			} else {
				entry = (NSString *)foo;
			}
		}
		[str appendString:entry];
		[str appendString:@"\n"];
		
		[resultsList setString:str];
	}
}
- (IBAction)quitAction:(id)sender
{
	dispatch_async(dispatch_get_main_queue(), ^
		{
			[[NSApplication sharedApplication] terminate:self];
		} );
}

- (IBAction)mailboxAction:(id)sender
{
	NSButton *but = (NSButton *)sender;
	
	BOOL useMailbox = [but state] == NSOnState;
	
	es.wantMailboxSpecifiers = useMailbox;
}

- (IBAction)regexSelection:(id)sender
{
	es.regex = [(NSPopUpButton *)sender titleOfSelectedItem];
}

@end
