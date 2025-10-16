from email.headerregistry import Group
from itertools import product
from traceback import format_tb
from django.contrib import admin
from django.contrib.auth.models import User, Group
import nested_admin # <-- Add Group here
from .models import (
    ProductColorImage, ProductColorSize, Role, Shop, Employee, Banner, BannerImage, Cart, CartItem, Color,
    Order, OrderItem, Product, Category, Brand, DeviceModel, Reply, Review,
    ShopInventory, Size, Wishlist, SalesSummary, Logo, AboutPageContent, Blog, Partner

)
from django.contrib.admin import TabularInline
from django.db.models import Sum, Q
from datetime import timedelta
from django.utils.timezone import localdate
# store/admin.py
from django import forms
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DefaultUserAdmin
from django.contrib.auth.models import User
from .models import Shop, Employee # Add any other models you have

# Unregister the default UserAdmin


# Create a custom UserAdmin to restrict permissions
from django.contrib.auth.admin import UserAdmin as DefaultUserAdmin
from django.contrib.auth.models import User
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.contrib.auth.models import User

from django.db.models.signals import post_save
from django.dispatch import receiver
# admin.site.register(ProductColorSize)
@receiver(post_save, sender=Employee)
def assign_role_group_permissions(sender, instance, **kwargs):
    """
    When an Employee is created or updated, assign the corresponding
    permissions group from the role to the associated User.
    """
    user = instance.user
    role = instance.role
    if role and role.permissions_group:
        user.groups.clear()
        user.groups.add(role.permissions_group)
        user.save()

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DefaultUserAdmin
from django.contrib.auth.models import User, Permission
from .models import Employee, Role, Shop

#------------------EmployeeForm-------------------
from django import forms
from django.contrib.auth.models import User
from .models import Employee, Shop, Role

class EmployeeCreationForm(forms.ModelForm):
    # Add User fields manually
    username = forms.CharField(required=True)
    password = forms.CharField(widget=forms.PasswordInput, required=True)
    first_name = forms.CharField(required=False)
    last_name = forms.CharField(required=False)
    email = forms.EmailField(required=False)

    class Meta:
        model = Employee
        fields = ['shop', 'role', 'position', 'phone']

    def __init__(self, *args, **kwargs):
        self.request = kwargs.pop('request', None)
        super().__init__(*args, **kwargs)

        if self.request and not self.request.user.is_superuser:
            # Limit shop choices
            self.fields['shop'].queryset = self.request.user.owned_shops.all()
            # Limit roles
            if self.request.user.owned_shops.exists():
                owned_shop = self.request.user.owned_shops.first()
                self.fields['role'].queryset = Role.objects.filter(shop=owned_shop)

    def save(self, commit=True):
        # Create the user first
        user_data = {
            'username': self.cleaned_data['username'],
            'first_name': self.cleaned_data.get('first_name', ''),
            'last_name': self.cleaned_data.get('last_name', ''),
            'email': self.cleaned_data.get('email', ''),
        }
        password = self.cleaned_data['password']
        user = User.objects.create(**user_data)
        user.set_password(password)
        user.is_staff = True  # Needed if you want them to access admin
        user.save()

        # Create the Employee
        employee = super().save(commit=False)
        employee.user = user
        if commit:
            employee.save()
        return employee


# ----------------- Employee Inline -----------------
class EmployeeInline(admin.StackedInline):
    model = Employee
    fields = ('shop', 'role', 'position', 'phone')
    extra = 1

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if hasattr(request.user, 'owned_shops') and not request.user.is_superuser:
            return qs.filter(shop__owner=request.user)
        return qs

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == 'shop' and hasattr(request.user, 'owned_shops') and not request.user.is_superuser:
            kwargs['queryset'] = request.user.owned_shops.all()
        if db_field.name == 'role' and hasattr(request.user, 'owned_shops') and not request.user.is_superuser:
            owned_shop = request.user.owned_shops.first()
            kwargs['queryset'] = Role.objects.filter(shop=owned_shop)
        return super().formfield_for_foreignkey(db_field, request, **kwargs)

