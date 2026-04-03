/*
  Warnings:

  - You are about to drop the column `UsuarioId` on the `Notificacao` table. All the data in the column will be lost.
  - Added the required column `TipoRelacao` to the `Notificacao` table without a default value. This is not possible if the table is not empty.
  - Added the required column `ServicoValor` to the `ServicoAgendamento` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "UsuEmpRelacao" AS ENUM ('USUARIO', 'EMPRESA');

-- CreateEnum
CREATE TYPE "UsuEstRelacao" AS ENUM ('USUARIO', 'ESTABELECIMENTO');

-- DropForeignKey
ALTER TABLE "public"."Notificacao" DROP CONSTRAINT "Notificacao_UsuarioId_fkey";

-- AlterTable
ALTER TABLE "Agendamento" ADD COLUMN     "EstabelecimentoId" INTEGER;

-- AlterTable
ALTER TABLE "Disponibilidade" ADD COLUMN     "EstabelecimentoId" INTEGER;

-- AlterTable
ALTER TABLE "Notificacao" DROP COLUMN "UsuarioId",
ADD COLUMN     "TipoRelacao" VARCHAR(50) NOT NULL,
ADD COLUMN     "UsuEmpId" "UsuEmpRelacao" NOT NULL DEFAULT 'USUARIO';

-- AlterTable
ALTER TABLE "Servico" ADD COLUMN     "ServicoEstabelecimentoId" INTEGER;

-- AlterTable
ALTER TABLE "ServicoAgendamento" ADD COLUMN     "ServicoValor" DECIMAL(10,2) NOT NULL;

-- AlterTable
ALTER TABLE "ServicoPreco" ADD COLUMN     "EstabelecimentoId" INTEGER;

-- AlterTable
ALTER TABLE "Usuario" ADD COLUMN     "UsuarioAtivo" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "UsuarioEnderecoId" INTEGER;

-- CreateTable
CREATE TABLE "Empresa" (
    "EmpresaId" SERIAL NOT NULL,
    "EmpresaNome" VARCHAR(100) NOT NULL,
    "EmpresaCNPJ" VARCHAR(20) NOT NULL,
    "EmpresaLogo" VARCHAR(255),
    "EmpresaDescricao" TEXT,
    "EmpresaAtivo" BOOLEAN NOT NULL DEFAULT true,
    "EmpresaDtCriacao" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "EmpresaTelefone" VARCHAR(15) NOT NULL,
    "EmpresaEmail" VARCHAR(256) NOT NULL,
    "EmpresaUltimoLogin" TIMESTAMP(3),

    CONSTRAINT "Empresa_pkey" PRIMARY KEY ("EmpresaId")
);

-- CreateTable
CREATE TABLE "Estabelecimento" (
    "EstabelecimentoId" SERIAL NOT NULL,
    "EmpresaId" INTEGER NOT NULL,
    "EstabelecimentoNome" VARCHAR(100) NOT NULL,
    "EstabelecimentoEndereco" INTEGER NOT NULL,
    "EstabelecimentoTelefone" VARCHAR(15) NOT NULL,
    "EstabelecimentoAtivo" BOOLEAN NOT NULL DEFAULT true,
    "EstabelecimentoDtCriacao" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Estabelecimento_pkey" PRIMARY KEY ("EstabelecimentoId")
);

-- CreateTable
CREATE TABLE "UsuarioEsatablecimento" (
    "UsuarioEstabelecimentoId" SERIAL NOT NULL,
    "UsuarioId" INTEGER NOT NULL,
    "EstabelecimentoId" INTEGER NOT NULL,

    CONSTRAINT "UsuarioEsatablecimento_pkey" PRIMARY KEY ("UsuarioEstabelecimentoId")
);

-- CreateTable
CREATE TABLE "Endereco" (
    "EnderecoId" SERIAL NOT NULL,
    "UsuEstId" "UsuEstRelacao" NOT NULL DEFAULT 'USUARIO',
    "TipoRelacao" VARCHAR(50) NOT NULL,
    "EnderecoRua" VARCHAR(255) NOT NULL,
    "EnderecoNumero" VARCHAR(10) NOT NULL,
    "EnderecoComplemento" VARCHAR(255),
    "EnderecoBairro" VARCHAR(100) NOT NULL,
    "EnderecoCidade" VARCHAR(100) NOT NULL,
    "EnderecoEstado" VARCHAR(2) NOT NULL,
    "EnderecoCEP" VARCHAR(10) NOT NULL,

    CONSTRAINT "Endereco_pkey" PRIMARY KEY ("EnderecoId")
);

-- CreateTable
CREATE TABLE "ServicoEstabelecimento" (
    "ServicoEstabelecimentoId" SERIAL NOT NULL,
    "EstabelecimentoId" INTEGER NOT NULL,
    "ServicoNome" VARCHAR(100) NOT NULL,
    "ServicoDescricao" TEXT,
    "ServicoTempoMedio" INTEGER NOT NULL,
    "ServicoAtivo" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "ServicoEstabelecimento_pkey" PRIMARY KEY ("ServicoEstabelecimentoId")
);

-- CreateTable
CREATE TABLE "Log" (
    "LogId" SERIAL NOT NULL,
    "UsuEmpId" "UsuEmpRelacao",
    "TipoRelacao" VARCHAR(50) NOT NULL,
    "LogAcao" VARCHAR(255) NOT NULL,
    "LogDetalhe" TEXT,
    "LogDataHora" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Log_pkey" PRIMARY KEY ("LogId")
);

-- CreateIndex
CREATE UNIQUE INDEX "Empresa_EmpresaCNPJ_key" ON "Empresa"("EmpresaCNPJ");

-- CreateIndex
CREATE UNIQUE INDEX "Empresa_EmpresaTelefone_key" ON "Empresa"("EmpresaTelefone");

-- CreateIndex
CREATE UNIQUE INDEX "Empresa_EmpresaEmail_key" ON "Empresa"("EmpresaEmail");

-- AddForeignKey
ALTER TABLE "Estabelecimento" ADD CONSTRAINT "Estabelecimento_EmpresaId_fkey" FOREIGN KEY ("EmpresaId") REFERENCES "Empresa"("EmpresaId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UsuarioEsatablecimento" ADD CONSTRAINT "UsuarioEsatablecimento_UsuarioId_fkey" FOREIGN KEY ("UsuarioId") REFERENCES "Usuario"("UsuarioId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UsuarioEsatablecimento" ADD CONSTRAINT "UsuarioEsatablecimento_EstabelecimentoId_fkey" FOREIGN KEY ("EstabelecimentoId") REFERENCES "Estabelecimento"("EstabelecimentoId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Disponibilidade" ADD CONSTRAINT "Disponibilidade_EstabelecimentoId_fkey" FOREIGN KEY ("EstabelecimentoId") REFERENCES "Estabelecimento"("EstabelecimentoId") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Servico" ADD CONSTRAINT "Servico_ServicoEstabelecimentoId_fkey" FOREIGN KEY ("ServicoEstabelecimentoId") REFERENCES "ServicoEstabelecimento"("ServicoEstabelecimentoId") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicoEstabelecimento" ADD CONSTRAINT "ServicoEstabelecimento_EstabelecimentoId_fkey" FOREIGN KEY ("EstabelecimentoId") REFERENCES "Estabelecimento"("EstabelecimentoId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServicoPreco" ADD CONSTRAINT "ServicoPreco_EstabelecimentoId_fkey" FOREIGN KEY ("EstabelecimentoId") REFERENCES "Estabelecimento"("EstabelecimentoId") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Agendamento" ADD CONSTRAINT "Agendamento_EstabelecimentoId_fkey" FOREIGN KEY ("EstabelecimentoId") REFERENCES "Estabelecimento"("EstabelecimentoId") ON DELETE SET NULL ON UPDATE CASCADE;
