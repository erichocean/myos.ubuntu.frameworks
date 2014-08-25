#ifndef _Controller_
#define _Controller_

#include <Foundation/NSObject.h>

@interface Controller : NSObject
{
  id textView;
  id label;

  NSPipe *pipe;
  NSFileHandle *fileHandle;
}

- (void) searchAction: (id) sender;
@end

#endif /* _Controller */
