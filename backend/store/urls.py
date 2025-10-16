from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views
from .views import (
    BannerViewSet, BrandViewSet, CartViewSet, CategoryViewSet, ColorViewSet, DeviceModelViewSet,
    LikeReviewView, LoginView, OrderDetailView, ProductColorImagesView, ProductRetrieveByNameView, ProductRetrieveView,
    ProfileUpdateView, ProfileView, ReplyReviewView, ReviewViewSet, SizeViewSet, TokenVerifyView, UserViewSet,
    WishlistDetail, WishlistList, submit_cart, AboutPageAPIView)
from .views import LogoView
from rest_framework_simplejwt.views import TokenRefreshView

router = DefaultRouter()
router.register(r'products', views.ProductViewSet)
router.register(r'banners', BannerViewSet)
router.register(r'reviews', ReviewViewSet)
router.register(r'users', UserViewSet)
router.register(r'colors', ColorViewSet)
router.register(r'categories', CategoryViewSet, basename='categories')
router.register(r'brands', BrandViewSet, basename='brand')
router.register(r'device-models', DeviceModelViewSet, basename='models')
router.register(r'carts', views.CartViewSet, basename='cart')
router.register(r'sizes', SizeViewSet, basename='size')
urlpatterns = [
    path('login/', LoginView.as_view(), name='login'),
    path('verify-token/', TokenVerifyView.as_view(), name='verify_token'),
    path('refresh-token/', views.refresh_token_view, name='refresh-token'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('editprofile/', ProfileUpdateView.as_view(), name='editprofile'),
    path('', include(router.urls)),  # Register viewsets here
    path('products/<int:id>/', ProductRetrieveView.as_view(), name='product-retrieve'),
    path('products/name/<str:name>/', ProductRetrieveByNameView.as_view(), name='product-retrieve-by-name'),
    path('products/<int:product_id>/reviews/', views.ReviewListCreateView.as_view(), name='product-reviews'),
    path('product/<int:product_id>/reviews/', views.submit_review, name='submit_review'),
    path('register/', views.register, name='register'),
    path('reviews/<int:review_id>/like/', LikeReviewView.as_view(), name='like_review'),
    path('reviews/<int:review_id>/reply/', ReplyReviewView.as_view(), name='reply_review'),
    path('cart/', views.add_to_cart, name='cart-items'),
    path('getcart/', views.get_cart, name='get_cart'),
    path('cart/remove/', views.remove_from_cart, name='remove-from-cart'),
    path('cart/increment/', views.increment_quantity, name='increment-quantity'),
    path('cart/decrement/', views.decrement_quantity, name='decrement-quantity'),
    path('delete_cart/', views.delete_cart, name='delete_cart'),
    path('orders/', submit_cart, name='submit_cart'),
    path('popular_products/', views.popular_products, name='popular-products'),
    path('wishlists/', WishlistList.as_view(), name='wishlist-list'),
    path('wishlists/user/<int:user_id>/', WishlistDetail.as_view(), name='wishlist-detail'),
    path('best_selling_products/', views.best_selling_products, name='best_selling_products'),
    path('search/', views.search_products, name='search_product'),
    path('checkorder/', views.order_history, name='order_history'),
    path('checkorder/<int:order_id>/', OrderDetailView.as_view(), name='checkorder'),
    path('products/<int:product_id>/color-images/', ProductColorImagesView.as_view(), name='product-color-images'),
    path('logo/', LogoView.as_view(), name='logo-api'),
    path('about/', AboutPageAPIView.as_view(), name='about-page'),
]
