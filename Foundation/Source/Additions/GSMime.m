/** Implementation for GSMIME

   Copyright (C) 2000,2001 Free Software Foundation, Inc.

   Written by: Richard Frith-Macdonald <rfm@gnu.org>
   Date: October 2000

   This file is part of the GNUstep Base Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02111 USA.

   <title>The MIME parsing system</title>
   <chapter>
      <heading>Mime Parser</heading>
      <p>
        The GNUstep Mime parser.  This is collection Objective-C classes
        for representing MIME (and HTTP) documents and managing conversions
        to and from convenient internal formats.
      </p>
      <p>
        The idea is to center round two classes -
      </p>
      <deflist>
        <term>document</term>
        <desc>
          A container for the actual data (and headers) of a mime/http
	  document, this is also used to create raw MIME data for sending.
        </desc>
        <term>parser</term>
        <desc>
          An object that can be fed data and will parse it into a document.
          This object also provides various utility methods  and an API
          that permits overriding in order to extend the functionality to
          cope with new document types.
        </desc>
      </deflist>
   </chapter>
   $Date: 2012-01-09 00:28:27 -0800 (Mon, 09 Jan 2012) $ $Revision: 34468 $
*/

#import "common.h"
#define	EXPOSE_GSMimeDocument_IVARS	1
#define	EXPOSE_GSMimeHeader_IVARS	1
#define	EXPOSE_GSMimeParser_IVARS	1
#define	EXPOSE_GSMimeSMTPClient_IVARS	1


#define	GS_GSMimeSMTPClient_IVARS \
  id			delegate;\
  NSString		*hostname;\
  NSString		*identity;\
  NSString		*originator;\
  NSString		*port;\
  NSString		*username;\
  NSTimer		*timer;\
  GSMimeDocument	*current;\
  GSMimeHeader		*version;\
  NSMutableArray	*queue;\
  NSMutableArray	*pending;\
  NSInputStream		*istream;\
  NSOutputStream	*ostream;\
  NSMutableData		*wdata;\
  NSMutableData		*rdata;\
  NSMutableString	*reply;\
  NSError		*lastError;\
  unsigned		woffset;\
  BOOL			readable;\
  BOOL			writable;\
  int			cState


#include <string.h>
#include <ctype.h>

#import	"Foundation/NSArray.h"
#import	"Foundation/NSAutoreleasePool.h"
#import	"Foundation/NSCharacterSet.h"
#import	"Foundation/NSData.h"
#import	"Foundation/NSDictionary.h"
#import	"Foundation/NSEnumerator.h"
#import	"Foundation/NSException.h"
#import	"Foundation/NSHost.h"
#import	"Foundation/NSRunLoop.h"
#import	"Foundation/NSScanner.h"
#import	"Foundation/NSStream.h"
#import	"Foundation/NSTimer.h"
#import	"Foundation/NSUserDefaults.h"
#import	"Foundation/NSValue.h"
#import	"GNUstepBase/GSObjCRuntime.h"
#import	"GNUstepBase/GSMime.h"
#import	"GNUstepBase/GSXML.h"
#import	"GNUstepBase/NSObject+GNUstepBase.h"
#import	"GNUstepBase/NSData+GNUstepBase.h"
#import	"GNUstepBase/NSDebug+GNUstepBase.h"
#import	"GNUstepBase/NSString+GNUstepBase.h"
#import	"GNUstepBase/NSMutableString+GNUstepBase.h"
#import	"GNUstepBase/Unicode.h"

#import "../GSPrivate.h"

static	NSCharacterSet	*whitespace = nil;
static	NSCharacterSet	*rfc822Specials = nil;
static	NSCharacterSet	*rfc2045Specials = nil;
static  NSMapTable	*charsets = 0;
static  NSMapTable	*encodings = 0;
static	Class		NSArrayClass = 0;
static	Class		NSStringClass = 0;
static	Class		documentClass = 0;

typedef BOOL (*boolIMP)(id, SEL, id);

@interface GSMimeDocument (Private)
- (GSMimeHeader*) _lastHeaderNamed: (NSString*)name;
- (NSUInteger) _indexOfHeaderNamed: (NSString*)name;
@end

/*
 *	Name -		decodebase64()
 *	Purpose -	Convert 4 bytes in base64 encoding to 3 bytes raw data.
 */
static void
decodebase64(unsigned char *dst, const unsigned char *src)
{
  dst[0] =  (src[0]         << 2) | ((src[1] & 0x30) >> 4);
  dst[1] = ((src[1] & 0x0F) << 4) | ((src[2] & 0x3C) >> 2);
  dst[2] = ((src[2] & 0x03) << 6) |  (src[3] & 0x3F);
}

static char b64[]
  = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static int
encodebase64(unsigned char *dst, const unsigned char *src, int length)
{
  int	dIndex = 0;
  int	sIndex;

  for (sIndex = 0; sIndex < length; sIndex += 3)
    {
      int	c0 = src[sIndex];
      int	c1 = (sIndex+1 < length) ? src[sIndex+1] : 0;
      int	c2 = (sIndex+2 < length) ? src[sIndex+2] : 0;

      dst[dIndex++] = b64[(c0 >> 2) & 077];
      dst[dIndex++] = b64[((c0 << 4) & 060) | ((c1 >> 4) & 017)];
      dst[dIndex++] = b64[((c1 << 2) & 074) | ((c2 >> 6) & 03)];
      dst[dIndex++] = b64[c2 & 077];
    }

   /* If len was not a multiple of 3, then we have encoded too
    * many characters.  Adjust appropriately.
    */
   if (sIndex == length + 1)
     {
       /* There were only 2 bytes in that last group */
       dst[dIndex - 1] = '=';
     }
   else if (sIndex == length + 2)
     {
       /* There was only 1 byte in that last group */
       dst[dIndex - 1] = '=';
       dst[dIndex - 2] = '=';
     }
  return dIndex;
}


static void
encodeQuotedPrintable(NSMutableData *result,
  const unsigned char *src, unsigned length)
{
  static char	*hex = "0123456789ABCDEF";
  unsigned	offset;
  unsigned	column = 0;
  unsigned	size = 0;
  unsigned	i;
  unsigned char	*dst;

  for (i = 0; i < length; i++)
    {
      unsigned char	c = src[i];
      int		add;

      if ('\r' == c && i < length && '\n' == src[i + 1])
	{
	  /* A cr-lf sequence is an end of line, we send that literally
	   * as a hard line break.
	   */
	  i++;
	  size += 2;
	  column = 0;
	  continue;
	}

      if ((' ' == c || '\t' == c) && i < length
	&& ('\r' == src[i + 1] || '\n' == src[i + 1]))
	{
	  /* RFC 2045 says we have to encode space and tab characters when
	   * they occur just before end of line.
	   */
	  add = 3;
	}
      else if ('\t' == c || (c >= 32 && c <= 60) || (c >= 62 && c <= 126))
	{
	  /* Most characters can be sent literally.
	   */
	  add = 1;
	}
      else
	{
	  /* Everything else must be escaped.
	   */
	  add = 3;
	}
      if (column + add > 75)
	{
	  size += 3;	// '=\r\n'
	  column = 0;
	}
      size += add;
      column += add;
    }

  offset = [result length];
  [result setLength: offset + size];
  dst = (unsigned char*)[result mutableBytes];
  column = 0;

  for (i = 0; i < length; i++)
    {
      unsigned char	c = src[i];
      int		add;

      if ('\r' == c && i < length && '\n' == src[i + 1])
	{
	  /* A cr-lf sequence is an end of line, we send that literally
	   * as a hard line break.
	   */
	  i++;
	  dst[offset++] = '\r';
	  dst[offset++] = '\n';
	  column = 0;
	  continue;
	}

      if ((' ' == c || '\t' == c) && i < length
	&& ('\r' == src[i + 1] || '\n' == src[i + 1]))
	{
	  /* RFC 2045 says we have to encode space and tab characters when
	   * they occur just before end of line.
	   */
	  add = 3;
	}
      else if ('\t' == c || (c >= 32 && c <= 60) || (c >= 62 && c <= 126))
	{
	  /* Most characters can be sent literally.
	   */
	  add = 1;
	}
      else
	{
	  /* Everything else must be escaped.
	   */
	  add = 3;
	}
      if (column + add > 75)
	{
	  dst[offset++] = '=';
          dst[offset++] = '\r';
          dst[offset++] = '\n';
	  column = 0;
	}
      if (3 == add)
	{
	  dst[offset++] = '=';
          dst[offset++] = hex[c >> 4];
          dst[offset++] = hex[c & 15];
	}
      else
	{
	  dst[offset++] = c;
	}
      column += add;
    }
}


typedef	enum {
  WE_QUOTED,
  WE_BASE64
} WE;

/*
 *	Name -		decodeWord()
 *	Params -	dst destination
 *			src where to start decoding from
 *			end where to stop decoding (or NULL if end of buffer).
 *			enc content-transfer-encoding
 *	Purpose -	Decode text with BASE64 or QUOTED-PRINTABLE codes.
 */
static unsigned char*
decodeWord(unsigned char *dst, const unsigned char *src, const unsigned char *end, WE enc)
{
  int	c;

  if (enc == WE_QUOTED)
    {
      while (*src && (src != end))
	{
	  if (*src == '=')
	    {
	      src++;
	      if (*src == '\0')
		{
		  break;
		}
              if (('\n' == *src) || ('\r' == *src))
                {
                  break;
                }
              if (!isxdigit(src[0]) || !isxdigit(src[1]))
                {
                  /* Strictly speaking the '=' must be followed by
                   * two hexadecimal characters, but RFC2045 says that
                   * 'A reasonable approach by a robust implementation might be
                   * to include the "=" character and the following character
                   * in the decoded data without any transformation'
                   */
                  *dst++ = '=';
                  *dst = *src;
                }
              else
                {
                  int   h;
                  int   l;

                  /* Strictly speaking only uppercase characters are legal
                   * here, but we tolerate lowercase too.
                   */
                  h = isdigit(*src) ? (*src - '0') : (*src - 55);
                  if (h > 15) h -= 32;  // lowercase a-f
                  src++;
                  l = isdigit(*src) ? (*src - '0') : (*src - 55);
                  if (l > 15) l -= 32;  // lowercase a-f
                  *dst = (h << 4) + l;
                }
	    }
	  else if (*src == '_')
	    {
	      *dst = '\040';
	    }
	  else
	    {
	      *dst = *src;
	    }
	  dst++;
	  src++;
	}
      *dst = '\0';
      return dst;
    }
  else if (enc == WE_BASE64)
    {
      unsigned char	buf[4];
      NSUInteger	pos = 0;

      while (*src && (src != end))
	{
	  c = *src++;
	  if (isupper(c))
	    {
	      c -= 'A';
	    }
	  else if (islower(c))
	    {
	      c = c - 'a' + 26;
	    }
	  else if (isdigit(c))
	    {
	      c = c - '0' + 52;
	    }
	  else if (c == '/')
	    {
	      c = 63;
	    }
	  else if (c == '+')
	    {
	      c = 62;
	    }
	  else if  (c == '=')
	    {
	      c = -1;
	    }
	  else if (c == '-')
	    {
	      break;		/* end    */
	    }
	  else
	    {
	      c = -1;		/* ignore */
	    }

	  if (c >= 0)
	    {
	      buf[pos++] = c;
	      if (pos == 4)
		{
		  pos = 0;
		  decodebase64(dst, buf);
		  dst += 3;
		}
	    }
	}

      if (pos > 0)
	{
	  NSUInteger	i;

	  for (i = pos; i < 4; i++)
	    buf[i] = '\0';
	  pos--;
	}
      decodebase64(dst, buf);
      dst += pos;
      *dst = '\0';
      return dst;
    }
  else
    {
      NSLog(@"Unsupported encoding type");
      return dst;
    }
}

static NSString *
selectCharacterSet(NSString *str, NSData **d)
{
  if ([str length] == 0)
    {
      *d = [NSData data];
      return @"us-ascii";	// Default character set.
    }
  if ((*d = [str dataUsingEncoding: NSASCIIStringEncoding]) != nil)
    return @"us-ascii";	// Default character set.
  if ((*d = [str dataUsingEncoding: NSISOLatin1StringEncoding]) != nil)
    return @"iso-8859-1";

  /*
   * What's the point of trying loads of charactersets ... utf-8 is
   * well-known nowadays, so if we can't use ascii or latin1 we may
   * as well go straight to utf-8
   */
#if 0
  if ((*d = [str dataUsingEncoding: NSISOLatin2StringEncoding]) != nil)
    return @"iso-8859-2";
  if ((*d = [str dataUsingEncoding: NSISOLatin3StringEncoding]) != nil)
    return @"iso-8859-3";
  if ((*d = [str dataUsingEncoding: NSISOLatin4StringEncoding]) != nil)
    return @"iso-8859-4";
  if ((*d = [str dataUsingEncoding: NSISOCyrillicStringEncoding]) != nil)
    return @"iso-8859-5";
  if ((*d = [str dataUsingEncoding: NSISOArabicStringEncoding]) != nil)
    return @"iso-8859-6";
  if ((*d = [str dataUsingEncoding: NSISOGreekStringEncoding]) != nil)
    return @"iso-8859-7";
  if ((*d = [str dataUsingEncoding: NSISOHebrewStringEncoding]) != nil)
    return @"iso-8859-8";
  if ((*d = [str dataUsingEncoding: NSISOLatin5StringEncoding]) != nil)
    return @"iso-8859-9";
  if ((*d = [str dataUsingEncoding: NSISOLatin6StringEncoding]) != nil)
    return @"iso-8859-10";
  if ((*d = [str dataUsingEncoding: NSISOLatin7StringEncoding]) != nil)
    return @"iso-8859-13";
  if ((*d = [str dataUsingEncoding: NSISOLatin8StringEncoding]) != nil)
    return @"iso-8859-14";
  if ((*d = [str dataUsingEncoding: NSISOLatin9StringEncoding]) != nil)
    return @"iso-8859-15";
  if ((*d = [str dataUsingEncoding: NSWindowsCP1250StringEncoding]) != nil)
    return @"windows-1250";
  if ((*d = [str dataUsingEncoding: NSWindowsCP1251StringEncoding]) != nil)
    return @"windows-1251";
  if ((*d = [str dataUsingEncoding: NSWindowsCP1252StringEncoding]) != nil)
    return @"windows-1252";
  if ((*d = [str dataUsingEncoding: NSWindowsCP1253StringEncoding]) != nil)
    return @"windows-1253";
  if ((*d = [str dataUsingEncoding: NSWindowsCP1254StringEncoding]) != nil)
    return @"windows-1254";
#endif
  *d = [str dataUsingEncoding: NSUTF8StringEncoding];
  return @"utf-8";		// Catch-all character set.
}

/**
 * Encode a word in a header according to RFC2047 if necessary.
 * For an ascii word, we just return the data.
 */
static NSData*
wordData(NSString *word)
{
  NSData	*d = nil;
  NSString	*charset;

  charset = selectCharacterSet(word, &d);
  if ([charset isEqualToString: @"us-ascii"] == YES)
    {
      return d;
    }
  else
    {
      int		len = [charset length];
      char		buf[len + 1];
      NSMutableData	*md;

      [charset getCString: buf
		maxLength: len + 1
		 encoding: NSISOLatin1StringEncoding];
      md = [NSMutableData dataWithCapacity: [d length]*4/3 + len + 8];
      d = [documentClass encodeBase64: d];
      [md appendBytes: "=?" length: 2];
      [md appendBytes: buf length: len];
      [md appendBytes: "?b?" length: 3];
      [md appendData: d];
      [md appendBytes: "?=" length: 2];
      return md;
    }
}

/**
 * Coding contexts are objects used by the parser to store the state of
 * decoding incoming data while it is being incrementally parsed.<br />
 * The most rudimentary context ... this is used for decoding plain
 * text and binary data (ie data which is not really decoded at all)
 * and all other decoding work is done by a subclass.
 */
@implementation	GSMimeCodingContext
/**
 * Returns the current value of the 'atEnd' flag.
 */
- (BOOL) atEnd
{
  return atEnd;
}

/**
 * Copying is implemented as a simple retain.
 */
- (id) copyWithZone: (NSZone*)z
{
  return RETAIN(self);
}

/**
 * Decode length bytes of data from sData and append the results to dData.<br />
 * Return YES on success, NO if there is an error.
 */
- (BOOL) decodeData: (const void*)sData
	     length: (NSUInteger)length
	   intoData: (NSMutableData*)dData
{
  NSUInteger	size = [dData length];

  [dData setLength: size + length];
  memcpy([dData mutableBytes] + size, sData, length);
  return YES;
}

/**
 * Sets the current value of the 'atEnd' flag.
 */
- (void) setAtEnd: (BOOL)flag
{
  atEnd = flag;
}
@end

@interface	GSMimeBase64DecoderContext : GSMimeCodingContext
{
@public
  unsigned char	buf[4];
  NSUInteger	pos;
}
@end
@implementation	GSMimeBase64DecoderContext
- (BOOL) decodeData: (const void*)sData
	     length: (NSUInteger)length
	   intoData: (NSMutableData*)dData
{
  NSUInteger	size = [dData length];
  unsigned char	*src = (unsigned char*)sData;
  unsigned char	*end = src + length;
  unsigned char	*beg;
  unsigned char	*dst;

  /*
   * Expand destination data buffer to have capacity to handle info.
   */
  [dData setLength: size + (3 * (end + 8 - src))/4];
  dst = (unsigned char*)[dData mutableBytes];
  beg = dst;

  /*
   * Now decode data into buffer, keeping count and temporary
   * data in context.
   */
  while (src < end)
    {
      int	cc = *src++;

      if (isupper(cc))
	{
	  cc -= 'A';
	}
      else if (islower(cc))
	{
	  cc = cc - 'a' + 26;
	}
      else if (isdigit(cc))
	{
	  cc = cc - '0' + 52;
	}
      else if (cc == '+')
	{
	  cc = 62;
	}
      else if (cc == '/')
	{
	  cc = 63;
	}
      else if  (cc == '=')
	{
          [self setAtEnd: YES];
	  cc = -1;
	}
      else if (cc == '-')
	{
	  [self setAtEnd: YES];
	  break;
	}
      else
	{
	  cc = -1;		/* ignore */
	}

      if (cc >= 0)
	{
	  buf[pos++] = cc;
	  if (pos == 4)
	    {
	      pos = 0;
	      decodebase64(dst, buf);
	      dst += 3;
	    }
	}
    }

  /*
   * Odd characters at end of decoded data need to be added separately.
   */
  if ([self atEnd] == YES && pos > 0)
    {
      NSUInteger	len = pos - 1;

      while (pos < 4)
	{
	  buf[pos++] = '\0';
	}
      pos = 0;
      decodebase64(dst, buf);
      size += len;
    }
  [dData setLength: size + dst - beg];
  return YES;
}
@end

@interface	GSMimeQuotedDecoderContext : GSMimeCodingContext
{
@public
  unsigned char	buf[4];
  NSUInteger	pos;
}
@end
@implementation	GSMimeQuotedDecoderContext
- (BOOL) decodeData: (const void*)sData
	     length: (NSUInteger)length
	   intoData: (NSMutableData*)dData
{
  NSUInteger	size = [dData length];
  unsigned char	*src = (unsigned char*)sData;
  unsigned char	*end = src + length;
  unsigned char	*beg;
  unsigned char	*dst;

  /*
   * Expand destination data buffer to have capacity to handle info.
   */
  [dData setLength: size + (end - src)];
  dst = (unsigned char*)[dData mutableBytes];
  beg = dst;

  while (src < end)
    {
      if (pos > 0)
	{
	  if (1 == pos && '\r' == *src)
	    {
	      pos++;
	    }
	  else if (*src == '\n')
	    {
	      pos = 0;
	    }
	  else
	    {
	      buf[pos++] = *src;
	      if (pos == 3)
		{
		  BOOL	ok = YES;
		  int	c;
		  int	val;

		  pos = 0;
		  c = buf[1];
		  if (isxdigit(c))
		    {
		      if (islower(c)) c = toupper(c);
		      val = isdigit(c) ? (c - '0') : (c - 55);
		      val *= 0x10;
		      c = buf[2];
		      if (isxdigit(c))
			{
			  if (islower(c)) c = toupper(c);
			  val += isdigit(c) ? (c - '0') : (c - 55);
			}
		      else
			{
			  ok = NO;
			}
		    }
		  else
		    {
		      ok = NO;
		    }
		  if (YES == ok)
		    {
		      *dst++ = val;
		    }
		  else
		    {
		      /* A bad escape sequence is copied literally.
		       */
		      *dst++ = '=';
		      *dst++ = buf[0];
		      *dst++ = buf[1];
		    }
		}
	    }
	}
      else if (*src == '=')
	{
	  buf[pos++] = '=';
	}
      else
	{
	  *dst++ = *src;
	}
      src++;
    }
  [dData setLength: size + dst - beg];
  return YES;
}
@end

@interface	GSMimeChunkedDecoderContext : GSMimeCodingContext
{
@public
  unsigned char	buf[8];
  NSUInteger	pos;
  enum {
    ChunkSize,		// Reading chunk size
    ChunkExt,		// Reading chunk extensions
    ChunkEol1,		// Reading end of line after size;ext
    ChunkData,		// Reading chunk data
    ChunkEol2,		// Reading end of line after data
    ChunkFoot,		// Reading chunk footer after newline
    ChunkFootA		// Reading chunk footer
  } state;
  NSUInteger	size;	// Size of buffer required.
  NSMutableData	*data;
}
@end
@implementation	GSMimeChunkedDecoderContext
- (void) dealloc
{
  RELEASE(data);
  [super dealloc];
}
- (id) init
{
  self = [super init];
  if (self != nil)
    {
      data = [NSMutableData new];
    }
  return self;
}
@end

/**
 * Inefficient ... copies data into output object and only performs
 * the actual decoding at the end.
 */
@interface	GSMimeUUCodingContext : GSMimeCodingContext
@end

@implementation	GSMimeUUCodingContext
- (BOOL) decodeData: (const void*)sData
	     length: (NSUInteger)length
	   intoData: (NSMutableData*)dData
{
  [super decodeData: sData length: length intoData: dData];

  if ([self atEnd] == YES)
    {
      NSMutableData		*dec;

      dec = [[NSMutableData alloc] initWithCapacity: [dData length]];
      [dData uudecodeInto: dec name: 0 mode: 0];
      [dData setData: dec];
      RELEASE(dec);
    }
  return YES;
}
@end


@interface GSMimeParser (Private)
- (void) _child;
- (BOOL) _decodeBody: (NSData*)d;
- (NSString*) _decodeHeader;
- (NSRange) _endOfHeaders: (NSData*)newData;
- (BOOL) _scanHeaderParameters: (NSScanner*)scanner into: (GSMimeHeader*)info;
@end

/**
 * <p>
 *   This class provides support for parsing MIME messages
 *   into GSMimeDocument objects.  Each parser object maintains
 *   an associated document into which data is stored.
 * </p>
 * <p>
 *   You supply the document to be parsed as one or more data
 *   items passed to the -parse: method, and (if
 *   the method always returns YES, you give it
 *   a final nil argument to mark the end of the
 *   document.
 * </p>
 * <p>
 *   On completion of parsing a valid document, the
 *   [GSMimeParser-mimeDocument] method returns the
 *   resulting parsed document.
 * </p>
 * <p>If you need to parse faulty documents (eg where a faulty mail client
 *   has produced an email which does not conform to the MIME standards), you
 *   should look at the -setBuggyQuotes: and -setDefaultCharset: methods, which
 *   are designed to cope with the most common faults.
 * </p>
 */
@implementation	GSMimeParser

/**
 * Convenience method to parse a single data item as a MIME message
 * and return the resulting document.
 */
+ (GSMimeDocument*) documentFromData: (NSData*)mimeData
{
  GSMimeDocument	*newDocument = nil;
  GSMimeParser		*parser = [GSMimeParser new];

  if ([parser parse: mimeData] == YES)
    {
      [parser parse: nil];
    }
  if ([parser isComplete] == YES)
    {
      newDocument = [parser mimeDocument];
      IF_NO_GC(RETAIN(newDocument);)
    }
  RELEASE(parser);
  return AUTORELEASE(newDocument);
}

+ (void) initialize
{
  if (NSArrayClass == 0)
    {
      NSArrayClass = [NSArray class];
    }
  if (NSStringClass == 0)
    {
      NSStringClass = [NSString class];
    }
  if (documentClass == 0)
    {
      documentClass = [GSMimeDocument class];
    }
}

/**
 * Create and return a parser.
 */
+ (GSMimeParser*) mimeParser
{
  return AUTORELEASE([[self alloc] init]);
}

/**
 * Return a coding context object to be used for decoding data
 * according to the scheme specified in the header.
 * <p>
 *   The default implementation supports the following transfer
 *   encodings specified in either a <code>transfer-encoding</code>
 *   of <code>content-transfer-encoding</code> header -
 * </p>
 * <list>
 *   <item>base64</item>
 *   <item>quoted-printable</item>
 *   <item>binary (no coding actually performed)</item>
 *   <item>7bit (no coding actually performed)</item>
 *   <item>8bit (no coding actually performed)</item>
 *   <item>chunked (for HTTP/1.1)</item>
 *   <item>x-uuencode</item>
 * </list>
 * To add new coding schemes to the parser, you need to ovrride
 * this method to return a new coding context for your scheme
 * when the info argument indicates that this is appropriate.
 */
