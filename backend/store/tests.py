from django.test import TestCase
from rest_framework.test import APIClient
from django.contrib.auth.models import User, Group
from rest_framework import status
from unittest.mock import patch

class LoginTestCase(TestCase):

    def setUp(self):
        # Create a sample user
        self.user = User.objects.create_user(username='testuser', email='test@example.com', password='password')
        self.client = APIClient()

    def test_missing_username_or_email(self):
        # Test missing username/email
        response = self.client.post('/api/login/', {'password': 'password'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Username or email and password are required', response.data['error'])

    def test_missing_password(self):
        # Test missing password
        response = self.client.post('/api/login/', {'username_or_email': 'testuser'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Username or email and password are required', response.data['error'])

    def test_user_not_found(self):
        # Test user not found
        response = self.client.post('/api/login/', {'username_or_email': 'testuser', 'password': 'password'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('User not found', response.data['error'])

    def test_invalid_credentials(self):
        # Test invalid credentials (wrong password)
        response = self.client.post('/api/login/', {'username_or_email': 'testuser', 'password': 'wrongpassword'})
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Invalid credentials', response.data['error'])

    @patch('authentication.RefreshToken.for_user')

    def test_successful_login(self, mock_refresh_token):
        # Mock token generation to avoid calling external services
        mock_refresh_token.return_value = 'mock_refresh_token'

        # Test successful login
        response = self.client.post('/api/login/', {'username_or_email': 'testuser', 'password': 'password'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertIn('refresh_token', response.data)
        self.assertIn('role', response.data)

        # Check if the role is assigned correctly
        self.assertEqual(response.data['role'], 'guest')  # No group assigned, so should default to guest
    @patch('authentication.RefreshToken.for_user')

    def test_successful_admin_login(self, mock_refresh_token):
        # Assign 'admin' group to the user
        admin_group = Group.objects.create(name='admin')
        self.user.groups.add(admin_group)

        # Mock token generation
        mock_refresh_token.return_value = 'mock_refresh_token'

        # Test successful admin login
        response = self.client.post('/api/login/', {'username_or_email': 'testuser', 'password': 'password'})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertIn('refresh_token', response.data)
        self.assertIn('role', response.data)

        # Check if the role is assigned as 'admin'
        self.assertEqual(response.data['role'], 'admin')
