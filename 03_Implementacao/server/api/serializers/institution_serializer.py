from rest_framework.serializers import ModelSerializer

from api.models import InstitutionModel


class InstitutionSerializer(ModelSerializer):
    """
    Converts the type of data, to create, update and delete from the system
    database an Institution.
    """
    class Meta:
        """
        Define the model type, and the fields.
        """
        model = InstitutionModel
        fields = '__all__'

    def update(self, instance, validated_data):
        """
        Updates the instance with the validated_data received.

        Args:
            instance (InstitutionModel): The instance.
            validated_data (dict): A dictionary with the data.

        Returns:
            InstitutionModel: The model updated.
        """
        instance.name = validated_data.get('name', instance.name)
        instance.description = validated_data.get(
            'description', instance.description
        )
        instance.save()
        return instance
        