- (GSMimeCodingContext*) contextFor: (GSMimeHeader*)info
{
  NSString	*name;
  NSString	*value;

  if (info == nil)
    {
      return AUTORELEASE([GSMimeCodingContext new]);
    }

  name = [info name];
  if ([name isEqualToString: @"content-transfer-encoding"] == YES
   || [name isEqualToString: @"transfer-encoding"] == YES)
    {
      value = [[info value] lowercaseString];
      if ([value length] == 0)
	{
	  NSLog(@"Bad value for %@ header - assume binary encoding", name);
	  return AUTORELEASE([GSMimeCodingContext new]);
	}
      if ([value isEqualToString: @"base64"] == YES)
	{
	  return AUTORELEASE([GSMimeBase64DecoderContext new]);
	}
      else if ([value isEqualToString: @"quoted-printable"] == YES)
	{
	  return AUTORELEASE([GSMimeQuotedDecoderContext new]);
	}
      else if ([value isEqualToString: @"binary"] == YES)
	{
	  return AUTORELEASE([GSMimeCodingContext new]);
	}
      else if ([value characterAtIndex: 0] == '7')
	{
	  return AUTORELEASE([GSMimeCodingContext new]);
	}
      else if ([value characterAtIndex: 0] == '8')
	{
	  return AUTORELEASE([GSMimeCodingContext new]);
	}
      else if ([value isEqualToString: @"chunked"] == YES)
	{
	  return AUTORELEASE([GSMimeChunkedDecoderContext new]);
	}
      else if ([value isEqualToString: @"x-uuencode"] == YES)
	{
	  return AUTORELEASE([GSMimeUUCodingContext new]);
	}
    }

  NSLog(@"contextFor: - unknown header (%@) ... assumed binary encoding", name);
  return AUTORELEASE([GSMimeCodingContext new]);
}

/**
 * Return the data accumulated in the parser.  If the parser is
 * still parsing headers, this will be the header data read so far.
 * If the parse has parsed the body of the message, this will be
 * the data of the body, with any transfer encoding removed.
 */
- (NSData*) data
{
  return data;
}

- (void) dealloc
{
  RELEASE(data);
  RELEASE(child);
  RELEASE(context);
  RELEASE(boundary);
  RELEASE(document);
  [super dealloc];
}

/**
 * <p>
 *   Decodes the raw data from the specified range in the source
 *   data object and appends it to the destination data object.
 *   The context object provides information about the content
 *   encoding type in use, and the state of the decoding operation.
 * </p>
 * <p>
 *   This method may be called repeatedly to incrementally decode
 *   information as it arrives on some communications channel.
 *   It should be called with a nil source data item (or with
 *   the atEnd flag of the context set to YES) in order to flush
 *   any information held in the context to the output data
 *   object.
 * </p>
 * <p>
 *   You may override this method in order to implement additional
 *   coding schemes, but usually it should be enough for you to
 *   implement a custom GSMimeCodingContext subclass fotr this method
 *   to use.
 * </p>
 */
- (BOOL) decodeData: (NSData*)sData
	  fromRange: (NSRange)aRange
	   intoData: (NSMutableData*)dData
	withContext: (GSMimeCodingContext*)con
{
  NSUInteger		len = [sData length];
  BOOL			result = YES;

  if (dData == nil || [con isKindOfClass: [GSMimeCodingContext class]] == NO)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"[%@ -%@] bad destination data for decode",
	NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    }
  GS_RANGE_CHECK(aRange, len);

  /*
   * Chunked decoding is relatively complex ... it makes sense to do it
   * here, in order to make use of parser facilities, rather than having
   * the decoding context do the work.  In this case the context is used
   * solely to store state information.
   */
  if ([con class] == [GSMimeChunkedDecoderContext class])
    {
      GSMimeChunkedDecoderContext	*ctxt;
      NSUInteger			size = [dData length];
      unsigned char		*beg;
      unsigned char		*dst;
      const char		*src;
      const char		*end;
      const char		*footers;

      ctxt = (GSMimeChunkedDecoderContext*)con;

      /*
       * Get pointers into source data buffer.
       */
      src = (const char *)[sData bytes];
      footers = src;
      src += aRange.location;
      end = src + aRange.length;
      beg = 0;
      /*
       * Make sure buffer is big enough, and set up output pointers.
       */
      [dData setLength: ctxt->size];
      dst = (unsigned char*)[dData mutableBytes];
      dst = dst + size;
      beg = dst;

      while ([ctxt atEnd] == NO && src < end)
	{
	  switch (ctxt->state)
	    {
	      case ChunkSize:
		if (isxdigit(*src) && ctxt->pos < sizeof(ctxt->buf))
		  {
		    ctxt->buf[ctxt->pos++] = *src;
		  }
		else if (*src == ';')
		  {
		    ctxt->state = ChunkExt;
		  }
		else if (*src == '\r')
		  {
		    ctxt->state = ChunkEol1;
		  }
		else if (*src == '\n')
		  {
		    ctxt->state = ChunkData;
		  }
		src++;
		if (ctxt->state != ChunkSize)
		  {
		    NSUInteger	val = 0;
		    NSUInteger	index;

		    for (index = 0; index < ctxt->pos; index++)
		      {
			val *= 16;
			if (isdigit(ctxt->buf[index]))
			  {
			    val += ctxt->buf[index] - '0';
			  }
			else if (isupper(ctxt->buf[index]))
			  {
			    val += ctxt->buf[index] - 'A' + 10;
			  }
			else
			  {
			    val += ctxt->buf[index] - 'a' + 10;
			  }
		      }
		    ctxt->pos = val;
		    /*
		     * If we have read a chunk already, make sure that our
		     * destination size is updated correctly before growing
		     * the buffer for another chunk.
		     */
		    size += (dst - beg);
		    ctxt->size = size + val;
		    [dData setLength: ctxt->size];
		    dst = (unsigned char*)[dData mutableBytes];
		    dst += size;
		    beg = dst;
		  }
		break;

	    case ChunkExt:
	      if (*src == '\r')
		{
		  ctxt->state = ChunkEol1;
		}
	      else if (*src == '\n')
		{
		  ctxt->state = ChunkData;
		}
	      src++;
	      break;

	    case ChunkEol1:
	      if (*src == '\n')
		{
		  ctxt->state = ChunkData;
		}
	      src++;
	      break;

	    case ChunkData:
	      /*
	       * If the pos is non-zero, we have a data chunk to read.
	       * otherwise, what we actually want is to read footers.
	       */
	      if (ctxt->pos > 0)
		{
		  *dst++ = *src++;
		  if (--ctxt->pos == 0)
		    {
		      ctxt->state = ChunkEol2;
		    }
		}
	      else
		{
		  footers = src;		// Record start position.
		  ctxt->state = ChunkFoot;
		}
	      break;

	    case ChunkEol2:
	      if (*src == '\n')
		{
		  ctxt->state = ChunkSize;
		}
	      src++;
	      break;

	    case ChunkFoot:
	      if (*src == '\r')
		{
		  src++;
		}
	      else if (*src == '\n')
		{
		  [ctxt setAtEnd: YES];
		}
	      else
		{
		  ctxt->state = ChunkFootA;
		}
	      break;

	    case ChunkFootA:
	      if (*src == '\n')
		{
		  ctxt->state = ChunkFootA;
		}
	      src++;
	      break;
	    }
	}
      if (ctxt->state == ChunkFoot || ctxt->state == ChunkFootA)
	{
	  [ctxt->data appendBytes: footers length: src - footers];
	  if ([ctxt atEnd] == YES)
	    {
	      NSMutableData	*old;

	      /*
	       * Pretend we are back parsing the original headers ...
	       */
	      old = data;
	      data = ctxt->data;
	      bytes = (unsigned char*)[data mutableBytes];
	      dataEnd = [data length];
	      flags.inBody = 0;

	      /*
	       * Duplicate the normal header parsing process for our footers.
	       */
	      while (flags.inBody == 0)
		{
		  NSString	*header;

		  header = [self _decodeHeader];
		  if (header == nil)
		    {
		      break;
		    }
		  if ([self parseHeader: header] == NO)
		    {
		      flags.hadErrors = 1;
		      break;
		    }
		}

	      /*
	       * restore original data.
	       */
	      ctxt->data = data;
	      data = old;
	      bytes = (unsigned char*)[data mutableBytes];
	      dataEnd = [data length];
	      flags.inBody = 1;
	    }
	}
      /*
       * Correct size of output buffer.
       */
      [dData setLength: size + dst - beg];
    }
  else
    {
      result = [con decodeData: [sData bytes] + aRange.location
			length: aRange.length
		      intoData: dData];
    }

  /*
   * A nil data item as input represents end of data.
   */
  if (sData == nil)
    {
      [con setAtEnd: YES];
    }

  return result;
}

- (NSString*) description
{
  NSMutableString	*desc;

  desc = [NSMutableString stringWithFormat: @"GSMimeParser <%0x> -\n", self];
  [desc appendString: [document description]];
  return desc;
}

/**
 * <deprecated />
 * Returns the object into which raw mime data is being parsed.
 */
- (id) document
{
  return document;
}

/** If there was more data passed to the parser than actually needed to
 * form the document, this method returns that excess data, othrwise it
 * returns nil.
 */
- (NSData*) excess
{
  if (flags.excessData == 1)
    {
      return boundary;
    }
  return nil;
}

/**
 * This method may be called to tell the parser that it should not expect
 * to parse any headers, and that the data it will receive is body data.<br />
 * If the parse is already in the body, or is complete, this method has
 * no effect.<br />
 * This is for use when some other utility has been used to parse headers,
 * and you have set the headers of the document owned by the parser
 * accordingly.  You can then use the GSMimeParser to read the body data
 * into the document.
 */
- (void) expectNoHeaders
{
  if (flags.complete == 0)
    {
      flags.inBody = 1;
    }
}

/**
 * Returns YES if the document parsing is known to be completed successfully.
 * Returns NO if either more data is needed, or if the parser encountered an
 * error.
 */
- (BOOL) isComplete
{
  if (flags.hadErrors == 1)
    {
      return NO;
    }
  return (flags.complete == 1) ? YES : NO;
}

/**
 * Returns YES if the parser is parsing an HTTP document rather than
 * a true MIME document.
 */
- (BOOL) isHttp
{
  return (flags.isHttp == 1) ? YES : NO;
}

/**
 * Returns YES if all the document headers have been parsed but
 * the document body parsing may not yet be complete.
 */
- (BOOL) isInBody
{
  return (flags.inBody == 1) ? YES : NO;
}

/**
 * Returns YES if parsing of the document headers has not yet
 * been completed.
 */
- (BOOL) isInHeaders
{
  if (flags.inBody == 1)
    return NO;
  if (flags.complete == 1)
    return NO;
  return YES;
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      document = [[documentClass alloc] init];
      data = [NSMutableData new];
      _defaultEncoding = NSASCIIStringEncoding;
    }
  return self;
}

/**
 * Returns the GSMimeDocument instance into which data is being parsed
 * or has been parsed.
 */
- (GSMimeDocument*) mimeDocument
{
  return document;
}

/**
 * <p>
 *   This method is called repeatedly to pass raw mime data into
 *   the parser.  It returns <code>YES</code> as long as it wants
 *   more data to complete parsing of a document, and <code>NO</code>
 *   if parsing is complete, either due to having reached the end of
 *   a document or due to an error.
 * </p>
 * <p>
 *   Since it is not always possible to determine if the end of a
 *   MIME document has been reached from its content, the method
 *   may need to be called with a nil or empty argument after you have
 *   passed all the data to it ... this tells it that the data
 *   is complete.
 * </p>
 * <p>
 *   The parser attempts to be as flexible as possible and to continue
 *   parsing wherever it can.  If an error occurs in parsing, the
 *   -isComplete method will always return NO, even after the -parse:
 *   method has been called with a nil argument.
 * </p>
 * <p>
 *   A multipart document will be parsed to content consisting of an
 *   NSArray of GSMimeDocument instances representing each part.<br />
 *   Otherwise, a document will become content of type NSData, unless
 *   it is of content type <em>text</em>, in which case it will be an
 *   NSString.<br />
 *   If a document has no content type specified, it will be treated as
 *   <em>text</em>, unless it is identifiable as a <em>file</em>
 *   (eg. t has a content-disposition header containing a filename parameter).
 * </p>
 */
- (BOOL) parse: (NSData*)d
{
  if (flags.complete == 1)
    {
      return NO;	/* Already completely parsed! */
    }
  if ([d length] > 0)
    {
      if (flags.inBody == 0)
        {
          if ([self parseHeaders: d remaining: &d] == YES)
            {
              return YES;
            }
        }
      if ([d length] > 0)
	{
	  if (flags.inBody == 1)
	    {
	      /*
	       * We can't just re-call -parse: ...
	       * that would lead to recursion.
	       */
	      return [self _decodeBody: d];
	    }
	  else
	    {
	      return [self parse: d];
	    }
	}
      if (flags.complete == 1)
	{
	  return NO;
	}
      return YES;	/* Want more data for body */
    }
  else
    {
      if (flags.wantEndOfLine == 1)
	{
	  [self parse: [NSData dataWithBytes: "\r\n" length: 2]];
	}
      else if (flags.inBody == 1)
	{
	  [self _decodeBody: d];
	}
      else
	{
	  /*
	   * If still parsing headers, add CR-LF sequences to terminate
	   * the headers.
           */
	  [self parse: [NSData dataWithBytes: "\r\n\r\n" length: 4]];
	}
      flags.wantEndOfLine = 0;
      flags.inBody = 0;
      flags.complete = 1;	/* Finished parsing	*/
      return NO;		/* Want no more data	*/
    }
}

- (BOOL) parseHeaders: (NSData*)d remaining: (NSData**)body
{
  GSMimeHeader	*info;
  GSMimeHeader	*hdr;
  NSRange	r;
  NSUInteger	l = [d length];

  if (flags.complete == 1 || flags.inBody == 1)
    {
      return NO;	/* Headers already parsed! */
    }
  if (body != 0)
    {
      *body = nil;
    }
  if (l == 0)
    {
      /* Add an empty line to the end of the current headers to force
       * completion of header parsing.
       */
      [self parseHeaders: [NSData dataWithBytes: "\r\n\r\n" length: 4]
	       remaining: 0];
      flags.wantEndOfLine = 0;
      flags.excessData = 0;
      flags.inBody = 0;
      flags.complete = 1;	/* Finished parsing	*/
      return NO;		/* Want no more data	*/
    }

  NSDebugMLLog(@"GSMime", @"Parse %u bytes - '%*.*s'", l, l, l, [d bytes]);

  r = [self _endOfHeaders: d];
  if (r.location == NSNotFound)
    {
      [data appendData: d];
      bytes = (unsigned char*)[data bytes];
      dataEnd = [data length];
    }
  else
    {
      NSUInteger	i = NSMaxRange(r);

      i -= [data length];			// Bytes to append to headers
      [data appendBytes: [d bytes] length: i];
      bytes = (unsigned char*)[data bytes];
      dataEnd = [data length];
      if (l > i)
	{
	  d = [[[NSData alloc] initWithBytesNoCopy: (void*)([d bytes] + i)
					    length: l - i
				      freeWhenDone: NO] autorelease];
	}
      else
	{
	  d = nil;
	}
      if (body != 0)
	{
	  *body = d;
	}
    }

  while (flags.inBody == 0)
    {
      NSString		*header;

      header = [self _decodeHeader];
      if (header == nil)
	{
	  if (1 == flags.hadErrors)
	    {
	      return NO;	/* Couldn't handle words.	*/
	    }
	  else if (0 == flags.inBody)
	    {
	      return YES;	/* need more data */
	    }
	}
      else if ([self parseHeader: header] == NO)
	{
	  flags.hadErrors = 1;
	  return NO;	/* Header not parsed properly.	*/
	}
    }

  /*
   * All headers have been parsed, so we empty our internal buffer
   * (which we will now use to store decoded data)
   */
  [data setLength: 0];
  bytes = 0;
  input = 0;

  /*
   * We have finished parsing the headers, but we may have http
   * continuation header(s), in which case, we must start parsing
   * headers again.
   */
  info = [document _lastHeaderNamed: @"http"];
  if (info != nil && flags.isHttp == 1)
    {
      NSNumber	*num;

      num = [info objectForKey: NSHTTPPropertyStatusCodeKey];
      if (num != nil)
        {
          int	v = [num intValue];

          if (v >= 100 && v < 200)
            {
              /*
               * This is an intermediary response ... so we have
               * to restart the parsing operation!
               */
              NSDebugMLLog(@"GSMime",
                @"Parsed http continuation", "");
              flags.inBody = 0;
              if ([d length] == 0)
                {
                  /* We need more data, so we have to return YES
                   * to ask our caller to provide it.
                   */
                  return YES;
                }
              return [self parseHeaders: d remaining: body];
            }
        }
    }

  /*
   * If there is a zero content length, all parsing is complete,
   * not just header parsing.
   */
  if (flags.headersOnly == 1
    || ((hdr = [document headerNamed: @"content-length"]) != nil
      && [[hdr value] intValue] == 0))
    {
      [document setContent: @""];
      flags.inBody = 0;
      flags.complete = 1;
      /* If we have more data after the headers ... it's excess and
       * should become available as excess data.
       */
      if ([d length] > 0)
	{
          ASSIGNCOPY(boundary, d);
	  flags.excessData = 1;
	}
    }

  return NO;		// No more data needed
}

/**
 * <p>
 *   This method is called to parse a header line <em>for the
 *   current document</em>, split its contents into a GSMimeHeader
 *   object, and add that information to the document.<br />
 *   The method is normally used internally by the -parse: method,
 *   but you may also call it to parse an entire header line and
 *   add it to the document (this may be useful in conjunction
 *   with the -expectNoHeaders method, to parse a document body data
 *   into a document where the headers are available from a
 *   separate source).
 * </p>
 * <example>
 *   GSMimeParser *parser = [GSMimeParser mimeParser];
 *
 *   [parser parseHeader: @"content-type: text/plain"];
 *   [parser expectNoHeaders];
 *   [parser parse: bodyData];
 *   [parser parse: nil];
 * </example>
 * <p>
 *   The standard implementation of this method scans the header
 *   name and then calls -scanHeaderBody:into: to complete the
 *   parsing of the header.
 * </p>
 * <p>
 *   This method also performs consistency checks on headers scanned
 *   so it is recommended that it is not overridden, but that
 *   subclasses override -scanHeaderBody:into: to
 *   implement custom scanning.
 * </p>
 * <p>
 *   As a special case, for HTTP support, this method also parses
 *   lines in the format of HTTP responses as if they were headers
 *   named <code>http</code>.  The resulting header object contains
 *   additional object values -
 * </p>
 * <deflist>
 *   <term>HttpMajorVersion</term>
 *   <desc>The first part of the version number</desc>
 *   <term>HttpMinorVersion</term>
 *   <desc>The second part of the version number</desc>
 *   <term>NSHTTPPropertyServerHTTPVersionKey</term>
 *   <desc>The full HTTP protocol version number</desc>
 *   <term>NSHTTPPropertyStatusCodeKey</term>
 *   <desc>The HTTP status code (numeric)</desc>
 *   <term>NSHTTPPropertyStatusReasonKey</term>
 *   <desc>The text message (if any) after the status code</desc>
 * </deflist>
 */
- (BOOL) parseHeader: (NSString*)aHeader
{
  NSScanner		*scanner = [NSScanner scannerWithString: aHeader];
  NSString		*name;
  NSString		*value;
  GSMimeHeader		*info;

  NSDebugMLLog(@"GSMime", @"Parse header - '%@'", aHeader);
  info = AUTORELEASE([GSMimeHeader new]);

  /*
   * Special case - permit web response status line to act like a header.
   */
  if ([scanner scanString: @"HTTP/" intoString: &name] == YES)
    {
      name = @"HTTP";
    }
  else
    {
      if ([scanner scanUpToString: @":" intoString: &name] == NO)
	{
	  NSLog(@"Not a valid header (%@)", [scanner string]);
	  return NO;
	}
      /*
       * Position scanner after colon and any white space.
       */
      if ([scanner scanString: @":" intoString: 0] == NO)
	{
	  NSLog(@"No colon terminating name in header (%@)", [scanner string]);
	  return NO;
	}
    }

  /*
   * Set the header name.
   */
  [info setName: name];
  name = [info name];

  /*
   * Break header fields out into info dictionary.
   */
  if ([self scanHeaderBody: scanner into: info] == NO)
    {
      return NO;
    }

  /*
   * Check validity of broken-out header fields.
   */
  if ([name isEqualToString: @"mime-version"] == YES)
    {
      int	majv = 0;
      int	minv = 0;

      value = [info value];
      if ([value length] == 0)
	{
	  NSLog(@"Missing value for mime-version header");
	  return NO;
	}
      if (sscanf([value UTF8String], "%d.%d", &majv, &minv) != 2)
	{
	  NSLog(@"Bad value for mime-version header (%@)", value);
	  return NO;
	}
      [document deleteHeaderNamed: name];	// Should be unique
    }
  else if ([name isEqualToString: @"content-type"] == YES)
    {
      NSString	*tmp = [info parameterForKey: @"boundary"];
      NSString	*type;
      NSString	*subtype;

      DESTROY(boundary);
      if (tmp != nil)
	{
	  NSUInteger	l = [tmp length];
	  unsigned char	*b;

#if	GS_WITH_GC
	  b = NSAllocateCollectable(l + 3, 0);
#else
	  b = NSZoneMalloc(NSDefaultMallocZone(), l + 3);
#endif
	  b[0] = '-';
	  b[1] = '-';
	  [tmp getCString: (char*)&b[2]
		maxLength: l + 1
		 encoding: NSISOLatin1StringEncoding];
	  boundary = [[NSData alloc] initWithBytesNoCopy: b length: l + 2];
	}

      type = [info objectForKey: @"Type"];
      if ([type length] == 0)
	{
	  NSLog(@"Missing Mime content-type");
	  return NO;
	}
      subtype = [info objectForKey: @"Subtype"];

      if ([type isEqualToString: @"text"] == YES)
	{
	  if (subtype == nil)
	    {
	      subtype = @"plain";
	      [info setObject: subtype forKey: @"Subtype"];
	    }
	}
      else if ([type isEqualToString: @"multipart"] == YES)
	{
	  if (subtype == nil)
	    {
	      subtype = @"mixed";
	      [info setObject: subtype forKey: @"Subtype"];
	    }
	  if (boundary == nil)
	    {
	      NSLog(@"multipart message without boundary");
	      return NO;
	    }
	}
      else
	{
	  if (subtype == nil)
	    {
	      subtype = @"octet-stream";
	      [info setObject: subtype forKey: @"Subtype"];
	    }
	}

      [document deleteHeaderNamed: name];	// Should be unique
    }

  NS_DURING
    [document addHeader: info];
  NS_HANDLER
    return NO;
  NS_ENDHANDLER
NSDebugMLLog(@"GSMime", @"Header parsed - %@", info);

  return YES;
}

/**
 * <p>
 *   This method is called to parse a header line and split its
 *   contents into the supplied [GSMimeHeader] instance.
 * </p>
 * <p>
 *   On entry, the header (info) is already partially filled,
 *   the name is a lowercase representation of the
 *   header name.  The the scanner must be set to a scan location
 *   immediately after the colon in the original header string
 *   (ie to the header value string).
 * </p>
 * <p>
 *   If the header is parsed successfully, the method should
 *   return YES, otherwise NO.
 * </p>
 * <p>
 *   You would not normally call this method directly yourself,
 *   but may override it to support parsing of new headers.<br />
 *   If you do call this yourself, you need to be aware that it
 *   may change the state of the document in the parser.
 * </p>
 * <p>
 *   You should be aware of the parsing that the standard
 *   implementation performs, and that <em>needs</em> to be
 *   done for certain headers in order to permit the parser to
 *   work generally -
 * </p>
 * <deflist>
 *   <term>content-disposition</term>
 *   <desc>
 *     <deflist>
 *     <term>Value</term>
 *     <desc>
 *       The content disposition (excluding parameters) as a
 *       lowercase string.
 *     </desc>
 *     </deflist>
 *   </desc>
 *   <term>content-type</term>
 *   <desc>
 *     <deflist>
 *       <term>Subtype</term>
 *       <desc>The MIME subtype lowercase</desc>
 *       <term>Type</term>
 *       <desc>The MIME type lowercase</desc>
 *       <term>value</term>
 *       <desc>The full MIME type (xxx/yyy) in lowercase</desc>
 *     </deflist>
 *   </desc>
 *   <term>content-transfer-encoding</term>
 *   <desc>
 *     <deflist>
 *     <term>Value</term>
 *     <desc>The transfer encoding type in lowercase</desc>
 *     </deflist>
 *   </desc>
 *   <term>http</term>
 *   <desc>
 *     <deflist>
 *     <term>HttpVersion</term>
 *     <desc>The HTTP protocol version number</desc>
 *     <term>HttpMajorVersion</term>
 *     <desc>The first component of the version number</desc>
 *     <term>HttpMinorVersion</term>
 *     <desc>The second component of the version number</desc>
 *     <term>HttpStatus</term>
 *     <desc>The response status value (numeric code)</desc>
 *     <term>Value</term>
 *     <desc>The text message (if any)</desc>
 *     </deflist>
 *   </desc>
 *   <term>transfer-encoding</term>
 *   <desc>
 *     <deflist>
 *      <term>Value</term>
 *      <desc>The transfer encoding type in lowercase</desc>
 *     </deflist>
 *   </desc>
 * </deflist>
 */
