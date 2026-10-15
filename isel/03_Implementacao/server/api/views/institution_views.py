from rest_framework.decorators import api_view
from rest_framework.response import Response

from api.models import InstitutionModel
from api.serializers.institution_serializer import InstitutionSerializer

#_______________________________________________________________________________
@api_view(['GET'])
def getInstitutions(request):
    """_summary_

    Args:
        request (htttp_method_name): Name of the http method.

    Returns:
        Response: _description_
    """
    institutions = InstitutionModel.objects.all()
    serializer = InstitutionSerializer(institutions, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def getInstitution(request, pkI):
    """_summary_

    Args:
        request (http_method_name): Name of the http method.
        pkI (str): Unique identifier of an Institution (primary key in database
        system).

    Returns:
        Response: _description_
    """
    institution = InstitutionModel.objects.get(id_i=pkI)
    serializer = InstitutionSerializer(institution, many=False)
    return Response(serializer.data)

@api_view(['GET'])
def getInstitutionID(request, name):
    """_summary_

    Args:
        request (http_method_name): Name of the http method.
        name (str): Name of the Institution.

    Returns:
        Response: _description_
    """
    institution = InstitutionModel.objects.get(name=name)
    return Response(institution.id_i)        

@api_view(['POST'])
def createInstitution(request):
    """_summary_

    Args:
        request (http_method_name): Name of the http method.

    Returns:
        Response: _description_
    """
    data = request.data
    
    institution_data = {
        'name': data['name']
    }
    
    if 'description' in data:
        institution_data['description'] = data['description']
        
    institution = InstitutionModel.objects.create(**institution_data)
    serializer = InstitutionSerializer(institution, many=False)
    
    return Response(serializer.data)
 
@api_view(['PUT'])
def updateInstitution(request, pkI):
    """_summary_

    Args:
        request (http_method_name): Name of the http method.
        pkI (str): Unique identifier of an Institution (primary key in database
        system).

    Returns:
        Response: _description_
    """
    institution = InstitutionModel.objects.get(id_i=pkI)

    serializer = InstitutionSerializer(
        institution, data=request.data, partial=True
    )
    
    if serializer.is_valid():
        name = request.data.get('name')
        if name:
            serializer.update(institution, {'name': name})
        
        description = request.data.get('description')
        serializer.update(institution, {'description': description})
        
        serializer.save()
    return Response(serializer.data)
    
@api_view(['DELETE'])
def deleteInstitution(request, pkI):
    """_summary_

    Args:
        request (http_method_name): Name of the http method.
        pkI (str): Unique identifier of an Institution (primary key in database
        system).

    Returns:
        Response: _description_
    """
    institution = InstitutionModel.objects.get(id_i=pkI)
    institution.delete()
    return Response("Delete successfull")