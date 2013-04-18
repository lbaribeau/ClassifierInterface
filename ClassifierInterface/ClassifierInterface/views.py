
from rest_framework import generics
from rest_framework import permissions
from django.shortcuts import render
from ClassifierInterface.models import Classifier
from ClassifierInterface.serializers import ClassifierSerializer


def home(request):
    context = {}
    return render(request, 'index.html', context)


class ClassifierList(generics.ListCreateAPIView):
    model = Classifier
    permission_classes = (permissions.IsAuthenticatedOrReadOnly,)  # TODO: Delete this
    serializer_class = ClassifierSerializer


class ClassifierDetail(generics.RetrieveUpdateDestroyAPIView):
    model = Classifier
    permission_classes = (permissions.IsAuthenticatedOrReadOnly,)  # TODO: Delete this
    serializer_class = ClassifierSerializer
