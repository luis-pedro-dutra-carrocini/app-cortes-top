/*
  Warnings:

  - The `TipoRelacao` column on the `Endereco` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - Changed the type of `UsuEstId` on the `Endereco` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- AlterTable
ALTER TABLE "Endereco" DROP COLUMN "UsuEstId",
ADD COLUMN     "UsuEstId" INTEGER NOT NULL,
DROP COLUMN "TipoRelacao",
ADD COLUMN     "TipoRelacao" "UsuEstRelacao" NOT NULL DEFAULT 'USUARIO';
