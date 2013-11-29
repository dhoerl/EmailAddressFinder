//
//  TestRegExWithExternalFiles.h
//  EmailAddressFinder
//
//  Created by David Hoerl on 7/12/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//

@protocol ReportProtocol <NSObject>
- (void)resultUpdate:(NSString *)str;
@end

@interface TestRegExWithExternalFiles : NSObject
@property (nonatomic, unsafe_unretained) id <ReportProtocol> delegate;
@property (nonatomic, strong) NSString *regEx;
@property (nonatomic, assign) BOOL posixToo;

- (void)test;

@end
