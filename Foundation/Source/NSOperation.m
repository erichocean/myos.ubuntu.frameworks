/**Implementation for NSOperation for GNUStep
   Copyright (C) 2009,2010 Free Software Foundation, Inc.

   Written by:  Gregory Casamento <greg.casamento@gmail.com>
   Written by:  Richard Frith-Macdonald <rfm@gnu.org>
   Date: 2009,2010
   
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

   <title>NSOperation class reference</title>
   $Date: 2008-06-08 11:38:33 +0100 (Sun, 08 Jun 2008) $ $Revision: 26606 $
   */ 

#import "common.h"

#import "Foundation/NSLock.h"

#define	GS_NSOperation_IVARS \
  NSRecursiveLock *lock; \
  NSConditionLock *cond; \
  NSOperationQueuePriority priority; \
  double threadPriority; \
  BOOL cancelled; \
  BOOL concurrent; \
  BOOL executing; \
  BOOL finished; \
  BOOL blocked; \
  BOOL ready; \
  NSMutableArray *dependencies;

#define	GS_NSOperationQueue_IVARS \
  NSRecursiveLock	*lock; \
  NSConditionLock	*cond; \
  NSMutableArray	*operations; \
  NSMutableArray	*waiting; \
  NSMutableArray	*starting; \
  NSString		*name; \
  BOOL			suspended; \
  NSInteger		executing; \
  NSInteger		threadCount; \
  NSInteger		count;

#import "Foundation/NSOperation.h"
#import "Foundation/NSArray.h"
#import "Foundation/NSAutoreleasePool.h"
#import "Foundation/NSDictionary.h"
#import "Foundation/NSEnumerator.h"
#import "Foundation/NSException.h"
#import "Foundation/NSKeyValueObserving.h"
#import "Foundation/NSThread.h"
#import "GSPrivate.h"

#define	GSInternal	NSOperationInternal
#include	"GSInternal.h"
GS_PRIVATE_INTERNAL(NSOperation)

/* The pool of threads for 'non-concurrent' operations in a queue.
 */
#define	POOL	8

static NSArray	*empty = nil;

@interface	NSOperation (Private)
- (void) _finish;
@end

@implementation NSOperation

+ (BOOL) automaticallyNotifiesObserversForKey: (NSString*)theKey
{
  /* Handle all KVO manually
   */
  return NO;
}

+ (void) initialize
{
  empty = [NSArray new];
}

- (void) addDependency: (NSOperation *)op
{
  if (NO == [op isKindOfClass: [NSOperation class]])
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"[%@-%@] dependency is not an NSOperation",
	NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    }
  if (op == self)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"[%@-%@] attempt to add dependency on self",
	NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    }
  [internal->lock lock];
  if (internal->dependencies == nil)
    {
      internal->dependencies = [[NSMutableArray alloc] initWithCapacity: 5];
    }
  NS_DURING
    {
      if (NSNotFound == [internal->dependencies indexOfObjectIdenticalTo: op])
	{
	  [self willChangeValueForKey: @"dependencies"];
          [internal->dependencies addObject: op];
	  /* We only need to watch for changes if it's possible for them to
	   * happen and make a difference.
	   */
	  if (NO == [op isFinished]
	    && NO == [self isCancelled]
	    && NO == [self isExecuting]
	    && NO == [self isFinished])
	    {
	      /* Can change readiness if we are neither cancelled nor
	       * executing nor finished.  So we need to observe for the
	       * finish of the dependency.
	       */
	      [op addObserver: self
		   forKeyPath: @"isFinished"
		      options: NSKeyValueObservingOptionNew
		      context: NULL];
	      if (internal->ready == YES)
		{
		  /* The new dependency stops us being ready ...
		   * change state.
		   */
		  [self willChangeValueForKey: @"isReady"];
		  internal->ready = NO;
		  [self didChangeValueForKey: @"isReady"];
		}
	    }
	  [self didChangeValueForKey: @"dependencies"];
	}
    }
  NS_HANDLER
    {
      [internal->lock unlock];
      NSLog(@"Problem adding dependency: %@", localException);
      return;
    }
  NS_ENDHANDLER
  [internal->lock unlock];
}

