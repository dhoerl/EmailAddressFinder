//
//  TestRegExWithExternalFiles.h
//  EmailAddressFinder
//
//  Created by David Hoerl on 7/12/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//

//#define LOG(format, ...) NSLog(format, ## __VA_ARGS__)
#define LOG(format, ...) [self logger:format, ## __VA_ARGS__]

//#define EXT_REGEX

#ifdef EXT_REGEX
#include <regex.h>
#endif

#import "TestRegExWithExternalFiles.h"

#import "EmailSearcher.h"
#import "TBXML.h"
#import "HTMLDecode.h"
#import "stdarg.h"

#if 0
void logger(id <ReportProtocol> delegate, NSString *format, ...)
{
	va_list ap;

	va_start(ap, delegate);

	NSString *str = [NSString alloc] initWithFormat:format arguments:(va_list)argList

	void
	va_end(va_list ap);
}
#endif

@implementation TestRegExWithExternalFiles
{
	EmailSearcher			*es;
	
#ifdef EXT_REGEX
	regex_t					rx;
	BOOL					validRX;
#endif
}

- (void)logger:(NSString *)format, ...
{
	va_list ap;

	va_start(ap, format);

	NSString *str = [[NSString alloc] initWithFormat:format arguments:ap];
	[_delegate resultUpdate:str];

	va_end(ap);
}

- (void)test
{
	[self logger:@"Start tests..."];
	[self setUp];
	[self tests_success];
	[self tearDown];

	[self setUp];
	[self tests_failure];
	[self tearDown];

	[self logger:@"End tests"];
}

- (void)setUp
{
	
	es = [EmailSearcher emailSearcherWithRegexStr:self.regEx];
	assert(es);
	
#ifdef EXT_REGEX
	if(self.posixToo) {
		int ret = regcomp(&rx, [_regEx cStringUsingEncoding:NSASCIIStringEncoding], REG_EXTENDED | REG_ENHANCED);
		assert(!ret);
		if(!ret) validRX = YES;
	}
#endif
}