- (BOOL) scanHeaderBody: (NSScanner*)scanner
		   into: (GSMimeHeader*)info
{
  NSString		*name = [info name];
  NSString		*value = nil;

  [self scanPastSpace: scanner];

  /*
   *	Now see if we are interested in any of it.
   */
  if ([name isEqualToString: @"http"] == YES)
    {
      int	loc = [scanner scanLocation];
      int	major;
      int	minor;
      int	status;
      NSUInteger	count;
      NSArray	*hdrs;

      if ([scanner scanInt: &major] == NO || major < 0)
	{
	  NSLog(@"Bad value for http major version in %@", [scanner string]);
	  return NO;
	}
      if ([scanner scanString: @"." intoString: 0] == NO)
	{
	  NSLog(@"Bad format for http version in %@", [scanner string]);
	  return NO;
	}
      if ([scanner scanInt: &minor] == NO || minor < 0)
	{
	  NSLog(@"Bad value for http minor version in %@", [scanner string]);
	  return NO;
	}
      if ([scanner scanInt: &status] == NO || status < 0)
	{
	  NSLog(@"Bad value for http status in %@", [scanner string]);
	  return NO;
	}
      [info setObject: [NSStringClass stringWithFormat: @"%d", minor]
	       forKey: @"HttpMinorVersion"];
      [info setObject: [NSStringClass stringWithFormat: @"%d.%d", major, minor]
	       forKey: @"HttpVersion"];
      [info setObject: [NSStringClass stringWithFormat: @"%d", major]
	       forKey: NSHTTPPropertyServerHTTPVersionKey];
      [info setObject: [NSNumber numberWithInt: status]
	       forKey: NSHTTPPropertyStatusCodeKey];
      [self scanPastSpace: scanner];
      value = [[scanner string] substringFromIndex: [scanner scanLocation]];
      [info setObject: value
	       forKey: NSHTTPPropertyStatusReasonKey];
      value = [[scanner string] substringFromIndex: loc];
      /*
       * Get rid of preceding headers in case this is a continuation.
       */
      hdrs = [document allHeaders];
      for (count = 0; count < [hdrs count]; count++)
	{
	  GSMimeHeader	*h = [hdrs objectAtIndex: count];

	  [document deleteHeader: h];
	}
      /*
       * Mark to say we are parsing HTTP content
       */
      [self setIsHttp];
    }
  else if ([name isEqualToString: @"content-transfer-encoding"] == YES
    || [name isEqualToString: @"transfer-encoding"] == YES)
    {
      value = [self scanToken: scanner];
      if ([value length] == 0)
	{
	  NSLog(@"Bad value for content-transfer-encoding header in %@",
	    [scanner string]);
	  return NO;
	}
      value = [value lowercaseString];
    }
  else if ([name isEqualToString: @"content-type"] == YES)
    {
      NSString	*type;
      NSString	*subtype = nil;

      type = [self scanName: scanner];
      if ([type length] == 0)
	{
	  NSLog(@"Invalid Mime content-type in %@", [scanner string]);
	  return NO;
	}
      type = [type lowercaseString];
      [info setObject: type forKey: @"Type"];
      if ([scanner scanString: @"/" intoString: 0] == YES)
	{
	  subtype = [self scanName: scanner];
	  if ([subtype length] == 0)
	    {
	      NSLog(@"Invalid Mime content-type (subtype) in %@",
		[scanner string]);
	      return NO;
	    }
	  subtype = [subtype lowercaseString];
	  [info setObject: subtype forKey: @"Subtype"];
	  value = [NSStringClass stringWithFormat: @"%@/%@", type, subtype];
	}
      else
	{
	  value = type;
	}

      [self _scanHeaderParameters: scanner into: info];
    }
  else if ([name isEqualToString: @"content-disposition"] == YES)
    {
      value = [self scanName: scanner];
      value = [value lowercaseString];
      /*
       *	Concatenate slash separated parts of field.
       */
      while ([scanner scanString: @"/" intoString: 0] == YES)
	{
	  NSString	*sub = [self scanName: scanner];

	  if ([sub length] > 0)
	    {
	      sub = [sub lowercaseString];
	      value = [NSStringClass stringWithFormat: @"%@/%@", value, sub];
	    }
	}

      /*
       *	Expect anything else to be 'name=value' parameters.
       */
      [self _scanHeaderParameters: scanner into: info];
    }
  else
    {
      int	loc;

      [self scanPastSpace: scanner];
      loc = [scanner scanLocation];
      value = [[scanner string] substringFromIndex: loc];
    }

  if (value != nil)
    {
      [info setValue: value];
    }

  return YES;
}

/**
 * A convenience method to use a scanner (that is set up to scan a
 * header line) to scan a name - a simple word.
 * <list>
 *   <item>Leading whitespace is ignored.</item>
 * </list>
 */
- (NSString*) scanName: (NSScanner*)scanner
{
  NSString		*value;

  [self scanPastSpace: scanner];

  /*
   * Scan value terminated by any MIME special character.
   */
  if ([scanner scanUpToCharactersFromSet: rfc2045Specials
			      intoString: &value] == NO)
    {
      return nil;
    }
  return value;
}

/**
 * A convenience method to scan past any whitespace in the scanner
 * in preparation for scanning something more interesting that
 * comes after it.  Returns YES if any space was read, NO otherwise.
 */
- (BOOL) scanPastSpace: (NSScanner*)scanner
{
  NSCharacterSet	*skip;
  BOOL			scanned;

  skip = RETAIN([scanner charactersToBeSkipped]);
  [scanner setCharactersToBeSkipped: nil];
  scanned = [scanner scanCharactersFromSet: whitespace intoString: 0];
  [scanner setCharactersToBeSkipped: skip];
  RELEASE(skip);
  return scanned;
}

/**
 * A convenience method to use a scanner (that is set up to scan a
 * header line) to scan in a special character that terminated a
 * token previously scanned.  If the token was terminated by
 * whitespace and no other special character, the string returned
 * will contain a single space character.
 */
- (NSString*) scanSpecial: (NSScanner*)scanner
{
  NSCharacterSet	*specials;
  NSUInteger		location;
  unichar		c;

  [self scanPastSpace: scanner];

  if (flags.isHttp == 1)
    {
      specials = rfc822Specials;
    }
  else
    {
      specials = rfc2045Specials;
    }
  /*
   * Now return token delimiter (may be whitespace)
   */
  location = [scanner scanLocation];
  c = [[scanner string] characterAtIndex: location];

  if ([specials characterIsMember: c] == YES)
    {
      [scanner setScanLocation: location + 1];
      return [NSStringClass stringWithCharacters: &c length: 1];
    }
  else
    {
      return @" ";
    }
}

/**
 * A convenience method to use a scanner (that is set up to scan a
 * header line) to scan a header token - either a quoted string or
 * a simple word.
 * <list>
 *   <item>Leading whitespace is ignored.</item>
 *   <item>Backslash escapes in quoted text are converted</item>
 * </list>
 */
- (NSString*) scanToken: (NSScanner*)scanner
{
  [self scanPastSpace: scanner];
  if ([scanner scanString: @"\"" intoString: 0] == YES)		// Quoted
    {
      NSString	*string = [scanner string];
      NSUInteger	length = [string length];
      NSUInteger	start = [scanner scanLocation];
      NSRange	r = NSMakeRange(start, length - start);
      BOOL	done = NO;

      while (done == NO)
	{
	  r = [string rangeOfString: @"\""
			    options: NSLiteralSearch
			      range: r];
	  if (r.length == 0)
	    {
	      NSLog(@"Parsing header value - found unterminated quoted string");
	      return nil;
	    }
	  if ([string characterAtIndex: r.location - 1] == '\\')
	    {
	      int	p;

	      /*
               * Count number of escape ('\') characters ... if it's odd
	       * then the quote has been escaped and is not a closing
	       * quote.
	       */
	      p = r.location;
	      while (p > 0 && [string characterAtIndex: p - 1] == '\\')
		{
		  p--;
		}
	      p = r.location - p;
	      if (p % 2 == 1)
		{
		  r.location++;
		  r.length = length - r.location;
		}
	      else
		{
		  done = YES;
		}
	    }
	  else
	    {
	      done = YES;
	    }
	}
      [scanner setScanLocation: r.location + 1];
      length = r.location - start;
      if (length == 0)
	{
	  return @"";
	}
      else
	{
	  unichar	buf[length];
	  unichar	*src = buf;
	  unichar	*dst = buf;

	  [string getCharacters: buf range: NSMakeRange(start, length)];
	  while (src < &buf[length])
	    {
	      if (*src == '\\')
		{
		  src++;
		  if (flags.buggyQuotes == 1 && *src != '\\' && *src != '"')
		    {
		      *dst++ = '\\';	// Buggy use of escape in quotes.
		    }
		}
	      *dst++ = *src++;
	    }
	  return [NSStringClass stringWithCharacters: buf length: dst - buf];
	}
    }
  else							// Token
    {
      NSCharacterSet		*specials;
      NSString			*value;

      if (flags.isHttp == 1)
	{
	  specials = rfc822Specials;
	}
      else
	{
	  specials = rfc2045Specials;
	}

      /*
       * Move past white space.
       */
      [self scanPastSpace: scanner];

      /*
       * Scan value terminated by any special character.
       */
      if ([scanner scanUpToCharactersFromSet: specials
				  intoString: &value] == NO)
	{
	  return nil;
	}
      return value;
    }
}

/**
 * Method to inform the parser that the data it is parsing is likely to
 * contain fields with buggy use of backslash quotes ... and it should
 * try to be tolerant of them and treat them as is they were escaped
 * backslashes.  This is for use with things like microsoft internet
 * explorer, which puts the backslashes used as file path separators
 * in parameters without quoting them.
 */
- (void) setBuggyQuotes: (BOOL)flag
{
  if (flag)
    {
      flags.buggyQuotes = 1;
    }
  else
    {
      flags.buggyQuotes = 0;
    }
}

/** This is a method to inform the parser that body parts with no content-type
 * header (which are treated as text/plain) should use the specified
 * characterset rather than the default (us-ascii).<br />
 * This also controls the parsing of headers ... in a legal MIME document
 * these must consst solely of us-ascii characters, but setting a different
 * default characterset (such as latin1) will permit many illegal header
 * lines (produced by faulty mail clients) to be parsed.<br />
 * HTTP requests use headers in the latin1 characterset,  so this is the
 * header line characterset used most commonly by faulty clients.
 */
- (void) setDefaultCharset: (NSString*)aName
{
  _defaultEncoding = [documentClass encodingFromCharset: aName];
  if (_defaultEncoding == 0)
    {
      _defaultEncoding = NSASCIIStringEncoding;
    }
}

/**
 * Method to inform the parser that only the headers should be parsed
 * and any remaining data be treated as excess
 */
- (void) setHeadersOnly
{
  flags.headersOnly = 1;
}

/**
 * Method to inform the parser that the data it is parsing is an HTTP
 * document rather than true MIME.  This method is called internally
 * if the parser detects an HTTP response line at the start of the
 * headers it is parsing.
 */
- (void) setIsHttp
{
  flags.isHttp = 1;
}

@end

@implementation	GSMimeParser (Private)

/*
 * Make a new child to parse a subsidiary document
 */
- (void) _child
{
  DESTROY(child);
  child = [GSMimeParser new];
  if (flags.buggyQuotes == 1)
    {
      [child setBuggyQuotes: YES];
    }
  /*
   * Tell child parser the default encoding to use.
   */
  child->_defaultEncoding = _defaultEncoding;
}

/*
 * Return YES if more data is needed, NO if the body has been completely
 * parsed.
 */
- (BOOL) _decodeBody: (NSData*)d
{
  NSUInteger	l = [d length];
  BOOL		needsMore = YES;

  rawBodyLength += l;

  if (context == nil)
    {
      GSMimeHeader	*hdr;

      expect = 0;
      /*
       * Check for expected content length.
       */
      hdr = [document headerNamed: @"content-length"];
      if (hdr != nil)
	{
	  expect = [[hdr value] intValue];
	}

      /*
       * Set up context for decoding data.
       */
      hdr = [document headerNamed: @"transfer-encoding"];
      if (hdr == nil)
	{
	  hdr = [document headerNamed: @"content-transfer-encoding"];
	}
      else if ([[[hdr value] lowercaseString] isEqualToString: @"chunked"])
	{
	  /*
	   * Chunked transfer encoding overrides any content length spec.
	   */
	  expect = 0;
	}
      context = [self contextFor: hdr];
      IF_NO_GC([context retain];)
      NSDebugMLLog(@"GSMime", @"Parse body expects %u bytes", expect);
    }

  NSDebugMLLog(@"GSMime", @"Parse %u bytes - '%*.*s'", l, l, l, [d bytes]);
  // NSDebugMLLog(@"GSMime", @"Boundary - '%*.*s'", [boundary length], [boundary length], [boundary bytes]);

  if ([context atEnd] == YES)
    {
      flags.inBody = 0;
      flags.complete = 1;
      if ([d length] > 0)
	{
	  NSLog(@"Additional data (%*.*s) ignored after parse complete",
	    (int)[d length], (int)[d length], [d bytes]);
	}
      needsMore = NO;	/* Nothing more to do	*/
    }
  else if (boundary == nil)
    {
      GSMimeHeader	*typeInfo;
      NSString		*type;

      typeInfo = [document headerNamed: @"content-type"];
      type = [typeInfo objectForKey: @"Type"];
      if ([type isEqualToString: @"multipart"] == YES)
	{
	  NSLog(@"multipart decode attempt without boundary");
	  flags.inBody = 0;
	  flags.complete = 1;
	  needsMore = NO;
	}
      else
	{
	  NSUInteger	dLength = [d length];

	  if (expect > 0 && rawBodyLength > expect)
	    {
	      NSData	*excess;

	      dLength -= (rawBodyLength - expect);
	      rawBodyLength = expect;
	      excess = [d subdataWithRange:
		NSMakeRange(dLength, [d length] - dLength)];
	      ASSIGN(boundary, excess);
	      flags.excessData = 1;
	    }
	  [self decodeData: d
		 fromRange: NSMakeRange(0, dLength)
		  intoData: data
	       withContext: context];

	  if ([context atEnd] == YES
	    || (expect > 0 && rawBodyLength >= expect))
	    {
	      NSString	*subtype = [typeInfo objectForKey: @"Subtype"];

	      flags.inBody = 0;
	      flags.complete = 1;

	      NSDebugMLLog(@"GSMime", @"Parse body complete", "");
	      /*
	       * If no content type is supplied, we assume text ... unless
	       * we have something that's known to be a file.
	       */
	      if (type == nil)
		{
		  if ([document contentFile] != nil)
		    {
		      type = @"application";
		      subtype= @"octet-stream";
		    }
		  else
		    {
		      type = @"text";
		      subtype= @"plain";
		    }
		}

	      if ([type isEqualToString: @"text"] == YES
		&& [subtype isEqualToString: @"xml"] == NO)
		{
		  NSStringEncoding	stringEncoding = _defaultEncoding;
		  NSString		*string;

		  if (typeInfo == nil)
		    {
		      typeInfo = [GSMimeHeader new];
		      [typeInfo setName: @"content-type"];
		      [typeInfo setValue: @"text/plain"];
		      [typeInfo setObject: type forKey: @"Type"];
		      [typeInfo setObject: subtype forKey: @"Subtype"];
		      [document setHeader: typeInfo];
		      RELEASE(typeInfo);
		    }
		  else
		    {
		      NSString	*charset;

		      charset = [typeInfo parameterForKey: @"charset"];
		      if (charset != nil)
			{
			  stringEncoding
			    = [documentClass encodingFromCharset: charset];
			}
		    }

		  /*
		   * Ensure that the charset reflects the encoding used.
		   */
		  if (stringEncoding != NSASCIIStringEncoding)
		    {
		      NSString	*charset;

		      charset = [documentClass charsetFromEncoding:
			stringEncoding];
		      [typeInfo setParameter: charset
				      forKey: @"charset"];
		    }

		  /*
		   * Assume that content type is best represented as NSString.
		   */
		  string = [NSStringClass allocWithZone: NSDefaultMallocZone()];
		  string = [string initWithData: data
				       encoding: stringEncoding];
		  if (string == nil)
		    {
		      [document setContent: data];	// Can't make string
		    }
		  else
		    {
		      [document setContent: string];
		      RELEASE(string);
		    }
		}
	      else
		{
		  /*
		   * Assume that any non-text content type is best
		   * represented as NSData.
		   */
		  [document setContent: data];
		}
	      needsMore = NO;
	    }
	}
    }
  else
    {
      NSUInteger		bLength;
      const unsigned char	*bBytes;
      unsigned char		bInit;
      const unsigned char	*buf;
      NSUInteger		len;
      BOOL			done = NO;
      BOOL			endedFinalPart = NO;

      bLength = [boundary length];
      bBytes = (const unsigned char*)[boundary bytes];
      bInit = bBytes[0];

      /* If we already have buffered data, append the new information
       * so we have a single buffer to scan.
       */
      if ([data length] > 0)
	{
	  [data appendData: d];
	  bytes = (unsigned char*)[data mutableBytes];
	  dataEnd = [data length];
	  d = data;
	}
      buf = (const unsigned char*)[d bytes];
      len = [d length];

      while (done == NO)
	{
	  BOOL		found = NO;
	  NSUInteger	eol = len;

	  /*
	   * Search data for the next boundary.
	   */
	  while (len - lineStart >= bLength)
	    {
	      if (buf[lineStart] == bInit
		&& memcmp(&buf[lineStart], bBytes, bLength) == 0)
		{
		  if (lineStart == 0 || buf[lineStart-1] == '\r'
		    || buf[lineStart-1] == '\n')
		    {
		      BOOL		lastPart = NO;

		      lineEnd = lineStart + bLength;
		      eol = lineEnd;
		      if (lineEnd + 2 <= len && buf[lineEnd] == '-'
			&& buf[lineEnd+1] == '-')
			{
			  eol += 2;
			  lastPart = YES;
			}
		      /*
		       * Ignore space/tab characters after boundary marker
		       * and before crlf.  Strictly this is wrong ... but
		       * at least one mailer generates bogus whitespace here.
		       */
		      while (eol < len
			&& (buf[eol] == ' ' || buf[eol] == '\t'))
			{
			  eol++;
			}
		      if (eol < len && buf[eol] == '\r')
			{
			  eol++;
			}
		      if (eol < len && buf[eol] == '\n')
			{
			  eol++;
			  flags.wantEndOfLine = 0;
			  found = YES;
			  endedFinalPart = lastPart;
			}
		      else
			{
			  flags.wantEndOfLine = 1;
			}
		      break;
		    }
		}
	      lineStart++;
	    }
	  if (found == NO)
	    {
	      /* Need more data ... so, if we have none buffered we must
	       * buffer any unused data, otherwise we can copy data within
	       * the buffer.
	       */
	      if ([data length] == 0)
		{
		  [data appendBytes: buf + sectionStart
			     length: len - sectionStart];
		  sectionStart = lineStart = 0;
		  bytes = (unsigned char*)[data mutableBytes];
		  dataEnd = [data length];
		}
	      else if (sectionStart > 0)
		{
		  len -= sectionStart;
		  memcpy(bytes, buf + sectionStart, len);
		  sectionStart = lineStart = 0;
		  [data setLength: len];
		  dataEnd = len;
		}
	      done = YES;	/* Needs more data.	*/
	    }
	  else if (child == nil)
	    {
	      NSString	*cset;

	      /*
	       * Found boundary at the start of the first section.
	       * Set sectionStart to point immediately after boundary.
	       */
	      lineStart += bLength;
	      sectionStart = lineStart;

	      /*
	       * If we have an explicit character set for the multipart
	       * document, we set it as the default characterset inherited
	       * by any child documents.
	       */
	      cset = [[document headerNamed: @"content-type"]
		parameterForKey: @"charset"];
	      if (cset != nil)
		{
		  [self setDefaultCharset: cset];
		}

	      [self _child];
	    }
	  else
	    {
	      NSData		*childBody;
	      NSUInteger	pos;

	      /*
	       * Found boundary at the end of a section.
	       * Skip past line terminator for boundary at start of section
	       * or past marker for end of multipart document.
	       */
	      if (buf[sectionStart] == '-' && sectionStart < len
		&& buf[sectionStart+1] == '-')
		{
		  sectionStart += 2;
		}
	      if (buf[sectionStart] == '\r')
		{
		  sectionStart++;
		}
	      if (buf[sectionStart] == '\n')
		{
		  sectionStart++;
		}

	      /*
	       * Create data object for this section and pass it to the
	       * child parser to deal with.  NB. As lineStart points to
	       * the start of the end boundary, we need to step back to
	       * before the end of line introducing it in order to have
	       * the correct length of body data for the child document.
	       */
	      pos = lineStart;
	      if (pos > 0 && buf[pos-1] == '\n')
		{
		  pos--;
		}
	      if (pos > 0 && buf[pos-1] == '\r')
		{
		  pos--;
		}
	      /* Since we know the child can't modify it, and we know
	       * that we aren't going to change the buffer while the
	       * child is using it, we can safely pass a data object
	       * which simply references the memory in our own buffer.
	       */
	      childBody = [[NSData alloc]
		initWithBytesNoCopy: (void*)(buf + sectionStart)
			     length: pos - sectionStart
		       freeWhenDone: NO];
	      if ([child parse: childBody] == YES)
		{
		  /*
		   * The parser wants more data, so pass a nil data item
		   * to tell it that it has had all there is.
		   */
		  [child parse: nil];
		}
	      [childBody release];
	      if ([child isComplete] == YES)
		{
		  GSMimeDocument	*doc;

		  /*
		   * Store the document produced by the child, and
		   * create a new parser for the next section.
	           */
		  doc = [child mimeDocument];
		  if (doc != nil)
		    {
		      [document addContent: doc];
		    }
		  [self _child];
		}
	      else
		{
		  /*
		   * Section failed to decode properly!
		   */
		  NSLog(@"Failed to decode section of multipart");
		  [self _child];
		}

	      /*
	       * Update parser data.
	       */
	      lineStart += bLength;
	      sectionStart = lineStart;
	      if (endedFinalPart == YES)
		{
		  if (eol < len)
		    {
		      NSData	*excess;

		      excess = [[NSData alloc] initWithBytes: buf + eol
						      length: len - eol];
		      ASSIGN(boundary, excess);
		      flags.excessData = 1;
		      [excess release];
		    }
		  lineStart = sectionStart = 0;
		  [data setLength: 0];
		  done = YES;
		}
	    }
	}
      /*
       * Check to see if we have reached content length or ended multipart
       * document.
       */
      if (endedFinalPart == YES || (expect > 0 && rawBodyLength >= expect))
	{
	  flags.complete = 1;
	  flags.inBody = 0;
	  needsMore = NO;
	}
    }
  return needsMore;
}

static const unsigned char *
unfold(const unsigned char *src, const unsigned char *end, BOOL *folded)
{
  BOOL	startOfLine = YES;

  *folded = NO;

  if (src >= end)
    {
      /* Not enough data to tell whether this is a header end or
       * just a folded header ... need to get more input.
       */
      return 0;
    }

  while (src < end && isspace(*src))
    {
      if (*src == '\r' || *src == '\n')
	{
	  if (YES == startOfLine)
	    {
	      return src;	// Pointer to line after headers
	    }
	  if (*src == '\r')
	    {
	      if (src + 1 >= end)
		{
		  return 0;		// Need more data (linefeed expected)
		}
	      if (src[1] == '\n')
		{
	          src++;		// Step past carriage return
		}
	    }
	  /* Step after end of line and look for fold (leading whitespace)
	   * or blank line (end of headers), or new data.
	   */
	  src++;
	  startOfLine = YES;
	  continue;
	}
      src++;
      startOfLine = NO;
    }
  if (src >= end)
    {
      return 0;	// Need more data
    }
  if (NO == startOfLine)
    {
      *folded = YES;
    }
  return src;	// Pointer to first non-space data
}

/*
 * This method takes the raw data of an unfolded header line, and handles
 * RFC2047 word encoding in the header by creating a
 * string containing the decoded words.
 * Strictly speaking, the header should be plain ASCII data with escapes
 * for non-ascii characters, but for the sake of fault tolerance, we also
 * attempt to use the default encoding currently set for the document,
 * and if that fails we try UTF8.  Only if none of these works do we
 * assume that the header is corrupt/unparsable.
 */
