# Implementation Plan - Payroll & Clients

## Objective
Implement a comprehensive client management and payroll system within the Flutter application, integrating with Supabase.

## Current Status
- [x] Create Supabase Schema (`supabase_setup.sql` created, needs execution).
- [x] Client Module
    - [x] Model & Repository
    - [x] List Screen (CRUD, Search, Realtime)
    - [x] Detail Screen
- [x] Payroll Module
    - [x] Models (`PagosDiarios`, `Soldadores`, `Instalacion`, `Chofer`, `PaymentDestajo`)
    - [x] Repository (CRUD, Streams)
    - [x] Dashboard Screen
    - [x] Sub-screens implementation:
        - [x] Pagos Diarios (Fixed encoding issues)
        - [x] Destajo Soldadores (Fixed encoding issues)
        - [x] Nomina Instalacion (Fixed encoding issues)
        - [x] Nomina Chofer (Fixed encoding issues)
- [x] Navigation & Routing

## Next Steps
- [ ] **Database Setup**: Execute `supabase_setup.sql` in Supabase SQL Editor.
- [ ] **Verification**: Run the app and test all CRUD operations manually.
- [ ] **UI Refinement**:
    - [ ] Employee Selection: Replace text input with Dropdown (fetching user list).
    - [ ] Catalog Integration: `truss_producto` selection for Welders.
    - [ ] Project Integration: `id_proyecto` selection for Installation.
- [ ] **Testing**: Write widget tests for new screens.

## User Action Required
Please run the SQL script located at `apps/cliente_app/supabase_setup.sql` in your Supabase project's SQL Editor to create the necessary tables.
