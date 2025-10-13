# products/views.py
from contextvars import Token
from decimal import Decimal
from itertools import count
import logging
from django.forms import DecimalField
from django.views.decorators.csrf import csrf_exempt
from django.db.models import Q
from rest_framework.permissions import AllowAny
from rest_framework.authtoken.models import Token
from django.shortcuts import get_object_or_404, render
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.generics import ListCreateAPIView, RetrieveAPIView
from .models import Banner, Brand, Cart, CartItem, Category, Color, CustomerProfile, DeviceModel, Order, OrderItem, Product, ProductColorImage, ProductColorSize, Reply, Review, Size, Wishlist
from .serializers import BannerSerializer, BestSellingProductSerializer, BrandSerializer, CartItemSerializer, CartSerializer, CategorySerializer, ColorSerializer, CustomerProfileSerializer, DeviceModelSerializer, OrderSerializer, ProductColorImageSerializer, ProductSerializer, ReplySerializer, ReviewSerializer, SizeSerializer, UserRegistrationSerializer, WishlistSerializer
from django.http import JsonResponse
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth.models import User
from rest_framework.decorators import api_view, permission_classes
from rest_framework import generics
import re
from django.db import IntegrityError
from django.contrib.auth import authenticate
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError, InvalidToken
from django.core.paginator import Paginator
from django.db.models import Sum, F, ExpressionWrapper, DecimalField
class TokenVerifyView(APIView):   
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Verifies that the current token is valid and not expired.
        """
        # Extract token from Authorization header (Bearer token)
        token = request.headers.get('Authorization')
        
        if not token:
            return Response({"error": "Authorization token is missing."}, status=status.HTTP_400_BAD_REQUEST)

        # Token format should be "Bearer <token>"
        token_parts = token.split()
        if len(token_parts) != 2 or token_parts[0].lower() != 'bearer':
            return Response({"error": "Invalid token format."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Extract the token
            token = token_parts[1]

            # Validate the token
            AccessToken(token)  # This will raise an error if the token is invalid or expired
            return Response({"message": "Token is valid!"}, status=status.HTTP_200_OK)
        
        except InvalidToken:
            return Response({"error": "Invalid token."}, status=status.HTTP_401_UNAUTHORIZED)
        except TokenError as e:
            # Any other issues with the token
            return Response({"error": f"Token error: {str(e)}"}, status=status.HTTP_401_UNAUTHORIZED)
        except Exception as e:
            # Catch any other unexpected errors
            return Response({"error": f"Unexpected error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
# Password validation regex
password_regex = re.compile(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])[A-Za-z\d!@#$%^&*(),.?":{}|<>]{8,}$')

# Phone number validation regex (exactly 11 digits)
phone_number_regex = re.compile(r'^\d{11}$')

# Email validation regex (basic format check)
email_regex = re.compile(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9-]+\.(com|org|net|edu|gov|io|co|[a-zA-Z]{2,})$')

# Address validation regex
address_regex = re.compile(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[,-\\])[a-zA-Z0-9,\\-\\s]+$')

@api_view(['POST'])
def register(request):
    try:
        # Get data from the request
        username = request.data.get('username')
        email = request.data.get('email')
        password = request.data.get('password')
        confirm_password = request.data.get('confirm_password')
        first_name = request.data.get('first_name', '')  # Optional
        last_name = request.data.get('last_name', '')  # Optional
        phone_number = request.data.get('phone_number', '')
        address = request.data.get('address', '')
        city = request.data.get('city', '')
        postal_code = request.data.get('postal_code', '')

        # Check if the email format is valid using regex
        if not email_regex.match(email):
            return Response({"error": "Invalid email format. Please enter a valid email address."}, status=status.HTTP_400_BAD_REQUEST)

        # Check if the email already exists in the database
        if User.objects.filter(email=email).exists():
            return Response({"error": "Email is already in use. Please use a different email address."}, status=status.HTTP_400_BAD_REQUEST)

        # Check if the username already exists in the database
        if User.objects.filter(username=username).exists():
            return Response({"error": "Username is already taken. Please choose a different username."}, status=status.HTTP_400_BAD_REQUEST)

        # Password validation
        if not password_regex.match(password):
            return Response({"error": "Password must be at least 8 characters long, contain at least one uppercase letter, one lowercase letter, and one special character."}, status=status.HTTP_400_BAD_REQUEST)

        # Confirm password check
        if password != confirm_password:
            return Response({"error": "Passwords do not match."}, status=status.HTTP_400_BAD_REQUEST)

        # Phone number validation (must be exactly 11 digits)
        if not phone_number_regex.match(phone_number):
            return Response({"error": "Phone number must be exactly 11 digits."}, status=status.HTTP_400_BAD_REQUEST)

        # Address validation (must contain at least one letter, one number, and one special character: -,\, or ,)
        if not address_regex.match(address):
            return Response({"error": "Address must contain at least one alphabetic character, one number, and one of the following characters: -, \\, or ,."}, status=status.HTTP_400_BAD_REQUEST)

        # Create user object
        user = User.objects.create_user(
            username=username, email=email, password=password,
            first_name=first_name, last_name=last_name
        )

        # Save additional profile information (phone number, address, etc.)
        user.customerprofile.phone_number = phone_number
        user.customerprofile.address = address
        user.customerprofile.city = city
        user.customerprofile.postal_code = postal_code
        user.customerprofile.save()

        # Return success message
        return Response({"message": "User registered successfully!"}, status=status.HTTP_201_CREATED)

    except Exception as e:
        # Generic error handling
        return Response({"error": "An error occurred during registration. Please try again."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
class ProfileView(APIView):
    permission_classes = [IsAuthenticated]  # Ensure the user is authenticated

    def get(self, request):
        user = request.user  # Get the currently logged-in user
        
        try:
            # Get the profile for the logged-in user
            profile = CustomerProfile.objects.get(user=user)
            # Serialize the profile data
            serializer = CustomerProfileSerializer(profile)
            # Return the serialized data in the response
            return Response(serializer.data, status=status.HTTP_200_OK)
        except CustomerProfile.DoesNotExist:
            return Response({"error": "Profile not found"}, status=status.HTTP_404_NOT_FOUND)
class ProfileUpdateView(APIView):
    permission_classes = [IsAuthenticated]  # Ensure the user is authenticated

    def put(self, request):
        user = request.user  # Get the currently logged-in user

        # Retrieve current and new passwords from request data
        current_password = request.data.get('current_password', None)
        new_password = request.data.get('new_password', None)

        if current_password and new_password:
            # Verify current password is correct
            user = authenticate(username=user.username, password=current_password)
            if user is None:
                return Response({"error": "Current password is incorrect"}, status=status.HTTP_400_BAD_REQUEST)

            # Set the new password if the current password is correct
            user.set_password(new_password)
            user.save()

        try:
            # Get the user profile
            profile = CustomerProfile.objects.get(user=user)  # Get the profile of the logged-in user
        except CustomerProfile.DoesNotExist:
            return Response({"error": "Profile not found"}, status=status.HTTP_404_NOT_FOUND)

        # Serialize the data and validate
        serializer = CustomerProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()  # Save the updated profile and user data
            return Response({"message": "Profile updated successfully", "profile": serializer.data}, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
import logging
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken

# Setting up logging
logger = logging.getLogger(__name__)

class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        # Get username and password from request
        username = request.data.get("username")
        password = request.data.get("password")

        # Log the incoming request for debugging purposes
        logger.debug(f"Login attempt with username: {username}")

        # Authenticate the user here (using Django authentication or custom logic)
        user = authenticate(username=username, password=password)
        if user is not None:
            # If user is authenticated, generate JWT tokens
            refresh = RefreshToken.for_user(user)

            # Return the access token, refresh token, and the user_id
            return Response({
                "access_token": str(refresh.access_token),
                "refresh_token": str(refresh),
                "user_id": user.id  # Include the user_id in the response
            })
        else:
            # Log invalid attempts for debugging purposes
            logger.warning(f"Failed login attempt for username: {username}")
            return Response({"detail": "Invalid credentials"}, status=401)
# Refresh token view to get a new access token
@api_view(['POST'])
def refresh_token_view(request):
    refresh_token = request.data.get('refresh_token')

    try:
        refresh = RefreshToken(refresh_token)
        access_token = str(refresh.access_token)  # New access token
        return Response({'access_token': access_token}, status=status.HTTP_200_OK)
    except TokenError:
        return Response({'detail': 'Invalid or expired refresh token'}, status=status.HTTP_400_BAD_REQUEST)
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status
class SizeViewSet(viewsets.ModelViewSet):
    queryset = Size.objects.all()
    serializer_class = SizeSerializer
class ColorViewSet(viewsets.ModelViewSet):
    queryset = Color.objects.all()
    serializer_class = ColorSerializer

    @action(detail=False, methods=['get'], url_path='by_name/(?P<color_name>[^/]+)')
    def get_color_by_name(self, request, color_name=None):
        """
        Custom endpoint to get color by its name
        :param color_name: Name of the color
        :return: Color details if found, else error message
        """
        try:
            color = Color.objects.get(color_name=color_name)
            serializer = ColorSerializer(color)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Color.DoesNotExist:
            return Response({"detail": "Color not found."}, status=status.HTTP_404_NOT_FOUND)
class ProductColorImagesView(APIView):
    def get(self, request, product_id):
        color_images = ProductColorImage.objects.filter(product_id=product_id)
        serializer = ProductColorImageSerializer(color_images, many=True, context={'request': request})
        return Response(serializer.data)
class CategoryViewSet(viewsets.ModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer

class BrandViewSet(viewsets.ModelViewSet):
    queryset = Brand.objects.all()
    serializer_class = BrandSerializer

    def get_queryset(self):
        category_name = self.request.query_params.get('category', None)
        if category_name:
            try:
                category = Category.objects.get(name=category_name)
                return Brand.objects.filter(category=category)
            except Category.DoesNotExist:
                return Brand.objects.none()
        return Brand.objects.all()

class DeviceModelViewSet(viewsets.ModelViewSet):
    queryset = DeviceModel.objects.all()
    serializer_class = DeviceModelSerializer

    def get_queryset(self):
        brand_id = self.request.query_params.get('brand_id', None)
        if brand_id:
            return DeviceModel.objects.filter(brand_id=brand_id)
        return DeviceModel.objects.all()

class ProductViewSet(viewsets.ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer

    def get_queryset(self):
        queryset = Product.objects.all()

        category_id = self.request.query_params.get('category_id', None)
        brand_id = self.request.query_params.get('brand_id', None)
        device_model_id = self.request.query_params.get('device_model_id', None)

        if category_id and category_id != 'All':
            queryset = queryset.filter(category_id=category_id)

        if brand_id and brand_id != 'All':
            queryset = queryset.filter(brand_id=brand_id)

        if device_model_id and device_model_id != 'All':
            queryset = queryset.filter(device_model_id=device_model_id)

        return queryset


# Retrieve Product View (for a single product)
class ProductRetrieveView(RetrieveAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    lookup_field = 'id'  # We will be looking up products by 'id'
class ProductRetrieveByNameView(APIView):
    def get(self, request, name, format=None):
        try:
            product = Product.objects.get(name=name)
            serializer = ProductSerializer(product)
            return Response(serializer.data)
        except Product.DoesNotExist:
            return Response({"error": "Product not found"}, status=status.HTTP_404_NOT_FOUND)
@api_view(['GET'])
def search_products(request):
    """
    API endpoint for searching products based on query prefix.
    Returns products that start with the query letters.
    """
    query = request.GET.get('q', '').strip().lower()  # normalize input
    page_number = request.GET.get('page', 1)

    if not query:
        return Response({'error': 'Search query cannot be empty.'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        page_number = int(page_number)
    except ValueError:
        page_number = 1

    # Use startswith for prefix search
    products = Product.objects.filter(
        Q(name__istartswith=query) | Q(description__icontains=query)
    ).only('id', 'name', 'description', 'price', 'image1')

    paginator = Paginator(products, 10)
    page_obj = paginator.get_page(page_number)

    serializer = ProductSerializer(page_obj.object_list, many=True, context={'request': request})

    return Response({
        'products': serializer.data,
        'total_pages': paginator.num_pages,
        'current_page': page_number
    }, status=status.HTTP_200_OK)
    
class BannerViewSet(viewsets.ModelViewSet):
    queryset = Banner.objects.all()
    serializer_class = BannerSerializer

class ReviewViewSet(viewsets.ModelViewSet):
    queryset = Review.objects.all()
    serializer_class = ReviewSerializer

class ReviewListCreateView(generics.ListCreateAPIView):
    serializer_class = ReviewSerializer
    # permission_classes = [IsAuthenticated]  # Ensure the user is authenticated

    def get_queryset(self):
        product_id = self.kwargs['product_id']  # Extract product ID from URL
        return Review.objects.filter(product_id=product_id)

    def perform_create(self, serializer):
        # Get the product from the URL parameter
        product = Product.objects.get(id=self.kwargs['product_id'])  
        
        # Get the logged-in user from the token (automatically populated by Django)
        user = self.request.user  
        
        # Save the review with both the user and the product
        serializer.save(user=user, product=product)
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework import status
from .models import Review

class LikeReviewView(APIView):
    def post(self, request, review_id):
        user = request.user  # Get the logged-in user from the token

        try:
            review = Review.objects.get(id=review_id)
        except Review.DoesNotExist:
            return Response({"error": "Review not found"}, status=status.HTTP_404_NOT_FOUND)

        # Check if the user has already liked this review
        if user in review.liked_by.all():
            return Response({
                "error": "You have already liked this review",
                "like_count": review.liked_by.count(),
                "has_liked": True  # Indicate that the user has liked this review
            }, status=status.HTTP_400_BAD_REQUEST)

        # Add the user to the "liked_by" list
        review.liked_by.add(user)
        review.like_count = review.liked_by.count()  # Update the like count

        # Save the review
        review.save()

        return Response({
            "message": "Like added successfully",
            "like_count": review.liked_by.count(),
            "has_liked": True  # Indicate that the user has liked this review now
        }, status=status.HTTP_201_CREATED)

class ReplyReviewView(APIView):
    permission_classes = [IsAuthenticated]  # Ensure only authenticated users can access this view

    def post(self, request, review_id):
        user = request.user  # The request.user should now be authenticated
        
        # Ensure that user is authenticated
        if not user.is_authenticated:
            return Response({'error': 'You must be logged in to reply'}, status=status.HTTP_401_UNAUTHORIZED)

        reply_text = request.data.get('reply_text')

        if not reply_text:
            return Response({'error': 'Reply text is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            review = Review.objects.get(id=review_id)
        except Review.DoesNotExist:
            return Response({"error": "Review not found"}, status=status.HTTP_404_NOT_FOUND)

        # Create a reply with the actual user instance
        reply = Reply.objects.create(review=review, user=user, reply_text=reply_text)
        return Response({"message": "Reply added successfully", "reply": ReplySerializer(reply).data}, status=status.HTTP_201_CREATED)

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [IsAuthenticated]  # Ensure only authenticated users can access this view
    
    @action(detail=True, methods=['put'])
    def update_profile(self, request, pk=None):
        user = self.get_object()
        profile_data = request.data.get('profile')

        # Update the profile data (phone, address, etc.)
        user.customerprofile.phone_number = profile_data.get('phone_number', user.customerprofile.phone_number)
        user.customerprofile.address = profile_data.get('address', user.customerprofile.address)
        user.customerprofile.city = profile_data.get('city', user.customerprofile.city)
        user.customerprofile.postal_code = profile_data.get('postal_code', user.customerprofile.postal_code)
        user.customerprofile.save()

        return Response({'status': 'Profile updated'})
import logging
from django.db.models import Avg
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import Product, Review

# Set up logger
logger = logging.getLogger(__name__)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_review(request, product_id):
    try:
        # Fetch the product
        product = Product.objects.get(id=product_id)
    except Product.DoesNotExist:
        logger.error(f"Product with ID {product_id} not found.")
        return Response({"error": "Product not found"}, status=status.HTTP_404_NOT_FOUND)

    # Validate the rating input
    rating = request.data.get('rating')
    if not rating or rating < 1 or rating > 5:
        logger.error(f"Invalid rating value: {rating}")
        return Response({"error": "Rating must be between 1 and 5"}, status=status.HTTP_400_BAD_REQUEST)

    # Save the review
    review = Review(
        product=product,
        user=request.user,
        rating=rating,
        comment=request.data.get('comment', '')
    )
    review.save()

    logger.info(f"Review submitted by {request.user.username} for product {product.name} with rating {rating}.")

    # Calculate the new average rating
    reviews = Review.objects.filter(product=product)
    average_rating = reviews.aggregate(Avg('rating'))['rating__avg']

    # Check if the average rating was calculated successfully
    if average_rating is not None:
        # Update the product's rating with the new average rating
        product.rating = round(average_rating, 1)  # Ensure it has one decimal place
        product.save()  # Save the updated product rating
        logger.info(f"Product {product.name} rating updated to: {product.rating}")
    else:
        # If no reviews yet, handle gracefully
        logger.warning(f"No reviews yet for product {product.name}, rating not updated.")
    
    # Return the response
    return Response({
        "message": "Review submitted successfully!",
        "average_rating": product.rating
    }, status=status.HTTP_201_CREATED)

class CartViewSet(viewsets.ModelViewSet):
    queryset = Cart.objects.all()
    serializer_class = CartSerializer  # Updated to CartSerializer

from django.db import transaction
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import F
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_to_cart(request):
    """
    Add a product to the cart, or increment quantity if it already exists.
    Handles multiple colors with sizes and quantities, enforcing stock limits.
    """
    user = request.user
    product_id = request.data.get('product_id')
    color_size_quantities = request.data.get('color_size_quantities', [])

    if not product_id or not color_size_quantities:
        return Response({"detail": "Missing product_id or color_size_quantities"}, status=status.HTTP_400_BAD_REQUEST)

    if not isinstance(color_size_quantities, list):
        return Response({"detail": "color_size_quantities must be a list"}, status=status.HTTP_400_BAD_REQUEST)

    # Get customer profile
    try:
        customer = CustomerProfile.objects.get(user=user)
    except CustomerProfile.DoesNotExist:
        return Response({"detail": "Invalid user"}, status=status.HTTP_400_BAD_REQUEST)

    # Get product
    try:
        product = Product.objects.get(id=product_id)
    except Product.DoesNotExist:
        return Response({"detail": "Invalid product"}, status=status.HTTP_400_BAD_REQUEST)

    # Get or create cart
    cart, _ = Cart.objects.get_or_create(customer=customer, defaults={'total_price': 0})

    try:
        with transaction.atomic():
            for item_data in color_size_quantities:
                color_name = item_data.get('color_name')
                size_name = item_data.get('size_name')
                requested_qty = item_data.get('quantity', 1)

                if not color_name or not size_name or not isinstance(requested_qty, int) or requested_qty <= 0:
                    return Response({"detail": "Invalid color_name, size_name, or quantity"}, status=status.HTTP_400_BAD_REQUEST)

                # Get color object
                try:
                    color = Color.objects.get(color_name=color_name)
                except Color.DoesNotExist:
                    return Response({"detail": f"Invalid color: {color_name}"}, status=status.HTTP_400_BAD_REQUEST)

                # Check stock at color + size level
                try:
                    color_image = ProductColorImage.objects.get(product=product, color=color)
                    color_size_entry = ProductColorSize.objects.get(product_color_image=color_image, size__name=size_name)
                    available_stock = color_size_entry.stock
                except ProductColorSize.DoesNotExist:
                    return Response({"detail": f"No stock record available for {product.name} - {color_name} - {size_name}"}, status=status.HTTP_400_BAD_REQUEST)

                # Check existing cart item
                current_cart_item = CartItem.objects.filter(cart=cart, product=product, color=color, size=color_size_entry.size).first()
                current_qty_in_cart = current_cart_item.quantity if current_cart_item else 0

                total_qty_after_add = current_qty_in_cart + requested_qty

                # Enforce stock limits
                if total_qty_after_add > available_stock:
                    return Response({
                        "detail": f"Not enough stock for {color_name} ({size_name}). "
                                  f"Available: {available_stock}, Requested: {requested_qty}, In cart: {current_qty_in_cart}"
                    }, status=status.HTTP_400_BAD_REQUEST)

                # Add or update cart item
                if current_cart_item:
                    current_cart_item.quantity += requested_qty
                    current_cart_item.save()
                else:
                    CartItem.objects.create(
                        cart=cart,
                        product=product,
                        color=color,
                        size=color_size_entry.size,
                        quantity=requested_qty
                    )

            # Recalculate total price
            cart.total_price = sum(item.product.price * item.quantity for item in cart.cart_items.all())
            cart.save()

    except Exception as e:
        return Response({"detail": f"Error while adding to cart: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    serializer = CartSerializer(cart, context={'request': request})
    return Response(serializer.data, status=status.HTTP_201_CREATED)
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Cart, CustomerProfile
from .serializers import CartSerializer
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_cart(request):
    """
    Retrieve the current cart for the authenticated customer.
    Automatically remove items that are out of stock.
    """
    user = request.user

    try:
        customer = CustomerProfile.objects.get(user=user)
    except CustomerProfile.DoesNotExist:
        return Response({"detail": "User profile not found."}, status=400)

    # Retrieve or create cart
    cart, _ = Cart.objects.get_or_create(customer=customer, defaults={'total_price': 0})

    # Remove cart items with 0 stock
    for item in cart.cart_items.all():
        # Get the stock for this product-color-size combination
        try:
            color_image = ProductColorImage.objects.get(product=item.product, color=item.color)
            color_size_entry = ProductColorSize.objects.get(product_color_image=color_image, size=item.size)
            if color_size_entry.stock <= 0:
                item.delete()  # Remove item from cart
        except ProductColorSize.DoesNotExist:
            # If stock record is missing, also remove the item
            item.delete()

    # Recalculate cart total price
    cart.total_price = sum(i.product.price * i.quantity for i in cart.cart_items.all())
    cart.save()

    serializer = CartSerializer(cart, context={'request': request})
    return Response(serializer.data, status=200)

from django.db.models import Sum
from django.db import transaction
from decimal import Decimal

# This is a standalone script block, NOT part of a view.
# Use with caution.
from django.db import transaction

with transaction.atomic():
    for cart in Cart.objects.all():
        items_to_process = list(cart.cart_items.all())  # iterate over copy
        aggregated_items = {}

        for item in items_to_process:
            key = (item.product_id, item.color_id, item.size_id)
            if key not in aggregated_items:
                aggregated_items[key] = {
                    'item': item,
                    'total_quantity': item.quantity
                }
            else:
                aggregated_items[key]['total_quantity'] += item.quantity
                item.delete()  # remove duplicate

        # Update remaining items with correct total quantity
        for data in aggregated_items.values():
            item = data['item']
            total_qty = data['total_quantity']
            if item.quantity != total_qty:
                item.quantity = total_qty
                item.save()

    # Recalculate cart total prices
    for cart in Cart.objects.all():
        total_price = Decimal("0.00")
        for item in cart.cart_items.all():
            product = item.product
            unit_price = product.price
            
            # Apply discount if it exists
            if getattr(product, 'discount', None):
                try:
                    unit_price = (Decimal(product.price) * (Decimal('1.0') - Decimal(product.discount) / Decimal('100'))).quantize(Decimal('0.01'))
                except Exception:
                    unit_price = Decimal(product.price)
            
            total_price += (unit_price * Decimal(item.quantity))

        cart.total_price = total_price
        cart.save()

print("Cart items deduplicated and quantities updated.")

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
from .models import Cart, CartItem, Product, Color, ProductColorImage
from .serializers import CartSerializer

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def remove_from_cart(request):
    """
    Remove a specific cart item (product, color, and size) from the cart.
    """
    product_id = request.data.get('product_id')
    color_name = request.data.get('color_name')
    size_name = request.data.get('size_name')  # New: size

    if not product_id or not color_name or not size_name:
        return Response({"detail": "Missing product_id, color_name, or size_name"}, status=status.HTTP_400_BAD_REQUEST)

    user = request.user
    try:
        cart = Cart.objects.get(customer__user=user)
    except Cart.DoesNotExist:
        return Response({"detail": "No cart found for this user"}, status=status.HTTP_404_NOT_FOUND)

    try:
        product = Product.objects.get(id=product_id)
    except Product.DoesNotExist:
        return Response({"detail": "Invalid product"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        color = Color.objects.get(color_name=color_name)
    except Color.DoesNotExist:
        return Response({"detail": f"Invalid color: {color_name}"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        cart_item = CartItem.objects.get(cart=cart, product=product, color=color, size__name=size_name)
    except CartItem.DoesNotExist:
        return Response({"detail": "Cart item not found for this product, color, and size"}, status=status.HTTP_404_NOT_FOUND)

    with transaction.atomic():
        # Optional: adjust color-size stock if you are tracking stock in real-time
        try:
            color_image = ProductColorImage.objects.get(product=cart_item.product, color=cart_item.color)
            color_size_entry = cart_item.size  # Assuming size is linked to ProductColorSize
            # If you want to return stock, uncomment the line below:
            # color_size_entry.stock += cart_item.quantity
            color_size_entry.save()
        except ProductColorImage.DoesNotExist:
            pass

        # Delete the cart item
        cart_item.delete()

        # Recalculate total price
        cart.total_price = sum(item.product.price * item.quantity for item in cart.cart_items.all())
        cart.save()

    serializer = CartSerializer(cart, context={'request': request})
    return Response(serializer.data, status=status.HTTP_200_OK)
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
from .models import Cart, CartItem, Product, Color, ProductColorImage
from .serializers import CartSerializer
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def increment_quantity(request):
    """
    Increment a cart item's quantity with color & size, enforcing stock limits.
    """
    product_id = request.data.get('product_id')
    color_name = request.data.get('color_name')
    size_name = request.data.get('size_name')

    if not product_id or not color_name or not size_name:
        return Response(
            {"detail": "Missing product_id, color_name, or size_name"},
            status=status.HTTP_400_BAD_REQUEST
        )

    user = request.user

    try:
        cart = Cart.objects.get(customer__user=user)
        product = Product.objects.get(id=product_id)
        color = Color.objects.get(color_name=color_name)

        # Find size stock entry
        color_image = ProductColorImage.objects.get(product=product, color=color)
        size_entry = ProductColorSize.objects.get(product_color_image=color_image, size__name=size_name)

        # Find cart item
        cart_item = CartItem.objects.get(cart=cart, product=product, color=color, size=size_entry.size)

    except (Cart.DoesNotExist, Product.DoesNotExist, Color.DoesNotExist,
            ProductColorImage.DoesNotExist, ProductColorSize.DoesNotExist,
            CartItem.DoesNotExist) as e:
        return Response({"detail": str(e)}, status=status.HTTP_404_NOT_FOUND)

    with transaction.atomic():
        # Check stock limit at size level
        if cart_item.quantity + 1 > size_entry.stock:
            return Response({
                "detail": f"Not enough stock for {color.color_name} ({size_name}). "
                          f"Only {size_entry.stock - cart_item.quantity} more can be added."
            }, status=status.HTTP_400_BAD_REQUEST)

        cart_item.quantity += 1
        cart_item.save()

        # Recalculate total price
        cart.total_price = sum(item.product.price * item.quantity for item in cart.cart_items.all())
        cart.save()

    serializer = CartSerializer(cart, context={'request': request})
    return Response(serializer.data, status=status.HTTP_200_OK)

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db import transaction
from .models import Cart, CartItem, Product, Color
from .serializers import CartSerializer

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def decrement_quantity(request):
    """
    Decrement the quantity of a specific cart item (product, color, and size).
    If quantity becomes 0, remove the item.
    """
    product_id = request.data.get('product_id')
    color_name = request.data.get('color_name')
    size_name = request.data.get('size_name')  # New: size

    if not product_id or not color_name or not size_name:
        return Response({"detail": "Missing product_id, color_name, or size_name"}, status=400)

    user = request.user

    try:
        cart = Cart.objects.get(customer__user=user)
        product = Product.objects.get(id=product_id)
        color = Color.objects.get(color_name=color_name)
        cart_item = CartItem.objects.get(cart=cart, product=product, color=color, size__name=size_name)
    except Cart.DoesNotExist:
        return Response({"detail": "No cart found for this user"}, status=404)
    except Product.DoesNotExist:
        return Response({"detail": "Invalid product"}, status=400)
    except Color.DoesNotExist:
        return Response({"detail": f"Invalid color: {color_name}"}, status=400)
    except CartItem.DoesNotExist:
        return Response({"detail": "Cart item not found for this product, color, and size"}, status=404)

    with transaction.atomic():
        if cart_item.quantity > 1:
            cart_item.quantity -= 1
            cart_item.save()
        else:
            cart_item.delete()  # Remove if quantity reaches 0

        # Recalculate total price
        cart.total_price = sum(item.product.price * item.quantity for item in cart.cart_items.all())
        cart.save()

    serializer = CartSerializer(cart, context={'request': request})
    return Response(serializer.data, status=200)
from decimal import Decimal
from django.db import transaction
from django.db.models import F, Sum, DecimalField
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import CustomerProfile, Product, Color, ProductColorImage, Order, OrderItem
from collections import defaultdict
from decimal import Decimal
from django.db import transaction
from django.db.models import F
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import CustomerProfile, Product, Color, ProductColorImage, Order, OrderItem
# ... (all imports and setup remain the same)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_cart(request):
    """
    Checkout/merge cart into pending orders.
    Supports product + color + optional size (uses ProductColorSize when size present).
    Handles multiple shops by creating separate pending orders per shop.
    """
    user_id = request.data.get('user_id')
    items_in = request.data.get('color_size_quantities') or request.data.get('color_quantities') or []

    if not user_id or not items_in:
        return Response({"detail": "Missing required data (user_id or items)."}, status=status.HTTP_400_BAD_REQUEST)

    # Aggregate items to handle duplicates
    aggregated = defaultdict(int)
    for it in items_in:
        prod_id = it.get('product_id')
        color_name = it.get('color_name')
        size_name = it.get('size_name')
        qty = it.get('quantity', 0)

        if not prod_id or not color_name or not isinstance(qty, int) or qty <= 0:
            return Response({"detail": "Invalid item format (product_id/color_name/quantity)."}, status=status.HTTP_400_BAD_REQUEST)

        size_name = size_name.strip() if size_name and size_name.strip() != "" else None
        key = (int(prod_id), str(color_name).strip(), size_name)
        aggregated[key] += qty

    try:
        customer = CustomerProfile.objects.get(user__id=user_id)
    except CustomerProfile.DoesNotExist:
        return Response({"detail": "Invalid user."}, status=status.HTTP_400_BAD_REQUEST)

    with transaction.atomic():
        # Dictionary to store items per shop
        processed_per_shop = defaultdict(list)

        for (product_id, color_name, size_name), total_qty in aggregated.items():
            try:
                product = Product.objects.select_for_update().get(id=product_id)
            except Product.DoesNotExist:
                return Response({"detail": f"Product {product_id} not found."}, status=status.HTTP_400_BAD_REQUEST)

            try:
                color = Color.objects.get(color_name=color_name)
            except Color.DoesNotExist:
                return Response({"detail": f"Color {color_name} not found."}, status=status.HTTP_400_BAD_REQUEST)

            try:
                color_image = ProductColorImage.objects.select_for_update().get(product=product, color=color)
            except ProductColorImage.DoesNotExist:
                return Response({"detail": f"No stock entry for {product.name} - {color_name}."}, status=status.HTTP_400_BAD_REQUEST)

            # Handle size
            size_entry = None
            size_obj = None
            if ProductColorSize.objects.filter(product_color_image=color_image).exists():
                if not size_name:
                    return Response({"detail": f"Size required for {product.name} - {color_name}."}, status=status.HTTP_400_BAD_REQUEST)
                try:
                    size_entry = ProductColorSize.objects.select_for_update().get(
                        product_color_image=color_image,
                        size__name__iexact=size_name
                    )
                    size_obj = size_entry.size
                    available_stock = size_entry.stock
                except ProductColorSize.DoesNotExist:
                    return Response({"detail": f"No size '{size_name}' for {product.name} - {color_name}."}, status=status.HTTP_400_BAD_REQUEST)
            else:
                available_stock = color_image.stock

            if available_stock < total_qty:
                return Response({
                    "detail": f"Not enough stock for {product.name} ({color_name}{' - ' + size_name if size_name else ''}). "
                              f"Available: {available_stock}, requested: {total_qty}."
                }, status=status.HTTP_400_BAD_REQUEST)

            if not product.created_by_shop:
                return Response({"detail": f"Product '{product.name}' is not linked to a shop."}, status=status.HTTP_400_BAD_REQUEST)

            # Calculate final price
            final_price = product.price
            if getattr(product, 'discount', None):
                try:
                    final_price = (Decimal(product.price) * (Decimal('1.0') - Decimal(product.discount) / Decimal('100'))).quantize(Decimal('0.01'))
                except Exception:
                    final_price = Decimal(product.price)

            # Add to shop-specific list
            shop = product.created_by_shop
            processed_per_shop[shop].append({
                "product": product,
                "color": color,
                "size": size_obj,
                "color_image": color_image,
                "size_entry": size_entry,
                "quantity": total_qty,
                "final_price": final_price,
            })

        if not processed_per_shop:
            return Response({"detail": "No valid items to add to the order."}, status=status.HTTP_400_BAD_REQUEST)

        # Process orders per shop
        orders_created = []
        for shop, items in processed_per_shop.items():
            order, created = Order.objects.select_for_update().get_or_create(
                customer=customer,
                shop=shop,
                status=Order.Status.PENDING,
                defaults={"total_price": Decimal("0.00")}
            )

            total_price = Decimal("0.00")
            for p in items:
                product = p["product"]
                color = p["color"]
                size_obj = p["size"]
                size_entry = p["size_entry"]
                qty = p["quantity"]

                order_item, oi_created = OrderItem.objects.get_or_create(
                    order=order,
                    product=product,
                    color=color,
                    size=size_obj,
                    defaults={"quantity": qty}
                )

                if not oi_created:
                    OrderItem.objects.filter(pk=order_item.pk).update(quantity=F('quantity') + qty)

                # decrement stock
                if size_entry:
                    ProductColorSize.objects.filter(pk=size_entry.pk).update(stock=F('stock') - qty)
                else:
                    ProductColorImage.objects.filter(pk=p["color_image"].pk).update(stock=F('stock') - qty)

                total_price += p["final_price"] * qty

            order.total_price = total_price
            order.save(update_fields=["total_price"])
            orders_created.append(order)

    return Response({
        "detail": "Orders placed/updated successfully.",
        "order_ids": [order.id for order in orders_created]
    }, status=status.HTTP_201_CREATED)

from django.db import transaction
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import CustomerProfile, Cart, CartItem, ProductColorImage

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_cart(request):
    """
    Delete the cart for the authenticated customer.
    Optionally, can restore stock for items in the cart if needed.
    """
    user = request.user
    try:
        customer = CustomerProfile.objects.get(user=user)
    except CustomerProfile.DoesNotExist:
        return Response({"detail": "Invalid user"}, status=status.HTTP_400_BAD_REQUEST)

    cart = Cart.objects.filter(customer=customer).first()

    if not cart:
        return Response({"detail": "No cart found for this user"}, status=status.HTTP_204_NO_CONTENT)

    with transaction.atomic():
        # Optional: Restore stock before deletion (uncomment if needed)
        # for item in cart.cart_items.select_related("product", "color"):
        #     try:
        #         color_stock = ProductColorImage.objects.select_for_update().get(
        #             product=item.product,
        #             color=item.color
        #         )
        #         color_stock.stock = F("stock") + item.quantity
        #         color_stock.save(update_fields=["stock"])
        #     except ProductColorImage.DoesNotExist:
        #         pass

        # Delete cart and its items
        cart.delete()

    return Response({"detail": "Cart deleted successfully"}, status=status.HTTP_204_NO_CONTENT)
class WishlistList(APIView):
    def post(self, request):
        # Get the customer's profile using the authenticated user
        customer_profile = CustomerProfile.objects.get(user=request.user)

        # Fetch product IDs from the request body
        product_ids = request.data.get('products', [])

        # Validate product IDs: ensure they are valid and exist
        products = Product.objects.filter(id__in=product_ids)

        # Check if the product list is empty (invalid product IDs were provided)
        if not products:
            return Response({"detail": "No valid products found."}, status=status.HTTP_400_BAD_REQUEST)

        # Prepare data to create a new wishlist
        wishlist_data = {
            'name': request.data.get('name'),
            'description': request.data.get('description'),
            'customer': customer_profile,
        }

        # Create the wishlist object
        wishlist = Wishlist.objects.create(**wishlist_data)

        # Associate the products with the wishlist
        wishlist.products.set(products)
        wishlist.save()

        # Return the serialized wishlist data as a response
        serializer = WishlistSerializer(wishlist)
        return Response(serializer.data, status=status.HTTP_201_CREATED)  
class OrderViewSet(viewsets.ModelViewSet):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer


@api_view(['GET'])
def popular_products(request):
    """
    Return products ordered by popularity (number of times they appear in orders).
    """
    # Annotate products with order count and order by descending popularity
    popular_products = Product.objects.annotate(
        order_count=count('order_items')
    ).order_by('-order_count')  # Most popular first

    serializer = ProductSerializer(popular_products, many=True, context={'request': request})
    return Response(serializer.data)
class WishlistDetail(APIView):
    def get(self, request, user_id):
        if str(user_id) != str(request.user.id):
            return Response(status=status.HTTP_403_FORBIDDEN)

        try:
            # Fetch the user's wishlists
            wishlists = Wishlist.objects.filter(customer__user=request.user)
            if not wishlists:
                return Response({"detail": "No wishlists found."}, status=status.HTTP_404_NOT_FOUND)

            # Serialize the wishlists with the request context
            serializer = WishlistSerializer(wishlists, many=True, context={'request': request})
            return Response(serializer.data)

        except Wishlist.DoesNotExist:
            return Response({"detail": "No wishlists found."}, status=status.HTTP_404_NOT_FOUND)

from django.db.models import Sum
def get_best_selling_products(limit=5):
    """
    Get the top-selling products based on total quantity sold.
    :param limit: Number of top-selling products to return.
    :return: List of dictionaries containing product instances and total quantity sold.
    """
    # Aggregate total quantity sold per product
    best_selling_items = (
        OrderItem.objects
        .values('product')
        .annotate(total_quantity_sold=Sum('quantity'))
        .order_by('-total_quantity_sold')[:limit]
    )

    # Prefetch related product objects efficiently
    product_ids = [item['product'] for item in best_selling_items]
    products = Product.objects.filter(id__in=product_ids).select_related('category', 'brand', 'device_model')

    # Build list for serializer
    product_map = {p.id: p for p in products}
    best_selling_list = []
    for item in best_selling_items:
        product = product_map.get(item['product'])
        if product:
            best_selling_list.append({
                'product': product,
                'total_quantity_sold': item['total_quantity_sold']
            })

    return best_selling_list


@api_view(['GET'])
def best_selling_products(request):
    """
    API endpoint to get top-selling products with details.
    """
    top_products = get_best_selling_products(limit=5)
    serializer = BestSellingProductSerializer(top_products, many=True, context={'request': request})
    return Response(serializer.data, status=status.HTTP_200_OK)
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from datetime import datetime

from .models import Order, CustomerProfile
from .serializers import OrderSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def order_history(request):
    """
    Retrieve all orders for the authenticated customer.
    Includes detailed debugging logs for tracing issues.
    """
    print("\n--- DEBUG ORDER HISTORY START ---")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Request path: {request.path}")
    print(f"Request method: {request.method}")
    
    # Debug request headers (only important headers)
    for header, value in request.headers.items():
        if header.lower() in ['authorization', 'content-type', 'user-agent', 'accept', 'host']:
            print(f"{header}: {value}")
    print("---------------------")

    if not request.user.is_authenticated:
        print("User is ANONYMOUS. Authentication FAILED ❌")
        return Response({'error': 'Authentication required. Please log in.'}, 
                        status=status.HTTP_401_UNAUTHORIZED)

    print(f"Authenticated User: {request.user.username} (ID: {request.user.id})")

    try:
        customer_profile = request.user.customerprofile
        print(f"Found CustomerProfile: ID={customer_profile.id}")
    except CustomerProfile.DoesNotExist:
        print(f"No CustomerProfile for user {request.user.username}")
        return Response({'error': 'User profile not found. Cannot fetch orders.'}, 
                        status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        print(f"Unexpected error: {e}")
        return Response({'error': f'Internal server error: {e}'}, 
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    # Fetch orders for this customer
    orders_queryset = Order.objects.filter(customer=customer_profile).order_by('-order_date')
    num_orders_found = orders_queryset.count()
    print(f"Number of orders found: {num_orders_found}")

    # Serialize the orders
    serializer = OrderSerializer(orders_queryset, many=True, context={'request': request})

    print("--- DEBUG ORDER HISTORY END ---\n")
    return Response(serializer.data, status=status.HTTP_200_OK)
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
class OrderDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, order_id):
        """
        Retrieve a specific order for the authenticated customer.
        """
        try:
            # Ensure the user has a customer profile
            customer_profile = request.user.customerprofile
        except CustomerProfile.DoesNotExist:
            return Response({"detail": "User profile not found"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Prefetch related order_items to reduce DB queries
            order = Order.objects.prefetch_related('order_items__product', 'order_items__color') \
                                 .get(id=order_id, customer=customer_profile)
        except Order.DoesNotExist:
            return Response({"detail": "Order not found"}, status=status.HTTP_404_NOT_FOUND)

        serializer = OrderSerializer(order, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)

from .models import Logo
from .serializers import LogoSerializer

class LogoView(APIView):
    def get(self, request):
        logo = Logo.objects.last()  # get latest logo
        serializer = LogoSerializer(logo, context={'request': request})
        return Response(serializer.data)