from rest_framework import serializers
from rest_framework import serializers
from .models import Banner, Logo, BannerImage, Cart, CartItem, Color, CustomerProfile, Order, OrderItem, Product, Category, Brand, DeviceModel, ProductColorImage, ProductColorSize, Reply, Review, Size, Wishlist
from django.contrib.auth.models import User

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'description']

class BrandSerializer(serializers.ModelSerializer):
    class Meta:
        model = Brand
        fields = ['id', 'name', 'category']

class DeviceModelSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceModel
        fields = ['id', 'name', 'brand']
class SizeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Size
        fields = ['id', 'name']
class ProductColorSizeSerializer(serializers.ModelSerializer):
    size_name = serializers.CharField(source='size.name', read_only=True)

    class Meta:
        model = ProductColorSize
        fields = ['id', 'size_name', 'stock']



class ColorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Color
        fields = ['color_name', 'color_code']
class ProductColorImageSerializer(serializers.ModelSerializer):
    color_name = serializers.CharField(source="color.color_name", read_only=True)
    color_code = serializers.CharField(source="color.color_code", read_only=True)
    sizes = ProductColorSizeSerializer(many=True, read_only=True)

    class Meta:
        model = ProductColorImage
        fields = ["id", "color_name", "color_code", "image", "stock", "sizes"]
 
# Reply Serializer
class ReplySerializer(serializers.ModelSerializer):
    class Meta:
        model = Reply
        fields = ['user', 'reply_text', 'created_at']

class ReviewSerializer(serializers.ModelSerializer):
    replies = ReplySerializer(many=True, read_only=True)  # Nested replies
    like_count = serializers.IntegerField(read_only=True)  # Directly use like_count() method without source

    class Meta:
        model = Review
        fields = ['id', 'product', 'user', 'rating', 'comment', 'created_at', 'like_count', 'replies']
        read_only_fields = ['user', 'product']  # Ensure these fields are read-only
class ProductSerializer(serializers.ModelSerializer):
    category = CategorySerializer(read_only=True)
    reviews = ReviewSerializer(many=True, read_only=True)
    brand = BrandSerializer(read_only=True)
    device_model = DeviceModelSerializer(read_only=True)
    image1 = serializers.SerializerMethodField()
    image2 = serializers.SerializerMethodField()
    image3 = serializers.SerializerMethodField()
    final_price = serializers.SerializerMethodField()
    color_images = ProductColorImageSerializer(many=True, read_only=True)

    class Meta:
        model = Product
        fields = [
            'id', 'name', 'description', 'price', 'make_by', 'rating', 'discount', 'stock',
            'image1', 'image2', 'image3', 'category', 'brand', 'device_model', 'reviews',
            'final_price', 'color_images'
        ]

    def get_image1(self, obj):
        first_color = obj.color_images.first()
        if first_color and first_color.image:
            return first_color.image.url
        return None

    def get_image2(self, obj):
        second_color = obj.color_images.all()[1] if obj.color_images.count() > 1 else None
        if second_color and second_color.image:
            return second_color.image.url
        return None

    def get_image3(self, obj):
        third_color = obj.color_images.all()[2] if obj.color_images.count() > 2 else None
        if third_color and third_color.image:
            return third_color.image.url
        return None

    def get_final_price(self, obj):
        if obj.discount:
            return obj.price - (obj.price * obj.discount / 100)
        return obj.price

# BannerImage Serializer
class BannerImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = BannerImage
        fields = ['id', 'image', 'order']

    def to_representation(self, instance):
        representation = super().to_representation(instance)
        request = self.context.get('request')
        if instance.image:
            representation['image'] = request.build_absolute_uri(instance.image.url)
        return representation

# Banner Serializer
class BannerSerializer(serializers.ModelSerializer):
    images = BannerImageSerializer(many=True, read_only=True)

    class Meta:
        model = Banner
        fields = ['id', 'title', 'description', 'link', 'created_at', 'updated_at', 'images']

class CustomerProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', required=False)
    email = serializers.EmailField(source='user.email', required=False)

    class Meta:
        model = CustomerProfile
        fields = ['id', 'user', 'username', 'email', 'phone_number', 'address', 'city', 'postal_code']

    def update(self, instance, validated_data):
        # Update the user fields
        user_data = validated_data.pop('user', {})
        if 'username' in user_data:
            instance.user.username = user_data['username']
        if 'email' in user_data:
            instance.user.email = user_data['email']
        
        # Update the profile fields
        instance.phone_number = validated_data.get('phone_number', instance.phone_number)
        instance.address = validated_data.get('address', instance.address)
        instance.city = validated_data.get('city', instance.city)
        instance.postal_code = validated_data.get('postal_code', instance.postal_code)
        
        # Save the changes
        instance.user.save()  # Save the user (username and email changes)
        instance.save()  # Save the profile (phone_number, address, etc.)
        
        return instance

class UserRegistrationSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'confirm_password']

    def validate(self, attrs):
        if attrs['password'] != attrs['confirm_password']:
            raise serializers.ValidationError({"password": "Passwords do not match."})
        return attrs

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User.objects.create(**validated_data)
        user.set_password(password)
        user.save()

        # Create CustomerProfile
        profile = CustomerProfile.objects.create(user=user)
        profile.save()
        
        return user
    
