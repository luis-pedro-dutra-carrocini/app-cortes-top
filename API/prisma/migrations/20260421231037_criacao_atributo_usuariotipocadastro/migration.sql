-- AlterTable
ALTER TABLE "Usuario" ADD COLUMN     "UsuarioTipoCadastro" VARCHAR(50),
ALTER COLUMN "UsuarioSenha" DROP NOT NULL;
