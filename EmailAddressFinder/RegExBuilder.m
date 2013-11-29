//
//  RegExBuilder.m
//  EmailAddressFinder
//
//  Created by David Hoerl on 7/15/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//


#import "RegExBuilder.h"

@interface RegExBuilder ()
// must be named exactly per the k properties in the interface file
@property (nonatomic, strong) NSString *commentString;
@property (nonatomic, strong) NSString *mailboxString;
@property (nonatomic, strong) NSString *angleAddrSpecString;
@property (nonatomic, strong) NSString *dispNameString;
@property (nonatomic, strong) NSString *nameAddrString;
@property (nonatomic, strong) NSString *ipv6String;
@property (nonatomic, strong) NSString *fwsString;
@property (nonatomic, strong) NSString *cfwsString;
@property (nonatomic, strong) NSString *testString;
@property (nonatomic, strong) NSNumber *nestLevel;
@property (nonatomic, strong) NSNumber *addrSpecOnly;
@property (nonatomic, strong) NSNumber *posix;
@property (nonatomic, strong) NSNumber *validateMode;
@property (nonatomic, strong) NSNumber *allowCFWS;
@property (nonatomic, strong) NSNumber *captureGroups;
@property (nonatomic, strong) NSNumber *compressFWS;
@property (nonatomic, strong) NSNumber *allowNullStr;
@property (nonatomic, strong) NSNumber *rfc5321IPV6;
@property (nonatomic, strong) NSNumber *rfc5321Len;

@end

@implementation RegExBuilder

+ (instancetype)regBuilder:(NSDictionary *)options
{
	RegExBuilder *re = [RegExBuilder new];
	
	NSArray *args;
	args =  @[
					kCommentString, kMailboxString, kAngleAddrSpec, kDisplayName, kNameAddress, kIPV6String, kFWS, kCommentFWS, kTestString,
					kCommentLevel, kAddrSpecOnly, kPOXIXcompliant, kValidateRegEx, kAllowCFWSwithAT, kCaptureGroups, kCompressedFWS,
					kAllowNullStr, kUseRFC5321IPV6, kUseRFC5321Len
				];
	[args enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
		{
			id optVal = options[obj];
			//NSLog(@"OBJ=%@ VAL=%@", obj, optVal);
			if([optVal isKindOfClass:[NSString class]]) {
				//NSLog(@"%@=\n%@", obj, optVal);
				optVal = (id)[self processString:(NSString *)optVal];
			}
			assert(optVal);
			[re setValue:optVal forKey:obj];
		}];
	return re;
}

+ (NSString *)processString:(NSString *)origStr
{
	NSMutableString *str = [NSMutableString stringWithCapacity:[origStr length]];
	NSArray *array = [origStr componentsSeparatedByString:@"\n"];
	[array enumerateObjectsUsingBlock:^(NSString *sub, NSUInteger idx, BOOL *stop)
		{
			if(![sub length]) return;
		
			NSArray *line = [sub componentsSeparatedByString:@" #"];	// Strip comments
			NSString *first = line[0];
			first = [first stringByReplacingOccurrencesOfString:@" " withString:@""];
			first = [first stringByReplacingOccurrencesOfString:@"\t" withString:@""];
			if([first length]) {
				[str appendString:first];
			}
		} ];
	// NSLog(@"REGEX file=%@: %@", name, str);
	return str;
}