- (void) cancel
{
  if (NO == internal->cancelled && NO == [self isFinished])
    {
      [internal->lock lock];
      if (NO == internal->cancelled && NO == [self isFinished])
	{
	  NS_DURING
	    {
	      [self willChangeValueForKey: @"isCancelled"];
	      internal->cancelled = YES;
	      if (NO == internal->ready)
		{
	          [self willChangeValueForKey: @"isReady"];
		  internal->ready = YES;
	          [self didChangeValueForKey: @"isReady"];
		}
	      [self didChangeValueForKey: @"isCancelled"];
	    }
	  NS_HANDLER
	    {
	      [internal->lock unlock];
	      NSLog(@"Problem cancelling operation: %@", localException);
	      return;
	    }
	  NS_ENDHANDLER
	}
      [internal->lock unlock];
    }
}

- (void) dealloc
{
  if (internal != nil)
    {
      NSOperation	*op;

      while ((op = [internal->dependencies lastObject]) != nil)
	{
	  [self removeDependency: op];
	}
      RELEASE(internal->dependencies);
      RELEASE(internal->cond);
      RELEASE(internal->lock);
      GS_DESTROY_INTERNAL(NSOperation);
    }
  [super dealloc];
}

- (NSArray *) dependencies
{
  NSArray	*a;

  if (internal->dependencies == nil)
    {
      a = empty;	// OSX return an empty array
    }
  else
    {
      [internal->lock lock];
      a = [NSArray arrayWithArray: internal->dependencies];
      [internal->lock unlock];
    }
  return a;
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      GS_CREATE_INTERNAL(NSOperation);
      internal->priority = NSOperationQueuePriorityNormal;
      internal->threadPriority = 0.5;
      internal->ready = YES;
      internal->lock = [NSRecursiveLock new];
    }
  return self;
}

- (BOOL) isCancelled
{
  return internal->cancelled;
}

- (BOOL) isExecuting
{
  return internal->executing;
}

- (BOOL) isFinished
{
  return internal->finished;
}

- (BOOL) isConcurrent
{
  return internal->concurrent;
}

- (BOOL) isReady
{
  return internal->ready;
}

- (void) main;
{
  return;	// OSX default implementation does nothing
}

- (void) observeValueForKeyPath: (NSString *)keyPath
		       ofObject: (id)object
                         change: (NSDictionary *)change
                        context: (void *)context
{
  [internal->lock lock];

  /* We only observe isFinished changes, and we can remove self as an
   * observer once we know the operation has finished since it can never
   * become unfinished.
   */
  [object removeObserver: self
	      forKeyPath: @"isFinished"];

  if (object == self)
    {
      /* We have finished and need to unlock the condition lock so that
       * any waiting thread can continue.
       */
      [internal->cond lock];
      [internal->cond unlockWithCondition: 1];
    }
  else if (NO == internal->ready)
    {
      NSEnumerator	*en;
      NSOperation	*op;

      /* Some dependency has finished (or been removed) ...
       * so we need to check to see if we are now ready unless we know we are.
       * This is protected by locks so that an update due to an observed
       * change in one thread won't interrupt anything in another thread.
       */
      en = [internal->dependencies objectEnumerator];
      while ((op = [en nextObject]) != nil)
        {
          if (NO == [op isFinished])
	    break;
        }
      if (op == nil)
	{
          [self willChangeValueForKey: @"isReady"];
	  internal->ready = YES;
          [self didChangeValueForKey: @"isReady"];
	}
    }
  [internal->lock unlock];
}

- (NSOperationQueuePriority) queuePriority
{
  return internal->priority;
}

- (void) removeDependency: (NSOperation *)op
{
  [internal->lock lock];
  NS_DURING
    {
      if (NSNotFound != [internal->dependencies indexOfObjectIdenticalTo: op])
	{
	  [op removeObserver: self
	          forKeyPath: @"isFinished"];
	  [self willChangeValueForKey: @"dependencies"];
	  [internal->dependencies removeObject: op];
	  if (NO == internal->ready)
	    {
	      /* The dependency may cause us to become ready ...
	       * fake an observation so we can deal with that.
	       */
	      [self observeValueForKeyPath: @"isFinished"
				  ofObject: op
				    change: nil
				   context: nil];
	    }
	  [self didChangeValueForKey: @"dependencies"];
	}
    }
  NS_HANDLER
    {
      [internal->lock unlock];
      NSLog(@"Problem removing dependency: %@", localException);
      return;
    }
  NS_ENDHANDLER
  [internal->lock unlock];
}

