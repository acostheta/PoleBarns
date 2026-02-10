# Enhancement: Invoice Detail View & Financial Integration

## Objective
Enhance the Invoice Detail view to serve as a central hub for project monetary management, including status tracking, actions, and cost management.

## Changes Implemented

### 1. Invoice Detail Screen (`invoice_detail_screen.dart`)
- **Status Indicator**: Added a visual banner showing the invoice status (Paid, Pending, Cancelled).
- **Actions Interface**: 
  - Added a "Create Project" button (visible if no project is linked) which opens the project creation dialog pre-filled with the client.
  - Added "Edit" and "Delete" options in the top-right menu.
- **Financial Dashboard**:
  - Implemented a financial summary section mirroring the Project's "Costs Tab".
  - Displays: Total Sales, Total Paid, Total Costs (Expenses), and Profit (Sales - Costs).
  - Added a "Costs" list section to track Accounts Payable associated with the invoice.
  - Added "Add Cost" button to quickly register new expenses for the invoice.

### 2. Accounts Payable Integration (`accounts_payable_provider.dart`, `accounts_payable_repository.dart`, `account_payable_model.dart`)
- **Model Update**: Added `invoiceId` field to `AccountPayableModel` to link costs directly to invoices.
- **Repository Update**: 
  - Added `getAccountsByInvoice(int invoiceId)` to fetch relevant costs.
  - Updated `createAccount` and `updateAccount` to handle `invoiceId`.
- **Provider Update**:
  - Created `invoiceAccountsPayableListProvider` to fetch costs for a specific invoice.
  - Created `invoiceAccountsPayableTotalProvider` to calculate total costs for the dashboard.
- **UI Update**: Updated `AddAccountDialog` to accept and save `invoiceId`.

### 3. Project Creation
- Updated `InvoiceDetailScreen` to launch `ProjectCreateDialog` with the invoice's client pre-selected.

## Verification
- **Aesthetics**: The new dashboard uses the app's clean, card-based design style with hero metrics for "Profit" and "Balance".
- **Functionality**: Users can now manage the entire financial lifecycle of a job (Invoicing + Expenses) from a single screen.
