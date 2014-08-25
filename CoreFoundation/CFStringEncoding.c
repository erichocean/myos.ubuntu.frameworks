/* CFStringEncoding.c
   
   Copyright (C) 2011 Free Software Foundation, Inc.
   
   Written by: Stefan Bidigaray
   Date: May, 2011
   
   This file is part of the GNUstep CoreBase Library.
   
   This library is free software; you can redisibute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is disibuted in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.         See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#include "CoreFoundation/CFBase.h"
#include "CoreFoundation/CFByteOrder.h"
#include "CoreFoundation/CFString.h"
#include "CoreFoundation/CFStringEncodingExt.h"
#include "GSPrivate.h"

#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unicode/ucnv.h>
#include <unicode/ustring.h>

static GSMutex _kCFStringEncodingLock;
static CFStringEncoding *_kCFStringEncodingList = NULL;
static CFStringEncoding _kCFStringSystemEncoding = kCFStringEncodingInvalidId;

void CFStringEncodingInitialize (void)
{
  GSMutexInitialize (&_kCFStringEncodingLock);
}

typedef struct
{
  CFStringEncoding enc;
  const char *converterName;
  UInt32 winCodepage;
  UConverter *ucnv;
} _str_encoding;

/* The values in this table are best guess. */
static _str_encoding str_encoding_table[] =
{
  { kCFStringEncodingMacRoman, "macos-0_2-10.2", 10000, NULL },
  { kCFStringEncodingMacJapanese, "", 10001, NULL },
  { kCFStringEncodingMacChineseTrad, "", 10002, NULL },
  { kCFStringEncodingMacKorean, "", 10003, NULL },
  { kCFStringEncodingMacArabic, "", 10004, NULL },
  { kCFStringEncodingMacHebrew, "", 10005, NULL },
  { kCFStringEncodingMacGreek, "macos-6_2-10.4", 10006, NULL },
  { kCFStringEncodingMacCyrillic, "macos-7_3-10.2", 10007, NULL },
  { kCFStringEncodingMacDevanagari, "", 0, NULL },
  { kCFStringEncodingMacGurmukhi, "", 0, NULL },
  { kCFStringEncodingMacGujarati, "", 0, NULL },
  { kCFStringEncodingMacOriya, "", 0, NULL },
  { kCFStringEncodingMacBengali, "", 0, NULL },
  { kCFStringEncodingMacTamil, "", 0, NULL },
  { kCFStringEncodingMacTelugu, "", 0, NULL },
  { kCFStringEncodingMacKannada, "", 0, NULL },
  { kCFStringEncodingMacMalayalam, "", 0, NULL },
  { kCFStringEncodingMacSinhalese, "", 0, NULL },
  { kCFStringEncodingMacBurmese, "", 0, NULL },
  { kCFStringEncodingMacKhmer, "", 0, NULL },
  { kCFStringEncodingMacThai, "", 10021, NULL },
  { kCFStringEncodingMacLaotian, "", 0, NULL },
  { kCFStringEncodingMacGeorgian, "", 0, NULL },
  { kCFStringEncodingMacArmenian, "", 0, NULL },
  { kCFStringEncodingMacChineseSimp, "", 10008, NULL },
  { kCFStringEncodingMacTibetan, "", 0, NULL },
  { kCFStringEncodingMacMongolian, "", 0, NULL },
  { kCFStringEncodingMacEthiopic, "", 0, NULL },
  { kCFStringEncodingMacCentralEurRoman, "macos-29-10.2", 10029, NULL },
  { kCFStringEncodingMacVietnamese, "", 0, NULL },
  { kCFStringEncodingMacExtArabic, "", 0, NULL },
  { kCFStringEncodingMacSymbol, "", 0, NULL },
  { kCFStringEncodingMacDingbats, "", 0, NULL },
  { kCFStringEncodingMacTurkish, "macos-35-10.2", 10081, NULL },
  { kCFStringEncodingMacCroatian, "", 10082, NULL },
  { kCFStringEncodingMacIcelandic, "", 10079, NULL },
  { kCFStringEncodingMacRomanian, "", 10010, NULL },
  { kCFStringEncodingMacCeltic, "", 0, NULL },
  { kCFStringEncodingMacGaelic, "", 0, NULL },
  { kCFStringEncodingMacFarsi, "", 0, NULL },
  { kCFStringEncodingMacUkrainian, "", 10017, NULL },
  { kCFStringEncodingMacInuit, "", 0, NULL },
  { kCFStringEncodingMacVT100, "", 0, NULL },
  { kCFStringEncodingMacHFS, "", 0, NULL },
  { kCFStringEncodingUTF16, "UTF-16", 0, NULL },
  { kCFStringEncodingUTF7, "UTF-7", 65000, NULL },
  { kCFStringEncodingUTF8, "UTF-8", 65001, NULL },
  { kCFStringEncodingUTF16BE, "UTF-16BE", 1201, NULL },
  { kCFStringEncodingUTF16LE, "UTF-16LE", 1200, NULL },
  { kCFStringEncodingUTF32, "UTF-32", 0, NULL },
  { kCFStringEncodingUTF32BE, "UTF-32BE", 12001, NULL },
  { kCFStringEncodingUTF32LE, "UTF-32LE", 12000, NULL },
  { kCFStringEncodingISOLatin1, "ISO-8859-1", 28591, NULL },
  { kCFStringEncodingISOLatin2, "ibm-912_P100-1995", 28592, NULL },
  { kCFStringEncodingISOLatin3, "ibm-913_P100-2000", 28593, NULL },
  { kCFStringEncodingISOLatin4, "ibm-914_P100-1995", 28594, NULL },
  { kCFStringEncodingISOLatinCyrillic, "ibm-915_P100-1995", 28595, NULL },
  { kCFStringEncodingISOLatinArabic, "ibm-1089_P100-1995", 28596, NULL },
  { kCFStringEncodingISOLatinGreek, "ibm-9005_X110-2007", 28597, NULL },
  { kCFStringEncodingISOLatinHebrew, "ibm-5012_P100-1999", 28598, NULL },
  { kCFStringEncodingISOLatin5, "ibm-920_P100-1995", 28599, NULL },
  { kCFStringEncodingISOLatin6, "iso-8859_10-1998", 0, NULL },
  { kCFStringEncodingISOLatinThai, "iso-8859_11-2001", 0, NULL },
  { kCFStringEncodingISOLatin7, "ibm-921_P100-1995", 28603, NULL },
  { kCFStringEncodingISOLatin8, "iso-8859_14-1998", 0, NULL },
  { kCFStringEncodingISOLatin9, "ibm-923_P100-1998", 28605, NULL },
  { kCFStringEncodingISOLatin10, "iso-8859_16-2001", 0, NULL },
  { kCFStringEncodingDOSLatinUS, "ibm-437_P100-1995", 437, NULL },
  { kCFStringEncodingDOSGreek, "ibm-737_P100-1997", 737, NULL },
  { kCFStringEncodingDOSBalticRim, "ibm-775_P100-1996", 775, NULL },
  { kCFStringEncodingDOSLatin1, "ibm-850_P100-1995", 850, NULL },
  { kCFStringEncodingDOSGreek1, "ibm-851_P100-1995", 851, NULL },
  { kCFStringEncodingDOSLatin2, "ibm-852_P100-1995", 852, NULL },
  { kCFStringEncodingDOSCyrillic, "ibm-855_P100-1995", 855, NULL },
  { kCFStringEncodingDOSTurkish, "ibm-857_P100-1995", 857, NULL },
  { kCFStringEncodingDOSPortuguese, "ibm-860_P100-1995", 860, NULL },
  { kCFStringEncodingDOSIcelandic, "ibm-861_P100-1995", 861, NULL },
  { kCFStringEncodingDOSHebrew, "ibm-862_P100-1995", 862, NULL },
  { kCFStringEncodingDOSCanadianFrench, "ibm-863_P100-1995", 863, NULL },
  { kCFStringEncodingDOSArabic, "ibm-720_P100-1997", 720, NULL },
  { kCFStringEncodingDOSNordic, "ibm-865_P100-1995", 865, NULL },
  { kCFStringEncodingDOSRussian, "ibm-866_P100-1995", 866, NULL },
  { kCFStringEncodingDOSGreek2, "ibm-869_P100-1995", 869, NULL },
  { kCFStringEncodingDOSThai, "ibm-874_P100-1995", 874, NULL },
  { kCFStringEncodingDOSJapanese, "ibm-942_P12A-1999", 932, NULL },
  { kCFStringEncodingDOSChineseSimplif, "windows-936-2000", 936, NULL },
  { kCFStringEncodingDOSKorean, "ibm-949_P110-1999", 949, NULL },
  { kCFStringEncodingDOSChineseTrad, "ibm-950_P110-1999", 950, NULL },
  { kCFStringEncodingWindowsLatin1, "ibm-5348_P100-1997", 1252, NULL },
  { kCFStringEncodingWindowsLatin2, "ibm-5346_P100-1998", 1250, NULL },
  { kCFStringEncodingWindowsCyrillic, "ibm-5347_P100-1998", 1251, NULL },
  { kCFStringEncodingWindowsGreek, "ibm-5349_P100-1998", 1253, NULL },
  { kCFStringEncodingWindowsLatin5, "ibm-5350_P100-1998", 1254, NULL },
  { kCFStringEncodingWindowsHebrew, "ibm-9447_P100-2002", 1255, NULL },
  { kCFStringEncodingWindowsArabic, "ibm-9448_X100-2005", 1256, NULL },
  { kCFStringEncodingWindowsBalticRim, "ibm-9449_P100-2002", 1257, NULL },
  { kCFStringEncodingWindowsVietnamese, "ibm-5354_P100-1998", 1258, NULL },
  { kCFStringEncodingWindowsKoreanJohab, "", 1361, NULL },
  { kCFStringEncodingASCII, "US-ASCII", 20127, NULL },
  { kCFStringEncodingANSEL, "", 0, NULL },
  { kCFStringEncodingJIS_X0201_76, "ibm-897_P100-1995", 50222, NULL },
  { kCFStringEncodingJIS_X0208_83, "", 0, NULL },
  { kCFStringEncodingJIS_X0208_90, "ibm-952_P110-1997", 20932, NULL },
  { kCFStringEncodingJIS_X0212_90, "ibm-953_P100-2000", 20932, NULL },
  { kCFStringEncodingJIS_C6226_78, "", 0, NULL },
  { kCFStringEncodingShiftJIS_X0213, "ibm-943_P15A-2003", 0, NULL },
  { kCFStringEncodingShiftJIS_X0213_MenKuTen, "", 0, NULL },
  { kCFStringEncodingGB_2312_80, "ibm-1383_P110-1999", 0, NULL },
  { kCFStringEncodingGBK_95, "windows-936-2000", 936, NULL },
  { kCFStringEncodingGB_18030_2000, "gb18030", 54936, NULL },
  { kCFStringEncodingKSC_5601_87, "ibm-970_P110_P110-2006_U2", 51949, NULL },
  { kCFStringEncodingKSC_5601_92_Johab, "", 0, NULL },
  { kCFStringEncodingCNS_11643_92_P1, "", 0, NULL },
  { kCFStringEncodingCNS_11643_92_P2, "", 0, NULL },
  { kCFStringEncodingCNS_11643_92_P3, "", 0, NULL },
  { kCFStringEncodingISO_2022_JP, "ISO_2022,locale=ja,version=0", 50220, NULL },
  { kCFStringEncodingISO_2022_JP_2, "ISO_2022,locale=ja,version=2", 0, NULL },
  { kCFStringEncodingISO_2022_JP_1, "ISO_2022,locale=ja,version=1", 50221, NULL },
  { kCFStringEncodingISO_2022_JP_3, "ISO_2022,locale=ja,version=3", 0, NULL },
  { kCFStringEncodingISO_2022_CN, "ISO_2022,locale=zh,version=0", 50227, NULL },
  { kCFStringEncodingISO_2022_CN_EXT, "ISO_2022,locale=zh,version=1", 0, NULL },
  { kCFStringEncodingISO_2022_KR, "ISO_2022,locale=ko,version=0", 50225, NULL },
  { kCFStringEncodingEUC_JP, "ibm-33722_P12A_P12A-2004_U2", 51932, NULL },
  { kCFStringEncodingEUC_CN, "ibm-1383_P110-1999", 51936, NULL },
  { kCFStringEncodingEUC_TW, "ibm-964_P110-1999", 51950, NULL },
  { kCFStringEncodingEUC_KR, "ibm-970_P110_P110-2006_U2", 51949, NULL },
  { kCFStringEncodingShiftJIS, "ibm-943_P15A-2003", 932, NULL },
  { kCFStringEncodingKOI8_R, "ibm-878_P100-1996", 20866, NULL },
  { kCFStringEncodingBig5, "windows-950-2000", 950, NULL },
  { kCFStringEncodingMacRomanLatin1, "", 0, NULL },
  { kCFStringEncodingHZ_GB_2312, "ibm-1383_P110-1999", 20936, NULL },
  { kCFStringEncodingBig5_HKSCS_1999, "ibm-1375_P100-2007", 0, NULL },
  { kCFStringEncodingVISCII, "", 0, NULL },
  { kCFStringEncodingKOI8_U, "ibm-1168_P100-2002", 21866, NULL },
  { kCFStringEncodingBig5_E, "", 0, NULL },
  { kCFStringEncodingUTF7_IMAP, "IMAP-mailbox-name", 0, NULL },
  { kCFStringEncodingNextStepLatin, "", 0, NULL },
  { kCFStringEncodingNextStepJapanese, "", 0, NULL },
  { kCFStringEncodingNonLossyASCII, "", 0, NULL },
  { kCFStringEncodingEBCDIC_US, "ibm-37_P100-1995", 37, NULL },
  { kCFStringEncodingEBCDIC_CP037, "ibm-37_P100-1995", 37, NULL }
};

