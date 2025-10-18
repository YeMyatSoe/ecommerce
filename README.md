# 🛒 Multi-Shop Ecommerce Platform

A full-stack **multi-vendor ecommerce platform** built with **Django REST Framework** (backend) and **Flutter Web** (frontend).  
Designed to handle multiple shops, advanced user roles, and product variants (color, size, stock).

---

## 🚀 Features

### 🌐 Frontend (Flutter Web)
- Responsive web UI for shopping
- Product browsing with search & filters
- Shopping cart and checkout
- User login/register with JWT tokens
- Live demo: [https://yemyatsoe.github.io/ecommerce/](https://yemyatsoe.github.io/ecommerce/)

### ⚙️ Backend (Django + DRF)
- **Multi-shop support**: Users can own shops and manage products
- **User Authentication & Authorization**:
  - JWT with refresh & access tokens
  - Role-based permissions for shop managers
- **Admin Dashboard**: Django default admin for superuser
- **Product Variants**:
  - Each product can have multiple colors and sizes
  - Stock management per variant
- **RESTful APIs** for frontend consumption
- **CORS enabled** for Flutter Web
- **Static file handling** via WhiteNoise

---

## 🗂️ Project Structure

ecommerce/
├── backend/
│ ├── backend/
│ │ ├── settings.py
│ │ ├── urls.py
│ │ └── wsgi.py
│ ├── store/
│ │ ├── models.py # Products, Shops, Variants
│ │ ├── views.py
│ │ └── serializers.py
│ ├── requirements.txt
│ ├── manage.py
│ └── staticfiles/
└── frontend/
├── lib/
├── web/
├── pubspec.yaml
└── build/

