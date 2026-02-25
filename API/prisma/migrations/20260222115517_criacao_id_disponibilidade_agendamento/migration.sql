/*
  Warnings:

  - Added the required column `DisponibilidadeId` to the `Agendamento` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Agendamento" ADD COLUMN     "DisponibilidadeId" INTEGER NOT NULL;