# ----------------- Employee Admin -----------------
class EmployeeAdmin(admin.ModelAdmin):
    form = EmployeeCreationForm
    list_display = ['user', 'shop', 'role', 'position']
    list_filter = ['shop', 'role']

    def get_form(self, request, obj=None, **kwargs):
        # Make sure request is passed to the form
        kwargs['form'] = self.form
        form_class = super().get_form(request, obj, **kwargs)
        # Attach request to form instance
        class FormWithRequest(form_class):
            def __new__(cls, *args, **kwargs2):
                kwargs2['request'] = request
                return form_class(*args, **kwargs2)
        return FormWithRequest

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        # Assign the role's group automatically
        if obj.role and obj.role.permissions_group:
            obj.user.groups.clear()
            obj.user.groups.add(obj.role.permissions_group)
            obj.user.save()

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'owned_shops'):
            return qs.filter(shop__owner=request.user)
        if hasattr(request.user, 'employee_profile'):
            return qs.filter(user=request.user)
        return qs.none()

    def has_add_permission(self, request):
        return request.user.is_superuser or (hasattr(request.user, 'owned_shops') and request.user.has_perm('auth.add_user'))

    def has_change_permission(self, request, obj=None):
        if request.user.is_superuser:
            return True
        if obj is None:
            return hasattr(request.user, 'owned_shops')
        if hasattr(request.user, 'owned_shops') and obj:
            return obj.shop.owner == request.user
        if hasattr(request.user, 'employee_profile') and obj:
            return obj.user == request.user
        return False

    def has_delete_permission(self, request, obj=None):
        if request.user.is_superuser:
            return True
        if obj is None:
            return False
        if hasattr(request.user, 'owned_shops') and obj:
            return obj.shop.owner == request.user
        return False
# ----------------- Custom User Admin -----------------
class CustomUserAdmin(DefaultUserAdmin):
    inlines = [EmployeeInline]

    def has_add_permission(self, request):
        return request.user.is_superuser or (hasattr(request.user, 'owned_shops') and request.user.has_perm('auth.add_user'))

    def has_change_permission(self, request, obj=None):
        if request.user.is_superuser:
            return True

        # Can edit own profile
        if obj and obj.id == request.user.id:
            return True

        # Shop owner editing their employee
        if obj and hasattr(request.user, 'owned_shops') and hasattr(obj, 'employee_profile'):
            return obj.employee_profile.shop.owner == request.user

        # **Fix: allow shop owner to access add page and user list**
        if obj is None and hasattr(request.user, 'owned_shops'):
            return True

        return False


    def has_delete_permission(self, request, obj=None):
        return request.user.is_superuser

    def get_fieldsets(self, request, obj=None):
        if request.user.is_superuser:
            return super().get_fieldsets(request, obj)
        if obj and obj.id == request.user.id:
            return (
                (None, {'fields': ('username',)}),
                ('Personal info', {'fields': ('first_name', 'last_name', 'email')}),
            )
        if obj and hasattr(request.user, 'owned_shops') and hasattr(obj, 'employee_profile'):
            if obj.employee_profile.shop.owner == request.user:
                return (
                    (None, {'fields': ('username', 'password')}),
                    ('Personal info', {'fields': ('first_name', 'last_name', 'email')}),
                )
        return ()

# ----------------- Register Admins -----------------
admin.site.unregister(User)
admin.site.register(User, CustomUserAdmin)
admin.site.register(Employee, EmployeeAdmin)

class ShopAdmin(admin.ModelAdmin):
    list_display = ['name', 'owner', 'contact_email']

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'owned_shops'):
            return qs.filter(owner=request.user)
        if hasattr(request.user, 'employee_profile'):
            return qs.filter(id=request.user.employee_profile.shop.id)
        return qs.none()

    def has_change_permission(self, request, obj=None):
        if request.user.is_superuser:
            return True
        if obj is None:
            return True
        if hasattr(request.user, 'employee_profile'):
            return obj == request.user.employee_profile.shop
        return obj.owner == request.user

    def has_delete_permission(self, request, obj=None):
        return self.has_change_permission(request, obj)

admin.site.register(Shop, ShopAdmin)

