from django.urls import path
from api.views import institution_views as iv
from api.views import crash_cart_views as cv
from api.views import drawer_views as dv
from api.views import slot_views as sv

# Paths:
institutionPath = 'institution/'
crashcartPath   = institutionPath + '<str:pkI>/crashcart/'
drawerPath      = crashcartPath + '<str:pkC>/drawer/'
slotPath        = drawerPath + '<str:pkD>/slot/'

# URL configuration module.
urlpatterns = [
    # Institution table:
    path('institutions/', iv.getInstitutions),
    path(institutionPath + 'create/', iv.createInstitution),
    path(institutionPath + '<str:pkI>/', iv.getInstitution),
    path(institutionPath + '<str:pkI>/update/', iv.updateInstitution),
    path(institutionPath + '<str:pkI>/delete/', iv.deleteInstitution),
    path(institutionPath + 'name/<str:name>/', iv.getInstitutionID),
    # Crash Cart table:
    path(institutionPath + '<str:pkI>/crashcarts/', cv.getCrashCarts),
    path(crashcartPath + 'create/', cv.createCrashCarts),
    path(crashcartPath + '<str:pkC>/', cv.getCrashCart),
    path(crashcartPath + '<str:pkC>/update/', cv.updateCrashCart),
    path(crashcartPath + '<str:pkC>/delete/', cv.deleteCrashCart),
    path(crashcartPath + 'name/<str:name>/', cv.getCrashCartID),
    # Drawer table:
    path(crashcartPath + '<str:pkC>/drawers/', dv.getDrawers),
    path(crashcartPath + '<str:pkC>/drawers/count/', dv.getNumDrawers),
    path(drawerPath + 'create/', dv.createDrawers),
    path(drawerPath + '<str:pkD>/', dv.getDrawer),
    path(drawerPath + '<str:pkD>/update/', dv.updateDrawer),
    path(drawerPath + '<str:pkD>/delete/', dv.deleteDrawer),
    path(drawerPath + 'name/<str:name>/', dv.getDrawerID),
    # Slot table:
    path(drawerPath + '<str:pkD>/slots/', sv.getSlots),
    path(drawerPath + '<str:pkD>/slots/info/', sv.getSlotsInfo),
    path(slotPath + 'create/', sv.createSlot),
    path(slotPath + '<str:pkS>/', sv.getSlot),
    path(slotPath + '<str:pkS>/update/', sv.updateSlot),
    path(slotPath + '<str:pkS>/delete/', sv.deleteSlot),
    path(slotPath + 'name/<str:name>/', sv.getSlotID)
]