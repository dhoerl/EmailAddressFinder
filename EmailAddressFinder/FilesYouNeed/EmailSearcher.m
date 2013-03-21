//
//  EmailSearcher.m
//  EmailAddressFinder
//
//  Created by David Hoerl on 3/20/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//

#import "EmailSearcher.h"

static NSCharacterSet *atSign;

@implementation EmailSearcher
{
	NSRegularExpression *reg;
	BOOL hasNL;
	BOOL hasCR;
}

+ (void)initialize
{
	if(self == [EmailSearcher class]) {
		atSign = [NSCharacterSet characterSetWithCharactersInString:@"@"];
	}
}

- (instancetype)init
{
	if((self = [super init])) {
		self.regex = @"Regex1";
	}
	return self;
}

- (void)setRegex:(NSString *)str
{
	_regex = [str copy];
	
	[self setup];
}

- (void)setup
{
	NSString *fullPath = [[NSBundle mainBundle] pathForResource:self.regex ofType:@"txt"];
	NSString *pattern = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:NULL];
	__autoreleasing NSError *error = nil;
	reg = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error]; // some patterns may not need NSRegularExpressionCaseInsensitive
	assert(reg && !error);
}

- (NSArray *)findMatchesInString:(NSString *)origStr
{
	// Pretest - if not possible to contain addresses then stop now
	{
		NSRange range = [origStr rangeOfCharacterFromSet:atSign];
		if(range.location == NSNotFound) {
			return nil;
		}
	}

	NSString *str = [origStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	// str = [origStr stringByReplacingOccurrencesOfString:@"\r" withString:@""]; // if needbe

	NSArray *ret = [reg matchesInString:str options:0 range:NSMakeRange(0, [str length])];
	NSMutableArray *mret;
	if(ret) {
		mret = [NSMutableArray arrayWithCapacity:[ret count]];

		for(NSTextCheckingResult *spec in ret) {
			NSRange r = spec.range;
			unichar c = r.location ? [str characterAtIndex:r.location - 1] : 0;
			unichar d = (r.location+r.length) < [str length] ? [str characterAtIndex:r.location+r.length] : 0;
			NSDictionary *entry;
			NSString *address;

			NSLog(@"MATCH: -%@-", [str substringWithRange:r]);

			// not the first character of the string
			if(c == '<' && d == '>') {
				// Someone provided a mailbox style address
				address = [str substringWithRange:r];
				{
					--r.location;
					r.length += 2;

					// Find the full "name" field
					NSInteger loc		= r.location - 1;
					NSInteger origLoc	= r.location;
					NSInteger endLoc	= r.location;

					BOOL isQuoted = NO;
					BOOL foundChar = NO;
					BOOL matchingQuotes = NO;

					while(loc >= 0) {
						unichar t = [str characterAtIndex:loc--];
						BOOL escaped = loc >= 0 && [str characterAtIndex:loc] == '\\';

						// handle escaped characters
						if(escaped) {
							if(!foundChar) {
								endLoc = loc+2;	// one past the first real char
							}
							foundChar = YES;
							--loc;	// skip it
							continue;
						}

						// Have space, not escaped
						if(t == ' ' || t == '\t') {
							if(foundChar) {
								if(!isQuoted) {
									break;	// got the full name now
								}
							} else {
								// still looking for that first character
								continue;
							}
						}
						
						// Have a real character now
						if(!foundChar) {
							endLoc = loc+2;	// one past the first real char
						}
						
						// handle quotes
						if(t == '"') {
							if(!foundChar) {
								isQuoted = YES;
							} else {
								// Got the whole string
								matchingQuotes = YES;
								break;
							}
						}
						
						// Now we can set it!
						foundChar = YES;
					}
					++loc;
					
					NSString *name;
					NSInteger realEndLoc = r.location + r.length;
					if(foundChar && !(isQuoted && !matchingQuotes)) {
						// If we got an initial quote, better have found the matching one
						NSRange nameRange = NSMakeRange(loc, endLoc - loc);
						name = [str substringWithRange:nameRange];
						r.location = loc;
					} else {
						name = @"";
						r.location = origLoc;
					}
					r.length = realEndLoc - r.location;
					//NSLog(@"loc %d endLoc=%d RANGE %@ str=%@", loc, realEndLoc, NSStringFromRange(r), str);
					NSString *mailbox = [str substringWithRange:r];
					
					entry = @{ @"name" : name, @"address" : address, @"mailbox" : mailbox };
				}
			} else {
				address = [str substringWithRange:r];
				entry = @{ @"address" : address };
			}
			[mret addObject:entry];
		}
	}
	return mret;
}

- (BOOL)isValidEmail:(NSString *)str
{
	BOOL ret = NO;
	NSUInteger len = [str length];

	NSTextCheckingResult *match = [reg firstMatchInString:str options:0 range:NSMakeRange(0, len)];
	if(match) {
		NSRange r = match.range;
		if(r.location == 0 && r.length == len) {
			ret = YES;
		}
	}
	return ret;
}

@end
