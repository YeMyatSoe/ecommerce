# products/models.py

from django.db import models
from django.contrib.auth.models import User, Group
from django.db.models.signals import post_save
from django.dispatch import receiver

class Shop(models.Model):
    name = models.CharField(max_length=255, unique=True)
    address = models.TextField()
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='owned_shops')  # Shop owner
    contact_email = models.EmailField()
    contact_phone = models.CharField(max_length=20)

    def __str__(self):
        return self.name
class Role(models.Model):
    shop = models.ForeignKey(Shop, on_delete=models.CASCADE, related_name='shop_roles')
    name = models.CharField(max_length=50)
    description = models.TextField(blank=True)
    # This links the role to a Django Group for managing permissions.
    permissions_group = models.OneToOneField(Group, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        unique_together = ('shop', 'name')

    def __str__(self):
        return f"{self.name} ({self.shop.name})"

class Employee(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='employee_profile')
    shop = models.ForeignKey(Shop, on_delete=models.CASCADE, related_name='employees')
    # The role is now defined by the Role model.
    role = models.ForeignKey(Role, on_delete=models.SET_NULL, null=True, blank=True)
    position = models.CharField(max_length=100)  # Keep this for a specific job title
    phone = models.CharField(max_length=20, blank=True, null=True)
    date_joined = models.DateField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.role.name} @ {self.shop.name}" if self.role else f"{self.user.get_full_name()} - No Role @ {self.shop.name}"
# Category Model
class Category(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField()

    def __str__(self):
        return self.name

# Brand Model
class Brand(models.Model):
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='brands', null=True)
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField()

    def __str__(self):
        return self.name

# DeviceModel Model
class DeviceModel(models.Model):
    name = models.CharField(max_length=100, unique=True)
    brand = models.ForeignKey(Brand, related_name='device_models', on_delete=models.CASCADE)

    def __str__(self):
        return self.name
    
class Color(models.Model):
    color_name = models.CharField(max_length=100)
    color_code = models.CharField(max_length=7)  # Store hex color code (e.g., #FF5733)

    def __str__(self):
        return self.color_name
# models.py
class Size(models.Model):
    name = models.CharField(max_length=50, unique=True)  # e.g., S, M, L, XL

    def __str__(self):
        return self.name
