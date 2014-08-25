#ifndef _CalendarView_
#define _CalendarView_

#include <AppKit/AppKit.h>

@interface CalendarView : NSView
{
  NSBox *calendarBox;
  NSTextField *yearLabel;
  NSButton *lastYearButton, *nextYearButton;
  NSMatrix *monthMatrix, *dayMatrix;
  NSCalendarDate *date;
  NSArray *monthArray;

  /* Outlet */
  id label;
}

- (NSCalendarDate *) date;
- (void) setDate: (NSCalendarDate *)date;

/* Used by interface */
- (void) updateDate: (id) sender;

@end

#endif /* _CalendarView_ */


