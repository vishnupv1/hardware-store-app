# Flutter App Backend

A Node.js/Express backend API for the Flutter application with dual authentication (User and Client), MongoDB database, and JWT authentication.

## Features

- 🔐 **Dual Authentication**: Support for both User and Client accounts
- 🛡️ **Security**: JWT tokens, password hashing, rate limiting, CORS protection
- 📊 **Database**: MongoDB with Mongoose ODM
- 🔄 **API**: RESTful API with proper error handling
- 📝 **Validation**: Input validation using express-validator
- 🚀 **Performance**: Compression, caching, and optimization

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- MongoDB (local or MongoDB Atlas)

## Quick Start

### 1. Setup Backend

```bash
# Navigate to backend directory
cd backend-flutter

# Run setup script (automatically installs dependencies and creates .env)
./setup.sh

# Or manually:
npm install
cp env.example .env
```

### 2. Configure Environment

Edit the `.env` file with your configuration:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017/flutter_app_db
MONGODB_URI_PROD=mongodb://your-production-mongodb-uri

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=7d

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### 3. Start MongoDB

**Local MongoDB:**
```bash
# Start MongoDB service
mongod
```

**MongoDB Atlas:**
- Create a free cluster at [MongoDB Atlas](https://www.mongodb.com/atlas)
- Get your connection string and update `MONGODB_URI` in `.env`

### 4. Start the Server

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start
```

The server will be available at `http://localhost:3000`

## API Endpoints

### Authentication

#### Admin Authentication
- `POST /api/auth/admin/register` - Register a new admin
- `POST /api/auth/admin/login` - Login admin
- `GET /api/auth/me` - Get current admin (protected)
- `POST /api/auth/logout` - Logout (protected)

#### Employee Authentication
- `POST /api/auth/employee/register` - Register a new employee
- `POST /api/auth/employee/login` - Login employee
- `GET /api/auth/me` - Get current employee (protected)
- `POST /api/auth/logout` - Logout (protected)

#### User Authentication
- `POST /api/auth/user/register` - Register a new user
- `POST /api/auth/user/login` - Login user
- `GET /api/auth/me` - Get current user (protected)
- `POST /api/auth/logout` - Logout (protected)

#### Client Authentication
- `POST /api/auth/client/register` - Register a new client
- `POST /api/auth/client/login` - Login client
- `GET /api/auth/me` - Get current client (protected)
- `POST /api/auth/logout` - Logout (protected)

### Request Examples

#### Admin Registration
```bash
curl -X POST http://localhost:3001/api'/auth/admin/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@company.com",
    "password": "SecurePass123!",
    "firstName": "Admin",
    "lastName": "User",
    "adminId": "ADM24001",
    "department": "IT",
    "position": "System Administrator",
    "phoneNumber": "+1234567890",
    "adminLevel": "admin",
    "accessLevel": "full_access",
    "salary": 75000
  }'
```

#### Admin Login
```bash
curl -X POST http://localhost:3001/api'/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@company.com",
    "password": "SecurePass123!"
  }'
```

#### Employee Registration
```bash
curl -X POST http://localhost:3001/api'/auth/employee/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "employee@company.com",
    "password": "SecurePass123!",
    "firstName": "John",
    "lastName": "Doe",
    "employeeId": "EMP24001",
    "department": "Sales",
    "position": "Sales Representative",
    "phoneNumber": "+1234567890",
    "role": "employee",
    "salary": 50000
  }'
```

#### Employee Login
```bash
curl -X POST http://localhost:3001/api'/auth/employee/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "employee@company.com",
    "password": "SecurePass123!"
  }'
```

#### User Registration
```bash
curl -X POST http://localhost:3001/api'/auth/user/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!",
    "firstName": "John",
    "lastName": "Doe",
    "phoneNumber": "+1234567890"
  }'
```

#### User Login
```bash
curl -X POST http://localhost:3001/api'/auth/user/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!"
  }'
```

#### Client Registration
```bash
curl -X POST http://localhost:3001/api'/auth/client/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "client@company.com",
    "password": "SecurePass123!",
    "companyName": "Example Corp",
    "contactPerson": {
      "firstName": "Jane",
      "lastName": "Smith"
    },
    "address": {
      "street": "123 Business St",
      "city": "New York",
      "state": "NY",
      "zipCode": "10001"
    }
  }'
```

## Flutter App Configuration

### API Base URL

The Flutter app automatically detects the platform and uses the appropriate base URL:

- **Android Emulator**: `http://10.0.2.2:3001/api'`
- **iOS Simulator**: `http://localhost:3001/api'`
- **Physical Device**: Update the base URL in `lib/core/services/api_service.dart`

### Testing the Connection

1. Start the backend server
2. Run your Flutter app
3. Try to login with test credentials
4. Check the server logs for API requests

## Development

### Project Structure

```
src/
├── middleware/          # Custom middleware
│   ├── auth.js         # JWT authentication
│   └── errorHandler.js # Error handling
├── models/             # Database models
│   ├── User.js         # User model
│   ├── Client.js       # Client model
│   ├── Employee.js     # Employee model
│   └── Admin.js        # Admin model
├── routes/             # API routes
│   ├── auth.js         # Authentication routes
│   ├── client.js       # Client routes
│   ├── user.js         # User routes
│   ├── employees.js    # Employee routes
│   └── admins.js       # Admin routes
└── server.js           # Main server file
```

### Available Scripts

- `npm run dev` - Start development server with auto-reload
- `npm start` - Start production server
- `npm test` - Run tests
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint issues

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment | development |
| `MONGODB_URI` | MongoDB connection string | mongodb://localhost:27017/flutter_app_db |
| `JWT_SECRET` | JWT secret key | your-super-secret-jwt-key |
| `JWT_EXPIRES_IN` | JWT expiration time | 7d |

## Security Features

- **Password Hashing**: bcryptjs for secure password storage
- **JWT Tokens**: Stateless authentication
- **Rate Limiting**: Prevents brute force attacks
- **CORS Protection**: Configurable cross-origin requests
- **Input Validation**: Request data validation
- **Helmet**: Security headers
- **Account Locking**: Temporary lock after failed attempts

## Error Handling

The API returns consistent error responses:

```json
{
  "success": false,
  "message": "Error description",
  "statusCode": 400
}
```

## Health Check

Check if the server is running:

```bash
curl http://localhost:3000/health
```

Response:
```json
{
  "status": "OK",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 123.456,
  "environment": "development"
}
```

## Troubleshooting

### Common Issues

1. **MongoDB Connection Error**
   - Ensure MongoDB is running
   - Check connection string in `.env`
   - Verify network connectivity

2. **Port Already in Use**
   - Change `PORT` in `.env`
   - Kill process using the port: `lsof -ti:3000 | xargs kill`

3. **CORS Errors**
   - Update CORS configuration in `server.js`
   - Add your Flutter app's domain to allowed origins

4. **JWT Token Issues**
   - Check `JWT_SECRET` in `.env`
   - Verify token expiration settings

### Logs

Enable detailed logging by setting `NODE_ENV=development` in `.env`.

## Production Deployment

1. Set `NODE_ENV=production`
2. Use a production MongoDB instance
3. Set a strong `JWT_SECRET`
4. Configure proper CORS origins
5. Use HTTPS in production
6. Set up monitoring and logging

## License

MIT License - see LICENSE file for details.
