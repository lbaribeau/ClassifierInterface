@import "../Models/Classifier.j"

@implementation ClassifierController : CPObject
{
    @outlet CPArrayController classifierArrayController;
    @outlet LoadClassifierNamesDelegate loadClassifierNamesDelegate;
}

- (void)fetchClassifiers
{
    console.log("Fetching names");
    console.log(classifierArrayController);
    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:'/classifiers/'
                    delegate:loadClassifierNamesDelegate
                    message:"Loading classifier from home"];
}
@end


@implementation LoadClassifierNamesDelegate : CPObject
{
    @outlet CPArrayController   classifierArrayController;
}

- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    var classifiers = [Classifier objectsFromJson:[anAction result]];
    [classifierArrayController addObjects:classifiers];
}
@end
