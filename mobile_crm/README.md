# mobile_crm

A new Flutter project.

## Cloudinary Setup

This application uses Cloudinary for image storage. Follow these steps to set up Cloudinary:

1. Create a free Cloudinary account at [cloudinary.com](https://cloudinary.com/)
2. Once registered, navigate to your Dashboard to find your account details
3. Update the following constants in `lib/core/constants/app_constants.dart`:
   ```dart
   static const String cloudinaryApiKey = "YOUR_CLOUDINARY_API_KEY";
   static const String cloudinaryApiSecret = "YOUR_CLOUDINARY_API_SECRET";
   static const String cloudinaryCloudName = "YOUR_CLOUDINARY_CLOUD_NAME";
   ```
4. Replace the placeholder values with your actual Cloudinary credentials

## Image Upload Functionality

The application now supports image uploads for repair jobs:

- Images can be captured from the camera or selected from the gallery
- Images are uploaded to Cloudinary when a repair job is created
- The image URLs are stored in Firestore and can be accessed from the repair details page
- Maximum 5 images can be uploaded per repair job
- Image quality is reduced to optimize upload speed and storage

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
