//
//  SIOutline.m
//
//  Copyright (c) 2009  Martin Kühl <purl.org/net/mkhl>
//

#import "SIOutline.h"
#import "Macros.h"

static NSString *const SIXMLChanged = @"SIXMLChanged";
static NSString *const SIMainWindowChanged = @"SIMainWindowChanged";
static NSString *const SISelectedRangeChanged = @"SISelectedRangeChanged";

NSView <OakTextView> *SIMainTextView(void)
{
  id view = [[[NSApp mainWindow] windowController] textView];
  if ([view isKindOfClass:NSClassFromString(@"OakTextView")])
    return (NSView <OakTextView> *)view;
  return nil;
}

#pragma mark -
@implementation SIOutline

#pragma mark Accessors
- (NSWindow *)window
{
  return window;
}
- (void)setXml:(NSXMLDocument *)newXml
{
  [xml_ autorelease];
  [self willChangeValueForKey:@"xml"];
  xml_ = [newXml retain];
  [self didChangeValueForKey:@"xml"];
}
- (NSXMLDocument *)xml
{
  return xml_;
}
- (void)setScopeRanges:(NSDictionary *)newScopes
{
  [scopeRanges_ autorelease];
  [self willChangeValueForKey:@"scopeRanges"];
  scopeRanges_ = [newScopes retain];
  [self didChangeValueForKey:@"scopeRanges"];
}
- (NSDictionary *)scopeRanges
{
  return scopeRanges_;
}
- (void)setLineOffsets:(NSArray *)newLines
{
  [lineOffsets_ autorelease];
  [self willChangeValueForKey:@"lineOffsets"];
  lineOffsets_ = [newLines retain];
  [self didChangeValueForKey:@"lineOffsets"];
}
- (NSArray *)lineOffsets
{
  return lineOffsets_;
}

#pragma mark Memory Management
- (void)awakeFromNib
{
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(outlineViewSelectionDidChange:)
                 name:NSOutlineViewSelectionDidChangeNotification
               object:view];
//  [NSApp addObserver:self
//          forKeyPath:@"mainWindow"
//             options:0
//             context:SIMainWindowChanged];
  [NSApp addObserver:self
          forKeyPath:@"mainWindow.windowController.textView.xmlRepresentation"
             options:0
             context:SIXMLChanged];
  //  [NSApp addObserver:self
//          forKeyPath:@"mainWindow.initialFirstResponder.selectedRange"
//             options:0
//             context:SISelectedRangeChanged];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  DESTROY(xml_);
  DESTROY(scopeRanges_);
  DESTROY(lineOffsets_);
  [super dealloc];
}

#pragma mark Entry Point
- (void)update
{
  textView = SIMainTextView();
  if (textView) {
    if ([window isVisible]) {
      updating_ = YES;
      [self updateXML];
      [self updateScopes];
      [self updateLines];
      [self filterXML];
      updating_ = NO;
    }
  }
}

#pragma mark -
#pragma mark Line Offsets
- (void)updateLines
{
  if ([self xml]) {
    NSMutableArray *offsets = [NSMutableArray array];
    NSArray *lines =  [[[[self xml] rootElement] stringValue] componentsSeparatedByString:@"\n"];
    uint offset = 0;
    uint i, count = [lines count];
    for (i = 0; i < count; i++) {
      [offsets addObject:[NSNumber numberWithUnsignedInt:offset]];
      offset += 1 + [[lines objectAtIndex:i] length];
    }
    [self setLineOffsets:offsets];
  }
}

#pragma mark Scope Ranges
- (void)updateScopeForNode:(NSXMLNode *)node
                  atOffset:(uint)offset
              inDictionary:(NSMutableDictionary *)dict
{
  [dict setObject:[NSValue valueWithRange:NSMakeRange(offset, [[node stringValue] length])] forKey:[node XPath]];
  uint currentOffset = offset;
  uint i, count = [node childCount];
  for (i = 0; i < count; i++) {
    NSXMLNode *child = [node childAtIndex:i];
    [self updateScopeForNode:child atOffset:currentOffset inDictionary:dict];
    currentOffset += [[child stringValue] length];
  }
}

