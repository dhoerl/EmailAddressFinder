//
// EmailSearcher.h
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

#import <regex.h>

#define WANT_SEARCH		1
#define WANT_MAILTO		1


typedef struct {
	char *display_name;
	char *local_part;
	char *domain;
} email_components;
extern email_components *email_to_components(const regex_t *preg, const char *str);
extern void free_email_comps(email_components *comps);


#define sIsMailBoxFormat	@"isMailBoxFormat"
#define sDisplayName		@"displayName"
#define sLocalPart			@"localPart"
#define sLocalPartNoCmt		@"localPartNoComment"
#define sDomain				@"domain"
#define sDomainNoCmt		@"domainNoComment"

@interface EmailSearcher : NSObject
+ (instancetype)emailSearcherWithRegexStr:(NSString *)str;

- (BOOL)isValidEmail:(NSString *)str;								// is string a simple valid email address, no leading space etc
- (NSDictionary *)isValidEmailReturningComponents:(NSString *)str;	// is string a simple valid email address, returns the pieces minus white space

#if WANT_SEARCH == 1
- (NSArray *)findMatchesInString:(NSString *)str;					// Uses Regular expressions to find individual addresses
																	// Returns an array of dictionaries using keys: name, address, mailbox
#endif

#if WANT_MAILTO == 1
- (BOOL)isValidMailTo:(NSString *)str;								// is string a simple valid email address, no leading space etc
- (NSArray *)findMailtoItems:(NSString *)str;						// Uses NSScanner to find "mailto:" tags and expands the complete value
																	// Returns an array of dictionaries, with these keys:
																	//  to: an array of addresses
																	//  cc: an array of addresses
																	//  bcc: an array of addresses
																	//  subject: a string
																	//  body: a string
#endif

@end
