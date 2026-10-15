from django.db import models
from django.core.validators import MinValueValidator


"""
Django does not suport composite primary keys. Because of this, it is not
possible to have crash carts from different institutions with the same id_c, if
this id_c is the primary key.
To solve the problem, the primary key (id) is automatically generated and
incremented, and the column id_c is a simple integer controlled by us to have
the properties we want.
This is applied to the drawer and slot models for the id_d and id_s.
The Meta class is used to make them unique when they have to be.
https://www.crunchydata.com/blog/composite-primary-keys-postgresql-and-django
"""
class InstitutionModel(models.Model):
    """
    Model of the Institution table in the data base.

    Args:
        id_i (AutoField): The primary key field for the Institution.
        name (CharField): The name of the Institution.
        description (TextField): The description of the Institution.
    """
    id_i = models.AutoField(primary_key=True)
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(null=True)
    
    def __str__(self) -> str:
        """
        Returns a string representation of the Institution.

        Returns:
            str: The name of the Institution.
        """
        return self.name

class CrashCartModel(models.Model):
    """
    Model of the CrashCart table in the database.

    Args:
        institution (ForeignKey): The ID of the Institution. Foreign key
        relation to the Institutiton model.
        id_c (IntegerField): Identifies the CrashCart.
        name (CharField): The name of the CrashCart.
        qr_code_str (CharField): The QR code string of the CrashCart.
        qr_code_img (BinaryField): The binary representation of the QR code
        image of the CrashCart.
    """
    institution = models.ForeignKey('InstitutionModel', on_delete=models.CASCADE)
    id_c = models.IntegerField()
    name = models.CharField(max_length=20)
    qr_code_str = models.CharField(max_length=20, unique=True)
    qr_code_img = models.BinaryField(unique=True, null=True)
    
    def save(self, *args, **kwargs):
        """
        To control the increment of the id_c of a CrashCart depending on the
        Institution. This away there can be multiple CrashCarts with the same
        id_c, but differente id_i's.
        """
        if not self.pk:  # Only executed on creation, not on updates
            existing_crash_carts = CrashCartModel.objects.filter(
                institution=self.institution
            )
            if existing_crash_carts.exists():
                last_crash_cart = existing_crash_carts.order_by('-id_c').first()
                self.id_c = last_crash_cart.id_c + 1
            else:
                self.id_c = 1
        super().save(*args, **kwargs)
    
    def __str__(self) -> str:
        """
        Returns a string representation of the CrashCart.

        Returns:
            str: The name of the CrashCart.
        """
        return self.name
    
    class Meta:
        """
        Define the context where name and id_c are unique.
        """
        unique_together = (('institution', 'name'))
        unique_together = (('institution', 'id_c'))

class DrawerModel(models.Model):
    """
    Model of the Drawer table in the database.
    
    Each Drawer object has a grid, composed by a collection of Slots. The size
    of the grid is defined by the number of lines and columns. The ammount of
    Slots a Drawer has, needs to be lesser than or equal to: n_lins * n_cols.

    Args:
        institution (ForeignKey): The ID of the Institution. Foreign key
        relation to the Institutiton model.
        crashcart (ForeignKey): The ID of the CrashCart. Foreign key relation to
        the CrashCart model.
        id_d (IntegerField): Indentifies the Drawer.
        name (CharField): The name of the Drawer.
        n_lins (IntegerField): Number of lines of the grid.
        n_cols (IntegerField): Number of columns of the grid.
        qr_code_str (CharField): The QR code string of the CrashCart.
        qr_code_img (BinaryField): The binary representation of the QR code
        image of the CrashCart.
    """
    institution = models.ForeignKey('InstitutionModel', on_delete=models.CASCADE)
    crashcart = models.ForeignKey('CrashCartModel', on_delete=models.CASCADE)
    id_d = models.IntegerField()
    name = models.CharField(max_length=20)
    n_lins = models.IntegerField(validators=[MinValueValidator(1)], null=True)
    n_cols = models.IntegerField(validators=[MinValueValidator(1)], null=True)
    qr_code_str = models.CharField(max_length=20, unique=True)
    qr_code_img = models.BinaryField(unique=True, null=True)
    
    def save(self, *args, **kwargs):
        """
        To control the increment of the id_d of a Drawer depending on the
        CrashCart. This away there can be multiple Drawers with the same
        id_d, but differente id_c's.
        """
        if not self.pk:  # Only execute on creation, not on updates
            existing_drawers = DrawerModel.objects.filter(
                institution=self.institution, crashcart=self.crashcart
            )
            if existing_drawers.exists():
                last_drawer = existing_drawers.order_by('-id_d').first()
                self.id_d = last_drawer.id_d + 1
            else:
                self.id_d = 1
        super().save(*args, **kwargs)
    
    def __str__(self) -> str:
        """
        Returns a string representation of the Drawer.

        Returns:
            str: The name of the Drawer.
        """
        return self.name
    
    class Meta:
        """
        Define the context where name and id_d are unique.
        """
        unique_together = (('institution', 'crashcart', 'name'))
        unique_together = (('institution', 'crashcart', 'id_d'))