- (NSString*) _decodeHeader
{
  NSStringEncoding	enc;
  WE			encoding;
  unsigned char		c;
  NSMutableString	*hdr = [NSMutableString string];
  NSString		*s;
  const unsigned char	*beg = &bytes[input];
  const unsigned char	*end = &bytes[dataEnd];
  const unsigned char	*src = beg;

  while (src < end)
    {
      if (src[0] == '\n'
        || (src[0] == '\r' && src+1 < end && src[1] == '\n')
        || (src[0] == '=' && src+1 < end && src[1] == '?'))
	{
	  /* Append any accumulated text to the header.
	   */
	  if (src > beg)
	    {
	      s = [NSStringClass allocWithZone: NSDefaultMallocZone()];
	      if (flags.isHttp == 1)
		{
		  s = [s initWithBytes: beg
				length: src - beg
			      encoding: NSISOLatin1StringEncoding];
		}
	      else
		{
		  s = [s initWithBytes: beg
				length: src - beg
			      encoding: NSASCIIStringEncoding];
		}
	      if (s == nil && _defaultEncoding != NSASCIIStringEncoding)
		{
		  s = [NSStringClass allocWithZone: NSDefaultMallocZone()];
		  s = [s initWithBytes: beg
				length: src - beg
			      encoding: _defaultEncoding];
		  if (s == nil && _defaultEncoding != NSUTF8StringEncoding)
		    {
		      s = [NSStringClass allocWithZone: NSDefaultMallocZone()];
		      s = [s initWithBytes: beg
				    length: src - beg
				  encoding: NSUTF8StringEncoding];
		    }
		}
	      [hdr appendString: s];
	      RELEASE(s);
	    }

	  if ('=' == src[0])
	    {
	      const unsigned char	*tmp;

	      src += 2;
	      tmp = src;
	      while (tmp < end && *tmp != '?' && !isspace(*tmp))
		{
		  tmp++;
		}
	      if (tmp >= end) return nil;
	      if (*tmp != '?')
		{
		  NSLog(@"Bad encoded word - character set terminator missing");
		  break;
		}

	      s = [NSStringClass allocWithZone: NSDefaultMallocZone()];
	      s = [s initWithBytes: src
			    length: tmp - src
			  encoding: NSUTF8StringEncoding];
	      enc = [documentClass encodingFromCharset: s];
	      RELEASE(s);

	      src = tmp + 1;
	      if (src >= end) return nil;
	      c = tolower(*src);
	      if (c == 'b')
		{
		  encoding = WE_BASE64;
		}
	      else if (c == 'q')
		{
		  encoding = WE_QUOTED;
		}
	      else
		{
		  NSLog(@"Bad encoded word - content type unknown");
		  break;
		}
	      src++;
	      if (src >= end) return nil;
	      if (*src != '?')
		{
		  NSLog(@"Bad encoded word - content type terminator missing");
		  break;
		}
	      src++;
	      if (src >= end) return nil;
	      tmp = src;
	      while (tmp < end && *tmp != '?' && !isspace(*tmp))
		{
		  tmp++;
		}
	      if (tmp+1 >= end) return nil;
	      if (tmp[0] != '?' || tmp[1] != '=')
		{
		  NSLog(@"Bad encoded word - data terminator missing");
		  break;
		}
	      /* If the data part is not empty, decode it and append to header.
	       */
	      if (tmp > src)
		{
		  unsigned char	buf[tmp - src];
		  unsigned char	*ptr;

		  ptr = decodeWord(buf, src, tmp, encoding);
		  s = [NSStringClass allocWithZone: NSDefaultMallocZone()];
		  s = [s initWithBytes: buf
				length: ptr - buf
			      encoding: enc];
		  [hdr appendString: s];
		  RELEASE(s);
		}
	      /* Point past end to continue parsing.
	       */
	      src = tmp + 2;
	      beg = src;
	      continue;
	    }
	  else
	    {
	      BOOL	folded;

	      if (src[0] == '\r')
		src++;
	      src++;
	      if ([hdr length] == 0)
		{
		  /* Nothing in this header ... it's the empty line
		   * between headers and body.
		   */
		  flags.inBody = 1;
		  input = src - bytes;
		  return nil;
		}
	      src = unfold(src, end, &folded);
	      if (src == 0)
		{
		  return nil;	// need more data
		}
	      if (NO == folded)
		{
		  /* End of line ... return this header.
		   */
		  input = src - bytes;
		  return hdr;
		}
	      /* Folded line ... add space at fold and continue parsing.
	       */
	      [hdr appendString: @" "];
	      beg = src;
	      continue;
	    }
	}
      src++;
    }

  /* Need more data.
   */
  return nil;
}

/* Scan the provided data for an empty line (a CRLF immediately followed
 * by another CRLF).  Return the range of the empty line or a zero length
 * range at index NSNotFound.<br />
 * Permits a bare LF as a line terminator for maximum compatibility.<br />
 * Also checks for an empty line overlapping the existing data and the
 * new data.<br />
 * Also, handles the special case of an empty line and no further headers.
 */
- (NSRange) _endOfHeaders: (NSData*)newData
{
  unsigned int		ol = [data length];
  unsigned int		nl = [newData length];
  unsigned int		len = ol + nl;
  unsigned int		pos = ol;
  const unsigned char	*op = (const unsigned char*)[data bytes];
  const unsigned char	*np = (const unsigned char*)[newData bytes];
  char			c;

#define	C(X)	((X) < ol ? op[(X)] : np[(X)-ol])

  if (ol > 0)
    {
      /* Find the start of any trailing CRLF or LF sequence we have already
       * checked.
       */
      while (pos > 0)
	{
	  c = C(pos - 1);
	  if (c != '\r' && c != '\n')
	    {
	      break;
	    }
	  pos--;
	}
    }

  /* Check for a document with no headers
   */
  if (0 == pos)
    {
      if (len < 1)
	{
	  return NSMakeRange(NSNotFound, 0);
	}
      c = C(0);
      if ('\n' == c)
	{
	  return NSMakeRange(0, 1);	// no headers ... just an LF.
	}
      if (len < 2)
	{
	  return NSMakeRange(NSNotFound, 0);
	}
      if ('\r' == c && '\n' == C(1))
	{
	  return NSMakeRange(0, 2);	// no headers ... just a CRLF.
	}
    }

  /* Now check for pairs of line ends overlapping the old and new data
   */
  if (pos < ol)
    {
      if (pos + 2 >= len)
	{
	  return NSMakeRange(NSNotFound, 0);
	}
      c = C(pos);
      if ('\n' == c)
	{
	  char	c1 = C(pos + 1);

	  if ('\n' ==  c1)
	    {
	      return NSMakeRange(pos, 2);	// LFLF
	    }
	  if ('\r' == c1 && pos + 3 <= len && '\n' == C(pos + 2))
	    {
	      return NSMakeRange(pos, 3);	// LFCRLF
	    }
	}
      else if ('\r' == c)
	{
	  char	c1 = C(pos + 1);

	  if ('\n' == c1 && pos + 3 <= len)
	    {
	      char	c2 = C(pos + 2);

	      if ('\n' == c2)
		{
		  return NSMakeRange(pos, 3);	// CRLFLF
		}
	      if ('\r' == c2 && pos + 4 <= len && '\n' == C(pos + 3))
		{
		  return NSMakeRange(pos, 4);	// CRLFCRLF
		}
	    }
	}
    }

  /* Now check for end of headers in new data.
   */
  pos = 0;
  while (pos + 2 <= nl)
    {
      c = np[pos];
      if ('\n' == c)
	{
	  char	c1 = np[pos + 1];

	  if ('\n' ==  c1)
	    {
	      return NSMakeRange(pos + ol, 2);	// LFLF
	    }
	  if ('\r' == c1 && pos + 3 <= nl && '\n' == np[pos + 2])
	    {
	      return NSMakeRange(pos + ol, 3);	// LFCRLF
	    }
	}
      else if ('\r' == c)
	{
	  char	c1 = np[pos + 1];

	  if ('\n' == c1 && pos + 3 <= nl)
	    {
	      char	c2 = np[pos + 2];

	      if ('\n' == c2)
		{
		  return NSMakeRange(pos + ol, 3);	// CRLFLF
		}
	      if ('\r' == c2 && pos + 4 <= nl && '\n' == np[pos + 3])
		{
		  return NSMakeRange(pos + ol, 4);	// CRLFCRLF
		}
	      pos++;
	    }
	}
      pos++;
    }

  return NSMakeRange(NSNotFound, 0);
}

- (BOOL) _scanHeaderParameters: (NSScanner*)scanner into: (GSMimeHeader*)info
{
  [self scanPastSpace: scanner];
  while ([scanner scanString: @";" intoString: 0] == YES)
    {
      NSString	*paramName;

      paramName = [self scanName: scanner];
      if ([paramName length] == 0)
	{
	  NSLog(@"Invalid Mime %@ field (parameter name) at %@",
	    [info name], [scanner string]);
	  return NO;
	}

      [self scanPastSpace: scanner];
      if ([scanner scanString: @"=" intoString: 0] == YES)
	{
	  NSString	*paramValue;

	  paramValue = [self scanToken: scanner];
	  [self scanPastSpace: scanner];
	  if (paramValue == nil)
	    {
	      paramValue = @"";
	    }
	  [info setParameter: paramValue forKey: paramName];
	}
      else
	{
	  NSLog(@"Ignoring Mime %@ field parameter (%@)",
	    [info name], paramName);
	}
    }
  return YES;
}

@end



@interface	_GSMutableInsensitiveDictionary : NSMutableDictionary
@end

@implementation	GSMimeHeader

static NSCharacterSet	*nonToken = nil;
static NSCharacterSet	*tokenSet = nil;

+ (void) initialize
{
  if (nonToken == nil)
    {
      NSMutableCharacterSet	*ms;

      ms = [NSMutableCharacterSet new];
      [ms addCharactersInRange: NSMakeRange(33, 126-32)];
      [ms removeCharactersInString: @"()<>@,;:\\\"/[]?="];
      tokenSet = [ms copy];
      RELEASE(ms);
      nonToken = RETAIN([tokenSet invertedSet]);
      if (NSArrayClass == 0)
	{
	  NSArrayClass = [NSArray class];
	}
      if (NSStringClass == 0)
	{
	  NSStringClass = [NSString class];
	}
      if (documentClass == 0)
	{
	  documentClass = [GSMimeDocument class];
	}
    }
}

/**
 * Makes the value into a quoted string if necessary (ie if it contains
 * any special / non-token characters).  If flag is YES then the value
 * is made into a quoted string even if it does not contain special characters.
 */
+ (NSString*) makeQuoted: (NSString*)v always: (BOOL)flag
{
  NSRange	r;
  NSUInteger	pos = 0;
  NSUInteger	l = [v length];

  r = [v rangeOfCharacterFromSet: nonToken
			 options: NSLiteralSearch
			   range: NSMakeRange(0, l)];
  if (flag == YES || r.length > 0)
    {
      NSMutableString	*m = [NSMutableString new];

      [m appendString: @"\""];
      while (r.length > 0)
	{
	  unichar	c;

	  if (r.location > pos)
	    {
	      [m appendString:
		[v substringWithRange: NSMakeRange(pos, r.location - pos)]];
	    }
	  pos = r.location + 1;
	  c = [v characterAtIndex: r.location];
	  if (c < 128)
	    {
	      if (c == '\\' || c == '"')
		{
		  [m appendFormat: @"\\%c", c];
		}
	      else
		{
		  [m appendFormat: @"%c", c];
		}
	    }
	  else
	    {
	      NSLog(@"NON ASCII characters not yet implemented");
	    }
	  r = [v rangeOfCharacterFromSet: nonToken
				 options: NSLiteralSearch
				   range: NSMakeRange(pos, l - pos)];
	}
      if (l > pos)
	{
	  [m appendString:
	    [v substringWithRange: NSMakeRange(pos, l - pos)]];
	}
      [m appendString: @"\""];
      v = AUTORELEASE(m);
    }
  return v;
}

/**
 * Convert the supplied string to a standardized token by removing
 * all illegal characters.  If preserve is NO then the result is
 * converted to lowercase.<br />
 * Returns an autoreleased (and possibly modified) copy of the original.
 */
+ (NSString*) makeToken: (NSString*)t preservingCase: (BOOL)preserve
{
  NSMutableString	*m = nil;
  NSRange		r;

  r = [t rangeOfCharacterFromSet: nonToken];
  if (r.length > 0)
    {
      m = [t mutableCopy];
      while (r.length > 0)
	{
	  [m deleteCharactersInRange: r];
	  r = [m rangeOfCharacterFromSet: nonToken];
	}
      t = m;
    }
  if (preserve == NO)
    {
      t = [t lowercaseString];
    }
  else
    {
      t = AUTORELEASE([t copy]);
    }
  TEST_RELEASE(m);
  return t;
}

/**
 * Convert the supplied string to a standardized token by making it
 * lowercase and removing all illegal characters.
 */
+ (NSString*) makeToken: (NSString*)t
{
  return [self makeToken: t preservingCase: NO];
}

- (id) copyWithZone: (NSZone*)z
{
  GSMimeHeader	*c = [GSMimeHeader allocWithZone: z];
  NSEnumerator	*e;
  NSString	*k;

  c = [c initWithName: [self namePreservingCase: YES]
		value: [self value]
	   parameters: [self parametersPreservingCase: YES]];
  e = [objects keyEnumerator];
  while ((k = [e nextObject]) != nil)
    {
      [c setObject: [self objectForKey: k] forKey: k];
    }
  return c;
}

- (void) dealloc
{
  RELEASE(name);
  RELEASE(value);
  TEST_RELEASE(objects);
  TEST_RELEASE(params);
  [super dealloc];
}

- (NSString*) description
{
  NSMutableString	*desc;

  desc = [NSMutableString stringWithFormat: @"GSMimeHeader <%0x> -\n", self];
  [desc appendFormat: @"  name: %@\n", [self name]];
  [desc appendFormat: @"  value: %@\n", [self value]];
  [desc appendFormat: @"  params: %@\n", [self parameters]];
  return desc;
}

/** Returns the full value of the header including any parameters and
 * preserving case.  This is an unfolded (long) line with no escape
 * sequences (ie contains a unicode string not necessarily plain ASCII).<br />
 * If you just want the plain value excluding any parameters, use the
 * -value method instead.
 */
- (NSString*) fullValue
{
  if ([params count] > 0)
    {
      NSMutableString	*m;
      NSEnumerator	*e;
      NSString		*k;

      m = [[value mutableCopy] autorelease];
      e = [params keyEnumerator];
      while ((k = [e nextObject]) != nil)
	{
	  NSString	*v;

	  v = [GSMimeHeader makeQuoted: [params objectForKey: k] always: NO];
	  [m appendString: @"; "];
	  [m appendString: k];
	  [m appendString: @"="];
	  [m appendString: v];
	}
      return [m makeImmutableCopyOnFail: YES];
    }
  else
    {
      return value;
    }
}

- (NSUInteger) hash
{
  return [[self name] hash];
}

- (id) init
{
  return [self initWithName: @"unknown" value: @"none" parameters: nil];
}

/**
 * Convenience method calling -initWithName:value:parameters: with the
 * supplied argument and nil parameters.
 */
- (id) initWithName: (NSString*)n
	      value: (NSString*)v
{
  return [self initWithName: n value: v parameters: nil];
}

/**
 * <init />
 * Initialise a GSMimeHeader supplying a name, a value and a dictionary
 * of any parameters occurring after the value.
 */
- (id) initWithName: (NSString*)n
	      value: (NSString*)v
	 parameters: (NSDictionary*)p
{
  [self setName: n];
  [self setValue: v];
  [self setParameters: p];
  return self;
}

- (BOOL) isEqual: (id)other
{
  if (other == self)
    {
      return YES;
    }
  if (NO == [other isKindOfClass: [GSMimeHeader class]])
    {
      return NO;
    }
  if (NO == [[self name] isEqual: [other name]])
    {
      return NO;
    }
  if (NO == [[self value] isEqual: [other value]])
    {
      return NO;
    }
  if (NO == [[self parameters] isEqual: [other parameters]])
    {
      return NO;
    }
  return YES;
}

/**
 * Returns the name of this header ... a lowercase string.
 */
- (NSString*) name
{
  return [self namePreservingCase: NO];
}

/**
 * Returns the name of this header as originally set (without conversion
 * to lowercase) if preserve is YES, but as a lowercase string if preserve
 * is NO.
 */
- (NSString*) namePreservingCase: (BOOL)preserve
{
  if (preserve == YES)
    {
      return name;
    }
  else
    {
      return [name lowercaseString];
    }
}

/**
 * Return extra information specific to a particular header type.
 */
- (id) objectForKey: (NSString*)k
{
  return [objects objectForKey: k];
}

/**
 * Returns a dictionary of all the additional objects for the header.
 */
- (NSDictionary*) objects
{
  return AUTORELEASE([objects copy]);
}

/**
 * Return the named parameter value.
 */
- (NSString*) parameterForKey: (NSString*)k
{
  NSString	*p = [params objectForKey: k];

  if (p == nil)
    {
      k = [GSMimeHeader makeToken: k];
      p = [params objectForKey: k];
    }
  return p;
}

/**
 * Returns the parameters of this header ... a dictionary whose keys
 * are all lowercase strings, and whose values are strings which may
 * contain mixed case.
 */
- (NSDictionary*) parameters
{
  return [self parametersPreservingCase: NO];
}

/**
 * Returns the parameters of this header ... a dictionary whose keys
 * are strings preserving the case originally used to set the values
 * or all lowercase depending on the preserve argument.
 */
- (NSDictionary*) parametersPreservingCase: (BOOL)preserve
{
  NSMutableDictionary	*m;
  NSEnumerator		*e;
  NSString		*k;

  m = [NSMutableDictionary dictionaryWithCapacity: [params count]];
  e = [params keyEnumerator];
  if (preserve == YES)
    {
      while ((k = [e nextObject]) != nil)
	{
	  [m setObject: [params objectForKey: k] forKey: k];
	}
    }
  else
    {
      while ((k = [e nextObject]) != nil)
	{
	  [m setObject: [params objectForKey: k] forKey: [k lowercaseString]];
	}
    }
  return [m makeImmutableCopyOnFail: YES];
}

/**
 * Returns the full text of the header, built from its component parts,
 * and including a terminating CR-LF
 */
- (NSMutableData*) rawMimeData
{
  return [self rawMimeDataPreservingCase: NO];
}

static NSUInteger
appendBytes(NSMutableData *m, NSUInteger offset, NSUInteger fold,
  const char *bytes, NSUInteger size)
{
  if (offset + size > fold && size + 8 <= fold)
    {
      NSUInteger  len = [m length];

      /* This would take the line beyond the folding limit,
       * so we fold at this point.
       * If we already have space at the end of the line,
       * we remove it because the wrapping counts as a space.
       */
      if (len > 0 && isspace(((unsigned char*)[m bytes])[len - 1]))
        {
          [m setLength: --len];
        }
      [m appendBytes: "\r\n\t" length: 3];
      offset = 8;
      if (size > 0 && isspace(bytes[0]))
        {
          /* The folding counts as a space character,
           * so we refrain from writing the next character
           * if it is also a space.
           */
          size--;
          bytes++;
        }
    }
  if (size > 0)
    {
      /* Append the supplied byte data and update the offset
       * on the current line.
       */
      [m appendBytes: bytes length: size];
      offset += size;
    }
  return offset;
}

static NSUInteger
appendString(NSMutableData *m, NSUInteger offset, NSUInteger fold,
  NSString *str, BOOL *ok)
{
  NSUInteger      pos = 0;
  NSUInteger      size = [str length];

  *ok = YES;
  while (pos < size)
    {
      NSRange   r = NSMakeRange(pos, size - pos);

      r = [str rangeOfCharacterFromSet: whitespace
                               options: NSLiteralSearch
                                 range: r];
      if (r.length > 0 && r.location == pos)
        {
          /* Found space at the start of the string, so we reduce
           * it to a single space in the output, or omit it entirely
           * if the string is nothing but space.
           */
          pos++;
          while (pos < size
            && [whitespace characterIsMember: [str characterAtIndex: pos]])
            {
              pos++;
            }
          if (pos < size)
            {
              offset = appendBytes(m, offset, fold, " ", 1);
            }
        }
      else if (r.length == 0)
        {
          NSString      *sub;
          NSData        *d;

          /* No space found ... we must output the entire string without
           * folding it.
           */
          sub = [str substringWithRange: NSMakeRange(pos, size - pos)];
          pos = size;
          d = wordData(sub);
          offset = appendBytes(m, offset, fold, [d bytes], [d length]);
        }
      else
        {
          NSString      *sub;
          NSData        *d;

          /* Output the substring up to the first space.
           */
          sub = [str substringWithRange: NSMakeRange(pos, r.location - pos)];
          pos = r.location;
          d = wordData(sub);
          offset = appendBytes(m, offset, fold, [d bytes], [d length]);
        }
      if (offset > fold)
        {
          *ok = NO;
        }
    }
  return offset;
}

/**
 * Returns the full text of the header, built from its component parts,
 * and including a terminating CR-LF.<br />
 * If preserve is YES then we attempt to build the text using the same
 * case as it was originally parsed/set from, otherwise we use common
 * conventions of capitalising the header names and using lowercase
 * parameter names.
 */
- (NSMutableData*) rawMimeDataPreservingCase: (BOOL)preserve
{
  NSMutableData	*md = [NSMutableData dataWithCapacity: 128];
  NSEnumerator	*e = [params keyEnumerator];
  NSString	*k;
  NSString	*n;
  NSData	*d;
  NSUInteger	fold = 78;      // Maybe pass as a parameter in a later release?
  NSUInteger	offset = 0;
  BOOL		conv = YES;
  BOOL          ok = YES;

  if (fold == 0)
    {
      fold = 78;        // This is what the RFCs say we should limit length to.
    }
  n = [self namePreservingCase: preserve];
  d = [n dataUsingEncoding: NSASCIIStringEncoding];
  if (preserve == YES)
    {
      /* Protect the user ... MIME-Version *must* have the correct case.
       */
      if ([n caseInsensitiveCompare: @"MIME-Version"] == NSOrderedSame)
        {
          offset = appendBytes(md, offset, fold, "MIME-Version", 12);
	}
      else
        {
          offset = appendBytes(md, offset, fold, [d bytes], [d length]);
	}
    }
  else
    {
      NSUInteger  l = [d length];
      char	buf[l];
      NSUInteger	i = 0;

      /*
       * Capitalise the header name.  However, the version header is a special
       * case - it is defined as being literally 'MIME-Version'
       */
      memcpy(buf, [d bytes], l);
      if (l == 12 && strncasecmp(buf, "mime-version", 12) == 0)
	{
	  memcpy(buf, "MIME-Version", 12);
	}
      else
	{
	  while (i < l)
	    {
	      if (conv == YES)
		{
		  if (islower(buf[i]))
		    {
		      buf[i] = toupper(buf[i]);
		    }
		}
	      if (buf[i++] == '-')
		{
		  conv = YES;
		}
	      else
		{
		  conv = NO;
		}
	    }
	}
      offset = appendBytes(md, offset, fold, buf, l);
    }
  if (offset > fold)
    {
      NSLog(@"Name '%@' too long for folding at %"PRIuPTR" in header",
	n, fold);
    }

  offset = appendBytes(md, offset, fold, ":", 1);
  offset = appendBytes(md, offset, fold, " ", 1);
  offset = appendString(md, offset, fold, value, &ok);
  if (ok == NO)
    {
      NSDebugMLLog(@"GSMime",
	@"Value for '%@' too long for folding at %u in header", n, fold);
    }

  while ((k = [e nextObject]) != nil)
    {
      NSString	*v;

      v = [GSMimeHeader makeQuoted: [params objectForKey: k] always: NO];
      if (preserve == NO)
        {
	  k = [k lowercaseString];
	}
      offset = appendBytes(md, offset, fold, ";", 1);
      offset = appendBytes(md, offset, fold, " ", 1);
      offset = appendString(md, offset, fold, k, &ok);
      if (ok == NO)
        {
	  NSDebugMLLog(@"GSMime",
	    @"Parameter name '%@' in '%@' too long for folding at %u",
            k, n, fold);
        }
      offset = appendBytes(md, offset, fold, "=", 1);
      offset = appendString(md, offset, fold, v, &ok);
      if (ok == NO)
        {
	  NSDebugMLLog(@"GSMime",
	    @"Parameter value for '%@' in '%@' too long for folding at %u",
            k, n, fold);
        }
    }
  [md appendBytes: "\r\n" length: 2];

  return md;
}

/**
 * Sets the name of this header ... and removes illegal characters.<br />
 * If given a nil or empty string argument, sets the name to 'unknown'.<br />
 * NB. The value returned by the -name method will be a lowercase version
 * of thae name.
 */
- (void) setName: (NSString*)s
{
  s = [GSMimeHeader makeToken: s preservingCase: YES];
  if ([s length] == 0)
    {
      s = @"unknown";
    }
  ASSIGN(name, s);
}

/**
 * Method to store specific information for particular types of
 * header.  This is used for non-standard parts of headers.<br />
 * Setting a nil value for o will remove any existing value set
 * using the k as its key.
 */
- (void) setObject: (id)o forKey: (NSString*)k
{
  if (o == nil)
    {
      [objects removeObjectForKey: k];
    }
  else
    {
      if (objects == nil)
        {
	  objects = [NSMutableDictionary new];
	}
      [objects setObject: o forKey: k];
    }
}

/**
 * Sets a parameter of this header ... converts name to lowercase and
 * removes illegal characters.<br />
 * If a nil parameter name is supplied, removes any parameter with the
 * specified key.
 */
- (void) setParameter: (NSString*)v forKey: (NSString*)k
{
  k = [GSMimeHeader makeToken: k preservingCase: YES];
  if (v == nil)
    {
      [params removeObjectForKey: k];
    }
  else
    {
      if (params == nil)
	{
	  params = [_GSMutableInsensitiveDictionary new];
	}
      [params setObject: v forKey: k];
    }
}

/**
 * Sets all parameters of this header ... converts names to lowercase
 * and removes illegal characters from them.
 */