- (void) setQueuePriority: (NSOperationQueuePriority)pri
{
  if (pri <= NSOperationQueuePriorityVeryLow)
    pri = NSOperationQueuePriorityVeryLow;
  else if (pri <= NSOperationQueuePriorityLow)
    pri = NSOperationQueuePriorityLow;
  else if (pri < NSOperationQueuePriorityHigh)
    pri = NSOperationQueuePriorityNormal;
  else if (pri < NSOperationQueuePriorityVeryHigh)
    pri = NSOperationQueuePriorityHigh;
  else
    pri = NSOperationQueuePriorityVeryHigh;

  if (pri != internal->priority)
    {
      [internal->lock lock];
      if (pri != internal->priority)
	{
	  NS_DURING
	    {
	      [self willChangeValueForKey: @"queuePriority"];
	      internal->priority = pri;
	      [self didChangeValueForKey: @"queuePriority"];
	    }
	  NS_HANDLER
	    {
	      [internal->lock unlock];
	      NSLog(@"Problem setting priority: %@", localException);
	      return;
	    }
	  NS_ENDHANDLER
	}
      [internal->lock unlock];
    }
}

- (void) setThreadPriority: (double)pri
{
  if (pri > 1) pri = 1;
  else if (pri < 0) pri = 0;
  internal->threadPriority = pri;
}

