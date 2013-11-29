// ReallyFastHTMLDecode (TM)
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

#import "HTMLDecode.h"

static NSDictionary *namedEntities();

static NSDictionary *translationDict;

static NSCharacterSet *alphaSet;
static NSCharacterSet *alphaNumSet;

#if 0
#define LOG NSLog
#else
#define LOG(x, ...) 
#endif

@interface HTMLDecode ()
@end

@implementation HTMLDecode

+ (void)initialize
{
	if(self == [HTMLDecode class]) {
		translationDict = namedEntities();
		
		NSMutableCharacterSet *cs;
		
		cs = [NSMutableCharacterSet characterSetWithRange:NSMakeRange('a', 26)];
		[cs formUnionWithCharacterSet:[NSCharacterSet characterSetWithRange:NSMakeRange('A', 26)]];
		alphaSet = [cs copy];
		
		cs = [NSMutableCharacterSet decimalDigitCharacterSet];
		[cs formUnionWithCharacterSet:alphaSet];
		alphaNumSet = [cs copy];
	}
}

- (NSString *)decodeData:(NSData *)data
{
	const uint8_t *ptr		= [data bytes];
	NSUInteger len			= [data length];
	const uint8_t *endPtr	= ptr + (len ? (len-1) : 0);	// need one char lookahead

	NSString *str = [[NSString alloc] initWithBytes:(void *)[data bytes] length:[data length] encoding:NSUTF8StringEncoding];	
	while(ptr != endPtr) {
		if(ptr[0] == '&' && ptr[1] != ' ') break;			// common case of & and no encoding
		++ptr;
	}
	if(ptr == endPtr) return str;

	str = [self decodeString:str];
	return str;
}

- (NSString *)decodeString:(NSString *)str
{
	NSArray *atArray = [str componentsSeparatedByString:@"&"];
	NSMutableArray *chunkArray = [NSMutableArray arrayWithCapacity:[atArray count]];
	
	// Preload the chunks to have the appropriate size of the receiver
	[atArray enumerateObjectsUsingBlock:^(NSString *chunk, NSUInteger idx, BOOL *stop)
		{
			[chunkArray addObject:[NSMutableString stringWithCapacity:[chunk length]+1]];	// +1 for '&'
		} ];	

	[atArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *chunk, NSUInteger idx, BOOL *stop)
		{
			NSMutableString *newChunk = chunkArray[idx];
			//NSUInteger chunkLen = [chunk length];
			//NSUInteger chunkLenM1 = chunkLen - 1;
			BOOL useOriginal = YES;

			// smallest possible is "#38;"
			if(idx == 0 || [chunk length] < 4) {
				if(idx) [newChunk appendString:@"&"];
				[newChunk appendString:chunk];
				return;
			}

			unichar c = [chunk characterAtIndex:0];
			switch(c) {
			case ' ':
				break;
			
			case '#':
			{
				// Number
				BOOL isHex = [chunk characterAtIndex:1] == 'x';
				NSScanner *scanner = [NSScanner scannerWithString:chunk];
				[scanner scanString:isHex ? @"#x" : @"#" intoString:NULL];	// skip prefix

				int i = 0;
				BOOL success = isHex ? [scanner scanHexInt:(unsigned int *)&i] : [scanner scanInt:&i];

				if(success && i > 0 && i <= 0xFFFD && [scanner scanString:@";" intoString:NULL]) {
					unichar tc = (unichar)i;
					LOG(@"Numeric Code: tc=%d", (int)tc);
					[newChunk appendFormat:@"%C%@", tc, [chunk substringFromIndex:[scanner scanLocation]]];
					useOriginal = NO;
				} else {
					LOG(@"BAD Numeric Code: tc=%u", i);
				}
			}
			
			default:
				if([alphaSet characterIsMember:c]) {
					NSScanner *scanner = [NSScanner scannerWithString:chunk];

					__autoreleasing NSString *name;
					[scanner scanCharactersFromSet:alphaNumSet intoString:&name];	// has to succeed since know the first char is valid
					
					NSString *translation = (NSString *)translationDict[name];
					if(translation && [scanner scanString:@";" intoString:NULL]) {
						[newChunk appendFormat:@"%@%@", translation, [chunk substringFromIndex:[scanner scanLocation]]];
						LOG(@"Character Code: key=%@ value=%@ leftover=%@", name, translation, [chunk substringFromIndex:[scanner scanLocation]]);
						useOriginal = NO;
					}
				}
				break;
			}
			if(useOriginal) {
				[newChunk appendFormat:@"&%@", chunk];
			}
		} ];
		
	return [chunkArray componentsJoinedByString:@""];
}

