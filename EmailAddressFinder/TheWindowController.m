//  TheWindowController.m
//  EmailAddressFinder
//
//  Created by David Hoerl on 3/20/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.


//#define TEST_MODE
//#define EXT_REGEX

#ifdef EXT_REGEX
#include <regex.h>
#endif


#import "TheWindowController.h"
#import "EmailSearcher.h"
#import "TestRegExWithExternalFiles.h"
#import "RegExBuilder.h"
#import "ColorView.h"

#if 0
<href mailto:"fred@smith.com,gooper@glop.com,Fro+ggy@glop.com?cc=fred@smith.com,gooper@glop.com,Fro+ggy@glop.com&bcc=fred@smith.com,gooper@glop.com,Fro+ggy@glop.com&subject=glop&body=goop">
#endif
@interface TheWindowController ()
@end
   
typedef enum { validateMode=1, scanMode } regex_typ;

@interface TheWindowController () <ReportProtocol>
@end

@implementation TheWindowController
{
	IBOutlet NSPopUpButton	*regExButton;
	IBOutlet NSButton		*validateButton;
	IBOutlet NSButton		*scanAddressesButton;
	IBOutlet NSButton		*scanMailTosButton;
	IBOutlet NSButton		*interactiveButton;
	IBOutlet NSTextView		*testString;
	
	IBOutlet NSButton		*captureGroups;
	IBOutlet NSButton		*addrSpecOnly;
	IBOutlet NSButton		*allowCFWS;
	IBOutlet NSButton		*posix;
	IBOutlet NSButton		*fullFWS;
	IBOutlet NSButton		*allowNullString;	// local-name -> ""
	IBOutlet NSButton		*rfc5321IPV6;
	IBOutlet NSButton		*rfc5321Lengths;
	IBOutlet NSButton		*optionsForValidating;
	IBOutlet ColorView		*validatingOptionsState;
	IBOutlet NSButton		*optionsForCompliance;
	IBOutlet ColorView		*complianceOptionsState;

	IBOutlet NSSlider		*cmntLevelSlider;
	IBOutlet NSTextField	*cmntLevelValue;

	IBOutlet NSSegmentedControl	*pasteType;
	IBOutlet NSButton		*pasteTextButton;
	IBOutlet NSButton		*pasteStringButton;

	IBOutlet NSButton		*regressionTests;

	NSString				*oldInput;
	NSString				*interInput;
	NSString				*fileName;	// true for Test and Mailto

	IBOutlet NSTextView		*resultsList;
	
	// Deal with comments
	BOOL					isComment;
	NSUInteger				nestLevel;
	
	EmailSearcher *es;
#ifdef EXT_REGEX
	regex_t rx;
#endif
}

- (void)resultUpdate:(NSString *)str
{
	NSString *oldStr = [resultsList string];
	[resultsList setString:[oldStr stringByAppendingString:[NSString stringWithFormat:@"\n%@", str]]];
}

- (void)windowDidLoad
{
    [super windowDidLoad];

	// switch between testing components and the whole kaboodle
#ifndef TEST_MODE
	[regExButton selectItemWithTitle:@"RFC-5322"];
#else
	[regExButton selectItemWithTitle:@"Test"];
	//[interactiveButton setState:NSOnState];
	//[self interactiveMode:interactiveButton];

#endif

	[self regexSelection:regExButton];
	
[testString setString:@"\"Fuddy\" <dhoerl@mac.com>"];
[testString setString:@"test_exa-mple.com"];
		[cmntLevelSlider setIntegerValue:1];
		[cmntLevelValue setStringValue:@"1"];

	interInput = [[testString string] copy];

	[self definedOptions:validateButton];
	[self updateUI:nil];
}

- (void)windowWillClose:(NSNotification *)notification
{
	dispatch_async(dispatch_get_main_queue(), ^
		{
			[[NSApplication sharedApplication] terminate:self];
		} );
}

