# Flutter App API Documentation

## Base URL
```
http://localhost:3001/api
```

## Authentication
All API endpoints require authentication using Bearer token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

## Endpoints

### Authentication

#### Client Login
```
POST /auth/client/login
```
**Body:**
```json
{
  "email": "client@example.com",
  "password": "password123"
}
```

#### Client Registration
```
POST /auth/client/register
```
**Body:**
```json
{
  "email": "client@example.com",
  "password": "password123",
  "companyName": "Example Company",
  "contactPerson": {
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "+1234567890",
    "position": "Manager"
  },
  "address": {
    "street": "123 Main St",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001",
    "country": "USA"
  },
  "businessInfo": {
    "industry": "Technology",
    "companySize": "11-50",
    "website": "https://example.com"
  }
}
```

### Customers

#### Get All Customers
```
GET /customers?page=1&limit=20&search=john&customerType=retail&isActive=true
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20, max: 100)
- `search` (optional): Search in name, email, phone, company
- `customerType` (optional): wholesale, retail, contractor
- `isActive` (optional): true/false

#### Get Customer by ID
```
GET /customers/:id
```

#### Create Customer
```
POST /customers
```
**Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phoneNumber": "+1234567890",
  "companyName": "Doe Enterprises",
  "gstNumber": "GST123456789",
  "address": "123 Business St",
  "city": "New York",
  "state": "NY",
  "pincode": "10001",
  "customerType": "wholesale",
  "creditLimit": 10000,
  "notes": "Important customer",
  "tags": ["vip", "wholesale"]
}
```

#### Update Customer
```
PUT /customers/:id
```
**Body:** (same as create, all fields optional)

#### Delete Customer
```
DELETE /customers/:id
```
*Note: This is a soft delete (sets isActive to false)*

#### Get Customer Statistics
```
GET /customers/stats/summary
```

#### Get Low Credit Customers
```
GET /customers/low-credit
```

### Products (Inventory)

#### Get All Products
```
GET /products?page=1&limit=20&search=laptop&category=electronics&brand=apple&stockStatus=low_stock
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20, max: 100)
- `search` (optional): Search in name, SKU, brand, category
- `category` (optional): Filter by category
- `brand` (optional): Filter by brand
- `isActive` (optional): true/false
- `stockStatus` (optional): in_stock, low_stock, out_of_stock

#### Get Product by ID
```
GET /products/:id
```

#### Create Product
```
POST /products
```
**Body:**
```json
{
  "name": "MacBook Pro 13",
  "description": "13-inch MacBook Pro with M2 chip",
  "category": "Electronics",
  "subcategory": "Laptops",
  "brand": "Apple",
  "model": "M2",
  "sku": "MBP13-M2-256",
  "costPrice": 1200,
  "sellingPrice": 1500,
  "wholesalePrice": 1350,
  "stockQuantity": 50,
  "minStockLevel": 10,
  "unit": "pieces",
  "imageUrl": "https://example.com/macbook.jpg",
  "barcode": "1234567890123",
  "weight": 1.4,
  "dimensions": {
    "length": 30.4,
    "width": 21.2,
    "height": 1.6
  },
  "supplier": {
    "name": "Apple Inc",
    "contact": "John Supplier",
    "email": "supplier@apple.com"
  },
  "reorderPoint": 5,
  "reorderQuantity": 20,
  "tags": ["laptop", "apple", "premium"],
  "specifications": {
    "processor": "M2",
    "ram": "8GB",
    "storage": "256GB SSD"
  }
}
```

#### Update Product
```
PUT /products/:id
```
**Body:** (same as create, all fields optional)

#### Delete Product
```
DELETE /products/:id
```
*Note: This is a soft delete (sets isActive to false)*

#### Update Product Stock
```
POST /products/:id/stock
```
**Body:**
```json
{
  "quantity": 10,
  "type": "add",
  "reason": "Restocked from supplier"
}
```
**Types:** add, subtract, set

#### Get Product Statistics
```
GET /products/stats/summary
```

#### Get Low Stock Products
```
GET /products/low-stock
```

#### Get Product Categories
```
GET /products/categories
```

#### Get Product Brands
```
GET /products/brands
```

### Sales

#### Get All Sales
```
GET /sales?page=1&limit=20&customerId=123&paymentStatus=pending&startDate=2024-01-01&endDate=2024-12-31
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20, max: 100)
- `customerId` (optional): Filter by customer ID
- `paymentStatus` (optional): pending, paid, partial, failed
- `saleStatus` (optional): completed, cancelled, returned, refunded
- `startDate` (optional): ISO 8601 date
- `endDate` (optional): ISO 8601 date