- (void) setParameters: (NSDictionary*)d
{
  NSMutableDictionary	*m = nil;
  NSUInteger		c = [d count];

  if (c > 0)
    {
      NSEnumerator	*e = [d keyEnumerator];
      NSString		*k;

      m = [[_GSMutableInsensitiveDictionary alloc] initWithCapacity: c];
      while ((k = [e nextObject]) != nil)
	{
	  [m setObject: [d objectForKey: k]
		forKey: [GSMimeHeader makeToken: k preservingCase: YES]];
	}
    }
  DESTROY(params);
  params = m;
}

/**
 * Sets the value of this header (without changing parameters)<br />
 * If given a nil argument, set an empty string value.
 */
- (void) setValue: (NSString*)s
{
  if (s == nil)
    {
      s = @"";
    }
  ASSIGN(value, s);
}

/**
 * Returns the full text of the header, built from its component parts,
 * and including a terminating CR-LF
 */
- (NSString*) text
{
  NSString	*s = [NSStringClass allocWithZone: NSDefaultMallocZone()];

  s = [s initWithData: [self rawMimeData] encoding: NSASCIIStringEncoding];
  return AUTORELEASE(s);
}

/**
 * Returns the value of this header (excluding any parameters).<br />
 * Use the -fullValue m,ethod if you want parameter included.
 */
- (NSString*) value
{
  return value;
}
@end



/**
 * <p>
 *   This class is intended to provide a wrapper for MIME messages
 *   permitting easy access to the contents of a message and
 *   providing a basis for parsing an unparsing messages that
 *   have arrived via email or as a web document.
 * </p>
 * <p>
 *   The class keeps track of all the document headers, and provides
 *   methods for modifying and examining the headers that apply to a
 *   document.
 * </p>
 */
@implementation	GSMimeDocument

/*
 * Examine xml data to find out the characterset needed to convert from
 * binary data to an NSString object.
 */
+ (NSString*) charsetForXml: (NSData*)xml
{
  NSUInteger		length = [xml length];
  const unsigned char	*ptr = (const unsigned char*)[xml bytes];
  const unsigned char	*end = ptr + length;
  NSUInteger		offset = 0;
  NSUInteger		size = 1;
  unsigned char		quote = 0;
  unsigned char		buffer[30];
  NSUInteger		buflen = 0;
  BOOL			found = NO;

  if (length < 4)
    {
      // Not long enough to determine an encoding
      return nil;
    }

  /*
   * Determine encoding using byte-order-mark if present
   */
  if ((ptr[0] == 0xFE && ptr[1] == 0xFF)
    || (ptr[0] == 0xFF && ptr[1] == 0xFE))
    {
      return @"utf-16";
    }
  if (ptr[0] == 0xEF && ptr[1] == 0xBB && ptr[2] == 0xBF)
    {
      return @"utf-8";
    }
  if ((ptr[0] == 0x00 && ptr[1] == 0x00)
    && ((ptr[2] == 0xFE && ptr[3] == 0xFF)
      || (ptr[2] == 0xFF && ptr[3] == 0xFE)))
    {
      return @"ucs-4";
    }

  /*
   * Look for nul bytes to determine whether this is a four byte
   * encoding or a two byte encoding (or the default).
   */
  if (ptr[0] == 0 && ptr[1] == 0 && ptr[2] == 0)
    {
      offset = 3;
      size = 4;
    }
  else if (ptr[0] == 0 && ptr[1] == 0 && ptr[3] == 0)
    {
      offset = 2;
      size = 4;
    }
  else if (ptr[0] == 0 && ptr[2] == 0 && ptr[3] == 0)
    {
      offset = 1;
      size = 4;
    }
  else if (ptr[1] == 0 && ptr[2] == 0 && ptr[3] == 0)
    {
      offset = 0;
      size = 4;
    }
  else if (ptr[0] == 0)
    {
      offset = 1;
      size = 2;
    }
  else if (ptr[1] == 0)
    {
      offset = 0;
      size = 2;
    }

  /*
   * Now look for the xml encoding declaration ...
   */

  // Tolerate leading whitespace
  while (ptr + size <= end && isspace(ptr[offset])) ptr += size;

  if (ptr + (size * 20) >= end || ptr[offset] != '<' || ptr[offset+size] != '?')
    {
      if (size == 1)
	{
	  return @"utf-8";
	}
      else if (size == 2)
	{
	  return @"utf-16";
	}
      else
	{
	  return @"ucs-4";
	}
    }
  ptr += size * 5;	// Step past '<?xml' prefix

  while (ptr + size <= end)
    {
      unsigned char	c = ptr[offset];

      ptr += size;
      if (quote == 0)
	{
	  if (c == '\'' || c == '"')
	    {
	      buflen = 0;
	      quote = c;
	    }
	  else
	    {
	      if (isspace(c) || c == '=')
		{
		  if (buflen == 8)
		    {
		      buffer[8] = '\0';
		      if (strcasecmp((char*)buffer, "encoding") == 0)
			{
			  found = YES;
			}
		    }
		  buflen = 0;
		}
	      else
		{
		  if (buflen == sizeof(buffer)) buflen = 0;
		  buffer[buflen++] = c;
		}
	    }
	}
      else if (c == quote)
	{
	  if (found == YES)
	    {
	      NSString		*tmp;

	      tmp = [[NSString alloc] initWithBytes: buffer
		length: buflen
		encoding: NSASCIIStringEncoding];
	      IF_NO_GC([tmp autorelease];)
	      return [tmp lowercaseString];
	    }
	  buflen = 0;
	  quote = 0;	// End of quoted section
	}
      else
	{
	  if (buflen == sizeof(buffer)) buflen = 0;
	  buffer[buflen++] = c;
	}
    }

  return @"utf-8";
}

/**
 * Return the MIME characterset name corresponding to the
 * specified string encoding.<br />
 * As a special case, returns "us-ascii" if enc is zero.<br />
 * Returns nil if enc cannot be mapped to a charset.<br />
 * NB. The correspondence between charsets and encodings is not
 * a direct one to one mapping, so successive calls to +encodingFromCharset:
 * and +charsetFromEncoding: may not produce the original input.
 */
+ (NSString*) charsetFromEncoding: (NSStringEncoding)enc
{
  NSString	*charset = @"us-ascii";

  if (enc != 0)
    {
      charset = (NSString*)NSMapGet(encodings, (void*)enc);
    }
  return charset;
}

+ (NSData*) decodeBase64: (NSData*)source
{
  int		length;
  int		declen;
  const unsigned char	*src;
  const unsigned char	*end;
  unsigned char *result;
  unsigned char	*dst;
  unsigned char	buf[4];
  NSUInteger	pos = 0;
  int		pad = 0;

  if (source == nil)
    {
      return nil;
    }
  length = [source length];
  if (length == 0)
    {
      return [NSData data];
    }
  declen = ((length + 3) * 3)/4;
  src = (const unsigned char*)[source bytes];
  end = &src[length];

#if	GS_WITH_GC
  result = (unsigned char*)NSAllocateCollectable(declen, 0);
#else
  result = (unsigned char*)NSZoneMalloc(NSDefaultMallocZone(), declen);
#endif
  dst = result;

  while ((src != end) && *src != '\0')
    {
      int	c = *src++;

      if (isupper(c))
	{
	  c -= 'A';
	}
      else if (islower(c))
	{
	  c = c - 'a' + 26;
	}
      else if (isdigit(c))
	{
	  c = c - '0' + 52;
	}
      else if (c == '/')
	{
	  c = 63;
	}
      else if (c == '_')
	{
	  c = 63;	/* RFC 4648 permits '_' in URLs and filenames */
	}
      else if (c == '+')
	{
	  c = 62;
	}
      else if (c == '-')
	{
	  c = 62;	/* RFC 4648 permits '-' in URLs and filenames */
	}
      else if  (c == '=')
	{
	  c = -1;
	  pad++;
	}
      else
	{
	  c = -1;	/* Ignore ... non-standard but more tolerant. */
	  length--;	/* Don't count this as part of the length. */
	}

      if (c >= 0)
	{
	  buf[pos++] = c;
	  if (pos == 4)
	    {
	      pos = 0;
	      decodebase64(dst, buf);
	      dst += 3;
	    }
	}
    }

  /* If number of bytes is not a multiple of four, treat it as if the missing
   * bytes were the '=' characters normally used for padding.
   * This is not allowed by the basic standards, but permitted in some
   * variants of 6ase64 encoding, so we should tolerate it.
   */
  if (length % 4 > 0)
    {
      pad += (4 - length % 4);
    }
  if (pos > 0)
    {
      NSUInteger	i;
      unsigned char	tail[3];

      for (i = pos; i < 4; i++)
	{
	  buf[i] = '\0';
	}
      decodebase64(tail, buf);
      if (pad > 3) pad = 3;
      memcpy(dst, tail, 3 - pad);
      dst += 3 - pad;
    }
  return AUTORELEASE([[NSData allocWithZone: NSDefaultMallocZone()]
    initWithBytesNoCopy: result length: dst - result]);
}

/**
 * Converts the base64 encoded data in source to a decoded ASCII string
 * using the +decodeBase64: method.  If the encoded data does not represent
 * an ASCII string, you should use the +decodeBase64: method directly.
 */
+ (NSString*) decodeBase64String: (NSString*)source
{
  NSData	*d = [source dataUsingEncoding: NSASCIIStringEncoding];
  NSString	*r = nil;

  d = [self decodeBase64: d];
  if (d != nil)
    {
      r = [NSStringClass allocWithZone: NSDefaultMallocZone()];
      r = [r initWithData: d encoding: NSASCIIStringEncoding];
      IF_NO_GC([r autorelease];)
    }
  return r;
}

/**
 * Convenience method to return an autoreleased document using the
 * specified content, type, and name value.  This calls the
 * -setContent:type:name: method to set up the document.
 */
+ (GSMimeDocument*) documentWithContent: (id)newContent
                                   type: (NSString*)type
                                   name: (NSString*)name
{
  GSMimeDocument	*doc = AUTORELEASE([self new]);

  [doc setContent: newContent type: type name: name];
  return doc;
}

+ (NSData*) encodeBase64: (NSData*)source
{
  int		length;
  int		destlen;
  unsigned char *sBuf;
  unsigned char *dBuf;

  if (source == nil)
    {
      return nil;
    }
  length = [source length];
  if (length == 0)
    {
      return [NSData data];
    }
  destlen = 4 * ((length + 2) / 3);
  sBuf = (unsigned char*)[source bytes];
#if	GS_WITH_GC
  dBuf = NSAllocateCollectable(destlen, 0);
#else
  dBuf = NSZoneMalloc(NSDefaultMallocZone(), destlen);
#endif

  destlen = encodebase64(dBuf, sBuf, length);

  return AUTORELEASE([[NSData allocWithZone: NSDefaultMallocZone()]
    initWithBytesNoCopy: dBuf length: destlen]);
}

/**
 * Converts the ASCII string source into base64 encoded data using the
 * +encodeBase64: method.  If the original data is not an ASCII string,
 * you should use the +encodeBase64: method directly.
 */
+ (NSString*) encodeBase64String: (NSString*)source
{
  NSData	*d = [source dataUsingEncoding: NSASCIIStringEncoding];
  NSString	*r = nil;

  d = [self encodeBase64: d];
  if (d != nil)
    {
      r = [NSStringClass allocWithZone: NSDefaultMallocZone()];
      r = [r initWithData: d encoding: NSASCIIStringEncoding];
      IF_NO_GC([r autorelease];)
    }
  return r;
}

/**
 * Return the string encoding corresponding to the specified MIME
 * characterset name.<br />
 * As a special case, returns NSASCIIStringEncoding if charset is nil.<br />
 * Returns 0 if charset cannot be found.<br />
 * NB. We treat iso-10646-ucs-2 as utf-16, which should
 * work for most text, but is not strictly correct.<br />
 * The correspondence between charsets and encodings is not
 * a direct one to one mapping, so successive calls to +encodingFromCharset:
 * and +charsetFromEncoding: may not produce the original input.
 */
+ (NSStringEncoding) encodingFromCharset: (NSString*)charset
{
  NSStringEncoding	enc = NSASCIIStringEncoding;

  if (charset != nil)
    {
      enc = (NSStringEncoding)NSMapGet(charsets, charset);
      if (enc == 0)
	{
	  charset = [charset lowercaseString];
	  enc = (NSStringEncoding)NSMapGet(charsets, charset);
	}
    }
  return enc;
}

+ (void) initialize
{
  if (self == [GSMimeDocument class])
    {
      NSMutableCharacterSet	*m = [[NSMutableCharacterSet alloc] init];

      if (documentClass == 0)
	{
	  documentClass = [GSMimeDocument class];
	}
      [m formUnionWithCharacterSet:
	[NSCharacterSet characterSetWithCharactersInString:
	@".()<>@,;:[]\"\\"]];
      [m formUnionWithCharacterSet:
	[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      [m formUnionWithCharacterSet:
	[NSCharacterSet controlCharacterSet]];
      [m formUnionWithCharacterSet:
	[NSCharacterSet illegalCharacterSet]];
      rfc822Specials = [m copy];
      [m formUnionWithCharacterSet:
	[NSCharacterSet characterSetWithCharactersInString:
	@"/?="]];
      [m removeCharactersInString: @"."];
      rfc2045Specials = [m copy];
      [m release];
      whitespace = RETAIN([NSCharacterSet whitespaceAndNewlineCharacterSet]);
      if (NSArrayClass == 0)
	{
	  NSArrayClass = [NSArray class];
	}
      if (NSStringClass == 0)
	{
	  NSStringClass = [NSString class];
	}
      if (charsets == 0)
	{
	  charsets = NSCreateMapTable (NSObjectMapKeyCallBacks,
	    NSIntegerMapValueCallBacks, 0);

	  /*
	   * These mappings were obtained primarily from
	   * http://www.iana.org/assignments/character-sets
	   * with additions determined empirically.
	   *
	   * We should ideally have all the aliases for each
	   * encoding we support, but I just did the aliases
	   * for ascii and latin1 as these (and utf-8 which
	   * has no aliases) account for most mime documents.
	   * Feel free to add more.
	   */

	  // All the ascii mappings from IANA
	  NSMapInsert(charsets, (void*)@"ansi_x3.4-1968",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-ir-6",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"ansi_x3.4-1986",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso_646.irv:1991",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso_646.991-irv",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"ascii",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso646-us",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"us-ascii",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"us",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"ibm367",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"cp367",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"csascii",
	    (void*)NSASCIIStringEncoding);

	  // All the latin1 mappings from IANA
	  NSMapInsert(charsets, (void*)@"iso-8859-1:1987",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-1:1987",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-ir-100",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso_8859-1",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-1",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-1",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"latin1",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"l1",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"ibm819",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"cp819",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"csisolatin1",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"ia5",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-2",
	    (void*)NSISOLatin2StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-2",
	    (void*)NSISOLatin2StringEncoding);
	  NSMapInsert(charsets, (void*)@"microsoft-symbol",
	    (void*)NSSymbolStringEncoding);
	  NSMapInsert(charsets, (void*)@"windows-symbol",
	    (void*)NSSymbolStringEncoding);
	  NSMapInsert(charsets, (void*)@"microsoft-cp1250",
	    (void*)NSWindowsCP1250StringEncoding);
	  NSMapInsert(charsets, (void*)@"windows-1250",
	    (void*)NSWindowsCP1250StringEncoding);
	  NSMapInsert(charsets, (void*)@"microsoft-cp1251",
	    (void*)NSWindowsCP1251StringEncoding);
	  NSMapInsert(charsets, (void*)@"windows-1251",
	    (void*)NSWindowsCP1251StringEncoding);
	  NSMapInsert(charsets, (void*)@"microsoft-cp1252",
	    (void*)NSWindowsCP1252StringEncoding);
	  NSMapInsert(charsets, (void*)@"windows-1252",
	    (void*)NSWindowsCP1252StringEncoding);
	  NSMapInsert(charsets, (void*)@"microsoft-cp1253",
	    (void*)NSWindowsCP1253StringEncoding);
	  NSMapInsert(charsets, (void*)@"windows-1253",
	    (void*)NSWindowsCP1253StringEncoding);
	  NSMapInsert(charsets, (void*)@"microsoft-cp1254",
	    (void*)NSWindowsCP1254StringEncoding);
	  NSMapInsert(charsets, (void*)@"windows-1254",
	    (void*)NSWindowsCP1254StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-10646-ucs-2",
	    (void*)NSUnicodeStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso10646-ucs-2",
	    (void*)NSUnicodeStringEncoding);
	  NSMapInsert(charsets, (void*)@"utf-16",
	    (void*)NSUnicodeStringEncoding);
	  NSMapInsert(charsets, (void*)@"utf16",
	    (void*)NSUnicodeStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-10646-1",
	    (void*)NSUnicodeStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso10646-1",
	    (void*)NSUnicodeStringEncoding);
	  NSMapInsert(charsets, (void*)@"jisx0201.1976",
	    (void*)NSShiftJISStringEncoding);
	  NSMapInsert(charsets, (void*)@"jisx0201",
	    (void*)NSShiftJISStringEncoding);
	  NSMapInsert(charsets, (void*)@"shift_JIS",
	    (void*)NSShiftJISStringEncoding);
	  NSMapInsert(charsets, (void*)@"utf-8",
	    (void*)NSUTF8StringEncoding);
	  NSMapInsert(charsets, (void*)@"utf8",
	    (void*)NSUTF8StringEncoding);
	  NSMapInsert(charsets, (void*)@"apple-roman",
	    (void*)NSMacOSRomanStringEncoding);

	  /* Also map from Apple encoding names.
	   */
	  NSMapInsert(charsets, (void*)@"NSASCIIStringEncoding",
	    (void*)NSASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSNEXTSTEPStringEncoding",
	    (void*)NSNEXTSTEPStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSJapaneseEUCStringEncoding",
	    (void*)NSJapaneseEUCStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSUTF8StringEncoding",
	    (void*)NSUTF8StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOLatin1StringEncoding",
	    (void*)NSISOLatin1StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSSymbolStringEncoding",
	    (void*)NSSymbolStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSNonLossyASCIIStringEncoding",
	    (void*)NSNonLossyASCIIStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSShiftJISStringEncoding",
	    (void*)NSShiftJISStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOLatin2StringEncoding",
	    (void*)NSISOLatin2StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSUnicodeStringEncoding",
	    (void*)NSUnicodeStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSWindowsCP1251StringEncoding",
	    (void*)NSWindowsCP1251StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSWindowsCP1252StringEncoding",
	    (void*)NSWindowsCP1252StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSWindowsCP1253StringEncoding",
	    (void*)NSWindowsCP1253StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSWindowsCP1254StringEncoding",
	    (void*)NSWindowsCP1254StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSWindowsCP1250StringEncoding",
	    (void*)NSWindowsCP1250StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISO2022JPStringEncoding",
	    (void*)NSISO2022JPStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSMacOSRomanStringEncoding",
	    (void*)NSMacOSRomanStringEncoding);

	  NSMapInsert(charsets, (void*)@"NSUTF16BigEndianStringEncoding",
	    (void*)NSUTF16BigEndianStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSUTF16LittleEndianStringEncoding",
	    (void*)NSUTF16LittleEndianStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSUTF32StringEncoding",
	    (void*)NSUTF32StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSUTF32BigEndianStringEncoding",
	    (void*)NSUTF32BigEndianStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSUTF32LittleEndianStringEncoding",
	    (void*)NSUTF32LittleEndianStringEncoding);

#if     !defined(NeXT_Foundation_LIBRARY)
	  NSMapInsert(charsets, (void*)@"gsm0338",
	    (void*)NSGSM0338StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-3",
	    (void*)NSISOLatin3StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-3",
	    (void*)NSISOLatin3StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-4",
	    (void*)NSISOLatin4StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-4",
	    (void*)NSISOLatin4StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-5",
	    (void*)NSISOCyrillicStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-5",
	    (void*)NSISOCyrillicStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-6",
	    (void*)NSISOArabicStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-6",
	    (void*)NSISOArabicStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-7",
	    (void*)NSISOGreekStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-7",
	    (void*)NSISOGreekStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-8",
	    (void*)NSISOHebrewStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-8",
	    (void*)NSISOHebrewStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-9",
	    (void*)NSISOLatin5StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-9",
	    (void*)NSISOLatin5StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-10",
	    (void*)NSISOLatin6StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-10",
	    (void*)NSISOLatin6StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-11",
	    (void*)NSISOThaiStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-11",
	    (void*)NSISOThaiStringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-13",
	    (void*)NSISOLatin7StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-13",
	    (void*)NSISOLatin7StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-14",
	    (void*)NSISOLatin8StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-14",
	    (void*)NSISOLatin8StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso-8859-15",
	    (void*)NSISOLatin9StringEncoding);
	  NSMapInsert(charsets, (void*)@"iso8859-15",
	    (void*)NSISOLatin9StringEncoding);
	  NSMapInsert(charsets, (void*)@"big5",
	    (void*)NSBIG5StringEncoding);
	  NSMapInsert(charsets, (void*)@"utf-7",
	    (void*)NSUTF7StringEncoding);
	  NSMapInsert(charsets, (void*)@"utf7",
	    (void*)NSUTF7StringEncoding);
	  NSMapInsert(charsets, (void*)@"koi8-r",
	    (void*)NSKOI8RStringEncoding);
	  NSMapInsert(charsets, (void*)@"ksc5601.1987",
	    (void*)NSKoreanEUCStringEncoding);
	  NSMapInsert(charsets, (void*)@"ksc5601",
	    (void*)NSKoreanEUCStringEncoding);
	  NSMapInsert(charsets, (void*)@"ksc5601.1997",
	    (void*)NSKoreanEUCStringEncoding);
	  NSMapInsert(charsets, (void*)@"ksc5601",
	    (void*)NSKoreanEUCStringEncoding);
	  NSMapInsert(charsets, (void*)@"gb2312.1980",
	    (void*)NSGB2312StringEncoding);
	  NSMapInsert(charsets, (void*)@"gb2312",
	    (void*)NSGB2312StringEncoding);

	  /* Also map from GNUstep encoding names.
	   */
	  NSMapInsert(charsets, (void*)@"NSISOCyrillicStringEncoding",
	    (void*)NSISOCyrillicStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSKOI8RStringEncoding",
	    (void*)NSKOI8RStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOLatin3StringEncoding",
	    (void*)NSISOLatin3StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOLatin4StringEncoding",
	    (void*)NSISOLatin4StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOArabicStringEncoding",
	    (void*)NSISOArabicStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOGreekStringEncoding",
	    (void*)NSISOGreekStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOHebrewStringEncoding",
	    (void*)NSISOHebrewStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOLatin5StringEncoding",
	    (void*)NSISOLatin5StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOLatin6StringEncoding",
	    (void*)NSISOLatin6StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOThaiStringEncoding",
	    (void*)NSISOThaiStringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOLatin7StringEncoding",
	    (void*)NSISOLatin7StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOLatin8StringEncoding",
	    (void*)NSISOLatin8StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSISOLatin9StringEncoding",
	    (void*)NSISOLatin9StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSUTF7StringEncoding",
	    (void*)NSUTF7StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSGB2312StringEncoding",
	    (void*)NSGB2312StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSGSM0338StringEncoding",
	    (void*)NSGSM0338StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSBIG5StringEncoding",
	    (void*)NSBIG5StringEncoding);
	  NSMapInsert(charsets, (void*)@"NSKoreanEUCStringEncoding",
	    (void*)NSKoreanEUCStringEncoding);
#endif
	}
      if (encodings == 0)
	{
	  encodings = NSCreateMapTable (NSIntegerMapKeyCallBacks,
	    NSObjectMapValueCallBacks, 0);

	  /* While the charset mappings above are many to one,
	   * mapping a variety of names to one encoding,
	   * the encodings map is a one to one mapping.
	   *
	   * The charset names used here should be the PREFERRED
	   * charset names from the IANA registration if one is
	   * specified.
	   * We adopt the convention that all names are in lowercase.
	   */
	  NSMapInsert(encodings, (void*)NSASCIIStringEncoding,
	    (void*)@"us-ascii");
	  NSMapInsert(encodings, (void*)NSISOLatin1StringEncoding,
	    (void*)@"iso-8859-1");
	  NSMapInsert(encodings, (void*)NSISOLatin2StringEncoding,
	    (void*)@"iso-8859-2");
	  NSMapInsert(encodings, (void*)NSWindowsCP1250StringEncoding,
	    (void*)@"windows-1250");
	  NSMapInsert(encodings, (void*)NSWindowsCP1251StringEncoding,
	    (void*)@"windows-1251");
	  NSMapInsert(encodings, (void*)NSWindowsCP1252StringEncoding,
	    (void*)@"windows-1252");
	  NSMapInsert(encodings, (void*)NSWindowsCP1253StringEncoding,
	    (void*)@"windows-1253");
	  NSMapInsert(encodings, (void*)NSWindowsCP1254StringEncoding,
	    (void*)@"windows-1254");
	  NSMapInsert(encodings, (void*)NSUnicodeStringEncoding,
	    (void*)@"utf-16");
	  NSMapInsert(encodings, (void*)NSShiftJISStringEncoding,
	    (void*)@"shift_JIS");
	  NSMapInsert(encodings, (void*)NSUTF8StringEncoding,
	    (void*)@"utf-8");
	  NSMapInsert(encodings, (void*)NSMacOSRomanStringEncoding,
	    (void*)@"apple-roman");
#if     !defined(NeXT_Foundation_LIBRARY)
	  NSMapInsert(encodings, (void*)NSISOLatin3StringEncoding,
	    (void*)@"iso-8859-3");
	  NSMapInsert(encodings, (void*)NSISOLatin4StringEncoding,
	    (void*)@"iso-8859-4");
	  NSMapInsert(encodings, (void*)NSISOCyrillicStringEncoding,
	    (void*)@"iso-8859-5");
	  NSMapInsert(encodings, (void*)NSISOArabicStringEncoding,
	    (void*)@"iso-8859-6");
	  NSMapInsert(encodings, (void*)NSISOGreekStringEncoding,
	    (void*)@"iso-8859-7");
	  NSMapInsert(encodings, (void*)NSISOHebrewStringEncoding,
	    (void*)@"iso-8859-8");
	  NSMapInsert(encodings, (void*)NSISOLatin5StringEncoding,
	    (void*)@"iso-8859-9");
	  NSMapInsert(encodings, (void*)NSISOLatin6StringEncoding,
	    (void*)@"iso-8859-10");
	  NSMapInsert(encodings, (void*)NSISOThaiStringEncoding,
	    (void*)@"iso-8859-11");
	  NSMapInsert(encodings, (void*)NSISOLatin7StringEncoding,
	    (void*)@"iso-8859-13");
	  NSMapInsert(encodings, (void*)NSISOLatin8StringEncoding,
	    (void*)@"iso-8859-14");
	  NSMapInsert(encodings, (void*)NSISOLatin9StringEncoding,
	    (void*)@"iso-8859-15");
	  NSMapInsert(encodings, (void*)NSBIG5StringEncoding,
	    (void*)@"big5");
	  NSMapInsert(encodings, (void*)NSUTF7StringEncoding,
	    (void*)@"utf-7");
	  NSMapInsert(encodings, (void*)NSGSM0338StringEncoding,
	    (void*)@"gsm0338");
	  NSMapInsert(encodings, (void*)NSKOI8RStringEncoding,
	    (void*)@"koi8-r");
	  NSMapInsert(encodings, (void*)NSGB2312StringEncoding,
	    (void*)@"gb2312.1980");
	  NSMapInsert(encodings, (void*)NSKoreanEUCStringEncoding,
	    (void*)@"ksc5601.1987");
#endif
	}
    }
}

/**
 * Adds a part to a multipart document
 */
- (void) addContent: (id)newContent
{
  if ([newContent isKindOfClass: documentClass] == NO)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"Content to add is not a GSMimeDocument"];
    }
  if (content == nil)
    {
      content = [NSMutableArray new];
    }
  if ([content isKindOfClass: [NSMutableArray class]] == YES)
    {
      [content addObject: newContent];
    }
  else
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"[%@ -%@] passed bad content",
	NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    }
}

