//
//  EmailSearcher.h
//  EmailAddressFinder
//
//  Created by David Hoerl on 3/20/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EmailSearcher : NSObject
@property (nonatomic, copy) NSString *regex;			// filename

- (NSArray *)findMatchesInString:(NSString *)str;		// Uses Regular expressions to find individual addresses
														// Returns an array of dictionaries using keys: name, address, mailbox

- (NSArray *)findMailtoItems:(NSString *)str;			// Uses NSScanner to find "mailto:" tags and expands the complete value
														// Returns an array of dictionaries, with these keys:
														//  to: an array of addresses
														//  cc: an array of addresses
														//  bcc: an array of addresses
														//  subject: a string
														//  body: a string

- (BOOL)isValidEmail:(NSString *)str;					// is string a simple valid email address, no leading space etc

@end
