-- AddForeignKey
ALTER TABLE "Agendamento" ADD CONSTRAINT "Agendamento_DisponibilidadeId_fkey" FOREIGN KEY ("DisponibilidadeId") REFERENCES "Disponibilidade"("Disponibilidadeid") ON DELETE RESTRICT ON UPDATE CASCADE;