static const CFIndex str_encoding_table_size =
  sizeof(str_encoding_table) / sizeof(_str_encoding);

/* Define this here so we can use it in the NSStringEncoding functions. */
enum
{
  NSASCIIStringEncoding = 1,
  NSNEXTSTEPStringEncoding = 2,
  NSJapaneseEUCStringEncoding = 3,
  NSUTF8StringEncoding = 4,
  NSISOLatin1StringEncoding = 5,
  NSSymbolStringEncoding = 6,
  NSNonLossyASCIIStringEncoding = 7,
  NSShiftJISStringEncoding = 8,
  NSISOLatin2StringEncoding = 9,
  NSUnicodeStringEncoding = 10,
  NSWindowsCP1251StringEncoding = 11,
  NSWindowsCP1252StringEncoding = 12,
  NSWindowsCP1253StringEncoding = 13,
  NSWindowsCP1254StringEncoding = 14,
  NSWindowsCP1250StringEncoding = 15,
  NSISO2022JPStringEncoding = 21,
  NSMacOSRomanStringEncoding = 30,
  NSUTF16BigEndianStringEncoding = 0x90000100,
  NSUTF16LittleEndianStringEncoding = 0x94000100,
  NSUTF32StringEncoding = 0x8c000100,
  NSUTF32BigEndianStringEncoding = 0x98000100,
  NSUTF32LittleEndianStringEncoding = 0x9c000100,
};