- (void)tearDown
{
#ifdef EXT_REGEX
    // Tear-down code here.
	if(validRX) regfree(&rx);
#endif
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
		//LOG(@"TST %@", [TBXML elementName:test]);
		//LOG(@"ID %@", [TBXML valueOfAttributeNamed:@"id" forElement:test]);
		
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
  if(![excluded containsObject:category]) LOG(@"Yikes: not excluded! %@", category);
}

		if(success) {
			NSString *oldAddr = [TBXML textForElement:[TBXML childElementNamed:@"address" parentElement:test]];
			assert(oldAddr);
			NSString *newAddr = [decoder decodeString:oldAddr];
			assert(newAddr);
			// NSLog(@"newAddr: %@", newAddr);
			
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

#if 0
- (void)xtests_original_success
{
	NSArray *array = [self loadTests:@"tests-original" type:@[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY", @"ISEMAIL_DNSWARN", @"ISEMAIL_CFWS"] exclude:@[@"ISEMAIL_ERR", @"ISEMAIL_DEPREC", @"ISEMAIL_RFC5322", ]];
	LOG(@"ARRAY[%@] = %ld", @[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY"], [array count]);
	
	[array enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop)
		{
			NSString *address = dict[@"address"];
			BOOL isValid = [es isValidEmail:address];
      //LOG(@"TEST[%@]: %@ ... ", dict[@"id"], address);
			if(!isValid) {
				LOG(@"NS[%@] FALSE: %@", dict[@"id"], address);
			}

#ifdef EXT_REGEX
			if(self.posixToo) {
				int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
				if(ret) {
					char str[256];
					regerror(ret, &rx, str, 256);
					LOG(@"RX[%@] FALSE: %s %s", dict[@"id"], [address cStringUsingEncoding:NSUTF8StringEncoding], str);
				}
			}
#endif
		}];
    //STFail(@"Unit tests are not implemented yet in EmailVerification");
}
- (void)xtests_original_failure
{
	NSArray *array = [self loadTests:@"tests-original" type:@[@"ISEMAIL_ERR", @"ISEMAIL_DEPREC", @"ISEMAIL_RFC5322", ] exclude:@[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY", @"ISEMAIL_DNSWARN", @"ISEMAIL_CFWS"]];
	LOG(@"ARRAY[%@] = %ld", @[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY"], [array count]);
	
	[array enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop)
		{
			NSString *address = dict[@"address"];
      //LOG(@"TEST[%@]: %@ ... ", dict[@"id"], address);
			BOOL isValid = [es isValidEmail:address];
			if(isValid) {
				LOG(@"NS[%@] TRUE: %@", dict[@"id"], address);
			}

#ifdef EXT_REGEX
			if(self.posixToo) {
				int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
				if(!ret) {
					LOG(@"RX[%@] TRUE: %s", dict[@"id"], [address cStringUsingEncoding:NSUTF8StringEncoding]);
				}
			}
#endif
		}];
    //STFail(@"Unit tests are not implemented yet in EmailVerification");
}
#endif

- (void)tests_success
{
	NSArray *allow		= @[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY", @"ISEMAIL_DNSWARN", @"ISEMAIL_CFWS"];
	NSArray *exclude	= @[@"ISEMAIL_ERR", @"ISEMAIL_DEPREC", @"ISEMAIL_RFC5322", @"ISEMAIL_RFC5321_DEPREC"];
	NSArray *array = [self loadTests:@"tests" type:allow exclude:exclude];

	LOG(@"SUCCESS Allow=%@ Exclude=%@ Count=%ld", allow, exclude, [array count]);
	NSLog(@"SUCCESS Allow=%@ Exclude=%@ Count=%ld", allow, exclude, [array count]);
	
	[array enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop)
		{
			NSString *address = dict[@"address"];
			BOOL isValid = [es isValidEmail:address];
//LOG(@"TEST[%@]: %@ ... ", dict[@"id"], address);
			if(!isValid) {
LOG(@"YIKES SHOULD HAVE PASSED[%@]: %@", dict[@"id"], address);
				LOG(@"NS[%@] FALSE: \"%@\"", dict[@"id"], address);
				for(int i=0; i<[address length]; ++i) {
					//unichar c = [address characterAtIndex:i];
					//printf("[%c %x] ", c, c);
				}
			}

#ifdef EXT_REGEX
			if(self.posixToo) {
				//int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
				email_components *comps = email_to_components(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding]);
				if(!comps) {
					char str[256] = { 0 };
					//regerror(ret, &rx, str, 256);
					LOG(@"RX[%@] FALSE: %s \"%s\"", dict[@"id"], [address cStringUsingEncoding:NSUTF8StringEncoding], str);
				}
				free_email_comps(comps);
			}
#endif
		}];
    //STFail(@"Unit tests are not implemented yet in EmailVerification");
}
- (void)tests_failure
{
	NSArray *allow		= @[@"ISEMAIL_ERR", @"ISEMAIL_DEPREC", @"ISEMAIL_RFC5322", @"ISEMAIL_RFC5321_DEPREC"];
	NSArray *exclude	= @[@"ISEMAIL_RFC5321", @"ISEMAIL_VALID_CATEGORY", @"ISEMAIL_DNSWARN", @"ISEMAIL_CFWS"];
	NSArray *array = [self loadTests:@"tests" type:allow exclude:exclude];

	LOG(@"FAIL Allow=%@ Exclude=%@ Count=%ld", allow, exclude, [array count]);
	
	[array enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop)
		{
			NSString *address = dict[@"address"];
			//LOG(@"TEST[%@]: %@ [%s] ... ", dict[@"id"], address, [address cStringUsingEncoding:NSUTF8StringEncoding]);
			BOOL isValid = [es isValidEmail:address];
			if(isValid) {
LOG(@"YIKES SHOULD HAVE FAILED[%@]: %@", dict[@"id"], address);
				LOG(@"NS[%@] TRUE: %@", dict[@"id"], address);
			}

#ifdef EXT_REGEX
			if(self.posixToo) {
				//int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
				email_components *comps = email_to_components(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding]);
				if(comps) {
					LOG(@"RX[%@] TRUE: %s", dict[@"id"], [address cStringUsingEncoding:NSUTF8StringEncoding]);
				}
				free_email_comps(comps);
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
			
//LOG(@"TEST: %@...", address);

			es = [EmailSearcher emailSearcherWithRegexStr:_regEx];
			assert(es);
			BOOL isValid = [es isValidEmail:address];
			if(!isValid) {
				LOG(@"NS[%ld] FALSE: %@", idx, address);
			}
#ifdef EXT_REGEX		
			if(self.posixToo) {
				int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
				if(ret) {
					char str[256];
					regerror(ret, &rx, str, 256);
					LOG(@"RX[%ld] FALSE: %s %s", idx, [address cStringUsingEncoding:NSUTF8StringEncoding], str);
				}
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
			
//LOG(@"TEST: %@...", address);

			es = [EmailSearcher emailSearcherWithRegexStr:_regEx];
			assert(es);
			BOOL isValid = [es isValidEmail:address];
			if(isValid) {
				LOG(@"NS[%d] TRUE should be false: %@", idx, address);
			}
#ifdef EXT_REGEX
			if(self.posixToo) {
				int ret = regexec(&rx, [address cStringUsingEncoding:NSUTF8StringEncoding], 0, NULL, 0);
				if(!ret) {
					LOG(@"RX[%d] TRUE: %s", idx, [address cStringUsingEncoding:NSUTF8StringEncoding]);
				}
			}
#endif
		}];
  

    //STFail(@"Unit tests are not implemented yet in EmailVerification");
}

@end