- (void) start
{
  NSAutoreleasePool	*pool = [NSAutoreleasePool new];
  double		prio = [NSThread  threadPriority];

  [internal->lock lock];
  NS_DURING
    {
      if (YES == [self isConcurrent])
	{
	  [NSException raise: NSInvalidArgumentException
		      format: @"[%@-%@] called on concurrent operation",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
	}
      if (YES == [self isExecuting])
	{
	  [NSException raise: NSInvalidArgumentException
		      format: @"[%@-%@] called on executing operation",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
	}
      if (YES == [self isFinished])
	{
	  [NSException raise: NSInvalidArgumentException
		      format: @"[%@-%@] called on finished operation",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
	}
      if (NO == [self isReady])
	{
	  [NSException raise: NSInvalidArgumentException
		      format: @"[%@-%@] called on operation which is not ready",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
	}
      if (NO == internal->executing)
	{
	  [self willChangeValueForKey: @"isExecuting"];
	  internal->executing = YES;
	  [self didChangeValueForKey: @"isExecuting"];
	}
    }
  NS_HANDLER
    {
      [internal->lock unlock];
      [localException raise];
    }
  NS_ENDHANDLER
  [internal->lock unlock];

  NS_DURING
    {
      if (NO == [self isCancelled])
	{
	  [NSThread setThreadPriority: internal->threadPriority];
	  [self main];
	}
    }
  NS_HANDLER
    {
      [NSThread setThreadPriority:  prio];
      [localException raise];
    }
  NS_ENDHANDLER;

  [self _finish];
  [pool release];
}

- (double) threadPriority
{
  return internal->threadPriority;
}

- (void) waitUntilFinished
{
  if (NO == [self isFinished])
    {
      [internal->lock lock];
      if (nil == internal->cond)
	{
	  /* Set up condition to wait on and observer to unblock.
	   */
	  internal->cond = [[NSConditionLock alloc] initWithCondition: 0];
	  [self addObserver: self
		 forKeyPath: @"isFinished"
		    options: NSKeyValueObservingOptionNew
		    context: NULL];
	  /* Some other thread could have marked us as finished while we
	   * were setting up ... so we can fake the observation if needed.
	   */
          if (YES == [self isFinished])
	    {
	      [self observeValueForKeyPath: @"isFinished"
				  ofObject: self
				    change: nil
				   context: nil];
	    }
	}
      [internal->lock unlock];
      [internal->cond lockWhenCondition: 1];	// Wait for finish
      [internal->cond unlockWithCondition: 1];	// Signal any other watchers
    }
}
@end

@implementation	NSOperation (Private)
- (void) _finish
{
  /* retain while finishing so that we don't get deallocated when our
   * queue removes and releases us.
   */
  [self retain];
  [internal->lock lock];
  if (NO == internal->finished)
    {
      if (NO == internal->executing)
        {
	  [self willChangeValueForKey: @"isExecuting"];
	  [self willChangeValueForKey: @"isFinished"];
	  internal->executing = NO;
	  internal->finished = YES;
	  [self didChangeValueForKey: @"isFinished"];
	  [self didChangeValueForKey: @"isExecuting"];
	}
      else
	{
	  [self willChangeValueForKey: @"isFinished"];
	  internal->finished = YES;
	  [self didChangeValueForKey: @"isFinished"];
	}
    }
  [internal->lock unlock];
  [self release];
}

@end

#undef	GSInternal
#define	GSInternal	NSOperationQueueInternal
#include	"GSInternal.h"
GS_PRIVATE_INTERNAL(NSOperationQueue)


@interface	NSOperationQueue (Private)
+ (void) _mainQueue;
- (void) _execute;
- (void) _thread;
- (void) observeValueForKeyPath: (NSString *)keyPath
		       ofObject: (id)object
                         change: (NSDictionary *)change
                        context: (void *)context;
@end

static NSInteger	maxConcurrent = 200;	// Thread pool size

static NSComparisonResult
sortFunc(id o1, id o2, void *ctxt)
{
  NSOperationQueuePriority p1 = [o1 queuePriority];
  NSOperationQueuePriority p2 = [o2 queuePriority];
  
  if (p1 < p2) return NSOrderedDescending;
  if (p1 > p2) return NSOrderedAscending;
  return NSOrderedSame;
}

static NSString	*threadKey = @"NSOperationQueue";
static NSOperationQueue *mainQueue = nil;

@implementation NSOperationQueue

+ (id) currentQueue
{
  return [[[NSThread currentThread] threadDictionary] objectForKey: threadKey];
}

+ (void) initialize
{
  if (mainQueue == nil)
    {
      [self performSelectorOnMainThread: @selector(_mainQueue)
			     withObject: nil
			  waitUntilDone: YES];
    }
}

+ (id) mainQueue
{
  return mainQueue;
}

- (void) addOperation: (NSOperation *)op
{
  if (op == nil || NO == [op isKindOfClass: [NSOperation class]])
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"[%@-%@] object is not an NSOperation",
	NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    }
  [internal->lock lock];
  if (NSNotFound == [internal->operations indexOfObjectIdenticalTo: op]
    && NO == [op isFinished])
    {
      [op addObserver: self
	   forKeyPath: @"isReady"
	      options: NSKeyValueObservingOptionNew
	      context: NULL];
      [self willChangeValueForKey: @"operations"];
      [self willChangeValueForKey: @"operationCount"];
      [internal->operations addObject: op];
      [self didChangeValueForKey: @"operationCount"];
      [self didChangeValueForKey: @"operations"];
      if (YES == [op isReady])
	{
	  [self observeValueForKeyPath: @"isReady"
			      ofObject: op
				change: nil
			       context: nil];
	}
    }
  [internal->lock unlock];
}

- (void) addOperations: (NSArray *)ops
     waitUntilFinished: (BOOL)shouldWait
{
  NSUInteger	total;
  NSUInteger	index;

  if (ops == nil || NO == [ops isKindOfClass: [NSArray class]])
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"[%@-%@] object is not an NSArray",
	NSStringFromClass([self class]), NSStringFromSelector(_cmd)];
    }
  total = [ops count];
  if (total > 0)
    {
      BOOL		invalidArg = NO;
      NSUInteger	toAdd = total;
      GS_BEGINITEMBUF(buf, total, id)

      [ops getObjects: buf];
      for (index = 0; index < total; index++)
	{
	  NSOperation	*op = buf[index];

	  if (NO == [op isKindOfClass: [NSOperation class]])
	    {
	      invalidArg = YES;
	      toAdd = 0;
	      break;
	    }
	  if (YES == [op isFinished])
	    {
	      buf[index] = nil;
	      toAdd--;
	    }
	}
      if (toAdd > 0)
	{
          [internal->lock lock];
	  [self willChangeValueForKey: @"operationCount"];
	  [self willChangeValueForKey: @"operations"];
	  for (index = 0; index < total; index++)
	    {
	      NSOperation	*op = buf[index];

	      if (op == nil)
		{
		  continue;		// Not added
		}
	      if (NSNotFound
		!= [internal->operations indexOfObjectIdenticalTo: op])
		{
		  buf[index] = nil;	// Not added
		  toAdd--;
		  continue;
		}
	      [op addObserver: self
		   forKeyPath: @"isReady"
		      options: NSKeyValueObservingOptionNew
		      context: NULL];
	      [internal->operations addObject: op];
	      if (NO == [op isReady])
		{
		  buf[index] = nil;	// Not yet ready
		}
	    }
	  [self didChangeValueForKey: @"operationCount"];
	  [self didChangeValueForKey: @"operations"];
	  for (index = 0; index < total; index++)
	    {
	      NSOperation	*op = buf[index];

	      if (op != nil)
		{
		  [self observeValueForKeyPath: @"isReady"
				      ofObject: op
					change: nil
				       context: nil];
		}
	    }
          [internal->lock unlock];
	}
      GS_ENDITEMBUF()
      if (YES == invalidArg)
	{
	  [NSException raise: NSInvalidArgumentException
	    format: @"[%@-%@] object at index %u is not an NSOperation",
	    NSStringFromClass([self class]), NSStringFromSelector(_cmd),
	    index];
	}
    }
  if (YES == shouldWait)
    {
      [self waitUntilAllOperationsAreFinished];
    }
}

- (void) cancelAllOperations
{
  [[self operations] makeObjectsPerformSelector: @selector(cancel)];
}

- (void) dealloc
{
  [internal->operations release];
  [internal->starting release];
  [internal->waiting release];
  [internal->name release];
  [internal->cond release];
  [internal->lock release];
  GS_DESTROY_INTERNAL(NSOperationQueue);
  [super dealloc];
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      GS_CREATE_INTERNAL(NSOperationQueue);
      internal->suspended = NO;
      internal->count = NSOperationQueueDefaultMaxConcurrentOperationCount;
      internal->operations = [NSMutableArray new];
      internal->starting = [NSMutableArray new];
      internal->waiting = [NSMutableArray new];
      internal->lock = [NSRecursiveLock new];
      internal->cond = [[NSConditionLock alloc] initWithCondition: 0];
    }
  return self;
}