static CFIndex
CFStringEncodingTableIndex (CFStringEncoding encoding)
{
  CFIndex idx = 0;
  while (idx < str_encoding_table_size
         && str_encoding_table[idx].enc != encoding)
    idx++;
  return idx;
}

CF_INLINE const char *
CFStringICUConverterName (CFStringEncoding encoding)
{
  const char *name;
  CFIndex idx;
  
  idx = CFStringEncodingTableIndex (encoding);
  name = str_encoding_table[idx].converterName;
  
  return name;
}

static UConverter *
CFStringICUConverterOpen (CFStringEncoding encoding, char lossByte)
{
  const char *converterName;
  UConverter *cnv;
  UErrorCode err = U_ZERO_ERROR;
  
  converterName = CFStringICUConverterName (encoding);
  
  cnv = ucnv_open (converterName, &err);
  if (U_FAILURE(err))
    cnv = NULL;
  
  if (lossByte)
    {
      /* FIXME: for some reason this is returning U_ILLEGAL_ARGUMENTS_ERROR */
      ucnv_setSubstChars (cnv, &lossByte, 1, &err);
    }
  else
    {
      ucnv_setToUCallBack (cnv, UCNV_TO_U_CALLBACK_STOP, NULL, NULL, NULL,
        &err);
      ucnv_setFromUCallBack (cnv, UCNV_FROM_U_CALLBACK_STOP, NULL, NULL, NULL,
        &err);
    }
  
  return cnv;
}

