#include "CoreFoundation/CFTree.h"
#include "../CFTesting.h"

int main (void)
{
  CFTreeRef tree;
  CFTreeRef child1;
  CFTreeRef child2;
  CFTreeRef child3;
  CFTreeContext ctxt;
  
  ctxt.version = 0;
  ctxt.info = NULL;
  ctxt.retain = NULL;
  ctxt.release = NULL;
  ctxt.copyDescription = NULL;
  
  tree = CFTreeCreate (NULL, &ctxt);
  child1 = CFTreeCreate (NULL, &ctxt);
  child2 = CFTreeCreate (NULL, &ctxt);
  child3 = CFTreeCreate (NULL, &ctxt);
  
  CFTreeAppendChild (tree, child2);
  CFTreePrependChild (tree, child1);
  CFTreeInsertSibling (child2, child3);
  
  CFRelease (child1);
  CFRelease (child2);
  CFRelease (child3);
  
  PASS(CFTreeGetChildCount (tree) == 3, "Tree has three children.")
  PASS(CFTreeGetParent (child3) == tree, "Parent is the original tree object.");
  PASS(CFTreeGetFirstChild (tree) == child1, "First child is child1.");
  PASS(CFTreeGetNextSibling (child1) == child2,
    "Next sibling for child1 is child2.");
  PASS(CFTreeGetChildAtIndex (tree, 2) == child3, "Child3 is at index 2");
  
  CFRelease (tree);
  
  return 0;
}