- (BOOL) isSuspended
{
  return internal->suspended;
}

- (NSInteger) maxConcurrentOperationCount
{
  return internal->count;
}

- (NSString*) name
{
  NSString	*s;

  [internal->lock lock];
  if (internal->name == nil)
    {
      internal->name
	= [[NSString alloc] initWithFormat: @"NSOperation %p", self];
    }
  s = [internal->name retain];
  [internal->lock unlock];
  return [s autorelease];
}

- (NSUInteger) operationCount
{
  NSUInteger	c;

  [internal->lock lock];
  c = [internal->operations count];
  [internal->lock unlock];
  return c;
}

- (NSArray *) operations
{
  NSArray	*a;

  [internal->lock lock];
  a = [NSArray arrayWithArray: internal->operations];
  [internal->lock unlock];
  return a;
}

- (void) setMaxConcurrentOperationCount: (NSInteger)cnt
{
  if (cnt < 0
    && cnt != NSOperationQueueDefaultMaxConcurrentOperationCount)
    {
      [NSException raise: NSInvalidArgumentException
		  format: @"[%@-%@] cannot set negative (%d) count",
	NSStringFromClass([self class]), NSStringFromSelector(_cmd), cnt];
    }
  [internal->lock lock];
  if (cnt != internal->count)
    {
      [self willChangeValueForKey: @"maxConcurrentOperationCount"];
      internal->count = cnt;
      [self didChangeValueForKey: @"maxConcurrentOperationCount"];
    }
  [internal->lock unlock];
  [self _execute];
}

- (void) setName: (NSString*)s
{
  if (s == nil) s = @"";
  [internal->lock lock];
  if (NO == [internal->name isEqual: s])
    {
      [self willChangeValueForKey: @"name"];
      [internal->name release];
      internal->name = [s copy];
      [self didChangeValueForKey: @"name"];
    }
  [internal->lock unlock];
}

- (void) setSuspended: (BOOL)flag
{
  [internal->lock lock];
  if (flag != internal->suspended)
    {
      [self willChangeValueForKey: @"suspended"];
      internal->suspended = flag;
      [self didChangeValueForKey: @"suspended"];
    }
  [internal->lock unlock];
  [self _execute];
}

- (void) waitUntilAllOperationsAreFinished
{
  NSOperation	*op;

  [internal->lock lock];
  while ((op = [internal->operations lastObject]) != nil)
    {
      [op retain];
      [internal->lock unlock];
      [op waitUntilFinished];
      [op release];
      [internal->lock lock];
    }
  [internal->lock unlock];
}
@end

@implementation	NSOperationQueue (Private)

