/*
  Warnings:

  - You are about to drop the `UsuarioEsatablecimento` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "public"."UsuarioEsatablecimento" DROP CONSTRAINT "UsuarioEsatablecimento_EstabelecimentoId_fkey";

-- DropForeignKey
ALTER TABLE "public"."UsuarioEsatablecimento" DROP CONSTRAINT "UsuarioEsatablecimento_UsuarioId_fkey";

-- DropTable
DROP TABLE "public"."UsuarioEsatablecimento";

-- CreateTable
CREATE TABLE "UsuarioEstabelecimento" (
    "UsuarioEstabelecimentoId" SERIAL NOT NULL,
    "UsuarioId" INTEGER NOT NULL,
    "EstabelecimentoId" INTEGER NOT NULL,
    "UsuarioEstabelecimentoDtCriacao" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "UsuarioEstabelecimentoStatus" "UsuarioEstabelecimentoStatus" NOT NULL DEFAULT 'ATIVO',

    CONSTRAINT "UsuarioEstabelecimento_pkey" PRIMARY KEY ("UsuarioEstabelecimentoId")
);

-- AddForeignKey
ALTER TABLE "UsuarioEstabelecimento" ADD CONSTRAINT "UsuarioEstabelecimento_UsuarioId_fkey" FOREIGN KEY ("UsuarioId") REFERENCES "Usuario"("UsuarioId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "UsuarioEstabelecimento" ADD CONSTRAINT "UsuarioEstabelecimento_EstabelecimentoId_fkey" FOREIGN KEY ("EstabelecimentoId") REFERENCES "Estabelecimento"("EstabelecimentoId") ON DELETE RESTRICT ON UPDATE CASCADE;
