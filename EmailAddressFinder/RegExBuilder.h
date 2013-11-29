//
//  RegExBuilder.h
//  EmailAddressFinder
//
//  Created by David Hoerl on 7/15/13.
//  Copyright (c) 2013 dhoerl. All rights reserved.
//

#define kCommentString		@"commentString"
#define kMailboxString		@"mailboxString"
#define kAngleAddrSpec		@"angleAddrSpecString"
#define kDisplayName		@"dispNameString"
#define kNameAddress		@"nameAddrString"
#define kIPV6String			@"ipv6String"
#define kFWS				@"fwsString"
#define kCommentFWS			@"cfwsString"
#define kTestString			@"testString"
#define kCommentLevel		@"nestLevel"	// number
#define kAddrSpecOnly		@"addrSpecOnly"	// boolean number
#define kPOXIXcompliant		@"posix"		// boolean number
#define kValidateRegEx		@"validateMode"	// boolean number
#define kAllowCFWSwithAT	@"allowCFWS"	// boolean number
#define kCaptureGroups		@"captureGroups"// boolean number
#define kCompressedFWS		@"compressFWS"	// boolean number
#define kAllowNullStr		@"allowNullStr"	// boolean number
#define kUseRFC5321IPV6		@"rfc5321IPV6"	// boolean number
#define kUseRFC5321Len		@"rfc5321Len"	// boolean number

@interface RegExBuilder : NSObject

+ (instancetype)regBuilder:(NSDictionary *)options;
- (NSString *)regex;

@end
