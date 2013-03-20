//
//  EmailSearcher.h
//  EmailAddressFinder
//
//  Created by David Hoerl on 3/20/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EmailSearcher : NSObject
@property (nonatomic, assign)	BOOL wantMailboxSpecifiers;		// ie "name" <a@b.com>
@property (nonatomic, copy)		NSString *regex;			// filename

- (NSArray *)findMatchesInString:(NSString *)str;

@end