class Product(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    make_by = models.CharField(max_length=100)
    color = models.ManyToManyField('Color', related_name='products')
    rating = models.DecimalField(max_digits=2, decimal_places=1)
    discount = models.DecimalField(max_digits=5, decimal_places=2)
    stock = models.IntegerField()
    image1 = models.ImageField(upload_to='products/images/', null=True, blank=True)
    image2 = models.ImageField(upload_to='products/images/', null=True, blank=True)
    image3 = models.ImageField(upload_to='products/images/', null=True, blank=True)
    category = models.ForeignKey('Category', related_name='products', on_delete=models.SET_NULL, null=True, blank=True)
    brand = models.ForeignKey('Brand', related_name='products', on_delete=models.SET_NULL, null=True, blank=True)
    device_model = models.ForeignKey('DeviceModel', related_name='products', on_delete=models.SET_NULL, null=True, blank=True)

    # 👇 Add this field
    created_by_shop = models.ForeignKey('Shop', on_delete=models.SET_NULL, null=True, blank=True, related_name='created_products')

    def __str__(self):
        return self.name

from django.db import models

class ProductColorImage(models.Model):
    product = models.ForeignKey(Product, related_name="color_images", on_delete=models.CASCADE)
    color = models.ForeignKey(Color, related_name="product_images", on_delete=models.CASCADE)
    image = models.ImageField(upload_to="product_colors/", blank=True, null=True)
    
    # Optional: color-level stock (auto-calculated from sizes)
    stock = models.PositiveIntegerField(default=0, editable=False)  # make read-only

    class Meta:
        unique_together = ("product", "color")  # Avoid duplicate color entries per product

    def __str__(self):
        return f"{self.product.name} - {self.color.color_name} (Stock: {self.stock})"

    # Auto-calculate color stock from all size stocks
    def update_stock(self):
        total = sum(size.stock for size in self.sizes.all())
        self.stock = total
        self.save()
class ProductColorSize(models.Model):
    product_color_image = models.ForeignKey(
        ProductColorImage,
        on_delete=models.CASCADE,
        related_name='sizes'
    )
    size = models.ForeignKey(Size, on_delete=models.CASCADE)
    stock = models.PositiveIntegerField(default=0)

    class Meta:
        unique_together = ('product_color_image', 'size')  # prevent duplicates

    def __str__(self):
        return f"{self.product_color_image.product.name} - {self.product_color_image.color.color_name} - {self.size.name} (Stock: {self.stock})"

class ShopInventory(models.Model):
    shop = models.ForeignKey('Shop', on_delete=models.CASCADE, related_name='inventories')
    product = models.ForeignKey('Product', on_delete=models.CASCADE, related_name='inventories')

    # Overrides
    custom_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    custom_discount = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    custom_stock = models.IntegerField(null=True, blank=True)

    available = models.BooleanField(default=True)

    class Meta:
        unique_together = ('shop', 'product')

    def __str__(self):
        return f"{self.product.name} in {self.shop.name}"

    def get_price(self):
        return self.custom_price if self.custom_price is not None else self.product.price

    def get_discount(self):
        return self.custom_discount if self.custom_discount is not None else self.product.discount

    def get_stock(self):
        return self.custom_stock if self.custom_stock is not None else self.product.stock

class Banner(models.Model):
    title = models.CharField(max_length=255, blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    link = models.URLField(blank=True, null=True)  # Optional: If you want the banner to link to another page
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title or "Banner"

class BannerImage(models.Model):
    banner = models.ForeignKey(Banner, related_name='images', on_delete=models.CASCADE)
    image = models.ImageField(upload_to='banners/')  # Store images in 'media/banners/'
    order = models.PositiveIntegerField(default=0)  # You can use this to define the order of the images

    def __str__(self):
        return f"Image for {self.banner.title}"

class CustomerProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)  # Link to User model
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    city = models.CharField(max_length=255, blank=True, null=True)
    postal_code = models.CharField(max_length=10, blank=True, null=True)
    
    def __str__(self):
        return f"Profile of {self.user.username}"
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created and not instance.is_superuser:  # Skip admin users
        CustomerProfile.objects.create(user=instance)

class Review(models.Model):
    product = models.ForeignKey(Product, related_name='reviews', on_delete=models.CASCADE)
    user = models.ForeignKey(User, related_name='reviews', on_delete=models.CASCADE)
    rating = models.PositiveIntegerField()
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    liked_by = models.ManyToManyField(User, related_name='liked_reviews', blank=True)

    def like_count(self):
        """Returns the number of likes for this review"""
        return self.liked_by.count()

    def like(self, user):
        """Adds a like to the review from the specified user"""
        self.liked_by.add(user)
        self.save()

    def __str__(self):
        return f"Review by {self.user.username} on {self.product.name}"
    
class Reply(models.Model):
    review = models.ForeignKey(Review, related_name='replies', on_delete=models.CASCADE)  # Link to Review
    user = models.ForeignKey(User, related_name='replies', on_delete=models.CASCADE)  # User who replies
    reply_text = models.TextField()  # Reply text
    created_at = models.DateTimeField(auto_now_add=True)  # When the reply was created

    def __str__(self):
        return f"Reply by {self.user.username} on {self.review.product.name}"
    
from django.db import models


class Order(models.Model):
    # Defining choices for the order status field
    class Status(models.TextChoices):
        PENDING = 'Pending', 'Pending'
        SHIPPED = 'Shipped', 'Shipped'
        DELIVERED = 'Delivered', 'Delivered'
        CANCELED = 'Canceled', 'Canceled'
        RETURNED = 'Returned', 'Returned'

    customer = models.ForeignKey(CustomerProfile, related_name='orders', on_delete=models.CASCADE)
    shop = models.ForeignKey(Shop, related_name='orders', on_delete=models.CASCADE, null=True, blank=True)
    
    total_price = models.DecimalField(max_digits=15, decimal_places=2)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    order_date = models.DateTimeField(auto_now_add=True)
    product_description = models.TextField(blank=True, null=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"Order {self.id} by {self.customer.user.username}"

    def get_order_colors(self):
        return ", ".join([item.color.color_name for item in self.order_items.all()])
    get_order_colors.short_description = 'Order Colors'

    def get_order_sizes(self):
        # FIX: Ensure this method also handles `None` size values.
        return ", ".join([item.size.name for item in self.order_items.all() if item.size])
    get_order_sizes.short_description = 'Sizes'
class OrderItem(models.Model):
    order = models.ForeignKey(Order, related_name='order_items', on_delete=models.CASCADE)
    product = models.ForeignKey(Product, related_name='order_items', on_delete=models.CASCADE)
    color = models.ForeignKey(Color, related_name='order_items', on_delete=models.CASCADE)
    size = models.ForeignKey(Size, related_name='order_items', on_delete=models.CASCADE, null=True, blank=True)  # NEW
    quantity = models.PositiveIntegerField(default=1)

    def __str__(self):
        size_name = f" - {self.size.name}" if self.size else ""
        return f"{self.quantity} x {self.product.name} ({self.color.color_name}{size_name})"


class SalesSummary(Order):
    class Meta:
        proxy = True
        verbose_name = "📊 Sales Summary"
        verbose_name_plural = "📊 Sales Summary"
        
class Cart(models.Model):
    customer = models.ForeignKey(CustomerProfile, related_name='carts', on_delete=models.CASCADE)
    category = models.ForeignKey(Category, related_name='carts', on_delete=models.SET_NULL, null=True, blank=True)
    brand = models.ForeignKey(Brand, related_name='carts', on_delete=models.SET_NULL, null=True, blank=True)
    total_price = models.DecimalField(max_digits=20, decimal_places=2)
    cart_date = models.DateTimeField(auto_now_add=True)  # Renamed to cart_date to reflect the cart creation time
    product_description = models.TextField(blank=True, null=True)  # Store product description in the cart

    def save(self, *args, **kwargs):
        # Only save the cart items description after the cart is created and saved
        if self.pk is not None:  # Make sure the object has been saved and has a primary key
            if self.cart_items.exists():
                self.product_description = ", ".join([str(item.product.name) for item in self.cart_items.all()])
        super(Cart, self).save(*args, **kwargs)

    def __str__(self):
        return f"Cart {self.id} by {self.customer.user.username}"

    def get_cart_colors(self):
        return ", ".join([item.color.color_name for item in self.cart_items.all()])

    get_cart_colors.short_description = 'Cart Colors'

class CartItem(models.Model):
    cart = models.ForeignKey(Cart, related_name='cart_items', on_delete=models.CASCADE)
    product = models.ForeignKey(Product, related_name='cart_items', on_delete=models.CASCADE)
    color = models.ForeignKey(Color, related_name='cart_items', on_delete=models.CASCADE)
    size = models.ForeignKey('Size', related_name='cart_items', on_delete=models.CASCADE, null=True, blank=True)  # NEW
    quantity = models.PositiveIntegerField(default=1)

    def __str__(self):
        size_name = f" - {self.size.name}" if self.size else ""
        return f"{self.quantity} x {self.product.name} ({self.color.color_name}{size_name})"


class Wishlist(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    products = models.ManyToManyField('Product', related_name='wishlists', blank=True)
    customer = models.ForeignKey(CustomerProfile, related_name='wishlists', on_delete=models.CASCADE, blank=True, null=True)

    def __str__(self):
        return self.name

class Logo(models.Model):
    name = models.CharField(max_length=100, default="App Logo")
    image = models.ImageField(upload_to='logos/')
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

    @property
    def image_url(self):
        if self.image:
            return self.image.url
        return ''
# ===========Footer=========
# Blog Section
class Blog(models.Model):
    title = models.CharField(max_length=200)
    image = models.ImageField(upload_to='blogs/')

    def __str__(self):
        return self.title

# Partner Section
class Partner(models.Model):
    name = models.CharField(max_length=100)
    logo = models.ImageField(upload_to='partners/')

    def __str__(self):
        return self.name

# About Page Content
class AboutPageContent(models.Model):
    image = models.ImageField(upload_to='about/', blank=True, null=True)
    title = models.CharField(max_length=200, default="About Sweet Shop")
    description = models.TextField()
    history_title = models.CharField(max_length=200, default="Our History")
    history_description = models.TextField()
    customers_title = models.CharField(max_length=200, default="Our Customers")
    customers_map_image = models.ImageField(upload_to='maps/')

    def __str__(self):
        return self.title