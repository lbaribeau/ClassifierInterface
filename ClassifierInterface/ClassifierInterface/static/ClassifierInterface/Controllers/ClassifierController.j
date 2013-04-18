@import "../Models/Classifier.j"

@implementation ClassifierController : CPObject
{
    @outlet LoadClassifiersDelegate loadClassifiersDelegate;
    @outlet CPWindow OpenClassifiersWindow;
}

- (void)fetchClassifiers
{
    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:'/classifiers/'
                    delegate:loadClassifiersDelegate
                    message:"Loading classifier from home"];
}
- (void)debugPrintWindow
{
    console.log("Well the controller has the window:");
    console.log(OpenClassifiersWindow);
}
@end


@implementation LoadClassifiersDelegate : CPObject
{
    @outlet CPArrayController classifierArrayController;
}

- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    var classifiers = [Classifier objectsFromJson:[anAction result]];
    [classifierArrayController addObjects:classifiers];
}
@end
