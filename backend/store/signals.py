from django.db.models.signals import post_save
from django.dispatch import receiver
from django.core.mail import send_mail
from django.conf import settings
from .models import Order
import requests

# # Signal to send notification on new order creation
# @receiver(post_save, sender=Order)
# def send_order_notification(sender, instance, created, **kwargs):
#     if created:
#         # New order created
#         # Trigger notification or email here
        
#         # Example using OneSignal to send a push notification
#         send_push_notification(instance)
        
#         # Optionally, you can also send an email to admin or customer
#         send_mail(
#             'New Order Placed',
#             f'A new order has been placed with ID: {instance.id}.',
#             settings.DEFAULT_FROM_EMAIL,
#             ['ye@gmail.com'],
#             fail_silently=False,
#         )

# def send_push_notification(order):
#     # Example using OneSignal API
#     url = "https://onesignal.com/api/v1/notifications"
    
#     # Replace with your OneSignal app ID and API key
#     app_id = "85b77d0b-6047-490b-8ef8-51201329fe49"
#     api_key = "os_v2_app_qw3x2c3ai5eqxdxykeqbgkp6jhpbcgkvpa3uvtuuxc47qhcj6vpqueuv53mcnc5v62wghl5th64wwgw4uvshf6cfctkhsu5dmlartfa"
    
#     headers = {
#         'Content-Type': 'application/json',
#         'Authorization': f'Basic {api_key}',
#     }
    
#     data = {
#         "app_id": app_id,
#         "included_segments": ["All"],  # Send to all users, or customize this
#         "headings": {"en": "New Order Received"},
#         "contents": {"en": f"A new order with ID {order.id} has been placed!"},
#         "data": {"order_id": order.id},
#     }
    
#     # Send POST request to OneSignal
#     response = requests.post(url, json=data, headers=headers)
    
#     if response.status_code == 200:
#         print(f"Notification sent for order ID {order.id}")
#     else:
#         print(f"Error sending notification for order ID {order.id}: {response.text}")

from django.db.models import Sum
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import Product, ProductColorImage, ProductColorSize

@receiver([post_save, post_delete], sender=ProductColorSize)
def update_color_stock(sender, instance, **kwargs):
    color_image = instance.product_color_image

    # Calculate total stock for this color from all sizes
    total_color_stock = color_image.sizes.aggregate(total=Sum('stock'))['total'] or 0

    # Update color image stock
    ProductColorImage.objects.filter(pk=color_image.pk).update(stock=total_color_stock)

    # Update product stock as well
    product = color_image.product
    total_product_stock = ProductColorImage.objects.filter(product=product).aggregate(total=Sum('stock'))['total'] or 0
    Product.objects.filter(pk=product.pk).update(stock=total_product_stock)

@receiver([post_save, post_delete], sender=ProductColorImage)
def update_product_stock(sender, instance, **kwargs):
    """
    Updates the main Product.stock whenever a ProductColorImage is changed.
    """
    product = instance.product
    total_product_stock = ProductColorImage.objects.filter(product=product).aggregate(total=Sum('stock'))['total'] or 0
    Product.objects.filter(pk=product.pk).update(stock=total_product_stock)