class RoleAdmin(admin.ModelAdmin):
    list_display = ['name', 'shop', 'permissions_group']
    list_filter = ['shop']

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'owned_shops'):
            return qs.filter(shop__owner=request.user)
        return qs.none()

    def has_add_permission(self, request):
        return request.user.is_superuser or hasattr(request.user, 'owned_shops')

    def has_change_permission(self, request, obj=None):
        if request.user.is_superuser:
            return True
        if obj is None:
            return hasattr(request.user, 'owned_shops')
        if hasattr(request.user, 'owned_shops'):
            return obj.shop.owner == request.user
        return False

    def has_delete_permission(self, request, obj=None):
        return self.has_change_permission(request, obj)

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == "shop" and not request.user.is_superuser:
            kwargs["queryset"] = request.user.owned_shops.all()
        return super().formfield_for_foreignkey(db_field, request, **kwargs)

admin.site.register(Role, RoleAdmin)




# Controlled Global Models
class CategoryAdmin(admin.ModelAdmin):
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        try:
            employee = request.user.employee_profile
            product_categories = Product.objects.filter(
                created_by_shop=employee.shop
            ).values_list('category', flat=True)
            return qs.filter(id__in=product_categories)
        except:
            return qs.none()
admin.site.register(Category, CategoryAdmin)

class BrandAdmin(admin.ModelAdmin):
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        try:
            employee = request.user.employee_profile
            product_brands = Product.objects.filter(
                created_by_shop=employee.shop
            ).values_list('brand', flat=True)
            return qs.filter(id__in=product_brands)
        except:
            return qs.none()
admin.site.register(Brand, BrandAdmin)

class DeviceModelAdmin(admin.ModelAdmin):
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        try:
            employee = request.user.employee_profile
            product_device_models = Product.objects.filter(
                created_by_shop=employee.shop
            ).values_list('device_model', flat=True)
            return qs.filter(id__in=product_device_models)
        except:
            return qs.none()
admin.site.register(DeviceModel, DeviceModelAdmin)

# Create a custom admin class for Color
class ColorAdmin(admin.ModelAdmin):
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        try:
            employee = request.user.employee_profile
            # Get a list of color IDs from products in the employee's shop
            shop_product_color_ids = ProductColorImage.objects.filter(
                product__created_by_shop=employee.shop
            ).values_list('color', flat=True)
            return qs.filter(id__in=shop_product_color_ids).distinct()
        except:
            return qs.none()

admin.site.register(Color, ColorAdmin)
admin.site.register(Size)
# store/admin.py

# ... other code
class WishlistAdmin(admin.ModelAdmin):
    # This line must be indented
    list_display = ('customer', 'product_item_fk', 'color_fk', 'wishlist_date')

    def get_queryset(self, request):
        # This function and its contents must also be indented
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        try:
            employee = request.user.employee_profile
            product_ids = employee.shop.inventories.values_list('product_id', flat=True)
            return qs.filter(product_item_id__in=product_ids)
        except (AttributeError, TypeError):
            return qs.none()

admin.site.register(Wishlist)

# Banner Admin (Unchanged as requested)
class BannerImageInline(admin.TabularInline):
    model = BannerImage
    extra = 1
class BannerAdmin(admin.ModelAdmin):
    inlines = [BannerImageInline]
admin.site.register(Banner, BannerAdmin)
class ProductColorSizeInline(nested_admin.NestedTabularInline):
    model = ProductColorSize
    extra = 1

class ProductColorImageInline(nested_admin.NestedTabularInline):
    model = ProductColorImage
    inlines = [ProductColorSizeInline]  # Nested sizes inside color
    extra = 1
    show_change_link = True
class ProductColorImageAdmin(admin.ModelAdmin):
    list_display = ('product', 'color', 'stock')
    readonly_fields = ('stock',)
    inlines = [ProductColorSizeInline]

# admin.site.register(ProductColorImage, ProductColorImageAdmin)
class ProductAdmin(nested_admin.NestedModelAdmin):
    list_display = ['name', 'price', 'stock', 'created_by_shop']
    inlines = [ProductColorImageInline]

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        try:
            employee = request.user.employee_profile
            return qs.filter(created_by_shop=employee.shop)
        except:
            return qs.none()

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == "created_by_shop" and not request.user.is_superuser:
            try:
                employee = request.user.employee_profile
                kwargs["queryset"] = employee.shop.__class__.objects.filter(pk=employee.shop.pk)
            except:
                kwargs["queryset"] = employee.shop.__class__.objects.none()
        return super().formfield_for_foreignkey(db_field, request, **kwargs)

    def save_model(self, request, obj, form, change):
        if not request.user.is_superuser:
            obj.created_by_shop = request.user.employee_profile.shop
        super().save_model(request, obj, form, change)