- (void)updateScopes
{
  if ([self xml]) {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [self updateScopeForNode:[[self xml] rootElement]
                    atOffset:0
                inDictionary:dict];
    [self setScopeRanges:dict]; 
  }
}

#pragma mark XML
- (void)filterXML
{
  if ([self xml]) {
    NSArray *nodes = [[self xml] nodesForXPath:@"//text()" error:nil];
    uint i, count = [nodes count];
    for (i = 0; i < count; i++) {
      [[nodes objectAtIndex:i] detach];
    }
  }
}

- (void)updateXML
{
  if (textView) {
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[[textView xmlRepresentation] dataUsingEncoding:NSUTF8StringEncoding]];
    [parser setDelegate:self];
    BOOL ok = [parser parse];
    if (!ok) {
      NSLog(@"%@: Failed to parse XML Representation: %@", self, [parser parserError]);
    }
    [parser release];
  }
}

#pragma mark -
#pragma mark OutlineView Notifications
- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
  if (!updating_) {
    NSString *xpath = [[[tree selectedObjects] lastObject] XPath];
    NSRange range = [[[self scopeRanges] objectForKey:xpath] rangeValue];
    [self selectRange:range];
  }
}

#pragma mark OakTextView Notifications
- (void)textViewSelectionDidChange
{
  if (textView) {
    NSLog(@"%@: Selection Changed: %@", self, NSStringFromRange([textView selectedRange]));
  }
}

#pragma mark Other Notifications
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
  if (context == SIMainWindowChanged) {
    [self update];
  } else if (context == SIXMLChanged) {
    [self update];
  } else if (context == SISelectedRangeChanged) {
    [self textViewSelectionDidChange];
  }
}
#pragma mark -
#pragma mark OakTextView Interaction
- (NSArray *)coordinatesForOffset:(uint)offset
{
  uint i, count = [[self lineOffsets] count];
  for (i = 0; i < count; i++)
    if ([[[self lineOffsets] objectAtIndex:i] unsignedIntValue] > offset)
      break;
  uint lineOffset = [[[self lineOffsets] objectAtIndex:i-1] unsignedIntValue];
  uint columnNumber = 1 + offset - lineOffset;
  // The line number (1 based)
  NSNumber *line = [NSNumber numberWithUnsignedInt:i];
  // The column number (1 based)
  NSNumber *column = [NSNumber numberWithUnsignedInt:columnNumber];
  return [NSArray arrayWithObjects:line, column, nil];
}

- (void)selectRange:(NSRange)range
{
  if (textView) {
    NSArray *from = [self coordinatesForOffset:range.location];
    NSArray *to = [self coordinatesForOffset:(range.location + range.length)];
    [textView goToLineNumber:[from objectAtIndex:0]];
    [textView goToColumnNumber:[from objectAtIndex:1]];
    [textView selectToLine:[to objectAtIndex:0]
                 andColumn:[to objectAtIndex:1]];
  }
}

#pragma mark -
#pragma mark NSXMLParser Delegate
// NSXMLDocument's own parser will always omit "ignorable whitespace" when 
// generating its `stringValue`, even when told to preserve whitespace.
// So we roll our own NSXMLParser to construct the NSXMLDocument.
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
  rootElement_ = nil;
  currentElement_ = nil;
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
  [self setXml:[[[NSXMLDocument alloc] initWithRootElement:rootElement_] autorelease]];
}

- (void)parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
    attributes:(NSDictionary *)attributeDict
{
  NSXMLElement *element = [NSXMLElement elementWithName:elementName];
  [element setAttributesAsDictionary:attributeDict];
  if (!rootElement_) {
    currentElement_ = rootElement_ = element;
  } else {
    [currentElement_ addChild:element];
    currentElement_ = element;
  } 
}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName
{
  currentElement_ = (NSXMLElement *)[currentElement_ parent];
}

- (void)parser:(NSXMLParser *)parser
foundCharacters:(NSString *)string
{
  [currentElement_ addChild:[NSXMLNode textWithStringValue:string]];
}

- (void)parser:(NSXMLParser *)parser
foundIgnorableWhitespace:(NSString *)string
{
  [currentElement_ addChild:[NSXMLNode textWithStringValue:string]];
}

@end
