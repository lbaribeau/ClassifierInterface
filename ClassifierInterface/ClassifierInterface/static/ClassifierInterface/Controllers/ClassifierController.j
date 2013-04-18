@import "../Models/Classifier.j"

@implementation ClassifierController : CPObject
{
    @outlet LoadClassifiersDelegate loadClassifiersDelegate;
}

- (void)fetchClassifiers
{
    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:'/classifiers/'
                    delegate:loadClassifiersDelegate
                    message:"Loading classifier from home"];
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
