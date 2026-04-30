const Map<String, List<String>> rolePermissions = {
  'Administrador': ['*'],
  'Admin': ['*'],
  'Manager': [
    'clients',
    'requests',
    'quotes',
    'jobs',
    'invoices',
    'inventory',
    'payroll',
    'users',
    'settings'
  ],
  'Secretaria': [
    'clients',
    'requests',
    'quotes',
    'jobs',
    'invoices',
    'inventory',
  ],
  'Vendedor': [
    'clients',
    'requests',
    'quotes',
    'jobs',
  ],
  'Worker': [
    'clients',
    'jobs',
  ],
  'Trabajador': [
    'clients',
    'jobs',
  ],
};