static void
CFStringICUConverterClose (UConverter *cnv)
{
  ucnv_close (cnv);
}

static UConverter *
CFStringEncodingGetUConverter (CFStringEncoding encoding)
{
  CFIndex tblIdx;
  _str_encoding *tableEntry;
  UConverter *ucnv;
  
  tblIdx = CFStringEncodingTableIndex (encoding);
  tableEntry = &str_encoding_table[tblIdx];
  ucnv = tableEntry->ucnv;
  if (ucnv == NULL)
    {
      ucnv = CFStringICUConverterOpen (encoding, 0);
      if (GSAtomicCompareAndSwapPointer(&tableEntry->ucnv, NULL, ucnv) != NULL)
        CFStringICUConverterClose (ucnv);
    }
  
  return ucnv;
}

static CFStringEncoding
CFStringConvertStandardNameToEncoding (const char *name, CFIndex length)
{
#define US_ASCII "US-ASCII"
#define UTF_PREFIX "utf-"
#define ISO_PREFIX "iso-"
#define WIN_PREFIX "windows-"
#define CP_PREFIX "cp"
#define UTF_LEN sizeof(UTF_PREFIX)-1
#define ISO_LEN sizeof(ISO_PREFIX)-1
#define WIN_LEN sizeof(WIN_PREFIX)-1
#define CP_LEN sizeof(CP_PREFIX)-1

/* FIXME: This isn't a very smart thing to do, but for now it's good enough. */
#if defined(_MSC_VER)
#define strncasecmp(a, b, n) lstrcmpiA (a, b)
#endif

  if (length == -1)
    length = strlen (name);
  
  if (strncmp(name, US_ASCII, length) == 0)
    {
      return kCFStringEncodingASCII;
    }
  else if (strncasecmp(name, UTF_PREFIX, UTF_LEN) == 0)
    {
      CFStringEncoding encoding = 0x100;
      if (strncasecmp(name + UTF_LEN, "8", 1) == 0)
        return kCFStringEncodingUTF8;
      else if (strncasecmp(name + UTF_LEN, "7", 1) == 0)
        return kCFStringEncodingUTF7;
      
      if (strncasecmp(name + UTF_LEN, "32", 2) == 0)
        encoding |= 0x0c000000;
      
      if (UTF_LEN + 2 > length)
        { 
          if (strncasecmp (name + UTF_LEN + 2, "LE", 2) == 0)
            encoding |= 0x14000000;
          else if (strncasecmp (name + UTF_LEN + 2, "BE", 2) == 0)
            encoding |= 0x10000000;
        }
      return encoding;
    }
  else if (strncasecmp(name, ISO_PREFIX, ISO_LEN) == 0)
    {
      if (strncasecmp(name + ISO_LEN, "8859-", 5) == 0)
        {
          int num = atoi (name + ISO_LEN + 5);
          return (num > 16) ? kCFStringEncodingInvalidId : 0x200 + num;
        }
      else if (strncasecmp(name + ISO_LEN, "2022-", 5) == 0)
        {
          /* FIXME */
        }
    }
  else if (strncasecmp(name, WIN_PREFIX, WIN_LEN) == 0)
    {
      int codepage = atoi (name + WIN_LEN);
      int idx = 0;
      while (idx < str_encoding_table_size)
        {
          if (str_encoding_table[idx].winCodepage != codepage)
            return str_encoding_table[idx].enc;
          ++idx;
        }
    }
  else if (strncasecmp(name, CP_PREFIX, CP_LEN) == 0)
    {
      int codepage = atoi (name + CP_LEN);
      int idx = 0;
      while (idx < str_encoding_table_size)
        {
          if (str_encoding_table[idx].winCodepage != codepage)
            return str_encoding_table[idx].enc;
          ++idx;
        }
    }
  else if (strncasecmp(name, "EUC-", sizeof("EUC-") - 1) == 0)
    {
      /* FIXME */
    }
  else if (strncasecmp(name, "macintosh", sizeof("macintosh") - 1) == 0)
    {
      return kCFStringEncodingMacRoman;
    }
  
  return kCFStringEncodingInvalidId;
}