admin.site.register(Product, ProductAdmin)

# ShopInventory Admin
class ShopInventoryAdmin(admin.ModelAdmin):
    list_display = ['shop', 'product', 'custom_price', 'custom_stock']
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        try:
            employee = request.user.employee_profile
            return qs.filter(shop=employee.shop)
        except:
            return qs.none()
    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == "product" and not request.user.is_superuser:
            try:
                employee = request.user.employee_profile
                kwargs["queryset"] = Product.objects.filter(created_by_shop=employee.shop)
            except:
                kwargs["queryset"] = Product.objects.none()
        return super().formfield_for_foreignkey(db_field, request, **kwargs)
    def save_model(self, request, obj, form, change):
        if not request.user.is_superuser:
            obj.shop = request.user.employee_profile.shop
        super().save_model(request, obj, form, change)
    def has_change_permission(self, request, obj=None):
        if request.user.is_superuser:
            return True
        if obj is None:
            return True
        try:
            employee = request.user.employee_profile
            return obj.shop == employee.shop
        except (AttributeError, TypeError):
            return False
    def has_delete_permission(self, request, obj=None):
        return self.has_change_permission(request, obj)
admin.site.register(ShopInventory, ShopInventoryAdmin)
# Admin configuration for OrderItem when displayed as an inline


# Inline for displaying OrderItems within the OrderAdmin page
class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    # FIX: Use a custom method to display size, gracefully handling None values.
    fields = ('product', 'color', 'get_size', 'quantity')
    readonly_fields = ('product', 'color', 'get_size', 'quantity')
    can_delete = False

    def get_size(self, obj):
        return obj.size.name if obj.size else '-'
    get_size.short_description = 'Size'

# The main OrderAdmin class
@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        'id', 'customer', 'order_date', 'total_price', 'status', 'shop',
        'get_product_names', 'get_order_colors', 'get_order_sizes', 'get_quantity'
    )
    search_fields = ('customer__user__username', 'product_description')
    list_filter = ('status', 'order_date', 'shop')
    inlines = [OrderItemInline]
    readonly_fields = ('total_price', 'shop', 'customer')

    # FIX: Override get_queryset to prefetch related data for list_display
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        
        # Prefetch order_items and their related product, color, and size
        qs = qs.prefetch_related(
            'order_items',
            'order_items__product',
            'order_items__color',
            'order_items__size'
        )

        # The existing user-based filtering logic
        if request.user.is_superuser:
            return qs
        if hasattr(request.user, 'employee_profile'):
            return qs.filter(shop=request.user.employee_profile.shop)
        if hasattr(request.user, 'owned_shops'):
            return qs.filter(shop__owner=request.user)
        return qs.none()

    # The rest of the OrderAdmin methods remain the same...
    def get_product_names(self, obj):
        return ", ".join([item.product.name for item in obj.order_items.all()])
    get_product_names.short_description = 'Products'

    def get_order_colors(self, obj):
        return ", ".join([item.color.color_name for item in obj.order_items.all()])
    get_order_colors.short_description = 'Order Colors'

    def get_order_sizes(self, obj):
        # This will now use the prefetched data, avoiding extra queries
        return ", ".join([item.size.name for item in obj.order_items.all() if item.size])
    get_order_sizes.short_description = 'Sizes'

    def get_quantity(self, obj):
        return sum([item.quantity for item in obj.order_items.all()])
    get_quantity.short_description = 'Total Quantity'
    
# For Cart (provided for context, no change needed)
class CartItemInline(admin.TabularInline):
    model = CartItem
    extra = 1
    fields = ('product', 'color', 'size', 'quantity')  # Added size
    readonly_fields = ('product', 'color', 'size')

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == "product" and not request.user.is_superuser:
            try:
                employee = request.user.employee_profile
                product_ids = employee.shop.inventories.values_list('product_id', flat=True)
                kwargs["queryset"] = Product.objects.filter(id__in=product_ids)
            except:
                kwargs["queryset"] = Product.objects.none()
        return super().formfield_for_foreignkey(db_field, request, **kwargs)


