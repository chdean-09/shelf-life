# 🥫 ShelfLife

**Tagline:** *Stop Hoarding. Start Saving.*

---

## 📋 Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Features](#features)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [Development Roadmap](#development-roadmap)
- [API Documentation](#api-documentation)
- [Database Schema](#database-schema)
- [Contributing](#contributing)

---

## 🎯 Overview

**ShelfLife** is an offline-first smart pantry management application designed to combat food waste and eliminate the "buy and forget" cycle. By combining computer vision for packaged goods recognition with intelligent shelf-life estimation for fresh produce, ShelfLife provides users with a unified, prioritized view of their kitchen inventory with a focus on expiration timelines.

### Key Differentiators

- **Hybrid Recognition System**: Barcode scanning + OCR for packaged goods, USDA-backed shelf-life estimates for fresh produce
- **Expiration-First UI**: Items are prioritized by urgency, not alphabetically
- **Offline-First Architecture**: Full functionality without internet connectivity
- **Waste Gamification**: Track monetary loss from discarded food to drive behavioral change
- **Multi-Device Sync**: Cloud synchronization allows household members to share inventory

---

## 🛠️ Tech Stack

### Mobile Application (Flutter)

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Framework** | Flutter | ^3.19.0 | Cross-platform UI framework (iOS/Android) |
| **Language** | Dart | ^3.3.0 | Primary programming language |
| **State Management** | flutter_riverpod | ^2.5.1 | Reactive state management with provider pattern |
| **Local Database** | isar / isar_flutter_libs | ^3.1.0 | High-performance NoSQL database for offline-first storage |
| **Code Generation** | isar_generator + build_runner | ^3.1.0 / ^2.4.7 | Generates Isar database schemas and models |
| **Secure Storage** | flutter_secure_storage | ^9.0.0 | Encrypted storage for JWT tokens (Keychain/KeyStore) |
| **HTTP Client** | dio | ^5.4.0 | HTTP client with interceptors for API communication |
| **Barcode Scanner** | mobile_scanner | ^4.0.0 | MLKit-powered barcode/QR code scanning |
| **OCR Engine** | google_mlkit_text_recognition | ^0.11.0 | On-device text recognition for expiry dates |
| **Charts** | fl_chart | ^0.66.0 | Data visualization for waste tracking |
| **Notifications** | flutter_local_notifications | ^16.3.0 | Local push notifications for expiring items |
| **Social Auth** | google_sign_in | ^6.2.1 | Google OAuth integration |
| **Device Storage** | path_provider | ^2.1.1 | Access to application storage directories |

### Backend API (Go)

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| **Language** | Go | 1.21+ | Backend programming language |
| **Web Framework** | Gin | ^1.10.0 | High-performance HTTP web framework |
| **ORM** | GORM | ^1.25.0 | Database ORM with migration support |
| **Database Driver** | gorm.io/driver/postgres | ^1.5.0 | PostgreSQL driver for GORM |
| **Authentication** | golang-jwt/jwt | ^5.2.0 | JWT token generation and validation |
| **Password Hashing** | golang.org/x/crypto/bcrypt | latest | Secure password hashing |
| **Environment Config** | joho/godotenv | ^1.5.1 | .env file parser |
| **Google Auth** | google.golang.org/api/idtoken | latest | Google ID token verification |
| **Database** | PostgreSQL | 15+ | Relational database for user data and sync |
| **Containerization** | Docker | latest | Development and deployment containerization |

### External Services & APIs

| Service | Purpose | Fallback Strategy |
|---------|---------|-------------------|
| **OpenFoodFacts API** | Product metadata retrieval (name, brand, image) | Local barcode cache |
| **USDA FoodKeeper Database** | Shelf-life estimates for 600+ food items | Bundled JSON asset (~4MB) |
| **Google OAuth 2.0** | Optional social authentication | Email/password fallback |

---

## 🏗️ Architecture

### High-Level Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         FLUTTER APP                              │
│  ┌────────────────┐  ┌──────────────┐  ┌───────────────────┐   │
│  │  UI Layer      │  │ State Mgmt   │  │  Services Layer   │   │
│  │  (Widgets)     │◄─┤  (Riverpod)  │◄─┤  (API / Database) │   │
│  └────────────────┘  └──────────────┘  └───────────────────┘   │
│                                             │         │          │
│                                             │         │          │
│                                             ▼         ▼          │
│                                       ┌─────────┐ ┌─────────┐   │
│                                       │  Isar   │ │   Dio   │   │
│                                       │  (DB)   │ │ (HTTP)  │   │
│                                       └─────────┘ └────┬────┘   │
└────────────────────────────────────────────────────────┼────────┘
                                                          │
                                            ┌─────────────▼────────────┐
                                            │    Internet (Optional)   │
                                            └─────────────┬────────────┘
                                                          │
┌─────────────────────────────────────────────────────────▼────────────┐
│                         GO BACKEND API                                │
│  ┌────────────────┐  ┌──────────────┐  ┌───────────────────────┐   │
│  │  HTTP Handlers │  │  Middleware  │  │  Database Layer       │   │
│  │  (Gin Routes)  │─►│  (Auth/CORS) │─►│  (GORM + PostgreSQL)  │   │
│  └────────────────┘  └──────────────┘  └───────────────────────┘   │
│          │                                                            │
│          ▼                                                            │
│  ┌────────────────────────────────────────────────┐                  │
│  │  External API Proxies                          │                  │
│  │  - OpenFoodFacts (Product Data)                │                  │
│  │  - Google OAuth (Token Verification)           │                  │
│  └────────────────────────────────────────────────┘                  │
└───────────────────────────────────────────────────────────────────────┘
```

### Offline-First Strategy

1. **Write Operations**: All CRUD operations write to Isar first, marking records with `synced: false`
2. **Background Sync**: Every 15 minutes (or on network reconnect), unsynced records are batched and sent to backend
3. **Conflict Resolution**: Last-write-wins strategy with `updated_at` timestamps
4. **Read Operations**: Always read from Isar, never block on network requests

---

## ✨ Features

### 1. Hybrid Entry System

#### 1.1 Packaged Goods Recognition

**Package**: `mobile_scanner: ^4.0.0`

**Implementation**:
- **Barcode Scanning**: Uses Google MLKit's barcode detection for instant product identification
- **Supported Formats**: EAN-13, UPC-A, Code-128, QR codes
- **API Integration**: Scanned barcodes query OpenFoodFacts API via Go backend proxy
- **Offline Cache**: Previously scanned products cached locally in Isar to reduce API calls

**Technical Flow**:
```dart
// 1. Scan barcode with mobile_scanner
BarcodeCapture barcode = await scanner.scan();

// 2. Check local cache
Product? cached = await isar.products.filter()
    .barcodeEqualTo(barcode.code).findFirst();

// 3. If not cached, query backend
if (cached == null) {
  Response response = await dio.get('/api/v1/products/${barcode.code}');
  cached = Product.fromJson(response.data);
  await isar.writeTxn(() => isar.products.put(cached));
}
```

**Backend Endpoint**:
```go
// GET /api/v1/products/:barcode
// Proxies request to OpenFoodFacts, caches in PostgreSQL
func (h *ProductHandler) GetByBarcode(c *gin.Context) {
    barcode := c.Param("barcode")
    
    // Check DB cache first
    var product models.Product
    if err := h.db.Where("barcode = ?", barcode).First(&product).Error; err == nil {
        c.JSON(200, product)
        return
    }
    
    // Fetch from OpenFoodFacts
    resp, _ := http.Get(fmt.Sprintf("https://world.openfoodfacts.org/api/v0/product/%s.json", barcode))
    // Parse, save to DB, return
}
```

#### 1.2 OCR Date Recognition

**Package**: `google_mlkit_text_recognition: ^0.11.0`

**Implementation**:
- **On-Device Processing**: Uses Google MLKit's text recognition (no network required)
- **Date Pattern Matching**: Regex patterns detect common expiry formats:
  - `BEST BEFORE MM/DD/YYYY`
  - `EXP DD-MM-YY`
  - `USE BY YYYY.MM.DD`
  - `BB 12/25`, `12 DEC 2025`, etc.

**Date Parser Utility**:
```dart
class ExpiryDateParser {
  static final List<RegExp> patterns = [
    RegExp(r'(\d{2})[/\-\.](\d{2})[/\-\.](\d{2,4})'), // MM/DD/YYYY
    RegExp(r'(\d{4})[/\-\.](\d{2})[/\-\.](\d{2})'),   // YYYY/MM/DD
    RegExp(r'(\d{2})\s*(JAN|FEB|MAR|...|DEC)\s*(\d{2,4})'), // DD MON YYYY
  ];
  
  static DateTime? parse(String text) {
    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        // Parse and return DateTime
      }
    }
    return null;
  }
}
```

**Confidence Scoring**:
- MLKit returns confidence score (0.0 - 1.0) for recognized text
- If confidence < 0.7, date field highlighted yellow for manual review
- User can accept, edit, or re-scan

#### 1.3 Fresh Produce Smart Estimates

**Data Source**: USDA FoodKeeper Database (bundled as `assets/usda_foodkeeper.json`)

**Database Structure**:
```json
{
  "categories": [
    {
      "name": "Vegetables",
      "items": [
        {
          "name": "Potatoes",
          "pantry_days": 14,
          "refrigerator_days": 42,
          "freezer_months": 10,
          "tips": "Store in cool, dark place"
        }
      ]
    }
  ]
}
```

**Storage Context Logic**:
```dart
enum StorageLocation { pantry, fridge, freezer }

DateTime calculateExpiryDate(String itemName, StorageLocation location) {
  final usdaData = await rootBundle.loadString('assets/usda_foodkeeper.json');
  final item = findItemByName(usdaData, itemName);
  
  switch (location) {
    case StorageLocation.pantry:
      return DateTime.now().add(Duration(days: item.pantry_days));
    case StorageLocation.fridge:
      return DateTime.now().add(Duration(days: item.refrigerator_days));
    case StorageLocation.freezer:
      return DateTime.now().add(Duration(days: item.freezer_months * 30));
  }
}
```

---

### 2. Expiration-First Dashboard

**Package**: `flutter_riverpod: ^2.5.1` (for reactive state)

**UI Implementation**:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final items = ref.watch(pantryItemsProvider);
  
  // Partition items by urgency
  final urgent = items.where((item) => 
    item.expiryDate.difference(DateTime.now()).inDays <= 3
  ).toList();
  
  final warning = items.where((item) {
    final days = item.expiryDate.difference(DateTime.now()).inDays;
    return days > 3 && days <= 7;
  }).toList();
  
  return ListView(
    children: [
      if (urgent.isNotEmpty) UrgentSection(items: urgent), // Red
      if (warning.isNotEmpty) WarningSsection(items: warning), // Orange
      AllItemsSection(items: items), // Normal
    ],
  );
}
```

**Color Coding**:
- **Red (≤3 days)**: `Colors.red[100]` background, bold text
- **Orange (4-7 days)**: `Colors.orange[100]` background
- **Green (>7 days)**: Default background

---

### 3. Waste Tracking & Gamification

**Package**: `fl_chart: ^0.66.0`

#### 3.1 Swipe Actions

**Implementation**:
```dart
Dismissible(
  key: Key(item.id.toString()),
  background: Container(color: Colors.green), // Right swipe = consumed
  secondaryBackground: Container(color: Colors.red), // Left swipe = wasted
  onDismissed: (direction) {
    if (direction == DismissDirection.endToStart) {
      _showWastePriceDialog(item); // Ask for estimated price
    } else {
      _markAsConsumed(item);
    }
  },
  child: ItemTile(item: item),
)
```

#### 3.2 Statistics Dashboard

**Data Model**:
```dart
@collection
class WasteLog {
  Id id = Isar.autoIncrement;
  late String itemName;
  late String category;
  late double estimatedPrice;
  late DateTime wastedDate;
}
```

**Monthly Aggregation**:
```dart
Future<Map<String, double>> getMonthlyWaste() async {
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  
  final logs = await isar.wasteLogs
    .filter()
    .wastedDateGreaterThan(startOfMonth)
    .findAll();
  
  double total = logs.fold(0, (sum, log) => sum + log.estimatedPrice);
  
  // Group by category
  Map<String, double> byCategory = {};
  for (var log in logs) {
    byCategory[log.category] = (byCategory[log.category] ?? 0) + log.estimatedPrice;
  }
  
  return byCategory;
}
```

**Chart Rendering**:
```dart
PieChart(
  PieChartData(
    sections: byCategory.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        title: '${entry.key}\n₱${entry.value.toStringAsFixed(0)}',
        color: categoryColors[entry.key],
      );
    }).toList(),
  ),
)
```

---

### 4. Cloud Synchronization

**Package**: `dio: ^5.4.0`

#### 4.1 Sync Strategy

**Local-First Writes**:
```dart
Future<void> addItem(PantryItem item) async {
  item.synced = false;
  item.updatedAt = DateTime.now();
  
  await isar.writeTxn(() async {
    await isar.pantryItems.put(item);
  });
  
  // Trigger background sync (non-blocking)
  _syncService.schedulSync();
}
```

**Background Sync Worker**:
```dart
class SyncService {
  Timer? _syncTimer;
  
  void startPeriodicSync() {
    _syncTimer = Timer.periodic(Duration(minutes: 15), (_) {
      syncUnsyncedItems();
    });
  }
  
  Future<void> syncUnsyncedItems() async {
    final unsynced = await isar.pantryItems
      .filter()
      .syncedEqualTo(false)
      .findAll();
    
    if (unsynced.isEmpty) return;
    
    try {
      final response = await dio.post('/api/v1/sync', data: {
        'items': unsynced.map((i) => i.toJson()).toList(),
      });
      
      // Mark as synced
      await isar.writeTxn(() async {
        for (var item in unsynced) {
          item.synced = true;
          await isar.pantryItems.put(item);
        }
      });
    } catch (e) {
      // Retry on next sync cycle
    }
  }
}
```

#### 4.2 Backend Sync Endpoint

**Go Handler**:
```go
type SyncRequest struct {
    Items []models.PantryItem `json:"items"`
}

func (h *SyncHandler) Sync(c *gin.Context) {
    userID := c.GetUint("user_id") // From JWT middleware
    
    var req SyncRequest
    c.ShouldBindJSON(&req)
    
    for _, item := range req.Items {
        item.UserID = userID
        
        // Upsert: Update if exists, insert if new
        h.db.Where("id = ? AND user_id = ?", item.ID, userID).
            Assign(item).
            FirstOrCreate(&item)
    }
    
    c.JSON(200, gin.H{"synced": len(req.Items)})
}
```

---

### 5. Smart Notifications

**Package**: `flutter_local_notifications: ^16.3.0`

**Implementation**:
```dart
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(InitializationSettings(android: android, iOS: ios));
  }
  
  Future<void> scheduleExpiryReminders() async {
    final items = await isar.pantryItems
      .filter()
      .expiryDateBetween(DateTime.now(), DateTime.now().add(Duration(days: 3)))
      .findAll();
    
    for (var item in items) {
      await _notifications.zonedSchedule(
        item.id,
        'Item Expiring Soon!',
        '${item.name} expires in ${item.expiryDate.difference(DateTime.now()).inDays} days',
        // Schedule for 9 AM on expiry date - 1 day
        _nextInstanceOf9AM(item.expiryDate.subtract(Duration(days: 1))),
        NotificationDetails(
          android: AndroidNotificationDetails('expiry_channel', 'Expiry Alerts'),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}
```

---

### 6. Authentication System

**Packages**: 
- `flutter_secure_storage: ^9.0.0`
- `google_sign_in: ^6.2.1`
- Backend: `golang-jwt/jwt: ^5.2.0`

#### 6.1 JWT Flow

**Registration/Login**:
```go
func (h *AuthHandler) Login(c *gin.Context) {
    var req LoginRequest
    c.ShouldBindJSON(&req)
    
    var user models.User
    h.db.Where("email = ?", req.Email).First(&user)
    
    // Verify password with bcrypt
    bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password))
    
    // Generate JWT
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
        "user_id": user.ID,
        "exp": time.Now().Add(7 * 24 * time.Hour).Unix(),
    })
    
    tokenString, _ := token.SignedString([]byte(os.Getenv("JWT_SECRET")))
    
    c.JSON(200, gin.H{"token": tokenString, "user": user})
}
```

**Flutter Storage**:
```dart
final storage = FlutterSecureStorage();
await storage.write(key: 'jwt_token', value: token);
```

**Dio Interceptor (Auto-Attach JWT)**:
```dart
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await storage.read(key: 'jwt_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  },
));
```

#### 6.2 Google OAuth

**Flutter**:
```dart
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

Future<void> signInWithGoogle() async {
  final account = await _googleSignIn.signIn();
  final auth = await account!.authentication;
  
  // Send ID token to backend
  final response = await dio.post('/api/v1/auth/google', data: {
    'id_token': auth.idToken,
  });
  
  await storage.write(key: 'jwt_token', value: response.data['token']);
}
```

**Go Backend**:
```go
import "google.golang.org/api/idtoken"

func (h *AuthHandler) GoogleSignIn(c *gin.Context) {
    var req struct { IDToken string `json:"id_token"` }
    c.ShouldBindJSON(&req)
    
    // Verify Google ID token
    payload, err := idtoken.Validate(context.Background(), req.IDToken, 
        os.Getenv("GOOGLE_CLIENT_ID"))
    
    email := payload.Claims["email"].(string)
    
    // Find or create user
    var user models.User
    h.db.FirstOrCreate(&user, models.User{Email: email})
    
    // Generate JWT
    token := generateJWT(user.ID)
    c.JSON(200, gin.H{"token": token, "user": user})
}
```

---

## 📂 Project Structure

```
shelflife/
├── mobile/                          # Flutter application
│   ├── lib/
│   │   ├── main.dart               # App entry point
│   │   ├── models/                 # Isar data models
│   │   │   ├── pantry_item.dart
│   │   │   ├── pantry_item.g.dart  # Generated
│   │   │   ├── waste_log.dart
│   │   │   └── user.dart
│   │   ├── screens/                # UI screens
│   │   │   ├── home_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── add_item_screen.dart
│   │   │   ├── stats_screen.dart
│   │   │   └── scanner_screen.dart
│   │   ├── widgets/                # Reusable UI components
│   │   │   ├── item_tile.dart
│   │   │   ├── urgent_section.dart
│   │   │   └── waste_chart.dart
│   │   ├── providers/              # Riverpod state providers
│   │   │   ├── auth_provider.dart
│   │   │   ├── pantry_provider.dart
│   │   │   └── stats_provider.dart
│   │   ├── services/               # Business logic
│   │   │   ├── database_service.dart
│   │   │   ├── auth_service.dart
│   │   │   ├── api_client.dart
│   │   │   ├── sync_service.dart
│   │   │   └── notification_service.dart
│   │   └── utils/                  # Helper functions
│   │       ├── date_parser.dart
│   │       └── constants.dart
│   ├── assets/
│   │   └── usda_foodkeeper.json    # USDA data (bundled)
│   ├── android/                    # Android-specific config
│   ├── ios/                        # iOS-specific config
│   ├── pubspec.yaml                # Flutter dependencies
│   └── test/                       # Unit tests
│
├── server/                          # Go backend
│   ├── cmd/
│   │   └── api/
│   │       └── main.go             # Server entry point
│   ├── internal/
│   │   ├── handlers/               # HTTP route handlers
│   │   │   ├── auth.go
│   │   │   ├── items.go
│   │   │   ├── sync.go
│   │   │   └── products.go
│   │   ├── middleware/             # HTTP middleware
│   │   │   ├── auth.go
│   │   │   └── cors.go
│   │   ├── models/                 # Database models
│   │   │   ├── user.go
│   │   │   ├── pantry_item.go
│   │   │   └── product.go
│   │   ├── database/               # DB connection
│   │   │   └── postgres.go
│   │   └── services/               # Business logic
│   │       ├── openfoodfacts.go
│   │       └── sync_service.go
│   ├── config/
│   │   └── config.go               # Configuration loader
│   ├── migrations/                 # SQL migrations
│   │   └── 001_initial.sql
│   ├── go.mod                      # Go dependencies
│   ├── go.sum                      # Dependency checksums
│   ├── .env.example                # Example environment vars
│   └── Dockerfile                  # Docker container config
│
├── docs/                            # Documentation
│   ├── API.md                      # API documentation
│   ├── DATABASE_SCHEMA.md          # Schema documentation
│   └── DEPLOYMENT.md               # Deployment guide
│
├── .gitignore
└── README.md
```

---

## 🚀 Setup Instructions

### Prerequisites

- **Flutter**: 3.19.0 or higher ([Install Guide](https://flutter.dev/docs/get-started/install))
- **Dart**: 3.3.0 or higher (included with Flutter)
- **Go**: 1.21 or higher ([Install Guide](https://go.dev/doc/install))
- **PostgreSQL**: 15 or higher ([Install Guide](https://www.postgresql.org/download/))
- **Docker** (optional, for containerized Postgres): [Install Guide](https://docs.docker.com/get-docker/)

### Mobile Setup (Flutter)

```bash
# 1. Clone repository
git clone https://github.com/yourusername/shelflife.git
cd shelflife/mobile

# 2. Install dependencies
flutter pub get

# 3. Generate Isar models
dart run build_runner build

# 4. Run on device/emulator
flutter run

# Optional: Run tests
flutter test
```

**Note**: For barcode scanning and OCR, you need a physical device (emulators lack camera support).

### Backend Setup (Go)

#### Option 1: Local Development

```bash
# 1. Navigate to server directory
cd shelflife/server

# 2. Install dependencies
go mod download

# 3. Set up PostgreSQL database
createdb shelflife_dev

# 4. Create .env file
cp .env.example .env
# Edit .env with your database credentials

# 5. Run database migrations (manual for now)
psql shelflife_dev < migrations/001_initial.sql

# 6. Run server
go run cmd/api/main.go
```

#### Option 2: Docker (PostgreSQL)

```bash
# 1. Start PostgreSQL container
docker run --name shelflife-postgres \
  -e POSTGRES_PASSWORD=yourpassword \
  -e POSTGRES_DB=shelflife_dev \
  -p 5432:5432 \
  -d postgres:15

# 2. Update .env
DATABASE_URL=postgresql://postgres:yourpassword@localhost:5432/shelflife_dev

# 3. Run server
go run cmd/api/main.go
```

### Environment Variables

#### Backend (`.env`)

```env
# Server
PORT=8080

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/shelflife_dev

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production

# Google OAuth (optional)
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com

# OpenFoodFacts (no key required, public API)
```

#### Flutter (No .env needed, uses hardcoded constants)

Edit `lib/utils/constants.dart`:
```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api/v1';
  // For Android emulator, use: http://10.0.2.2:8080/api/v1
  // For iOS simulator, use: http://localhost:8080/api/v1
  // For physical device, use: http://YOUR_COMPUTER_IP:8080/api/v1
}
```

---

## 🗓️ Development Roadmap

### Phase 1: Core Functionality (Weeks 1-2)
- [x] Manual item entry UI
- [x] Isar database integration
- [x] List view with expiry dates
- [x] Basic CRUD operations
- [ ] Date picker for expiry dates
- [ ] Storage location selector (Fridge/Freezer/Pantry)

### Phase 2: Smart Features (Weeks 3-4)
- [ ] USDA FoodKeeper integration
- [ ] Automatic expiry calculation for fresh produce
- [ ] Color-coded urgency dashboard
- [ ] Sort/filter by expiry date
- [ ] Search functionality

### Phase 3: Computer Vision (Weeks 5-6)
- [ ] Barcode scanner implementation
- [ ] OpenFoodFacts API integration
- [ ] Product cache system
- [ ] OCR expiry date scanning
- [ ] Date parser with regex patterns
- [ ] Confidence score UI

### Phase 4: Waste Tracking (Week 7)
- [ ] Swipe-to-consume/waste gestures
- [ ] Waste log database model
- [ ] Price input dialog
- [ ] Monthly statistics aggregation
- [ ] Pie chart visualization
- [ ] Category-based waste breakdown

### Phase 5: Backend & Sync (Weeks 8-9)
- [ ] Go API server setup
- [ ] PostgreSQL schema
- [ ] JWT authentication endpoints
- [ ] CRUD API endpoints
- [ ] Sync endpoint with conflict resolution
- [ ] Background sync service in Flutter

### Phase 6: Authentication (Week 10)
- [ ] Email/password registration
- [ ] Login flow
- [ ] JWT storage in Flutter
- [ ] Dio interceptors
- [ ] Google OAuth integration
- [ ] Auth state management with Riverpod

### Phase 7: Notifications & Polish (Week 11)
- [ ] Local notifications setup
- [ ] Daily expiry reminders
- [ ] App icons and splash screens
- [ ] Onboarding flow
- [ ] Settings screen
- [ ] Dark mode support

### Phase 8: Testing & Deployment (Week 12)
- [ ] Unit tests (Flutter & Go)
- [ ] Integration tests
- [ ] Performance optimization
- [ ] Android APK build
- [ ] iOS TestFlight beta
- [ ] Backend deployment (Heroku/Railway/Fly.io)

---

## 📡 API Documentation

### Base URL
```
http://localhost:8080/api/v1
```

### Authentication

#### Register
```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword123"
}

Response 201:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "created_at": "2024-03-15T10:30:00Z"
  }
}
```

#### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securepassword123"
}

Response 200: (same as register)
```

#### Google Sign-In
```http
POST /auth/google
Content-Type: application/json

{
  "id_token": "google_id_token_from_flutter"
}

Response 200: (same as register)
```

### Pantry Items (Protected Routes - Require JWT)

#### Get All Items
```http
GET /items
Authorization: Bearer {jwt_token}

Response 200:
{
  "items": [
    {
      "id": 1,
      "name": "Milk",
      "expiry_date": "2024-03-20T00:00:00Z",
      "storage_location": "fridge",
      "created_at": "2024-03-15T10:30:00Z",
      "updated_at": "2024-03-15T10:30:00Z"
    }
  ]
}
```

#### Create Item
```http
POST /items
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "name": "Chicken Breast",
  "expiry_date": "2024-03-18T00:00:00Z",
  "storage_location": "fridge",
  "category": "meat"
}

Response 201:
{
  "id": 2,
  "name": "Chicken Breast",
  "expiry_date": "2024-03-18T00:00:00Z",
  "storage_location": "fridge",
  "category": "meat",
  "created_at": "2024-03-15T10:35:00Z"
}
```

#### Update Item
```http
PUT /items/:id
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "name": "Chicken Breast (Updated)",
  "expiry_date": "2024-03-19T00:00:00Z"
}

Response 200: (updated item)
```

#### Delete Item
```http
DELETE /items/:id
Authorization: Bearer {jwt_token}

Response 204: No Content
```

### Product Lookup

#### Get Product by Barcode
```http
GET /products/:barcode
Authorization: Bearer {jwt_token}

Response 200:
{
  "barcode": "3017620422003",
  "name": "Nutella",
  "brand": "Ferrero",
  "image_url": "https://images.openfoodfacts.org/...",
  "category": "spreads"
}
```

### Sync

#### Sync Unsynced Items
```http
POST /sync
Authorization: Bearer {jwt_token}
Content-Type: application/json

{
  "items": [
    {
      "id": 3,
      "name": "Eggs",
      "expiry_date": "2024-03-25T00:00:00Z",
      "storage_location": "fridge",
      "created_at": "2024-03-15T11:00:00Z",
      "updated_at": "2024-03-15T11:00:00Z"
    }
  ]
}

Response 200:
{
  "synced": 1
}
```

---

## 🗄️ Database Schema

### PostgreSQL (Backend)

```sql
-- Users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255), -- NULL for Google OAuth users
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pantry items table
CREATE TABLE pantry_items (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    expiry_date TIMESTAMP NOT NULL,
    storage_location VARCHAR(50) NOT NULL, -- 'fridge', 'freezer', 'pantry'
    category VARCHAR(100),
    barcode VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product cache (from OpenFoodFacts)
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    barcode VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255),
    brand VARCHAR(255),
    image_url TEXT,
    category VARCHAR(100),
    cached_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Waste logs
CREATE TABLE waste_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    estimated_price DECIMAL(10, 2) NOT NULL,
    wasted_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_pantry_items_user_id ON pantry_items(user_id);
CREATE INDEX idx_pantry_items_expiry_date ON pantry_items(expiry_date);
CREATE INDEX idx_waste_logs_user_id ON waste_logs(user_id);
CREATE INDEX idx_waste_logs_wasted_date ON waste_logs(wasted_date);
```

### Isar (Flutter Local Database)

```dart
@collection
class PantryItem {
  Id id = Isar.autoIncrement;
  
  late String name;
  late DateTime expiryDate;
  
  @enumerated
  late StorageLocation storageLocation;
  
  String? category;
  String? barcode;
  
  late DateTime createdAt;
  late DateTime updatedAt;
  
  @Index()
  late bool synced; // For sync tracking
}

@collection
class WasteLog {
  Id id = Isar.autoIncrement;
  
  late String itemName;
  late String category;
  late double estimatedPrice;
  late DateTime wastedDate;
  late DateTime createdAt;
}

@collection
class Product {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String barcode;
  
  late String name;
  String? brand;
  String? imageUrl;
  String? category;
  late DateTime cachedAt;
}

enum StorageLocation {
  pantry,
  fridge,
  freezer,
}
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

**Flutter/Dart**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
**Go**: Use `gofmt` and follow [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **OpenFoodFacts**: Community-driven food database
- **USDA FoodKeeper**: Shelf-life data for fresh produce
- **Google MLKit**: On-device ML models for OCR and barcode scanning
- **Isar Database**: High-performance Flutter database
- **Flutter Team**: For the amazing cross-platform framework

---

## 📞 Contact

**Project Maintainer**: Your Name
- Email: your.email@example.com
- GitHub: [@yourusername](https://github.com/yourusername)
- Twitter: [@yourhandle](https://twitter.com/yourhandle)

**Project Link**: [https://github.com/yourusername/shelflife](https://github.com/yourusername/shelflife)

---

## 📊 Project Status

**Current Version**: 0.1.0-alpha
**Status**: In Active Development
**Last Updated**: February 16, 2026

---

## 🎯 Future Enhancements (Post-MVP)

- Recipe suggestions based on expiring items
- Voice input for adding items
- Meal planning integration
- Barcode history cache
- Multi-language support (i18n)
- Wear OS / Apple Watch companion app
- Family sharing with role-based permissions
- Export data to CSV
- Integration with grocery delivery apps
- AR mode to scan entire pantry at once