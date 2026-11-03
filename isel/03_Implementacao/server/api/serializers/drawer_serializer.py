from rest_framework.serializers import ModelSerializer

from api.models import DrawerModel

 
class DrawerSerializer(ModelSerializer):
    """
    Converts the type of data, to create, update and delete from the system
    database an Drawer.
    """
    class Meta:
        """
        Define the model type, and the fields.
        """
        model = DrawerModel
        fields = '__all__'
        
    def update(self, instance, validated_data):
        """
        Updates the instance with the validated_data received.

        Args:
            instance (DrawerModel): The instance.
            validated_data (dict): A dictionary with the data.

        Returns:
            DrawerModel: The model updated.
        """
        # Update the shape of the Drawer:
        instance.n_lins = validated_data.get('n_lins', instance.n_lins)
        instance.n_cols = validated_data.get('n_cols', instance.n_cols)
        
        # Update qr code image:
        instance.qr_code_img = validated_data.get(
            'qr_code_img', instance.qr_code_img
        )
        
        instance.save()
        return instance