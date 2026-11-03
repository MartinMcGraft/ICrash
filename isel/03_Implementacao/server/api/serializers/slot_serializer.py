from rest_framework.serializers import ModelSerializer

from api.models import SlotModel

 
class SlotSerializer(ModelSerializer):
    """
    Converts the type of data, to create, update and delete from the system
    database an Slot.
    """
    class Meta:
        """
        Define the model type, and the fields.
        """
        model = SlotModel
        fields = '__all__'
        
    def update(self, instance, validated_data):
        """
        Updates the instance with the validated_data received.

        Args:
            instance (SlotModel): The instance.
            validated_data (dict): A dictionary with the data.

        Returns:
            SlotModel: The model updated.
        """
        # Update the shape of the Slot:
        instance.s_adj_hor = validated_data.get(
            's_adj_hor', instance.s_adj_hor
        )
        instance.s_adj_ver = validated_data.get(
            's_adj_ver', instance.s_adj_ver
        )
        
        # Update the informaion of a product:
        instance.name_prod = validated_data.get(
            'name_prod', instance.name_prod
        )
        instance.vol_weight = validated_data.get(
            'vol_weight', instance.vol_weight
        )
        instance.application = validated_data.get(
            'application', instance.application
        )
        instance.max_quant = validated_data.get(
            'max_quant', instance.max_quant
        )
        
        # Update validation date:
        instance.valid_date = validated_data.get(
            'valid_date', instance.valid_date
        )
        
        # Update qr code image:
        instance.qr_code_img = validated_data.get(
            'qr_code_img', instance.qr_code_img
        )
        
        instance.save()
        return instance