class CartAdmin(admin.ModelAdmin):
    list_display = (
        'id', 'customer', 'cart_date', 'total_price',
        'product_description', 'get_cart_colors', 'get_cart_sizes', 'get_quantity'
    )
    search_fields = ('customer__user__username', 'product_description', 'cart_items__product__name')
    list_filter = ('cart_date', 'cart_items__product__category', 'cart_items__product__brand')
    inlines = [CartItemInline]

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        try:
            employee = request.user.employee_profile
            product_ids = employee.shop.inventories.values_list('product_id', flat=True)
            return qs.filter(cart_items__product_id__in=product_ids).distinct()
        except:
            return qs.none()

    def save_model(self, request, obj, form, change):
        if not obj.pk:
            obj.save()
        super().save_model(request, obj, form, change)

    def get_cart_colors(self, obj):
        return ", ".join([item.color.color_name for item in obj.cart_items.all()])
    get_cart_colors.short_description = 'Cart Colors'

    def get_cart_sizes(self, obj):
        return ", ".join([item.size.name for item in obj.cart_items.all() if item.size])
    get_cart_sizes.short_description = 'Sizes'

    def get_quantity(self, obj):
        return sum([item.quantity for item in obj.cart_items.all()])
    get_quantity.short_description = 'Total Quantity'

admin.site.register(Cart, CartAdmin)
# store/admin.py

from django.contrib import admin
from .models import Review, Reply, Product  # Ensure all necessary models are imported

# Register the models with their admin classes
# ... (other admin classes)

class ReviewAdmin(admin.ModelAdmin):
    # Corrected list_display based on assumed models.py
    list_display = ['product', 'user', 'rating', 'created_at']

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        try:
            employee = request.user.employee_profile
            product_ids = employee.shop.inventories.values_list('product_id', flat=True)
            return qs.filter(product_id__in=product_ids)
        except:
            return qs.none()

admin.site.register(Review, ReviewAdmin)

class ReplyAdmin(admin.ModelAdmin):
    # Corrected list_display based on assumed models.py
    list_display = ['review', 'user', 'created_at']
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        try:
            employee = request.user.employee_profile
            product_ids = employee.shop.inventories.values_list('product_id', flat=True)
            return qs.filter(review__product_id__in=product_ids)
        except:
            return qs.none()
    
    def save_model(self, request, obj, form, change):
        if not request.user.is_superuser:
            obj.employee = request.user.employee_profile # This line needs to be corrected as well
        super().save_model(request, obj, form, change)

admin.site.register(Reply, ReplyAdmin)
# Assuming SalesSummary model has a ForeignKey to Order
# which has a ManyToMany relationship with Product

@admin.register(SalesSummary)
class SalesSummaryAdmin(admin.ModelAdmin):
    list_filter = (
        ('order_date', admin.DateFieldListFilter),
    )
    change_list_template = 'admin/sales_summary_change_list.html'

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        try:
            employee = request.user.employee_profile
            # Get product IDs linked to the employee's shop
            product_ids = employee.shop.inventories.values_list('product_id', flat=True)
            # Filter sales summaries by orders that contain those products
            return qs.filter(order__order_items__product_id__in=product_ids).distinct()
        except:
            return qs.none()

    def changelist_view(self, request, extra_context=None):
        response = super().changelist_view(request, extra_context)
        try:
            queryset = response.context_data['cl'].queryset

            chart_data = []
            chart_labels = []

            if queryset.exists():
                start_date = queryset.order_by('order_date').first().order_date
                end_date = queryset.order_by('-order_date').first().order_date
                delta = (end_date - start_date).days + 1
                for i in range(delta):
                    day = start_date + timedelta(days=i)
                    total = queryset.filter(order_date=day).aggregate(total=Sum('total_price'))['total'] or 0
                    chart_labels.append(day.strftime('%b %d'))
                    chart_data.append(float(total))

            extra_context = extra_context or {}
            extra_context['chart_labels'] = chart_labels
            extra_context['chart_data'] = chart_data

            response.context_data.update(extra_context)
        except (AttributeError, KeyError):
            pass

        return response
    
admin.site.register(Logo)
admin.site.register(AboutPageContent)
admin.site.register(Blog)
admin.site.register(Partner)