@end

static NSDictionary *namedEntities()
{
	return @{
		@"AElig": @"Æ",
		@"Aacute": @"Á",
		@"Acirc": @"Â",
		@"Agrave": @"À",
		@"Alpha": @"Α",
		@"Aring": @"Å",
		@"Atilde": @"Ã",
		@"Auml": @"Ä",
		@"Beta": @"Β",
		@"Ccedil": @"Ç",
		@"Chi": @"Χ",
		@"Dagger": @"‡",
		@"Delta": @"Δ",
		@"ETH": @"Ð",
		@"Eacute": @"É",
		@"Ecirc": @"Ê",
		@"Egrave": @"È",
		@"Epsilon": @"Ε",
		@"Eta": @"Η",
		@"Euml": @"Ë",
		@"Gamma": @"Γ",
		@"Iacute": @"Í",
		@"Icirc": @"Î",
		@"Igrave": @"Ì",
		@"Iota": @"Ι",
		@"Iuml": @"Ï",
		@"Kappa": @"Κ",
		@"Lambda": @"Λ",
		@"Mu": @"Μ",
		@"Ntilde": @"Ñ",
		@"Nu": @"Ν",
		@"OElig": @"Œ",
		@"Oacute": @"Ó",
		@"Ocirc": @"Ô",
		@"Ograve": @"Ò",
		@"Omega": @"Ω",
		@"Omicron": @"Ο",
		@"Oslash": @"Ø",
		@"Otilde": @"Õ",
		@"Ouml": @"Ö",
		@"Phi": @"Φ",
		@"Pi": @"Π",
		@"Prime": @"″",
		@"Psi": @"Ψ",
		@"Rho": @"Ρ",
		@"Scaron": @"Š",
		@"Sigma": @"Σ",
		@"THORN": @"Þ",
		@"Tau": @"Τ",
		@"Theta": @"Θ",
		@"Uacute": @"Ú",
		@"Ucirc": @"Û",
		@"Ugrave": @"Ù",
		@"Upsilon": @"Υ",
		@"Uuml": @"Ü",
		@"Xi": @"Ξ",
		@"Yacute": @"Ý",
		@"Yuml": @"Ÿ",
		@"Zeta": @"Ζ",
		@"aacute": @"á",
		@"acirc": @"â",
		@"acute": @"´",
		@"aelig": @"æ",
		@"agrave": @"à",
		@"alefsym": @"ℵ",
		@"alpha": @"α",
		@"amp": @"&",
		@"and": @"∧",
		@"ang": @"∠",
		@"apos": @"'",
		@"aring": @"å",
		@"asymp": @"≈",
		@"atilde": @"ã",
		@"auml": @"ä",
		@"bdquo": @"„",
		@"beta": @"β",
		@"brvbar": @"¦",
		@"bull": @"•",
		@"cap": @"∩",
		@"ccedil": @"ç",
		@"cedil": @"¸",
		@"cent": @"¢",
		@"chi": @"χ",
		@"circ": @"ˆ",
		@"clubs": @"♣",
		@"cong": @"≅",
		@"copy": @"©",
		@"crarr": @"↵",
		@"cup": @"∪",
		@"curren": @"¤",
		@"dArr": @"⇓",
		@"dagger": @"†",
		@"darr": @"↓",
		@"deg": @"°",
		@"delta": @"δ",
		@"diams": @"♦",
		@"divide": @"÷",
		@"eacute": @"é",
		@"ecirc": @"ê",
		@"egrave": @"è",
		@"empty": @"∅",
		@"emsp": @" ",
		@"ensp": @" ",
		@"epsilon": @"ε",
		@"equiv": @"≡",
		@"eta": @"η",
		@"eth": @"ð",
		@"euml": @"ë",
		@"euro": @"€",
		@"exist": @"∃",
		@"fnof": @"ƒ",
		@"forall": @"∀",
		@"frac12": @"½",
		@"frac14": @"¼",
		@"frac34": @"¾",
		@"frasl": @"⁄",
		@"gamma": @"γ",
		@"ge": @"≥",
		@"gt": @">",
		@"hArr": @"⇔",
		@"harr": @"↔",
		@"hearts": @"♥",
		@"hellip": @"…",
		@"iacute": @"í",
		@"icirc": @"î",
		@"iexcl": @"¡",
		@"igrave": @"ì",
		@"image": @"ℑ",
		@"infin": @"∞",
		@"int": @"∫",
		@"iota": @"ι",
		@"iquest": @"¿",
		@"isin": @"∈",
		@"iuml": @"ï",
		@"kappa": @"κ",
		@"lArr": @"⇐",
		@"lambda": @"λ",
		@"lang": @"〈",
		@"laquo": @"«",
		@"larr": @"←",
		@"lceil": @"⌈",
		@"ldquo": @"“",
		@"le": @"≤",
		@"lfloor": @"⌊",
		@"lowast": @"∗",
		@"loz": @"◊",
		@"lrm": @"\xE2\x80\x8E",
		@"lsaquo": @"‹",
		@"lsquo": @"‘",
		@"lt": @"<",
		@"macr": @"¯",
		@"mdash": @"—",
		@"micro": @"µ",
		@"middot": @"·",
		@"minus": @"−",
		@"mu": @"μ",
		@"nabla": @"∇",
		@"nbsp": @" ",
		@"ndash": @"–",
		@"ne": @"≠",
		@"ni": @"∋",
		@"not": @"¬",
		@"notin": @"∉",
		@"nsub": @"⊄",
		@"ntilde": @"ñ",
		@"nu": @"ν",
		@"oacute": @"ó",
		@"ocirc": @"ô",
		@"oelig": @"œ",
		@"ograve": @"ò",
		@"oline": @"‾",
		@"omega": @"ω",
		@"omicron": @"ο",
		@"oplus": @"⊕",
		@"or": @"∨",
		@"ordf": @"ª",
		@"ordm": @"º",
		@"oslash": @"ø",
		@"otilde": @"õ",
		@"otimes": @"⊗",
		@"ouml": @"ö",
		@"para": @"¶",
		@"part": @"∂",
		@"permil": @"‰",
		@"perp": @"⊥",
		@"phi": @"φ",
		@"pi": @"π",
		@"piv": @"ϖ",
		@"plusmn": @"±",
		@"pound": @"£",
		@"prime": @"′",	// prime = minutes = fee
		@"prod": @"∏",
		@"prop": @"∝",
		@"psi": @"ψ",
		@"quot": @"″",
		@"rArr": @"⇒",
		@"radic": @"√",
		@"rang": @"〉",
		@"raquo": @"»",
		@"rarr": @"→",
		@"rceil": @"⌉",
		@"rdquo": @"”",
		@"real": @"ℜ",
		@"reg": @"®",
		@"rfloor": @"⌋",
		@"rho": @"ρ",
		@"rlm": @"\xE2\x80\x8F",
		@"rsaquo": @"›",
		@"rsquo": @"’",
		@"sbquo": @"‚",
		@"scaron": @"š",
		@"sdot": @"⋅",
		@"sect": @"§",
		@"shy": @"\xC2\xAD",
		@"sigma": @"σ",
		@"sigmaf": @"ς",
		@"sim": @"∼",
		@"spades": @"♠",
		@"sub": @"⊂",
		@"sube": @"⊆",
		@"sum": @"∑",
		@"sup": @"⊃",
		@"sup1": @"¹",
		@"sup2": @"²",
		@"sup3": @"³",
		@"supe": @"⊇",
		@"szlig": @"ß",
		@"tau": @"τ",
		@"there4": @"∴",
		@"theta": @"θ",
		@"thetasym": @"ϑ",
		@"thinsp": @" ",
		@"thorn": @"þ",
		@"tilde": @"˜",
		@"times": @"×",
		@"trade": @"™",
		@"uArr": @"⇑",
		@"uacute": @"ú",
		@"uarr": @"↑",
		@"ucirc": @"û",
		@"ugrave": @"ù",
		@"uml": @"¨",
		@"upsih": @"ϒ",
		@"upsilon": @"υ",
		@"uuml": @"ü",
		@"weierp": @"℘",
		@"xi": @"ξ",
		@"yacute": @"ý",
		@"yen": @"¥",
		@"yuml": @"ÿ",
		@"zeta": @"ζ",
		@"zwj": @"\xE2\x80\x8D",
		@"zwnj": @"\xE2\x80\x8C"};
}
