-- AlterTable: Add queueDate column
ALTER TABLE "QueueToken" ADD COLUMN "queueDate" TIMESTAMP(3) NOT NULL DEFAULT date_trunc('day', CURRENT_TIMESTAMP);

-- Backfill queueDate from existing joinedAt normalized to midnight UTC
UPDATE "QueueToken" SET "queueDate" = date_trunc('day', "joinedAt");

-- DropIndex: Drop old unique constraint on (clinicId, tokenNumber)
DROP INDEX IF EXISTS "QueueToken_clinicId_tokenNumber_key";

-- CreateIndex: Create new per-day unique constraint on (clinicId, queueDate, tokenNumber)
CREATE UNIQUE INDEX "QueueToken_clinicId_queueDate_tokenNumber_key" ON "QueueToken"("clinicId", "queueDate", "tokenNumber");
