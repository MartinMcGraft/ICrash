from rest_framework.decorators import api_view
from rest_framework.response import Response

from api.models import CrashCartModel
from api.serializers.crash_cart_serializer import CrashCartSerializer


@api_view(['GET'])
def getCrashCarts(request, pkI):
    crash_carts = CrashCartModel.objects.filter(institution_id=pkI)
    serializer = CrashCartSerializer(crash_carts, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def getCrashCart(request, pkI, pkC):
    crash_cart = CrashCartModel.objects.get(institution_id=pkI, id_c=pkC)
    serializer = CrashCartSerializer(crash_cart, many=False)
    return Response(serializer.data)

@api_view(['GET'])
def getCrashCartID(request, pkI, name):
    crash_cart = CrashCartModel.objects.get(institution_id=pkI, name=name)
    return Response(crash_cart.id_c)

@api_view(['POST'])
def createCrashCarts(request, pkI):
    num = 0
    numCC = request.data['numCC']
     
    crash_carts = CrashCartModel.objects.filter(institution_id=pkI)
    serializer = CrashCartSerializer(crash_carts, many=True)
    saved_data = serializer.data
    
    if len(saved_data) != 0:
        last_cc = saved_data[-1]['name']
        num = int(last_cc.split('CrashCart')[1])
    
    for q in range(int(numCC)):
        q += 1
        name = 'CrashCart' + str(q + num)
        qr_code_str = pkI + "/" + str(q + num)
        crash_cart_data = {
            "name": name,
            "qr_code_str": qr_code_str,
            "institution_id": pkI
        }
        crash_cart = CrashCartModel.objects.create(**crash_cart_data)
        serializer = CrashCartSerializer(crash_cart, many=False)
    
    return Response(serializer.data)
 
@api_view(['PUT'])
def updateCrashCart(request, pkI, pkC):
    crash_cart = CrashCartModel.objects.get(institution_id=pkI, id_c=pkC)
    
    serializer = CrashCartSerializer(
        crash_cart, data=request.data, partial=True
    )
    
    if serializer.is_valid():
        qr_code_img = request.data.get('qr_code_img')
        serializer.update(crash_cart, {'qr_code_img': qr_code_img})
        
        serializer.save()
    return Response(serializer.data)

    
@api_view(['DELETE'])
def deleteCrashCart(request, pkI, pkC):
    crash_cart = CrashCartModel.objects.get(institution_id=pkI, id_c=pkC)
    crash_cart.delete()
    return Response("Delete successfull")