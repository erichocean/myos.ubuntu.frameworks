#include <AppKit/AppKit.h>
#include "Controller.h"

@implementation Controller

- (void) searchAction: (id) sender
{
  NSString *file;
  NSArray *args;
  NSTask *task;

  file = [sender stringValue];
  args = [NSArray arrayWithObjects: NSHomeDirectory(), @"-name", file, @"-print", nil];

  ASSIGN(pipe, [NSPipe pipe]);
  task = [NSTask new];
  [task setLaunchPath: @"/usr/bin/find"];
  [task setArguments: args];
  [task setStandardOutput: pipe];
  fileHandle = [pipe fileHandleForReading];
  [[NSNotificationCenter defaultCenter] addObserver: self
                                        selector: @selector(taskEnded:)
                                        name: NSTaskDidTerminateNotification
                                        object: nil];
  [[NSNotificationCenter defaultCenter] addObserver: self
                                        selector: @selector(readData:)
                                        name: NSFileHandleReadCompletionNotification
                                        object: fileHandle];
  [fileHandle readInBackgroundAndNotify];
  [task launch];
}

- (void) taskEnded: (NSNotification *) not
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  [fileHandle closeFile];
}

- (void) readData: (NSNotification *) not
{
  NSData *data = [[not userInfo] objectForKey: NSFileHandleNotificationDataItem];
  NSString *string = [[NSString alloc] initWithData: data
                                       encoding: [NSString defaultCStringEncoding]];
  [textView setString: string];
}

@end
