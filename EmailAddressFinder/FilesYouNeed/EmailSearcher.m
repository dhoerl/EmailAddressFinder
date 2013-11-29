//
// EmailSearcher.m
// Copyright (C) 2013 by David Hoerl
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "EmailSearcher.h"

static NSCharacterSet *atSign;

@interface EmailSearcher ()
@property (nonatomic, strong) NSRegularExpression *regEx;
@property (nonatomic, strong) NSString *regExStr;

@end

@implementation EmailSearcher
{
	BOOL hasNL;
	BOOL hasCR;
	
	NSString *comment;
}

+ (void)initialize
{
	if(self == [EmailSearcher class]) {
		atSign = [NSCharacterSet characterSetWithCharactersInString:@"@"];
	}
}

+ (instancetype)emailSearcherWithRegexStr:(NSString *)str
{
	EmailSearcher *es;
	if([str length]) {
		__autoreleasing NSError *error;
		NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:str options:0 error:&error];
		if(regEx) {
			es = [EmailSearcher new];
			es.regExStr = [str copy];
			es.regEx = regEx;
		} else {
			NSLog(@"YIKES! Error %@", error);
		}
	}
	return es;
}

- (instancetype)init
{
	if((self = [super init])) {
	}
	return self;
}

- (BOOL)isValidEmail:(NSString *)str
{
	BOOL ret = NO;
	NSUInteger len = [str length];

	assert(_regEx);
//NSLog(@"Start[%@]...", str);
	NSTextCheckingResult *match = [_regEx firstMatchInString:str options:0 range:NSMakeRange(0, len)];
	if(match) {
		NSRange r = match.range;
		if(r.location == 0 && r.length == len) {
			ret = YES;
		}
	}
//NSLog(@"...result = %@", ret ? @"success" : @"FAILED"); // test for stalling
	if(ret) {
		if(![self isValidEmailReturningComponents:str]) ret = NO;
	}

	return ret;
}

- (NSDictionary *)isValidEmailReturningComponents:(NSString *)str
{
	BOOL ret = NO;
	NSUInteger len = [str length];

	assert(_regEx);
	NSTextCheckingResult *match = [_regEx firstMatchInString:str options:0 range:NSMakeRange(0, len)];
	if(match) {
		NSRange r = match.range;
		if(r.location == 0 && r.length == len) {
			ret = YES;
		}
	}
//NSLog(@"...result = %@", ret ? @"success" : @"FAILED");
	if(ret) {
		return [self parseEmail:str withSpec:match];
	} else {
		return nil;
	}
}

