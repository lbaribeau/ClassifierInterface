from rest_framework import generics
from rest_framework import permissions
from django.shortcuts import render
from django.views.decorators.csrf import ensure_csrf_cookie

from ClassifierInterface.models import Classifier
from ClassifierInterface.serializers import ClassifierSerializer, ClassifierListSerializer

#import ast


@ensure_csrf_cookie
def home(request):
    context = {}
    return render(request, 'index.html', context)


class ClassifierList(generics.ListCreateAPIView):
    model = Classifier
    permission_classes = (permissions.AllowAny,)  # TODO: change
    serializer_class = ClassifierListSerializer


class ClassifierDetail(generics.RetrieveUpdateDestroyAPIView):
    model = Classifier
    permission_classes = (permissions.AllowAny,)  # TODO: change
    serializer_class = ClassifierSerializer

    def patch(self, request, pk, *args, **kwargs):
        kwargs['partial'] = True
        glyphs = request.DATA.get('glyphs', None)
        if glyphs:
            self.get_object().write_xml(glyphs)

        return self.update(request, *args, **kwargs)
