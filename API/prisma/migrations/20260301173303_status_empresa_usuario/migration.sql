/*
  Warnings:

  - You are about to drop the column `EmpresaAtivo` on the `Empresa` table. All the data in the column will be lost.
  - You are about to drop the column `EstabelecimentoAtivo` on the `Estabelecimento` table. All the data in the column will be lost.
  - You are about to alter the column `LogAcao` on the `Log` table. The data in that column could be lost. The data in that column will be cast from `VarChar(255)` to `VarChar(20)`.
  - The `TipoRelacao` column on the `Notificacao` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - You are about to drop the column `UsuarioAtivo` on the `Usuario` table. All the data in the column will be lost.
  - Made the column `LogDetalhe` on table `Log` required. This step will fail if there are existing NULL values in that column.
  - Changed the type of `UsuEmpId` on the `Notificacao` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "EmpresaStatus" AS ENUM ('ATIVA', 'EXCLUIDA', 'BLOQUEADAPAGAMENTO', 'BLOQUEADA');

-- CreateEnum
CREATE TYPE "UsuarioStatus" AS ENUM ('ATIVO', 'EXCLUIDO', 'BLOQUEADOPAGAMENTO', 'BLOQUEADO');

-- CreateEnum
CREATE TYPE "EstabelecimentoStatus" AS ENUM ('ATIVO', 'EXCLUIDO', 'INATIVO', 'BLOQUEADO');

-- AlterTable
ALTER TABLE "Empresa" DROP COLUMN "EmpresaAtivo",
ADD COLUMN     "EmpresaStatus" "EmpresaStatus" NOT NULL DEFAULT 'ATIVA';

-- AlterTable
ALTER TABLE "Estabelecimento" DROP COLUMN "EstabelecimentoAtivo",
ADD COLUMN     "EstabelecimentoStatus" "EstabelecimentoStatus" NOT NULL DEFAULT 'ATIVO';

-- AlterTable
ALTER TABLE "Log" ALTER COLUMN "LogAcao" SET DATA TYPE VARCHAR(20),
ALTER COLUMN "LogDetalhe" SET NOT NULL;

-- AlterTable
ALTER TABLE "Notificacao" DROP COLUMN "TipoRelacao",
ADD COLUMN     "TipoRelacao" "UsuEmpRelacao" NOT NULL DEFAULT 'USUARIO',
DROP COLUMN "UsuEmpId",
ADD COLUMN     "UsuEmpId" INTEGER NOT NULL;

-- AlterTable
ALTER TABLE "Usuario" DROP COLUMN "UsuarioAtivo",
ADD COLUMN     "UsuarioStatus" "UsuarioStatus" NOT NULL DEFAULT 'ATIVO',
ADD COLUMN     "UsuarioUltimoLogin" TIMESTAMP(3);