class SlotModel(models.Model):
    """
    Model of the Slot table in the database.

    Args:
        institution (ForeignKey): The ID of the Institution. Foreign key
        relation to the Institutiton model.
        crashcart (ForeignKey): The ID of the CrashCart. Foreign key relation to
        the CrashCart model.
        drawer (ForeignKey): The ID of the Drawer. Foreign key relation to the
        Drawer model.
        id_s (IntegerField): Identifies the Slot.
        name (CharField): The name of the Slot.
        s_adj_hor (IntegerField): Number of Slots adjancent horizontaly
        (default=1, has to be >=1).
        s_adj_ver (IntegerField): Number of Slots adjancent verticaly
        (default=1, has to be >=1).
        name_prod (CharField): The name of the product.
        vol_weight (CharField): Volume and weight of the product.
        application (CharField): Form of application.
        max_quant (IntegerField): The maximum quantity of the product allowed
        in the Slot.
        valid_date (DateField): The earliest to expire valid date of the product
        in the Slot.
        qr_code_str (CharField): The QR code string of the Slot.
        qr_code_img (BinaryField): The binary representation of the QR code
        image of the Slot.
    """
    institution = models.ForeignKey('InstitutionModel', on_delete=models.CASCADE)
    crashcart = models.ForeignKey('CrashCartModel', on_delete=models.CASCADE)
    drawer = models.ForeignKey('DrawerModel', on_delete=models.CASCADE)
    id_s = models.IntegerField()
    name = models.CharField(max_length=20)
    s_adj_hor = models.IntegerField(validators=[MinValueValidator(1)])
    s_adj_ver = models.IntegerField(validators=[MinValueValidator(1)])
    name_prod = models.CharField(max_length=50)
    vol_weight = models.CharField(max_length=50)
    application = models.CharField(max_length=100, null=True)
    max_quant = models.IntegerField(validators=[MinValueValidator(1)])
    valid_date = models.DateField(null=True)
    qr_code_str = models.CharField(max_length=20)
    qr_code_img = models.BinaryField(unique=True, null=True)
    
    def save(self, *args, **kwargs):
        """
        To control the increment of the id_s of a Slot depending on the
        Drawer. This away there can be multiple Slots with the same
        id_s, but differente id_d's.
        """
        if not self.pk:  # Only execute on creation, not on updates
            existing_slots = SlotModel.objects.filter(
                institution=self.institution,
                crashcart=self.crashcart,
                drawer=self.drawer
            )
            
            if existing_slots.exists():
                last_slot = existing_slots.order_by('-id_s').first()
                self.id_s = last_slot.id_s + 1
            else:
                self.id_s = 1
        super().save(*args, **kwargs)
    
    class Meta:
        """
        Define the context where name and id_s are unique.
        """
        unique_together = (('institution', 'crashcart', 'drawer', 'name'))
        unique_together = (('institution', 'crashcart', 'drawer', 'id_s'))