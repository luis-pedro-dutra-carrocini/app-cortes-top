/*
  Warnings:

  - You are about to alter the column `AgendamentoHoraServico` on the `Agendamento` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(5)`.
  - You are about to drop the column `DisponibilidadeDiaSemana` on the `Disponibilidade` table. All the data in the column will be lost.
  - You are about to alter the column `DisponibilidadeHoraFim` on the `Disponibilidade` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(5)`.
  - You are about to alter the column `DisponibilidadeHoraInicio` on the `Disponibilidade` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(5)`.
  - You are about to alter the column `ServicoNome` on the `Servico` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(100)`.
  - You are about to alter the column `UsuarioEmail` on the `Usuario` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(256)`.
  - You are about to alter the column `UsuarioNome` on the `Usuario` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(100)`.
  - You are about to alter the column `UsuarioTelefone` on the `Usuario` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(15)`.
  - A unique constraint covering the columns `[UsuarioTelefone]` on the table `Usuario` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateEnum
CREATE TYPE "NotificationStatus" AS ENUM ('ENVIADO', 'EXIBIDO', 'LIDO');

-- AlterTable
ALTER TABLE "Agendamento" ALTER COLUMN "AgendamentoHoraServico" SET DATA TYPE VARCHAR(5);

-- AlterTable
ALTER TABLE "Disponibilidade" DROP COLUMN "DisponibilidadeDiaSemana",
ADD COLUMN     "DisponibilidadeData" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "DisponibilidadeStatus" BOOLEAN NOT NULL DEFAULT true,
ALTER COLUMN "DisponibilidadeHoraFim" SET DATA TYPE VARCHAR(5),
ALTER COLUMN "DisponibilidadeHoraInicio" SET DATA TYPE VARCHAR(5);

-- AlterTable
ALTER TABLE "Servico" ALTER COLUMN "ServicoNome" SET DATA TYPE VARCHAR(100);

-- AlterTable
ALTER TABLE "Usuario" ALTER COLUMN "UsuarioEmail" SET DATA TYPE VARCHAR(256),
ALTER COLUMN "UsuarioNome" SET DATA TYPE VARCHAR(100),
ALTER COLUMN "UsuarioTelefone" SET DATA TYPE VARCHAR(15);

-- CreateTable
CREATE TABLE "Notificacao" (
    "Notificacaoid" SERIAL NOT NULL,
    "UsuarioId" INTEGER NOT NULL,
    "NotificacaoData" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "NotificacaoTipo" VARCHAR(50) NOT NULL,
    "NotificacaoTitulo" VARCHAR(100) NOT NULL,
    "NotificacaoMensagem" TEXT NOT NULL,
    "NotificacaoStatus" "NotificationStatus" NOT NULL DEFAULT 'ENVIADO',

    CONSTRAINT "Notificacao_pkey" PRIMARY KEY ("Notificacaoid")
);

-- CreateIndex
CREATE UNIQUE INDEX "Usuario_UsuarioTelefone_key" ON "Usuario"("UsuarioTelefone");

-- AddForeignKey
ALTER TABLE "Notificacao" ADD CONSTRAINT "Notificacao_UsuarioId_fkey" FOREIGN KEY ("UsuarioId") REFERENCES "Usuario"("UsuarioId") ON DELETE RESTRICT ON UPDATE CASCADE;
