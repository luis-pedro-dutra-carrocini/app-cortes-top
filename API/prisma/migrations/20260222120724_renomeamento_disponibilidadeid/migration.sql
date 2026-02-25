/*
  Warnings:

  - The primary key for the `Disponibilidade` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `Disponibilidadeid` on the `Disponibilidade` table. All the data in the column will be lost.

*/
-- DropForeignKey
ALTER TABLE "public"."Agendamento" DROP CONSTRAINT "Agendamento_DisponibilidadeId_fkey";

-- AlterTable
ALTER TABLE "Disponibilidade" DROP CONSTRAINT "Disponibilidade_pkey",
DROP COLUMN "Disponibilidadeid",
ADD COLUMN     "DisponibilidadeId" SERIAL NOT NULL,
ADD CONSTRAINT "Disponibilidade_pkey" PRIMARY KEY ("DisponibilidadeId");

-- AddForeignKey
ALTER TABLE "Agendamento" ADD CONSTRAINT "Agendamento_DisponibilidadeId_fkey" FOREIGN KEY ("DisponibilidadeId") REFERENCES "Disponibilidade"("DisponibilidadeId") ON DELETE RESTRICT ON UPDATE CASCADE;
