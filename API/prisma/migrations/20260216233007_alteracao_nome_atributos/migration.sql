/*
  Warnings:

  - The primary key for the `Agendamento` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `clienteId` on the `Agendamento` table. All the data in the column will be lost.
  - You are about to drop the column `dataCriacao` on the `Agendamento` table. All the data in the column will be lost.
  - You are about to drop the column `dataServico` on the `Agendamento` table. All the data in the column will be lost.
  - You are about to drop the column `horaServico` on the `Agendamento` table. All the data in the column will be lost.
  - You are about to drop the column `id` on the `Agendamento` table. All the data in the column will be lost.
  - You are about to drop the column `prestadorId` on the `Agendamento` table. All the data in the column will be lost.
  - You are about to drop the column `status` on the `Agendamento` table. All the data in the column will be lost.
  - You are about to drop the column `tempoGasto` on the `Agendamento` table. All the data in the column will be lost.
  - You are about to drop the column `valorTotal` on the `Agendamento` table. All the data in the column will be lost.
  - The primary key for the `Disponibilidade` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `diaSemana` on the `Disponibilidade` table. All the data in the column will be lost.
  - You are about to drop the column `horaFim` on the `Disponibilidade` table. All the data in the column will be lost.
  - You are about to drop the column `horaInicio` on the `Disponibilidade` table. All the data in the column will be lost.
  - You are about to drop the column `id` on the `Disponibilidade` table. All the data in the column will be lost.
  - You are about to drop the column `prestadorId` on the `Disponibilidade` table. All the data in the column will be lost.
  - The primary key for the `Servico` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `ativo` on the `Servico` table. All the data in the column will be lost.
  - You are about to drop the column `descricao` on the `Servico` table. All the data in the column will be lost.
  - You are about to drop the column `id` on the `Servico` table. All the data in the column will be lost.
  - You are about to drop the column `nome` on the `Servico` table. All the data in the column will be lost.
  - You are about to drop the column `prestadorId` on the `Servico` table. All the data in the column will be lost.
  - You are about to drop the column `tempoMedio` on the `Servico` table. All the data in the column will be lost.
  - The primary key for the `ServicoAgendamento` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `agendamentoId` on the `ServicoAgendamento` table. All the data in the column will be lost.
  - You are about to drop the column `id` on the `ServicoAgendamento` table. All the data in the column will be lost.
  - You are about to drop the column `servicoId` on the `ServicoAgendamento` table. All the data in the column will be lost.
  - The primary key for the `ServicoPreco` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `dataInicio` on the `ServicoPreco` table. All the data in the column will be lost.
  - You are about to drop the column `id` on the `ServicoPreco` table. All the data in the column will be lost.
  - You are about to drop the column `servicoId` on the `ServicoPreco` table. All the data in the column will be lost.
  - You are about to drop the column `valor` on the `ServicoPreco` table. All the data in the column will be lost.
  - The primary key for the `Usuario` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `createdAt` on the `Usuario` table. All the data in the column will be lost.
  - You are about to drop the column `email` on the `Usuario` table. All the data in the column will be lost.
  - You are about to drop the column `id` on the `Usuario` table. All the data in the column will be lost.
  - You are about to drop the column `nome` on the `Usuario` table. All the data in the column will be lost.
  - You are about to drop the column `senha` on the `Usuario` table. All the data in the column will be lost.
  - You are about to drop the column `telefone` on the `Usuario` table. All the data in the column will be lost.
  - You are about to drop the column `tipo` on the `Usuario` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[UsuarioTelefone]` on the table `Usuario` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[UsuarioEmail]` on the table `Usuario` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `AgendamentoDtServico` to the `Agendamento` table without a default value. This is not possible if the table is not empty.
  - Added the required column `AgendamentoHoraServico` to the `Agendamento` table without a default value. This is not possible if the table is not empty.
  - Added the required column `AgendamentoTempoGasto` to the `Agendamento` table without a default value. This is not possible if the table is not empty.
  - Added the required column `AgendamentoValorTotal` to the `Agendamento` table without a default value. This is not possible if the table is not empty.
  - Added the required column `ClienteId` to the `Agendamento` table without a default value. This is not possible if the table is not empty.
  - Added the required column `PrestadorId` to the `Agendamento` table without a default value. This is not possible if the table is not empty.
  - Added the required column `DisponibilidadeDiaSemana` to the `Disponibilidade` table without a default value. This is not possible if the table is not empty.
  - Added the required column `DisponibilidadeHoraFim` to the `Disponibilidade` table without a default value. This is not possible if the table is not empty.
  - Added the required column `DisponibilidadeHoraInicio` to the `Disponibilidade` table without a default value. This is not possible if the table is not empty.
  - Added the required column `PrestadorId` to the `Disponibilidade` table without a default value. This is not possible if the table is not empty.
  - Added the required column `PrestadorId` to the `Servico` table without a default value. This is not possible if the table is not empty.
  - Added the required column `ServicoNome` to the `Servico` table without a default value. This is not possible if the table is not empty.
  - Added the required column `ServicoTempoMedio` to the `Servico` table without a default value. This is not possible if the table is not empty.
  - Added the required column `AgendamentoId` to the `ServicoAgendamento` table without a default value. This is not possible if the table is not empty.
  - Added the required column `ServicoId` to the `ServicoAgendamento` table without a default value. This is not possible if the table is not empty.
  - Added the required column `ServicoId` to the `ServicoPreco` table without a default value. This is not possible if the table is not empty.
  - Added the required column `ServicoValor` to the `ServicoPreco` table without a default value. This is not possible if the table is not empty.
  - Added the required column `UsuarioEmail` to the `Usuario` table without a default value. This is not possible if the table is not empty.
  - Added the required column `UsuarioNome` to the `Usuario` table without a default value. This is not possible if the table is not empty.
  - Added the required column `UsuarioSenha` to the `Usuario` table without a default value. This is not possible if the table is not empty.
  - Added the required column `UsuarioTelefone` to the `Usuario` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "public"."Agendamento" DROP CONSTRAINT "Agendamento_clienteId_fkey";

-- DropForeignKey
ALTER TABLE "public"."Agendamento" DROP CONSTRAINT "Agendamento_prestadorId_fkey";

-- DropForeignKey
ALTER TABLE "public"."Disponibilidade" DROP CONSTRAINT "Disponibilidade_prestadorId_fkey";

-- DropForeignKey
ALTER TABLE "public"."Servico" DROP CONSTRAINT "Servico_prestadorId_fkey";

-- DropForeignKey
ALTER TABLE "public"."ServicoAgendamento" DROP CONSTRAINT "ServicoAgendamento_agendamentoId_fkey";

-- DropForeignKey
ALTER TABLE "public"."ServicoAgendamento" DROP CONSTRAINT "ServicoAgendamento_servicoId_fkey";

-- DropForeignKey
ALTER TABLE "public"."ServicoPreco" DROP CONSTRAINT "ServicoPreco_servicoId_fkey";

-- DropIndex
DROP INDEX "public"."Usuario_email_key";

-- DropIndex
DROP INDEX "public"."Usuario_telefone_key";

-- AlterTable
ALTER TABLE "Agendamento" DROP CONSTRAINT "Agendamento_pkey",
DROP COLUMN "clienteId",
DROP COLUMN "dataCriacao",
DROP COLUMN "dataServico",
DROP COLUMN "horaServico",
DROP COLUMN "id",
DROP COLUMN "prestadorId",
DROP COLUMN "status",
DROP COLUMN "tempoGasto",
DROP COLUMN "valorTotal",
ADD COLUMN     "AgendamentoDtCriacao" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "AgendamentoDtServico" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "AgendamentoHoraServico" TEXT NOT NULL,
ADD COLUMN     "AgendamentoId" SERIAL NOT NULL,
ADD COLUMN     "AgendamentoStatus" "AppointmentStatus" NOT NULL DEFAULT 'PENDENTE',
ADD COLUMN     "AgendamentoTempoGasto" INTEGER NOT NULL,
ADD COLUMN     "AgendamentoValorTotal" DECIMAL(10,2) NOT NULL,
ADD COLUMN     "ClienteId" INTEGER NOT NULL,
ADD COLUMN     "PrestadorId" INTEGER NOT NULL,
ADD CONSTRAINT "Agendamento_pkey" PRIMARY KEY ("AgendamentoId");

-- AlterTable
ALTER TABLE "Disponibilidade" DROP CONSTRAINT "Disponibilidade_pkey",
DROP COLUMN "diaSemana",
DROP COLUMN "horaFim",
DROP COLUMN "horaInicio",
DROP COLUMN "id",
DROP COLUMN "prestadorId",
ADD COLUMN     "DisponibilidadeDiaSemana" INTEGER NOT NULL,
ADD COLUMN     "DisponibilidadeHoraFim" TEXT NOT NULL,
ADD COLUMN     "DisponibilidadeHoraInicio" TEXT NOT NULL,
ADD COLUMN     "Disponibilidadeid" SERIAL NOT NULL,
ADD COLUMN     "PrestadorId" INTEGER NOT NULL,
ADD CONSTRAINT "Disponibilidade_pkey" PRIMARY KEY ("Disponibilidadeid");

-- AlterTable
ALTER TABLE "Servico" DROP CONSTRAINT "Servico_pkey",
DROP COLUMN "ativo",
DROP COLUMN "descricao",
DROP COLUMN "id",
DROP COLUMN "nome",
DROP COLUMN "prestadorId",
DROP COLUMN "tempoMedio",
ADD COLUMN     "PrestadorId" INTEGER NOT NULL,
ADD COLUMN     "ServicoAtivo" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "ServicoDescricao" TEXT,
ADD COLUMN     "ServicoId" SERIAL NOT NULL,
ADD COLUMN     "ServicoNome" TEXT NOT NULL,
ADD COLUMN     "ServicoTempoMedio" INTEGER NOT NULL,
ADD CONSTRAINT "Servico_pkey" PRIMARY KEY ("ServicoId");

-- AlterTable
ALTER TABLE "ServicoAgendamento" DROP CONSTRAINT "ServicoAgendamento_pkey",
DROP COLUMN "agendamentoId",
DROP COLUMN "id",
DROP COLUMN "servicoId",
ADD COLUMN     "AgendamentoId" INTEGER NOT NULL,
ADD COLUMN     "ServicoAgendamentoId" SERIAL NOT NULL,
ADD COLUMN     "ServicoId" INTEGER NOT NULL,
ADD CONSTRAINT "ServicoAgendamento_pkey" PRIMARY KEY ("ServicoAgendamentoId");

-- AlterTable
ALTER TABLE "ServicoPreco" DROP CONSTRAINT "ServicoPreco_pkey",
DROP COLUMN "dataInicio",
DROP COLUMN "id",
DROP COLUMN "servicoId",
DROP COLUMN "valor",
ADD COLUMN     "ServicoId" INTEGER NOT NULL,
ADD COLUMN     "ServicoPrecoDtCriacao" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "ServicoPrecoId" SERIAL NOT NULL,
ADD COLUMN     "ServicoValor" DECIMAL(10,2) NOT NULL,
ADD CONSTRAINT "ServicoPreco_pkey" PRIMARY KEY ("ServicoPrecoId");

-- AlterTable
ALTER TABLE "Usuario" DROP CONSTRAINT "Usuario_pkey",
DROP COLUMN "createdAt",
DROP COLUMN "email",
DROP COLUMN "id",
DROP COLUMN "nome",
DROP COLUMN "senha",
DROP COLUMN "telefone",
DROP COLUMN "tipo",
ADD COLUMN     "UsuarioDtCriacao" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "UsuarioEmail" TEXT NOT NULL,
ADD COLUMN     "UsuarioId" SERIAL NOT NULL,
ADD COLUMN     "UsuarioNome" TEXT NOT NULL,
ADD COLUMN     "UsuarioSenha" TEXT NOT NULL,
ADD COLUMN     "UsuarioTelefone" TEXT NOT NULL,
ADD COLUMN     "UsuarioTipo" "UserType" NOT NULL DEFAULT 'CLIENTE',
ADD CONSTRAINT "Usuario_pkey" PRIMARY KEY ("UsuarioId");

-- CreateIndex
CREATE UNIQUE INDEX "Usuario_UsuarioTelefone_key" ON "Usuario"("UsuarioTelefone");

-- CreateIndex
CREATE UNIQUE INDEX "Usuario_UsuarioEmail_key" ON "Usuario"("UsuarioEmail");

-- AddForeignKey
ALTER TABLE "Disponibilidade" ADD CONSTRAINT "Disponibilidade_PrestadorId_fkey" FOREIGN KEY ("PrestadorId") REFERENCES "Usuario"("UsuarioId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Servico" ADD CONSTRAINT "Servico_PrestadorId_fkey" FOREIGN KEY ("PrestadorId") REFERENCES "Usuario"("UsuarioId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicoPreco" ADD CONSTRAINT "ServicoPreco_ServicoId_fkey" FOREIGN KEY ("ServicoId") REFERENCES "Servico"("ServicoId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Agendamento" ADD CONSTRAINT "Agendamento_PrestadorId_fkey" FOREIGN KEY ("PrestadorId") REFERENCES "Usuario"("UsuarioId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Agendamento" ADD CONSTRAINT "Agendamento_ClienteId_fkey" FOREIGN KEY ("ClienteId") REFERENCES "Usuario"("UsuarioId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicoAgendamento" ADD CONSTRAINT "ServicoAgendamento_ServicoId_fkey" FOREIGN KEY ("ServicoId") REFERENCES "Servico"("ServicoId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicoAgendamento" ADD CONSTRAINT "ServicoAgendamento_AgendamentoId_fkey" FOREIGN KEY ("AgendamentoId") REFERENCES "Agendamento"("AgendamentoId") ON DELETE RESTRICT ON UPDATE CASCADE;
