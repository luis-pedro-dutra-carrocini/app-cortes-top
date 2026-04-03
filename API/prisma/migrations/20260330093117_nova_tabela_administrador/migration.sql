/*
  Warnings:

  - The primary key for the `Log` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `LogDataHora` on the `Log` table. All the data in the column will be lost.
  - The primary key for the `Notificacao` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `Notificacaoid` on the `Notificacao` table. All the data in the column will be lost.
  - Changed the type of `TipoRelacao` on the `Log` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - The required column `NotificacaoId` was added to the `Notificacao` table with a prisma-level default value. This is not possible if the table is not empty. Please add this column as optional, then populate it before making it required.

*/
-- CreateEnum
CREATE TYPE "LogTipoRelacao" AS ENUM ('USUARIO', 'EMPRESA', 'SISTEMA', 'OUTRO');

-- AlterTable
ALTER TABLE "Log" DROP CONSTRAINT "Log_pkey",
DROP COLUMN "LogDataHora",
ALTER COLUMN "LogId" DROP DEFAULT,
ALTER COLUMN "LogId" SET DATA TYPE TEXT,
DROP COLUMN "TipoRelacao",
ADD COLUMN     "TipoRelacao" "LogTipoRelacao" NOT NULL,
ADD CONSTRAINT "Log_pkey" PRIMARY KEY ("LogId");
DROP SEQUENCE "Log_LogId_seq";

-- AlterTable
ALTER TABLE "Notificacao" DROP CONSTRAINT "Notificacao_pkey",
DROP COLUMN "Notificacaoid",
ADD COLUMN     "NotificacaoId" TEXT NOT NULL,
ADD CONSTRAINT "Notificacao_pkey" PRIMARY KEY ("NotificacaoId");

-- CreateTable
CREATE TABLE "Administrador" (
    "AdministradorId" SERIAL NOT NULL,
    "AdministradorNome" VARCHAR(100) NOT NULL,
    "AdministradorUsuario" VARCHAR(20) NOT NULL,
    "AdministradorSenha" TEXT NOT NULL,
    "AdministradorUltimoLogin" TIMESTAMP(3),

    CONSTRAINT "Administrador_pkey" PRIMARY KEY ("AdministradorId")
);
