//
//  SIWindowController.m
//
//  Copyright (c) 2009  Martin Kühl <purl.org/net/mkhl>
//

#import "SIWindowController.h"
#import "SIOutline.h"

#pragma mark Helper Functions
NSMenu *SIWindowMenu(void)
{
  return [[[NSApp mainMenu] itemWithTitle:@"Window"] submenu];
}

NSMenuItem *SICreateMenuItem(id self)
{
  NSMenuItem *item;
  item = [[[NSMenuItem alloc] initWithTitle:@"Show Syntax Inspector"
                                     action:@selector(showWindow:)
                              keyEquivalent:@""] autorelease];
  [item setTarget:self];
  return item;
}

#pragma mark -
@implementation SIWindowController

#pragma mark Memory Management
- (id)initWithPlugInController:(id <TMPlugInController>)controller
{
  SIOutline *it = [[[SIOutline alloc] init] autorelease];
	self = [super initWithWindowNibName:@"SyntaxInspector" owner:it];
  if (!self)
    return nil;
  outline = [it retain];
  menuItem = [SICreateMenuItem(self) retain];
  [self installMenuItem];
	return self;
}

- (void)dealloc
{
  [self uninstallMenuItem];
  [menuItem release];
  [super dealloc];
}

#pragma mark Menu Item
- (void)installMenuItem
{
  NSMenu *windowMenu = SIWindowMenu();
  if (windowMenu) {
    NSArray *items = [windowMenu itemArray];
    uint index, separators, count = [items count];
    for (index = 0, separators = 0; index < count; index++) {
      if ([[items objectAtIndex:index] isSeparatorItem]) {
        separators++;
        if (separators == 2) {
          [windowMenu insertItem:menuItem atIndex:index-1];
          return;
        }
      }
    }
    [windowMenu insertItem:menuItem atIndex:0];
  }
}

- (void)uninstallMenuItem
{
  [SIWindowMenu() removeItem:menuItem];
}

#pragma mark NSWindowController
- (void)showWindow:(id)sender
{
  [super showWindow:sender];
  [self setWindow:[outline window]];
  [outline update];
}

@end
