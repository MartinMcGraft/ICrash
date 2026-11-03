from rest_framework.serializers import ModelSerializer

from api.models import CrashCartModel

 
class CrashCartSerializer(ModelSerializer):
    """
    Converts the type of data, to create, update and delete from the system
    database an CrashCart.
    """
    class Meta:
        """
        Define the model type, and the fields.
        """
        model = CrashCartModel
        fields = '__all__'
        
    def update(self, instance, validated_data):
        """
        Updates the instance with the validated_data received.

        Args:
            instance (CrashCartModel): The instance.
            validated_data (dict): A dictionary with the data.

        Returns:
            CrashCartModel: The model updated.
        """
        instance.qr_code_img = validated_data.get(
            'qr_code_img', instance.qr_code_img
        )
        
        instance.save()
        return instance