CFStringRef
CFStringConvertEncodingToIANACharSetName (CFStringEncoding encoding)
{
  const char *name;
  const char *cnvName;
  UErrorCode err = U_ZERO_ERROR;
  
  cnvName = CFStringICUConverterName (encoding);
  name = ucnv_getStandardName (cnvName, "IANA", &err);
  if (U_FAILURE(err))
    return NULL;
  /* Using this function here because we don't want to make multiple copies
     of this string. */
  return __CFStringMakeConstantString (name);
}

unsigned long
CFStringConvertEncodingToNSStringEncoding (CFStringEncoding encoding)
{
  switch (encoding)
    {
      case kCFStringEncodingASCII:
        return NSASCIIStringEncoding;
      case kCFStringEncodingNextStepLatin:
        return NSNEXTSTEPStringEncoding;
      case kCFStringEncodingEUC_JP:
        return NSJapaneseEUCStringEncoding;
      case kCFStringEncodingUTF8:
        return NSUTF8StringEncoding;
      case kCFStringEncodingISOLatin1:
        return NSISOLatin1StringEncoding;
      case kCFStringEncodingMacSymbol:
        return NSSymbolStringEncoding;
      case kCFStringEncodingNonLossyASCII:
        return NSNonLossyASCIIStringEncoding;
      case kCFStringEncodingShiftJIS:
        return NSShiftJISStringEncoding;
      case kCFStringEncodingISOLatin2:
        return NSISOLatin2StringEncoding;
      case kCFStringEncodingUTF16:
        return NSUnicodeStringEncoding;
      case kCFStringEncodingWindowsCyrillic:
        return NSWindowsCP1251StringEncoding;
      case kCFStringEncodingWindowsLatin1:
        return NSWindowsCP1252StringEncoding;
      case kCFStringEncodingWindowsGreek:
        return NSWindowsCP1253StringEncoding;
      case kCFStringEncodingWindowsLatin5:
        return NSWindowsCP1254StringEncoding;
      case kCFStringEncodingWindowsLatin2:
        return NSWindowsCP1250StringEncoding;
      case kCFStringEncodingISO_2022_JP:
        return NSISO2022JPStringEncoding;
      case kCFStringEncodingMacRoman:
        return NSMacOSRomanStringEncoding;
      case kCFStringEncodingUTF16BE:
        return NSUTF16BigEndianStringEncoding;
      case kCFStringEncodingUTF16LE:
        return NSUTF16LittleEndianStringEncoding;
      case kCFStringEncodingUTF32:
        return NSUTF32StringEncoding;
      case kCFStringEncodingUTF32BE:
        return NSUTF32BigEndianStringEncoding;
      case kCFStringEncodingUTF32LE:
        return NSUTF32LittleEndianStringEncoding;
    }
  return 0;
}

