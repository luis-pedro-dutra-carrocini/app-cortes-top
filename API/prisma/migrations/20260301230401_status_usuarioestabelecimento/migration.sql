-- CreateEnum
CREATE TYPE "UsuarioEstabelecimentoStatus" AS ENUM ('ATIVO', 'SOLICITADOEST', 'SOLICITADOPRE', 'INATIVO', 'EXCLUIDO', 'BLOQUEADO');

-- AlterTable
ALTER TABLE "UsuarioEsatablecimento" ADD COLUMN     "UsuarioEstabelecimentoDtCriacao" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "UsuarioEstabelecimentoStatus" "UsuarioEstabelecimentoStatus" NOT NULL DEFAULT 'ATIVO';