from rest_framework import serializers
from .models import Order, CustomerProfile, Category, Brand, Color, Product
from .serializers import CustomerProfileSerializer, CategorySerializer, BrandSerializer, ColorSerializer, DeviceModelSerializer
# Serializer for OrderItem
class OrderItemSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source='product.name', read_only=True)
    color_name = serializers.CharField(source='color.color_name', read_only=True)
    size_name = serializers.CharField(source='size.name', read_only=True)  # NEW

    class Meta:
        model = OrderItem
        fields = ['product_name', 'color_name', 'size_name', 'quantity']

# Serializer for Order
class OrderSerializer(serializers.ModelSerializer):
    customer = CustomerProfileSerializer()  # Nested CustomerProfile serializer
    order_items = OrderItemSerializer(many=True, read_only=True)  # Include order items

    # Status field
    status = serializers.ChoiceField(choices=Order.Status.choices, read_only=True)

    class Meta:
        model = Order
        fields = [
            'id', 'customer', 'order_items', 'total_price', 'status', 'order_date',
        ]

class CartItemSerializer(serializers.ModelSerializer):
    size_name = serializers.CharField(source='size.name', read_only=True)  # NEW

    class Meta:
        model = CartItem
        fields = ['product', 'color', 'size_name', 'quantity']

    
from decimal import Decimal, ROUND_HALF_UP
from rest_framework import serializers
from .models import Cart, CartItem


class CartSerializer(serializers.ModelSerializer):
    cart_items = CartItemSerializer(many=True, read_only=True)
    total_price = serializers.SerializerMethodField()

    class Meta:
        model = Cart
        fields = ['id', 'customer', 'total_price', 'cart_items']

    def get_total_price(self, obj):
        if obj.total_price is None:
            return "0.00"
        return str(
            Decimal(obj.total_price).quantize(Decimal("0.00"), rounding=ROUND_HALF_UP)
        )


class WishlistSerializer(serializers.ModelSerializer):
    products = ProductSerializer(many=True, read_only=True)
    customer = CustomerProfileSerializer(read_only=True)

    class Meta:
        model = Wishlist
        fields = '__all__'

class WishlistCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Wishlist
        fields = ['name', 'description', 'products', 'customer']
class BestSellingProductSerializer(serializers.ModelSerializer):
    product_id = serializers.IntegerField(source='product.id')  
    product_name = serializers.CharField(source='product.name')
    description = serializers.CharField(source='product.description')
    price = serializers.DecimalField(source='product.price', max_digits=10, decimal_places=2)
    make_by = serializers.CharField(source='product.make_by')
    color = serializers.StringRelatedField(many=True, source='product.color.all')  
    rating = serializers.DecimalField(source='product.rating', max_digits=2, decimal_places=1)
    discount = serializers.DecimalField(source='product.discount', max_digits=5, decimal_places=2)
    stock = serializers.IntegerField(source='product.stock')  
    total_quantity_sold = serializers.IntegerField()  
    image1 = serializers.SerializerMethodField()
    image2 = serializers.SerializerMethodField()
    image3 = serializers.SerializerMethodField()
    final_price = serializers.SerializerMethodField()  
    category = CategorySerializer(source='product.category')  # Nested serializer for category
    brand = BrandSerializer(source='product.brand')  # Nested serializer for brand
    device_model = DeviceModelSerializer(source='product.device_model')  # Nested serializer for device model
    
    def get_image1(self, obj):
        return self.build_image_url(obj, 'image1')

    def get_image2(self, obj):
        return self.build_image_url(obj, 'image2')

    def get_image3(self, obj):
        return self.build_image_url(obj, 'image3')

    def build_image_url(self, obj, image_field):
        """Helper method to build the full image URL."""
        image = getattr(obj['product'], image_field, None)
        if image:
            return self.context['request'].build_absolute_uri(image.url)
        return None

    def get_final_price(self, obj):
        price = obj['product'].price
        discount = obj['product'].discount
        final_price = price - (price * (discount / 100))
        return final_price

    class Meta:
        model = Product
        fields = [
            'product_id', 'product_name', 'description', 'price', 'make_by', 'color', 'rating', 'discount', 'stock',
            'total_quantity_sold', 'image1', 'image2', 'image3', 'final_price', 'category', 'brand', 'device_model',
        ]

class LogoSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Logo
        fields = ['id', 'name', 'image_url']

    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image and request:
            return request.build_absolute_uri(obj.image.url)
        return None

# ===============Footer=========
from .models import AboutPageContent, Blog, Partner

class BlogSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Blog
        fields = ['id', 'title', 'image_url']

    def get_image_url(self, obj):
        request = self.context.get('request')
        return request.build_absolute_uri(obj.image.url)

class PartnerSerializer(serializers.ModelSerializer):
    logo_url = serializers.SerializerMethodField()

    class Meta:
        model = Partner
        fields = ['id', 'name', 'logo_url']

    def get_logo_url(self, obj):
        request = self.context.get('request')
        return request.build_absolute_uri(obj.logo.url)

class AboutPageContentSerializer(serializers.ModelSerializer):
    blogs = BlogSerializer(many=True, read_only=True)
    partners = PartnerSerializer(many=True, read_only=True)

    class Meta:
        model = AboutPageContent
        fields = [
            'image',
            'title',
            'description',
            'history_title',
            'history_description',
            'customers_title',
            'customers_map_image',
            'blogs',
            'partners'
        ]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get('request')
        data['customers_map_image'] = request.build_absolute_uri(instance.customers_map_image.url)
        return data