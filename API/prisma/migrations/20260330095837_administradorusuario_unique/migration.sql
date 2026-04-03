/*
  Warnings:

  - A unique constraint covering the columns `[AdministradorNome]` on the table `Administrador` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "Administrador_AdministradorNome_key" ON "Administrador"("AdministradorNome");
