import { ThemeProvider } from "next-themes"
import { GeistSans } from "geist/font/sans"
import { GeistMono } from "geist/font/mono"
import { AuthProvider } from "@/app/contexts/AuthContext" // Provider do ADMIN
import "./globals.css"

export const metadata = {
  title: "Sistema Agendamento de Serviços",
  description: "Gerenciamento do sistema de agendamentos de serviços",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="pt-BR" suppressHydrationWarning>
      <body className={`${GeistSans.variable} ${GeistMono.variable} font-sans antialiased`}>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          {/* Ordem não importa, desde que ambos estejam disponíveis */}
          <AuthProvider>
            <AuthProvider>
              {children}
            </AuthProvider>
          </AuthProvider>
        </ThemeProvider>
      </body>
    </html>
  )
}