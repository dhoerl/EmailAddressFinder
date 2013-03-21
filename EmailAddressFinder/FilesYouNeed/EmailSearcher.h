//
//  EmailSearcher.h
//  EmailAddressFinder
//
//  Created by David Hoerl on 3/20/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EmailSearcher : NSObject
@property (nonatomic, copy)		NSString *regex;			// filename

- (NSArray *)findMatchesInString:(NSString *)str;			// Array of Dictionaries

- (BOOL)isValidEmail:(NSString *)str;						// is string a simple valid email address, no leading space etc

@end
