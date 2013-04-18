@implementation OpenClassifiersWindowController : CPObject
{
    @outlet CPWindow openClassifiersWindow;
    @outlet CPButton cancelButton;
    @outlet CPButton openButton;
    // I shouldn't need the buttons because the window should have them
    // But I can't find the getter...
}
- (void)tieCancelButtonToCloseFunction
{
    [cancelButton setAction:@selector(closeWindow:)];
    [cancelButton setTarget:self];
}
- (@action)closeWindow:(id)aSender
{
    [openClassifiersWindow close];
}
@end