UInt32
CFStringConvertEncodingToWindowsCodepage (CFStringEncoding encoding)
{
  CFIndex idx = CFStringEncodingTableIndex (encoding);
  return str_encoding_table[idx].winCodepage;
}

CFStringEncoding
CFStringConvertIANACharSetNameToEncoding (CFStringRef str)
{
  /* We'll start out by checking if it's one of the UTF identifiers, than ISO,
     Windows codepages, DOS codepages and EUC.  Will use strncasecmp because
     the compare here is not case sensitive. */
  char buffer[32];
  CFIndex length;
  
  if (!CFStringGetCString(str, buffer, 32, kCFStringEncodingASCII))
    return kCFStringEncodingInvalidId;
  length = CFStringGetLength (str);
  
  return CFStringConvertStandardNameToEncoding (buffer, length);
}

CFStringEncoding
CFStringConvertNSStringEncodingToEncoding (unsigned long encoding)
{
  switch (encoding)
    {
      case NSASCIIStringEncoding:
        return kCFStringEncodingASCII;
      case NSNEXTSTEPStringEncoding:
        return kCFStringEncodingNextStepLatin;
      case NSJapaneseEUCStringEncoding:
        return kCFStringEncodingEUC_JP;
      case NSUTF8StringEncoding:
        return kCFStringEncodingUTF8;
      case NSISOLatin1StringEncoding:
        return kCFStringEncodingISOLatin1;
      case NSSymbolStringEncoding:
        return kCFStringEncodingMacSymbol;
      case NSNonLossyASCIIStringEncoding:
        return kCFStringEncodingNonLossyASCII;
      case NSShiftJISStringEncoding:
        return kCFStringEncodingShiftJIS;
      case NSISOLatin2StringEncoding:
        return kCFStringEncodingISOLatin2;
      case NSUnicodeStringEncoding:
        return kCFStringEncodingUTF16;
      case NSWindowsCP1251StringEncoding:
        return kCFStringEncodingWindowsCyrillic;
      case NSWindowsCP1252StringEncoding:
        return kCFStringEncodingWindowsLatin1;
      case NSWindowsCP1253StringEncoding:
        return kCFStringEncodingWindowsGreek;
      case NSWindowsCP1254StringEncoding:
        return kCFStringEncodingWindowsLatin5;
      case NSWindowsCP1250StringEncoding:
        return kCFStringEncodingISOLatin2;
      case NSISO2022JPStringEncoding:
        return kCFStringEncodingISO_2022_JP;
      case NSMacOSRomanStringEncoding:
        return kCFStringEncodingMacRoman;
      case NSUTF16BigEndianStringEncoding:
        return kCFStringEncodingUTF16BE;
      case NSUTF16LittleEndianStringEncoding:
        return kCFStringEncodingUTF16LE;
      case NSUTF32StringEncoding:
        return kCFStringEncodingUTF32;
      case NSUTF32BigEndianStringEncoding:
        return kCFStringEncodingUTF32BE;
      case NSUTF32LittleEndianStringEncoding:
        return kCFStringEncodingUTF32LE;
    }
  return kCFStringEncodingInvalidId;
}

