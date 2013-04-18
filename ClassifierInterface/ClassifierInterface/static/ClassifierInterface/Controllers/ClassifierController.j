@import "../Models/Classifier.j"

@implementation ClassifierController : CPObject
{
    @outlet ClassifierDelegate classifierDelegate;
}

- (void)fetchClassifiers
{
    [WLRemoteAction schedule:WLRemoteActionGetType
                    path:'/classifiers/'
                    delegate:classifierDelegate
                    message:"Loading classifier from home"];
}
@end


@implementation ClassifierDelegate : CPObject
{
    @outlet CPArrayController   classifierArrayController;
}

- (void)remoteActionDidFinish:(WLRemoteAction)anAction
{
    var classifiers = [Classifier objectsFromJson:[anAction result]];
    [classifierArrayController addObjects:classifiers];
}
@end
