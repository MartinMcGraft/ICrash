from rest_framework.decorators import api_view
from rest_framework.response import Response

from api.models import DrawerModel
from api.serializers.drawer_serializer import DrawerSerializer


@api_view(['GET'])
def getDrawers(request, pkI, pkC):
    drawers = DrawerModel.objects.filter(institution_id=pkI, crashcart_id=pkC)
    serializer = DrawerSerializer(drawers, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def getNumDrawers(request, pkI, pkC):
    drawers = DrawerModel.objects.filter(institution_id=pkI, crashcart_id=pkC)
    return Response(drawers.count())

@api_view(['GET'])
def getDrawer(request, pkI, pkC, pkD):
    drawer = DrawerModel.objects.get(institution_id=pkI, crashcart_id=pkC, id_d=pkD)
    serializer = DrawerSerializer(drawer, many=False)
    return Response(serializer.data)

@api_view(['GET'])
def getDrawerID(request, pkI, pkC, name):
    drawer = DrawerModel.objects.get(institution_id=pkI, crashcart_id=pkC, name=name)
    return Response(drawer.id_d)

@api_view(['POST'])
def createDrawers(request, pkI, pkC):
    num = 0
    numD = request.data['numD']
    
    drawers = DrawerModel.objects.filter(institution_id=pkI, crashcart_id=pkC)
    serializer = DrawerSerializer(drawers, many=True)
    saved_data = serializer.data
    
    if len(saved_data) != 0:
        last_d = saved_data[-1]['name']
        num = int(last_d.split('Drawer')[1])
    
    for q in range(int(numD)):
        q += 1
        name = 'Drawer' + str(q + num)
        qr_code_str = pkI + '/' + pkC + '/' + str(q + num)
        drawer_data = {
            "name": name,
            "qr_code_str": qr_code_str,
            "institution_id": pkI,
            "crashcart_id": pkC
        }
        drawer = DrawerModel.objects.create(**drawer_data)
        serializer = DrawerSerializer(drawer, many=False)
    
    return Response(serializer.data)
 
@api_view(['PUT'])
def updateDrawer(request, pkI, pkC, pkD):
    drawer = DrawerModel.objects.get(institution_id=pkI, crashcart_id=pkC, id_d=pkD)
    
    serializer = DrawerSerializer(drawer, data=request.data, partial=True)
    
    if serializer.is_valid():
        # Update the shape of the Drawer:
        n_lins = request.data.get('n_lins')
        n_cols = request.data.get('n_cols')
        serializer.update(drawer, {'n_lins': n_lins})
        serializer.update(drawer, {'n_cols': n_cols})
        
        # Update qr code image:
        qr_code_img = request.data.get('qr_code_img')
        serializer.update(drawer, {'qr_code_img': qr_code_img})
        
        serializer.save()
    return Response(serializer.data)
    
@api_view(['DELETE'])
def deleteDrawer(request, pkI, pkC, pkD):
    drawer = DrawerModel.objects.get(institution_id=pkI, crashcart_id=pkC, id_d=pkD)
    drawer.delete()
    return Response("Delete successfull")