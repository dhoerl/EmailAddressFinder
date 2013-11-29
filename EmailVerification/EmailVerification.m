//
//  EmailVerification.m
//  EmailVerification
//
//  Created by David Hoerl on 6/22/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//

#define EXT_REGEX

#ifdef EXT_REGEX
#include <regex.h>
#endif

#import "EmailVerification.h"

#import "EmailSearcher.h"
#import "TBXML.h"
#import "HTMLDecode.h"


@implementation EmailVerification
{
	NSString *regEx;
	EmailSearcher *es;
	
#ifdef EXT_REGEX
	regex_t rx;
#endif
}

- (void)setUp
{
    [super setUp];
	
	NSString* regExPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestRegex" ofType:@"txt"];
	assert(regExPath);

	__autoreleasing NSError *error;
	regEx = [NSString stringWithContentsOfFile:regExPath encoding:NSUTF8StringEncoding error:&error];
	assert(regEx);

	es = [EmailSearcher emailSearcherWithRegexStr:regEx];
	assert(es);
	
#ifdef EXT_REGEX
	int ret = regcomp(&rx, [regEx cStringUsingEncoding:NSASCIIStringEncoding], REG_EXTENDED | REG_NOSUB | REG_ENHANCED);
	assert(!ret);
#endif
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (NSArray *)loadTests:(NSString *)name type:(NSArray *)types exclude:(NSArray *)excluded
{
	NSMutableArray *array = [NSMutableArray new];
	HTMLDecode *decoder = [HTMLDecode new];

	NSString* plistPath = [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"xml"];
	assert(plistPath);
	
	__autoreleasing NSError *error = nil;
	TBXML *contents = [TBXML newTBXMLWithXMLData:[NSData dataWithContentsOfFile:plistPath] error:&error];
	assert(!error);

	TBXMLElement *test = [TBXML childElementNamed:@"test" parentElement:contents.rootXMLElement];
	assert(test);
	do {
		//NSLog(@"TST %@", [TBXML elementName:test]);
		//NSLog(@"ID %@", [TBXML valueOfAttributeNamed:@"id" forElement:test]);
		
		NSString *category = [TBXML textForElement:[TBXML childElementNamed:@"category" parentElement:test]];

#if 0
		__block BOOL success = NO;
		[types enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop)
			{
				if([category isEqualToString:obj]) {
					success = YES;
					*stop = YES;
				}
			}];
#endif

BOOL success = [types containsObject:category];
if(!success) {
  if(![excluded containsObject:category]) NSLog(@"Yikes: not excluded! %@", category);
}

		if(success) {
			NSString *oldAddr = [TBXML textForElement:[TBXML childElementNamed:@"address" parentElement:test]];
			assert(oldAddr);
			NSString *newAddr = [decoder decodeString:oldAddr];
			assert(newAddr);
			//newAddr = [newAddr stringByReplacingOccurrencesOfString:@"\u2400" withString:[NSString stringWithFormat:@"%c", '\0']];
			newAddr = [newAddr stringByReplacingOccurrencesOfString:@"\u2407" withString:[NSString stringWithFormat:@"%c", 0x07]];
			newAddr = [newAddr stringByReplacingOccurrencesOfString:@"\u2409" withString:[NSString stringWithFormat:@"%c", 0x09]];
			newAddr = [newAddr stringByReplacingOccurrencesOfString:@"\u240A" withString:[NSString stringWithFormat:@"%c", 0x0a]];
			newAddr = [newAddr stringByReplacingOccurrencesOfString:@"\u240D" withString:[NSString stringWithFormat:@"%c", 0x0d]];
      
			[array addObject:@{
								@"id" :			[TBXML valueOfAttributeNamed:@"id" forElement:test],
								@"address" :	newAddr,
								@"diagnosis" :	[TBXML textForElement:[TBXML childElementNamed:@"diagnosis" parentElement:test]]
								} ];
		}
		test = [TBXML nextSiblingNamed:@"test" searchFromElement:test];
	} while(test);

	return array;
}

