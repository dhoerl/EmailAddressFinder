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
	IBOutlet NSPopUpButton *regExButton;
	
	EmailSearcher *es;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
	
	es = [EmailSearcher new];

	[regExButton selectItemWithTitle:@"Mailto"];
	[self regexSelection:regExButton];
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
	} else
	if([es.regex isEqualToString:@"Mailto"]) {
		[resultsList setString:@""];
	
		NSArray *a = [es findMailtoItems:str];
		NSMutableString *str = [NSMutableString stringWithCapacity:256];

		for(NSDictionary *dict in a) {
			[str appendString:dict.description];
			[str appendString:@"\n"];
		}
		
		[resultsList setString:str];
	} else {
		[resultsList setString:@""];
	
		NSArray *a = [es findMatchesInString:str];
		NSMutableString *str = [NSMutableString stringWithCapacity:256];
		
		for(id foo in a) {
			if([foo isMemberOfClass:[NSNull class]]) {
				NSLog(@"YIKES! failed to process address");
				continue;
			}
			NSDictionary *dict = (NSDictionary *)foo;
			NSString *entry;
			if(dict[@"mailbox"]) {
				entry = [NSString stringWithFormat:@"Address: %@  Name: %@  Mailbox: %@", dict[@"address"], dict[@"name"], dict[@"mailbox"]];
			} else {
				entry = [NSString stringWithFormat:@"Address: %@", dict[@"address"]];
			}
			[str appendString:entry];
			[str appendString:@"\n"];
		}
		
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

- (IBAction)regexSelection:(id)sender
{
	es.regex = [(NSPopUpButton *)sender titleOfSelectedItem];
}

- (IBAction)testSelection:(id)sender
{
	NSString *str = [testString string];

	BOOL val = [es isValidEmail:str];
	[resultsList setString:val ? @"YES!" : @"No"];

}

@end