#### Get Sale by ID
```
GET /sales/:id
```

#### Create Sale
```
POST /sales
```
**Body:**
```json
{
  "customerId": "507f1f77bcf86cd799439011",
  "items": [
    {
      "productId": "507f1f77bcf86cd799439012",
      "quantity": 2,
      "unitPrice": 1500,
      "discount": 100
    }
  ],
  "paymentMethod": "card",
  "paymentStatus": "paid",
  "saleStatus": "completed",
  "taxAmount": 150,
  "discountAmount": 50,
  "shippingCost": 25,
  "notes": "Customer requested express delivery",
  "shippingAddress": {
    "street": "123 Customer St",
    "city": "New York",
    "state": "NY",
    "pincode": "10001",
    "country": "USA"
  }
}
```

#### Update Sale
```
PUT /sales/:id
```
**Body:**
```json
{
  "paymentStatus": "paid",
  "notes": "Payment received",
  "refundAmount": 0,
  "refundReason": ""
}
```

#### Cancel Sale
```
DELETE /sales/:id
```
*Note: This cancels the sale and restores product stock*

#### Return Sale Items
```
POST /sales/:id/return
```
**Body:**
```json
{
  "items": [
    {
      "productId": "507f1f77bcf86cd799439012",
      "quantity": 1
    }
  ],
  "refundAmount": 1500,
  "refundReason": "Customer changed mind"
}
```

#### Get Sales Statistics
```
GET /sales/stats/summary?startDate=2024-01-01&endDate=2024-12-31
```

#### Get Pending Payments
```
GET /sales/pending-payments
```

#### Get Customer Sales
```
GET /sales/customer/:customerId
```

## Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": {
    // Response data
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "errors": [
    {
      "field": "email",
      "message": "Please enter a valid email address"
    }
  ]
}
```

### Paginated Response
```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "totalPages": 5,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

## Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `404` - Not Found
- `500` - Internal Server Error

## Features

### Customers
- ✅ Full CRUD operations
- ✅ Search and filtering
- ✅ Pagination
- ✅ Customer types (wholesale, retail, contractor)
- ✅ Credit limit management
- ✅ Statistics and analytics
- ✅ Soft delete

### Products (Inventory)
- ✅ Full CRUD operations
- ✅ Advanced search and filtering
- ✅ Stock management
- ✅ Categories and brands
- ✅ Barcode support
- ✅ Supplier information
- ✅ Reorder points
- ✅ Statistics and analytics
- ✅ Soft delete

### Sales
- ✅ Full CRUD operations
- ✅ Multi-item sales
- ✅ Payment status tracking
- ✅ Sale status management
- ✅ Returns and refunds
- ✅ Stock auto-update
- ✅ Customer statistics update
- ✅ Invoice number generation
- ✅ Date range filtering
- ✅ Statistics and analytics

### Security Features
- ✅ JWT authentication
- ✅ Role-based authorization
- ✅ Input validation
- ✅ Rate limiting
- ✅ CORS protection
- ✅ Helmet security headers
- ✅ Request compression

### Performance Features
- ✅ Database indexing
- ✅ Pagination
- ✅ Efficient queries
- ✅ Response compression
- ✅ Connection pooling

## Usage Examples

### Flutter Integration

```dart
// Get customers
final response = await apiService.getCustomers(
  page: 1,
  limit: 20,
  search: 'john',
  customerType: 'retail'
);

// Create customer
final customerData = {
  'name': 'John Doe',
  'email': 'john@example.com',
  'phoneNumber': '+1234567890',
  'customerType': 'retail',
  'creditLimit': 5000
};
final response = await apiService.createCustomer(customerData);

// Get products
final response = await apiService.getProducts(
  search: 'laptop',
  category: 'electronics',
  stockStatus: 'low_stock'
);

// Create sale
final saleData = {
  'customerId': 'customer_id',
  'items': [
    {
      'productId': 'product_id',
      'quantity': 2,
      'unitPrice': 100
    }
  ],
  'paymentMethod': 'card',
  'paymentStatus': 'paid'
};
final response = await apiService.createSale(saleData);
```

This API provides a complete backend solution for your Flutter inventory management app with all the necessary CRUD operations, security features, and performance optimizations.
