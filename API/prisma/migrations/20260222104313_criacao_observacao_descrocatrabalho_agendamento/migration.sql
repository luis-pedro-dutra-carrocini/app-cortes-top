/*
  Warnings:

  - Added the required column `DisponibilidadeDiaSemana` to the `Disponibilidade` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Agendamento" ADD COLUMN     "AgendamentoDescricaoTrabalho" TEXT,
ADD COLUMN     "AgendamentoObservacao" TEXT;

-- AlterTable
ALTER TABLE "Disponibilidade" ADD COLUMN     "DisponibilidadeDiaSemana" INTEGER NOT NULL;
