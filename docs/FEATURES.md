# FEATURES

This document lists the main capabilities of INVENTORY in practical terms.

## 1) Premium UI/UX

- Responsive layout for mobile, tablet, and web
- Light and dark themes with system/default support
- Reusable premium components (app bar, cards, states, buttons, inputs)
- Smooth shell navigation with bottom tabs

## 2) Authentication and Roles

- Email/password sign-in
- Role-based permissions:
  - **Owner**: full control (team, settings, advanced reports)
  - **Admin**: operational and product management
  - **Staff**: day-to-day actions (scan, stock, sell)

## 3) Product Management

- View product catalog
- Add/edit products (role-restricted)
- Product details with pricing, stock, and QR access
- Optional product image support (Firebase mode)

## 4) QR Inventory System

- Generate QR for products
- Scan QR for stock in
- Scan QR to add items to POS/cart
- Manual fallback entry for unsupported camera scenarios

## 5) Stock In Workflow

- Select product
- Enter quantity and optional note
- Commit stock transaction through service layer

## 6) POS and Checkout

- Product search and add-to-cart
- Quantity controls and stock guardrails
- Checkout flow updates sales and inventory
- BDT-focused currency display

## 7) Reporting

- Sales report
- Stock report
- Profit/Loss report (role-controlled)
- Dashboard KPI shortcuts

## 8) AI-Powered Features

- AI Assistant (local fallback + provider API option)
- AI product recognition flow (mock-ready)
- Smart insights cards
- Restock prediction and analytics views

## 9) Demo Mode

- App can run without Firebase
- Helpful for UI testing, local demos, and contributor onboarding
- Uses demo credentials and fallback logic

## 10) Settings and Business Controls

- Business profile/settings
- Backend mode visibility
- App appearance (system/light/dark)
- Logout and account-level controls