/**
 * <p>
 *   This method may be called to add a header to the document.
 *   The header must be a mutable dictionary object that contains
 *   at least the fields that are standard for all headers.
 * </p>
 * <p>
 *   Certain well-known headers are restricted to one occurrence in
 *   an email, and when extra copies are added they replace originals.
 * </p>
 * <p>
 *  The mime-version header is special ... it is inserted before any
 *  other mime headers rather than being added at the end.
 * </p>
 */
- (void) addHeader: (GSMimeHeader*)info
{
  NSString	*name = [info name];

  if (name == nil || [name isEqualToString: @"unknown"] == YES)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"[%@ -%@] header with invalid name",
	NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    }
  if ([name isEqualToString: @"mime-version"] == YES
    || [name isEqualToString: @"content-disposition"] == YES
    || [name isEqualToString: @"content-transfer-encoding"] == YES
    || [name isEqualToString: @"content-type"] == YES
    || [name isEqualToString: @"subject"] == YES)
    {
      NSUInteger	index = [self _indexOfHeaderNamed: name];

      if (index != NSNotFound)
	{
	  [headers replaceObjectAtIndex: index withObject: info];
	}
      else if ([name isEqualToString: @"mime-version"] == YES)
	{
	  NSUInteger	tmp;

	  index = [headers count];
	  tmp = [self _indexOfHeaderNamed: @"content-disposition"];
	  if (tmp != NSNotFound && tmp < index)
	    {
	      index = tmp;
	    }
	  tmp = [self _indexOfHeaderNamed: @"content-transfer-encoding"];
	  if (tmp != NSNotFound && tmp < index)
	    {
	      index = tmp;
	    }
	  tmp = [self _indexOfHeaderNamed: @"content-type"];
	  if (tmp != NSNotFound && tmp < index)
	    {
	      index = tmp;
	    }
	  [headers insertObject: info atIndex: index];
	}
      else
	{
	  [headers addObject: info];
	}
    }
  else
    {
      [headers addObject: info];
    }
}

/**
 * Convenience method to create a new header and add it to the receiver.<br />
 * Returns the newly created header.<br />
 * See [GSMimeHeader-initWithName:value:parameters:] and -addHeader: methods.
 */
- (GSMimeHeader*) addHeader: (NSString*)name
		      value: (NSString*)value
		 parameters: (NSDictionary*)parameters
{
  GSMimeHeader	*hdr;

  hdr = [[GSMimeHeader alloc] initWithName: name
				     value: value
				parameters: parameters];
  [self addHeader: hdr];
  RELEASE(hdr);
  return hdr;
}

/**
 * <p>
 *   This method returns an array containing GSMimeHeader objects
 *   representing the headers associated with the document.
 * </p>
 * <p>
 *   The order of the headers in the array is the order of the
 *   headers in the document.
 * </p>
 */
- (NSArray*) allHeaders
{
  return [NSArray arrayWithArray: headers];
}

/**
 * This returns the content data of the document in the same format in
 * which the data was placed in the document.  This may be one of -
 * <deflist>
 *   <term>text</term>
 *   <desc>an NSString object</desc>
 *   <term>binary</term>
 *   <desc>an NSData object</desc>
 *   <term>multipart</term>
 *   <desc>an NSArray object containing GSMimeDocument objects</desc>
 * </deflist>
 * If you want to be sure that you get a particular type of data, use the
 * -convertToData or -convertToText method.
 */
- (id) content
{
  return content;
}

/**
 * Search the content of this document to locate a part whose content ID
 * matches the specified key.  Recursively descend into other documents.<br />
 * Wraps the supplied key in angle brackets if they are not present.<br />
 * Return nil if no match is found, the matching GSMimeDocument otherwise.
 */
- (id) contentByID: (NSString*)key
{
  if ([key hasPrefix: @"<"] == NO)
    {
      key = [NSStringClass stringWithFormat: @"<%@>", key];
    }
  if ([content isKindOfClass: NSArrayClass] == YES)
    {
      NSEnumerator	*e = [content objectEnumerator];
      GSMimeDocument	*d;

      while ((d = [e nextObject]) != nil)
	{
	  if ([[d contentID] isEqualToString: key] == YES)
	    {
	      return d;
	    }
	  d = [d contentByID: key];
	  if (d != nil)
	    {
	      return d;
	    }
	}
    }
  return nil;
}

/**
 * Search the content of this document to locate a part whose content ID
 * matches the specified key.  Recursively descend into other documents.<br />
 * Wraps the supplied key in angle brackets if they are not present.<br />
 * Return nil if no match is found, the matching GSMimeDocument otherwise.
 */
- (id) contentByLocation: (NSString*)key
{
  if ([content isKindOfClass: NSArrayClass] == YES)
    {
      NSEnumerator	*e = [content objectEnumerator];
      GSMimeDocument	*d;

      while ((d = [e nextObject]) != nil)
	{
	  if ([[d contentLocation] isEqualToString: key] == YES)
	    {
	      return d;
	    }
	  d = [d contentByLocation: key];
	  if (d != nil)
	    {
	      return d;
	    }
	}
    }
  return nil;
}

/**
 * Search the content of this document to locate a part whose content-type
 * name or content-disposition name matches the specified key.
 * Recursively descend into other documents.<br />
 * Return nil if no match is found, the matching GSMimeDocument otherwise.
 */
- (id) contentByName: (NSString*)key
{

  if ([content isKindOfClass: NSArrayClass] == YES)
    {
      NSEnumerator	*e = [content objectEnumerator];
      GSMimeDocument	*d;

      while ((d = [e nextObject]) != nil)
	{
	  GSMimeHeader	*hdr;

	  hdr = [d headerNamed: @"content-type"];
	  if ([[hdr parameterForKey: @"name"] isEqualToString: key] == YES)
	    {
	      return d;
	    }
	  hdr = [d headerNamed: @"content-disposition"];
	  if ([[hdr parameterForKey: @"name"] isEqualToString: key] == YES)
	    {
	      return d;
	    }
	  d = [d contentByName: key];
	  if (d != nil)
	    {
	      return d;
	    }
	}
    }
  return nil;
}

/**
 * Convenience method to fetch the content file name from the header.
 */
- (NSString*) contentFile
{
  GSMimeHeader	*hdr = [self headerNamed: @"content-disposition"];

  return [hdr parameterForKey: @"filename"];
}

/**
 * Convenience method to fetch the content ID from the header.
 */
- (NSString*) contentID
{
  GSMimeHeader	*hdr = [self headerNamed: @"content-id"];

  return [hdr value];
}

/**
 * Convenience method to fetch the content location from the header.
 */
- (NSString*) contentLocation
{
  GSMimeHeader	*hdr = [self headerNamed: @"content-location"];

  return [hdr value];
}

/**
 * Convenience method to fetch the content name from the header.
 */
- (NSString*) contentName
{
  GSMimeHeader	*hdr = [self headerNamed: @"content-type"];

  return [hdr parameterForKey: @"name"];
}

/**
 * Convenience method to fetch the content sub-type from the header.
 */
- (NSString*) contentSubtype
{
  GSMimeHeader	*hdr = [self headerNamed: @"content-type"];
  NSString	*val = nil;

  if (hdr != nil)
    {
      val = [hdr objectForKey: @"Subtype"];
      if (val == nil)
	{
	  val = [hdr value];
	  if (val != nil)
	    {
	      NSRange	r;

	      r = [val rangeOfString: @"/"];
	      if (r.length > 0)
		{
		  val = [val substringFromIndex: r.location + 1];
		  r = [val rangeOfString: @"/"];
		  if (r.length > 0)
		    {
		      val = [val substringToIndex: r.location];
		    }
		  val = [val stringByTrimmingSpaces];
		  [hdr setObject: val forKey: @"Subtype"];
		}
	      else
		{
		  val = nil;
		}
	    }
	}
    }

  return val;
}

/**
 * Convenience method to fetch the content type from the header.
 */
- (NSString*) contentType
{
  GSMimeHeader	*hdr = [self headerNamed: @"content-type"];
  NSString	*val = nil;

  if (hdr != nil)
    {
      val = [hdr objectForKey: @"Type"];
      if (val == nil)
	{
	  val = [hdr value];
	  if (val != nil)
	    {
	      NSRange	r;

	      r = [val rangeOfString: @"/"];
	      if (r.length > 0)
		{
		  val = [val substringToIndex: r.location];
		  val = [val stringByTrimmingSpaces];
		}
	      [hdr setObject: val forKey: @"Type"];
	    }
	}
    }

  return val;
}

/**
 * Search the content of this document to locate all parts whose content-type
 * name or content-disposition name matches the specified key.
 * Do <em>NOT</em> recurse into other documents.<br />
 * Return nil if no match is found, an array of matching GSMimeDocument
 * instances otherwise.
 */
- (NSArray*) contentsByName: (NSString*)key
{
  NSMutableArray	*a = nil;

  if ([content isKindOfClass: NSArrayClass] == YES)
    {
      NSEnumerator	*e = [content objectEnumerator];
      GSMimeDocument	*d;

      while ((d = [e nextObject]) != nil)
	{
	  GSMimeHeader	*hdr;
	  BOOL		match = YES;

	  hdr = [d headerNamed: @"content-type"];
	  if ([[hdr parameterForKey: @"name"] isEqualToString: key] == NO)
	    {
	      hdr = [d headerNamed: @"content-disposition"];
	      if ([[hdr parameterForKey: @"name"] isEqualToString: key] == NO)
		{
		  match = NO;
		}
	    }
	  if (match == YES)
	    {
	      if (a == nil)
		{
		  a = [NSMutableArray arrayWithCapacity: 4];
		}
	      [a addObject: d];
	    }
	}
    }
  return a;
}

/**
 * Converts any binary parts of the receiver's content to be base64
 * encoded rather than 8bit or binary encoded ... a convenience method to
 * make the results of the -rawMimeData method safe for sending via
 * routes which only support 7bit data.
 */
- (void) convertToBase64
{
  if ([content isKindOfClass: NSArrayClass] == YES)
    {
      NSEnumerator	*e = [content objectEnumerator];
      GSMimeDocument	*d;

      while ((d = [e nextObject]) != nil)
	{
	  [d convertToBase64];
	}
    }
  else
    {
      GSMimeHeader	*h = [self headerNamed: @"content-transfer-encoding"];
      NSString		*v = [h value];

      if ([v isEqual: @"binary"] == YES || [v isEqual: @"8bit"] == YES)
	{
	  [h setValue: @"base64"];
	}
    }
}

/**
 * Converts any base64 encoded parts of the receiver's content to be
 * binary encoded instead ... a convenience method to
 * shrink down the size of the message when converted to data using
 * the -rawMimeData method.
 */
- (void) convertToBinary
{
  if ([content isKindOfClass: NSArrayClass] == YES)
    {
      NSEnumerator	*e = [content objectEnumerator];
      GSMimeDocument	*d;

      while ((d = [e nextObject]) != nil)
	{
	  [d convertToBinary];
	}
    }
  else
    {
      GSMimeHeader	*h = [self headerNamed: @"content-transfer-encoding"];
      NSString		*v = [h value];

      if ([v isEqual: @"base64"] == YES)
	{
	  [h setValue: @"binary"];
	}
    }
}

/**
 * Return the content as an NSData object (unless it is multipart)<br />
 * Perform conversion from text to data using the charset specified in
 * the content-type header, or infer the charset, and update the header
 * accordingly.<br />
 * If the content can not be represented as a plain NSData object, this
 * method returns nil.
 */
- (NSData*) convertToData
{
  NSData	*d = nil;

  if ([content isKindOfClass: NSStringClass] == YES)
    {
      GSMimeHeader	*hdr = [self headerNamed: @"content-type"];
      NSString		*charset = [hdr parameterForKey: @"charset"];
      NSStringEncoding	enc;

      enc = [documentClass encodingFromCharset: charset];
      d = [content dataUsingEncoding: enc];
      if (d == nil)
	{
	  charset = selectCharacterSet(content, &d);
	  [hdr setParameter: charset forKey: @"charset"];
	}
    }
  else if ([content isKindOfClass: [NSData class]] == YES)
    {
      d = content;
    }
  return d;
}

/**
 * Return the content as an NSString object (unless it is multipart)
 * If the content cannot be represented as text, this returns nil.
 */
- (NSString*) convertToText
{
  NSString	*s = nil;

  if ([content isKindOfClass: NSStringClass] == YES)
    {
      s = content;
    }
  else if ([content isKindOfClass: [NSData class]] == YES)
    {
      GSMimeHeader	*hdr = [self headerNamed: @"content-type"];
      NSString		*charset = [hdr parameterForKey: @"charset"];
      NSStringEncoding	enc;

      /*
       * Treat text/xml as a special case ... if we have no charset
       * specified then we can get the charset from the xml header
       * or, if that is not present, xml is utf-8
       */
      if (charset == nil
	&& [[hdr objectForKey: @"Subtype"] isEqualToString: @"xml"] == YES)
	{
	  charset = [documentClass charsetForXml: content];
	  if (charset == nil)
	    {
	      charset = @"utf-8";
	    }
	}
      enc = [documentClass encodingFromCharset: charset];
      s = [NSStringClass allocWithZone: NSDefaultMallocZone()];
      s = [s initWithData: content encoding: enc];
      IF_NO_GC([s autorelease];)
    }
  return s;
}

/**
 * Returns a copy of the receiver.
 */
- (id) copyWithZone: (NSZone*)z
{
  GSMimeDocument	*c = [documentClass allocWithZone: z];

  c->headers = [[NSMutableArray allocWithZone: z] initWithArray: headers
						      copyItems: YES];

  if ([content isKindOfClass: NSArrayClass] == YES)
    {
      c->content = [[NSMutableArray allocWithZone: z] initWithArray: content
							  copyItems: YES];
    }
  else
    {
      c->content = [content copyWithZone: z];
    }
  return c;
}

- (void) dealloc
{
  RELEASE(headers);
  RELEASE(content);
  [super dealloc];
}

/**
 * Deletes all ocurrances of parts identical to aPart from the receiver.<br />
 * Recursively deletes from enclosed documents as necessary.
 */
- (void) deleteContent: (GSMimeDocument*)aPart
{
  if (aPart != nil)
    {
      if ([content isKindOfClass: [NSMutableArray class]] == YES)
	{
	  NSUInteger	count = [content count];

	  while (count-- > 0)
	    {
	      GSMimeDocument	*part = [content objectAtIndex: count];

	      if (part == aPart)
		{
		  [content removeObjectAtIndex: count];
		}
	      else
		{
		  [part deleteContent: part];	// Recursive.
		}
	    }
	}
    }
}

/**
 * This method removes all occurrences of header objects identical to
 * the one supplied as an argument.
 */
- (void) deleteHeader: (GSMimeHeader*)aHeader
{
  [headers removeObjectIdenticalTo: aHeader];
}

/**
 * This method removes all occurrences of headers whose name
 * matches the supplied string.
 */
- (void) deleteHeaderNamed: (NSString*)name
{
  NSUInteger	count = [headers count];

  if (count > 0)
    {
      IMP	imp1;
      boolIMP	imp2;

      name = [name lowercaseString];

      imp1 = [headers methodForSelector: @selector(objectAtIndex:)];
      imp2 = (boolIMP)[name methodForSelector: @selector(isEqualToString:)];
      while (count-- > 0)
	{
	  GSMimeHeader	*info;

	  info = (*imp1)(headers, @selector(objectAtIndex:), count);
	  if ((*imp2)(name, @selector(isEqualToString:), [info name]))
	    {
	      [headers removeObjectAtIndex: count];
	    }
	}
    }
}

- (NSString*) description
{
  NSMutableString	*desc;
  NSDictionary		*locale;

  desc = [NSMutableString stringWithFormat: @"GSMimeDocument <%0x> -\n", self];
  locale = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
  [desc appendString: [headers descriptionWithLocale: locale]];
  [desc appendFormat: @"\nDocument content -\n%@", content];
  return desc;
}

- (NSUInteger) hash
{
  return [[self content] hash];
}

/**
 * This method returns the first header whose name equals the supplied argument.
 */
- (GSMimeHeader*) headerNamed: (NSString*)name
{
  NSUInteger	count = [headers count];

  if (count > 0)
    {
      NSUInteger	index;
      IMP		imp1;
      boolIMP		imp2;

      name = [GSMimeHeader makeToken: name preservingCase: NO];
      imp1 = [headers methodForSelector: @selector(objectAtIndex:)];
      imp2 = (boolIMP)[name methodForSelector: @selector(isEqualToString:)];
      for (index = 0; index < count; index++)
	{
	  GSMimeHeader	*info;

	  info = (*imp1)(headers, @selector(objectAtIndex:), index);
	  if ((*imp2)(name, @selector(isEqualToString:), [info name]))
	    {
	      return info;
	    }
	}
    }
  return nil;
}

/**
 * This method returns an array of GSMimeHeader objects for all headers
 * whose names equal the supplied argument.
 */
- (NSArray*) headersNamed: (NSString*)name
{
  NSUInteger	count;

  name = [GSMimeHeader makeToken: name preservingCase: NO];
  count = [headers count];
  if (count > 0)
    {
      NSUInteger	index;
      NSMutableArray	*array;
      IMP		imp1;
      boolIMP		imp2;

      imp1 = [headers methodForSelector: @selector(objectAtIndex:)];
      imp2 = (boolIMP)[name methodForSelector: @selector(isEqualToString:)];
      array = [NSMutableArray array];

      for (index = 0; index < count; index++)
	{
	  GSMimeHeader	*info;

	  info = (*imp1)(headers, @selector(objectAtIndex:), index);
	  if ((*imp2)(name, @selector(isEqualToString:), [info name]))
	    {
	      [array addObject: info];
	    }
	}
      return array;
    }
  return [NSArray array];
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      headers = [NSMutableArray new];
    }
  return self;
}

- (BOOL) isEqual: (id)other
{
  if (other == self)
    {
      return YES;
    }
  if (NO == [other isKindOfClass: [GSMimeDocument class]])
    {
      return NO;
    }
  if (NO == [[self allHeaders] isEqual: [other allHeaders]])
    {
      return NO;
    }
  if (NO == [[self content] isEqual: [(GSMimeDocument*)other content]])
    {
      return NO;
    }
  return YES;
}

/**
 * <p>Make a probably unique string suitable for use as the
 * boundary parameter in the content of a multipart document.
 * </p>
 * <p>This implementation provides base64 encoded data
 * consisting of an MD5 digest of some pseudo random stuff,
 * plus an incrementing counter.  The inclusion of the counter
 * guarantees that we won't produce two identical strings in
 * the same run of the program.
 * </p>
 * <p>The boundary has a suffix of '=_' to ensure it's not mistaken
 * for quoted-printable data.
 * </p>
 */
- (NSString*) makeBoundary
{
  static int		count = 0;
  unsigned char		output[20];
  unsigned char		*ptr;
  NSMutableData		*md;
  NSString		*result;
  NSData		*source;
  NSData		*digest;
  int			sequence = ++count;
  int			length;

  source = [[[NSProcessInfo processInfo] globallyUniqueString]
    dataUsingEncoding: NSUTF8StringEncoding];

  digest = [source md5Digest];
  memcpy(output, [digest bytes], 16);
  output[16] = (sequence >> 24) & 0xff;
  output[17] = (sequence >> 16) & 0xff;
  output[18] = (sequence >> 8) & 0xff;
  output[19] = sequence & 0xff;

  md = [NSMutableData allocWithZone: NSDefaultMallocZone()];
  md = [md initWithLength: 40];
  length = encodebase64([md mutableBytes], output, 20);
  [md setLength: length + 2];
  ptr = (unsigned char*)[md mutableBytes];
  ptr[length] = '=';
  ptr[length+1] = '_';
  result = [NSStringClass allocWithZone: NSDefaultMallocZone()];
  result = [result initWithData: md encoding: NSASCIIStringEncoding];
  RELEASE(md);
  return AUTORELEASE(result);
}

/**
 * Create new content ID header, set it as the content ID of the document
 * and return it.<br />
 * This is a convenience method which simply places angle brackets around
 * an [NSProcessInfo-globallyUniqueString] to form the header value.
 */
- (GSMimeHeader*) makeContentID
{
  GSMimeHeader	*hdr;
  NSString	*str = [[NSProcessInfo processInfo] globallyUniqueString];

  str = [NSStringClass stringWithFormat: @"<%@>", str];
  hdr = [[GSMimeHeader alloc] initWithName: @"content-id"
				     value: str
				parameters: nil];
  [self setHeader: hdr];
  RELEASE(hdr);
  return hdr;
}

/**
 * Deprecated ... use -setHeader:value:parameters:
 */
- (GSMimeHeader*) makeHeader: (NSString*)name
		       value: (NSString*)value
		  parameters: (NSDictionary*)parameters
{
  GSMimeHeader	*hdr;

  hdr = [[GSMimeHeader alloc] initWithName: name
				     value: value
				parameters: parameters];
  [self setHeader: hdr];
  RELEASE(hdr);
  return hdr;
}

/**
 * Create new message ID header, set it as the message ID of the document
 * and return it.<br />
 * This is a convenience method which simply places angle brackets around
 * an [NSProcessInfo-globallyUniqueString] to form the header value.
 */
- (GSMimeHeader*) makeMessageID
{
  GSMimeHeader	*hdr;
  NSString	*str = [[NSProcessInfo processInfo] globallyUniqueString];

  str = [NSStringClass stringWithFormat: @"<%@>", str];
  hdr = [[GSMimeHeader alloc] initWithName: @"message-id"
				     value: str
				parameters: nil];
  [self setHeader: hdr];
  RELEASE(hdr);
  return hdr;
}

/**
 * Return an NSData object representing the MIME document as raw data
 * ready to be sent via an email system.<br />
 * Calls -rawMimeData: with the isOuter flag set to YES.
 */
- (NSMutableData*) rawMimeData
{
  return [self rawMimeData: YES];
}

/**
 * <p>Return an NSData object representing the MIME document as raw data
 * ready to be sent via an email system.
 * </p>
 * <p>The isOuter flag denotes whether this document is the outermost
 * part of a MIME message, or is a part of a multipart message.
 * </p>
 * <p>During generation of the document this method will perform some
 * consistency checks and try to automatically generate missing header
 * information needed to build the mime data (eg. filling in the boundary
 * parameter in the content-type header for multipart documents).<br />
 * However, you should not depend on automatic behaviors but should
 * fill in as much detail as possible before generating data.
 * </p>
 */
