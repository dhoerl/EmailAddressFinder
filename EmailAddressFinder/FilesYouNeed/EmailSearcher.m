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

- (NSArray *)findMailtoItems:(NSString *)str
{
	NSMutableArray *items = [NSMutableArray array];
	NSScanner *s = [NSScanner scannerWithString:str];
	while(!s.isAtEnd) {
		BOOL ret = [s scanUpToString:@"mailto:\"" intoString:NULL];
		if(ret && !s.isAtEnd) {
			[s scanString:@"mailto:\"" intoString:NULL];
			
			__autoreleasing NSString *mailTo;
			ret = [s scanUpToString:@"\"" intoString:&mailTo];
			if(!ret || s.isAtEnd) {
				NSLog(@"ERROR");
				break;
			}
			[s scanString:@"\"" intoString:NULL];	// for completeness
			
			NSDictionary *mailToDict = [self mailltoItemFrom:mailTo];
			if(mailToDict) {
				[items addObject:mailToDict];
			}
		}
	}
	return [items copy];
}

- (NSDictionary *)mailltoItemFrom:(NSString *)mailTo
{
	NSScanner *s = [NSScanner scannerWithString:mailTo];
	NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"=&?"];
	NSArray *addrs;

	NSMutableDictionary *dict;
	__autoreleasing NSString *val;
	BOOL ret = [s scanUpToString:@"?" intoString:&val];
	if(ret) {
		addrs = [self emailsFromString:val];
		[s scanCharactersFromSet:set intoString:NULL];
		if([addrs count]) {
			dict = [NSMutableDictionary dictionaryWithCapacity:5];
			dict[@"to"] = addrs;
		}
	}
	while(!s.isAtEnd && dict) {
		ret = [s scanUpToString:@"=" intoString:&val];
		if(!ret) break;
		[s scanCharactersFromSet:set intoString:NULL];
		NSString *type = [val copy];

		ret = [s scanUpToString:@"&" intoString:&val];
		if(!ret) break;
		[s scanCharactersFromSet:set intoString:NULL];
	
		if([@"cc" isEqualToString:type]) {
			addrs = [self emailsFromString:val];
			if([addrs count]) {
				dict[@"cc"] = addrs;
			}
		} else
		if([@"bcc" isEqualToString:type]) {
			addrs = [self emailsFromString:val];
			if([addrs count]) {
				dict[@"bcc"] = addrs;
			}
		} else
		if([@"subject" isEqualToString:type]) {
			addrs = [self emailsFromString:val];
			if([addrs count]) {
				dict[@"subject"] = [addrs lastObject];
			}
		} else
		if([@"body" isEqualToString:type]) {
			addrs = [self emailsFromString:val];
			if([addrs count]) {
				dict[@"body"] = [addrs lastObject];
			}
		}		
	}
	// NSLog(@"DICT: %@", dict);
	return [dict copy];
}
- (NSArray *)emailsFromString:(NSString *)str
{
	NSArray *array = [str componentsSeparatedByString:@","];
	NSUInteger count = [array count];
	NSMutableArray *mArray = [NSMutableArray arrayWithCapacity:count];
	[array enumerateObjectsUsingBlock:^(NSString *rawAddr, NSUInteger idx, BOOL *stop)
		{
			NSString *first = [rawAddr stringByReplacingOccurrencesOfString:@"+" withString:@" "];
			NSString *second = [first stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			[mArray addObject:second];
		}];
	return mArray;
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
