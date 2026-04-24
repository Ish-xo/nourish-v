# Nourish V

**AI-Powered Malnutrition Detection App**

Nourish V is a Flutter-based mobile application developed for the **MIT-ADT AI Grand Challenge 2026**. It empowers rural healthcare workers (ASHA/Anganwadi staff) to detect and classify malnutrition in children under 5 years and pregnant women using AI-powered image analysis and WHO growth standards. The app features offline-first functionality, guided camera capture, and role-based access control with Firebase integration.

## Features

- **Offline-First Data Entry**: Manual data entry forms for patient vitals that work without internet.
- **Guided Image Capture**: Camera interface with silhouette overlays for accurate posture, distance, and lighting.
- **Malnutrition Detection**: Categorizes Underweight, Stunting, and Wasting based on WHO standards (Z-scores, MUAC).
- **Traffic Light System**: Color-coded results (Green: Healthy, Yellow: At Risk, Red: Severe).
- **Nutrition Plans & Referrals**: Automated recommendations and medical referral alerts per WHO guidelines.
- **Role-Based Access**:
  - **Workers**: Take screenings, view history.
  - **Admins**: Access analytics dashboard and government reports.
- **Multi-Language Support**: Seamless translation into regional Indian languages (Hindi, Marathi, Gujarati).
- **Dashboard & Reporting**: Regional trends, charts, and PDF export for government compliance.
- **Firebase Integration**: Auth, Firestore for data persistence, Cloudinary for image storage.

## Tech Stack

| Layer          | Technology                           |
| -------------- | ------------------------------------ |
| Framework      | Flutter 3.x (Dart)                   |
| State Mgmt     | `flutter_riverpod`                   |
| Architecture   | MVC + Repository Pattern             |
| Auth           | Firebase Auth (email/password)       |
| Database       | Cloud Firestore (offline-first)      |
| Image Storage  | Cloudinary (unsigned upload preset)  |
| Charts         | `fl_chart`                           |
| Animations     | `flutter_animate`                    |
| Camera         | `camera`                             |
| Fonts          | `google_fonts` (Poppins)             |
| PDF Reports    | `pdf` + `printing`                   |
| Environment    | `flutter_dotenv` (.env file)         |

## Installation

### Prerequisites

- Flutter SDK (3.x or later)
- Dart SDK
- Android Studio or VS Code with Flutter extensions
- Firebase project set up
- Cloudinary account

### Setup Steps

1. **Clone the Repository**:
   ```bash
   git clone <repository-url>
   cd nourish_v
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Environment Configuration**:
   - Create a `.env` file in the project root:
     ```
     CLOUDINARY_CLOUD_NAME=your_cloud_name
     CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset
     ```
   - Configure Firebase:
     - Run `flutterfire configure` to link your Firebase project.
     - Add users manually in Firebase Console (Auth and Firestore).

4. **Firebase Setup**:
   - Enable Firestore and Authentication in Firebase Console.
   - Create collections as per `SCHEMA.md`.
   - Set up security rules.

5. **Run the App**:
   ```bash
   flutter run
   ```

## Usage

- **Login**: Use role-based credentials (workers/admins).
- **Screening**: Enter patient data, capture guided images, view results.
- **History**: Workers view their assessments; admins access dashboards.
- **Reports**: Export PDFs or submit to government systems.

## Contributing

This project was developed for the MIT-ADT AI Grand Challenge 2026. Contributions are welcome via pull requests. Please follow Flutter best practices and ensure offline-first design.

## License

MIT License - See LICENSE file for details.

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [WHO Child Growth Standards](https://www.who.int/tools/child-growth-standards)