- (IBAction)updateUI:(id)sender
{
	BOOL isOff = [interactiveButton state] == NSOffState;

	//NSLog(@"INTERACTIVE: isOff = %d", isOff);
	
	regExButton.enabled = isOff;
	regExButton.enabled = isOff;
	validateButton.enabled = isOff;
	scanAddressesButton.enabled = isOff;
	scanMailTosButton.enabled = isOff;

	captureGroups.enabled = isOff;
	addrSpecOnly.enabled = isOff;
	allowCFWS.enabled = isOff;
	posix.enabled = isOff;
	fullFWS.enabled = isOff;
	allowNullString.enabled = isOff;
	rfc5321IPV6.enabled = isOff;
	rfc5321Lengths.enabled = isOff;

	optionsForValidating.enabled = isOff;
	optionsForCompliance.enabled = isOff;
	cmntLevelSlider.enabled = isOff;
	
	pasteType.enabled = isOff;
	pasteTextButton.enabled = isOff;
	pasteStringButton.enabled = isOff;

	regressionTests.enabled = isOff;

	[cmntLevelValue setIntegerValue:[cmntLevelSlider integerValue]];
	
	NSColor *color;

	// Validating
	if(
		[captureGroups state] == NSOffState		&&
		[addrSpecOnly state] == NSOnState		&&
		[allowCFWS state] == NSOffState			&&
		[posix state] == NSOnState				&&
		[fullFWS state] == NSOffState			&&
		[allowNullString state] == NSOffState	&&
		[rfc5321IPV6 state] == NSOffState		&&
		[rfc5321Lengths state] == NSOffState	&&
		[cmntLevelSlider integerValue] == 0
	) {
		color = [NSColor greenColor];
	} else {
		color = [NSColor redColor];
	}
	validatingOptionsState.backgroundColor = color;
	[validatingOptionsState setNeedsDisplay:YES];

	// Compliance
	if(
		[captureGroups state] == NSOnState		&&
		[addrSpecOnly state] == NSOffState		&&
		[posix state] == NSOnState				&&
		[fullFWS state] == NSOnState			&&
		[allowNullString state] == NSOnState	&&
		[rfc5321IPV6 state] == NSOnState		&&
		[rfc5321Lengths state] == NSOnState		&&
		[cmntLevelSlider integerValue] == 5
	) {
		color = [allowCFWS state] == NSOffState ? [NSColor greenColor] : [NSColor yellowColor];
	} else {
		color = [NSColor redColor];
	}
	complianceOptionsState.backgroundColor = color;
	[complianceOptionsState setNeedsDisplay:YES];
}

- (IBAction)regexSelection:(id)sender
{
	fileName = [(NSPopUpButton *)sender titleOfSelectedItem];
}

