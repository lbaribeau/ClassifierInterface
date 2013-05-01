from rest_framework import generics
from rest_framework import permissions
from django.dispatch import receiver
from django.db.models.signals import post_save
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

    # def post(self, request, *args, **kwargs):
    #     response = self.create(request, *args, **kwargs)

    #     # self.create is the regular django rest task for creating the model,
    #     # but in addition to the database we must maintain the XML
    #     # See how self.object gets defined in CreateModelMixin
    #     self.object.new_xml()

    #     return response


@receiver(post_save, sender=Classifier)
def create_xml(sender, instance=None, created=False, **kwargs):
    if created:
        instance._create_new_xml()


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
