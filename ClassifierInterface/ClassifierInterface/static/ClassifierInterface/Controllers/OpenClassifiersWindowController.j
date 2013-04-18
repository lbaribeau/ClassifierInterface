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
    console.log("Setting close function to button");
    console.log("Is the close function in my scope?");
    //console.log(closeWindow);  // Unknown class / uninitialized variable
    console.log("Calling close window from 'tieCancelButtonToCloseFunction'");
    //[self closeWindow];  // This call works if closeWindow doesn't have an argument
    //closeWindow;  //can't resolve closeWindow
    console.log("How do I give the button the method???")
    //console.log(@selector(self:closeWindow:));  //syntax works if there are no arguments
    //[cancelButton setAction:@selector(self:closeWindow:)];  //syntax passes but doesn't work
    //[cancelButton setAction:@selector(closeWindow:)];  //can't resolve closeWindow
    [cancelButton setAction:@selector(closeWindow:)];
    [cancelButton setTarget:self];
        // This makes it work!  So self receives the message specified by the action, whatever that means.
    console.log("Is it in scope?");
    console.log(@selector(closeWindow:));
    //[closeWindow];  //undefined

    console.log("Button:");
    console.log(cancelButton);
}
- (@action)closeWindow:(id)aSender  // Do I need a sender argument?
{
    console.log("Cancel button was pressed.");
    [openClassifiersWindow close];
}

- (void)debugPrintWindow
{
    console.log("Maybe I get it after init!:");
    console.log(openClassifiersWindow);
}
- (void)helloWorld
{
    console.log("Hello World!");
}
@end

