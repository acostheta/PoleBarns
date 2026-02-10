-- 1. Remove the old relationship and the table
ALTER TABLE "Invoices" DROP CONSTRAINT IF EXISTS "Invoices_group_id_fkey";
DROP TABLE IF EXISTS "groups";

-- 2. Change group_id type from bigint to uuid in Invoices
-- Since there's no data, we can just drop and add or alter
ALTER TABLE "Invoices" DROP COLUMN IF EXISTS "group_id";
ALTER TABLE "Invoices" ADD COLUMN "group_id" uuid;

-- 3. Add Foreign Key to worker_groups
ALTER TABLE "Invoices" 
ADD CONSTRAINT "Invoices_worker_group_id_fkey" 
FOREIGN KEY ("group_id") 
REFERENCES "worker_groups"("id");
