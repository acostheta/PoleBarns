-- Add project_name column
ALTER TABLE "Invoices" ADD COLUMN IF NOT EXISTS "project_name" text;

-- Update project_name from existing relationships (optional, to preserve data)
UPDATE "Invoices" i
SET "project_name" = p.address
FROM "projects" p
WHERE i."IdProyecto" = p.id;

-- Drop the Foreign Key constraint
ALTER TABLE "Invoices" DROP CONSTRAINT IF EXISTS "Invoices_IdProyecto_fkey";

-- Make IdProyecto nullable (it already is, but just in case)
ALTER TABLE "Invoices" ALTER COLUMN "IdProyecto" DROP NOT NULL;