CFStringEncoding
CFStringConvertWindowsCodepageToEncoding (UInt32 codepage)
{
  CFIndex idx = 0;
  while (idx < str_encoding_table_size)
    if (str_encoding_table[idx++].winCodepage == codepage)
      return str_encoding_table[idx - 1].enc;
  return kCFStringEncodingInvalidId;
}

const CFStringEncoding *
CFStringGetListOfAvailableEncodings (void)
{
  if (_kCFStringEncodingList == NULL)
    {
      GSMutexLock (&_kCFStringEncodingLock);
      if (_kCFStringEncodingList == NULL)
        {
          int32_t count;
          int32_t idx;
          const char *name;
          UErrorCode err = U_ZERO_ERROR;
          
          count = ucnv_countAvailable ();
          
          _kCFStringEncodingList = CFAllocatorAllocate (NULL,
            sizeof(CFStringEncoding) * (count + 1), 0);
          
          idx = 0;
          while (idx < count)
            {
              name = ucnv_getStandardName(ucnv_getAvailableName (idx),
                "MIME", &err);
              if (U_SUCCESS(err))
                _kCFStringEncodingList[idx] =
                  CFStringConvertStandardNameToEncoding (name, -1);
              ++idx;
            }
          _kCFStringEncodingList[idx] = kCFStringEncodingInvalidId;
        }
      GSMutexUnlock (&_kCFStringEncodingLock);
    }
  
  return _kCFStringEncodingList;
}

CFIndex
CFStringGetMaximumSizeForEncoding (CFIndex length, CFStringEncoding encoding)
{
  UConverter *cnv;
  int8_t charSize;
  
  cnv = CFStringEncodingGetUConverter (encoding);
  charSize = ucnv_getMaxCharSize (cnv);
  return charSize * length;
}

CFStringEncoding
CFStringGetMostCompatibleMacStringEncoding (CFStringEncoding encoding)
{
  return kCFStringEncodingInvalidId; /* FIXME */
}

CFStringEncoding
CFStringGetSystemEncoding (void)
{
  if (_kCFStringSystemEncoding == kCFStringEncodingInvalidId)
    {
      GSMutexLock (&_kCFStringEncodingLock);
      if (_kCFStringSystemEncoding == kCFStringEncodingInvalidId)
        {
          const char *name;
          const char *defaultName;
          UErrorCode err = U_ZERO_ERROR;
          
          defaultName = ucnv_getDefaultName ();
          name = ucnv_getStandardName (defaultName, "MIME", &err);
          if (name != NULL)
            {
              _kCFStringSystemEncoding =
                CFStringConvertStandardNameToEncoding (name, -1);
            }
          else
            {
              name = ucnv_getStandardName (defaultName, "IANA", &err);
              if (name != NULL)
                _kCFStringSystemEncoding =
                  CFStringConvertStandardNameToEncoding (name, -1);
              else
                _kCFStringSystemEncoding = kCFStringEncodingInvalidId;
            }
        }
      GSMutexUnlock (&_kCFStringEncodingLock);
    }
  return _kCFStringSystemEncoding;
}

Boolean
CFStringIsEncodingAvailable (CFStringEncoding encoding)
{
  const CFStringEncoding *encodings = CFStringGetListOfAvailableEncodings ();
  while (*encodings != kCFStringEncodingInvalidId)
    if (*(encodings++) == encoding)
      return true;
  return false;
}

CFStringEncoding
CFStringGetFastestEncoding (CFStringRef str)
{
  const UniChar *s = CFStringGetCharactersPtr (str);
  return s ? kCFStringEncodingUTF16 : kCFStringEncodingASCII;
}

CFStringEncoding
CFStringGetSmallestEncoding (CFStringRef str)
{
  return kCFStringEncodingInvalidId;
}

CFIndex
CFStringGetMaximumSizeOfFileSystemRepresentation (CFStringRef string)
{
  CFIndex length = CFStringGetLength (string);
  return
    CFStringGetMaximumSizeForEncoding (length, CFStringGetSystemEncoding());
}


CFStringRef
CFStringGetNameOfEncoding (CFStringEncoding encoding)
{
  return NULL;
}