- (NSString *)regex
{
	NSString *insertCommentString = @"";
	
	typedef enum { rfcMode, testMode } mode_t;
	mode_t mode = [self.testString length] ? testMode : rfcMode;

	NSString *captureString;
	if([self.captureGroups boolValue]) {
		captureString = @"";
	} else {
		captureString = @"?:";
	}
	
	//NSLog(@"filename=%@ processMode=%d", fileName, processMode);

	// build up the "recursive" comment string to the specified depth, for use later
	//NSLog(@"NEST=%ld", nestLevel);
	if([self.nestLevel integerValue]) {
		insertCommentString = self.commentString;
		NSMutableString *s = [NSMutableString new];
		[s setString:[insertCommentString stringByReplacingOccurrencesOfString:@"CMNT" withString:@""]];  // wipe the original marker, not in the original

		// NSLog(@"INSERT: %@", insertCommentString);
		// NSLog(@"CMNT0: %@", s);

		for(int i=1; i<[self.nestLevel integerValue]; ++i) {
			NSString *cmtNoCGs = [s stringByReplacingOccurrencesOfString:@"CG" withString:@"?:"];	// Capture various items (or not) // or ?:
			[s setString:[insertCommentString stringByReplacingOccurrencesOfString:@"CMNT" withString:[@"|" stringByAppendingString:cmtNoCGs]]];
			
			//NSLog(@"CMNT[%d]: %@", i, s);
		}
		insertCommentString = s;
	}
	//NSLog(@"insertCommentString: %@", insertCommentString);

	NSString *pattern;
	{
		NSLog(@"REPLACE MIN_ADDR_LEN with %@", [self.allowNullStr boolValue]? @"*" : @"+");
		NSString *nameAddr = [self.nameAddrString stringByReplacingOccurrencesOfString:@"MIN_ADDR_LEN" withString:[self.allowNullStr boolValue]? @"*" : @"+"];
		if(mode == rfcMode) {
			NSString *str;
			if([self.addrSpecOnly boolValue]) {
				str = [NSString stringWithFormat:@"%@%@%@", @"CFWS?", nameAddr, @"CFWS?"];
				//NSLog(@"SELECT %@", str);
			} else {
				assert([self.mailboxString length]);
				assert([self.dispNameString length]);
				assert([self.angleAddrSpecString length]);
				str = self.mailboxString;
				str = [str stringByReplacingOccurrencesOfString:@"DISPLAY_NAME" withString:self.dispNameString];
				str = [str stringByReplacingOccurrencesOfString:@"ANGLE_ADDR" withString:self.angleAddrSpecString];
				//str = [NSString stringWithFormat:@"CFWS?(?:ADDR-SPEC|(?:%@CFWS?%@))CFWS?", self.dispNameString, self.angleAddrSpecString]; // GOOD
				//NSString *str = [NSString stringWithFormat:@"%@", self.angleAddrSpecString];
			}
			assert([nameAddr length]);
			pattern = [str stringByReplacingOccurrencesOfString:@"ADDR-SPEC" withString:nameAddr];
		} else {
			assert([self.testString length]);
			pattern = self.testString;
		}
		assert([pattern length]);
	}
	
	NSString *ipv6;
	if([self.rfc5321IPV6 boolValue]) {
		assert([self.ipv6String length]);
		ipv6 = [self.ipv6String stringByReplacingOccurrencesOfString:@"HEX_NUM" withString:@"[1-9A-Fa-f](?:[0-9A-Fa-f]{0,3})"];
	} else {
		ipv6 = @"(?:FWS?[\\x21-\\x5a\\x5e-\\x7e])*FWS?";	// From RFC-5322.txt, as the ABNF specifies
	}
	pattern = [pattern stringByReplacingOccurrencesOfString:@"IPV6" withString:ipv6];
//NSLog(@"FINAL insertCommentString: %@", insertCommentString);	
	
	// Must do this first as CFWS replaced next
	pattern = [pattern stringByReplacingOccurrencesOfString:@"CFWS_OPTION" withString:[self.allowCFWS boolValue] ? @"CFWS?" : @""];
	assert([pattern length]);
	pattern = [pattern stringByReplacingOccurrencesOfString:@"CFWS" withString:self.cfwsString];
	assert([pattern length]);

	pattern = [pattern stringByReplacingOccurrencesOfString:@"CMNT" withString:[insertCommentString length] ? insertCommentString : self.fwsString];

	if([self.compressFWS boolValue]) {
		pattern = [pattern stringByReplacingOccurrencesOfString:@"FWS?" withString:[self.compressFWS boolValue] ? @"(?:\x20)*" : self.fwsString];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"FWS" withString:[self.compressFWS boolValue] ? @"(?:\x20)+" : self.fwsString];
	} else {
		pattern = [pattern stringByReplacingOccurrencesOfString:@"FWS" withString:[self.compressFWS boolValue] ? @"xxx" : self.fwsString];
	}
	assert([pattern length]);

	pattern = [pattern stringByReplacingOccurrencesOfString:@"CG" withString:captureString];	// Capture various items (or not) // or ?:

	if([self.posix boolValue]) {
		// For POSIX versions
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x0a" withString:@"\\n"];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x0d" withString:@"\\r"];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x09" withString:@"\\t"];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x20" withString:@" "];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x21" withString:@"!"];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x23" withString:@"#"];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x27" withString:@"'"];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x28" withString:@"("];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x2a" withString:@"*"];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x5a" withString:@"Z"];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x5b" withString:@"\\["];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x5d" withString:@"\\]"];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x5e" withString:@"^"];
		pattern = [pattern stringByReplacingOccurrencesOfString:@"\\x7e" withString:@"~"];
	}
	assert([pattern length]);
	if([self.validateMode boolValue]) {
		pattern = [NSString stringWithFormat:@"^%@$", pattern];
	}

NSLog(@"PATTERN Len [%ld] %@", [pattern length], pattern);

#if 1
	__autoreleasing NSError *error = nil;
	NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error]; // some patterns may not need NSRegularExpressionCaseInsensitive
	if(!regEx) NSLog(@"ERROR: %@", error);
	assert(regEx);

#if 0
  EmailSearcher *e = [EmailSearcher emailSearcherWithRegexStr:pattern];
  if(![e isValidEmail:@"first(Welcome to\r\n the (\"wonderful\" (!)) world\r\n of email)@example.com"]) {
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

@end
