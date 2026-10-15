from rest_framework.decorators import api_view
from rest_framework.response import Response

from api.models import SlotModel, DrawerModel
from api.serializers.slot_serializer import SlotSerializer


@api_view(['GET'])
def getSlots(request, pkI, pkC, pkD):
    slots = SlotModel.objects.filter(institution_id=pkI, crashcart_id=pkC, drawer_id=pkD)
    serializer = SlotSerializer(slots, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def getSlotsInfo(request, pkI, pkC, pkD):
    slots = SlotModel.objects.filter(institution_id=pkI, crashcart_id=pkC, drawer_id=pkD).values(
        'name',
        's_adj_hor',
        's_adj_ver',
        'name_prod',
        'application',
        'vol_weight',
        'max_quant'
    )
    return Response(slots)

@api_view(['GET'])
def getSlot(request, pkI, pkC, pkD, pkS):
    slots = SlotModel.objects.get(institution_id=pkI, crashcart_id=pkC, drawer_id=pkD, id_s=pkS)
    serializer = SlotSerializer(slots, many=False)
    return Response(serializer.data)

@api_view(['GET'])
def getSlotID(request, pkI, pkC, pkD, name):
    slot = SlotModel.objects.get(institution_id=pkI, crashcart_id=pkC, drawer_id=pkD, name=name)
    return Response(slot.id_s)

@api_view(['POST'])
def createSlot(request, pkI, pkC, pkD):
    drawer = DrawerModel.objects.get(institution_id=pkI, crashcart_id=pkC, id_d=pkD)
    max_slots = drawer.n_lins * drawer.n_cols
    
    slots = SlotModel.objects.filter(institution_id=pkI, crashcart_id=pkC, drawer_id=pkD)
    num_slots = slots.count()
    
    if not num_slots >= max_slots:
        #TODO
        #Need to check accourding to the s_adj_hor and s_adj_ver
        #verify in the sum of s_adj_hor is less or equal than n_cols for every line
        #do the same for every line for every column
        
        data = request.data
        serializer = SlotSerializer(slots, many=True)
        saved_data = serializer.data
        
        num = 0
        if len(saved_data) != 0:
            last_d = saved_data[-1]['name']
            num = int(last_d.split('Slot')[1])
            
        slot_data = {
            "name": 'Slot' + str(num + 1),
            "qr_code_str": pkI + '/' + pkC + '/' + pkD + '/' + str(num + 1),
            "institution_id": pkI,
            "crashcart_id": pkC,
            "drawer_id": pkD
        }
        
        slot_data["s_adj_hor"] = data["s_adj_hor"]
        slot_data["s_adj_ver"] = data["s_adj_ver"]
        slot_data["name_prod"] = data["name_prod"]
        slot_data["vol_weight"] = data["vol_weight"]
        slot_data["max_quant"] = data["max_quant"]
        
        if 'application' in data:
            slot_data["application"] = data["application"]
            
        if 'valid_date' in data:
            slot_data["valid_date"] = data["valid_date"]
        
        slot = SlotModel.objects.create(**slot_data)
        serializer = SlotSerializer(slot, many=False)
        
        return Response(serializer.data)
    return Response(f"A drawer can have a maximum of {max_slots} slots.")
 
@api_view(['PUT'])
def updateSlot(request, pkI, pkC, pkD, pkS):
    slot = SlotModel.objects.get(institution_id=pkI, crashcart_id=pkC, drawer_id=pkD, id_s=pkS)
    
    serializer = SlotSerializer(slot, data=request.data, partial=True)
    
    if serializer.is_valid():
        # Update the shape of the Slot:
        s_adj_hor = request.data.get('s_adj_hor')
        s_adj_ver = request.data.get('s_adj_ver')
        if s_adj_hor:
            serializer.update(slot, {'s_adj_hor': s_adj_hor})
        if s_adj_ver:
            serializer.update(slot, {'s_adj_ver': s_adj_ver})
        
        # Update the informaion of a product:
        name_prod = request.data.get('name_prod')
        vol_weight = request.data.get('vol_weight')
        max_quant = request.data.get('max_quant')
        application = request.data.get('application')
        if name_prod:
            serializer.update(slot, {'name_prod': name_prod})
        if vol_weight:
            serializer.update(slot, {'vol_weight': vol_weight})
        if max_quant:
            serializer.update(slot, {'max_quant': max_quant})
        serializer.update(slot, {'application': application})
        
        # Update validation date:
        valid_date = request.data.get('valid_date')
        serializer.update(slot, {'valid_date': valid_date})
        
        # Update qr code image:
        qr_code_img = request.data.get('qr_code_img')
        serializer.update(slot, {'qr_code_img': qr_code_img})
        
        serializer.save()
    return Response(serializer.data)

@api_view(['DELETE'])
def deleteSlot(request, pkI, pkC, pkD, pkS):
    slot = SlotModel.objects.get(institution_id=pkI, crashcart_id=pkC, drawer_id=pkD, id_s=pkS)
    slot.delete()
    return Response("Delete successfull")