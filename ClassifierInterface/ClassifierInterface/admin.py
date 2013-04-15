from django.contrib import admin
from ClassifierInterface.models import Classifier


class ClassifierAdmin(admin.ModelAdmin):
    list_display = ('name', )


admin.site.register(Classifier, ClassifierAdmin)