+ (void) _mainQueue
{
  if (mainQueue == nil)
    {
      mainQueue = [self new];
      [[[NSThread currentThread] threadDictionary] setObject: mainQueue
						      forKey: threadKey];
    }
}

- (void) observeValueForKeyPath: (NSString *)keyPath
		       ofObject: (id)object
                         change: (NSDictionary *)change
                        context: (void *)context
{
  [internal->lock lock];
  if (YES == [object isFinished])
    {
      internal->executing--;
      [object removeObserver: self
		  forKeyPath: @"isFinished"];
      [self willChangeValueForKey: @"operations"];
      [self willChangeValueForKey: @"operationCount"];
      [internal->operations removeObjectIdenticalTo: object];
      [self didChangeValueForKey: @"operationCount"];
      [self didChangeValueForKey: @"operations"];
    }
  else if (YES == [object isReady])
    {
      [object removeObserver: self
		  forKeyPath: @"isReady"];
      [internal->waiting addObject: object];
    }
  [internal->lock unlock];
  [self _execute];
}

- (void) _thread
{
  NSAutoreleasePool	*pool = [NSAutoreleasePool new];

  for (;;)
    {
      NSOperation	*op;
      NSDate		*when;
      BOOL		found;

      when = [[NSDate alloc] initWithTimeIntervalSinceNow: 5.0];
      found = [internal->cond lockWhenCondition: 1 beforeDate: when];
      [when release];
      if (NO == found)
	{
	  break;	// Idle for 5 seconds ... exit thread.
	}

      if ([internal->starting count] > 0)
	{
          op = [internal->starting objectAtIndex: 0];
	  [internal->starting removeObjectAtIndex: 0];
	}
      else
	{
	  op = nil;
	}

      if ([internal->starting count] > 0)
	{
	  // Signal any other idle threads,
          [internal->cond unlockWithCondition: 1];
	}
      else
	{
	  // There are no more operations starting.
          [internal->cond unlockWithCondition: 0];
	}

      if (nil != op)
	{
          NS_DURING
	    {
	      NSAutoreleasePool	*opPool = [NSAutoreleasePool new];

	      if (NO == [op isCancelled])
		{
		  [NSThread setThreadPriority: [op threadPriority]];
		  [op main];
		}
	      [opPool release];
	    }
          NS_HANDLER
	    {
	      NSLog(@"Problem running operation %@ ... %@",
		op, localException);
	    }
          NS_ENDHANDLER
	  [op _finish];
	}
    }

  [internal->lock lock];
  internal->threadCount--;
  [internal->lock unlock];
  [pool release];
  [NSThread exit];
}

/* Check for operations which can be executed and start them.
 */
- (void) _execute
{
  NSInteger	max;

  [internal->lock lock];

  max = [self maxConcurrentOperationCount];
  if (NSOperationQueueDefaultMaxConcurrentOperationCount == max)
    {
      max = maxConcurrent;
    }

  while (NO == [self isSuspended]
    && max > internal->executing
    && [internal->waiting count] > 0)
    {
      NSOperation	*op;

      /* Make sure we have a sorted queue of operations waiting to execute.
       */
      [internal->waiting sortUsingFunction: sortFunc context: 0];

      /* Take the first operation from the queue and start it executing.
       * We set ourselves up as an observer for the operating finishing
       * and we keep track of the count of operations we have started,
       * but the actual startup is left to the NSOperation -start method.
       */
      op = [internal->waiting objectAtIndex: 0];
      [internal->waiting removeObjectAtIndex: 0];
      [op addObserver: self
	   forKeyPath: @"isFinished"
	      options: NSKeyValueObservingOptionNew
	      context: NULL];
      internal->executing++;
      if (YES == [op isConcurrent])
	{
          [op start];
	}
      else
	{
	  NSUInteger	pending;

	  [internal->cond lock];
	  pending = [internal->starting count];
	  [internal->starting addObject: op];

	  /* Create a new thread if all existing threads are busy and
	   * we haven't reached the pool limit.
	   */
	  if (0 == internal->threadCount
	    || (pending > 0 && internal->threadCount < POOL))
	    {
	      internal->threadCount++;
	      [NSThread detachNewThreadSelector: @selector(_thread)
				       toTarget: self
				     withObject: nil];
	    }
	  /* Tell the thread pool that there is an operation to start.
	   */
	  [internal->cond unlockWithCondition: 1];
	}
    }
  [internal->lock unlock];
}

@end