- (NSDictionary *)parseEmail:(NSString *)str withSpec:(NSTextCheckingResult *)spec
{
	NSUInteger numRanges = [spec numberOfRanges];
	//NSMutableArray *array = [NSMutableArray arrayWithCapacity:numRanges];
	//BOOL angleAddr = NO;
	NSUInteger indexOfAtSign = NSNotFound;
	NSUInteger indexOfAngleBracket = NSNotFound;

	NSRange r = spec.range;
	//unichar c = r.location ? [str characterAtIndex:r.location - 1] : 0;
	//unichar d = (r.location+r.length) < [str length] ? [str characterAtIndex:r.location+r.length] : 0;
	//NSDictionary *entry;
	//NSString *address;

//NSLog(@"MATCH: -%@- numGroups=%ld", [str substringWithRange:r], [spec numberOfRanges]);
	
	NSMutableString *displayName		= [NSMutableString stringWithCapacity:64];
	NSMutableString *localPart			= [NSMutableString stringWithCapacity:64];
	NSMutableString *domain				= [NSMutableString stringWithCapacity:64];
	NSMutableString *displayNameNoCmnt	= [NSMutableString stringWithCapacity:64];
	NSMutableString *localPartNoCmnt	= [NSMutableString stringWithCapacity:64];
	NSMutableString *domainNoCmnt		= [NSMutableString stringWithCapacity:64];

	for(NSUInteger j = 1; j< numRanges; ++j) {
		NSRange r2 = [spec rangeAtIndex:j];
//NSLog(@"RANGE=%@", NSStringFromRange(r2));
		if(r2.location != NSNotFound && r2.length) {
			NSString *s	= [str substringWithRange:r2];
			unichar c	= [s characterAtIndex:0];
			//NSLog(@"GROUP[%ld]: -%@-", j, [str substringWithRange:r2]);
			if([s isEqualToString:@"@"]) {
				if(indexOfAngleBracket == NSNotFound) {
					[localPart setString:displayName];
					[localPartNoCmnt setString:displayNameNoCmnt];
					[displayName setString:@""];
					[displayNameNoCmnt setString:@""];
				}
				indexOfAtSign = j;
				continue;
			} else
			if([s isEqualToString:@"<"]) {
				// earlier comments associated with "display-name"
				indexOfAngleBracket = j;
			} else
			if([s isEqualToString:@">"]) {
				// This code does not deal with trailing comments after the '>'
				break;
			}
			if(indexOfAtSign == NSNotFound) {
				if(indexOfAngleBracket == NSNotFound) {
					if(c != '(') [displayNameNoCmnt appendString:s];
					[displayName appendString:s];
				} else {
					if(c != '(') [localPartNoCmnt appendString:s];
					[localPart appendString:s];
				}
			} else {
				if(c != '(') [domainNoCmnt appendString:s];
				[domain appendString:s];
			}
		}
	}

	NSString *lpnc = [localPartNoCmnt stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
	NSString *dpnc = [domainNoCmnt stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
	NSUInteger localPartLen		= [lpnc length];
	NSUInteger domainPartLen	= [dpnc length];

	if(localPartLen > 64) {
		NSLog(@"YIKES! Local %zd too long \"%@\"", localPartLen, lpnc);
		return nil;
	}
	if((localPartLen + domainPartLen + 1) > 254) {
		NSLog(@"YIKES! TOTAL %zd-%zd too long \"%@ @ %@\"", localPartLen, domainPartLen, lpnc, dpnc);
		return nil;
	}
	
	NSDictionary *dict = @{
							sIsMailBoxFormat	: indexOfAngleBracket == NSNotFound ? @NO : @YES,
							sDisplayName		: [displayName stringByReplacingOccurrencesOfString:@"\r\n" withString:@""],
							sLocalPart			: [localPart stringByReplacingOccurrencesOfString:@"\r\n" withString:@""],
							sDomain				: [domain stringByReplacingOccurrencesOfString:@"\r\n" withString:@""]
						} ;
	
	return dict;
}

#if WANT_SEARCH == 1

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

	NSMutableArray *mret;
	NSArray *ret = [_regEx matchesInString:str options:0 range:NSMakeRange(0, [str length])];
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

#endif

#if WANT_MAILTO == 1

- (BOOL)isValidMailTo:(NSString *)str
{
	BOOL flag;
	NSArray *array = [self findMailtoItems:str atEnd:&flag];
	
	return [array count] == 1 && flag == YES;
}

- (NSArray *)findMailtoItems:(NSString *)str
{
	return [self findMailtoItems:str atEnd:NULL];
}

- (NSArray *)findMailtoItems:(NSString *)str atEnd:(BOOL *)flag
{
	NSMutableArray *items = [NSMutableArray array];

	if(flag) *flag = NO;	// presume failure

	NSScanner *s = [NSScanner scannerWithString:str];
	while(!s.isAtEnd) {
		if(flag) *flag = NO;
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
			if(flag) *flag = YES;
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

#endif

@end

email_components *email_to_components(const regex_t *preg, const char *str)
{
	regmatch_t *pmatch = malloc(sizeof(regmatch_t) * preg->re_nsub);
	email_components *comps;
	
	int ret = regexec(preg, str, preg->re_nsub, pmatch, 0);
	if(!ret) {
		size_t len = strlen(str) + 1;
		comps = (email_components *)calloc(sizeof(email_components), 1);
		comps->display_name	= (char *)calloc(len, 1);
		comps->local_part	= (char *)calloc(len, 1);
		comps->domain		= (char *)calloc(len, 1);
		char *s				= (char *)calloc(len, 1);
		
		regoff_t index_of_at_sign = -1;
		regoff_t index_of_angle_bracket = -1;
		
		regmatch_t *matches = pmatch+1;
		for(int i=1; i<preg->re_nsub; ++i, ++matches) {
			regoff_t rlen = matches->rm_eo - matches->rm_so;
			
			if((matches->rm_so == -1 && matches->rm_eo == -1) || rlen <= 0) continue;
			//NSLog(@"MATCH[%d] str len=%ld so=%lx eo=%lx rlen=%ld", i, strlen(str), (long)matches->rm_so, (long)matches->rm_eo, (long)rlen);

			strncpy(s, str+matches->rm_so, rlen);
			s[rlen] = '\0';
			
			//NSLog(@"GROUP[%ld]: -%@-", j, [str substringWithRange:r2]);
			if(s[0] == '@') {
				if(index_of_angle_bracket == -1) {
					strcpy(comps->local_part, comps->display_name);
					strcpy(comps->display_name, "");
				}
				index_of_at_sign = matches->rm_so;
				continue;
			} else
			if(s[0] == '<') {
				// earlier comments associated with "display-name"
				index_of_angle_bracket = matches->rm_so;
			} else
			if(s[0] == '>') {
				// This code does not deal with trailing comments after the '>'
				break;
			}
			if(index_of_at_sign == -1) {
				if(index_of_angle_bracket == -1) {
					strcat(comps->display_name, s);
				} else {
					strcat(comps->local_part, s);
				}
			} else {
				strcat(comps->domain, s);
			}
		}
		free(s);

		size_t localPartLen		= strlen(comps->local_part);
		size_t domainPartLen	= strlen(comps->domain);

		if(localPartLen > 64) {
			NSLog(@"YIKES! Local too long");
			free_email_comps(comps);
			return NULL;
		}
		if((localPartLen + domainPartLen + 1) > 254) {
			NSLog(@"YIKES! Total too long");
			free_email_comps(comps);
			return NULL;
		}
	} else {
		comps = NULL;
	}

	free(pmatch);

	return comps;
}

void free_email_comps(email_components *comps)
{
	if(comps) {
		free(comps->display_name);
		free(comps->local_part);
		free(comps->domain);
		free(comps);
	}
}
