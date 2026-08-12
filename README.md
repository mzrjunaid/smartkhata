# SmartKhata - Modern FinTech Ledger & Loan Management System

<div align="center">
  <img src="assets/images/logo.png" alt="SmartKhata Logo" width="150" />
</div>

<p align="center">
  <strong>A comprehensive, secure, and intuitive loan management and digital ledger application built with Flutter and Supabase.</strong>
</p>

## 🚀 Overview

**SmartKhata** (meaning *Smart Ledger*) is a robust FinTech application designed to digitize and streamline the lending and borrowing process. Whether you are an individual tracking personal loans or a microfinance entity managing multiple borrowers, SmartKhata provides the essential tools to track transactions, manage repayments, and maintain transparent audit logs.

This project showcases advanced mobile development practices, utilizing a modern tech stack to deliver a seamless user experience across platforms.

## ✨ Core Services & Features

- 👥 **Role-Based Dashboards**: Tailored experiences with dedicated **Lender** and **Borrower** dashboards.
- 💰 **Comprehensive Loan Management**: Create, track, and manage new loans with flexible terms.
- 📊 **Real-time Analytics**: Visual insights and charts (powered by `fl_chart`) to track financial health and repayment progress.
- 🔄 **Transaction & Repayment Tracking**: Detailed ledger for every transaction, ensuring both parties have a clear financial history.
- 🔐 **Secure Authentication**: Robust user authentication and authorization handled securely via **Supabase**.
- 📝 **Transparent Audit Logs**: Immutable audit trails for all financial activities to maintain trust and accountability.
- 📱 **Cross-Platform**: Built with **Flutter** for a beautiful, responsive native experience on both Android and iOS.

## 🛠️ Tech Stack & Architecture

SmartKhata is built using industry-standard tools and architectural patterns to ensure scalability, maintainability, and performance:

- **Frontend Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend as a Service (BaaS)**: [Supabase](https://supabase.com/) (PostgreSQL, Auth, Storage)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`) for reactive caching and data binding.
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) for declarative routing.
- **Data Modeling**: [Freezed](https://pub.dev/packages/freezed) & [JSON Serializable](https://pub.dev/packages/json_serializable) for robust, immutable data classes.
- **UI Components**: Custom UI elements with `flutter_form_builder` and `shimmer` for loading states.

## 📈 My Progress & Learnings

Developing SmartKhata has been a journey in mastering full-stack mobile development. Key areas of knowledge demonstrated in this repository include:

- **Complex State Management**: Effectively managing complex application states, such as user sessions, real-time transaction updates, and offline caching using Riverpod.
- **Backend Integration**: Seamlessly integrating a Flutter app with Supabase, handling complex relational database queries, and implementing secure Row Level Security (RLS) policies.
- **Scalable Architecture**: Structuring the codebase using a feature-first, layered architecture for better maintainability.
- **UI/UX Design**: Building responsive and accessible user interfaces that provide a premium native feel.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.12.2)
- Dart SDK
- Supabase account (for backend configuration)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/smartkhata.git
   ```
2. Navigate into the project directory:
   ```bash
   cd smartkhata
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the code generation for Freezed and JSON Serializable:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
5. Run the app:
   ```bash
   flutter run
   ```
