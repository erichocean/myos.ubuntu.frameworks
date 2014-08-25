#include "CoreFoundation/CFString.h"
#include "CoreFoundation/CFLocale.h"
#include "../CFTesting.h"

int main (void)
{
  CFLocaleRef locale;
  CFStringRef str;
  
  locale = CFLocaleCreate (NULL,
    CFSTR("en_US"));
  str = CFLocaleCopyDisplayNameForPropertyValue (locale,
    kCFLocaleLanguageCode,
    CFSTR("pt_BR@calendar=gregorian;collation=traditional;currency=BRL"));
  PASS_CFEQ(str, CFSTR("Portuguese"), "Display language is correct");
  CFRelease (str);
  
  str = CFLocaleCopyDisplayNameForPropertyValue (locale,
    kCFLocaleCountryCode,
    CFSTR("pt_BR@calendar=gregorian;collation=traditional;currency=BRL"));
  PASS_CFEQ(str, CFSTR("Brazil"), "Display country is correct");
  CFRelease (str);
  
  str = CFLocaleCopyDisplayNameForPropertyValue (locale,
    kCFLocaleScriptCode,
    CFSTR("pt_BR@calendar=gregorian;collation=traditional;currency=BRL"));
  PASS_CFEQ(str, NULL, "Display script is correct");
  CFRelease (str);
  
  str = CFLocaleCopyDisplayNameForPropertyValue (locale,
    kCFLocaleVariantCode,
    CFSTR("pt_BR@calendar=gregorian;collation=traditional;currency=BRL"));
  PASS_CFEQ(str, NULL, "Display variant is correct");
  CFRelease (str);
  
  str = CFLocaleCopyDisplayNameForPropertyValue (locale,
    kCFLocaleCalendarIdentifier,
    CFSTR("pt_BR@calendar=gregorian;collation=traditional;currency=BRL"));
  PASS_CFEQ(str, CFSTR("Gregorian Calendar"),
    "Display calendar identifier is correct");
  CFRelease (str);
  
  str = CFLocaleCopyDisplayNameForPropertyValue (locale,
    kCFLocaleCollationIdentifier,
    CFSTR("pt_BR@calendar=gregorian;collation=traditional;currency=BRL"));
  PASS_CFEQ(str, CFSTR("Traditional Sort Order"),
    "Display collation identifier is correct");
  CFRelease (str);
  
  str = CFLocaleCopyDisplayNameForPropertyValue (locale,
    kCFLocaleCurrencyCode,
    CFSTR("pt_BR@calendar=gregorian;collation=traditional;currency=BRL"));
  PASS_CFEQ(str, CFSTR("Brazilian Real"), "Display currency code is correct");
  CFRelease (str);
  
  return 0;
}