- (NSMutableData*) rawMimeData: (BOOL)isOuter
{
  NSMutableArray	*partData = nil;
  NSMutableData		*md = [NSMutableData dataWithCapacity: 1024];
  NSData		*d = nil;
  NSEnumerator		*enumerator;
  GSMimeHeader		*type;
  GSMimeHeader		*enc;
  GSMimeHeader		*hdr;
  NSData		*boundary = 0;
  BOOL			contentIsBinary = NO;
  BOOL			contentIs7bit = YES;
  NSUInteger		count;
  NSUInteger		i;
  NSAutoreleasePool	*arp = [NSAutoreleasePool new];

  if (isOuter == YES)
    {
      /*
       * Ensure there is a mime version header.
       */
      hdr = [self headerNamed: @"mime-version"];
      if (hdr == nil)
	{
	  hdr = [GSMimeHeader alloc];
	  hdr = [hdr initWithName: @"mime-version"
			    value: @"1.0"
		       parameters: nil];
	  [self addHeader: hdr];
	  RELEASE(hdr);
	}
    }
  else
    {
      /*
       * Inner documents should not contain the mime version header.
       */
      hdr = [self headerNamed: @"mime-version"];
      if (hdr != nil)
	{
	  [self deleteHeader: hdr];
	}
    }

  if ([content isKindOfClass: NSArrayClass] == YES)
    {
      count = [content count];
      partData = [NSMutableArray arrayWithCapacity: count];
      for (i = 0; i < count; i++)
	{
	  GSMimeDocument	*part = [content objectAtIndex: i];

	  [partData addObject: [part rawMimeData: NO]];

	  /*
	   * If any part of a multipart document is not 7bit then
	   * the document as a whole must not be 7bit either.
	   * It is important to check this *after* the part has been
	   * processed by -rawMimeData:, so we know that the encoding
	   * set for the part is valid.
	   */
	  if (contentIs7bit == YES)
	    {
	      NSString		*v;

	      enc = [part headerNamed: @"content-transfer-encoding"];
	      v = [enc value];
	      if ([v isEqualToString: @"8bit"] == YES
		|| [v isEqualToString: @"binary"] == YES)
		{
		  contentIs7bit = NO;
		  if ([v isEqualToString: @"binary"] == YES)
		    {
		      contentIsBinary = YES;
		    }
		}
	    }
	}
    }

  type = [self headerNamed: @"content-type"];
  if (type == nil)
    {
      /*
       * Attempt to infer the content type from the content.
       */
      if (partData != nil)
	{
	  [self setContent: content type: @"multipart/mixed" name: nil];
	}
      else if ([content isKindOfClass: NSStringClass] == YES)
	{
	  [self setContent: content type: @"text/plain" name: nil];
	}
      else if ([content isKindOfClass: [NSData class]] == YES)
	{
	  [self setContent: content
		      type: @"application/octet-stream"
		      name: nil];
	}
      else if (content == nil)
	{
	  [self setContent: @"" type: @"text/plain" name: nil];
	}
      else
	{
	  [NSException raise: NSInternalInconsistencyException
		      format: @"[%@ -%@] with bad content",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
	}
      type = [self headerNamed: @"content-type"];
    }

  if (partData != nil)
    {
      NSString	*v;
      BOOL	shouldSet;

      enc = [self headerNamed: @"content-transfer-encoding"];
      v = [enc value];
      if ([v isEqualToString: @"binary"])
	{
	  /*
	   * For binary encoding, we can just accept the setting.
	   */
	  shouldSet = NO;
	}
      else if ([v isEqualToString: @"8bit"])
	{
	  if (contentIsBinary == YES)
	    {
	      shouldSet = YES;	// Need to promote from 8bit to binary
	    }
	  else
	    {
	      shouldSet = NO;
	    }
	}
      else if (v == nil || [v isEqualToString: @"7bit"] == YES)
	{
	  /*
	   * For 7bit encoding, we can accept the setting if the content
	   * is all 7bit data, otherwise we must change it to 8bit so
	   * that the content can be handled properly.
	   */
	  if (contentIs7bit == YES)
	    {
	      shouldSet = NO;
	    }
	  else
	    {
	      shouldSet = YES;
	    }
	}
      else
	{
	  /*
	   * A multipart document can't have any other encoding, so we need
	   * to fix it.
	   */
	  shouldSet = YES;
	}

      if (shouldSet == YES)
	{
	  NSString	*encoding;

	  /*
	   * Force a change to the current transfer encoding setting.
	   */
	  if (contentIs7bit == YES)
	    {
	      encoding = @"7bit";
	    }
	  else if (contentIsBinary == YES)
	    {
	      encoding = @"binary";
	    }
	  else
	    {
	      encoding = @"8bit";
	    }
	  if (enc == nil)
	    {
	      enc = [GSMimeHeader alloc];
	      enc = [enc initWithName: @"content-transfer-encoding"
				value: encoding
			   parameters: nil];
	      [self setHeader: enc];
	      RELEASE(enc);
	    }
	  else
	    {
	      [enc setValue: encoding];
	    }
	}

      v = [type parameterForKey: @"boundary"];
      if (v == nil)
	{
	  v = [self makeBoundary];
	  [type setParameter: v forKey: @"boundary"];
	}
      boundary = [v dataUsingEncoding: NSASCIIStringEncoding];

      v = [type objectForKey: @"Subtype"];
      if ([v isEqualToString: @"related"] == YES)
	{
	  GSMimeDocument	*start;

	  v = [type parameterForKey: @"start"];
	  if (v == nil)
	    {
	      start = [content objectAtIndex: 0];
#if 0
	      /*
	       * The 'start' parameter is not compulsory ... should we
	       * force it to be set anyway in case some dumb software
	       * doesn't default to the first part of the message?
	       */
	      v = [start contentID];
	      if (v == nil)
		{
		  hdr = [start makeContentID];
		  v = [hdr value];
		}
	      [type setParameter: v forKey: @"start"];
#endif
	    }
	  else
	    {
	      start = [self contentByID: v];
	    }
	  hdr = [start headerNamed: @"content-type"];
	  v = [hdr value];
	  /*
	   * If there is no 'type' parameter, we can fill it in automatically.
	   */
	  if ([type parameterForKey: @"type"] == nil)
	    {
	      [type setParameter: v forKey: @"type"];
	    }
	  if ([v isEqual: [type parameterForKey: @"type"]] == NO)
	    {
	      [NSException raise: NSInvalidArgumentException
		format: @"multipart/related 'type' (%@) does not match "
		@"that of the 'start' part (%@)",
		[type parameterForKey: @"type"], v];
	    }
	}
    }
  else
    {
      NSString	*encoding;

      d = [self convertToData];
      enc = [self headerNamed: @"content-transfer-encoding"];
      encoding = [enc value];
      if (encoding == nil)
	{
	  if ([[type objectForKey: @"Type"] isEqualToString: @"text"] == YES)
	    {
	      NSString		*charset;
	      NSStringEncoding	e;

	      charset = [type parameterForKey: @"charset"];
	      e = [documentClass encodingFromCharset: charset];
#if     defined(NeXT_Foundation_LIBRARY)
	      if (e != NSASCIIStringEncoding)
#else
	      if (e != NSASCIIStringEncoding && e != NSUTF7StringEncoding)
#endif
		{
		  encoding = @"8bit";
		  enc = [GSMimeHeader alloc];
		  enc = [enc initWithName: @"content-transfer-encoding"
				    value: encoding
			       parameters: nil];
		  [self addHeader: enc];
		  RELEASE(enc);
		}
	    }
	  else
	    {
	      enc = [GSMimeHeader alloc];
	      enc = [enc initWithName: @"content-transfer-encoding"
				value: @"base64"
			   parameters: nil];
	      [self addHeader: enc];
	      RELEASE(enc);
	    }
	}

      if (encoding == nil
	|| [encoding isEqualToString: @"7bit"] == YES
	|| [encoding isEqualToString: @"8bit"] == YES)
	{
	  unsigned char	*bytes = (unsigned char*)[d bytes];
	  NSUInteger	length = [d length];
	  BOOL		hadCarriageReturn = NO;
	  NSUInteger 	lineLength = 0;
	  NSUInteger	i;

	  for (i = 0; i < length; i++)
	    {
	      unsigned char	c = bytes[i];

	      if (hadCarriageReturn == YES)
		{
		  if (c != '\n')
		    {
		      encoding = @"binary";	// CR not part of CRLF
		      break;
		    }
		  hadCarriageReturn = NO;
		  lineLength = 0;
		}
	      else if (c == '\n')
		{
		  encoding = @"binary";		// LF not part of CRLF
		  break;
		}
	      else if (c == '\r')
		{
		  hadCarriageReturn = YES;
		}
	      else if (++lineLength > 998)
		{
		  encoding = @"binary";	// Line of more than 998
		  break;
		}

	      if (c == 0)
		{
		  encoding = @"binary";
		  break;
		}
	      else if (c > 127)
		{
		  encoding = @"8bit";	// Not 7bit data
		}
	    }

	  if (encoding != nil)
	    {
	      if (enc == nil)
		{
		  enc = [GSMimeHeader alloc];
		  enc = [enc initWithName: @"content-transfer-encoding"
				    value: encoding
			       parameters: nil];
		  [self addHeader: enc];
		  RELEASE(enc);
		}
	      else
		{
		  [enc setValue: encoding];
		}
	    }
	}
    }

  /*
   * Add all the headers.
   */
  enumerator = [headers objectEnumerator];
  while ((hdr = [enumerator nextObject]) != nil)
    {
      [md appendData: [hdr rawMimeData]];
    }

  if (partData != nil)
    {
      count = [content count];
      for (i = 0; i < count; i++)
	{
	  GSMimeDocument	*part = [content objectAtIndex: i];
	  NSMutableData		*rawPart = [partData objectAtIndex: i];

	  if (contentIs7bit == YES)
	    {
	      NSString	*v;

	      enc = [part headerNamed: @"content-transport-encoding"];
	      v = [enc value];
	      if (v != nil && ([v isEqualToString: @"8bit"]
		|| [v isEqualToString: @"binary"]))
	        {
		  [NSException raise: NSInternalInconsistencyException
		    format: @"[%@ -%@] bad part encoding for 7bit container",
		    NSStringFromClass([self class]),
		    NSStringFromSelector(_cmd)];
		}
	    }
	  /*
	   * For a multipart document, insert the boundary before each part.
	   */
	  [md appendBytes: "\r\n--" length: 4];
	  [md appendData: boundary];
	  [md appendBytes: "\r\n" length: 2];
	  [md appendData: rawPart];
	}
      [md appendBytes: "\r\n--" length: 4];
      [md appendData: boundary];
      [md appendBytes: "--\r\n" length: 4];
    }
  else
    {
      /*
       * Separate headers from body.
       */
      [md appendBytes: "\r\n" length: 2];

      if ([[enc value] isEqualToString: @"base64"] == YES)
        {
	  const char	*ptr;
	  NSUInteger	len;
	  NSUInteger	pos = 0;

	  d = [documentClass encodeBase64: d];
	  ptr = [d bytes];
	  len = [d length];

	  while (len - pos > 76)
	    {
	      [md appendBytes: &ptr[pos] length: 76];
	      [md appendBytes: "\r\n" length: 2];
	      pos += 76;
	    }
	  if (pos < len)
	    {
	      [md appendBytes: &ptr[pos] length: len-pos];
	      [md appendBytes: "\r\n" length: 2];
	    }
	}
      else if ([[enc value] isEqualToString: @"quoted-printable"] == YES)
        {
	  encodeQuotedPrintable(md, [d bytes], [d length]);
	}
      else if ([[enc value] isEqualToString: @"x-uuencode"] == YES)
        {
	  NSString	*name;

	  name = [[self headerNamed: @"content-type"] parameterForKey: @"name"];
	  if (name == nil)
	    {
	      name = @"untitled";
	    }
          [d uuencodeInto: md name: name mode: 0644];
	}
      else
	{
	  [md appendData: d];
	}
    }
  [arp drain];
  return md;
}

/**
 * Sets a new value for the content of the document.
 */
- (void) setContent: (id)newContent
{
  if ([newContent isKindOfClass: NSStringClass] == YES)
    {
      if (newContent != content)
	{
	  ASSIGNCOPY(content, newContent);
	}
    }
  else if ([newContent isKindOfClass: [NSData class]] == YES)
    {
      if (newContent != content)
	{
	  ASSIGNCOPY(content, newContent);
	}
    }
  else if ([newContent isKindOfClass: NSArrayClass] == YES)
    {
      if (newContent != content)
	{
	  NSUInteger	c = [newContent count];

	  while (c-- > 0)
	    {
	      id	o = [newContent objectAtIndex: c];

	      if ([o isKindOfClass: documentClass] == NO)
		{
		  [NSException raise: NSInvalidArgumentException
			      format: @"Content contains non-GSMimeDocument"];
		}
	    }
	  newContent = [newContent mutableCopy];
	  ASSIGN(content, newContent);
	  RELEASE(newContent);
	}
    }
  else
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"[%@ -%@] passed bad content: %@",
	NSStringFromClass([self class]), NSStringFromSelector(_cmd),
	newContent];
    }
}

/**
 * Convenience method calling -setContent:type:name: to set document
 * content and type with a nil value for name ... useful for top-level
 * documents rather than parts within a document (parts should really
 * be named).
 */
- (void) setContent: (id)newContent
	       type: (NSString*)type
{
  [self setContent: newContent type: type name: nil];
}

/**
 * <p>Convenience method to set the content of the document along with
 * creating a content-type header for it.
 * </p>
 * <p>The type parameter may be a simple common content type (text,
 * multipart, or application), in which case the default subtype for
 * that type is used.  Alternatively it may be full detail of a
 * content type header value, which will be parsed into 'type', 'subtype'
 * and 'parameters'.<br />
 * NB. In this case, if the parsed data contains a 'name' parameter
 * and the name argument is non-nil, the argument value will
 * override the parsed value.
 * </p>
 * <p>You can get the same effect by calling -setContent: to set the document
 * content, then creating a [GSMimeHeader] instance, initialising it with
 * the content type information you want using
 * [GSMimeHeader-initWithName:value:parameters:], and  calling the
 * -setHeader: method to attach it to the document.
 * </p>
 * <p>Using this method imposes a few extra checks and restrictions on the
 * combination of content and type/subtype you may use ... so you may want
 * to use the more primitive methods in order to bypass these checks if
 * you are using unusual type/subtype information or if you need to provide
 * additional parameters in the header.
 * </p>
 */
- (void) setContent: (id)newContent
	       type: (NSString*)type
	       name: (NSString*)name
{
  NSString		*subtype = nil;
  GSMimeHeader		*hdr = nil;
  NSAutoreleasePool	*arp = [NSAutoreleasePool new];

  if (type == nil)
    {
      type = @"text";
    }

  if ([type isEqualToString: @"text"] == YES)
    {
      subtype = @"plain";
    }
  else if ([type isEqualToString: @"multipart"] == YES)
    {
      subtype = @"mixed";
    }
  else if ([type isEqualToString: @"application"] == YES)
    {
      subtype = @"octet-stream";
    }
  else
    {
      GSMimeParser	*p = AUTORELEASE([GSMimeParser new]);
      NSScanner		*scanner = [NSScanner scannerWithString: type];

      hdr = AUTORELEASE([GSMimeHeader new]);
      [hdr setName: @"content-type"];
      if ([p scanHeaderBody: scanner into: hdr] == NO)
	{
	  [NSException raise: NSInvalidArgumentException
		      format: @"Unable to parse type information"];
	}
    }

  if (hdr == nil)
    {
      NSString	*val;

      val = [NSStringClass stringWithFormat: @"%@/%@", type, subtype];
      hdr = [GSMimeHeader alloc];
      hdr = [hdr initWithName: @"content-type" value: val parameters: nil];
      [hdr setObject: type forKey: @"Type"];
      [hdr setObject: subtype forKey: @"Subtype"];
      IF_NO_GC([hdr autorelease];)
    }
  else
    {
      type = [hdr objectForKey: @"Type"];
    }

  if (name != nil)
    {
      [hdr setParameter: name forKey: @"name"];
    }

  if ([type isEqualToString: @"multipart"] == NO
    && [type isEqualToString: @"application"] == NO
    && [content isKindOfClass: NSArrayClass] == YES)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"[%@ -%@] content doesn't match content-type",
	NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    }

  [self setContent: newContent];
  [self setHeader: hdr];
  [arp drain];
}

/**
 * <p>Convenience method to set the content type of the document without
 * altering any content.
 * The supplied newType may be full type information including subtype
 * and parameters as found after the colon in a mime Content-Type header.
 * </p>
 */
- (void) setContentType: (NSString *)newType
{
  GSMimeHeader		*hdr = nil;
  GSMimeParser		*p;
  NSScanner		*scanner;
  NSAutoreleasePool	*arp = [NSAutoreleasePool new];

  p = AUTORELEASE([GSMimeParser new]);
  scanner = [NSScanner scannerWithString: newType];
  hdr = AUTORELEASE([GSMimeHeader new]);
  [hdr setName: @"content-type"];
  if ([p scanHeaderBody: scanner into: hdr] == NO)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"Unable to parse type information"];
    }
  [self setHeader: hdr];
  [arp drain];
}

/**
 * This method may be called to set a header in the document.
 * Any other headers with the same name will be removed from
 * the document.
 */
- (void) setHeader: (GSMimeHeader*)info
{
  [self deleteHeaderNamed: [info name]];
  [self addHeader: info];
}

/**
 * Convenience method to create a new header and add it to the receiver
 * replacing any existing header of the same name.<br />
 * Returns the newly created header.<br />
 * See [GSMimeHeader-initWithName:value:parameters:] and -setHeader: methods.
 */
- (GSMimeHeader*) setHeader: (NSString*)name
		      value: (NSString*)value
		 parameters: (NSDictionary*)parameters
{
  GSMimeHeader	*hdr;

  hdr = [[GSMimeHeader alloc] initWithName: name
				     value: value
				parameters: parameters];
  [self setHeader: hdr];
  RELEASE(hdr);
  return hdr;
}

@end

@implementation GSMimeDocument (Private)
/**
 * Returns the index of the first header matching the specified name
 * or NSNotFound if no match is found.<br />
 * NB. The supplied name <em>must</em> be lowercase.<br />
 * This method is for internal use
 */
- (NSUInteger) _indexOfHeaderNamed: (NSString*)name
{
  NSUInteger	count = [headers count];

  if (count > 0)
    {
      NSUInteger	index;
      IMP	imp1 = [headers methodForSelector: @selector(objectAtIndex:)];
      boolIMP	imp2 = (boolIMP)[name methodForSelector: @selector(isEqualToString:)];

      for (index = 0; index < count; index++)
	{
	  GSMimeHeader	*info;

	  info = (*imp1)(headers, @selector(objectAtIndex:), index);
	  if ((*imp2)(name, @selector(isEqualToString:), [info name]))
	    {
	      return index;
	    }
	}
    }
  return NSNotFound;
}

- (GSMimeHeader*) _lastHeaderNamed: (NSString*)name
{
  NSUInteger	count = [headers count];

  if (count > 0)
    {
      IMP	imp1 = [headers methodForSelector: @selector(objectAtIndex:)];
      boolIMP	imp2 = (boolIMP)[name methodForSelector: @selector(isEqualToString:)];

      while (count-- > 0)
	{
	  GSMimeHeader	*info;

	  info = (*imp1)(headers, @selector(objectAtIndex:), count);
	  if ((*imp2)(name, @selector(isEqualToString:), [info name]))
	    {
	      return info;
	    }
	}
    }
  return nil;
}

@end


NSString* const GSMimeErrorDomain = @"GSMimeErrorDomain";

typedef	enum	{
  TP_IDLE,
  TP_OPEN,
  TP_INTRO,
  TP_EHLO,
  TP_HELO,
  TP_AUTH,
  TP_MESG,
  TP_FROM,
  TP_TO,
  TP_DATA,
  TP_BODY
} CState;

typedef	enum	{
  SMTPE_DSN,		// delivery status notification extension
} SMTPE;

NSString *
eventText(NSStreamEvent e)
{
  if (e == NSStreamEventNone)
    return @"NSStreamEventNone";
  if (e == NSStreamEventOpenCompleted)
    return @"NSStreamEventOpenCompleted";
  if (e == NSStreamEventHasBytesAvailable)
    return @"NSStreamEventHasBytesAvailable";
  if (e == NSStreamEventHasSpaceAvailable)
    return @"NSStreamEventHasSpaceAvailable";
  if (e == NSStreamEventErrorOccurred)
    return @"NSStreamEventErrorOccurred";
  if (e == NSStreamEventEndEncountered)
    return @"NSStreamEventEndEncountered";
  return @"unknown event";
}

NSString *
statusText(NSStreamStatus s)
{
  if (s == NSStreamStatusNotOpen) return @"NSStreamStatusNotOpen";
  if (s == NSStreamStatusOpening) return @"NSStreamStatusOpening";
  if (s == NSStreamStatusOpen) return @"NSStreamStatusOpen";
  if (s == NSStreamStatusReading) return @"NSStreamStatusReading";
  if (s == NSStreamStatusWriting) return @"NSStreamStatusWriting";
  if (s == NSStreamStatusAtEnd) return @"NSStreamStatusAtEnd";
  if (s == NSStreamStatusClosed) return @"NSStreamStatusClosed";
  if (s == NSStreamStatusError) return @"NSStreamStatusError";
  return @"unknown status";
}

/*
 * Convert 8bit/binary data parts to base64 encoding for old mail
 * software which can't handle 8bit data.
 */
static void makeBase64(GSMimeDocument *doc)
{
  id	o = [doc content];

  if ([o isKindOfClass: [NSArray class]] == YES)
    {
      NSEnumerator	*e = [o objectEnumerator];

      while ((doc = [e nextObject]) != nil)
	{
	  makeBase64(doc);
	}
    }
  else
    {
      GSMimeHeader	*h = [doc headerNamed: @"content-transfer-encoding"];
      NSString		*v = [h value];

      if ([v isEqual: @"binary"] == YES || [v isEqual: @"8bit"] == YES)
	{
	  [h setValue: @"base64"];
	}
    }
}

@interface	GSMimeSMTPClient (Private)
- (NSError*) _commsEnd;
- (NSError*) _commsError;
- (void) _doMessage;
- (NSString*) _identity;
- (void) _performIO;
- (void) _recvData: (NSData*)m;
- (NSError*) _response: (NSString*)r;
- (void) _sendData: (NSData*)m;
- (void) _shutdown: (NSError*)e;
- (void) _startup;
- (void) _timer: (NSTimeInterval)s;
@end

#define	GSInternal	GSMimeSMTPClientInternal
#include	"GSInternal.h"
GS_PRIVATE_INTERNAL(GSMimeSMTPClient)

@implementation	NSObject (GSMimeSMTPClient)
- (void) smtpClient: (GSMimeSMTPClient*)client
	 mimeFailed: (GSMimeDocument*)doc
{
  return;
}
- (void) smtpClient: (GSMimeSMTPClient*)client
	 mimeSent: (GSMimeDocument*)doc
{
  return;
}
- (void) smtpClient: (GSMimeSMTPClient*)client
	 mimeUnsent: (GSMimeDocument*)doc
{
  return;
}
@end


@implementation	GSMimeSMTPClient

/* Shuts the connection down, fails any message in progress, anbd discards all
 * queued messages as 'unsent'
 */
- (void) abort
{
  NSUInteger	c;
  NSError	*e;
  NSDictionary	*d;

  d = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSString stringWithFormat: @"Abort while %@", [self stateDesc]],
    NSLocalizedDescriptionKey,
    nil];
  e = [NSError errorWithDomain: GSMimeErrorDomain
			  code: GSMimeSMTPAbort
		      userInfo: d];

  [self _shutdown: e];
  [internal->timer invalidate];
  internal->timer = nil;

  /* For any message not yet sent, we inform the delegate of the failure
   */
  c = [internal->queue count];
  while (c-- > 0)
    {
      GSMimeDocument	*d = [internal->queue objectAtIndex: c];

      if (nil == internal->delegate)
	{
          NSDebugMLLog(@"GSMime", @"-smtpClient:mimeUnsent: %@ %@", self, d);
	}
      else
	{
          [internal->delegate smtpClient: self mimeUnsent: d];
	}
    }
  [internal->queue removeAllObjects];
}

- (void) dealloc
{
  [self abort];
  if (internal != nil)
    {
      DESTROY(internal->reply);
      DESTROY(internal->wdata);
      DESTROY(internal->rdata);
      DESTROY(internal->pending);
      DESTROY(internal->queue);
      DESTROY(internal->username);
      DESTROY(internal->port);
      DESTROY(internal->hostname);
      DESTROY(internal->identity);
      DESTROY(internal->originator);
      DESTROY(internal->lastError);
      GS_DESTROY_INTERNAL(GSMimeSMTPClient);
    }
  [super dealloc];
}

- (id) delegate
{
  return internal->delegate;
}

- (BOOL) flush: (NSDate*)limit
{
  if (limit == nil)
    {
      limit = [NSDate distantFuture];
    }
  while ([internal->queue count] > 0)
    {
      [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode
			       beforeDate: limit];
    }
  return [internal->queue count] == 0 ? YES : NO;
}

- (id) init
{
  if ((self = [super init]) != 0)
    {
      GS_CREATE_INTERNAL(GSMimeSMTPClient);
      internal->queue = [NSMutableArray new];
    }
  return self;
}

- (NSError*) lastError
{
  return internal->lastError;
}

- (void) send: (GSMimeDocument*)message
{
  [self send: message envelopeID: nil];
}

- (void) send: (GSMimeDocument*)message envelopeID: (NSString*)envid
{
  if (nil == [message headerNamed: @"mime-version"])
    {
      [message setHeader: @"MIME-Version" value: @"1.0" parameters: nil];
    }
  if (nil != envid)
    {
      [[message headerNamed: @"mime-version"] setObject: envid
						 forKey: @"ENVID"];
    }
  [internal->queue addObject: message];
  if (internal->cState == TP_IDLE)
    {
      if (internal->timer != nil)
	{
	  [internal->timer invalidate];
	  internal->timer = nil;
	}
      [self _startup];
    }
  else if (internal->cState == TP_MESG)
    {
      [self _doMessage];
    }
}