- (void)xtests_original_success
{
	NSArray *array = [self loadTests:@"tests-original" type:@[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY", @"ISEMAIL_DNSWARN", @"ISEMAIL_CFWS"] exclude:@[@"ISEMAIL_ERR", @"ISEMAIL_DEPREC", @"ISEMAIL_RFC5322", ]];
	NSLog(@"ARRAY[%@] = %ld", @[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY"], [array count]);
	
	[array enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop)
		{
			NSString *address = dict[@"address"];
			BOOL isValid = [es isValidEmail:address];
      //NSLog(@"TEST[%@]: %@ ... ", dict[@"id"], address);
			if(!isValid) {
				NSLog(@"NS[%@] FALSE: %@", dict[@"id"], address);
			}

#ifdef EXT_REGEX
			int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
			if(ret) {
				char str[256];
				regerror(ret, &rx, str, 256);
				NSLog(@"RX[%@] FALSE: %s %s", dict[@"id"], [address cStringUsingEncoding:NSUTF8StringEncoding], str);
			}
#endif
		}];
    //STFail(@"Unit tests are not implemented yet in EmailVerification");
}
- (void)xtests_original_failure
{
	NSArray *array = [self loadTests:@"tests-original" type:@[@"ISEMAIL_ERR", @"ISEMAIL_DEPREC", @"ISEMAIL_RFC5322", ] exclude:@[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY", @"ISEMAIL_DNSWARN", @"ISEMAIL_CFWS"]];
	NSLog(@"ARRAY[%@] = %ld", @[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY"], [array count]);
	
	[array enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop)
		{
			NSString *address = dict[@"address"];
      //NSLog(@"TEST[%@]: %@ ... ", dict[@"id"], address);
			BOOL isValid = [es isValidEmail:address];
			if(isValid) {
				NSLog(@"NS[%@] TRUE: %@", dict[@"id"], address);
			}

#ifdef EXT_REGEX
			int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
			if(!ret) {
				NSLog(@"RX[%@] TRUE: %s", dict[@"id"], [address cStringUsingEncoding:NSUTF8StringEncoding]);
			}
#endif
		}];
    //STFail(@"Unit tests are not implemented yet in EmailVerification");
}
- (void)tests_success
{
	NSArray *array = [self loadTests:@"tests" type:@[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY", @"ISEMAIL_DNSWARN", @"ISEMAIL_CFWS"] exclude:@[@"ISEMAIL_ERR", @"ISEMAIL_DEPREC", @"ISEMAIL_RFC5322", @"ISEMAIL_RFC5321_DEPREC"]];
	NSLog(@"SUCCESS FOR [%@] = %ld", @[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY"], [array count]);
	
	[array enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop)
		{
			NSString *address = dict[@"address"];
			BOOL isValid = [es isValidEmail:address];
      //NSLog(@"TEST[%@]: %@ ... ", dict[@"id"], address);
			if(!isValid) {
				NSLog(@"NS[%@] FALSE: \"%@\"", dict[@"id"], address);
				for(int i=0; i<[address length]; ++i) {
					unichar c = [address characterAtIndex:i];
					printf("[%c %x] ", c, c);
				}
			}

#ifdef EXT_REGEX
			int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
			if(ret) {
				char str[256];
				regerror(ret, &rx, str, 256);
				NSLog(@"RX[%@] FALSE: %s \"%s\"", dict[@"id"], [address cStringUsingEncoding:NSUTF8StringEncoding], str);
			}
#endif
		}];
    //STFail(@"Unit tests are not implemented yet in EmailVerification");
}
- (void)tests_failure
{
	NSArray *array = [self loadTests:@"tests" type:@[@"ISEMAIL_ERR", @"ISEMAIL_DEPREC", @"ISEMAIL_RFC5322", @"ISEMAIL_RFC5321_DEPREC", ] exclude:@[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY", @"ISEMAIL_DNSWARN", @"ISEMAIL_CFWS", ]];
	NSLog(@"FAIL ARRAY[%@] = %ld", @[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY"], [array count]);
	
	[array enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop)
		{
			NSString *address = dict[@"address"];
			//NSLog(@"TEST[%@]: %@ [%s] ... ", dict[@"id"], address, [address cStringUsingEncoding:NSUTF8StringEncoding]);
			BOOL isValid = [es isValidEmail:address];
			if(isValid) {
				NSLog(@"NS[%@] TRUE: %@", dict[@"id"], address);
			}

#ifdef EXT_REGEX
			int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
			if(!ret) {
				NSLog(@"RX[%@] TRUE: %s", dict[@"id"], [address cStringUsingEncoding:NSUTF8StringEncoding]);
			}
#endif
		}];
    //STFail(@"Unit tests are not implemented yet in EmailVerification");
}


- (void)xtestsForSuccess
{
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestForSuccess" ofType:@"txt"];
	assert(path);
	
	__autoreleasing NSError *error;
	NSString *str = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:&error];
	
	NSArray *array = [str componentsSeparatedByString:@"\n"];
	NSMutableArray *mArray = [NSMutableArray arrayWithCapacity:[array count]];
	[array enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop)
		{
			NSString *s = obj;
			NSArray *twofer = [obj componentsSeparatedByString:@"# "];
			if([twofer count] > 1) {
				s = twofer[0];
				if(![s length]) return;
				s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			}
			[mArray addObject:s];
		}];
	
	[mArray enumerateObjectsUsingBlock:^(NSString *address, NSUInteger idx, BOOL *stop)
		{
			if([address isEqualToString:@"."]) {
				*stop = YES;
				return;
			}
			
//NSLog(@"TEST: %@...", address);

			es = [EmailSearcher emailSearcherWithRegexStr:regEx];
			assert(es);
			BOOL isValid = [es isValidEmail:address];
			if(!isValid) {
				NSLog(@"NS[%ld] FALSE: %@", idx, address);
			}
#ifdef EXT_REGEX			
			int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
			if(ret) {
				char str[256];
				regerror(ret, &rx, str, 256);
				NSLog(@"RX[%ld] FALSE: %s %s", idx, [address cStringUsingEncoding:NSUTF8StringEncoding], str);
			}
#endif
		}];
  

    //STFail(@"Unit tests are not implemented yet in EmailVerification");
}

- (void)xtestsForFailure
{
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestForFailure" ofType:@"txt"];
	assert(path);
	
	__autoreleasing NSError *error;
	NSString *str = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	
	NSArray *array = [str componentsSeparatedByString:@"\n"];
	NSMutableArray *mArray = [NSMutableArray arrayWithCapacity:[array count]];
	[array enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop)
		{
			NSString *s = obj;
			NSArray *twofer = [obj componentsSeparatedByString:@"# "];
			if([twofer count] > 1) {
				s = twofer[0];
				if(![s length]) return;
				s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			}
			[mArray addObject:s];
		}];
	
	[mArray enumerateObjectsUsingBlock:^(NSString *address, NSUInteger idx, BOOL *stop)
		{
			if([address isEqualToString:@"."]) {
				*stop = YES;
				return;
			}
			
//NSLog(@"TEST: %@...", address);

			es = [EmailSearcher emailSearcherWithRegexStr:regEx];
			assert(es);
			BOOL isValid = [es isValidEmail:address];
			if(isValid) {
				NSLog(@"NS[%ld] TRUE should be false: %@", (unsigned long)idx, address);
			}
#ifdef EXT_REGEX
			int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
			if(!ret) {
				NSLog(@"RX[%ld] TRUE: %s", (unsigned long)idx, [address cStringUsingEncoding:NSUTF8StringEncoding]);
			}
#endif
		}];
  

    //STFail(@"Unit tests are not implemented yet in EmailVerification");
}

@end