CFIndex
GSStringEncodingFromUnicode (CFStringEncoding encoding, char *dst,
  CFIndex dstLength, const UniChar **src, CFIndex srcLength, char lossByte,
  Boolean isExternalRepresentation, CFIndex *bytesNeeded)
{
  CFIndex used;
  UInt8 stackBuffer[U_CNV_SAFECLONE_BUFFERSIZE];
  int32_t pBufferSize = U_CNV_SAFECLONE_BUFFERSIZE;
  UConverter *ucnv;
  UErrorCode err = U_ZERO_ERROR;
  
  ucnv = CFStringEncodingGetUConverter (encoding);
  ucnv = ucnv_safeClone (ucnv, stackBuffer, &pBufferSize, &err);
  used = 0;
  if (U_SUCCESS(err))
    {
      char *target;
      const char *targetLimit;
      const UniChar *source;
      const UniChar *sourceLimit;
      
      target = dst;
      targetLimit = target + dstLength;
      source = *src;
      sourceLimit = source + srcLength;
      
      if (isExternalRepresentation)
        {
          /* To add a BOM we can simply convert an fake BOM. */
          const UniChar bom[] = { UTF16_BOM };
          const UniChar *bomStart = bom;
          
          ucnv_fromUnicode (ucnv, &target, targetLimit, &bomStart,
            bomStart + 1, NULL, false, &err);
        }
      
      ucnv_fromUnicode (ucnv, &target, targetLimit, &source, sourceLimit, NULL,
        true, &err);
      *src = source;
      used = (CFIndex)(target - dst);
      if (bytesNeeded)
        {
          *bytesNeeded = used;
          if (bytesNeeded && err == U_BUFFER_OVERFLOW_ERROR)
            {
              char ibuffer[256]; /* Arbitrary buffer size */
              
              targetLimit = ibuffer + 255;
              do
                {
                  target = ibuffer;
                  err = U_ZERO_ERROR;
                  ucnv_fromUnicode (ucnv, &target, targetLimit, &source,
                    sourceLimit, NULL, true, &err);
                  *bytesNeeded += (CFIndex)(target - ibuffer);
                } while (err == U_BUFFER_OVERFLOW_ERROR);
            }
        }
      
      ucnv_close (ucnv);
    }
  
  return used;
}

CFIndex
GSStringEncodingToUnicode (CFStringEncoding encoding, UniChar *dst,
  CFIndex dstLength, const char **src, CFIndex srcLength,
  Boolean isExternalRepresentation, CFIndex *bytesNeeded)
{
  CFIndex converted;
  UInt8 stackBuffer[U_CNV_SAFECLONE_BUFFERSIZE];
  int32_t pBufferSize = U_CNV_SAFECLONE_BUFFERSIZE;
  UConverter *ucnv;
  UErrorCode err = U_ZERO_ERROR;
  
  ucnv = CFStringEncodingGetUConverter (encoding);
  ucnv = ucnv_safeClone (ucnv, stackBuffer, &pBufferSize, &err);
  converted = 0;
  if (U_SUCCESS(err))
    {
      UniChar *target;
      const UniChar *targetLimit;
      const char *source;
      const char *sourceLimit;
      
      target = dst;
      targetLimit = target + dstLength;
      source = *src;
      sourceLimit = source + srcLength;
      
      if (isExternalRepresentation)
        {
          const char *tmpSrc;
          UniChar bom[1];
          UniChar *bomStart = bom;
          
          tmpSrc = source;
          ucnv_toUnicode (ucnv, &bomStart, bomStart + 1, &tmpSrc, sourceLimit,
                          NULL, false, &err);
          if (bom[0] == UTF16_BOM)
            source = tmpSrc;
          err = U_ZERO_ERROR;
        }
      
      ucnv_toUnicode (ucnv, &target, targetLimit, &source, sourceLimit, NULL,
        true, &err);
      *src = source;
      converted = (CFIndex)(target - dst);
      if (bytesNeeded)
        {
          *bytesNeeded = converted;
          if (err == U_BUFFER_OVERFLOW_ERROR)
            {
              UniChar ibuffer[256]; /* Arbitrary buffer size */
              
              targetLimit = ibuffer + 255;
              do
                {
                  target = ibuffer;
                  err = U_ZERO_ERROR;
                  ucnv_toUnicode (ucnv, &target, targetLimit, &source,
                    sourceLimit, NULL, true, &err);
                  *bytesNeeded += (CFIndex)((char*)target - (char*)ibuffer);
                } while (err == U_BUFFER_OVERFLOW_ERROR);
            }
        }
      
      ucnv_close (ucnv);
    }
  
  return converted;
}