- (void) setDelegate: (id)d
{
  internal->delegate = d;
}

- (void) setHostname: (NSString*)s
{
  ASSIGNCOPY(internal->hostname, s);
}

- (void) setIdentity: (NSString*)s
{
  ASSIGNCOPY(internal->identity, s);
}

- (void) setOriginator: (NSString*)s
{
  ASSIGNCOPY(internal->originator, s);
}

- (void) setPort: (NSString*)s
{
  ASSIGNCOPY(internal->port, s);
}

- (void) setUsername: (NSString*)s
{
  ASSIGNCOPY(internal->username, s);
}

- (int) state
{
  return internal->cState;
}

- (NSString*) stateDesc
{
  switch (internal->cState)
    {
      case TP_OPEN:	return @"waiting for connection to SMTP server";
      case TP_INTRO:	return @"waiting for initial prompt from SMTP server";
      case TP_EHLO:	return @"waiting for SMTP server EHLO completion";
      case TP_HELO:	return @"waiting for SMTP server HELO completion";
      case TP_AUTH:	return @"waiting for SMTP server AUTH response";
      case TP_FROM:	return @"waiting for ack of FROM command";
      case TP_TO:	return @"waiting for ack of TO command";
      case TP_DATA:	return @"waiting for ack of DATA command";
      case TP_BODY:	return @"waiting for ack of message body";
      case TP_MESG:	return @"waiting for message to send";
      case TP_IDLE:	return @"idle ... not connected to SMTP server";
    }
  return @"idle ... not connected to SMTP server";
}

/** Handler for stream events ...
 */
- (void) stream: (NSStream*)aStream handleEvent: (NSStreamEvent)anEvent
{
  NSStreamStatus	sStatus = [aStream streamStatus];

  if (aStream == internal->istream)
    {
      NSDebugMLLog(@"GSMime", @"%@ istream event %@ in %@",
	self, eventText(anEvent), statusText(sStatus));
      if (anEvent == NSStreamEventHasBytesAvailable)
        {
	  internal->readable = YES;
	}
    }
  else
    {
      NSDebugMLLog(@"GSMime", @"%@ ostream event %@ in %@",
	self, eventText(anEvent), statusText(sStatus));
      if (anEvent == NSStreamEventHasSpaceAvailable)
        {
	  internal->writable = YES;
	}
    }

  if (anEvent == NSStreamEventEndEncountered)
    {
      [self _shutdown: [self _commsEnd]];
      return;
    }
  if (anEvent == NSStreamEventErrorOccurred)
    {
      [self _shutdown: [self _commsError]];
      return;
    }

  if (anEvent == NSStreamEventOpenCompleted)
    {
      internal->cState = TP_INTRO;
    }

  [self _performIO];
}

@end

@implementation	GSMimeSMTPClient (Private)

- (NSError*) _commsEnd
{
  NSError	*e;
  NSDictionary	*d;

  d = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSString stringWithFormat: @"End of input while %@", [self stateDesc]],
    NSLocalizedDescriptionKey,
    nil];
  e = [NSError errorWithDomain: GSMimeErrorDomain
			  code: GSMimeSMTPCommsEnd
		      userInfo: d];
  return e;
}

- (NSError*) _commsError
{
  NSError	*e;
  NSDictionary	*d;

  d = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSString stringWithFormat: @"Error on I/O while %@", [self stateDesc]],
    NSLocalizedDescriptionKey,
    nil];
  e = [NSError errorWithDomain: GSMimeErrorDomain
			  code: GSMimeSMTPCommsError
		      userInfo: d];
  return e;
}

/** Initiates sending of the next message (or the next stage of the
 * current message).
 */
- (void) _doMessage
{
  if ([internal->queue count] > 0)
    {
      NSString		*tmp;

      internal->current = [internal->queue objectAtIndex: 0];
      internal->version = [internal->current headerNamed: @"mime-version"];

      if (internal->cState == TP_IDLE)
	{
	  [self _startup];
	}
      else if (internal->cState == TP_MESG)
	{
	  NSString	*from = internal->originator;

	  DESTROY(internal->lastError);
	  if (from == nil)
	    {
	      from = [[NSUserDefaults standardUserDefaults]
		stringForKey: @"GSMimeSMTPClientOriginator"];
	    }
	  if ([from length] == 0)
	    {
	      from = [[internal->current headerNamed: @"from"] value];
	    }
	  if ([from length] == 0)
	    {
	      /* If we have no sender address ... use postmaster.
	       */
	      from = [NSString stringWithFormat: @"postmaster@%@",
		[self _identity]];
	    }

	  tmp = [internal->version objectForKey: @"ENVID"];
	  if (nil == tmp)
	    {
	      tmp = [NSString stringWithFormat: @"MAIL FROM: <%@>\r\n", from];
	    }
	  else
	    {
	      /* Tell the mail server we want headers, not the full body
	       * when an email is bounced or acknowledged.
	       * Set the envelope ID to be the ID of the current message.
	       */
	      tmp = [NSString stringWithFormat:
		@"MAIL FROM: <%@> RET=HDRS ENVID=%@\r\n", from, tmp];
	    }
	  NSDebugMLLog(@"GSMime", @"Initiating new mail message - %@", tmp);
	  internal->cState = TP_FROM;
	  [self _timer: 20.0];
	  [self _sendData: [tmp dataUsingEncoding: NSUTF8StringEncoding]];
	}
      else if (internal->cState == TP_FROM)
	{
	  tmp = [[internal->current headerNamed: @"to"] value];
	  if (nil == [internal->version objectForKey: @"ENVID"])
	    {
	      tmp = [NSString stringWithFormat: @"RCPT TO: <%@>\r\n", tmp];
	    }
	  else
	    {
	      /* We have an envelope ID, so we need success/failure reports.
	       */
	      tmp = [NSString stringWithFormat:
		@"RCPT TO: <%@> NOTIFY=SUCCESS,FAILURE\r\n", tmp];
	    }
	  NSDebugMLLog(@"GSMime", @"Destination - %@", tmp);
	  internal->cState = TP_TO;
	  [self _timer: 20.0];
	  [self _sendData: [tmp dataUsingEncoding: NSUTF8StringEncoding]];
        }
      else if (internal->cState == TP_TO)
	{
	  internal->cState = TP_DATA;
          tmp = @"DATA\r\n";
	  [self _timer: 20.0];
	  [self _sendData: [tmp dataUsingEncoding: NSUTF8StringEncoding]];
	}
      else if (internal->cState == TP_DATA)
	{
	  NSMutableData	*md;
	  NSData	*data;
	  const char	*ibuf;
	  char		*obuf;
	  BOOL		sol = YES;
	  unsigned	ilen;
	  unsigned	olen;
	  unsigned	osiz;
	  unsigned	ipos = 0;
	  unsigned	opos = 0;

	  internal->cState = TP_BODY;

          makeBase64(internal->current);
          data = [internal->current rawMimeData];

	  /*
	   * Any line in the message which begins with a dot must have
	   * that dot escaped by another dot.
	   */
	  ilen = [data length];
	  olen = ilen + 5;	// Allow for CR-LF-.-CR-LF termination
	  osiz = olen + 10;	// Allow some expansion to escape dots

	  md = [[NSMutableData alloc] initWithLength: osiz];
	  ibuf = [data bytes];
	  obuf = [md mutableBytes];

	  while (ipos < ilen)
	    {
	      char	c = ibuf[ipos++];

	      if (c == '\n')
	      	{
		  sol = YES;
		}
	      else
	        {
		  if (c == '.' && sol == YES)
		    {
		      obuf[opos++] = '.';	// Extra dot acts as an escape
		      if (olen++ == osiz)	// Lengthen to allow for dot
			{
			  osiz += 16;
			  [md setLength: osiz];
			  obuf = [md mutableBytes];
			}
		    }
		  sol = NO;
		}
	      obuf[opos++] = c;
	    }
	  obuf[opos++] = '\r';
	  obuf[opos++] = '\n';
	  /*
	   * Now terminate the message with a line consisting of a dot.
	   */
	  obuf[opos++] = '.';
	  obuf[opos++] = '\r';
	  obuf[opos++] = '\n';
	  [md setLength: opos];
	  [self _timer: 60.0];
	  [self _sendData: md];
	  RELEASE(md);
        }
      else
	{
	  NSLog(@"_doMessage called in unexpected state.");
	  [self _shutdown: nil];
	}
    }
  else
    {
      [self _shutdown: nil];
    }
}

- (NSString*) _identity
{
  NSString	*tmp = internal->identity;

  if (tmp == nil)
    {
      tmp = [[NSUserDefaults standardUserDefaults]
	stringForKey: @"GSMimeSMTPClientIdentity"];
    }
  if ([tmp length] == 0)
    {
      tmp = [[NSHost currentHost] name];
    }
  return tmp;
}

/** Does low level writing and reading of data.
 */
- (void) _performIO
{
  NS_DURING
    {
      [self retain];             // Make sure we don't get released until done.

      /* First perform all reads ... so we process incoming data,
       */
      while (internal->readable == YES && internal->cState != TP_OPEN)
        {
          uint8_t       buf[BUFSIZ];
          int   	length;

          /* Try to fill the buffer, then process any data we have.
           */
          length = [internal->istream read: buf maxLength: sizeof(buf)];
          if (length > 0)
            {
              uint8_t   *ptr;
              int       i;

              if (internal->rdata == nil)
                {
                  internal->rdata = [[NSMutableData alloc] initWithBytes: buf
		    length: length];
                }
              else
                {
                  [internal->rdata appendBytes: buf length: length];
                  length = [internal->rdata length];
                }
              ptr = [internal->rdata mutableBytes];
              for (i = 0; i < length; i++)
                {
                  if (ptr[i] == '\n')
                    {
                      NSData    *d;

                      i++;
                      if (i == length)
                        {
                          d = [internal->rdata autorelease];
                          internal->rdata = nil;
                        }
                      else
                        {
                          d = [NSData dataWithBytes: ptr length: i];
                          memcpy(ptr, ptr + i, length - i);
                          length -= i;
                          [internal->rdata setLength: length];
                          ptr = [internal->rdata mutableBytes];
                          i = -1;
                        }
                      [self _recvData: d];
                    }
                }
            }
          else
            {
              internal->readable = NO;	// Can't read more right now.
              if (length == 0)
                {
                  NSLog(@"EOF on input stream ... terminating");
                  [self _shutdown: [self _commsEnd]];
                }
              else if ([internal->istream streamStatus] == NSStreamStatusError)
                {
                  NSLog(@"Error on input stream ... terminating");
                  [self _shutdown: [self _commsError]];
                }
            }
        }

      /* Perform write operations after read operations, so that we are able
       * to write any packets resulting from the incoming data as a single
       * block of outgoing data if possible.
       */
      while (internal->writable == YES && [internal->pending count] > 0)
        {
          uint8_t   *wbytes = [internal->wdata mutableBytes];
          unsigned  wlength = [internal->wdata length];
          int       result;

          result = [internal->ostream write: wbytes + internal->woffset
				  maxLength: wlength - internal->woffset];
          if (result > 0)
            {
              NSData    *d = [internal->pending objectAtIndex: 0];
              unsigned  dlength = [d length];

              internal->woffset += result;
              if (internal->woffset >= dlength)
                {
                  unsigned      total = 0;

                  while (internal->woffset >= total + dlength)
                    {
                      NSDebugMLLog(@"GSMime", @"%@ Write: %@", self, d);
                      [internal->pending removeObjectAtIndex: 0];
                      total += dlength;
                      if ([internal->pending count] > 0)
                        {
                          d = [internal->pending objectAtIndex: 0];
                          dlength = [d length];
                        }
                    }
                  if (total < wlength)
                    {
                      memcpy(wbytes, wbytes + total, wlength - total);
                    }
                  [internal->wdata setLength: wlength - total];
                  internal->woffset -= total;
                }
            }
          else
            {
              internal->writable = NO;	// Can't write more right now.
              if (result == 0)
                {
                  NSLog(@"EOF on output stream ... terminating");
                  [self _shutdown: [self _commsEnd]];
                }
              else if ([internal->ostream streamStatus] == NSStreamStatusError)
                {
                  NSLog(@"Error on output stream ... terminating");
                  [self _shutdown: [self _commsError]];
                }
            }
        }

      [self release];
    }
  NS_HANDLER
    {
      NSLog(@"Exception handling stream event: %@", localException);
      RELEASE(self);
    }
  NS_ENDHANDLER
}

/** Receives a chunk of data from the input stream and performs state
 * transitions based on the current state and the information received
 * from the SMTP server.
 */
- (void) _recvData: (NSData*)m
{
  unsigned int		c = 0;
  NSMutableString	*s = nil;

  if ([internal->queue count] > 0)
    {
      internal->current = [internal->queue objectAtIndex: 0];
    }

  NSDebugMLLog(@"GSMime", @"%@ _recvData: %@", self, m);

  if (m != nil)
    {
      unichar	sep;

      /*
       * Get this reply line and check it is of the correct format.
       */
      s = [[NSMutableString alloc] initWithData: m
				       encoding: NSASCIIStringEncoding];
      [s trimSpaces];
      if ([s length] <= 4)
	{
	  NSLog(@"Server made short response ... %@", s);
	  RELEASE(s);
	  [self _shutdown: [self _response: @"short data"]];
	  return;
	}
      sep = [s characterAtIndex: 3];
      if (sep != ' ' && sep != '-')
	{
	  NSLog(@"Server made illegal response ... %@", s);
	  [self _shutdown: [self _response: @"bad format"]];
	  return;
	}

      /*
       * Accumulate multiline replies in the 'reply' ivar.
       */
      if ([internal->reply length] == 0)
	{
	  ASSIGN(internal->reply, s);
	}
      else
	{
	  [s replaceCharactersInRange: NSMakeRange(0, 4) withString: @" "];
	  [internal->reply appendString: s];
	}
      RELEASE(s);
      if (sep == '-')
	{
	  return;	// Continuation line ... wait for more.
	}

      /*
       * Got end of reply ... move from ivar to local variable ready for
       * accumulating the next reply.
       */
      c = [internal->reply intValue];
      s = AUTORELEASE(internal->reply);
      internal->reply = nil;
    }

  switch (internal->cState)
    {
      case TP_INTRO:
	if (c == 220)
	  {
	    NSString	*tmp;

	    tmp = [NSString stringWithFormat: @"HELO %@\r\n", [self _identity]];
	    NSDebugMLLog(@"GSMime", @"Intro OK - sending helo");
	    internal->cState = TP_HELO;
	    [self _timer: 30.0];
	    [self _sendData: [tmp dataUsingEncoding: NSUTF8StringEncoding]];
	  }
	else
	  {
	    NSLog(@"Server went away ... %@", s);
	    [self _shutdown: [self _response: s]];
	  }
	break;

      case TP_EHLO:
	if (c == 220)
	  {
	    NSDebugMLLog(@"GSMime", @"System acknowledged EHLO");
	    if ([internal->username length] == 0)
	      {
		internal->cState = TP_MESG;
		[self _doMessage];
	      }
	    else
	      {
		NSString	*tmp;

		tmp = [NSString stringWithFormat: @"AUTH PLAIN %@\r\n",
		  [GSMimeDocument encodeBase64String: internal->username]];
		NSDebugMLLog(@"GSMime", @"Ehlo OK - sending auth");
		internal->cState = TP_AUTH;
	        [self _timer: 30.0];
                [self _sendData: [tmp dataUsingEncoding: NSUTF8StringEncoding]];
	      }
	  }
	else
	  {
	    NSString	*tmp;

	    tmp = [NSString stringWithFormat: @"HELO %@\r\n", [self _identity]];
	    NSDebugMLLog(@"GSMime", @"Ehlo failed - sending helo");
	    internal->cState = TP_HELO;
	    [self _timer: 30.0];
	    [self _sendData: [tmp dataUsingEncoding: NSUTF8StringEncoding]];
	  }
	break;

      case TP_HELO:
	if (c == 250)
	  {
	    NSDebugMLLog(@"GSMime", @"System acknowledged HELO");
	    if ([internal->username length] == 0)
	      {
		internal->cState = TP_MESG;
		[self _doMessage];
	      }
	    else
	      {
		NSString	*tmp;

		tmp = [NSString stringWithFormat: @"AUTH PLAIN %@\r\n",
		  [GSMimeDocument encodeBase64String: internal->username]];
		NSDebugMLLog(@"GSMime", @"Helo OK - sending auth");
		internal->cState = TP_AUTH;
	        [self _timer: 30.0];
                [self _sendData: [tmp dataUsingEncoding: NSUTF8StringEncoding]];
	      }
	  }
	else
	  {
	    NSLog(@"Server nacked helo ... %@", s);
	    [self _shutdown: [self _response: s]];
	  }
	break;

      case TP_AUTH:
	if (c == 250)
	  {
	    NSDebugMLLog(@"GSMime", @"System acknowledged AUTH");
	    internal->cState = TP_MESG;
	    [self _doMessage];
	  }
	else
	  {
	    NSLog(@"Server nacked auth ... %@", s);
	    [self _shutdown: [self _response: s]];
	  }
	break;

      case TP_FROM:
	if (c != 250)
	  {
	    NSLog(@"Server nacked FROM... %@", s);
	    [self _shutdown: [self _response: s]];
	  }
	else
	  {
	    NSDebugMLLog(@"GSMime", @"System acknowledged FROM");
	    [self _doMessage];
	  }
	break;

      case TP_TO:
	if (c != 250)
	  {
	    NSLog(@"Server nacked TO... %@", s);
	    [self _shutdown: [self _response: s]];
	  }
	else
	  {
	    NSDebugMLLog(@"GSMime", @"System acknowledged TO");
	    [self _doMessage];
	  }
	break;

      case TP_DATA:
	if (c != 354)
	  {
	    NSLog(@"Server nacked DATA... %@", s);
	    [self _shutdown: [self _response: s]];
	  }
	else
	  {
	    [self _doMessage];
	  }
	break;

      case TP_BODY:
	if (c != 250)
	  {
	    NSLog(@"Server nacked body ... %@", s);
	    [self _shutdown: [self _response: s]];
	  }
	else
	  {
            internal->cState = TP_MESG;
	    if (internal->current != nil)
	      {
		GSMimeDocument	*d = [internal->current retain];

		internal->current = nil;
		[internal->queue removeObjectAtIndex: 0];
		if (nil == internal->delegate)
		  {
		    NSDebugMLLog(@"GSMime", @"-smtpClient:mimeSent: %@ %@",
		      self, d);
		  }
		else
		  {
		    [internal->delegate smtpClient: self mimeSent: d];
		  }
		[d release];
	      }
            [self _doMessage];
	  }
	break;

      case TP_MESG:
	NSLog(@"Unknown response from SMTP system. - %@", s);
	[self _shutdown: [self _response: s]];
	break;

      default:
        NSLog(@"system in unexpected state.");
        [self _shutdown: [self _response: s]];
	break;
    }
}

- (NSError*) _response: (NSString*)r
{
  NSError	*e;
  NSDictionary	*d;
  NSString	*s;

  s = [NSString stringWithFormat:
    @"Unexpected response form server while %@: %@",
    [self stateDesc], r];

  d = [NSDictionary dictionaryWithObjectsAndKeys:
    s, NSLocalizedDescriptionKey,
    nil];
  e = [NSError errorWithDomain: GSMimeErrorDomain
			  code: GSMimeSMTPServerResponse
		      userInfo: d];
  return e;
}

/** Add a chunk of data to the output stream.
 */
- (void) _sendData: (NSData*)m
{
  NSDebugMLLog(@"GSMime", @"%@ _sendData: %@", self, m);
  if (internal->pending == nil)
    {
      internal->pending = [NSMutableArray new];
    }
  [internal->pending addObject: m];
  if (internal->wdata == nil)
    {
      internal->wdata = [m mutableCopy];
    }
  else
    {
      [internal->wdata appendData: m];
    }
  if ([internal->pending count] > 0 && internal->writable == YES)
    {
      [self _performIO];
    }
}

/** Shuts down the connection to the SMTP server and fails any message
 * currently in progress.  If there are queued messages, this sets a
 * timer to reconnect.
 */
- (void) _shutdown: (NSError*)e
{
  [internal->istream removeFromRunLoop: [NSRunLoop currentRunLoop]
			       forMode: NSDefaultRunLoopMode];
  [internal->ostream removeFromRunLoop: [NSRunLoop currentRunLoop]
			       forMode: NSDefaultRunLoopMode];
  [internal->istream setDelegate: nil];
  [internal->ostream setDelegate: nil];
  [internal->istream close];
  [internal->ostream close];

  DESTROY(internal->istream);
  DESTROY(internal->ostream);

  [internal->wdata setLength: 0];
  internal->woffset = 0;
  internal->readable = NO;
  internal->writable = NO;
  internal->cState = TP_IDLE;

  [internal->pending removeAllObjects];
  ASSIGN(internal->lastError, e);
  if (internal->current != nil)
    {
      GSMimeDocument	*d = [internal->current retain];

      [internal->queue removeObjectAtIndex: 0];
      internal->current = nil;
      if (nil == internal->delegate)
	{
	  NSDebugMLLog(@"GSMime", @"-smtpClient:mimeFailed: %@ %@", self, d);
	}
      else
	{
          [internal->delegate smtpClient: self mimeFailed: d];
	}
      [d release];
    }
  if ([internal->queue count] > 0)
    {
      [self _timer: 10.0];	// Try connecting again in 10 seconds
    }
}

/** If the receiver is in an idle state, this method initiates a connection
 * to the SMTP server.
 */
- (void) _startup
{
  if (internal->cState == TP_IDLE)
    {
      NSUserDefaults	*defs = [NSUserDefaults standardUserDefaults];
      NSHost    	*h;
      NSString		*n = internal->hostname;
      NSString		*p = internal->port;
      int		pnum;

      DESTROY(internal->lastError);

      /* Need to start up ...
       */
      if (n == nil)
	{
	  n = [defs stringForKey: @"GSMimeSMTPClientHost"];
	  if ([n length] == 0)
	    {
	      n = @"localhost";
	    }
	}
      h = [NSHost hostWithName: n];
      if (h == nil)
        {
          internal->istream = nil;
          internal->ostream = nil;
          NSLog(@"Unable to find host %@", n);
          [self _shutdown: nil];
	  return;
        }

      if (p == nil)
	{
	  p = [defs stringForKey: @"GSMimeSMTPClientPort"];
	  if ([p length] == 0)
	    {
	      p = @"25";
	    }
	}
      if ((pnum = [p intValue]) <= 0 || pnum > 65535)
	{
          NSLog(@"Bad port '%@' ... using 25", p);
	  pnum = 25;
	}

      [NSStream getStreamsToHost: h
			    port: pnum
		     inputStream: &internal->istream
		    outputStream: &internal->ostream];
      [internal->istream retain];
      [internal->ostream retain];
      if (internal->istream == nil || internal->ostream == nil)
	{
	  NSLog(@"Unable to connect to %@:%@", n, p);
	  [self _shutdown: nil];
	  return;
	}

      [internal->istream setDelegate: self];
      [internal->ostream setDelegate: self];

      [internal->istream scheduleInRunLoop: [NSRunLoop currentRunLoop]
				   forMode: NSDefaultRunLoopMode];
      [internal->ostream scheduleInRunLoop: [NSRunLoop currentRunLoop]
				   forMode: NSDefaultRunLoopMode];

      internal->cState = TP_OPEN;
      [self _timer: 30.0];	// Allow 30 seconds for login
      [internal->istream open];
      [internal->ostream open];
    }
}

/** Handles a timeout.
 * Behavior depends on the state of the connection.
 */
- (void) _timeout: (NSTimer*)t
{
  if (internal->timer == t)
    {
      internal->timer = nil;
    }
  if (internal->cState == TP_IDLE)
    {
      /* Not connected.
       */
      if ([internal->queue count] > 0)
	{
          [self _startup];	// Try connecting
	}
    }
  else if (internal->cState == TP_MESG)
    {
      /* Already connected to server.
       */
      if ([internal->queue count] == 0)
	{
	  [self _shutdown: nil];	// Nothing to send ... disconnect
	}
      else
	{
	  [self _doMessage];		// Send the next message
	}
    }
  else
    {
      NSError		*e;
      NSDictionary	*d;

      d = [NSDictionary dictionaryWithObjectsAndKeys:
	[NSString stringWithFormat: @"Timeout while %@", [self stateDesc]],
	NSLocalizedDescriptionKey,
	nil];
      e = [NSError errorWithDomain: GSMimeErrorDomain
			      code: GSMimeSMTPTimeout
			  userInfo: d];
      NSDebugMLLog(@"GSMime", @"%@ timeout at %@", self, [self stateDesc]);
      [self _shutdown: e];
    }
}

/* A convenience method to set the receivers timer to go off after the
 * specified interval.  Cancels previous timer (if any).
 */
- (void) _timer: (NSTimeInterval)s
{
  if (internal->timer != nil)
    {
      [internal->timer invalidate];
    }
  internal->timer
    = [NSTimer scheduledTimerWithTimeInterval: s
				       target: self
				     selector: @selector(_timeout:)
				     userInfo: nil
				      repeats: NO];
}
@end

