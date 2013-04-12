from django.conf.urls import patterns, include, url
from django.contrib import admin
admin.autodiscover()
from rest_framework.urlpatterns import format_suffix_patterns
#from ClassifierInterface.views import ClassifierList, ClassifierDetail

urlpatterns = []
 
urlpatterns += patterns('',
    url(r'^admin/', include(admin.site.urls)),
)
 
urlpatterns += format_suffix_patterns(
    patterns('ClassifierInterface.views',
        url(r'^browse/$', 'api_root'),
#        url(r'^classifiers/$', ClassifierList.as_view(), name="classifier-list"),
#        url(r'^classifier/(?P<pk>[0-9]+)/$', ClassifierDetail.as_view(), name="classifier-detail"),
        url(r'^$', 'home'),
        url(r'^interface/$', "interface")
    )
)
