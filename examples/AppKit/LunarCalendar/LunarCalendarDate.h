#ifndef _LunarCalendarDate_
#define _LunarCalendarDate_

#include <Foundation/NSObject.h>

@interface LunarCalendarDate: NSObject
{
  int lunarDay, lunarMonth;
}

- (void) setDate: (NSCalendarDate *) date;
- (int) dayOfMonth;
- (int) monthOfYear;
@end

#endif /* _LunarCalendarDate_ */