- (IBAction)quitAction:(id)sender
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
	if([fileName isEqualToString:@"Mailto"]) {
		[resultsList setString:@""];
		es = [EmailSearcher new];
		
		NSArray *a = [es findMailtoItems:str];
		NSMutableString *str = [NSMutableString stringWithCapacity:256];

		for(NSDictionary *dict in a) {
			[str appendString:dict.description];
			[str appendString:@"\n"];
		}
		
		[resultsList setString:str];
	} else {
		[resultsList setString:@""];
		NSString *regEx = [self createRegEx:scanMode];
		es = [EmailSearcher emailSearcherWithRegexStr:regEx];
		assert(es);
	
#ifdef xxx____EXT_REGEX
		int ret = regcomp(&rx, [regEx cStringUsingEncoding:NSASCIIStringEncoding], REG_EXTENDED | REG_NOSUB | REG_ENHANCED);
		assert(!ret);
#endif
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

- (IBAction)testSelection:(id)sender
{
	NSString *str = [testString string];
	BOOL ret = NO;
	NSString *retStr;

	if(![str length]) {
		NSBeep();
		retStr = @"";
	} else
	if([fileName isEqualToString:@"Mailto"]) {
		[resultsList setString:@""];
		es = [EmailSearcher new];

		ret = [es isValidMailTo:str];
		retStr = ret ? @"YES!" : @"No";
	} else {
		[resultsList setString:@""];
		NSString *regEx = [self createRegEx:validateMode];
		es = [EmailSearcher emailSearcherWithRegexStr:regEx];
		assert(es);
		
		ret = [es isValidEmail:str];
		retStr = ret ? @"YES!" : @"No";

#ifdef EXT_REGEX
		int val = regcomp(&rx, [regEx cStringUsingEncoding:NSASCIIStringEncoding], REG_EXTENDED |
			//REG_NOSUB |
			REG_ENHANCED);
		if(val) NSLog(@"BAD REGEX %s", [regEx cStringUsingEncoding:NSASCIIStringEncoding]);
		assert(!val);
		
#if 0
		const char *s = [regEx cStringUsingEncoding:NSASCIIStringEncoding];
		const char *s2 = "^[\\x5d]$";
		NSLog(@"len=%d len=%d", strlen(s), strlen(s2));
		for(int i=0; i<strlen(s); ++i) {
			NSLog(@"CHAR: %c %x %c %x", s[i], s[i], s2[i], s2[i]);
		}
		//int val = regcomp(&rx, "^[\x5d]$", REG_EXTENDED | REG_NOSUB | REG_ENHANCED);
		NSLog(@"STRCMP = %d", strcmp(s2, s));
		for(int i=0; i<strlen(s); ++i) {
		}"first\"last"@iana.org
#endif
		assert(str);
		if([str length]) {
			NSLog(@"str=%s", [str cStringUsingEncoding:NSASCIIStringEncoding]);
			val = regexec(&rx, [str cStringUsingEncoding:NSASCIIStringEncoding], 0, NULL, 0);
			//val = regexec(&rx, "]", 0, NULL, 0);

			retStr = [NSString stringWithFormat:@"NSRE: %@ IEEE=%@ str=\"%s\" "
						//"regEx=%s"
						, retStr, !val ? @"YES!" : @"No", [str cStringUsingEncoding:NSASCIIStringEncoding]
						//,  [regEx cStringUsingEncoding:NSASCIIStringEncoding]
						];
		}
#endif
	}
  assert(retStr);
	
	[resultsList setString:retStr];
}

- (IBAction)pasteRegex:(id)sender
{
	NSInteger tag = [sender tag];
	NSString *str = [self createRegEx:[pasteType selectedSegment] ? scanMode : validateMode];

	if(tag && [str length]) {
		// 1: One huge string
		// 2: multi-line
		if(tag == 2) {
			NSMutableString *m = [NSMutableString stringWithCapacity:[str length] + 64];
			[m appendString:@"•\n"]; // replace • with \\ at the very end
			
			NSUInteger len = [str length];
			BOOL chunkSize;
			for(NSUInteger i = 0; i < len; i += chunkSize) {
				chunkSize = (i + 80) <= len ? 80 : (len - i);
				if(chunkSize == 80) {
					while(YES) {
						unichar c = [str characterAtIndex:i+chunkSize-1];
						if(c == '\\') {
							--chunkSize;
							NSLog(@"HAHAHA GOTCHA %zd", chunkSize);
						} else {
							break;
						}
					}
				}
				NSRange r = (NSRange){i, chunkSize};
				NSString *sub = [str substringWithRange:r];
				[m appendString:sub];
				[m appendString:@"•\n"];
			}

			str = [m copy];
		}
		str = [str stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\" options:0 range:NSMakeRange(0, [str length])];
		str = [str stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, [str length])];
		if(tag == 2) {
			str = [str stringByReplacingOccurrencesOfString:@"•" withString:@"\\" options:0 range:NSMakeRange(0, [str length])];
		}
		str = [NSString stringWithFormat:@"@\"%@\"", str];
	}
	[resultsList setString:str];
}

- (IBAction)interactiveMode:(NSButton *)button
{
	BOOL isOff = [button state] == NSOffState;

	if(isOff) {
		interInput = testString ? [[testString string] copy] : @"";
		[testString setString:oldInput ? oldInput : @""];
	} else {
		oldInput = testString ? [[testString string] copy] : @"";
		[testString setString:interInput ? interInput : @""];
		dispatch_async(dispatch_get_main_queue(), ^
			{
				[self testSelection:nil];
			});
	}
}

- (IBAction)crlfAction:(id)sender
{
	NSString *test = [testString string];
	test = [test stringByAppendingString:@"\r\n"];
	[testString setString:test];
	
	[self textView:testString shouldChangeTextInRange:NSMakeRange(0,0) replacementString:@""];
}

- (IBAction)definedOptions:(id)sender
{
	if([sender tag]) {
		// Compliance
		[captureGroups setState:NSOnState];
		[addrSpecOnly setState:NSOffState];
		[allowCFWS setState:NSOffState];
		[posix setState:NSOnState];
		[fullFWS setState:NSOnState];
		[allowNullString setState:NSOnState];
		[rfc5321IPV6 setState:NSOnState];
		[rfc5321Lengths setState:NSOnState];
		[cmntLevelSlider setIntegerValue:5];
		[cmntLevelValue setStringValue:@"5"];
	} else {
		// Validating
		[captureGroups setState:NSOffState];
		[addrSpecOnly setState:NSOnState];
		[allowCFWS setState:NSOffState];
		[posix setState:NSOnState];
		[fullFWS setState:NSOffState];
		[allowNullString setState:NSOffState];
		[rfc5321IPV6 setState:NSOffState];
		[rfc5321Lengths setState:NSOffState];
		[cmntLevelSlider setIntegerValue:0];
		[cmntLevelValue setStringValue:@"0"];
	}
	
	[self updateUI:nil];
}

- (IBAction)runTestsAction:(id)sender
{
	TestRegExWithExternalFiles *r = [TestRegExWithExternalFiles new];
	r.delegate = self;
	r.posixToo = [posix state] == NSOnState;
	r.regEx = [self createRegEx:validateMode];
	
	[resultsList setString:@""];
	[r test];
}

- (NSString *)createRegEx:(regex_typ)style
{
	NSString *pattern;
	
	typedef enum { mailToMode=1, testMode, rfcMode } mode_t;
	mode_t mode;
	if([fileName isEqualToString:@"Test"]) {
		mode = testMode;
	} else
	if([fileName isEqualToString:@"RFC-5322"]) {
		mode = rfcMode;
	} else {
		mode = mailToMode;
	}
	
	BOOL processMode = (mode == rfcMode) | (mode == testMode);
	
//NSLog(@"filename=%@ processMode=%d", fileName, processMode);

	// build up the "recursive" comment string to the specified depth, for use later
	if(processMode) {
		NSString *insertCommentString = [self processFile:@"RFC-5322-Comment"];
		assert([insertCommentString length]);
		
		NSString *mailboxString = [self processFile:@"RFC-5322-Mailbox"];
		assert([mailboxString length]);

 		NSString *addrSpecString = [self processFile:@"RFC-5322-Addr-Spec"];
		assert([addrSpecString length]);

		NSString *dispNameString = [self processFile:@"RFC-5322-Display-Name"];
		assert([dispNameString length]);

		NSString *angleAddrString = [self processFile:@"RFC-5322-Angle-Addr"];
		assert([angleAddrString length]);
    
		NSString *fwsString = [self processFile:@"RFC-5322-FWS"];
		assert([fwsString length]);

		NSString *cfwsString = [self processFile:@"RFC-5322-CFWS"];
		assert([cfwsString length]);

		NSString *testFileString = mode == testMode ? [self processFile:fileName] : @"";
		if(mode == testMode) assert([testFileString length]);
		
		// (?: (?: (?: (?: \x09 | \x20 )* \x0d\x0a )? [\x21-\x5a\x5e-\x7e] )* (?: (?: \x09 | \x20 )* \x0d\x0a )? )
	
		NSString *ipv6 = [self processFile:@"RFC-5321-IPv6"];
		assert([ipv6 length]);

		// NSLog(@"COMMENT LEVEL %ld", [cmntLevelSlider integerValue]);
		NSDictionary *dict;
		dict = @{
			kCommentString		: insertCommentString,
			kMailboxString		: mailboxString,
			kAngleAddrSpec		: angleAddrString,
			kDisplayName		: dispNameString,
			kNameAddress		: addrSpecString,
			kIPV6String			: ipv6,
			kFWS				: fwsString,
			kCommentFWS			: cfwsString,
			kTestString			: testFileString,
			kCommentLevel		: @([cmntLevelSlider integerValue]),
			kAddrSpecOnly		: @([addrSpecOnly state] == NSOnState),
			kPOXIXcompliant		: @([posix state] == NSOnState),
			kValidateRegEx		: @(style == validateMode),
			kAllowCFWSwithAT	: @([allowCFWS state] == NSOnState),
			kCaptureGroups		: @([captureGroups state] == NSOnState),
			kCompressedFWS		: @([fullFWS state] == NSOffState),
			kAllowNullStr		: @([allowNullString state] == NSOnState),
			kUseRFC5321IPV6		: @([rfc5321IPV6 state] == NSOnState),
			kUseRFC5321Len		: @([rfc5321Lengths state] == NSOnState),
		};

	NSLog(@"CommentLevel %@", dict[kCommentLevel]);

		RegExBuilder *b = [RegExBuilder regBuilder:dict];
		pattern = [b regex];
	} else {
		pattern = [self processFile:fileName];
		if(style == validateMode){
			pattern = [NSString stringWithFormat:@"^%@$", pattern];
		}
	}
	assert([pattern length]);

	NSLog(@"PATTERN Len [%ld]", [pattern length]);

#if 1
	__autoreleasing NSError *error = nil;
	NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error]; // some patterns may not need NSRegularExpressionCaseInsensitive
	if(!regEx) NSLog(@"ERROR: %@", error);
	assert(regEx);
#if 0
  EmailSearcher *e = [EmailSearcher emailSearcherWithRegexStr:pattern];
  if(![e isValidEmail:@"\first(Welcome to\r\n the (\"wonderful\" (!)) world\r\n of email)@example.com"]) {
    // challenge on http://blog.dominicsayers.com/category/email-address-validation/
    NSLog(@"Dominic email failed!");
  }
    
  if(![e isValidEmail:@"\"test\r\n blah\"@iana.org"]) {
    NSLog(@"TEST email failed!");
  }
#endif
 
#endif
	return pattern;
}


// This processing lets us use white space, comments, and an end of "real data" marker in the file
- (NSString *)processFile:(NSString *)name
{
	// NSLog(@"PROCESS %@", name);
	NSString *file = [[NSBundle mainBundle] pathForResource:name ofType:@"txt"];
	assert(file);
	
	__autoreleasing NSError *error;
	NSString *origStr = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&error];

	NSMutableString *str = [NSMutableString stringWithCapacity:[origStr length]];
	NSArray *array = [origStr componentsSeparatedByString:@"\n"];
	[array enumerateObjectsUsingBlock:^(NSString *sub, NSUInteger idx, BOOL *stop)
		{
			if(![sub length]) return;
			if([sub characterAtIndex:0] == '#') return;
			if([sub characterAtIndex:0] == '.') { *stop = YES; return; }
			
			[str appendString:sub];
			[str appendString:@"\n"];
		} ];
	// NSLog(@"REGEX file=%@: %@", name, str);
	return str;
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	if(interactiveButton.state == NSOnState)
	{
		dispatch_async(dispatch_get_main_queue(), ^
			{
				[self testSelection:nil];
			} );
	}

	return YES;
}

@end
